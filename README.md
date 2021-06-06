# Tasksystem

An asynchronous task system like vscode on **(Neo)Vim**

![Sceenshot][1]

## Features

- [x] support [vim-floaterm][2]
- [x] support sequent tasks
- [ ] support terminal
- [ ] support quickfix
- [ ] list in [LeaderF][3]

## Instruction

Vscode use a `.vscode/tasks.json` file to define project specific tasks. Similar, Tasksystem uses a `.tasks.json` file in your project folders for local tasks and use `'~/.config/nvim/tasks.json'` for `neovim`( or `~/.vim/tasks.json` for `vim`) to define global tasks for generic projects.

## Installtion

For [vim-plug][4]

```vim
Plug 'caoshenghui/tasksystem'
Plug 'voldikss/vim-floaterm'
```

in your `.vimrc` or `init.vim`, then restart (neo)vim and run `:PlugInstall`

## Usage

### Start command

```vim
:Tasksystem[!] taskname
```

### Predefinedvars

Predefinedvars like vscode

| Name | Description |
| ---- | ----------- |
| ${workspaceFolder} |  the path of the folder opened in (Neo)Vim|
| ${workspaceFolderBasename}| the name of the folder opened in (Neo)Vim without any slashes (/) |
| ${file} | the current opened file |
| ${fileWorkspaceFolder} | the current opened file's workspace folder |
| ${relativeFile} | the current opened file relative to workspaceFolder |
| ${relativeFileDirname} | the current opened file's dirname relative to workspaceFolder |
| ${fileBasename} | the current opened file's basename |
| ${fileBasenameNoExtension} | the current opened file's basename with no file extension |
| ${fileDirname} | the current opened file's dirname |
| ${fileExtname} | the current opened file's extension |
| ${lineNumber} | the current selected line number in the active file |
| ${selectedText} (can't support now)| the current selected text in the active file |
| ${cwd} (can't support now)| the task runner's current working directory on startup |

### Options

**Tasksystem** can support mostly vscode's options for `tasks.json`, you can learn more through [Vscode's tasks][5] and [Schema for tasks.json][6]

Schema for Tasksystem's tasks.json:

```jsonc
interface TaskConfiguration extends BaseTaskConfiguration {
  /**
   * The configuration's version number
   */
  version: '1.0.0';
}

interface BaseTaskConfiguration {
  /**
   * The type of a custom task. Tasks of type "shell" are executed
   * a shell (e.g. floaterm)
   * Defaults to 'floaterm'
   */
  type: string;

  /**
   * The command to be executed.
   * Defaults to ''
   */
  command: string;

  /**
   * Specifies whether a global command is a background task.
   * Defaults to false
   */
  isBackground?: boolean;

  /**
   * The command options used when the command is executed.
   */
  options?: CommandOptions;  see `interface CommandOptions` for details

  /**
   * The arguments passed to the command.
   * Defaults to []
   */
  args?: string[];

  /**
   * The presentation options.
   */
  presentation?: PresentationOptions; see `interface PresentationOptions` for details

  /**
   * The configuration of the available tasks.
   */
  tasks?: TaskDescription[]; see `interface TaskDescription` for details
}

export interface CommandOptions {
  /**
   * The current working directory of the executed program or shell.
   * Defaults to '${workspaceFolder}'
   */
  cwd?: string;

/**
 * The description of a task.
 */
interface TaskDescription {
  /**
   * The task's name
   */
  label: string;

  /**
   * The type of a custom task. Tasks of type "shell" are executed
   * inside a shell (e.g. terminal, floaterm)
   * Defaults to 'floaterm'
   */
   type: string;

  /**
   * The command to execute.
   * command line including any additional arguments passed to the command.
   * Defaults to ''
   */
  command: string;

  /**
   * Whether the executed command is kept alive and runs in the background.
   * Defaults to false
   */
  isBackground?: boolean;

  /**
   * Additional arguments passed to the command.
   * Defaults to []
   */
  args?: string[];

  /**
   * The presentation options.
   */
  presentation?: PresentationOptions;

  /**
   * Compose tasks out of simpler tasks
   * Defaults to []
   */
   dependsOn?: string[];

  /**
   * The task executed order
   * 'preLaunch' and 'postLaunch' are available
   * If you set 'preLaunch', the task will be executed after `dependsOn`, 'postLaunch' is before `dependsOn`
   * Defaults to 'preLaunch' 
   */
   dependsType?: string;

   /**
    * Execute 'dependsOn' mode
    * Defaults to 'parallel', 'sequent', 'continuous' are available
    */
    dependsOrder?: string;
}

interface PresentationOptions {
  /**
   * Controls whether the task output is reveal in the user interface.
   * Defaults to `always`.
   */
  reveal?: 'never' | 'silent' | 'always';

  /**
   * Controls whether the panel showing the task output is taking focus.
   */
  focus?: boolean;

  /**
   * Controls if the task panel is used for this task only (dedicated),
   * shared between tasks (shared) or if a new panel is created on
   * every task execution (new). Defaults to `new`
   */
  panel?: 'shared' | 'dedicated' | 'new';
}
```

#### floaterm

If you want to use floaterm's options you can put it's options to json's options.If you don't set floaterm's options, when you start a task, it's settins depend on [floaterm's options][7]

For example:

```jsonc
{
  "type": "floaterm",
  "command": "python3",
  "args": ["${file}"],
  "options": {
    "cwd": "${workspaceFolder}",
    "autoclose": 0,
    "wintype": "float",
    "name": "123",
    "silent": 0,
    "width": 0.5,
    "height": 0.5,
    "title": "test",
    "position": "center"
  },
  // if you omit `options['silent']`, `isBackground` will decide whether silent
  "isBackground": false,
  "presentation": {
    // when `panel='shared'`, it will reuse floaterm's windows next
    "panel": "shared"
  }
}
```

**Command:**

If `panel != 'shared'`

```vim
:Tasksystem[!] taskname
```

It will start by `:FloatermNew[!]`

### Examples

`tasks.json`

```jsonc
{
  "version": "1.0.0",
  // This `isBackground` is a global option
  "isBackground": false,
  "tasks": [
    {
      "label": "run",
      "type": "floaterm",
      "isBackground": false,
      "presentation": {
          "shared": "new"
      },
      "options": {
        "cwd": "${workspaceFolder}",
        "name": "123",
        "width": 0.5,
        "height": 0.5,
        "title": "test",
        "silent": 0,
        "wintype": "float",
        "position": "center",
        "autoclose": 0
      },
      "filetype": {
        "python": {
          "command": "python3",
          "args": ["${file}"],
          "options": {
            "cwd": "${workspaceFolder}"
          }
        },
        "cpp": {
          "command": "./a.out",
          "args": [],
          "options": {
            "cwd": "${workspaceFolder}"
          }
        }
      }
    }
  ]
}
```

**Note:**

If you set `filetype` in your single `task`, you can override these parameters: `command`,`args`,`options`,`type`.And this task only works filetypes list in `filetype`

## Reference

[skywind3000/asynctasks.vim][8]

[voldikss/vim-floaterm][2]

## License

MIT

[1]: ./GIF1.gif
[2]: https://github.com/voldikss/vim-floaterm
[3]: https://github.com/Yggdroot/LeaderF
[4]: https://github.com/junegunn/vim-plug
[5]: https://code.visualstudio.com/docs/editor/tasks
[6]: https://code.visualstudio.com/docs/editor/tasks-appendix
[7]: https://github.com/voldikss/vim-floaterm#options
[8]: https://github.com/skywind3000/asynctasks.vim
