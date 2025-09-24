vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class BLADE extends a.ATest implements i.ITest

  def new()
    this.noServer = true
  enddef

  def Config(): dict<any>
    return {
      name: "blade-ls",
      filetype: ["blade.php"],
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
      ("completionWord\ncompl¤", "completionWord", "completionWord\ncompletionWord\n"),
    ]
  enddef

  def CompletionIncrEdit(): list<tuple<string, string, list<list<string>>>>
    return []
  enddef

endclass
