if exists("b:current_syntax")
  finish
endif

runtime! syntax/cpp.vim
unlet b:current_syntax

runtime! syntax/jinja.vim
unlet b:current_syntax

let b:current_syntax = "jinja_cpp"
