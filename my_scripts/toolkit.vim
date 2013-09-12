function Timer()
	if !exists('s:Timer')
		let s:Timer = {}

		function s:Timer._tick()
			for k in keys(self._handlers)
				let handler = self._handlers[k]
				call call(handler.func, handler.args, handler.dict)
			endfor
			call feedkeys("f\e")
		endf

		function s:Timer.addHandler(func, dict, ...)
			let started_at_key = self._keyGenerator
			while has_key(self._handlers, self._keyGenerator)
				let self._keyGenerator += 1
				if self._keyGenerator == started_at_key
					throw 'TimerException: too much handlers!'
				end
			endw

			let self._handlers[self._keyGenerator] = { 'func': a:func, 'dict': a:dict, 'args': a:000 }

			return self._keyGenerator
		endf

		function s:Timer.removeHandler(id)
			if has_key(self._handlers, id)
				unlet self._handlers[id]
			end
		endf
	end

	let self = copy(s:Timer)
	let self._handlers = {}
	let self._keyGenerator = 0
	return self
endf

let g:timer = Timer()

autocmd CursorHold * call g:timer._tick()


function StripString(s)
    return substitute(a:s, '^\s*\(.\{-}\)\s*$', '\1', '')
endf


function SortBuf(begin, end)
	if a:begin >= a:end
		return
	end
	let lines = getline(a:begin, a:end)
	call sort(lines)
	for i in range(a:end - a:begin + 1)
		call setline(a:begin + i, lines[i])
	endfor
endf


function! GetTextBetweenPositions(line1, col1, line2, col2)
	let lines = getline(a:line1, a:line2)
	if len(lines) == 0
		return ''
	end
	let lines[-1] = lines[-1][: a:col2 - 2]
	let lines[0] = lines[0][a:col1 - 1:]
	return join(lines, "\n")
endf


function! Relpath(filename)
	let cwd = getcwd()
	let s1 = substitute(a:filename, "^./" , "", "")
	let s2 = substitute(s1, l:cwd . "/" , "", "")
	return s2
endf


function! GetTabVar(tabnr, var)
	let current_tab = tabpagenr()
	let old_eventignore = &eventignore

	set eventignore=all
	exec "tabnext " . a:tabnr

	let got_result = 0
	if exists('t:' . a:var)
		exec 'let v = t:' . a:var
		let got_result = 1
	endif

	exec "tabnext " . current_tab
	let &ei = old_eventignore

	if got_result
		return {'value':v}
	else
		return {}
	end
endfunction


function! GetCommonSubstrLen(s1, s2)
	let i = 0
	for i in range(min([strlen(a:s1), strlen(a:s2)]))
		if a:s1[i] != a:s2[i]
			return i
		end
	endfor
	return i + 1
endf


function GetCommonSublistLen(l1, l2)
	let i = 0
	for i in range(min([len(a:l1), len(a:l2)]))
		if a:l1[i] != a:l2[i]
			return i
		end
	endfor
	return i + 1
endf

