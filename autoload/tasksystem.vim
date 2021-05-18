
function! tasksystem#complete(ArgLead, CmdLine, CursorPos)
    return tasksystem#json#namelist()
endfunction

function! tasksystem#run(bang, label)
    let opts = tasksystem#json#taskinfo()
    " check params
    if has_key(opts, a:label)
        let params = opts[a:label]
        if a:bang == '!'
            let params.bang = '!'
        endif
        if get(params, 'command', '') == ''
            call tasksystem#utils#errmsg("task miss command")
        endif
        let cmd = params.command . ' ' . get(params, 'args', '')
        let params.cmd = cmd
        let type = get(params, 'type', 'floaterm')
        if type == 'floaterm'
            call tasksystem#floaterm#run(params)
        endif
    else
        call tasksystem#utils#errmsg(a:label . " task not exist!")
    endif
endfunction
