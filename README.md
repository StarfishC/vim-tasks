# Tasksystem

[![GitHub license](https://img.shields.io/github/license/caoshenghui/tasksystem)](https://github.com/caoshenghui/tasksystem/blob/master/LICENSE) 
[![Maintenance](https://img.shields.io/maintenance/yes/2021)](https://github.com/caoshenghui/tasksystem/graphs/commit-activity)


An asynchronous task system like vscode on **(Neo)Vim**

![Sceenshot][1]

## Features

- [ ] support terminal
- [ ] support quickfix
- [x] support parallel/sequent/continuous tasks
- [x] support [vim-floaterm][2]
- [x] list in [LeaderF][3]

## Instruction

Vscode uses a `.vscode/tasks.json` file to define project specific tasks. Similar, Tasksystem uses a `.tasks.json` file in your project folders for local tasks and uses `~/.vim/tasks.json` for `vim`( or `'~/.config/nvim/tasks.json'` for `neovim`) to define global tasks for generic projects.

## Installtion

For [vim-plug][4]

```vim
Plug 'caoshenghui/tasksystem'
Plug 'voldikss/vim-floaterm'
```

in your `.vimrc` or `init.vim`, then restart (neo)vim and run **`:PlugInstall`**

## Start command

```vim
:Tasksystem[!] taskname
```

## Vim configuration

```vim
" Configure your global task file directory
" Default: '~/.vim' for vim and '~/.config/nvim' for nvim
g:tasksystem_globalPath

" Markers used to detect the project root directory
" Default: ['.project', '.root', '.git', '.hg', '.svn']
g:tasksystem_rootMarkers

" Global task json file name
" Default: 'tasks.json'
g:tasksystem_globalTasksName

" Local task json file name
" Default: '.tasks.json'
g:tasksystem_localTasksName
```

## Task congiguration

### Predefinedvars

Predefinedvars like vscode

| Name | Description |
| ---- | ----------- |
| **${workspaceFolder}** |  the path of the folder opened in (Neo)Vim|
| **${workspaceFolderBasename}**| the name of the folder opened in (Neo)Vim without any slashes (/) |
| **${file}** | the current opened file |
| **${fileWorkspaceFolder}** | the current opened file's workspace folder |
| **${relativeFile}** | the current opened file relative to workspaceFolder |
| **${relativeFileDirname}** | the current opened file's dirname relative to workspaceFolder |
| **${fileBasename}** | the current opened file's basename |
| **${fileBasenameNoExtension}** | the current opened file's basename with no file extension |
| **${fileDirname}** | the current opened file's dirname |
| **${fileExtname}** | the current opened file's extension |
| **${lineNumber}** | the current selected line number in the active file |
| **${cword}** | the word under the cursor |
| ${selectedText} (can't support now)| the current selected text in the active file |
| ${cwd} (can't support now)| the task runner's current working directory on startup |
| **${input=xxx}** | If you want to input something in vim, xxx is input tips|

### Options

> **Tasksystem** can support mostly vscode's options for `tasks.json`, you can learn more through [Vscode's tasks][5] and [Schema for tasks.json][6]
Schema for Tasksystem's tasks.json:

```jsonc
interface TaskConfiguration extends BaseTaskConfiguration {
  /**
   * The configuration's version number
   * can be ommitted
   */
  version: '1.0.0';
}

interface BaseTaskConfiguration {
  /**
   * The type of a custom task. Tasks of type "shell" are executed
   * Defaults to 'floaterm'
   * Valid options: ['floaterm']
   */
  type: string;

  /**
   * The command to be executed
   * Defaults to ''
   */
  command: string;

  /**
   * Which buffer to write
   * Defaults to 'none'
   * Valid options: ['none', 'all', 'current']
   * - 'none': not save any buffer
   * - 'all': write all changed buffers
   * - 'current': only write current buffer
   */
  save?: string

  /**
   * The command options used when the command is executed
   */
  options?: CommandOptions;  see "interface CommandOptions" for details

  /**
   * The arguments passed to the command
   * Defaults to []
   */
  args?: string[];

  /**
   * The presentation options
   */
  presentation?: PresentationOptions; see "interface PresentationOptions" for details

  /**
   * The configuration of the available tasks
   */
  tasks?: TaskDescription[]; see "interface TaskDescription" for details
}

export interface CommandOptions {
  /**
   * The current working directory of the executed program or shell
   * Defaults to "${workspaceFolder}"
   */
  cwd?: string;
}

export interface PresentationOptions {
  /**
   * Controls whether the task output is reveal in the user interface
   * Defaults to "always"
   * Valid options: ["silent", "always"]
   * - "silent": not show in the user interface
   * - "always": always show
   */
  reveal?: string;

  /**
   * Controls whether the panel showing the task output is taking focus
   * Can't work correctly in vim popup windows(E994)
   */
  focus?: boolean;

  /**
   * Controls how the task panel is used
   * Defaults to "new"
   * Valid: ["new", "shared", "dedicated"]
   * - "new": every task execution will open a new panel 
   * - "shared": a panel shares between tasks, if the panel is not existed, a new panel will be created
   * - "dedicated": the task panel is used for this task only
   */
  panel?: string;
}

export interface TaskDescription {
  /**
   * The task's name
   */
  label: string;

  /**
   * These following options correspond to the options of "interface BaseTaskConfiguration"
   * Only work the task if you set these options
   */
  type: string;
  command: string;
  save?: string;
  args?: string[];
  options?: CommandOptions;
  presentation?: PresentationOptions;

  /**
   * Compose tasks out of simpler tasks
   * Defaults to []
   */
   dependsOn?: string[];

  /**
   * Order of the task execution
   * 'preLaunch' and 'postLaunch' are available
   * If you set 'preLaunch', the task will be executed after `dependsOn`, 'postLaunch' is before `dependsOn`
   * Defaults to "preLaunch"
   * Valid options: ["preLaunch", "postLaunch"]
   * - "preLaunch": the task will be executed after `dependsOn`
   * - "postLaunch": the task will be executed before `dependsOn`
   */
   dependsType?: string;

   /**
    * Execute 'dependsOn' mode
    * Defaults to 'parallel'
    * Valid options: ["parallel", "sequent", "continuous"]
    * - "parallel": these tasks can be executed in parallel
    * - "sequent": these tasks can be executed in sequent
          e.g, ["ls", "pwd"] "ls" will be executed firstly, no matter whether the task is successful or not, 
               and "pwd" will be executed secondly, 
    * - "continuous": these tasks can be executed in continuous
          e.g, ["rm xxx", "ls"] "rm xxx" will be executed firstly, if execution failed, 
               the next command "ls" will not be exectue, like "rm xxx && ls " in your shell
    */
    dependsOrder?: string;
    
   /**
    * The task only works specific filetype, works on all filetype by default
    * You can reconfigure `task` options expect "label","filetype"
    * e.g, {"cpp": {"command": "g++", "args": [], "python": {"command": "python3"}}
    * See README 'Examples' for details
    */
    filetype?:{}task;
}
```

## Extensions

### [vim-floaterm][2]

If you want to use floaterm's options you can put it's options to json's `options`.If you don't set floaterm's options in tasks.json, when you start a task, it's settings depend on [floaterm's options][7]

**Example:**

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
   "presentation": {
     // when `panel='shared'`, it will reuse floaterm's windows next
     "panel": "shared",
     // if you omit `options['silent']`, `reveal` will decide whether silent
     "reveal": "silent",
   }
}
```

**Command:**

If `panel != 'shared'`, **`:Tasksystem[!] taskname`** will start by **`:FloatermNew[!]`**  
If `panel = 'shared'` then it uses **`:FloatermNew!`** to create a terminal so that it can be reused again

### [LeaderF][3]

If you want to list tasks in **LeaderF**, you need set the following option:

```vim
let g:tasksystem_listLeaderF = 1
```

Use **`:LeaderfTask`** or **`:Leaderf --nowrap task`** to start

![LeaderfScreenShot][9]

## Json Examples

`tasks.json`

```jsonc
{
    "version": "1.0.0",
    "type": "floaterm",
    "options": {
        "cwd": "${fileWorkspaceFolder}"
    },
    "presentation": {
        "panel": "shared"
    },
    "tasks": [
        {
            "label": "quick-run",
            "type": "floaterm",
            "save": "current",
            "options": {
                "position": "bottomright",
                "autoclose": 0
            },
            "presentation": {
                "focus": 0,
                "panel": "shared"
            },
            "filetype": {
                "python": {
                    "command": "python3",
                    "args": ["${file}"]
                },
                "cpp": {
                    "command": "clang++",
                    "args": [
                        "${file}",
                        "-std=c++11",
                        "-o",
                        "${fileWorkspaceFolder}${pathSeparator}a.out"
                    ],
                    "dependsOn": ["execute"],
                    "dependsType": "postLaunch",
                    "dependsOrder": "sequent"
                },
                "vim": {
                    "command": "so ${file}",
                    "type": "vim"
                },
                "markdown": {
                    "command": "MarkdownPreviewToggle",
                    "type": "vim"
                }
            }
        },
        {
            "label": "execute",
            "command": "time",
            "args": [
                "${fileWorkspaceFolder}${pathSeparator}a.out"
            ]
        },
        {
            "label": "project-build",
            "command": "rm build -r;mkdir build && cd build && cmake",
            "args": [
                "-DECMAKE_EXPORT_COMPILE_COMMANDS=1",
                ".."
            ]
        },
        {
            "label": "project-cmake",
            "command": "cmake",
            "args": [
                "--build",
                "build"
            ]
        },
        {
            "label": "project-run",
            "command": "build${pathSeparator}${workspaceFolderBasename}"
        },
        {
            "label": "project",
            "dependsOrder": "sequent",
            "dependsOn": ["project-build", "project-cmake", "project-run"]
        }
    ]
}
```

## Reference

[skywind3000/asynctasks.vim][8]

[voldikss/vim-floaterm][2]

## License

MIT

[1]: https://user-images.githubusercontent.com/49725192/122890034-e87be480-d375-11eb-8d81-5b7b1e1cb74e.gif
[2]: https://github.com/voldikss/vim-floaterm
[3]: https://github.com/Yggdroot/LeaderF
[4]: https://github.com/junegunn/vim-plug
[5]: https://code.visualstudio.com/docs/editor/tasks
[6]: https://code.visualstudio.com/docs/editor/tasks-appendix
[7]: https://github.com/voldikss/vim-floaterm#options
[8]: https://github.com/skywind3000/asynctasks.vim
[9]: https://user-images.githubusercontent.com/49725192/123261538-764c0100-d529-11eb-992c-add3f4724bad.png
