vim9script
# vim -Nu NONE -i NONE -n -es -S tests/completion_cursor.vim
source <sfile>:h/../plugin/lsp.vim
import '../lib/Protocol/Objects/TextDocumentContentChangeEvent.vim' as tdce
import '../lib/Protocol/Objects/Position.vim' as p
import '../lib/Utils/TextEdit.vim' as t

var server = {serverCapabilites: {positionEncoding: 'utf-16'}}
var edits: list<tdce.TextDocumentContentChangeEvent> = []

def Edit(a: list<number>, b: list<number>, text: string, primary = false)
  var change = tdce.TextDocumentContentChangeEvent.new(text, {
    start: {line: a[0], character: a[1]}, end: {line: b[0], character: b[1]},
  }, server, primary)
  change.VimDecode(bufnr())
  edits->add(change)
enddef

def Accept()
  cursor(t.ApplyTextEdits(bufnr(), edits))
  edits = []
enddef

# Type a sentinel at the returned insertion point while still in Insert mode.
inoremap <F2> <Cmd>call <SID>Accept()<CR>
setline(1, ['old', 'remove', '😀fo + tail', 'below'])
Edit([2, 2], [2, 4], "foo\n  bar", true)
Edit([3, 0], [3, 5], 'after')
Edit([0, 0], [0, 0], "import\n\n")
Edit([1, 0], [2, 0], '')
feedkeys("i\<F2>!\<Esc>", 'xt')
assert_equal(['import', '', 'old', '😀foo', '  bar! + tail', 'after'], getline(1, '$'))

for [encoding, offset] in [['utf-8', 4], ['utf-16', 2], ['utf-32', 1]]
  server.serverCapabilites.positionEncoding = encoding
  setline(1, '😀fo')
  assert_equal(offset, p.Position.new(server, 1, 5).ToJson().character)
  Edit([0, offset], [0, offset + 2], 'foo', true)
  Edit([0, 0], [0, 0], '>')
  feedkeys("i\<F2>!\<Esc>", 'xt')
  assert_equal('>😀foo!', getline(1), encoding)
endfor

if !empty(v:errors)
  echomsg join(v:errors, "\n")
  cquit
endif
qa!
