let g:keyMapping = {}

let g:keyMapping['general.search']						= '<F5>'
let g:keyMapping['general.findFile']					= '<F3>'
let g:keyMapping['general.prevError']					= '<F7>'
let g:keyMapping['general.nextError']					= '<F8>'

let g:keyMapping['langPlugin.addImport']				= '<C-K>'
let g:keyMapping['langPlugin.gotoSymbol']				= 't<C-]>'
let g:keyMapping['langPlugin.openAlternativeFile']		= '<F4>'
let g:keyMapping['langPlugin.printScope']				= '<C-P>'
let g:keyMapping['langPlugin.searchDerived']			= '<C-F5>'
let g:keyMapping['langPlugin.toggleComment']			= '<F2>'
let g:keyMapping['langPlugin.openSymbolInNewTab']		= '<F6>'
let g:keyMapping['langPlugin.openSymbolPreview']		= '<C-\>'
let g:keyMapping['langPlugin.openDocumentation']		= 'K'

let g:keyMapping['buildsystem.buildFile']				= '<C-F7>'
let g:keyMapping['buildsystem.buildAll']				= '<S-F5>'

let g:keyMapping['plugins.vimCommander.toggle']			= [ '<C-F><C-F>', '<C-F>f' ]
let g:keyMapping['plugins.nerdTree.toggle']				= [ '<C-N><C-N>', '<C-N>n' ]
let g:keyMapping['plugins.nerdTree.findCurrentFile']	= [ '<C-N><C-F>', '<C-N>f' ]
