#!/usr/bin/env zsh

source "${0:A:h}/test-helper.zsh"

# Runs the result check as precmd would after a command with the given
# exit status and execution time.
check_result() {
	local exit_status=$1 exec_time=$2
	typeset -g prompt_pure_cmd_timestamp=$EPOCHSECONDS
	typeset -g prompt_pure_cmd_exec_time=$exec_time
	prompt_pure_check_cmd_result $exit_status
}

main() {
	set +u
	zmodload zsh/datetime

	# Disabled by default.
	check_result 1 ''
	assert_empty "$psvar[24]" "result should be hidden unless enabled" || return

	zstyle ':prompt:pure:result' show yes

	check_result 0 ''
	assert_empty "$psvar[24]" "fast success should show nothing" || return

	check_result 0 '42s'
	assert_equal '[PASS]' "$psvar[24]" "slow success should show pass" || return

	check_result 1 ''
	assert_equal '[FAIL] 1' "$psvar[24]" "failure should show fail with status" || return

	check_result 127 ''
	assert_equal '[ERROR] 127' "$psvar[24]" "command not found should show error" || return

	check_result 126 ''
	assert_equal '[ERROR] 126' "$psvar[24]" "not executable should show error" || return

	check_result $(( 128 + 9 )) ''
	assert_equal '[FATAL] SIGKILL' "$psvar[24]" "signal death should show fatal with signal name" || return

	check_result 130 ''
	assert_empty "$psvar[24]" "Ctrl-C should show nothing" || return

	check_result 255 ''
	assert_equal '[FAIL] 255' "$psvar[24]" "status above the signal range should show fail" || return

	# No command ran (empty line): preexec never set the timestamp.
	unset prompt_pure_cmd_timestamp
	prompt_pure_check_cmd_result 1
	assert_empty "$psvar[24]" "result should be hidden when no command ran" || return

	zstyle ':prompt:pure:result:pass' symbol '[OK]'
	zstyle ':prompt:pure:result:fail' symbol '[KO]'
	check_result 0 '42s'
	assert_equal '[OK]' "$psvar[24]" "pass symbol should be configurable" || return
	check_result 2 ''
	assert_equal '[KO] 2' "$psvar[24]" "fail symbol should be configurable" || return

	zstyle ':prompt:pure:result:fail' symbol ''
	check_result 2 ''
	assert_empty "$psvar[24]" "empty symbol should hide that result" || return
	zstyle -d ':prompt:pure:result:pass' symbol
	zstyle -d ':prompt:pure:result:fail' symbol

	# precmd must read the command's status before running anything else.
	prompt_pure_set_title() { : }
	prompt_pure_async_tasks() { : }
	prompt_pure_check_cmd_exec_time() { : }
	prompt_pure_set_colors() { : }
	typeset -gA prompt_pure_vcs_info=(pwd '' top '')
	typeset -gA prompt_pure_state=(prompt '❯')
	typeset -g prompt_pure_cmd_timestamp=$EPOCHSECONDS
	(exit 3) || prompt_pure_precmd >/dev/null
	assert_equal '[FAIL] 3' "$psvar[24]" "precmd should use the last command's exit status" || return

	# The tag renders in one color run: green after success, red after failure.
	local expanded
	expanded=$(command zsh -fc 'source ./pure.zsh >/dev/null 2>&1; psvar[24]="[FAIL] 3"; (exit 3) || print -r -- ${(S%%)PROMPT}')
	if [[ $expanded != *$'\e[31m[FAIL] 3'* ]]; then
		print -u2 -- "Assertion failed: failed result should render red in one color run"
		return 1
	fi
	expanded=$(command zsh -fc 'source ./pure.zsh >/dev/null 2>&1; psvar[24]="[PASS]"; print -r -- ${(S%%)PROMPT}')
	if [[ $expanded != *$'\e[32m[PASS]'* ]]; then
		print -u2 -- "Assertion failed: passed result should render green"
		return 1
	fi

	# The tag sits right before the execution time.
	local prompt_layout=$(command zsh -fc 'source ./pure.zsh >/dev/null 2>&1; print -r -- $PROMPT')
	local before_result=${prompt_layout%%"%(24V."*}
	local before_execution_time=${prompt_layout%%"%(19V."*}
	assert_equal 1 $(( ${#before_result} < ${#before_execution_time} )) "result should render before execution time" || return

	print -- "result tests passed"
}

main "$@"
