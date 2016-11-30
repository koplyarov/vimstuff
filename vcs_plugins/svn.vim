function SvnCommitInfo(id)
	if !exists('s:SvnCommitInfo')
		let s:SvnCommitInfo = {}

		function s:SvnCommitInfo.getAuthor()
			return self._svnLog(2)
		endf

		function s:SvnCommitInfo.getDate()
			return self._svnLog(3)
		endf

		function s:SvnCommitInfo.getId()
			return self._id
		endf

		function s:SvnCommitInfo._svnLog(group)
			let out = system('svn log -r '.self._id)
			for l in split(out, '\n')
				let m = matchlist(l, '^r\(\d\+\)\s\+|\s\+\([^|]\+\)\s\+|\s\+\([^|]\+\)\s\+|')
				if empty(m)
					continue
				end
				return m[a:group]
			endfor
			throw 'Cannot parse svn log output'
		endf

		function s:SvnCommitInfo.show()
			if self.getId() <= 0
				throw 'Invalid revision id!'
			end

			call system('which colordiff')
			let has_colordiff = (v:shell_error == 0)
			call system('which less')
			let has_less = (v:shell_error == 0)

			execute '!svn diff'.(has_colordiff ? ' --diff-cmd=colordiff' : '').' -r '.(self.getId() - 1).':'.self.getId().(has_less ? '| less -R' : '')
		endf
	end

	let self = s:SvnCommitInfo
	let self._id = a:id
	return self
endf


function SvnVcs()
	let self = VcsBase()

	function self.blame()
		let file= Relpath(@%)

		let blame_data = split(system('svn ann '.file), '\n')
		let id = matchstr(blame_data[line('.') - 1], '^\d*\ze\s')
		return SvnCommitInfo(id)
	endf

	return self
endf


let g:svn_vcs = SvnVcs()
