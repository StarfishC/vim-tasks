" vim:sw=4
" ============================================================================
" File:           leaderf.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:    list in LeaderF (Yggdroot/LeaderF)
" LICENSE:        MIT
" ============================================================================


function! s:lf_tasksystem_source(...) abort
    let taskinfo = tasksystem#params#taskinfo()
    let fileinfo = tasksystem#params#filetypetask()
    let candidates = []
    if has_key(fileinfo, &filetype)
        for name in fileinfo[&filetype]
            let task = taskinfo[name . '::' . &filetype]
            let type = task.type
            let comment = task.command . ' ' . join(task.args, ' ')
            let line = printf("%-20s%-10s\t\t%s", name, type, comment)
            call add(candidates, line)
        endfor
    endif
    for name in fileinfo['*']
        let task = taskinfo[name]
        let type = task.type
        let comment = task.command . ' ' . join(task.args, ' ')
        let line = printf("%-20s%-10s\t\t%s", name, type, comment)
        call add(candidates, line)
    endfor
    return candidates
endfunction

function! s:lf_tasksystem_accpet(line, arg) abort
    let taskname = trim(a:line[0:19], " ", 2)
    call tasksystem#run(0, taskname)
endfunction


function! tasksystem#extensions#leaderf#init() abort
    if !exists(':Leaderf')
        call tasksystem#utils#errmsg("require Yggdroot/LeaderF")
    endif
    let g:Lf_Extensions = get(g:, 'Lf_Extensions', {})
    let g:Lf_Extensions.task = {
        \ 'source': string(function('s:lf_tasksystem_source'))[10: -3],
        \ 'accept': string(function('s:lf_tasksystem_accpet'))[10: -3],
        \ }

    if !exists(':LeaderfTask')
        command! -bar -nargs=+ LeaderfTask Leaderf task <args>
    endif
endfunction

