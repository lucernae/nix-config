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

# --- Line 1: starship info line ---
if [ -n "$current_dir" ]; then
    STARSHIP_SHELL=bash starship prompt --path "$current_dir" 2>/dev/null \
        | sed 's/\\\[//g; s/\\\]//g' \
        | grep . \
        | head -1
fi

# --- Git branch ---
branch=""
if [ -n "$current_dir" ]; then
    branch=$(git -C "$current_dir" symbolic-ref --short HEAD 2>/dev/null)
fi
if [ -z "$branch" ]; then
    branch=$(git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
fi
if [ -z "$branch" ]; then
    branch="(no git)"
fi

# --- Worktree tag ---
worktree_tag=""
if [ -n "$git_worktree" ]; then
    worktree_tag=" [worktree: $git_worktree]"
fi

# --- Session identifier ---
if [ -n "$session_name" ]; then
    # Show both name and short ID
    short_id=$(printf '%s' "$session_id" | cut -c1-8)
    session_part="session: $session_name ($short_id)"
else
    short_id=$(printf '%s' "$session_id" | cut -c1-8)
    session_part="$short_id"
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

# --- Assemble output (two lines, table-aligned) ---
printf '%-20s | %s\n' "$branch$worktree_tag" "$session_part"
printf '%-20s | %-12s | %s\n' "$model_part" "$cost_part" "$ctx_part"
