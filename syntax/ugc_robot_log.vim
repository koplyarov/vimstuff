if exists("b:current_syntax")
	finish
endif

syntax match logDate /^\d\{4}-\d\{2}-\d\{2}/
syntax match logTime /\zsT\d\{2}:\d\{2}:\d\{2}\S*/
syntax match logThreadId /\s\zs\[\d\+\]\ze\s/
syntax match logLevelYtTransaction /Transaction \x\+-\x\+-\x\+-\x\+.*$/
syntax match logLevelYtOperation /Operation \x\+-\x\+-\x\+-\x\+.*$/
syntax match logLevelYtRsp /RSP \x\+-\x\+-\x\+-\x\+.*$/
syntax match logLevelInfo /\[INFO\].*$/
syntax match logLevelWarning /\[WARNING\].*/
syntax match logLevelError /\[ERROR\].*/

highlight link logDate Type
highlight link logTime Function
highlight link logThreadId Comment
highlight link logLevelYtTransaction Special
highlight link logLevelYtOperation Special
highlight link logLevelYtRsp Special
highlight link logLevelWarning StatusLine
highlight link logLevelError Error

let b:current_syntax = "ugc_robot_log"
