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
		if not license.Closet then
			print("[BananaVape] Downloading: " .. path)
		end
		
		local commitPath = 'bananavxpe/profiles/commit.txt'
		if not isfile(commitPath) then
			writefile(commitPath, 'main')
		end
		
		local commit = readfile(commitPath)
		if type(commit) ~= "string" then
			warn("Commit was " .. type(commit) .. ", resetting to 'main'")
			commit = 'main'
			writefile(commitPath, 'main')
		end
		
		commit = commit:gsub("%s+", "")
		
		if commit == "" or commit == nil then
			commit = "main"
		end
		
		local relativePath = select(1, path:gsub('bananavxpe/', ''))
		if type(relativePath) ~= "string" then
			relativePath = tostring(relativePath) or ""
		end
		
		local url = 'https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/' .. commit .. '/' .. relativePath
		
		if type(url) ~= "string" or url == "" then
			error("Invalid URL generated: " .. tostring(url))
		end
		
		local suc, res = pcall(function()
			return game:HttpGet(url, true)
		end)
		
		if not suc or res == '404: Not Found' then
			error(res or "Failed to download")
		end
		
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function loadGameSpecificScript()
	if not table.find then
		function table.find(tbl, value)
			for i, v in ipairs(tbl) do
				if v == value then
					return i
				end
			end
			return nil
		end
	end
	
	local placeId = game.PlaceId
	local gameScriptPath = 'bananavxpe/games/'..placeId..'.lua'
	
	local knownGames = {
		6872274481,
		6872265039,
		8444591321,
		8560631822,
		606849621,
		5938036553,
		893973440,
		142823291,
		155615604,
		8542259458,
		8542275097,
		8592115909,
		8768229691,
		8951451142,
		13246639586,
		11156779721,
		80041634734121,
		77790193039862,
		123804558118054,
		131465939650733,
		135564683255158,
		139566161526375,
	}
	
	print("[BananaVape] Looking for game script at: " .. gameScriptPath)
	print("[BananaVape] Current GameId: " .. placeId)
	
	if not table.find(knownGames, placeId) then
		print("[BananaVape] No custom script available for: " .. placeId)
		return false, "No custom script for this game"
	end
	
	local function executeScript(scriptContent, scriptName)
		if type(scriptContent) == "boolean" then
			print("[BananaVape] Script content is boolean (false), treating as empty")
			return false, "Script content is boolean (file read failed)"
		end
		
		if type(scriptContent) ~= "string" then
			return false, "Script content is not a string (type: " .. type(scriptContent) .. ")"
		end
		
		if scriptContent == "" then
			return false, "Script content is empty"
		end
		
		local func, compileError = loadstring(scriptContent, scriptName)
		if not func then
			return false, "Compile error: " .. tostring(compileError)
		end
		
		local success, result = pcall(func, license)
		if success then
			print("[BananaVape] Script executed successfully")
			return true, result
		end
	
		success, result = pcall(func)
		if success then
			print("[BananaVape] Script executed successfully (no args)")
			return true, result
		end
		
		return false, "All execution methods failed"
	end
	
	if isfile(gameScriptPath) then
		print("[BananaVape] Found local game script, loading...")
		local scriptContent = readfile(gameScriptPath)
		
		print("[BananaVape] readfile returned type: " .. type(scriptContent))
		
		if type(scriptContent) == "boolean" then
			warn("[BananaVape] readfile returned boolean, attempting to re-read or redownload")
			pcall(function() writefile(gameScriptPath, '') end)
			scriptContent = nil
		end
		
		if scriptContent and type(scriptContent) == "string" then
			local success, result = executeScript(scriptContent, tostring(placeId))
			if success then
				print("[BananaVape] Successfully loaded local game script for PlaceId: " .. placeId)
				return true, "Loaded local game script"
			else
				warn("Failed to load local game script: " .. tostring(result))
			end
		else
			warn("[BananaVape] Local game script file exists but readfile returned invalid data")
		end
	end
	
	if not shared.VapeDeveloper then
		print("[BananaVape] Attempting to download game script from GitHub...")
		local commit = 'main'
		if isfile('bananavxpe/profiles/commit.txt') then
			local commitContent = readfile('bananavxpe/profiles/commit.txt')
			if type(commitContent) == "string" and commitContent ~= "" then
				commit = commitContent
			end
		end
		
		local url = 'https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/'..commit..'/games/'..placeId..'.lua'
		print("[BananaVape] Download URL: " .. url)
		
		local suc, res = pcall(function()
			return game:HttpGet(url, true)
		end)
		
		if suc and res and type(res) == "string" and res ~= '404: Not Found' and res ~= '' then
			print("[BananaVape] Downloaded game script, saving and loading...")
			
			if not res:find('This watermark is used to delete the file') then
				res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			end
			writefile(gameScriptPath, res)
			
			local success, result = executeScript(res, tostring(placeId))
			if success then
				print("[BananaVape] Successfully loaded downloaded game script for PlaceId: " .. placeId)
				return true, "Downloaded and loaded game script"
			else
				warn("Failed to load downloaded game script: " .. tostring(result))
			end
		else
			print("[BananaVape] Game script not found on GitHub for PlaceId: " .. placeId)
			if type(res) == "string" and res == '404: Not Found' then
				print("[BananaVape] No custom module exists for this game yet")
			end
		end
	end
	
	print("[BananaVape] No game-specific script found for: " .. placeId)
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
		error("Failed to load GUI file (download returned nil)")
	end
	
	local loadFunc = loadstring(guiContent, 'gui')
	if not loadFunc then
		error("Failed to compile GUI file (syntax error)")
	end
	
	vape = loadFunc(license)
	if not vape then
		error("Failed to initialize vape (GUI returned nil)")
	end
	
	_G.vape = vape
	shared.vape = vape

	if shared.mainbanana then
		redirect()
		playersService:Kick('this script is outdated...\n\n\nfucking dumbass lol')
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
