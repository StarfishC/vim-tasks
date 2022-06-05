vim9script

# vim:sw=4
# ============================================================================
# File:       Utils.vim
# Author:     caoshenghui <576365750@qq.com>
# Github:     https://github.com/
# LICENSE:    MIT
# ============================================================================


export def ErrorMsg(msg: string): void
    echohl ErrorMsg
    echom "Error: " .. msg
    echohl NONE
enddef

