vim9script

import "../env.vim" as e
import "./Langs/Abs/ITest.vim" as i
import "./Langs/PHP.vim" as php
import "./Langs/VUE.vim" as vue
import "./Langs/VIM.vim" as vim
import "./Langs/TXT.vim" as txt

e.TESTING = true
e.DEBUG = true

var result = 1

def RunCheck(test: i.ITest): void
  if test.Run()
    :stop
    :mes
  endif
enddef

RunCheck(txt.TXT.new())
RunCheck(php.PHP.new())
RunCheck(vue.VUE.new())
RunCheck(vim.VIM.new())

echomsg "ALL TEST OK, EXITING ..."
e.DEBUG = false
sleep 2
:exit
