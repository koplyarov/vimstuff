function CMakeBuildSystem()
	let self = {}

	function self.buildFile(filename)
		if !filereadable(a:filename)
			return
		end
		let dir = self._getSubdirectory(a:filename)
		let file = substitute(Relpath(a:filename), '^'.escape(dir, '&*./\^[]$').(strlen(dir) == 0 ? '' : '\/'), '', '')
		let self._buildDir = dir
		if !empty(dir)
			let dir = '-C '.dir
		end
		exec 'make '.dir.' '.file.'.o'
		unlet self._buildDir
	endf

	function self.buildAll()
		make
	endf

	function self._getSubdirectory(path)
		let path = split(a:path, '/')
		while len(path) >= 0
			if filereadable(join(path, '/').(len(path) > 0 ? '/' : '').'CMakeLists.txt')
				return join(path, '/')
			end
			if len(path) > 0
				call remove(path, -1)
			end
		endw
		return ''
	endf

	function self._getBuildDirFromMakePrg()
		let ml = matchlist(&makeprg, '-C \(\S*\)')
		if len(ml) > 1
			return ml[1].'/'
		else
			return ''
		end
	endf

	function self.patchQuickFix()
		let build_dir_from_makeprg = self._getBuildDirFromMakePrg()

		let has_entries = 0
		let subdirs_hint = {}

		let qflist = getqflist()
		for entry in qflist
			if has_key(entry, 'bufnr') && entry['bufnr'] != 0
				let has_entries = 1
			end
			if exists('*CustomQuickFixPatcher')
				if CustomQuickFixPatcher(entry)
					continue
				end
			end
			if has_key(entry, 'text') && entry['text'] =~ 'Building \S\+ object'
				let m = matchlist(entry['text'], 'Building \S\+ object \%(\(.*\)\/\)CMakeFiles\/.*\.dir\/\(.\+\)\.o$')
				let subdirs_hint[m[2]] = m[1]
			end
			if has_key(entry, 'bufnr') && entry['bufnr'] != 0
				let filename = bufname(entry['bufnr'])
				if !filereadable(filename)
					let dirs = (has_key(self, '_buildDir') ? [ self._buildDir ] : []) + self._subdirectories
					if has_key(subdirs_hint, filename)
						call insert(dirs, subdirs_hint[filename])
					end
					for dir in dirs
						let fn = build_dir_from_makeprg.dir.'/'.filename
						if filereadable(fn)
							let entry['bufnr']=bufnr(fn, 1)
							break
						end
					endfor
				end
			end
		endfor
		call setqflist(qflist, 'r')
		return has_entries
	endf

	let self._subdirectories = filter(map(split(glob('**/CMakeLists.txt'), '\n'), 'substitute(v:val, "\\/\\?CMakeLists\\.txt$", "", "")'), 'strlen(v:val) > 0')
	return self
endf

let g:cmake_buildsystem = CMakeBuildSystem()
