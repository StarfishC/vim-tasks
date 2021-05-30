" vim:sw=4
" ============================================================================
" File:           tasksystem.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:
" LICENSE:        MIT
" ============================================================================

function! tasksystem#start(bang, params)
    let type = get(a:params, 'type', 'floaterm')
    if type == 'floaterm'
        call tasksystem#floaterm#run(a:bang, a:params)
    endif
endfunction

function! tasksystem#complete(ArgLead, CmdLine, CursorPos) abort
	let template = tasksystem#params#namelist()
	let candidate = []
	for key in template
		if key != ''
			if stridx(key, a:ArgLead) == 0
				let candidate += [key]
			endif
		endif
	endfor
	return candidate
endfunction

function! tasksystem#run(bang, label) abort
    let taskinfo = tasksystem#params#taskinfo()
    let ftinfo = tasksystem#params#fttaskinfo()
    let label = a:label
    if has_key(ftinfo, &filetype) && index(ftinfo[&filetype], a:label) != -1
        let label = a:label . "::" . &filetype
    endif
    if has_key(taskinfo, label)
        let params = taskinfo[label]
        if has_key(params, 'dependsOn')
            for name in params.dependsOn
                if has_key(ftinfo, &filetype) && index(ftinfo[&filetype], name) != -1
                    let name = name . "::" . &filetype
                endif
                if has_key(taskinfo, name)
                    let taskopts = taskinfo[name]
                    call tasksystem#start(a:bang, taskopts)
                else
                    call tasksystem#utils#errmsg("'dependsOn' task " . name . ' not exist')
                endif
            endfor
        endif
        call tasksystem#start(a:label, params)
    else
        call tasksystem#utils#errmsg(a:label . " task not exist!")
    endif
endfunction

" call tasksystem#run(1, 'One')
