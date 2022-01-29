--[[
 * author : kaishiqi
 * descpt : 日志信息弹窗
]]
local LogInfoPopup = class('LogInfoPopup', function()
    return ui.layer({name = 'root.LogInfoPopup', enableEvent = true})
end)

local FPS_FILTER = 0.10

local CHANNEL_TAB_DEFINES = {
    {title = __('错误日志'), type = logInfo.Types.ERROR},
    {title = __('短连日志'), type = logInfo.Types.HTTP},
    {title = __('长连日志'), type = logInfo.Types.GAME},
    -- {title = __('聊天日志'), type = logInfo.Types.CHAT},
    -- {title = __('组队日志'), type = logInfo.Types.TEAM},  -- 打牌也用的这个频道
    {title = __('调试日志'), type = logInfo.Types.DEBUG},
}

local HEADER_FEATURE = 'var = { '
local FOOTER_FEATURE = '}'

-------------------------------------------------
-- life cycle

function LogInfoPopup:ctor(args)
    local initArgs       = checktable(args)
    local initTabIndex   = initArgs.tabIndex or 1
    self.isControllable_ = true

    -- create view
    self.viewData_ = LogInfoPopup.CreateView()
    self:add(self:getViewData().view)

    self.historyVD_ = LogInfoPopup.CreateHistoryView()
    self:add(self:getHistoryVD().view)

    -- add listener
    ui.bindClick(self:getViewData().closeBtn, handler(self, self.onClickCloseButtonHandler_))
    ui.bindClick(self:getViewData().cleanBtn, handler(self, self.onClickCleanButtonHandler_))
    ui.bindClick(self:getViewData().reloadBtn, handler(self, self.onClickReloadButtonHandler_))
    ui.bindClick(self:getViewData().historyBtn, handler(self, self.onClickHistoryButtonHandler_))
    ui.bindClick(self:getViewData().textureBtn, handler(self, self.onClickTextureButtonHandler_))
    ui.bindClick(self:getViewData().toTopBtn, handler(self, self.onClickToTopButtonHandler_))
    ui.bindClick(self:getViewData().toBottomBtn, handler(self, self.onClickToBottomButtonHandler_))
    ui.bindClick(self:getViewData().toUpBtn, handler(self, self.onClickToUpButtonHandler_))
    ui.bindClick(self:getViewData().toDownBtn, handler(self, self.onClickToDownButtonHandler_))
    ui.bindClick(self:getHistoryVD().blockLayer, handler(self, self.onClickHistoryBlockLayerHandler_))
    self:getViewData().channelTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickChannelButtonHandler_))
    end)
    self:getViewData().logInfoTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickInfoTableCellandler_))
    end)
    for index, datebtn in ipairs(self:getHistoryVD().dateBtnList) do
        ui.bindClick(datebtn, handler(self, self.onClickHistoryDateButtonHandler_))
    end

    self:getViewData().channelTableView:setCellUpdateHandler(handler(self, self.onUpdateChannelCellHandler_))
    self:getViewData().logInfoTableView:setCellUpdateHandler(handler(self, self.onUpdateLogInfoCellHandler_))
    self:getViewData().logInfoTableView:setOnScrollingScriptHandler(handler(self, self.onScrollingLogInfoTableViewHandler_))

    local keyboardEventListener = cc.EventListenerKeyboard:create()
    keyboardEventListener:registerScriptHandler(handler(self, self.onKeyboardPressedHandler_), cc.Handler.EVENT_KEYBOARD_PRESSED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(keyboardEventListener, self)

    local logInfoUpdateListener  = cc.EventListenerCustom:create(logInfo.EVENT_LOG_UPDATE, handler(self, self.onLogInfoUpdateHandler_))
    local pingSendUpdateListener = cc.EventListenerCustom:create(logInfo.PING_SEND_UPDATE, handler(self, self.onPingSendUpdateHandler_))
    local pingTakeUpdateListener = cc.EventListenerCustom:create(logInfo.PING_TAKE_UPDATE, handler(self, self.onPingTakeUpdateHandler_))
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(logInfoUpdateListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(pingSendUpdateListener, self)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(pingTakeUpdateListener, self)

    -- init status
    self:getViewData().channelTableView:resetCellCount(#CHANNEL_TAB_DEFINES, true)
    self:getViewData().reloadBtn:setVisible(DEBUG > 0 and (device.platform == "mac" or device.platform == "windows"))
    self:getViewData().textureBtn:setVisible(DEBUG > 0)
    self:getViewData().fpsLabel:setVisible(false) -- 没啥用，关掉了
    self:updateInfoCountdownUpdate_()
    self:updateFPSCountdownUpdate_()
    self:loadLocalErrorLog_()
    self:hideHistoryPopup_()
    self:setTabIndex(initTabIndex)
end


-------------------------------------------------
-- get / set

function LogInfoPopup:getViewData()
    return self.viewData_
end
function LogInfoPopup:getHistoryVD()
    return self.historyVD_
end


function LogInfoPopup:getTabIndex()
    return checkint(self.tabIndex_)
end
function LogInfoPopup:setTabIndex(index)
    local oldIndex = self:getTabIndex()
    local newIndex = checkint(index)
    self.tabIndex_ = newIndex

    if oldIndex ~= newIndex then
        -- update channelTabCell
        self:getViewData().channelTableView:updateCellViewData(oldIndex, nil, 'selected')
        self:getViewData().channelTableView:updateCellViewData(newIndex, nil, 'selected')

        -- reload logInfoTableView
        self:reloadLogInfo_(true)
        self:updatePingSendLabel_()
        self:updatePingTakeLabel_()

        -- update historyButton
        local isErroryType = self:getTabDefine().type == logInfo.Types.ERROR
        local isHttpType   = self:getTabDefine().type == logInfo.Types.HTTP
        self:getViewData().toUpBtn:setVisible(isHttpType)
        self:getViewData().toDownBtn:setVisible(isHttpType)
        self:getViewData().historyBtn:setVisible(not self:getViewData().reloadBtn:isVisible() and isErroryType)
        if not isErroryType then
            self:hideHistoryPopup_()
        end
    end
end


function LogInfoPopup:getTabDefine(tabIndex)
    return CHANNEL_TAB_DEFINES[tabIndex or self:getTabIndex()] or {}
end


function LogInfoPopup:getInfoData()
    return logInfo.dataCache[self:getTabDefine().type] or {}
end


function LogInfoPopup:getPingData()
    return logInfo.pingCache[self:getTabDefine().type] or {}
end


function LogInfoPopup:getErrorLogDirPath()
    return cc.FileUtils:getInstance():getWritablePath() .. 'log/'
end
function LogInfoPopup:getErrorLogFileName(dayStr)
    return string.format('eater-%s.log', dayStr)
end


-------------------------------------------------
-- public method

function LogInfoPopup:close()
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- private method

function LogInfoPopup:checkInfoListIsTop_()
    local logInfoTableView = self:getViewData().logInfoTableView
    return logInfoTableView:getMinOffset().y - logInfoTableView:getContentOffset().y  >= -100
end


function LogInfoPopup:checkInfoListIsBottom_()
    local logInfoTableView = self:getViewData().logInfoTableView
    return logInfoTableView:getMaxOffset().y - logInfoTableView:getContentOffset().y <= 100
end


function LogInfoPopup:reloadLogInfo_(toBottom)
    local logInfoTableView = self:getViewData().logInfoTableView
    local beforeHeight     = logInfoTableView:getContainerSize().height
    local beforeOffsetY    = logInfoTableView:getContentOffset().y
    logInfoTableView:resetCellCount(#self:getInfoData())

    if toBottom == true then
        logInfoTableView:setContentOffsetToBottom()
    else
        local afterHeight = logInfoTableView:getContainerSize().height
        logInfoTableView:setContentOffset(cc.p(0, beforeHeight - afterHeight + beforeOffsetY))
    end
end


function LogInfoPopup:loadLocalErrorLog_(dayStr)
    -- read log file
	local errorText  = ''
    local LINE_CHAR  = 108
    local READ_MAX   = 1024 * 30
	local fileUtils  = cc.FileUtils:getInstance()
    local logDirPath = self:getErrorLogDirPath()
    if fileUtils:isDirectoryExist(logDirPath) then
        local todayStr = dayStr or os.date('%Y-%m-%d')
        local fileName = self:getErrorLogFileName(todayStr)
		local filePath = logDirPath .. fileName
		if fileUtils:isFileExist(filePath) then
            local fsize = io.filesize(filePath)
            local file  = io.open(filePath, 'r')
            if file then
                local lineCount = 0
                local lineDatas = {}
                local aLineText = ''

                if fsize > READ_MAX then
                    lineCount = lineCount + 1
                    lineDatas[lineCount] = '(ignore more ......)'
                    file:seek("cur", (fsize - READ_MAX))
                end

                for line in file:lines() do
                    for i = 1, math.max(string.len(line), 1), LINE_CHAR do
                        aLineText = string.sub(line, i, i + LINE_CHAR-1)
                        lineCount = lineCount + 1
                        lineDatas[lineCount] = aLineText
                    end
                end
                errorText = table.concat(lineDatas, '\n')

                io.close(file)
            end
		end
    end
	if string.isEmpty(errorText) then
        errorText = "Today's log is empty..."
    end

    -- re-record error log data
    logInfo.dataCache[logInfo.Types.ERROR] = {}
    logInfo.add(logInfo.Types.ERROR, errorText)
end


function LogInfoPopup:startInfoCountdownUpdate_()
    if self.infoCountdownHandler_ then return end
    self.infoCountdownHandler_ = scheduler.scheduleGlobal(function()
        self:updateInfoCountdownUpdate_()
    end, 1)
end
function LogInfoPopup:stopInfoCountdownUpdate_()
    if self.infoCountdownHandler_ then
        scheduler.unscheduleGlobal(self.infoCountdownHandler_)
        self.infoCountdownHandler_ = nil
    end
end
function LogInfoPopup:updateInfoCountdownUpdate_()
    -- local networkText = ''
    -- if network.getInternetConnectionStatus() == 0 then
    --     networkText = 'none'
    -- elseif network.getInternetConnectionStatus() == 1 then
    --     networkText = 'WIFI'
    -- elseif network.getInternetConnectionStatus() == 2 then
    --     networkText = 'WWAN'
    -- end
    local clientTime   = getLoginClientTime and getLoginClientTime() or 0
    local playerId     = (app and app.gameMgr and app.gameMgr.GetPlayerId) and app.gameMgr:GetPlayerId() or '?'
    local channelId    = Platform and checkint(Platform.id) or '?'
    local timeText     = string.format('Now: %s, Run: %s', os.date('%H:%M:%S'), string.formattedTime(os.time() - clientTime, '%02i:%02i:%02i'))
    local deviceText   = string.format('Platform: %s, Display: %dx%d', tostring(device.platform), display.sizeInPixels.width, display.sizeInPixels.height)
    local gameInfoText = string.format('pID: %s, cID: %s, v:%s', playerId, channelId, utils.getAppVersion(true))
    self:getViewData().statusLabel:setString(timeText..'\n'..deviceText..'\n'..gameInfoText)
end


function LogInfoPopup:startFPSCountdownUpdate_()
    if self.fpsCountdownHandler_ then return end
    self.fpsCountdownHandler_ = scheduler.scheduleGlobal(function()
        self:updateFPSCountdownUpdate_()
    end, 0.1)
end
function LogInfoPopup:stopFPSCountdownUpdate_()
    if self.fpsCountdownHandler_ then
        scheduler.unscheduleGlobal(self.fpsCountdownHandler_)
        self.fpsCountdownHandler_ = nil
    end
end
function LogInfoPopup:updateFPSCountdownUpdate_()
    local deltaTime = cc.Director:getInstance():getDeltaTime()
    local interval  = cc.Director:getInstance():getAnimationInterval()
    local delayTime = deltaTime * FPS_FILTER + (1-FPS_FILTER) * interval
    self:getViewData().fpsLabel:setString(string.format('FPS %.1f', 1 / delayTime))
end


function LogInfoPopup:updatePingSendLabel_(isAnimation)
    local pingTime  = checkstr(self:getPingData().pingSendTimeStr)
    local pingLabel = self:getViewData().pingSendLabel
    if self:getPingData().pingSendTimeStr then
        if self:getPingData().pingStacksCount <= 1 then
            pingLabel:setString(pingTime .. '\n> send ping >')
        elseif self:getPingData().pingStacksCount == 2 then
            pingLabel:setString(pingTime .. '\n>> send ping >>')
        elseif self:getPingData().pingStacksCount == 3 then
            pingLabel:setString(pingTime .. '\n>>> send ping >>>')
        else
            pingLabel:setString(pingTime .. '\n>>>> send ping >>>>')
        end
    else
        pingLabel:setString('')
    end

    if isAnimation then
        pingLabel:runAction(cc.Sequence:create(
            cc.TintTo:create(0.05, cc.c3b(125,125,125)),
            cc.TintTo:create(0.05, cc.c3b(150,150,150))
        ))
    end
end
function LogInfoPopup:updatePingTakeLabel_(isAnimation)
    local pingTime  = checkstr(self:getPingData().pingTakeTimeStr)
    local pingLabel = self:getViewData().pingTakeLabel
    if self:getPingData().pingTakeTimeStr then
        pingLabel:setString(pingTime .. '\n< take ping <')
    else
        pingLabel:setString('')
    end

    if isAnimation then
        pingLabel:runAction(cc.Sequence:create(
            cc.TintTo:create(0.05, cc.c3b(125,125,125)),
            cc.TintTo:create(0.05, cc.c3b(150,150,150))
        ))
    end
end


function LogInfoPopup:hideHistoryPopup_()
    self:getHistoryVD().view:setVisible(false)
end
function LogInfoPopup:showHistoryPopup_()
    self:getHistoryVD().view:setVisible(true)

    local historyLen  = #self:getHistoryVD().dateBtnList
    local historyList = table.reverse(dumpTree(self:getErrorLogDirPath(), 1, historyLen))
    for btnIndex = historyLen, 1, -1 do
        local historyStr = historyList[historyLen - btnIndex + 1]
        local historyBtn = self:getHistoryVD().dateBtnList[btnIndex]
        historyBtn:setVisible(historyStr ~= nil)
        if historyStr then
            local dayStr = historyStr:match("eater[-](.+)\.log$")
            historyBtn.label:updateLabel({text = dayStr})
        end
    end
end


-------------------------------------------------
-- handler

function LogInfoPopup:onEnter()
    self:startInfoCountdownUpdate_()
    if DEBUG > 0 then
        self:startFPSCountdownUpdate_()
    end
end


function LogInfoPopup:onExit()
    self:stopInfoCountdownUpdate_()
    self:stopFPSCountdownUpdate_()
end


function LogInfoPopup:onUpdateChannelCellHandler_(cellIndex, cellViewData, updateType)
    if cellViewData == nil then return end

    if updateType == nil then
        cellViewData.clickArea:setTag(cellIndex)

        local channelTabDefine = self:getTabDefine(cellIndex)
        local textStringWidth  = cellViewData.normalBg:getContentSize().width - 4
        cellViewData.textLabel:updateLabel({text = tostring(channelTabDefine.title), maxW = textStringWidth})
    end

    if updateType == nil or updateType == 'selected' then
        local isSelected = self:getTabIndex() == cellIndex
        cellViewData.selectBg:setVisible(isSelected)
        cellViewData.normalBg:setVisible(not isSelected)
    end

    if updateType == 'highlight' then
        cellViewData.hlightBg:stopAllActions()
        cellViewData.hlightBg:setOpacity(0)
        cellViewData.hlightBg:runAction(cc.Sequence:create(
            cc.FadeTo:create(0.2, 150),
            cc.FadeTo:create(0.2, 0)
        ))
    end
end


function LogInfoPopup:onUpdateLogInfoCellHandler_(cellIndex, cellViewData, updateType)
    if cellViewData == nil then return end

    local logInfoText = self:getInfoData()[cellIndex] or ''
    cellViewData.logLabel:setString(checkstr(logInfoText))
    cellViewData.clickArea:setTag(cellIndex)
end


function LogInfoPopup:onScrollingLogInfoTableViewHandler_(sender)
    self:getViewData().toTopBtn:setVisible(not self:checkInfoListIsTop_())
    self:getViewData().toBottomBtn:setVisible(not self:checkInfoListIsBottom_())
end


function LogInfoPopup:onClickChannelButtonHandler_(sender)
    local tabIndex = checkint(sender:getTag())
    self:setTabIndex(tabIndex)
end


function LogInfoPopup:onClickInfoTableCellandler_(sender)
    local infoCellIndex = checkint(sender:getTag())
    local channelType   = self:getTabDefine().type
    local infoCellText  = logInfo.dataCache[channelType][infoCellIndex]
    if channelType == logInfo.Types.HTTP and (device.platform == "mac" or device.platform == "windows") then
        -- check is begin -
        if string.sub(infoCellText, 1, 1) then
            local fullInfoList = { infoCellText }
            for index = infoCellIndex, 1, -1 do
                local cellText = logInfo.dataCache[channelType][index]
                if index ~= infoCellIndex then
                    table.insert(fullInfoList, 1, cellText)
                end
                if cellText == HEADER_FEATURE then
                    break
                end
            end
            for index = infoCellIndex, #logInfo.dataCache[channelType] do
                local cellText = logInfo.dataCache[channelType][index]
                if index ~= infoCellIndex then
                    table.insert(fullInfoList, cellText)
                end
                if cellText == FOOTER_FEATURE then
                    break
                end
            end
            device.showAlert('http', table.concat(fullInfoList, '\n'))
        end
    end
end


function LogInfoPopup:onClickCloseButtonHandler_(sender)
    self:close()
end


function LogInfoPopup:onClickReloadButtonHandler_(sender)
    if utils.isExistent('reloadList.lua') then
        unrequire('reloadList')
        logInfo.reloadFiles = require('reloadList') or {}
        -- logt(logInfo.reloadFiles, 'reloadList')
    end
    for _, luaFile in ipairs(logInfo.reloadFiles or {}) do
        local filePath = string.gsub(luaFile, '[\.]', '/')
        if utils.isExistent(filePath .. '.lua') then
            unrequire(luaFile)
            require(luaFile)
        else
            logInfo.add(1, 'reload error : ' .. luaFile)
        end
    end
end


function LogInfoPopup:onClickToTopButtonHandler_(sender)
    self:getViewData().logInfoTableView:setContentOffsetToTop()
end


function LogInfoPopup:onClickToBottomButtonHandler_(sender)
    self:getViewData().logInfoTableView:setContentOffsetToBottom()
end


function LogInfoPopup:onClickToUpButtonHandler_(sender)
    local channelType = self:getTabDefine().type
    if channelType == logInfo.Types.HTTP then
        local logInfoTableView  = self:getViewData().logInfoTableView
        local logCellSizeHeight = logInfoTableView:getSizeOfCell().height
        local logTableOffsetY   = logInfoTableView:getContentOffset().y - logInfoTableView:getMinOffset().y
        local infoCellIndex     = math.floor(logTableOffsetY/logCellSizeHeight) + 1
        local infoCellText      = checktable(logInfo.dataCache[channelType])[infoCellIndex]
        if infoCellText and string.sub(infoCellText, 1, 1) then
            for index = infoCellIndex, 1, -1 do
                local cellText = logInfo.dataCache[channelType][index]
                if cellText == HEADER_FEATURE then
                    local targetIndex   = index - 2  -- -2 is (show self) + (show POST info)
                    local targetOffsetY = logInfoTableView:getMinOffset().y - (targetIndex * -logCellSizeHeight)
                    logInfoTableView:setContentOffset(cc.p(0, targetOffsetY))
                    break
                end
            end
        end
    end
end


function LogInfoPopup:onClickToDownButtonHandler_(sender)
    local channelType = self:getTabDefine().type
    if channelType == logInfo.Types.HTTP then
        local logInfoTableView  = self:getViewData().logInfoTableView
        local logCellSizeHeight = logInfoTableView:getSizeOfCell().height
        local logTableOffsetY   = logInfoTableView:getContentOffset().y - logInfoTableView:getMinOffset().y
        local infoCellIndex     = math.floor(logTableOffsetY/logCellSizeHeight) + 1
        local infoCellText      = checktable(logInfo.dataCache[channelType])[infoCellIndex]
        if infoCellText and string.sub(infoCellText, 1, 1) then
            for index = infoCellIndex, #logInfo.dataCache[channelType] do
                local cellText = logInfo.dataCache[channelType][index]
                if cellText == FOOTER_FEATURE then
                    local targetIndex   = index - 0  -- -2 is (show self) + (show POST info)
                    local targetOffsetY = logInfoTableView:getMinOffset().y - (targetIndex * -logCellSizeHeight)
                    logInfoTableView:setContentOffset(cc.p(0, math.min(targetOffsetY, logInfoTableView:getMaxOffset().y)))
                    break
                end
            end
        end
    end
end


function LogInfoPopup:onClickCleanButtonHandler_(sender)
    local channelType = self:getTabDefine().type
    logInfo.dataCache[channelType] = {}
    logInfo.pingCache[channelType] = {}

    if channelType == logInfo.Types.ERROR then
        local fileUtils  = cc.FileUtils:getInstance()
        local logDirPath = self:getErrorLogDirPath()
        if fileUtils:isDirectoryExist(logDirPath) then
            local todayStr = os.date('%Y-%m-%d')
            local fileName = self:getErrorLogFileName(todayStr)
            local filePath = logDirPath .. fileName
            local errorFile = io.open(filePath, 'w+')
            if not errorFile then
                errorFile:write('')
                errorFile:flush()
                errorFile:close()
            end
        end
    end

    self:reloadLogInfo_()
    self:updatePingSendLabel_()
    self:updatePingTakeLabel_()
end


function LogInfoPopup:onClickHistoryButtonHandler_(sender)
    self:showHistoryPopup_()
end


function LogInfoPopup:onClickHistoryBlockLayerHandler_(sender)
    self:hideHistoryPopup_()
end


function LogInfoPopup:onClickHistoryDateButtonHandler_(sender)
    local dayStr = sender.label:getString()
    self:loadLocalErrorLog_(dayStr)
    self:reloadLogInfo_(true)
end


function LogInfoPopup:onClickTextureButtonHandler_(sender)
    local cachedTextureInfo = cc.Director:getInstance():getTextureCache():getCachedTextureInfo()
    local cachedTextureList = string.split2(cachedTextureInfo, '\n')
    local textureDataArray  = {}
    local textureDescrList  = {}
    for _, textureInfo in ipairs(cachedTextureList) do
        if string.len(textureInfo) > 0 then
            local infoData = {
                path = string.gmatch(textureInfo, '"(.*)"')(),
                id   = string.gmatch(textureInfo, 'id=([0-9]*)')(),
                rc   = string.gmatch(textureInfo, 'rc=([0-9]*)')(),
                kb   = string.gmatch(textureInfo, '=> ([0-9]*) KB')(),
                w    = string.gmatch(textureInfo, ' ([0-9]*) x ')(),
                h    = string.gmatch(textureInfo, ' x ([0-9]*) ')(),
            }
            if infoData.path then
                infoData.name = string.sub(infoData.path, string.len(utils.getParentPath(infoData.path))+1)
                table.insert(textureDataArray, infoData)
            end
        end
    end
    table.sort(textureDataArray, function(a, b)
        return a.name < b.name
    end)
    for _, infoData in ipairs(textureDataArray) do
        table.insert(textureDescrList, string.format('%03s) %s', infoData.rc, infoData.name))
    end

    -- logs(cachedTextureInfo)
    local cachedResult = cachedTextureList[#cachedTextureList-1]
    local textureCount = string.gmatch(cachedResult, 'TextureCache dumpDebugInfo: ([0-9]*) textures, ')()
    local allTextureKB = string.gmatch(cachedResult, ' textures, for ([0-9]*) KB ')()
    local comIntroNode = require('common.IntroPopup').new({
        title = string.format('TextureCache [%s / %s KB]', tostring(textureCount), tostring(allTextureKB)),
        descr = table.concat(textureDescrList, '\n'),
    })
    self:addChild(comIntroNode)
end


function LogInfoPopup:onKeyboardPressedHandler_(keyCode, event)
    if not self.isControllable_ then return end

    -- [num 1] keycode = 77
    local tabIndex = keyCode - 76
    if tabIndex > 0 and tabIndex <= #CHANNEL_TAB_DEFINES then
        self:setTabIndex(tabIndex)

    -- [ESC] keycode = 6
    elseif keyCode == 6 then
        self:close()

    -- [`] keycode = 123
    elseif keyCode == 123 then
        -- self:toSocketPanel_()
        if DEBUG > 0 then
            -- 模拟各种功能的中途踢人，是否会引起异常发生
            app:GetManager('SocketManager'):AnalysePacket_({
                cmd  = NetCmd.Request2008,
                data = { data = {} }
            })
        end

    -- [back] keycode = 7
    elseif keyCode == 7 then
        self:onClickCleanButtonHandler_()

    end
end


function LogInfoPopup:onLogInfoUpdateHandler_(event)
    local eventData = checktable(event.data)
    local tabDefine = self:getTabDefine()

    -- update infoList
    if tabDefine.type == eventData.logType then
        self:reloadLogInfo_(self:checkInfoListIsBottom_())
    end

    -- tips tabButton
    local eventLogIndex = 0
    for tabIndex, tabDefine in ipairs(CHANNEL_TAB_DEFINES) do
        if tabDefine.type == eventData.logType then
            eventLogIndex = tabIndex
            break
        end
    end
    if eventLogIndex > 0 then
        self:getViewData().channelTableView:updateCellViewData(eventLogIndex, nil, 'highlight')
    end
end


function LogInfoPopup:onPingSendUpdateHandler_(event)
    local eventData = checktable(event.data)
    local tabDefine = self:getTabDefine()

    -- update pingSendLabel
    if tabDefine.type == eventData.logType then
        self:updatePingSendLabel_(true)
    end
end


function LogInfoPopup:onPingTakeUpdateHandler_(event)
    local eventData = checktable(event.data)
    local tabDefine = self:getTabDefine()
    
    -- update pingSendLabel
    if tabDefine.type == eventData.logType then
        self:updatePingTakeLabel_(true)
    end
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function LogInfoPopup.CreateFuncBtn(size, text, btnTag)
    local btnSize  = size or cc.size(150, 50)
    local btnNode  = ui.layer({size = btnSize, color = '#00C80064', ap = ui.cc, enable = true, tag = btnTag})
    local btnLabel = ui.label({p = cc.sizep(btnSize, ui.cc), fnt = FONT.TEXT24, color = '#CCCCCC', text = tostring(text)})
    btnNode.label  = btnLabel
    btnNode:add(btnLabel)
    return btnNode
end


function LogInfoPopup.CreateView()
    local size = display.size
    local view = ui.layer({size = size})

    -- block layer
    view:add(ui.layer({size = size, color = '#001450C8', enable = true}))


    -- channel tableView
    local channelTableView = ui.tableView({size = cc.size(display.SAFE_SIZE.width - 365, 50), csizeW = 190, dir = display.SDIR_H})
    view:addList(channelTableView):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 15, offsetY = -15})
    channelTableView:setCellCreateHandler(LogInfoPopup.CreateTabBtn)


    -- statusLabel | fpsLabel
    local infoLabelGroup = view:addList({
        ui.label({fnt = FONT.TEXT20, color = '#CCCCCC', text = '----', ap = ui.rc}),
        ui.label({fnt = FONT.TEXT20, color = '#CCCC00', text = '88.8', ap = ui.rc}),
    })
    ui.flowLayout(cc.p(display.SAFE_R - 25, channelTableView:getPositionY() - 10), infoLabelGroup, {type = ui.flowV, ap = ui.rc})


    -- pingSendLabel | closeButton | pingTakeLabel
    local centerBottomGroup = view:addList({
        ui.label({fnt = FONT.TEXT24, color = '#999999', ap = ui.rc, hAlign = display.TAC, mr = 20}),
        LogInfoPopup.CreateFuncBtn(cc.size(360, 50), __('点我关闭')),
        ui.label({fnt = FONT.TEXT24, color = '#999999', ap = ui.lc, hAlign = display.TAC, ml = 20}),
    })
    ui.flowLayout(cc.p(size.width/2, 40), centerBottomGroup, {type = ui.flowH, ap = ui.cc})

    centerBottomGroup[2]:setCascadeOpacityEnabled(true)
    centerBottomGroup[2]:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.FadeOut:create(1),
        cc.FadeIn:create(1)
    )))


    -- logInfo tableView
    local logInfoTableSize = cc.size(display.SAFE_RECT.width, size.height - 80 - 75)
    local logInfoTableView = ui.tableView({size = logInfoTableSize, csizeH = 28, dir = display.SDIR_V, bgColor = '#FFFFFF20'})
    view:addList(logInfoTableView):alignTo(nil, ui.cb, {offsetY = 80})
    logInfoTableView:setCellCreateHandler(LogInfoPopup.CreateInfoCell)


    -- texture button
    local textureBtn = ui.layer({size = cc.size(320, 60), color = '#FF000010', ap = ui.cc, enable = true})
    view:addList(textureBtn):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L, offsetY = -10})

    -- clean button
    local cleanBtn = LogInfoPopup.CreateFuncBtn(nil, __('清空信息'))
    view:addList(cleanBtn):alignTo(nil, ui.lb, {offsetX = display.SAFE_L + 40, offsetY = 15})

    -- reload button
    local reloadBtn = LogInfoPopup.CreateFuncBtn(nil, __('重载缓存'))
    view:addList(reloadBtn):alignTo(nil, ui.rb, {offsetX = -display.SAFE_L - 40, offsetY = 15})

    -- history button
    local historyBtn = LogInfoPopup.CreateFuncBtn(nil, __('历史报错'))
    view:addList(historyBtn):alignTo(nil, ui.rb, {offsetX = -display.SAFE_L - 40, offsetY = 15})

    -- toDown button
    local toDownBtn = LogInfoPopup.CreateFuncBtn(cc.size(60, 50), '⇩')
    view:addList(toDownBtn):alignTo(nil, ui.rb, {offsetX = -display.SAFE_L - 130, offsetY = 15 + 80})
    
    -- toBottom button
    local toBottomBtn = LogInfoPopup.CreateFuncBtn(cc.size(60, 50), '▼')
    view:addList(toBottomBtn):alignTo(nil, ui.rb, {offsetX = -display.SAFE_L - 40, offsetY = 15 + 80})

    -- toUp button
    local toUpBtn = LogInfoPopup.CreateFuncBtn(cc.size(60, 50), '⇧')
    view:addList(toUpBtn):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L - 130, offsetY = -10 - 80})

    local toTopBtn = LogInfoPopup.CreateFuncBtn(cc.size(60, 50), '▲')
    view:addList(toTopBtn):alignTo(nil, ui.rt, {offsetX = -display.SAFE_L - 40, offsetY = -10 - 80})

    return {
        view             = view,
        channelTableView = channelTableView,
        statusLabel      = infoLabelGroup[1],
        fpsLabel         = infoLabelGroup[2],
        pingSendLabel    = centerBottomGroup[1],
        closeBtn         = centerBottomGroup[2],
        pingTakeLabel    = centerBottomGroup[3],
        logInfoTableView = logInfoTableView,
        textureBtn       = textureBtn,
        cleanBtn         = cleanBtn,
        reloadBtn        = reloadBtn,
        historyBtn       = historyBtn,
        toBottomBtn      = toBottomBtn,
        toDownBtn        = toDownBtn,
        toTopBtn         = toTopBtn,
        toUpBtn          = toUpBtn,
    }
end


function LogInfoPopup.CreateTabBtn(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local colorSize = cc.resize(size, -10, 0)
    local nodeGroup = view:addList({
        ui.layer({size = colorSize, color = '#00000065'}),  -- bg
        ui.layer({size = colorSize, color = '#C8C80096'}),  -- select
        ui.layer({size = colorSize, color = '#C800C896'}),  -- normal
        ui.layer({size = colorSize, color = '#FFFFFF00'}),  -- hlight
        ui.label({fnt = FONT.TEXT24, color = '#CCCCCC'}),
    })
    ui.flowLayout(cpos, nodeGroup, {type = ui.flowC, ap = ui.cc})

    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:add(clickArea)

    return {
        view      = view,
        clickArea = clickArea,
        selectBg  = nodeGroup[2],
        normalBg  = nodeGroup[3],
        hlightBg  = nodeGroup[4],
        textLabel = nodeGroup[5],
    }
end


function LogInfoPopup.CreateInfoCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local logLabel = ui.label({p = cc.p(10,0), fnt = FONT.TEXT20, color = '#CCCCCC', ap = ui.lb})
    logLabel:setSystemFontName('Menlo')
    view:addChild(logLabel)

    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:add(clickArea)

    return {
        view      = view,
        logLabel  = logLabel,
        clickArea = clickArea,
    }
end


function LogInfoPopup.CreateHistoryView()
    local size = display.size
    local view = ui.layer({size = size})

    local blockLayer = ui.layer({size = size, color = '#0000003F', enable = true})
    view:add(blockLayer)

    local historyLayer = ui.layer()
    view:add(historyLayer)

    local dateBtnList = {}
    for btnIndex = 1, 9 do
        dateBtnList[btnIndex] = LogInfoPopup.CreateFuncBtn(cc.size(150, 50), '0000-00-00')
    end
    historyLayer:addList(dateBtnList)
    ui.flowLayout(cc.p(display.SAFE_R - 40, 80), dateBtnList, {type = ui.flowV, ap = ui.rt, gapH = 17})


    return {
        view        = view,
        blockLayer  = blockLayer,
        dateBtnList = dateBtnList,
    }
end


return LogInfoPopup
