--!nocheck
local license = ... or {}
license.Key = script_key or license.Key

local cloneref = cloneref or function(ref) return ref end

local delfile = delfile or function(file)
    pcall(function() writefile(file, '') end)
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
        
        local relativePath = path:gsub('bananavxpe/', '')
        local url = 'https://raw.githubusercontent.com/SolentraXminishakk/BananaVape/' .. commit .. '/' .. relativePath
        
        -- Wait a bit for HTTP service
        task.wait(0.1)
        
        local suc, res = pcall(function()
            return game:HttpGet(url, true)
        end)
        
        if not suc then
            warn("[BananaVape] HttpGet failed, retrying... " .. tostring(res))
            task.wait(0.5)
            suc, res = pcall(function()
                return game:HttpGet(url, true)
            end)
        end
        
        if not suc or res == '404: Not Found' then
            error(tostring(res or "Failed to download: " .. path))
        end
        
        if path:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
        end
        writefile(path, res)
    end
    return (func or readfile)(path)
end

for _, folder in {'bananavxpe', 'bananavxpe/games', 'bananavxpe/profiles', 'bananavxpe/assets', 'bananavxpe/libraries', 'bananavxpe/guis'} do
    if not isfolder(folder) then
        print("[BananaVape] Downloaded Folder: " .. folder)
        pcall(makefolder, folder)
    end
end

if not shared.VapeDeveloper then
    local commit = license.Commit or 'main'
    writefile('bananavxpe/profiles/commit.txt', commit)
end

if not isfile('bananavxpe/profiles/commit.txt') then
    writefile('bananavxpe/profiles/commit.txt', 'main')
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
