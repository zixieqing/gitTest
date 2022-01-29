--[[
飞艇Mediator

todo
    1. 更新飞艇积分
    2. 根据倒计时更新 立即到达所需幻晶石数

--]]

local Mediator = mvc.Mediator
local AirShipHomeMediator = class("AirShipHomeMediator", Mediator)

local VIEW_TAG = 777110
local COMMON_TIP_TAG = 3000
local NAME = "AirShipHomeMediator"

local BTN_TAGS = {
    RULE_TAG = 1000,    -- 规则说明
    -- ACCELERATE_LADE_TAG = 1001, -- 加速时间  直接改用道具id
    LADE_TAG = 1002, -- 开船
    PACK_TAG = 1003, -- 装箱
    ONE_KEY_PACK = 1004, -- 一键装箱
}

local AIR_SHIP_ACTION_STATE = {
    SHOW_AIR_SHIP                    = 1,           -- 显示飞船
    HIDE_AIR_SHIP                    = 2,           -- 隐藏飞船
    SHOW_LOADING_NOTICE              = 3,           -- 显示装载预告
    HIDE_LOADING_NOTICE              = 4,           -- 隐藏装载预告
    SHOW_PACKING                     = 5,           -- 显示装载预告
    HIDE_PACKING                     = 6,           -- 隐藏装载预告
    SHOW_LOADING_NOTICE_POP_REWARD   = 7,           -- 在弹出奖励后显示装载预告
}

local DEFAULT_RATE_CARD_ID = 200071
local GOODS_ACCELERATE_ID = 890045

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")

local getTimeArr = nil
local CreateRichTextStr = nil

local ACCELERATELADE_CONF = CommonUtils.GetConfigAllMess('accelerateLade', 'airship') or {}

function AirShipHomeMediator:ctor(params, viewComponent)
    self.super:ctor(NAME,viewComponent)
    self.airShipHomeData = checktable(params)
    self.packTag = -1
    self.packTags = {} -- 用于 保存 装箱 的tag  防止 网速不好  用户切换 order cell 导致的刷新错误
    -- dump(self.airShipHomeData, 'reAirShipHomeMediator')
    -- self.airShipHomeData = getVData()
    self.ladeRewards = {}

    self.ladeUnitPrice = 10  or self.airShipHomeData.ladeUnitPrice
    self.airShipHomeData.accelerateArrivalDiamond = 10

    self.isCanOnkeyPack = false

    self.isControllable_ = true

end

function AirShipHomeMediator:InterestSignals()
	local signals = {
        POST.AIRSHIP_HOME.sglName,
        POST.AIRSHIP_PACK.sglName,
        POST.AIRSHIP_LADE.sglName,
        POST.AIRSHIP_ACCELERATE_LADE.sglName,
        COUNT_DOWN_ACTION,
        "REFRESH_NOT_CLOSE_GOODS_EVENT",
	}

	return signals
end

function AirShipHomeMediator:ProcessSignal( signal )
	local name = signal:GetName()
	-- print(name)
    local body = signal:GetBody()
    if name == POST.AIRSHIP_HOME.sglName then
        -- print(nextA)
        -- self.airShipHomeData = getVData(nextA)
        self.airShipHomeData = checktable(body)

        self:GetViewComponent():updateOnKeyBtnShowState(self:checkIsCanOnKeyPacking())
        self:ShowView(false)
    elseif name == POST.AIRSHIP_PACK.sglName then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "41-01"})
        local requestData = body.requestData
        local packId = checkint(requestData.packId)

        local rewards = body and body.rewards or {}

        if rewards and #rewards > 0 then
            uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end

        -- 如果是一键装箱
        if packId == -1 then
            self:updateOneKeyPackState()
            self:GetViewComponent():updateOnKeyBtnShowState(false)
            return
        end

        local isNormalPack = true
        if self.totalDiamondValue then
            -- 幻晶石装箱 更新幻晶石
            gameMgr:GetUserInfo().diamond = gameMgr:GetUserInfo().diamond - self.totalDiamondValue
            self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = (gameMgr:GetUserInfo().diamond)})
            self.totalDiamondValue = nil
            isNormalPack = false
        end

        self:updatePackCompleteUi(isNormalPack)
        -- self:up

    elseif name == POST.AIRSHIP_LADE.sglName then
        self.packTag = -1
        local rewards = body and body.rewards or {}
        local airshipPoint = body and body.airshipPoint or 0
        if rewards and #rewards > 0 then
            self.ladeRewards = rewards
        end

        self:SendSignal(POST.AIRSHIP_HOME.cmdName)
    -- elseif name == 'POST.AIRSHIP_ONE_KEY_PACK.sglName' then
        
    --     local packingViewData = self.viewData.packingViewData
    --     local packingLayer = packingViewData.packingLayer
    --     if packingLayer:isVisible() then
    --         self:GetViewComponent():showUiAction(AIR_SHIP_ACTION_STATE.HIDE_PACKING)
    --     end
        
    --     local datas = self.airShipHomeData.pack or {}
    --     for i, packData in ipairs(datas) do
    --         local hasDone = packData.hasDone == nil and 2 or checkint(packData.hasDone)
    --         if hasDone == 0 then
    --             self:updatePackCellCompleteState(i, true)
    --         end
    --     end
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "41-02"})
    elseif name == POST.AIRSHIP_ACCELERATE_LADE.sglName then
        self.isControllable_ = false
        -- 1. 移除倒计时
        timerMgr:RemoveTimer(COUNT_DOWN_TAG_AIR_SHIP)
        app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.AIRSHIP})
        -- 2. 更新幻晶石
        local requestData = body.requestData
        local goodsId     = requestData.goodsId
        local consumeNum  = body.num

        local conf = ACCELERATELADE_CONF[tostring(goodsId)]
        if conf then
            CommonUtils.DrawRewards({
                {goodsId = goodsId, num = -consumeNum}
            })
        end
        
        self:SendSignal(POST.AIRSHIP_HOME.cmdName)
    elseif name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then
        local airShipLayer = self.viewData.airShipViewData.airShipLayer
        if airShipLayer:isVisible() then
            self:updateAirShipView(self.airShipHomeData.pack)
        end

        if self.packTag then
            local data = checktable(self.airShipHomeData.pack[self.packTag])
            local needNum = data.num
            local goodsId = data.goodsId
            self:updateProgressBar(goodsId, needNum)
        end
    elseif name == COUNT_DOWN_ACTION then
        local tag = body.tag
        if tag ~= RemindTag.AIRSHIP then return end

        local seconds = checkint(body.countdown)
        self.airShipHomeData.nextArrivalLeftSeconds = seconds

        -- local ladeUnitPrice = self.ladeUnitPrice
        local loadingNoticeViewData = self.viewData.loadingNoticeViewData
        local timeNums = loadingNoticeViewData.timeNums

        local timeArr = getTimeArr(seconds)
        for i,v in ipairs(timeNums) do
            display.commonLabelParams(v, {text = tostring(timeArr[i])})
        end
        
        local accelerateBtns = loadingNoticeViewData.accelerateBtns
        for key, value in pairs(ACCELERATELADE_CONF) do
            local goodsId = checkint(value.goodsId)
            local accelerateBtn = accelerateBtns[goodsId]
            local confSeconds = checkint(value.seconds)

            if seconds % confSeconds == 0 then
                local consumeNum = math.ceil(seconds / confSeconds)
                local richText = accelerateBtn:getChildByTag(2000)
                if richText then
                    self:UpdateAccelerateText(richText, goodsId, consumeNum)
                end
            end
        end

        if seconds == 0 then
            -- 请求 home
            timerMgr:RemoveTimer(COUNT_DOWN_TAG_AIR_SHIP)

            self:SendSignal(POST.AIRSHIP_HOME.cmdName)
            local scene = uiMgr:GetCurrentScene()
            scene:RemoveDialogByTag(COMMON_TIP_TAG)
        end
    end
end

function AirShipHomeMediator:Initial( key )
	self.super.Initial(self,key)

    local viewParams = {tag = VIEW_TAG, mediatorName = NAME}
    local viewComponent  = require('Game.views.AirShipHomeView').new(viewParams)
	viewComponent:setTag(VIEW_TAG)
	viewComponent:setPosition(display.center)
	self:SetViewComponent(viewComponent)

    local scene = uiMgr:GetCurrentScene()
    -- scene:AddDialog(viewComponent)
    scene:AddGameLayer(viewComponent)

    self.viewData = viewComponent.viewData
    self:initUi()
end

function AirShipHomeMediator:initUi()
    local viewComponent = self:GetViewComponent()

    local viewData = self.viewData

    local ruleBtn = viewData.airShipViewData.ruleBtn
    ruleBtn:setTag(BTN_TAGS.RULE_TAG)
    display.commonUIParams(ruleBtn, {cb = handler(self, self.OnButtonAction)})

    local sailBtn = viewData.orderPrizeViewData.sailBtn
    sailBtn:setTag(BTN_TAGS.LADE_TAG)
    display.commonUIParams(sailBtn, {cb = handler(self, self.OnButtonAction)})

    local loadingNoticeViewData = viewData.loadingNoticeViewData
    for goodsId, btn in pairs(loadingNoticeViewData.accelerateBtns) do
        btn:setTag(goodsId)
        display.commonUIParams(btn, {cb = handler(self, self.OnButtonAction)})
    end

    local packBtn = viewData.packingViewData.packBtn
    packBtn:setTag(BTN_TAGS.PACK_TAG)
    display.commonUIParams(packBtn, {cb = handler(self, self.OnButtonAction)})

    local touchView = viewData.airShipViewData.touchView
    display.commonUIParams(touchView, {cb = handler(self, self.CloseHandler)})

    local oneKeyPackBtn = viewData.airShipViewData.oneKeyPackBtn
    oneKeyPackBtn:setTag(BTN_TAGS.ONE_KEY_PACK)
    display.commonUIParams(oneKeyPackBtn, {cb = handler(self, self.OnButtonAction)})

    local rankBtn = viewData.rankBtn
    if rankBtn then display.commonUIParams(rankBtn, {cb = handler(self, self.ShowRank)}) end

    self:GetViewComponent():updateOnKeyBtnShowState(self:checkIsCanOnKeyPacking())

    self:ShowView()

    -- viewComponent:showUiAction(4)
end

function AirShipHomeMediator:ShowView(isFirst)
    if isFirst == nil then isFirst = true end

    local viewComponent = self:GetViewComponent()
    local function callback()
        if self.ladeRewards and #self.ladeRewards > 0 then
            -- viewComponent:showUiAction(AIR_SHIP_ACTION_STATE.SHOW_AIR_SHIP, callback)
            local closeCallback = function ()
                PlayAudioClip(AUDIOS.UI.ui_transport_prediction.id)
                if viewComponent.showUiAction then
                    viewComponent:showUiAction(AIR_SHIP_ACTION_STATE.SHOW_LOADING_NOTICE_POP_REWARD)
                end
                self.isControllable_ = true
            end
            uiMgr:AddDialog('common.RewardPopup', {rewards = self.ladeRewards, closeCallback = closeCallback})
            self.ladeRewards = {}
        else
            self.isControllable_ = true
        end
    end

    self.isControllable_ = false
    gameMgr:startAirShipCountDown(checkint(self.airShipHomeData.nextArrivalLeftSeconds))

    local rareCardId = self.airShipHomeData.rareCardId
    viewComponent:updateTimeLimitActivityBg(self.airShipHomeData.rareCardBg)
    viewComponent:updateActivityCardView(rareCardId or DEFAULT_RATE_CARD_ID)

    -- self.airShipHomeData.nextArrivalLeftSeconds = 10000
    if checkint(self.airShipHomeData.nextArrivalLeftSeconds) > 0 then
        self:ShowLoadingNoticeView(viewComponent)
        if isFirst then
            PlayAudioClip(AUDIOS.UI.ui_transport_prediction.id)
            viewComponent:showUiAction(AIR_SHIP_ACTION_STATE.SHOW_LOADING_NOTICE, callback)
        else
            PlayAudioClip(AUDIOS.UI.ui_transport_depart.id)
            viewComponent:showUiAction(AIR_SHIP_ACTION_STATE.HIDE_AIR_SHIP, callback, self.airShipHomeData.rareCardId)
        end
    else
        self:ShowAirShipView(viewComponent)

        if isFirst then
            PlayAudioClip(AUDIOS.UI.ui_transport_down.id)
            viewComponent:showUiAction(AIR_SHIP_ACTION_STATE.SHOW_AIR_SHIP, callback)
        else
            PlayAudioClip(AUDIOS.UI.ui_transport_down.id)
            viewComponent:showUiAction(AIR_SHIP_ACTION_STATE.HIDE_LOADING_NOTICE, callback)
        end
    end
end

function AirShipHomeMediator:ShowAirShipView(viewComponent)
    if viewComponent == nil then return end

    local airShipViewData = self.viewData.airShipViewData
    local airShipLayer = airShipViewData.airShipLayer
    local airShipDoor = airShipViewData.airShipDoor

    self:updateAirShipView(self.airShipHomeData.pack)
    self:updateOrderPrizeView(self.airShipHomeData.ladeRewards, self.airShipHomeData.airshipPoint)
    
end

function AirShipHomeMediator:ShowLoadingNoticeView(viewComponent)
    if viewComponent == nil then return end

    local loadingNoticeViewData = self.viewData.loadingNoticeViewData
    local loadingNoticeView = loadingNoticeViewData.view
    local orderCells = loadingNoticeViewData.orderCells
    local timeNums = loadingNoticeViewData.timeNums

    loadingNoticeView:setVisible(true)

    self:updateLoadingNoticeView(self.airShipHomeData)
end

--  0: 未完成 1: 已完成 2:无状态
function AirShipHomeMediator:ShowOrderCell(parent, data)
    -- dump(data)
    local cViewData = parent.viewData
    local orderImgs = cViewData.orderImgs
    local goodsId = data.goodsId
    local hasDone = data.hasDone == nil and 2 or data.hasDone

    local showView = nil
    for i,v in pairs(orderImgs) do
        v:setVisible(i == hasDone)
        if i == hasDone then
            showView = v
        end
    end

    if hasDone == 0 then
        local goodNode = cViewData.goodNode
        -- local nextEnergyLabel = cViewData.nextEnergyLabel
        local goodBgN = cViewData.goodBgN
        local goodBgS = cViewData.goodBgS
        local ownNumLabel = cViewData.ownNumLabel
        local needNumLabel = cViewData.needNumLabel

        local numBgSize = cViewData.numBgSize
        goodBgN:setVisible(true)
        goodBgS:setVisible(false)
        goodNode:RefreshSelf({goodsId = goodsId})

        local ownNum = CommonUtils.GetCacheProductNum(goodsId)
        local needNum = data.num

        local fontPath = ownNum < needNum and 'font/small/common_text_num_5.fnt' or 'font/small/common_text_num.fnt'
        ownNumLabel:setBMFontFilePath(fontPath)
        ownNumLabel:setString(ownNum)

        needNumLabel:setString('/' .. needNum)

        local ownNumSize = ownNumLabel:getContentSize()
        local needNumSize = needNumLabel:getContentSize()
        ownNumLabel:setPosition(numBgSize.width / 2 - needNumSize.width / 2, numBgSize.height / 2)
        needNumLabel:setPosition(numBgSize.width / 2 + ownNumSize.width / 2, numBgSize.height / 2)

    end

    return showView
 end

 function AirShipHomeMediator:ShowRank()
    if not self.isControllable_ then return end
    -- AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "AirShipHomeMediator"},
    -- {name = "RankingListMediator", params = {rankTypes = RankTypes.AIRSHIP}})
    PlayAudioByClickNormal()
    local RankingListMediator = require( 'Game.mediator.RankingListMediator' )
    local mediator = RankingListMediator.new({rankTypes = RankTypes.AIRSHIP})
    self:GetFacade():RegistMediator(mediator)
 end

function AirShipHomeMediator:updateAirShipView(datas)
    if datas == nil then return end

    local airShipViewData = self.viewData.airShipViewData
    local cells = airShipViewData.cells

    -- 1.设置所有 cell 的显示状态
    for i,cell in ipairs(cells) do
        local showView = self:ShowOrderCell(cell, checktable(datas[i]))
        cell:setTag(i)
        display.commonUIParams(cell, {cb = handler(self, self.OnOrderCellAction)})
    end

end

function AirShipHomeMediator:updateOrderPrizeView(datas, airshipPoint)
    if datas == nil then return end
    local orderPrizeViewData = self.viewData.orderPrizeViewData
    local orderPrizeLayer = orderPrizeViewData.orderPrizeLayer
    local rewardList      = orderPrizeViewData.rewardList
    rewardList:removeAllNodes()

    local cloneData = clone(datas)
    local airshipPointConf = {airshipPoint = airshipPoint, img = _res('ui/common/ship_order_ico_point.png'), bg = _res('ui/common/common_frame_goods_5.png')}
    table.insert(cloneData, 1, airshipPointConf)
    -- table.insert(cloneData, 1, airshipPointConf)

    orderPrizeLayer:setVisible(true)

    local function callBack(sender, params)
        PlayAudioByClickNormal()
        if not self.isControllable_ then return end
        if params then
            uiMgr:ShowInformationTipsBoard(params)
        else
            uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end
    end

    local goodLayerSize = cc.size(93, 90)
    for i,v in ipairs(cloneData) do
        local goodLayer = display.newLayer(0, 0,{size = goodLayerSize})
        local goodNode = nil
        if v.airshipPoint then
            goodNode = display.newButton(0, 0, {n = v.bg, cb = function (sender)
                local params = {targetNode = goodNode, type = 9, title = __('空运积分'),
                    descr = __('每次空运开船可获得的积分，主要运用于空运排行榜。'),
                    sub = __('特殊'),
                    mainIconConf = airshipPointConf
                }
                callBack(sender, params)
            end})
            local nodeSize = goodNode:getContentSize()
            local img = display.newImageView(v.img, nodeSize.width / 2, nodeSize.height / 2, {ap = display.CENTER})
            img:setScale(0.55)
            goodNode:addChild(img)

            local infoLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', tostring(v.airshipPoint))
            display.commonUIParams(infoLabel, {ap = display.RIGHT_BOTTOM})
            infoLabel:setPosition(cc.p(nodeSize.width - 5, 3))
            goodNode:addChild(infoLabel)
        else
            goodNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, callBack = callBack})
        end

        if goodNode then
            goodNode:setScale(0.8)
            display.commonUIParams(goodNode, {po = cc.p(goodLayerSize.width / 2, goodLayerSize.height / 2)})
            goodLayer:addChild(goodNode)
            rewardList:insertNodeAtLast(goodLayer)
        end
    end

    rewardList:setBounceable(#cloneData > 4)
    rewardList:reloadData()
    rewardList:setContentOffset(rewardList:getMaxOffset())
end

function AirShipHomeMediator:updateLoadingNoticeView(datas)
    if datas == nil then return end

    local loadingNoticeViewData = self.viewData.loadingNoticeViewData
    local orderCells = loadingNoticeViewData.orderCells
    local timeNums = loadingNoticeViewData.timeNums
    local accelerateBtns = loadingNoticeViewData.accelerateBtns

    local nextArrivalLeftSeconds = datas.nextArrivalLeftSeconds

    -- 开启倒计时
    if nextArrivalLeftSeconds > 0 then
        gameMgr:startAirShipCountDown(nextArrivalLeftSeconds)
    end

    for key, value in pairs(ACCELERATELADE_CONF) do
        local goodsId = checkint(value.goodsId)
        local accelerateBtn = accelerateBtns[goodsId]
        local confSeconds = checkint(value.seconds)

        local consumeNum = math.ceil(nextArrivalLeftSeconds / confSeconds)
        local richText = accelerateBtn:getChildByTag(2000)
        if richText then
            self:UpdateAccelerateText(richText, goodsId, consumeNum)
        end
    end

    -- 刷新订单
    local pack = datas.pack
    for i,v in ipairs(orderCells) do
        local cViewData = v.viewData
        local goodNode = cViewData.goodNode
        local activeBg = cViewData.activeBg
        local noGoodBg = cViewData.noGoodBg
        local orderData = pack[i]
        goodNode:setVisible(false)
        activeBg:setVisible(false)
        noGoodBg:setVisible(false)
        if orderData then
            goodNode:setVisible(true)
            activeBg:setVisible(true)
            goodNode:RefreshSelf({goodsId = orderData.goodsId})
        else
            noGoodBg:setVisible(true)
        end
    end
end

function AirShipHomeMediator:updatePackCompleteUi(isNormalPack)
    

    -- 1. 隐藏 装箱界面
    local packingViewData = self.viewData.packingViewData
    local packingLayer = packingViewData.packingLayer
    -- packingLayer:setVisible(false)
    self:GetViewComponent():showUiAction(AIR_SHIP_ACTION_STATE.HIDE_PACKING)

    -- 2. 更新本地数据
    for i,v in pairs(self.packTags) do
        self:updatePackCellCompleteState(v, isNormalPack)
    end

    -- 3. 清除 packTag 缓存
    self.packTags = {}

end

function AirShipHomeMediator:updatePackCellCompleteState(tag, isNormalPack)
    -- 1 更改 订单数据
    self.airShipHomeData.pack[tag].hasDone = 1

    -- 2 更新背包数据
    self:updateBackpackData(tag, isNormalPack)

    -- 3 更改订单 cell
    local airShipViewData = self.viewData.airShipViewData
    local cells = airShipViewData.cells
    local cell = cells[tag]
    self:ShowOrderCell(cell, self.airShipHomeData.pack[tag])
end

function AirShipHomeMediator:updateBackpackData(tag, isNormalPack)
    local num = 0
    local goodsId = self.airShipHomeData.pack[tag].goodsId
    
    if isNormalPack then
        -- 2.2 减去背包中的道具
        num = self.airShipHomeData.pack[tag].num
    else
        num = CommonUtils.GetCacheProductNum(goodsId)
    end
    
    CommonUtils.DrawRewards({{goodsId = goodsId, num = -1 * num}}, true)
end

function AirShipHomeMediator:updateProgressBar(goodsId, needNum)
    if needNum and goodsId then
        local packingViewData = self.viewData.packingViewData
        local progressBar = packingViewData.progressBar
        local ownNum = CommonUtils.GetCacheProductNum(goodsId)
        progressBar:setMaxValue(needNum)
        progressBar:setValue(ownNum)
    end
end

function AirShipHomeMediator:updateOneKeyPackState()
    local packingViewData = self.viewData.packingViewData
    local packingLayer = packingViewData.packingLayer
    if packingLayer:isVisible() then
        self:GetViewComponent():showUiAction(AIR_SHIP_ACTION_STATE.HIDE_PACKING)
    end

    self.needPackList         = self.needPackList or {}
    local canPackList         = self.needPackList.canPackList
    local diamondPackList     = self.needPackList.diamondPackList
    local consumeDiamondCount = self.needPackList.consumeDiamondCount

    if canPackList then
        for i, packTag in ipairs(canPackList) do
            self:updatePackCellCompleteState(packTag, true)
        end
    end

    if diamondPackList then
        for i, packTag in ipairs(diamondPackList) do
            self:updatePackCellCompleteState(packTag, false)
        end
    end

    if consumeDiamondCount then
        gameMgr:GetUserInfo().diamond = gameMgr:GetUserInfo().diamond - consumeDiamondCount
        self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = (gameMgr:GetUserInfo().diamond)})
    end

    self.needPackList = nil
    
end


function AirShipHomeMediator:initOnKeyPackingData()
    local datas = self.airShipHomeData.pack or {}
    local canPackList = {}
    local diamondPackList = {}
    local consumeDiamondCount = 0
    if next(datas) ~= nil then
        for i, v in ipairs(datas) do
            if v.hasDone == 0 then
                local goodsId = v.goodsId
                local ownNum = CommonUtils.GetCacheProductNum(goodsId)
                local needNum = checkint(v.num)
                if ownNum >= needNum then
                    table.insert(canPackList, i)
                else
                    local goodData = checktable(CommonUtils.GetConfig('goods', 'goods', goodsId)) or {}
                    local diamondValue = checknumber(goodData.diamondValue)
                    if diamondValue == 0 then
                        print(string.format('goods %s diamondValue is 0', tostring(goodsId)))
                    end
                    consumeDiamondCount = consumeDiamondCount + diamondValue * (needNum - ownNum)
                    table.insert(diamondPackList, i)
                end
            end
        end
    end
    return canPackList, diamondPackList, consumeDiamondCount
end

function AirShipHomeMediator:checkIsCanOnKeyPacking()
    local canPackList, diamondPackList = self:initOnKeyPackingData()
    return not (next(canPackList) == nil and next(diamondPackList) == nil)
end

function AirShipHomeMediator:OnButtonAction(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local tag = sender:getTag()

    local accelerateladeConf = ACCELERATELADE_CONF[tostring(tag)]
    if accelerateladeConf then
        local costGoodsId = tag
        local goodsConfig = CommonUtils.GetConfig('goods', 'goods', costGoodsId) or {}
        local nextArrivalLeftSeconds = self.airShipHomeData.nextArrivalLeftSeconds
        local second = checkint(accelerateladeConf.seconds)
        local consumeNum = math.ceil(nextArrivalLeftSeconds / second)
        if CommonUtils.GetCacheProductNum(costGoodsId) >= consumeNum then
            local commonTip = require( 'common.CommonTip' ).new({ 
                text = __('是否要加快进度?'), 
                descr = string.format(__('此项操作将会扣除您%d%s!'), consumeNum, tostring(goodsConfig.name)), callback = function()
                PlayAudioByClickNormal()
                self:SendSignal(POST.AIRSHIP_ACCELERATE_LADE.cmdName, {goodsId = costGoodsId})
                -- app:DispatchObservers(POST.AIRSHIP_ACCELERATE_LADE.sglName, {requestData = {goodsId = costGoodsId}, num = 8 * 60 * 60 - 100})
            end })
            commonTip:setPosition(display.center)
            commonTip:setTag(COMMON_TIP_TAG)
            local scene = uiMgr:GetCurrentScene()
            scene:AddDialog(commonTip, 10)
        else
            if costGoodsId == DIAMOND_ID then
                if GAME_MODULE_OPEN.NEW_STORE then
                    app.uiMgr:showDiamonTips()
                else
                    uiMgr:ShowInformationTips(__("幻晶石不足"))
                end
            else
                app.uiMgr:AddDialog("common.GainPopup", {goodId = costGoodsId})
            end
        end

        return
    end

    -- print('GetViewComponent', tag)
    if tag == BTN_TAGS.RULE_TAG then
        uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.AIRSHIP)]})
    elseif tag == BTN_TAGS.LADE_TAG then
        local isCanLade = true

        for i,v in ipairs(self.airShipHomeData.pack) do
            isCanLade = (v.hasDone == 1) and isCanLade
        end

        if isCanLade then
            self:SendSignal(POST.AIRSHIP_LADE.cmdName)
        else
            uiMgr:ShowInformationTips(__("没有全部装箱，不能开船！"))
        end
        -- self:GetFacade():DispatchObservers(POST.AIRSHIP_LADE.sglName)
    elseif tag == BTN_TAGS.PACK_TAG then

        local data = self.airShipHomeData.pack[self.packTag]

        local ownNum = CommonUtils.GetCacheProductNum(data.goodsId)
        local needNum = data.num

        local packId = data.packId

        if ownNum >= needNum then
            -- 如果能装箱 则保存 packtag  self.packTags
            self.packTags[self.packTag] = self.packTag
            self:SendSignal(POST.AIRSHIP_PACK.cmdName, {packId = packId})
        else
            local goodData = checktable(CommonUtils.GetConfig('goods', 'goods', data.goodsId))
            local diamondValue = checknumber(goodData.diamondValue)

            if diamondValue == 0 then
                -- 单价为0
                uiMgr:ShowInformationTips(__("道具不足"))
                return
            end

            local totalDiamondValue = diamondValue * (needNum - ownNum)
            local ownDiamond = gameMgr:GetUserInfo().diamond

            self:CreateDiamondTip(totalDiamondValue, function ()
                PlayAudioByClickNormal()
                if ownDiamond < totalDiamondValue then
                    -- 幻晶石不足
                    if GAME_MODULE_OPEN.NEW_STORE then
                        app.uiMgr:showDiamonTips()
                    else
                        uiMgr:ShowInformationTips(__("幻晶石不足"))
                    end
                    return
                end

                -- 如果能装箱 则保存 packtag  self.packTags
                self.packTags[self.packTag] = self.packTag
                self.totalDiamondValue = totalDiamondValue
                self:SendSignal(POST.AIRSHIP_PACK.cmdName, {packId = packId})
            end)
        end

        -- self:GetFacade():DispatchObservers(POST.AIRSHIP_PACK.sglName)
    elseif tag == BTN_TAGS.ONE_KEY_PACK then
        local ownDiamond = CommonUtils.GetCacheProductNum(DIAMOND_ID)
        local canPackList, diamondPackList, consumeDiamondCount = self:initOnKeyPackingData()

        local isOwnPackList = next(canPackList) ~= nil
        local isOwnDiamondPackList = next(diamondPackList) ~= nil
        if not isOwnPackList and not isOwnDiamondPackList then
            uiMgr:ShowInformationTips(__('所有箱子已经完成装箱'))
            return
        end

        local surplusDiamond = ownDiamond - consumeDiamondCount

        -- 没有钻石列表 并且 拥有 可装箱的包裹
        if not isOwnDiamondPackList and isOwnPackList then
            self.needPackList = {canPackList = canPackList}
            self:SendSignal(POST.AIRSHIP_PACK.cmdName, {packId = -1})
        else
            self:CreateDiamondTip(consumeDiamondCount, function ()
                if surplusDiamond < 0 then
                    if GAME_MODULE_OPEN.NEW_STORE then
                        app.uiMgr:showDiamonTips()
                    else
                        uiMgr:ShowInformationTips(__("幻晶石不足"))
                    end
                    return
                end
                self.needPackList = {canPackList = canPackList, diamondPackList = diamondPackList, consumeDiamondCount = consumeDiamondCount}
                self:SendSignal(POST.AIRSHIP_PACK.cmdName, {packId = -1})
            end)
        end

        -- self:GetFacade():DispatchObservers(POST.AIRSHIP_PACK.sglName, {packId = -1})
        -- self:SendSignal(POST.AIRSHIP_PACK.cmdName, {packId = -1})
    end
end

function AirShipHomeMediator:OnOrderCellAction(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    local tag = sender:getTag()
    local data = checktable(self.airShipHomeData.pack[tag])
    local hasDone = data.hasDone == nil and 2 or data.hasDone

    if hasDone == 0 then
        local needNum = data.num
        local goodsId = data.goodsId
        local rewards = data.rewards
        if self.packTag == tag then return end

        -- todo  检查  进入 装载预告时  要 重置 self.packTag
        self.packTag = tag

        local packingViewData = self.viewData.packingViewData
        local packingLayer = packingViewData.packingLayer
        -- local touchView = self.viewData.airShipViewData.touchView
        local visible = packingLayer:isVisible()
        if not visible then

            -- packingLayer:setVisible(not visible)
            PlayAudioClip(AUDIOS.UI.ui_transport_cut.id)
            self:GetViewComponent():showUiAction(AIR_SHIP_ACTION_STATE.SHOW_PACKING)
        end

        local recipeNameLabel = packingViewData.recipeNameLabel
        local goodNode = packingViewData.goodNode
        local progressBar = packingViewData.progressBar
        local pickRewardLayer = packingViewData.pickRewardLayer
        local packBtn = packingViewData.packBtn

        local rewards = data.rewards
        local name = CommonUtils.GetConfig('goods', 'goods', goodsId).name
        display.commonLabelParams(recipeNameLabel,{text = tostring(name)})

        goodNode:RefreshSelf({goodsId = goodsId})

        self:updateProgressBar(goodsId, needNum)


        self:GetViewComponent():CreatePickReward(pickRewardLayer, rewards)

    elseif hasDone == 1 then
        uiMgr:ShowInformationTips(__("该订单已完成"))
    elseif hasDone == 2 then
        uiMgr:ShowInformationTips(__("空订单"))
    end

end

function AirShipHomeMediator:UpdateAccelerateText(richText, goodsId, consumeNum)
    display.reloadRichLabel(richText, {c = CreateRichTextStr(goodsId, consumeNum)})
    CommonUtils.AddRichLabelTraceEffect(richText)
end

function AirShipHomeMediator:CloseHandler()
    local packingLayer = self.viewData.packingViewData.packingLayer
    local touchView = self.viewData.airShipViewData.touchView
    self.packTag = -1
    -- print(packingLayer:getPositionX())
    -- packingLayer:setVisible(false)
    -- touchView:setVisible(false)
    PlayAudioByClickNormal()
    self:GetViewComponent():showUiAction(AIR_SHIP_ACTION_STATE.HIDE_PACKING)

end

function AirShipHomeMediator:CreateDiamondTip(totalDiamondValue, cb)
    -- 显示购买弹窗
    local descrRich = {
        {text = __('此项操作将会扣除您')},
        {text = tostring(totalDiamondValue), fontSize = fontWithColor('15').fontSize, color = '#ff0000'},
        {text = __('幻晶石!')},
    }
    local costInfo = {goodsId = DIAMOND_ID, num = totalDiamondValue}
    local commonTip = require('common.CommonTip').new({
        textRich = {
            {text = __('道具不足，花费幻晶石可装箱?')}
        },
        descrRich = descrRich,
        defaultRichPattern = true,
        costInfo = costInfo,
        callback = function ()
            if cb then
                cb()
            end
        end
    })

    commonTip:setPosition(display.center)
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(commonTip, 10)
end

getTimeArr = function (seconds)
    local hour   = math.floor(seconds / 3600)
    local minute = math.floor((seconds - hour * 3600) / 60)
    local sec    = (seconds - hour * 3600 - minute * 60)

    local tArr = {hour, minute, sec}

    local function timeFormat(t)
        return  math.floor(t / 10), t % 10
    end

    local timeArr = {}
    for i,v in ipairs(tArr) do
        local ten, bit = timeFormat(v)
        table.insert(timeArr, ten)
        table.insert(timeArr, bit)
    end
    -- local hourTen, hourBit = timeFormat(hour)
    -- local minuteTen, minuteBit = timeFormat(minute)
    -- local secTen, secBit = timeFormat(sec)

    return timeArr --{hourTen, hourBit, minuteTen, minuteBit, secTen, secBit}
end

CreateRichTextStr = function (goodsId, num)
    local t = {}
    if goodsId == DIAMOND_ID then
        table.insert(t, { img = _res('ui/home/lobby/cooking/refresh_ico_quick_recovery.png')})
    end
    table.insert(t, fontWithColor(14, {fontSize = 24, text = tostring(num)}))
    table.insert(t, {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.2})

    return t
end

function AirShipHomeMediator:OnRegist(  )
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")

    regPost(POST.AIRSHIP_HOME)
    regPost(POST.AIRSHIP_PACK)
    regPost(POST.AIRSHIP_LADE)
    regPost(POST.AIRSHIP_ACCELERATE_LADE)
    
end

function AirShipHomeMediator:OnUnRegist(  )
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")

    unregPost(POST.AIRSHIP_HOME)
    unregPost(POST.AIRSHIP_PACK)
    unregPost(POST.AIRSHIP_LADE)
    unregPost(POST.AIRSHIP_ACCELERATE_LADE)

    local scene = uiMgr:GetCurrentScene()
    scene:RemoveGameLayer(self.viewComponent)

    AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

return AirShipHomeMediator
