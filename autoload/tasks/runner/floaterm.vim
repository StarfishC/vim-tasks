vim9script

# vim:sw=4
# ============================================================================
# File:           floaterm.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:    Run tasks in voldikss/vim-floaterm
# LICENSE:        MIT
# ============================================================================

import autoload '../runner.vim'
import autoload '../utils.vim'
import autoload '../vscodetask.vim'

# https://github.com/voldikss/vim-floaterm#Commands
export class FloatermRunner extends runner.Runner
    var _task: vscodetask.TaskDescription

    def Execute(Bang: bool, Task: vscodetask.TaskDescription): void
        this._task = Task

        if !exists(':FloatermNew')
            utils.ErrorMsg("Require voldikss/vim-floaterm")
            return
        endif
        var shell = g:floaterm_shell
        g:floaterm_shell = this._task.options.shell.executable
        this._SetFloatermOptions()
        var panel = this._task.presentation.panel
        if panel == 'new'
            this._RunNewFloaterm(Bang)
        else
            this._RunOldFloaterm(Bang, panel)
        endif
        g:floaterm_shell = shell
    enddef

    def _RunNewFloaterm(Bang: bool): void
        floaterm#new(Bang, this._GetCmd(), {}, this._task.typeOptions)
        this._FocusFloaterm()
    enddef

    def _RunOldFloaterm(Bang: bool, Panel: string): void
        var curr_bufnr = -1
        if Panel == 'dedicated'
            curr_bufnr = floaterm#terminal#get_bufnr(this._task.typeOptions.name)
        else
            curr_bufnr = floaterm#buflist#curr()
        endif
        if curr_bufnr == -1
            curr_bufnr = floaterm#new(Bang, this._GetCmd(), {}, this._task.typeOptions)
        else
            var cmd = []
            add(cmd, 'cd ' .. this._task.typeOptions.cwd)
            add(cmd, this._GetCmd())
            floaterm#terminal#send(curr_bufnr, cmd)
            if !this._task.typeOptions.silent
                floaterm#show(Bang, curr_bufnr, '')
            endif
        endif
        this._FocusFloaterm()
    enddef

    def _SetFloatermOptions()
        if !has_key(this._task.typeOptions, 'cwd')
            this._task.typeOptions.cwd = this._task.options.cwd
        endif
        if !has_key(this._task.typeOptions, 'name')
            this._task.typeOptions.name = this._task.label
        endif
        if !has_key(this._task.typeOptions, 'silent')
            this._task.typeOptions.silent = this._task.presentation.reveal != 'silent' ? 0 : 1
        endif
    enddef

    def _GetCmd(): string
        var cmd = this._task.command
        cmd ..= ' ' .. join(this._task.args, ' ')
        return cmd
    enddef

    def _FocusFloaterm(): void
        if this._task.presentation.focus && !this._task.typeOptions.silent
            stopinsert | noa wincmd p
            augroup close-floaterm-runner
                autocmd!
                autocmd CursorMoved,InsertEnter * ++nested call timer_start(100, { -> s:floaterm_close() })
            augroup end
        endif
    enddef

endclass
