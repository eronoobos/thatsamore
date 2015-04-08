outDir = "output/"

AmoreComWords = {
	heightpreview = function(words, myWorld, uiCommand)
		myWorld:RenderHeight(displayMapRuler, uiCommand)
	end,
	attributespreview = function(words, myWorld, uiCommand)
		myWorld:RenderAttributes(displayMapRuler, "data", uiCommand)
	end,
	exit = function(words, myWorld, uiCommand)
		love.event.quit()
	end,
	quit = function(words, myWorld, uiCommand)
		love.event.quit()
	end,
}

AmoreWorldSaveBlacklist = {
  "rgb",
  "dispX",
  "dispY",
  "dispX2",
  "dispY2",
  "infoStr",
  "infoX",
  "infoY",
  "dispCraterRadius",
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
