require "class"
require "perlin"
require "meteor"
require "config"

pi = math.pi
twicePi = math.pi * 2
piHalf = math.pi / 2
piEighth = math.pi / 8
piTwelfth = math.pi / 12
piSixteenth = math.pi / 16
twoSqrtTwo = 2 * math.sqrt(2)
naturalE = math.exp(1)
radiansPerAngle = math.pi / 180

mSqrt = math.sqrt
mRandom = love.math.random --math.random
mMin = math.min
mMax = math.max
mAtan2 = math.atan2
mExp = math.exp
mCeil = math.ceil
mFloor = math.floor
mAbs = math.abs
mMix = math.mix

tInsert = table.insert
tRemove = table.remove
tSort = table.sort

spEcho = print

function mClamp(val, lower, upper)
    assert(val and lower and upper, "not very useful error message here")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return mMax(lower, mMin(upper, val))
end

function mSmoothstep(edge0, edge1, value)
	if value <= edge0 then return 0 end
	if value >= edge1 then return 1 end
	local x = (value - edge0) / (edge1 - edge0)
	local t = mClamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

function mMix(x, y, a)
	return x * (1-a) + y * a
end

function tRemoveRandom(fromTable)
	return tRemove(fromTable, mRandom(1, #fromTable))
end

function tGetRandom(fromTable)
	return fromTable[mRandom(1, #fromTable)]
end

-- simple duplicate, does not handle nesting
function tDuplicate(sourceTable)
	local duplicate = {}
	for k, v in pairs(sourceTable) do
		duplicate[k] = v
	end
	return duplicate
end

function splitIntoWords(s)
  local words = {}
  for w in s:gmatch("%S+") do tInsert(words, w) end
  return words
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

function stringCapitalize(string)
	local first = string:sub(1,1)
	first = string.upper(first)
	return first .. string:sub(2)
end

function DiceRoll(dice)
  local n = 0
  for d = 1, dice do
    n = n + (mRandom() / dice)
  end
  return n
end

function NewSeed()
  return mCeil(mRandom()*1000)
end

function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do tInsert(a, n) end
  tSort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function MinMaxRandom(minimum, maximum)
  return (mRandom() * (maximum - minimum)) + minimum
end

function RandomVariance(variance)
  return (1-variance) + (mRandom() * variance * 2)
end

function VaryWithinBounds(value, variance, minimum, maximum)
  if not value then return nil end
  return mMax(mMin(value*RandomVariance(variance), maximum), minimum)
end

function uint32little(n)
  return string.char( n%256, (n%65536)/256, (n%16777216)/65536, n/16777216 )
end

function uint16little(n)
  return string.char( n%256, (n%65536)/256 )
end

function uint16big(n)
  return string.char( (n%65536)/256, n%256 )
end

function uint8(n)
  return string.char( n%256 )
end

---

function FReadOpen(name, ext, endFunc)
  readEndFunc = endFunc
  readBuffer = ""
  currentReadFilename = name .. "." .. ext
  currentReadFilename = outDir .. currentReadFilename
  print("reading from " .. currentReadFilename)
  currentReadFile = assert(io.open(currentReadFilename,"r"), "Unable to read from "..currentReadFilename)
  while true do
    local line = currentReadFile:read()
    if line then
      readBuffer = readBuffer .. line .. "\n"
    else
      break
    end
  end
  currentReadFile:close()
  currentReadFile = nil
  currentReadFilename = nil
  readEndFunc(readBuffer)
  readBuffer = ""
end

function FReadLine()
  readBuffer = readBuffer .. currentReadFile:read() .. "\n"
end

function FReadClose()
  currentReadFile:close()
  currentReadFile = nil
  currentReadFilename = nil
  readEndFunc(readBuffer)
  readBuffer = ""
end

function FWriteOpen(name, ext, mode)
  name = name or ""
  ext = ext or "txt"
  mode = mode or "wb"
  currentFilename = name .. "." .. ext
  currentFilename = outDir .. currentFilename
  currentFile = assert(io.open(currentFilename,mode), "Unable to save to "..currentFilename)
  -- currentFile, errorstr = love.filesystem.newFile( currentFilename, "w" )
  -- i would use love.filesystem, except it's many times slower writing
end

function FWrite(...)
  local send = ""
  for i, str in ipairs({...}) do
    send = send .. str
  end
  currentFile:write(send)
end

function FWriteClose()
  currentFile:close()
  print(currentFilename .. " written")
end

MirrorTypes = { "reflectionalx", "reflectionalz", "rotational", "none" }
MirrorNames = {}
for i, name in pairs(MirrorTypes) do
  MirrorNames[name] = i
end

function InterpretCommand(msg, myWorld)
  if not msg then return end
  if msg == "" then return end
  msg = "loony " .. msg
  local words = splitIntoWords(msg)
  local where = words[1]
  if where == "loony" then
    local commandWord = words[2]
    local uiCommand = string.sub(msg, 7)
    if commandWord == "meteor" then
      local radius = words[5] / 15
      myWorld:AddMeteor(words[3], words[4], radius*2)
    elseif commandWord == "shower" then
      myWorld:MeteorShower(words[3], words[4], words[5], words[6], words[7], words[8], words[9], words[10], words[11], yesMare)
    elseif commandWord == "clear" then
      myWorld:Clear()
    elseif commandWord == "blur" then
      local radius = words[3] or 1
      myWorld.heightBuf:Blur(radius, uiCommand)
    elseif commandWord == "read" then
      myWorld.heightBuf:Read()
    elseif commandWord == "height" then
      myWorld.heightBuf:SendFile(uiCommand)
    elseif commandWord == "attributes" then
      myWorld:RenderAttributes(uiCommand)
    elseif commandWord == "attributesl3dt" then
      myWorld:RenderAttributes(uiCommand, L3DTMapRuler)
    elseif commandWord == "heightl3dt" then
      myWorld:RenderHeightImage(uiCommand, L3DTMapRuler)
    elseif commandWord == "heightfull" then
      myWorld:RenderHeightImage(uiCommand, fullMapRuler)
    elseif commandWord == "attributesfull" then
      myWorld:RenderAttributes(uiCommand, fullMapRuler)
    elseif commandWord == "metal" then
      myWorld:RenderMetal(uiCommand)
    elseif commandWord == "features" then
      myWorld:RenderFeatures(uiCommand)
    elseif commandWord == "bypasstoggle" then
      bypassSpring = not bypassSpring
      spEcho("bypassSpring is now", tostring(bypassSpring))
      SendToUnsynced("BypassSpring", tostring(bypassSpring))
    elseif commandWord == "maretoggle" then
      yesMare = not yesMare
      spEcho("yesMare is now", tostring(yesMare))
    elseif commandWord == "mirror" then
      myWorld.mirror = words[3]
      spEcho("mirror: " .. myWorld.mirror)
    elseif commandWord == "mirrornext" then
      local mt = MirrorNames[myWorld.mirror]+1
      if mt == #MirrorTypes+1 then mt = 1 end
      myWorld.mirror = MirrorTypes[mt]
      spEcho("mirror: " .. myWorld.mirror)
    elseif commandWord == "save" then
      myWorld:Save(words[3])
    elseif commandWord == "load" then
      FReadOpen("world" .. (words[3] or ""), "lua", function(str) myWorld:Load(str) end)
    elseif commandWord == "resetages" then
      myWorld:ResetMeteorAges()
    elseif commandWord == "renderall" then
      myWorld:RenderFeatures()
      myWorld:RenderMetal()
      myWorld:RenderAttributes()
      myWorld.heightBuf:SendFile(uiCommand)
    elseif commandWord == "renderalll3dt" then
      myWorld:RenderFeatures()
      myWorld:RenderMetal()
      myWorld:RenderAttributes(nil, L3DTMapRuler)
      myWorld:RenderHeightImage(uiCommand, L3DTMapRuler)
    elseif commandWord == "renderallfull" then
      myWorld:RenderFeatures()
      myWorld:RenderMetal()
      myWorld:RenderAttributes(nil, fullMapRuler)
      myWorld:RenderHeightImage(uiCommand, fullMapRuler)
    end
  end
end

function RectXYWH(rect)
  if not rect then return end
  love.graphics.rectangle("fill", rect.x1, rect.y1, rect.w, rect.h)
end

function ColorRGB(rgb)
  if not rgb then return end
  love.graphics.setColor(rgb.r, rgb.g, rgb.b)
end

function DistanceSq(x1, y1, x2, y2)
  local dx = mAbs(x2 - x1)
  local dy = mAbs(y2 - y1)
  return (dx*dx) + (dy*dy)
end

-- globals used here and to export:

heightMapRuler = MapRuler(nil, (Game.mapSizeX / Game.squareSize) + 1, (Game.mapSizeZ / Game.squareSize) + 1)
metalMapRuler = MapRuler(16, (Game.mapSizeX / 16), (Game.mapSizeZ / 16))
L3DTMapRuler = MapRuler(4, (Game.mapSizeX / 4), (Game.mapSizeZ / 4))
fullMapRuler = MapRuler(1)
displayMapRuler = MapRuler(10, (Game.mapSizeX / 10), (Game.mapSizeZ / 10))