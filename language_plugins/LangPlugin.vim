function Syntax()
	if !exists("s:Syntax")
		let s:Syntax = {}

		function s:Syntax.isKeyword(word)
			return index(self.keywords, a:word) != -1
		endf
	end

	let self = deepcopy(s:Syntax)

	let self.keywords = [ ]

	return self
endf


function AutocompleteSettings()
	if !exists('s:AutocompleteSettings')
		let s:AutocompleteSettings = {}

		function s:AutocompleteSettings.autoInvokeEnabled()
			return self._autoInvokeEnabled
		endf

		function s:AutocompleteSettings.enableAutoInvoke(enable)
			let self._autoInvokeEnabled = a:enable
		endf

		function s:AutocompleteSettings.getAutoInvokationKeys()
			return self._autoInvokationKeys
		endf

		function s:AutocompleteSettings.setAutoInvokationKeys(keys)
			let self._autoInvokationKeys = a:keys
		endf
	end

	let self = copy(s:AutocompleteSettings)
	let self._autoInvokeEnabled = 0
	let self._autoInvokationKeys = '\<C-N>'
	return self
endf


function s:ImportLine(line, import_regexes)
	if !exists('s:ImportLinePrototype')
		let s:ImportLinePrototype = {}

		function s:ImportLinePrototype.s_getGroupPriority(line, import_regexes)
			for i in range(0, len(a:import_regexes) - 1)
				if match(a:line, a:import_regexes[i]) != -1
					return i
				end
			endfor
			return len(a:import_regexes)
		endf
	end

	let self = deepcopy(s:ImportLinePrototype)
	let self.line = a:line
	let self.groupPriority = self.s_getGroupPriority(a:line, a:import_regexes)
	return self
endf


function s:ImportsComparer()
	if !exists('s:ImportsComparerPrototype')
		let s:ImportsComparerPrototype = {}

		function s:ImportsComparerPrototype.compare(l, r)
			if a:l.groupPriority == a:r.groupPriority
				return a:l.line == a:r.line ? 0 : a:l.line > a:r.line ? 1 : -1
			else
				return a:l.groupPriority > a:r.groupPriority ? 1 : -1
			end
		endf
	end

	let self = deepcopy(s:ImportsComparerPrototype)
	return self
endf


function LangPlugin()
	if !exists('s:LangPlugin')
		let s:LangPlugin = {}

		function s:LangPlugin.addImport(inc, import_priorities)
			if strlen(a:inc) == 0
				return
			end
			let include_line = self.syntax.getImportLine(a:inc)
			if search(self.syntax.getImportRegex(escape(a:inc, '&*./\')), 'bWn') != 0
				echo include_line.' already exists!'
				return
			end

			let imports_list = []
			let import_regexes = map(copy(a:import_priorities), 'self.syntax.getImportRegex(v:val)')

			let imports_search_begin = has_key(self, 'getImportsBeginLine') ? max([self.getImportsBeginLine(), 1]) : 1

			let whitespaces_count = 0
			let generic_import_re = self.syntax.getImportRegex('.*')
			for line_num in range(imports_search_begin, line('$'))
				let line = getline(line_num)
				if line =~ '^\s*$'
					let whitespaces_count += 1
					continue
				end
				if match(line, generic_import_re) != -1
					call add(imports_list, s:ImportLine(line, import_regexes))
					if exists('l:imports_begin')
						let imports_end = line_num + 1
					else
						let imports_begin = line_num - whitespaces_count
						let imports_end = line_num + 1
					end
				else
					break
				end
				let whitespaces_count = 0
			endfor

			if !exists('l:imports_begin')
				let imports_begin = imports_search_begin
				let imports_end = imports_begin
			end

			let imports_end += whitespaces_count

			call add(imports_list, s:ImportLine(include_line, import_regexes))

			let cmp = s:ImportsComparer()
			call sort(imports_list, cmp.compare, cmp)

			let import_lines = []

			let prev_group = -1
			for import in imports_list
				if prev_group != -1 && prev_group != import.groupPriority
					call add(import_lines, '')
				end
				call add(import_lines, import.line)
				let prev_group = import.groupPriority
			endfor

			let import_lines = (imports_begin != 1 ? repeat([''], self.whitespacesCountAroundImports) : []) + import_lines + repeat([''], self.whitespacesCountAroundImports)

			let lines_delta = len(import_lines) - (imports_end - imports_begin)
			let winview = winsaveview()
			if imports_begin != imports_end
				execute imports_begin.','.(imports_end - 1).'d _'
			end
			call append(imports_begin - 1, import_lines)
			let winview.lnum += lines_delta
			if winview.topline != 1
				let winview.topline += lines_delta
			end
			call winrestview(winview)

			redraw
			echo include_line
		endf

		function s:LangPlugin.gotoSymbol(symbol)
			if self.syntax.isKeyword(a:symbol)
				echo a:symbol.' is a keyword'
				return
			end
			let symbol = self.indexer.getSymbolInfoAtLocation(a:symbol, self.createLocation(getpos('.')))
			if !empty(symbol)
				call symbol.goto()
			else
				call self.gotoLocalSymbol(a:symbol)
			end
		endf

		function s:LangPlugin.searchDerived(symbol)
			if self.syntax.isKeyword(a:symbol)
				echo a:symbol.' is a keyword'
				return
			end
			let symbol_info = self.indexer.getSymbolInfoAtLocation(a:symbol, self.createLocation(getpos('.')))
			let derived = symbol_info.getDerived()
			if empty(derived)
				echo "Derived classes not found"
				return
			end
			cgetexpr ""
			for d in derived
				call d.addToQuickFix()
			endfor
			let win_num = winnr()
			cw
		endf

		function s:LangPlugin.getAlternativeFile(filename)
			if has_key(self, 'alternativeExtensionsMap')
				let substitute_ext = self.alternativeExtensionsMap
				for src in keys(substitute_ext)
					let regex = '\.'.src.'$'
					if a:filename =~ regex
						for dst in split(substitute_ext[src], ';')
							let alternative_filename = substitute(a:filename, regex, '.'.dst, '')
							if filereadable(alternative_filename)
								return alternative_filename
							end
						endfor
						return alternative_filename
					end
				endfor
			end
			return ''
		endf

		function s:LangPlugin.openAlternativeFile(filename)
			let alt_file = self.getAlternativeFile(a:filename)
			if !empty(alt_file)
				silent execute 'e '.alt_file
			end
		endf

		function s:LangPlugin.searchUsages(symbolName)
			if self.syntax.isKeyword(a:symbolName)
				echo a:symbolName.' is a keyword'
				return
			end
			" TODO: reimplement
			let includes_list = map(copy(self.fileExtensions), '"*.".v:val')
			let excludedirs_list = ["etc", "build", ".git", "CMakeFiles", ".svn"]
			let excludes_string = '--exclude-dir="' . join(excludedirs_list, '" --exclude-dir="') . '"'
			if exists("g:exclude_from_search")
				for e in g:exclude_from_search
					let excludes_string .= ' --exclude='.e
				endfor
			end
			let includes_string = '--include="' . join(includes_list, '" --include="')  . '"'
			execute 'grep! '.includes_string.' '.excludes_string.' -rIFw '''.a:symbolName.''' ./'
			let win_num = winnr()
			cw
			exe win_num."wincmd w"
		endf

		function s:LangPlugin.removeTrailingWhitespaces()
			if empty(filter(getline(1, '$'), 'v:val =~ "\\s\\+$"'))
				return
			end
			call setline(1, map(getline(1,'$'), 'substitute(v:val,"\\s\\+$","","")'))
		endf

		function s:LangPlugin.getWordUnderCursor()
			return expand('<cword>')
		endf

		function s:LangPlugin.openSymbolInNewTab(symbolName)
			tabnew
			execute "tag ".a:symbolName
		endf

		function s:LangPlugin.openSymbolPreview(symbolName)
			execute "ptj ".a:symbolName
		endf
	end

	let self = copy(s:LangPlugin)
	let self.autocompleteSettings = AutocompleteSettings()
	let self.whitespacesCountAroundImports = 2
	return self
endf


function ActivateLangPlugin(plugin)
	let b:lang_plugin = a:plugin

	if has_key(b:lang_plugin, 'getAlternativeFile')
		call MapKeys('langPlugin.openAlternativeFile', 'nmap <silent> <buffer>', ":call b:lang_plugin.openAlternativeFile('<C-R>%')<CR>")
	end

	if has_key(b:lang_plugin, 'fileExtensions')
		call MapKeys('langPlugin.searchUsages', 'nmap <silent> <buffer>', ':call b:lang_plugin.searchUsages(b:lang_plugin.getWordUnderCursor())<CR>')
	end

	call MapKeys('langPlugin.printScope',			'nmap <silent> <buffer>',	":echo b:lang_plugin.createLocation(getpos('.')).getLocationPath().toString()<CR>")
	call MapKeys('langPlugin.openSymbolInNewTab',	'nmap',						':call b:lang_plugin.openSymbolInNewTab(b:lang_plugin.getWordUnderCursor())<CR>')
	call MapKeys('langPlugin.openSymbolPreview',	'nmap',						':call b:lang_plugin.openSymbolPreview(b:lang_plugin.getWordUnderCursor())<CR>')

	if has_key(b:lang_plugin, 'indexer')
		call MapKeys('langPlugin.addImport', 'nmap <silent> <buffer>', ':call b:lang_plugin.addImport(b:lang_plugin.indexer.getImport(b:lang_plugin.getWordUnderCursor()), has_key(b:lang_plugin, "getImportPriorities") ? b:lang_plugin.getImportPriorities(expand("%")) : [])<CR>')
		call MapKeys('langPlugin.gotoSymbol', 'map <silent> <buffer>', ':call b:lang_plugin.gotoSymbol(b:lang_plugin.getWordUnderCursor())<CR>')
		nmap <silent> <buffer> <C-RightMouse> <LeftMouse>t<C-]>

		if has_key(b:lang_plugin.indexer, 'builder') && has_key(b:lang_plugin.indexer.builder, 'canUpdate') && b:lang_plugin.indexer.builder.canUpdate()
			au BufWritePost <buffer> call b:lang_plugin.indexer.builder.updateForFile(@%)
		end

		call MapKeys('langPlugin.searchDerived', 'nmap <buffer>', ':call b:lang_plugin.searchDerived(b:lang_plugin.getWordUnderCursor())<CR>')
	end

	if has_key(b:lang_plugin, 'autocompleteSettings')
		if b:lang_plugin.autocompleteSettings.autoInvokeEnabled()
			call EnableAutocompleteAutoTriggering(bufnr('%'), b:lang_plugin.autocompleteSettings.getAutoInvokationKeys())
		end
	end

	if has_key(b:lang_plugin, 'onActivated')
		call b:lang_plugin.onActivated()
	end
endf

command! -nargs=0 RebuildIndex call b:lang_plugin.indexer.builder.rebuildIndex()
