vim9script

import "../env.vim" as e
import "./Langs/PHP.vim" as php
import "./Langs/VUE.vim" as vue
import "./Langs/VIM.vim" as vim

e.TESTING = true
e.DEBUG = true

var result = 1
result = vim.VIM.new().Run()
result = php.PHP.new().Run()
result = vue.VUE.new().Run()

if !result
  echomsg "ALL TEST OK, EXITING ..."
  e.DEBUG = false
  sleep 2
  :exit
endif
