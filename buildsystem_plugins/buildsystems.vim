runtime buildsystem_plugins/cmake.vim

function DetectBuildSystem()
	if filereadable('CMakeLists.txt')
		let g:buildsystem = CMakeBuildSystem()
	end

	if !exists('g:buildsystem')
		return
	end
	
	if has_key(g:buildsystem, 'buildFile')
		call MapKeys('buildsystem.buildFile', 'nmap <silent>', ":call g:buildsystem.buildFile('<C-R>%')<CR>")
	end

	if has_key(g:buildsystem, 'buildAll')
		call MapKeys('buildsystem.buildAll', 'nmap <silent>', ':call g:buildsystem.buildAll()<CR>')
	end

	if has_key(g:buildsystem, 'patchQuickFix')
		au QuickfixCmdPost make nested if g:buildsystem.patchQuickFix() | silent! cn | cw | else | ccl | end
	end
endf

call DetectBuildSystem()
