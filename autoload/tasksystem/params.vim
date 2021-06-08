" vim:sw=4
" ============================================================================
" File:           params.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:
" LICENSE:        MIT
" ============================================================================


" ${workspaceFolder} - the path of the folder opened in VS Code
" ${workspaceFolderBasename} - the name of the folder opened in VS Code without any slashes (/)
" ${file} - the current opened file
" ${fileWorkspaceFolder} - the current opened file's workspace folder
" ${relativeFile} - the current opened file relative to workspaceFolder
" ${relativeFileDirname} - the current opened file's dirname relative to workspaceFolder
" ${fileBasename} - the current opened file's basename
" ${fileBasenameNoExtension} - the current opened file's basename with no file extension
" ${fileDirname} - the current opened file's dirname
" ${fileExtname} - the current opened file's extension
" ${cwd} - the task runner's current working directory on startup
" ${lineNumber} - the current selected line number in the active file
" ${selectedText} - the current selected text in the active file
" ${execPath} - the path to the running VS Code executable
" ${defaultBuildTask} - the name of the default build task
" ${pathSeparator} - the character used by the operating system to separate components in file paths


let s:local_json_name = get(g:, "tasksystem_localTasksName", "")
let s:global_json_name = get(g:, "tasksystem_globalTasksName", "")
let s:default_local_path = tasksystem#path#get_root()
let s:default_global_path = get(g:, "tasksystem_globalPath", ".")
if has("win32") || has("win64")
    let s:is_windows = 1
else
    let s:is_windows = 0
endif
let s:tasks_complete_list = []      " Tasksystem complete
let s:tasks_info = {}               " all tasks
let s:tasks_filetype = {}           " task for specific filetype
let s:file_modify_time = {"local": 0, "global": 0}  " last modification time of tasks.json


" read json file
function! s:json_decode(filename) abort
    if filereadable(a:filename) == 0
        return {}
    endif
    let contents = readfile(a:filename)
    let pattern1 = '\s*[^(".*"\s+,)][\s]*\/\/.*'    "match comments
    for i in range(len(contents))
        if contents[i] =~ pattern1
            let contents[i] = substitute(contents[i], pattern1, '', '')
        endif
    endfor
    if !has("nvim")
        let contents = join(contents, '')
    endif
    return json_decode(contents)
endfunction

" predefinedvars like vscode
function! s:expand_macros() abort
	let macros = {}
    if s:is_windows == 1
        let macros['pathSeparator'] = '\\'
    else
        let macros['pathSeparator'] = '/'
    endif
    let macros['workspaceFolder'] = tasksystem#path#get_root()
    let macros['workspaceFolderBasename'] = fnamemodify(macros['workspaceFolder'], ':t')
    let macros['file'] = expand("%:p")
    let macros['fileWorkspaceFolder'] = tasksystem#path#get_root()
    let macros['fileBasename'] = expand("%:t")
    let macros['fileBasenameNoExtension'] = expand("%:t:r")
    let macros['fileDirname'] = expand("%:p:h")
    let macros['fileExtname'] = "." . expand("%:e")
    let macros['relativeFileDirname'] = fnamemodify(getcwd(), ":t")
    let macros['relativeFile'] = macros['relativeFileDirname'] . macros['pathSeparator'] . macros['fileBasename']
    " let macros['cwd'] = getcwd()
    let macros['lineNumber'] = '' . &lines
    " let macros['selectedText'] = ''

	return macros
endfunction

" default parameters
function! s:schema_params(opts, rep) abort
    let params = a:opts
    let params.type = get(a:opts, "type", get(a:rep, "type", "floaterm"))
    let params.command = get(a:opts, 'command', get(a:rep, "command", ""))
    let params.save = get(a:opts, 'save', get(a:rep, "save", "none"))
    let params.isBackground = get(a:opts, 'isBackground', get(a:rep, "isBackground", v:false))
    let params.options = get(a:opts, 'options', get(a:rep, "options", {}))
    let params.options.cwd = get(params.options, 'cwd', get(get(a:rep, "options", {}), "cwd", "${workspaceFolder}"))
    " let params.options.env = get(params.options, 'env', {})       unuseful now
    " let params.options.shell = get(params.options, 'shell', {})   unuseful now
    let params.args = get(a:opts, 'args', get(a:rep, "args", []))
    let presentation = {"reveal": "always", "echo" : v:false, "focus": v:true, "panel": "new"}
    let params.presentation = get(a:opts, 'presentation', get(a:rep, "presentation", presentation))
    let params.presentation.reveal = get(a:opts.presentation, 'reveal', get(get(a:rep, 'presentation', presentation), 'reveal', 'always'))
    let params.presentation.echo = get(a:opts.presentation, 'echo', get(get(a:rep, 'presentation', presentation), 'echo', v:false))
    let params.presentation.focus = get(a:opts.presentation, 'focus', get(get(a:rep, 'presentation', presentation), 'focus', v:true))
    let params.presentation.panel = get(a:opts.presentation, 'panel', get(get(a:rep, 'presentation', presentation), 'panel', "new"))
    " let params.tasks = get(a:opts, 'tasks', get(a:rep, "tasks", []))
    if a:rep == {}
        let params.tasks = get(a:opts, 'tasks', [])
    else
        let params.dependsType = get(a:opts, 'dependsType', 'preLaunch')
        let params.dependsOn = get(a:opts, 'dependsOn', [])
        let params.dependsOrder = get(a:opts, 'dependsOrder', 'parallel')
        if params.dependsType == 'postLaunch'
            call insert(params.dependsOn, params.label)
        else
            call add(params.dependsOn, params.label)
        endif
    endif
    return params
endfunction

" transfer predefinedvars
function! s:transfer_vars(str) abort
    let macros = s:expand_macros()
    if type(a:str) != v:t_string
        return a:str
    endif
    let subpattern = '\${[a-zA-Z]\{-}}'
    let keypattern = '[a-zA-Z]\+'
    let tmp = a:str
    while v:true
        let substr = matchstr(tmp, subpattern)
        let keystr = matchstr(substr, keypattern)
        if has_key(macros, keystr)
            let tmp = substitute(tmp, substr, macros[keystr], 'g')
        else
            break
        endif
    endwhile
    return tmp
endfunction

function! s:process_params(name, opts) abort
    if a:opts == {}
        return
    endif
    let defaultparams = s:schema_params(a:opts, {})
    for task in a:opts.tasks
        if get(task, 'label', '') == ''
            call tasksystem#utils#errmsg('task miss "label"')
        endif
        if index(s:tasks_complete_list, task.label) != -1
            let task.label = task.label . "::" . a:name
        endif
        call add(s:tasks_complete_list, task.label)
        " complete task's params
        let task = s:schema_params(task, defaultparams)
        let task.filetype = get(task, 'filetype', {})
        if task.filetype == {}
            if has_key(s:tasks_filetype, "*")
                call add(s:tasks_filetype["*"], task.label)
            else
                let s:tasks_filetype["*"] = []
                call add(s:tasks_filetype["*"], task.label)
            endif
            let s:tasks_info[task.label] = task
        endif
        for key in keys(task.filetype)
            let ft = task.filetype[key]
            let ft.label = task.label . "::" . key
            let ft = s:schema_params(ft, task)
            for k in keys(task.options)
                if !has_key(ft.options, k)
                    let ft.options[k] = task.options[k]
                endif
            endfor
            " add label-opts to s:tasks_filetype
            if has_key(s:tasks_filetype, key)
                call add(s:tasks_filetype[key], task.label)
            else
                let s:tasks_filetype[key] = []
                call add(s:tasks_filetype[key], task.label)
            endif
            let s:tasks_info[ft.label] = ft
        endfor
    endfor
endfunction


" like vscode, predefinedvars only supports 'command', 'args', 'options', 'filetype'
function! tasksystem#params#replacemacros(task) abort
    if a:task == {}
        return
    endif
    let task = deepcopy(a:task)
    " repalce predefinedvars
    let task.command = s:transfer_vars(task.command)
    for i in range(len(task.args))
        let task.args[i] = s:transfer_vars(task.args[i])
    endfor
    for key in keys(task.options)
        let task.options[key] = s:transfer_vars(task.options[key])
    endfor
    return task
endfunction

function! tasksystem#params#completelist() abort
    call tasksystem#params#taskinfo()
    let item = []
    if has_key(s:tasks_filetype, &filetype)
        let item = copy(s:tasks_filetype[&filetype])
    endif
    call extend(item, s:tasks_filetype['*'])
    return item
endfunction

function! tasksystem#params#filetypetask() abort
    return s:tasks_filetype
endfunction

function! tasksystem#params#taskinfo() abort
    let files = {'global': expand(s:default_global_path . '/' . s:global_json_name),
             \ 'local' : expand(s:default_local_path . '/' . s:local_json_name)}
    for file in keys(files)
        let lasttime = getftime(files[file])
        if lasttime != -1 && lasttime > s:file_modify_time[file]
            let s:file_modify_time[file] = lasttime
            call s:process_params(file, s:json_decode(files[file]))
        endif
    endfor
    return s:tasks_info
endfunction

