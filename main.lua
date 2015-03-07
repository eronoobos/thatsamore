require "common"

local myWorld
local keyPress = {}
local mousePress = {}

local commandKeys = {
	s = "shower 100",
	h = "height",
	a = "attributes",
}

function love.load()
	myWorld = World(2.32, 1000)
    love.window.setMode(metalMapRuler.width, metalMapRuler.height, {resizable=false, vsync=false})
end

function love.keypressed(key)
	keyPress[key] = { x = love.mouse.getX(), y = love.mouse.getY() }
end

function love.keyreleased(key)
	myWorld:InterpretCommand(commandKeys[key])
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

function love.draw()
	-- love.graphics.rectangle("fill", point.t*displayMult, displayMultHundred-point.r*displayMult, displayMult, displayMult)
	-- love.graphics.setColor(255, 0, 0)
	-- love.graphics.print(mFloor(myClimate.pointSet.distance or "nil") .. " " .. mFloor(myClimate.subPointSet.distance or "nil"), 10, displayMultHundred + 70)
end

function love.update(dt)
	local renderer = myWorld.renderers[1]
	if renderer then
		renderer:Frame()
		if renderer.complete then
		  -- spEcho(renderer.renderType, "complete", #myWorld.renderers)
		  tRemove(myWorld.renderers, 1)
		  renderer = nil
		end
	end
	-- love.mouse.getX(), love.mouse.getY()
   -- love.window.setTitle( )
end