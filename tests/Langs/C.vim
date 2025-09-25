vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class C extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "c-ls",
      filetype: ["c"],
      path: "clangd",
      args: ["--background-index", "--clang-tidy"],
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
      ("#inc¤", "include", "#include\n"),
    ]
  enddef

  def CompletionIncrEdit(): list<tuple<string, string, list<list<string>>>>
    return []
  enddef

endclass
