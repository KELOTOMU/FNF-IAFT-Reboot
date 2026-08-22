require = math -- because yes

-- customizable vars
	--files
	generate = false -- if true, generates a new xml file for the fill sprite. only use once per file change. requires game restart after generation
	sunSprite = "sun" -- blank for yellow square placeholder
	sunAnim = "suncol" -- xml name of animation to loop. blank for static sprite. if you know how to create a character json in the psych editor, this shouldn't be an issue.
	collectsound = "" -- insert sound name to play whenever sun is collected. only the name is needed, not the file extension.
	sunFrames = 8 -- framerate of the sun animation. unused if sunAnim is blank
	barSprite = "sun_meter" -- image name for bar, expected to be at full size, no additional resizing avaliable
	fillSprite = "sun_fill" -- image name for fill, expected to fit inside barSprite, including blank space.

	-- sun dropping
	flowerAmount = 1 -- if there is more than one flower, name all lua sprites the same with a number after it starting with 1. ex: "flower1", "flower2", "flower3"...
	flowerSprite = "gf" -- this expects there to only be one flower on the stage, with this pointing to the lua sprite for it.
	maxGroundSun = 20 -- max amount of sun particles (performance reasons)
	randomInterval = {5,7} -- range of time to randomly pick from (sunflowers will drop faster)
	flowerDropMult = 2 -- how much faster flowers will drop suns compared to the value above
	dropanim = "sunSpawn" -- name of animation to play for sunflower when dropping sun. sprite is expected to already have animations set up when this is called. keep blank to not play any animation.
	dropanimframe = 0.55 -- seconds to wait until dropping sun from sunflower. do the math yourself.

	--collection
	spaceCollect = true -- true or false, allows the collection of sun by pressing space. can always be collected through clicking.
	curStoredSuns = 200 -- starting sun, if any
	maxStoreSun = 200 -- max amount of collected sun
	sunNeeded = 0 -- sun needed to allow health gain
	sunDrain = 6 -- amount of sun to lose per second, tweened
	sunMult = 25 -- the amount of sun to collect each time you collect a sun... huh. easier to understand than it is to explain.
	collecttarget = "boyfriend" -- where the sun goes after being clicked or when pressing space. must be on stage!
	collectanim = "hey" -- name of animation to play for sprite when sun collected
	
	--positioning
	sunSpawnOffset = {130,-300} -- offset formatted as {x,y} that determines where the sun should spawn from a sunflower
	sunFallOffset = 300 -- how far the sun from a sunflower should fall. set to the opposite of the sunSpawnOffset y position normally, or adjust to match the "floor"
	sunDropRadius = 0 -- how far from the sunflowers (or bf if made as main source) sun can spawn
	sunMainSource = "spread" -- can be either "spread" or "bf". "spread" will cause sun to spawn between bf and the opponent rather than just bf
	barSpriteLocation = {.1, .6} -- where the bar should appear on screen, taken as percentages, arranged as {x, y}
	fillPositions = {58, 307} -- where the fill is on its image, arranged as {top, bottom}.
	sunflowerspawnheight = 100 -- how high sun should jump when spawning from a flower

	--zombie stuff
	killsun = true -- kills sun instead of letting zombies collect it.
	zombieCollect = 1 -- time in seconds before the enemy tries to collect any dropped suns. just set to an impossibly large number if you don't want it, i guess
	zombieMaxSuns = 5 -- how many the zombies need before bf just dies

-- non-customizable vars. in other words, no touchie
curSun = 0 -- not the amount of sun you have, this is the index of the last sun spawned
activeSuns = {} -- a table of all spawned suns
spawningSuns = {} -- a table of each sun that's queued to be spawned.
zombieSuns = 0 -- amount of sun zombies have. currently no way to display amount to player? come up with a way soon or scrap it.
generateddistancetable = {} -- empty table that's filled based on the "fillPositions" table earlier. used to determine the best frame for the "fillSprite"

function onCreatePost()
	runTimer('dropSunBF', math.random(randomInterval[1], randomInterval[2]), 1) --get the infinite timers set up
	if flowerAmount > 1 then
		for i = 1, flowerAmount do
			runTimer('dropSunFlower'..i, math.random(randomInterval[1], randomInterval[2])/2, 1)
		end
	else
		runTimer('dropSunFlower', math.random(randomInterval[1], randomInterval[2])/flowerDropMult, 1)
	end
	
	--[[
	for i = 1, flowerAmount do
		makeLuaSprite('sunflower'..i, sunSprite, getProperty("boyfriend.x") - 400, getProperty("boyfriend.y"))
		makeGraphic('sunflower'..i, 90, 300, '00FF00')
		addLuaSprite('sunflower'..i, true)
	end
	]]--
	-- Just a debug placeholder to make fake sunflowers. you can uncomment it if you want, i guess, though it won't do anything if "flowerSprite" is set to anything but "sunflower".
	
	setPropertyFromClass('flixel.FlxG', 'mouse.visible', true)
	
	makeAnimatedLuaSprite('fillSprite', fillSprite)
	
	addAnimationByPrefix("fillSprite", 'full', "full", 1, true)
	
	for i = 1, fillPositions[2] - fillPositions[1] do
		addAnimationByPrefix("fillSprite", i .. "state", i .. "state", 1, true)
		generateddistancetable[i] = i / (fillPositions[2] - fillPositions[1])
	end
	
	playAnim("fillSprite", 'full', true)
	
	addLuaSprite("fillSprite", true)
	setObjectCamera('fillSprite', 'hud')
	
	makeLuaSprite("barSprite", barSprite, 0, 0)
	setObjectCamera('barSprite','hud')
	addLuaSprite("barSprite", true)
	setProperty("barSprite.x", (screenWidth * barSpriteLocation[1]) - (getProperty("barSprite.width") / 2))
	setProperty("barSprite.y", (screenHeight * barSpriteLocation[2]) - (getProperty("barSprite.height") / 2))
	
	if generate then
		deleteFile("images/"..fillSprite..".xml")
		saveFile("images/"..fillSprite..".xml", generatexml(fillPositions))
	end
	
	
	setProperty("fillSprite.x", (screenWidth * barSpriteLocation[1]) - (getProperty("barSprite.width") / 2))
	setProperty("fillSprite.y", (screenHeight * barSpriteLocation[2]) - (getProperty("barSprite.height") / 2))
	
end

function onUpdate(elapsed)

	if mouseClicked("left") then
		for i = 1, table.maxn(activeSuns) do
			if positionWithin((getMouseX("game") + getProperty('camGame.scroll.x')), (getMouseY("game") + getProperty('camGame.scroll.y')), getProperty('sun'..activeSuns[i]..'.x'), getProperty('sun'..activeSuns[i]..'.x') + getProperty('sun'..activeSuns[i]..'.width'), getProperty('sun'..activeSuns[i]..'.y'), getProperty('sun'..activeSuns[i]..'.y') + getProperty('sun'..activeSuns[i]..'.height')) and getProperty('sun'..activeSuns[i]..'.alpha') == 1 then
				doTweenY('yun'..activeSuns[i], 'sun'..activeSuns[i], getProperty(collecttarget..'.y') + (getProperty(collecttarget..'.height') / 2), 0.5, 'outQuart')
				doTweenX('xun'..activeSuns[i], 'sun'..activeSuns[i], getProperty(collecttarget..'.x') + (getProperty(collecttarget..'.width') / 2), 0.5, 'outQuart')
				doTweenAlpha('killsunrightno'..activeSuns[i], 'sun'..activeSuns[i], 0, 0.5, 'linear')
				table.remove(activeSuns, i)
				curStoredSuns = math.min(curStoredSuns + sunMult, maxStoreSun)
				playSound(collectsound, 1)
				
			end
		end
	end
	
	--you can just remove the bottom half if you don't want people pressing space to collect. ditto for the top half and clicking.
	
	if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.SPACE') and table.maxn(activeSuns) >= 1 and spaceCollect and getProperty('sun'..activeSuns[1]..'.alpha') == 1 then
		doTweenY('yun'..activeSuns[1], 'sun'..activeSuns[1], getProperty(collecttarget..'.y') + (getProperty(collecttarget..'.height') / 2), 0.5, 'outQuart')
		doTweenX('xun'..activeSuns[1], 'sun'..activeSuns[1], getProperty(collecttarget..'.x') + (getProperty(collecttarget..'.width') / 2), 0.5, 'outQuart')
		doTweenAlpha('killsunrightno'..activeSuns[1], 'sun'..activeSuns[1], 0, 0.5, 'linear')
		removeLuaSprite('sun'..activeSuns[1], true)
		table.remove(activeSuns, 1)
		curStoredSuns = math.min(curStoredSuns + sunMult, maxStoreSun)
		playSound(collectsound, 1)
	end
	
	curStoredSuns = math.max(0, curStoredSuns - (sunDrain * elapsed))
	
	if curStoredSuns <= sunNeeded then
		setProperty('boyfriend.stunned', true);
	else
		setProperty('boyfriend.stunned', false);
	end
	
	nearestdrain = 1
	lastclosest = 900
	tempStoredSuns = 1 - (curStoredSuns / maxStoreSun)
	for i = 1, table.maxn(generateddistancetable) do
		if math.abs(tempStoredSuns - generateddistancetable[i]) < lastclosest then
			lastclosest = math.abs(tempStoredSuns - generateddistancetable[i])
			nearestdrain = i
		end
	end
	
	playAnim("fillSprite", nearestdrain .. "state", true)
	setProperty("fillSprite.y", (screenHeight * barSpriteLocation[2]) - (getProperty("barSprite.height") / 2) + nearestdrain + fillPositions[1])
	
	if spawningSuns == {} then
	else
		removequeue = {}
		for i = 1, table.maxn(spawningSuns) do
			spawningSuns[i].c = spawningSuns[i].c + elapsed
			if spawningSuns[i].c >= dropanimframe then
				if spawningSuns[i].s == nil then
					dropSun(flowerSprite)
				else
					dropSun(flowerSprite .. spawningSuns[i].s)
				end
				table.insert(removequeue, i)
			end
		end
		if removequeue == {} then
		else
			removeoffset = 0
			for i = 1, table.maxn(removequeue) do
				table.remove(spawningSuns, i - removeoffset)
				removeoffset = removeoffset + 1
			end
		end
	end
end

function dropSun(source) --i love rewriting code to fit both bf and sunflowers in the same function
	if table.maxn(activeSuns) >= maxGroundSun then
		for i = 1, table.maxn(activeSuns) do
			if getProperty('sun'..activeSuns[i]..'.alpha') == 0 then
				table.remove(activeSuns, i)
				dropSun(source)
			end
		end
	else
		curSun = curSun + 1
		if not sunAnim then
			if sunMainSource == "bf" or source ~= "boyfriend" then
				makeLuaSprite('sun'..curSun, sunSprite, getProperty(source .. ".x") + (getProperty(source .. ".width")/2) + math.random(-sunDropRadius,sunDropRadius) + sunSpawnOffset[1], getProperty(source .. ".y") + getProperty(source .. ".height") - 900 + math.random(-10,10) + sunSpawnOffset[2])
			else
				makeLuaSprite('sun'..curSun, sunSprite, math.random(getProperty("boyfriend.x"), getProperty("dad.x")), math.random(getProperty("boyfriend.y") + getProperty("boyfriend.height"), getProperty("dad.y") + getProperty("dad.height")) - 900 + math.random(-10,10))
			end
			
			if sunSprite == "" then
				makeGraphic('sun'..curSun, 50, 50, 'FFFF00')
			end
		else
			if sunMainSource == "bf" or source ~= "boyfriend" then
				makeAnimatedLuaSprite('sun'..curSun, sunSprite, getProperty(source .. ".x") + (getProperty(source .. ".width")/2) + math.random(-sunDropRadius,sunDropRadius) + sunSpawnOffset[1], getProperty(source .. ".y") + getProperty(source .. ".height") + sunSpawnOffset[2])
			else
				makeAnimatedLuaSprite('sun'..curSun, sunSprite, math.random(getProperty("boyfriend.x"), getProperty("dad.x")), math.random(getProperty("boyfriend.y") + getProperty("boyfriend.height"), getProperty("dad.y") + getProperty("dad.height")) - 900 + math.random(-10,10))
			end
			addAnimationByPrefix('sun'..curSun, 'sun', sunAnim, sunFrames, true)
		end
		addLuaSprite('sun'..curSun, true)
		if source == "boyfriend" then
			doTweenY('sun'..curSun, 'sun'..curSun, getProperty('sun'..curSun..'.y') + 800, 4, 'linear')
		else
			doTweenY('presun'..curSun, 'sun'..curSun, getProperty('sun'..curSun .. ".y") - sunflowerspawnheight + math.random(-10,10), sunflowerspawnheight / (800/4), 'cubeOut')
			doTweenX('Xresun'..curSun, 'sun'..curSun, getProperty('sun'..curSun..'.x') + math.random(-80,80), (sunflowerspawnheight / (800/4)) * 2, 'linear')
		end
		table.insert(activeSuns, curSun)
		objectPlayAnimation('sun'..curSun, 'sun', true)
	end
	-- i used to have a lot of trouble with "not" conditions in if statements, so i've just gotten used to doing it this way instead. plus, this gives an easy way to add in more functionality later.
	-- update. what the fuck did i mean by this? what functionality was this going to help with??? the problem with the "not" condition is real though
	-- update 2. encountered a bug that could only be fixed by adding extra functionality to this code. hahaha, i knew i was onto something the first time!
end

function onTimerCompleted(tag, loops, loopsLeft) --behold, the infinite loops from earlier! done very poorly!
	if tag == 'dropSunBF' then
		dropSun('boyfriend')
		runTimer('dropSunBF', math.random(randomInterval[1], randomInterval[2]), 1)
	end
	if string.sub(tag, 1, 13) == 'dropSunFlower' then -- hehe i am smart, this definitely won't break if there are more than 9 sunflowers.
		if string.sub(tag, -1) == 'r' then
			table.insert (spawningSuns, {c=0})
			playAnim(flowerSprite, dropanim)
			setProperty(flowerSprite..'.specialAnim', true)
		else
			table.insert(spawningSuns, {s = string.sub(tag,-1), c = 0})
			playAnim(flowerSprite..string.sub(tag, -1), dropanim)
			setProperty(flowerSprite..string.sub(tag, -1)..'.specialAnim', true)
		end
		runTimer(tag, math.random(randomInterval[1], randomInterval[2])/flowerDropMult, 1)
	end
	if string.sub(tag, 1, 13) == 'zombieCollect' then
		if table.find(activeSuns, tonumber(string.sub(tag, 14))) then
			activeSuns = table.pop(activeSuns, tonumber(string.sub(tag, 14))) --it's their sun now, idiot
			if killsun then
				doTweenAlpha('killsunrightno'..string.sub(tag, 14), 'sun'..string.sub(tag, 14), 0, 1, 'linear')
			else
				objectPlayAnimation('dad', 'singUp', false)
				setProperty('dad.specialAnim', true)
				doTweenX('zombieCollectx'..string.sub(tag, 14), 'sun'..string.sub(tag, 14), getProperty('dad.x') + (getProperty('dad.width')/2), 2, 'expoout')
				doTweenY('zombieCollecty'..string.sub(tag, 14), 'sun'..string.sub(tag, 14), getProperty('dad.y') + (getProperty('dad.height')/2), 2, 'expoout')
			end
		end
	end
end

function onTweenCompleted(tag)
	if string.sub(tag, 1, 3) == 'sun' then
		runTimer('zombieCollect' .. string.sub(tag, 4), zombieCollect, 1)
	end
	if string.sub(tag, 1, 3) == 'xun' then
		removeLuaSprite('sun'.. string.sub(tag, 4), true)
		playAnim(collecttarget, collectanim)
		setProperty(collecttarget..'.specialAnim', true)
	end
	if string.sub(tag, 1, 6) == "presun" then
		doTweenY('sun'..string.sub(tag, 7), 'sun'..string.sub(tag, 7), getProperty("sun" .. string.sub(tag, 7) .. ".y") + sunflowerspawnheight + sunFallOffset, math.abs((sunflowerspawnheight + sunFallOffset) / (800/4)), 'cubeIn')
	end
	if string.sub(tag, 1, 14) == 'killsunrightno' then
		removeLuaSprite('sun'.. string.sub(tag, 15), true)
	end
	if string.sub(tag, 1, 14) == 'zombieCollectx' then
		removeLuaSprite('sun'.. string.sub(tag, 15), true)
		zombieSuns = zombieSuns + 1
		if zombieSuns >= zombieMaxSuns then
			setProperty('health', -9999)
		end
	end
end

function positionWithin(x, y, x1, x2, y1, y2) -- makes code look nicer, but damn i butchered the execution. you need all the values still, and at that point, just don't make the function.
	if x >= x1 and x <= x2 and y >= y1 and y <= y2 then
		return true
	else
		return false
	end
end

function table.pop(dick, value) --custom table function that I'm surprised isn't here
	for i = 1, table.maxn(dick) do
		if dick[table.maxn(dick)-i+1] == value then
			table.remove(dick, table.maxn(dick)-i+1)
		end
	end
	return dick
end

function table.find(dick, value) --custom table function that I'm surprised isn't here
	for i = 1, table.maxn(dick) do
		if dick[i] == value then
			return true
		end
	end
	return false
end

function generatexml(penis)
	cock = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<TextureAtlas imagePath=\"".. fillSprite ..".png\">\n\t<!-- Created with Adobe Animate version 22.0.3.179 -->\n\t<!-- http://www.adobe.com/products/animate.html -->"
	
	for i = penis[1], penis[2] do
		cock = cock .. "\n\t<SubTexture name=\"".. i - penis[1] + 1 .. "state" .."\" x=\"".. 0 .."\" y=\"".. i .."\" width=\""..getProperty("barSprite.width").."\" height=\"".. penis[2] - i .."\" pivotX=\"0\" pivotY=\"".. 0 - i .."\"/>"
	end
	
	cock = cock .. "\n\t<SubTexture name=\"".. "full" .."\" x=\"".. 0 .."\" y=\"".. 0 .."\" width=\"".. getProperty("barSprite.width") .."\" height=\"".. getProperty("barSprite.height") .."\" pivotX=\"0\" pivotY=\"0\"/>"
	cock = cock .. "\n</TextureAtlas>"
	
	return cock
end