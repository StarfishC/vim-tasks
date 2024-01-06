vim9script

# vim:sw=4
# ============================================================================
# File:           runner.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:
# LICENSE:        MIT
# ============================================================================

import autoload './vscodetask.vim'

export abstract class Runner
    abstract def Execute(Bang: bool, Task: vscodetask.TaskDescription): void
endclass


