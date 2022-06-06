vim9script

# vim:sw=4
# ============================================================================
# File:           Leaderf.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:    list in LeaderF (Yggdroot/LeaderF)
# LICENSE:        MIT
# ============================================================================


var showDevicon = get(g:, "Lf_ShowDevIcons", 1)
var devicons =
    {
       "ex":       showDevicon ? "\ue7c5" : "",
       "floaterm": showDevicon ? "\ue795" : "",
       "terminal": showDevicon ? "\uf489" : "",
       "local":    showDevicon ? "\uf53f" : "",
       "global":   showDevicon ? "\uf53e" : "",
       "comment":  showDevicon ? "\ufb28" : "",
       "other":    showDevicon ? "\uf911" : "",
    }

import autoload "../Task.vim"
import autoload "../Utils.vim"
import autoload "../../Tasks.vim"


export def Init(): void
    if !exists(':Leaderf')
        Utils.ErrorMsg("require Yggdroot/LeaderF")
    endif
    g:Lf_Extensions = get(g:, 'Lf_Extensions', {})
    g:Lf_Extensions.task = {
        'source': string(function(Lf_tasks_source))[10 : -3],
        'accept': string(function(Lf_tasks_accept))[10 : -3],
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


def Lf_tasks_source(...itemlist: list<any>): list<string>
    var taskinfo = Task.TaskInfo()
    var ftinfo   = Task.FiletypeTask()
    var filelist = has_key(ftinfo, &filetype) ? [&filetype, "*"] : ["*"]
    var candidates = []
    for key in filelist
        for ft in ftinfo[key]
            var info = {}
            var name = ""
            if key == &filetype
                info = taskinfo[ft .. '::' .. &filetype]
                name = devicons.local .. " " .. ft
            else
                info = taskinfo[ft]
                name = devicons.global .. " " .. ft
            endif
            var type = (has_key(devicons, info.type) ? devicons[info.type] : devicons.other) .. " " .. info.type
            var comment = devicons.comment .. " " .. info.command .. ' ' ..  join(info.args, ' ')
            var line = printf("%-20s%-15s%s", name, type, comment)
            call add(candidates, line)
        endfor
    endfor
    return candidates
enddef

def Lf_tasks_accept(line: string, ...arg: list<any>): void
    var taskname = trim(line[2 : 17], " ", 2)
    Tasks.Run(v:false, taskname)
enddef

