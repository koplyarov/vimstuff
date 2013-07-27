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


function CTagsSymbolInfo(indexer, rawTag, symbolDelimiter)
	if !exists('s:CTagsSymbolInfo')
		let s:CTagsSymbolInfo = {}

		function s:CTagsSymbolInfo.getParent()
			let scope = self.getScope()
			if empty(scope)
				return {}
			end
			let symbols = self._indexer.matchSymbols('^'.join(scope, self._symbolDelimiter).'$')
			if len(symbols) != 1
				return {}
			end
			return symbols[0]
		endf

		function s:CTagsSymbolInfo.getBase()
			let base = []
			if has_key(self._rawTag, 'inherits')
				let base = split(self._rawTag['inherits'], ',')
			end
			let result = []
			for b in base
				let scope = self.getScope()
				while 1
					let tag_to_search = join(scope, self._symbolDelimiter)
					let tag_to_search .= (empty(tag_to_search) ? '' : self._symbolDelimiter).b
					let symbols = self._indexer.matchSymbols('^'.tag_to_search.'$')
					let got_match = 0
					for s in symbols
						let s_scope = s.getScope()
						if s_scope == scope + split(b, self._escSymbolDelimiter)[:-2]
							let got_match = 1
							call add(result, s)
							break
						end
					endfor
					if got_match || len(scope) == 0
						break
					end
					call remove(scope, -1)
				endw
			endfor
			return result
		endf

		function s:CTagsSymbolInfo.getDerived()
			let scope = self.getScope()
			let name = split(self._rawTag['name'], self._escSymbolDelimiter)[-1]
			let grep_result = split(system('grep ''\<inherits:\S*\<'.name.'\>'' tags | sed -n ''s/^\(\S*\)\s.*$/\1/p'''), '\n')
			let suitable_kinds = [ 'c', 's' ]
			let tags = map(copy(grep_result), 'filter(self._indexer.matchSymbols("^".v:val."$"), "index(suitable_kinds, v:val._rawTag[''kind'']) != -1")[0]')
			" Removing duplicates
			let dict = {}
			for t in tags
				let key = t._rawTag['filename'].':'.t._rawTag['cmd']
				if has_key(dict, key) && strlen(dict[key]._rawTag['name']) > strlen(t._rawTag['name'])
					continue
				end
				let dict[key] = t
			endfor
			let tags = values(dict)
			let result = []
			for t in tags
				let inherits = split(t._rawTag['inherits'], ',')
				for i in inherits
					let i_scope = split(i, self._escSymbolDelimiter)
					call remove(i_scope, -1)
					let got_match = 0
					let t_scope = t.getScope()
					while 1
						let scope_to_check = t_scope + i_scope
						if scope[0 : len(scope_to_check) - 1] == scope_to_check
							call add(result, t)
							let got_match = 1
							break
						end
						if len(t_scope) <= len(i_scope)
							break
						end
						call remove(t_scope, -1)
					endw
					if got_match
						break
					end
				endfor
			endfor
			return result
		endf

		function s:CTagsSymbolInfo.addToQuickFix()
			let cmd = self._rawTag['cmd']
			if cmd[0] != '/'
				throw CTagsPluginException('unexpected ctags cmd syntax: '.cmd)
			end
			let cmd = '/\M'.cmd[1:]
			exec 'silent vimgrepadd '.cmd.' '.self._rawTag['filename']
		endf

		function s:CTagsSymbolInfo.getScope()
			for key in ['namespace', 'struct', 'class']
				if has_key(self._rawTag, key)
					return split(self._rawTag[key], self._escSymbolDelimiter)
				end
			endfor
			return []
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
	let self._indexer = a:indexer
	let self._rawTag = a:rawTag
	let self._symbolDelimiter = a:symbolDelimiter
	let self._escSymbolDelimiter = escape(self._symbolDelimiter, '&*./\')
	return self
endf


function CTagsIndexBuilder()
	if !exists('s:CTagsIndexBuilder')
		let s:CTagsIndexBuilder = {}

		function s:CTagsIndexBuilder.canUpdate()
			call system('which ctags')
			return v:shell_error == 0 && (!filereadable('tags') || filewritable('tags') == 1)
		endf

		function s:CTagsIndexBuilder.exclude(pathsList)
			let self._excludes += a:pathsList
		endf

		function s:CTagsIndexBuilder.addCustomLanguage(language, extension)
			if has_key(self._customLanguages, a:language)
				throw CTagsPluginException('language '.a:language.' already registered!')
			end
			let self._customLanguages[a:language] = a:extension
		endf

		function s:CTagsIndexBuilder.addCustomRegex(language, regex)
			if !has_key(self._customRegexes, a:language)
				let self._customRegexes[a:language] = []
			end
			call add(self._customRegexes[a:language], a:regex)
		endf

		function s:CTagsIndexBuilder._getInvokeCtagsCmd(flags, path, tagsFile)
			let excludes_str = join(map(copy(self._excludes), '"--exclude=".v:val'), ' ')
			let langs_str = join(values(map(copy(self._customLanguages), '"--langdef=".v:key." --langmap=".v:key.":".self._customLanguages[v:key]')), ' ')
			let regexes_str = join(values(map(copy(self._customRegexes), 'join(map(copy(self._customRegexes[v:key]), "\"--regex-".v:key."=''\".v:val.\"''\""), " ")')), ' ')
			return 'ctags '.a:flags.' --fields=+ail '.excludes_str.' --extra=+q -f '.a:tagsFile.' '.shellescape(a:path)
		endf

		function s:CTagsIndexBuilder.rebuildIfNecessary()
			if self.canUpdate() && !filereadable('tags')
				for update in self._asyncUpdates
					let update = self._asyncUpdates[0]
					if empty(update.name)
						return " Already rebuilding
					end
				endfor

				return self.rebuildIndex()
			end
		endf

		function s:CTagsIndexBuilder.syncRebuildIfNecessary()
			call self.rebuildIfNecessary()
			call self.waitForLastRebuildToComplete()
		endf

		function s:CTagsIndexBuilder.rebuildIndex()
			if !self.canUpdate()
				return 0
			end

			call self._update('')
			return 1
		endf

		function s:CTagsIndexBuilder.waitForLastRebuildToComplete()
			for update in self._asyncUpdates
				let update = self._asyncUpdates[0]
				if empty(update.name)
					echo 'Rebuilding ctags...'
					while empty(update.process) || !update.process.isTerminated()
						sleep 100m
					endw
					redraw!
					return
				end
			endfor
		endf

		function s:CTagsIndexBuilder.updateForFile(filename)
			if self.rebuildIfNecessary()
				return
			end

			call self._update(a:filename)
		endf

		function s:CTagsIndexBuilder._update(filename)
			while !empty(self._asyncUpdates)
				let update = self._asyncUpdates[0]
				if empty(update.process) || !update.process.isTerminated()
					if !empty(a:filename) && update.name != a:filename
						break
					end
					call update.process.terminate()
				end
				call remove(self._asyncUpdates, 0)
			endw

			let process = {}
			if empty(a:filename)
				let cmd = self._getInvokeCtagsCmd('-R', './', 'tags')
			else
				let cmd = 'grep -v ''^\S*\s\(\.\/\)\?'.escape(a:filename, '.*/\$^[]&').''' tags > tags.new && '.self._getInvokeCtagsCmd('-a', Relpath(a:filename), 'tags.new').' && mv tags.new tags'
			end

			if empty(self._asyncUpdates)
				let process = AsyncShell(cmd)
				let cmd = ''
			end

			let asyncUpdate = { 'name': a:filename, 'process': process, 'cmd': cmd }
			call add(self._asyncUpdates, asyncUpdate)
		endf

		function s:CTagsIndexBuilder._onTimerTick()
			call self.rebuildIfNecessary()
			while !empty(self._asyncUpdates)
				let update = self._asyncUpdates[0]
				if empty(update.process)
					let update.process = AsyncShell(update.cmd)
					let update.cmd = ''
					break
				end
				if !update.process.isTerminated()
					break
				end
				call remove(self._asyncUpdates, 0)
			endw
		endf
	end

	let self = copy(s:CTagsIndexBuilder)
	let self._excludes = [ '*CMakeFiles*', '*doxygen*', '*.git*', '*.svn*' ]
	let self._customLanguages = {}
	let self._customRegexes = {}
	let self._asyncUpdates = []
	let self._timerHandlerId = g:timer.addHandler(self._onTimerTick, self)
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
			return CTagsSymbolInfo(self, a:tag, self._syntax.symbolDelimiter)
		endf

		function s:CTagsIndexer.getSymbolInfoAtLocation(symbol, location)
			call self.builder.syncRebuildIfNecessary()
			let ctx = a:location.getLocationPath().getTagRegex()
			let tags = []
			while 1
				let tags += taglist('^'.join(ctx + [a:symbol.'$'], self._syntax.symbolDelimiter))
				if len(ctx) == 0
					break
				end
				call remove(ctx, -1)
			endw
			if !empty(tags)
				return self._createSymbolInfo(tags[0])
			end
			return {}
		endf

		function s:CTagsIndexer.matchSymbols(str)
			call self.builder.syncRebuildIfNecessary()
			return map(taglist(a:str), 'self._createSymbolInfo(v:val)')
		endf

		function s:CTagsIndexer.getImport(symbol)
			call self.builder.syncRebuildIfNecessary()

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

		let s:CTagsIndexer.builder = CTagsIndexBuilder()
	end

	let self = copy(s:CTagsIndexer)
	let self._syntax = a:langPlugin.syntax
	let self._langPlugin = a:langPlugin
	let self._frameworks = []
	return self
endf
