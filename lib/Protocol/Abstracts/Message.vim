vim9script

import "../../Utils/Json.vim" as j

export abstract class Message implements j.JsonSerializable
  var jsonrpc = "2.0"
  def ToJson(): dict<any>
    return {
       jsonrpc: this.jsonrpc
    }
  enddef
endclass
