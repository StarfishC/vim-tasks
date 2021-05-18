let s:is_nvim = has("nvim")
let s:config = tasksystem#json#taskinfo()


" Job callback
function! s:task_callback(channel, text)
endfunction

" Job close_cb
function! s:task_close_cb(channel)
endfunction

" Job exit_cb
function! s:task_exit_cb()
endfunction


function! tasksystem#job#start(bang, taskname, ...)
    if has_key(s:config, a:taskname)
        let taskconfig = s:config[a:taskname]
        let command = get(taskconfig, 'command', '')
        let args = get(taskconfig, 'args', '')
        if command == ''
            call tasksystem#utils#errmsg("command empty!")
        endif
        if s:is_nvim == 0
            let l:options = {}
            let l:options['callback'] = function('s:task_callback')
            let l:options['close_cb'] = function('s:task_close_cb')
            let l:options['exit_cb'] = function('s:task_exit_cb')
            let l:options['out_io'] = 'pipe'
            let l:options['err_io'] = 'out'
            let l:options['in_io'] = 'null'
            let l:options['out_mode'] = 'nl'
            let l:options['err_mode'] = 'nl'
            let l:options['stoponexit'] = 'term'
            if g:asyncrun_stop != ''
                let l:options['stoponexit'] = g:asyncrun_stop
            endif
            if s:async_info.range > 0
                let l:options['in_io'] = 'buffer'
                let l:options['in_mode'] = 'nl'
                let l:options['in_buf'] = s:async_info.range_buf
                let l:options['in_top'] = s:async_info.range_top
                let l:options['in_bot'] = s:async_info.range_bot
            elseif exists('*ch_close_in')
                if g:asyncrun_stdin != 0
                    let l:options['in_io'] = 'pipe'
                endif
            endif
            let s:async_job = job_start(l:args, l:options)
            let l:success = (job_status(s:async_job) != 'fail')? 1 : 0
            if l:success && l:options['in_io'] == 'pipe'
                silent! call ch_close_in(job_getchannel(s:async_job))
            endif
        else
            let l:callbacks = {'shell': 'AsyncRun'}
            let l:callbacks['on_stdout'] = function('s:AsyncRun_Job_NeoVim')
            let l:callbacks['on_stderr'] = function('s:AsyncRun_Job_NeoVim')
            let l:callbacks['on_exit'] = function('s:AsyncRun_Job_NeoVim')
            let s:neovim_stdout = ''
            let s:neovim_stderr = ''
            let s:async_job = jobstart(l:args, l:callbacks)
            let l:success = (s:async_job > 0)? 1 : 0
            if l:success != 0
                if s:async_info.range > 0
                    let l:top = s:async_info.range_top
                    let l:bot = s:async_info.range_bot
                    let l:lines = getline(l:top, l:bot)
                    if exists('*chansend')
                        call chansend(s:async_job, l:lines)
                    elseif exists('*jobsend')
                        call jobsend(s:async_job, l:lines)
                    endif
                endif
                if exists('*chanclose')
                    call chanclose(s:async_job, 'stdin')
                elseif exists('*jobclose')
                    call jobclose(s:async_job, 'stdin')
                endif
            endif
        endif
    else
        call tasksystem#utils#errmsg(a:taskname . " task can't found")
    endif
endfunction


function! tasksystem#job#stop()
endfunction


call tasksystem#job#start("!", "build")
