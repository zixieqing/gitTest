--[[
 * author : kaishiqi
 * descpt : 资源下载弹窗
]]
local DownloadResPopup = class('DownloadResPopup', function()
    return display.newLayer(0, 0, {name = 'common.DownloadResPopup', enableEvent = true})
end)

local RES_DICT = {
    FRAME_BG     = _res('ui/common/common_bg_10.png'),
    ORANGE_BTN   = _res('ui/common/common_btn_orange.png'),
    WHITE_BTN    = _res('ui/common/common_btn_white_default.png'),
    PROGRESS_BAR = _res('ui/home/infor/settings_ico_loading.png'),
    PROGRESS_BG  = _res('ui/home/infor/settings_bg_loading.png'),
    INFO_BAR     = _res('ui/common/common_bg_close.png'),
}

local CreateView = nil


-------------------------------------------------
-- life cycle

function DownloadResPopup:ctor()
    self.isControllable_    = true
    self.downloadResDatas_  = {}
    self.downloadingIndex_  = 0
    self.downloadResLength_ = 0

    -- block bg
    local blockBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    self:addChild(blockBg)

    -- black bg
    self.blackBg_ = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150)})
    self:addChild(self.blackBg_)

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
    
    -- init status
    self:cleanAllDownloadTask_()
    self:hideResPopup_()
    
    -- add listens
    app:RegistObserver(DOWNLOAD_DEFINE.RES_POPUP.event, mvc.Observer.new(self.onResDownloadedHandler_, self))
    app:RegistObserver(DOWNLOAD_DEFINE.RES_POPUP.progress, mvc.Observer.new(self.onResProgressHandler_, self))
    display.commonUIParams(self:getViewData().retryBtn, {cb = handler(self, self.onClickRetryButtonHandler_)})
    display.commonUIParams(self:getViewData().cancelBtn, {cb = handler(self, self.onClickCancelButtonHandler_)})
end


CreateView = function()
    local size = cc.size(600, 300)
    local view = display.newLayer(display.cx, display.cy, {bg = RES_DICT.FRAME_BG, ap = display.CENTER, scale9 = true, size = size, capInsets = cc.rect(200, 100, 30, 30)})

    local titleLabel = display.newLabel(size.width/2, size.height - 35, fontWithColor(14, {fontSize = 32, text = __('资源同步中')}))
    view:addChild(titleLabel)

    local cancelBtn = display.newButton(size.width/2 - 110, 50, {n = RES_DICT.WHITE_BTN})
    display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __('取消')}))
    view:addChild(cancelBtn)
    
    local retryBtn = display.newButton(size.width/2 + 110, cancelBtn:getPositionY(), {n = RES_DICT.ORANGE_BTN})
    display.commonLabelParams(retryBtn, fontWithColor(14, {text = __('重试')}))
    view:addChild(retryBtn)

    local progressBar = CProgressBar:create(RES_DICT.PROGRESS_BAR)
    progressBar:setBackgroundImage(RES_DICT.PROGRESS_BG)
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    progressBar:setPosition(size.width/2, size.height/2 + 10)
    progressBar:setAnchorPoint(display.CENTER)
    progressBar:setMaxValue(100)
    progressBar:setValue(0)
    progressBar:setScaleX(1.6)
    progressBar:setScaleY(1.2)
    view:addChild(progressBar)

    local errorInfoLabel = display.newLabel(size.width/2, progressBar:getPositionY() + 35, fontWithColor(16))
    view:addChild(errorInfoLabel)

    local progressLabel = display.newLabel(size.width/2, progressBar:getPositionY() - 35, fontWithColor(16))
    view:addChild(progressLabel)

    retryBtn:setVisible(false)
    cancelBtn:setVisible(false)
    return {
        view           = view,
        retryBtn       = retryBtn,
        cancelBtn      = cancelBtn,
        progressBar    = progressBar,
        progressLabel  = progressLabel,
        errorInfoLabel = errorInfoLabel,
        leftBtnPos     = cc.p(cancelBtn:getPosition()),
        rightBtnPos    = cc.p(retryBtn:getPosition()),
        centerBtnPos   = cc.p(size.width/2, retryBtn:getPositionY()),
    }
end


-------------------------------------------------
-- get / set

function DownloadResPopup:getViewData()
    return self.viewData_
end


function DownloadResPopup:isFuzzyMode()
    return self.isFuzzyMode_ == true
end
function DownloadResPopup:setFuzzyMode(isFuzzy)
    self.isFuzzyMode_ = isFuzzy == true
end


function DownloadResPopup:getErrorText()
    return self.errorText_
end
function DownloadResPopup:setErrorText(text)
    self.errorText_ = tostring(text)
    local viewData  = self:getViewData()
    display.commonLabelParams(viewData.errorInfoLabel, {text = self.errorText_})
end


function DownloadResPopup:setFinishCallback(finishCB)
    self.finishCallback_ = finishCB
end


function DownloadResPopup:setDownloadResDatas(resDataList)
    self:cleanAllDownloadTask_()
    self:hideResPopup_()

    -- pre-check download task
    local tempResCacheMap = {}
    for _, resData in ipairs(resDataList or {}) do
        local resPath  = tostring(resData)
        local resType  = type(resData) == 'string' and RES_TYPE.FILE or tostring(resData.type)
        local isVerify = false

        -- verify res
        if resType == RES_TYPE.FILE then
            isVerify = app.gameResMgr:verifyRes(resPath)
    
        elseif resType == RES_TYPE.SPINE then
            isVerify = app.gameResMgr:verifySpine(resPath)
    
        elseif resType == RES_TYPE.PARTICLE then
            isVerify = app.gameResMgr:verifyParticle(resPath)
        end
    
        if not isVerify then
            if tempResCacheMap[tostring(resType)] and tempResCacheMap[tostring(resType)][tostring(resPath)] then
                -- filter repeat resData
            else
                tempResCacheMap[tostring(resType)] = tempResCacheMap[tostring(resType)] or {}
                tempResCacheMap[tostring(resType)][tostring(resPath)] = true
                table.insert(self.downloadResDatas_, resData)
            end
        end
    end
    
    -- ready downloading
    self.downloadResLength_ = #self.downloadResDatas_
    if self.downloadResLength_ > 0 then
        self:showResPopup_()
        self:updateDownloadProgress_()
        self:continueDownloadTask_()
    else
        self:finishAllDownloadTask_()
    end
end


-------------------------------------------------
-- public method

function DownloadResPopup:close()
    self:hideResPopup_()
    self:stopAllActions()
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- private method

function DownloadResPopup:hideResPopup_()
    if self:isFuzzyMode() then
        app.uiMgr:removeVerifyInfoPopup()
    else
        self.blackBg_:setVisible(false)
        self:getViewData().view:setVisible(false)
    end
end
function DownloadResPopup:showResPopup_()
    if self:isFuzzyMode() then
        app.uiMgr:showVerifyInfoPopup({infoText = __('资源同步中')})
    else
        self.blackBg_:setVisible(true)
        self:getViewData().view:setVisible(true)
    end
end


function DownloadResPopup:cleanAllDownloadTask_()
    self.downloadResDatas_  = {}
    self.downloadingIndex_  = 0
    self.downloadResLength_ = 0
    self:updateDownloadProgress_()
end


function DownloadResPopup:updateDownloadProgress_()
    local totalNum   = 0
    local finishNum  = 0
    local totalSize  = 0
    local finishSize = 0

    local updateProgress = function(isVerify, remoteDefine)
        local resSize = remoteDefine and checkint(remoteDefine.size) or 0
        totalNum   = totalNum + 1
        finishNum  = finishNum + (isVerify and 1 or 0)
        totalSize  = totalSize + resSize
        finishSize = finishSize + (isVerify and resSize or 0)
    end
    
    -- statistics task
    for _, resData in ipairs(self.downloadResDatas_) do
        local resPath  = tostring(resData)
        local resType  = type(resData) == 'string' and RES_TYPE.FILE or tostring(resData.type)
        local isVerify = false

        if resType == RES_TYPE.FILE then
            local isVerify, remoteDefine = app.gameResMgr:verifyRes(resPath, true)
            updateProgress(isVerify, remoteDefine)
    
        elseif resType == RES_TYPE.SPINE then
            local _, verifyMap = app.gameResMgr:verifySpine(resPath, true)
            if verifyMap then
                local atlasVerifyMap = verifyMap['atlas']
                if atlasVerifyMap then
                    updateProgress(atlasVerifyMap.isVerify, atlasVerifyMap.remoteDefine)
                end

                local jsonVerifyMap = verifyMap['json']
                if jsonVerifyMap then
                    updateProgress(jsonVerifyMap.isVerify, jsonVerifyMap.remoteDefine)
                end

                local imgsVerifyList = verifyMap['imgs']
                for _, imgVerifyMap in pairs(imgsVerifyList or {}) do
                    updateProgress(imgVerifyMap.isVerify, imgVerifyMap.remoteDefine)
                end
            end
    
        elseif resType == RES_TYPE.PARTICLE then
            local _, verifyMap = app.gameResMgr:verifyParticle(resPath, true)
            if verifyMap then
                local plistVerifyMap = verifyMap['plist']
                if plistVerifyMap then
                    updateProgress(plistVerifyMap.isVerify, plistVerifyMap.remoteDefine)
                end
                
                local imageVerifyMap = verifyMap['image']
                if imageVerifyMap then
                    updateProgress(imageVerifyMap.isVerify, imageVerifyMap.remoteDefine)
                end
            end
        end
    end

    -- update progress progresssBar
    self:getViewData().progressBar:setValue(math.max(0, math.min(finishNum / totalNum * 100, 100)))

    -- update progress label
    local totalSizeStr  = string.format('%0.2f', totalSize / 1024/1024)
    local finishSizeStr = string.format('%0.2f', finishSize / 1024/1024)
    display.commonLabelParams(self:getViewData().progressLabel, {text = string.fmt('%1 MB / %2 MB', finishSizeStr, totalSizeStr)})
end


function DownloadResPopup:continueDownloadTask_()
    if self.downloadingIndex_ < self.downloadResLength_ then
        -- next task
        self.downloadingIndex_ = self.downloadingIndex_ + 1
        self:retryDownloadTask_()
    else
        -- finish all
        self:finishAllDownloadTask_()
    end
end
function DownloadResPopup:retryDownloadTask_()
    local resData = self.downloadResDatas_[self.downloadingIndex_]
    if resData then
        app.downloadMgr:addResTask(resData, DOWNLOAD_DEFINE.RES_POPUP.event, DOWNLOAD_DEFINE.RES_POPUP.progress)
    end
end
function DownloadResPopup:finishAllDownloadTask_()
    if self.finishCallback_ then
        self.finishCallback_()
    end
    self:close()
end


-------------------------------------------------
-- handler

function DownloadResPopup:onCleanup()
    -- clean downloading task
    local resData = self.downloadResDatas_[self.downloadingIndex_]
    if resData then
        local resPath = tostring(resData)
        app.downloadMgr:delResTask(resPath)
    end

    -- remove download listen
    app:UnRegistObserver(DOWNLOAD_DEFINE.RES_POPUP.event, self)
    app:UnRegistObserver(DOWNLOAD_DEFINE.RES_POPUP.progress, self)
end


function DownloadResPopup:onResDownloadedHandler_(signal)
    local dataBody = signal:GetBody()
    
    -- check downloaded
    if dataBody.isDownloaded then
        self:updateDownloadProgress_()
        self:continueDownloadTask_()

    else
        if self:isFuzzyMode() then
            self:retryDownloadTask_()
        else
            self:setErrorText(__('下载失败，清重试'))
            self:getViewData().retryBtn:setVisible(true)
            self:getViewData().cancelBtn:setVisible(true)
        end
    end
end


function DownloadResPopup:onResProgressHandler_(signal)
    self:updateDownloadProgress_()
end


function DownloadResPopup:onClickRetryButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    self:getViewData().retryBtn:setVisible(false)
    self:getViewData().cancelBtn:setVisible(false)
    self:retryDownloadTask_()
end


function DownloadResPopup:onClickCancelButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    self:close()
end


return DownloadResPopup
