" vim:sw=4
" ============================================================================
" File:           tasksystem.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:
" LICENSE:        MIT
" ============================================================================


if exists("g:loaded_tasksystem")
    finish
endif
let g:loaded_tasksystem = 1

let s:tasksystem_version = '1.0.0'
if has("nvim")
    let s:default_globalPath = "~/.config/nvim"
else
    let s:default_globalPath = "~/.vim"
endif

let g:tasksystem_nvim = has("nvim")
let g:tasksystem_globalPath = get(g:, 'tasksystem_globalPath', s:default_globalPath)
let g:tasksystem_rootMarkers = get(g:, 'tasksystem_rootMarkers', ['.project', '.root', '.git', '.hg', '.svn'])
let g:tasksystem_localTasksName = get(g:, 'tasksystem_localTasksName', '.tasks.json')
let g:tasksystem_globalTasksName = get(g:, 'tasksystem_globalTasksName', 'tasks.json')


command! -bang -nargs=+ -range=0 -complete=customlist,tasksystem#complete Tasksystem call tasksystem#run(<bang>0, <q-args>)


