--!nocheck
-- CRITICAL FIX: Override readfile to NEVER return boolean
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
license.Key = script_key or license.Key

local cloneref = cloneref or function(ref) return ref end

local delfile = delfile or function(file)
	pcall(function()
		writefile(file, '')
	end)
end

local function downloadFile(path, func)
	if not isfile(path) then
		print("[BananaVape] Downloaded: " .. path)
		
		local commitPath = 'bananavxpe/profiles/commit.txt'
		local commit = 'main'
		
		if isfile(commitPath) then
			local commitContent = readfile(commitPath)
			if commitContent ~= "" then
				commit = commitContent:gsub("%s+", "")
			end
		else
			writefile(commitPath, 'main')
		end
		
		if type(commit) ~= "string" or commit == "" then
			commit = "main"
		end
		
		local relativePath = select(1, path:gsub('bananavxpe/', ''))
		local url = 'https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/' .. commit .. '/' .. relativePath
		
		local suc, res = pcall(function()
			return game:HttpGet(url, true)
		end)
		
		if not suc or res == '404: Not Found' then
			error(tostring(res or "Failed to download"))
		end
		
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('init') then continue end
		if file:find('profile') then continue end
		if isfile(file) then
			delfile(file)
		elseif isfolder(file) then
			wipeFolder(file)
		end
	end
end

for _, folder in {'bananavxpe', 'bananavxpe/games', 'bananavxpe/profiles', 'bananavxpe/assets', 'bananavxpe/libraries', 'bananavxpe/guis'} do
	if not isfolder(folder) then
		print("[BananaVape] Downloaded Folder: " .. folder)
		pcall(makefolder, folder)
	end
end

if not shared.VapeDeveloper then
	local commit = license.Commit or nil
	if not commit then
		local success, result = pcall(function() 
			return game:HttpGet('https://github.com/SolentraXminishakk/BananaVape') 
		end)
		if success and type(result) == "string" then
			local oidPos = result:find('currentOid')
			if oidPos then
				commit = result:sub(oidPos + 13, oidPos + 52)
				if type(commit) ~= "string" or #commit ~= 40 then
					commit = 'main'
				end
			else
				commit = 'main'
			end
		else
			commit = 'main'
		end
	end
	
	if type(commit) ~= "string" then
		commit = 'main'
	end
	
	local currentCommit = ''
	if isfile('bananavxpe/profiles/commit.txt') then
		currentCommit = readfile('bananavxpe/profiles/commit.txt')
	end
	
	if commit == 'main' or currentCommit ~= commit then
		if commit ~= 'main' and isfile('bananavxpe/profiles/commit.txt') then
			shared.updated = currentCommit
		end
	end
	writefile('bananavxpe/profiles/commit.txt', commit)
end

local mainContent = downloadFile('bananavxpe/main.lua')
if type(mainContent) ~= "string" or mainContent == "" then
	error("Failed to load main.lua, got: " .. type(mainContent))
end

local mainFunc = loadstring(mainContent, 'main')
if not mainFunc then
	error("Failed to compile main.lua")
end

return mainFunc(license)
