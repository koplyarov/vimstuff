function LinuxProcess(pid)
	if !exists('s:LinuxProcess')
		let s:LinuxProcess = {}

		function s:LinuxProcess.isTerminated()
			call system('kill -0 '.self._pid)
			return v:shell_error != 0
		endf

		function s:LinuxProcess.getId()
			return self._pid
		endf

		function s:LinuxProcess.terminate()
			call system('kill '.self._pid)
		endf
	end

	let self = copy(s:LinuxProcess)
	let self._pid = a:pid
	return self
endf

function AsyncShell(cmd)
	let pid = system(a:cmd.' & echo $!')
	return LinuxProcess(pid)
endf
