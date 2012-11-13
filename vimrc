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
if has("foldcolumn")
	set foldcolumn=1
end
set fillchars=vert:\|
filetype plugin on

colorscheme torte

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
	map <C-K> "wyiw:call AddInclude(GetIncludeFile("\\<".@w."\\>"))<CR>
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

if 0 " exists('*ResetSnippets')
	au BufRead,BufNewFile *.h,*.hpp,*.c,*.cpp call ResetSnippets('cpp') | call ResetSnippets('c') | call ExtractSnipsFile('/home/koplyarov/.vim/my-snippets/cpp.snippets', 'cpp') | call ExtractSnipsFile('/home/koplyarov/.vim/my-snippets/c.snippets', 'c')
endif

if !exists('g:TagHighlightSettings')
	let g:TagHighlightSettings = {}
endif
let g:TagHighlightSettings['DoNotGenerateTags'] = 'True'

"nmap <F1> yyjp>>^dW:s/([^)]*)//g<CR>iprintf("TRACE: <ESC>A<BSlash>n");<ESC>:noh<CR>
map <F3> :FufCoverageFile<CR>
nmap <F8> :cn<CR>
nmap <F7> :cN<CR>
nmap <F5> "zyiw:Search \<<C-R>z\><CR><CR>:cw<CR>
nmap <F6> "zyiw:tabf <C-R>%<CR>:tag <C-R>z<CR>
nmap <S-F5> :make<CR>
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
	let res = ''
	let save_cursor = getpos('.')
	let [l, p] = [0, 0]
	let [l, p] = searchpairpos('{', '', '}', 'b')
	while l != 0 || p != 0
		let [l2, p2] = searchpos('namespace\(\s\|\n\)*\S*\(\s\|\n\)*{', 'becWn')
		if l == l2 && p == p2
			let [sl, sp] = searchpos('namespace\(\s\|\n\)*\zs\ze\S*\(\s\|\n\)*{', 'becWn')
			let [el, ep] = searchpos('namespace\(\s\|\n\)*\S*\zs\ze\(\s\|\n\)*{', 'becWn')
			if len(res) != 0
				let res = '::' . res
			end
			let res = GetTextBetweenPositions(sl, sp, el, ep) . res
		endif
		let [l, p] = searchpairpos('{', '', '}', 'bW')
	endw
	call setpos('.', save_cursor)
	return res
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

function GetIncludeFile(symbol)
	func! MyCompare(a1, a2)
		return GetCommonSubstrLen(a:a2['namespace'], s:ns) - GetCommonSubstrLen(a:a1['namespace'], s:ns)
	endf

	let s:ns = GetCppNamespace()
	let tags = filter(taglist(a:symbol), 'v:val["filename"] =~ "\\.\\(h\\|hpp\\)$"') " Headers only
	let tags = filter(tags, 'has_key(v:val, "namespace")') " Only symbols within a namespace
	let tags = sort(tags, 'MyCompare')

	if len(tags) == 0
		echo "No tags found!"
		return ''
	end

	if GetCommonSubstrLen(tags[0]['namespace'], s:ns) == strlen(s:ns) && GetCommonSubstrLen(tags[1]['namespace'], s:ns) != strlen(s:ns)
		echo Relpath(tags[0]['filename'])
		return Relpath(tags[0]['filename'])
	end

	echo "Multiple tags found! Adding " . Relpath(tags[0]['filename'])
	return Relpath(tags[0]['filename'])
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
	let save_cursor = getpos('.')
	let l = search('#include', 'bW')
	if l == 0
		call setpos('.', [save_cursor[0], 1, 1, save_cursor[3]])
		if strlen(getline(1)) == 0
			call append(0, ['#include <'.a:inc.'>'])
		else
			let l = search('^$', 'Wc')
			if l != 0
				call append(l, ['#include <'.a:inc.'>', ''])
			end
		end
	else
		call append(l, '#include <'.a:inc.'>')
		let b = search('^$', 'Wbcn')
		let e = search('^$', 'Wcn')
		call SortBuf(b + 1, e - 1)
	end
	call setpos('.', [save_cursor[0], save_cursor[1] + 1, save_cursor[2], save_cursor[3]])
endf

if (filereadable(".vimrc") && (getcwd() != $HOME))
	source .vimrc
endif
