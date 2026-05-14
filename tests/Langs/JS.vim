vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

# TODO

export class JS extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "js-ls",
      filetype: ["js"],
      path: "typescript-language-server",
      args: ["--stdio"],
      initializationOptions: {},
      workspaceConfig: {}
    }
  enddef

endclass
