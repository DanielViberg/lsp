vim9script

export interface ITest

  def Run(): number

  def Config(): dict<any>

# Formatting
  def PreFormatString(): string

  def PostFormatString(): string

# Completion
  def CompletionStates(): list<tuple<string, list<string>>>
  def CompletionAccepts(): list<tuple<string, string, string>>
  def CompletionIncrEdit(): list<tuple<string, string, list<list<string>>>>

# Diagnostics

# GoToDefinition

# Workspace

endinterface
