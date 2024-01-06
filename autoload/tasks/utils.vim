vim9script

# vim:sw=4
# ============================================================================
# File:       utils.vim
# Author:     caoshenghui <576365750@qq.com>
# Github:     https://github.com/
# LICENSE:    MIT
# ============================================================================


export def ErrorMsg(msg: string): void
    echohl ErrorMsg
    echom "Error: " .. msg
    echohl NONE
enddef

# read json/jsonc file
export def JsoncDecode(filename: string): dict<any>
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
