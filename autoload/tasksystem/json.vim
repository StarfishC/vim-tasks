" local variables
" >>>>>>>>>>>>>>>
let s:default_local_path = tasksystem#predefinedvars#get_root()
let s:default_global_path = get(g:, "tasksystem_global_path", ".")
let s:json_name = get(g:, "tasksystem_tasks_name", "")
let s:is_nvim = has("nvim")
let s:namecompleteopts = []
let s:tasksinfo = {}


" read json file
function! s:tasksystem_json_decode(filename)
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
function! tasksystem#json#getconfig()
    let l:filelist = [s:default_global_path . '/' . s:json_name,
                     \s:default_local_path . '/' . s:json_name]
    let s:namecompleteopts = []
    let s:tasksinfo = {}
    for filepath in filelist
        let l:jsoncontents = s:tasksystem_json_decode(filepath)
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

function! tasksystem#json#namelist()
    " if s:namecompleteopts == []
    "     call tasksystem#json#getconfig()
    " endif
    call tasksystem#json#getconfig()
    return s:namecompleteopts
endfunction

function! tasksystem#json#taskinfo()
    " if s:tasksinfo == {}
    "     call tasksystem#json#getconfig()
    " endif
    call tasksystem#json#getconfig()
    return s:tasksinfo
endfunction

" echo tasksystem#json#getconfig()
" echo s:namecompleteopts
" echo tasksystem#json#taskinfo()

