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
					local success1, result1 = pcall(func)
					if success1 then
						return true, result1
					else
						local success2, result2 = pcall(func, license)
						if success2 then
							return true, result2
						else
							local success3, result3 = pcall(function() return func(license) end)
							if success3 then
								return true, result3
							end
						end
						return nil, result1 or result2 or result3
					end
				end
				return nil, "loadstring returned nil"
			end)
			if success and result then
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
					local callSuccess, callResult
					
					callSuccess, callResult = pcall(func)
					if callSuccess then
						return true, callResult
					end
					
					callSuccess, callResult = pcall(function() return func(license) end)
					if callSuccess then
						return true, callResult
					end
					
					callSuccess, callResult = pcall(func, license)
					if callSuccess then
						return true, callResult
					end
					
					return nil, "All calling methods failed for downloaded script"
				end
				return nil, "loadstring returned nil for downloaded script"
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
