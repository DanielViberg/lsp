vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class VIM extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "vim-ls",
      filetype: ["vim"],
      path: "vim-language-server",
      args: ["--stdio"],
      initializationOptions: {},
      workspaceConfig: {}
    }
  enddef

  def PreFormatString(): string
    return ""
  enddef

  def PostFormatString(): string
    return ""
  enddef

  def CompletionStates(): list<tuple<string, list<string>>>
    return []
  enddef

  def CompletionAccepts(): list<tuple<string, string, string>>
    return [
      ("vim9script\nappend\n app¤\n", "append", "vim9script\nappend\nappend\n"),
    ]
  enddef

  def CompletionIncrEdit(): list<tuple<string, string, list<list<string>>>>
    return []
  enddef

endclass
