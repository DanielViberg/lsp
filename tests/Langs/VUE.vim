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
              tsdk: "/home/daniel/sources/tools/node-v20.18.0-linux-x64/lib/node_modules/typescript/lib"
          },
          vue: {
            hybridMode: false
          }
       },
      workspaceConfig: {}
    }
  enddef

  def PreFormatString(): string
  enddef

  def PostFormatString(): string
  enddef

endclass
