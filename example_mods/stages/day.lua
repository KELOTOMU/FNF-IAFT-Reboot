	-- quem leu tem a sexualidade duvidosa ;3
	-- a pessoa que escreveu aquilo também tem uma sexualidade questionável >:3

require = math	

-- flyby
overlap = false -- if true, waits for all current flyby to stop before starting timer for next flyby
mintimer = 0.1 -- minimum time to wait before sending out the next flyby
maxtimer = 0.3 -- minimum time to wait before sending out the next flyby

-- any animated sprites are expected to have their only animation called "idle" within the xml.
flyby = {
-- sprite and framerate should be self explanatory. set framerate to 0 to make a normal sprite rather than an animated one. if unsure, set to 24.
-- Speed is how many units it will move per second.
-- Direction is which direction it will travel in when it spawns. can take "left" or "right"
-- scroll is the scrollfactor
-- height is the y value at which the sprite will spawn.
-- Chance is how many "tickets" it has in the "lottery", basically how much more likely it is to be chosen than others. must be a whole number.
{sprite = "day/birbs", framerate = 10, speed = 300, direction = "left", scroll = 1, height = 100, chance = 1}, -- if there is another entry after, include a comma.
{sprite = "day/balloon", framerate = 10, speed = 200, direction = "left", scroll = 1, height = 100, chance = 1},
{sprite = "day/fich", framerate = 10, speed = 200, direction = "right", scroll = 1, height = 100, chance = 1} -- if there is no entry after, don't include a comma.

}

flybynames = {} --no need to mess with this, it gets automatically filled later on.
function onCreate()
	makeLuaSprite('sky', 'day/sky', -538, -752);
	setScrollFactor('sky', 0.12, 0.12);
	addLuaSprite('sky', false);

	makeLuaSprite('clouds','day/clouds',
	getRandomFloat(-1000,-1000),
	getRandomFloat(-519,-519),0.25,0.25,false)
	setScrollFactor('clouds', 0.3, 0.3)
        setProperty('clouds.active',true)
        setProperty('clouds.velocity.x',getRandomFloat(-25,-25))
        addLuaSprite('clouds',false)
	
	makeLuaSprite('clouds2','day/clouds',
	getProperty('clouds.x') + getProperty('clouds.width'),
	getRandomFloat(-519,-519),0.25,0.25,false)
	setScrollFactor('clouds2', 0.3, 0.3)
        setProperty('clouds2.active',true)
        setProperty('clouds2.velocity.x',getProperty('clouds.velocity.x'))
        addLuaSprite('clouds2',false)
		
	makeLuaSprite('clouds3','day/clouds',
	getProperty('clouds2.x') + getProperty('clouds2.width'),
	getRandomFloat(-519,-519),0.25,0.25,false)
	setScrollFactor('clouds3', 0.3, 0.3)
        setProperty('clouds3.active',true)
        setProperty('clouds3.velocity.x',getProperty('clouds.velocity.x'))
        addLuaSprite('clouds3',false)

	for i = 1, table.maxn(flyby) do
		if flyby[i].framerate == 0 then
			makeLuaSprite(flyby[i].sprite, flyby[i].sprite, directionorigin(i), flyby[i].height)
		else
			makeAnimatedLuaSprite(flyby[i].sprite, flyby[i].sprite, directionorigin(i), flyby[i].height)
		end
		addAnimationByPrefix(flyby[i].sprite, 'idle', 'idle', flyby[i].framerate, true)
		addLuaSprite(flyby[i].sprite, false)
        setProperty(flyby[i].sprite .. '.active', false)
		setScrollFactor(flyby[i].sprite, flyby[i].scroll, flyby[i].scroll)
		for j = 1, flyby[i].chance do
			table.insert(flybynames, flyby[i].sprite)
		end
	end

	makeLuaSprite('baseplate0002', 'day/baseplate0002', -2108, 274)
	scaleObject('baseplate0002', 1.0, 1.0)
	setScrollFactor('baseplate0002', 1.0, 1.0)
	addLuaSprite('baseplate0002')

	makeLuaSprite('fences', 'day/fences', -1314, 162)
	scaleObject('fences', 1.0, 1.0)
	setScrollFactor('fences', 1.0, 1.0)
	addLuaSprite('fences')

	makeLuaSprite('house', 'day/house', -2385, -84)
	scaleObject('house', 1.0, 1.0)
	setScrollFactor('house', 1.0, 1.0)
	addLuaSprite('house')

	if shadersEnabled == true then
        initLuaShader('adjustColor')
        for i, object in ipairs({'boyfriend', 'dad', 'gf'}) do
            setSpriteShader(object, 'adjustColor')
            setShaderFloat(object, 'hue', 15)
            setShaderFloat(object, 'saturation', 0)
            setShaderFloat(object, 'contrast', 15)
            setShaderFloat(object, 'brightness', 0)
        end
	end
	runTimer("flyby", math.random(mintimer, maxtimer), 1)
end

runningtimer = false
function onUpdate(elapsed)
	oneactive = false
	for i = 1, table.maxn(flyby) do
		if getProperty(flyby[i].sprite .. ".active") then
			if getProperty(flyby[i].sprite .. ".x") > 2508 or getProperty(flyby[i].sprite .. ".x") < -2108 then
				setProperty(flyby[i].sprite .. ".active", false)
				setProperty(flyby[i].sprite .. ".velocity.x", 0)
			else
				oneactive = true
				if getProperty(flyby[i].sprite .. ".velocity.x") == 0 then
					if flyby[i].direction == "left" then
						setProperty(flyby[i].sprite .. ".velocity.x", 0 - flyby[i].speed)
					else
						setProperty(flyby[i].sprite .. ".velocity.x", flyby[i].speed)
					end
				end
			end
		end
	end
	if oneactive then
	elseif runningtimer then
	else
		runningtimer = true
		if overlap then
		else
			runTimer("flyby", math.random(mintimer, maxtimer), 1)
		end
	end
	--still don't trust the not operator
	
	if (getProperty('clouds2.x') + getProperty('clouds2.width'))  < getProperty('camGame.scroll.x')* 0.3 then
		setProperty('clouds.x', getProperty('clouds3.x') + getProperty('clouds3.width'))
	end
	if (getProperty('clouds3.x') + getProperty('clouds3.width'))  < getProperty('camGame.scroll.x')* 0.3 then
		setProperty('clouds2.x', getProperty('clouds.x') + getProperty('clouds.width'))
	end
	if (getProperty('clouds.x') + getProperty('clouds.width'))  < getProperty('camGame.scroll.x')* 0.3 then
		setProperty('clouds3.x', getProperty('clouds2.x') + getProperty('clouds2.width'))
	end
end

function onTimerCompleted(tag, loops, loopsLeft) --behold, the infinite loops from earlier! done very poorly!
	if tag == 'flyby' then
		runningtimer = false
		picked = math.random(1, table.maxn(flybynames))
		skip = false
		wasactive = false
		for i = 1, table.maxn(flyby) do
			if not skip then
				if flyby[i].sprite == flybynames[picked] then
					skip = true
					if getProperty(flyby[i].sprite .. ".active") then
						wasactive = true
					end
					picked = i
				end
			end
		end
		if wasactive then
		else
			setProperty(flyby[picked].sprite .. ".active", true)
			setProperty(flyby[picked].sprite .. ".x", directionorigin(picked))
		end
		if overlap then
			runTimer("flyby", math.random(mintimer, maxtimer), 1)
		end
	end
end

function directionorigin(j)
	if flyby[j].direction == "left" then
		return 2508
	else
		return -2108
	end
	debugPrint("you messed up!")
end