vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class PHP extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "php-ls",
      filetype: ["php"],
      path: "intelephense",
      args: ["--stdio"],
      initializationOptions: {},
      workspaceConfig: {
        intelephense: {
          format: {
		        braces: "k&r"
          }
        }
      }
    }
  enddef

  def PreFormatString(): string
    return "<?php\nclass Test {}"
  enddef

  def PostFormatString(): string
    return "<?php\nclass Test {\n}"
  enddef

endclass
