vim9script

# vim:sw=4
# ============================================================================
# File:           tasks.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:
# LICENSE:        MIT
# ============================================================================


if exists("g:LoadedTasks") | finish | endif
g:LoadedTasks = 1

import autoload '../autoload/tasks.vim'
import autoload '../autoload/tasks/path.vim'
import autoload '../autoload/tasks/extensions.vim'


def Init(): void
    g:TasksConfig.IsWindows = has("win32") || has("win64")

    var root_markers = get(g:, 'TasksRootMarkers', ['.project', '.root', '.git', '.hg', '.svn'])
    var filepath = path.GetRootDir(root_markers)
    var file = get(g:, 'TasksLocalTasksName', '.tasks.json')
    var separator = g:TasksConfig.IsWindows ? '\\' : '/'
    g:TasksConfig.LocalFile = expand(filepath) .. separator .. file

    filepath = get(g:, 'TasksGlobalPath', g:TasksConfig.IsWindows ? '~/vimfiles' : '~/.vim')
    file = get(g:, 'Tasks_GlobalTasksName', 'tasks.json')
    g:TasksConfig.GlobalFile = expand(filepath) .. separator .. file

    g:TasksConfig.Runner = get(g:, 'TasksRunner', {})
    g:TasksConfig.UsingLeaderF = get(g:, 'TasksUsingLeaderF', 0)
enddef

g:TasksConfig = {}
Init()

extensions.Init()
command! -bang -nargs=+ -range=0 -complete=customlist,tasks.ListTasks TaskRun call tasks.Run(<bang>0, <q-args>)

