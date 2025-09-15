vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class VUE extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "vue-ls",
      filetype: ["vue"],
      path: "vue-language-server",
      args: ["--stdio"],
      initializationOptions: {
          typescript: {
              tsdk: "/usr/local/lib/node_modules/typescript/lib"
          },
          vue: {
            hybridMode: false
          }
       },
      workspaceConfig: {}
    }
  enddef

  def PreFormatString(): string
    return "<style>\n.text {}\n\n</style>"
  enddef

  def PostFormatString(): string
    return "<style>\n.text {}\n</style>"
  enddef

endclass
