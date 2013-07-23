runtime vcs_plugins/VcsBase.vim
runtime vcs_plugins/git.vim

function DetectVcs()
	if isdirectory('.git')
		let g:vcs = g:git_vcs
	end

	if !exists('g:vcs')
		return
	end

	command -nargs=0 VcsBlame call g:vcs.showBlameMsg()
	command -nargs=0 VcsShow call g:vcs.blame().show()
endf

call DetectVcs()
