runtime buildsystem_plugins/cmake.vim

function DetectBuildSystem()
	if filereadable('CMakeLists.txt')
		let g:buildsystem = CMakeBuildSystem()
	end

	if !exists('g:buildsystem')
		return
	end
	
	if has_key(g:buildsystem, 'buildFile')
		nmap <silent> <C-F7> :call g:buildsystem.buildFile('<C-R>%')<CR>
	end

	if has_key(g:buildsystem, 'buildAll')
		nmap <silent> <S-F5> :call g:buildsystem.buildAll()<CR>
	end

	if has_key(g:buildsystem, 'patchQuickFix')
		au QuickfixCmdPost make nested if g:buildsystem.patchQuickFix() | silent! cn | cw | else | ccl | end
	end
endf

call DetectBuildSystem()
