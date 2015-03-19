require "common"
-- local noise = require "fbm_noise"

local myWorld
local keyPress = {}
local keyPresses = 0
local mousePress = {}
local mousePresses = 0
local mouseAngle = 0
local mouseAngleX2, mouseAngleY2 = 0, 0
local commandBuffer
local commandHistory = {}
local commandHistoryPos = 1
local selectedMeteor
local testNoise = false
local testNoiseMap

printLines = {}
realPrint = print
function print(...)
	local line = ""
	for i, str in ipairs({...}) do
		if i > 1 then line = line .. "\t" end
		line = line .. tostring(str)
	end
	tInsert(printLines, line)
	if logFile then logFile:write(line .. "\n") end
	realPrint(...)
end

function love.conf(t)
	t.identity = 'thatsamore'
end

function love.load()
	io.stdout:setvbuf("no")
	logFile = assert(io.open(outDir.."stdout.log","w"), "Unable to save to "..outDir.."stdout.log")
	commandLineFont = love.graphics.newFont("fonts/SourceCodePro-Medium.ttf", 16)
	printLineFont = love.graphics.newFont("fonts/SourceCodePro-Medium.ttf", 12)
	love.keyboard.setKeyRepeat(true)
	myWorld = World(4, 1000)
	local dWidth, dHeight = love.window.getDesktopDimensions()
	for p = 0, 4 do
		local pixelsPerElmo = 2 ^ p
		local testWidth, testHeight = Game.mapSizeX / pixelsPerElmo, Game.mapSizeZ / pixelsPerElmo
		if testWidth <= dWidth and testHeight <= dHeight then
			displayMapRuler = MapRuler(pixelsPerElmo, Game.mapSizeX / pixelsPerElmo, Game.mapSizeZ / pixelsPerElmo)
			break
		end
	end
    love.window.setMode(displayMapRuler.width, displayMapRuler.height, {resizable=false, vsync=false})
    if displayMapRuler.width == dWidth or displayMapRuler.height == dHeight then
    	love.window.setMode(displayMapRuler.width, displayMapRuler.height, {resizable=false, vsync=false, borderless=true})
    end
    love.window.setTitle(displayMapRuler.width .. "x" .. displayMapRuler.height)
    print("displaymapruler dimensions: " .. displayMapRuler.width .. "x" .. displayMapRuler.height)
    local ww, wh = love.window.getDimensions()
    print("window dimensions: " .. ww .. "x" .. wh)
    printLineHeight = printLineFont:getHeight()
    printLineWidth = mFloor(displayMapRuler.width / 2)
    maximumPrintLines = mFloor((displayMapRuler.height - 16) / printLineHeight) - 1
end

function love.quit()
	logFile:close()
end

function love.textinput(t)
	if commandBuffer then
		commandBuffer = commandBuffer .. t
	else
		if commandKeys[t] then InterpretCommand(commandKeys[t], myWorld) end
	end
end

function love.keypressed(key, isRepeat)
	if isRepeat then
		if key == "backspace" then
			if commandBuffer then
				commandBuffer = commandBuffer:sub(1,-2)
			end
		end
	end
	if isRepeat then return end
	keyPress[key] = { x = love.mouse.getX(), y = love.mouse.getY() }
	keyPresses = keyPresses + 1
	if key == "return" then
		if commandBuffer then
			if commandBuffer ~= "" then
				local validCommand = InterpretCommand(commandBuffer, myWorld)
				if validCommand then tInsert(commandHistory, commandBuffer) end
			end
			commandBuffer = nil
			previewCanvas = nil
		else
			commandBuffer = ""
		end
		commandHistoryPos = #commandHistory+1
	end
	if commandBuffer then
		if key == "backspace" then
			if commandBuffer then
				commandBuffer = commandBuffer:sub(1,-2)
			end
		elseif key == "up" then
			commandHistoryPos = mMax(commandHistoryPos - 1, 1)
			commandBuffer = commandHistory[commandHistoryPos]
		elseif key == "down" then
			commandHistoryPos = mMin(commandHistoryPos + 1, #commandHistory+1)
			commandBuffer = commandHistory[commandHistoryPos] or ""
		end
	else
		-- non-command buffer global keys
		if key == "." then
			local x, y = love.mouse.getPosition()
			local sx, sz = displayMapRuler:XYtoXZ(x, y)
			myWorld:AddMeteor(sx, sz)
		elseif key == "x" then
			testNoise = not testNoise
			if testNoise then
				testNoiseMap = TwoDimensionalNoise(NewSeed(), displayMapRuler.width, 255, 0.25, 5, 1)
			end
		elseif key == "escape" then
			love.event.quit()
		end
		if selectedMeteor then
			-- keys for a selected meteor
			if key == "m" then
				selectedMeteor:IncreaseMetal()
			elseif key == "n" then
				selectedMeteor:DecreaseMetal()
			elseif key == "g" then
				selectedMeteor:GeothermalToggle()
			elseif key == "d" then
				selectedMeteor:Delete()
			elseif key == "pageup" then
				selectedMeteor:ShiftUp()
			elseif key == "pagedown" then
				selectedMeteor:ShiftDown()
			elseif key == "r" then
				-- local x, y = love.mouse.getPosition()
				-- local angle = AngleXYXY(selectedMeteor.dispX, selectedMeteor.dispY, x, y)
				selectedMeteor:AddRamp(mouseAngle, 1000)
			elseif key == "=" then
				print("mirror")
				selectedMeteor:Mirror()
			end
 		end
	end
end

function love.keyreleased(key)
	keyPress[key] = nil
	keyPresses = keyPresses - 1
end

function love.mousepressed(x, y, button)
	if selectedMeteor then
		if button == "wu" then
			selectedMeteor:ShiftUp()
		elseif button == "wd" then
			selectedMeteor:ShiftDown()
		end
	end
	mousePress[button] = {x = x, y = y}
	mousePresses = mousePresses + 1
end

function love.mousereleased(x, y, button)
	if button == "r" then
		if mousePress["r"].origMeteorDispRadius then
			local mult = selectedMeteor.dispCraterRadius / mousePress["r"].origMeteorDispRadius
			print(mult)
			selectedMeteor:Resize(mult)
		end
	end
	mousePress[button] = nil
	mousePresses = mousePresses - 1
end

function love.mousemoved(x, y, dx, dy)
	if mousePresses == 0 and keyPresses == 0 then
		local minDist = 9999
		for i, m in pairs(myWorld.meteors) do
			local dist = DistanceSq(x, y, m.dispX, m.dispY)
			if dist < minDist then
				minDist = dist
				selectedMeteor = m
			end
		end
	end
	if selectedMeteor then
		mouseAngle = AngleXYXY(selectedMeteor.dispX, selectedMeteor.dispY, x, y)
		mouseAngleX2, mouseAngleY2 = CirclePos(selectedMeteor.dispX, selectedMeteor.dispY, selectedMeteor.dispCraterRadius, mouseAngle)
		if mousePress["l"] then
			local mp = mousePress["l"]
			if not mp.origMeteorDispX then
				mp.origMeteorDispX = selectedMeteor.dispX+0
				mp.origMeteorDispY = selectedMeteor.dispY+0
				mousePress["l"] = mp
			end
			local mdx, mdy = x - mp.x, y - mp.y
			local mx = mp.origMeteorDispX + mdx
			local my = mp.origMeteorDispY + mdy
			local sx, sz = displayMapRuler:XYtoXZ(mx, my)
			-- print(mp.x, mp.y, mdx, mdy, mx, my, sx, sz)
			selectedMeteor:Move(sx, sz)
		elseif mousePress["r"] then
			local mp = mousePress["r"]
			mp.origMeteorDispRadius = mp.origMeteorDispRadius or selectedMeteor.dispCraterRadius+0
			mousePress["r"] = mp
			local dx = x - mp.x
			selectedMeteor.dispCraterRadius = mMax(mp.origMeteorDispRadius + dx, 1)
		end
	end
end

function love.draw()
	if testNoise then
		for x = 0, displayMapRuler.width-1 do
			for y = 0, displayMapRuler.height-1 do
				local n = testNoiseMap:Get(x+1,y+1)
				love.graphics.setColor(n,n,n)
				love.graphics.point(x, y)
			end
		end
		return
	end
	if myWorld and not previewCanvas then
		for i, m in pairs(myWorld.meteors) do
			if not m.rgb then m:PrepareDraw() end
			love.graphics.setColor(m.rgb[1], m.rgb[2], m.rgb[3])
			love.graphics.circle("fill", m.dispX, m.dispY, m.dispCraterRadius, 8)
		end
		for i, m in pairs(myWorld.meteors) do
			if m.metal > 0 then
				love.graphics.setColor(255, 0, 0)
				love.graphics.circle("fill", m.dispX, m.dispY, 6+(2*m.metal), 4)
			end
			if m.geothermal then
				love.graphics.setColor(255, 255, 0)
				love.graphics.circle("fill", m.dispX, m.dispY, 4, 3)
			end
			if #m.ramps > 0 then
				love.graphics.setLineWidth(7)
				love.graphics.setColor(255, 127, 0)
				for r, ramp in pairs(m.ramps) do
					if not ramp.dispX2 then m:PrepareDraw() end
					love.graphics.line(m.dispX, m.dispY, ramp.dispX2, ramp.dispY2)
				end
			end
		end
		if selectedMeteor then
			if mouseAngleX2 then
				love.graphics.setLineWidth(3)
				love.graphics.setColor(127, 63, 0)
				love.graphics.line(selectedMeteor.dispX, selectedMeteor.dispY, mouseAngleX2, mouseAngleY2)
			end
			love.graphics.setLineWidth(3)
			love.graphics.setColor(255, 255, 255)
			love.graphics.circle("line", selectedMeteor.dispX, selectedMeteor.dispY, selectedMeteor.dispCraterRadius, 8)
			if selectedMeteor.mirroredMeteor and type(selectedMeteor.mirroredMeteor) ~= "boolean" then
				love.graphics.setLineWidth(1)
				love.graphics.setColor(128, 128, 128)
				love.graphics.line(selectedMeteor.dispX, selectedMeteor.dispY, selectedMeteor.mirroredMeteor.dispX, selectedMeteor.mirroredMeteor.dispY)
				love.graphics.setColor(255, 255, 255)
				love.graphics.circle("line", selectedMeteor.mirroredMeteor.dispX, selectedMeteor.mirroredMeteor.dispY, selectedMeteor.mirroredMeteor.dispCraterRadius, 8)
			end
			if not commandBuffer then
				love.graphics.setColor(255,255,255)
				love.graphics.print(selectedMeteor.infoStr, 8, 8)
			end
		end
		local r = myWorld.renderers[1]
		if r and r.renderBgRect then
			ColorRGB(renderBgRGB)
			RectXYWH(r.renderBgRect)
			ColorRGB(r.renderFgRGB)
			RectXYWH(r.renderFgRect)
			love.graphics.setColor(255, 255, 255)
			love.graphics.print(r.renderType, r.renderBgRect.x2, r.renderBgRect.y2)
			if r.renderProgressString then love.graphics.print(r.renderProgressString, r.renderBgRect.x2, r.renderBgRect.y1) end
		end
	end
	if previewCanvas then
		love.graphics.setColor(255,0,0)
		love.graphics.print("PREVIEW", 8, 108)
		love.graphics.setColor(255,255,255)
		love.graphics.draw(previewCanvas)
	end
	if commandBuffer then
		local maxLen = commandBuffer:len()
		local maxStr = commandBuffer
		for i, c in pairs(commandHistory) do
			if c:len() > maxLen then
				maxLen = c:len()
				maxStr = c
			end
		end
		maxStr = "  " .. maxStr .. " "
		love.graphics.setColor(0, 0, 0, 127)
		love.graphics.rectangle("fill", 8, displayMapRuler.height - 8 - commandLineFont:getHeight()*(#commandHistory+1), commandLineFont:getWidth(maxStr), commandLineFont:getHeight()*(#commandHistory+1) )
		PrintCommandLine(commandBuffer)
		if #commandHistory > 0 then
			for i = #commandHistory, 1, -1 do
				local c = commandHistory[i]
				local r, g, b
				if i == commandHistoryPos then
					r, g, b = 0, 255, 0
				end
				local invI = (#commandHistory - i) + 1
				PrintCommandLine(c, invI, r, g, b)
			end
		end
		if printLines and #printLines > 0 then
			love.graphics.setFont(printLineFont)
			love.graphics.setColor(255, 255, 255)
			-- love.graphics.setBlendMode("subtractive")
			local firstCol = mMax(1, #printLines - maximumPrintLines)
			for i = firstCol, #printLines do
				local l = printLines[i]
				-- local invI = #printLines - i
				local row = i - firstCol
				love.graphics.printf( l, printLineWidth, 8 + printLineHeight*row, printLineWidth, "left" )
			end
			-- love.graphics.setBlendMode("alpha")
		end
	end
	love.graphics.setColor(0,0,0)
end

function love.update(dt)
	local renderer = myWorld.renderers[1]
	if renderer then
		renderer:Frame()
		if renderer.complete then
		  -- spEcho(renderer.renderType, "complete", #myWorld.renderers)
		  tRemove(myWorld.renderers, 1)
		  renderer = nil
		else
			renderer:PrepareDraw()
		end
	end
end