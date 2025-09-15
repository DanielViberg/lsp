vim9script 

import "./ITest.vim" as i
import "../../../env.vim" as e
import "../../../lib/Utils/Log.vim" as l
import "../../../lib/ClientState/Session.vim" as ses

export abstract class ATest

  abstract def Config(): dict<list<any>>

  def Run(): number
    writefile([json_encode({ servers: [ this.Config() ]})], e.TESTING_CONF_FILE)
    var file = "/tmp/vim-lsp-test-" .. this.Config().name .. "." .. this.Config().filetype[0]
    writefile([""], file)
    execute "e! " .. file 

    # Wait until server init
    var servers = ses.GetSessionServersByBuf(bufnr())
    if servers->len() == 0
      l.PrintError("No server found")
      return 0
    endif

    var maxWait = 5
    while !servers[0].isFeatInit && maxWait > 0
      l.PrintDebug("Waiting for server to init")
      maxWait -= 1
      if maxWait == 0
        l.PrintError("Failed to init server")
        return 1
      endif
      sleep 1
    endwhile

    # Formatting
    appendbufline(bufnr(), 0, split(this.PreFormatString(), '\n'))
    :doautocmd TextChangedI
    LspFormat
    if this.PostFormatString() != join(getline(1, '$'), "\n")
      l.PrintError("Formatting failed")
      echomsg this.PostFormatString()
      echomsg join(getline(1, '$'), "\n")
      :mes
      return 1
    endif
    :1,$d
    return 0
  enddef

endclass

