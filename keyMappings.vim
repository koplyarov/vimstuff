let s:keyMapping = {}

let s:mappedKeys = {}

function SetKeysMapping(name, keys)
	let s:keyMapping[a:name] = a:keys
	if has_key(s:mappedKeys, a:name)
		let mk = s:mappedKeys[a:name]
		call UnmapKeys(a:name)
		call MapKeys(a:name, mk.mapCmds, mk.cmd)
	end
endf

function MapKeys(name, mapCmds, cmd)
	if has_key(s:keyMapping, a:name)
		let mapCmds = type(a:mapCmds) != type([]) ? [a:mapCmds] : a:mapCmds
		let keys = type(s:keyMapping[a:name]) != type([]) ? [s:keyMapping[a:name]] : s:keyMapping[a:name]
		let s:mappedKeys[a:name] = { 'mapCmds': mapCmds, 'keys': keys, 'cmd': a:cmd }
		for key in keys
			for mapCmd in mapCmds
				exec mapCmd.' '.key.' '.a:cmd
			endfor
		endfor
	end
endf

function UnmapKeys(name)
	if has_key(s:mappedKeys, a:name)
		let mk = s:mappedKeys[a:name]
		for key in mk.keys
			for mapCmd in mk.mapCmds
				let unmapCmd = substitute(mapCmd, '\(nore\)\?map', 'unmap', '')
				exec unmapCmd.' '.key
			endfor
		endfor
		unlet s:mappedKeys[a:name]
	end
endf


call SetKeysMapping('general.search',					'<F5>')
call SetKeysMapping('general.findFile',					'<F3>')
call SetKeysMapping('general.findSymbol',				'O1;5R') " <C-F3>
call SetKeysMapping('general.prevError',				'<F7>')
call SetKeysMapping('general.nextError',				'<F8>')
call SetKeysMapping('general.prevTab',					'<M-PageUp>')
call SetKeysMapping('general.nextTab',					'<M-PageDown>')
call SetKeysMapping('general.prevBuf',					'<M-Left>')
call SetKeysMapping('general.nextBuf',					'<M-Right>')

call SetKeysMapping('langPlugin.addImport',				'<C-K>')
call SetKeysMapping('langPlugin.gotoSymbol',			't<C-]>')
call SetKeysMapping('langPlugin.openAlternativeFile',	'<F4>')
call SetKeysMapping('langPlugin.printScope',			'<C-P>')
call SetKeysMapping('langPlugin.searchDerived',			'<C-F5>')
call SetKeysMapping('langPlugin.searchUsages',			'<S-F5>')
call SetKeysMapping('langPlugin.toggleComment',			'<F2>')
call SetKeysMapping('langPlugin.openSymbolInNewTab',	'<F6>')
call SetKeysMapping('langPlugin.openSymbolPreview',		'<C-\>')
call SetKeysMapping('langPlugin.openDocumentation',		'K')

call SetKeysMapping('vcs.showCommit',					[])
call SetKeysMapping('vcs.blame',						[])

call SetKeysMapping('buildsystem.buildFile',			'<C-F7>')
call SetKeysMapping('buildsystem.buildAll',				'<S-F5>')

call SetKeysMapping('plugins.vimCommander.toggle',		[ '<C-F><C-F>', '<C-F>f' ])
call SetKeysMapping('plugins.nerdTree.toggle',			[ '<C-N><C-N>', '<C-N>n' ])
call SetKeysMapping('plugins.nerdTree.findCurrentFile',	[ '<C-N><C-F>', '<C-N>f' ])
