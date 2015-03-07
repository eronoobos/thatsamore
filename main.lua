require "common"

local myWorld
local keyPress = {}
local mousePress = {}
local commandBuffer
local commandHistory = {}
local commandHistoryPos = 1

function love.conf(t)
	t.identity = 'thatsamore'
end

function love.load()
	myWorld = World(2.32, 1000)
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
	if key == "return" then
		if commandBuffer then
			InterpretCommand(commandBuffer, myWorld)
			tInsert(commandHistory, commandBuffer)
			commandBuffer = nil
		else
			commandBuffer = ""
		end
	elseif key == "backspace" then
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
end

function love.keyreleased(key)
	keyPress[key] = nil
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
end

function love.mousereleased(x, y, button)
	mousePress[button] = nil
end

local underscore = 0

function love.draw()
	if myWorld then
		for i, m in pairs(myWorld.meteors) do
			if not m.rgb then m:PrepareDraw() end
			love.graphics.setColor(m.rgb[1], m.rgb[2], m.rgb[3])
			love.graphics.circle("fill", m.dispX, m.dispY, m.dispCraterRadius, 8)
			if m.metal then
				love.graphics.setColor(255, 0, 0)
				love.graphics.circle("fill", m.dispX, m.dispY, 4, 4)
			end
			if m.geothermal then
				love.graphics.setColor(255, 255, 0)
				love.graphics.circle("fill", m.dispX, m.dispY, 6, 3)
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
		love.graphics.setColor(0,0,0)
	end
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