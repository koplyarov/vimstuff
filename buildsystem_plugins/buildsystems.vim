runtime buildsystem_plugins/cmake.vim

function DetectBuildSystem()
	if filereadable('CMakeLists.txt')
		let b:buildsystem = g:cmake_buildsystem
	end

	if !exists('b:buildsystem')
		return
	end
	
	if has_key(b:buildsystem, 'buildFile')
		nmap <silent> <buffer> <C-F7> :call b:buildsystem.buildFile('<C-R>%')<CR>
	end

	if has_key(b:buildsystem, 'buildAll')
		nmap <silent> <buffer> <S-F5> :call b:buildsystem.buildAll()<CR>
	end
endf

au BufRead,BufNewFile *.* call DetectBuildSystem()
