require "class"
require "config"

Loony = require "LoonyModule/loony"

pi = math.pi
twicePi = math.pi * 2
piHalf = math.pi / 2
piEighth = math.pi / 8
piTwelfth = math.pi / 12
piSixteenth = math.pi / 16
twoSqrtTwo = 2 * math.sqrt(2)
naturalE = math.exp(1)
radiansPerDegree = math.pi / 180

mSqrt = math.sqrt
mRandom = love.math.random --math.random
mRandomSeed = love.math.setRandomSeed
mMin = math.min
mMax = math.max
mAtan2 = math.atan2
mSin = math.sin
mCos = math.cos
mAsin = math.asin
mAcos = math.acos
mExp = math.exp
mCeil = math.ceil
mFloor = math.floor
mAbs = math.abs

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
  return mCeil(mRandom()*9999)
end

function NextSeed(seed)
  return mMax(1, (mCeil(seed) + 1) % 10000)
end

function PreviousSeed(seed)
  return mMax(1, mMin(9999, (mCeil(seed) - 1) % 10000))
end

function CreateSeedPacket(seedSeed, number)
  mRandomSeed(seedSeed)
  local packet = {}
  for i = 1, number do
    tInsert(packet, NewSeed())
  end
  return packet
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

function AngleAdd(angle1, angle2)
  return (angle1 + angle2) % twicePi
end

function AngleXYXY(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return mAtan2(dy, dx)
end

function CirclePos(cx, cy, dist, angle)
  angle = angle or mRandom() * twicePi
  local x = cx + dist * mCos(angle)
  local y = cy + dist * mSin(angle)
  return x, y
end

function AngleDist(angle1, angle2)
  return mAbs((angle1 + pi -  angle2) % twicePi - pi)
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

CommandWords = {
  meteor = function(words, myWorld, uiCommand)
    local radius = (words[5] or 10)
    myWorld:AddMeteor(words[3], words[4], radius*2)
  end,
  shower = function(words, myWorld, uiCommand)
    myWorld:MeteorShower(words[3], words[4], words[5], words[6], words[7], words[8], words[9], words[10], words[11], yesMare)
  end,
  clear = function(words, myWorld, uiCommand)
    myWorld:Clear()
  end,
  height = function(words, myWorld, uiCommand)
    myWorld:RenderHeightImage(uiCommand, mapRulerNames[words[3]] or heightMapRuler)
  end,
  attributes = function(words, myWorld, uiCommand)
    myWorld:RenderAttributes(uiCommand, mapRulerNames[words[3]] or heightMapRuler)
  end,
  heightpreview = function(words, myWorld, uiCommand)
    myWorld:RenderHeightImage(uiCommand, displayMapRuler)
  end,
  attributespreview = function(words, myWorld, uiCommand)
    myWorld:RenderAttributes(uiCommand, displayMapRuler)
  end,
  metal = function(words, myWorld, uiCommand)
    myWorld:RenderMetal(uiCommand)
  end,
  features = function(words, myWorld, uiCommand)
    myWorld:RenderFeatures(uiCommand)
  end,
  maretoggle = function(words, myWorld, uiCommand)
    yesMare = not yesMare
    spEcho("yesMare is now", tostring(yesMare))
  end,
  mirror = function(words, myWorld, uiCommand)
    myWorld.mirror = words[3]
    spEcho("mirror: " .. myWorld.mirror)
  end,
  mirrornext = function(words, myWorld, uiCommand)
    local mt = MirrorNames[myWorld.mirror]+1
    if mt == #MirrorTypes+1 then mt = 1 end
    myWorld.mirror = MirrorTypes[mt]
    spEcho("mirror: " .. myWorld.mirror)
  end,
  save = function(words, myWorld, uiCommand)
    myWorld:Save(words[3])
  end,
  load = function(words, myWorld, uiCommand)
    FReadOpen("world" .. (words[3] or ""), "lua", function(str) myWorld:Load(str) end)
  end,
  resetages = function(words, myWorld, uiCommand)
    myWorld:ResetMeteorAges()
  end,
  renderall = function(words, myWorld, uiCommand)
    local mapRuler = mapRulerNames[words[3]] or heightMapRuler
    myWorld:RenderFeatures()
    myWorld:RenderMetal()
    myWorld:RenderAttributes(nil, mapRuler)
    myWorld:RenderHeightImage(uiCommand, mapRuler)
  end,
  exit = function(words, myWorld, uiCommand)
    love.event.quit()
  end,
  quit = function(words, myWorld, uiCommand)
    love.event.quit()
  end,
}

function InterpretCommand(msg, myWorld)
  if not msg then return end
  if msg == "" then return end
  msg = "loony " .. msg
  local words = splitIntoWords(msg)
  local where = words[1]
  if where == "loony" then
    local commandWord = words[2]
    local uiCommand = string.sub(msg, 7)
    if CommandWords[commandWord] then
      CommandWords[commandWord](words, myWorld, uiCommand)
      return true
    end
  end
  return false
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

function PrintCommandLine(lineStr, pos, r, g, b)
  r = r or 255
  g = g or 255
  b = b or 255
  pos = pos or 0
  local prefix = "  "
  local suffix = ""
  if pos == 0 then
    prefix = "> "
    suffix = "_"
  end
  local outStr = prefix .. lineStr .. suffix
  local y = displayMapRuler.height - (commandLineFont:getHeight()*(pos+1)) - 8
  love.graphics.setFont(commandLineFont)
  love.graphics.setColor(r, g, b)
  love.graphics.print(outStr, 8, y)
end

function RendererPrepareDraw(renderer)
  local renderRatio = renderer.progress / renderer.totalProgress
  renderer.renderFgRGB = { r = (1-renderRatio)*255, g = renderRatio*255, b = 0 }
  renderer.renderProgressString = tostring(mFloor(renderRatio * 100)) .. "%" --renderProgress .. "/" .. renderTotal
  local viewX, viewY = displayMapRuler.width, displayMapRuler.height
  local rrr = renderRatioRect
  local x1, y1 = rrr.x1*viewX, rrr.y1*viewY
  local x2, y2 = rrr.x2*viewX, rrr.y2*viewY
  local dx = x2 - x1
  local dy = y2 - y1
  renderer.renderBgRect = { x1 = x1-4, y1 = y1-4, x2 = x2+4, y2 = y2+4, w = dx+8, h = dy+8 }
  renderer.renderFgRect = { x1 = x1, y1 = y1, x2 = x2, y2 = y1+(dx*renderRatio), w = dx*renderRatio, h = dy }
end

function PreviewHeights(heightBuf)
  local canvas = love.graphics.newCanvas()
  local heightDif = heightBuf.maxHeight - heightBuf.minHeight
  canvas:renderTo(function()
    for x = 1, heightBuf.w do
      for y = 1, heightBuf.h do
        local value = mFloor(((heightBuf.heights[x][y] - heightBuf.minHeight) / heightDif) * 255)
        love.graphics.setColor(value, value, value)
        love.graphics.point(x-1,y-1)
      end
    end
  end)
  return canvas
end

function ResetDisplay(myWorld)
  local dWidth, dHeight = love.window.getDesktopDimensions()
  for p = 0, 4 do
    local elmosPerPixel = 2 ^ p
    local testWidth, testHeight = myWorld.mapSizeX / elmosPerPixel, myWorld.mapSizeZ / elmosPerPixel
    if testWidth <= dWidth and testHeight <= dHeight then
      displayMapRuler = MapRuler(myWorld, elmosPerPixel, myWorld.mapSizeX / elmosPerPixel, myWorld.mapSizeZ / elmosPerPixel)
      break
    end
  end
    love.window.setMode(displayMapRuler.width, displayMapRuler.height, {resizable=false, vsync=false})
    if displayMapRuler.width == dWidth or displayMapRuler.height == dHeight then
      love.window.setMode(displayMapRuler.width, displayMapRuler.height, {resizable=false, vsync=false, borderless=true})
    end
    love.window.setTitle("map: " .. myWorld.mapSize512X .. "x" .. myWorld.mapSize512Z .. " elmos: " .. myWorld.mapSizeX .. "x" .. myWorld.mapSizeZ .. " display:" .. displayMapRuler.width .. "x" .. displayMapRuler.height .. " (1:" .. displayMapRuler.elmosPerPixel.. ")")
    print("displaymapruler dimensions: " .. displayMapRuler.width .. "x" .. displayMapRuler.height)
    local ww, wh = love.window.getDimensions()
    print("window dimensions: " .. ww .. "x" .. wh)
    printLineHeight = printLineFont:getHeight()
    printLineWidth = mFloor(displayMapRuler.width / 2)
    maximumPrintLines = mFloor((displayMapRuler.height - 16) / printLineHeight) - 1
end

-- globals used here and to export:

