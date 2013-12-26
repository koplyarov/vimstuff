function GlslSyntax()
	let self = Syntax()

	let self.keywords = [ ]

	return self
endf


function GlslPlugin()
	let self = LangPlugin()

	let self.fileExtensions = [ 'vsh', 'psh' ]
	let self.syntax = GlslSyntax()

	function self.getAlternativeFile(filename)
		let substitute_ext = { 'vsh': 'psh', 'psh': 'vsh' }
		for src in keys(substitute_ext)
			let regex = '\.'.src.'$'
			if a:filename =~ regex
				for dst in split(substitute_ext[src], ';')
					let alternative_filename = substitute(a:filename, regex, '.'.dst, '')
					if filereadable(alternative_filename)
						return alternative_filename
					end
				endfor
				return alternative_filename
			end
		endfor
	endf

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
