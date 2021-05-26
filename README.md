# Tasksystem

An asynchronous task system like vscode on neovim

> can't support vim now, beacause of the function(`json_decode`) in vim_

## Features

- [x] support [vim-floaterm](https://github.com/voldikss/vim-floaterm)
- [ ] support sequent tasks
- [ ] support terminal
- [ ] support quickfix
- [ ] list in [LeaderF](https://github.com/Yggdroot/LeaderF)

## Instruction

Vscode use a `.vscode/tasks.json` file to define project specific tasks. Similar, Tasksystem uses a `.tasks.json` file in your project folders for local tasks and use `'~/.config/nvim/tasks.json'` for `neovim`( or `~/.vim/tasks.json` for `vim`) to define global tasks for generic projects.

## Installtion

For [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'caoshenghui/tasksystem'
Plug 'voldikss/vim-floaterm'
```

in your `.vimrc` or `init.vim`, then restart (neo)vim and run `:PlugInstall`

## Usage

### Start command

```vim
Tasksystem[!] taskname
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
| ${relativeFileDirname} } the current opened file's dirname relative to workspaceFolder |
| ${fileBasename} | the current opened file's basename |
| ${fileBasenameNoExtension} | the current opened file's basename with no file extension |
| ${fileDirname} | the current opened file's dirname |
| ${fileExtname} | the current opened file's extension |
| ${cwd} | the task runner's current working directory on startup |
| ${lineNumber} | the current selected line number in the active file |
| ${selectedText} | the current selected text in the active file |
| ${execPath} | the path to the running VS Code executable |
| ${defaultBuildTask} | the name of the default build task |

### Options

**Tasksystem** can support mostly vscode's options for `tasks.json`, you can learn more through [vscode's tasks](https://code.visualstudio.com/docs/editor/tasks)

Global options:

| Name | type | Description | Default |
| ---- | ---- | ----------- | ------------------- |
| version | string |The configuration's version number | |
| type | string | e.g. floaterm | |
| command | string | The command to be executed | |
| isBackground | boolean | Secifies whether a command is a background task| |
| options | {} | The command options used when the command is executed | |
| args | string[] | The arguments passed to the command | |
| presentation | {} | The presentation options | |
| tasks | [] | The configuration of the available | |

For every task:

| Name | type | Description | Default | Compare to floaterm |
