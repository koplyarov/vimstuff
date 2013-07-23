function GitCommitInfo(dir, hash)
	if !exists('s:GitCommitInfo')
		let s:GitCommitInfo = {}

		function s:GitCommitInfo.getAuthor()
			return self._gitLog('%an')
		endf

		function s:GitCommitInfo.getDate()
			return self._gitLog('%ad')
		endf

		function s:GitCommitInfo.getId()
			return self._hash
		endf

		function s:GitCommitInfo._gitLog(format)
			let out = system(self._cdCommand.'git log --format='.a:format.' -n 1 '.self._hash)
			return split(out, '\n')[0]
		endf

		function s:GitCommitInfo.show()
			execute '!'.self._cdCommand.'git show '.self.getId()
		endf
	end

	let self = s:GitCommitInfo
	let self._hash = a:hash
	let self._dir = a:dir
	let self._cdCommand = strlen(a:dir) > 0 ? 'cd '.a:dir.' && ' : ''
	return self
endf


function GitVcs()
	let self = VcsBase()

	function self.blame()
		let file= Relpath(@%)
		let dir = self._getSubrepo(file)
		let file = substitute(file, '^'.escape(dir, '&*./\^[]$').(strlen(dir) == 0 ? '' : '\/'), '', '')

		let hash = matchstr(system((strlen(dir) > 0 ? 'cd '.dir.' && ' : '').'git blame -L '.line('.').','.line('.').' '.file), '^\x*\ze\s')
		return GitCommitInfo(dir, hash)
	endf

	function self._getSubrepo(path)
		let path = split(a:path, '/')
		while len(path) >= 0
			if isdirectory(join(path, '/').(len(path) > 0 ? '/' : '').'.git')
				return join(path, '/')
			end
			if len(path) > 0
				call remove(path, -1)
			end
		endw
		return ''
	endf

	return self
endf


let g:git_vcs = GitVcs()
