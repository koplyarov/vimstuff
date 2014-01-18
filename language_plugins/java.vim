function JavaPluginException(msg)
	return "JavaPluginException: ".a:msg
endf


function JavaNamespace(ns)
	if !exists('s:JavaNamespace')
		let s:JavaNamespace = {}

		function s:JavaNamespace.getRaw()
			return deepcopy(self._ns)
		endf

		function s:JavaNamespace.compareSymbols(s1, s2)
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

	let self = copy(s:JavaNamespace)
	let self._ns = a:ns
	return self
endf


function JavaLocationPathEntry(type, name)
	let self = { 'type': a:type, 'name': a:name }
	return self
endf


function JavaLocationPath(rawPath)
	if !exists('s:JavaLocationPath')
		let s:JavaLocationPath = {}

		function s:JavaLocationPath.getRaw()
			return deepcopy(self._rawPath)
		endf

		function s:JavaLocationPath.getNamespace()
			return JavaNamespace(map(filter(self.getRaw(), 'v:val["type"] == "namespace"'), 'v:val["name"]'))
		endf

		function s:JavaLocationPath.getTagRegex()
			return map(self.getRaw(), 'v:val["name"]')
		endf

		function s:JavaLocationPath.toString()
			return join(map(self.getRaw(), 'v:val["name"]'), '::')
		endf
	end

	let self = copy(s:JavaLocationPath)
	let self._rawPath = a:rawPath
	return self
endf


function JavaLocation(rawLocation)
	if !exists('s:JavaLocation')
		let s:JavaLocation = {}

		function s:JavaLocation.getRaw()
			return deepcopy(self._rawLocation)
		endf

		function s:JavaLocation.getLocationPath()
			" TODO: parse package string
			let res = []
			let save_cursor = getpos('.')
			call setpos('.', self.getRaw())
			let [l, p] = [0, 0]
			let [l, p] = searchpairpos('{', '', '}', 'b')
			while l != 0 || p != 0
				let [l2, p2] = searchpos('\(class\)\(\s\|\n\)*\S*\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
				if l == l2 && p == p2
					let [sl, sp] = searchpos('\(class\)\(\s\|\n\)*\zs\ze\S*\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
					let [el, ep] = searchpos('\(class\)\(\s\|\n\)*\S*\zs\ze\(\s\|\n\)*\(\:\([^{};]\|\n\)*\)\?{', 'becWn')
					call insert(res, JavaLocationPathEntry('class', GetTextBetweenPositions(sl, sp, el, ep)))
				endif
				let [l2, p2] = searchpos(')\(\s\|\n\)*\(const\(\s\|\n\)*\)\?{', 'becWn')
				if l == l2 && p == p2
					call searchpos('\zs\ze)\(\s\|\n\)*\(const\(\s\|\n\)*\)\?{', 'becW')
					call searchpairpos('(', '', ')', 'bW')
					let [sl, sp] = searchpos('[^:,\s\n\t]\(\s\|\n\)\zs\ze\S*\(\s\|\n\)*(', 'becWn')
					let [el, ep] = searchpos('[^:,\s\n\t]\(\s\|\n\)\S*\zs\ze\(\s\|\n\)*(', 'becWn')
					let func_res = filter(split(GetTextBetweenPositions(sl, sp, el, ep), '\.'), 'v:val != "while" && v:val != "for" && v:val != "if"')
					let func_res = map(func_res, 'JavaLocationPathEntry("function_or_class", v:val)')
					let res = func_res + res
				endif
				let [l, p] = searchpairpos('{', '', '}', 'bW')
			endw
			call setpos('.', save_cursor)
			return JavaLocationPath(res)
		endf
	end

	let self = copy(s:JavaLocation)
	let self._rawLocation = a:rawLocation
	return self
endf


function JavaSyntax()
	let self = {}

	let self.symbolDelimiter = '.'

	function self.getImportLine(dependency)
		return 'import '.a:dependency.';'
	endf

	function self.getImportRegex(regex)
		return 'import\s\+\('.a:regex.'\);'
	endf

	return self
endf


let g:include_priorities = []


function JavaPlugin()
	let self = LangPlugin()

	call self.autocompleteSettings.enableAutoInvoke(1)
	call self.autocompleteSettings.setAutoInvokationKeys('\<C-N>')

	let self.fileExtensions = [ 'java' ]
	let self.syntax = JavaSyntax()
	let self.indexer = CTagsIndexer(self)
	let self.createLocation = function('JavaLocation')

	function self.filterImportableSymbols(symbols)
		return a:symbols
	endf

	function self.getImportForSymbol(symbol)
		return join(a:symbol.getScope(), '.')
	endf

	function self.gotoLocalSymbol(symbol)
		call searchdecl(a:symbol, 0, 1)
	endf

	function self.onActivated()
		setlocal omnifunc=javacomplete#Complete
	endf

	return self
endf


let g:java_plugin = JavaPlugin()

au BufRead,BufNewFile *.java call ActivateLangPlugin(g:java_plugin)
