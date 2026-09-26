#!/usr/bin/env zsh

source "${0:A:h}/test-helper.zsh"

main() {
	set +eu
	zmodload zsh/datetime

	prompt_pure_set_title() { : }
	prompt_pure_async_tasks() { : }
	prompt_pure_check_cmd_exec_time() { : }
	prompt_pure_preprompt_render() { : }
	prompt_pure_set_colors() { : }

	# Record redraws instead of talking to a real line editor.
	typeset -gi redraws=0
	zle() {
		[[ $1 == .reset-prompt ]] && (( redraws++ ))
		return 0
	}

	typeset -gA prompt_pure_vcs_info=(pwd '' top '')
	typeset -gA prompt_pure_state=(prompt '❯')
	typeset -gA prompt_pure_colors=(prompt:success magenta prompt:error red)
	local full_prompt='%(22V.%22v .)preprompt${prompt_newline}%F{magenta}❯%f '
	PROMPT=$full_prompt
	CONTEXT=start

	prompt_pure_transient_prompt_widget
	assert_equal "$full_prompt" "$PROMPT" "prompt should stay full unless enabled" || return
	assert_equal 0 $redraws "prompt should not redraw unless enabled" || return

	zstyle ':prompt:pure:prompt' transient yes

	CONTEXT=vared prompt_pure_transient_prompt_widget
	assert_equal "$full_prompt" "$PROMPT" "prompt should stay full outside the main prompt" || return

	prompt_pure_transient_prompt_widget
	assert_equal 1 $redraws "accepted line should redraw the prompt" || return
	local expanded=${(S%%)PROMPT}
	assert_equal $'\e[35m❯\e[39m ' "$expanded" "accepted line should keep only the prompt symbol" || return

	(exit 1) || prompt_pure_transient_prompt_widget
	expanded=${(S%%)PROMPT}
	assert_equal $'\e[35m❯\e[39m ' "$expanded" "a second line finish should not collapse the transient prompt again" || return

	prompt_pure_precmd >/dev/null
	assert_equal "$full_prompt" "$PROMPT" "precmd should restore the full prompt" || return

	PROMPT=$full_prompt
	prompt_pure_transient_prompt_widget
	(exit 1) || expanded=${(S%%)PROMPT}
	assert_equal $'\e[31m❯\e[39m ' "$expanded" "transient prompt should use the error color after a failure" || return
	prompt_pure_precmd >/dev/null

	# Terminal prompt marks around the prompt (Ghostty, VS Code) must survive,
	# and the restored prompt must match exactly so the terminal can unwrap it.
	local mark_start=$'%{\e]133;A;cl=line\a%}' mark_end=$'%{\e]133;B\a%}'
	PROMPT=${mark_start}${full_prompt}${mark_end}
	prompt_pure_transient_prompt_widget
	[[ $PROMPT == ${mark_start}*${mark_end} && $PROMPT != *preprompt* ]]
	assert_equal 0 $? "transient prompt should keep the terminal prompt marks" || return
	prompt_pure_precmd >/dev/null
	assert_equal "${mark_start}${full_prompt}${mark_end}" "$PROMPT" "precmd should restore the marked prompt exactly" || return

	print -- "transient tests passed"
}

main "$@"
