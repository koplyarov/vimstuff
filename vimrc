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

	runtime keyMappings.vim
	runtime my_scripts/toolkit.vim
	runtime my_scripts/system.vim
	runtime buildsystem_plugins/buildsystems.vim
	runtime vcs_plugins/vcs.vim
	runtime indexer_plugins/ctags.vim
	runtime language_plugins/LangPlugin.vim
	runtime language_plugins/cpp.vim
	runtime language_plugins/csharp.vim

	let g:clang_jumpto_declaration_key = "c<C-]>"
	let g:clang_jumpto_back_key = "c<C-O>"

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
		let excludedirs_list = ["etc", "build", ".git", "CMakeFiles", ".svn"]
		let excludes_string = "--exclude=\"" . join(excludes_list, "\" --exclude=\"") . "\" --exclude-dir=\"" . join(excludedirs_list, "\" --exclude-dir=\"") . "\""
		execute "grep " . excludes_string . " -rI \"" . a:expression . "\" ./"
	endf

	function! InitGitHotKeys()
		map <2-LeftMouse> <LeftMouse> "zyiw:if match(@z, '\x\{40\}') != -1 <Bar> execute "!clear; git show --color ".@z." <Bar> less -RSX"<Bar> end<CR>
		nmap <CR> "zyiw:if match(@z, '\x\{40\}') != -1 <Bar> execute "!clear; git show --color ".@z." <Bar> less -RSX"<Bar> end<CR>
	endf

	command! -nargs=1 -complete=tag Search call DoSearch('<args>')

	au BufRead,BufNewFile *.git call InitGitHotKeys()
	au BufRead,BufNewFile *.qml set filetype=qml
	au BufRead,BufNewFile *.decl set filetype=qml
	au BufRead,BufNewFile *.cmix set filetype=cmix
	au BufNewFile,BufRead *.pas,*.PAS set ft=pascal
	au! Syntax qml source $HOME/.vim/syntax/qml.vim

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
	call MapKeys('langPlugin.toggleComment',		['nmap', 'vmap'],			'<BSlash>c<Space>')
	call MapKeys('general.findFile',				'nmap',						':FufCoverageFile<CR>')
	call MapKeys('general.findSymbol',				'nmap',						':FufTag!<CR>')
	call MapKeys('general.findSymbolInBuffer',		'nmap',						':FufBufferTag<CR>')
	call MapKeys('general.nextError',				'nmap',						':cn<CR>')
	call MapKeys('general.prevError',				'nmap',						':cN<CR>')
	call MapKeys('general.search',					'nmap',						'"zyiw:Search \<<C-R>z\><CR><CR>:cw<CR>')
	call MapKeys('langPlugin.openSymbolInNewTab',	'nmap',						'"zyiw:tabnew<CR>:tag <C-R>z<CR>')
	call MapKeys('langPlugin.openSymbolPreview',	'nmap',						'"zyiw:ptj <C-R>z<CR>')
	call MapKeys('general.prevTab',					['nmap', 'vmap', 'imap'],	'<Esc>gT')
	call MapKeys('general.nextTab',					['nmap', 'vmap', 'imap'],	'<Esc>gt')

	map gd "qyiw:call searchdecl("<C-R>q", 0, 1)<CR>:let @/='\<'.@q.'\>'<CR>:echo @q<CR>
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

	nmap K :<C-U>call OpenMan(expand('<cword>'), v:count)<CR>

	command! -nargs=+ -complete=shellcmd Man call OpenMan(<f-args>)

	function! CountTweets()
		normal gg
		silent! /^\d\+\s\?\S\+ \(.*\) ‏@.*$
		normal kdgg
		normal GNjdG
		silent! g/^\d\+\s\?\S\+ \(.*\) ‏@.*$/normal J
		silent! g/^\(\s*Показать\s\)\|\(Развернуть\)/d
		g/^\(\s*View\s\)\|\(Expand\)\|\(\s*from\s\)/d
		silent! %s/^\d\+ \S\+ \(.*\) ‏@.*$/=== \1/g
		silent! %s/^\sRetweeted by \(.*\)$/=== \1/g
		silent! %s/^\s\(.\+\)$/=== \1/g
		silent! v/^=== /d
		silent 1,$sor
		normal gg
		normal "zdG
		let @z = system('uniq -c | sort -rn', @z)
		normal "zP
	endf

	if (filereadable(".vimrc") && (getcwd() != $HOME))
		source .vimrc
	endif
endif
