function! GetCppNamespaceFromPath(path)
	return []
endfunction

autocmd User plugin-template-loaded call s:template_keywords()
function! s:template_keywords()
	%s/<+FILENAME+>/\=toupper(substitute(expand('%'), '[-.\/\\\\:]', '_', 'g'))/ge
	%s/<+FILENAME_MANGLED+>/\=toupper(substitute(expand('%'), '[-.\/\\\\:]', '_', 'g'))/ge
	%s/<+DATE+>/\=strftime('%Y-%m-%d')/ge
	let namespaces=GetCppNamespaceFromPath(split(Relpath(expand('%')), '/'))
	if len(namespaces) == 0
		g/<+NAMESPACES_OPEN+>/de
		g/<+NAMESPACES_CLOSE+>/de
	else
		let namespaces_string = ''
		for ns in namespaces
			if len(namespaces_string) > 0
				let namespaces_string .= " {\n"
			endif
			let namespaces_string .= 'namespace '.ns
		endfor
		let namespaces_string .= "\n{"
		%s/<+NAMESPACES_OPEN+>/\=namespaces_string/ge
		%s/<+NAMESPACES_CLOSE+>/\=repeat('}', len(namespaces))/ge
	endif
	silent %s/<%=\(.\{-}\)%>/\=eval(submatch(1))/ge
	if search('<+CURSOR+>')
		execute 'normal! "_da>'
	endif
	" And more...
endfunction

let g:clang_complete_auto=0
let g:clang_hl_errors=0
let g:clang_user_options='|| exit 0'

let g:c_std_includes = 'stdio\.h\|string\.h\|ctype.h\|cstdio\|cstring'
let g:cpp_std_includes = 'vector\|string\|set\|map\|list\|deque\|queue\|memory\|stdexcept\|iostream\|algorithm\|functional\|streambuf\|utility\|sstream\|fstream\|typeinfo'
let g:platform_includes = 'windows\.h\|wintypes\.h'

func! RemoveIncludeDirectory(filename)
	if exists('g:include_directories')
		for dir in g:include_directories
			if a:filename[0 : len(dir) - 1] == dir
				return a:filename[((a:filename[len(dir)] == '/') ? len(dir) + 1 : len(dir)):]
			end
		endfor
	end
	return a:filename
endf

function! GetHeaderFile(filename)
	let filename_str = ''
	if stridx(a:filename, ".cpp") != -1
		let filename_str = substitute(a:filename, "\\.cpp$", ".h", "")
		if !filereadable(filename_str)
			let filename_str = substitute(a:filename, "\\.cpp$", ".hpp", "")
		endif
	elseif stridx(a:filename, ".c") != -1
		let filename_str = substitute(a:filename, "\\.c$", ".h", "")
	endif
	return RemoveIncludeDirectory(filename_str)
endf

nmap <C-F5> "zyiw:Search \(virtual\s\s*\)\?\(public\\<Bar>protected\\<Bar>private\)\s\s*\(virtual\)\?\s\s*\<<C-R>z\><CR><CR>:cw<CR>

function! GetTagsInContext(symbol, context)
	let ctx = map(copy(a:context), '(strlen(v:val) > 0) ? v:val : "__anon\\d*"')
	let tags = []
	while 1
		let tags += taglist('^'.join(ctx + [a:symbol.'$'], '::'))
		if len(ctx) == 0
			break
		end
		call remove(ctx, -1)
	endw
	return tags
endf

function! GetMembers(fullSymbol)
	let tags = taglist('^'.a:fullSymbol.'::[^:]*$')
	let membernames = map(copy(tags), 'strpart(v:val["name"], strlen(a:fullSymbol."::"))')
	return membernames
endf

function! GetTags(symbol)
	return GetTagsInContext(a:symbol, map(g:cpp_plugin.createLocation(getpos('.')).getLocationPath().getRaw(), 'v:val["name"]'))
endf

function! GotoTag(tag)
	let path = Relpath(a:tag['filename'])
	execute 'edit ' . path
	let cmd = a:tag['cmd']
	if cmd[0] == '/'
		let cmd = '/\M' . strpart(cmd, 1)
	endif
	silent execute cmd
endf

function! Goto(symbol)
	let tags = GetTags(a:symbol)
	if len(tags) > 0
		call GotoTag(tags[0])
	else
		call searchdecl(a:symbol, 0, 1)
	end
endf

function CppNamespace(ns) " TODO use prototypes for such objects
	let self = {}

	let self._ns = a:ns

	function self.getRaw()
		return copy(self._ns)
	endf

	function self.compareTags(t1, t2)
		let ns = self.getRaw()
		let ns1 = a:t1.getNamespace()
		let ns2 = a:t2.getNamespace()
		let res = (len(ns1) - GetCommonSublistLen(ns1, ns)) - (len(ns2) - GetCommonSublistLen(ns2, ns))
		if res == 0
			let res = GetCommonSublistLen(ns2, ns) - GetCommonSublistLen(ns1, ns)
		end
		return res
	endf

	return self
endf

function CppPluginException(msg)
	return "CppPluginException: ".a:msg
endf

function! CppTag(rawTag)
	let self = {}

	let self._rawTag = a:rawTag

	function self.getRaw()
		return copy(self._rawTag)
	endf

	function self.getNamespace() " TODO Rename this method
		for key in ['namespace', 'struct', 'class']
			if has_key(self.getRaw(), key)
				return split(self.getRaw()[key], '::')
			end
		endfor
		throw CppPluginException('unknown tag type!')
	endf

	return self
endf


function GetIncludeFile(langPlugin, symbol)
	let std_includes = {}
	function! ExtendIncludes(dict, file, symbols)
		for s in a:symbols
			let a:dict[s] = a:file
		endfor
	endf
	call ExtendIncludes(std_includes, 'stdio.h', [ 'fclose', 'fopen', 'freopen', 'fdopen', 'remove', 'rename', 'rewind', 'tmpfile', 'Функции', 'для', 'операций', 'ввода-вывода', 'clearerr', 'feof', 'ferror', 'fflush', 'fgetpos', 'fgetc', 'fgets', 'fputc', 'fputs', 'ftell', 'fseek', 'fsetpos', 'fread', 'fwrite', 'getc', 'getchar', 'gets', 'printf', 'vprintf', 'fprintf', 'vfprintf', 'sprintf', 'snprintf', 'vsprintf', 'perror', 'putc', 'putchar', 'fputchar', 'scanf', 'vscanf', 'fscanf', 'vfscanf', 'sscanf', 'vsscanf', 'setbuf', 'setvbuf', 'tmpnam', 'ungetc', 'puts' ])
	call ExtendIncludes(std_includes, 'string.h', [ 'memcpy', 'memmove', 'memchr', 'memcmp', 'memset', 'strcat', 'strncat', 'strchr', 'strrchr', 'strcmp', 'strncmp', 'strcoll', 'strcpy', 'strncpy', 'strerror', 'strlen', 'strspn', 'strcspn', 'strpbrk', 'strstr', 'strtok', 'strxfrm' ])
	call ExtendIncludes(std_includes, 'vector', [ 'vector' ])
	call ExtendIncludes(std_includes, 'string', [ 'string', 'basic_string' ])
	call ExtendIncludes(std_includes, 'set', [ 'set' ])
	call ExtendIncludes(std_includes, 'map', [ 'map' ])
	call ExtendIncludes(std_includes, 'list', [ 'list' ])
	call ExtendIncludes(std_includes, 'deque', [ 'deque' ])
	call ExtendIncludes(std_includes, 'queue', [ 'queue' ])
	call ExtendIncludes(std_includes, 'memory', [ 'auto_ptr' ])
	call ExtendIncludes(std_includes, 'stdexcept', [ 'logic_error', 'domain_error', 'invalid_argument', 'length_error', 'out_of_range', 'runtime_error', 'range_error', 'overflow_error', 'underflow_error' ])
	call ExtendIncludes(std_includes, 'iostream', [ 'istream', 'ostream', 'basic_istream', 'basic_ostream', 'cin', 'cout', 'cerr', 'endl' ])
	call ExtendIncludes(std_includes, 'algorithm', [ 'for_each', 'find', 'find_if', 'find_end', 'find_first_of', 'adjacent_find', 'count', 'count_if', 'mismatch', 'equal', 'search', 'search_n', 'copy', 'copy_backward', 'swap', 'swap_ranges', 'iter_swap', 'transform', 'replace', 'replace_if', 'replace_copy', 'replace_copy_if', 'fill', 'fill_n', 'generate', 'generate_n', 'remove', 'remove_if', 'remove_copy', 'remove_copy_if', 'unique', 'unique_copy', 'reverse', 'reverse_copy', 'rotate', 'rotate_copy', 'random_shuffle', 'partition', 'stable_partition', 'sort', 'stable_sort', 'partial_sort', 'partial_sort_copy', 'nth_element', 'lower_bound', 'upper_bound', 'equal_range', 'binary_search', 'merge', 'inplace_merge', 'includes', 'set_union', 'set_intersection', 'set_difference', 'set_symmetric_difference', 'push_heap', 'pop_heap', 'make_heap', 'sort_heap', 'min', 'max', 'min_element', 'max_element', 'lexicographical_compare', 'next_permutation', 'prev_permutation' ])
	call ExtendIncludes(std_includes, 'functional', [ 'unary_function', 'binary_function', 'plus', 'minus', 'multiplies', 'divides', 'modulus', 'negate', 'equal_to', 'not_equal_to', 'greater', 'less', 'greater_equal', 'less_equal', 'logical_and', 'logical_or', 'logical_not', 'not1', 'not2', 'bind1st', 'bind2nd', 'ptr_fun', 'mem_fun', 'mem_fun_ref', 'unary_negate', 'binary_negate', 'binder1st', 'binder2nd', 'pointer_to_unary_function', 'pointer_to_binary_function', 'mem_fun_t', 'mem_fun1_t', 'const_mem_fun_t', 'const_mem_fun1_t', 'mem_fun_ref_t', 'mem_fun1_ref_t', 'const_mem_fun_ref_t', 'const_mem_fun1_ref_t' ])
	call ExtendIncludes(std_includes, 'streambuf', [ 'streambuf' ])
	call ExtendIncludes(std_includes, 'utility', [ 'pair' ])
	call ExtendIncludes(std_includes, 'sstream', [ 'stringstream', 'istringstream', 'ostringstream', 'basic_stringstream', 'basic_istringstream', 'basic_ostringstream' ])
	call ExtendIncludes(std_includes, 'fstream', [ 'fstream', 'ifstream', 'ofstream', 'basic_fstream', 'basic_ifstream', 'basic_ofstream' ])
	call ExtendIncludes(std_includes, 'typeinfo', [ 'type_info', 'bad_cast', 'bad_typeid', 'typeid' ])

	if has_key(std_includes, a:symbol)
		return std_includes[a:symbol]
	end

	let s:langPlugin = a:langPlugin " =(

	function! MyCompare(t1, t2)
		return s:ns_obj.compareTags(s:langPlugin.parseTag(a:t1), s:langPlugin.parseTag(a:t2)) " =(
	endf

	let s:ns_obj = a:langPlugin.createLocation(getpos('.')).getLocationPath().getNamespace()
	let tags = a:langPlugin.filterImportableTags(taglist('\<'.a:symbol.'\>'))
	call sort(tags, 'MyCompare')
	let s:filenames = map(copy(tags), 'v:val["filename"]')
	let tags = filter(copy(tags), 'index(s:filenames, v:val["filename"], v:key + 1)==-1')

	if len(tags) == 0
		echo "No tags found!"
		return ''
	end

	if len(tags) == 1
		return a:langPlugin.getImportForTag(tags[0])
	end

	let ns = s:ns_obj.getRaw()
	let ns1 = a:langPlugin.parseTag(tags[0]).getNamespace()
	let ns2 = a:langPlugin.parseTag(tags[1]).getNamespace()
	if ns1 == ns && ns2 != ns
		return a:langPlugin.getImportForTag(tags[0])
	end
	if GetCommonSublistLen(ns1, ns) == len(ns) && GetCommonSublistLen(ns2, ns) != len(ns)
		return a:langPlugin.getImportForTag(tags[0])
	end
	if GetCommonSublistLen(ns1, ns) == len(ns1) && GetCommonSublistLen(ns2, ns) != len(ns2)
		return a:langPlugin.getImportForTag(tags[0])
	end

	let s:choices = []
	for t in tags
		call add(s:choices, a:langPlugin.getImportForTag(t))
	endfor

	function! ImportsComplete(A,L,P)
		return s:choices
	endf
	return input('Multiple tags found, make your choice: ', s:choices[0], 'customlist,ImportsComplete')
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

function CppLocationPathEntry(type, name)
	let self = { 'type': a:type, 'name': a:name }
	return self
endf

function CppLocationPath(rawPath)
	let self = {}

	let self._rawPath = a:rawPath

	function self.getRaw()
		return copy(self._rawPath)
	endf

	function self.getNamespace()
		return CppNamespace(map(filter(self.getRaw(), 'v:val["type"] == "namespace"'), 'v:val["name"]'))
	endf

	function self.toString()
		return join(map(self.getRaw(), 'v:val["name"]'), '::')
	endf

	return self
endf

function CppLocation(rawLocation)
	let self = {}

	let self._rawLocation = a:rawLocation

	function self.getRaw()
		return copy(self._rawLocation)
	endf

	function self.getLocationPath()
		let res = []
		let save_cursor = getpos('.')
		call setpos('.', self.getRaw())
		let [l, p] = [0, 0]
		let [l, p] = searchpairpos('{', '', '}', 'b')
		while l != 0 || p != 0
			let [l2, p2] = searchpos('namespace\(\s\|\n\)*\S*\(\s\|\n\)*{', 'becWn')
			if l == l2 && p == p2
				let [sl, sp] = searchpos('namespace\(\s\|\n\)*\zs\ze\S*\(\s\|\n\)*{', 'becWn')
				let [el, ep] = searchpos('namespace\(\s\|\n\)*\S*\zs\ze\(\s\|\n\)*{', 'becWn')
				call insert(res, CppLocationPathEntry('namespace', GetTextBetweenPositions(sl, sp, el, ep)))
			endif
			let [l2, p2] = searchpos('\(class\|struct\)\(\s\|\n\)*\S*\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
			if l == l2 && p == p2
				let [sl, sp] = searchpos('\(class\|struct\)\(\s\|\n\)*\zs\ze\S*\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
				let [el, ep] = searchpos('\(class\|struct\)\(\s\|\n\)*\S*\zs\ze\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
				call insert(res, CppLocationPathEntry('class', GetTextBetweenPositions(sl, sp, el, ep)))
			endif
			let [l2, p2] = searchpos(')\(\s\|\n\)*\(const\(\s\|\n\)*\)\?{', 'becWn')
			if l == l2 && p == p2
				call searchpos('\zs\ze)\(\s\|\n\)*\(const\(\s\|\n\)*\)\?{', 'becW')
				call searchpairpos('(', '', ')', 'bW')
				let [sl, sp] = searchpos('[^:,\s\n\t]\(\s\|\n\)\zs\ze\S*\(\s\|\n\)*(', 'becWn')
				let [el, ep] = searchpos('[^:,\s\n\t]\(\s\|\n\)\S*\zs\ze\(\s\|\n\)*(', 'becWn')
				let func_res = filter(split(GetTextBetweenPositions(sl, sp, el, ep), '::'), 'v:val != "while" && v:val != "for" && v:val != "if"')
				let func_res = map(func_res, 'CppLocationPathEntry("function_or_class", v:val)')
				let res = func_res + res
			endif
			let [l, p] = searchpairpos('{', '', '}', 'bW')
		endw
		call setpos('.', save_cursor)
		return CppLocationPath(res)
	endf

	return self
endf

function! CppSyntax()
	let self = {}

	function self.getImportLine(dependency)
		return '#include <'.a:dependency.'>'
	endf

	function self.getImportRegex(regex)
		return '#include <\('.a:regex.'\)'
	endf

	return self
endf

let g:include_priorities = []

function! CppPlugin()
	let self = LangPlugin()

	let self.syntax = CppSyntax()
	let self.parseTag = function('CppTag')
	let self.createLocation = function('CppLocation')

	function self.buildFile() " TODO create BuildSystemPlugin
		exec Relpath('<C-R>%').'.o'
	endf

	function self.initHotkeys() " TODO move this out of CppPlugin
		nmap <C-F7> :call g:cpp_plugin.buildFile('<C-R>%')<CR>
		nmap <F4> :call g:cpp_plugin.openAlternativeFile('<C-R>%')<CR>
		map <C-K> "wyiw:call g:cpp_plugin.addImport(GetIncludeFile(g:cpp_plugin, @w), g:include_priorities)<CR>
		map t<C-]> "wyiw:call Goto(@w)<CR>
		nmap <C-RightMouse> <LeftMouse>t<C-]>
		nmap <C-P> :echo g:cpp_plugin.createLocation(getpos('.')).getLocationPath().toString()<CR>
		nmap g% :call searchpair('<', '', '>', getline('.')[col('.') - 1] == '>' ? 'bW' : 'W')<CR>
	endf

	function self.filterImportableTags(taglist)
		return filter(a:taglist, 'v:val["filename"] =~ "\\.\\(h\\|hpp\\)$"') " Headers only
	endf

	function self.getImportForTag(tag)
		return RemoveIncludeDirectory(Relpath(a:tag['filename']))
	endf

	function self.openAlternativeFile(filename)
		let substitute_ext = { 'hpp': 'cpp', 'h': 'c;cpp', 'cpp': 'h;hpp', 'c': 'h' }
		for src in keys(substitute_ext)
			let regex = '\.'.src.'$'
			if a:filename =~ regex
				for dst in split(substitute_ext[src], ';')
					let filename_to_open = substitute(a:filename, regex, '.'.dst, '')
					if filereadable(filename_to_open)
						break
					end
				endfor
				silent execute 'e '.filename_to_open
				break
			end
		endfor
	endf

	return self
endf

let g:cpp_plugin = CppPlugin()

function! GetCppPath()
	return g:cpp_plugin.createLocation(getpos('.')).getLocationPath().toString()
endf

au BufRead,BufNewFile *.h,*.hpp,*.c,*.cpp call g:cpp_plugin.initHotkeys()
