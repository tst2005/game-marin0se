require("hook")
require("libs.tserial")
require("utils")
require("globals")
require("loveutils")
require("libs.cupid")
require("libs.filter")
--[[
	STEAL MY SHIT AND I'LL FUCK YOU UP
	PRETTY MUCH EVERYTHING BY MAURICE GUÉGAN AND IF SOMETHING ISN'T BY ME THEN IT SHOULD BE OBVIOUS OR NOBODY CARES

	Please keep in mind that for obvious reasons, I do not hold the rights to artwork, audio or trademarked elements of the game.
	This license only applies to the code and original other assets. Obviously. Duh.
	Anyway, enjoy.
	
	
	
	DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
              Version 2, December 2004

	Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

	Everyone is permitted to copy and distribute verbatim or modified
	copies of this license document, and changing it is allowed as long
	as the name is changed.

			DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
	TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

	0. You just DO WHAT THE FUCK YOU WANT TO.
]]
--[[distance models
	none: basically everything stays the same, always
	inverse: things get quieter as you move away
	linear: basically things just move around but never fade, you get the most dopple out of this
	exponent: like inverse, except happens quicker
	x clamped: gain gets clamped
]]
love.audio.setDistanceModel("exponent clamped")

function love.run()
	love.math.setRandomSeed(os.time())
	
	
    love.load(arg)

    -- Main loop time.
    while true do
        -- Process events.
		love.event.pump()
		for e,a,b,c,d in love.event.poll() do
			if e == "quit" then
				if not love.quit() then
					love.audio.stop()
					return
				end
			end
			love.handlers[e](a,b,c,d)
		end

        -- Update dt, as we'll be passing it to update
		love.timer.step()
		local dt = love.timer.getDelta()

        -- Call update and draw
        love.update(dt) -- will pass 0 if love.timer is disabled
		love.graphics.clear()
		love.graphics.origin()
		
		--Fullscreen hack
		if not mkstation and fullscreen and gamestate ~= "intro" then
			completecanvas:clear()
			love.graphics.setScissor()
			completecanvas:renderTo(love.draw)
			love.graphics.setScissor()
			if fullscreenmode == "full" then
				love.graphics.draw(completecanvas, 0, 0, 0, desktopsize.width/(width*16*scale), desktopsize.height/(height*16*scale))
			else
				love.graphics.draw(completecanvas, 0, touchfrominsidemissing/2, 0, touchfrominsidescaling/scale, touchfrominsidescaling/scale)
				love.graphics.setColor(0, 0, 0)
				love.graphics.rectangle("fill", 0, 0, desktopsize.width, touchfrominsidemissing/2)
				love.graphics.rectangle("fill", 0, desktopsize.height-touchfrominsidemissing/2, desktopsize.width, touchfrominsidemissing/2)
				love.graphics.setColor(255, 255, 255, 255)
			end
		else
			love.graphics.setScissor()
			love.draw()
		end
		
		love.graphics.present()
		love.timer.sleep(0.001)
    end
end

function add(desc)
	print((desc or "") .. "\n" .. round((love.timer.getTime()-starttime)*1000) .. "ms\tlines " .. lastline+1 .. " - " .. debug.getinfo(2).currentline-1 .. "\n")
	lastline = debug.getinfo(2).currentline
	totaltime = totaltime + round((love.timer.getTime()-starttime)*1000)
	starttime = love.timer.getTime()
end

function love.load(args)
	hook.Call("LovePreLoad", args)
	game = {}
	debugmode = "none"
	userectdebug = true
	args = args or {}
	for k,v in pairs(args) do
		if v=="-zbs" then
			-- debug features exclusive to zerobrane
			io.stdout:setvbuf("no")
			require("mobdebug").start()
		elseif v=="-debug" then
			skipintro = true
			uploadoncrash = true
			--DEBUG = false
			--editordebug = DEBUG
			--skiplevelscreen = DEBUG
			--debugbinds = DEBUG
			--debugclasses = false
			debugmode = args[k+1] or "none"
		end
	end
	hook.Add("GameConsoleOpened", "ConsoleDisableControls", function()
		if objects and objects["player"] and objects["player"][1] then
			objects["player"][1].controlsenabled = false
		end
	end)
	hook.Add("GameConsoleClosed", "ConsoleReEnableControls", function()
		--@WARNING: This might enable someone's controls at the wrong time, like when the game is paused.
		if objects and objects["player"] and objects["player"][1] then
			objects["player"][1].controlsenabled = false
		end
	end)
	expectedconnections = 2
	if debugmode=="client" or debugmode=="server" then
		uploadoncrash = false
		hook.Add("GameLoaded", "DebugImmediate", function()
			onlinemenu_load()
		end)
		hook.Add("GameOnlineMenuLoaded", "DebugImmediate", function()
			if debugmode=="server" then
				creategame()
				hook.Add("ServerClientConnected", "DebugImmediate", function()
					expectedconnections = expectedconnections - 1
					if expectedconnections==0 then
						server_start()
					end
				end)
			elseif debugmode=="client" then
				guielements.ipentry.value = "127.0.0.1"
				joingame()
			end
		end)
	end
	marioversion = 1107
	versionstring = "version 1.0se"
	
	--version check by checking for a const that was added in 0.8.0 --todo: change to 0.9.0
	if love._version_major == nil or (love._version_minor and love._version_minor < 9) then 
		versionerror = true
		error("You have an outdated version of Love! Get 0.9.0 and retry.") 
	end

	math.mod = math.fmod
	math.random = love.math.random
	-- I'm literally doing this just so the title load text gets shaken up.
	math.random()
	for i=1,math.random(5) do
		math.random()
	end
	
	print("Loading Mari0 SE!")
	print("=======================")
	lastline = debug.getinfo(1).currentline
	starttime = love.timer.getTime()
	totaltime = 0
	JSON = require("libs.JSON")
	require "timer"
	require "notice"
	
	--Get biggest screen size
	
	local sizes = love.window.getFullscreenModes()
	desktopsize = sizes[1]
	
	for i = 2, #sizes do
		if sizes[i].width > desktopsize.width or sizes[i].height > desktopsize.height then
			desktopsize = sizes[i]
		end
	end
	
	recordtarget = 1/40
	recordskip = 1
	recordframe = 1
	
	shaderlist = love.filesystem.getDirectoryItems( "shaders/" )
	local rem
	for i, v in pairs(shaderlist) do
		if v == "init.lua" then
			rem = i
		else
			shaderlist[i] = string.sub(v, 1, string.len(v)-5)
		end
	end
	
	table.remove(shaderlist, rem)
	table.insert(shaderlist, 1, "none")
	
	love.graphics.setDefaultFilter("nearest", "nearest")
	
	overwrittenimages = {}
	imagelist = {"coinblockanimation", "coinanimation", "coinblock", "coin", "axe", "spring", "springhigh", "toad", "peach", "platform", "oddjobhud", "redcoin", "redcointall", "redcoinbig", "firework",
	"platformbonus", "scaffold", "seesaw", "vine", "bowser", "decoys", "flag", "castleflag", "bubble", "emanceparticle", "emanceside", "doorpiece", "doorcenter", "pswitch",
	"button", "pushbutton", "wallindicator", "walltimer", "lightbridge", "lightbridgeglow", "lightbridgeside", "laser", "laserside", "excursionbase", "excursionfunnel", "excursionfunnel2", "excursionfunnelend", 
	"excursionfunnel2end", "faithplateplate", "laserdetector", "gel1", "gel2", "gel3", "gel4", "gel5", "gel6", "gel1ground", "gel2ground", "gel3ground", "gel4ground", "gel5ground", "gel6ground", "geldispenser", "cubedispenser", "panel", "pedestalbase", "cursorarea", 
	"pedestalgun", "actionblock", "portal", "markbase", "markoverlay", "andgate", "notgate", "orgate", "squarewave", "rsflipflop", "portalglow", "sfxentity", "animationtarget", "musicentity", "smbtiles", "portaltiles", "transparency", "smokepuff",
	"animatedtiletrigger", "delayer", "leaf", "groundlight"}
	
	graphicspacki = 1
	graphicspack = "DEFAULT"
	graphicspacklist = {}
	--@WARNING: This will be inaccurate for any mappacks that provide a namespaced graphicspack or potential mods.
	for k,v in pairs(love.filesystem.getDirectoryItems( "graphics" )) do
		if love.filesystem.isDirectory("graphics/"..v) and string.upper(v)==v then
			table.insert(graphicspacklist, v)
		end
	end
	
	soundpacki = 1
	soundpack = "DEFAULT"
	soundpacklist = {}
	--@WARNING: Same goes for me.
	for k,v in pairs(love.filesystem.getDirectoryItems( "sounds" )) do
		if love.filesystem.isDirectory("graphics/"..v) and string.upper(v)==v then
			table.insert(soundpacklist, v)
		end
	end
	
	add("Variables, shaderlist")
	
	local suc, err = pcall(loadconfig)
	if not suc then
		players = 1
		defaultconfig()
		print("== FAILED TO LOAD CONFIG ==")
		print(err)
	end
	
	--@DEBUG: here are some vars that are used elsewhere, maybe
	physicsdebug = false
	incognito = false
	portalwalldebug = false
	speeddebug = false
	
	frameskip = false -- false/0     true is not valid, so stop accidentally writing that.
	
	replaysystem = false
	drawreplays = false
	drawalllinks = false
	bdrawui = true
	skippedframes = 0
	
	width = 25	--! default 25
	height = 14
	fsaa = 0
	
	steptimer = 0
	targetdt = 1/60
	
	--Calculate relative scaling factor
	touchfrominsidescaling = math.min(desktopsize.width/(width*16), desktopsize.height/(height*16))
	touchfrominsidemissing = desktopsize.height-height*16*touchfrominsidescaling
	
	add("Variables")
	changescale(scale, true)
	add("Resolution change")
	require "characterloader"
	add("Characterloader")
	
	dlclist = {}
	
	hatcount = #love.filesystem.getDirectoryItems("graphics/standardhats")
	saveconfig()
	love.window.setTitle( "Marin0 SE" )
	
	love.graphics.setBackgroundColor(0, 0, 0)
	
	cursorareaquads = {}
	for i = 1, 4 do
		cursorareaquads[i] = love.graphics.newQuad((i-1)*18, 0, 18, 18, 72, 18)
	end
	
	--[[@DEV:
		I'm getting really tired of |nonstandard global containers| for entities, so
		to reduce the number of crazy all-over-the-place codepoints I'm creating an
		iterable whitelist of entities that adhere to a specific standard.
		Those being:
			* **being located in** _"/entities/classname.lua"_
			* **a classname that matches the filename, ex:** `classname = class:("classname")`
			* **a function creation signature of** `classname:init(x, y, r)`
				* if not placable in maps, then this isn't entirely necessary, but it helps
			* **having instances stored in the array** `objects["classname"]`
	]]
	saneents = {
		"sfxentity", "portalwall", "tile", "vine", "door", "button",
		"groundlight", "wallindicator", "animatedtiletrigger", "delayer",
		"walltimer", "notgate", "rsflipflop", "orgate", "andgate",
		"musicentity", "enemyspawner", "squarewave", "lightbridge",
		"faithplate", "laser", "noportal", "bulletbill", "animationtarget", 
		"portalprojectile", "portalprojectileparticle", "portalparticle",
		"laserdetector", "gel", "geldispenser", "pushbutton",
		"cubedispenser", "platform", "castlefire", "platformspawner",
		"bowser", "spring", "seesawplatform", "checkpoint", "seesaw",
		"ceilblocker", "funnel", "panel", "scaffold", "axe",
		"regiontrigger", "animationtrigger", "castlefirefire", "portalent",
		"portalent", "actionblock", "leaf", "enemy", "lightbridgebody", "weapon",
		"pedestal", "textentity", "firework", "emancipationgrill", "redcoin",
		"generatorwind", "generatorbullet", "generatorcheeps", "generatorflames",
		"pswitch", "smokepuff", "emancipateanimation", "userect"
	}
	-- we made weapon a saneent because tracing mario's draw is REALLY TOUGH
	-- testing removal of "fireball",
	
	--[[ here are a list of entities that have BROKEN THE LAW ]]
	insaneents = {
		"player", --discrepency in class names
		"warppipe", --this doesn't have any code, it's just a marker
		"spawn", --"  "
		"manycoins", --"  "
		"pipespawn", --"  "
		"axe", --"  "
		"flag", --"  "
		
		"mazestart", "mazeend", --doesn't have its own logic, is implicit and global
		"firestart", "fireend", --"  "
		"flyingfishstart", "flyingfishend", --"  "
		"bulletbillstart", "bulletbillend", --"  "
		"windstart", "windend", --"  "
		"lakitoend", --"  ", except it doesn't even have a start?!
		
		"gel", --this alters the map when loaded, which is an extreme anomoly
	}
	
	-- this is for global allocation of images + quads
	globalimages = {}
	--[[structure:{
			imagename = {
				dims = {xdim, ydim}, --size of a single graphic
				frames = num, --how many times dims fits in the image
				quads = {},
				img = imgdata,
			}
		}
		
		if errors ever arise in reference to this, it's because an entity
		is trying to reach this when its assets have been unloaded for mysterious reasons
	]]
	
	add("Variables")
	
	--require ALL the files!
	require("libs.lube")
	class = require("libs.middleclass")
	require("libs.neubind")
	nb = neubind:new(neuControlTable)
	TLbind = require("libs.TLbind")
	binds, controls = TLbind.giveInstance(controlTable)
	require("libs.monocle")
	Monocle.new({
		isActive=false,
		customPrinter=false,
		customColor = {0, 128, 0, 255},
		debugToggle = 'f1',
		filesToWatch = {}
	})
	--[[watchfunction = function()
		local str = "n/a"
		if activeeditortool then
			str=  ""
			for k,v in pairs(activeeditortool) do str=str..tostring(k).."="..tostring(v).."\n" end
		end
		return str
	end]]
	--Monocle.watch("misc", watchfunction)
	
	require("libs.von")
	--require "netplay2"
	require "netplay"
	--require "client"
	require "server"
	require "lobby"
	
	require "shaders"
	require "variables"
	
	-- gui elements??
	require "gui.onlinemenu"
	require "gui.killfeed"
	require "gui.nodetree"
	require "gui.maptree"
	require "gui.tiletree"
	
	reloadGraphics()
	reloadSounds()
	
	spritebatches = {} --global spritebatch array, keyed by tileset name
	
	fontglyphs = "0123456789abcdefghijklmnopqrstuvwxyz.:/,\"C-_A* !{}?'()+=><#%"
	fontquads = {}
	for i = 1, string.len(fontglyphs) do
		fontquads[string.sub(fontglyphs, i, i)] = love.graphics.newQuad((i-1)*8, 0, 8, 8, fontimage:getWidth(), fontimage:getHeight())
	end
	fontquadsback = {}
	for i = 1, string.len(fontglyphs) do
		fontquadsback[string.sub(fontglyphs, i, i)] = love.graphics.newQuad((i-1)*10, 0, 10, 10, fontimageback:getWidth(), fontimageback:getHeight())
	end
	
	-- injecting this here, I'm sorry
		love.graphics.clear()
		love.graphics.setColor(100, 100, 100)
		loadingtext = loadingtexts[math.random(1,#loadingtexts)]
		
		local logoscale = scale
		if logoscale <= 1 then
			logoscale = 0.5
		else
			logoscale = 1
		end
		
		love.graphics.setColor(255, 255, 255)
		
		love.graphics.draw(logo, love.graphics.getWidth()/2, love.graphics.getHeight()/2, 0, logoscale, logoscale, 142, 150)
		love.graphics.setColor(150, 150, 150)
		properprint(loading_header, love.graphics.getWidth()/2-string.len(loading_header)*4*scale, love.graphics.getHeight()/2-170*logoscale-7*scale)
		love.graphics.setColor(50, 50, 50)
		properprint(loadingtext, love.graphics.getWidth()/2-string.len(loadingtext)*4*scale, love.graphics.getHeight()/2+165*logoscale)
		love.graphics.present()
	-- whew, that's over with
	require("libs.sha1")
	require "magic"
	require "camera"
	require "baseentity"
	require "entity"
	
	local mixins = love.filesystem.getDirectoryItems("basedmixins")

	for k,v in pairs(mixins) do
		require("basedmixins."..v:sub(0,-5))
		
		-- precache all the images used by this entity type, eventually this will be dynamic
		--for k2,v2 in pairs(_G[basedents[k]].image_sigs) do
		--	allocate_image(k2, v2[1], v2[2])
		--end]]
	end
	
	-- basedents are used for the transition from saneents to entities that actually inherit and have some common ground
	-- this is very confusing and I'm sorry for that but it's what must be done
	basedents = love.filesystem.getDirectoryItems("basedents")

	for k,v in pairs(basedents) do
		basedents[k] = v:sub(0,-5)
		require("basedents."..basedents[k])
		
		-- precache all the images used by this entity type, eventually this will be dynamic
		--for k2,v2 in pairs(_G[basedents[k]].image_sigs) do
		--	allocate_image(k2, v2[1], v2[2])
		--end]]
	end
	
	
	
	-- we don't use the saneents list here because entity name weirdness 
	--for _,v in pairs(love.filesystem.getDirectoryItems("entities")) do
	for _,v in pairs(saneents) do
		-- we're doing sub because I forgot how not to \o/
		--require("entities."..v:sub(0, -5))
		require("entities."..v)
	end
	require("weapons.portalgun")
	require("weapons.gelcannon")
	
	require "animatedquad"
	require "intro"
	require "menu"
	require "levelscreen"
	require "game"
	require "editor"
	require "animationguiline"
	require "physics"
	require "quad"
	require "hatconfigs"
	require "bighatconfigs"
	require "customhats"
	require "coinblockanimation"
	require "screenboundary"
	require "gui"
	require "musicloader"
	require "rightclickmenu"
	require "animation"
	require "animationsystem"
	require "regiondrag"
	require "animatedtimer"
	require "entitylistitem"
	require "entitytooltip"
	require "imgurupload"
	
	require "player"
	require "fire"
	require "portal"
	require "dialogbox"
	require "itemanimation"
	
	require "enemies"
	add("Requires")
	
	http = require("socket.http")
	http.PORT = 55555
	http.TIMEOUT = 1
	
	updatenotification = false
	if getupdate() then
		updatenotification = true
	end
	http.TIMEOUT = 4
	
	playertypei = 1
	playertype = playertypelist[playertypei] --portal, gelcannon
	
	if volume == 0 then
		soundenabled = false
	else
		soundenabled = true
	end
	love.filesystem.createDirectory( "mappacks" )
	editormode = false
	yoffset = 0
	love.graphics.setPointSize(3*scale)
	love.graphics.setLineWidth(2*scale)
	
	uispace = math.floor(width*16*scale/4)
	guielements = {}
	
	--limit hats
	for playerno = 1, players do
		for i = 1, #mariohats[playerno] do
			if mariohats[playerno][i] > hatcount then
				mariohats[playerno][i] = hatcount
			end
		end
	end
	
	--Backgroundcolors
	backgroundcolor = {
						{92, 148, 252},
						{0, 0, 0},
						{32, 56, 236},
						{158, 219, 248},
						{210, 159, 229},
						{237, 241, 243},
						{244, 178, 92},
						{253, 246, 175},
						{249, 183, 206},
					}
	add("Update Check, variables")
	
	--tiles
	tilequads = {}
	rgblist = {}
	
	--add smb tiles
	local imgwidth, imgheight = smbtilesimg:getWidth(), smbtilesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata = love.image.newImageData("smbtiles.png")
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads, quad:new(smbtilesimg, imgdata, x, y, imgwidth, imgheight))
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r, g, b})
		end
	end
	smbtilecount = width*height
	
	--add portal tiles
	local imgwidth, imgheight = portaltilesimg:getWidth(), portaltilesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata = love.image.newImageData("portaltiles.png")
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads, quad:new(portaltilesimg, imgdata, x, y, imgwidth, imgheight))
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r, g, b})
		end
	end
	portaltilecount = width*height
	
	--add entities
	entityquads = {}
	local imgwidth, imgheight = entitiesimg:getWidth(), entitiesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata = love.image.newImageData("/guihud/entities.png")
	
	for y = 1, height do
		for x = 1, width do
			table.insert(entityquads, entity:new(entitiesimg, x, y, imgwidth, imgheight))
			entityquads[#entityquads]:sett(#entityquads)
		end
	end
	entitiescount = width*height
	
	-- overload table because we can't change the timing of the above
	for k,v in pairs(entityquad_overloads) do
		entityquads[k] = v
	end
	
	numberglyphs = "0123456789"
	font2quads = {}
	for i = 1, 10 do
		font2quads[string.sub(numberglyphs, i, i)] = love.graphics.newQuad((i-1)*4, 0, 4, 8, 40, 8)
	end

	symbolglyphs = "0123"
	font3quads = {}
	for i = 1, 4 do
		font3quads[string.sub(symbolglyphs, i, i)] = love.graphics.newQuad((i-1)*4, 0, 4, 8, 40, 8)
	end
	
	popupfontquads = {}
	for i = 1, 6 do
		popupfontquads[i] = love.graphics.newQuad((i-1)*16, 0, 16, 8, 96, 8)
	end

	fireworkquads = {}
	for i = 1, 4 do
		fireworkquads[i] = love.graphics.newQuad((i-1)*32, 0, 32, 32, 128, 32)
	end
	
	oddjobhudquads = {}
	for i = 1, 5 do
		oddjobhudquads[i] = love.graphics.newQuad((i-1)*8, 0, 8, 8, 40, 8)
	end
	
	coinblockanimationquads = {}
	for i = 1, 30 do
		coinblockanimationquads[i] = love.graphics.newQuad((i-1)*8, 0, 8, 52, 256, 64)
	end
	
	coinanimationquads = {}
	for j = 1, 4 do
		coinanimationquads[j] = {}
		for i = 1, 5 do
			coinanimationquads[j][i] = love.graphics.newQuad((i-1)*5, (j-1)*8, 5, 8, 25, 32)
		end
	end
	
	--coinblock
	coinblockquads = {}
	for j = 1, 4 do
		coinblockquads[j] = {}
		for i = 1, 5 do
			coinblockquads[j][i] = love.graphics.newQuad((i-1)*16, (j-1)*16, 16, 16, 80, 64)
		end
	end
	
	--coin
	coinquads = {}
	for j = 1, 4 do
		coinquads[j] = {}
		for i = 1, 5 do
			coinquads[j][i] = love.graphics.newQuad((i-1)*16, (j-1)*16, 16, 16, 80, 64)
		end
	end

	--redcoin
	redcoinquads = {}
	for i = 1, 4 do
		redcoinquads[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 64, 16)
	end	
	
	redcointallquads = {}
	for i = 1, 4 do
		redcointallquads[i] = love.graphics.newQuad((i-1)*16, 0, 16, 32, 64, 32)
	end	
	
	redcoinbigquads = {}
	for i = 1, 4 do
		redcoinbigquads[i] = love.graphics.newQuad((i-1)*32, 0, 32, 32, 128, 32)
	end	
	
	--smoke puff
	smokepuffquads = {}
	for i = 1, 4 do
		smokepuffquads[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 64, 16)
	end	
	
	--leaf
	leafquad = {}
	for y = 1, 4 do
		leafquad[y] = {}
		for x = 1, 2 do
			leafquad[y][x] = love.graphics.newQuad((x-1)*8, (y-1)*8, 8, 8, 16, 32)
		end
	end
	
	--axe
	axequads = {}
	for i = 1, 5 do
		axequads[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 80, 16)
	end
	
	--spring
	springquads = {}
	for i = 1, 4 do
		springquads[i] = {}
		for j = 1, 3 do
			springquads[i][j] = love.graphics.newQuad((j-1)*16, (i-1)*32, 16, 32, 48, 128)
		end
	end
	
	-- pswitch
	pswitchquads = {}
	for i = 1, 2 do
		pswitchquads[i] = {}
		for j = 1, 4 do
			pswitchquads[i][j] = love.graphics.newQuad((j-1)*16, (i-1)*16, 16, 16, 64, 32)
		end	
	end
	
	seesawquad = {}
	for i = 1, 4 do
		seesawquad[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 64, 16)
	end
	
	starquad = {}
	for i = 1, 4 do
		starquad[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 64, 16)
	end
	
	flowerquad = {}
	for i = 1, 4 do
		flowerquad[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 64, 16)
	end
	
	vinequad = {}
	for i = 1, 4 do
		vinequad[i] = {}
		for j = 1, 2 do
			vinequad[i][j] = love.graphics.newQuad((j-1)*16, (i-1)*16, 16, 16, 32, 64) 
		end
	end
	
	--enemies
	goombaquad = {}
	
	for y = 1, 4 do
		goombaquad[y] = {}
		for x = 1, 2 do
			goombaquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*16, 16, 16, 32, 64)
		end
	end
		
	spikeyquad = {}
	for y = 1, 4 do
		spikeyquad[y] = {}
		for x = 1, 4 do
			spikeyquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*16, 16, 16, 64, 64)
		end
	end
	
	lakitoquad = {}
	for y = 1, 4 do
		lakitoquad[y] = {}
		for x = 1, 2 do
			lakitoquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*24, 16, 24, 32, 96)
		end
	end
	
	koopaquad = {}
	
	for y = 1, 4 do
		koopaquad[y] = {}
		for x = 1, 5 do
			koopaquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*24, 16, 24, 80, 96)
		end
	end
	
	singlequad = love.graphics.newQuad(0, 0, 16, 16, 16, 16)
	
	cheepcheepquad = {}
	
	cheepcheepquad[1] = {}
	cheepcheepquad[1][1] = love.graphics.newQuad(0, 0, 16, 16, 32, 32)
	cheepcheepquad[1][2] = love.graphics.newQuad(16, 0, 16, 16, 32, 32)
	
	cheepcheepquad[2] = {}
	cheepcheepquad[2][1] = love.graphics.newQuad(0, 16, 16, 16, 32, 32)
	cheepcheepquad[2][2] = love.graphics.newQuad(16, 16, 16, 16, 32, 32)
	
	squidquad = {}
	for x = 1, 2 do
		squidquad[x] = love.graphics.newQuad((x-1)*16, 0, 16, 24, 32, 24)
	end
	
	bulletbillquad = {}
	
	for y = 1, 4 do
		bulletbillquad[y] = love.graphics.newQuad(0, (y-1)*16, 16, 16, 16, 64)
	end
	
	hammerbrosquad = {}
	for y = 1, 4 do
		hammerbrosquad[y] = {}
		for x = 1, 4 do
			hammerbrosquad[y][x] = love.graphics.newQuad((x-1)*16, (y-1)*34, 16, 34, 64, 136)
		end
	end	
	
	hammerquad = {}
	for j = 1, 4 do
		hammerquad[j] = {}
		for i = 1, 4 do
			hammerquad[j][i] = love.graphics.newQuad((i-1)*16, (j-1)*16, 16, 16, 64, 64)
		end
	end
	
	plantquads = {}
	for j = 1, 4 do
		plantquads[j] = {}
		for i = 1, 2 do
			plantquads[j][i] = love.graphics.newQuad((i-1)*16, (j-1)*23, 16, 23, 32, 92)
		end
	end
	
	firequad = {love.graphics.newQuad(0, 0, 24, 8, 48, 8), love.graphics.newQuad(24, 0, 24, 8, 48, 8)}
	
	
	bowserquad = {}
	bowserquad[1] = {love.graphics.newQuad(0, 0, 32, 32, 64, 64), love.graphics.newQuad(32, 0, 32, 32, 64, 64)}
	bowserquad[2] = {love.graphics.newQuad(0, 32, 32, 32, 64, 64), love.graphics.newQuad(32, 32, 32, 32, 64, 64)}
	
	decoysquad = {}
	for y = 1, 7 do
		decoysquad[y] = love.graphics.newQuad(0, (y-1)*32, 32, 32, 64, 256)
	end
	
	--magic!
	magicquad = {}
	for x = 1, 6 do
		magicquad[x] = love.graphics.newQuad((x-1)*9, 0, 9, 9, 54, 9)
	end
	
	--GUI
	checkboxquad = {{love.graphics.newQuad(0, 0, 9, 9, 18, 18), love.graphics.newQuad(9, 0, 9, 9, 18, 18)}, {love.graphics.newQuad(0, 9, 9, 9, 18, 18), love.graphics.newQuad(9, 9, 9, 9, 18, 18)}}
	
	--portals
	portalquad = {}
	for i = 0, 7 do
		portalquad[i] = love.graphics.newQuad(0, i*4, 32, 4, 32, 28)
	end
	
	--Portal props	
	buttonquad = {love.graphics.newQuad(0, 0, 32, 5, 64, 5), love.graphics.newQuad(32, 0, 32, 5, 64, 5)}
	
	pushbuttonquad = {love.graphics.newQuad(0, 0, 16, 16, 32, 16), love.graphics.newQuad(16, 0, 16, 16, 32, 16)}
	
	wallindicatorquad = {love.graphics.newQuad(0, 0, 16, 16, 32, 16), love.graphics.newQuad(16, 0, 16, 16, 32, 16)}
	
	walltimerquad = {}
	for i = 1, 10 do
		walltimerquad[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 160, 16)
	end
	
	groundlightquad = {}
	for i = 1, 6 do
		groundlightquad[i] = love.graphics.newQuad((i-1)*16, 0, 16, 16, 96, 16)
	end
	
	directionsquad = {}
	for x = 1, 6 do
		directionsquad[x] = love.graphics.newQuad((x-1)*7, 0, 7, 7, 42, 7)
	end
	
	excursionquad = {}
	for x = 1, 8 do
		excursionquad[x] = love.graphics.newQuad((x-1)*8, 0, 8, 32, 64, 32)
	end
	
	faithplatequad = {love.graphics.newQuad(0, 0, 32, 16, 32, 32), love.graphics.newQuad(0, 16, 32, 16, 32, 32)}
	
	gelquad = {love.graphics.newQuad(0, 0, 12, 12, 36, 12), love.graphics.newQuad(12, 0, 12, 12, 36, 12), love.graphics.newQuad(24, 0, 12, 12, 36, 12)}
	
	panelquad = {}
	for x = 1, 2 do
		panelquad[x] = love.graphics.newQuad((x-1)*16, 0, 16, 16, 32, 16)
	end
	
	add("Images, quads")
	
	--AUDIO
	delaylist = {}
	delaylist["blockhit"] = 0.2
	
	musicname = "overworld.ogg"
	
	add("Sounds")
	shaders:init()
	add("Shaders init")
	
	for i, v in pairs(dlclist) do
		delete_mappack(v)
	end
	
	firstload = true
	
	--@DEV: Copied this over, too. Probably making a mess.
	magicdns_session_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	magicdns_session = ""
	for i = 1, 8 do
		rand = math.random(string.len(magicdns_session_chars))
		magicdns_session = magicdns_session .. string.sub(magicdns_session_chars, rand, rand)
	end
	--use love.filesystem.getIdentity() when it works
	magicdns_identity = love.filesystem.getSaveDirectory():split("/")
	magicdns_identity = string.upper(magicdns_identity[#magicdns_identity])
	
	add("Intro Load")
	print("TOTAL: " .. totaltime .. "ms")
	
	mycamera = camera:new()
	mycamera:zoomTo(0.4)
	
	skipintro=true
	if skipintro then
		menu_load()
	else
		intro_load()
	end
	
	hook.Call("LovePostLoad", args)
end

function love.update(dt)
	hook.Call("LovePreUpdate", dt)
	if music then
		music:update()
	end
	timer.Update(dt)
	Monocle.update()
	nb:update(dt)
	TLbind:update()
	binds:update()
	controlsUpdate(dt)
	realdt = dt
	dt = math.min(0.5, dt) --ignore any dt higher than half a second
	
	if recording then
		dt = recordtarget
	end
	
	steptimer = steptimer + dt
	dt = targetdt
	
	if skipupdate then
		steptimer = 0
		skipupdate = false
		return
	end
	
	--speed
	if bullettime and speed ~= speedtarget then
		if speed > speedtarget then
			speed = math.max(speedtarget, speed+(speedtarget-speed)*dt*5)
		elseif speed < speedtarget then
			speed = math.min(speedtarget, speed+(speedtarget-speed)*dt*5)
		end
		
		if math.abs(speed-speedtarget) < 0.02 then
			speed = speedtarget
		end
		
		if speed > 0 then
			for i, v in pairs(soundlist) do
				v.source:setPitch( speed )
			end
			music.pitch = speed
			love.audio.setVolume(volume)
		else	
			love.audio.setVolume(0)
		end
	end
	
	while steptimer >= targetdt do
		steptimer = steptimer - targetdt
		
		if frameskip then
			if frameskip > skippedframes then
				skippedframes = skippedframes + 1
				return
			else
				skippedframes = 0
			end
		end
		
		keyprompt_update()
		
		if gamestate == "menu" or gamestate == "mappackmenu" or gamestate == "onlinemenu" or gamestate == "options" or gamestate == "lobby" then
			menu_update(dt)
		elseif gamestate == "levelscreen" or gamestate == "gameover" or gamestate == "sublevelscreen" or gamestate == "mappackfinished" then
			levelscreen_update(dt)
		elseif gamestate == "game" then
			game_update(dt)	
		elseif gamestate == "intro" then
			intro_update(dt)	
		end
		if onlinemp then
			if clientisnetworkhost then
				server_update(dt)
			end
			network_update(dt)
		end
		
		for i, v in pairs(guielements) do
			v:update(dt)
		end
		
		--netplay_update(dt)
		
		notice.update(dt)
		killfeed.update(dt)
		
		love.window.setTitle("NCN:"..networkclientnumber.."; FPS:" .. love.timer.getFPS())
	end
	hook.Call("LovePostUpdate", dt)
end

function love.draw()
	hook.Call("LovePreDraw")
	shaders:predraw()
	
	--mycamera:attach()
	if gamestate == "menu" or gamestate == "mappackmenu" or gamestate == "onlinemenu" or gamestate == "options" or gamestate == "lobby" then
		menu_draw()
	elseif gamestate == "levelscreen" or gamestate == "gameover" or gamestate == "mappackfinished" then
		levelscreen_draw()
	elseif gamestate == "game" then
		game_draw()
	elseif gamestate == "intro" then
		intro_draw()
	end
	
	notice.draw()
	killfeed.draw()
	
	--mycamera:detach()
	
	shaders:postdraw()
		
	love.graphics.setColor(255, 255,255)
	
	if recording then
		screenshotimagedata = love.graphics.newScreenshot( )
		screenshotimagedata:encode("recording/" .. recordframe .. ".png")
		recordframe = recordframe + 1
		screenshotimagedata = nil
		
		if recordframe%100 == 0 then
			collectgarbage("collect")
		end
	end
	Monocle.draw()
	hook.Call("LovePostDraw")
end

function saveconfig()
	if CLIENT or SERVER then
		return
	end
	
	local s = ""
	for i = 1, #oldcontrols do
		s = s .. "playercontrols:" .. i .. ":"
		local count = 0
		for j, k in pairs(oldcontrols[i]) do
			local c = ""
			for l = 1, #oldcontrols[i][j] do
				c = c .. oldcontrols[i][j][l]
				if l ~= #oldcontrols[i][j] then
					c = c ..  "-"
				end
			end
			s = s .. j .. "-" .. c
			count = count + 1
			if count == 12 then
				s = s .. ";"
			else
				s = s .. ","
			end
		end
	end	
	
	for i = 1, #mariocolors do --players
		s = s .. "playercolors:" .. i .. ":"
		if #mariocolors[i] > 0 then
			for j = 1, #mariocolors[i] do --colorsets (dynamic)
				for k = 1, 3 do --R, G or B values
					s = s .. mariocolors[i][j][k]
					if j == #mariocolors[i] and k == 3 then
						s = s .. ";"
					else
						s = s .. ","
					end
				end
			end
		else
			s = s .. ";"
		end
	end
	
	for i = 1, #mariocharacter do
		s = s .. "mariocharacter:" .. i .. ":"
		s = s .. mariocharacter[i]
		s = s .. ";"
	end
	
	for i = 1, #portalhues do
		s = s .. "portalhues:" .. i .. ":"
		s = s .. round(portalhues[i][1], 4) .. "," .. round(portalhues[i][2], 4) .. ";"
	end
	
	for i = 1, #mariohats do
		s = s .. "mariohats:" .. i
		if #mariohats[i] > 0 then
			s = s .. ":"
		end
		for j = 1, #mariohats[i] do
			s = s .. mariohats[i][j]
			if j == #mariohats[i] then
				s = s .. ";"
			else
				s = s .. ","
			end
		end
		
		if #mariohats[i] == 0 then
			s = s .. ";"
		end
	end
	
	s = s .. "scale:" .. scale .. ";"
	
	s = s .. "shader1:" .. shaderlist[currentshaderi1] .. ";"
	s = s .. "shader2:" .. shaderlist[currentshaderi2] .. ";"
	
	s = s .. "graphicspack:" .. graphicspacklist[graphicspacki] .. ";"
	s = s .. "soundpack:" .. soundpacklist[soundpacki] .. ";"
	
	s = s .. "volume:" .. volume .. ";"
	s = s .. "mouseowner:" .. mouseowner .. ";"
	
	s = s .. "mappack:" .. mappack .. ";"
	
	if vsync then
		s = s .. "vsync;"
	end
	
	if gamefinished then
		s = s .. "gamefinished;"
	end
	
	s = s .. "fullscreen:" .. tostring(fullscreen) .. ";"
	s = s .. "fullscreenmode:" .. fullscreenmode .. ";"
	
	--reached worlds
	for i, v in pairs(reachedworlds) do
		s = s .. "reachedworlds:" .. i .. ":"
		for j = 1, 8 do
			if v[j] then
				s = s .. 1
			else
				s = s .. 0
			end
			
			if j == 8 then
				s = s .. ";"
			else
				s = s .. ","
			end
		end
	end
	
	love.filesystem.write("options.txt", s)
end

function loadconfig()
	players = 1
	defaultconfig()
	
	if not love.filesystem.exists("options.txt") then
		return
	end
	
	local s = love.filesystem.read("options.txt")
	s1 = s:split(";")
	
	for i = 1, #s1-1 do
		s2 = s1[i]:split(":")
		if s2[1] == "playercontrols" then
			if oldcontrols[tonumber(s2[2])] == nil then
				oldcontrols[tonumber(s2[2])] = {}
			end
			
			s3 = s2[3]:split(",")
			for j = 1, #s3 do
				s4 = s3[j]:split("-")
				oldcontrols[tonumber(s2[2])][s4[1]] = {}
				for k = 2, #s4 do
					if tonumber(s4[k]) ~= nil then
						oldcontrols[tonumber(s2[2])][s4[1]][k-1] = tonumber(s4[k])
					else
						oldcontrols[tonumber(s2[2])][s4[1]][k-1] = s4[k]
					end
				end
			end
			players = math.max(players, tonumber(s2[2]))
			
		elseif s2[1] == "playercolors" then
			if mariocolors[tonumber(s2[2])] == nil then
				mariocolors[tonumber(s2[2])] = {}
			end
			s3 = s2[3]:split(",")
			mariocolors[tonumber(s2[2])] = {}
			for i = 1, #s3/3 do
				mariocolors[tonumber(s2[2])][i] = {tonumber(s3[1+(i-1)*3]), tonumber(s3[2+(i-1)*3]), tonumber(s3[3+(i-1)*3])}
			end
		elseif s2[1] == "portalhues" then
			if portalhues[tonumber(s2[2])] == nil then
				portalhues[tonumber(s2[2])] = {}
			end
			s3 = s2[3]:split(",")
			portalhues[tonumber(s2[2])] = {tonumber(s3[1]), tonumber(s3[2])}
		
		elseif s2[1] == "mariohats" then
			local playerno = tonumber(s2[2])
			mariohats[playerno] = {}
			
			if s2[3] == "mariohats" then --SAVING WENT WRONG OMG
			
			elseif s2[3] then
				s3 = s2[3]:split(",")
				for i = 1, #s3 do
					local hatno = tonumber(s3[i])
					mariohats[playerno][i] = hatno
				end
			end
			
		elseif s2[1] == "scale" then
			scale = tonumber(s2[2])
			
		elseif s2[1] == "shader1" then
			for i = 1, #shaderlist do
				if shaderlist[i] == s2[2] then
					currentshaderi1 = i
				end
			end
		elseif s2[1] == "shader2" then
			for i = 1, #shaderlist do
				if shaderlist[i] == s2[2] then
					currentshaderi2 = i
				end
			end
		elseif s2[1] == "graphicspack" then
			for i = 1, #graphicspacklist do
				if graphicspacklist[i] == s2[2] then
					graphicspacki = i
					graphicspack = s2[2]
				end
			end
		elseif s2[1] == "soundpack" then
			for i = 1, #soundpacklist do
				if soundpacklist[i] == s2[2] then
					soundpacki = i
					soundpack = s2[2]
				end
			end
		elseif s2[1] == "volume" then
			volume = tonumber(s2[2])
			love.audio.setVolume( volume )
		elseif s2[1] == "mouseowner" then
			mouseowner = tonumber(s2[2])
		elseif s2[1] == "mappack" then
			if love.filesystem.exists("mappacks/" .. s2[2] .. "/settings.txt") then
				mappack = s2[2]
			end
		elseif s2[1] == "gamefinished" then
			gamefinished = true
		elseif s2[1] == "vsync" then
			vsync = true
		elseif s2[1] == "reachedworlds" then
			reachedworlds[s2[2]] = {}
			local s3 = s2[3]:split(",")
			for i = 1, #s3 do
				if tonumber(s3[i]) == 1 then
					reachedworlds[s2[2]][i] = true
				end
			end
		elseif s2[1] == "mariocharacter" then
			mariocharacter[tonumber(s2[2])] = s2[3]
		elseif s2[1] == "fullscreen" then
			fullscreen = s2[2] == "true"
		elseif s2[1] == "fullscreenmode" then
			fullscreenmode = s2[2]
		end
	end
	
	for i = 1, math.max(4, players) do
		portalcolor[i] = {getrainbowcolor(portalhues[i][1]), getrainbowcolor(portalhues[i][2])}
	end
	
	players = 1
end

function defaultconfig()
	--------------
	-- CONTORLS --
	--------------
	
	-- Joystick stuff:
	-- joy, #, hat, #, direction (r, u, ru, etc)
	-- joy, #, axe, #, pos/neg
	-- joy, #, but, #
	-- You cannot set Hats and Axes as the jump button. Bummer.
	
	mouseowner = 1
	
	oldcontrols = {}
	
	local i = 1
	oldcontrols[i] = {}
	oldcontrols[i]["right"] = {"d"}
	oldcontrols[i]["left"] = {"a"}
	oldcontrols[i]["down"] = {"s"}
	oldcontrols[i]["up"] = {"w"}
	oldcontrols[i]["run"] = {"lshift"}
	oldcontrols[i]["jump"] = {" "}
	oldcontrols[i]["aimx"] = {""} --mouse aiming, so no need
	oldcontrols[i]["aimy"] = {""}
	oldcontrols[i]["portal1"] = {""}
	oldcontrols[i]["portal2"] = {""}
	oldcontrols[i]["reload"] = {"r"}
	oldcontrols[i]["use"] = {"e"}
	
	for i = 2, 4 do
		oldcontrols[i] = {}		
		oldcontrols[i]["right"] = {"joy", i-1, "hat", 1, "r"}
		oldcontrols[i]["left"] = {"joy", i-1, "hat", 1, "l"}
		oldcontrols[i]["down"] = {"joy", i-1, "hat", 1, "d"}
		oldcontrols[i]["up"] = {"joy", i-1, "hat", 1, "u"}
		oldcontrols[i]["run"] = {"joy", i-1, "but", 3}
		oldcontrols[i]["jump"] = {"joy", i-1, "but", 1}
		oldcontrols[i]["aimx"] = {"joy", i-1, "axe", 5, "neg"}
		oldcontrols[i]["aimy"] = {"joy", i-1, "axe", 4, "neg"}
		oldcontrols[i]["portal1"] = {"joy", i-1, "but", 5}
		oldcontrols[i]["portal2"] = {"joy", i-1, "but", 6}
		oldcontrols[i]["reload"] = {"joy", i-1, "but", 4}
		oldcontrols[i]["use"] = {"joy", i-1, "but", 2}
	end
	-------------------
	-- PORTAL COLORS --
	-------------------
	
	portalhues = {}
	portalcolor = {}
	for i = 1, 4 do
		local players = 4
		portalhues[i] = {(i-1)*(1/players), (i-1)*(1/players)+0.5/players}
		portalcolor[i] = {getrainbowcolor(portalhues[i][1]), getrainbowcolor(portalhues[i][2])}
	end
	
	--hats.
	mariohats = {}
	for i = 1, 4 do
		mariohats[i] = {1}
	end
	
	------------------
	-- MARIO COLORS --
	------------------
	--1: hat, pants (red)
	--2: shirt, shoes (brown-green)
	--3: skin (yellow-orange)
	
	mariocolors = {}
	mariocolors[1] = {{224,  32,   0}, {136, 112,   0}, {252, 152,  56}}
	mariocolors[2] = {{255, 255, 255}, {  0, 160,   0}, {252, 152,  56}}
	mariocolors[3] = {{  0,   0,   0}, {200,  76,  12}, {252, 188, 176}}
	mariocolors[4] = {{ 32,  56, 236}, {  0, 128, 136}, {252, 152,  56}}
	for i = 5, players do
		mariocolors[i] = mariocolors[math.random(4)]
	end
	
	--STARCOLORS
	starcolors = {}
	starcolors[1] = {{  0,   0,   0}, {200,  76,  12}, {252, 188, 176}}
	starcolors[2] = {{  0, 168,   0}, {252, 152,  56}, {252, 252, 252}}
	starcolors[3] = {{252, 216, 168}, {216,  40,   0}, {252, 152,  56}}
	starcolors[4] = {{216,  40,   0}, {252, 152,  56}, {252, 252, 252}}
	
	flowercolor = {{252, 216, 168}, {216,  40,   0}, {252, 152,  56}}
	
	--CHARACTERS
	mariocharacter = {"mario", "mario", "mario", "mario"}
	
	--options
	scale = 2
	volume = 1
	mappack = "smb"
	vsync = false
	currentshaderi1 = 1
	currentshaderi2 = 1
	graphicspacki = 1
	graphicspack = "DEFAULT"
	soundpacki = 1
	soundpack = "DEFAULT"
	firstpersonview = false
	firstpersonrotate = false
	seethroughportals = false
	fullscreen = false
	fullscreenmode = "letterbox"
	
	reachedworlds = {}
end

function loadcustomimages(path)
	for i = 1, #overwrittenimages do
		local s = overwrittenimages[i]
		_G[s .. "img"] = _G["default" .. s .. "img"]
	end
	overwrittenimages = {}

	local fl = love.filesystem.getDirectoryItems(path)
	for i = 1, #fl do
		local v = fl[i]
		if love.filesystem.isFile(path .. "/" .. v) then
			local s = string.sub(v, 1, -5)
			if table.contains(imagelist, s) then
				_G[s .. "img"] = love.graphics.newImage(path .. "/" .. v)
				table.insert(overwrittenimages, s)
			end
		end
	end
	
	--tiles
	tilequads = {}
	rgblist = {}
	
	--add smb tiles
	local imgwidth, imgheight = smbtilesimg:getWidth(), smbtilesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata
	if love.filesystem.isFile(path .. "/smbtiles.png") then
		imgdata = love.image.newImageData(path .. "/smbtiles.png")
	else
		imgdata = love.image.newImageData("graphics/DEFAULT/smbtiles.png")
	end
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads, quad:new(smbtilesimg, imgdata, x, y, imgwidth, imgheight))
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r, g, b})
		end
	end
	smbtilecount = width*height
	
	--add portal tiles
	local imgwidth, imgheight = portaltilesimg:getWidth(), portaltilesimg:getHeight()
	local width = math.floor(imgwidth/17)
	local height = math.floor(imgheight/17)
	local imgdata
	if love.filesystem.isFile(path .. "/portaltiles.png") then
		imgdata = love.image.newImageData(path .. "/portaltiles.png")
	else
		imgdata = love.image.newImageData("graphics/DEFAULT/portaltiles.png")
	end
	
	for y = 1, height do
		for x = 1, width do
			table.insert(tilequads, quad:new(portaltilesimg, imgdata, x, y, imgwidth, imgheight))
			local r, g, b = getaveragecolor(imgdata, x, y)
			table.insert(rgblist, {r, g, b})
		end
	end
	portaltilecount = width*height
end

--[[function suspendgame()
	local s = ""
	if marioworld == "M" then
		marioworld = 1
		mariolevel = 3
	end
	s = s .. "a/" .. marioworld .. "|"
	s = s .. "b/" .. mariolevel .. "|"
	s = s .. "c/" .. mariocoincount .. "|"
	s = s .. "d/" .. marioscore .. "|"
	s = s .. "e/" .. players .. "|"
	for i = 1, players do
		if mariolivecount ~= false then
			s = s .. "f/" .. i .. "/" .. mariolives[i] .. "|"
		end
		if objects["player"][i] then
			s = s .. "g/" .. i .. "/" .. objects["player"][i].size .. "|"
		else
			s = s .. "g/" .. i .."/1|"
		end
	end
	s = s .. "h/" .. mappack
	
	love.filesystem.write("suspend.txt", s)
	
	love.audio.stop()
	menu_load()
end]]

--[[function continuegame()
	if not love.filesystem.exists("suspend.txt") then
		return
	end
	
	local s = love.filesystem.read("suspend.txt")
	
	mariosizes = {}
	mariolives = {}
	
	local split = s:split("|")
	--@TODO: Gotta make room for currentmap = "1-1" in the save.
	for i = 1, #split do
		local split2 = split[i]:split("/")
		if split2[1] == "a" then
			marioworld = tonumber(split2[2])
		elseif split2[1] == "b" then
			mariolevel = tonumber(split2[2])
		elseif split2[1] == "c" then
			mariocoincount = tonumber(split2[2])
		elseif split2[1] == "d" then
			marioscore = tonumber(split2[2])
		elseif split2[1] == "e" then
			players = tonumber(split2[2])
		elseif split2[1] == "f" and mariolivecount ~= false then
			mariolives[tonumber(split2[2])] = tonumber(split2[3])
		elseif split2[1] == "g" then
			mariosizes[tonumber(split2[2])] = tonumber(split2[3])
		elseif split2[1] == "h" then
			mappack = split2[2]
		end
	end
	
	love.filesystem.remove("suspend.txt")
end]]

function changescale(s, init)
	scale = s
	
	if not init then
		if width*16*scale > desktopsize.width then
			if fullscreen and fullscreenmode == "full" then
				scale = scale - 1
				return
			end
			
			if fullscreen and fullscreenmode == "touchfrominside" then
				fullscreenmode = "full"
				scale = scale - 1
				return
			end
			
			if love.graphics.isSupported("canvas") then
				fullscreen = true
			end
			
			scale = scale - 1
			fullscreenmode = "touchfrominside"
			
		elseif fullscreen then
			if fullscreenmode == "full" then
				fullscreenmode = "touchfrominside"
				scale = scale + 1
				return
			else
				fullscreen = false
			end
			scale = scale + 1
			fullscreenmode = "full"
			
		end
	end
	
	if fullscreen then
		love.window.setMode(desktopsize.width, desktopsize.height, {fullscreen=fullscreen, vsync=vsync, fsaa=fsaa})
	else
		uispace = math.floor(width*16*scale/4)
		love.window.setMode(width*16*scale, height*16*scale, {fullscreen=fullscreen, vsync=vsync, fsaa=fsaa}) --25x14 blocks (15 blocks actual height)
	end
	
	if love.graphics.isSupported("canvas") then
		completecanvas = love.graphics.newCanvas()
		completecanvas:setFilter("linear", "linear")
	end
	
	gamewidth = love.window.getWidth()
	gameheight = love.window.getHeight()
	
	if shaders then
		shaders:refresh()
	end
	
	if generatespritebatch then
		generatespritebatch()
	end
end
function screenshotUploadWrap(iname, idata)
	local t=upload_imagedata(iname, idata)
	if t.success then
		print("Your image was uploaded to: "..t.data.link)
		love.system.setClipboardText(t.data.link)
		notice.new("screenshot uploaded")
		--love.filesystem.write("screenshot_url.txt", t.data.link)
		--openImage(t.data.link)
	else
		print("Your image upload failed, please upload '"..outname.."' manually.")
		notice.new("upload failed, try manually")
		openSaveFolder()
	end
end

function controlsUpdate(dt)
	if controls.tap.gameScreenshot then
		screenshotUploadWrap("screenshot.png", love.graphics.newScreenshot())
	end
	
	if controls.tap.editorGetMousePosition then
		local x, y = getMouseTile(mouse.getX(), mouse.getY())
		print("mouse position", x, y)
	end
	
	if controls.debugModifier then
		
		if controls.tap.recordToggle then
			recording = not recording
		end
		if replaysystem and controls.tap.replaySave then
			objects["player"][1]:savereplaydata()
		end
		if controls.tap.debugLua then
			debug.debug()
		end
		if controls.tap.debugCrash then
			totallynonexistantfunction()
		end
	end
	
	if controls.tap.gameGrabMouseToggle then
		love.mouse.setGrabbed(not love.mouse.isGrabbed())
	end
	
	if gamestate == "lobby" or gamestate == "onlinemenu" then
		if controls.tap.menuBack then
			net_quit()
			return
		end
	end
	
	if gamestate == "menu" or gamestate == "mappackmenu" or gamestate == "onlinemenu" or gamestate == "options" then
		menu_controlupdate(dt)
	elseif gamestate == "game" then
		game_controlupdate(dt)
	elseif gamestate == "intro" then
		intro_skip()
	end
end

function love.keypressed(key, isrepeat)
	if keyprompt then
		keypromptenter("key", key)
		return
	end

	--@WARNING: This is the sample of code that causes the online lobby to edit all textboxes at once.
	for i, v in pairs(guielements) do
		if v:keypress(string.lower(key)) then
			--return
		end
	end
	
	if testbed then
		for k,v in pairs(testbed) do
			if v.active then
				v:keypressed(key)
			end
		end
	end
	
	
	if gamestate == "menu" or gamestate == "mappackmenu" or gamestate == "onlinemenu" or gamestate == "options" then
		table.insert(konamitable, key)
		table.remove(konamitable, 1)
		local s = ""
		for i = 1, #konamitable do
			s = s .. konamitable[i]
		end
		
		if sha1(s) == konamihash then --Before you wonder how dumb this is; This used to be a different code than konami because I thought it'd be fun to make people figure it out before they can tell others how to easily unlock cheats (without editing files). It wasn't, really.
			playsound("konami") --allowed global
			gamefinished = true
			saveconfig()
			notice.new("Cheats unlocked!")
		end
	elseif gamestate == "game" and editormode and rightclickm then
		-- aside from the transplanted code above, this was the only thing left in the editor's keypressed
		rightclickm:keypressed(key)
	elseif gamestate == "intro" then
		intro_skip()
	end
end

function getMousePos()
	--[[local x, y = love.mouse.getX(), love.mouse.getY()
	if fullscreen then
		if fullscreenmode == "full" then
			x, y = x/(desktopsize.width/(width*16*scale)), y/(desktopsize.height/(height*16*scale))
		else
			x, y = x/(touchfrominsidescaling/scale), y/(touchfrominsidescaling/scale)-touchfrominsidemissing/2
		end
	end]]
	return mouse.getX(), mouse.getY()
end

function love.mousepressed(ox, oy, button)
	local x, y = getMousePos()
	if gamestate == "intro" then
		intro_skip()
	end
	
	--editor transplant because I guess the editor doesn't use the standard guielements array
	
	--editor transplant because ???
	if rightclickm then
		allowdrag = false
		if button == "r" or not rightclickm:mousepressed(x, y, button) then
			closerightclickmenu()
			return
		else
			return
		end
	end
	
	if testbed then
		for k,v in pairs(testbed) do
			if v.active then
				v:mousepressed(x, y, button)
			end
		end
	end
	
	for i, v in pairs(guielements) do
		if v.priority then
			if v:click(x, y, button) then
				return
			end
		end
	end
	
	for i, v in pairs(guielements) do
		if not v.priority then
			if v:click(x, y, button) then
				return
			end
		end
	end
end

function love.mousereleased(ox, oy, button)
	local x, y = getMousePos()
	--desktopsize.width/(width*16*scale)*x, desktopsize.height/(height*16*scale)*y
	
	for i, v in pairs(guielements) do
		v:unclick(x, y, button)
	end
	
	if testbed then
		for k,v in pairs(testbed) do
			if v.active then
				v:mousereleased(x, y, button)
			end
		end
	end
	
	--same as above
	if rightclickm then
		rightclickm:mousereleased(x, y, button)
	end
end

function round(num, idp) --Not by me
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function keyPromptSignal(itype, ...)
	
end

function getrainbowcolor(i)
	local whiteness = 255
	local r, g, b
	if i < 1/6 then
		r = 1
		g = i*6
		b = 0
	elseif i >= 1/6 and i < 2/6 then
		r = (1/6-(i-1/6))*6
		g = 1
		b = 0
	elseif i >= 2/6 and i < 3/6 then
		r = 0
		g = 1
		b = (i-2/6)*6
	elseif i >= 3/6 and i < 4/6 then
		r = 0
		g = (1/6-(i-3/6))*6
		b = 1
	elseif i >= 4/6 and i < 5/6 then
		r = (i-4/6)*6
		g = 0
		b = 1
	else
		r = 1
		g = 0
		b = (1/6-(i-5/6))*6
	end
	
	return {round(r*whiteness), round(g*whiteness), round(b*whiteness), 255}
end

function newRecoloredImage(path, tablein, tableout)
	local imagedata = love.image.newImageData( path )
	local width, height = imagedata:getWidth(), imagedata:getHeight()
	
	for y = 0, height-1 do
		for x = 0, width-1 do
			local oldr, oldg, oldb, olda = imagedata:getPixel(x, y)
			
			if olda > 128 then
				for i = 1, #tablein do
					if oldr == tablein[i][1] and oldg == tablein[i][2] and oldb == tablein[i][3] then
						local r, g, b = unpack(tableout[i])
						imagedata:setPixel(x, y, r, g, b, olda)
					end
				end
			end
		end
	end
	
	return love.graphics.newImage(imagedata)
end

function getaveragecolor(imgdata, cox, coy)	
	local xstart = (cox-1)*17
	local ystart = (coy-1)*17
	
	local r, g, b = 0, 0, 0
	
	local count = 0
	
	for x = xstart, xstart+15 do
		for y = ystart, ystart+15 do
			local pr, pg, pb, a = imgdata:getPixel(x, y)
			if a > 127 then
				r, g, b = r+pr, g+pg, b+pb
				count = count + 1
			end
		end
	end
	
	r, g, b = r/count, g/count, b/count
	
	return r, g, b
end

function keyprompt_update()
	if keyprompt then
		for i = 1, prompt.joysticks do
			for j = 1, #prompt.joystick[i].validhats do
				local dir = love.joystick.getHat(i, prompt.joystick[i].validhats[j])
				if dir ~= "c" then
					keypromptenter("joyhat", i, prompt.joystick[i].validhats[j], dir)
					return
				end
			end
			
			for j = 1, prompt.joystick[i].axes do
				local value = love.joystick.getAxis(i, j)
				if value > prompt.joystick[i].axisposition[j] + joystickdeadzone then
					keypromptenter("joyaxis", i, j, "pos")
					return
				elseif value < prompt.joystick[i].axisposition[j] - joystickdeadzone then
					keypromptenter("joyaxis", i, j, "neg")
					return
				end
			end
		end
	end
end

function print_r (t, indent) --Not by me
	local indent=indent or ''
	for key,value in pairs(t) do
		io.write(indent,'[',tostring(key),']') 
		if type(value)=="table" then io.write(':\n') print_r(value,indent..'\t')
		else io.write(' = ',tostring(value),'\n') end
	end
end

--[[function love.focus(f)
	if not f and gamestate == "game"and not editormode and not levelfinished and not everyonedead  then
		pausemenuopen = true
		love.audio.pause()
	end
end]]
function openImage(img)
	local path = love.filesystem.getSaveDirectory()
	
	local cmdstr
	local successval = 0
	
	if os.getenv("WINDIR") then -- windows
		cmdstr = "Explorer \"%s\""
	elseif os.getenv("HOME") then
		if path:match("/Library/Application Support") then -- OSX
			cmdstr = "open \"%s\""
		else -- linux?
			cmdstr = "xdg-open \"%s\""
		end
	end
	
	os.execute(cmdstr:format(img))
	return cmdstr~=nil
end
function openSaveFolder(subfolder) --By Slime
	local path = love.filesystem.getSaveDirectory()
	path = subfolder and path.."/"..subfolder or path
	
	local cmdstr
	local successval = 0
	
	if os.getenv("WINDIR") then -- lolwindows
		--cmdstr = "Explorer /root,%s"
		if path:match("LOVE") then --hardcoded to fix ISO characters in usernames and made sure release mode doesn't mess anything up -saso
			cmdstr = "Explorer %%appdata%%\\LOVE\\Marin0SE"
		else
			cmdstr = "Explorer %%appdata%%\\Marin0SE"
		end
		path = path:gsub("/", "\\")
		successval = 1
	elseif os.getenv("HOME") then
		if path:match("/Library/Application Support") then -- OSX
			cmdstr = "open \"%s\""
		else -- linux?
			cmdstr = "xdg-open \"%s\""
		end
	end
	
	-- returns true if successfully opened folder
	return cmdstr and os.execute(cmdstr:format(path)) == successval
end

function getupdate()
	local onlinedata, code = http.request("http://server.stabyourself.net/mari0/?mode=mappacks")
	if code ~= 200 then
		return false
	elseif not onlinedata then
		return false
	end
	
	local latestversion
	
	local split1 = onlinedata:split("<")
	for i = 2, #split1 do
		local split2 = split1[i]:split(">")
		if split2[1] == "latestversion" then
			latestversion = tonumber(split2[2])
		end
	end
	
	if latestversion and latestversion > marioversion then
		return true
	end
	return false
end

function properprint(s, x, y, sc)
	local scale = sc or scale
	local startx = x
	local skip = 0
	for i = 1, string.len(tostring(s)) do
		if skip > 0 then
			skip = skip - 1
		else
			local char = string.sub(s, i, i)
			if string.sub(s, i, i+3) == "_dir" and tonumber(string.sub(s, i+4, i+4)) then
				love.graphics.draw(directionsimg, directionsquad[tonumber(string.sub(s, i+4, i+4))], x+((i-1)*8+1)*scale, y, 0, scale, scale)
				skip = 4
			elseif char == "|" then
				x = startx-((i)*8)*scale
				y = y + 10*scale
			elseif fontquads[char] then
				love.graphics.draw(fontimage, fontquads[char], x+((i-1)*8)*scale, y, 0, scale, scale)
			end
		end
	end
end

function properprintbackground(s, ox, oy, include, dcolor, sc)
	--[[if type(s)~="string" then
		print("WARNING: Tried to properprint a non-string.")
		return
	end]]
	local scale = sc or scale
	local x = ox
	local y = oy
	local startx = x
	local dcolor = dcolor or {255,255,255}
	local skip = 0
	local precolor = {love.graphics.getColor()}
	love.graphics.setColor(unpack(dcolor))
	for i = 1, string.len(tostring(s)) do
		if skip > 0 then
			skip = skip - 1
		else
			local char = string.sub(s, i, i)
			if char == "|" then
				x = startx-((i)*8)*scale
				y = y + 10*scale
			elseif fontquadsback[char] then
				love.graphics.draw(fontimageback, fontquadsback[char], x+((i-1)*8)*scale, y-1*scale, 0, scale, scale)
			end
		end
	end
	love.graphics.setColor(unpack(precolor))
	if include ~= false then
		properprint(s, ox, oy, scale)
	end
end

function loadcustombackgrounds()
	custombackgrounds = {}

	custombackgroundimg = {}
	custombackgroundwidth = {}
	custombackgroundheight = {}
	local fl = love.filesystem.getDirectoryItems("mappacks/" .. mappack .. "/backgrounds")
	
	for i = 1, #fl do
		local v = "mappacks/" .. mappack .. "/backgrounds/" .. fl[i]
		
		if love.filesystem.isFile(v) then
			if string.sub(v, -5, -5) == "1" then
				local name = string.sub(fl[i], 1, -6)
				local bg = string.sub(v, 1, -6)
				local i = 1
				
				custombackgroundimg[name] = {}
				custombackgroundwidth[name] = {}
				custombackgroundheight[name] = {}
					
				while love.filesystem.exists(bg .. i .. ".png") do
					print("background", bg, "index", i)
					custombackgroundimg[name][i] = love.graphics.newImage(bg .. i .. ".png")
					custombackgroundwidth[name][i] = custombackgroundimg[name][i]:getWidth()/16
					custombackgroundheight[name][i] = custombackgroundimg[name][i]:getHeight()/16
					i = i + 1
				end
				table.insert(custombackgrounds, name)
			--[[else
				local name = string.sub(fl[i], 1, -5)
				local bg = string.sub(v, 1, -5)
				
				custombackgroundimg[name] = {love.graphics.newImage(bg .. ".png")}
				custombackgroundwidth[name] = {custombackgroundimg[name][1]:getWidth()/16}
				custombackgroundheight[name] = {custombackgroundimg[name][1]:getHeight()/16}
				
				table.insert(custombackgrounds, name)]]
			end
		end
	end
end

function loadlevelscreens()
	levelscreens = {}
	
	local fl = love.filesystem.getDirectoryItems("mappacks/" .. mappack .. "/levelscreens")
	
	for i = 1, #fl do
		local v = "mappacks/" .. mappack .. "/levelscreens/" .. fl[i]
		if love.filesystem.isFile(v) then
			table.insert(levelscreens, string.lower(string.sub(fl[i], 1, -5)))
		end
	end
end

function loadcustommusics()
	musiclist = {"none.ogg", "overworld.ogg", "underground.ogg", "castle.ogg", "underwater.ogg", "starmusic.ogg", "athletic.ogg",}
	local fl = love.filesystem.getDirectoryItems("mappacks/" .. mappack .. "/music")
	custommusics = {}
	
	for i = 1, #fl do
		local v = fl[i]
		if (v:match(".ogg") or v:match(".mp3")) and v:sub(-9, -5) ~= "-fast" then
			table.insert(musiclist, v)
			--music:load(v) --Sometimes I come back to code and wonder why things are commented out. This is one of those cases. But it works so eh.
		end
	end
end

function loadanimatedtiles()
	if animatedtilecount then
		for i = 1, animatedtilecount do
			tilequads["a" .. i] = nil
		end
	end
	
	local function loadfolder(folder)
		local fl = love.filesystem.getDirectoryItems(folder)
		
		local i = 1
		while love.filesystem.isFile(folder .. "/" .. i .. ".png") do
			local v = folder .. "/" .. i .. ".png"
			if love.filesystem.isFile(v) and string.sub(v, -4) == ".png" then
				if love.filesystem.isFile(string.sub(v, 1, -5) .. ".txt") then
					animatedtilecount = animatedtilecount + 1
					local number = animatedtilecount+10000
					local t = animatedquad:new(v, love.filesystem.read(string.sub(v, 1, -5) .. ".txt"), number)
					tilequads[number] = t
					table.insert(animatedtiles, t)
				end
			end
			i = i + 1
		end
	end
	
	animatedtilecount = 0
	animatedtiles = {}
	loadfolder("graphics/animated")
	loadfolder("mappacks/" .. mappack .. "/animated")
end

function loadcustomtiles()
	if love.filesystem.exists("mappacks/" .. mappack .. "/tiles.png") then
		customtiles = true
		customtilesimg = love.graphics.newImage("mappacks/" .. mappack .. "/tiles.png")
		local imgwidth, imgheight = customtilesimg:getWidth(), customtilesimg:getHeight()
		local width = math.floor(imgwidth/17)
		local height = math.floor(imgheight/17)
		local imgdata = love.image.newImageData("mappacks/" .. mappack .. "/tiles.png")
		
		for y = 1, height do
			for x = 1, width do
				table.insert(tilequads, quad:new(customtilesimg, imgdata, x, y, imgwidth, imgheight))
				local r, g, b = getaveragecolor(imgdata, x, y)
				table.insert(rgblist, {r, g, b})
			end
		end
		customtilecount = width*height
	else
		customtiles = false
		customtilecount = 0
	end
end

function reloadGraphics()
	-- this doesn't rebuild quads so if any of these change resolution we're royally hosed
	iconimg = love.image.newImageData("/guihud/icon.gif")
	love.window.setIcon(iconimg)

	fontimage = love.graphics.newImage("/guihud/font.png")
	fontimageback = love.graphics.newImage("/guihud/fontback.png")
	
	logo = love.graphics.newImage("/guihud/stabyourself.png")
	logoblood = love.graphics.newImage("/guihud/stabyourselfblood.png")
	
	for _, v in pairs(imagelist) do
		_G[v .. "img"] = love.graphics.newImage( v .. ".png")
	end
	
	transparencyimg:setWrap("repeat", "repeat")
	
	menuselection = love.graphics.newImage("/guihud/menuselect.png")
	mappackback = love.graphics.newImage("/guihud/mappackback.png")
	mappacknoicon = love.graphics.newImage("/guihud/mappacknoicon.png")
	mappackoverlay = love.graphics.newImage("/guihud/mappackoverlay.png")
	mappackhighlight = love.graphics.newImage("/guihud/mappackhighlight.png")
	
	mappackscrollbar = love.graphics.newImage("/guihud/mappackscrollbar.png")
	
	fontimage2 = love.graphics.newImage("/guihud/smallfont.png")
	fontimage3 = love.graphics.newImage("/guihud/smallsymbols.png")
	
	entitiesimg = love.graphics.newImage("/guihud/entities.png")
	
	popupfontimage = love.graphics.newImage("/guihud/popupfont.png")
	
	linktoolpointerimg = love.graphics.newImage("/guihud/linktoolpointer.png")
	
	titleimage = love.graphics.newImage("/guihud/title.png")
	playerselectimg = love.graphics.newImage("/guihud/playerselectarrow.png")
	
	magicimg = love.graphics.newImage("/guihud/magic.png")
	
	checkboximg = love.graphics.newImage("/guihud/checkbox.png")
	
	dropdownarrowimg = love.graphics.newImage("/guihud/dropdownarrow.png")
	
	portalparticleimg = love.graphics.newImage("portalparticle.png")
	portalcrosshairimg = love.graphics.newImage("portalcrosshair.png")
	portaldotimg = love.graphics.newImage("portaldot.png")
	portalprojectileimg = love.graphics.newImage("portalprojectile.png")
	portalprojectileparticleimg = love.graphics.newImage("portalprojectileparticle.png")
	portalbackgroundimg = love.graphics.newImage("portalbackground.png")
	
	--Menu shit
	huebarimg = love.graphics.newImage("/guihud/huebar.png")
	huebarmarkerimg = love.graphics.newImage("/guihud/huebarmarker.png")
	volumesliderimg = love.graphics.newImage("/guihud/volumeslider.png")
	directionsimg = love.graphics.newImage("/guihud/directions.png")
	
	gradientimg = love.graphics.newImage("/guihud/gradient.png")
	gradientimg:setFilter("linear", "linear")
	
	--@WARNING: This code is a bad influence because icons that don't already exist can't be introduced by a modpack. I'll fix it later.
	killfeed.icons = {}
	killfeed.exicons = {}
	local gdir = "graphics/DEFAULT/"
	local idir = "ui/icons/kill"
	for h,s in ipairs(love.filesystem.getDirectoryItems(gdir..idir)) do
		if love.filesystem.isFile(gdir..idir.."/"..s) then
			killfeed.icons[s:sub(0,-5)] = love.graphics.newImage(gdir..idir.."/"..s)
		end
	end
	idir = "ui/icons"
	for h,s in ipairs(love.filesystem.getDirectoryItems(gdir..idir)) do
		if love.filesystem.isFile(gdir..idir.."/"..s) then
			killfeed.exicons[s:sub(0,-5)] = love.graphics.newImage(gdir..idir.."/"..s)
		end
	end
	
end

function reloadSounds() -- mastersfx, master list of sounds current being looked at.
	soundstoload = {"none", "jump", "jumpbig", "stomp", "shot", "blockhit", "blockbreak", "coin", "pipe", "boom", "mushroomappear", "mushroomeat", "shrink", "death", "gameover", "fireball", "redcoin1", "redcoin2", "redcoin3", "redcoin4", "redcoin5", "boss_spit", "enemy_hit", "rainboom", "kirbyenemy",
					"oneup", "levelend", "castleend", "scorering", "intermission", "fire", "bridgebreak", "bowserfall", "vine", "swim", "konami", "pause", "bulletbill", "addtime", "throw", "trophy", "switch",
					"lowtime", "tailwag", "planemode", "stab", "spring", "portal1open", "portal2open", "portalenter", "portalfizzle"}
				
	soundlist = {}
	
	for i, v in pairs(soundstoload) do
		local dat = love.sound.newSoundData(v..".ogg")
		soundlist[v] = {}
		soundlist[v].duration = dat:getDuration()
		soundlist[v].samplecount = dat:getSampleCount()
		soundlist[v].samplerate = dat:getSampleRate()
		soundlist[v].source = love.audio.newSource(dat)
		soundlist[v].lastplayed = 0
	end
	
	soundlist["scorering"].source:setLooping(true)
	soundlist["planemode"].source:setLooping(true)
	soundlist["portal1open"].source:setVolume(0.3)
	soundlist["portal2open"].source:setVolume(0.3)
	soundlist["portalenter"].source:setVolume(0.3)
	soundlist["portalfizzle"].source:setVolume(0.3)
end

function love.quit()
	
end

function savestate(i)
	serializetable(_G)
end

function serializetable(t)
	tablestodo = {t}
	tableindex = {}
	repeat
		nexttablestodo = {}
		for i, v in pairs(tablestodo) do
			if type(v) == "table" then
				local tableexists = false
				for j, k in pairs(tableindex) do
					if k == v then
						tableexists = true
					end
				end
				
				if tableexists then
					
				else
					table.insert(nexttablestodo, v)
					table.insert(tableindex, v)
				end
			end
		end
		tablestodo = nexttablestodo
	until #tablestodo == 0
end

mouse = {}

function mouse.getPosition()
	if fullscreen then
		if fullscreenmode == "full" then
			return love.mouse.getX()/(desktopsize.width/(width*16*scale)), love.mouse.getY()/(desktopsize.height/(height*16*scale))
		else
			return love.mouse.getX()/(touchfrominsidescaling/scale), love.mouse.getY()/(touchfrominsidescaling/scale)-touchfrominsidemissing/2
		end
	else
		return love.mouse.getPosition()
	end
end

function mouse.getX()
	if fullscreen then
		if fullscreenmode == "full" then
			return love.mouse.getX()/(desktopsize.width/(width*16*scale))
		else
			return love.mouse.getX()/(touchfrominsidescaling/scale)
		end
	else
		return love.mouse.getX()
	end
end

function mouse.getY()
	if fullscreen then
		if fullscreenmode == "full" then
			return love.mouse.getY()/(desktopsize.height/(height*16*scale))
		else
			return love.mouse.getY()/(touchfrominsidescaling/scale)-touchfrominsidemissing/2
		end
	else
		return love.mouse.getY()
	end
end

function net_quit()
	gamestate = "menu"
	guielements = {}
	if onlinemp then
		if not clientisnetworkhost then
			local unconnectedstring = tostring(udp)
			local splitstring = unconnectedstring:split(":")
			if splitstring[1] == "udp{connected}" then
				udp:send("clientquit;" .. networkclientnumber)
			end
		else
			server_shutserver()
			print("shutting server")
		end
		if clientisnetworkhost then
			magicdns_remove()
		end
	end
end