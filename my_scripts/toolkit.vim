function! GetCommonSublistLen(l1, l2)
	let i = 0
	for i in range(min([len(a:l1), len(a:l2)]))
		if a:l1[i] != a:l2[i]
			return i
		end
	endfor
	return i + 1
endf

