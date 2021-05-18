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

let s:default_root_markers = get(g:, 'tasksystem_root_markers', '')

if has("win32") || has("win64")
    let s:is_windows = 1
else
    let s:is_windows = 0
endif

function! s:expand_macros()
	let macros = {}
    if s:is_windows == 1
        let macros['pathSeparator'] = '\\'
    else
        let macros['pathSeparator'] = '/'
    endif
    let macros['workspaceFolder'] = tasksystem#predefinedvars#get_root()
    let macros['workspaceFolderBasename'] = fnamemodify(macros['workspaceFolder'], ':t')
    let macros['file'] = expand("%:p")
    let macros['fileWorkspaceFolder'] = tasksystem#predefinedvars#get_root()
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
endfunc

function! s:find_root(path, markers, strict)
    function! s:guess_root(filename, markers)
        let fullname = s:fullname(a:filename)
        if fullname =~ '^fugitive:/'
            if exists('b:git_dir')
                return fnamemodify(b:git_dir, ':h')
            endif
            return '' " skip any fugtitive buffers early
        endif
        let pivot = fullname
        if !isdirectory(pivot)
            let pivot = fnamemodify(pivot, ':h')
        endif
        while 1
            let prev = pivot
            for marker in a:markers
                let newname = s:path_join(pivot, marker)
                if newname =~ '[\*?\[\]]'
                    if glob(newname) != ''
                        return pivot
                    endif
                elseif filereadable(newname)
                    return pivot
                elseif isdirectory(newname)
                    return pivot
                endif
            endfor
            let pivot = fnamemodify(pivot, ':h')
            if pivot == prev
                break
            endif
        endwhile
        return ''
    endfunction

    let root = s:guess_root(a:path, a:markers)
    if root != ''
        return s:fullname(root)
    elseif a:strict != 0
        return ''
    endif
    " Not found: return parent directory of current file / file itself.
    let fullname = s:fullname(a:path)
    if isdirectory(fullname)
        return fullname
    endif
    return s:fullname(fnamemodify(fullname, ':h'))
endfunction

function! s:fullname(f)
    let f = a:f
    if f =~ "'."
        try
            redir => m
            silent exe ':marks' f[1]
            redir END
            let f = split(split(m, '\n')[-1])[-1]
            let f = filereadable(f) ? f : ''
        catch
            let f = '%'
        endtry
    endif
    let f = (f != '%') ? f : expand('%')
    let f = fnamemodify(f, ':p')
    if s:is_windows
        let f = substitute(f, "\\", '/', 'g')
    endif
    if len(f) > 1
        let size = len(f)
        if f[size - 1] == '/'
            let f = strpart(f, 0, size - 1)
        endif
    endif
    return f
endfunction

function! s:path_join(home, name)
    let l:size = strlen(a:home)
    if l:size == 0 | return a:name | endif
    let l:last = strpart(a:home, l:size - 1, 1)
    if s:is_windows
        let l:first = strpart(a:name, 0, 1)
        if l:first == '/' || l:first == "\\"
            let head = strpart(a:home, 1, 2)
            if index([":\\", ":/"], head) >= 0
                return strpart(a:home, 0, 2) . a:name
            endif
            return a:name
        elseif index([":\\", ":/"], strpart(a:name, 1, 2)) >= 0
            return a:name
        endif
        if l:last == "/" || l:last == "\\"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    else
        if strpart(a:name, 0, 1) == '/'
            return a:name
        endif
        if l:last == "/"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    endif
endfunction

function! tasksystem#predefinedvars#get_root()
    let markers = s:default_root_markers
    let strict = 0
    let l:hr = s:find_root(getcwd(), markers, strict)
    if s:is_windows
        let l:hr = s:StringReplace(l:hr, '/', '\\')
    endif
    return l:hr
endfunction

