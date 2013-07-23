function CTagsPluginException(msg)
	return "CTagsPluginException: ".a:msg
endf


function CTagsFrameworkInfo()
	if !exists('s:CTagsFrameworkInfo')
		let s:CTagsFrameworkInfo = {}

		function s:CTagsFrameworkInfo.addImports(packageStr, symbols)
			for s in a:symbols
				let self._symbols[s] = a:packageStr
			endfor
		endf

		function s:CTagsFrameworkInfo.hasSymbol(symbol)
			return has_key(self._symbols, a:symbol)
		endf

		function s:CTagsFrameworkInfo.getImport(symbol)
			return self._symbols[a:symbol]
		endf
	end

	let self = copy(s:CTagsFrameworkInfo)
	let self._symbols = {}
	return self
endf


function CTagsSymbolInfo(rawTag, symbolDelimiter)
	if !exists('s:CTagsSymbolInfo')
		let s:CTagsSymbolInfo = {}

		function s:CTagsSymbolInfo.getScope()
			for key in ['namespace', 'struct', 'class']
				if has_key(self._rawTag, key)
					return split(self._rawTag[key], escape(self._symbolDelimiter, '&*./\'))
				end
			endfor
			throw CTagsPluginException('unknown tag type!')
		endf

		function s:CTagsSymbolInfo.goto()
			execute 'edit '.Relpath(self._rawTag['filename'])
			let cmd = self._rawTag['cmd']
			if cmd[0] == '/'
				let cmd = '/\M' . strpart(cmd, 1)
			endif
			silent execute cmd
		endf

		function s:CTagsSymbolInfo.getFilename()
			return self._rawTag['filename']
		endf
	end

	let self = copy(s:CTagsSymbolInfo)
	let self._rawTag = a:rawTag
	let self._symbolDelimiter = a:symbolDelimiter
	return self
endf


function CTagsIndexer(langPlugin)
	if !exists('s:CTagsIndexer')
		let s:CTagsIndexer = {}

		function s:CTagsIndexer.getFrameworks()
			return deepcopy(self._frameworks)
		endf

		function s:CTagsIndexer.registerFramework(framework)
			call add(self._frameworks, a:framework)
		endf

		function s:CTagsIndexer._createSymbolInfo(tag)
			return CTagsSymbolInfo(a:tag, self._syntax.symbolDelimiter)
		endf

		function s:CTagsIndexer.getSymbolInfoAtLocation(symbol, location)
			let ctx = a:location.getLocationPath().getTagRegex()
			let tags = []
			while 1
				let tags += taglist('^'.join(ctx + [a:symbol.'$'], self._syntax.symbolDelimiter))
				if len(ctx) == 0
					break
				end
				call remove(ctx, -1)
			endw
			return map(tags, 'self._createSymbolInfo(v:val)')
		endf

		function s:CTagsIndexer.matchSymbols(str)
			return map(taglist(a:str), 'self._createSymbolInfo(v:val)')
		endf

		function s:CTagsIndexer.getImport(symbol)
			for fw in self.getFrameworks()
				if fw.hasSymbol(a:symbol)
					return fw.getImport(a:symbol)
				end
			endfor

			let ns_obj = self._langPlugin.createLocation(getpos('.')).getLocationPath().getNamespace()
			let tags = self._langPlugin.filterImportableSymbols(self.matchSymbols('\<'.a:symbol.'\>'))
			call sort(tags, ns_obj.compareSymbols, ns_obj)
			let s:filenames = map(copy(tags), 'v:val.getFilename()')
			let tags = filter(copy(tags), 'index(s:filenames, v:val.getFilename(), v:key + 1)==-1')

			if len(tags) == 0
				echo "No tags found!"
				return ''
			end

			if len(tags) == 1
				return self._langPlugin.getImportForSymbol(tags[0])
			end

			let ns = ns_obj.getRaw()
			let ns1 = tags[0].getScope()
			let ns2 = tags[1].getScope()
			if ns1 == ns && ns2 != ns
				return self._langPlugin.getImportForSymbol(tags[0])
			end
			if GetCommonSublistLen(ns1, ns) == len(ns) && GetCommonSublistLen(ns2, ns) != len(ns)
				return self._langPlugin.getImportForSymbol(tags[0])
			end
			if GetCommonSublistLen(ns1, ns) == len(ns1) && GetCommonSublistLen(ns2, ns) != len(ns2)
				return self._langPlugin.getImportForSymbol(tags[0])
			end

			let s:choices = map(tags, 'self._langPlugin.getImportForSymbol(v:val)')
			function! ImportsComplete(A,L,P)
				return s:choices
			endf
			return input('Multiple tags found, make your choice: ', s:choices[0], 'customlist,ImportsComplete')
		endf

		function s:CTagsIndexer.canUpdate()
			call system('which ctags')
			return v:shell_error == 0 && filewritable('tags') == 1
		endf

		function s:CTagsIndexer._invokeCtags(flags, path)
			let excludes = '--exclude=*CMakeFiles* --exclude=*doxygen*'
			call system('ctags '.a:flags.' --fields=+ail '.excludes.' --extra=+q '.a:path)
		endf

		function s:CTagsIndexer.rebuildIfNecessary()
			if !self.canUpdate() || filereadable('tags')
				return 0
			end

			call self._invokeCtags('-R', './')
			return 1
		endf

		function s:CTagsIndexer.updateForFile(filename)
			if self.rebuildIfNecessary()
				return
			end

			call system('sed -i ''/^\S*\s\(\.\/\)\?'.escape(a:filename, '.*/\$^[]&').'/d'' tags')
			call self._invokeCtags('-a', Relpath(a:filename))
			redraw!
		endf
	end

	let self = copy(s:CTagsIndexer)
	let self._syntax = a:langPlugin.syntax
	let self._langPlugin = a:langPlugin
	let self._frameworks = []
	return self
endf
