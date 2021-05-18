
function! tasksystem#utils#errmsg(msg)
	echohl ErrorMsg
	echom 'Error: ' . a:msg
	echohl NONE
endfunc
