if !has('vim9script') 
  echoe "Needs Vim version 9 and above"
  finish
endif
if exists("loaded_lsp")
  finish
endif
vim9script
g:loaded_lsp = true

#Settings
g:lsp_format_pre_save = true
g:lsp_autocomplete    = true
g:lsp_diagnostics     = true

import "../lib/ClientState/Buffer.vim" as b
import "../lib/ClientState/Config.vim" as c
import "../lib/Features/Formatting.vim" as f

def InitServers()
  b.Buffer.new()
enddef

#Commands
command! LspConfig call c.OpenLspConfig()
command! LspFormat call f.FormatCmd()

au BufEnter * call InitServers()
