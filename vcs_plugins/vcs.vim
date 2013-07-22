runtime vcs_plugins/VcsBase.vim
runtime vcs_plugins/git.vim

function DetectVcs()
	if isdirectory('.git')
		let b:vcs = g:git_vcs
	end

	if !exists('b:vcs')
		return
	end

	command! -nargs=0 VcsBlame call b:vcs.showBlameMsg()
	command! -nargs=0 VcsShow call b:vcs.blame().show()
endf

au BufRead,BufNewFile *.* call DetectVcs()
