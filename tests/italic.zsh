#!/usr/bin/env zsh

source "${0:A:h}/test-helper.zsh"

# Prints the expanded prompt after running the given zsh code.
expand_prompt() {
	command zsh -fc "source ./pure.zsh >/dev/null 2>&1; $1; prompt_pure_set_colors; print -r -- \${(S%%)PROMPT}"
}

assert_contains() {
	local haystack=$1 needle=$2 message=$3
	if [[ $haystack != *"$needle"* ]]; then
		print -u2 -- "Assertion failed: $message"
		print -u2 -- "Actual: ${(q+)haystack}"
		return 1
	fi
}

main() {
	local italic=$'\e[3m' upright=$'\e[23m'
	local current_path=${(%):-%~}
	local expanded

	expanded=$(expand_prompt 'psvar[14]=main; psvar[16]=merge')
	if [[ $expanded == *$italic* ]]; then
		print -u2 -- "Assertion failed: nothing should be italic by default"
		return 1
	fi

	expanded=$(expand_prompt 'psvar[14]=main; psvar[15]="*"; zstyle :prompt:pure:git:branch italic yes')
	assert_contains "$expanded" "${italic}main${upright}" "branch should be italic when enabled" || return
	assert_contains "$expanded" $'\e[38;5;218m*' "dirty marker should stay upright" || return

	expanded=$(expand_prompt 'zstyle :prompt:pure:path italic yes')
	assert_contains "$expanded" "${italic}${current_path}${upright}" "path should be italic when enabled" || return

	expanded=$(expand_prompt 'zstyle :prompt:pure:path italic yes; zstyle :prompt:pure:path:separator dim yes')
	assert_contains "$expanded" "$italic" "dimmed path should be italic when enabled" || return
	assert_contains "$expanded" "$upright" "dimmed path should end italic" || return

	expanded=$(expand_prompt 'psvar[16]=merge; psvar[20]=venv; zstyle ":prompt:pure:*" italic yes')
	assert_contains "$expanded" "${italic}merge${upright}" "git action should be italic when enabled" || return
	assert_contains "$expanded" "${italic}venv${upright}" "virtualenv should be italic when enabled" || return

	print -- "italic tests passed"
}

main "$@"
