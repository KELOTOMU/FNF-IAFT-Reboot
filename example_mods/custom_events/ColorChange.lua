function onEvent(name, value1, value2)
	if name == "ColorChange" then
		ohwowiamsuchanidiot = value2:split(",", ohwowiamsuchanidiot)
		doTweenColor(value1, value1, ohwowiamsuchanidiot[1], tonumber(ohwowiamsuchanidiot[2]), ohwowiamsuchanidiot[3])
	end
end

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end