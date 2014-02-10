function VimPluginException(msg)
	return "VimPluginException: ".a:msg
endf


function VimNamespace(ns)
	if !exists('s:VimNamespace')
		let s:VimNamespace = {}

		function s:VimNamespace.getRaw()
			return deepcopy(self._ns)
		endf

		function s:VimNamespace.compareSymbols(s1, s2)
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

	let self = copy(s:VimNamespace)
	let self._ns = a:ns
	return self
endf


function VimLocationPathEntry(type, name)
	let self = { 'type': a:type, 'name': a:name }
	return self
endf


function VimLocationPath(rawPath)
	if !exists('s:VimLocationPath')
		let s:VimLocationPath = {}

		function s:VimLocationPath.getRaw()
			return deepcopy(self._rawPath)
		endf

		function s:VimLocationPath.getNamespace()
			return VimNamespace(map(filter(self.getRaw(), 'v:val["type"] == "namespace"'), 'v:val["name"]'))
		endf

		function s:VimLocationPath.getTagRegex()
			return map(map(self.getRaw(), 'v:val["name"]'), '(strlen(v:val) > 0) ? v:val : "__anon\\d*"')
		endf

		function s:VimLocationPath.toString()
			return join(map(self.getRaw(), 'v:val["name"]'), '::')
		endf
	end

	let self = copy(s:VimLocationPath)
	let self._rawPath = a:rawPath
	return self
endf


function VimLocation(rawLocation)
	if !exists('s:VimLocation')
		let s:VimLocation = {}

		function s:VimLocation.getRaw()
			return deepcopy(self._rawLocation)
		endf

		function s:VimLocation.getBufNum()
			return self._rawLocation[0]
		endf

		function s:VimLocation.getLineNum()
			return self._rawLocation[1]
		endf

		function s:VimLocation.getColumnNum()
			return self._rawLocation[2]
		endf

		function s:VimLocation.endOfPrevLine()
			return VimLocation([ self.getBufNum(), self.getLineNum() - 1, len(getline(self.getLineNum() - 1)) + 1, 0 ])
		endf

		function s:VimLocation.beginOfNextLine()
			return VimLocation([ self.getBufNum(), self.getLineNum() + 1, 1, 0 ])
		endf

		function s:VimLocation.goto(...)
			if a:0 == 1
				call insert(a:1, VimLocation(getpos('.')))
			end
			call setpos('.', self.getRaw())
		endf

		function s:VimLocation.goBack(locationStack)
			if empty(a:locationStack)
				throw "VimLocation: location stack empty!"
			end
			let top = remove(a:locationStack, 0)
			call top.goto()
		endf

		function s:VimLocation.getLocationPath()
			let res = []
			return VimLocationPath(res)
		endf
	end

	let self = copy(s:VimLocation)
	let self._rawLocation = a:rawLocation
	return self
endf


function VimSyntax()
	let self = Syntax()

	let self.symbolDelimiter = '.'

	return self
endf


function VimPlugin()
	let self = LangPlugin()

	call self.autocompleteSettings.enableAutoInvoke(1)
	call self.autocompleteSettings.setAutoInvokationKeys('\<C-N>')

	let self.fileExtensions = [ 'vim' ]
	let self.syntax = VimSyntax()
	let self.indexer = CTagsIndexer(self)
	let self.createLocation = function('VimLocation')

	function self.onActivated()
		au BufWritePre <buffer> :call b:lang_plugin.removeTrailingWhitespaces()
	endf

	return self
endf


let g:vim_plugin = VimPlugin()

au BufRead,BufNewFile *.vim,vimrc,.vimrc call ActivateLangPlugin(g:vim_plugin)
