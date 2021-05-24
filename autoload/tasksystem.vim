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
    if has_key(opts, a:label)
        let params = opts[a:label]
        " process predefinedvars
        let params = tasksystem#predefinedvars#process_macros(params)
        let type = get(params, 'type', 'floaterm')
        if type == 'floaterm'
            call tasksystem#floaterm#run(a:bang, params)
        endif
    else
        call tasksystem#utils#errmsg(a:label . " task not exist!")
    endif
endfunction

" call tasksystem#run('', '12')
