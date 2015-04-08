require "common"

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

local worldEditMode
local worldEditKey
local worldEditInput

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


-- love callins --------------------------------------------------------------

function love.conf(t)
	t.identity = 'thatsamore'
end

function love.load()
	io.stdout:setvbuf("no")
	logFile = assert(io.open(outDir.."stdout.log","w"), "Unable to save to "..outDir.."stdout.log")
	commandLineFont = love.graphics.newFont("fonts/SourceCodePro-Medium.ttf", 16)
	printLineFont = love.graphics.newFont("fonts/SourceCodePro-Medium.ttf", 12)
	love.keyboard.setKeyRepeat(true)
	myWorld = Loony.World(nil, nil, 4, 1000)
	ResetDisplay(myWorld)
	for word, comFunc in pairs(AmoreComWords) do
		Loony.SetCommandWord(word, comFunc)
	end
	for i, k in pairs(AmoreWorldSaveBlacklist) do
		Loony.AddToWorldSaveBlacklist(k)
	end
end

function love.quit()
	logFile:close()
end

function love.textinput(t)
	if worldEditInput then
		worldEditInput = worldEditInput .. t
	elseif commandBuffer then
		commandBuffer = commandBuffer .. t
	else
		if commandKeys[t] then myWorld:InterpretCommand(commandKeys[t], myWorld) end
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
				local validCommand = myWorld:InterpretCommand(commandBuffer, myWorld)
				if validCommand then tInsert(commandHistory, commandBuffer) end
			end
			commandBuffer = nil
			previewCanvas = nil
		else
			commandBuffer = ""
		end
		commandHistoryPos = #commandHistory+1
	end
	if worldEditMode then
		if key == "w" then
			worldEditMode = nil
		elseif key == "return" then
			if worldEditInput then
				local result = tonumber(worldEditInput) or worldEditInput == "true" or worldEditInput
				myWorld[worldEditKey] = result
				myWorld:Calculate()
				ResetDisplay(myWorld)
				worldEditInput = nil
			else
				worldEditInput = ""
			end
		elseif key == "down" then
			local nextOne
			for k, v in pairs(myWorld) do
				if not worldEditBlackList[k] and type(v) ~= "table" then
					if nextOne then
						worldEditKey = k
						break
					end
					if k == worldEditKey then nextOne = true end
				end
			end
		elseif key == "up" then
			local prevOne
			for k, v in pairs(myWorld) do
				if not worldEditBlackList[k] and type(v) ~= "table" then
					if k == worldEditKey then
						worldEditKey = prevOne or worldEditKey
						break
					end
					prevOne = k
				end
			end
		end
	elseif commandBuffer then
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
		elseif key == "w" then
			worldEditMode = true
			for k, v in pairs(myWorld) do
				if not worldEditBlackList[k] and type(v) ~= "table" then
					worldEditKey = k
					break
				end
			end
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
				selectedMeteor:AddRamp(mouseAngle, 1000)
			elseif key == "f" then
				selectedMeteor:ClearRamps()
			elseif key == "=" then
				selectedMeteor:Mirror()
			elseif key == "s" then
				selectedMeteor:NextSeed()				
			elseif key == "a" then
				selectedMeteor:PreviousSeed()
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
			if not m.rgb then PrepareMeteorDraw(m) end
			love.graphics.setColor(m.rgb[1], m.rgb[2], m.rgb[3])
			local segments = 6
			if m.impact and m.impact.complex then segments = 12 end
			love.graphics.circle("fill", m.dispX, m.dispY, m.dispCraterRadius, segments)
		end
		for i, m in pairs(myWorld.meteors) do
			if m.impact and m.impact.blastNoise then
				love.graphics.setColor(0, 0, 255)
				love.graphics.setLineWidth(3)
				love.graphics.circle("line", m.dispX, m.dispY, m.dispCraterRadius-3, 5)
			end
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
					if not ramp.dispX2 then PrepareDraw(m) end
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
			if not commandBuffer and not worldEditMode then
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
	if worldEditMode then
		love.graphics.setFont(commandLineFont)
		love.graphics.setColor(255, 0, 0)
		love.graphics.print("WORLD", 8, 8)
		local i = 1
		for k, v in pairs(myWorld) do
			if not worldEditBlackList[k] and type(v) ~= "table" then
				local c = k .. " = " .. tostring(v)
				local r, g, b = 255, 255, 255
				if k == worldEditKey then
					r, g, b = 0, 255, 0
					if worldEditInput then
						c = k .. " = " .. worldEditInput .. "_"
					end
				end
				love.graphics.setColor(r or 255, g or 255, b or 255)
				love.graphics.setLineWidth(5)
				love.graphics.print(c, 8, 8 + (i*commandLineFont:getHeight()))
				i = i + 1
			end
		end
	elseif commandBuffer then
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
	myWorld:RendererFrame(dt)
end

-- end love callins ----------------------------------------------------------


-- Loony callins -------------------------------------------------------------

function Loony.UpdateMeteor(meteor)
	PrepareMeteorDraw(meteor)
end

function Loony.UpdateWorld(myWorld)
	ResetDisplay(myWorld)
end

function Loony.FrameRenderer(renderer)
	PrepareRendererDraw(renderer)
end

function Loony.CompleteRenderer(renderer)
	if renderer.uiCommand == "heightpreview" then
		previewCanvas = PreviewHeights(renderer.heightBuf)
	elseif renderer.uiCommand == "attributespreview" then
		previewCanvas = PreviewAttributes(renderer.data)
	end
end

-- end Loony callins ---------------------------------------------------------
