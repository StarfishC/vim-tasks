" vim:sw=4
" ============================================================================
" File:           predefinedvars.vim
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

function! s:schema_params(args) abort
    let params = {}
    let params.type = get(a:args, "type", "floaterm")
    let params.command = get(a:args, 'command', '')
    let params.isBackground = get(a:args, 'isBackground', v:false)
    let params.options = get(a:args, 'options', {})
    let params.options.cwd = get(params.options, 'cwd', {"${workspaceFolder}"})
    " let params.options.env = get(params.options, 'env', {})       unuseful now
    " let params.options.shell = get(params.options, 'shell', {})   unuseful now
    let params.args = get(a:args, 'args', [])
    let params.presentation = get(a:args, 'presentation', {})
    let params.tasks = get(a:args, 'tasks', [])
endfunction


" like vscode, it only supports 'command', 'args', 'options', 'filetype'
function! tasksystem#predefinedvars#process_macros(opts) abort
    let macros = s:expand_macros()
    let params = a:opts
    let subpattern = '\${[a-zA-Z]\{-}}'
    let keypattern = '[a-zA-Z]\+'
    if has_key(params, 'command')
        while v:true
            let substr = matchstr(params.command, subpattern)
            let keystr = matchstr(params.command, keypattern)
            if has_key(macros, keystr)
                let retstr = substitute(params.command, substr, macros[keystr], 'g')
                let params.command = retstr
            else
                break
            endif
        endwhile
    endif
    if has_key(params, 'args')
        let args = []
        for arg in params.args
            while v:true
                let substr = matchstr(arg, subpattern)
                let keystr = matchstr(arg, keypattern)
                if has_key(macros, keystr)
                    let arg = substitute(arg, substr, macros[keystr], 'g')
                else
                    call add(args, arg)
                    break
                endif
            endwhile
        endfor
        let params.args = args
    endif
    if has_key(params, 'options')
        for key in keys(params.options)
            if type(params.options[key]) != v:t_string
                continue
            endif
            while v:true
                let substr = matchstr(params.options[key], subpattern)
                let keystr = matchstr(substr, keypattern)
                if has_key(macros, keystr)
                    let retstr = substitute(params.options[key], substr, macros[keystr], 'g')
                    let params.options[key] = retstr
                else
                    break
                endif
            endwhile
        endfor
    endif
    return params
endfunction
