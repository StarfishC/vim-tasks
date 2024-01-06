vim9script

# vim:sw=4
# ============================================================================
# File:           leaderf.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:    list in LeaderF (Yggdroot/LeaderF)
# LICENSE:        MIT
# ============================================================================


import autoload '../utils.vim'
import autoload '../vscodetask.vim'
import autoload '../../tasks.vim'

var show_devicon = get(g:, "Lf_ShowDevIcons", 1)
var devicons =
{
   "ex":       show_devicon ? "\ue7c5" : "[e]",
   "floaterm": show_devicon ? "\uf489" : "[f]",
   "terminal": show_devicon ? "\uea85" : "[t]",
   "other":    show_devicon ? "\uf120" : "[o]",
   "local":    show_devicon ? "\ue630" : "[l]",
   "global":   show_devicon ? "\uf260" : "[g]",
   "comment":  show_devicon ? "\ueb26" : "[c]",
}

export def Init(): void
    if !exists(':Leaderf')
        utils.ErrorMsg("Require Yggdroot/LeaderF")
    endif
    g:Lf_Extensions = get(g:, 'Lf_Extensions', {})
    g:Lf_Extensions.task = {
        'source': string(function(LfTasksSource))[10 : -3],
        'accept': string(function(LfTasksAccept))[10 : -3],
        'highlights_def': {
              'Lf_hl_funcScope': '.*\%<21c',
              'Lf_hl_funcReturnType': '\%>20c.*\%<36c',
              'Lf_hl_funcName': '\%>35c.*$'
        }
    }
    if !exists(':LeaderfTask')
        command! -bar -nargs=* LeaderfTask Leaderf task <args>
    endif
enddef

def LfTasksSource(...itemlist: list<any>): list<string>
    var candidate: list<string>
    var task_dict = tasks.GetTaskDict()
    var task_config: vscodetask.TaskConfiguration
    var task_manager: vscodetask.TaskManager
    for key in keys(task_dict)
        task_manager = task_dict[key]
        task_config = task_manager.GetTask().GetConfiguration()
        if task_config == null | continue | endif
        for task in task_config.tasks
            var label = devicons[key] .. " " .. task.label
            var pos = index(candidate, label)
            if pos != -1 | label ..= '::' .. key | endif
            var type = has_key(devicons, task.type) ? devicons[task.type] : devicons.other
            type ..= " " .. task.type
            var comment = devicons.comment .. " " .. task.command .. ' ' ..  join(task.args, ' ')
            var line = printf("%-20s%-15s%s", label, type, comment)
            add(candidate, line)
        endfor
    endfor
    return candidate
enddef

def LfTasksAccept(line: string, ...arg: list<any>): void
    var taskname = trim(line[2 : 17], " ", 2)
    tasks.Run(true, taskname)
enddef

