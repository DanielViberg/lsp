if !has('vim9script') 
  echoe "Needs Vim version 9 and above"
  finish
endif
if exists("loaded_lsp")
  finish
endif
vim9script

import "../lib/ClientState/Buffer.vim" as buf
import "../lib/ClientState/Session.vim" as ses
import "../lib/ClientState/Config.vim" as c
import "../lib/Features/Formatting.vim" as f
import "../lib/Features/Hover.vim" as h
import "../lib/Features/GoToDefinition.vim" as g

g:loaded_lsp = true

#Settings
g:lsp_format_pre_save      = true
g:lsp_autocomplete         = true
g:lsp_comp_buf_cache_limit = 1000
g:lsp_diagnostics          = true

def InitServers()
  buf.Buffer.new()
enddef

#Commands
command! LspConfig call c.OpenLspConfig()
command! LspFormat call f.FormatCmd()
command! LspRestart call Restart()
command! LspDisable call Disable()
command! LspEnable call Enable()
command! LspHover call h.HoverCmd()
command! LspGoToD call g.GoToCmd()

def Disable(): void
	buf.disable = true
	for server in ses.SessionServers
		server.Stop()
	endfor
enddef

def Enable(): void
	buf.disable = true
	for server in ses.SessionServers
		server.Init(bufnr())
	endfor
enddef

def Restart(): void
enddef

au BufEnter * call InitServers()
