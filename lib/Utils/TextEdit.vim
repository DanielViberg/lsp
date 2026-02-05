vim9script

import "../Protocol/Objects/TextDocumentContentChangeEvent.vim" as tdce
import "../Protocol/Objects/Position.vim" as p
import "../Utils/Log.vim" as l
import "../Utils/Str.vim" as s

export def ApplyTextEdits(bnr: number, changes: list<tdce.TextDocumentContentChangeEvent>): void
  if changes->empty()
    return 
  endif

  :silent! bnr->bufload()
  setbufvar(bnr, '&buflisted', true)

  var startLine: number = 4294967295	
  var finishLine: number = -1
  var updateEdits: list<dict<any>> = []
  var startRow: number
  var startCol: number
  var endRow: number
  var endCol: number

  var idx = 0

  # create a list of buffer positions where the edits have to be applied.
  for c in changes
    # Adjust the start and end columns for multibyte characters
    startRow = c.start.line - 1
    startCol = c.start.character
    startLine = [c.start.line - 1, startLine]->min()

    endRow = c.end.line - 1
    endCol = c.end.character
    finishLine = [c.end.line - 1, finishLine]->max()

    updateEdits->add({
       A: [startRow, startCol],
       B: [endRow, endCol],
       idx: idx,
       lines: c.text->split("\n", true)
    })
    idx += 1
  endfor

  # Reverse sort the edit operations by descending line and column numbers so
  # that they can be applied without interfering with each other.
  updateEdits->sort('EditSortFunc')

  var lines: list<string> = bnr->getbufline(startLine + 1, finishLine + 1)
  var fixEol: bool = bnr->getbufvar('&fixeol')
  var setEol = fixEol && bnr->getbufinfo()[0].linecount <= finishLine + 1
  if !lines->empty() && setEol && lines[-1]->len() != 0
    lines->add('')
  endif

  for e in updateEdits
    var A: list<number> = [e.A[0] - startLine, e.A[1]]
    var B: list<number> = [e.B[0] - startLine, e.B[1]]
    lines = SetLines(lines, A, B, e.lines)
  endfor

  # If the last line is empty and we need to set EOL, then remove it.
  if !lines->empty() && setEol && lines[-1]->len() == 0
    lines->remove(-1)
  endif

  # if the buffer is empty, appending lines before the first line adds an
  # extra empty line at the end. Delete the empty line after appending the
  # lines.
  var dellastline: bool = false
  if startLine == 0 && bnr->getbufinfo()[0].linecount == 1 &&
					bnr->getbufline(1)->get(0, '')->empty()
    dellastline = true
  endif

  # Now we apply the textedits to the actual buffer.
  # In theory we could just delete all old lines and append the new lines.
  # This would however cause the cursor to change position: It will always be
  # on the last line added.
  #
  # Luckily there is an even simpler solution, that has no cursor sideeffects.
  #
  # Logically this method is split into the following three cases:
  #
  # 1. The number of new lines is equal to the number of old lines:
  #    Just replace the lines inline with setbufline()
  #
  # 2. The number of new lines is greater than the old ones:
  #    First append the missing lines at the **end** of the range, then use
  #    setbufline() again. This does not cause the cursor to change position.
  #
  # 3. The number of new lines is less than before:
  #    First use setbufline() to replace the lines that we can replace.
  #    Then remove superfluous lines.
  #
  # Luckily, the three different cases exist only logically, we can reduce
  # them to a single case practically, because appendbufline() does not append
  # anything if an empty list is passed just like deletebufline() does not
  # delete anything, if the last line of the range is before the first line.
  # We just need to be careful with all indices.
  appendbufline(bnr, finishLine + 1, lines[finishLine - startLine + 1 : -1])
  setbufline(bnr, startLine + 1, lines)
  deletebufline(bnr, startLine + 1 + lines->len(), finishLine + 1)

  if dellastline
    bnr->deletebufline(bnr->getbufinfo()[0].linecount)
  endif
enddef

# sort the list of edit operations in the descending order of line and column
# numbers.
# 'a': {'A': [lnum, col], 'B': [lnum, col]}
# 'b': {'A': [lnum, col], 'B': [lnum, col]}
def EditSortFunc(a: dict<any>, b: dict<any>): number
  # line number
  if a.A[0] != b.A[0]
    return b.A[0] - a.A[0]
  endif
  # column number
  if a.A[1] != b.A[1]
    return b.A[1] - a.A[1]
  endif

  # Assume that the LSP sorted the lines correctly to begin with
  return b.idx - a.idx
enddef

def SetLines(lines: list<string>, 
            A: list<number>, 
            B: list<number>,
					  newLines: list<string>): list<string>

  var i0: number = A[0]
  # If it extends past the end, truncate it to the end. This is because the
  # way the LSP describes the range including the last newline is by
  # specifying a line number after what we would call the last line.
  var numlines: number = lines->len()
  var in = [B[0], numlines - 1]->min()

  if i0 < 0 || i0 >= numlines || in < 0 || in >= numlines
    var msg = $"set_lines: Invalid range, A = {A->string()}"
    msg ..= $", B = {B->string()}, numlines = {numlines}"
    msg ..= $", new lines = {newLines->string()}"
    l.PrintWarning(msg)
    #Warning
    return lines
  endif

  # save the prefix and suffix text before doing the replacements
  var prefix: string = ''
  var suffix: string = lines[in][B[1] :]
  if A[1] > 0
    prefix = lines[i0][0 : A[1] - 1]
  endif

  var newLinesLen: number = newLines->len()

  var n: number = in - i0 + 1
  if n != newLinesLen
    if n > newLinesLen
      # remove the deleted lines
      lines->remove(i0, i0 + n - newLinesLen - 1)
    else
      # add empty lines for newly the added lines (will be replaced with the
      # actual lines below)
      lines->extend(repeat([''], newLinesLen - n), i0)
    endif
  endif

  # replace the previous lines with the new lines
  for i in newLinesLen->range()
    lines[i0 + i] = newLines[i]
  endfor

  # append the suffix (if any) to the last line
  if suffix != ''
    var i = i0 + newLinesLen - 1
    lines[i] = lines[i] .. suffix
  endif

  # prepend the prefix (if any) to the first line
  if prefix != ''
    lines[i0] = prefix .. lines[i0]
  endif

  return lines
enddef
