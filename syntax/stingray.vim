if exists("b:current_syntax_s")
	finish
endif

syntax match cmt /#.*$/
syntax match num /\<\d\+\>/
syntax match time /\(\(\<\d\+\>\.\<\d\+\>\.\<\d\+\>\)\? \<\d\+\>:\<\d\+\>\(:\<\d\+\>\)\?\)\|\(now\(+\d\+[sSmMhH]\?\)\?\)/
syntax match timeDuration /\d\+[sSmMhH]/

syntax keyword cmd key add age alarm all analog_mode antenna_power aspect aspect_conversion audio boot cancel cas channel choose close config crutch default disable down download dump dvbs dvbs2 echo eject emercom enable epg erase factory factory_reset format freq freqs get id info input languages led list log mail media modem mute parental_control pause play play_file playback provider providers quit receiver record remove remove_attachment removed repair rescan reset resolution restore resume save scan schedule seek select serial set show show_attachment sleep spdif speaker standby start step stop storage stream subscriptions subtitles suicide teletext test threads toggle_last trickspeed uhf ui ui_language unmute up user viewing volume watch watchdog on
syntax keyword constants on off true false TV Radio Trace Debug Info Warning Error

highlight link cmt Comment
highlight link num Number
highlight link time Keyword
highlight link timeDuration Keyword
highlight link constants Keyword
highlight link cmd Type

let b:current_syntax = "stingray"
