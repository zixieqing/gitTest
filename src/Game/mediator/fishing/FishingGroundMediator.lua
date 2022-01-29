--[[
    钓场Mediator
--]]
local Mediator = mvc.Mediator
---@class FishingGroundMediator:Mediator
local FishingGroundMediator = class("FishingGroundMediator", Mediator)

local NAME = "FishingGroundMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = shareFacade:GetManager("UIManager")
local gameMgr = shareFacade:GetManager("GameManager")
---@type FishingManager
local fishingMgr = AppFacade.GetInstance():GetManager("FishingManager")
local scheduler = require('cocos.framework.scheduler')
local fishConfigParser = require('Game.Datas.Parser.FishConfigParser')
local FISH_TAG = {
    ADD_BAIT = 1001,
    WISH     = 1002,
    INFO     = 1003,
    SHOP     = 1004,
    REWARDS  = 1005,
    FRIEND   = 1010,
}
local DATA_TYPE = {
    NONE    = 0,
    BUFF    = 1,
    CARD    = 2,
    BAIT    = 3,
    LEVEL   = 4,
    START_FISHING   = 5,
    MYFRIEND        = 6,
}

local RES_DICT          = {
    BTN_BOX_EMPTY       = _res('ui/home/fishing/fishing_main_ico_box_empty'),
    BTN_ADD_BAIT_EMPTY  = _res('ui/home/fishing/fishing_main_ico_bait_empty'),
    BTN_BOX_FULL        = _res('ui/home/fishing/fishing_main_ico_box_full'),
    BTN_ADD_BAIT_FULL   = _res('ui/home/fishing/fishing_main_ico_bait_full'),
}
local INFO_LAYER_TAG = 621
function FishingGroundMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.datas = params or {}
    self.isFirstLookFriend = true
    self.isRewards = false  -- 是否有奖励获取
    -- 初始化homeData 数据
    self:InitialData()
    if not self.inFriendGround then
        self.enterBySelf = true
    end
end

function FishingGroundMediator:InitialData(  )
    local data = self.datas
    fishingMgr:InitFishDatas(self.datas)
    self.groundLevel = checkint(data.level)
    self.friendGroundId = data.requestData.queryPlayerId
    self.inFriendGround = (tostring(self.friendGroundId) ~= tostring(gameMgr:GetUserInfo().playerId))
    self.friendFish = nil
    self.waittingForSync = {}
    self.startSync = false
    --dump(data, os.time())
    for k,v in pairs(data.fishCards) do
        if next(v) then
            if not v.maxVigour then
                v.maxVigour = (checkint(v.vigour) < 100) and 100 or v.vigour
            end
        end
    end
    local friendFish = data.friendFish
    if friendFish then
        if next(friendFish) and (not friendFish.maxVigour) then
            if tostring(friendFish.friendId) == tostring(gameMgr:GetUserInfo().playerId) then
                local cardData = gameMgr:GetCardDataByCardId(friendFish.cardId)
                friendFish.maxVigour = app.restaurantMgr:getCardVigourLimit(cardData.id)
            else
                friendFish.maxVigour = (checkint(friendFish.vigour) < 100) and 100 or friendFish.vigour
            end
        end
    end
end

function FishingGroundMediator:InterestSignals()
	local signals = {
        FISHERMAN_SWITCH_EVENT,
        FISHERMAN_CLICK_EVENT,
        FISHERMAN_VIGOUR_RECOVER_EVENT,
        FISHING_BAIT_APPEND_EVENT,
        FISHERMAN_SENT_TO_FRIEND_EVENT,
        FISHERMAN_SINGLE_FISHING_END_EVENT,
        FISH_FRIEND_ADD_CARD_EVENT,
        FISH_LEVEL_UP_EVENT,
        FISHERMAN_ALTER_IN_FRIEND_EVENT,
        FISHERMAN_SENT_TO_ICEROOM_EVENT,
        FISHING_GROUND_WEATHER_ALTER_EVENT,
        FISHING_BAIT_UNLOAD_EVENT,
        FISHERMAN_RECALL_EVENT,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        SGL.TAG_FRIEND_FISHERMAN_RECALL_EVENT,
        POST.FISHPLACE_HOME.sglName ,
        POST.FISHPLACE_LEVEL_UP.sglName ,
        POST.FISHPLACE_KICK_FRIEND_FISH_CARD.sglName ,
        POST.FISHPLACE_SET_FRIEND_FISH.sglName ,
        POST.FISHPLACE_SETFISHING_CARD.sglName ,
        POST.FISHPLACE_SYN_DATA.sglName ,
        POST.FISHPLACE_SETFISHING_BAIT.sglName ,
        POST.FISHPLACE_DRAW_FISHINGR_EWARDS.sglName,
        SIGNALNAMES.IcePlace_Home_Callback ,
        SIGNALNAMES.IcePlace_AddCard_Callback,
        FISH_FRIEND_CARD_UNLOAD_EVENT , 
        FISH_SYN_BAIT_NUM
    }
	return signals
end

function FishingGroundMediator:ProcessSignal( signal )
	local name = signal:GetName()
    local body = checktable(signal:GetBody())
    -- 点击钓位上的气泡 点击更换或遣返按钮
    if name == FISHERMAN_SWITCH_EVENT then
        while 0 == body.tag do
            -- 设置好友钓场钓手
            if self.inFriendGround then
                break
            end
            if not body.friendFish then
                uiMgr:ShowInformationTips(__('邀请好友前来垂钓吧'))
            -- 遣返
            else
                self:SendSignal(POST.FISHPLACE_KICK_FRIEND_FISH_CARD.cmdName,{})
            end
            return
        end
        local levelConfig = CommonUtils.GetConfig('fish', 'level', tostring(self.groundLevel))
        if body.tag > checkint(levelConfig.seatNum) then
            if not self.inFriendGround then
                local parseConfig = app.fishingMgr:GetConfigParse()
                local levelAllConfig = app.fishingMgr:GetConfigDataByName(parseConfig.TYPE.LEVEL)
                local minLevel  = nil 
                for k , v in pairs(levelAllConfig) do
                    if checkint(v.seatNum)  == body.tag then
                        if not  minLevel  then
                            minLevel = checkint(v.level)
                        else
                            minLevel = math.min(minLevel , checkint(v.level))
                        end
                    end
                end
                uiMgr:ShowInformationTips(string.format(__('需要钓场达到%d级解锁')   , checkint(levelAllConfig[tostring(minLevel)].level)  )  )
            end
            return
        end
        if 0 == body.tag or not self.inFriendGround then
            self:OpenChooseFishermanLayer(body)
        end
    -- 点击钓手
    elseif name == FISHERMAN_CLICK_EVENT then
        local friendFish = self.datas.friendFish or {}
        if 0 == body.tag and self.inFriendGround and not next(friendFish) then
            self:OpenChooseFishermanLayer(body)
        else
            local FishermanFeedMediator = require( 'Game.mediator.fishing.FishermanFeedMediator')
            table.merge(body, {operational = not self.inFriendGround, friendGroundId = self.friendGroundId })
            local delegate = FishermanFeedMediator.new(body)
            shareFacade:RegistMediator(delegate)
        end
    -- 飨灵喂食成功
    elseif name == FISHERMAN_VIGOUR_RECOVER_EVENT then
        local viewData = self.viewComponent.viewData
        local seat = viewData.seats[body.requestData.tag]
        seat:AddVigourEffect(body)
        self:UpdateHomeData({type = DATA_TYPE.NONE})
        if not self.startSync then
            self.startSync = true
            self:SendSignal(POST.FISHPLACE_SYN_DATA.cmdName)
        end
    -- 在好友钓场的好友钓位添加钓饵
    elseif name == FISHING_BAIT_APPEND_EVENT then
        local viewData = self.viewComponent.viewData
        local friendSeatNode = viewData.friendSeatNode
        self.friendFish = self.friendFish or {}
        table.merge(self.friendFish, body)
        friendSeatNode:RefreshNode({operational = self.inFriendGround, friendFish = self.friendFish})
    -- 派遣钓手到好友钓场
    elseif name == FISHERMAN_SENT_TO_FRIEND_EVENT then
        if not self.friendFish then
            uiMgr:ShowInformationTips(__('请选择钓手'))
        elseif not self.friendFish.cardId then
            uiMgr:ShowInformationTips(__('请选择钓手'))
        elseif not self.friendFish.baitId then
            uiMgr:ShowInformationTips(__('请选择钓饵'))
        else
            local totalSendNum = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PARAM_CONFIG , 'fish')[tostring(1)].dispatched
            local sentNum = table.nums(self.datas.myFriendFish or {})
            local leftNum = checkint(totalSendNum) - sentNum
            if 0 >= leftNum then
                uiMgr:ShowInformationTips(__('可派遣飨灵数已达到上限'))
            else
                local cardData = gameMgr:GetCardDataByCardId(self.friendFish.cardId)
                if 2 > checkint(cardData.vigour) then
                    uiMgr:ShowInformationTips(__('钓手新鲜度不足'))
                else
                    local scene = uiMgr:GetCurrentScene()
                    local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('是否确定派遣该飨灵至好友处垂钓。'),
                        isOnlyOK = false, callback = function ()
                            if self.friendFish then
                                local baitConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRODUCE_CONFIG , 'fish')
                                self:SendSignal(POST.FISHPLACE_SET_FRIEND_FISH.cmdName,{friendId = self.friendGroundId, fishCardId = cardData.id, baitId = self.friendFish.baitId, num = self.friendFish.baitNum})
                            end
                        end})
                    CommonTip:setPosition(display.center)
                    scene:AddDialog(CommonTip)
                end
            end
        end
    -- 钓手一次钓鱼结束
    elseif name == FISHERMAN_SINGLE_FISHING_END_EVENT then
        dump(body, os.time())
        local tag = body.tag
        if 0 == tag then
            self:UpdateHomeData({type = DATA_TYPE.START_FISHING, tag = 0, cardData = {friendFish = self.datas.friendFish, operational = self.inFriendGround}})
            return
        end
        if self.inFriendGround then
            return
        end
        if self.waittingForSync[checkint(tag)] then
            self.waittingForSync[checkint(tag)] = false
            if not self.startSync then
                self.startSync = true
                self:SendSignal(POST.FISHPLACE_SYN_DATA.cmdName)
            else
            end
        else
            self:UpdateHomeData({type = DATA_TYPE.START_FISHING, tag = checkint(tag), cardData = {card = self.datas.fishCards[tostring(tag)]}})
        end
    -- 好友钓场的钓手被遣返或者自然下场
    elseif name == FISHERMAN_ALTER_IN_FRIEND_EVENT then
        if checkint(body.friendId) == checkint(self.friendGroundId) then
            self:UpdateHomeData({type = DATA_TYPE.CARD, tag = 0, cardData = {operational = self.inFriendGround}})
        else
            self:UpdateHomeData({type = DATA_TYPE.NONE})
        end
    -- 把钓手送入冰场
    elseif name == FISHERMAN_SENT_TO_ICEROOM_EVENT then
        -- 先换下钓手
        self:SendSignal(POST.FISHPLACE_SETFISHING_CARD.cmdName, body)
    -- 钓场天气变化
    elseif name == FISHING_GROUND_WEATHER_ALTER_EVENT then
        self:UpdateHomeData({type = DATA_TYPE.BUFF, buff = self.datas.buff})
    -- 卸下钓饵
    elseif name == FISHING_BAIT_UNLOAD_EVENT then
        self:UpdateHomeData({type = DATA_TYPE.BAIT, bait = body.bait})
    -- 召回派遣到好友钓场的钓手
    elseif name == FISHERMAN_RECALL_EVENT then
        fishingMgr:UnloadFriendFishCardsData({playerCardId = body.playerCardId, vigour = body.vigour, playerId = gameMgr:GetUserInfo().playerId})
        CommonUtils.DrawRewards({ {goodsId = body.baitId , num = body.baitNum } })
        self:UpdateHomeData({type = DATA_TYPE.MYFRIEND, myfriend = {playerId = body.requestData.friendId}})
    -- 一次钓鱼结束后同步数据
    elseif name == POST.FISHPLACE_SYN_DATA.sglName then
        dump(body, os.time())
        self.startSync = false
        local viewData = self.viewComponent.viewData
        for k,v in pairs(body.fishCards) do
            if not v.baitId or checkint(v.leftSeconds) < 0 then
                v.baitId = nil
                v.leftSeconds = nil
                viewData.seats[checkint(k)]:ShowCountDown('')
            end
            if v.vigour then
                if v.cardId then
                    gameMgr:UpdateCardDataByCardId(v.cardId ,{vigour = v.vigour})
                elseif v.playerCardId then
                    gameMgr:UpdateCardDataById(v.playerCardId ,{vigour = v.vigour})
                end
            end
            if self.waittingForSync[checkint(k)] then
                self.waittingForSync[checkint(k)] = false
                self.datas.fishCards[tostring(k)] = v
            else
                self:UpdateHomeData({type = DATA_TYPE.START_FISHING, tag = checkint(k), cardData = {card = v}})
            end
        end
        self:UpdateHomeData({type = DATA_TYPE.BAIT, bait = body.fishBaits})
        if CommonUtils.JuageMySelfOperation(checkint(self.friendGroundId) )then
            app:DispatchObservers(FISH_SYN_BAIT_NUM , body)
        end
    -- 好友召回钓手
    elseif name == SGL.TAG_FRIEND_FISHERMAN_RECALL_EVENT then
        if not self.inFriendGround then
            self:UpdateHomeData({type = DATA_TYPE.CARD, tag = 0, cardData = {operational = self.inFriendGround}})
        end
    -- home数据
    elseif name == POST.FISHPLACE_HOME.sglName then
        self.datas = body or {}
        self:InitialData()
        self:RefreshScene()
    -- 钓场升级成功
    elseif name == FISH_LEVEL_UP_EVENT then
        local nextLevel = body.level
        local levelConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.LEVEL, 'fish')
        local preSeatNum = checkint(levelConfig[tostring(self.groundLevel)].seatNum)
        local newSeatNum = checkint(levelConfig[tostring(nextLevel)].seatNum)
        if newSeatNum > preSeatNum then
            for i=preSeatNum+1,newSeatNum do
                self:UpdateHomeData({type = DATA_TYPE.CARD, tag = i})
            end
        end
        self:UpdateHomeData({type = DATA_TYPE.LEVEL, level = nextLevel})
        gameMgr:UpdatePlayer({fishPlaceLevel = nextLevel})

        --local moneyNods = self.viewComponent.viewData.moneyNods
        --moneyNods[tostring(FISH_POPULARITY_ID)]:updataUi(FISH_POPULARITY_ID)
    -- 成功遣返好友钓手 
    elseif name == POST.FISHPLACE_KICK_FRIEND_FISH_CARD.sglName then
        self:UpdateHomeData({type = DATA_TYPE.CARD, tag = 0})
    -- 在好友钓场设置钓手成功
    elseif name == POST.FISHPLACE_SET_FRIEND_FISH.sglName then
        -- 扣除道具数量
        CommonUtils.DrawRewards({{goodsId = body.requestData.baitId, num = 0 - checkint(body.requestData.num)}})
        -- 更新数据
        self.friendFish = self.friendFish or {}
        self.friendFish.friendId = gameMgr:GetUserInfo().playerId
        self.friendFish.baitNum = checkint(self.friendFish.baitNum) - 1
        self.friendFish.vigour = checkint(self.friendFish.vigour) - 2
        self.friendFish.playerCardId = body.requestData.fishCardId
        local buff = self.datas.buff or {}
        self.friendFish.leftSeconds = fishingMgr:GetBaitConumeTimeAndVigour(self.friendFish.baitId, 1, buff.buffId, buff.leftSeconds)
        app.fishingMgr:AddMyFriendFishCardData(
                clone(self.friendFish) ,self.friendGroundId
        )
        gameMgr:UpdateCardDataByCardId(self.friendFish.cardId ,{vigour = self.friendFish.vigour})
        self.datas.myFriendFish[tostring(self.friendGroundId)] = nil
        self:UpdateHomeData({type = DATA_TYPE.MYFRIEND, myfriend = self.friendFish})
        self:UpdateHomeData({type = DATA_TYPE.START_FISHING, tag = 0, cardData = {friendFish = self.friendFish}})
        gameMgr:SetCardPlace({},{{id = body.requestData.fishCardId }} ,CARDPLACE.PLACE_FISH_PLACE)
        self.friendFish = nil
    -- 设置钓手
    elseif name == POST.FISHPLACE_SETFISHING_CARD.sglName then
        local id = body.requestData.fishCardId
        local fishPlaceId = checkint(body.requestData.fishPlaceId)
        app.fishingMgr:SetFishCardPlace(id , fishPlaceId)
        self:UpdateHomeData({type = DATA_TYPE.CARD, tag = fishPlaceId, cardData = {card = {playerCardId = id}}})
        if body.requestData.icePlaceId then
            -- 把钓手送入冰场
            shareFacade:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, body.requestData,'home')
            return
        end
        local fisherman = self.datas.fishCards[tostring(fishPlaceId)] or {}
        local fishBaits = self.datas.fishBaits or {}
        if next(fishBaits) and next(fisherman) then
            if not self.startSync then
                self.startSync = true
                self:SendSignal(POST.FISHPLACE_SYN_DATA.cmdName)
            end
        end
    -- 设置钓饵
    elseif name == POST.FISHPLACE_SETFISHING_BAIT.sglName then
        if not self.startSync then
            self.startSync = true
            self:SendSignal(POST.FISHPLACE_SYN_DATA.cmdName)
        end
    -- 领取钓鱼奖励
    elseif name == POST.FISHPLACE_DRAW_FISHINGR_EWARDS.sglName then
        self:SetBoxFull(false)
        uiMgr:AddDialog('common.RewardPopup', body)
    -- 好友在好友钓位设置钓手
    elseif name == FISH_FRIEND_ADD_CARD_EVENT then
        if not self.inFriendGround then
            self:UpdateHomeData({type = DATA_TYPE.START_FISHING, tag = 0, cardData = {friendFish = self.datas.friendFish}})
        end
    -- 冰场添加飨灵成功
    elseif name == SIGNALNAMES.IcePlace_Home_Callback then
        local body = checktable(signal:GetBody())
        local icePlace = body.icePlace
        local countNum =  table.nums(icePlace)
        local restaurantMgr =  app.restaurantMgr
        local isHave = false
        for icePlaceId = 1 , countNum  do
            local icePlaceBed = icePlace[tostring(icePlaceId)].icePlaceBed or {}
            local icePlaceBedNum = checkint( icePlace[tostring(icePlaceId)].icePlaceBedNum)
            body.requestData.icePlaceId = icePlaceId
            if icePlaceBedNum > table.nums(icePlaceBed)  then
                shareFacade:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE,body.requestData ,'addCard')
                isHave = true
            else
                for id , vigourData in pairs(icePlaceBed) do
                    local maxVigour = restaurantMgr:getCardVigourLimit(id)
                    if checkint(maxVigour) <=  checkint(vigourData.newVigour) then
                        shareFacade:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, body.requestData,'addCard')
                        isHave = true
                        break
                    end
                end
            end
            if isHave then
                break
            end
        end
    elseif name == SIGNALNAMES.IcePlace_AddCard_Callback then
        if not signal:GetBody().errcode then
            gameMgr:SetCardPlace({}, {{id = body.requestData.playerCardId}}, CARDPLACE.PLACE_ICE_ROOM)
            if checktable(signal:GetBody().oldPlayerCard).playerCardId then
                local oldCardId = checkint(signal:GetBody().oldPlayerCard.playerCardId)
                local ovigour = checkint(signal:GetBody().oldPlayerCard.vigour)
                gameMgr:UpdateCardDataById(oldCardId, {vigour = ovigour})
                gameMgr:DelCardOnePlace( oldCardId ,CARDPLACE.PLACE_ICE_ROOM)
            end
            uiMgr:ShowInformationTips(__('添加成功'))
        end
    -- 更新道具数量
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        local moneyNods = self.viewComponent.viewData.moneyNods
        for i, goodPurchaseNode in pairs(moneyNods) do
            goodPurchaseNode:updataUi(checkint(i))
        end
    elseif FISH_FRIEND_CARD_UNLOAD_EVENT == name  then
        for k,v in pairs(self.datas.myFriendFish or {}) do
            if checkint(v.playerCardId) == checkint(body.playerCardId) then
                body.playerId = k
                break
            end
        end
        self.datas.myFriendFish[tostring(body.playerId)] = body
        self:UpdateHomeData({type = DATA_TYPE.MYFRIEND, myfriend = body})
        self:GetViewComponent():RefreshCountTime()
    end
end

function FishingGroundMediator:Initial( key )
	self.super.Initial(self,key)
    ---@type FishingGroundView
    local viewComponent = uiMgr:SwitchToTargetScene('Game.views.fishing.FishingGroundView')
    self:SetViewComponent(viewComponent)

    local viewData = viewComponent.viewData
    display.commonUIParams(viewData.rewardButton , {cb = handler(self, self.ButtonActions)})
    for k,v in pairs(viewData.actionButtons) do
        display.commonUIParams(v  , {cb = handler(self, self.ButtonActions)})
    end
    viewData.friendBtn:setOnClickScriptHandler(handler(self, self.ButtonActions))
    viewData.detailView:setOnClickScriptHandler(handler(self, self.OpenInfoLayer))
    viewData.detailButton:setOnClickScriptHandler(handler(self, self.OpenInfoLayer))
    viewData.friendWeatherBtn:setOnClickScriptHandler(function ( sender )
        uiMgr:ShowInformationTipsBoard({targetNode = sender, buff = self.datas.buff, type = 14})
    end)
    self:RefreshScene()
    if viewData.chatBtn then
        viewData.chatBtn:delayInit()
    end
end
--[[
刷新钓场所有界面
--]]
function FishingGroundMediator:RefreshScene(  )
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    viewData.friendTopView:setVisible(self.inFriendGround)
    viewData.friendBottomView:setVisible(self.inFriendGround)
    viewData.topView:setVisible(not self.inFriendGround)
    viewData.bottomView:setVisible(not self.inFriendGround)
    local fishRewards = self.datas.fishRewards or {}
    self:SetBoxFull(next(fishRewards) and true)
    local fishBaits = self.datas.fishBaits or {}
    if not self.inFriendGround then
        viewData.actionButtons[1]:getChildByTag(FISH_TAG.ADD_BAIT):setTexture(next(fishBaits) and RES_DICT.BTN_ADD_BAIT_FULL or RES_DICT.BTN_ADD_BAIT_EMPTY)
    end
    if self.rewards and self.inFriendGround then
        for k,v in pairs(self.rewards) do
            for _,v2 in pairs(v) do
                v2:removeFromParent()
            end
            self.rewards[k] = {}
        end
    end
    local card = self.datas.fishCards
    local friendFish = self.inFriendGround and (self.datas.friendFish or {}) or self.datas.friendFish
    self.preTime = os.time()
    if not self.inFriendGround then
        for k,v in pairs(card) do
            if v.vigour then
                if v.cardId then
                    gameMgr:UpdateCardDataByCardId(v.cardId ,{vigour = v.vigour})
                elseif v.playerCardId then
                    gameMgr:UpdateCardDataById(v.playerCardId ,{vigour = v.vigour})
                end
            end
            -- 钓鱼结束
            if not v.baitId or checkint(v.leftSeconds) <= 0 then
                v.baitId = nil
                v.leftSeconds = nil
                viewData.seats[checkint(k)]:ShowCountDown('')
            else
                viewData.seats[checkint(k)]:ShowCountDown(v.leftSeconds)
            end
        end
        if friendFish then
            if next(friendFish) then
                -- 钓鱼结束
                if checkint(friendFish.leftSeconds) <= 0 then
                    self.datas.friendFish = nil
                    friendFish = nil
                    viewData.friendSeatNode:ShowCountDown('')
                else
                    viewData.friendSeatNode:ShowCountDown(friendFish.leftSeconds)
                end
            end
        end
    end
    viewData.friendSeatNode:SetHomeData(self.datas)
    viewData.friendSeatNode:RefreshNode({friendFish = friendFish, operational = self.inFriendGround})
    local levelConfig = CommonUtils.GetConfig('fish', fishConfigParser.TYPE.LEVEL, tostring(self.groundLevel))
    for i,v in ipairs(viewData.seats) do
        v:SetHomeData(self.datas)
        v:RefreshNode({card = card[tostring(i)], isLock = i > checkint(levelConfig.seatNum), inFriendGround = self.inFriendGround})
        if self.inFriendGround then
            v.fishingEndAni = false
        end
    end
    self:UpdateHomeData({type = DATA_TYPE.NONE})

    local function SafeStopScheduler( ... )
        if self.GtimeUpdateFunc then
            scheduler.unscheduleGlobal(self.GtimeUpdateFunc)
            self.GtimeUpdateFunc = nil
        end
    end
    SafeStopScheduler()
    local getX, getY = viewData.rewardButton:getPosition()
    local baitConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRODUCE_CONFIG , 'fish')
    self.GtimeUpdateFunc = scheduler.scheduleGlobal(function(dt)
        local curTime = os.time()
        -- 玩家改时间或长时间切换到后台 重新拉home数据
        if curTime < self.preTime or curTime > (self.preTime + 2 * dt) then
            SafeStopScheduler()
            self:SendSignal(POST.FISHPLACE_HOME.cmdName,{queryPlayerId = self.friendGroundId})
        else
            self.preTime = curTime
            if not self.inFriendGround then
                for k,v in pairs(card) do
                    local baitId = v.baitId
                    if baitId then
                        if checkint(v.leftSeconds) > 0 then
                            v.leftSeconds = v.leftSeconds - 1
                            viewData.seats[checkint(k)]:ShowCountDown(v.leftSeconds)
                        else
                            local seat = viewData.seats[checkint(k)]
                            if not seat.fishingEndAni then
                                self.waittingForSync[checkint(k)] = true
                                seat:SingleFishingEnd(function (  )
                                    if not self.inFriendGround then
                                        local x,y = seat:getPosition()
                                        self:PlayRewardAnimation(fishingMgr:GetOutput(baitId), cc.p(x, y), cc.p(getX, getY), function (  )
                                            -- todo
                                            shareFacade:DispatchObservers(FISHERMAN_SINGLE_FISHING_END_EVENT, {tag = k})
                                        end, k)
                                    end
                                end)
                            end
                        end
                    -- else
                    --     if next(self.datas.fishBaits or {}) and next(self.datas.fishCards[tostring(k)] or {}) then
                    --         local card = self.datas.fishCards[tostring(k)]
                    --         local cardData
                    --         if card.cardId then
                    --             cardData = gameMgr:GetCardDataByCardId(card.cardId)
                    --         elseif card.playerCardId then
                    --             cardData = gameMgr:GetCardDataById(card.playerCardId)
                    --         end
                    --         if cardData then
                    --             if 2 <= checkint(cardData.vigour) then
                    --                 shareFacade:DispatchObservers(FISHERMAN_SINGLE_FISHING_END_EVENT, {tag = k})
                    --             end
                    --         end
                    --     end
                    end
                end
            end
            local friendFish = self.datas.friendFish or {}
            if next(friendFish) then
                if checkint(friendFish.leftSeconds) > 0 then
                    friendFish.leftSeconds = friendFish.leftSeconds - 1
                    viewData.friendSeatNode:ShowCountDown(friendFish.leftSeconds)
                else
                    local bait = friendFish.baitId
                    if friendFish.baitNum > 0 and 2 <= friendFish.vigour then
                        friendFish.baitNum = friendFish.baitNum - 1
                        local buff = self.datas.buff or {}
                        friendFish.leftSeconds = fishingMgr:GetBaitConumeTimeAndVigour(friendFish.baitId, 1, buff.buffId, buff.leftSeconds)
                        if not friendFish.maxVigour then
                            friendFish.maxVigour = (checkint(friendFish.vigour) < 100) and 100 or friendFish.vigour
                        end
                        friendFish.vigour = friendFish.vigour - 2
                    else
                        self.datas.friendFish = nil
                        friendFish = nil
                    end
                    viewData.friendSeatNode:FriendSingleFishingEnd(function ( ... )
                        if self.inFriendGround then
                            if not friendFish then
                                SafeStopScheduler()
                                self:SendSignal(POST.FISHPLACE_HOME.cmdName,{queryPlayerId = self.friendGroundId})
                            else
                                shareFacade:DispatchObservers(FISHERMAN_SINGLE_FISHING_END_EVENT, {tag = 0})
                            end
                        else
                            local x,y = viewData.friendSeatNode:getPosition()
                            self:PlayRewardAnimation(fishingMgr:GetOutput(bait), cc.p(x, y), cc.p(getX, getY), function (  )
                                -- todo
                                shareFacade:DispatchObservers(FISHERMAN_SINGLE_FISHING_END_EVENT, {tag = 0})
                            end, 0)
                        end
                    end, friendFish)
                end
            end
            local buff = self.datas.buff or {}
            if next(buff) then
                buff.leftSeconds = buff.leftSeconds - 1
                if checkint(buff.leftSeconds) <= 0 then
                    buff = nil
                end
                self:UpdateHomeData({type = DATA_TYPE.BUFF, buff = buff})
            end
        end
    end,1.0)
end
function FishingGroundMediator:PlayRewardAnimation( output, initPos, endPos, cb, tag )
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local rewardButton = viewData.rewardButton
    local posTab = {
        cc.p(0,60),
        cc.p(-20,30),
        cc.p(25,30),
        cc.p(-30,-30),
        cc.p(30,-30),
        cc.p(math.random(10),math.random(90)),
        cc.p(math.random(30),math.random(70)),
        cc.p(math.random(50),math.random(50)),
        cc.p(math.random(70),math.random(30)),
        cc.p(math.random(90),math.random(10))
    }
    local scene = uiMgr:GetCurrentScene()
    if not self.rewards then
        self.rewards = {}
    end
    if not self.rewards[tostring(tag)] then
        self.rewards[tostring(tag)] = {}
    end
    for i=1,table.nums(posTab) do
        local iconPath = CommonUtils.GetGoodsIconPathById(output)
        local img= display.newImageView(_res(iconPath),0,0,{as = false})
        img:setPosition(initPos)
        img:setTag(555)
        viewComponent:addChild(img,10)
        table.insert( self.rewards[tostring(tag)], img )

        local scale = 0.4
        img:setScale(0)
        local actionSeq = cc.Sequence:create(
            cc.Spawn:create(
                cc.ScaleTo:create(0.2, scale),
                cc.MoveBy:create(0.3,posTab[i])
                ),
            cc.MoveBy:create(0.1+i*0.11,cc.p(math.random(15),math.random(15))),
            cc.DelayTime:create(i*0.01),
            cc.Spawn:create(
                cc.MoveTo:create(0.4, endPos),
                cc.ScaleTo:create(0.4, 0.2)
                ),
            cc.CallFunc:create(function ()
                self.rewards[tostring(tag)][i] = nil
                if i == table.nums(posTab) then
                    if cb then
                        cb()
                    end
                elseif 1 == i then
                    self:SetBoxFull(true)
                    rewardButton:runAction(cc.Sequence:create(
                        cc.ScaleTo:create(0.1, 1.4),
                        cc.ScaleTo:create(0.1, 1)
                    ))
                end
            end),
            cc.RemoveSelf:create())
        img:runAction(actionSeq)
    end
end
--[[
打开钓场概况界面
--]]
function FishingGroundMediator:OpenInfoLayer( sender )
    PlayAudioByClickNormal()
    local FishingGroundInfoLayer = require('Game.views.fishing.FishingGroundInfoLayer')
    local infoLayer = FishingGroundInfoLayer.new()
    infoLayer:setTag(INFO_LAYER_TAG)
    display.commonUIParams(infoLayer, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx, 0)})
    self:GetViewComponent():addChild(infoLayer, 66)
    infoLayer:RefreshLayer(self.datas)
end

function FishingGroundMediator:ButtonActions(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == FISH_TAG.ADD_BAIT then
        if not  app.fishingMgr:GetHomeDataByKey('isFishLimit') then
            local mediator = require("Game.mediator.fishing.FishingAddBaitMediator").new()
            self:GetFacade():RegistMediator(mediator)
        else
            app.uiMgr:ShowInformationTips(__('已达到钓场收获上限，请先收取钓场奖励'))
        end
    elseif tag == FISH_TAG.WISH then
        local mediator = require("Game.mediator.fishing.FishWishMediator").new(self.datas)
        self:GetFacade():RegistMediator(mediator)
    elseif tag == FISH_TAG.INFO then
        local mediator = require("Game.mediator.fishing.FishingInformationMediator").new()
        self:GetFacade():RegistMediator(mediator)
    elseif tag == FISH_TAG.SHOP then
        local mediator = require("Game.mediator.fishing.FishingShopMeditor").new()
        self:GetFacade():RegistMediator(mediator)
    elseif tag == FISH_TAG.REWARDS then
        if self.isRewards then
            local mediator = require("Game.mediator.fishing.FishingRewardMediator").new()
            self:GetFacade():RegistMediator(mediator)
        else
            app.uiMgr:ShowInformationTips(__('无可领取收获'))
        end
    elseif tag == FISH_TAG.FRIEND then
        local mediator = self:GetFacade():RetrieveMediator('LobbyFriendMediator')
        if mediator then
            mediator:GetViewComponent():setVisible(true)
            return
        end
        local mediator = require("Game.mediator.LobbyFriendMediator").new({isFirstLookFriend = self.isFirstLookFriend ,visitType = 2 })
        self:GetFacade():RegistMediator(mediator)
        self.isFirstLookFriend = false
    end
end

--[[
打开选择钓手界面
@params params table {
    tag int 钓位序号
}
--]]
function FishingGroundMediator:OpenChooseFishermanLayer( body )
    local ChooseLobbyPeopleMediator = require( 'Game.mediator.ChooseLobbyPeopleMediator' )
    local params = {chooseType = 4, callback = function ( cardData )
        local viewData = self.viewComponent.viewData
        local seat = 0 == body.tag and viewData.friendSeatNode or viewData.seats[body.tag]
        if 0 == body.tag then
            if not self.friendFish then
                self.friendFish = {}
            end
            -- 换下
            if self.friendFish.cardId == cardData.cardId then
                self.friendFish.cardId = nil
                self.friendFish.skinId = nil
                self.friendFish.name = nil
                self.friendFish.vigour = nil
                self.friendFish.cardName = nil
                self.friendFish.maxVigour = nil
            else
                table.merge(self.friendFish, {
                    cardId = cardData.cardId, 
                    skinId = cardData.defaultSkinId, 
                    name = gameMgr:GetUserInfo().playerName, 
                    vigour = cardData.vigour,
                    cardName = cardData.cardName,
                    maxVigour = app.restaurantMgr:getCardVigourLimit(cardData.id),
                })
            end
            cardData = {operational = self.inFriendGround, friendFish = self.friendFish}
            local viewData = self.viewComponent.viewData
            viewData.friendSeatNode:RefreshNode(cardData)
            shareFacade:UnRegsitMediator("ChooseLobbyPeopleMediator")
            return 
        end
        -- 卸下
        if body.card then
            if checkint(cardData.id) == checkint(body.card.playerCardId) then
                self:SendSignal(POST.FISHPLACE_SETFISHING_CARD.cmdName,{fishPlaceId = body.tag})
                shareFacade:UnRegsitMediator("ChooseLobbyPeopleMediator")
                return
            end
        end
        self:SendSignal(POST.FISHPLACE_SETFISHING_CARD.cmdName,{fishPlaceId = body.tag, fishCardId = cardData.id})
        shareFacade:UnRegsitMediator("ChooseLobbyPeopleMediator")
    end}
    table.merge(params, body)
    local mediator = ChooseLobbyPeopleMediator.new(params)
    shareFacade:RegistMediator(mediator)
end

--[[
更新钓场数据
如果有变动更新界面
@params params table {
    type enum DATA_TYPE 更新数据类型
    buff table 天气
    tag int 钓位序号
    cardData table 钓手信息
    bait table 钓饵信息
}
--]]
function FishingGroundMediator:UpdateHomeData( ... )
    local args = unpack({...}) or {}
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    if DATA_TYPE.BUFF == args.type then
        self.datas.buff = args.buff
    end
    if DATA_TYPE.CARD == args.type or DATA_TYPE.START_FISHING == args.type then
        if args.tag then
            local seat = (0 == args.tag) and viewData.friendSeatNode or viewData.seats[args.tag]
            if DATA_TYPE.START_FISHING == args.type then
                table.merge(args.cardData, {start = true})
            end
            if 0 == args.tag then
                if not args.cardData then
                    self.datas.friendFish = nil
                else
                    self.datas.friendFish = args.cardData.friendFish
                end
            else
                if not args.cardData then
                    self.datas.fishCards[tostring(args.tag)] = nil
                else
                    self.datas.fishCards[tostring(args.tag)] = args.cardData.card
                end
            end
            seat:RefreshNode(args.cardData)
        end
    end
    if DATA_TYPE.BAIT == args.type then
        self.datas.fishBaits = args.bait or {}
        if not self.inFriendGround then
            viewData.actionButtons[1]:getChildByTag(FISH_TAG.ADD_BAIT):setTexture(next(self.datas.fishBaits) and RES_DICT.BTN_ADD_BAIT_FULL or RES_DICT.BTN_ADD_BAIT_EMPTY)
        end
    end
    if DATA_TYPE.LEVEL == args.type then
        self.datas.level = args.level
        self.groundLevel = args.level
    end
    if DATA_TYPE.MYFRIEND == args.type then
        local playerId = args.myfriend.playerId or self.friendGroundId
        if not next(self.datas.myFriendFish[tostring(playerId)] or {}) then
            self.datas.myFriendFish[tostring(playerId)] = args.myfriend
        else
            self.datas.myFriendFish[tostring(playerId)] = nil
        end
    end
    -- 更新所有钓手状态
    if DATA_TYPE.NONE == args.type and not self.inFriendGround then

    end

    if args.type then
        if not self.inFriendGround then 
            viewComponent:RefreshInfoBar(self.datas, args.type) 
        else
            viewComponent:RefreshFriendView(self.datas, args.type, self.friendGroundId)
        end
        local infoLayer = viewComponent:getChildByTag(INFO_LAYER_TAG)
        if infoLayer then
            infoLayer:RefreshLayer(self.datas)
        end

        local curNode = uiMgr:GetCurrentScene():GetDialogByTag(23456)
        if curNode then
            if 14 == curNode.type then
                uiMgr:ShowInformationTipsBoard({targetNode = viewData.friendWeatherBtn, buff = self.datas.buff, type = 14})
            end
        end
    end
    if DATA_TYPE.CARD == args.type or DATA_TYPE.START_FISHING == args.type or DATA_TYPE.NONE == args.type then
        local feedview = shareFacade:RetrieveMediator('FishermanFeedMediator')
        if feedview then
            local tag = feedview.data.tag
            if 0 ~= tag then
                local card = self.datas.fishCards[tostring(tag)]
                if card then
                    if next(card) then
                        if not card.vigour then
                            card.vigour = gameMgr:GetCardDataById(card.playerCardId).vigour
                        end
                        feedview:GetViewComponent():UpdateVigour(card.playerCardId, card.vigour)
                    end
                end
            else
                if not self.datas.friendFish then
                    shareFacade:UnRegsitMediator('FishermanFeedMediator')
                end
            end
        end
    end
end

function FishingGroundMediator:SetBoxFull( isFull )
    local rewardButton = self:GetViewComponent().viewData.rewardButton
    if isFull then
        rewardButton:setNormalImage(RES_DICT.BTN_BOX_FULL)
        rewardButton:setSelectedImage(RES_DICT.BTN_BOX_FULL)
    else
        rewardButton:setNormalImage(RES_DICT.BTN_BOX_EMPTY)
        rewardButton:setSelectedImage(RES_DICT.BTN_BOX_EMPTY)
    end
    self.isRewards = isFull
end

function FishingGroundMediator:BackAction(  )
    if self.inFriendGround and self.enterBySelf then
        self:SendSignal(POST.FISHPLACE_HOME.cmdName,{queryPlayerId = gameMgr:GetUserInfo().playerId})
    else
        --shareFacade:BackMediator()
        AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = 'HomelandMediator'}, {name = 'HomelandMediator', params = {playerId =self.friendGroundId}})
    end
end

function FishingGroundMediator:OnRegist(  )
	PlayBGMusic(AUDIOS.BGM2.Food_Fishing.id)
    regPost(POST.FISHPLACE_HOME)
    regPost(POST.FISHPLACE_KICK_FRIEND_FISH_CARD)
    regPost(POST.FISHPLACE_SET_FRIEND_FISH)
    regPost(POST.FISHPLACE_SETFISHING_CARD)
    regPost(POST.FISHPLACE_SYN_DATA)
	local IceRoomCommand = require( 'Game.command.IceRoomCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_ICEPLACE, IceRoomCommand)
    local canUpgrade = app.fishingMgr:CheckFishUpgradeLevel()
    if canUpgrade then
        app.dataMgr:AddRedDotNofication( tostring(RemindTag.BTN_FISH_UPGRADE) , tostring(RemindTag.BTN_FISH_UPGRADE))
    else
        app.dataMgr:ClearRedDotNofication( tostring(RemindTag.BTN_FISH_UPGRADE) , tostring(RemindTag.BTN_FISH_UPGRADE))
    end
    app:DispatchObservers(COUNT_DOWN_ACTION , { tag = RemindTag.BTN_FISH_UPGRADE , countdown = 0 })
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
end

function FishingGroundMediator:OnUnRegist(  )
	PlayBGMusic()
    if self.GtimeUpdateFunc then
		scheduler.unscheduleGlobal(self.GtimeUpdateFunc)
        self.GtimeUpdateFunc = nil
    end
	unregPost(POST.FISHPLACE_HOME)
	unregPost(POST.FISHPLACE_KICK_FRIEND_FISH_CARD)
	unregPost(POST.FISHPLACE_SET_FRIEND_FISH)
	unregPost(POST.FISHPLACE_SETFISHING_CARD)
	unregPost(POST.FISHPLACE_SYN_DATA)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_ICEPLACE)
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
end

return FishingGroundMediator
