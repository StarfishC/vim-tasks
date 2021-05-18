
function! s:floaterm_params(opts)
    let params = {}
    if get(a:opts, 'cwd', '') == ''
        let params.cwd = fnameescape(getcwd())
    else
        let params.cwd = fnameescape(a:opts.cwd)
    endif
    if has_key(a:opts, 'name')
        let params.name = fnameescape(a:opts.name)
    endif
    if has_key(a:opts, 'width')
        let params.width = a:opts.width
    endif
    if has_key(a:opts, 'height')
        let params.height = a:opts.height
    endif
    if has_key(a:opts, 'title')
        let params.title = fnameescape(a:opts.title)
    endif
    if has_key(a:opts, 'wintype')
        let params.wintype = a:opts.wintype
    endif
    if has_key(a:opts, 'position')
        let params.position = a:opts.position
    endif
    if has_key(a:opts, 'opener')
        let params.opener = a:opts.opener
    endif
    if has_key(a:opts, 'silent')
        let params.silent = a:opts.silent
    endif
    if has_key(a:opts, 'disposable')
        let params.disposable = a:opts.disposable
    endif
    if has_key(a:opts, 'autoclose')
        let params.autoclose = a:opts.autoclose
    endif
    return params
endfunction


function! s:floaterm_run(opts)
    if get(a:opts, 'bang', '!') == '!'
        let cmd = 'FloatermNew!'
    else
        let cmd = 'FloatermNew'
    endif
    let params = s:floaterm_params(a:opts)
    for key in keys(params)
        let cmd .= ' --' . key . '=' . params[key]
    endfor
    if get(a:opts, 'cmd', '') != ''
        let cmd .= ' ' . a:opts.cmd
    endif
    exec cmd
    if get(a:opts, 'focus', 1) == 0
        stopinsert | noa wincmd p
        augroup close-floaterm-runner
            autocmd!
            autocmd CursorMoved,InsertEnter * ++nested call timer_start(100, { -> s:floaterm_close() })
        augroup end
    endif
endfunction


function! s:floaterm_close() abort
    if &ft == 'floaterm' | return | endif
    for b in tabpagebuflist()
        if getbufvar(b, '&ft') == 'floaterm' && getbufvar(b, 'floaterm_jobexists') == v:false
            execute b 'bwipeout!'
            break
        endif
    endfor
endfunction


function! s:floaterm_run_reuse(opts)
    let params = s:floaterm_params(a:opts)
    let curr_bufnr = floaterm#buflist#curr()
    if curr_bufnr == -1
        let bang = v:true
        if get(a:opts, 'bang', '!') != '!'
            let bang = '!'
        endif
        let curr_bufnr = floaterm#new(bang, 'ls', {}, params)
    else
        call floaterm#terminal#open_existing(curr_bufnr)
    endif
    if get(params, 'silent', 0) == 1
        FloatermHide!
    endif
    let cmd = 'cd ' . shellescape(params.cwd)
    call floaterm#terminal#send(curr_bufnr, [cmd])
    call floaterm#terminal#send(curr_bufnr, [a:opts.cmd])
    stopinsert
    if &filetype == 'floaterm' && g:floaterm_autoinsert
        call floaterm#util#startinsert()
    endif
    return 0
endfunction


function! tasksystem#floaterm#run(opts)
    if exists(':FloatermNew') != 2
        return tasksystem#utils#errmsg("require voldikss/vim-floatem")
    endif
    if get(a:opts, 'reuse', 0) == 1
        call s:floaterm_run_reuse(a:opts)
    else
        call s:floaterm_run(a:opts)
    endif
endfunction


" ==================== TEST ========================
let dic = {}
let dic.position = 'bottom'
let dic.type = 'floaterm'
let dic.autoclose = 0
let dic.bang = '!'
let dic.focus = 0
let dic.cmd = 'ls -la'
" echo s:floaterm_run(dic)
" echo tasksystem#floaterm#run(dic)

" call s:floaterm_run_reuse(dic)

let cmd = "ls"
let jobopts = {}
let params = {'cwd': '~/.vim' , 'wintype' : 'float', 'position': 'center', 'silent': 0, 'autoclose':0}
let bang = '!'
" call floaterm#new(1, cmd, jobopts, params)
