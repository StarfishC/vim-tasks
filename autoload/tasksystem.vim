" vim:sw=4
" ============================================================================
" File:           tasksystem.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:
" LICENSE:        MIT
" ============================================================================

function! s:start_task(bang, params)
    let type = get(a:params, 'type', 'floaterm')
    if type == 'floaterm'
        call tasksystem#floaterm#run(a:bang, a:params)
    elseif type == 'vim'
        let cmdline = a:params.command
        for arg in a:params.args
            let cmdline .= ' ' . arg
        endfor
        exec cmdline
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
        let cmd = ''
        let reverse = v:false
        if params.dependsType == 'reverse'
            let reverse = v:true
            if params.dependsOrder == 'sequent'
                call s:start_task(a:bang, params)
            endif
        endif
        for name in params.dependsOn
            if has_key(ftinfo, &filetype) && index(ftinfo[&filetype], name) != -1
                let name = name . "::" . &filetype
            endif
            if has_key(taskinfo, name)
                let taskopts = taskinfo[name]
                if params.dependsOrder == 'parallel'
                    let taskopts.presentation.panel = 'new'
                    call s:start_task(a:bang, taskopts)
                elseif params.dependsOrder == 'sequent'
                    let taskopts.presentation.panel = 'shared'
                    call s:start_task(a:bang, taskopts)
                else
                    let cmd .= taskopts.command
                    for arg in taskopts.args
                        let cmd .= ' ' . arg
                    endfor
                    let cmd .= ';'
                    continue
                endif
            else
                call tasksystem#utils#errmsg("'dependsOn' task " . name . ' not exist')
            endif
        endfor
        if params.dependsOrder == 'continuous'
            if !reverse
                let params.command = cmd . params.command
            else
                for arg in params.args
                    let params.command .= ' ' . arg
                endfor
                let params.args = []
                let params.command = params.command . ';' . cmd
            endif
        endif
        if params.command != '' && params.dependsType != 'reverse'
            call s:start_task(a:label, params)
        endif
    else
        call tasksystem#utils#errmsg(a:label . " task not exist!")
    endif
endfunction

" call tasksystem#run(0, 'One')
