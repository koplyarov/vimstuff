function CSharpPluginException(msg)
	return "CSharpPluginException: ".a:msg
endf


function CSharpNamespace(ns)
	if !exists('s:CSharpNamespace')
		let s:CSharpNamespace = {}

		function s:CSharpNamespace.getRaw()
			return deepcopy(self._ns)
		endf

		function s:CSharpNamespace.compareSymbols(s1, s2)
			let ns = self.getRaw()
			let ns1 = a:s1.getScope()
			let ns2 = a:s2.getScope()
			let res = (len(ns1) - GetCommonSublistLen(ns1, ns)) - (len(ns2) - GetCommonSublistLen(ns2, ns))
			if res == 0
				let res = GetCommonSublistLen(ns2, ns) - GetCommonSublistLen(ns1, ns)
			end
			return res
		endf
	end

	let self = copy(s:CSharpNamespace)
	let self._ns = a:ns
	return self
endf


function CSharpLocationPathEntry(type, name)
	let self = { 'type': a:type, 'name': a:name }
	return self
endf


function CSharpLocationPath(rawPath)
	if !exists('s:CSharpLocationPath')
		let s:CSharpLocationPath = {}

		function s:CSharpLocationPath.getRaw()
			return deepcopy(self._rawPath)
		endf

		function s:CSharpLocationPath.getNamespace()
			return CSharpNamespace(map(filter(self.getRaw(), 'v:val["type"] == "namespace"'), 'v:val["name"]'))
		endf

		function s:CSharpLocationPath.getTagRegex()
			return map(self.getRaw(), 'v:val["name"]')
		endf

		function s:CSharpLocationPath.toString()
			return join(map(self.getRaw(), 'v:val["name"]'), '::')
		endf
	end

	let self = copy(s:CSharpLocationPath)
	let self._rawPath = a:rawPath
	return self
endf


function CSharpLocation(rawLocation)
	if !exists('s:CSharpLocation')
		let s:CSharpLocation = {}

		function s:CSharpLocation.getRaw()
			return deepcopy(self._rawLocation)
		endf

		function s:CSharpLocation.getLocationPath()
			let res = []
			let save_cursor = getpos('.')
			call setpos('.', self.getRaw())
			let [l, p] = [0, 0]
			let [l, p] = searchpairpos('{', '', '}', 'b')
			while l != 0 || p != 0
				let [l2, p2] = searchpos('namespace\(\s\|\n\)*\S*\(\s\|\n\)*{', 'becWn')
				if l == l2 && p == p2
					let [sl, sp] = searchpos('namespace\(\s\|\n\)*\zs\ze\S*\(\s\|\n\)*{', 'becWn')
					let [el, ep] = searchpos('namespace\(\s\|\n\)*\S*\zs\ze\(\s\|\n\)*{', 'becWn')
					let ns_res = map(split(GetTextBetweenPositions(sl, sp, el, ep), '\.'), 'CSharpLocationPathEntry("namespace", v:val)')
					let res = ns_res + res
				endif
				let [l2, p2] = searchpos('\(class\|struct\)\(\s\|\n\)*\S*\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
				if l == l2 && p == p2
					let [sl, sp] = searchpos('\(class\|struct\)\(\s\|\n\)*\zs\ze\S*\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
					let [el, ep] = searchpos('\(class\|struct\)\(\s\|\n\)*\S*\zs\ze\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
					call insert(res, CSharpLocationPathEntry('class', GetTextBetweenPositions(sl, sp, el, ep)))
				endif
				let [l2, p2] = searchpos(')\(\s\|\n\)*\(const\(\s\|\n\)*\)\?{', 'becWn')
				if l == l2 && p == p2
					call searchpos('\zs\ze)\(\s\|\n\)*\(const\(\s\|\n\)*\)\?{', 'becW')
					call searchpairpos('(', '', ')', 'bW')
					let [sl, sp] = searchpos('[^:,\s\n\t]\(\s\|\n\)\zs\ze\S*\(\s\|\n\)*(', 'becWn')
					let [el, ep] = searchpos('[^:,\s\n\t]\(\s\|\n\)\S*\zs\ze\(\s\|\n\)*(', 'becWn')
					let func_res = filter(split(GetTextBetweenPositions(sl, sp, el, ep), '\.'), 'v:val != "while" && v:val != "for" && v:val != "if"')
					let func_res = map(func_res, 'CSharpLocationPathEntry("function_or_class", v:val)')
					let res = func_res + res
				endif
				let [l, p] = searchpairpos('{', '', '}', 'bW')
			endw
			call setpos('.', save_cursor)
			return CSharpLocationPath(res)
		endf
	end

	let self = copy(s:CSharpLocation)
	let self._rawLocation = a:rawLocation
	return self
endf


function CSharpSyntax()
	let self = {}

	let self.symbolDelimiter = '.'

	function self.getImportLine(dependency)
		return 'using '.a:dependency.';'
	endf

	function self.getImportRegex(regex)
		return 'using\s\+\('.a:regex.'\);'
	endf

	return self
endf


let g:include_priorities = []


function CSharpPlugin()
	let self = LangPlugin()

	call self.autocompleteSettings.enableAutoInvoke(1)
	call self.autocompleteSettings.setAutoInvokationKeys('\<C-N>')

	let self.fileExtensions = [ 'cs' ]
	let self.syntax = CSharpSyntax()
	let self.indexer = CTagsIndexer(self)
	let self.createLocation = function('CSharpLocation')

	let dotNet = CTagsFrameworkInfo()
	call dotNet.addImports('System.Collections.Generic', [ 'IDictionary', 'IList' ]) " ...
	call self.indexer.registerFramework(dotNet)

	function self.filterImportableSymbols(symbols)
		return a:symbols
	endf

	function self.getImportForSymbol(symbol)
		return join(a:symbol.getScope(), '.')
	endf

	function self.gotoLocalSymbol(symbol)
		call searchdecl(a:symbol, 0, 1)
	endf

	return self
endf


let g:csharp_plugin = CSharpPlugin()

au BufRead,BufNewFile *.cs call ActivateLangPlugin(g:csharp_plugin)
