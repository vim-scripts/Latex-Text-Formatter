" ******************************************************
function! SingleLineLatexParEndings()
	" Creates the regexp that searches for single-line paragraph terminators
	let empty_s  = '^\s*'
	let empty_e  = '\s*$'
	let lpe0  = 'FMT_LTX_TERM'             " the terminator string
	let lpe1  = empty_s.'\$\$'.empty_e     " a line containing only '$$'
	let lpe2  = empty_s.'\\begin'          " a line starting with '\begin'
	let lpe3  = empty_s.'\\end'            " a line starting with '\end'
	let lpe4  = empty_s.'{'.empty_e        " a line containing only '{'
	let lpe5  = empty_s.'\\\a\+{'.empty_e  " a line containing only '\anycommand{'
	let lpe6  = empty_s.'}'.empty_e        " a line containing only '}'
	let lpe7  = empty_s.'.*%'              " a line having a comment somewhere
	let lpe8  = empty_s.'\\\['.empty_e     " a line containing only '\['
	let lpe9  = empty_s.'\\\]'.empty_e     " a line containing only '\]'
	
	let str = lpe0
	let index = 1
	while index <= 9
		exe "let cur=lpe".index
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
	let lpe0  = 'FMT_LTX_TERM'             " the terminator string
	let lpe1  = empty_s.'\\item'          " a line starting with '\item'
	
	let str = lpe0
	let index = 1
	while index <= 1
		exe "let cur=lpe".index
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
" Beginning of the multiline comment (assuming current line is a comment)
function! CommentStart(here)
	exe ":".(a:here)
	silent exe '?^[^%]\|^$'
	return line('.')+1
endfunction

" ******************************************************
" End of the multiline comment (assuming current line is a comment)
function! CommentEnd(here)
	exe ":".(a:here)
	silent exe '/^[^%]\|^$'
	return line('.')-1
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
function! LatexParBegin(here)
	" Beginning of the paragraph
	exe ":".a:here
	exe ':normal }'
	exe ":normal {"
	let par = line(".")

	let slp = SearchBackward( a:here, SingleLineLatexParEndings() ) + 1
	let mlp = SearchBackward( a:here, MultiLineLatexParEndings() )
	
	"echo 'lpb: ' a:here ' ' par ' ' slp ' ' mlp

	let pos = Min( a:here, Max ( par, slp, mlp ) )

	" Moves back to starting cursor position 
	exe ":".a:here

	return pos
endfunction

" ******************************************************
function! LatexParEnd(here)
	" Beginning of the paragraph
	exe ":".a:here
	exe ':normal }'
	let par = line(".")

	let slp = SearchForward( a:here,   SingleLineLatexParEndings() ) - 1
	let mlp = SearchForward( a:here+1, MultiLineLatexParEndings() ) - 1
	
	let pos = Max( a:here, Min ( par, slp, mlp ) )

	" Moves back to starting cursor position 
	exe ":".a:here

	return pos
endfunction

" ******************************************************
function! FormatComment(here, lvl)
	" if we are on a comment, goes into the recursive mode
	let top   = CommentStart(a:here)
	let bot   = CommentEnd(a:here)

	let buf   = @%

	" copies the multiline comment, and cleans a bit around
	exe ':'.top.','.bot.'d'
	exe ':e '.buf.'.fmttmp'
	exe ':put!'
	" removes the comment
	exe ':%s/^%//'
	" goes at the right line
	exe ':'.(a:here-top+1)
	
	" recursive call of FormatLatexPar
	call FormatLatexPar(a:lvl+1)

	" remembers position in the file
	let next = line(".")
	" removes the empty line at the end
	exe ':normal G'
	if a:lvl==0
		" The undo can be joined only for the original buffer
		exe ':undojoin | d'
	else
		exe ':d'
	endif
	" puts back the comment character and copies the text into the register
	exe ':%s/^/%/'
	exe ':'.next
	exe ':%d'
	" deletes the temporary buffer
	exe ':bd!'
	" copies back the text in the original buffer
	exe ':b '.buf
	exe ':'.top-1
	if a:lvl==0
		" The undo can be joined only for the original buffer
		exe ':undojoin | put'
	else
		exe ':put'
	endif
	"goes at the next point
	return top + next - 1
endfunction

" ******************************************************
function! FormatLatexPar(lvl)
	" Remembers position (+1 because we are adding a starting line) 
	let here = line(".")+1

	" Stores window view
	if v:version >= 700 && a:lvl == 0
		let fmt_winview = winsaveview()
	endif    

	" Goes to beginning of file and writes a special terminator string
	exe ':1'
	exe ':s/.*/\r&/'
	exe ':1'
	exe ':normal iFMT_LTX_TERM'
	" Goes to end of file and writes a special terminator string
	exe ':normal G'
	exe ':s/.*/&\r/'
	exe ':normal G'
	exe ':normal iFMT_LTX_TERM'

	" finds next comment (to see if we are upon a comment)
	exe ':'.here	
	let cmt = SearchForward(here, '^%\|FMT_LTX_TERM')
	
	if cmt == here
		" if we are on a comment, goes into the recursive mode
		let next = FormatComment(here,a:lvl)
	else
		" otherwise goes for the normal mode
	
		" Finds begin and end of paragraph
		let top = LatexParBegin(here)
		let bot = LatexParEnd(here)

		if bot==here && top==here
			" We are on top of a paragraph ending, or on an empty line
			" We simply move to the following line (we don't want to
			" paragraph endings that are too long)
			let next = here+1
		else
			" We are in a standard paragraph
			
			" Formats the lines between top and bot
			silent exe ':'.top.','.bot.'!fmt'
	
			" Moves at the begin of the next paragraph
			exe ":".top
			exe ":".(LatexParEnd(here)+1)
			let next = line(".")
		endif
	endif

	" Removes special terminators
	exe ':normal G'
	exe ':d'
	exe ':1'
	exe ':d'

	" Restores window view
	if v:version >= 700 && a:lvl == 0
		call winrestview(fmt_winview)
	endif
	" Goes where it is supposed to go
	exe ':'.(next-1)
endfunction



" Maps FormatPar function to Ctrl-J
map  <C-j>  <ESC>:silent call FormatLatexPar(0)<CR>i
map! <C-j>  <ESC>:silent call FormatLatexPar(0)<CR>i

