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
      workspaceConfig: {
        html: {
          format: {
	          enable: true,
	          wrapAttributes: "force-aligned"
          }
        }
      }
    }
  enddef

  def PreFormatString(): string
    return "<style>\n.text {}\n\n</style>\n<template>\n<div :style=\"\" :class=\"\">\n</div>\n</template>"
  enddef

  def PostFormatString(): string
    return "<style>\n.text {}\n</style>\n<template>\n\t<div :style=\"\"\n\t     :class=\"\">\n\t</div>\n</template>"
  enddef

  def CompletionStates(): list<tuple<string, list<string>>>
    return []
  enddef

  def CompletionAccepts(): list<tuple<string, string, string>>
    return [
    ]
  enddef

endclass
