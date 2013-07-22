function VcsBase()
	if !exists('s:VcsBase')
		let s:VcsBase = {}
		
		function s:VcsBase.showBlameMsg()
			let commit = self.blame()
			echo commit.getId().': '.commit.getAuthor().' '.commit.getDate()
		endf
	end

	let self = copy(s:VcsBase)
	return self
endf
