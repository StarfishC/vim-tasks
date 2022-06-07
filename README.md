# Tasks

[![GitHub license](https://img.shields.io/github/license/caoshenghui/vim-tasks)](https://github.com/caoshenghui/vim-tasks/blob/master/LICENSE) 
[![Maintenance](https://img.shields.io/maintenance/yes/2021)](https://github.com/caoshenghui/vim-tasks/graphs/commit-activity)


An asynchronous task system like VSCode on **Vim** (not support neovim now)

![Sceenshot][1]

## Features

- [ ] support terminal
- [ ] support quickfix
- [ ] support neovim
- [x] support parallel/sequent/continuous tasks
- [x] support [vim-floaterm][2]
- [x] list in [LeaderF][3]

## Wiki

You can visit [wiki][8] for details.

## Instruction

**VSCode** uses a `.vscode/tasks.json` file to define project specific tasks. Similar, **Tasks** uses a `.tasks.json` file in your project folders for local tasks and uses `~/.vim/tasks.json` for `vim`( or `'~/.config/nvim/tasks.json'` for `neovim`) to define global tasks for generic projects.

## Installtion

For [vim-plug][4]

```vim
Plug 'caoshenghui/vim-tasks'
Plug 'voldikss/vim-floaterm'
```

in your `.vimrc` or `init.vim`, then restart (neo)vim and run **`:PlugInstall`**

## Usage

### Commands

Start a task called taskname:

```vim
:TaskRun[!] taskname
```

### Tasks

Maybe you need to visit the [Task configuration][9] so that you can configure your tasks.

Example: 

- run your python file using vim-floaterm

  ```jsonc
  {
    "tasks": [
      {
        "label": "test-run",
        "type": "floaterm",
        "options": {
          "cwd": "${workspaceFolder}"
        },
        "command": "python3",
        "args": ["${file}"]
      }
    ]
  }  
  ```

  Run **`:TaskRun test-run`**, it will execute `python3 ${file}`, `${file}` and `${workspaceFolder}` are predefinedvars.
  
- If you want to run single `CPP` file with taskname "test-run", you need to set `filetype` option

  ```
  {
    "tasks": [
      {
        "label": "test-run",
        "type": "floaterm",
        "options": {
          "cwd": "${workspaceFolder}"
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
          }
        }
      },
      {
        "label": "execute",
        "command": "time",
        "args": ["${fileWorkspaceFolder}${pathSeparator}a.out"]
      }
    ]
  }
  ```

  When running **:TaskRun test-run**, the task will start with `clang++` in `CPP` file, and with `python3` in `python` file, of course, both starting with `args`.
  
- If you want to know more usage,you can visit [Examples][10]

## Extensions

### [vim-floaterm][2]

If you want to use floaterm's options you can put it's options to json's `options`.If you don't set floaterm's options in tasks.json, when you start a task, it's settings depend on [floaterm's options][5]

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

### [LeaderF][3]

If you want to list tasks in **LeaderF**, you need configure the following option:

```vim
g:Tasks_UsingLeaderF = 1
```

Using  **`:LeaderfTask`** or **`:Leaderf --nowrap task`** to start

![LeaderfScreenShot][7]


## Reference

[skywind3000/asynctasks.vim][6]  
[voldikss/vim-floaterm][2]  
[Yggdroot/LeaderF][3]

## License

MIT

[1]: https://user-images.githubusercontent.com/49725192/123510321-5a716800-d6ad-11eb-928b-e9316195a76d.gif
[2]: https://github.com/voldikss/vim-floaterm
[3]: https://github.com/Yggdroot/LeaderF
[4]: https://github.com/junegunn/vim-plug
[5]: https://github.com/voldikss/vim-floaterm#options
[6]: https://github.com/skywind3000/asynctasks.vim
[7]: https://user-images.githubusercontent.com/49725192/123509429-0dd75e00-d6a8-11eb-82cb-ba7cfbf90212.png
[8]: https://github.com/caoshenghui/vim-tasks/wiki
[9]: https://github.com/caoshenghui/vim-tasks/wiki/Task-configuration
[10]: https://github.com/caoshenghui/vim-tasks/wiki/Task-configuration#Examples

