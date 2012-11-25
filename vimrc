if !exists("g:vimstuff_sourced")
	let g:vimstuff_sourced = 1
	set hidden
	set tabstop=4
	set shiftwidth=4
	set number
	set hlsearch
	if has("mouse")
		set mouse=a
	end
	set cursorline
	set autoindent
	set makeprg=make\ -j8
	set isfname-==
	set wildmode=longest,list,full
	set cinoptions=g0,:0,l1,t0
	if has("foldcolumn")
		set foldcolumn=1
	end
	set fillchars=vert:\|
	filetype plugin on

	colorscheme torte

	autocmd VimLeavePre * colorscheme default


	" Resetting colors for ubuntu 12.10 vim =(
	hi Pmenu			ctermfg=7 ctermbg=5 gui=bold guifg=White guibg=DarkGray
	hi PmenuSel			ctermfg=7 ctermbg=0 guibg=DarkGrey
	hi PmenuSbar		ctermbg=7 guibg=Grey
	hi PmenuThumb		cterm=reverse gui=reverse

	let g:fuf_coveragefile_exclude = '\v\~$|\.(o|exe|dll|bak|png|jpg|orig|sw[po]|pyc)$|(^|[/\\])\.(hg|git|bzr)($|[/\\])'
	let g:clang_complete_auto=0
	let g:clang_hl_errors=0
	let g:clang_user_options='|| exit 0'

	" Some settings for vtree-explorer
	let treeExplVertical=1
	let treeExplWinSize=40
	let treeExplDirSort=1

	function! DoComment()	
		let current_line = getline(line("v"))
		let comment_check = substitute(current_line, "^\\s*//", "", "")
		if current_line != comment_check
			let subst_cmd = "s/^\\(\\s*\\)\\/\\//\\1/g"
		else
			let subst_cmd = "s/^\\(\\s*\\)\\([^/]\\)/\\1\\/\\/\\2/g"
		endif
			
		silent! execute subst_cmd
	endf

	function! DoNewFile(filename)
		let command_str = g:createCodeFileScript . " " . a:filename
		call system(command_str)
		let open_cmd = "e " . a:filename
		silent execute open_cmd
	endf

	function! DoHeaderToCpp(filename)
		if stridx(a:filename, ".hpp") != -1
			let filename_str = substitute(a:filename, "\\.hpp$", ".cpp", "")
		elseif stridx(a:filename, ".h") != -1
			let filename_str = substitute(a:filename, "\\.h$", ".cpp", "")
			if !filereadable(filename_str)
				let filename_str = substitute(a:filename, "\\.h$", ".c", "")
			endif
		elseif stridx(a:filename, ".cpp") != -1
			let filename_str = substitute(a:filename, "\\.cpp$", ".h", "")
			if !filereadable(filename_str)
				let filename_str = substitute(a:filename, "\\.cpp$", ".hpp", "")
			endif
		elseif stridx(a:filename, ".c") != -1
			let filename_str = substitute(a:filename, "\\.c$", ".h", "")
		endif
		let open_cmd = "e " . filename_str
		silent execute open_cmd
	endf

	function! Relpath(filename)
		let cwd = getcwd()
		let s1 = substitute(a:filename, "^./" , "", "")
		let s2 = substitute(s1, l:cwd . "/" , "", "")
		return s2
	endf


	function! DoSearch(expression)
		let args = split(a:expression)
		let expression = a:expression
		let context_lines = 0
		if len(args) > 1
			try
				let context_lines = args[-1]
				call remove(args, 0)
				let expression = join(args, " ")
			endtry
		end
		let excludes_list = ["*map", "*tex", "*html", "*git*", "*doxygen*", "*svn*", "*entries", "*all-wcprops", "depend*", "*includecache", "tags", "valgrind*", "types_*.vim"]
		let excludedirs_list = ["etc", "build", ".git", "CMakeFiles"]
		let excludes_string = "--exclude=\"" . join(excludes_list, "\" --exclude=\"") . "\" --exclude-dir=\"" . join(excludedirs_list, "\" --exclude-dir=\"") . "\""
		execute "grep " . excludes_string . " -A " . context_lines . " -rI \"" . expression . "\" ./"
	endf

	function! InitCppHotKeys()
		command! -nargs=1 -complete=file HeaderToCpp call DoHeaderToCpp("<args>")

		map <F2> :call DoComment()<CR>
		nmap <C-F7> :let @z=Relpath('<C-R>%')<CR>:make <C-R>z.o<CR>
		nmap <F4> :HeaderToCpp <C-R>%<CR>
		"map <C-K> mX"wyiw:keepj tag <C-R>w<CR>:while match(@%, "\.h$") == -1 && match(@%, "\.hpp$") == -1<CR>keepj tn<CR>endw<CR>:let @q=Relpath(@%)<CR>:keepj normal 'XG<CR>:keepj ?#include<CR>:noh<CR>o#include <<C-R>q><ESC>:keepj normal V{<CR>:sort u<CR>:keepj normal `X<CR>:echo "#include <<C-R>q>"<CR>
		map <C-K> "wyiw:call AddInclude(GetIncludeFile(@w))<CR>
		map t<C-]> "wyiw:call Goto(@w)<CR>
		nmap <C-RightMouse> <LeftMouse>t<C-]>
		nmap <C-P> :echo join(GetCppPath(), '::')<CR>
	endf

	command! -nargs=1 -complete=file NewFile call DoNewFile("<args>")
	command! -nargs=1 -complete=tag Search call DoSearch('<args>')

	function FixQuickFix()
		let has_entries = 0

		let qflist = getqflist()
		for entry in qflist
			if has_key(entry, 'bufnr') && entry['bufnr'] != 0
				let has_entries = 1
				let filename = bufname(entry['bufnr'])
				if exists('*CustomQuickFixPatcher')
					if CustomQuickFixPatcher(filename, entry)
						continue
					end
				end
				if !file_readable(filename)
					for dir in g:subdirectories
						if file_readable(dir.'/'.filename)
							let entry['bufnr']=bufnr(dir.'/'.filename, 1)
							break
						end
					endfor
				end
			end
		endfor
		call setqflist(qflist, 'r')
		return has_entries
	endf


	au QuickfixCmdPost make nested if FixQuickFix() | cn | end | cw
	au BufRead,BufNewFile *.h,*.hpp,*.c,*.cpp call InitCppHotKeys()
	au BufRead,BufNewFile *.qml set filetype=qml
	au BufRead,BufNewFile *.decl set filetype=qml
	au BufRead,BufNewFile *.cmix set filetype=cmix
	au BufNewFile,BufRead *.pas,*.PAS set ft=pascal
	au! Syntax qml source $HOME/.vim/syntax/qml.vim

	"if exists('*pathogen#infect')
		call pathogen#infect()
	"end

	" Remove clang-complete stupid mappings
	au BufRead,BufNewFile *.h,*.hpp,*.c,*.cpp silent! execute 'iunmap <Tab>'

	if 0 " exists('*ResetSnippets')
		au BufRead,BufNewFile *.h,*.hpp,*.c,*.cpp call ResetSnippets('cpp') | call ResetSnippets('c') | call ExtractSnipsFile('/home/koplyarov/.vim/my-snippets/cpp.snippets', 'cpp') | call ExtractSnipsFile('/home/koplyarov/.vim/my-snippets/c.snippets', 'c')
	endif

	if !exists('g:TagHighlightSettings')
		let g:TagHighlightSettings = {}
	endif
	let g:TagHighlightSettings['DoNotGenerateTags'] = 'True'

	"nmap <F1> yyjp>>^dW:s/([^)]*)//g<CR>iprintf("TRACE: <ESC>A<BSlash>n");<ESC>:noh<CR>
	nmap ZZ :echo "Save and exit prevented! =)"<CR>
	map <F3> :FufCoverageFile<CR>
	nmap <F8> :cn<CR>
	nmap <F7> :cN<CR>
	nmap <F5> "zyiw:Search \<<C-R>z\><CR><CR>:cw<CR>
	nmap <F6> "zyiw:tabf <C-R>%<CR>:tag <C-R>z<CR>
	nmap <S-F5> :make<CR>
	nmap <C-B> :echo substitute(system('git blame -L '.line('.').','.line('.').' '.Relpath(@%)), '^\([^(]*([^)]*)\).*$', '\1', '')<CR>
	nmap <C-B>c :execute '!git show '.substitute(system('git blame -L '.line('.').','.line('.').' '.Relpath(@%)), '^\(\x*\)\s.*$', '\1', '')<CR>
	nmap <C-\> "zyiw:ptag <C-R>z<CR>
	nmap g<C-\> "zyiw:ptj <C-R>z<CR>
	map gd "qyiw:call searchdecl("<C-R>q", 0, 1)<CR>:let @/='\<'.@q.'\>'<CR>:set hlsearch<CR>:echo @q<CR>
	inoremap <Nul> <Space> <BS><BS><C-X><C-O>
	noremap <M-Up> [{
	noremap <M-Down> ]}
	noremap <M-Left> [(
	noremap <M-Right> ])


	"//<editor-fold defaultstate="collapsed" desc="global references">
	"//</editor-fold>
	function! NetBeansFoldText()
		let line = getline(v:foldstart)
		let sub = substitute(line, "^\\s*//\\s*<editor-fold.*desc\\s*=\\s*\"\\([^\"]*\\).*$", " [ \\1 ] ", '') 
		return sub
	endf
	"set foldtext=NetBeansFoldText()

	function! NetBeansFoldExpr(lineNum)
		let line = getline(a:lineNum)
		let is_fold_begin = (line =~ "^\\s*//\\s*<editor-fold")
		let is_fold_end = (line =~ "^\\s*//\\s*</editor-fold")
		let result = is_fold_begin ? "a1" : (is_fold_end ? "s1" : "=")
		return result
	endf
	"set foldexpr=NetBeansFoldExpr(v:lnum) " SLOW!
	"set foldmethod=expr

	function! GetTextBetweenPositions(line1, col1, line2, col2)
		let lines = getline(a:line1, a:line2)
		let lines[-1] = lines[-1][: a:col2 - 2]
		let lines[0] = lines[0][a:col1 - 1:]
		return join(lines, "\n")
	endf

	function! GetCppNamespace()
		let res = []
		let save_cursor = getpos('.')
		let [l, p] = [0, 0]
		let [l, p] = searchpairpos('{', '', '}', 'b')
		while l != 0 || p != 0
			let [l2, p2] = searchpos('namespace\(\s\|\n\)*\S*\(\s\|\n\)*{', 'becWn')
			if l == l2 && p == p2
				let [sl, sp] = searchpos('namespace\(\s\|\n\)*\zs\ze\S*\(\s\|\n\)*{', 'becWn')
				let [el, ep] = searchpos('namespace\(\s\|\n\)*\S*\zs\ze\(\s\|\n\)*{', 'becWn')
				call insert(res, GetTextBetweenPositions(sl, sp, el, ep))
			endif
			let [l, p] = searchpairpos('{', '', '}', 'bW')
		endw
		call setpos('.', save_cursor)
		return res
	endf

	function! GetCppPath()
		let res = []
		let save_cursor = getpos('.')
		let [l, p] = [0, 0]
		let [l, p] = searchpairpos('{', '', '}', 'b')
		while l != 0 || p != 0
			let [l2, p2] = searchpos('namespace\(\s\|\n\)*\S*\(\s\|\n\)*{', 'becWn')
			if l == l2 && p == p2
				let [sl, sp] = searchpos('namespace\(\s\|\n\)*\zs\ze\S*\(\s\|\n\)*{', 'becWn')
				let [el, ep] = searchpos('namespace\(\s\|\n\)*\S*\zs\ze\(\s\|\n\)*{', 'becWn')
				call insert(res, GetTextBetweenPositions(sl, sp, el, ep))
			endif
			let [l2, p2] = searchpos('\(class\|struct\)\(\s\|\n\)*\S*\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
			if l == l2 && p == p2
				let [sl, sp] = searchpos('\(class\|struct\)\(\s\|\n\)*\zs\ze\S*\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
				let [el, ep] = searchpos('\(class\|struct\)\(\s\|\n\)*\S*\zs\ze\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
				call insert(res, GetTextBetweenPositions(sl, sp, el, ep))
			endif
			let [l2, p2] = searchpos(')\(\s\|\n\)*\(const\(\s\|\n\)*\)\?{', 'becWn')
			if l == l2 && p == p2
				let save_cursor_2 = getpos('.')
				call searchpos('\zs\ze)\(\s\|\n\)*\(const\(\s\|\n\)*\)\?{', 'becW')
				call searchpairpos('(', '', ')', 'bW')
				let [sl, sp] = searchpos('[^:,\s\n\t]\(\s\|\n\)\zs\ze\S*\(\s\|\n\)*(', 'becWn')
				let [el, ep] = searchpos('[^:,\s\n\t]\(\s\|\n\)\S*\zs\ze\(\s\|\n\)*(', 'becWn')
				let res = filter(split(GetTextBetweenPositions(sl, sp, el, ep), '::'), 'v:val != "while" && v:val != "for" && v:val != "if"') + res
			endif
			let [l, p] = searchpairpos('{', '', '}', 'bW')
		endw
		call setpos('.', save_cursor)
		return res
	endf

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
		return GetTagsInContext(a:symbol, GetCppPath())
	endf

	function! GotoTag(tag)
		let path = Relpath(a:tag['filename'])
		execute 'edit ' . path
		silent execute a:tag['cmd']
	endf

	function! Goto(symbol)
		let tags = GetTags(a:symbol)
		if len(tags) > 0
			call GotoTag(tags[0])
		else
			call searchdecl(a:symbol, 0, 1)
		end
	endf

	function! GetCommonSubstrLen(s1, s2)
		let i = 0
		for i in range(min([strlen(a:s1), strlen(a:s2)]))
			if a:s1[i] != a:s2[i]
				return i
			end
		endfor
		return i + 1
	endf

	function! GetCommonSublistLen(l1, l2)
		let i = 0
		for i in range(min([len(a:l1), len(a:l2)]))
			if a:l1[i] != a:l2[i]
				return i
			end
		endfor
		return i + 1
	endf


	function GetTagNamespace(tag)
		let result=[]
		if has_key(a:tag, 'namespace')
			let result = split(a:tag['namespace'], '::')
		else
			if has_key(a:tag, 'struct')
				let result = split(a:tag['struct'], '::')
				"call remove(result, -1)
			end
			if has_key(a:tag, 'class')
				let result = split(a:tag['class'], '::')
				"call remove(result, -1)
			end
		end
		return result
	endf

	function GetIncludeFile(symbol)
		let std_includes = {}
		function! ExtendIncludes(dict, file, symbols)
			for s in a:symbols
				let a:dict[s] = a:file
			endfor
		endf
		call ExtendIncludes(std_includes, 'stdio.h', [ 'fclose', 'fopen', 'freopen', 'fdopen', 'remove', 'rename', 'rewind', 'tmpfile', 'Функции', 'для', 'операций', 'ввода-вывода', 'clearerr', 'feof', 'ferror', 'fflush', 'fgetpos', 'fgetc', 'fgets', 'fputc', 'fputs', 'ftell', 'fseek', 'fsetpos', 'fread', 'fwrite', 'getc', 'getchar', 'gets', 'printf', 'vprintf', 'fprintf', 'vfprintf', 'sprintf', 'snprintf', 'vsprintf', 'perror', 'putc', 'putchar', 'fputchar', 'scanf', 'vscanf', 'fscanf', 'vfscanf', 'sscanf', 'vsscanf', 'setbuf', 'setvbuf', 'tmpnam', 'ungetc', 'puts' ])
		call ExtendIncludes(std_includes, 'memory.h', [ 'memcpy', 'memmove', 'memchr', 'memcmp', 'memset', 'strcat', 'strncat', 'strchr', 'strrchr', 'strcmp', 'strncmp', 'strcoll', 'strcpy', 'strncpy', 'strerror', 'strlen', 'strspn', 'strcspn', 'strpbrk', 'strstr', 'strtok', 'strxfrm' ])
		call ExtendIncludes(std_includes, 'vector', [ 'vector' ])
		call ExtendIncludes(std_includes, 'string', [ 'string', 'basic_string' ])
		call ExtendIncludes(std_includes, 'set', [ 'set' ])
		call ExtendIncludes(std_includes, 'map', [ 'map' ])
		call ExtendIncludes(std_includes, 'list', [ 'list' ])
		call ExtendIncludes(std_includes, 'deque', [ 'deque' ])
		call ExtendIncludes(std_includes, 'queue', [ 'queue' ])
		call ExtendIncludes(std_includes, 'memory', [ 'memory' ])
		call ExtendIncludes(std_includes, 'stdexcept', [ 'logic_error', 'domain_error', 'invalid_argument', 'length_error', 'out_of_range', 'runtime_error', 'range_error', 'overflow_error', 'underflow_error' ])
		call ExtendIncludes(std_includes, 'iostream', [ 'istream', 'ostream', 'basic_istream', 'basic_ostream', 'cin', 'cout', 'cerr', 'endl' ])
		call ExtendIncludes(std_includes, 'algorithm', [ 'for_each', 'find', 'find_if', 'find_end', 'find_first_of', 'adjacent_find', 'count', 'count_if', 'mismatch', 'equal', 'search', 'search_n', 'copy', 'copy_backward', 'swap', 'swap_ranges', 'iter_swap', 'transform', 'replace', 'replace_if', 'replace_copy', 'replace_copy_if', 'fill', 'fill_n', 'generate', 'generate_n', 'remove', 'remove_if', 'remove_copy', 'remove_copy_if', 'unique', 'unique_copy', 'reverse', 'reverse_copy', 'rotate', 'rotate_copy', 'random_shuffle', 'partition', 'stable_partition', 'sort', 'stable_sort', 'partial_sort', 'partial_sort_copy', 'nth_element', 'lower_bound', 'upper_bound', 'equal_range', 'binary_search', 'merge', 'inplace_merge', 'includes', 'set_union', 'set_intersection', 'set_difference', 'set_symmetric_difference', 'push_heap', 'pop_heap', 'make_heap', 'sort_heap', 'min', 'max', 'min_element', 'max_element', 'lexicographical_compare', 'next_permutation', 'prev_permutation' ])
		call ExtendIncludes(std_includes, 'functional', [ 'unary_function', 'binary_function', 'plus', 'minus', 'multiplies', 'divides', 'modulus', 'negate', 'equal_to', 'not_equal_to', 'greater', 'less', 'greater_equal', 'less_equal', 'logical_and', 'logical_or', 'logical_not', 'not1', 'not2', 'bind1st', 'bind2nd', 'ptr_fun', 'mem_fun', 'mem_fun_ref', 'unary_negate', 'binary_negate', 'binder1st', 'binder2nd', 'pointer_to_unary_function', 'pointer_to_binary_function', 'mem_fun_t', 'mem_fun1_t', 'const_mem_fun_t', 'const_mem_fun1_t', 'mem_fun_ref_t', 'mem_fun1_ref_t', 'const_mem_fun_ref_t', 'const_mem_fun1_ref_t' ])
		call ExtendIncludes(std_includes, 'streambuf', [ 'streambuf' ])
		call ExtendIncludes(std_includes, 'utility', [ 'pair' ])
		call ExtendIncludes(std_includes, 'sstream', [ 'stringstream', 'istringstream', 'ostringstream', 'basic_stringstream', 'basic_istringstream', 'basic_ostringstream' ])
		call ExtendIncludes(std_includes, 'fstream', [ 'fstream', 'ifstream', 'ofstream', 'basic_fstream', 'basic_ifstream', 'basic_ofstream' ])
		call ExtendIncludes(std_includes, 'type_info', [ 'type_info', 'bad_cast', 'bad_typeid' ])

		if has_key(std_includes, a:symbol)
			return std_includes[a:symbol]
		end

		func! MyCompare(a1, a2)
			let ns1 = GetTagNamespace(a:a1)
			let ns2 = GetTagNamespace(a:a2)
			let res = (len(ns1) - GetCommonSublistLen(ns1, s:ns)) - (len(ns2) - GetCommonSublistLen(ns2, s:ns))
			if res == 0
				let res = GetCommonSublistLen(ns2, s:ns) - GetCommonSublistLen(ns1, s:ns)
			end
			return res
		endf

		let s:ns = GetCppNamespace()
		let tags = filter(taglist("\\<".a:symbol."\\>"), 'v:val["filename"] =~ "\\.\\(h\\|hpp\\)$"') " Headers only
		call sort(tags, 'MyCompare')
		let s:filenames = map(copy(tags), "v:val['filename']")
		let tags = filter(copy(tags), 'index(s:filenames, v:val["filename"], v:key + 1)==-1')
		let s:filenames = map(copy(tags), "Relpath(v:val['filename'])")

		if len(s:filenames) == 0
			echo "No tags found!"
			return ''
		end

		if len(s:filenames) == 1
			return s:filenames[0]
		end

		let ns1 = GetTagNamespace(tags[0])
		let ns2 = GetTagNamespace(tags[1])
		if ns1 == s:ns && ns2 != s:ns
			return s:filenames[0]
		end
		if GetCommonSublistLen(ns1, s:ns) == len(s:ns) && GetCommonSublistLen(ns2, s:ns) != len(s:ns)
			return s:filenames[0]
		end
		if GetCommonSublistLen(ns1, s:ns) == len(ns1) && GetCommonSublistLen(ns2, s:ns) != len(ns2)
			return s:filenames[0]
		end

		function! IncludesComplete(A,L,P)
			return s:filenames
		endf
		return input('Multiple tags found, make your choice: ', s:filenames[0], 'customlist,IncludesComplete')
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

	function! AddInclude(inc)
		if strlen(a:inc) == 0
			return
		end
		if search('#include <'.escape(a:inc, '&*./\').'>', 'bWn') != 0
			echo '#include <'.a:inc.'> already exists!'
			return
		end
		let save_cursor = getpos('.')
		let l = search('#include', 'bW')
		if l == 0
			call setpos('.', [save_cursor[0], 1, 1, save_cursor[3]])
			if strlen(getline(1)) != 0
				let l = search('^$', 'Wc')
			end
			call append(l, ['', '#include <'.a:inc.'>', ''])
			let lines_inserted = 3
		else
			call append(l, '#include <'.a:inc.'>')
			let lines_inserted = 1
			let b = search('^$', 'Wbcn')
			let e = search('^$', 'Wcn')
			call SortBuf(b + 1, e - 1)
		end
		call setpos('.', [save_cursor[0], save_cursor[1] + lines_inserted, save_cursor[2], save_cursor[3]])
		for i in range(lines_inserted)
			normal! 
		endfor
		redraw
		echo '#include <'.a:inc.'>'
	endf

	if (filereadable(".vimrc") && (getcwd() != $HOME))
		source .vimrc
	endif
endif
