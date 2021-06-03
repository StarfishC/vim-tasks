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
let s:namecompleteopts = []     " Tasksystem complete
let s:tasksinfo = {}            " all tasks
let s:filetypetaskinfo = {}     " task for specific filetype


" read json file
function! s:json_decode(filename) abort
    let l:filename = expand(a:filename)
    if filereadable(l:filename) == 0
        return {}
    endif
    let l:contents = readfile(l:filename)
    let pattern1 = '\s*[^(".*"\s+,)][\s]*\/\/.*'    "match comments
    for i in range(len(l:contents))
        if l:contents[i] =~ pattern1
            let l:contents[i] = substitute(l:contents[i], pattern1, '', '')
        endif
    endfor
    if !has("nvim")
        let l:contents = join(l:contents, '')
    endif
    return json_decode(l:contents)
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
    let params.dependsOn = get(a:opts, 'dependsOn', get(a:rep, "dependsOn", []))
    let params.dependsType = get(a:opts, 'dependsType', get(a:rep, 'dependsType', 'positive'))
    let params.dependsOrder = get(a:opts, 'dependsOrder', get(a:rep, 'dependsOrder', 'parallel'))
    " let params.tasks = get(a:opts, 'tasks', get(a:rep, "tasks", []))
    if a:rep == {}
        let params.tasks = get(a:opts, 'tasks', [])
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

" like vscode, predefinedvars only supports 'command', 'args', 'options', 'filetype'
function! s:process_params(name, opts) abort
    if a:opts == {}
        return
    endif
    let defaultparams = s:schema_params(a:opts, {})
    for task in a:opts.tasks
        if get(task, 'label', '') == ''
            call tasksystem#utils#errmsg('task miss "label"')
        endif
        if index(s:namecompleteopts, task.label) != -1
            let task.label = task.label . "::" . a:name
        endif
        call add(s:namecompleteopts, task.label)
        " complete task's params
        let task = s:schema_params(task, defaultparams)
        " repalce predefinedvars
        let task.command = s:transfer_vars(task.command)
        for i in range(len(task.args))
            let task.args[i] = s:transfer_vars(task.args[i])
        endfor
        for key in keys(task.options)
            let task.options[key] = s:transfer_vars(task.options[key])
        endfor
        let task.filetype = get(task, 'filetype', {})
        if task.filetype == {}
            if has_key(s:filetypetaskinfo, "*")
                call add(s:filetypetaskinfo["*"], task.label)
            else
                let s:filetypetaskinfo["*"] = []
                call add(s:filetypetaskinfo["*"], task.label)
            endif
            let s:tasksinfo[task.label] = task
        endif
        for key in keys(task.filetype)
            let ft = task.filetype[key]
            let ft = s:schema_params(ft, task)
            for k in keys(task.options)
                if !has_key(ft.options, k)
                    let ft.options[k] = task.options[k]
                endif
            endfor
            let ft.command = s:transfer_vars(ft.command)
            for i in range(len(ft.args))
                let ft.args[i] = s:transfer_vars(ft.args[i])
            endfor
            for tmp in keys(ft.options)
                let ft.options[tmp] = s:transfer_vars(ft.options[tmp])
            endfor
            let ft.label = task.label . "::" . key
            " add label-opts to s:filetypetaskinfo
            if has_key(s:filetypetaskinfo, key)
                call add(s:filetypetaskinfo[key], task.label)
            else
                let s:filetypetaskinfo[key] = []
                call add(s:filetypetaskinfo[key], task.label)
            endif
            let s:tasksinfo[ft.label] = ft
        endfor
    endfor
endfunction


function! tasksystem#params#namelist() abort
    call tasksystem#params#taskinfo()
    let item = []
    if has_key(s:filetypetaskinfo, &filetype)
        let item = s:filetypetaskinfo[&filetype]
    endif
    call extend(item, s:filetypetaskinfo['*'])
    return item
endfunction

function! tasksystem#params#fttaskinfo() abort
    return s:filetypetaskinfo
endfunction

function! tasksystem#params#taskinfo() abort
    let s:namecompleteopts = []
    let s:filetypetaskinfo = {}
    let s:tasksinfo = {}
    let ret = {'global': s:default_global_path . '/' . s:global_json_name,
             \ 'local': s:default_local_path . '/' . s:local_json_name}
    for task in keys(ret)
        call s:process_params(task, s:json_decode(ret[task]))
    endfor
    return s:tasksinfo
endfunction

