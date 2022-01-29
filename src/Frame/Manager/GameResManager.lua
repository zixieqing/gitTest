--[[
 * author : kaishiqi
 * descpt : 游戏资源 管理器
]]
local BaseManager    = require('Frame.Manager.ManagerBase')
---@class GameResManager
local GameResManager = class('GameResManager', BaseManager)

local PATH_PREFIX       = 'res/'
local PATH_PREFIX_LEN   = string.len(PATH_PREFIX)
local WRITABLE_PATH_LEN = string.len(device.writablePath)

local VERIFY_RESULT = {
    YES_VERIFY_CACHE     = 'yes verify cache',
    YES_SAME_FILE_MD5    = 'yes same md5',
    YES_UPDATE_FILE_MD5  = 'yes update md5',
    NOT_PATH_DEFINE      = 'not pathDefine',
    NOT_FILE_DEFINE      = 'not fileDefine',
    NOT_VALID_REMOTE_MD5 = 'not valid remote md5',
    NOT_EXIST_LOCAL_FILE = 'not exist local file',
    NOT_SAME_FILE_MD5    = 'not same file md5',
    NOT_INCLUDE_FILE     = 'not include file',
}


-------------------------------------------------
-- manager method

GameResManager.DEFAULT_NAME = 'GameResManager'
GameResManager.instances_   = {}


function GameResManager.GetInstance(instancesKey)
    instancesKey = instancesKey or GameResManager.DEFAULT_NAME

    if not GameResManager.instances_[instancesKey] then
        GameResManager.instances_[instancesKey] = GameResManager.new(instancesKey)
    end
    return GameResManager.instances_[instancesKey]
end


function GameResManager.Destroy(instancesKey)
    instancesKey = instancesKey or GameResManager.DEFAULT_NAME

    if GameResManager.instances_[instancesKey] then
        GameResManager.instances_[instancesKey]:release()
        GameResManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function GameResManager:ctor(instancesKey)
    self.super.ctor(self)

    if GameResManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function GameResManager:initial()
    self.verifyPassMap_  = {}  -- 验证通过的 map
    self.remoteDefines_  = {}  -- 远程资源信息定义
    self.localVerifyDB_  = self:openLocalVerifyDB_()  -- 资源验证 db
    self.localVerifyMap_ = self:dumpLocalVerifyDB_()  -- 本地验证 map
end


function GameResManager:release()
    if self.localVerifyDB_ then
        self.localVerifyDB_:close()
        self.localVerifyDB_ = nil
    end
end


-------------------------------------------------
-- public method

function GameResManager:setRemoteResJson(jsonZipData)
    if io.writefile(RES_JSON_ZIP_PATH, jsonZipData) then
        local resJsonStr    = FTUtils:getFileDataFromZip(RES_JSON_ZIP_PATH, 'res.json')
        local originJson    = json.decode(resJsonStr) or {}
        self.remoteDefines_ = originJson.resDefines or {}
        self.remoteAddress_ = originJson.urlAddress or ''
    else
        assert(false, "jsonZipData write faile !!")
    end
end


function GameResManager:getRemoteAddresss()
    return self.remoteAddress_ or ''
end


function GameResManager:isExistent(resPath)
    local isVerify, remoteDefine, verifyResult = self:verifyRes(resPath)
    return isVerify or remoteDefine ~= nil
end


--[[
    @eg ui/home/teamformation/newCell/team_bg_tianjiawan.png
    @return bool    is validity
    @return table   remoteDefine    {path : string, name : string, url : string}
    @return string  verify result
]]
function GameResManager:verifyRes(resPath, isForced)
    local originResPath = checkstr(resPath)
    local verifyResPath = originResPath

    -- check verify cache
    if self.verifyPassMap_[originResPath] ~= nil and not isForced then
        return  self.verifyPassMap_[originResPath], nil, VERIFY_RESULT.YES_VERIFY_CACHE
        
    else
        -- verify 'res/' prefix path
        local pathPreFix = string.sub(originResPath, 0, PATH_PREFIX_LEN)
        if pathPreFix == PATH_PREFIX then
            verifyResPath = string.sub(originResPath, PATH_PREFIX_LEN + 1, -1)
        end

        -- verify lang path
        local currLang = i18n.getLang()
        local filePath, fileName = self:filePathSplit_(verifyResPath)

        -- first verify lang path
        local isVerify, remoteDefine, verifyResult = self:verifyLocalFileMD5_(string.fmt('%1%2/', filePath, currLang), fileName)
        if isVerify or remoteDefine then
            if isVerify then
                self.verifyPassMap_[originResPath] = true
            end
            return isVerify, remoteDefine, verifyResult
        else
            isVerify, remoteDefine, verifyResult = self:verifyLocalFileMD5_(filePath, fileName)

            -- update verify cache
            if isVerify then
                self.verifyPassMap_[originResPath] = true
            else
                if remoteDefine == nil then
                    self.verifyPassMap_[originResPath] = false
                end
            end
            return isVerify, remoteDefine, verifyResult
        end
    end
end


--[[
    @eg 'cards/spine/avatar/200001'
    @eg 'ui/tower/team/spine/shengji'
    @return bool    is validity
    @return table   verify map
        {
            'atlas' = {isVerify: bool, remoteDefine: table, verifyResult: string},
            'json'  = {isVerify: bool, remoteDefine: table, verifyResult: string},
            'imgs'  = {
                {isVerify: bool, remoteDefine: table, verifyResult: string}, 
                ... 
            }
        }
]]
function GameResManager:verifySpine(spinePath, isForced)
    local originSpinePath = checkstr(spinePath)
    
    -- check verify cache
    if self.verifyPassMap_[originSpinePath] ~= nil and not isForced then
        return self.verifyPassMap_[originSpinePath], nil

    else
        local verifyMap = {}

        -- verify atlas file
        local isAtlasVerify, atlasRemoteDefine, atlasVerifyResult = self:verifyRes(spinePath .. '.atlas', isForced)
        verifyMap['atlas'] = {isVerify = isAtlasVerify, remoteDefine = atlasRemoteDefine, verifyResult = atlasVerifyResult}
        if isAtlasVerify then
            -- read atlas file
            local originPath, spineName = self:filePathSplit_(originSpinePath)
            local atlasPath  = atlasRemoteDefine and atlasRemoteDefine.path or originPath  -- atlasRemoteDefine.path 可能是带有 xxxx/lang/200001 的路径，所以优先使用和define一致的路径
            local isExistent = FTUtils:isPathExistent(atlasPath .. i18n.getLang() .. '/' .. spineName .. '.atlas')
            local atlasFile  = isExistent and FTUtils:getFileData(atlasPath .. i18n.getLang() .. '/' .. spineName .. '.atlas') or ''
            if not isExistent then
                isExistent = FTUtils:isPathExistent(atlasPath .. spineName .. '.atlas')
                atlasFile  = isExistent and FTUtils:getFileData(atlasPath .. spineName .. '.atlas') or ''
            end
            
            -- verify imgs file
            verifyMap['imgs']  = {}
            local isImgEmpties = true
            local isImgsVerify = true
            for i, line in ipairs(string.split2(atlasFile, '\n')) do
                if string.rtrim(FTUtils:getPathExtension(line)) == '.png' then
                    local isImgVerify, imgRemoteDefine, imgVerifyResult = self:verifyRes(atlasPath .. line, isForced)
                    table.insert(verifyMap['imgs'], {isVerify = isImgVerify, remoteDefine = imgRemoteDefine, verifyResult = imgVerifyResult})
                    if isImgVerify == false then
                        isImgsVerify = false
                    end
                    if imgRemoteDefine ~= nil then
                        isImgEmpties = false
                    end
                end
            end
            
            -- verify json file
            local isJsonVerify, jsonRemoteDefine, jsonVerifyResult = self:verifyRes(atlasPath .. spineName .. '.json', isForced)
            verifyMap['json'] = {isVerify = isJsonVerify, remoteDefine = jsonRemoteDefine, verifyResult = jsonVerifyResult}

            -- update verify cache
            local isSpineVerify = isJsonVerify and isImgsVerify and #verifyMap['imgs'] > 0
            if isSpineVerify then
                self.verifyPassMap_[originSpinePath] = true
            else
                if atlasRemoteDefine == nil and jsonRemoteDefine == nil and isImgEmpties == true then
                    self.verifyPassMap_[originSpinePath] = false
                end
            end
            return isSpineVerify, verifyMap

        else
            return false, verifyMap
        end
    end
end


--[[
    @eg ui/tower/path/particle/chest_show.plist
    @return bool  is validty
    @return table verify map
        {
            'plist' = {isVerify: bool, remoteDefine: table, verifyResult: string},
            if plist['textureImageData'] == nil then
                'image' = {isVerify: bool, remoteDefine: table, verifyResult: string},
            else
                'image' = nil
            end
        }
]]
function GameResManager:verifyParticle(particlePath, isForced)
    local originParticlePath = checkstr(particlePath)

    -- check verify cache
    if self.verifyPassMap_[originParticlePath] ~= nil and not isForced then
        return self.verifyPassMap_[originParticlePath], nil

    else
        local verifyMap = {}

        -- verify plist file
        local isPListVerify, plistRemoteDefine, plistVerifyResult = self:verifyRes(originParticlePath, isForced)
        verifyMap['plist'] = {isVerify = isPListVerify, remoteDefine = plistRemoteDefine, verifyResult = plistVerifyResult}

        if isPListVerify then
            -- read plist file
            local originPath, particleName = self:filePathSplit_(originParticlePath)
            local plistPath = plistRemoteDefine and plistRemoteDefine.path or originPath  -- plistRemoteDefine.path 可能是带有 xxxx/lang/xxx.plist 的路径，所以优先使用和define一致的路径
            local plistDict = app.fileUtils:getValueMapFromFile(plistPath .. particleName) or {}

            -- check particle image
            if plistDict['textureImageData'] == nil then
                local imagePath = plistPath .. tostring(plistDict['textureFileName'])
                
                -- verify image file
                local isImageVerify, imageRemoteDefine, imageVerifyResult = self:verifyRes(imagePath, isForced)
                verifyMap['image'] = {isVerify = isImageVerify, remoteDefine = imageRemoteDefine, verifyResult = imageVerifyResult}

                -- update verify cache
                local isParticleVerify = isImageVerify
                if isParticleVerify then
                    self.verifyPassMap_[originParticlePath] = true
                else
                    if plistRemoteDefine == nil and imageRemoteDefine == nil then
                        self.verifyPassMap_[originParticlePath] = false
                    end
                end
                return isParticleVerify, verifyMap

            else
                -- update verify cache
                if isPListVerify then
                    self.verifyPassMap_[originParticlePath] = true
                else
                    if plistRemoteDefine == nil then
                        self.verifyPassMap_[originParticlePath] = false
                    end
                end
                return isPListVerify, verifyMap
            end

        else
            return false, verifyMap
        end
    end
end


-------------------------------------------------
-- private method

function GameResManager:openLocalVerifyDB_()
    if not DYNAMIC_LOAD_MODE then return nil end
    local dbStore   = RES_VERIFY_DB_PATH
    local sqlite3   = require('lsqlite3')
    local dbHandler = sqlite3.open(dbStore)
    if dbHandler and dbHandler:isopen() then
        local result = dbHandler:exec[=[
            create table `verify` (
                `id` INTEGER PRIMARY KEY,
                `name` TEXT,
                `md5` TEXT
            );
        ]=]
        return dbHandler
    else
        return nil
    end
end


function GameResManager:dumpLocalVerifyDB_()
    local localVerifyMap = {}
    if self.localVerifyDB_ then
        local sqlQuery = 'select * from verify'
        for row in self.localVerifyDB_:nrows(sqlQuery) do
            localVerifyMap[tostring(row.name)] = checkstr(row.md5)
        end
    end
    return localVerifyMap
end


function GameResManager:checkLocalVerifyDbNameID_(name)
    local sqlResult = {}
    local sqlQuery  = string.fmt('select * from verify t where(t.name == "%1") order by id DESC limit 1;', tostring(name))
    if self.localVerifyDB_ then
        for row in self.localVerifyDB_:nrows(sqlQuery) do
            table.insert(sqlResult, row)
        end
    end
    return #sqlResult > 0 and checkint(sqlResult[1].id) or 0
end


function GameResManager:insertLocalVerifyDbData_(name, md5)
    if self.localVerifyDB_ then
        self.localVerifyDB_:exec('begin;')
        local pstmtObj = self.localVerifyDB_:prepare('insert into verify(name, md5) values(?,?);')
        pstmtObj:bind(1, tostring(name))
        pstmtObj:bind(2, tostring(md5))
        pstmtObj:step()
        pstmtObj:reset()
        self.localVerifyDB_:exec('commit;')
        pstmtObj:finalize()
    end
end


function GameResManager:updateLocalVerifyDbData_(id, md5)
    if self.localVerifyDB_ then
        self.localVerifyDB_:exec('begin;')
        local pstmtObj = self.localVerifyDB_:prepare('update verify set md5 = ? where id = ?;')
        pstmtObj:bind(1, tostring(md5))
        pstmtObj:bind(2, checkint(id))
        pstmtObj:step()
        pstmtObj:reset()
        self.localVerifyDB_:exec('commit;')
        pstmtObj:finalize()
    end
end


function GameResManager:verifyLocalFileMD5_(filePath, fileName)
    -- logInfo.add(5, string.fmt('verifyLocalFileMD5_ %1 %2', filePath, fileName))
    local definePath = string.len(checkstr(filePath)) == 0 and '#' or checkstr(filePath)
    local pathDefine = self.remoteDefines_[definePath]
    
    -- check path define
    if pathDefine then

        -- check file define
        local convertName = self:checkRemoteFileType_(fileName, pathDefine)
        local fileDefine  = pathDefine[convertName]
        if fileDefine then

            -- update fileDefine data
            fileDefine.path = filePath
            fileDefine.name = convertName
            fileDefine.url  = self:getRemoteAddresss() .. filePath .. convertName

            -- check md5 validity
            local remoteMD5 = checkstr(fileDefine.md5)
            local localPath = filePath .. convertName
            local cacheMD5  = checkstr(self.localVerifyMap_[localPath])
            if string.len(remoteMD5) > 0 then

                -- check same md5
                if cacheMD5 == remoteMD5 then
                    return true, fileDefine, VERIFY_RESULT.YES_SAME_FILE_MD5
    
                else
                    -- check has local file
                    if FTUtils:isPathExistent(localPath) then

                        -- check package include file（由于 crypto.md5file 方法无法读取包体内文件，所以需要避开验证包体内自带文件）
                        local absolutePath = app.fileUtils:fullPathForFilename(localPath)
                        local absoluteRoot = string.sub(absolutePath, 1, WRITABLE_PATH_LEN)
                        if absoluteRoot == device.writablePath then

                            -- get local file md5
                            local localMD5 = crypto.md5file(app.fileUtils:fullPathForFilename(localPath))
                            if localMD5 == remoteMD5 then
                                
                                -- update localVerifyMap
                                self.localVerifyMap_[localPath] = remoteMD5

                                -- update localVerifyDB
                                local localVerifyDbNameID = self:checkLocalVerifyDbNameID_(localPath)
                                if localVerifyDbNameID > 0 then
                                    self:updateLocalVerifyDbData_(localVerifyDbNameID, remoteMD5)
                                else
                                    self:insertLocalVerifyDbData_(localPath, remoteMD5)
                                end

                                return true, fileDefine, VERIFY_RESULT.YES_UPDATE_FILE_MD5

                            else
                                return false, fileDefine, VERIFY_RESULT.NOT_SAME_FILE_MD5
                            end

                        else
                            return FTUtils:isPathExistent(utils.getFileName(filePath .. fileName)), nil, VERIFY_RESULT.NOT_INCLUDE_FILE
                        end

                    else
                        return false, fileDefine, VERIFY_RESULT.NOT_EXIST_LOCAL_FILE
                    end
                end

            else
                return FTUtils:isPathExistent(utils.getFileName(filePath .. fileName)), nil, VERIFY_RESULT.NOT_VALID_REMOTE_MD5
            end

        else
            return FTUtils:isPathExistent(utils.getFileName(filePath .. fileName)), nil, VERIFY_RESULT.NOT_FILE_DEFINE
        end

    else
        return FTUtils:isPathExistent(utils.getFileName(filePath .. fileName)), nil, VERIFY_RESULT.NOT_PATH_DEFINE
    end
end


--[[
    @see utils.getFileName
]]
function GameResManager:checkRemoteFileType_(fileName, pathDefine)
    if string.find(fileName, '.ccz') or string.find(fileName, '.plist') or string.find(fileName, '.atlas') then
        return fileName
    elseif string.find(fileName, '.json.zip') then
        return fileName
    elseif string.find(fileName, '.json') then
        if pathDefine[fileName .. '.zip'] then
            return fileName .. '.zip'
        end
    else
        local shortName = FTUtils:deletePathExtension(fileName)
        if pathDefine[shortName .. '.pvr.ccz'] then
            return shortName .. '.pvr.ccz'
        elseif pathDefine[shortName .. '.png'] then
            return shortName .. '.png'
        elseif pathDefine[shortName .. '.jpg'] then
            return shortName .. '.jpg'
        end
    end
    return fileName
end


--[[
    @eg ui/tower/path/tower_bg_2_front.png --> 'ui/tower/path/', 'tower_bg_2_front.png'
    @eg test.json --> '', 'test.json'
    @return1 filePath
    @return2 fileName
]]
function GameResManager:filePathSplit_(filePath)
    local filePath = checkstr(filePath)
    local lastPos  = 0
    for st, sp in function() return string.find(filePath, '/', lastPos, true) end do
        lastPos = sp + 1
    end
    local fileName = string.sub(filePath, lastPos)
    local filePath = lastPos == 0 and '' or string.sub(filePath, 1, lastPos - 1)
    return filePath, fileName
end


return GameResManager
