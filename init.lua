--!nocheck
local license = ... or {}
license.Key = script_key or license.Key

local cloneref = cloneref or function(ref) return ref end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		if not license.Closet then
			print("[BananaVape] Downloading: " .. path)
		end
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/'..readfile('bananavxpe/profiles/commit.txt')..'/'..select(1, path:gsub('bananavxpe/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
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
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local commit = license.Commit or nil
	if not commit then
		local _, subbed = pcall(function() 
			return game:HttpGet('https://github.com/SolentraXminishakk/BananaVape') 
		end)
		commit = subbed:find('currentOid')
		commit = commit and subbed:sub(commit + 13, commit + 52) or nil
		commit = commit and #commit == 40 and commit or 'main'
	end
	if commit == 'main' or (isfile('bananavxpe/profiles/commit.txt') and readfile('bananavxpe/profiles/commit.txt') or '') ~= commit then
		if commit ~= 'main' and isfile('bananavxpe/profiles/commit.txt') then
			shared.updated = readfile('bananavxpe/profiles/commit.txt')
		end
        -- wipeFolder('bananavxpe')
        -- wipeFolder('bananavxpe/games')
        -- wipeFolder('bananavxpe/guis')
        -- wipeFolder('bananavxpe/libraries')
	end
	writefile('bananavxpe/profiles/commit.txt', commit)
end

return loadstring(downloadFile('bananavxpe/main.lua'), 'main')(license)
