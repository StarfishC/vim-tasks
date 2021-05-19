" vim:sw=4
" ============================================================================
" File:           json.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:
" LICENSE:        MIT
" ============================================================================


" local variables
let s:local_json_name = get(g:, "tasksystem_localTasksName", "")
let s:global_json_name = get(g:, "tasksystem_globalTasksName", "")
let s:default_local_path = tasksystem#path#get_root()
let s:default_global_path = get(g:, "tasksystem_globalPath", ".")
let s:is_nvim = has("nvim")
let s:namecompleteopts = []
let s:tasksinfo = {}


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

" extract json file configs
function! s:json_getconfig() abort
    let l:filelist = [s:default_global_path . '/' . s:global_json_name,
                     \s:default_local_path . '/' . s:local_json_name]
    let s:namecompleteopts = []
    let s:tasksinfo = {}
    for filepath in filelist
        let l:jsoncontents = s:json_decode(filepath)
        if l:jsoncontents != {}
            for tmp in l:jsoncontents.tasks
                if get(tmp, 'label', 'error') == 'error'
                    call tasksystem#utils#errmsg('tasks miss "label"')
                    return 0
                endif
                let s:tasksinfo[tmp.label] = {}
                call add(s:namecompleteopts, tmp.label)
                for key in keys(tmp)
                    if key == 'args'
                        let s:tasksinfo[tmp.label][key] = join(tmp[key], ' ')
                    else
                        let s:tasksinfo[tmp.label][key] = tmp[key]
                    endif
                endfor
            endfor
        endif
    endfor
    return 1
endfunction


function! tasksystem#json#namelist() abort
    call s:json_getconfig()
    return s:namecompleteopts
endfunction

function! tasksystem#json#taskinfo() abort
    call s:json_getconfig()
    return s:tasksinfo
endfunction

