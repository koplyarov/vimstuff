function s:MakeException(msg)
	return 'Make buildsystem error: '.a:msg
endf


function MakeBuildConfig(numThreads)
	return { 'numThreads': a:numThreads }
endf


function MakeBuildSystem(buildSettings)
	let self = {}

	function self.getTargets()
		let grep_result = split(system('grep "^[^ 	]\+:" '.self._makefile), "\n")
		return map(grep_result, 'substitute(v:val, ":.*$", "", "")')
	endf

	function self.buildAll()
		call self.build('')
	endf

	function self.build(target)
		let old_makeprg = SetMakePrg(self._getMakePrg())
		try
			silent exec 'make '.a:target
		finally
			let &makeprg = old_makeprg
		endtry
	endf

	function self._getMakePrg()
		let bc = self._getBuildConfigObj()
		return 'make -j'.string(bc.numThreads)
	endf

	function self._getBuildConfigObj()
		return copy(self._availableBuildConfigs[self._settings.getBuildConfig()])
	endf

	function self.getAvailableBuildConfigs()
		return copy(self._availableBuildConfigs)
	endf

	let self._availableBuildConfigs = { 'default': MakeBuildConfig(GetCPUsCount()) }
	let self._settings = a:buildSettings
	let self._makefile = 'Makefile'

	return self
endf
