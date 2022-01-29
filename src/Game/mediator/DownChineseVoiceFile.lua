---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 10/01/2018 8:46 PM
---
if  DownChineseVoiceFile then
   return DownChineseVoiceFile

end
DownChineseVoiceFile = {}
DownChineseVoiceFile.instance = nil

function DownChineseVoiceFile.new()
    local instance = {}
    DownChineseVoiceFile.__index = DownChineseVoiceFile
    setmetatable(instance ,DownChineseVoiceFile )
    instance:ctor()
    return instance
end

function DownChineseVoiceFile.GetInstance()
    if DownChineseVoiceFile.instance== nil  then
        DownChineseVoiceFile.instance = DownChineseVoiceFile.new()
    end
    return DownChineseVoiceFile.instance
end
--[[
--初始化相关的数据
--@url  http url地址
--@tsize 表示需要适配的node节点的大小
--@hpath 表示初始的默认图标
--]]
---@class DownChineseVoiceFile
function DownChineseVoiceFile:ctor(...)
    print(VOICE_DATA.VOICE_PATH)
    local shareFileUtils = cc.FileUtils:getInstance()
    if not shareFileUtils:isFileExist(VOICE_DATA.VOICE_RES_SUB_PATH) then
        shareFileUtils:createDirectory(VOICE_DATA.VOICE_RES_SUB_PATH)
    end
    --if not shareFileUtils:isFileExist(VOICE_DATA.VOICE_PATH) then
    --    shareFileUtils:createDirectory(VOICE_DATA.VOICE_PATH)
    --end
    self.count = 1
    self.downTime =  0
    self.isDownLoad = 0  -- 0 尚未开启下澡 1 正在下载中 2 下载完成 3 取消下载
end
function DownChineseVoiceFile:UpdateData(param )
    self.loadFailure = {} -- 下载失败的文件
    self.downLoadData = param.downLoadData -- 要下载的数据
    self.downLoadDataCopy =  clone(param.downLoadData)
    self.localData = param.localData
    self.downloadSize =  0
    self.totalDownloadSize =   self:GetTotalDownLoadSize()
end
--[[
    获取到下载的总量
--]]
function DownChineseVoiceFile:GetTotalDownLoadSize()
    local count = 0
    for k , v in pairs(self.downLoadData) do
        if v.size then
            count = checkint(v.size) + count
        end
    end
    return count
end

function DownChineseVoiceFile:DownloadChineseVoiceFileAck()
    if self.isDownLoad == 3 then return end
    if self.count <= table.nums(self.downLoadData) then
        self.isDownLoad = 1

        AppFacade.GetInstance():RegistObserver(DOWNLOAD_DEFINE.VOICE_ACB.event, mvc.Observer.new(function(context, signal)
            local data = signal:GetBody()
            if data.isDownloaded then
                -- check file md5
                local md5 = crypto.md5file(VOICE_DATA.VOICE_RES_SUB_PATH .. self.downLoadData[self.count].name)
                if md5 == self.downLoadData[self.count].md5 then

                    -- update local log
                    if self.localData then
                        self.localData[self.downLoadData[self.count].name] = md5
                        io.writefile(VOICE_DATA.VOICE_RES_SUB_PATH .. VOICE_DATA.VOICE_LACAL_FILE, json.encode(self.localData))
                    end
                end
                self.downloadSize = self.downloadSize + checkint(self.downLoadData[self.count].size)
            end
            
            -- download next file
            self.count = self.count + 1
            self:DownloadChineseVoiceFileAck()
            AppFacade.GetInstance():DispatchObservers(VOICE_DOWNLOAD_EVENT, {})

        end, DownChineseVoiceFile.GetInstance()))

        -- to download file
        local url = self.downLoadData[self.count].url
        app.downloadMgr:addUrlTask(url, DOWNLOAD_DEFINE.VOICE_ACB.event, VOICE_DATA.VOICE_RES_SUB_PATH, self.downLoadData[self.count].name)

    else
        if self.downTime > 2 then
            self.isDownLoad = 2  -- 下载完成
        end
        if #self.loadFailure  > 0 then
            self.downTime = self.downTime +1
            self.downLoadData = self.loadFailure
            self.loadFailure = {}
        else
            self.isDownLoad = 2
        end
        AppFacade.GetInstance():DispatchObservers(VOICE_DOWNLOAD_EVENT, {})
    end
end
--[[
    设置暂停
--]]
function DownChineseVoiceFile:SetStopDownload()
    self.isDownLoad = 3
    AppFacade.GetInstance():DispatchObservers(VOICE_DOWNLOAD_EVENT, {})
end
--[[
    重现下载
--]]
function DownChineseVoiceFile:SetRestartDownload()
    self.isDownLoad = 1
    self:DownloadChineseVoiceFileAck()
    AppFacade.GetInstance():DispatchObservers(VOICE_DOWNLOAD_EVENT, {})
end
return  DownChineseVoiceFile
