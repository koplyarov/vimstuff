function CMakeBuildSystem()
	let self = {}

	function self.buildFile(filename)
		exec 'make '.Relpath(a:filename).'.o'
	endf

	function self.buildAll()
		make
	endf

	return self
endf

let g:cmake_buildsystem = CMakeBuildSystem()
