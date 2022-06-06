vim9script

# vim:sw=4
# ============================================================================
# File:           floaterm.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:    Run tasks in voldikss/vim-floaterm
# LICENSE:        MIT
# ============================================================================

import autoload "../Utils.vim"

export def Run(bang: bool, opts: dict<any>): void
    if !exists(':FloatermNew')
        Utils.ErrorMsg("require voldikss/vim-floaterm")
        return void
    endif
    var shell = g:floaterm_shell
    g:floaterm_shell = opts.options.shell.executable
    if opts.presentation.panel == 'new'
        Floaterm_run_new(bang, opts)
    elseif opts.presentation.panel == 'shared'
        Floaterm_run_op(v:true, opts, 'shared')
    else
        Floaterm_run_op(v:true, opts, 'dedicated')
    endif
    g:floaterm_shell = shell
enddef


def Floaterm_params(opts: dict<any>): dict<any>
    var params = {}
    params.cwd = fnameescape(opts.options.cwd)
    params.name = fnameescape(get(opts.options, 'name', '') != '' ?  opts.options.name : opts.label)
    if has_key(opts.options, 'width')
        params.width = opts.options.width
    endif
    if has_key(opts.options, 'height')
        params.height = opts.options.height
    endif
    if has_key(opts.options, 'title')
        params.title = fnameescape(opts.options.title)
    endif
    if has_key(opts.options, 'wintype')
        params.wintype = opts.options.wintype
    endif
    if has_key(opts.options, 'position')
        params.position = opts.options.position
    endif
    if has_key(opts.options, 'opener')
        params.opener = opts.options.opener
    endif
    if has_key(opts.options, 'silent')
        params.silent = opts.options.silent
    else
        params.silent = get(opts.presentation, 'reveal', 'silent') != 'silent' ? 0 : 1
    endif
    if has_key(opts.options, 'disposable')
        params.disposable = opts.options.disposable
    endif
    if has_key(opts.options, 'autoclose')
        params.autoclose = opts.options.autoclose
    endif
    return params
enddef

def Floaterm_focus(): void
    if !has("nvim") | return | endif
    stopinsert | noa wincmd p
    augroup close-floaterm-runner
        autocmd!
        autocmd CursorMoved,InsertEnter * ++nested call timer_start(100, { -> s:floaterm_close() })
    augroup end
enddef

def Floaterm_close(): void
    if &ft == 'floaterm' | return | endif
    for b in tabpagebuflist()
        if getbufvar(b, '&ft') == 'floaterm' && getbufvar(b, 'floaterm_jobexists') == v:false
            execute b 'bwipeout!'
            break
        endif
    endfor
enddef

def Floaterm_run_new(bang: bool, opts: dict<any>): void
    var cmd = bang ? "FloatermNew!" : "FloatermNew"
    var params = Floaterm_params(opts)
    for key in keys(params)
        cmd ..= ' --' .. key .. '=' .. (type(params[key]) == v:t_float ?  string(params[key]) : params[key])
    endfor
    var cmdline = opts.command
    for arg in opts.args
        cmdline ..= ' ' .. arg
    endfor
    cmd ..= ' ' .. cmdline
    execute cmd
    if get(opts.presentation, 'focus', v:false) == v:true
        Floaterm_focus()
    endif
enddef

def Floaterm_run_op(bang: bool, opts: dict<any>, panel: string): void
    var params = Floaterm_params(opts)
    var curr_bufnr = -1
    if panel == 'dedicated'
        curr_bufnr = floaterm#terminal#get_bufnr(params.name)
    elseif panel == 'shared'
        curr_bufnr = floaterm#buflist#curr()
    endif
    if curr_bufnr == -1
        curr_bufnr = floaterm#new(bang, '', {}, params)
    endif
    if get(opts, 'silent', 0) == 1
        FloatermHide!
    else
        execute ":" .. curr_bufnr .. 'FloatermShow'
    endif
    var cmd = 'cd ' .. shellescape(params.cwd)
    var cmdline = opts.command
    for arg in opts.args
        cmdline ..= ' ' .. arg
    endfor
    floaterm#terminal#send(curr_bufnr, [cmd])
    floaterm#terminal#send(curr_bufnr, [cmdline])
    stopinsert
    if &filetype == 'floaterm' && g:floaterm_autoinsert
        call floaterm#util#startinsert()
    endif
    if get(opts.presentation, 'focus', v:false) == v:true
        Floaterm_focus()
    endif
enddef

