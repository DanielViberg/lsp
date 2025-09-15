# Vim 9 Language Server Protocol Client


### ⚠️ Note! Early alpha status, lots of things are hard coded and many things dont work yet.

### TL;DR
A lightweight lsp client. 
1. No dependencies except the server binaries.
2. Utilizes as much of the default features vim can provide.
3. Tested and expected to work in vim -u DEFAULTS

### WIP
- Configurable commands and features
- Vim documentation
- Testing
- More lsp features

### Features
- Completion
- GoToDefinition (Hardcoded to "\<Enter>")
- Diagnostics
- Formatting (Hardcoded to BufPreWrite event)

### Requirements
- Vim version 9.0 or higher

### Installation
Install using [vim-plug](https://github.com/junegunn/vim-plug). Add the following lines to your `.vimrc` file:

```
vim9script
plug#begin()
Plug 'DanielViberg/lsp'
plug#end()
```

For legacy scripts, use:

```
call plug#begin()
Plug 'DanielViberg/lsp'
call plug#end()
```

### Configuration
Configuration file mirrors the format used in this project: [**lsp.vim**](https://github.com/yegappan/lsp) 
TBD

### Commands
- :LspConf (Edit lsp-config.json)

### Similar Plugins

1. [**vim-lsp.vim**](https://github.com/prabirshrestha/vim-lsp) - Vim 8 lsp.

2. [**lsp.vim**](https://github.com/yegappan/lsp) - Vim 9 lsp.

3. [**coc.nvim**](https://github.com/neoclide/coc.nvim) - Vim 9 lsp.
