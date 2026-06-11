--!nocheck
local oldReadfile = readfile
readfile = function(file)
    local result = oldReadfile(file)
    if type(result) == "boolean" then
        return ""
    end
    return result or ""
end

local oldIsfile = isfile
isfile = function(file)
    local result = oldIsfile(file)
    if type(result) == "boolean" then
        return result
    end
    local content = readfile(file)
    return content ~= nil and content ~= "" and type(content) == "string"
end

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
		print("[BananaVape] Downloaded: " .. path)
		
		local commitPath = 'bananavxpe/profiles/commit.txt'
		if not isfile(commitPath) then
			writefile(commitPath, 'main')
		end
		
		local commit = readfile(commitPath)
		if type(commit) ~= "string" then
			commit = 'main'
			writefile(commitPath, 'main')
		end
		
		commit = commit:gsub("%s+", "")
		if commit == "" then
			commit = "main"
		end
		
		local relativePath = select(1, path:gsub('bananavxpe/', ''))
		local url = 'https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/' .. commit .. '/' .. relativePath
		
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
		6872274481, 6872265039, 8444591321, 8560631822, 606849621,
		5938036553, 893973440, 142823291, 155615604, 8542259458,
		8542275097, 8592115909, 8768229691, 8951451142, 13246639586,
		11156779721, 80041634734121, 77790193039862, 123804558118054,
		131465939650733, 135564683255158, 139566161526375,
	}
	
	if not table.find(knownGames, placeId) then
		return false, "No custom script for this game"
	end
	
	local function executeScript(scriptContent, scriptName)
		if type(scriptContent) == "boolean" then
			return false, "Script content is boolean"
		end
		
		if type(scriptContent) ~= "string" or scriptContent == "" then
			return false, "Script content is invalid"
		end
		
		local func, compileError = loadstring(scriptContent, scriptName)
		if not func then
			return false, "Compile error: " .. tostring(compileError)
		end
		
		local success, result = pcall(func, license)
		if success then
			return true, result
		end
	
		success, result = pcall(func)
		if success then
			return true, result
		end
		
		return false, "All execution methods failed"
	end
	
	if isfile(gameScriptPath) then
		local scriptContent = readfile(gameScriptPath)
		
		if type(scriptContent) == "boolean" then
			pcall(function() writefile(gameScriptPath, '') end)
			scriptContent = nil
		end
		
		if scriptContent and type(scriptContent) == "string" then
			local success, result = executeScript(scriptContent, tostring(placeId))
			if success then
				return true, "Loaded local game script"
			end
		end
	end
	
	if not shared.VapeDeveloper then
		local commit = 'main'
		if isfile('bananavxpe/profiles/commit.txt') then
			local commitContent = readfile('bananavxpe/profiles/commit.txt')
			if type(commitContent) == "string" and commitContent ~= "" then
				commit = commitContent
			end
		end
		
		local url = 'https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/'..commit..'/games/'..placeId..'.lua'
		
		local suc, res = pcall(function()
			return game:HttpGet(url, true)
		end)
		
		if suc and res and type(res) == "string" and res ~= '404: Not Found' and res ~= '' then
			if not res:find('This watermark is used to delete the file') then
				res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			end
			writefile(gameScriptPath, res)
			
			local success, result = executeScript(res, tostring(placeId))
			if success then
				return true, "Downloaded and loaded game script"
			end
		end
	end
	
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
		error("Failed to load GUI file")
	end
	
	local loadFunc = loadstring(guiContent, 'gui')
	if not loadFunc then
		error("Failed to compile GUI file")
	end
	
	vape = loadFunc(license)
	if not vape then
		error("Failed to initialize vape")
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
				pcall(function() universalFunc(license) end)
			end
		end
		
		loadGameSpecificScript()
		
		local premiumContent = downloadFile('bananavxpe/libraries/premium.lua')
		if premiumContent then
			local premiumFunc = loadstring(premiumContent, 'premium')
			if premiumFunc then
				pcall(function() premiumFunc(license) end)
			end
		end
		
		finishLoading()
	else
		vape.Init = finishLoading
		return vape
	end
end

local success, err = xpcall(initialize, function(e)
	return e
end)

if not success then
	error("Script failed to initialize: " .. tostring(err or "Unknown error"))
end
