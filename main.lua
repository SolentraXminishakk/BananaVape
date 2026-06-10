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
	if isfile(path) then
		return (func or readfile)(path)
	end
	
	warn("Downloading: " .. path)
	local commitFile = 'bananavxpe/profiles/commit.txt'
	
	if not isfile(commitFile) then
		warn("commit.txt not found, creating default")
		writefile(commitFile, 'main')
	end
	
	local commit = readfile(commitFile)
	local relativePath = select(1, path:gsub('bananavxpe/', ''))
	local url = 'https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/'..commit..'/'..relativePath
	
	local suc, res = pcall(function()
		return game:HttpGet(url, true)
	end)
	
	if not suc or res == '404: Not Found' then
		warn("Failed to download: " .. path .. " - " .. tostring(res))
		return nil
	end
	
	if suc and res then
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
		print("Downloaded: " .. path)
		return (func or readfile)(path)
	end
	
	return nil
end

local function loadGameSpecificScript()
	local placeId = game.PlaceId
	local gameScriptPath = 'bananavxpe/games/'..placeId..'.lua'
	
	print("[BananaVape] Looking for game script at: " .. gameScriptPath)
	print("[BananaVape] Current PlaceId: " .. placeId)
	
	if isfile(gameScriptPath) then
		print("[BananaVape] Found local game script, loading...")
		local scriptContent = readfile(gameScriptPath)
		if scriptContent then
			local success, result = pcall(function()
				local func = loadstring(scriptContent, tostring(placeId))
				if func then
					return func(license)
				end
				return nil
			end)
			if success then
				print("[BananaVape] Successfully loaded local game script for PlaceId: " .. placeId)
				return true, "Loaded local game script"
			else
				warn("Failed to load local game script: " .. tostring(result))
			end
		end
	end
	
	if not shared.VapeDeveloper then
		print("[BananaVape] Attempting to download game script from GitHub...")
		local commit = isfile('bananavxpe/profiles/commit.txt') and readfile('bananavxpe/profiles/commit.txt') or 'main'
		local url = 'https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/'..commit..'/games/'..placeId..'.lua'
		print("[BananaVape] Download URL: " .. url)
		
		local suc, res = pcall(function()
			return game:HttpGet(url, true)
		end)
		
		if suc and res and res ~= '404: Not Found' then
			print("[BananaVape] Downloaded game script, saving and loading...")
			if res:find('.lua') then
				res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			end
			writefile(gameScriptPath, res)
			
			local success, result = pcall(function()
				local func = loadstring(res, tostring(placeId))
				if func then
					return func(license)
				end
				return nil
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
	if not vape then
		warn("finishLoading called but vape is nil")
		return
	end
	
	vape.Init = nil
	vape:Load()
	
	task.spawn(function()
		repeat
			task.wait(10)
			if vape and vape.Save then
				pcall(function() vape:Save() end)
			end
		until not vape or not vape.Loaded
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
		if vape and vape.Categories then
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
end

local function initialize()
	local folders = {
		'bananavxpe',
		'bananavxpe/profiles',
		'bananavxpe/games',
		'bananavxpe/libraries',
		'bananavxpe/guis',
		'bananavxpe/assets/new'
	}
	
	for _, folder in ipairs(folders) do
		if not isfolder(folder) then
			makefolder(folder)
		end
	end
	
	if not isfile('bananavxpe/profiles/gui.txt') then
		writefile('bananavxpe/profiles/gui.txt', 'new')
	end
	
	local gui = 'new'
	
	if not isfile('bananavxpe/profiles/commit.txt') then
		writefile('bananavxpe/profiles/commit.txt', 'main')
	end

	getgenv().used_init = true
	
	local guiContent = downloadFile('bananavxpe/guis/'..gui..'.lua')
	if not guiContent then
		error("Failed to load GUI file - download returned nil")
	end
	
	local loadFunc = loadstring(guiContent, 'gui')
	if not loadFunc then
		error("Failed to compile GUI file - syntax error")
	end
	
	vape = loadFunc(license)
	if not vape then
		error("Failed to initialize vape - GUI returned nil")
	end
	
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
			local universalFunc = loadstring(universalContent, 'universal')
			if universalFunc then
				local success = pcall(function()
					universalFunc(license)
				end)
				if not success then
					warn("Failed to load universal.lua")
				else
					print("[BananaVape] Universal.lua loaded successfully")
				end
			end
		else
			warn("Failed to download universal.lua")
		end
		
		local gameScriptLoaded, gameScriptMessage = loadGameSpecificScript()
		
		if gameScriptLoaded then
			print("[BananaVape] SUCCESS: " .. gameScriptMessage)
		else
			print("[BananaVape] WARNING: " .. gameScriptMessage)
		end
		
		local premiumContent = downloadFile('bananavxpe/libraries/premium.lua')
		if premiumContent then
			local premiumFunc = loadstring(premiumContent, 'premium')
			if premiumFunc then
				local success = pcall(function()
					premiumFunc(license)
				end)
				if not success then
					warn("Failed to load premium.lua")
				end
			end
		end
		
		finishLoading()
	else
		vape.Init = finishLoading
		return vape
	end
end

local success, err = xpcall(initialize, function(e)
	warn("Initialization error: " .. tostring(e))
	warn(debug.traceback())
	return e
end)

if not success then
	error("Script failed to initialize: " .. tostring(err or "Unknown error"))
end
