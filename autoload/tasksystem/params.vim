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
let s:is_nvim = has("nvim")
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
    if s:is_nvim == 1
        let dic = []
        for i in range(len(l:contents))
            if l:contents[i] =~ pattern1
                let l:contents[i] = substitute(l:contents[i], pattern1, '', '')
            endif
            call add(dic, l:contents[i])
        endfor
        return json_decode(dic)
    else
        let dic = {}
        let pattern2 = '\s*"\(.*\)"\s*:\s*\(.*\),\s*'           " match key-value, example 'ss' : 1.0
        let pattern3 = '\s*"\(.*\)"\s*:\s*"\(.*\)"\s*,\?\s*'    " match key-value, example 'ss' : 'abc'
        for i in range(len(l:contents))
            if l:contents[i] =~ pattern1
                let l:contents[i] = substitute(l:contents[i], pattern1, '', '')
            endif
            if l:contents[i] =~ '\d\s*,$'     "ends with number and a comma
                let l:contents[i] = substitute(l:contents[i], pattern2, '\1=;\2', '')
                let tmp = split(l:contents[i], "=;")
                if len(tmp) != 2
                    call tasksystem#utils#errmsg("split error: " . l:contents[i])
                    return {}
                endif
                let dic[tmp[0]] = str2float(tmp[1])
            elseif l:contents[i] =~ '\s*[\s*'       " ends with [
            elseif l:contents[i] =~ '\"\s*,\?$'     " ends with string and a comma
                let l:contents[i] = substitute(l:contents[i], pattern3, '\1=;\2', '')
                let tmp = split(l:contents[i], "=;")
                if len(tmp) != 2
                    call tasksystem#utils#errmsg("split error: " . l:contents[i])
                    return {}
                endif
                if len(tmp) != 2
                    call tasksystem#utils#errmsg("split error: " . l:contents[i])
                    return {}
                endif
                let dic[tmp[0]] = tmp[1]
            endif
        endfor
    endif
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

" preset parameters
function! s:schema_params(opts) abort
    let params = a:opts
    let params.type = get(a:opts, "type", "floaterm")
    let params.command = get(a:opts, 'command', '')
    let params.isBackground = get(a:opts, 'isBackground', v:false)
    let params.options = get(a:opts, 'options', {})
    let params.options.cwd = get(params.options, 'cwd', "${workspaceFolder}")
    " let params.options.env = get(params.options, 'env', {})       unuseful now
    " let params.options.shell = get(params.options, 'shell', {})   unuseful now
    let params.args = get(a:opts, 'args', [])
    let params.presentation = get(a:opts, 'presentation',
                            \ {"reveal": "always", "echo" : v:false, "focus": v:true, "panel": "new"})
    let params.tasks = get(a:opts, 'tasks', [])
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
        let keystr = matchstr(tmp, keypattern)
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
    let defaultparams = s:schema_params(a:opts)
    let taskinfo = {}
    for task in a:opts.tasks
        if get(task, 'label', '') == ''
            call tasksystem#utils#errmsg('task miss "label"')
        endif
        if has_key(s:namecompleteopts, task.label)
            let task.label = task.label . "::" . name
        endif
        call add(s:namecompleteopts, task.label)
        " complete task's params
        let task.type = get(task, 'type', defaultparams.type)
        let task.command = get(task, 'command', defaultparams.command)
        let task.isBackground = get(task, 'isBackground', defaultparams.isBackground)
        let task.options = get(task, 'options', defaultparams.options)
        let task.args = get(task, 'args', defaultparams.args)
        let task.presentation = get(task, 'presentation', defaultparams.presentation)
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
            let s:filetypetaskinfo["*"] = [task.label]
        endif
        for key in keys(task.filetype)
            let ft = task.filetype[key]
            let ft.command = (get(ft, 'command', '') == '') ? task.command : s:transfer_vars(ft.command)
            if has_key(ft, 'args')
                if type(ft.args) != v:t_list
                    call tasksystem#utils#errmsg("parameter 'args' is must a list")
                endif
                for i in range(len(ft.args))
                    let ft.args[i] = s:transfer_vars(ft.args[i])
                endfor
            else
                let ft.args = task.args
            endif
            if has_key(ft, 'options')
                if type(ft.options) != v:t_dict
                    call tasksystem#utils#errmsg("parameter 'options' is must a dict")
                endif
                for tmp in keys(ft.options)
                    let ft.options[tmp] = s:transfer_vars(ft.options[tmp])
                endfor
            else
                let ft.options = task.options
            endif
            " add label-opts to s:filetypetaskinfo
            let s:filetypetaskinfo[key] = get(s:filetypetaskinfo, key, [])
            call add(s:filetypetaskinfo[key], task.label)
        endfor
        let taskinfo[task.label] = task
    endfor
    return taskinfo
endfunction


function! tasksystem#params#namelist() abort
    call tasksystem#params#taskinfo()
    return s:namecompleteopts
endfunction

function! tasksystem#params#fttaskinfo() abort
    return s:filetypetaskinfo
endfunction

function! tasksystem#params#taskinfo()
    let s:namecompleteopts = []
    let s:filetypetaskinfo = {}
    let ret = {}
    let ret.local = s:json_decode(s:default_local_path . '/' . s:local_json_name)
    let ret.global = s:json_decode(s:default_global_path . '/' . s:global_json_name)
    for task in keys(ret)
        let ret[task] = s:process_params(task, ret[task])
    endfor
    return ret
endfunction

