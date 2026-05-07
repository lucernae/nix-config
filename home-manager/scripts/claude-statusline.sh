#!/run/current-system/sw/bin/nix-shell
#!nix-shell -i bash -p jq git starship
# Claude Code status line script
# Reads JSON from stdin and outputs a compact status line.

input=$(cat)

# Extract fields from JSON
current_dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // empty')
git_worktree=$(printf '%s' "$input" | jq -r '.workspace.git_worktree // empty')
session_name=$(printf '%s' "$input" | jq -r '.session_name // empty')
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // empty')

# --- Lines 1 & 3: starship split at " via " ---
starship_main=""
starship_via=""
if [ -n "$current_dir" ]; then
    starship_raw=$(STARSHIP_SHELL=bash starship prompt --path "$current_dir" 2>/dev/null \
        | sed 's/\\\[//g; s/\\\]//g; s/\\\$/$/' \
        | grep . \
        | head -1)
    starship_main=$(printf '%s' "$starship_raw" | sed 's/ via .*//')
    starship_via=$(printf '%s' "$starship_raw" | sed -n 's/.* via /via /p')
fi

# --- Worktree tag ---
worktree_tag=""
if [ -n "$git_worktree" ]; then
    worktree_tag="[worktree: $git_worktree] "
fi

# --- Session identifier ---
short_id=$(printf '%s' "$session_id" | cut -c1-8)
if [ -n "$session_name" ]; then
    session_part=$(printf '🧵 \033[94m%s\033[0m · \033[38;5;208m%s\033[0m' "$session_name" "$short_id")
else
    session_part=$(printf '🧵 \033[38;5;208m%s\033[0m' "$short_id")
fi

# --- Model ---
model_part="${model:--}"

# --- Cost ---
if [ -n "$cost" ]; then
    cost_part="$(printf '$%.4f' "$cost")"
else
    cost_part='$-'
fi

# --- Context usage ---
if [ -n "$used_pct" ]; then
    ctx_part="ctx: $(printf '%.0f' "$used_pct")%"
else
    ctx_part="ctx: -"
fi

# --- Assemble output (four lines, table-aligned) ---
printf '%s%s\n' "$worktree_tag" "$session_part"
printf '%s\n' "$starship_main"
printf '%s\n' "$starship_via"
printf '%-20s | %-12s | %s\n' "$model_part" "$cost_part" "$ctx_part"
