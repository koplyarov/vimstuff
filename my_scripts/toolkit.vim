function SortBuf(begin, end)
	if a:begin >= a:end
		return
	end
	let lines = getline(a:begin, a:end)
	call sort(lines)
	for i in range(a:end - a:begin + 1)
		call setline(a:begin + i, lines[i])
	endfor
endf

function GetCommonSublistLen(l1, l2)
	let i = 0
	for i in range(min([len(a:l1), len(a:l2)]))
		if a:l1[i] != a:l2[i]
			return i
		end
	endfor
	return i + 1
endf

