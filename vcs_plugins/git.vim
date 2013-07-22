function GitCommitInfo(hash)
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
			let out = system('git log --format='.a:format.' -n 1 '.self._hash)
			return split(out, '\n')[0]
		endf

		function s:GitCommitInfo.show()
			execute '!git show '.self.getId()
		endf
	end

	let self = s:GitCommitInfo
	let self._hash = a:hash
	return self
endf


function GitVcs()
	let self = VcsBase()

	function self.blame()
		let hash = matchstr(system('git blame -L '.line('.').','.line('.').' '.Relpath(@%)), '^\x*\ze\s')
		return GitCommitInfo(hash)
	endf

	return self
endf


let g:git_vcs = GitVcs()
