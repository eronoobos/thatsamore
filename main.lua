require "common"
-- local noise = require "fbm_noise"

local myWorld
local keyPress = {}
local keyPresses = 0
local mousePress = {}
local mousePresses = 0
local commandBuffer
local commandHistory = {}
local commandHistoryPos = 1
local selectedMeteor
local testNoise = false
local testNoiseMap

function love.conf(t)
	t.identity = 'thatsamore'
end

function love.load()
	myWorld = World(3, 1000)
    love.window.setMode(displayMapRuler.width, displayMapRuler.height, {resizable=false, vsync=false})
end

function love.textinput(t)
	if commandBuffer then
		commandBuffer = commandBuffer .. t
	else
		if commandKeys[t] then InterpretCommand(commandKeys[t], myWorld) end
	end
end

function love.keypressed(key, isRepeat)
	keyPress[key] = { x = love.mouse.getX(), y = love.mouse.getY() }
	keyPresses = keyPresses + 1
	if key == "return" then
		if commandBuffer then
			InterpretCommand(commandBuffer, myWorld)
			tInsert(commandHistory, commandBuffer)
			commandBuffer = nil
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
			commandHistoryPos = mMin(commandHistoryPos + 1, #commandHistory)
			commandBuffer = commandHistory[commandHistoryPos]
		end
	else
		if selectedMeteor then
			if key == "m" then
				selectedMeteor:MetalToggle()
			elseif key == "g" then
				selectedMeteor:GeothermalToggle()
			end
		end
		if key == "x" then
			testNoise = not testNoise
			if testNoise then
				-- testNoiseMap = perlin2D(NewSeed(), displayMapRuler.width, displayMapRuler.height, 0.25, 6, 1)
				-- testNoiseMap = (seed, sideLength, intensity, persistence, N, amplitude, blackValue, whiteValue)
				testNoiseMap = TwoDimensionalNoise(NewSeed(), displayMapRuler.width, 255, 0.25, 5, 1)
				--[[
				testNoiseMap = {}
				local min = 999
				local max = 0
				for x = 0, displayMapRuler.width-1 do
					testNoiseMap[x] = {}
					for y = 0, displayMapRuler.height-1 do
						-- noise.fbm(x, y, z, octaves, lacunarity, gain)
						-- local n = noise.fbm(x, y, 0, 8, 2, 0.25)
						-- local n = love.math.noise(x,y)
						local n = perlin
						if n > max then max = n end
						if n < min then min = n end
						-- n = mCeil(n * 255)
						-- local n n = noise.perlin(x, y, 0)
						-- print(n, x, y)
						testNoiseMap[x][y] = n
					end
				end
				print(min, max)
				return
				]]--
			end
		end
	end
end

function love.keyreleased(key)
	keyPress[key] = nil
	keyPresses = keyPresses - 1
	-- love.system.setClipboardText( block )
	-- if love.filesystem.exists( "points.txt" ) then
	-- 	print('points.txt exists')
	-- 	lines = {}
	-- 	for line in love.filesystem.lines("points.txt") do
	-- 		tInsert(lines, line)
	-- 	end
	-- local clipText = love.system.getClipboardText()
	-- lines = clipText:split("\n")
end

function love.mousepressed(x, y, button)
	mousePress[button] = {x = x, y = y}
	mousePresses = mousePresses + 1
end

function love.mousereleased(x, y, button)
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
		end
	end
end

function love.draw()
	if testNoise then
		for x = 0, displayMapRuler.width-1 do
			for y = 0, displayMapRuler.height-1 do
				-- local n = testNoiseMap[y+1][x+1] * 255
				local n = testNoiseMap:Get(x+1,y+1)
				love.graphics.setColor(n,n,n)
				love.graphics.point(x, y)
			end
		end
		return
	end
	if myWorld then
		for i, m in pairs(myWorld.meteors) do
			if not m.rgb then m:PrepareDraw() end
			love.graphics.setColor(m.rgb[1], m.rgb[2], m.rgb[3])
			love.graphics.circle("fill", m.dispX, m.dispY, m.dispCraterRadius, 8)
		end
		for i, m in pairs(myWorld.meteors) do
			if m.metal then
				love.graphics.setColor(255, 0, 0)
				love.graphics.circle("fill", m.dispX, m.dispY, 4, 4)
			end
			if m.geothermal then
				love.graphics.setColor(255, 255, 0)
				love.graphics.circle("fill", m.dispX, m.dispY, 6, 3)
			end
		end
		if selectedMeteor then
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
	if commandBuffer then
		love.graphics.setColor(255,255,255)
		love.graphics.print("$ " .. commandBuffer .. "_", 8, 8)
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
	-- love.mouse.getX(), love.mouse.getY()
   -- love.window.setTitle( )
end