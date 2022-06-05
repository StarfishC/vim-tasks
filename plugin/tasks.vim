vim9script

# vim:sw=4
# ============================================================================
# File:           tasks.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:
# LICENSE:        MIT
# ============================================================================


if exists("g:Loaded_Tasks") | finish | endif
g:Loaded_Tasks = 1

var default_global_path = "~/.vim"

g:Tasks_GlobalPath       = get(g:, 'Tasks_GlobalPath', default_global_path)
g:Tasks_RootMarkers      = get(g:, 'Tasks_RootMarkers', ['.project', '.root', '.git', '.hg', '.svn'])
g:Tasks_LocalTasksName   = get(g:, 'Tasks_LocalTasksName', '.tasks.json')
g:Tasks_GlobalTasksName  = get(g:, 'Tasks_GlobalTasksName', 'tasks.json')
g:Tasks_UsingLeaderF     = get(g:, 'Tasks_UsingLeaderF', 0)

g:Tasks_BuiltinRunner    = get(g:, 'Tasks_BuiltinRunner', {})
g:Tasks_ExtensionsRunner = get(g:, 'Tasks_ExtensionsRunner', {})

import autoload "../autoload/tasks/Extensions.vim"
import autoload "../autoload/Tasks.vim"

Extensions.Init()
command! -bang -nargs=+ -range=0 -complete=customlist,Tasks.Complete TaskRun call Tasks.Run(<bang>0, <q-args>)

