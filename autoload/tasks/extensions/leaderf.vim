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

class PreviewManager
    public var content: dict<any>

    def Add(Label: string, Command: string, Args: list<string>, DependsOn: list<string>)
        var text_list: list<string>
        add(text_list, "command: " .. Command)
        if len(Args) > 0
            this._AddSublist(text_list, "args", Args)
        else
            add(text_list, "args: []")
        endif
        this._AddSublist(text_list, "dependsOn", DependsOn)
        this.content[Label] = text_list
    enddef

    def _AddSublist(Text: list<string>, Name: string, Item: list<string>)
        if len(Item) > 0
            add(Text, Name .. ":[")
            for i in Item
                add(Text, "    " .. i)
            endfor
            add(Text, "]")
        endif
    enddef

endclass

var preview_manager: PreviewManager = PreviewManager.new()

export def Init(): void
    if !exists(':Leaderf')
        utils.ErrorMsg("Require Yggdroot/LeaderF")
    endif
    g:Lf_Extensions = get(g:, 'Lf_Extensions', {})
    g:Lf_Extensions.task = {
        'source': string(function(LfTasksSource))[10 : -3],
        'accept': string(function(LfTasksAccept))[10 : -3],
        'preview': string(function(LfTaskPreview))[10 : -3],
        'highlights_def': {
              'Lf_hl_funcScope': '.*\%<31c',
              'Lf_hl_funcReturnType': '\%>30c.*\%<50c',
              'Lf_hl_funcName': '\%>50c.*$'
        }
    }
    command! -bar -nargs=* LeaderfTask Leaderf task <args>
enddef

def LfTasksSource(...ItemList: list<any>): list<string>
    var candidate: list<string>
    var task_dict = tasks.GetTaskDict()
    var task_config: vscodetask.TaskConfiguration
    var task_manager: vscodetask.TaskManager
    for key in keys(task_dict)
        task_manager = task_dict[key]
        task_config = task_manager.GetTask().GetConfiguration()
        if task_config == null | continue | endif
        for task in task_config.tasks
            var label = task.label
            var pos = index(candidate, label)
            if pos != -1 | label ..= '::' .. key | endif
            var type = has_key(devicons, task.type) ? devicons[task.type] : devicons.other
            type ..= " " .. task.type
            preview_manager.Add(label, task.command, task.args, task.dependsOn)
            label = devicons[key] .. " " .. label
            var line = printf("%-30s%-20s", label, type)
            add(candidate, line)
        endfor
    endfor
    return candidate
enddef

def LfTasksAccept(line: string, ...arg: list<any>): void
    var task_name = show_devicon ? trim(line[2 : 27], " ", 2) : trim(line[4 : 27], " ", 2)
    tasks.Run(true, task_name)
enddef

def LfTaskPreview(orig_buf_nr: any, orig_cursor: any, line: any, args: any): list<any>
    var task_name = show_devicon ? trim(line[2 : 27], " ", 2) : trim(line[4 : 27], " ", 2)
    var bid = bufadd('')
    bufload(bid)
    setbufvar(bid, '&buflisted', 0)
    setbufvar(bid, '&bufhidden', 'hide')
    setbufline(bid, 1, preview_manager.content[task_name])
    setbufvar(bid, '&modified', 0)
    return [bid, 1, '']
enddef

