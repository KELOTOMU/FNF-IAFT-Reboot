require = math

wind = 0 -- additional side velocity applied to all "leaves"
randomwind = 25 -- additional side velocity to randomly add to each "leaf"
gravity = 250 -- additional downwards velocity applied to all "leaves"
randomgravity = 10 -- additional downwards velocity to randomly add to each "leaf"
spin = 0 -- additional... you get the point.
randomspin = 10 -- spin, each leaf, yatta yatta, etc etc

leaflimit = 50 -- max amount of "leaves" for performance reasons. set to 0 or less for no limit. limit required for "all at once" mode
mintimebetweenleaves = 7-- minimum seconds until each batch of "leaves" spawn. a value of 0 will have the batch spawn on the next avaliable frame.
maxtimebetweenleaves = 15 -- maximum seconds until each batch of "leaves" spawn. a value of 0 will have the batch spawn on the next avaliable frame.
minleavesperbatch = 1 -- minimum amount of leaves in each batch. will be ignored if the "leaf" limit is reached, spawning 0 leaves until the active "leaves" are used up
maxleavesperbatch = 1 -- maximum amount of leaves in each batch.

allatonce = false -- alternate "leaves" mode. spawns all leaves at once, and reuses them as they leave the screen. may cause tile like patterns

leaves = {
-- sprite. if it's not in the "images/" folder of your mod, specify the path further. for example, "day/day/lawnmower"
-- x is the velocity the "leaf" will have going side to side. positive is right, negative is left. it's recommended that all leaves travel the same way for clarity, but do whatever.
-- y is the velocity the "leaf" will have going down or up. positive is down, negative is up. unless you want your leaves to start flying upwards, leave the number positive.
-- angle is the amount the "leaf" will spin. goes based off of the pivot point on the sprite, normally the center, but can be modified using an XML file.
-- chance is how many "tickets" the "leaf" will have in the lottery to get picked.
-- infront is if the "leaf" is spawned in front of the characters on stage / on top of the hud.
-- using a random variable for the velocity type variables is not accepted. use the "random" type variables above to add more variation if needed.
{sprite = "day/falling leaf0002", x = 100, y = 50, angle = 5, chance = 1, infront = true}, -- if there is another entry after, include a comma.
{sprite = "day/falling leaf0001", x = 100, y = 50, angle = 5, chance = 3, infront = true},
{sprite = "day/falling leaf0002", x = 100, y = 50, angle = 5, chance = 1, infront = true} -- if there is no entry after, don't include a comma.
}

cameramode = "stage" -- 'stage' or 'hud'. make your choice.

--no touchie
leafchances = {}
activeleaves = {}
uniqueleaf = 1
function onCreate()

	for i = 1, table.maxn(leaves) do
		for j = 1, leaves[i].chance do
			table.insert(leafchances, i)
		end
	end
	
	if allatonce then
		for i = 1, leaflimit do
			randomleaf = math.random(1, table.maxn(leafchances))
			if cameramode == "stage" then
				makeLuaSprite("leaf"..i, leaves[leafchances[randomleaf]].sprite, math.random(getProperty("camGame.scroll.x"),getProperty("camGame.scroll.x") + (1280 / getProperty("camGame.zoom"))), math.random(getProperty("camGame.scroll.y"),getProperty("camGame.scroll.y") + (720 / getProperty("camGame.zoom"))))
				setObjectCamera('leaf'..i,'game')
			else
				makeLuaSprite("leaf"..i, leaves[leafchances[randomleaf]].sprite, math.random(0,1280), math.random(0,720))
				setObjectCamera('leaf'..i,'hud')
			end
			setScrollFactor('leaf'.. i , 1, 1)
			addLuaSprite("leaf"..i, leaves[leafchances[randomleaf]].infront)
			setProperty("leaf"..i..".velocity.x", leaves[leafchances[randomleaf]].x + wind + math.random(-randomwind, randomwind))
			setProperty("leaf"..i..".velocity.y", leaves[leafchances[randomleaf]].y + gravity + math.random(-randomgravity, randomgravity))
			setProperty("leaf"..i..".angularVelocity", leaves[leafchances[randomleaf]].angle + spin + math.random(-randomspin, randomspin))
			table.insert(activeleaves, {sprite = "leaf"..i, indexreference = leafchances[randomleaf]})
		end
	else
		runTimer('dropleaf', math.random(mintimebetweenleaves, maxtimebetweenleaves), 1)
	end
	
	if debugscreen then
		makeLuaSprite("debug", leaves[1].sprite, math.random(0,1280), math.random(0,720))
		setObjectCamera('debug','game')
		setScrollFactor('debug', 1, 1)
		addLuaSprite("debug", true)
	end
end
debugscreen = false
function onUpdate(elapsed)
	if debugscreen then
		setProperty('debug.y', getProperty("camGame.scroll.y") + (-420 / getProperty("camGame.zoom")))
		debugPrint(getProperty("camGame.scroll.y") + (-420 / getProperty("camGame.zoom")))
	end
	
	for i = 1, table.maxn(activeleaves) do
		if cameramode == "stage" then
			--all other checks were removed so the leaves don't just "dissapear" the second they're offscreen.
			if getProperty(activeleaves[i].sprite .. ".y") > getProperty("camGame.scroll.y") + (720 / getProperty("camGame.zoom")) then
				if allatonce then
					setProperty(activeleaves[i].sprite .. ".y", getProperty("camGame.scroll.y") - getProperty(activeleaves[i].sprite .. ".height"))
				else
					removeLuaSprite(activeleaves[i].sprite, true)
					table.remove(activeleaves, i)
				end
			end
			-- i beg you just don't use negative gravity and it'll all be fine
		else
			if getProperty(activeleaves[i].sprite .. ".x") > 1280 then
				if allatonce then
					setProperty(activeleaves[i].sprite .. ".x", 0 - getProperty(activeleaves[i].sprite .. ".width"))
				else
					removeLuaSprite(activeleaves[i].sprite, true)
					table.remove(activeleaves, i)
				end
			end
			if getProperty(activeleaves[i].sprite .. ".x") < 0 - getProperty(activeleaves[i].sprite .. ".width") then
				if allatonce then
					setProperty(activeleaves[i].sprite .. ".x", 1280)
				else
					removeLuaSprite(activeleaves[i].sprite, true)
					table.remove(activeleaves, i)
				end
			end
			if getProperty(activeleaves[i].sprite .. ".y") > 720 then
				if allatonce then
					setProperty(activeleaves[i].sprite .. ".y", 0 - getProperty(activeleaves[i].sprite .. ".height"))
				else
					removeLuaSprite(activeleaves[i].sprite, true)
					table.remove(activeleaves, i)
				end
			end
			if getProperty(activeleaves[i].sprite .. ".y") < 0 - getProperty(activeleaves[i].sprite .. ".height") then
				if allatonce then
					setProperty(activeleaves[i].sprite .. ".y", 720)
				else
					removeLuaSprite(activeleaves[i].sprite, true)
					table.remove(activeleaves, i)
				end
			end
		end
	end
end

function onTimerCompleted(tag, loops, loopsLeft)
	if tag == "dropleaf" then
		for i = 1, math.random(minleavesperbatch, maxleavesperbatch) do
			if table.maxn(activeleaves) < leaflimit then
				randomleaf = math.random(1, table.maxn(leafchances))
				if cameramode == "stage" then
					makeLuaSprite("leaf"..uniqueleaf, leaves[leafchances[randomleaf]].sprite, math.random(getProperty("camGame.scroll.x"),getProperty("camGame.scroll.x") + (1280 / getProperty("camGame.zoom"))), getProperty("camGame.scroll.y")-420)
					setObjectCamera('leaf'..uniqueleaf,'game')
				else
					makeLuaSprite("leaf"..uniqueleaf, leaves[leafchances[randomleaf]].sprite, math.random(0,1280), -200)
					setObjectCamera('leaf'..uniqueleaf,'hud')
				end
				addLuaSprite("leaf"..uniqueleaf, leaves[leafchances[randomleaf]].infront)
				setScrollFactor('leaf'.. uniqueleaf , 1, 1)
				setProperty("leaf".. uniqueleaf ..".velocity.x", leaves[leafchances[randomleaf]].x + wind + math.random(0 - randomwind, randomwind))
				setProperty("leaf"..uniqueleaf..".velocity.y", leaves[leafchances[randomleaf]].y + gravity + math.random(0 - randomgravity, randomgravity))
				setProperty("leaf"..uniqueleaf..".angularVelocity", leaves[leafchances[randomleaf]].angle + spin + math.random(0 - randomspin, randomspin))
				table.insert(activeleaves, {sprite = "leaf"..uniqueleaf, indexreference = leafchances[randomleaf]})
				uniqueleaf = uniqueleaf + 1
			end
		end
		runTimer('dropleaf', math.random(mintimebetweenleaves, maxtimebetweenleaves), 1)
	end
end