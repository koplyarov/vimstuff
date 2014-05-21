function Config(filename, defaultValues)
	let self = {}

	function self._load()
		let cfg = {}
		if filereadable(self._filename)
			for l in readfile(self._filename)
				let m = matchlist(l, '^\([^:]\+\):\(.*\)$')
				let cfg[m[1]] = m[2]
			endfor
		end
		call extend(self._values, cfg)
	endf

	function self._save()
		call writefile(values(map(copy(self._values), 'v:key.":".v:val')), self._filename)
	endf

	function self.getValue(key)
		return self._values[a:key]
	endf

	function self.setValue(key, val)
		let self._values[a:key] = a:val
		call self._save()
	endf

	let self._filename = a:filename
	let self._values = copy(a:defaultValues)

	call self._load()

	return self
endf
