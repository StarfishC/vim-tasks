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
    let s:default_global_path = "~/.config/nvim"
else
    let s:default_global_path = "~/.vim"
endif

let g:tasksystem_nvim = has("nvim")
let g:tasksystem_tasks_name = get(g:, 'tasksystem_tasks_name', 'tasks.json')
let g:tasksystem_global_path = get(g:, 'tasksystem_global_path', s:default_global_path)
let g:tasksystem_root_markers = get(g:, 'tasksystem_root_markers', ['.project', '.root', '.git', '.hg', '.svn'])


command! -bang -nargs=+ -range=0 -complete=customlist,tasksystem#complete Tasksystem call tasksystem#run(<bang>0, <q-args>)


