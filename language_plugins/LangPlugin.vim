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

			let includes_group = -1
			if len(a:import_priorities) > 0
				for i in range(0, len(a:import_priorities) - 1)
					if match(include_line, self.syntax.getImportRegex(a:import_priorities[i])) != -1
						let includes_group = i
						break
					end
				endfor
			end

			let save_cursor = getpos('.')

			let l = 0
			let insert_type = 0
			if includes_group != -1
				let l = search(self.syntax.getImportRegex(a:import_priorities[includes_group]), 'bW')
				if l == 0
					for i in range(includes_group + 1, len(a:import_priorities) - 1)
						normal gg
						let l = search(self.syntax.getImportRegex(a:import_priorities[i]), 'W')
						if l != 0
							let insert_type = 1
							break
						end
					endfor
				end
				if l == 0
					for i in range(0, includes_group - 1)
						normal G
						let l = search(self.syntax.getImportRegex(a:import_priorities[i]), 'bW')
						if l != 0
							let insert_type = -1
							break
						end
					endfor
				end
			end

			if l == 0
				call setpos('.', save_cursor)
				let l = search(self.syntax.getImportRegex('.*'), 'bW')
			end
			if l == 0
				call setpos('.', [save_cursor[0], 1, 1, save_cursor[3]])
				if strlen(getline(1)) != 0
					let l = search('^$', 'Wc')
				end
				call append(l, ['', include_line, ''])
				let lines_inserted = 3
			else
				if insert_type == 0
					call append(l, include_line)
					let lines_inserted = 1
					let b = search('^$', 'Wbcn')
					let e = search('^$', 'Wcn')
					call SortBuf(b + 1, e - 1)
				elseif insert_type == 1
					call append(l - 1, [include_line, ''])
					let lines_inserted = 2
				elseif insert_type == -1
					call append(l, ['', include_line])
					let lines_inserted = 2
				end
			end
			call setpos('.', [save_cursor[0], save_cursor[1] + lines_inserted, save_cursor[2], save_cursor[3]])
			for i in range(lines_inserted)
				normal! 
			endfor
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
			execute 'grep '.includes_string.' '.excludes_string.' -rIFw '''.a:symbolName.''' ./'
			let win_num = winnr()
			cw
			exe win_num."wincmd w"
		endf

		function s:LangPlugin.removeTrailingWhitespaces()
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
		call MapKeys('langPlugin.addImport', 'nmap <silent> <buffer>', ':call b:lang_plugin.addImport(b:lang_plugin.indexer.getImport(b:lang_plugin.getWordUnderCursor()), g:include_priorities)<CR>')
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
