# Vim 9 Language Server Protocol Client


### ⚠️ Note! Beta status, lots of things are hard coded and many things dont work yet.

### TL;DR
A pure vim9script, lightweight lsp client. 
1. No dependencies except the server binaries.
2. Utilizes as much of the default features vim can provide.
3. Tested and expected to work in vim -u DEFAULTS

### Features
- Completion
- GoToDefinition (Hardcoded to "\<Enter>")
- Diagnostics
- Solution-wide diagnostics in the quickfix list
- Formatting (Hardcoded to BufPreWrite event)

### Requirements
- Vim version 9.2 or higher
- Linux
- Windows

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
WIP

### Commands
- :LspConf           (Edit lsp-config.json)
- :LspRestart        (Restart the lsp server)
- :LspDisable        (Disabel the lsp server)
- :LspEnable         (Enable the lsp server)
- :LspFormat         (Format the current buffer)
- :LspGoToDefinition (Go to symbol definition)
- :LspDiagnostics    (Check solution-wide diagnostics for servers used by open buffers)

`:LspDiagnostics` queries each supported language server once, including issues
in unopened files. Servers without workspace-diagnostic support are skipped.
Results open in Vim's quickfix window with abbreviated solution-relative paths:

```text
"s/S/AccountService.cs" error: Unknown identifier (42:9)
"s/C/Settings.cs" warning: Unused variable (18:5)
```

Use Enter, `:cnext`, or `:cprevious` to jump to an issue. Errors, warnings,
information, and hints are included.

### Similar Plugins

1. [**vim-lsp.vim**](https://github.com/prabirshrestha/vim-lsp) - Vim 8 lsp.

2. [**lsp.vim**](https://github.com/yegappan/lsp) - Vim 9 lsp.

3. [**coc.nvim**](https://github.com/neoclide/coc.nvim) - Vim 9 lsp.
