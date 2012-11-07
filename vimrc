set hidden
set tabstop=4
set shiftwidth=4
set number
set hlsearch
set mouse=a
set cursorline
set autoindent
set makeprg=make\ -j8
set isfname-==
set wildmode=longest,list,full
set foldcolumn=1
set fillchars=vert:\|
filetype plugin on

colorscheme torte

" Resetting colors for ubuntu 12.10 vim =(
hi Pmenu			ctermfg=7 ctermbg=5 gui=bold guifg=White guibg=DarkGray
hi PmenuSel			ctermfg=7 ctermbg=0 guibg=DarkGrey
hi PmenuSbar		ctermbg=7 guibg=Grey
hi PmenuThumb		cterm=reverse gui=reverse

let g:fuf_coveragefile_exclude = '\v\~$|\.(o|exe|dll|bak|png|jpg|orig|sw[po]|pyc)$|(^|[/\\])\.(hg|git|bzr)($|[/\\])'

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

if exists('g:createCodeFileScript')
	function! DoNewFile(filename)
		let command_str = g:createCodeFileScript . " " . a:filename
		call system(command_str)
		let open_cmd = "e " . a:filename
		silent execute open_cmd
	endf
end

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
	map <C-K> mX"wyiw:keepj tag <C-R>w<CR>:while match(@%, "\.h$") == -1 && match(@%, "\.hpp$") == -1<CR>keepj tn<CR>endw<CR>:let @q=Relpath(@%)<CR>:keepj normal 'XG<CR>:keepj ?#include<CR>:noh<CR>o#include <<C-R>q><ESC>:keepj normal V{<CR>:sort u<CR>:keepj normal `X<CR>:echo "#include <<C-R>q>"<CR>
endf

command! -nargs=1 -complete=file NewFile call DoNewFile("<args>")
command! -nargs=1 -complete=tag Search call DoSearch('<args>')

au BufRead,BufNewFile *.h,*.hpp,*.c,*.cpp call InitCppHotKeys()
au BufRead,BufNewFile *.qml set filetype=qml
au BufRead,BufNewFile *.decl set filetype=qml
au BufRead,BufNewFile *.cmix set filetype=cmix
au BufNewFile,BufRead *.pas,*.PAS set ft=pascal
au! Syntax qml source $HOME/.vim/syntax/qml.vim

"if exists('*pathogen#infect')
	call pathogen#infect()
"end

if exists('*ResetSnippets')
	au BufRead,BufNewFile *h,*hpp,*.c,*.cpp call ResetSnippets('cpp') | call ResetSnippets('c') | call ExtractSnipsFile('/home/koplyarov/.vim/my-snippets/cpp.snippets', 'cpp') | call ExtractSnipsFile('/home/koplyarov/.vim/my-snippets/c.snippets', 'cpp')
endif

"nmap <F1> yyjp>>^dW:s/([^)]*)//g<CR>iprintf("TRACE: <ESC>A<BSlash>n");<ESC>:noh<CR>
map <F3> :FufCoverageFile<CR>
nmap <F8> :cn<CR>
nmap <F7> :cN<CR>
nmap <F5> "zyiw:Search \<<C-R>z\><CR><CR>:cw<CR>
nmap <F6> "zyiw:tabf <C-R>%<CR>:tag <C-R>z<CR>
nmap <S-F5> :make<CR>
nmap <C-\> "zyiw:ptag <C-R>z<CR>
nmap g<C-\> "zyiw:ptj <C-R>z<CR>
inoremap <Nul> <Space> <BS><BS><C-X><C-O>


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

function! GetCppNamespace()
	let save_cursor = getpos(".")
	let [l, p] = [0, 0]
	let [l, p] = searchpairpos('{', '', '}', 'b')
	while l != 0 || p != 0
		let [l2, p2] = searchpos('namespace\(\s\|\n\)*\S*\(\s\|\n\)*{', 'becWn')
		if l == l2 && p == p2
			let ns = searchpos('namespace\(\s\|\n\)*\(\S*\)\(\s\|\n\)*{', 'becWnp')
			echo join(ns, ', ')
		endif
		let [l, p] = searchpairpos('{', '', '}', 'bW')
	endw
	call setpos('.', save_cursor)
endf

if (filereadable(".vimrc") && (getcwd() != $HOME))
	source .vimrc
endif
