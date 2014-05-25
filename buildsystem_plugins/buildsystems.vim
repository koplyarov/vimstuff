function BuildSystemException(msg)
	return 'Build system exception: '.a:msg
endf


function SetMakePrg(newMakePrg)
	let old_makeprg = &makeprg
	let &makeprg = a:newMakePrg
	return old_makeprg
endf


function BuildSettings()
	let self = {}

	function self.getBuildConfig()
		return self._config.getValue('buildConfig')
	endf

	function self.setBuildConfig(buildConfig)
		call self._config.setValue('buildConfig', a:buildConfig)
	endf

	function self.getBuildTarget()
		return self._config.getValue('buildTarget')
	endf

	function self.setBuildTarget(buildTarget)
		call self._config.setValue('buildTarget', a:buildTarget)
	endf

	function self.getSaveBeforeBuild()
		return self._config.getValue('saveBeforeBuild')
	endf

	function self.setSaveBeforeBuild(enable)
		if (type(a:enable) != type(0))
			throw CMakeException('Invalid argument type (must be integer)!')
		end
		call self._config.setValue('saveBeforeBuild', a:enable)
	endf

	let self._config = Config('.buildSettings', { 'buildConfig': 'default', 'buildTarget': '', 'saveBeforeBuild': 0 })

	return self
endf


runtime buildsystem_plugins/cmake.vim
runtime buildsystem_plugins/make.vim


function BuildSystem(backend, buildSettings)
	let self = {}

	function self._doBuild(func, params)
		if self._settings.getSaveBeforeBuild()
			wa
		end

		try
			call call(a:func, a:params, self._backend)
		finally
			let win_num = winnr()
			cw
			exe win_num."wincmd w"
			redraw!
			call Notify('vimstuff.BuildSystem', 'Build finished, '.(empty(filter(getqflist(), 'v:val.valid')) ? 'no' : 'there are some').' errors or warnings.')
		endtry
	endf

	if has_key(a:backend, 'buildFile')
		function self.buildFile(filename)
			if !filereadable(a:filename)
				return
			end
			call self._doBuild(self._backend.buildFile, [a:filename])
		endf
	end

	if has_key(a:backend, 'build')
		function self.build(target)
			call self._doBuild(self._backend.build, [a:target])
		endf
	end

	if has_key(a:backend, 'buildAll')
		function self.buildAll()
			call self._doBuild(self._backend.buildAll, [])
		endf
	end

	function self.getTargets()
		return has_key(self._backend, 'getTargets') ? self._backend.getTargets() : []
	endf

	function self.getAvailableBuildConfigs()
		return has_key(self._backend, 'getAvailableBuildConfigs') ? self._backend.getAvailableBuildConfigs() : []
	endf

	function self.setAvailableBuildConfigs(configs)
		if !has_key(self._backend, 'setAvailableBuildConfigs')
			throw BuildSystemException('This backend does not support setting build configs!')
		end
		call self._backend.setAvailableBuildConfigs(a:configs)
	endf

	let self._backend = a:backend
	let self._settings = a:buildSettings

	return self
endf


function DetectBuildSystem()
	let g:buildSettings = BuildSettings()

	if filereadable('CMakeLists.txt')
		let g:buildsystem = BuildSystem(CMakeBuildSystem(g:buildSettings), g:buildSettings)
	elseif filereadable('Makefile')
		let g:buildsystem = BuildSystem(MakeBuildSystem(g:buildSettings), g:buildSettings)
	end

	if !exists('g:buildsystem')
		return
	end

	if has_key(g:buildsystem, 'buildFile')
		call MapKeys('buildsystem.buildFile', 'nmap <silent>', ":call g:buildsystem.buildFile('<C-R>%')<CR>")
	end

	if has_key(g:buildsystem, 'build')
		call MapKeys('buildsystem.build', 'nmap <silent>', ':call g:buildsystem.build(g:buildSettings.getBuildTarget())<CR>')
	end

	if has_key(g:buildsystem, 'buildAll')
		call MapKeys('buildsystem.buildAll', 'nmap <silent>', ':call g:buildsystem.buildAll()<CR>')
	end

	if has_key(g:buildsystem, 'patchQuickFix')
		au QuickfixCmdPost make nested if g:buildsystem.patchQuickFix() | silent! cn | cw | else | ccl | end
	end
endf


function s:GetBuildConfigNames(A, L, P)
	return join(keys(g:buildsystem.getAvailableBuildConfigs()), "\n")
endf

function s:BuildPlatform(platform)
	if !has_key(g:buildsystem.getAvailableBuildConfigs(), a:platform)
		throw BuildSystemException('Platform '.a:platform.' not found!')
	end
	call g:buildSettings.setBuildConfig(a:platform)
endf

function s:GetBuildTargets(A, L, P)
	return join(g:buildsystem.getTargets(), "\n")
endf

function s:BuildTarget(target)
	call g:buildSettings.setBuildTarget(a:target)
endf

command! -nargs=1 -complete=custom,<SID>GetBuildConfigNames BuildPlatform call <SID>BuildPlatform('<args>')
command! -nargs=? -complete=custom,<SID>GetBuildTargets BuildTarget call <SID>BuildTarget('<args>')
command! -nargs=? -complete=custom,<SID>GetBuildTargets Build call g:buildsystem.build('<args>')
command! -nargs=1 BuildEnableSaveBeforeBuild call g:buildSettings.setSaveBeforeBuild(<args>)

call DetectBuildSystem()
