" vim:sw=4
" ============================================================================
" File:       utils.vim
" Author:     caoshenghui <576365750@qq.com>
" Github:     https://github.com/
" LICENSE:    MIT
" ============================================================================


function! tasksystem#utils#errmsg(msg)
	echohl ErrorMsg
	echom 'Error: ' . a:msg
	echohl NONE
endfunc
