#!/usr/bin/env zsh

source "${0:A:h}/test-helper.zsh"

main() {
	set +eu
	zmodload zsh/datetime

	prompt_pure_set_title() { : }
	prompt_pure_set_colors() { : }
	prompt_pure_async_tasks() { : }

	typeset -gA prompt_pure_vcs_info=(pwd '' top '')
	typeset -gA prompt_pure_state=(prompt '❯')

	(exit 1) || prompt_pure_precmd >/dev/null
	assert_equal '❯' "$prompt_pure_state[prompt]" "failure should keep the symbol when no error symbol is set" || return

	PURE_PROMPT_ERROR_SYMBOL='✗'
	(exit 1) || prompt_pure_precmd >/dev/null
	assert_equal '✗' "$prompt_pure_state[prompt]" "failure should show the error symbol" || return

	KEYMAP=vicmd prompt_pure_update_vim_prompt_widget
	assert_equal '❮' "$prompt_pure_state[prompt]" "vicmd mode should show the vicmd symbol after a failure" || return

	KEYMAP=viins prompt_pure_update_vim_prompt_widget
	assert_equal '✗' "$prompt_pure_state[prompt]" "insert mode should return to the error symbol" || return

	prompt_pure_reset_vim_prompt_widget
	assert_equal '✗' "$prompt_pure_state[prompt]" "line finish should keep the error symbol" || return

	prompt_pure_precmd >/dev/null
	assert_equal '❯' "$prompt_pure_state[prompt]" "success should show the normal symbol" || return

	KEYMAP=main prompt_pure_update_vim_prompt_widget
	assert_equal '❯' "$prompt_pure_state[prompt]" "insert mode after success should show the normal symbol" || return

	print -- "prompt-symbol tests passed"
}

main "$@"
