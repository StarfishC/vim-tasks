" vim:sw=4
" ============================================================================
" File:           tasksystem.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:
" LICENSE:        MIT
" ============================================================================


function! tasksystem#complete(ArgLead, CmdLine, CursorPos) abort
    return tasksystem#params#namelist()
endfunction

function! tasksystem#run(bang, label) abort
    let taskinfo = tasksystem#params#taskinfo()
    let ftinfo = tasksystem#params#fttaskinfo()
    if has_key(taskinfo, a:label)
        let params = taskinfo[a:label]
        let type = get(params, 'type', 'floaterm')
        if type == 'floaterm'
            call tasksystem#floaterm#run(a:bang, params)
        endif
    else
        call tasksystem#utils#errmsg(a:label . " task not exist!")
    endif
endfunction

" call tasksystem#run('', 'run')
