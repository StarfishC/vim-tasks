" vim:sw=4
" ============================================================================
" File:           extensions.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:    extensions for tasksystem
" LICENSE:        MIT
" ============================================================================


function tasksystem#extensions#init() abort
    if get(g:, 'tasksystem_usingLeaderF', 0)
        call tasksystem#extensions#leaderf#init()
    endif
    let g:tasksystem_extensionsRunner.floaterm = function("tasksystem#extensions#floaterm#run")
endfunction

