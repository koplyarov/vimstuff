function PythonPluginException(msg)
	return "PythonPluginException: ".a:msg
endf


function PythonNamespace(ns)
	if !exists('s:PythonNamespace')
		let s:PythonNamespace = {}

		function s:PythonNamespace.getRaw()
			return deepcopy(self._ns)
		endf

		function s:PythonNamespace.compareSymbols(s1, s2)
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

	let self = copy(s:PythonNamespace)
	let self._ns = a:ns
	return self
endf


function PythonLocationPathEntry(type, name)
	let self = { 'type': a:type, 'name': a:name }
	return self
endf


function PythonLocationPath(rawPath)
	if !exists('s:PythonLocationPath')
		let s:PythonLocationPath = {}

		function s:PythonLocationPath.getRaw()
			return deepcopy(self._rawPath)
		endf

		function s:PythonLocationPath.getNamespace()
			return PythonNamespace(map(filter(self.getRaw(), 'v:val["type"] == "namespace"'), 'v:val["name"]'))
		endf

		function s:PythonLocationPath.getTagRegex()
			return map(map(self.getRaw(), 'v:val["name"]'), '(strlen(v:val) > 0) ? v:val : "__anon\\d*"')
		endf

		function s:PythonLocationPath.toString()
			return join(map(self.getRaw(), 'v:val["name"]'), '::')
		endf
	end

	let self = copy(s:PythonLocationPath)
	let self._rawPath = a:rawPath
	return self
endf


function PythonLocation(rawLocation)
	if !exists('s:PythonLocation')
		let s:PythonLocation = {}

		function s:PythonLocation.getRaw()
			return deepcopy(self._rawLocation)
		endf

		function s:PythonLocation.getBufNum()
			return self._rawLocation[0]
		endf

		function s:PythonLocation.getLineNum()
			return self._rawLocation[1]
		endf

		function s:PythonLocation.getColumnNum()
			return self._rawLocation[2]
		endf

		function s:PythonLocation.endOfPrevLine()
			return PythonLocation([ self.getBufNum(), self.getLineNum() - 1, len(getline(self.getLineNum() - 1)) + 1, 0 ])
		endf

		function s:PythonLocation.beginOfNextLine()
			return PythonLocation([ self.getBufNum(), self.getLineNum() + 1, 1, 0 ])
		endf

		function s:PythonLocation.goto(...)
			if a:0 == 1
				call insert(a:1, PythonLocation(getpos('.')))
			end
			call setpos('.', self.getRaw())
		endf

		function s:PythonLocation.goBack(locationStack)
			if empty(a:locationStack)
				throw "PythonLocation: location stack empty!"
			end
			let top = remove(a:locationStack, 0)
			call top.goto()
		endf

		function s:PythonLocation.getLocationPath()
			let res = []
			return PythonLocationPath(res)
		endf
	end

	let self = copy(s:PythonLocation)
	let self._rawLocation = a:rawLocation
	return self
endf


function PythonSyntax()
	let self = Syntax()

	let self.symbolDelimiter = '.'
	let self.keywords = ['False', 'None', 'True', 'and', 'as', 'assert', 'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield']

	function self.getImportLine(dependency)
		return 'import <'.a:dependency.'>'
	endf

	function self.getImportRegex(regex)
		return 'import \('.a:regex.'\)'
	endf

	return self
endf


function PythonPlugin()
	let self = LangPlugin()

	call self.autocompleteSettings.enableAutoInvoke(1)
	call self.autocompleteSettings.setAutoInvokationKeys('\<C-N>')

	let self.fileExtensions = [ 'py' ]
	let self.syntax = PythonSyntax()
	let self.indexer = CTagsIndexer(self)
	let self.createLocation = function('PythonLocation')

	function self.onActivated()
		au BufWritePre <buffer> :call b:lang_plugin.removeTrailingWhitespaces()
	endf

	return self
endf


let g:python_plugin = PythonPlugin()

au BufRead,BufNewFile *.py call ActivateLangPlugin(g:python_plugin)
