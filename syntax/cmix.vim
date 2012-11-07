" Vim syntax file
" Language:	Mixed C and Assembly GCC objdump disassembly format.
" Maintainer:	Vihar Rai   oxcrete@yahoo.com
" Last Change:	2001 Oct 17
" Version:      0.1
" File Names:   *.dis
" Comment:      gcc -g -c xxx.c             /*output is xxx.o*/
"               objdump -S xxx.o > xxx.dis  /* creates disassembly mixed with source */
"               It does not recognize any opcodes, so it's processor independent.

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Read the C syntax to start with
if version < 600
  so <sfile>:p:h/c.vim
else
  runtime! syntax/c.vim
  unlet b:current_syntax
endif

" Match the labels and Assembly lines
syn match       cMixLabel                "^\x\+\s\+<.*>:$"
syn match       cMixAsm                  "^\s*\x\+:\s\+\x\+.*$"

"------------------------------------------------------------------
"   GUIDE
"
"  First Token breakdown 
"  00000084 <_main>:
"
"       ^       Beginning of line
"       \x\+    one or more hex
"       \s\+    one or more space
"       <.*>    zero or more characters enclosed within < >
"       :       literally :
"       $       End of Line.
"
"  Second Token breakdown
"  75:	69 64 0a 00 49 6e 76 	imul   $0x61766e49,0x0(%edx,%ecx,1),%esp
"
"       ^       Beginning of line
"       \s*     zero or more spaces
"       \x\+    one or more hex digit
"       :       literally ":"
"       \s\+    one or more space
"       \x\+    one or more hex
"       $       EOL
"-------------------------------------------------------------------

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_cmix_syn_inits")
  if version < 508
    let did_cmix_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink cMixLabel               DiffDelete
  HiLink cMixAsm                 Special
  delcommand HiLink
endif

let b:current_syntax = "cmix"

" vim: ts=8
