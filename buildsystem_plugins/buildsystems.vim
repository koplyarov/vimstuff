function BuildSystemException(msg)
	return 'Build system exception: '.a:msg
endf

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

	if has_key(g:buildsystem, 'build')
		call MapKeys('buildsystem.build', 'nmap <silent>', ':call g:buildsystem.build(g:buildsystem.getBuildTarget())<CR>')
	end

	if has_key(g:buildsystem, 'buildAll')
		call MapKeys('buildsystem.buildAll', 'nmap <silent>', ':call g:buildsystem.buildAll()<CR>')
	end

	if has_key(g:buildsystem, 'patchQuickFix')
		au QuickfixCmdPost make nested if g:buildsystem.patchQuickFix() | silent! cn | cw | else | ccl | end
	end
endf

function s:GetBuildConfigNames(A, L, P)
	return join(keys(g:buildsystem.getAvailableBuildConfigs()), "\n")
endf

function s:BuildPlatform(platform)
	if !has_key(g:buildsystem.getAvailableBuildConfigs(), a:platform)
		throw BuildSystemException('Platform '.a:platform.' not found!')
	end
	call g:buildsystem.setBuildConfig(a:platform)
endf

function s:BuildTarget(target)
	call g:buildsystem.setBuildTarget(a:target)
endf

command! -nargs=1 -complete=custom,<SID>GetBuildConfigNames BuildPlatform call <SID>BuildPlatform('<args>')
command! -nargs=? BuildTarget call <SID>BuildTarget('<args>')
command! -nargs=? Build call g:buildsystem.build('<args>')

call DetectBuildSystem()
