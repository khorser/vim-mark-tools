" Toggle and navigate bookmarks
" Last Change: $HGLastChangedDate$
" URL:	http://www.vim.org/scripts/script.php?script_id=2929
"	https://bitbucket.org/khorser/vim-mark-tools
"	https://github.com/khorser/vim-mark-tools
" Maintainer:  Sergey Khorev <sergey.khorev@gmail.com>
" vim: set ft=vim ts=8 sts=2 sw=2:
"
" MAPPINGS DEFINED:
" <Plug>ToggleMarkAZ- mark/unmark current position
"		      if there are multiple marks on the line, remove the first
" <Plug>ToggleMarkZA- mark/unmark current position
"		      if there are multiple marks on the line, remove the last
" <Plug>ForceMarkAZ - add an unused mark starting from a, even if the position is marked
" <Plug>ForceMarkZA - add an unused mark starting from z, even if the position is marked
" <Plug>NextMarkPos - go to next mark
" <Plug>PrevMarkPos - go to prev mark
" <Plug>NextMarkLexi- go to previous mark in lexicographical order
" <Plug>PrevMarkLexi- go to next mark in lexicographical order
" <Plug>MarksLoc    - open location list window with local mark positions
" <Plug>MarksQF	    - open quickfix window with marks
"
" recommended mapping:
" nmap <Leader>a <Plug>ToggleMarkAZ
" nmap <Leader>z <Plug>ToggleMarkZA
" nmap <Leader>A <Plug>ForceMarkAZ
" nmap <Leader>Z <Plug>ForceMarkZA
" nmap <Leader>m <Plug>NextMarkPos
" nmap <Leader>M <Plug>PrevMarkPos
" nmap <Leader>l <Plug>NextMarkLexi
" nmap <Leader>L <Plug>PrevMarkLexi
" nmap <Leader>w <Plug>MarksLoc
" nmap <Leader>W <Plug>MarksQF
" so
" \a and \z toggle a mark at current line
" \A and \Z force another mark
" \m and \M go to next/prev mark
" \l and \L go to next/prev mark alphabetically
" \w and \W open location list/quickfix window with defined marks
"
" Also I recommend installation of a plugin to visualise marks
" e.g. quickfixsigns (http://www.vim.org/scripts/script.php?script_id=2584)
"
" CUSTOMISATION:
" toggle_marks_wrap_search variable controls whether search wraps around or not
" (order of precedence: w:toggle_marks_wrap_search, b:toggle_marks_wrap_search, g:toggle_marks_wrap_search)
" Possible values:
" -1 - use 'wrapscan' option value
"  0 - do not wrap
"  1 - always wrap (default)
"
"  To customise marks which you want to see in location list and quickfix
"  windows you can override variables below:
"  let g:lmarks_names = 'abcdefghijklmnopqrstuvwxyz''.'
"  let g:gmarks_names = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
"
" When using \w and \W with quickfixsigns plugin, you may want to protect mark signs from
" quickfix signs with:
" let g:quickfixsigns_lists = [
"      \ {'sign': 'QFS_QFL', 'get': 'g:NonMarkQFEntries()', 'event': ['BufEnter']},
"      \ {'sign': 'QFS_LOC', 'get': 'g:NonMarkLocEntries(winnr())', 'event': ['BufEnter']},
"      \ ]

let s:save_cpo = &cpo
set cpo&vim

if exists("loaded_toggle_local_marks")
  finish
endif
let loaded_toggle_local_marks = 1

unlockvar s:marks_names
unlockvar s:marks_count
unlockvar s:marks_nlist
let s:marks_names = 'abcdefghijklmnopqrstuvwxyz'
let s:marks_nlist = split(s:marks_names, '\zs')
let s:marks_count = strlen(s:marks_names)
lockvar s:marks_names
lockvar s:marks_nlist
lockvar s:marks_count

function! s:LocalMarkList()
  return map(copy(s:marks_nlist), '[v:val, line("''" . v:val)]')
endfunction

function! s:MarksAt(pos)
  return join(map(filter(s:LocalMarkList(), 'v:val[1]==' . a:pos), 'v:val[0]'), '')
endfunction

function! s:UsedMarks()
  return join(map(s:LocalMarkList(), '(v:val[1]>0 ? v:val[0] : " ")'),'')
endfunction

function! s:NextMark(pos)
  let l:mark = ''
  let l:pos = 0
  let l:dist = 0
  for m in s:LocalMarkList()
    if m[1] > a:pos && (l:pos == 0 || m[1] - a:pos < l:dist)
      let l:mark = m[0]
      let l:pos = m[1]
      let l:dist = m[1] - a:pos
    endif
  endfor
  return l:mark
endfunction

function! s:PrevMark(pos)
  let l:mark = ''
  let l:pos = 0
  let l:dist = 0
  for m in s:LocalMarkList()
    if m[1] > 0 && m[1] < a:pos && (l:pos == 0 || a:pos - m[1] < l:dist)
      let l:mark = m[0]
      let l:pos = m[1]
      let l:dist = a:pos - m[1]
    endif
  endfor
  return l:mark
endfunction

function! s:NextMarkAlpha(mark)
  let l:index = char2nr(a:mark) - char2nr(s:marks_names[0])
  for m in s:LocalMarkList()[l:index + 1:]
    if m[1] > 0
      return m[0]
    endif
  endfor
  return ''
endfunction

function! s:PrevMarkAlpha(mark)
  let l:index = char2nr(s:marks_names[s:marks_count-1]) - char2nr(a:mark)
  for m in reverse(s:LocalMarkList())[l:index + 1:]
    if m[1] > 0
      return m[0]
    endif
  endfor
  return ''
endfunction

function! s:ToggleMarks(a2z, forceAdd)
  let l:marks_here = s:MarksAt(line('.'))

  if !a:forceAdd && !empty(l:marks_here)
    " delete one mark
    if a:a2z
      exec 'delma ' . l:marks_here[0]
    else
      exec 'delma ' . l:marks_here[strlen(l:marks_here)-1]
    endif
  else
    " no marks, add first available mark
    let l:used = s:UsedMarks()
    let l:len = strlen(l:used)
    if a:a2z
      for i in range(0, l:len-1)
	if l:used[i] == ' '
	  exec "normal m" . s:marks_names[i]
	  return
	endif
      endfor
    else
      for i in range(l:len-1, 0, -1)
	if l:used[i] == ' '
	  exec "normal m" . s:marks_names[i]
	  return
	endif
      endfor
    endif
  endif
endfunction

function! s:GetWrapSearch()
  let l:wrap = 1
  if exists('w:toggle_marks_wrap_search')
    let l:wrap = w:toggle_marks_wrap_search
  elseif exists('b:toggle_marks_wrap_search')
    let l:wrap = b:toggle_marks_wrap_search
  elseif exists('g:toggle_marks_wrap_search')
    let l:wrap = g:toggle_marks_wrap_search
  end

  if l:wrap < 0
    return &wrapscan
  elseif l:wrap == 0
    return 0
  else
    return 1
  endif
endfunction

function! s:NextByPos()
  let l:mark = s:NextMark(line('.'))
  if empty(l:mark) && s:GetWrapSearch()
    let l:mark = s:NextMark(0)
  endif
  if !empty(l:mark)
    exec ':''' . l:mark
  endif
endfunction

function! s:PrevByPos()
  let l:mark = s:PrevMark(line('.'))
  if empty(l:mark) && s:GetWrapSearch()
    let l:mark = s:PrevMark(line('$')+1)
  endif
  if !empty(l:mark)
    exec ':''' . l:mark
  endif
endfunction

function! s:NextByAlpha()
  let l:marks_here = s:MarksAt(line('.'))
  if !empty(l:marks_here)
    let l:mark = s:NextMarkAlpha(l:marks_here[strlen(l:marks_here)-1])
    if empty(l:mark) && s:GetWrapSearch()
      let l:mark = s:NextMarkAlpha(nr2char(char2nr(s:marks_names[0])-1))
    endif
    if !empty(l:mark)
      exec ':''' . l:mark
    endif
  endif
endfunction

function! s:PrevByAlpha()
  let l:marks_here = s:MarksAt(line('.'))
  if !empty(l:marks_here)
    let l:mark = s:PrevMarkAlpha(l:marks_here[0])
    if empty(l:mark) && s:GetWrapSearch()
      let l:mark = s:PrevMarkAlpha(nr2char(char2nr(s:marks_names[s:marks_count-1])+1))
    endif
    if !empty(l:mark)
      exec ':''' . l:mark
    endif
  endif
endfunction

if !exists('g:lmarks_names')
  let g:lmarks_names = 'abcdefghijklmnopqrstuvwxyz''.'
endif

if !exists('g:gmarks_names')
  let g:gmarks_names = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
endif

unlockvar s:lmarks_nlist
unlockvar s:gmarks_nlist
let s:lmarks_nlist = split(g:lmarks_names, '\zs')
let s:gmarks_nlist = split(g:gmarks_names, '\zs')
lockvar s:lmarks_nlist
lockvar s:gmarks_nlist

function! s:CreateMarkEntry(mark)
  let [buf, lnum, col, off] = getpos("'" . a:mark)
  let lines = getbufline(buf, lnum)
  if buf == 0
    return {'lnum': 0}
  else
    return {'bufnr': buf, 'lnum': lnum, 'col': col, 'type': 'M',
      \'text': a:mark . ': ' . (empty(lines) ? '' : lines[0])}
  endif
endfunction

function! s:MarksLoc()
  call setloclist(0,
	\filter(
	  \map(
	    \copy(s:lmarks_nlist),
	    \'{"bufnr": bufnr("%"), "lnum": line("''" . v:val), "col": col("''" . v:val),
	      \"type": "m", "text": v:val . ": " . getline(line("''" . v:val))}'),
	  \'v:val.lnum > 0'))
  lopen
endfunction

function! s:MarksQF()
  call setqflist(
	\filter(
	  \map(
	    \copy(s:gmarks_nlist), 's:CreateMarkEntry(v:val)'),
	  \'v:val.lnum > 0'))
  copen
endfunction

function! g:NonMarkQFEntries()
  return filter(getqflist(), 'v:val.type !=? "m"')
endfunction

function! g:NonMarkLocEntries(winnr)
  return filter(getloclist(a:winnr), 'v:val.type !=? "m"')
endfunction

" suggested mapping: <Leader>a and <Leader>z
nnoremap <silent> <Plug>ToggleMarkAZ :call <SID>ToggleMarks(1, 0)<CR>
nnoremap <silent> <Plug>ToggleMarkZA :call <SID>ToggleMarks(0, 0)<CR>
" suggested mapping: <Leader>A and <Leader>Z
nnoremap <silent> <Plug>ForceMarkAZ :call <SID>ToggleMarks(1, 1)<CR>
nnoremap <silent> <Plug>ForceMarkZA :call <SID>ToggleMarks(0, 1)<CR>
" suggested mapping: <Leader>m and <Leader>M
nnoremap <silent> <Plug>NextMarkPos :call <SID>NextByPos()<CR>
nnoremap <silent> <Plug>PrevMarkPos :call <SID>PrevByPos()<CR>
" suggested mapping: <Leader>l and <Leader>L (lexicographic)
nnoremap <silent> <Plug>NextMarkLexi :call <SID>NextByAlpha()<CR>
nnoremap <silent> <Plug>PrevMarkLexi :call <SID>PrevByAlpha()<CR>
" suggested mapping: <Leader>w and <Leader>W
nnoremap <silent> <Plug>MarksLoc :call <SID>MarksLoc()<CR>
nnoremap <silent> <Plug>MarksQF :call <SID>MarksQF()<CR>

let &cpo = s:save_cpo
