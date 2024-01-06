vim9script

# vim:sw=4
# ============================================================================
# File:           tasks.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:
# LICENSE:        MIT
# ============================================================================

import autoload './tasks/vscodetask.vim'
import autoload './tasks/utils.vim'
import autoload './tasks/runner.vim'

var task_dict =
{
    'local': vscodetask.TaskManager.new(g:TasksConfig.LocalFile),
    'global': vscodetask.TaskManager.new(g:TasksConfig.GlobalFile)
}

export def GetTaskDict(): dict<any>
    return task_dict
enddef

export def ListTasks(ArgLead: string, CmdLine: string, CursorPos: number): list<string>
    var data = CompleteList()
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

export def Run(Bang: bool, Label: string): void
    var target: vscodetask.TaskDescription = FindTaskDesciption(Label)
    if target == null
        utils.ErrorMsg('not found task label : ' .. Label)
    else
        StartTask(Bang, target)
    endif
enddef

export def FindTaskDesciption(Label: string): vscodetask.TaskDescription
    var label = Label
    var pos = match(label, '::[local|global]')
    if pos != -1 | label = label[ : pos - 1 ] | endif
    var target: vscodetask.TaskDescription
    for key in keys(task_dict)
        target = task_dict[key].FindTaskDesc(label)
        if target != null | break | endif
    endfor
    return target
enddef

export def CompleteList(): list<string>
    var complete_list = []
    var obj: vscodetask.Tasks
    for key in keys(task_dict)
        obj = task_dict[key].GetTask()
        var labels = obj.GetLabels()
        for label in labels
            var pos = index(complete_list, label)
            var value = label
            if pos != -1
                value ..= '::' .. key
            endif
            add(complete_list, value)
        endfor
    endfor
    return complete_list
enddef

export def StartTask(Bang: bool, Task: vscodetask.TaskDescription)
    var macros = vscodetask.Macros.new(g:TasksConfig.IsWindows, fnamemodify(g:TasksConfig.LocalFile, ':h'))
    macros.HandleMacros(Task)
    var cmd: string = ''
    if Task.command != ''
        var type = Task.type
        if has_key(g:TasksConfig.Runner, type)
            var obj: runner.Runner = g:TasksConfig.Runner[type]
            obj.Execute(Bang, Task)
        endif
    endif
    for label in Task.dependsOn
        Run(Bang, label)
    endfor
enddef

