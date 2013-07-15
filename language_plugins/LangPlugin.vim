function! LangPlugin()
	let self = {}

	function self.addImport(inc, include_priorities)
		if strlen(a:inc) == 0
			return
		end
		let include_line = self.syntax.getImportLine(a:inc)
		if search(self.syntax.getImportRegex(escape(a:inc, '&*./\')), 'bWn') != 0
			echo include_line.' already exists!'
			return
		end

		let includes_group = -1
		if exists('a:include_priorities')
			for i in range(0, len(a:include_priorities) - 1)
				if match(include_line, self.syntax.getImportRegex(a:include_priorities[i])) != -1
					let includes_group = i
					break
				end
			endfor
		end

		let save_cursor = getpos('.')

		let l = 0
		let insert_type = 0
		if includes_group != -1
			let l = search(self.syntax.getImportRegex(a:include_priorities[includes_group]), 'bW')
			if l == 0
				for i in range(includes_group + 1, len(a:include_priorities) - 1)
					normal gg
					let l = search(self.syntax.getImportRegex(a:include_priorities[i]), 'W')
					if l != 0
						let insert_type = 1
						break
					end
				endfor
			end
			if l == 0
				for i in range(0, includes_group - 1)
					normal G
					let l = search(self.syntax.getImportRegex(a:include_priorities[i]), 'bW')
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

	return self
endf
