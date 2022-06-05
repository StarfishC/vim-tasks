vim9script

# vim:sw=4
# ============================================================================
# File:           leaderf.vim
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
        'source': Lf_tasksystem_source,
        'accept': Lf_tasksystem_accept,
        'highlights_def': {
              'Lf_hl_funcScope': '\(\%uf53f\|\%uf53e\).\{16}',
              'Lf_hl_funcReturnType': '\(\%ue7c5\|\%ue795\|\%uf489\|\%uf911\)\_s\+\S\+',
              'Lf_hl_funcName': '\%ufb28.*$'
        }
    }
    if !exists(':LeaderfTask')
        command! -bar -nargs=* LeaderfTask Leaderf task <args>
    endif
enddef


def Lf_tasksystem_source(): list<string>
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
            var line = printf("%-20s%-10s\t%s", name, type, comment)
            call add(candidates, line)
        endfor
    endfor
    return candidates
enddef

def Lf_tasksystem_accept(line: string, arg: string)
    var taskname = trim(line[4 : 19], " ", 2)
    Tasks.Run(v:false, taskname)
enddef

