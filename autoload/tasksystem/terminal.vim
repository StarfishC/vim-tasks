" vim:sw=4
" ============================================================================
" File:           terminal.vim
" Author:         caoshenghui <576365750@qq.com>
" Github:         https://github.com/caoshenghui
" Description:
" LICENSE:        MIT
" ============================================================================


function! s:callback(channel, msg)
endfunction

function! s:out_cb(channel, msg)
endfunction

function! s:err_cb(channel, msg)
endfunction

function! s:close_cb(channel)
endfunction

function! s:exit_cb(channel, status)
endfunction

function! s:terminal_options(opts) abort
    let options = {}
    let options.stoponexit  = "term"
    let options.cwd         = a:opts.options.cwd
    " let options.env =
    let options.callback    = function("s:callback")
    let options.out_cb      = function("s:out_cb")
    let options.err_cb      = function("s:err_cb")
    let options.exit_cb     = function("s:exit_cb")
    let options.close_cb    = function("s:close_cb")

    let options.term_name   = get(a:opts.options, 'title', a:opts.label)
    let options.term_rows   = get(a:opts.options, 'height', winheight('')/2)
    let options.term_cols   = get(a:opts.options, 'width', winwidth('')/2)
    let options.term_kill   = "kill"
    let options.term_finish = "open"
    let options.eof_chars   = ""
    let options.hidden      = 0

    if has_key(a:opts.options, 'position')
        if a:opts.options.position == 'vsplit'
            let options.vertical = 1
            let options.curwin   = 0
        endif
    endif
    return options
endfunction

function! s:terminal_run1(opts) abort
    let options = s:terminal_options(a:opts)
    let cmdlist = [a:opts.command]
    call extend(cmdlist, a:opts.args)
    let id = win_getid()
    call term_start(cmdlist, options)
    if a:opts.presentation.focus == 0
        call win_gotoid(id)
    endif
endfunction

function! s:terminal_run2(opts) abort
    let shell = a:opts.options.shell.executable
    let options = s:terminal_options(a:opts)
    let buf = term_start("zsh", options)
    let cmdline = a:opts.command
    for arg in a:opts.args
        let cmdline .= " " . arg
    endfor
    let cmdline .= "\n"
    let job = term_getjob(buf)
    call ch_sendraw(job, cmdline)
endfunction


function! tasksystem#terminal#run(bang, opts) abort
    if a:bang
        call s:terminal_run2(a:opts)
    else
        call s:terminal_run1(a:opts)
    endif
endfunction
