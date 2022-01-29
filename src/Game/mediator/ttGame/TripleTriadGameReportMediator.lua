--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 战报中介者
]]
local TTGameReportMediator = class('TripleTriadGameReportMediator', mvc.Mediator)

local RES_DICT = {
    BG_FRAME   = _res('ui/common/common_bg_9.png'),
    COM_TITLE  = _res('ui/common/common_bg_title_2.png'),
    INFO_BAR   = _res('ui/ttgame/report/cardgame_report_label_text.png'),
    CELL_FRAME = _res('ui/ttgame/report/cardgame_report_bg_frame.png'),
    DRAW_ICON  = _res('ui/ttgame/report/cardgame_report_ico_draw.png'),
    LOSE_ICON  = _res('ui/ttgame/report/cardgame_report_ico_lose.png'),
    WIN_ICON   = _res('ui/ttgame/report/cardgame_report_ico_win.png'),
}

local CreateView       = nil
local CreateReportCell = nil


function TTGameReportMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGameReportMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


CreateView = function()
    local size = cc.size(550, 640)
    local view = display.newLayer(0, 0, {size = size, bg = RES_DICT.BG_FRAME, scale9 = true})

    local titleBar = display.newButton(size.width/2, size.height - 20, {n = RES_DICT.COM_TITLE, enable = false})
    display.commonLabelParams(titleBar, fontWithColor(3, {text = __('战报'), offset = cc.p(0, -2)}))
    view:addChild(titleBar)

    -- report info
    local infoLayerNode = display.newLayer(size.width/2, size.height - 75, {bg = RES_DICT.INFO_BAR, ap = display.CENTER})
    local infoLayerSize = infoLayerNode:getContentSize()
    view:addChild(infoLayerNode)

    local reportCountPoint = cc.p(infoLayerNode:getPositionX() - infoLayerSize.width/2 + 20, infoLayerNode:getPositionY())
    local reportRatePoint  = cc.p(infoLayerNode:getPositionX() + infoLayerSize.width/2 - 20, infoLayerNode:getPositionY())
    local reportCountLabel = display.newLabel(reportCountPoint.x, reportCountPoint.y, fontWithColor(18, {text = '----', ap = display.LEFT_CENTER}))
    local reportRateLabel  = display.newLabel(reportRatePoint.x, reportRatePoint.y, fontWithColor(18, {text = '----', ap = display.RIGHT_CENTER}))
    view:addChild(reportCountLabel)
    view:addChild(reportRateLabel)


    -- empty layer
    local emptyLayer = display.newLayer()
    view:addChild(emptyLayer,1)

    local emptyImage = AssetsUtils.GetCartoonNode(3, size.width/2, size.height/2)
    emptyImage:setScale(0.6)
    emptyLayer:addChild(emptyImage)
    
    emptyLayer:addChild(display.newLabel(size.width/2, size.height/2 - 180, fontWithColor(15, {text = __('暂时没有任何对战记录')})))
    

    -- report list
    local reportListSize = cc.size(size.width - 30, size.height - 110)
    local reportListView = CTableView:create(reportListSize)
    reportListView:setSizeOfCell(cc.size(reportListSize.width, 125))
    reportListView:setDirection(eScrollViewDirectionVertical)
    reportListView:setAnchorPoint(display.CENTER_BOTTOM)
    reportListView:setPosition(size.width/2, 5)
    -- reportListView:setBackgroundColor(cc.r4b(250))
    view:addChild(reportListView)

    return {
        view             = view,
        emptyLayer       = emptyLayer,
        reportCountLabel = reportCountLabel,
        reportRateLabel  = reportRateLabel,
        reportListView   = reportListView,
    }
end


CreateReportCell = function(size)
    local view = CTableViewCell:new()
    view:setContentSize(size)

    -- block layer
    local centerPos = cc.p(size.width/2, size.height/2)
    view:addChild(display.newImageView(RES_DICT.CELL_FRAME, centerPos.x, centerPos.y))

    local iconPos  = cc.p(centerPos.x - 207, centerPos.y)
    local winIcon  = display.newImageView(RES_DICT.WIN_ICON, iconPos.x, iconPos.y)
    local drawIcon = display.newImageView(RES_DICT.DRAW_ICON, iconPos.x, iconPos.y)
    local failIcon = display.newImageView(RES_DICT.LOSE_ICON, iconPos.x, iconPos.y)
    view:addChild(winIcon)
    view:addChild(drawIcon)
    view:addChild(failIcon)
    
    local headNode = require('common.PlayerHeadNode').new({showLevel = true})
    headNode:setPosition(iconPos.x + 110 , iconPos.y)
    headNode:setScale(0.65)
    view:addChild(headNode)
    
    local nameLabel = display.newLabel(headNode:getPositionX() + 65, headNode:getPositionY() + 30, fontWithColor(3, {color = '#d07022', ap = display.LEFT_CENTER, text = '----'}))
    view:addChild(nameLabel)

    local timeLabel = display.newLabel(nameLabel:getPositionX(), headNode:getPositionY() - 30, fontWithColor(15, {ap = display.LEFT_CENTER, text = '----'}))
    view:addChild(timeLabel)

    local headClickArea = display.newLayer(size.width/2 - 50, 0, {size = cc.size(100, size.height), ap = display.RIGHT_BOTTOM, color = cc.r4b(0), enable = true})
    local teamClickArea = display.newLayer(0, 0, {size = cc.size(size.width, size.height), ap = display.LEFT_BOTTOM, color = cc.r4b(0), enable = true})
    view:addChild(teamClickArea)
    view:addChild(headClickArea)

    return {
        view          = view,
        winIcon       = winIcon,
        drawIcon      = drawIcon,
        failIcon      = failIcon,
        headNode      = headNode,
        nameLabel     = nameLabel,
        timeLabel     = timeLabel,
        headClickArea = headClickArea,
        teamClickArea = teamClickArea,
    }
end


-------------------------------------------------
-- inheritance

function TTGameReportMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    self.reportCellDict_ = {}
    self.reportListData_ = {}

    -- create view
    self.viewData_    = CreateView()
    self.ownerScene_  = app.uiMgr:GetCurrentScene()
    local reportLayer = display.newLayer(0, 0)
    self:getOwnerScene():AddDialog(reportLayer)
    self:SetViewComponent(reportLayer)
    
    local commonBG = require('common.CloseBagNode').new({callback = function()
        PlayAudioByClickClose()
        self:close()
    end})
    commonBG:setName('commonBG')
    commonBG:setPosition(display.center)
    commonBG:addContentView(self:getViewData().view)
    reportLayer:addChild(commonBG)

    -- add listener
    self:getViewData().reportListView:setDataSourceAdapterScriptHandler(handler(self, self.onReportListDataAdapterHandler_))
    
    -- update views
    self:updateRateLabel_()
    self:updateCountLabel_()
end


function TTGameReportMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function TTGameReportMediator:OnRegist()
    regPost(POST.TTGAME_REPORT)

    self:SendSignal(POST.TTGAME_REPORT.cmdName)
end


function TTGameReportMediator:OnUnRegist()
    unregPost(POST.TTGAME_REPORT)
end


function TTGameReportMediator:InterestSignals()
    return {
        POST.TTGAME_REPORT.sglName
    }
end
function TTGameReportMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if POST.TTGAME_REPORT.sglName then
        self:setReportListData(data.report or {})
    end
end


-------------------------------------------------
-- get / set

function TTGameReportMediator:getOwnerScene()
    return self.ownerScene_
end


function TTGameReportMediator:getViewData()
    return self.viewData_
end


function TTGameReportMediator:getReportListData()
    return self.reportListData_ or {}
end
function TTGameReportMediator:setReportListData(data)
    self.reportListData_ = data or {}
    self:getViewData().emptyLayer:setVisible(#self:getReportListData() <= 0)
    self:getViewData().reportListView:setCountOfCell(#self:getReportListData())
    self:getViewData().reportListView:reloadData()
    self:updateCountLabel_()
    self:updateRateLabel_()
end


-------------------------------------------------
-- public

function TTGameReportMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function TTGameReportMediator:updateRateLabel_()
    local winnerCount = 0
    local reportCount = #self:getReportListData()
    for _, reportData in ipairs(self:getReportListData()) do
        if TTGAME_DEFINE.RESULT_TYPE.WIN == checkint(reportData.result) then
            winnerCount = winnerCount + 1
        end
    end
    local winnerRateNumber = reportCount == 0 and '--' or checkint(winnerCount / reportCount * 100)
    local reportRateLabel  = self:getViewData().reportRateLabel
    display.commonLabelParams(reportRateLabel, {text = string.fmt(__('胜率：_num_%'), {_num_ = tostring(winnerRateNumber)})})
end


function TTGameReportMediator:updateCountLabel_()
    local reportCountNumber = #self:getReportListData()
    local reportCountLabel  = self:getViewData().reportCountLabel
    display.commonLabelParams(reportCountLabel, {text = string.fmt(__('总场次：_num_'), {_num_ = reportCountNumber})})
end


function TTGameReportMediator:initReportCell_(viewData)
    local cellViewData = viewData
    display.commonUIParams(cellViewData.headClickArea, {cb = handler(self, self.onClickReaportCellHeadAreaHandler_)})
    display.commonUIParams(cellViewData.teamClickArea, {cb = handler(self, self.onClickReaportCellTeamAreaHandler_)})
end
function TTGameReportMediator:updateReportCell_(cellIndex, viewData)
    local reportListView = self:getViewData().reportListView
    local cellViewData   = viewData or self.reportCellDict_[reportListView:cellAtIndex(cellIndex - 1)]
    local cellListData   = self:getReportListData()[cellIndex] or {}

    if cellViewData then
        local result = checkint(cellListData.result)
        cellViewData.winIcon:setVisible(result == TTGAME_DEFINE.RESULT_TYPE.WIN)
        cellViewData.drawIcon:setVisible(result == TTGAME_DEFINE.RESULT_TYPE.DRAW)
        cellViewData.failIcon:setVisible(result == TTGAME_DEFINE.RESULT_TYPE.FAIL)

        cellViewData.headNode.showLevel = checkint(cellListData.opponentLevel) > 0
        cellViewData.headNode:RefreshUI({
            playerLevel = cellListData.opponentLevel,
            avatar      = cellListData.opponentAvatar,
            avatarFrame = cellListData.opponentAvatarFrame,
        })
        
        local timeFormatString = os.date('%Y-%m-%d %H:%M:%S', checkint(cellListData.createTime))
        display.commonLabelParams(cellViewData.nameLabel, {text = tostring(cellListData.opponentName)})
        display.commonLabelParams(cellViewData.timeLabel, {text = tostring(timeFormatString)})
    end
end


-------------------------------------------------
-- handler

function TTGameReportMediator:onReportListDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    if pCell == nil then
        local cellNodeSize = self:getViewData().reportListView:getSizeOfCell()
        local cellViewData = CreateReportCell(cellNodeSize)
        self.reportCellDict_[cellViewData.view] = cellViewData
        self:initReportCell_(cellViewData)
        pCell = cellViewData.view
    end
    
    local cellViewData = self.reportCellDict_[pCell]
    self:updateReportCell_(index, cellViewData)
    cellViewData.headClickArea:setTag(index)
    cellViewData.teamClickArea:setTag(index)
    return pCell
end


function TTGameReportMediator:onClickReaportCellHeadAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local reportIndex  = checkint(sender:getTag())
    local cellListData = self:getReportListData()[reportIndex] or {}
    local playerId     = checkint(cellListData.opponentId)
    local playerLevel  = checkint(cellListData.opponentLevel)
    if playerLevel > 0 then
        app.uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(playerId)})
    end
end


function TTGameReportMediator:onClickReaportCellTeamAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local reportIndex  = checkint(sender:getTag())
    local cellListData = self:getReportListData()[reportIndex] or {}
    local battleCards  = checktable(cellListData.opponentBattleCards)
    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, battleCards = battleCards, type = 18})
end


return TTGameReportMediator
