" ******************************************************
function! SingleLineLatexParEndings()
	" Creates the regexp that searches for single-line paragraph terminators
	let empty_s  = '^\s*'
	let empty_e  = '\s*$'
	let s:lpe:0  = '\%$'                      " the end of file (so that there is always a match)
	let s:lpe:1  = empty_s.'\$\$'.empty_e     " a line containing only '$$'
	let s:lpe:2  = empty_s.'\\begin'          " a line starting with '\begin'
	let s:lpe:3  = empty_s.'\\end'            " a line starting with '\end'
	let s:lpe:4  = empty_s.'{'.empty_e        " a line containing only '{'
	let s:lpe:5  = empty_s.'\\\a\+{'.empty_e  " a line containing only '\anycommand{'
	let s:lpe:6  = empty_s.'}'.empty_e        " a line containing only '}'
	let s:lpe:7  = empty_s.'.*%'              " a line having a comment somewhere
	let s:lpe:8  = empty_s.'\\\['.empty_e      " a line containing only '\['
	let s:lpe:9  = empty_s.'\\\]'.empty_e      " a line containing only '\]'
	
	let str = s:lpe:0
	let index = 1
	while index <= 9
		exe "let cur=s:lpe:".index
		let str = str.'\|'.cur
		let index = index + 1
	endwhile
	return str
	
	"return StringsSepCat('\|', ...)	
endfunction

" ******************************************************
function! MultiLineLatexParEndings()
	" Creates the regexp that searches for multi-line paragraph terminators,
	" i.e., terminators for which the text starts inlined after the terminator
	let empty_s  = '^\s*'
	let empty_e  = '\s*$'
	let s:lpe:0  = '\%$'                      " the end of file (so that there is always a match)
	let s:lpe:1  = empty_s.'\\item'           " a line starting with '\item'
	
	let str = s:lpe:0
	let index = 1
	while index <= 1
		exe "let cur=s:lpe:".index
		let str = str.'\|'.cur
		let index = index + 1
	endwhile
	return str
endfunction

" ******************************************************
" Position of the first occurrence before here (-1 if none)
function! SearchBackward(here, string)
	exe ":".(a:here+1)
	silent exe "?".a:string
	let str_occ = line(".")
	if str_occ > a:here
		return -1
	endif
	return str_occ
endfunction

" ******************************************************
" Position of the first occurrence after here (-1 if none)
function! SearchForward(here, string)
	exe ":".(a:here-1)
	silent exe "/".a:string
	let str_occ = line(".")
	if str_occ < a:here
		return -1
	endif
	return str_occ
endfunction

" ******************************************************
" Maximum among a set of positive numbers. Negative numbers are not considered.
" If all numbers are negative, -1 is returned
function! Max(...)
	let max = -1
	let index = 1
	while index <= a:0
		exe "let cur=a:".index
		if cur > max
			let max = cur
		endif
		let index = index + 1
	endwhile
	return max
endfunction

" ******************************************************
" Minimum among a set of positive numbers. Negative numbers are not considered.
" If all numbers are negative, -1 is returned
function! Min(...)
	let min = -1
	let index = 1
	while index <= a:0
		exe "let cur=a:".index
		if cur >= 0
			if cur < min || min == -1
				let min = cur
			endif
		endif
		let index = index + 1
	endwhile
	return min
endfunction
	

" ******************************************************
function! LatexParBegin()
	" Current position
	let here = line(".")
	
	" Beginning of the paragraph
	exe ':normal }'
	exe ":normal {"
	let par = line(".")

	let slp = SearchBackward( here, SingleLineLatexParEndings() ) + 1
	let mlp = SearchBackward( here, MultiLineLatexParEndings() )
	
	let pos = Max ( par, slp, mlp )

	" Moves back to starting cursor position 
	exe ":".here

	return pos
endfunction

" ******************************************************
function! LatexParEnd()
	" Current position
	let here = line(".")
	
	" Beginning of the paragraph
	exe ':normal }'
	let par = line(".")

	let slp = SearchForward( here,   SingleLineLatexParEndings() ) - 1
	let mlp = SearchForward( here+1, MultiLineLatexParEndings() ) - 1
	
	let pos = Min ( par, slp, mlp )

	" Moves back to starting cursor position 
	exe ":".here

	return pos
endfunction

" ******************************************************
function! FormatLatexPar()
	let here  = line(".")
	let top   = LatexParBegin()
	let bot   = LatexParEnd()

	if bot<here || top>here
		" We are on top of a paragraph ending, or on an empty line
		" We simply move to the following line
		exe ":".(here+1)
	else
		" We are in a standard paragraph.
		
		" Formats the lines between top and bot
		silent exe ':'.top.','.bot.'!fmt'

		" Moves at the begin of the next paragraph
		exe ":".top
		exe ":".(LatexParEnd()+1)
	endif
endfunction

" Maps FormatPar function to Ctrl-J
map  <C-j>  <ESC>:silent call FormatLatexPar()<CR>i
map! <C-j>  <ESC>:silent call FormatLatexPar()<CR>i

