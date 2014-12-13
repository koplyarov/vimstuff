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
	set cot+=longest
	set cot-=preview
	if has("foldcolumn")
		set foldcolumn=1
	end
	set fillchars=vert:\|
	filetype plugin on

	colorscheme torte

	autocmd VimLeavePre * colorscheme default

	runtime keyMappings.vim
	runtime my_scripts/toolkit.vim
	runtime my_scripts/system.vim
	runtime my_scripts/config.vim
	runtime buildsystem_plugins/buildsystems.vim
	runtime vcs_plugins/vcs.vim
	runtime indexer_plugins/ctags.vim
	runtime language_plugins/LangPlugin.vim
	runtime language_plugins/cpp.vim
	runtime language_plugins/csharp.vim
	runtime language_plugins/java.vim
	runtime language_plugins/glsl.vim
	runtime language_plugins/python.vim
	runtime language_plugins/vim.vim

	let g:clang_jumpto_declaration_key = "c<C-]>"
	let g:clang_jumpto_back_key = "c<C-O>"
	let g:clang_complete_auto = 1
	let g:clang_complete_macros = 1
	let g:clang_remove_duplicating = 1

	for p in ['/usr/lib/'] + split(glob('/usr/lib/llvm-*/lib'), '\n')
		if filereadable(p.'/libclang.so')
			let g:clang_library_path = p
			break
		end
	endfor

	" Resetting colors for ubuntu 12.10 vim =(
	hi Pmenu			ctermfg=7 ctermbg=5 gui=bold guifg=White guibg=DarkGray
	hi PmenuSel			ctermfg=7 ctermbg=0 guibg=DarkGrey
	hi PmenuSbar		ctermbg=7 guibg=Grey
	hi PmenuThumb		cterm=reverse gui=reverse

	let g:NERDCustomDelimiters = {
		\ 'qml': { 'left': '//', 'leftAlt': '/*', 'rightAlt': '*/' }
	\ }

	let g:snippets_dir = $HOME.'/.vim/my-snippets'
	let g:fuf_coveragefile_exclude = '\v\~$|\.(o|exe|dll|bak|png|jpg|orig|sw[po]|pyc)$|(^|[/\\])\.(hg|git|bzr)($|[/\\])'

	function! HasNERDTrees()
		let treeBufNames = []
		for i in range(1, tabpagenr("$"))
			if len(GetTabVar(i, 'NERDTreeBufName')) > 0
				return 1
			endif
		endfor
		return 0
	endf

	function! DoSearch(expression)
		let excludes_list = ["*map", "*tex", "*html", "*git*", "*doxygen*", "*svn*", "*entries", "*all-wcprops", "depend*", "*includecache", "tags", "valgrind*", "types_*.taghl", "types_*.vim"]
		if exists("g:exclude_from_search")
			let excludes_list += g:exclude_from_search
		end
		let excludedirs_list = ["etc", "build", ".git", "CMakeFiles", ".svn", "doxygen"]
		let excludes_string = "--exclude=\"" . join(excludes_list, "\" --exclude=\"") . "\" --exclude-dir=\"" . join(excludedirs_list, "\" --exclude-dir=\"") . "\""
		execute "grep " . excludes_string . " -rI \"" . a:expression . "\" ./"
	endf

	function! InitGitHotKeys()
		map <2-LeftMouse> <LeftMouse> if match(expand('<cword>'), '\x\{40\}') != -1 <Bar> execute "!clear; git show --color ".expand('<cword>')." <Bar> less -RSX"<Bar> end<CR>
		nmap <CR> if match(expand('<cword>'), '\x\{40\}') != -1 <Bar> execute "!clear; git show --color ".expand('<cword>')." <Bar> less -RSX"<Bar> end<CR>
	endf

	let s:previous_num_chars_on_current_line = -1
	let s:old_cursor_position = []
	function s:OnCursorMovedInsertMode()
		let current_position = getpos('.')
		if current_position == s:old_cursor_position
			return
		end

		let num_chars_in_current_cursor_line = strlen( getline('.') )

		let moved_vertically = (s:old_cursor_position == []) || (current_position[1] != s:old_cursor_position[1])
		if moved_vertically
			let s:old_cursor_position = current_position
			let s:previous_num_chars_on_current_line = num_chars_in_current_cursor_line
			return
		end

		let s:old_cursor_position = current_position

		if s:previous_num_chars_on_current_line != -1 && num_chars_in_current_cursor_line > s:previous_num_chars_on_current_line
			exec 'doautocmd User CharTypedInBuf_'.bufnr('%')
		end
		let s:previous_num_chars_on_current_line = num_chars_in_current_cursor_line
	endf

	command! -nargs=1 -complete=tag Search call DoSearch('<args>')

	au CursorMovedI * call <SID>OnCursorMovedInsertMode()
	au BufRead,BufNewFile *.git call InitGitHotKeys()
	au BufRead,BufNewFile *.c,*.cpp,*.h,*.hpp set filetype=cpp.doxygen
	au BufRead,BufNewFile *.qml set filetype=qml
	au BufRead,BufNewFile *.i set filetype=swig
	au BufRead,BufNewFile *.vsh,*.psh set filetype=glsl
	au BufRead,BufNewFile *.decl set filetype=qml
	au BufRead,BufNewFile *.cmix set filetype=cmix
	au BufNewFile,BufRead *.pas,*.PAS set ft=pascal
	au! Syntax qml source $HOME/.vim/syntax/qml.vim

    inoremap <expr> <Down> <SID>HookCompleteFocusMove("\<Down>", 1)
    inoremap <expr> <Up> <SID>HookCompleteFocusMove("\<Up>", -1)
    inoremap <expr> <C-N> <SID>HookCompleteFocusMove("\<C-N>", 1)
    inoremap <expr> <C-P> <SID>HookCompleteFocusMove("\<C-P>", -1)
    inoremap <expr> <CR> <SID>HookEnterKey()

	let s:focusedAutocompleteItem = 0
	function s:HookCompleteFocusMove(key, direction)
		if pumvisible()
			let s:focusedAutocompleteItem += a:direction
		end
		return a:key
	endf

	function! s:HookEnterKey()
		if pumvisible()
			return GetFocusedAutocompleteItem() == 0 ? "\<C-N>\<C-Y>" : "\<C-Y>"
		end
		return "\<CR>"
	endf

	function s:ResetFocusedAutocompleteItem()
		let s:focusedAutocompleteItem = 0
	endf

	function GetFocusedAutocompleteItem()
		return s:focusedAutocompleteItem
	endf

	let s:complete_done_hack_state = 0
	function s:CompleteDoneHandler()
		if s:complete_done_hack_state == 1
			call s:ResetFocusedAutocompleteItem()
			if s:has_longest == 1
				set cot+=longest
			end
			let s:has_longest = -1
			let s:complete_done_hack_state = 0
		else
			let s:complete_done_hack_state = 1
		end
	endf

	"if exists("#CompleteDone")
		"au CompleteDone * call <SID>CompleteDoneHandler()
	"else
		au CursorMovedI * if !pumvisible() | call <SID>CompleteDoneHandler() | end
	"end

	let s:has_longest = -1
	function s:StartIdentifierCompletion(completionKeys)
		let pos = getpos('.')
		let line = getline('.')
		if !pumvisible() && (line[pos[2] - 2] =~ '[A-Za-z_]' && line[pos[2] - 3] !~ '[A-Za-z0-9_]' || (has_key(b:lang_plugin, 'testInvokeAutocomplete') && b:lang_plugin.testInvokeAutocomplete()))
			let s:has_longest = (&cot =~ '\<longest\>')
			set cot-=longest
			call feedkeys(a:completionKeys."\<C-P>", 'n')
		end
	endf

	function EnableAutocompleteAutoTriggering(bufnum, completionKeys)
		exec 'au User CharTypedInBuf_'.a:bufnum.' call <SID>StartIdentifierCompletion("'.a:completionKeys.'")'
	endf

	"if exists('*pathogen#infect')
		call pathogen#infect()
	"end

	" Remove clang-complete stupid mappings
	"au BufRead,BufNewFile *.h,*.hpp,*.c,*.cpp silent! execute 'iunmap <Tab>'

	if !exists('g:TagHighlightSettings')
		let g:TagHighlightSettings = {}
	endif
	let g:TagHighlightSettings['DoNotGenerateTags'] = 'True'

	"nmap <F1> yyjp>>^dW:s/([^)]*)//g<CR>iprintf("TRACE: <ESC>A<BSlash>n");<ESC>:noh<CR>
	nmap ZZ :echo "Save and exit prevented! =)"<CR>
	nmap <C-C> :echo "Type  :quit<Enter>  to exit Vim"<CR>
	call MapKeys('langPlugin.toggleComment',		['nmap', 'vmap'],			'<BSlash>c<Space>')
	call MapKeys('general.findFile',				'nmap',						':FufCoverageFile<CR>')
	call MapKeys('general.findSymbol',				'nmap',						':FufTag!<CR>')
	call MapKeys('general.findSymbolInBuffer',		'nmap',						':FufBufferTag<CR>')
	call MapKeys('general.findLineInBuffer',		'nmap',						':FufLine!<CR>')
	call MapKeys('general.findChangeListEntry',		'nmap',						':FufChangeList!<CR>')
	call MapKeys('general.nextError',				'nmap',						':cn<CR>')
	call MapKeys('general.prevError',				'nmap',						':cN<CR>')
	call MapKeys('general.search',					'nmap',						':call DoSearch("\\<".expand("<cword>")."\\>")<CR><CR>:cw<CR>')
	call MapKeys('general.prevTab',					['nmap', 'vmap', 'imap'],	'<Esc>gT')
	call MapKeys('general.nextTab',					['nmap', 'vmap', 'imap'],	'<Esc>gt')

	noremap gd 1gd
	inoremap <Nul> <Space> <BS><BS><C-X><C-O>
	noremap <M-Up> [{zz
	noremap <M-Down> ]}zz
	"noremap <M-Left> [(
	"noremap <M-Right> ])

	function! MirrorOrToggleNERDTree()
		if HasNERDTrees()
			if exists('t:NERDTreeBufName')
				NERDTreeToggle
			else
				NERDTreeMirror
			end
		else
			NERDTreeToggle
		end
	endf

	call MapKeys('plugins.vimCommander.toggle',			'nmap',	':call VimCommanderToggle()<CR>')
	call MapKeys('plugins.nerdTree.toggle',				'nmap',	':call MirrorOrToggleNERDTree()<CR>')
	call MapKeys('plugins.nerdTree.findCurrentFile',	'nmap',	':let @q = bufname("%") <Bar> NERDTreeMirror <Bar> execute bufwinnr(@q)."wincmd w" <Bar> NERDTreeFind<CR>')

	function JumpToNextBuf(back)
		let jumplimit = 100
		let orig_buf = bufnr('%')

		let i = 0
		while bufnr('%') == orig_buf && i < jumplimit
			execute 'normal!' (a:back ? "\<C-O>" : "1\<C-I>")
			let i += 1
		endw

		let end_buf = bufnr('%')

		if a:back && i == jumplimit && end_buf == orig_buf
			buffer #
			echohl WarningMsg
			echomsg 'Jump list limit exceeded; switching to alternate buffer'
			echohl None
		endif
	endfunction

	call MapKeys('general.prevBuf', ['nmap', 'vmap', 'imap'], '<Esc>:call JumpToNextBuf(1)<CR>')
	call MapKeys('general.nextBuf', ['nmap', 'vmap', 'imap'], '<Esc>:call JumpToNextBuf(0)<CR>')

	function SmartTab(op)
		let pos = getpos('.')
		let cur_line = getline(pos[1])
		let col_num = pos[2] - 1
		let reference_lines = [ getline(pos[1] - 1), getline(pos[1] + 1) ]

		let visible_column = 0
		for i in range(0, col_num - 1)
			let visible_column += (cur_line[i] == '	') ? &tabstop : 1
		endfor

		let offsets = []
		for ref_line in reference_lines
			let ofs = -1
			let visible_column_tmp = 0
			for c in split(ref_line, '\zs')
				let c_width= (c == '	') ? (&tabstop - (visible_column_tmp % &tabstop)) : 1
				let visible_column_tmp += c_width
				if visible_column_tmp <= visible_column
					continue
				endif
				if !(c =~ '	')
					if ofs != -1
						break
					else
						continue
					end
				end
				let ofs = visible_column_tmp
			endfor
			if ofs != -1
				call add(offsets, ofs)
			end
		endfor

		if a:op == 'add'
			let ofs = empty(offsets) ? -1 : min(offsets)
			let tabs_to_insert = (ofs != -1) ? ((ofs - visible_column) / &tabstop + ((ofs - visible_column) % &tabstop != 0)) : 1
			if tabs_to_insert == 0
				let tabs_to_insert = 1
			end
			let line_start = col_num > 0 ? cur_line[0:(col_num - 1)] : ''
			let line_end = cur_line[(col_num):]
			let tabs_in_the_line = len(matchstr(line_end, '^	*'))
			let cursor_shift = tabs_to_insert
			let tabs_to_insert = max([tabs_to_insert - tabs_in_the_line, 0])
			call setline('.', line_start.repeat('	', tabs_to_insert).line_end)
			call setpos('.', [pos[0], pos[1], pos[2] + cursor_shift, pos[3]])
		elseif a:op == 'remove'
			throw NotImplementedException()
		else
			throw VimStuffException('Unknown SmartTab operation: '.a:op)
		endif
	endf


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

	function! GetManSections(str)
		return split(system("man -f ".a:str." 2>&1 | sed -n 's/[^(]*(\\([^)]*\\)).*$/\\1/p'"), '\n')
	endf

	function! GetManSection(str)
		let sections = GetManSections(a:str)
		return index(sections, b:man_section) != -1 ? b:man_section : (len(sections) != 0 ? sections[0] : -1)
	endf

	function! OpenMan(str, ...)
		let man_section = string(len(a:000) == 0 ? -1 : (a:000[0] == 0 ? -1 : a:000[0]))
		let sections = GetManSections(a:str)
		if man_section == -1 && len(sections) > 0
			let man_section = sections[0]
		end

		let man_pages_bufnr_new = bufnr('vimstuff man pages reader ['.a:str.', '.man_section.']', 1)
		if !exists('g:man_pages_bufnr')
			let g:man_pages_bufnr = man_pages_bufnr_new
		end

		let window_nr = bufwinnr(g:man_pages_bufnr)
		if window_nr == -1
			top split
		else
			exec window_nr."wincmd w"
		end
		let g:man_pages_bufnr = man_pages_bufnr_new
		execute 'buffer '.g:man_pages_bufnr

		if !exists('b:man_pages_bufnr_has_mappings')
			map <buffer> <CR> :call OpenMan(expand('<cword>'), GetManSection(expand('<cword>')))<CR>
			let b:man_pages_bufnr_has_mappings = 1
		end
		let b:man_section = man_section

		let section = man_section == -1 ? '' : man_section.' '

		set ma
		set noswf
		silent 1,$delete _
		silent! execute 'r!man '.section.a:str.' | col -b'
		silent 1delete _
		set ft=man
		set noma
		set nomod
	endf

	if glob('AndroidManifest.xml') =~ ''
		if filereadable('project.properties')
			let s:androidSdkPath = '/home/koplyarov/sdk/android-sdk-linux'
			" the following line uses external tools and is less portable
			"let s:androidTargetPlatform = system('grep target= project.properties | cut -d \= -f 2')
			vimgrep /target=/j project.properties
			let s:androidTargetPlatform = split(getqflist()[0].text, '=')[1]
			let s:targetAndroidJar = s:androidSdkPath . '/platforms/' . s:androidTargetPlatform . '/android.jar'
			if !empty($CLASSPATH)
				let $CLASSPATH = s:targetAndroidJar . ':' . $CLASSPATH
			else
				let $CLASSPATH = s:targetAndroidJar
			endif
		end
	endif

	nmap K :<C-U>call OpenMan(expand('<cword>'), v:count)<CR>

	command! -nargs=+ -complete=shellcmd Man call OpenMan(<f-args>)

	" Making ^M line endings less visible
	for i in ['cterm', 'gui']
		for j in ['fg', 'bg']
			let c = synIDattr(hlID('Normal'), 'bg', i)
			if (c != -1)
				exec 'hi CarriageReturn ' . i . j . '=' . c
			endif
		endfor
	endfor
	match CarriageReturn /\r$/

	function DoDeleteHiddenBuffers()
		let tpbl=[]
		call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
		for buf in filter(range(1, bufnr('$')), 'bufexists(v:val) && index(tpbl, v:val)==-1')
			silent execute 'bwipeout' buf
		endfor
	endfunction

	command! -nargs=0 DeleteHiddenBuffers call DoDeleteHiddenBuffers()

	if (filereadable(".vimrc") && (getcwd() != $HOME))
		source .vimrc
	endif
endif
