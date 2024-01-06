vim9script

# vim:sw=4
# ============================================================================
# File:           extensions.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:    extensions for tasksystem
# LICENSE:        MIT
# ============================================================================

import autoload "./extensions/leaderf.vim"
import autoload './runner/floaterm.vim'

export def Init(): void
    if g:TasksConfig.UsingLeaderF | leaderf.Init() | endif
    g:TasksConfig.Runner.floaterm = GetFloatermRunner()
enddef

def GetFloatermRunner(): floaterm.FloatermRunner
    return floaterm.FloatermRunner.new()
enddef


