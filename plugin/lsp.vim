if !has('vim9script') 
  echoe "Needs Vim version 9 and above"
  finish
endif
if exists("loaded_lsp")
  finish
endif
vim9script
g:loaded_lsp = true

import "../lib/ClientState/Buffer.vim" as b
import "../lib/ClientState/Config.vim" as c

def InitServers()
  b.Buffer.new()
enddef

command! LspConfig call c.OpenLspConfig()

au BufEnter * call InitServers()
