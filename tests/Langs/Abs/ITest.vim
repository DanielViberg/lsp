vim9script

export interface ITest

  def Run(): number

  def Config(): dict<any>

# Formatting
  def PreFormatString(): string

  def PostFormatString(): string

# Completion

# Diagnostics

# GoToDefinition

# Workspace

endinterface
