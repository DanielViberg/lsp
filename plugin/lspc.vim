vim9script

import "../lib/ClientState/Buffer.vim" as b

def InitServers()
  b.Buffer.new()
enddef

au BufEnter * call InitServers()
