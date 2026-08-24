vim9script

import "../env.vim" as e
import "./Langs/Abs/ITest.vim" as i
import "./Langs/PHP.vim" as php
import "./Langs/VUE.vim" as vue
import "./Langs/VIM.vim" as vim
import "./Langs/TXT.vim" as txt
import "./Langs/BLADE.vim" as blade
import "./Langs/JS.vim" as js
import "./Langs/TS.vim" as ts
import "./Langs/C.vim" as c
import "./Langs/CS.vim" as cs
import "./Langs/BASH.vim" as bs

e.TESTING = true
e.DEBUG = true
e.DEBUG_RPC = true

def RunCheck(test: i.ITest): void
  if test.Run()
    throw "Test failed: " .. test.Config().name
  endif
enddef

var tests: list<i.ITest> = [
  blade.BLADE.new(),
  txt.TXT.new(),
  php.PHP.new(),
  vue.VUE.new(),
  vim.VIM.new(),
  bs.BASH.new(),
  #cs.CS.new(),
# ts.TS.new(),
# c.C.new(),
]

var failed = false
try
  for test in tests
    RunCheck(test)
  endfor
catch
  failed = true
  echohl ErrorMsg
  echomsg "TEST FAILED: " .. v:exception
  echohl None
  messages
endtry

if !failed
  echomsg "ALL TEST OK, EXITING ..."
  e.DEBUG = false
  sleep 2
  :exit
endif
# On failure vim is left open on the failing buffer for inspection.
# Quit with :cq to exit with an error status.
