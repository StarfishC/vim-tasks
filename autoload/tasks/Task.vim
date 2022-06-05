vim9script

# vim:sw=4
# ============================================================================
# File:           Task.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:
# LICENSE:        MIT
# ============================================================================


# ${workspaceFolder} - the path of the folder opened in (Neo)Vim
# ${workspaceFolderBasename} - the name of the folder opened in Vim without any slashes (/)
# ${file} - the current opened file
# ${fileWorkspaceFolder} - the current opened file's workspace folder
# ${relativeFile} - the current opened file relative to workspaceFolder
# ${relativeFileDirname} - the current opened file's dirname relative to workspaceFolder
# ${fileBasename} - the current opened file's basename
# ${fileBasenameNoExtension} - the current opened file's basename with no file extension
# ${fileDirname} - the current opened file's dirname
# ${fileExtname} - the current opened file's extension
# ${cwd} - the task runner's current working directory on startup
# ${cword} - the word under the cursor
# ${lineNumber} - the current selected line number in the active file
# ${selectedText} - the current selected text in the active file
# ${pathSeparator} - the character used by the operating system to separate components in file paths
# ${input=xxx} - you can input something in vim

import autoload "./Path.vim"
import autoload "./Utils.vim"

var local_json_name     = get(g:, "Tasks_LocalTasksName", "")
var global_json_name    = get(g:, "Tasks_GlobalTasksName", "")
var default_local_path  = Path.RootDir()
var default_global_path = get(g:, 'Tasks_GlobalPath', ".")
var is_windows          = (has("win32") || has("win64")) ? 1 : 0

var tasks_complete_list = [] # Tasksystem complete
var tasks_info          = {} # all tasks
var tasks_filetype      = {} # task for specific filetype
var file_modify_time    = {"local": 0, "global": 0} # last modification time of tasks.json


export def TaskInfo(): dict<any>
    var symbol = is_windows ? '\\' : '/'
    var files = {
        'global': expand(default_global_path) .. symbol ..  global_json_name,
        'local':  expand(default_local_path) .. symbol .. local_json_name
    }
    var flag = v:false
    for file in keys(files)
        var lasttime = getftime(files[file])
        if file_modify_time[file] == 0
            file_modify_time[file] = lasttime
            Process_params(file, Json_decode(files[file]))
        elseif lasttime != -1 && lasttime > file_modify_time[file]
            flag = v:true
            break
        endif
    endfor
    if flag
        tasks_complete_list = []
        tasks_info          = {}
        tasks_filetype      = {}
        for file in keys(files)
            file_modify_time[file] = getftime(files[file])
            Process_params(file, Json_decode(files[file]))
        endfor
    endif
    return tasks_info
enddef

export def ReplaceMacros(task: dict<any>): dict<any>
    if task == {} | return {} | endif
    var data = deepcopy(task)
    data.command = Process_vars(data.command)
    for i in range(len(data.args))
        data.args[i] = Process_vars(data.args[i])
    endfor
    for key in keys(data.options)
        if type(data.options[key]) != v:t_string | continue | endif
        data.options[key] = Process_vars(data.options[key])
    endfor
    return data
enddef

export def CompleteList(): list<string>
    TaskInfo()
    var item = []
    if has_key(tasks_filetype, &filetype)
        item = copy(tasks_filetype[&filetype])
    endif
    if has_key(tasks_filetype, '*')
        extend(item, tasks_filetype['*'])
    endif
    return item
enddef

export def FiletypeTask(): dict<any>
    return tasks_filetype
enddef


# read json file
def Json_decode(filename: string): dict<any>
    if !filereadable(filename) | return {} | endif
    var contents = readfile(filename)
    var pattern  = '\s*[^(".*"\s+,)][\s]*\/\/.*'
    for i in range(len(contents))
        if contents[i] =~ pattern
            contents[i] = substitute(contents[i], pattern, '', '')
        endif
    endfor
    var data = join(contents, '')
    return json_decode(data)
enddef

# predefinedvars like VScode
def Expand_marcors(): dict<any>
    var macros = {}
    macros["pathSeparator"]           = is_windows ? "\\" : "/"
    macros["workspaceFolder"]         = default_local_path
    macros["workspaceFolderBasename"] = fnamemodify(macros["workspaceFolder"], ":t")
    macros["file"]                    = expand("%:p")
    macros["fileWorkspaceFolder"]     = default_local_path
    macros["fileBasename"]            = expand("%:t")
    macros["fileBasenameNoExtension"] = expand("%:t:r")
    macros["fileDirname"]             = expand("%:p:h")
    macros["fileExtname"]             = "." .. expand("%:e")
    macros["relativeFileDirname"]     = fnamemodify(getcwd(), ":t")
    macros["relativeFile"]            = macros["relativeFileDirname"] ..  macros["pathSeparator"] .. macros["fileBasename"]
    macros["cword"]                   = expand("<cword>")
    macros["lineNumber"]              = '' .. &lines
    # macros["cwd"] = getcwd()
    # macros["selectedText"] = ''
    return macros
enddef

# default parameters
def Scheme_params(opts: dict<any>, rep: dict<any>): dict<any>
    var params = opts
    params.type                = get(opts, "type", get(rep, "type", "floaterm"))
    params.command             = get(opts, "command", get(rep, "command", ""))
    params.save                = get(opts, "save", get(rep, "save", "none"))
    params.options             = get(opts, "options", get(rep, "options", {}))
    params.options.cwd         = get(params.options, "cwd", "${workspaceFolder}")
    params.options.shell       = get(params.options, "shell", get(rep, "shell", {}))
    params.options.shell.executable = get(params.options.shell, "executable", &shell)
    params.options.shell.args  = get(params.options.shell, "args", [])
    params.args                = get(opts, "args", get(rep, "args", []))
    params.presentation        = get(opts, "presentation", get(rep, "presentation", {}))
    params.presentation.reveal = get(params.presentation, "reveal", "always")
    params.presentation.echo   = get(params.presentation, "echo", v:false)
    params.presentation.focus  = get(params.presentation, "focus", v:true)
    params.presentation.panel  = get(params.presentation, "panel", "new")

    if rep == {}
        params.tasks = get(opts, "tasks", [])
    else
        params.dependsType  = get(opts, "dependsType", "preLaunch")
        params.dependsOn    = get(opts, "dependsOn", [])
        params.dependsOrder = get(opts, "dependsOrder", "parallel")
        if params.dependsType == "postLaunch"
            insert(params.dependsOn, params.label)
        else
            add(params.dependsOn, params.label)
        endif
    endif
    return params
enddef

# process predefinedvars
var macros = Expand_marcors()
def Process_vars(str: string): string
    var subpattern   = '\${[a-zA-Z]\{-}}'
    var keypattern   = '[a-zA-Z]\+'
    var inputpattern = '\${input=\(.\{-}\)}'
    var tmp = str
    while v:true
        var substr = matchstr(tmp, subpattern)
        var keystr = matchstr(substr, keypattern)
        if has_key(macros, keystr)
            tmp = substitute(tmp, substr, macros[keystr], 'g')
        else
            var inputstr = matchstr(tmp, inputpattern)
            var tips = substitute(inputstr, inputpattern, '\1', 'g')
            if inputstr != ''
                call inputsave()
                echohl type
                var inputcontent = input("Input your " .. tips .. ": ")
                execute "normal \<Esc>"
                echohl None
                call inputrestore()
                tmp = substitute(tmp, inputpattern, inputcontent, '')
            else
                break
            endif
        endif
    endwhile

    return tmp
enddef

def Process_params(name: string, opts: dict<any>)
    var defaultparams = Scheme_params(opts, {})
    for task in opts.tasks
        if get(task, 'label', '') == ''
            Utils.ErrorMsg('task miss "label"')
        endif
        task.label = trim(task.label)
        if index(tasks_complete_list, task.label) != -1
            task.label = task.label .. "::" .. name
        endif
        add(tasks_complete_list, task.label)

        # complete task's params
        var taskparams = Scheme_params(task, defaultparams)
        taskparams.filetype = get(taskparams, 'filetype', {})
        if taskparams.filetype == {}
            if has_key(tasks_filetype, "*")
                add(tasks_filetype["*"], taskparams.label)
            else
                tasks_filetype["*"] = []
                add(tasks_filetype["*"], taskparams.label)
            endif
            tasks_info[taskparams.label] = taskparams
        endif
        for key in keys(taskparams.filetype)
            var ft = taskparams.filetype[key]
            ft.label = taskparams.label .. "::" .. key
            ft = Scheme_params(ft, task)
            for k in keys(taskparams.options)
                if !has_key(ft.options, k)
                    ft.options[k] = taskparams.options[k]
                endif
            endfor
            # add label-opts to tasks_filetype
            if has_key(tasks_filetype, key)
                add(tasks_filetype[key], taskparams.label)
            else
                tasks_filetype[key] = []
                add(tasks_filetype[key], taskparams.label)
            endif
            tasks_info[ft.label] = ft
        endfor
    endfor
enddef

