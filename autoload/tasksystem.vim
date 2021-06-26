" vim:sw=4
" ============================================================================
" File:           tasksystem.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:
" LICENSE:        MIT
" ============================================================================

function! s:start_task(bang, params)
    if a:params.save == "current"
        silent! exec 'w'
    elseif a:params.save == "all"
        silent! exec 'wall'
    endif
    if a:params.type == 'ex'
        let cmdline = a:params.command
        for arg in a:params.args
            let cmdline .= ' ' . arg
        endfor
        exec cmdline
    elseif has_key(g:tasksystem_extensionsRunner, a:params.type)
        call g:tasksystem_extensionsRunner[a:params.type](a:bang, a:params)
    endif
endfunction

function! tasksystem#complete(ArgLead, CmdLine, CursorPos) abort
    let template = tasksystem#params#completelist()
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
    let ftinfo = tasksystem#params#filetypetask()
    let label = a:label
    if has_key(ftinfo, &filetype) && index(ftinfo[&filetype], a:label) != -1
        let label = a:label . "::" . &filetype
    endif
    if has_key(taskinfo, label)
        let params = tasksystem#params#replacemacros(taskinfo[label])
        let cmd = ''
        if len(params.dependsOn) == 1
            call s:start_task(a:bang, params)
            return
        endif
        for name in params.dependsOn
            if has_key(ftinfo, &filetype) && index(ftinfo[&filetype], name) != -1
                let name = name . "::" . &filetype
            endif
            if has_key(taskinfo, name)
                let taskopts = tasksystem#params#replacemacros(taskinfo[name])
                if params.dependsOrder == 'parallel'
                    let taskopts.presentation.panel = 'new'
                elseif params.dependsOrder == 'sequent'
                    let taskopts.presentation.panel = 'shared'
                else
                    let cmd .= taskopts.command
                    for arg in taskopts.args
                        let cmd .= ' ' . arg
                    endfor
                    let cmd .= ';'
                    continue
                endif
                call s:start_task(a:bang, taskopts)
            else
                call tasksystem#utils#errmsg("'dependsOn' task " . name . ' not exist')
            endif
        endfor
        if params.dependsOrder == 'continuous' && cmd != ''
            let params.command = cmd
            let params.args = []
            call s:start_task(a:label, params)
        endif
    else
        call tasksystem#utils#errmsg(a:label . " task not exist!")
    endif
endfunction

