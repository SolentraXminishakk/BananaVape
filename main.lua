local license = ... or {}
license.Key = script_key or license.Key or nil

repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('BananaVape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end

local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end

local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local httpService = cloneref(game:GetService('HttpService'))

local redirect = function()
	local body = httpService:JSONEncode({
		nonce = httpService:GenerateGUID(false),
		args = {
			invite = {code = 'bananavape'},
			code = 'bananavape'
		},
		cmd = 'INVITE_BROWSER'
	})

	for i = 1, 2 do
		task.spawn(function()
			request({
				Method = 'POST',
				Url = 'http://127.0.0.1:6463/rpc?v=1',
				Headers = {
					['Content-Type'] = 'application/json',
					Origin = 'https://discord.com'
				},
				Body = body
			})
		end)
	end
end

local function downloadFile(path, func)
	if not isfile(path) then
		warn("Downloading: " .. path)
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/'..readfile('bananavxpe/profiles/commit.txt')..'/'..select(1, path:gsub('bananavxpe/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			warn("Failed to download: " .. path .. " - " .. tostring(res))
			return nil
		end
		if suc then
			if path:find('.lua') then
				res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			end
			writefile(path, res)
			print("Downloaded: " .. path)
		end
	end
	return (func or readfile)(path)
end

local function loadGameSpecificScript()
	local placeId = game.PlaceId
	local gameScriptPath = 'bananavxpe/games/'..placeId..'.lua'
	
	print("[BananaVape] Looking for game script at: " .. gameScriptPath)
	print("[BananaVape] Current PlaceId: " .. placeId)
	
	if isfile(gameScriptPath) then
		print("[BananaVape] Found local game script, loading...")
		local success, result = pcall(function()
			local scriptContent = readfile(gameScriptPath)
			local func = loadstring(scriptContent, tostring(placeId))
			return func(license)
		end)
		if success then
			print("[BananaVape] Successfully loaded local game script for PlaceId: " .. placeId)
			return true, "Loaded local game script"
		else
			warn("Failed to load local game script: " .. tostring(result))
		end
	end
	
	if not shared.VapeDeveloper then
		print("[BananaVape] Attempting to download game script from GitHub...")
		local commit = readfile('bananavxpe/profiles/commit.txt')
		local url = 'https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/'..commit..'/games/'..placeId..'.lua'
		print("[BananaVape] Download URL: " .. url)
		
		local suc, res = pcall(function()
			return game:HttpGet(url, true)
		end)
		
		if suc and res and res ~= '404: Not Found' then
			print("[BananaVape] Downloaded game script, saving and loading...")
			if path:find('.lua') then
				res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			end
			writefile(gameScriptPath, res)
			
			local success, result = pcall(function()
				local func = loadstring(res, tostring(placeId))
				return func(license)
			end)
			if success then
				print("[BananaVape] Successfully loaded downloaded game script for PlaceId: " .. placeId)
				return true, "Downloaded and loaded game script"
			else
				warn("Failed to load downloaded game script: " .. tostring(result))
			end
		else
			print("[BananaVape] Game script not found on GitHub for PlaceId: " .. placeId)
			if res == '404: Not Found' then
				print("[BananaVape] No custom module exists for this game")
			end
		end
	end
	
	print("[BananaVape] No game-specific script found for PlaceId: " .. placeId)
	return false, "No game-specific script found"
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function(state)
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				if shared.VapeDeveloper then
					loadstring(readfile('bananavxpe/main.lua'), 'main')(_scriptconfig)
				else
					loadstring(game:HttpGet('https://api.catvape.dev/script?key=_key'), 'init')(_scriptconfig)
				end
			]]
			local teleportConfig = httpService:JSONEncode(license)
			teleportConfig = teleportConfig:gsub('":true', "=true"):gsub('{"', '{')
			teleportConfig = teleportConfig:gsub(',"', ','):gsub('":', '=')
			teleportConfig = teleportConfig:gsub('%[', '{'):gsub('%]', '}')
			teleportScript = teleportScript:gsub('_key', tostring(license.Key or '_key'))
			teleportScript = teleportScript:gsub('_scriptconfig', teleportConfig)
			
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main and vape.Categories.Main.Options['GUI bind indicator'] and vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			if getgenv().catrole == 'HWID MISMATCH' then
				vape:CreateNotification('Cat', 'HWID MISMATCH, Go to the script panel to reset hwid', 25, 'alert')
				getgenv().catrole = ''
				task.wait(0.1)
			end
			
			if vape.Place ~= 6872274481 and not license.Closet then
				task.spawn(redirect)
			end
			
			local authMessage = (getgenv().catname and `Authenticated as {getgenv().catname} with {getgenv().catrole}, ` or '')
			local guiMessage = (vape.VapeButton and 'Press the button in the top right' or 'Press '..table.concat(vape.Keybind, ' + '):upper())..' to open GUI'
			
			vape:CreateNotification('Finished Loading', authMessage..guiMessage, 5)
			
			task.delay(1, function()
				if shared.updated then
					vape:CreateNotification('Cat', `Script has updated from {shared.updated} to {readfile('bananavxpe/profiles/commit.txt')}`, 10, 'info')
				end
			end)
		end
	end
end

local function initialize()
	if not isfolder('bananavxpe') then
		makefolder('bananavxpe')
	end
	if not isfolder('bananavxpe/profiles') then
		makefolder('bananavxpe/profiles')
	end
	if not isfolder('bananavxpe/games') then
		makefolder('bananavxpe/games')
	end
	if not isfolder('bananavxpe/libraries') then
		makefolder('bananavxpe/libraries')
	end
	if not isfolder('bananavxpe/guis') then
		makefolder('bananavxpe/guis')
	end
	
	if not isfile('bananavxpe/profiles/gui.txt') then
		writefile('bananavxpe/profiles/gui.txt', 'new')
	end
	
	local gui = 'new'

	if not isfolder('bananavxpe/assets/'..gui) then
		makefolder('bananavxpe/assets/'..gui)
	end
	
	if not isfile('bananavxpe/profiles/commit.txt') then
		writefile('bananavxpe/profiles/commit.txt', 'main')
	end

	getgenv().used_init = true
	
	local guiContent = downloadFile('bananavxpe/guis/'..gui..'.lua')
	if not guiContent then
		error("Failed to load GUI file")
	end
	
	vape = loadstring(guiContent, 'gui')(license)
	_G.vape = vape
	shared.vape = vape

	if shared.mainbanana then
		redirect()
		playersService:Kick('this script is outdated...')
		return
	end

	if not shared.VapeIndependent then
		local universalContent = downloadFile('bananavxpe/games/universal.lua')
		if universalContent then
			local success = pcall(function()
				loadstring(universalContent, 'universal')(license)
			end)
			if not success then
				warn("Failed to load universal.lua")
			else
				print("[Vape] Universal.lua loaded successfully")
			end
		else
			warn("Failed to download universal.lua")
		end
		
		local gameScriptLoaded, gameScriptMessage = loadGameSpecificScript()
		
		if gameScriptLoaded then
			print("[BananaVape] SUCCESS: " .. gameScriptMessage)
			print("[BananaVape] Custom modules for PlaceId " .. game.PlaceId .. " should now be loaded")
		else
			print("[BananaVape] WARNING: " .. gameScriptMessage)
			print("[BananaVape] No custom modules found for this game. Only universal features will work.")
		end
		
		local premiumContent = downloadFile('bananavxpe/libraries/premium.lua')
		if premiumContent then
			local success = pcall(function()
				loadstring(premiumContent, 'premium')(license)
			end)
			if not success then
				warn("Failed to load premium.lua")
			end
		end
		
		finishLoading()
	else
		vape.Init = finishLoading
		return vape
	end
end

local success, err = xpcall(initialize, function(err)
	warn("Initialization error: " .. tostring(err))
	warn(debug.traceback())
	if vape and vape.CreateNotification then
		vape:CreateNotification('Error', 'Failed to initialize: ' .. tostring(err), 10, 'alert')
	end
end)

if not success then
	error("Script failed to initialize: " .. tostring(err))
end
