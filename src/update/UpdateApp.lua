local UpdateApp = {}

UpdateApp.__cname = "UpdateApp"
UpdateApp.__index = UpdateApp
UpdateApp.__ctype = 2


require('config')
require('cocos.init')

function wwritefile(content, mode)
    local fileUtils = cc.FileUtils:getInstance()
    local dirpath = fileUtils:getWritablePath() .. "log/"
    if not fileUtils:isDirectoryExist(dirpath) then
        fileUtils:createDirectory(dirpath)
    end
    local path = dirpath .. 'trace.log'
    if path then
        mode = mode or "a"
        local file = io.open(path, mode)
        if file then
            if file:write((content .. '\n')) == nil then return false end
            io.close(file)
            return true
        else
            return false
        end
    end
end

Logger = require( "Frame.Log.logger" )
Logger.InitialLoggers(function()
    local console = require("Frame.Log.console")
    local disk = require("Frame.Log.disk")
    local config = {}
    if DEBUG > 0 then
        config['CONSOLE'] = Logger.new(console.new(), "CONSOLE", Logger.INFO)
    end
    config['FILE'] = Logger.new(disk.new("eater-%s.log", "%Y-%m-%d"),"FILE", Logger.ERROR)
    return config
end)

function funLog(level, message, traceback)
    local adapters = Logger.GetAdapters()
    for k, v in pairs(adapters) do
        v:Log(level, message, traceback)
    end
end

local sharedDirector = cc.CSceneManager:getInstance()
local sharedFileUtils = cc.FileUtils:getInstance()

local updater = require("update.updater")


function UpdateApp.new(...)
    local instance = setmetatable({}, UpdateApp)
    instance.class = UpdateApp
    instance:ctor(...)
    return instance
end

function UpdateApp:ctor(appName, packageRoot)
    self.name = appName
    self.packageRoot = packageRoot or appName
    funLog(Logger.DEBUG,string.format("UpdateApp.ctor, appName:%s, packageRoot:%s", self.name, self.packageRoot))
    -- set global app
    _G[self.name] = self
end

function UpdateApp:run(checkNewUpdatePackage)
    local newUpdatePackage = updater.hasNewUpdatePackage()
    funLog(Logger.DEBUG, string.format("UpdateApp.run(%s), newUpdatePackage:%s",
        tostring(checkNewUpdatePackage), tostring(newUpdatePackage)))
    if  checkNewUpdatePackage and newUpdatePackage then
        self:updateSelf(newUpdatePackage)
    else
        self:runUpdateScene(function()
            -- _G["finalRes"] = updater.getResCopy()
            updater.getResCopy()
            self:runRootScene()
        end)
    end
end

-- Remove update package, load new update package and run it.
function UpdateApp:updateSelf(newUpdatePackage)
    funLog(Logger.DEBUG, "UpdateApp.updateSelf ", newUpdatePackage)
    local updatePackage = {
        "update.UpdateApp",
        "update.updater",
        "update.UpdateScene",
    }
    self:_printPackages("--before clean")
    for __,v in ipairs(updatePackage) do
        package.preload[v] = nil
        package.loaded[v] = nil
    end
    self:_printPackages("--after clean")
    _G["update"] = nil
    cc.LuaLoadChunksFromZIP(newUpdatePackage)
    self:_printPackages("--after cc,LuaLoadChunksForZIP")
    require("update.UpdateApp").new("update"):run(false)
    self:_printPackages("--after require and run")
end

-- Show a scene for update.
function UpdateApp:runUpdateScene(handler)
    local scene = require("update.UpdateScene").addListener(handler)
    local t = scene.new()
    self:enterScene(t)
end

-- Load all of packages(except update package, it is not in finalRes.lib)
-- and run root
function UpdateApp:runRootScene()
    -- local works = {['res/lib/update.zip'] = 'res/lib/update.zip'}
    -- for v, __ in pairs(works) do
    --     cc.LuaLoadChunksFromZIP(v)
    -- end

    ---显示用户逻辑面板
    local function _printPackages(label, call)
        label = label or ""
        funLog(Logger.DEBUG, "\npring packages "..label.."------------------")
        local unloaded = {"config", "cocos.framework.display", "cocos.framework.utils"}
        for __k, __v in pairs( unloaded ) do
            package.preload[__v] = nil
            package.loaded[__v] = nil
            funLog(Logger.DEBUG, "package.preload:" .. tostring(__k) .. tostring(__v))
        end
        funLog(Logger.DEBUG, "\npring packages "..label.."------------------")
        call()
    end
    if SKIP_UPDATE then
        _printPackages("UpdateApp", function()
            require( "root.AppFacade" )
            AppFacade.GetInstance():StartUP()
        end)
    else
        _printPackages("UpdateApp", function()
            require( "root.AppFacade" )
            AppFacade.GetInstance():StartUP()
        end)
    end
end

function UpdateApp:_printPackages(label)
    label = label or ""
    funLog(Logger.DEBUG, "\npring packages "..label.."------------------")
    for __k, __v in pairs(package.preload) do
        funLog(Logger.DEBUG, "package.preload:" .. tostring(__k) .. tostring(__v))
    end
    for __k, __v in pairs(package.loaded) do
        funLog(Logger.DEBUG, "package.preload:" .. tostring(__k) .. tostring(__v))
    end
    funLog(Logger.DEBUG, "\npring packages "..label.."------------------")
end


function UpdateApp:exit()
    sharedDirector:endToLua()
    os.exit()
end

function UpdateApp:enterScene(__scene)
    -- sceneWorld:removeAllChildren()
    __scene:setPosition(display.center)
    sceneWorld:addChild(__scene, 10,10)
end

return UpdateApp
