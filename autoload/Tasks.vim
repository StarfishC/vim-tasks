vim9script

# vim:sw=4
# ============================================================================
# File:           Tasks.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:
# LICENSE:        MIT
# ============================================================================

import autoload "./tasks/Task.vim"
import autoload "./tasks/Utils.vim"

export def Complete(ArgLead: string, CmdLine: string, CursorPos: number): list<string>
    var data = Task.CompleteList()
    var candidate = []
    for key in data
        if key != ''
            if stridx(key, ArgLead) == 0
                candidate += [key]
            endif
        endif
    endfor
    return candidate
enddef

export def Run(bang: bool, labelname: string): void
    var taskinfo = Task.TaskInfo()
    var ftinfo   = Task.FiletypeTask()
    var label    = ""
    if has_key(ftinfo, &filetype) && index(ftinfo[&filetype], labelname) != -1
        label = labelname .. "::" .. &filetype
    endif
    if has_key(taskinfo, label)
        var param = Task.ReplaceMacros(taskinfo[label])
        var cmd = ''
        if len(param.dependsOn) == 1
            Start_task(bang, param)
            return
        endif
        for depends in param.dependsOn
            var name = depends
            if has_key(ftinfo, &filetype) && index(ftinfo[&filetype], name) != -1
                name = name .. "::" .. &filetype
            endif
            if has_key(taskinfo, name)
                var taskopts = Task.ReplaceMacros(taskinfo[name])
                if param.dependsOrder == 'parallel'
                    taskopts.presentation.panel = 'new'
                elseif param.dependsOrder == 'sequent'
                    taskopts.presentation.panel = 'shared'
                else
                    cmd ..= taskopts.command
                    for arg in taskopts.args
                        cmd ..= (' ' .. arg)
                    endfor
                    cmd ..= ';'
                    continue
                endif
                Start_task(bang, taskopts)
            else
                Utils.ErrorMsg("'dependsOn' task " .. name .. ' not exist!')
            endif
        endfor
        if param.dependsOrder == 'continue' && cmd != ''
            param.command = cmd
            param.args = []
            Start_task(bang, param)
        endif
    else
        Utils.ErrorMsg(label .. " task not exist!")
    endif
enddef

def Start_task(bang: bool, param: dict<any>): void
    if param.save == "current"
        silent! execute "w"
    elseif param.save == "all"
        silent! execute "wall"
    endif
    if param.type == "ex"
        var cmdline = param.command
        for arg in param.args
            cmdline ..= (' ' .. arg)
        endfor
        execute cmdline
    elseif param.type == 'terminal'
        echo "112"
    elseif has_key(g:Tasks_ExtensionsRunner, param.type)
        g:Tasks_ExtensionsRunner[param.type](bang, param)
    endif
enddef

