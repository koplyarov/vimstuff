function! LangPlugin()
	let self = {}

	let self._frameworks = []

	function self.getFrameworks()
		return copy(self._frameworks)
	endf

	function self.registerFramework(framework)
		call add(self._frameworks, a:framework)
	endf

	function self.getImport(symbol)
		for fw in self.getFrameworks()
			if fw.hasSymbol(a:symbol)
				return fw.getImport(a:symbol)
			end
		endfor

		let s:langPlugin = self " =(

		function! MyCompare(t1, t2)
			return s:ns_obj.compareTags(s:langPlugin.parseTag(a:t1), s:langPlugin.parseTag(a:t2)) " =(
		endf

		let s:ns_obj = self.createLocation(getpos('.')).getLocationPath().getNamespace()
		let tags = self.filterImportableTags(taglist('\<'.a:symbol.'\>'))
		call sort(tags, 'MyCompare')
		let s:filenames = map(copy(tags), 'v:val["filename"]')
		let tags = filter(copy(tags), 'index(s:filenames, v:val["filename"], v:key + 1)==-1')

		if len(tags) == 0
			echo "No tags found!"
			return ''
		end

		if len(tags) == 1
			return self.getImportForTag(tags[0])
		end

		let ns = s:ns_obj.getRaw()
		let ns1 = self.parseTag(tags[0]).getScope()
		let ns2 = self.parseTag(tags[1]).getScope()
		if ns1 == ns && ns2 != ns
			return self.getImportForTag(tags[0])
		end
		if GetCommonSublistLen(ns1, ns) == len(ns) && GetCommonSublistLen(ns2, ns) != len(ns)
			return self.getImportForTag(tags[0])
		end
		if GetCommonSublistLen(ns1, ns) == len(ns1) && GetCommonSublistLen(ns2, ns) != len(ns2)
			return self.getImportForTag(tags[0])
		end

		let s:choices = []
		for t in tags
			call add(s:choices, self.getImportForTag(t))
		endfor

		function! ImportsComplete(A,L,P)
			return s:choices
		endf
		return input('Multiple tags found, make your choice: ', s:choices[0], 'customlist,ImportsComplete')
	endf

	function self.addImport(inc, import_priorities)
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

	function self.gotoSymbol(symbol)
		let tags = self.createLocation(getpos('.')).getTags(a:symbol)
		if len(tags) > 0
			call tags[0].goto()
		else
			call self.gotoLocalSymbol(a:symbol)
		end
	endf

	function self.openAlternativeFile(filename)
		silent execute 'e '.self.getAlternativeFile(a:filename)
	endf

	return self
endf
