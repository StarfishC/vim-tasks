" vim:sw=4
" ============================================================================
" File:           floaterm.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:    Run tasks in voldikss/vim-floaterm
" LICENSE:        MIT
" ============================================================================


function! s:floaterm_params(opts) abort
    let params = {}
    let params.cwd = fnameescape(a:opts.options.cwd)
    let params.name = fnameescape(get(a:opts.options, 'name', '') != '' ? a:opts.options.name : a:opts.label)
    if has_key(a:opts.options, 'width')
        let params.width = a:opts.options.width
    endif
    if has_key(a:opts.options, 'height')
        let params.height = a:opts.options.height
    endif
    if has_key(a:opts.options, 'title')
        let params.title = fnameescape(a:opts.options.title)
    endif
    if has_key(a:opts.options, 'wintype')
        let params.wintype = a:opts.options.wintype
    endif
    if has_key(a:opts.options, 'position')
        let params.position = a:opts.options.position
    endif
    if has_key(a:opts.options, 'opener')
        let params.opener = a:opts.options.opener
    endif
    if has_key(a:opts.options, 'silent')
        let params.silent = a:opts.options.silent
    else
        let params.silent = get(a:opts.presentation, 'reveal', 'silent') != 'silent' ? 0 : 1
    endif
    if has_key(a:opts.options, 'disposable')
        let params.disposable = a:opts.options.disposable
    endif
    if has_key(a:opts.options, 'autoclose')
        let params.autoclose = a:opts.options.autoclose
    endif
    return params
endfunction

function! s:floaterm_run_new(bang, opts) abort
    if a:bang
        let cmd = 'FloatermNew!'
    else
        let cmd = 'FloatermNew'
    endif
    let params = s:floaterm_params(a:opts)
    for key in keys(params)
        let cmd .= ' --' . key . '=' . (type(params[key]) == v:t_float ? string(params[key]) : params[key])
    endfor
    let cmdline = a:opts.command
    for arg in a:opts.args
        let cmdline .= ' ' . arg
    endfor
    let cmd .= ' ' . cmdline
    exec cmd
    if get(a:opts.presentation, 'focus', 1) == 0
        call s:floaterm_focus()
    endif
endfunction

function s:floaterm_focus() abort
    if !has("nvim") | return | endif
    stopinsert | noa wincmd p
    augroup close-floaterm-runner
        autocmd!
        autocmd CursorMoved,InsertEnter * ++nested call timer_start(100, { -> s:floaterm_close() })
    augroup end
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

function! s:floaterm_run_op(bang, opts, panel) abort
    let params = s:floaterm_params(a:opts)
    if a:panel == 'dedicated'
        let curr_bufnr = floaterm#terminal#get_bufnr(params.name)
    elseif a:panel == 'shared'
        let curr_bufnr = floaterm#buflist#curr()
    endif
    if curr_bufnr == -1
        let curr_bufnr = floaterm#new(a:bang, '', {}, params)
    endif
    if get(params, 'silent', 0) == 1
        FloatermHide!
    else
        execute curr_bufnr . 'FloatermShow'
    endif
    let cmd = 'cd ' . shellescape(params.cwd)
    let cmdline = a:opts.command
    for arg in a:opts.args
        let cmdline .= ' ' . arg
    endfor
    call floaterm#terminal#send(curr_bufnr, [cmd])
    call floaterm#terminal#send(curr_bufnr, [cmdline])
    stopinsert
    if &filetype == 'floaterm' && g:floaterm_autoinsert
        call floaterm#util#startinsert()
    endif
    if get(a:opts.presentation, 'focus', 1) == 0
        call s:floaterm_focus()
    endif
endfunction


function! tasksystem#extensions#floaterm#run(bang, opts) abort
    if !exists(':FloatermNew')
        return tasksystem#utils#errmsg("require voldikss/vim-floatem")
    endif
    if a:opts.presentation.panel == 'new'
        call s:floaterm_run_new(a:bang, a:opts)
    elseif a:opts.presentation.panel == 'shared'
        call s:floaterm_run_op(v:true, a:opts, 'shared')
    else
        call s:floaterm_run_op(v:true, a:opts, 'dedicated')
    endif
endfunction

