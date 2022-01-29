require "lfs"
local updater = {}
local print_raw = print_raw or print

updater.STATES = {
    kDownStart = "downloadStart",
    kDownDone = "downloadDone",
    kUncompressStart = "uncompressStart",
    kUncompressDone = "uncompressDone",
    unknown = "stateUnknown",
}

updater.ERRORS = {
    kCreateFile = "errorCreateFile",
    kNetwork = "errorNetwork",
    kNoNewVersion = "errorNoNewVersion",
    kUncompress = "errorUncompress",
    unknown = "errorUnknown";
}

function updater.isState(state)
    for k,v in pairs(updater.STATES) do
        if v == state then
            return true
        end
    end
    return false
end

function updater.clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function updater.vardump(object, label, returnTable)
    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local function _vardump(object, label, indent, nest)
        label = label or ""
        local postfix = ""
        if nest > 1 then postfix = "," end
        if type(object) ~= "table" then
            if type(label) == "string" then
                result[#result +1] = string.format("%s[\"%s\"] = %s%s", indent, label, _v(object), postfix)
            else
                result[#result +1] = string.format("%s%s%s", indent, _v(object), postfix)
            end
        elseif not lookupTable[object] then
            lookupTable[object] = true

            if type(label) == "string" then
                result[#result +1 ] = string.format("%s%s = {", indent, label)
            else
                result[#result +1 ] = string.format("%s{", indent)
            end
            local indent2 = indent .. "    "
            local keys = {}
            local values = {}
            for k, v in pairs(object) do
                keys[#keys + 1] = k
                values[k] = v
            end
            table.sort(keys, function(a, b)
                if type(a) == "number" and type(b) == "number" then
                    return a < b
                else
                    return tostring(a) < tostring(b)
                end
            end)
            for i, k in ipairs(keys) do
                _vardump(values[k], k, indent2, nest + 1)
            end
            result[#result +1] = string.format("%s}%s", indent, postfix)
        end
    end
    _vardump(object, label, "", 1)

    if returnTable then return result end
    return table.concat(result, "\n")
end

local u  = nil
local f = cc.FileUtils:getInstance()
-- The res index file in original package.
local lresinfo = "resinfo.md5"
local uroot = f:getWritablePath()
-- The directory for save updated files.
local ures = uroot.."res/"
---- The package zip file what download from server.
local uzip = ""
-- The directory for uncompress res.zip.
-- local utmp = uroot.."utmp/"
local utmp = uroot.."res/" --移除临时文件
-- The res index file in zip package for update.
local zresinfo = uroot.."resinfo.md5"

-- The res index file for final game.
-- It combiled original lresinfo and zresinfo.
local uresinfo = ures .. "resinfo.md5"

local localResInfo = nil
local remoteResInfo = nil
local finalResInfo = nil

local function _initUpdater()
    print_raw("initUpdater, ", u)
    if not u then u = Updater:new() end
    print_raw("after initUpdater:", u)
end

function updater.writeFile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function updater.readFile(path)
    --    return f:getFileData(path)
    local content = FTUtils:getFileDataWithoutDec(path)
    return content
end

function updater.exists(path)
    return f:isFileExist(path)
end

function updater.hex(s)
    s = string.gsub(s,"(.)",function (x) return string.format("%02X",string.byte(x)) end)
    return s
end

function updater.fileDataMd5(fileData)
    if fileData ~= nil then
        return CCCrypto:MD5Lua(updater.hex(fileData), false)
    else
        return nil
    end
end

function updater.fileMd5(filePath)
    local data = updater.readFile(filePath)
    return updater.fileDataMd5(data)
end

function updater.checkFileDataWithMd5(data, cryptoCode)
    if cryptoCode == nil then
        return true
    end

    local fMd5 = CCCrypto:MD5Lua(updater.hex(data), false)
    if fMd5 == cryptoCode then
        return true
    end

    return false
end

function updater.checkFileWithMd5(filePath, cryptoCode)
    if not updater.exists(filePath) then
        return false
    end
    local data = updater.readFile(filePath)
    if data == nil then
        return false
    end
    return updater.checkFileDataWithMd5(data, cryptoCode)
end

--[[
-- Departed, uses lfs instead.
function updater._mkdir(path)
_initUpdater()
return u:createDirectory(path)
end

-- Departed, get a warning in ios simulator
function updater._rmdir(path)
_initUpdater()
return u:removeDirectory(path)
end
--]]

function updater.mkdir(path)
    if not updater.exists(path) then
        return lfs.mkdir(path)
    end
    return true
end

function updater.rmdir(path)
    print_raw("updater.rmdir:", path)
    if updater.exists(path) then
        local function _rmdir(path)
            local iter, dir_obj = lfs.dir(path)
            while true do
                local dir = iter(dir_obj)
                if dir == nil then break end
                if dir ~= "." and dir ~= ".." then
                    local curDir = path..dir
                    local mode = lfs.attributes(curDir, "mode")
                    if mode == "directory" then
                        _rmdir(curDir.."/")
                    elseif mode == "file" then
                        os.remove(curDir)
                    end
                end
            end
            local succ, des = os.remove(path)
            if des then print_raw(des) end
            return succ
        end
        _rmdir(path)
    end
    return true
end

-- Is there a update.zip package in ures directory?
-- If it is true, return its abstract path.
function updater.hasNewUpdatePackage()
    local newUpdater = ures.."lib/update.zip"
    if updater.exists(newUpdater) then
        return newUpdater
    end
    return nil
end

function updater.maintainServer( reslua )
    localResInfo = updater.getLocalResInfo()
    remoteResInfo = reslua
end

-- Check local resinfo and remote resinfo, compare their version value.
function updater.checkUpdate(reslua)
    --删除本地document解压产生resinfo文件
    if f:isFileExist(zresinfo) then
        --Documents/resinfo.md5将其删除
        FTUtils:deleteFile(zresinfo)
    end
    localResInfo = updater.getLocalResInfo()
    local localVer = localResInfo.version
    updater.getRemoteResInfo(reslua)
    remoteResInfo = reslua
    if remoteResInfo and remoteResInfo.version then
        local remoteVer = remoteResInfo.version
        --如果大版本号不一致
        --新的app已经更新需要删除更新目录下的所有文件
        if compareVersion(FTUtils:getAppVersion(), localResInfo.version) == 1 then
            -- updater.rmdir(uroot .. 'res/')
            -- updater.rmdir(uroot .. 'publish/')
            --覆盖安装需要清楚一下内存信息
            local resInfoTxt = nil
            if updater.exists(uresinfo) then
                resInfoTxt = updater.readFile(uresinfo)
            else
                --再判断一次
                if f:isFileExist(zresinfo) then
                    --Documents/resinfo.md5将其删除
                    FTUtils:deleteFile(zresinfo)
                end
                if not f:isFileExist(ures) then
                    assert(updater.mkdir(ures), ures.." create error!")
                end
                local info = updater.readFile(lresinfo)
                assert(info, string.format("Can not get the constent from %s!", lresinfo))
                updater.writeFile(uresinfo, info)
                resInfoTxt = info
            end
            localResInfo = assert(loadstring(resInfoTxt))()
            localVer = localResInfo.version
        end
        print_raw("localVer:", localVer)
        print_raw("remoteVer:", remoteVer)
        if compareVersion(remoteVer, localVer) == 1 then
            return true
        else
            return false
        end
    else
        return nil
    end
end

function updater.getRemotePackageInfo()
    return remoteResInfo
end

-- Copy resinfo.lua from original package to update directory(ures)
-- when it is not in ures.
function updater.getLocalResInfo()
    --    print_raw(string.format("updater.getLocalResInfo, lresinfo:%s, uresinfo:%s",
    --        lresinfo,uresinfo))
    if not localResInfo then
        local resInfoTxt = nil
        if updater.exists(uresinfo) then
            resInfoTxt = updater.readFile(uresinfo)
        else
            --再判断一次
            if f:isFileExist(zresinfo) then
                --Documents/resinfo.md5将其删除
                FTUtils:deleteFile(zresinfo)
            end
            assert(updater.mkdir(ures), ures.." create error!")
            local info = updater.readFile(lresinfo)
            assert(info, string.format("Can not get the constent from %s!", lresinfo))
            updater.writeFile(uresinfo, info)
            resInfoTxt = info
        end
        localResInfo = assert(loadstring(resInfoTxt))()
    end
    return localResInfo
end

function updater.getRemoteResInfo(reslua)
    _initUpdater()
    -- print_raw("updater.getRemoteResInfo:", path)
    -- u:addRequestHeader('Host:'..updater.host)
    -- local resInfoTxt = u:getUpdateInfo(path)
    -- print_raw("resInfoTxt:", resInfoTxt)
    remoteResInfo = reslua
    -- return assert(loadstring(resInfoTxt))()
end

function updater.parseDomains( strInput,handler)
    _initUpdater() --初始化
    if handler then
        u:registerScriptHandler(handler)
    end
    u:preLoadDomains(strInput)
end

function updater.getNeededDownloadSize()
    assert(localResInfo and localResInfo.version, " localResInfo or local version is null!")
    if (not localResInfo) or (not localResInfo.version) then
        print_raw("updater.getNeededDownloadSize: local infor is null %s", tostring(localResInfo))
    end
    local filename = string.format('%s.zip',remoteResInfo.version)
    local zipFile = (uroot .. filename)
    local downloadedSize = u:getLocalFileLength(zipFile)
    if (downloadedSize == nil or  downloadedSize < 0) then downloadedSize = 0 end
    local totalSize = remoteResInfo['patches'][localResInfo.version]
    local dsize = checkint(totalSize) - checkint(downloadedSize)
    return dsize
end

function updater.removePatchZip()
    local filename = string.format('%s.zip.tmp',remoteResInfo.version) --需要删除临时文件
    local zipFile = (uroot .. filename)
    if f:isFileExist(zipFile) then
        FTUtils:deleteFile(zipFile)
    end
    local filenamezip = string.format('%s.zip',remoteResInfo.version) --需要删除临时文件
    local zipFile1 = (uroot .. filenamezip)
    if f:isFileExist(zipFile1) then
        FTUtils:deleteFile(zipFile1)
    end
end

function updater.update(handler, targetIp, host)
    assert(localResInfo and remoteResInfo and remoteResInfo.patchBaseURL, "Can not get remoteResInfo!")
    local packageUrl = remoteResInfo.patchBaseURL
    local filename = string.format('%s.zip',localResInfo.version)
    local t = {packageUrl,remoteResInfo.version, filename}
    local updateURL = table.concat(t,'/')
    local url = require('cocos.cocos2d.URL')
    local lurl = url.parse(updateURL):normalize()
    local targetURL = table.concat({'http://',targetIp,lurl.path},'')
    if USE_SSL then
        if string.find(targetIp, '^%d') then
            targetURL = table.concat({'http://',targetIp,lurl.path},'')
        else
            targetURL = table.concat({'https://',targetIp,lurl.path},'')
        end
    end
    -- print( "update url ===", targetURL )
    if handler then
        u:registerScriptHandler(handler)
    end
    -- updater.rmdir(utmp)
    local rfilename = string.format('%s.zip',remoteResInfo.version)
    uzip = (uroot .. rfilename)
    local totalSize = remoteResInfo['patches'][localResInfo.version]
    totalSize = checkint(totalSize)
    local downloadedSize = u:getLocalFileLength(uzip)
    -- print(downloadedSize,totalSize)
    if (downloadedSize == nil or  downloadedSize < 0) then downloadedSize = 0 end
    local needUnzip = 1
    if downloadedSize > totalSize then
        if f:isFileExist(uzip) then
            FTUtils:deleteFile(uzip)
        end
    elseif ((downloadedSize == totalSize) and (totalSize > 0)) then
        needUnzip = 0
    end
    if needUnzip == 1 then
        targetURL = string.format('%s?%d',targetURL,totalSize)
        if string.find(targetIp, '^%d') then
            host = lurl.host
            u:addRequestHeader('Host:'..host)
        end
        local app = cc.Application:getInstance()
        local target = app:getTargetPlatform()
        u:addRequestHeader("User-Agent:" .. table.concat({CCNative:getOpenUDID(),FTUtils:getAppVersion(),CCNative:getDeviceName(),target}, ";"))
        u:update(targetURL, uzip, uroot, false)
    else
        u:startUncompress(uzip,uroot,false)
    end
end

function updater.uploadErrorPackageInfo(event)
    local rfilename = string.format('%s.zip',remoteResInfo.version)
    uzip = (uroot .. rfilename)
    local size = io.filesize(uzip)
    local pathinfo = io.pathinfo(uzip)
    pathinfo[size] = tostring(size)
    pathinfo['event'] = tostring(event.event)
    if event.msg then
        pathinfo['emsg'] = tostring(event.msg)
    end
    local packageUrl = remoteResInfo.package
    local filename = string.format('%s.zip',localResInfo.version)
    local t = {packageUrl,remoteResInfo.version, filename}
    local updateURL = table.concat(t,'/')
    local url = require('cocos.cocos2d.URL')
    local targetURL = tostring(url.parse(updateURL):normalize())
    pathinfo[url] = targetURL
    local tstr = updater.vardump(pathinfo,'local data',true)
    local rstr = table.concat(tstr, "\n")
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if targetPlatform == cc.PLATFORM_OS_ANDROID then
        onLuaException(tostring(rstr),tostring(rstr))
    end
end

--[[--
过明api 废弃
--]]
-- function updater._copyNewFile(resInZip)
--     -- Create nonexistent directory in update res.
--     local i,j = 1,1
--     while true do
--         j = string.find(resInZip, "/", i)
--         if j == nil then break end
--         local dir = string.sub(resInZip, 1,j)
--         -- Save created directory flag to a table because
--         -- the io operation is too slow.
--         if not updater._dirList[dir] then
--             updater._dirList[dir] = true
--             local fullUDir = uroot..dir
--             updater.mkdir(fullUDir)
--         end
--         i = j+1
--     end
--     local fullFileInURes = uroot..resInZip
--     local fullFileInUTmp = utmp..resInZip
--     print_raw(string.format('copy %s to %s', fullFileInUTmp, fullFileInURes))
--     local zipFileContent = updater.readFile(fullFileInUTmp)
--     if zipFileContent then
--         updater.writeFile(fullFileInURes, zipFileContent)
--         return fullFileInURes
--     end
--     return nil
-- end

function updater._copyNewFilesBatch(resType, resInfoInZip)
    local resList = resInfoInZip[resType]
    if not resList then return end
    local finalRes = finalResInfo[resType]
    for k,v in pairs(resList) do
        -- local fullFileInURes = updater._copyNewFile(k)
        -- if fullFileInURes then
            -- Update key and file in the finalResInfo
            -- Ignores the update package because it has been in memory.
        if k ~= "res/lib/update.zip" then
            finalRes[k] = v
        end
        -- else
        --     print_raw(string.format("updater ERROR, copy file %s.", v))
        -- end
    end
end

function updater.updateFinalResInfo()
    assert(localResInfo and remoteResInfo,
        "Perform updater.checkUpdate() first!")
    if not finalResInfo then
        finalResInfo = updater.clone(localResInfo)
    end
    --do return end
    --资源更新包里面存在一个resinfo文件防止出问题
    local resInfoTxt = updater.readFile(zresinfo)
    local zipResInfo = assert(loadstring(resInfoTxt))()
    if zipResInfo["version"] then
        --更新本地版本号
        finalResInfo.version = zipResInfo["version"]
    end
    --[[不再需要了直接进行版本更新
    -- Save a dir list maked.
    -- updater._dirList = {}
    updater._copyNewFilesBatch("lib", zipResInfo)
    updater._copyNewFilesBatch("oth", zipResInfo)
    -- Clean dir list.
    --]]
    -- updater._dirList = nil
    --remove unzip temp resource information
    --再判断一次
    if f:isFileExist(zresinfo) then
        --Documents/resinfo.md5将其删除
        FTUtils:deleteFile(zresinfo)
    end
    -- updater.rmdir(utmp)
    local dumpTable = updater.vardump(finalResInfo, "local data", true)
    dumpTable[#dumpTable+1] = "return data"
    if updater.writeFile(uresinfo, table.concat(dumpTable, "\n")) then
        --remove zip file，文件写入完成后删除zip文件
        updater.removePatchZip()
        return true
    end
    return false
end

function updater.getResCopy()
    --    if finalResInfo then return updater.clone(finalResInfo) end
    --    return updater.clone(localResInfo)
    --改为只存一个版本信息号
    if finalResInfo then
        _G['aversion'] = finalResInfo.version
    else
        _G['aversion'] = localResInfo.version
    end
end

function updater.clean()
    if u then
        u:unregisterScriptHandler()
        u:delete()
        u = nil
    end
    -- updater.rmdir(utmp)
    localResInfo = nil
    remoteResInfo = nil
    finalResInfo = nil
end

return updater
