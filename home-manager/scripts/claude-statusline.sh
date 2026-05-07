#!/run/current-system/sw/bin/nix-shell
#!nix-shell -i python3 -p python3 python3Packages.pyyaml git starship
import json, os, random, re, shutil, subprocess, sys, time, unicodedata
import yaml

# ── Config ────────────────────────────────────────────────────────────────────

CONFIG_PATH = os.path.expanduser('~/.claude/statusline.yaml')

DEFAULTS = {
    'box': True,
    'sparkles': {
        'enabled': True,
        'density': 8,
        'chars':  ['✦', '✧', '⋆', '·'],
        'colors': ['yellow', 'white', 'cyan', 'magenta'],
    },
    'direction': 'ltr',
    'lines':  ['session', 'starship', 'stats'],
    'icons': {
        'session':   '🧵',
        'model':     '🧠',
        'cost':      '💸',
        'duration':  '⏱',
        'context':   '📊',
        'directory': '📂',
        'branch':    '🌿',
    },
    'colors': {
        'session_name': 'bright_blue',
        'session_id':   'orange',
        'model':        'bright_blue',
        'cost':         'bright_green',
        'duration':     'bright_cyan',
        'context':      'bright_yellow',
        'directory':    'bright_cyan',
        'branch':       'bright_magenta',
    },
}

def load_config():
    try:
        with open(CONFIG_PATH) as f:
            user = yaml.safe_load(f) or {}
    except FileNotFoundError:
        user = {}
    cfg = dict(DEFAULTS)
    for k, v in user.items():
        if isinstance(v, dict) and isinstance(cfg.get(k), dict):
            cfg[k] = {**cfg[k], **v}
        else:
            cfg[k] = v
    return cfg

cfg = load_config()

# ── Color map ─────────────────────────────────────────────────────────────────

ANSI = {
    'bright_blue':    '\033[94m',
    'bright_green':   '\033[92m',
    'bright_yellow':  '\033[93m',
    'bright_cyan':    '\033[96m',
    'bright_magenta': '\033[95m',
    'bright_white':   '\033[97m',
    'bright_red':     '\033[91m',
    'orange':         '\033[38;5;208m',
    'blue':           '\033[34m',  'green':   '\033[32m',
    'yellow':         '\033[33m',  'cyan':    '\033[36m',
    'magenta':        '\033[35m',  'white':   '\033[37m',
    'red':            '\033[31m',  'dim':     '\033[2m',
}
RST = '\033[0m'

def c(name):
    return ANSI.get(name, '')

col = cfg['colors']
ico = cfg['icons']
rtl = cfg.get('direction', 'ltr') == 'rtl'

# ── Text helpers ───────────────────────────────────────────────────────────────

def term_width():
    cols = os.environ.get('COLUMNS')
    if cols and cols.isdigit():
        return int(cols)
    return shutil.get_terminal_size(fallback=(80, 24)).columns

ANSI_RE = re.compile(r'\033\[[0-9;]*m')

def display_width(s):
    w = 0
    for ch in ANSI_RE.sub('', s):
        w += 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1
    return w

def trunc_text(s, limit):
    w = 0
    for i, ch in enumerate(s):
        cw = 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1
        if w + cw > limit:
            return s[:i].rstrip() + '…'
        w += cw
    return s

# ── Sparkles ───────────────────────────────────────────────────────────────────

sp_cfg    = cfg['sparkles']
SP_CHARS  = sp_cfg['chars']
SP_COLORS = [ANSI.get(n, RST) for n in sp_cfg['colors']]

def sparkle_pad(n, seed):
    if n <= 0 or not sp_cfg['enabled']:
        return ' ' * n
    rng   = random.Random(hash(seed))
    cells = [' '] * n
    count = max(1, n // sp_cfg['density'])
    for pos in rng.sample(range(n), min(count, n)):
        cells[pos] = f'{rng.choice(SP_COLORS)}{rng.choice(SP_CHARS)}{RST}'
    return ''.join(cells)

# ── Line rendering ─────────────────────────────────────────────────────────────

def ansi_trunc_pad(s, limit, seed=None, rtl=False):
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
    pad = sparkle_pad(limit - vis, seed) if seed is not None else ' ' * (limit - vis)
    content = ''.join(result) + RST
    return pad + content if rtl else content + pad

def format_duration(ms):
    if ms is None:
        return '-'
    ms = int(ms)
    if ms < 1000:
        return f'{ms}ms'
    s = ms // 1000
    if s < 60:
        return f'{s}s'
    m, s = divmod(s, 60)
    if m < 60:
        return f'{m}m {s}s'
    h, m = divmod(m, 60)
    return f'{h}h {m}m'

# ── Starship ───────────────────────────────────────────────────────────────────

def has_starship_config():
    # STARSHIP_CONFIG env var being set means starship is integrated (home-manager sets it)
    if os.environ.get('STARSHIP_CONFIG'):
        return True
    # Fallback: check default config location for manual installs
    return os.path.isfile(os.path.expanduser('~/.config/starship.toml'))

def starship(path, width=80):
    if not has_starship_config():
        return ''
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

def build_dir_line(cdir):
    home = os.path.expanduser('~')
    short = cdir.replace(home, '~') if cdir.startswith(home) else cdir
    branch = ''
    try:
        r = subprocess.run(
            ['git', '-C', cdir, 'branch', '--show-current'],
            capture_output=True, text=True, timeout=2
        )
        if r.returncode == 0:
            branch = r.stdout.strip()
    except Exception:
        pass
    line = f'{ico["directory"]} {c(col["directory"])}{short}{RST}'
    if branch:
        line += f' on {ico["branch"]} {c(col["branch"])}{branch}{RST}'
    return line

# ── Data ───────────────────────────────────────────────────────────────────────

data  = json.load(sys.stdin)
ws    = data.get('workspace', {})
cdir  = ws.get('current_dir', '')
wt    = ws.get('git_worktree', '')
sname = data.get('session_name', '')
sid   = data.get('session_id', '')[:8]
pct   = data.get('context_window', {}).get('used_percentage')
model = data.get('model', {}).get('display_name', '-')
cost  = data.get('cost', {}).get('total_cost_usd')
dur   = data.get('cost', {}).get('total_duration_ms')

width = term_width()
inner = max(2, width - 2)
tick  = int(time.time())

# ── Build sections ─────────────────────────────────────────────────────────────

raw = starship(cdir, width) if cdir else ''
if raw:
    if ' via ' in raw:
        idx = raw.index(' via ')
        starship_lines = [raw[:idx], 'via ' + raw[idx+5:]]
    else:
        starship_lines = [raw]
elif cdir:
    starship_lines = [build_dir_line(cdir)]
else:
    starship_lines = []

wt_tag = f'[worktree: {wt}]' if wt else ''
if sname:
    # icon(2) + space(1) + " · "(3) + sid(8) = 14 cols fixed
    wt_w          = display_width(wt_tag) + (1 if wt_tag else 0)
    name_budget   = inner - wt_w - 14
    sname_display = trunc_text(sname, max(1, name_budget))
    if rtl:
        session = (f'{c(col["session_id"])}{sid}{RST}'
                   f' · {c(col["session_name"])}{sname_display}{RST}'
                   f' {ico["session"]}' + (f' {wt_tag}' if wt_tag else ''))
    else:
        session = ((f'{wt_tag} ' if wt_tag else '') +
                   f'{ico["session"]} {c(col["session_name"])}{sname_display}{RST}'
                   f' · {c(col["session_id"])}{sid}{RST}')
else:
    if rtl:
        session = f'{c(col["session_id"])}{sid}{RST} {ico["session"]}' + (f' {wt_tag}' if wt_tag else '')
    else:
        session = (f'{wt_tag} ' if wt_tag else '') + f'{ico["session"]} {c(col["session_id"])}{sid}{RST}'

cost_s = f'${cost:.4f}' if cost is not None else '$-'
dur_s  = format_duration(dur)
if pct is not None:
    filled = round(pct / 10)
    bar    = '█' * filled + '░' * (10 - filled)
    ctx_s  = f'[{bar}] {pct:.0f}%'
else:
    ctx_s = '[░░░░░░░░░░] -%'

# Stats elements: (icon, value, color_key) — reversed in RTL
stat_elems = [
    (ico['model'],    None,   col['model']),   # model filled below after budget calc
    (ico['cost'],     cost_s, col['cost']),
    (ico['duration'], dur_s,  col['duration']),
    (ico['context'],  ctx_s,  col['context']),
]
fixed_w = sum(display_width(f' {i} {v}') for i, v, _ in stat_elems[1:])
model_budget = max(1, inner - display_width(ico['model']) - 1 - fixed_w)
model_disp   = trunc_text(model, model_budget)
stat_elems[0] = (ico['model'], model_disp, col['model'])

if rtl:
    parts = [f'{c(col)}{val}{RST} {icon}' for icon, val, col in reversed(stat_elems)]
else:
    parts = [f'{icon} {c(col)}{val}{RST}' for icon, val, col in stat_elems]
stats = ' '.join(parts)

# ── Widget renderer ────────────────────────────────────────────────────────────

def render_widget(w):
    icon   = w.get('icon', '')
    color  = ANSI.get(w.get('color', ''), '')
    prefix = f'{icon} ' if icon else ''

    if 'command' in w:
        try:
            out = subprocess.run(
                w['command'], shell=True, capture_output=True, text=True, timeout=5
            ).stdout.strip()
            result = out.splitlines()[0] if out else ''
        except Exception:
            result = ''
    elif 'text' in w:
        result = str(w['text'])
    elif 'field' in w:
        val = data
        for key in str(w['field']).split('.'):
            val = val.get(key, '') if isinstance(val, dict) else ''
        result = str(val) if val else ''
    else:
        result = ''

    return f'{prefix}{color}{result}{RST}' if result else ''

# ── Assemble lines in configured order ────────────────────────────────────────

output_lines = []
for entry in cfg['lines']:
    if isinstance(entry, dict):
        line = render_widget(entry)
        if line:
            output_lines.append(line)
    elif entry == 'session':
        output_lines.append(session)
    elif entry == 'starship':
        output_lines.extend(starship_lines)
    elif entry == 'stats':
        output_lines.append(stats)

# ── Print ──────────────────────────────────────────────────────────────────────

if cfg['box']:
    border = '─' * inner
    print('┌' + border + '┐')
    for idx, line in enumerate(output_lines):
        print('│' + ansi_trunc_pad(line, inner, seed=(tick, idx), rtl=rtl) + '│')
    print('└' + border + '┘')
else:
    for idx, line in enumerate(output_lines):
        print(ansi_trunc_pad(line, inner, seed=(tick, idx), rtl=rtl))
