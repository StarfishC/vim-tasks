vim9script

# vim:sw=4
# ============================================================================
# File:           vscodetask.vim
# Author:         caoshenghui <576365750@qq.com>
# Github:         https://github.com/caoshenghui
# Description:
# LICENSE:        MIT
# ============================================================================


# ${workspaceFolder} - the path of the folder opened in Vim
# ${workspaceFolderBasename} - the name of the folder opened in Vim without any slashes (/)
# ${file} - the current opened file
# ${fileWorkspaceFolder} - the current opened file's workspace folder
# ${relativeFile} - the current opened file relative to workspaceFolder
# ${relativeFileDirname} - the current opened file's dirname relative to workspaceFolder
# ${fileBasename} - the current opened file's basename
# ${fileBasenameNoExtension} - the current opened file's basename with no file extension
# ${fileDirname} - the current opened file's dirname
# ${fileExtname} - the current opened file's extension
# ${cwd} - the task runner's current working directory on startup
# ${cword} - the word under the cursor
# ${lineNumber} - the current selected line number in the active file
# ${selectedText} - the current selected text in the active file
# ${pathSeparator} - the character used by the operating system to separate components in file paths
# ${input=xxx} - you can input something in vim

import autoload './utils.vim'

# reference : https://code.visualstudio.com/docs/editor/tasks-appendix
class PresentationOptions
    public var reveal: string # 'never' | 'silent' | 'always'
    public var echo: bool
    public var focus: bool
    public var panel: string # 'shared' | 'dedicated' | 'new'
    public var showReuseMessage: bool
    public var clear: bool
    public var group: string
endclass

class BackgroundMatcher
    public var activeOnStart: bool
    public var beginPattern: string
    public var endPattern: string
endclass

class ProblemMatcher # only support pattern
    public var base: string
    public var owner: string
    public var source: string
    public var severity: string
    public var fileLocation: any
    public var pattern: any
    public var background: BackgroundMatcher
endclass

class RunOptions
    public var reevaluateOnRerun: bool
    public var runOn: string
endclass

class CommandOptions
    public var cwd: string
    public var env: dict<string>
    public var shell: dict<any>

    def Clone(): any
        var obj = CommandOptions.new()
        obj.cwd = this.cwd
        obj.env = deepcopy(this.env)
        obj.shell = deepcopy(this.shell)
        return obj
    enddef
endclass

export class TaskDescription
    public var label: string
    public var type: string
    public var typeOptions: dict<any>  # vim only
    public var command: string
    public var isBackground: bool
    public var args: list<string>
    public var presentation: PresentationOptions
    public var group: any
    public var problemMatcher: ProblemMatcher
    public var runOptions: RunOptions
    public var options: CommandOptions

    # compound tasks
    public var dependsOrder: string
    public var dependsOn: list<string>

    def Clone(): any
        var obj = TaskDescription.new()
        obj.label = this.label
        obj.type = this.type
        obj.typeOptions = deepcopy(this.typeOptions)
        obj.command = this.command
        obj.isBackground = this.isBackground
        obj.args = deepcopy(this.args)
        obj.presentation = this.presentation
        obj.group = this.group
        obj.problemMatcher = this.problemMatcher
        obj.runOptions = this.runOptions
        obj.options = this.options.Clone()
        obj.dependsOrder = this.dependsOrder
        obj.dependsOn = deepcopy(this.dependsOn)
        return obj
    enddef

endclass

abstract class BaseTaskConfiguration
    public var type: string
    public var typeOptions: dict<any>  # vim only
    public var command: string
    public var isBackground: bool
    public var options: CommandOptions
    public var args: list<string>
    public var presentation: PresentationOptions
    public var problemMatcher: ProblemMatcher
    public var tasks: list<TaskDescription>
endclass

export class TaskConfiguration extends BaseTaskConfiguration
    public var version: string
    public var windows: BaseTaskConfiguration
    public var osx: BaseTaskConfiguration
    public var linux: BaseTaskConfiguration
endclass

export class Tasks
    var _json_file: string
    var _json_data: dict<any>
    var _labels: list<string>
    var _task_config: TaskConfiguration

    def new(this._json_file)
        if filereadable(this._json_file)
            this._json_data = utils.JsoncDecode(this._json_file)
            this._SerializeDataToTaskConfiguration()
        endif
    enddef

    def GetConfiguration(): TaskConfiguration
        return this._task_config
    enddef

    def GetLabels(): list<string>
        return this._labels
    enddef

    def _SerializeDataToTaskConfiguration(): void
        var opts = this._json_data
        if type(get(opts, 'options')) != type({}) | opts.options = {} | endif
        if type(get(opts.options, 'shell')) != type({}) | opts.options.shell = {} | endif
        if type(get(opts.options, 'env')) != type({}) | opts.options.env = {} | endif
        if type(get(opts, 'presentation')) != type({}) | opts.presentation = {} | endif

        this._task_config = TaskConfiguration.new()
        this._task_config.type = get(opts, 'type', 'shell')
        this._task_config.typeOptions = get(opts, 'typeOptions', {})
        this._task_config.command = get(opts, 'command', '')
        this._task_config.isBackground = get(opts, 'isBackground', false)
        this._task_config.options = CommandOptions.new()
        this._task_config.options.cwd = get(opts.options, 'cwd', '${workspaceFolder}')
        this._task_config.options.env = get(opts.options, 'env', {})
        this._task_config.options.shell = get(opts.options, 'shell', {})
        this._task_config.options.shell.executable = get(opts.options.shell, 'executable', &shell)
        this._task_config.options.shell.args = get(opts.options.shell, 'args', [])
        this._task_config.args = get(opts, 'args', [])
        this._task_config.presentation = PresentationOptions.new()
        this._task_config.presentation.reveal = get(opts.presentation, 'reveal', 'always')
        this._task_config.presentation.echo = get(opts.presentation, 'echo', false)
        this._task_config.presentation.focus = get(opts.presentation, 'focus', true)
        this._task_config.presentation.panel = get(opts.presentation, 'panel', 'new')
        this._task_config.tasks = []

        for task in opts.tasks
            if get(task, 'label', '') == '' | continue | endif
            task.label = trim(task.label)
            this._AddTaskDescrption(task)
            add(this._labels, task.label)
        endfor
    enddef

    def _AddTaskDescrption(Task: dict<any>)
        var task_description = TaskDescription.new()
        Task['presentation'] = get(Task, 'presentation', {})
        Task['options'] = get(Task, 'options', {})
        Task['options']['shell'] = get(Task.options, 'shell', {})
        task_description.label = Task.label
        task_description.type = get(Task, 'type', this._task_config.type)
        task_description.typeOptions = deepcopy((get(Task, 'typeOptions', {})))
        task_description.typeOptions->extend(this._task_config.typeOptions, 'keep')
        task_description.command = get(Task, 'command', this._task_config.command)
        task_description.isBackground = get(Task, 'isBackground', this._task_config.isBackground)
        task_description.args = deepcopy(get(Task, 'args', []))
        task_description.group = get(Task, 'group', '')
        task_description.presentation = PresentationOptions.new()
        task_description.presentation.reveal = get(Task.presentation, 'reveal', this._task_config.presentation.reveal)
        task_description.presentation.echo = get(Task.presentation, 'echo', this._task_config.presentation.echo)
        task_description.presentation.focus = get(Task.presentation, 'focus', this._task_config.presentation.focus)
        task_description.presentation.panel = get(Task.presentation, 'panel', this._task_config.presentation.panel)
        task_description.options = CommandOptions.new()
        task_description.options.cwd = get(Task.options, 'cwd', this._task_config.options.cwd)
        task_description.options.env = get(Task.options, 'env', this._task_config.options.env)
        task_description.options.shell = {}
        task_description.options.shell.executable = get(Task.options.shell, 'executable', this._task_config.options.shell.executable)
        task_description.options.shell.args = deepcopy(get(Task.options.shell, 'args', this._task_config.options.shell.args))
        task_description.dependsOn = deepcopy(get(Task, 'dependsOn', []))
        task_description.dependsOrder = get(Task, 'dependsOrder', '')
        add(this._task_config.tasks, task_description)
    enddef

endclass

export class TaskManager
    var _file_name: string
    var _file_time: number
    var _task: Tasks

    def new(fname: string)
        this._file_name = fname
        this._file_time = getftime(fname)
        this._task = Tasks.new(fname)
    enddef

    def GetTask(): Tasks
        var ftime = getftime(this._file_name)
        if ftime > this._file_time
            this._task = Tasks.new(this._file_name)
            this._file_time = ftime
        endif
        return this._task
    enddef

    def FindTaskDesc(Label: string): TaskDescription
        var ret: TaskDescription
        var base_config = this._task.GetConfiguration()
        if base_config != null
            var tasks = base_config.tasks
            for task in tasks
                if task.label == Label
                    ret = task.Clone()
                    break
                endif
            endfor
        endif
        return ret
    enddef

endclass

# predefinedvars like VScode
export class Macros
    var _macros: dict<string>

    def new(IsWindows: bool, LocalPath: string)
        this._macros['pathSeparator']           = IsWindows ? '\\' : '/'
        this._macros['workspaceFolder']         = LocalPath
        this._macros['workspaceFolderBasename'] = fnamemodify(this._macros['workspaceFolder'], ':t')
        this._macros['file']                    = expand('%:p')
        this._macros['fileWorkspaceFolder']     = LocalPath
        this._macros['fileBasename']            = expand('%:t')
        this._macros['fileBasenameNoExtension'] = expand('%:t:r')
        this._macros['fileDirname']             = expand('%:p:h')
        this._macros['fileExtname']             = '.' .. expand('%:e')
        this._macros['relativeFileDirname']     = fnamemodify(getcwd(), ':t')
        this._macros['relativeFile'] = this._macros['relativeFileDirname'] .. this._macros['pathSeparator'] .. this._macros['fileBasename']
        this._macros['cword']                   = expand('<cword>')
        this._macros['lineNumber']              = '' .. &lines
    enddef

    def HandleMacros(TaskDesc: TaskDescription)
        TaskDesc.command = this._HandleVars(TaskDesc.command)
        for i in range(len(TaskDesc.args))
            TaskDesc.args[i] = this._HandleVars(TaskDesc.args[i])
        endfor
        TaskDesc.options.cwd = this._HandleVars(TaskDesc.options.cwd)
    enddef

    def _HandleVars(str: string): string
        var subpattern   = '\${[a-zA-Z]\{-}}'
        var keypattern   = '[a-zA-Z]\+'
        var inputpattern = '\${input=\(.\{-}\)}'
        var tmp = str
        while true
            var substr = matchstr(tmp, subpattern)
            var keystr = matchstr(substr, keypattern)
            if has_key(this._macros, keystr)
                tmp = substitute(tmp, substr, this._macros[keystr], 'g')
            else
                var inputstr = matchstr(tmp, inputpattern)
                var tips = substitute(inputstr, inputpattern, '\1', 'g')
                if inputstr != ''
                    call inputsave()
                    echohl type
                    var inputcontent = input("Input your " .. tips .. ": ")
                    execute "normal \<Esc>"
                    echohl None
                    call inputrestore()
                    tmp = substitute(tmp, inputpattern, inputcontent, '')
                else
                    break
                endif
            endif
        endwhile
        return tmp
    enddef

endclass

