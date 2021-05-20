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


if has("win32") || has("win64")
    let s:is_windows = 1
else
    let s:is_windows = 0
endif
let s:namecompleteopts = []     " Tasksystem complete
let s:tasksinfo = {}            " all tasks
let s:filetypetaskinfo = {}     " task for specific filetype
let s:macros = s:expand_macros()


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
    let params.presentation = get(a:opts, 'presentation', {})
    return params
endfunction

" transfer predefinedvars
function! s:transfer_vars(str) abort
    if type(a:str) != v:t_string
        return a:str
    endif
    let subpattern = '\${[a-zA-Z]\{-}}'
    let keypattern = '[a-zA-Z]\+'
    let tmp = a:str
    while v:true
        let substr = matchstr(tmp, subpattern)
        let keystr = matchstr(tmp, keypattern)
        if has_key(s:macros, keystr)
            let tmp = substitute(tmp, substr, s:macros[keystr], 'g')
        else
            break
        endif
    endwhile
    return tmp
endfunction


" like vscode, it only supports 'command', 'args', 'options', 'filetype'
function! tasksystem#params#process(opts) abort
    let s:namecompleteopts = []
    let s:tasksinfo = {}
    let s:filetypetaskinfo = {}
    echo a:opts
    return
    for task in a:opts.tasks
        if get(task, 'label', '') == ''
            call tasksystem#utils#errmsg('task miss "label"')
        endif
        call add(s:namecompleteopts, task.label)
        let task = s:schema_params(task)
        let task.command = s:transfer_vars(task.command)
        for i in range(len(task.args))
            let task.args[i] = s:transfer_vars(task.args[i])
        endfor
        for key in keys(task.options)
            let task.options[key] = s:transfer_vars(task.options[key])
        endfor
        let task.filetype = get(task, 'filetype', {})
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
                for key in keys(ft.options)
                    let ft.options[key] = s:transfer_vars(ft.options[key])
                endfor
            else
                let ft.options = task.options
            endif
            " add label-opts to s:filetypetaskinfo
        endfor
        let s:tasksinfo[key] = task
    endfor
endfunction

function! tasksystem#json#namelist() abort
    call s:json_getconfig()
    return s:namecompleteopts
endfunction

function! tasksystem#json#taskinfo() abort
    call s:json_getconfig()
    return s:tasksinfo
endfunction
