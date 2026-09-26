#!/usr/bin/env zsh

source "${0:A:h}/test-helper.zsh"

main() {
	# Set up colors like prompt_pure_setup would.
	typeset -gA prompt_pure_colors=(
		custom:prefix        242
		custom:suffix        242
		execution_time       yellow
		git:arrow            cyan
		git:stash            cyan
		git:branch           242
		git:branch:cached    red
		git:action           yellow
		git:dirty            218
		host                 242
		node_version         green
		path                 blue
		prompt:error         red
		prompt:success       magenta
		prompt:continuation  242
		result:fail          red
		result:pass          green
		suspended_jobs       red
		user                 242
		user:root            default
		virtualenv           242
	)
	typeset -gA prompt_pure_colors_default
	prompt_pure_colors_default=("${(@kv)prompt_pure_colors}")

	local output
	output=$(prompt_pure_preview 2>&1)

	for component in prefix suffix zaphod heartofgold "~/dev/pure" "main" "rebase-i" "42s" "[PASS]" "[FAIL] 1" "venv" "prompt after error" "continuation prompt" "root" "branch color when data is cached"; do
		if [[ $output != *"$component"* ]]; then
			print -u2 "Missing component in preview output: $component"
			return 1
		fi
	done

	zstyle ':prompt:pure:path' color red
	output=$(prompt_pure_preview 2>&1)

	if [[ $output != *$'\e[31m~/dev/pure'* ]]; then
		print -u2 "Preview did not apply zstyle path color."
		return 1
	fi

	zstyle ':prompt:pure:environment:node_version' symbol '⬡'
	output=$(prompt_pure_preview 2>&1)

	if [[ $output != *'⬡22'* ]]; then
		print -u2 "Preview did not apply zstyle Node.js symbol."
		return 1
	fi

	zstyle ':prompt:pure:path:separator' dim yes
	output=$(prompt_pure_preview 2>&1)

	if [[ $output != *$'\e[2m/\e[22m'* ]]; then
		print -u2 "Preview did not apply dimmed path separators."
		return 1
	fi

	zstyle ':prompt:pure:host' show no
	output=$(prompt_pure_preview 2>&1)

	if [[ $output == *'heartofgold'* ]]; then
		print -u2 "Preview should not show hostname when host display is disabled."
		return 1
	fi

	if [[ $output != *'zaphod'* ]]; then
		print -u2 "Preview should still show username when host display is disabled."
		return 1
	fi

	PURE_GIT_DOWN_ARROW='<-'
	PURE_GIT_UP_ARROW='->'
	zstyle ':prompt:pure:git:arrow' count yes
	output=$(prompt_pure_preview 2>&1)
	[[ $output == *'<-2->3'* ]] || {
		print -u2 -- "Preview should show configured arrows with counts."
		return 1
	}
	zstyle ':prompt:pure:git:diverged' symbol '<->'
	output=$(prompt_pure_preview 2>&1)
	[[ $output == *'<->'* && $output != *'<-2->3'* ]] || {
		print -u2 -- "Preview should use the divergence symbol instead of arrows."
		return 1
	}

	zstyle ':prompt:pure:git:branch' symbol '?. '
	zstyle ':prompt:pure:result:pass' symbol '[OK]%'
	zstyle ':prompt:pure:result:fail' symbol '[KO]%'
	zstyle ':prompt:pure:git:conflicts' symbol '<?>'
	zstyle ':prompt:pure:git:action:rebase-i' symbol '->'
	zstyle ':prompt:pure:git:stash' count yes
	zstyle ':prompt:pure:suspended_jobs' count yes
	PURE_PROMPT_SYMBOL='=>'
	PURE_PROMPT_ERROR_SYMBOL='!='
	output=$(prompt_pure_preview 2>&1)
	for component in '?. main' '[OK]%' '[KO]% 1' '<?> ->' '≡3' '✦2' '=>' '!='; do
		[[ $output == *"$component"* ]] || {
			print -u2 -- "Missing configured component in preview: $component"
			return 1
		}
	done

	psvar[14]=current-branch
	psvar[24]=current-result
	psvar[26]=current-symbol
	prompt_pure_preview >/dev/null
	assert_equal current-branch "$psvar[14]" "preview should preserve the live branch" || return
	assert_equal current-result "$psvar[24]" "preview should preserve the live result" || return
	assert_equal current-symbol "$psvar[26]" "preview should preserve the live symbol" || return

	print "preview tests passed."
}

main "$@"
