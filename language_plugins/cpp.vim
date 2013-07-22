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


nmap <C-F5> "zyiw:Search \(virtual\s\s*\)\?\(public\\<Bar>protected\\<Bar>private\)\s\s*\(virtual\)\?\s\s*\<<C-R>z\><CR><CR>:cw<CR>


function CppPluginException(msg)
	return "CppPluginException: ".a:msg
endf


function! GetMembers(fullSymbol)
	let tags = taglist('^'.a:fullSymbol.'::[^:]*$')
	let membernames = map(copy(tags), 'strpart(v:val["name"], strlen(a:fullSymbol."::"))')
	return membernames
endf


function CppNamespace(ns) " TODO use prototypes for such objects
	let self = {}

	let self._ns = a:ns

	function self.getRaw()
		return deepcopy(self._ns)
	endf

	function self.compareTags(t1, t2)
		let ns = self.getRaw()
		let ns1 = a:t1.getScope()
		let ns2 = a:t2.getScope()
		let res = (len(ns1) - GetCommonSublistLen(ns1, ns)) - (len(ns2) - GetCommonSublistLen(ns2, ns))
		if res == 0
			let res = GetCommonSublistLen(ns2, ns) - GetCommonSublistLen(ns1, ns)
		end
		return res
	endf

	return self
endf


function! CppTag(rawTag)
	let self = {}

	let self._rawTag = a:rawTag

	function self.getRaw()
		return deepcopy(self._rawTag)
	endf

	function self.getScope() " TODO Rename this method
		for key in ['namespace', 'struct', 'class']
			if has_key(self.getRaw(), key)
				return split(self.getRaw()[key], '::')
			end
		endfor
		throw CppPluginException('unknown tag type!')
	endf

	function self.goto()
		execute 'edit '.Relpath(self._rawTag['filename'])
		let cmd = self._rawTag['cmd']
		if cmd[0] == '/'
			let cmd = '/\M' . strpart(cmd, 1)
		endif
		silent execute cmd
	endf

	return self
endf


function FrameworkInfo(namespace)
	let self = {}

	let self._namespace = a:namespace
	let self._includes = {}

	function self.getNamespace()
		return deepcopy(self._namespace)
	endf

	function self._extendIncludes(file, symbols)
		for s in a:symbols
			let self._includes[s] = a:file
		endfor
	endf

	function self.hasSymbol(symbol)
		return has_key(self._includes, a:symbol)
	endf

	function self.getImport(symbol)
		return self._includes[a:symbol]
	endf

	return self
endf


function CppLocationPathEntry(type, name)
	let self = { 'type': a:type, 'name': a:name }
	return self
endf


function CppLocationPath(rawPath)
	let self = {}

	let self._rawPath = a:rawPath

	function self.getRaw()
		return deepcopy(self._rawPath)
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
		return deepcopy(self._rawLocation)
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

	function! self.getTags(symbol)
		let ctx = map(map(self.getLocationPath().getRaw(), 'v:val["name"]'), '(strlen(v:val) > 0) ? v:val : "__anon\\d*"')
		let tags = []
		while 1
			let tags += taglist('^'.join(ctx + [a:symbol.'$'], '::'))
			if len(ctx) == 0
				break
			end
			call remove(ctx, -1)
		endw
		return map(tags, 'CppTag(v:val)')
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

	let c_stdlib = FrameworkInfo(CppNamespace([]))
	call c_stdlib._extendIncludes('stdio.h', [ 'fclose', 'fopen', 'freopen', 'fdopen', 'remove', 'rename', 'rewind', 'tmpfile', 'clearerr', 'feof', 'ferror', 'fflush', 'fgetpos', 'fgetc', 'fgets', 'fputc', 'fputs', 'ftell', 'fseek', 'fsetpos', 'fread', 'fwrite', 'getc', 'getchar', 'gets', 'printf', 'vprintf', 'fprintf', 'vfprintf', 'sprintf', 'snprintf', 'vsprintf', 'perror', 'putc', 'putchar', 'fputchar', 'scanf', 'vscanf', 'fscanf', 'vfscanf', 'sscanf', 'vsscanf', 'setbuf', 'setvbuf', 'tmpnam', 'ungetc', 'puts' ])
	call c_stdlib._extendIncludes('string.h', [ 'memcpy', 'memmove', 'memchr', 'memcmp', 'memset', 'strcat', 'strncat', 'strchr', 'strrchr', 'strcmp', 'strncmp', 'strcoll', 'strcpy', 'strncpy', 'strerror', 'strlen', 'strspn', 'strcspn', 'strpbrk', 'strstr', 'strtok', 'strxfrm' ])
	call self.registerFramework(c_stdlib)

	let cpp_stdlib = FrameworkInfo(CppNamespace(['std']))
	call cpp_stdlib._extendIncludes('vector', [ 'vector' ])
	call cpp_stdlib._extendIncludes('string', [ 'string', 'basic_string' ])
	call cpp_stdlib._extendIncludes('set', [ 'set' ])
	call cpp_stdlib._extendIncludes('map', [ 'map' ])
	call cpp_stdlib._extendIncludes('list', [ 'list' ])
	call cpp_stdlib._extendIncludes('deque', [ 'deque' ])
	call cpp_stdlib._extendIncludes('queue', [ 'queue' ])
	call cpp_stdlib._extendIncludes('memory', [ 'auto_ptr' ])
	call cpp_stdlib._extendIncludes('stdexcept', [ 'logic_error', 'domain_error', 'invalid_argument', 'length_error', 'out_of_range', 'runtime_error', 'range_error', 'overflow_error', 'underflow_error' ])
	call cpp_stdlib._extendIncludes('iostream', [ 'istream', 'ostream', 'basic_istream', 'basic_ostream', 'cin', 'cout', 'cerr', 'endl' ])
	call cpp_stdlib._extendIncludes('algorithm', [ 'for_each', 'find', 'find_if', 'find_end', 'find_first_of', 'adjacent_find', 'count', 'count_if', 'mismatch', 'equal', 'search', 'search_n', 'copy', 'copy_backward', 'swap', 'swap_ranges', 'iter_swap', 'transform', 'replace', 'replace_if', 'replace_copy', 'replace_copy_if', 'fill', 'fill_n', 'generate', 'generate_n', 'remove', 'remove_if', 'remove_copy', 'remove_copy_if', 'unique', 'unique_copy', 'reverse', 'reverse_copy', 'rotate', 'rotate_copy', 'random_shuffle', 'partition', 'stable_partition', 'sort', 'stable_sort', 'partial_sort', 'partial_sort_copy', 'nth_element', 'lower_bound', 'upper_bound', 'equal_range', 'binary_search', 'merge', 'inplace_merge', 'includes', 'set_union', 'set_intersection', 'set_difference', 'set_symmetric_difference', 'push_heap', 'pop_heap', 'make_heap', 'sort_heap', 'min', 'max', 'min_element', 'max_element', 'lexicographical_compare', 'next_permutation', 'prev_permutation' ])
	call cpp_stdlib._extendIncludes('functional', [ 'unary_function', 'binary_function', 'plus', 'minus', 'multiplies', 'divides', 'modulus', 'negate', 'equal_to', 'not_equal_to', 'greater', 'less', 'greater_equal', 'less_equal', 'logical_and', 'logical_or', 'logical_not', 'not1', 'not2', 'bind1st', 'bind2nd', 'ptr_fun', 'mem_fun', 'mem_fun_ref', 'unary_negate', 'binary_negate', 'binder1st', 'binder2nd', 'pointer_to_unary_function', 'pointer_to_binary_function', 'mem_fun_t', 'mem_fun1_t', 'const_mem_fun_t', 'const_mem_fun1_t', 'mem_fun_ref_t', 'mem_fun1_ref_t', 'const_mem_fun_ref_t', 'const_mem_fun1_ref_t' ])
	call cpp_stdlib._extendIncludes('streambuf', [ 'streambuf' ])
	call cpp_stdlib._extendIncludes('utility', [ 'pair' ])
	call cpp_stdlib._extendIncludes('sstream', [ 'stringstream', 'istringstream', 'ostringstream', 'basic_stringstream', 'basic_istringstream', 'basic_ostringstream' ])
	call cpp_stdlib._extendIncludes('fstream', [ 'fstream', 'ifstream', 'ofstream', 'basic_fstream', 'basic_ifstream', 'basic_ofstream' ])
	call cpp_stdlib._extendIncludes('typeinfo', [ 'type_info', 'bad_cast', 'bad_typeid', 'typeid' ])
	call self.registerFramework(cpp_stdlib)

	function self.buildFile() " TODO create BuildSystemPlugin
		exec Relpath('<C-R>%').'.o'
	endf

	function self.filterImportableTags(taglist)
		return filter(a:taglist, 'v:val["filename"] =~ "\\.\\(h\\|hpp\\)$"') " Headers only
	endf

	function self.getImportForTag(tag)
		return self.getImportForPath(Relpath(a:tag['filename']))
	endf

	function self.getImportForPath(filename)
		if exists('g:include_directories')
			for dir in g:include_directories
				if a:filename[0 : len(dir) - 1] == dir
					return a:filename[((a:filename[len(dir)] == '/') ? len(dir) + 1 : len(dir)):]
				end
			endfor
		end
		return a:filename
	endf

	function self.getAlternativeFile(filename)
		let substitute_ext = { 'hpp': 'cpp', 'h': 'c;cpp', 'cpp': 'h;hpp', 'c': 'h' }
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
	endf

	function self.gotoLocalSymbol(symbol)
		call searchdecl(a:symbol, 0, 1)
	endf

	return self
endf


let g:cpp_plugin = CppPlugin()

au BufRead,BufNewFile *.h,*.hpp,*.c,*.cpp call ActivateLangPlugin(g:cpp_plugin)
