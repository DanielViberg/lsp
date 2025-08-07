vim9script

import "../Protocol/Objects/TextDocumentContentChangeEvent.vim" as tdce
import "../Protocol/Objects/Position.vim" as p
import "../Utils/Log.vim" as l

export def ApplyTextEdits(bnr: number, changes: list<tdce.TextDocumentContentChangeEvent>)
  # Sort changes bottom up
  var sChanges = SortChanges(changes)

  echomsg 'changes: ' .. sChanges->len()
  
  for change in sChanges
    var bLines = getbufline(bnr, 1, '$')
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

    sleep 1

    var endLine: string
    var newLines: list<string> = split(change.text, "\n", 1)

    echomsg 'newLines:'
    echomsg  newLines

    # Replace lines with new lines
    var bufLen = getbufline(bnr, 1, '$')->len()
    # Change within buffer limits
    var changeStart = min([start.line, bufLen])

    #Clear trailing lines if change ends after buf len
    echomsg 'endl:' .. end.line
    echomsg 'bufLen:' .. bufLen
    echomsg 'newlLINE' .. newLines->len()

    # Trailing lines on full buffer change
    if end.line >= bufLen && 
       newLines->len() < bufLen &&
       newLines->len() > end.line - start.line  
      echomsg 'delete ' .. newLines->len() .. bufLen
        deletebufline(bnr, newLines->len(), bufLen)
    endif
    

    # This change removes lines
    if newLines->len() < end.line - start.line  
      for dl in range(start.line, end.line)->reverse()
        # Ignore partial line delete
        echomsg 'dl: ' .. dl
        echomsg 'startl ' .. start.line 
        echomsg 'endl ' .. end.line 
        if (start.character > 1 && dl == start.line) || 
            end.character >= 1 && dl == end.line
          # Erase after (start) or up until (end)
          var eline = getbufoneline(bnr, dl)
          if dl == start.line
            echomsg 'set start ' .. eline[ : start.character - 1]
            setbufline(bnr, dl, eline[ : start.character - 1])
          endif
          if dl == end.line
            echomsg 'set end ' .. eline[end.character - 1 : ]
            setbufline(bnr, dl, eline[end.character - 1 : ])
          endif
          echomsg 'skip'
          continue
        endif
        echomsg 'erasel: ' .. dl
        deletebufline(bnr, dl)
      endfor
    endif

    var idx: number = 0
    for newLine in newLines
      # First line change by character
      var changeIdx = changeStart + idx
      if idx == 0 && start.character > 1
        var aline = getbufoneline(bnr, changeIdx)
        setbufline(bnr, changeIdx, aline[ : start.character] .. newLine)
        idx += 1
        echomsg 'flc ' .. changeIdx .. ' t:' ..  newLine
        continue
      endif

      # Last line change by character
      if idx == newLines->len() - 1 &&
          end.character > 1
        var aline = getbufoneline(bnr, changeIdx)
        echomsg 'l line: ' aline[end.character - 2 : ]
        echomsg 'e r:' .. end.character 
        echomsg 'llc ' .. changeIdx .. ' t:' ..  newLine .. aline[end.character - 2 : ]
        setbufline(bnr, changeIdx, newLine .. aline[end.character - 2 : ])
        idx += 1
        continue
      endif

      # Full line change
      if !empty(newLine)
        echomsg 'set full line:' newLine
        setbufline(bnr, changeStart + idx, newLine)
      endif
      idx += 1
    endfor
  endfor
enddef

# SortChanges orders edits by (start, end) offset.
# Puts insertions (end == start) before deletions (end > start) at the same point.
# Uses stable sort to preserve order of multiple insertions at the same point.
def SortChanges(edits: list<tdce.TextDocumentContentChangeEvent>): list<tdce.TextDocumentContentChangeEvent>
    edits->sort((i1, i2) => Less(i1, i2) ? 1 : -1)
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
