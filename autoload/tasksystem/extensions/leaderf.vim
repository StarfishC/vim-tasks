" vim:sw=4
" ============================================================================
" File:           leaderf.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:    list in LeaderF (Yggdroot/LeaderF)
" LICENSE:        MIT
" ============================================================================


let s:showDevicon = get(g:, "Lf_ShowDevIcons", 1)
let s:devicons = {
        \   "Ex":       s:showDevicon ? "\ue7c5" : "",
        \   "floaterm": s:showDevicon ? "\ue795" : "",
        \   "terminal": s:showDevicon ? "\uf489" : "",
        \   "local":    s:showDevicon ? "\uf53f" : "",
        \   "global":   s:showDevicon ? "\uf53e" : "",
        \   "comment":  s:showDevicon ? "\ufb28" : "",
        \}

function! s:lf_tasksystem_source(...) abort
    let taskinfo = tasksystem#params#taskinfo()
    let fileinfo = tasksystem#params#filetypetask()
    let candidates = []
    if has_key(fileinfo, &filetype)
        for name in fileinfo[&filetype]
            let task = taskinfo[name . '::' . &filetype]
            let type = s:devicons[task.type] . " " . task.type
            let comment = s:devicons.comment . " " . task.command . ' ' . join(task.args, ' ')
            let name = s:devicons.local . " " . name
            let line = printf("%-20s%-10s\t%s", name, type, comment)
            call add(candidates, line)
        endfor
    endif
    for name in fileinfo['*']
        let task = taskinfo[name]
        let type = s:devicons[task.type] . " " . task.type
        let comment = s:devicons.comment . " " . task.command . ' ' . join(task.args, ' ')
        let name = s:devicons.global . " " . name
        let line = printf("%-20s%-10s\t%s", name, type, comment)
        call add(candidates, line)
    endfor
    return candidates
endfunction

function! s:lf_tasksystem_accpet(line, arg) abort
    let taskname = trim(a:line[4:19], " ", 2)
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
            \ 'highlights_def': {
            \       'Lf_hl_funcScope': '\(\%uf53f\|\%uf53e\).\{16}',
            \       'Lf_hl_funcReturnType': '\(\%ue7c5\|\%ue795\|%uf489\)\_s\+\S\+',
            \       'Lf_hl_funcName': '\%ufb28.*$'
            \ }
        \ }

    if !exists(':LeaderfTask')
        command! -bar -nargs=* LeaderfTask Leaderf task <args>
    endif
endfunction

