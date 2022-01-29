--[[
 * author : kaishiqi
 * descpt : 登录服务器中介者
]]
local LoginServerMediator = class('LoginServerMediator', mvc.Mediator)

local RES_DICT = {
    SERVER_LIST_FRAME  = 'ui/server/server_bg.png',
    SERVER_LIST_TITLE  = 'ui/common/common_title_3.png',
    LIST_INSIDE_FRAME  = 'ui/common/common_bg_goods.png',
    LABEL_UNDERLINE    = 'ui/server/server_bg_line_1.png',
    BTN_CONFIRM        = 'ui/common/common_btn_orange.png',
    ALPHA_IMG          = 'ui/common/story_tranparent_bg.png',
    SERVER_PLAYER_ICON = 'ui/server/server_ico_player.png',
    CELL_FRAME_BLACK   = 'ui/server/server_frame_text_black.png',
    CELL_FRAME_DEFAULT = 'ui/server/server_frame_text_default.png',
    CELL_FRAME_SELECT  = 'ui/server/server_frame_text_selected.png',
    RECOMMEND_FRAME    = 'avatar/ui/avatarShop/shop_tag_sale_member.png',
}

local CreateView       = nil
local CreateServerCell = nil


function LoginServerMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'LoginServerMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method

function LoginServerMediator:Initial(key)
    self.super.Initial(self, key)

    local selectServerId  = checkint(self.ctorArgs_.serverId)
    self.lastLoginId_     = checkint(self.ctorArgs_.lastLoginId)
    self.serverDataList_  = checktable(self.ctorArgs_.servers)
    self.confirmServerCB_ = self.ctorArgs_.confirmServerCB
    self.isControllable_  = true
    self.serverCellDict_  = {}

    -- create view
    self.viewData_   = CreateView()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self.ownerScene_ = uiManager:GetCurrentScene()
    self.ownerScene_:AddDialog(self.viewData_.view)

    -- init view
    display.commonUIParams(self.viewData_.blackBg, {cb = handler(self, self.onClickBlackBgHandler_), animate = false})
    display.commonUIParams(self.viewData_.confirmBtn, {cb = handler(self, self.onClickConfirmButtonHandler_)})
    -- display.commonUIParams(self.viewData_.declareBtn, {cb = handler(self, self.onClickDeclareButtonHandler_)})
    self.viewData_.serverGridView:setDataSourceAdapterScriptHandler(handler(self, self.onServerGridDataAdapterHandler_))

    -- update view
    self:updateLastLoginLabel_()
    self.viewData_.serverGridView:setCountOfCell(#self:getServeDataList())
    self.viewData_.serverGridView:reloadData()

    for i, serverData in ipairs(self:getServeDataList() or {}) do
        if checkint(serverData.id) == selectServerId then
            self:setSelectIndex(i)
            break
        end
    end

    -- show ui
    self:show()
end


function LoginServerMediator:CleanupView()
    if self:getViewData().view  and (not tolua.isnull(self:getViewData().view )) then
        self:getViewData().view:runAction(cc.RemoveSelf:create())
        self.ownerScene_ = nil
    end     
end


function LoginServerMediator:OnRegist()
end
function LoginServerMediator:OnUnRegist()
end


function LoginServerMediator:InterestSignals()
    return {
    }
end
function LoginServerMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- view defines

CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- black bg
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
    view:addChild(blackBg)

    -- list layer
    local frameImg  = display.newImageView(_res(RES_DICT.SERVER_LIST_FRAME), 0, 0, {enable = true, ap = display.LEFT_BOTTOM})
    local frameSize = frameImg:getContentSize()
    local listLayer = display.newLayer(size.width/2, size.height/2, {size = frameSize, ap = display.CENTER})
    listLayer:addChild(frameImg)
    view:addChild(listLayer)

    local insideFrameSize = cc.size(frameSize.width - 60, frameSize.height - 200)
    listLayer:addChild(display.newImageView(_res(RES_DICT.LIST_INSIDE_FRAME), frameSize.width/2, frameSize.height/2, {scale9 = true, size = insideFrameSize}))

    -- list titleBar
    local listTitleBar = display.newButton(frameSize.width/2, frameSize.height - 30, {n = _res(RES_DICT.SERVER_LIST_TITLE), scale9 = true, enable = false})
    display.commonLabelParams(listTitleBar, fontWithColor(5, {text = __('选择服务器'), paddingW = 50}))
    listLayer:addChild(listTitleBar)

    -- last name info
    local lastInfoPos   = cc.p(frameSize.width/2 - 70, frameSize.height - 85)
    local lastNameSize  = cc.size(220, 2)
    local lastNameLabel = display.newLabel(lastInfoPos.x + lastNameSize.width/2, lastInfoPos.y, fontWithColor(13, {fontSize = 22, ap = display.CENTER_BOTTOM}))
    listLayer:addChild(lastNameLabel)
    listLayer:addChild(display.newLabel(lastInfoPos.x, lastInfoPos.y, fontWithColor(13, {fontSize = 22, text = __('最近登录：'), ap = display.RIGHT_BOTTOM})))
    listLayer:addChild(display.newImageView(_res(RES_DICT.LABEL_UNDERLINE), lastInfoPos.x, lastInfoPos.y, {scale9 = true, size = lastNameSize, ap = display.LEFT_TOP}))

    -- server gridView
    local serverGridSize = cc.size(insideFrameSize.width - 8, insideFrameSize.height - 8)
    local serverGridView = CGridView:create(serverGridSize)
    serverGridView:setSizeOfCell(cc.size(serverGridSize.width/2, 114))
    serverGridView:setPosition(frameSize.width/2, frameSize.height/2)
    serverGridView:setAnchorPoint(display.CENTER)
    serverGridView:setColumns(2)
    listLayer:addChild(serverGridView)

    -- confirm button
    -- local confirmBtn = display.newButton(frameSize.width/2 + 80, 55, {n = _res(RES_DICT.BTN_CONFIRM), ap = display.LEFT_CENTER})
    local confirmBtn = display.newButton(frameSize.width/2, 55, {n = _res(RES_DICT.BTN_CONFIRM), ap = display.LEFT_CENTER})
    display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确定')}))
    listLayer:addChild(confirmBtn)

    --[[
    -- declare button
    local declarePos = cc.p(frameSize.width/2 + 50, confirmBtn:getPositionY())
    local declareBtn = display.newButton(declarePos.x, declarePos.y, {n = _res(RES_DICT.ALPHA_IMG), scale9 = true, ap = display.RIGHT_CENTER})
    display.commonLabelParams(declareBtn, fontWithColor(13, {fontSize = 22, text = __('《食之契约》公平运营申明'), paddingW = 1, offset = cc.p(-1,0)}))
    listLayer:addChild(declareBtn)

    local declareSize = declareBtn:getContentSize()
    listLayer:addChild(display.newImageView(_res(RES_DICT.LABEL_UNDERLINE), declarePos.x, declarePos.y - 16, {scale9 = true, size = cc.size(declareSize.width, 2), ap = display.RIGHT_CENTER}))
    --]]

    return {
        view           = view,
        blackBg        = blackBg,
        listLayer      = listLayer,
        lastNameLabel  = lastNameLabel,
        serverGridView = serverGridView,
        confirmBtn     = confirmBtn,
        -- declareBtn     = declareBtn,
    }
end


CreateServerCell = function(size)
    local view = CGridViewCell:new()
    view:setCascadeOpacityEnabled(true)
    view:setContentSize(size)

    local normalImg = display.newImageView(_res(RES_DICT.CELL_FRAME_DEFAULT), size.width/2, size.height/2)
    local selectImg = display.newImageView(_res(RES_DICT.CELL_FRAME_SELECT), size.width/2, size.height/2)
    view:addChild(normalImg)
    view:addChild(selectImg)

    local iconLayer = display.newLayer(74, size.height/2 + 3)
    iconLayer:setScale(0.56)
    view:addChild(iconLayer)

    local serverLabel = display.newLabel(size.width/2 - 50, size.height/2 - 5, fontWithColor(4, {color = '#8F7640', ap = display.LEFT_BOTTOM}))
    view:addChild(serverLabel)
    view:addChild(display.newImageView(_res(RES_DICT.LABEL_UNDERLINE), serverLabel:getPositionX() - 10, serverLabel:getPositionY() - 6, {ap = display.LEFT_TOP}))

    local playerIcon = display.newImageView(_res(RES_DICT.SERVER_PLAYER_ICON), size.width - 40, 32)
    view:addChild(playerIcon)

    local playerLabel = display.newLabel(playerIcon:getPositionX() - 20, playerIcon:getPositionY(), {fontSize = 18, color = '#8F7640', ap = display.RIGHT_CENTER})
    view:addChild(playerLabel)

    local blackImg = display.newImageView(_res(RES_DICT.CELL_FRAME_BLACK), size.width/2, size.height/2)
    view:addChild(blackImg)

    local disableLable = display.newLabel(size.width - 20, size.height - 20, fontWithColor(7, {fontSize = 20, text = __('正在维护'), ap = display.RIGHT_TOP}))
    view:addChild(disableLable)

    local recommendBar = display.newButton(size.width - 6, size.height , {n = _res(RES_DICT.RECOMMEND_FRAME), enable = false, isFlipX = true, ap = display.RIGHT_TOP ,scale9 =true })
    display.commonLabelParams(recommendBar, fontWithColor(7, {fontSize = 20, text = __('推荐'), offset = cc.p(5,0) , paddingW = 10 }))
    view:addChild(recommendBar)

    local clickArea = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickArea)

    return {
        view         = view,
        normalImg    = normalImg,
        selectImg    = selectImg,
        blackImg     = blackImg,
        iconLayer    = iconLayer,
        serverLabel  = serverLabel,
        playerIcon   = playerIcon,
        playerLabel  = playerLabel,
        disableLable = disableLable,
        recommendBar = recommendBar,
        clickArea    = clickArea,
    }
end


-------------------------------------------------
-- get / set

function LoginServerMediator:getViewData()
    return self.viewData_
end


function LoginServerMediator:getServeDataList()
    return self.serverDataList_
end


function LoginServerMediator:getLastLoginId()
    return self.lastLoginId_
end


function LoginServerMediator:getSelectIndex()
    return self.selectIndex_
end
function LoginServerMediator:setSelectIndex(index)
    local oldSelectIndex = checkint(self:getSelectIndex())
    self.selectIndex_    = checkint(index)
    self:updateServerCell_(oldSelectIndex)
    self:updateServerCell_(self.selectIndex_)
end


-------------------------------------------------
-- public method

function LoginServerMediator:show()
    local actionTime     = 0.15
    self.isControllable_ = false
    self.viewData_.listLayer:setScale(0)
    self.viewData_.listLayer:setOpacity(0)

    self.viewData_.view:stopAllActions()
    self.viewData_.view:runAction(cc.Sequence:create({
        cc.Spawn:create(
            cc.TargetedAction:create(self.viewData_.listLayer, cc.FadeIn:create(actionTime)),
            cc.TargetedAction:create(self.viewData_.listLayer, cc.ScaleTo:create(actionTime, 1))
        ),
        cc.CallFunc:create(function()
            self.isControllable_ = true
        end)
    }))
end
function LoginServerMediator:hide()
    local actionTime     = 0.1
    self.isControllable_ = false
    self.viewData_.listLayer:setScale(1)
    self.viewData_.listLayer:setOpacity(255)

    self.viewData_.view:stopAllActions()
    self.viewData_.view:runAction(cc.Sequence:create({
        cc.Spawn:create(
            cc.TargetedAction:create(self.viewData_.listLayer, cc.FadeOut:create(actionTime)),
            cc.TargetedAction:create(self.viewData_.listLayer, cc.ScaleTo:create(actionTime, 0))
        ),
        cc.CallFunc:create(function()
            self:GetFacade():UnRegsitMediator(self:GetMediatorName())
        end)
    }))
end


-------------------------------------------------
-- private method

function LoginServerMediator:updateLastLoginLabel_()
    local lastLoginId    = checkint(self:getLastLoginId())
    local lastNameLabel  = self:getViewData().lastNameLabel
    local lastServerName = ''

    if lastLoginId > 0 then
        for i, serverData in ipairs(self:getServeDataList() or {}) do
            if serverData.id == lastLoginId then
                lastServerName = serverData.name
                break
            end
        end
    end
    display.commonLabelParams(lastNameLabel, {text = lastServerName})
end


function LoginServerMediator:updateServerCell_(index, cellViewData)
    local serverGridView = self:getViewData().serverGridView
    local cellViewData   = cellViewData or self.serverCellDict_[serverGridView:cellAtIndex(index - 1)]
    local serverData     = self:getServeDataList()[index]

    if cellViewData and serverData then

        -- update selected status
        local isSelected = index == self:getSelectIndex()
        cellViewData.normalImg:setVisible(not isSelected)
        cellViewData.selectImg:setVisible(isSelected)

        -- update server info
        local serverName = tostring(serverData.name)
        local foodIconId = checkint(serverData.foodIconId)
        display.commonLabelParams(cellViewData.serverLabel, {text = serverName})

        local iconPath = CommonUtils.GetGoodsIconPathById(serverData.foodIconId)
        cellViewData.iconLayer:removeAllChildren()
        cellViewData.iconLayer:setVisible(foodIconId > 0)
        cellViewData.iconLayer:addChild(display.newImageView(_res(iconPath)))

        -- update playerInfo
        local playerName = checkstr(serverData.playerName)
        if string.len(playerName) > 0 then
            cellViewData.playerIcon:setVisible(true)
            display.commonLabelParams(cellViewData.playerLabel, {text = playerName})
        else
            cellViewData.playerIcon:setVisible(false)
        end

        -- update recommend info
        local isRecommend = checkint(serverData.isRecommend) == 1
        cellViewData.recommendBar:setVisible(isRecommend)

        -- update other info
        cellViewData.blackImg:setVisible(false)
        cellViewData.disableLable:setVisible(false)
    end
end



-------------------------------------------------
-- handler

function LoginServerMediator:onClickBlackBgHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    self:hide()
end


function LoginServerMediator:onClickConfirmButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    if self.confirmServerCB_ then
        local selectIndex = checkint(self:getSelectIndex())
        local serverData  = self:getServeDataList()[selectIndex]
        self.confirmServerCB_(serverData)
    end

    self:hide()
end


function LoginServerMediator:onClickDeclareButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local uiManager = self:GetFacade():GetManager('UIManager')
    uiManager:ShowIntroPopup({moduleId = MODULE_DATA.SERVER_DECLARE})
end


function LoginServerMediator:onServerGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    local serverGridView = self:getViewData().serverGridView
    local serverCellSize = serverGridView:getSizeOfCell()

    -- create cell
    if pCell == nil then
        local cellViewData = CreateServerCell(serverCellSize)
        display.commonUIParams(cellViewData.clickArea, {cb = handler(self, self.onClickServerCellHandler_)})

        pCell = cellViewData.view
        self.serverCellDict_[pCell] = cellViewData
    end

    -- init cell
    local cellViewData = self.serverCellDict_[pCell]
    cellViewData.clickArea:setTag(index)

    -- update cell
    self:updateServerCell_(index, cellViewData)

    return pCell
end


function LoginServerMediator:onClickServerCellHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local cellIndex = sender:getTag()
    self:setSelectIndex(cellIndex)
end


return LoginServerMediator
