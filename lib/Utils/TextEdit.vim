vim9script

import "../Protocol/Objects/TextDocumentContentChangeEvent.vim" as tdce
import "../Protocol/Objects/Position.vim" as p
import "../Utils/Log.vim" as l

export def ApplyTextEdits(bnr: number, changes: list<tdce.TextDocumentContentChangeEvent>)
  var bLines = getbufline(bnr, 1, '$')
  # Sort
  var sChanges = SortChanges(changes)
  
  for change in sChanges
    # Skip empty edits 
    if change.start.Equals(change.end) || change.text == ""
      return
    endif

    var start = change.start->copy()
    var end = change.end->copy()

    start.VimDecode()
    end.VimDecode()

    echomsg 'bline: ' .. bLines->len()
    echomsg start.line
    echomsg start.character
    echomsg end.line
    echomsg end.character
    echomsg 'text: '  .. change.text

    # Special case deleting of complete lines
    if empty(change.text) &&
        start.character == 1 &&
        end.character == 1
      var delStart = min([start.line, bLines->len()])
      var delEnd = min([end.line - 1, bLines->len()])
      echomsg 'delete line: ' .. delStart .. ' to ' .. delEnd
      deletebufline(bnr, delStart, delEnd)
      bLines = bLines[ : delStart - 1] + bLines[delEnd : ]
      continue
    endif

    var newLines: list<string> = split(change.text, "\n")
    echomsg newLines

    var startLine: string
    var endLine: string
    var appendAdjust: number = 1

    if start.line - 1 < bLines->len() && 
        newLines->len() > 0
      appendAdjust = 0
      startLine = bLines[start.line - 1]
      newLines[0] = [startLine[ : start.character - 1], newLines[0]]->join("\n")
      if end.line - 1 < bLines->len()
        endLine = bLines[end.line - 1]
        newLines[newLines->len() - 1] ..= endLine[end.character - 1 : ]
      endif
			# We only need to update the start line because we can't have overlapping edits
      bLines[start.line - 1] = newLines[0]
      echomsg 'set at: ' .. start.line .. ' with ' .. bLines[start.line - 1]
      setbufline(bnr, start.line, bLines[start.line - 1]->split("\n"))
      bLines = getbufline(bnr, 1, '$')
      echomsg 'post set: ' ..  bLines->len()
    endif

    if start.line != end.line 
			# We can't delete beyond the end of the buffer. So the start end end here are
			# both min() reduced
      var delStart = min([start.line + 1, bLines->len()])
      var delEnd = min([end.line, bLines->len()])
      echomsg 'delete at: ' .. delStart .. ' to ' .. delEnd
      deletebufline(bnr, delStart, delEnd)
      bLines = getbufline(bnr, 1, '$')
    endif

    if newLines->len() > 1 
      var nr: number = start.line - appendAdjust
      echomsg 'append buf line at: ' .. nr .. 
        ' with ' .. 
        newLines[1 - appendAdjust : newLines->len() - appendAdjust]->join("\n")
      appendbufline(bnr, 
        start.line - appendAdjust, 
        newLines[1 - appendAdjust : newLines->len() - appendAdjust])
      bLines = getbufline(bnr, 1, '$')
    endif
  endfor
enddef

# SortChanges orders edits by (start, end) offset.
# Puts insertions (end == start) before deletions (end > start) at the same point.
# Uses stable sort to preserve order of multiple insertions at the same point.
def SortChanges(edits: list<tdce.TextDocumentContentChangeEvent>): list<tdce.TextDocumentContentChangeEvent>
    edits->sort((i1, i2) => Less(i1, i2) ? -1 : 1)
    return edits
enddef

def Less(i: tdce.TextDocumentContentChangeEvent, 
         j: tdce.TextDocumentContentChangeEvent): bool
    def PositionCmp(x: any, y: any): number
        var cmp: number = x.line - y.line
        if cmp != 0
            return cmp
        endif
        return x.character - y.character
    enddef
    var cmp: number = PositionCmp(i.start, j.start)
    if cmp != 0
        return cmp < 0
    endif
    return PositionCmp(i.end, j.end) < 0
enddef
