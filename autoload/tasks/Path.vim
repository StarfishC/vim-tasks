vim9script

# vim:sw=4
# ============================================================================
# File:           Path.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:    These codes are from voldikss/vim-floaterm
# LICENSE:        MIT
# ============================================================================


var is_windows = (has("win32") || has("win64")) ? 1 : 0
var default_root_markers = get(g:, 'Tasks_RootMarkers', [])

export def RootDir(): string
    var root = Find_root(getcwd(), default_root_markers, 0)
    return root
enddef

def Find_root(path: string, markers: list<string>, strict: number): string
    def Guess_root(filename: string, markers2: list<string>): string
        var fullname = Full_name(filename)
        if fullname =~ '^fugitive:/'
            if exists('b:git_dir') | return fnamemodify(b:git_dir, ':h') | endif
            return ''
        endif
        var pivot = fullname
        if !isdirectory(pivot)
            pivot = fnamemodify(pivot, ":h")
        endif
        while 1
            var prev = pivot
            for marker in markers2
                var newname = Path_join(pivot, marker)
                if newname =~ '[\*?\[\]]'
                    if glob(newname) != ''
                        return pivot
                    endif
                elseif filereadable(newname) || isdirectory(newname)
                    return pivot
                endif
            endfor
            pivot = fnamemodify(pivot, ':h')
            if pivot == prev | break | endif
        endwhile
        return ''
    enddef

    var root = Guess_root(path, markers)
    if root != ''
        return Full_name(root)
    elseif strict != 0
        return ''
    endif
    # Not found: return parent directory of current file / file itself.
    var fullname = Full_name(path)
    if isdirectory(fullname)
        return fullname
    endif
    return Full_name(fnamemodify(fullname, ':h'))
enddef

def Full_name(name: string): string
    var filename = name
    if filename =~ "'."
        try
            var m = ""
            redir => m
            silent execute ':marks' filename[1]
            redir END
            filename = split(split(m, '\n')[-1])[-1]
            filename = filereadable(filename) ? filename : ''
        catch
            filename = '%'
        endtry
    endif
    filename = (filename != '%') ? filename : expand("%")
    filename = fnamemodify(filename, ':p')
    if is_windows
        filename = substitute(filename, "\\", '/', 'g')
    endif
    if len(filename) > 1
        var size = len(filename)
        if (filename[size - 1]) == '/'
            filename = strpart(filename, 0, size - 1)
        endif
    endif
    return filename
enddef

def Path_join(home: string, name: string): string
    if strlen(home) == 0 | return name | endif
    var last = home[-1 :]
    if is_windows
        if name[0] == '/' || name[0] == "\\"
            var head = strpart(home, 1, 2)
            if index([":\\", ":/"], head) >= 0
                return strpart(home, 0, 2) .. name
            endif
            return name
        elseif index([":\\", ":/"], strpart(name, 1, 2)) >= 0
            return name
        endif
        if last == "/" || last == "\\"
            return home .. name
        else
            return home .. '/' .. name
        endif
    else
        if name[0] == '/' | return name | endif
        if last == "/"
            return home .. name
        else
            return home .. '/' .. name
        endif
    endif
enddef

