local license = ... or {}
license.Key = script_key or license.Key or nil

repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
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
		warn(path)
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/'..readfile('bananavxpe/profiles/commit.txt')..'/'..select(1, path:gsub('bananavxpe/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			task.spawn(error, res)
		end
		if suc then
			if path:find('.lua') then
				res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			end
			writefile(path, res)
		end
	end
	return (func or readfile)(path)
end

local function loadGameSpecificScript()
	local placeId = game.PlaceId
	local gameScriptPath = 'bananavxpe/games/'..placeId..'.lua'
	
	if isfile(gameScriptPath) then
		local success, result = pcall(function()
			return loadstring(readfile(gameScriptPath), tostring(placeId))(license)
		end)
		if success then
			return true, "Loaded local game script"
		else
			warn("Failed to load local game script: " .. tostring(result))
		end
	end
	
	if not shared.VapeDeveloper then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/'..readfile('bananavxpe/profiles/commit.txt')..'/games/'..placeId..'.lua', true)
		end)
		
		if suc and res and res ~= '404: Not Found' then
			local success, result = pcall(function()
				return loadstring(downloadFile(gameScriptPath), tostring(placeId))(license)
			end)
			if success then
				return true, "Downloaded and loaded game script"
			else
				warn("Failed to load downloaded game script: " .. tostring(result))
			end
		end
	end
	
	return false, "No game-specific script found"
end

local function loadModules()
	local modules = {
		{name = "universal", path = "bananavxpe/games/universal.lua", required = true},
		{name = "premium", path = "bananavxpe/libraries/premium.lua", required = false},
	}
	
	local results = {}
	
	for _, module in ipairs(modules) do
		local success, err = pcall(function()
			return loadstring(downloadFile(module.path), module.name)(license)
		end)
		
		if success then
			results[module.name] = true
		else
			warn("Failed to load " .. module.name .. ": " .. tostring(err))
			results[module.name] = not module.required
			if module.required then
				return false, "Required module failed: " .. module.name
			end
		end
	end
	
	return true, results
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
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
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
	vape = loadstring(downloadFile('bananavxpe/guis/'..gui..'.lua'), 'gui')(license)
	_G.vape = vape
	shared.vape = vape

	if shared.mainbanana then
		redirect()
		playersService:Kick('this script is outdated...')
		return
	end

	if not shared.VapeIndependent then
		local universalSuccess = pcall(function()
			loadstring(downloadFile('bananavxpe/games/universal.lua'), 'universal')(license)
		end)
		
		if not universalSuccess then
			warn("Failed to load universal.lua, continuing anyway...")
		end
		
		local gameScriptLoaded, gameScriptMessage = loadGameSpecificScript()
		
		if gameScriptLoaded then
			print("[Vape] " .. gameScriptMessage)
		else
			print("[Vape] No game-specific features loaded for PlaceId: " .. game.PlaceId)
		end
		
		local premiumSuccess = pcall(function()
			loadstring(downloadFile('bananavxpe/libraries/premium.lua'), 'premium')(license)
		end)
		
		if not premiumSuccess then
			warn("Failed to load premium.lua")
		end
		
		finishLoading()
	else
		vape.Init = finishLoading
		return vape
	end
end

local success, err = xpcall(initialize, function(err)
	warn("Initialization error: " .. tostring(err))
	if vape and vape.CreateNotification then
		vape:CreateNotification('Error', 'Failed to initialize: ' .. tostring(err), 10, 'alert')
	end
end)

if not success then
	error("Script failed to initialize: " .. tostring(err))
end
