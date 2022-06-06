vim9script

# vim:sw=4
# ============================================================================
# File:           Extensions.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:    extensions for tasksystem
# LICENSE:        MIT
# ============================================================================

import autoload "./extensions/Floaterm.vim"
import autoload "./extensions/Leaderf.vim"

export def Init(): void
    if get(g:, "Tasks_UsingLeaderF", 0)
        Leaderf.Init()
    endif
    g:Tasks_ExtensionsRunner.floaterm = Floaterm.Run
enddef

