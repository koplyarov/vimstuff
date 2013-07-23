function CMakeBuildSystem()
	let self = {}

	function self.buildFile(filename)
		if !filereadable(a:filename)
			return
		end
		let dir = self._getSubdirectory(a:filename)
		let file = substitute(Relpath(a:filename), '^'.escape(dir, '&*./\^[]$').(strlen(dir) == 0 ? '' : '\/'), '', '')
		exec 'make -C '.dir.' '.file.'.o'
	endf

	function self.buildAll()
		make
	endf

	function self._getSubdirectory(path)
		let path = split(a:path, '/')
		while len(path) >= 0
			echo path
			if filereadable(join(path, '/').(len(path) > 0 ? '/' : '').'CMakeLists.txt')
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

let g:cmake_buildsystem = CMakeBuildSystem()
