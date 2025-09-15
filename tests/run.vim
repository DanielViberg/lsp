vim9script

import "../env.vim" as e
import "./Langs/PHP.vim" as php
import "./Langs/VUE.vim" as vue

e.TESTING = true
e.DEBUG = true

php.PHP.new().Run()
vue.VUE.new().Run()
