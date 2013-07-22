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

	" Some settings for vtree-explorer
	let treeExplVertical=1
	let treeExplWinSize=40
	let treeExplDirSort=1

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

	function GetBuildDir()
		let ml = matchlist(&makeprg, '-C \(\S*\)')
		if len(ml) > 1
			return ml[1].'/'
		else
			return ''
		end
	endf

	function FixQuickFix()
		let build_dir = GetBuildDir()

		let has_entries = 0

		let qflist = getqflist()
		for entry in qflist
			if has_key(entry, 'bufnr') && entry['bufnr'] != 0
				let has_entries = 1
			end
			if exists('*CustomQuickFixPatcher')
				if CustomQuickFixPatcher(entry)
					continue
				end
			end
			if has_key(entry, 'bufnr') && entry['bufnr'] != 0
				let has_entries = 1
				let filename = bufname(entry['bufnr'])
				if !file_readable(filename) && exists('g:subdirectories')
					for dir in g:subdirectories
						if file_readable(dir.'/'.filename)
							let entry['bufnr']=bufnr(dir.'/'.filename, 1)
							break
						end
						if file_readable(build_dir.dir.'/'.filename)
							let entry['bufnr']=bufnr(build_dir.dir.'/'.filename, 1)
							break
						end
					endfor
				end
			end
		endfor
		call setqflist(qflist, 'r')
		return has_entries
	endf


	au QuickfixCmdPost make nested if FixQuickFix() | silent! cn | cw | else | ccl | end
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
	nmap <F2> <BSlash>c<Space>
	vmap <F2> <BSlash>c<Space>
	nmap ZZ :echo "Save and exit prevented! =)"<CR>
	map <F3> :FufCoverageFile<CR>
	nmap <F8> :cn<CR>
	nmap <F7> :cN<CR>
	nmap <F5> "zyiw:Search \<<C-R>z\><CR><CR>:cw<CR>
	nmap <F6> "zyiw:tabnew<CR>:tag <C-R>z<CR>
	nmap <S-F5> :make<CR>
	command! -nargs=0 GitBlame echo substitute(system('git blame -L '.line('.').','.line('.').' '.Relpath(@%)), '^\([^(]*([^)]*)\).*$', '\1', '')
	command! -nargs=0 GitShow execute '!git show '.substitute(system('git blame -L '.line('.').','.line('.').' '.Relpath(@%)), '^\(\x*\)\s.*$', '\1', '')
	"nmap <C-B> :GitBlame<CR>
	"nmap <C-B>c :GitShow<CR>
	nmap <C-\> "zyiw:ptag <C-R>z<CR>
	nmap g<C-\> "zyiw:ptj <C-R>z<CR>
	map gd "qyiw:call searchdecl("<C-R>q", 0, 1)<CR>:let @/='\<'.@q.'\>'<CR>:set hlsearch<CR>:echo @q<CR>
	inoremap <Nul> <Space> <BS><BS><C-X><C-O>
	noremap <M-Up> [{zz
	noremap <M-Down> ]}zz
	noremap <M-Left> [(
	noremap <M-Right> ])

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

	nmap <C-F><C-F> :call VimCommanderToggle() <CR>
	nmap <C-F>f :call VimCommanderToggle() <CR>
	nmap <C-N><C-N> :call MirrorOrToggleNERDTree() <CR>
	nmap <C-N>n :call MirrorOrToggleNERDTree() <CR>
	nmap <C-N><C-F> :let @q = bufname("%") <Bar> NERDTreeMirror <Bar> execute bufwinnr(@q).'wincmd w' <Bar> NERDTreeFind<CR>
	nmap <C-N>f :let @q = bufname("%") <Bar> NERDTreeMirror <Bar> execute bufwinnr(@q).'wincmd w' <Bar> NERDTreeFind<CR>


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
		if len(lines) == 0
			return ''
		end
		let lines[-1] = lines[-1][: a:col2 - 2]
		let lines[0] = lines[0][a:col1 - 1:]
		return join(lines, "\n")
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

	runtime my_scripts/toolkit.vim
	runtime language_plugins/LangPlugin.vim
	runtime language_plugins/cpp.vim
	runtime language_plugins/csharp.vim

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
