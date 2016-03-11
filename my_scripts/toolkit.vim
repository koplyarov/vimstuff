function VimStuffException(msg)
	return 'VimStuff: '.a:msg
endf

function NotImplementedException()
	return VimStuffException('Not implemented!')
endf

function IsOnACPower()
	call system("on_ac_power")
	if v:shell_error == 0
		return 1
	elseif v:shell_error == 1
		return 0
	else
		if filereadable('/sys/class/power_supply/AC0/online')
			let ac_online = readfile('/sys/class/power_supply/AC0/online')
			if len(ac_online) == 1
				return eval(ac_online[0]);
			end
		end
		return 1
	end
endf

function GetCPUsCount()
	let res = system("nproc")
	if v:shell_error != 0
		return 1
	end
	return eval(StripString(res))
endf

function Notify(title, msg)
	call system('notify-send '.shellescape(a:title).' '.shellescape(a:msg))
endf

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
    return substitute(a:s, '^\%(\s\|\n\)*\(.\{-}\)\%(\s\|\n\)*$', '\1', '')
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
	return fnamemodify(a:filename, ':p:.')
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


function PathComplete(paths, pathBegin, findstart, base)
	let path_start = getline('.')[a:pathBegin - 1 : max([col('.') - 2, 0])]
	let last_slash_pos = strridx(path_start, '/')

	if a:findstart
		return a:pathBegin + last_slash_pos
	else
		let path_dir = path_start[0 : last_slash_pos - 1]
		let paths = filter(copy(a:paths), 'isdirectory(v:val."/".path_dir)')
		let result = []
		for po in paths
			let glob_list = split(globpath(po.'/'.path_dir, a:base.'*'), '\n')
			call map(glob_list, '{ "word": split(v:val, "/")[-1], "menu": isdirectory(v:val) ? "dir" : "file" }')
			let result += glob_list
		endfor
		return result
	end
endf

function HasSilverSearcher()
	call system('which ag')
	return v:shell_error == 0
endf

function PerlGrep(expression)
	if HasSilverSearcher()
		call setqflist([])
		"let ag_res = systemlist("ag '".expression."'")
		let old_grepprg=&grepprg
		let old_grepformat=&grepformat
		try
			set grepprg=ag
			set grepformat=%f:%l:%m
			execute "grep! '".a:expression."'"
		finally
			let &grepprg=old_grepprg
			let &grepformat=old_grepformat
		endtry
	else
		let excludes_list = ["*map", "*tex", "*html", "*git*", "*doxygen*", "*svn*", "*entries", "*all-wcprops", "depend*", "*includecache", "tags", "valgrind*", "types_*.taghl", "types_*.vim"]
		if exists("g:exclude_from_search")
			let excludes_list += g:exclude_from_search
		end
		let excludedirs_list = ["etc", "build", ".git", "CMakeFiles", ".svn", "doxygen", "toolchains"]
		let excludes_string = "--exclude=\"" . join(excludes_list, "\" --exclude=\"") . "\" --exclude-dir=\"" . join(excludedirs_list, "\" --exclude-dir=\"") . "\""
		execute "grep! -P " . excludes_string . " -rI \"" . a:expression . "\" ./"
	end
endf
