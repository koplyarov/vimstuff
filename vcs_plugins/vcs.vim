runtime vcs_plugins/VcsBase.vim
runtime vcs_plugins/git.vim
runtime vcs_plugins/svn.vim

function DetectVcs()
	if isdirectory('.git')
		let g:vcs = g:git_vcs
	end

	if isdirectory('.svn')
		let g:vcs = g:svn_vcs
	end

	if !exists('g:vcs')
		return
	end

	command -nargs=0 VcsBlame call g:vcs.showBlameMsg()
	command -nargs=0 VcsShow call g:vcs.blame().show()

	call MapKeys('vcs.showCommit',	'nmap', ':VcsShow<CR>')
	call MapKeys('vcs.blame',		'nmap', ':VcsBlame<CR>')
endf

call DetectVcs()
