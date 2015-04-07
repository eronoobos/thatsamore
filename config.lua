outDir = "output/"

AmoreComWords = {
	heightpreview = function(words, myWorld, uiCommand)
		myWorld:RenderHeightImage(uiCommand, displayMapRuler)
	end,
	attributespreview = function(words, myWorld, uiCommand)
		myWorld:RenderAttributes(uiCommand, displayMapRuler)
	end,
	exit = function(words, myWorld, uiCommand)
		love.event.quit()
	end,
	quit = function(words, myWorld, uiCommand)
		love.event.quit()
	end,
}

commandKeys = {
}

renderRatioRect = { x1 = 0.25, y1 = 0.49, x2 = 0.75, y2 = 0.51 }
renderBgRGB = { r = 0, g = 0, b = 128 }

worldEditBlackList = {
  complexDiameter = 1,
  complexDiameterCutoff = 1,
  complexDepthScaleFactor = 1,
  blastRayAgeDivisor = 1,
  mapSizeX = 1,
  mapSizeZ = 1,
}
