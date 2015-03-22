outDir = "output/"
yesMare = false -- send huge melt-floor-generating meteors before a shower?
doNotStore = false
mapSize512X = 12
mapSize512Z = 12

Game = {
	mapSizeX = mapSize512X * 512,
	mapSizeZ = mapSize512Z * 512,
	squareSize = 8,
	-- gravity = 130,
	gravity = 130,
	mapHardness = 100,
	mapName = "Loony.smf",
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
}
