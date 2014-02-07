function GlslSyntax()
	let self = Syntax()

	let self.keywords = [ ]

	return self
endf


function GlslPlugin()
	let self = LangPlugin()

	call self.autocompleteSettings.enableAutoInvoke(1)
	call self.autocompleteSettings.setAutoInvokationKeys('\<C-N>')

	let self.fileExtensions = [ 'vsh', 'psh' ]
	let self.alternativeExtensionsMap = { 'vsh': 'psh', 'psh': 'vsh' }
	let self.syntax = GlslSyntax()

	function self.gotoLocalSymbol(symbol)
		call searchdecl(a:symbol, 0, 1)
	endf

	function self.onActivated()
		au BufWritePre <buffer> :call b:lang_plugin.removeTrailingWhitespaces()
	endf

	return self
endf


let g:glsl_plugin = GlslPlugin()

au BufRead,BufNewFile *.vsh,*psh call ActivateLangPlugin(g:glsl_plugin)
