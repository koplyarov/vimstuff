function CTagsPluginException(msg)
	return "CTagsPluginException: ".a:msg
endf


function CTagsSymbolInfo(rawTag, symbolDelimiter)
	if !exists('s:CTagsSymbolInfo')
		let s:CTagsSymbolInfo = {}

		function s:CTagsSymbolInfo.getScope()
			for key in ['namespace', 'struct', 'class']
				if has_key(self._rawTag, key)
					return split(self._rawTag[key], escape(self._symbolDelimiter, '&*./\'))
				end
			endfor
			throw CTagsPluginException('unknown tag type!')
		endf

		function s:CTagsSymbolInfo.goto()
			execute 'edit '.Relpath(self._rawTag['filename'])
			let cmd = self._rawTag['cmd']
			if cmd[0] == '/'
				let cmd = '/\M' . strpart(cmd, 1)
			endif
			silent execute cmd
		endf
	end

	let self = copy(s:CTagsSymbolInfo)
	let self._rawTag = a:rawTag
	let self._symbolDelimiter = a:symbolDelimiter
	return self
endf


function CTagsIndexer()
	let self = {}

	let self.getSymbolInfo = function('CTagsSymbolInfo')

	return self
endf

let g:ctags_indexer = CTagsIndexer()
