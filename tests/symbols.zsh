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
	local expanded

	expanded=$(expand_prompt 'psvar[14]=main; psvar[20]=venv; psvar[13]=1')
	assert_contains "$expanded" $'\e[38;5;242mmain' "branch should have no symbol by default" || return
	assert_contains "$expanded" $'\e[38;5;242mvenv' "virtualenv should have no symbol by default" || return

	expanded=$(expand_prompt 'psvar[14]=main; zstyle :prompt:pure:git:branch symbol "B "; zstyle :prompt:pure:git:branch italic yes')
	assert_contains "$expanded" $'B \e[3mmain' "branch symbol should come before the branch and outside italic" || return

	expanded=$(expand_prompt 'psvar[20]=venv; zstyle :prompt:pure:environment:virtualenv symbol "V "')
	assert_contains "$expanded" 'V venv' "virtualenv symbol should come before the name" || return

	expanded=$(expand_prompt 'psvar[13]=1; zstyle :prompt:pure:host symbol "H "')
	assert_contains "$expanded" "H "$'\e[39m\e[38;5;242m'"${(%):-%n}" "host symbol should come before the username" || return

	expanded=$(expand_prompt 'psvar[14]=main; zstyle :prompt:pure:git:branch symbol "100%"')
	assert_contains "$expanded" '100%main' "a percent sign in a symbol should show as is" || return

	print -- "symbols tests passed"
}

main "$@"
