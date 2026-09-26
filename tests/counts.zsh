#!/usr/bin/env zsh

source "${0:A:h}/test-helper.zsh"

# Restore the real render function that test-helper.zsh stubs out.
source ./pure.zsh >/dev/null 2>&1 || :

arrows() {
	typeset -g REPLY=
	prompt_pure_check_git_arrows "$@" || :
}

main() {
	set +u
	zmodload zsh/parameter

	# ── Git arrows ──

	arrows 3 2
	assert_equal '⇣⇡' "$REPLY" "arrows should show without counts by default" || return

	zstyle ':prompt:pure:git:arrow' count yes
	arrows 3 2
	assert_equal '⇣2⇡3' "$REPLY" "arrows should show behind and ahead counts" || return
	arrows 1 0
	assert_equal '⇡1' "$REPLY" "only ahead should show one count" || return
	arrows 0 0
	assert_empty "$REPLY" "up to date should show nothing" || return

	zstyle ':prompt:pure:git:diverged' symbol '<->'
	arrows 3 2
	assert_equal '<->' "$REPLY" "diverged branch should show the diverged symbol" || return
	arrows 0 2
	assert_equal '⇣2' "$REPLY" "diverged symbol should not apply when only behind" || return
	zstyle -d ':prompt:pure:git:diverged' symbol
	zstyle -d ':prompt:pure:git:arrow' count

	# ── Stash and suspended jobs ──

	prompt_pure_reset_prompt() { : }
	typeset -gA prompt_pure_colors=()
	typeset -gA prompt_pure_state=(prompt '❯')
	typeset -gA prompt_pure_vcs_info=(branch '' action '')
	typeset -g prompt_pure_git_stash=4
	# Hide the read-only $jobstates special with fake jobs.
	local -hA jobstates=(1 'suspended:+:1=suspended' 2 'suspended:-:2=suspended' 3 'running::3=running')

	prompt_pure_preprompt_render
	assert_equal '≡' "$psvar[18]" "stash should show without count by default" || return
	assert_equal '✦' "$psvar[12]" "suspended jobs should show without count by default" || return

	zstyle ':prompt:pure:*' count yes
	prompt_pure_preprompt_render
	assert_equal '≡4' "$psvar[18]" "stash should show its count" || return
	assert_equal '✦2' "$psvar[12]" "suspended jobs should show their count, ignoring running jobs" || return

	print -- "counts tests passed"
}

main "$@"
