function GetCppNamespaceFromPath(path)
	return []
endfunction


autocmd User plugin-template-loaded call s:template_keywords()
function s:template_keywords()
	%s/<+FILENAME+>/\=toupper(substitute(s:GetRelativeIncludePath(expand('%')), '[-.\/\\\\:]', '_', 'g'))/ge
	%s/<+FILENAME_MANGLED+>/\=toupper(substitute(s:GetRelativeIncludePath(expand('%')), '[-.\/\\\\:]', '_', 'g'))/ge
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


function s:GetRelativeIncludePath(filename)
	let filename = substitute(a:filename, '\(^\|/\)./', '\1', 'g')
	if exists('g:include_directories')
		for dir in g:include_directories
			if filename[0 : len(dir) - 1] == dir
				return filename[((filename[len(dir)] == '/') ? len(dir) + 1 : len(dir)):]
			end
		endfor
	end
	return filename
endf

let g:clang_complete_auto=0
let g:clang_hl_errors=0
let g:clang_user_options='|| exit 0'

let g:c_std_includes = 'assert\.h\|complex\.h\|ctype\.h\|errno\.h\|fenv\.h\|float\.h\|inttypes\.h\|iso646\.h\|limits\.h\|locale\.h\|math\.h\|search\.h\|setjmp\.h\|signal\.h\|stdalign\.h\|stdarg\.h\|stdatomic\.h\|stdbool\.h\|stddef\.h\|stdint\.h\|stdio\.h\|stdlib\.h\|stdnoreturn\.h\|string\.h\|tgmath\.h\|threads\.h\|time\.h\|uchar\.h\|wchar\.h\|wctype\.h'

let g:cpp_std_includes = 'algorithm\|array\|atomic\|bitset\|cfenv\|chrono\|codecvt\|complex\|condition_variable\|deque\|exception\|forward_list\|fstream\|functional\|future\|initializer_list\|iomanip\|ios\|iosfwd\|iostream\|istream\|iterator\|limits\|list\|locale\|map\|memory\|mutex\|new\|numeric\|ostream\|queue\|random\|ratio\|regex\|scoped_allocator\|set\|shared_mutex\|sstream\|stack\|stdexcept\|streambuf\|string\|strstream\|system_error\|thread\|tuple\|type_traits\|typeindex\|typeinfo\|unordered_map\|unordered_set\|utility\|valarray\|vector'
let g:platform_includes = 'aio\.h\|arpa/inet\.h\|cpio\.h\|dirent\.h\|dlfcn\.h\|fcntl\.h\|fmtmsg\.h\|fnmatch\.h\|ftw\.h\|glob\.h\|grp\.h\|iconv\.h\|langinfo\.h\|libgen\.h\|monetary\.h\|mqueue\.h\|ndbm\.h\|net/if\.h\|netdb\.h\|netinet/in\.h\|netinet/tcp\.h\|nl_types\.h\|poll\.h\|pthread\.h\|pwd\.h\|regex\.h\|sched\.h\|semaphore\.h\|signal\.h\|spawn\.h\|strings\.h\|stropts\.h\|sys/ipc\.h\|sys/mman\.h\|sys/msg\.h\|sys/resource\.h\|sys/select\.h\|sys/sem\.h\|sys/shm\.h\|sys/socket\.h\|sys/stat\.h\|sys/statvfs\.h\|sys/time\.h\|sys/times\.h\|sys/types\.h\|sys/uio\.h\|sys/un\.h\|sys/utsname\.h\|sys/wait\.h\|syslog\.h\|tar\.h\|termios\.h\|tgmath\.h\|trace\.h\|ulimit\.h\|unistd\.h\|utime\.h\|utmpx\.h\|wordexp\.h\|windows\.h\|wintypes\.h'


function CppPluginException(msg)
	return "CppPluginException: ".a:msg
endf


function GetMembers(fullSymbol)
	let tags = taglist('^'.a:fullSymbol.'::[^:]*$')
	let membernames = map(copy(tags), 'strpart(v:val["name"], strlen(a:fullSymbol."::"))')
	return membernames
endf


function CppNamespace(ns)
	if !exists('s:CppNamespace')
		let s:CppNamespace = {}

		function s:CppNamespace.getRaw()
			return deepcopy(self._ns)
		endf

		function s:CppNamespace.compareSymbols(s1, s2)
			let ns = self.getRaw()
			let ns1 = a:s1.getScope()
			let ns2 = a:s2.getScope()
			let res = (len(ns1) - GetCommonSublistLen(ns1, ns)) - (len(ns2) - GetCommonSublistLen(ns2, ns))
			if res == 0
				let res = GetCommonSublistLen(ns2, ns) - GetCommonSublistLen(ns1, ns)
			end
			return res
		endf
	end

	let self = copy(s:CppNamespace)
	let self._ns = a:ns
	return self
endf


function CppLocationPathEntry(type, name)
	let self = { 'type': a:type, 'name': a:name }
	return self
endf


function CppLocationPath(rawPath)
	if !exists('s:CppLocationPath')
		let s:CppLocationPath = {}

		function s:CppLocationPath.getRaw()
			return deepcopy(self._rawPath)
		endf

		function s:CppLocationPath.getNamespace()
			return CppNamespace(map(filter(self.getRaw(), 'v:val["type"] == "namespace"'), 'v:val["name"]'))
		endf

		function s:CppLocationPath.getTagRegex()
			return map(map(self.getRaw(), 'v:val["name"]'), '(strlen(v:val) > 0) ? v:val : "__anon\\d*"')
		endf

		function s:CppLocationPath.toString()
			return join(map(self.getRaw(), 'v:val["name"]'), '::')
		endf
	end

	let self = copy(s:CppLocationPath)
	let self._rawPath = a:rawPath
	return self
endf


function CppLocation(rawLocation)
	if !exists('s:CppLocation')
		let s:CppLocation = {}

		function s:CppLocation.getRaw()
			return deepcopy(self._rawLocation)
		endf

		function s:CppLocation.getBufNum()
			return self._rawLocation[0]
		endf

		function s:CppLocation.getLineNum()
			return self._rawLocation[1]
		endf

		function s:CppLocation.getColumnNum()
			return self._rawLocation[2]
		endf

		function s:CppLocation.endOfPrevLine()
			return CppLocation([ self.getBufNum(), self.getLineNum() - 1, len(getline(self.getLineNum() - 1)) + 1, 0 ])
		endf

		function s:CppLocation.beginOfNextLine()
			return CppLocation([ self.getBufNum(), self.getLineNum() + 1, 1, 0 ])
		endf

		function s:CppLocation.goto(...)
			if a:0 == 1
				call insert(a:1, CppLocation(getpos('.')))
			end
			call setpos('.', self.getRaw())
		endf

		function s:CppLocation.goBack(locationStack)
			if empty(a:locationStack)
				throw "CppLocation: location stack empty!"
			end
			let top = remove(a:locationStack, 0)
			call top.goto()
		endf

		function s:CppLocation.getLocationPath()
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
	end

	let self = copy(s:CppLocation)
	let self._rawLocation = a:rawLocation
	return self
endf


function CppSyntax()
	let self = Syntax()

	let self.symbolDelimiter = '::'
	let self.keywords = [ "alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand", "bitor", "bool", "break", "case", "catch", "char", "char16_t", "char32_t", "class", "compl", "const", "constexpr", "const_cast", "continue", "decltype", "default", "delete", "do", "double", "dynamic_cast", "else", "enum", "explicit", "export", "extern", "false", "float", "for", "friend", "goto", "if", "inline", "int", "long", "mutable", "namespace", "new", "noexcept", "not", "not_eq", "nullptr", "operator", "or", "or_eq", "private", "protected", "public", "register", "reinterpret_cast", "return", "short", "signed", "sizeof", "static", "static_assert", "static_cast", "struct", "switch", "template", "this", "thread_local", "throw", "true", "try", "typedef", "typeid", "typename", "union", "unsigned", "using", "virtual", "void", "volatile", "wchar_t", "while", "xor", "xor_eq" ]

	function self.getImportLine(dependency)
		return '#include <'.a:dependency.'>'
	endf

	function self.getImportRegex(regex)
		return '#include [<"]\('.a:regex.'\)'
	endf

	function self._getCurrentLine(location)
		let s = getline(a:location.getLineNum())

		let result = ''
		let state = 'normal'
		let i = 0
		let parsePrevLine = 1
		let parseNextLine = 1
		while i < len(s)
			if (s[i] == '"' || s[i] == "'") && s[i - 1] != '\'
				if state != 'string'
					let state = 'string'
				else
					let state = 'normal'
				end
			end
			if (s[i] == ';' || s[i] == '{' || s[i] == '}') && state != 'string'
				if i >= a:location.getColumnNum() - 1
					let parseNextLine = 0
					if s[i] == ';'
						let result .= s[i]
					end
					break
				else
					let result = ''
					let i += 1
					let parsePrevLine = 0
					continue
				end
			end
			let result .= s[i]
			let i += 1
		endw

		return { 'string': StripString(result), 'parsePrevLine': parsePrevLine, 'parseNextLine': parseNextLine }
	endf

	function self.getLine(location)
		let location_stack = []

		call a:location.goto(location_stack)

		let loc = a:location
		let cl = self._getCurrentLine(a:location)
		let result = cl.string
		while cl.parsePrevLine
			let loc = loc.endOfPrevLine()
			let cl = self._getCurrentLine(loc)
			let result = cl.string . result
		endw

		let loc = a:location
		let cl = self._getCurrentLine(a:location)
		while cl.parseNextLine
			let loc = loc.beginOfNextLine()
			let cl = self._getCurrentLine(loc)
			let result .= cl.string
		endw

		call a:location.goBack(location_stack)

		return result
	endf

	return self
endf


let g:include_priorities = []


function CppPlugin()
	let self = LangPlugin()

	call self.autocompleteSettings.enableAutoInvoke(0)
	"if IsOnACPower()
		"call self.autocompleteSettings.setAutoInvokationKeys('\<C-X>\<C-O>')
	"else
		call self.autocompleteSettings.setAutoInvokationKeys('\<C-N>')
	"end

	let self.fileExtensions = [ 'h', 'c', 'hpp', 'cpp' ]
	let self.alternativeExtensionsMap = { 'hpp': 'cpp', 'h': 'c;cpp', 'cpp': 'h;hpp', 'c': 'h' }
	let self.syntax = CppSyntax()
	let self.indexer = CTagsIndexer(self)
	let self.createLocation = function('CppLocation')

	let c_stdlib = CTagsFrameworkInfo()
	call c_stdlib.addImports('assert.h', [ 'assert' ])
	call c_stdlib.addImports('stddef.h', [ 'size_t' ])
	call c_stdlib.addImports('stdio.h', [ 'fclose', 'fopen', 'freopen', 'fdopen', 'remove', 'rename', 'rewind', 'tmpfile', 'clearerr', 'feof', 'ferror', 'fflush', 'fgetpos', 'fgetc', 'fgets', 'fputc', 'fputs', 'ftell', 'fseek', 'fsetpos', 'fread', 'fwrite', 'getc', 'getchar', 'gets', 'printf', 'vprintf', 'fprintf', 'vfprintf', 'sprintf', 'snprintf', 'vsprintf', 'perror', 'putc', 'putchar', 'fputchar', 'scanf', 'vscanf', 'fscanf', 'vfscanf', 'sscanf', 'vsscanf', 'setbuf', 'setvbuf', 'tmpnam', 'ungetc', 'puts' ])
	call c_stdlib.addImports('string.h', [ 'memcpy', 'memmove', 'memchr', 'memcmp', 'memset', 'strcat', 'strncat', 'strchr', 'strrchr', 'strcmp', 'strncmp', 'strcoll', 'strcpy', 'strncpy', 'strerror', 'strlen', 'strspn', 'strcspn', 'strpbrk', 'strstr', 'strtok', 'strxfrm' ])
	call c_stdlib.addImports('stdint.h', [ 'int8_t', 'uint8_t', 'int16_t', 'uint16_t', 'int32_t', 'uint32_t', 'int64_t', 'uint64_t' ])
	call self.indexer.registerFramework(c_stdlib)

	let cpp_stdlib = CTagsFrameworkInfo()
	call cpp_stdlib.addImports('atomic', [ 'atomic' ])
	call cpp_stdlib.addImports('vector', [ 'vector' ])
	call cpp_stdlib.addImports('string', [ 'string', 'basic_string' ])
	call cpp_stdlib.addImports('set', [ 'set' ])
	call cpp_stdlib.addImports('map', [ 'map' ])
	call cpp_stdlib.addImports('multiset', [ 'multiset' ])
	call cpp_stdlib.addImports('multimap', [ 'multimap' ])
	call cpp_stdlib.addImports('list', [ 'list' ])
	call cpp_stdlib.addImports('deque', [ 'deque' ])
	call cpp_stdlib.addImports('queue', [ 'queue', 'priority_queue' ])
	call cpp_stdlib.addImports('memory', [ 'auto_ptr', 'unique_ptr', 'shared_ptr' ])
	call cpp_stdlib.addImports('stdexcept', [ 'logic_error', 'domain_error', 'invalid_argument', 'length_error', 'out_of_range', 'runtime_error', 'range_error', 'overflow_error', 'underflow_error' ])
	call cpp_stdlib.addImports('iomanip', [ 'resetiosflags', 'setiosflags', 'setbase', 'setfill', 'setprecision', 'setw', 'get_money', 'put_money', 'get_time', 'put_time', 'quoted' ])

	call cpp_stdlib.addImports('iostream', [ 'istream', 'ostream', 'basic_istream', 'basic_ostream', 'cin', 'cout', 'cerr', 'endl' ])
	call cpp_stdlib.addImports('algorithm', [ 'for_each', 'find', 'find_if', 'find_end', 'find_first_of', 'adjacent_find', 'count', 'count_if', 'mismatch', 'equal', 'search', 'search_n', 'copy', 'copy_backward', 'swap_ranges', 'iter_swap', 'transform', 'replace', 'replace_if', 'replace_copy', 'replace_copy_if', 'fill', 'fill_n', 'generate', 'generate_n', 'remove', 'remove_if', 'remove_copy', 'remove_copy_if', 'unique', 'unique_copy', 'reverse', 'reverse_copy', 'rotate', 'rotate_copy', 'random_shuffle', 'partition', 'stable_partition', 'sort', 'stable_sort', 'partial_sort', 'partial_sort_copy', 'nth_element', 'lower_bound', 'upper_bound', 'equal_range', 'binary_search', 'merge', 'inplace_merge', 'includes', 'set_union', 'set_intersection', 'set_difference', 'set_symmetric_difference', 'push_heap', 'pop_heap', 'make_heap', 'sort_heap', 'min', 'max', 'min_element', 'max_element', 'lexicographical_compare', 'next_permutation', 'prev_permutation' ])
	call cpp_stdlib.addImports('functional', [ 'function', 'bind', 'unary_function', 'binary_function', 'plus', 'minus', 'multiplies', 'divides', 'modulus', 'negate', 'equal_to', 'not_equal_to', 'greater', 'less', 'greater_equal', 'less_equal', 'logical_and', 'logical_or', 'logical_not', 'not1', 'not2', 'bind1st', 'bind2nd', 'ptr_fun', 'mem_fun', 'mem_fun_ref', 'unary_negate', 'binary_negate', 'binder1st', 'binder2nd', 'pointer_to_unary_function', 'pointer_to_binary_function', 'mem_fun_t', 'mem_fun1_t', 'const_mem_fun_t', 'const_mem_fun1_t', 'mem_fun_ref_t', 'mem_fun1_ref_t', 'const_mem_fun_ref_t', 'const_mem_fun1_ref_t' ])
	call cpp_stdlib.addImports('streambuf', [ 'streambuf' ])
	call cpp_stdlib.addImports('type_traits', [ 'integral_constant', 'is_void', 'is_null_pointer', 'is_integral', 'is_floating_point', 'is_array', 'is_enum', 'is_union', 'is_class', 'is_function', 'is_pointer', 'is_lvalue_reference', 'is_rvalue_reference', 'is_member_object_pointer', 'is_member_function_pointer', 'is_fundamental', 'is_arithmetic', 'is_scalar', 'is_object', 'is_compound', 'is_reference', 'is_member_pointer', 'is_const', 'is_volatile', 'is_trivial', 'is_trivially_copyable', 'is_standard_layout', 'is_pod', 'is_literal_type', 'is_empty', 'is_polymorphic', 'is_abstract', 'is_signed', 'is_unsigned', 'is_constructible', 'is_trivially_constructible', 'is_nothrow_constructible', 'is_default_constructible', 'is_trivially_default_constructible', 'is_nothrow_default_constructible', 'is_copy_constructible', 'is_trivially_copy_constructible', 'is_nothrow_copy_constructible', 'is_move_constructible', 'is_trivially_move_constructible', 'is_nothrow_move_constructible', 'is_assignable', 'is_trivially_assignable', 'is_nothrow_assignable', 'is_copy_assignable', 'is_trivially_copy_assignable', 'is_nothrow_copy_assignable', 'is_move_assignable', 'is_trivially_move_assignable', 'is_nothrow_move_assignable', 'is_destructible', 'is_trivially_destructible', 'is_nothrow_destructible', 'has_virtual_destructor', 'alignment_of', 'rank', 'extent', 'is_same', 'is_base_of', 'is_convertible', 'remove_cv', 'remove_const', 'remove_volatile', 'add_cv', 'add_const', 'add_volatile', 'remove_reference', 'add_lvalue_reference', 'add_rvalue_reference', 'remove_pointer', 'add_pointer', 'make_signed', 'make_unsigned', 'remove_extent', 'remove_all_extents', 'aligned_storage', 'aligned_union', 'decay', 'enable_if', 'conditional', 'common_type', 'underlying_type', 'result_of' ])

	call cpp_stdlib.addImports('thread', [ 'thread' ])
	call cpp_stdlib.addImports('future', [ 'future', 'promise' ])
	call cpp_stdlib.addImports('mutex', [ 'mutex', 'recursive_mutex', 'call_once', 'once_flag' ])
	call cpp_stdlib.addImports('utility', [ 'swap', 'pair', 'make_pair', 'forward', 'move' ])
	call cpp_stdlib.addImports('sstream', [ 'stringstream', 'istringstream', 'ostringstream', 'basic_stringstream', 'basic_istringstream', 'basic_ostringstream' ])
	call cpp_stdlib.addImports('fstream', [ 'fstream', 'ifstream', 'ofstream', 'basic_fstream', 'basic_ifstream', 'basic_ofstream' ])
	call cpp_stdlib.addImports('typeinfo', [ 'type_info', 'bad_cast', 'bad_typeid', 'typeid' ])
	call self.indexer.registerFramework(cpp_stdlib)

	function self.codeComplete(findstart, base)
		return ClangComplete(a:findstart, a:base)
	endf

	let self._includeStartRegex = '^\s*#\s*include\s*["<]'

	function self.autoComplete(findstart, base)
		let line_start = getline('.')[0 : max([col('.') - 2, 0])]

		if line_start =~ self._includeStartRegex
			let include_start_match = matchstr(line_start, self._includeStartRegex)
			let paths_list = split(&path, ',')
			if filereadable('.clang_complete')
				let paths_list += map(filter(readfile('.clang_complete'), 'v:val =~ "^-I"'), 'substitute(v:val, "^-I\s*", "", "")')
			end
			return PathComplete(paths_list, len(include_start_match) + 1, a:findstart, a:base)
		else
			return self.codeComplete(a:findstart, a:base)
		end
	endf

	function self.testInvokeAutocomplete()
		let line_start = getline('.')[0 : max([col('.') - 2, 0])]
		return line_start =~ self._includeStartRegex && getline('.')[col('.') - 2] =~ '[</"]'
	endf

	function self.filterImportableSymbols(symbols)
		return filter(a:symbols, 'v:val.getFilename() =~ "\\.\\(h\\|hpp\\)$"') " Headers only
	endf

	function self.getImportPriorities(filename)
		let prepend = [ ]
		if a:filename[-4:] == '.cpp' || a:filename[-2:] == '.c'
			let filename_local = fnamemodify(a:filename, ':t')
			let dir = fnamemodify(a:filename, ':h')

			let self_header_local = substitute(filename_local, '\.\(c\|cpp\)$', '.h', '')
			if !filereadable(dir.'/'.self_header_local)
				let self_header_local = substitute(filename_local, '\.\(c\|cpp\)$', '.hpp', '')
			end

			let self_header = substitute(a:filename, '\.\(c\|cpp\)$', '.h', '')
			if !filereadable(self_header)
				let self_header = substitute(a:filename, '\.\(c\|cpp\)$', '.hpp', '')
			end

			if filereadable(dir.'/'.self_header_local)
				call add(prepend, escape(s:GetRelativeIncludePath(self_header_local), '&*.\'))
			end

			if filereadable(self_header)
				call add(prepend, escape(s:GetRelativeIncludePath(self_header), '&*.\'))
			end
		end
		return prepend + g:include_priorities
	endf

	function self.getImportsBeginLine()
		let b = self.getImportsBeginLineNoLicense()
		let metComment = 0
		for i in range(b, line('$'))
			let line = getline(i)
			if line =~ '^\s*$'
				continue
			end
			if line =~ '^\s*//.*$'
				let metComment = 1
				continue
			end
			"let res = getline(i - 1) =~ '^\s*$' ? i - self.whitespacesCountAroundImports : i
			if metComment
				let res = i
				return res
			else
				return b
			end
		endfor
		return b
	endf

	function self.getImportsBeginLineNoLicense()
		let filename = expand('%')
		if filename[-4:] == '.hpp' || filename[-2:] == '.h'
			for i in range(1, line('$'))
				let line = getline(i)
				if line =~ '^\s*$'
					continue
				elseif line =~ '^\s*#\s*pragma\s\+once\s*$'
					return i + 1
				else
					let define_name = ''
					let m = matchlist(line, '^\s*#\s*ifndef\s\+\(\i\+\)\s*$')
					if !empty(m)
						let define_name = m[1]
					else
						let m = matchlist(line, '^\s*#\s*if\s*!\s*defined\s*\%((\|\s\)\s*\(\i\+\)\s*)\?\s*$')
						if !empty(m)
							let define_name = m[1]
						end
					end
					if !empty(define_name)
						for j in range(i + 1, line('$'))
							let line2 = getline(j)
							if line2 =~ '^\s*#\s*define\s\+'.define_name.'\s*$'
								return j + 1
							end
						endfor
					end
				end
			endfor
		end
		return 1
	endf

	function self.getImportForSymbol(symbol)
		return self.getImportForPath(Relpath(a:symbol.getFilename()))
	endf

	function self.getImportForPath(filename)
		return s:GetRelativeIncludePath(a:filename)
	endf

	function self.gotoLocalSymbol(symbol)
		call searchdecl(a:symbol, 0, 1)
	endf

	function self._hookGoToTag(cmd)
		redir => get_type_out
		silent! YcmCompleter GetType
		redir END
		let type = StripString(get_type_out)
		if type == 'int' || type == 'Unknown type' || type =~? "^internal error:"
			exe a:cmd." ".expand("<cword>")
		else
			YcmCompleter GoTo
		end
	endf

	function self.onActivated()
		au BufWritePre <buffer> :call b:lang_plugin.removeTrailingWhitespaces()
	endf

	return self
endf


function s:SetCppPaths()
	if !exists("s:cpp_paths")
		let s:cpp_paths = []
		let lines = split(system("echo '' | g++ -v -x c++ -E -"), '\n')
		let got_includes = 0
		for l in lines
			if !got_includes
				if l =~ '#include <\.\.\.> search starts here:'
					let got_includes = 1
				end
			else
				if l =~ 'End of search list.'
					break
				end
				call add(s:cpp_paths, substitute(StripString(l), '\s\+(framework directory)$', '', ''))
			end
		endfor
	end

	for p in s:cpp_paths
		execute 'set path+='.p
	endfor
endf

function CppCompleteFunc(findstart, base)
	return g:cpp_plugin.autoComplete(a:findstart, a:base)
endf


let g:cpp_plugin = CppPlugin()

au FileType cpp.doxygen,c,cpp,objc,objcpp call <SID>SetCppPaths()
au FileType cpp.doxygen,c,cpp,objc,objcpp call ActivateLangPlugin(g:cpp_plugin)
