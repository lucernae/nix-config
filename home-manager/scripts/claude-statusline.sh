#!/run/current-system/sw/bin/nix-shell
#!nix-shell -i python3 -p python3 git starship
import json, os, re, shutil, subprocess, sys, time, unicodedata

def term_width():
    # Prefer COLUMNS env var (set by shell), then tput, then fall back to 80
    cols = os.environ.get('COLUMNS')
    if cols and cols.isdigit():
        return int(cols)
    size = shutil.get_terminal_size(fallback=(80, 24))
    return size.columns

ANSI_RE = re.compile(r'\033\[[0-9;]*m')

def display_width(s):
    w = 0
    for ch in ANSI_RE.sub('', s):
        w += 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1
    return w

def ansi_trunc(s, limit=80):
    result, vis, i = [], 0, 0
    while i < len(s):
        if s[i] == '\033' and i + 1 < len(s) and s[i+1] == '[':
            j = i + 2
            while j < len(s) and not s[j].isalpha():
                j += 1
            result.append(s[i:j+1])
            i = j + 1
        else:
            w = 2 if unicodedata.east_asian_width(s[i]) in ('W', 'F') else 1
            if vis + w <= limit:
                result.append(s[i])
                vis += w
            i += 1
    return ''.join(result) + '\033[0m'

def ansi_trunc_pad(s, limit):
    """Truncate to limit visible cols, pad with spaces to exactly limit cols."""
    result, vis, i = [], 0, 0
    while i < len(s):
        if s[i] == '\033' and i + 1 < len(s) and s[i+1] == '[':
            j = i + 2
            while j < len(s) and not s[j].isalpha():
                j += 1
            result.append(s[i:j+1])
            i = j + 1
        else:
            w = 2 if unicodedata.east_asian_width(s[i]) in ('W', 'F') else 1
            if vis + w <= limit:
                result.append(s[i])
                vis += w
            i += 1
    return ''.join(result) + '\033[0m' + ' ' * (limit - vis)

def ansi_slice(s, start_col, num_cols):
    """Extract visible columns [start_col, start_col+num_cols) preserving ANSI state."""
    result, vis, end_col, i = [], 0, start_col + num_cols, 0
    while i < len(s):
        if s[i] == '\033' and i + 1 < len(s) and s[i+1] == '[':
            j = i + 2
            while j < len(s) and not s[j].isalpha():
                j += 1
            result.append(s[i:j+1])
            i = j + 1
        else:
            w = 2 if unicodedata.east_asian_width(s[i]) in ('W', 'F') else 1
            if start_col <= vis < end_col:
                result.append(s[i])
            vis += w
            i += 1
            if vis >= end_col:
                break
    return ''.join(result) + '\033[0m'

def marquee(text, budget, now):
    """Scroll text left-to-right if it overflows budget, pause 3s at end, reset."""
    full_w = display_width(text)
    if full_w <= budget:
        return text
    scroll_dist = full_w - budget
    offset = min(int(now) % (scroll_dist + 3), scroll_dist)
    return ansi_slice(text, offset, budget)

def starship(path, width=80):
    try:
        out = subprocess.run(
            ['starship', 'prompt', '--path', path, '--terminal-width', str(width)],
            capture_output=True, text=True,
            env={**os.environ, 'STARSHIP_SHELL': 'bash'}
        ).stdout
        out = out.replace('\\[', '').replace('\\]', '').replace('\\$', '$')
        lines = [l for l in out.splitlines() if l.strip()]
        return lines[0] if lines else ''
    except Exception:
        return ''

data    = json.load(sys.stdin)
ws      = data.get('workspace', {})
cdir    = ws.get('current_dir', '')
wt      = ws.get('git_worktree', '')
sname   = data.get('session_name', '')
sid     = data.get('session_id', '')[:8]
pct     = data.get('context_window', {}).get('used_percentage')
model   = data.get('model', {}).get('display_name', '-')
cost    = data.get('cost', {}).get('total_cost_usd')

width = term_width()
now   = time.time()
inner = max(2, width - 2)  # content width inside box borders

# Starship: split at " via "
raw = starship(cdir, width) if cdir else ''
if ' via ' in raw:
    idx = raw.index(' via ')
    s_main, s_via = raw[:idx], 'via ' + raw[idx+5:]
else:
    s_main, s_via = raw, ''

# Session line — marquee name to fit, keeping " · sid" intact
wt_tag = f'[worktree: {wt}] ' if wt else ''
if sname:
    # fixed: 🧵(2) + space(1) + " · "(3) + sid(8) = 14 cols
    name_budget = inner - display_width(wt_tag) - 14
    sname_display = marquee(sname, max(1, name_budget), now)
    session = f'🧵 \033[94m{sname_display}\033[0m · \033[38;5;208m{sid}\033[0m'
else:
    session = f'🧵 \033[38;5;208m{sid}\033[0m'

# Model / cost / context line
cost_s = f'${cost:.4f}' if cost is not None else '$-'
if pct is not None:
    filled = round(pct / 10)
    bar = '█' * filled + '░' * (10 - filled)
    ctx_s = f'[{bar}] {pct:.0f}%'
else:
    ctx_s = '[░░░░░░░░░░] -%'
suffix_s = f' 💸 \033[92m{cost_s}\033[0m 📊 \033[93m{ctx_s}\033[0m'
model_budget = max(1, inner - 3 - display_width(suffix_s))
model_display = marquee(model, model_budget, now)
stats = f'🧠 \033[94m{model_display}\033[0m{suffix_s}'

# Box output
border = '─' * inner
lines = [wt_tag + session]
if s_main: lines.append(marquee(s_main, inner, now))
if s_via:  lines.append(marquee(s_via, inner, now))
lines.append(stats)

print('┌' + border + '┐')
for line in lines:
    print('│' + ansi_trunc_pad(line, inner) + '│')
print('└' + border + '┘')
