function s:CMakeException(msg)
	return 'CMake buildsystem error: '.a:msg
endf


function CMakeBuildConfig(numThreads, buildDir)
	return { 'numThreads': a:numThreads, 'buildDir': a:buildDir }
endf


function CMakeMakeBackend()
	let self = {}

	function self.buildFile(buildSystem, subdirectory, filename)
		let a:buildSystem._buildDir = a:subdirectory
		let dir = empty(a:subdirectory) ? '' : '-C '.a:subdirectory
		silent exec 'make '.dir.' depend'
		exec 'make '.dir.' '.a:filename.'.o'
		unlet a:buildSystem._buildDir
	endf

	function self.build(target)
		exec 'make '.a:target
	endf

	function self.getMakePrg(buildConfig)
		let bc = a:buildConfig
		return 'make -j'.string(bc.numThreads).(empty(bc.buildDir) ? '' : ' -C '.bc.buildDir)
	endf

	function self.probe(buildConfig)
		let bc = a:buildConfig
		return filereadable((empty(bc.buildDir) ? '' : bc.buildDir.'/').'Makefile')
	endf

	return self
endf


function CMakeNinjaBackend()
	let self = {}

	function self.buildFile(buildSystem, subdirectory, filename)
		let dir = empty(a:subdirectory) ? '' : a:subdirectory.'/'
		let project = a:buildSystem.getProjectName(a:subdirectory).'.dir'
		exec 'make '.dir.'CMakeFiles/'.project.'/'.a:filename.'.o'
	endf

	function self.build(target)
		exec 'make '.a:target
	endf

	function self.getMakePrg(buildConfig)
		let bc = a:buildConfig
		return 'ninja -j'.string(bc.numThreads).(empty(bc.buildDir) ? '' : ' -C '.bc.buildDir)
	endf

	function self.probe(buildConfig)
		let bc = a:buildConfig
		return filereadable((empty(bc.buildDir) ? '' : bc.buildDir.'/').'build.ninja')
	endf

	return self
endf


function CMakeBuildSystem()
	let self = {}

	function self.buildFile(filename)
		if !filereadable(a:filename)
			return
		end

		let dir = self._getSubdirectory(a:filename)
		let file = substitute(Relpath(a:filename), '^'.escape(dir, '&*./\^[]$').(strlen(dir) == 0 ? '' : '\/'), '', '')

		let backend = self.getBackend()
		let old_makeprg = self._setMakePrg(backend.getMakePrg(self.getBuildConfigObj()))
		try
			call backend.buildFile(self, dir, file)
		finally
			let &makeprg = old_makeprg
		endtry
	endf

	function self.buildAll()
		call self.build('')
	endf

	function self.build(target)
		let backend = self.getBackend()
		let old_makeprg = self._setMakePrg(backend.getMakePrg(self.getBuildConfigObj()))
		try
			call backend.build(a:target)
		finally
			let &makeprg = old_makeprg
		endtry
	endf

	function self.getBuildConfigObj()
		return copy(self._availableBuildConfigs[self._buildConfig])
	endf

	function self.setBuildConfig(buildConfig)
		let self._buildConfig = a:buildConfig
		call writefile(['buildConfig: '.self._buildConfig], '.buildsystemSetup')
	endf

	function self._setMakePrg(newMakePrg)
		let old_makeprg = &makeprg
		let &makeprg = a:newMakePrg
		return old_makeprg
	endf

	function self.getProjectName(subdirectory)
		let cmake_file = (empty(a:subdirectory) ? '' : a:subdirectory.'/').'CMakeLists.txt'
		let grep_result = system('grep "^\s*project(\s*[^)]\+\s*)\s*$" '.shellescape(cmake_file))
		if v:shell_error != 0
			throw CMakeException('Could not find project name in '.cmake_file)
		end
		let grep_result = split(grep_result, '\n')[0]
		return substitute(grep_result, '^\s*project(\s*\([^) ]\+\)\s*)\s*$', '\1', '')
	endf

	function self.getBackend()
		let suitable_backends = filter(self._getBackends(), 'v:val.probe(self.getBuildConfigObj())')

		if empty(suitable_backends)
			throw CMakeException('Cannot detect CMake backend!')
		end

		if len(suitable_backends) > 1
			throw CMakeException('Found several suitable CMake backends!')
		end

		return suitable_backends[0]
	endf

	function self._getBackends()
		return copy(self._backends)
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
				if CustomQuickFixPatcher(self._getBuildDirFromMakePrg(), entry)
					continue
				end
			end
			if has_key(entry, 'text') && entry['text'] =~ 'Building \S\+ object'
				let m = matchlist(entry['text'], 'Building \S\+ object \%(\(.*\)\/\)\?CMakeFiles\/.*\.dir\/\(.\+\)\.o$')
				if len(m) == 3
					let subdirs_hint[m[2]] = m[1]
				end
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

	function self.getAvailableBuildConfigs()
		return copy(self._availableBuildConfigs)
	endf

	function self.setAvailableBuildConfigs(configs)
		let self._availableBuildConfigs = a:configs
		if !has_key(a:configs, self._buildConfig) && !empty(a:configs)
			call self.setBuildConfig(keys(a:configs)[0])
		end
	endf

	let self._subdirectories = filter(map(split(glob('**/CMakeLists.txt'), '\n'), 'substitute(v:val, "\\/\\?CMakeLists\\.txt$", "", "")'), 'strlen(v:val) > 0')
	let self._backends = [ CMakeMakeBackend(), CMakeNinjaBackend() ]
	let self._availableBuildConfigs = { 'default': CMakeBuildConfig(GetCPUsCount(), '') }

	let cfg = { 'buildConfig': 'default' }

	if filereadable('.buildsystemSetup')
		for l in readfile('.buildsystemSetup')
			let m = matchlist(l, '^\s*\([^: ]\+\)\s*:\s*\(.*\)$')
			let cfg[m[1]] = m[2]
		endfor
	end

	let self._buildConfig = cfg['buildConfig']

	return self
endf
