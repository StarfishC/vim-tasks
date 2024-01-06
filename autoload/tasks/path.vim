vim9script

# vim:sw=4
# ============================================================================
# File:           path.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:    These codes are from voldikss/vim-floaterm
# LICENSE:        MIT
# ============================================================================

class Path
    var _is_windows: bool
    var _root_markers: list<string>

    def new(this._root_markers)
        this._is_windows = has('win32') ? true : false
    enddef

    def GetRootDir(): string
        var root = this._FindRoot(getcwd(), this._root_markers, 0)
        return root
    enddef

    def _FindRoot(CurPath: string, Markers: list<string>, Strict: number): string
            def GuessRoot(FileName: string, markers2: list<string>): string
                var fullname = this._FullName(FileName)
            if fullname =~ '^fugitive:/'
                if exists('b:git_dir') | return fnamemodify(b:git_dir, ':h') | endif
                return ''
            endif
            var pivot = fullname
            if !isdirectory(pivot)
                pivot = fnamemodify(pivot, ':h')
            endif
            while 1
                var prev = pivot
                for marker in markers2
                    var newname = this._Pathjoin(pivot, marker)
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

        var root = GuessRoot(CurPath, Markers)
        if root != ''
            return this._FullName(root)
        elseif Strict != 0
            return ''
        endif
        # Not found: return parent directory of current file / file itself.
        var fullname = this._FullName(CurPath)
        if isdirectory(fullname)
            return fullname
        endif
        return this._FullName(fnamemodify(fullname, ':h'))
    enddef

    def _FullName(Name: string): string
        var filename = Name
        if filename =~ "'."
            try
                var m = ''
                redir => m
                silent execute ':marks' filename[1]
                redir END
                filename = split(split(m, '\n')[-1])[-1]
                filename = filereadable(filename) ? filename : ''
            catch
                filename = '%'
            endtry
        endif
        filename = (filename != '%') ? filename : expand('%')
        filename = fnamemodify(filename, ':p')
        if this._is_windows
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

    def _Pathjoin(Home: string, Name: string): string
        if strlen(Home) == 0 | return Name | endif
        var last = Home[-1 :]
        if this._is_windows
            if Name[0] == '/' || Name[0] == '\\'
                var head = strpart(Home, 1, 2)
                if index([':\\', ':/'], head) >= 0
                    return strpart(Home, 0, 2) .. Name
                endif
                return Name
            elseif index([':\\', ':/'], strpart(Name, 1, 2)) >= 0
                return Name
            endif
            if last == '/' || last == '\\'
                return Home .. Name
            else
                return Home .. '/' .. Name
            endif
        else
            if Name[0] == '/' | return Name | endif
            if last == '/'
                return Home .. Name
            else
                return Home .. '/' .. Name
            endif
        endif
    enddef

endclass

export def GetRootDir(Markers: list<string>): string
    return Path.new(Markers).GetRootDir()
enddef
