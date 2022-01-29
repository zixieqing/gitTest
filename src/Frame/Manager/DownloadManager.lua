--[[
 * author : kaishiqi
 * descpt : 下载 管理器
]]
local BaseManager     = require('Frame.Manager.ManagerBase')
---@class DownloadManager
local DownloadManager = class('DownloadManager', BaseManager)

local FAIL_RETRY_COUNT  = 3    -- 重试次数，超过当做下载失败
local WRITE_FILE_TIMES  = 30   -- 写文件次数，超过当做写入失败
local DOWNLOAD_INTERVAL = 0.2  -- 下载间隔
local OLD_RES_PATH_LEN  = string.len(RES_ABSOLUTE_PATH)


-------------------------------------------------
-- DownloadTaskVO : value object

local DownloadTaskVOType = {
    BASE = 0,
    URL  = 1,
    RES  = 2,
}

local DownloadTaskBaseVO = function(args)
    return {
        downloadId   = checkstr(args.taskId),    -- 自身的 下载任务id
        prevTaskId   = checkstr(args.prevId),    -- 上一个 下载任务id（链表结构）
        nextTaskId   = checkstr(args.nextId),    -- 下一个 下载任务id（链表结构）
        eventName    = args.eventName,           -- 下载事件
        ownerName    = args.ownerName,           -- 所属队列
        customData   = args.customData,          -- 自定数据
        retryCount   = 0,                        -- 重试次数
        retainCount  = 1,                        -- 任务次数
        downloadData = nil,                      -- 下载数据
        isDownloaded = false,                    -- 是否下完
        voType       = DownloadTaskVOType.BASE,  -- vo类型
    }
end

local DownloadTaskUrlVO = function(args)
    local taskBaseVO = DownloadTaskBaseVO(args)
    taskBaseVO.voType    = DownloadTaskVOType.URL
    taskBaseVO.writePath = args.writePath  -- 写入路径
    taskBaseVO.writeName = args.writeName  -- 写入名字
    taskBaseVO.targetUrl = args.targetUrl  -- 下载地址
    return taskBaseVO
end

local DownloadTaskResVO = function(args)
    local taskBaseVO = DownloadTaskBaseVO(args)
    taskBaseVO.voType        = DownloadTaskVOType.RES
    taskBaseVO.resType       = args.resType        -- 资源类型
    taskBaseVO.resPath       = args.resPath        -- 资源地址
    taskBaseVO.progressEvent = args.progressEvent  -- 进度事件
    taskBaseVO.remoteDefine  = nil                 -- {path : string, name : string, url : string}
    return taskBaseVO
end


-------------------------------------------------
-- DownloadTaskQueue : class

local DownloadTaskQueue = class('DownloadTaskQueue')

function DownloadTaskQueue:ctor(name)
    self.taskQuestName_   = name
    self.downloadTaskMap_ = {}
    self.firstDownloadId_ = nil
    self.lastDownloadId_  = nil
end


function DownloadTaskQueue:getName()
    return self.taskQuestName_
end


function DownloadTaskQueue:isClearTask()
    return next(self.downloadTaskMap_) == nil
end


function DownloadTaskQueue:getTopTask()
    return self.downloadTaskMap_[self.firstDownloadId_]
end


function DownloadTaskQueue:hasTask(taskId)
    return self.downloadTaskMap_[checkstr(taskId)] ~= nil
end


function DownloadTaskQueue:addUrlTask(url, eventName, writePath, writeName, customData)
    if url == '' then return end

    local downloadUrl = checkstr(url)
    local taskUrlVO = DownloadTaskUrlVO({
        taskId    = downloadUrl,
        targetUrl = downloadUrl,
        writePath = writePath,
        writeName = writeName,
    })
    self:addTaskVO_(taskUrlVO, eventName, customData)
end


function DownloadTaskQueue:addResTask(resType, resPath, eventName, progressEvent, customData)
    if resPath == '' then return end

    local taskResVO = DownloadTaskResVO({
        taskId        = resPath,
        resType       = resType,
        resPath       = resPath,
        progressEvent = progressEvent,
    })
    self:addTaskVO_(taskResVO, eventName, customData)
end


function DownloadTaskQueue:addTaskVO_(taskVO, eventName, customData)
    if not taskVO then return end

    local newTaskId = taskVO.downloadId
    local oldTaskVO = self.downloadTaskMap_[newTaskId]

    if oldTaskVO then
        -- update retainCount
        oldTaskVO.retainCount = oldTaskVO.retainCount + 1

    else
        -- update laskTaskVO.nextTaskId
        local lastTaskVO  = self.downloadTaskMap_[self.lastDownloadId_]
        if lastTaskVO then
            lastTaskVO.nextTaskId = newTaskId
        end

        -- add new taskVO
        taskVO.customData  = customData
        taskVO.eventName   = eventName
        taskVO.ownerName   = self:getName()
        taskVO.prevTaskId  = lastTaskVO and lastTaskVO.downloadId or ''
        self.downloadTaskMap_[newTaskId] = taskVO

        -- udpate firstDownloadId
        if not self.firstDownloadId_ or self.firstDownloadId_ == '' then
            self.firstDownloadId_ = newTaskId
        end

        -- update lastDownloadId
        self.lastDownloadId_ = newTaskId
    end
end


function DownloadTaskQueue:delTask(taskId)
    if not self:hasTask(taskId) then return end

    local killTaskVO = self.downloadTaskMap_[taskId]
    if killTaskVO then
        killTaskVO.retainCount = killTaskVO.retainCount - 1

        if killTaskVO.retainCount <= 0 then
            self:cleanTask(taskId)
        end
    end
end


function DownloadTaskQueue:cleanTask(taskId)
    if not self:hasTask(taskId) then return end

    -- delete taskVO
    local killTaskVO  = self.downloadTaskMap_[taskId] or {}
    local prevTaskVO  = self.downloadTaskMap_[killTaskVO.prevTaskId]
    local nextTaskVO  = self.downloadTaskMap_[killTaskVO.nextTaskId]
    if prevTaskVO then
        prevTaskVO.nextTaskId = nextTaskVO and nextTaskVO.downloadId or ''
    end
    if nextTaskVO then
        nextTaskVO.prevTaskId = prevTaskVO and prevTaskVO.downloadId or ''
    end

    -- update firstDownloadId
    if self.firstDownloadId_ == taskId then
        self.firstDownloadId_ = killTaskVO.nextTaskId or ''
    end

    -- update lastDownloadId
    if self.lastDownloadId_ == taskId then
        self.lastDownloadId_ = killTaskVO.prevTaskId or ''
    end

    self.downloadTaskMap_[taskId] = nil
end


-------------------------------------------------
-------------------------------------------------
-- manager method

DownloadManager.DEFAULT_NAME = 'DownloadManager'
DownloadManager.instances_   = {}


function DownloadManager.GetInstance(instancesKey)
    instancesKey = instancesKey or DownloadManager.DEFAULT_NAME

    if not DownloadManager.instances_[instancesKey] then
        DownloadManager.instances_[instancesKey] = DownloadManager.new(instancesKey)
    end
    return DownloadManager.instances_[instancesKey]
end


function DownloadManager.Destroy(instancesKey)
    instancesKey = instancesKey or DownloadManager.DEFAULT_NAME

    if DownloadManager.instances_[instancesKey] then
        DownloadManager.instances_[instancesKey]:release()
        DownloadManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function DownloadManager:ctor(instancesKey)
    self.super.ctor(self)

    if DownloadManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function DownloadManager:initial()
    self.downloadingTaskVO_   = nil
    self.foregroundTaskQueue_ = DownloadTaskQueue.new('fore')
    self.backgroundTaskQueue_ = DownloadTaskQueue.new('back')
    self:startDownloadUpdate_()
end


function DownloadManager:release()
    self:stopDownloadUpdate_()
    self.downloadingTaskVO_ = nil
end


-------------------------------------------------
-- public method

function DownloadManager:isDownloading()
    return self.downloadingTaskVO_ ~= nil
end


--[[
    @param url string        下载地址
    @param eventName string  下载结束事件（失败&成功）
    @param writePath string  写文件路径（可选）
    @param writeFile string  写文件名字（可选）
    @param customData any    自定义数据（可选）
]]
function DownloadManager:addUrlTask(url, eventName, writePath, writeName, customData)
    self.foregroundTaskQueue_:addUrlTask(url, eventName, writePath, writeName, customData)
end
function DownloadManager:addUrlLazyTask(url, eventName, writePath, writeName, customData)
    self.backgroundTaskQueue_:addUrlTask(url, eventName, writePath, writeName, customData)
end

function DownloadManager:delUrlTask(url)
    self.foregroundTaskQueue_:delTask(url)
end
function DownloadManager:delUrlLazyTask(url)
    self.backgroundTaskQueue_:delTask(url)
end

function DownloadManager:cleanUrlTask(url)
    self.foregroundTaskQueue_:cleanTask(url)
end
function DownloadManager:cleanUrlLazyTask(url)
    self.backgroundTaskQueue_:cleanTask(url)
end


function DownloadManager:addResTask(resData, eventName, progressEvent, customData)
    local resPath = tostring(resData)
    local resType = type(resData) == 'string' and RES_TYPE.FILE or tostring(resData.type)
    self.foregroundTaskQueue_:addResTask(resType, resPath, eventName, progressEvent, customData)
end
function DownloadManager:addResLazyTask(resData, eventName, progressEvent, customData)
    local resPath = tostring(resData)
    local resType = type(resData) == 'string' and RES_TYPE.FILE or tostring(resData.type)
    self.backgroundTaskQueue_:addResTask(resType, resPath, eventName, progressEvent, customData)
end

function DownloadManager:delResTask(resPath)
    self.foregroundTaskQueue_:delTask(resPath)
end
function DownloadManager:delResLazyTask(resPath)
    self.backgroundTaskQueue_:delTask(resPath)
end

function DownloadManager:cleanResTask(resPath)
    self.foregroundTaskQueue_:cleanTask(resPath)
end
function DownloadManager:cleanResLazyTask(resPath)
    self.backgroundTaskQueue_:cleanTask(resPath)
end


function DownloadManager:cleanTask(taskVO)
    if not taskVO then return end
    
    local isForeTask = taskVO.ownerName == self.foregroundTaskQueue_:getName()
    if taskVO.voType == DownloadTaskVOType.URL then
        if isForeTask then
            self:cleanUrlTask(taskVO.targetUrl)
        else
            self:cleanUrlLazyTask(taskVO.targetUrl)
        end
        
    elseif taskVO.voType == DownloadTaskVOType.RES then
        if isForeTask then
            self:cleanResTask(taskVO.resPath)
        else
            self:cleanResLazyTask(taskVO.resPath)
        end
    end
end


-------------------------------------------------
-- private method

function DownloadManager:updateResTaskStatus_(resTaskVO)
    if not resTaskVO then return end

    local resTaskPath  = resTaskVO.resPath
    local resTaskType  = resTaskVO.resType
    local oldResDefine = resTaskVO.remoteDefine
    local newResDefine = nil

    -- file type
    if resTaskType == RES_TYPE.FILE then
        local isVerify, remoteDefine = app.gameResMgr:verifyRes(resTaskPath)
        if isVerify then
            resTaskVO.isDownloaded = true
        else
            newResDefine = remoteDefine
        end

    -- spine type
    elseif resTaskType == RES_TYPE.SPINE then
        local isVerify, verifyMap = app.gameResMgr:verifySpine(resTaskPath)
        if isVerify then
            resTaskVO.isDownloaded = true
        else
            if verifyMap then
                local atlasVerifyMap = verifyMap['atlas']
                if not newResDefine and atlasVerifyMap and not atlasVerifyMap.isVerify then
                    newResDefine = atlasVerifyMap.remoteDefine
                end

                local jsonVerifyMap = verifyMap['json']
                if not newResDefine and jsonVerifyMap and not jsonVerifyMap.isVerify then
                    newResDefine = jsonVerifyMap.remoteDefine
                end

                local imgsVerifyList = verifyMap['imgs']
                if not newResDefine and imgsVerifyList then
                    for _, imgVerifyMap in pairs(imgsVerifyList) do
                        if not imgVerifyMap.isVerify then
                            newResDefine = imgVerifyMap.remoteDefine
                            break
                        end
                    end
                end
            end
        end

    -- particle type
    elseif resTaskType == RES_TYPE.PARTICLE then
        local isVerify, verifyMap = app.gameResMgr:verifyParticle(resTaskPath)
        if isVerify then
            resTaskVO.isDownloaded = true
        else
            if verifyMap then
                local plistVerifyMap = verifyMap['plist']
                if not newResDefine and plistVerifyMap and not plistVerifyMap.isVerify then
                    newResDefine = plistVerifyMap.remoteDefine
                end

                local imageVerifyMap = verifyMap['image']
                if not newResDefine and imageVerifyMap and not imageVerifyMap.isVerify then
                    newResDefine = imageVerifyMap.remoteDefine
                end
            end
        end
    end

    -- check new download
    if oldResDefine and newResDefine and oldResDefine.url ~= newResDefine.url then
        resTaskVO.retryCount = 0
    end

    -- update remoteDefine
    resTaskVO.remoteDefine = newResDefine
end


function DownloadManager:checkResTaskVerify_(resTaskVO)
    if not resTaskVO then return false end

    local resTaskPath = resTaskVO.resPath
    local resTaskType = resTaskVO.resType

    if resTaskType == RES_TYPE.FILE then
        return app.gameResMgr:verifyRes(resTaskPath)

    elseif resTaskType == RES_TYPE.SPINE then
        return app.gameResMgr:verifySpine(resTaskPath)

    elseif resTaskType == RES_TYPE.PARTICLE then
        return app.gameResMgr:verifyParticle(resTaskPath)

    end
    return false
end


function DownloadManager:startDownloadUpdate_()
    if self.downloadUpdateHandler_ then return end
    self.downloadUpdateHandler_ = scheduler.scheduleGlobal(function()
        if not self:isDownloading() then
            
            -- foreground first
            if not self.foregroundTaskQueue_:isClearTask() then
                self.downloadingTaskVO_ = self.foregroundTaskQueue_:getTopTask()
            elseif not self.backgroundTaskQueue_:isClearTask() then
                self.downloadingTaskVO_ = self.backgroundTaskQueue_:getTopTask()
            end
            
            -- to download firstTask
            if self.downloadingTaskVO_ then
                local downloadTaskUrl = ''
                
                -- check taskType
                if self.downloadingTaskVO_.voType == DownloadTaskVOType.URL then
                    downloadTaskUrl = checkstr(self.downloadingTaskVO_.targetUrl)

                elseif self.downloadingTaskVO_.voType == DownloadTaskVOType.RES then
                    self:updateResTaskStatus_(self.downloadingTaskVO_)
                    if self.downloadingTaskVO_.remoteDefine then
                        downloadTaskUrl = checkstr(self.downloadingTaskVO_.remoteDefine.url)
                    end
                end

                -- check taskUrl
                if string.len(downloadTaskUrl) > 0 then
                    -- check retry count
                    if self.downloadingTaskVO_.retryCount >= FAIL_RETRY_COUNT then
                        self:downloadFailed_(self.downloadingTaskVO_, 'retry count exceed', downloadTaskUrl)

                        -- clean downloadingTask
                        self.downloadingTaskVO_ = nil

                    else
                        -- request download
                        local xhr        = cc.XMLHttpRequest:new()
                        xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
                        xhr.timeout      = 60
                        xhr:open("GET", downloadTaskUrl)
                        xhr:registerScriptHandler(function()
                            -- update taskVO data
                            if self.downloadingTaskVO_ then
                                logs('[downloadMgr]', string.fmt('%1 <<< : %2', self.downloadingTaskVO_.ownerName, string.sub(downloadTaskUrl, -65)))
                            
                                self.downloadingTaskVO_.retryCount   = self.downloadingTaskVO_.retryCount + 1
                                self.downloadingTaskVO_.downloadData = xhr.response
                            end
                            
                            -- check download done
                            if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
                                if self:checkDownloadFinished_(self.downloadingTaskVO_) then

                                    if self.downloadingTaskVO_.voType == DownloadTaskVOType.RES then
                                        if self:checkResTaskVerify_(self.downloadingTaskVO_) then
                                            self:downloadSucceed_(self.downloadingTaskVO_)
                                        else
                                            self:downloadProgress_(self.downloadingTaskVO_)
                                        end

                                    else
                                        self:downloadSucceed_(self.downloadingTaskVO_)
                                    end

                                else
                                    self:downloadFailed_(self.downloadingTaskVO_, 'write times exceed', downloadTaskUrl)
                                end
                            end

                            -- clean downloadingTask
                            self.downloadingTaskVO_ = nil
                        end)
                        logs('[downloadMgr]', string.fmt('%1 >>> : %2', self.downloadingTaskVO_.ownerName, string.sub(downloadTaskUrl, -65)))
                        xhr:send()
                    end

                else
                    if self.downloadingTaskVO_.isDownloaded then
                        self:downloadSucceed_(self.downloadingTaskVO_)
                    else
                        self:downloadFailed_(self.downloadingTaskVO_, 'url invalid', self.downloadingTaskVO_.resPath)
                    end

                    -- clean downloadingTask
                    self.downloadingTaskVO_ = nil
                end

            end
        end
    end, DOWNLOAD_INTERVAL)
end


function DownloadManager:stopDownloadUpdate_()
    if self.downloadUpdateHandler_ then
        scheduler.unscheduleGlobal(self.downloadUpdateHandler_)
        self.downloadUpdateHandler_ = nil
    end
end


function DownloadManager:checkDownloadFinished_(taskVO)
    if not taskVO then return end
    local writeTimes = 0
    local writePath  = nil
    local writeName  = nil
    local writeData  = taskVO.downloadData

    if taskVO.voType == DownloadTaskVOType.URL then
        writePath = taskVO.writePath
        writeName = taskVO.writeName
        
    elseif taskVO.voType == DownloadTaskVOType.RES and taskVO.remoteDefine then
        local localFilePath   = tostring(taskVO.remoteDefine.path) .. taskVO.remoteDefine.name
        local oldAbsolutePath = app.fileUtils:fullPathForFilename(localFilePath)
        local oldAbsoluteRoot = string.sub(oldAbsolutePath, 1, OLD_RES_PATH_LEN)

        if oldAbsoluteRoot == RES_ABSOLUTE_PATH then
            --[[
                需要删除可写目录中的旧文件。原因：
                一开始热更资源会写入到 res 目录；
                后期该资源支持了动态下载，写入时就需要先移除 res 目录中旧的，向 res_sub 目录写入新的；
                这样才能保证检索文件正确，因为 res 比 res_sub 索引优先级别高。
            ]]
            utils.deleteFile(oldAbsolutePath)
            --[[
                删除文件的同时，必须清理一次搜索缓存。原因：
                如果不清楚搜索缓存，外面 getFullPath 的时候依然会直接返回 res 的目录；
                但是这时候文件已经不存在了，被重新写入到 res_sub 目录中了，所以需要清空重新建立检索缓存。
            ]]
            app.fileUtils:purgeCachedEntries()
        end
        
        writePath = RES_SUB_ABSOLUTE_PATH .. tostring(taskVO.remoteDefine.path)
        writeName = taskVO.remoteDefine.name
    end
    
    -- check write file
    if writePath and writeName and writeData then
        local fileUtils = cc.FileUtils:getInstance()
        if not fileUtils:isFileExist(writePath) then
            fileUtils:createDirectory(writePath)
        end
        
        local fileStore = writePath .. writeName
        while (not io.writefile(fileStore, writeData) and writeTimes < WRITE_FILE_TIMES) do
            writeTimes = writeTimes + 1
        end
    end

    return writeTimes < WRITE_FILE_TIMES
end


function DownloadManager:downloadProgress_(taskVO)
    if not taskVO then return end
    
    if taskVO.progressEvent then
        AppFacade.GetInstance():DispatchObservers(taskVO.progressEvent, taskVO)
    end
end


function DownloadManager:downloadSucceed_(taskVO)
    if not taskVO then return end

    taskVO.isDownloaded = true
    self:cleanTask(taskVO)

    if taskVO.eventName then
        AppFacade.GetInstance():DispatchObservers(taskVO.eventName, taskVO)
    end
end


function DownloadManager:downloadFailed_(taskVO, descr, url)
    if not taskVO then return end

    -- write error log
    funLog(Logger.ERROR, string.fmt('[ downloadFailed: %1 ]', tostring(descr)), '--')
    funLog(Logger.ERROR, string.sub(url or '', -65), nil)

    taskVO.isDownloaded = false
    self:cleanTask(taskVO)

    if taskVO.eventName then
        AppFacade.GetInstance():DispatchObservers(taskVO.eventName, taskVO)
    end
end


return DownloadManager
