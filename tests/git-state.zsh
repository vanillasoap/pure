#!/usr/bin/env zsh

setopt clobber
set -euo pipefail

zmodload -F zsh/files b:zf_rm b:zf_mkdir

source "${0:A:h}/test-helper.zsh"

tmpdir="$PWD/.ai-temporary/git-state-test.$$"
zf_mkdir -p "$tmpdir"

cleanup() {
	zf_rm -rf -- "$tmpdir"
}
trap cleanup EXIT

git_quiet() {
	command git -c user.email=test@test.com -c user.name=Test "$@" >/dev/null 2>&1
}

read_vcs_info() {
	local output
	# vcs_info is not written for errexit.
	output=$(set +e; prompt_pure_async_vcs_info)
	typeset -gA info=("${(Q@)${(z)output}}")
}

check_conflicts() {
	prompt_pure_async_git_conflicts >/dev/null && typeset -g check_code=0 || typeset -g check_code=$?
}

# Renders the git state from the given action and flags.
render_state() {
	local action=$1 detached=$2 conflicts=$3
	typeset -gA prompt_pure_vcs_info=(action "$action" detached "$detached")
	typeset -g prompt_pure_git_conflicts=$conflicts
	prompt_pure_set_git_state
}

set +u
autoload -Uz vcs_info
zmodload zsh/datetime

# ── Detached HEAD detection ──

cd "$tmpdir"
command git init -q
echo "base" > file.txt
git_quiet add file.txt
git_quiet commit -m base

read_vcs_info
assert_empty "$info[detached]" "branch checkout should not be detached"

git_quiet checkout --detach
read_vcs_info
assert_equal 1 "$info[detached]" "detached checkout should be detected"
git_quiet checkout -

# Branch names are rendered through psvar, which does not expand prompt escapes.
local original_branch=$(command git symbolic-ref --short HEAD)
git_quiet checkout -b 'feature/100%done'
read_vcs_info
assert_equal 'feature/100%done' "$info[branch]" "branch names should retain literal percent signs"
psvar[14]=$info[branch]
assert_equal 'feature/100%done' "${(%):-%14v}" "the branch segment should render the name unchanged"
git_quiet checkout "$original_branch"

# ── Conflict detection ──

check_conflicts
assert_equal 0 $check_code "clean repo should have no conflicts"

echo "unstaged" > file.txt
check_conflicts
assert_equal 0 $check_code "unstaged changes should not count as conflicts"
command git checkout -q -- file.txt

git_quiet checkout -b other
echo "other" > file.txt
git_quiet commit -am other
git_quiet checkout -
echo "main" > file.txt
git_quiet commit -am main
git_quiet merge other || :
check_conflicts
assert_equal 1 $check_code "unresolved merge should report conflicts"

git_quiet add file.txt
check_conflicts
assert_equal 0 $check_code "resolved merge should have no conflicts"
git_quiet merge --abort || :

# ── Rendering ──

render_state '' '' ''
assert_empty "$psvar[16]" "no state should render nothing"

render_state bisect '' ''
assert_equal bisect "$psvar[16]" "actions should show as text by default"

zstyle ':prompt:pure:git:action:bisect' symbol '[BUG]'
render_state bisect '' ''
assert_equal '[BUG]' "$psvar[16]" "action symbol should replace the action text"
render_state rebase-i '' ''
assert_equal rebase-i "$psvar[16]" "actions without a symbol should stay as text"

render_state merge '' 1
assert_equal '[FIXME] merge' "$psvar[16]" "conflicts should show before the action"

zstyle ':prompt:pure:git:conflicts' symbol '!'
render_state merge '' 1
assert_equal '! merge' "$psvar[16]" "conflict symbol should be configurable"
zstyle -d ':prompt:pure:git:conflicts' symbol

render_state '' 1 ''
assert_empty "$psvar[16]" "detached HEAD should be hidden unless enabled"

zstyle ':prompt:pure:git:detached' show yes
render_state '' 1 ''
assert_equal '[WARN]' "$psvar[16]" "detached HEAD should show a warning when enabled"
render_state rebase-i 1 ''
assert_equal rebase-i "$psvar[16]" "an action should replace the detached warning"

zstyle ':prompt:pure:git:cached' show yes
render_state '' '' ''
assert_empty "$psvar[16]" "fresh git data should not show the cached warning"
typeset -g prompt_pure_git_last_dirty_check_timestamp=$EPOCHSECONDS
prompt_pure_set_git_state
assert_equal '[WARN]' "$psvar[16]" "stale git data should show the cached warning when enabled"
zstyle ':prompt:pure:git:cached' symbol '[TRACE]'
render_state merge 1 1
assert_equal '[FIXME] merge [TRACE]' "$psvar[16]" "all states should combine in order"

print "git-state tests passed"
