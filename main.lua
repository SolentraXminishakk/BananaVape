--!nocheck
local license = ... or {}
license.Key = script_key or license.Key or nil

repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

local vape
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local httpService = cloneref(game:GetService('HttpService'))

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
        
        local relativePath = path:gsub('bananavxpe/', '')
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
    local placeId = game.PlaceId
    local gameScriptPath = 'bananavxpe/games/'..placeId..'.lua'
    
    local knownGames = {
        6872274481, 6872265039, 8444591321, 8560631822, 606849621,
        5938036553, 893973440, 142823291, 155615604, 8542259458,
        8542275097, 8592115909, 8768229691, 8951451142, 13246639586,
        11156779721, 80041634734121, 77790193039862, 123804558118054,
        131465939650733, 135564683255158, 139566161526375,
    }
    
    local found = false
    for _, v in ipairs(knownGames) do
        if v == placeId then
            found = true
            break
        end
    end
    
    if not found then
        return false
    end
    
    local function executeScript(scriptContent, scriptName)
        if type(scriptContent) ~= "string" or scriptContent == "" then
            return false
        end
        
        local func, err = loadstring(scriptContent, scriptName)
        if not func then
            return false
        end
        
        local success, result = pcall(func, license)
        if success then
            return true
        end
        
        success, result = pcall(func)
        return success
    end
    
    if isfile(gameScriptPath) then
        local scriptContent = readfile(gameScriptPath)
        if type(scriptContent) == "string" and #scriptContent > 10 then
            local success = executeScript(scriptContent, tostring(placeId))
            if success then
                print("[BananaVape] Game script loaded")
                return true
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
        
        if suc and type(res) == "string" and res ~= '404: Not Found' and #res > 100 then
            if not res:find('This watermark') then
                res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
            end
            writefile(gameScriptPath, res)
            
            local success = executeScript(res, tostring(placeId))
            if success then
                print("[BananaVape] Downloaded and loaded game script")
                return true
            end
        end
    end
    
    return false
end

local function initialize()
    local folders = {
        'bananavxpe', 'bananavxpe/profiles', 'bananavxpe/games',
        'bananavxpe/libraries', 'bananavxpe/guis', 'bananavxpe/assets/new'
    }
    
    for _, folder in ipairs(folders) do
        if not isfolder(folder) then
            makefolder(folder)
        end
    end
    
    if not isfile('bananavxpe/profiles/gui.txt') then
        writefile('bananavxpe/profiles/gui.txt', 'new')
    end
    
    if not isfile('bananavxpe/profiles/commit.txt') then
        writefile('bananavxpe/profiles/commit.txt', 'main')
    end

    getgenv().used_init = true
    
    local guiContent = downloadFile('bananavxpe/guis/new.lua')
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
    error("Script failed to initialize: " .. tostring(err))
end
