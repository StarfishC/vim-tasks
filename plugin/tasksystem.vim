" local variables
" >>>>>>>>>>>>>>>
let s:tasksystem_version = '1.0.0'
let s:default_tasks_name = 'tasks.json'
let s:default_root_markers = ['.project', '.root', '.git', '.hg', '.svn']
if has("nvim")
    let s:default_global_path = "~/.config/nvim"
else
    let s:default_global_path = "~/.vim"
endif


" global variables
" >>>>>>>>>>>>>>>>
let g:tasksystem_global_path = get(g:, 'tasksystem_global_path', s:default_global_path)
let g:tasksystem_tasks_name = get(g:, 'tasksystem_tasks_name', s:default_tasks_name)
let g:tasksystem_root_markers = get(g:, 'tasksystem_root_markers', s:default_root_markers)



command! -bang -nargs=+ -range=0 -complete=customlist,tasksystem#complete Tasksystem call tasksystem#run('<bang>', <q-args>)


