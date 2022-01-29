local Mediator = mvc.Mediator

local IceRoomMediator = class("IceRoomMediator", Mediator)

local NAME = "IceRoomMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")

local IceRoomHeroCell = require("Game.views.IceRoomHeroCell")

local PAGE_SIZE = 6
local ICE_PLACE_MAX_CARD = 8
local function filterDatas( datas, excludes)
    local rets = {}
    if excludes then
        table.each(excludes,function(k,v)
            datas[tostring(v)] = nil
        end)
    end

    for idx,val in pairs(datas) do
        local vigour = checkint(val.vigour)
        local maxVigour = app.restaurantMgr:getCardVigourLimit(val.id)
        local ratio = (vigour / maxVigour) * 100
        val.ratio = ratio
        table.insert(rets, val)
    end

    table.sort(rets, function(a, b)
        return a.ratio < b.ratio
    end)

    for i, v in pairs(rets) do
        v.ratio = nil
    end
    return rets
end

local function CreateItemView()
    local size = cc.size(78,78)
    local view = CLayout:create(size)
    local bgImage = display.newButton(0,0, {
        n = _res("ui/iceroom/refresh_main_role_mask.png"),scale9 = true, size = size
    })
    display.commonUIParams(bgImage, {po = cc.p(size.width * 0.5, size.height * 0.5)})
    view:addChild(bgImage)
    --roleheader
    local headerNode = require("common.HeaderNode").new({id = 200013})
    display.commonUIParams(headerNode, {po = cc.p(size.width * 0.5, size.height * 0.5)})
    headerNode:setScale(0.7)
    view:addChild(headerNode,1)
    headerNode:setVisible(false)

    local checkedFlag = display.newSprite("ui/iceroom/refresh_mian_ico_correct.png") display.commonUIParams(checkedFlag, {ap = display.CENTER_BOTTOM, po = cc.p(size.width * 0.84,0)})
    view:addChild(checkedFlag,2)
    checkedFlag:setVisible(false)
    local lockSprite = display.newSprite("ui/common/common_ico_lock.png")
    display.commonUIParams(lockSprite, {po = cc.p(size.width * 0.5 ,size.height * 0.5)})
    view:addChild(lockSprite,3)
    lockSprite:setVisible(false)

    return {
        view        = view,
        bgbutton    = bgImage,
        headerNode  = headerNode,
        checkedFlag = checkedFlag,
        lockSprite  = lockSprite
    }
end

--[[
-- create hero list views
--]]
local function CreateCardsView()
    local contentView = CLayout:create(display.size)
    display.commonUIParams(contentView, {po = display.center})
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    contentView:addChild(eaterLayer, -1)

    local size = cc.size(display.width, 306)
    local view = CLayout:create(size)
    display.commonUIParams(view, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx,0)})
    contentView:addChild(view) --add views
    local touchImage = display.newImageView(_res('ui/common/story_tranparent_bg'),display.cx,153, {enable = true, scale9 = true, size = size})
    view:addChild(touchImage)


    local topSize = cc.size(1334, 114)
    local topView = CLayout:create(topSize)
    topView:setBackgroundImage(_res("ui/iceroom/refresh_main_bg_up"))
    display.commonUIParams(topView, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx ,display.height - topSize.height)})
    contentView:addChild(topView, 3) --添加上面一条的功能
    local touchTrans = display.newImageView(_res('ui/common/story_tranparent_bg'),topSize.width * 0.5,topSize.height * 0.5, {enable = true, scale9 = true, size = topSize})
    topView:addChild(touchTrans,1)

    local rolesItems = {}
    for i=1 , 8 do
        local x = (i -1 ) * 90 + 342
        local itemData = CreateItemView()
        display.commonUIParams(itemData.view,{po = cc.p(x + 10, 68)})
        topView:addChild(itemData.view,2)
        itemData.bgbutton:setTag(i) --位置信息
        itemData.bgbutton:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
            local id = sender:getUserTag()
            AppFacade.GetInstance():DispatchObservers("UNLOAD_ITEMS", {single = true, id = id})
        end)
        table.insert(rolesItems, itemData)
    end
    local unloadAllButton = display.newButton(1180 , topSize.height - 10, {
        n = _res("ui/common/common_btn_orange"), scale9 = true, size = cc.size(124, 62)})
    display.commonUIParams(unloadAllButton, {ap = display.LEFT_TOP})
    display.commonLabelParams(unloadAllButton, fontWithColor(14, {reqW = 120,  text = __('全部撤下')}))
    unloadAllButton:setOnClickScriptHandler(function(sender)
        PlayAudioByClickNormal()
        AppFacade.GetInstance():DispatchObservers("UNLOAD_ITEMS", {single = false})
    end)
    local lwidth = display.getLabelContentSize(unloadAllButton).width
    if lwidth < 124 then lwidth = 124 end
    unloadAllButton:setContentSize(cc.size(lwidth + 20, 62))
    topView:setName('TOPVIEW')
    topView:addChild(unloadAllButton,2)


    ---下面部分的卡牌页面的逻辑
    local csize = cc.size(1334, 232)
    local bgLayout = CLayout:create(csize)
    bgLayout:setBackgroundImage(_res("ui/iceroom/refresh_bg_card.png"))
    display.commonUIParams(bgLayout, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx,0)})
    view:addChild(bgLayout,3)

    --添加左右键
    local XSize = 120
    local leftArrow = CLayout:create(cc.size(120, 232))
    leftArrow:setBackgroundImage(_res("ui/iceroom/refresh_bg_card_s.png"))
    leftArrow:setPosition(cc.p(46,124))
    bgLayout:addChild(leftArrow,2)
    local leftButton = display.newButton(120 * 0.55, 232 * 0.54, {
        n = _res("ui/iceroom/common_btn_direct_s_left.png"),
        d = _res("ui/iceroom/common_btn_direct_disabled_s_left.png")
    })
    leftArrow:addChild(leftButton)
    local rightArrow = CLayout:create(cc.size(120, 232))
    rightArrow:setBackgroundImage(_res("ui/iceroom/refresh_bg_card_s.png"))
    rightArrow:setPosition(cc.p(1334 - 60,124))
    bgLayout:addChild(rightArrow,2)
    local rightButton = display.newButton(120 * 0.585, 232 * 0.54, {
        n = _res("ui/iceroom/common_btn_direct_s.png"),
        d = _res("ui/iceroom/common_btn_direct_disabled_s.png")
    })
    rightArrow:addChild(rightButton)

    local itemNodes = {}
    local csize = cc.size((1334 - 340 ) / 6,232)
    local deltaX = 165
    for i=1,6 do
        local node = IceRoomHeroCell.new({size = csize})
        display.commonUIParams(node, {ap = display.LEFT_CENTER,po = cc.p(deltaX + (i - 1) * csize.width + 40, 116)})
        node:setScale(0.95)
        bgLayout:addChild(node)
        table.insert( itemNodes,node )
    end
    local quickAllPlayBtn = display.newButton(csize.width - 10 ,116 ,{ n = _res('ui/iceroom/refresh_btn_quick_enter')})
    bgLayout:addChild(quickAllPlayBtn)
    display.commonLabelParams(quickAllPlayBtn , fontWithColor(14, {text =__('一键放入') , offset = cc.p(0, -60 )}))

    quickAllPlayBtn:setOnClickScriptHandler(function(sender)
        PlayAudioByClickNormal()
        AppFacade.GetInstance():DispatchObservers("QUICK_ALL_ICE_PLAY", {})
    end)
     -- close button
    local closeButton = display.newButton(display.cx + 612, size.height - 10, {
        n = _res("ui/iceroom/refresh_bg_quit.png")})
    local icon = display.newSprite(_res("ui/iceroom/refresh_ico_quit.png"))
    display.commonUIParams(icon, {po = cc.p(closeButton:getContentSize().width * 0.584, closeButton:getContentSize().height * 0.484)})
    closeButton:addChild(icon)
    display.commonUIParams(closeButton, {ap = display.CENTER_TOP})
    view:addChild(closeButton,2)
    return {
        touchLayout     = eaterLayer,
        contentView     = contentView,
        view            = view,
        bgLayout        = bgLayout,
        leftArrow       = leftArrow,
        leftButton      = leftButton,
        rightArrow      = rightArrow,
        rightButton     = rightButton,
        itemNodes       = itemNodes,
        closeButton     = closeButton,
        topView         = topView,
        rolesItems      = rolesItems,
        quickAllPlayBtn = quickAllPlayBtn,
        unloadAllButton = unloadAllButton,
    }
end


function IceRoomMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = {}
end

function IceRoomMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.IcePlace_Home_Callback,
		SIGNALNAMES.IcePlace_Unlock_Callback,
		SIGNALNAMES.IcePlace_AddCard_Callback,
        SIGNALNAMES.IcePlace_RemoveCardOut_Callback,
        SIGNALNAMES.Hero_AddVigour_Callback, --喂食的操作
        SIGNALNAMES.ICEPLACE_UnLockPosition, --解锁位置
        SIGNALNAMES.ICEPLACE_UnLoad, --卸载冰场的操作
        SIGNALNAMES.ICEPLACE_Rewards,--冰场事件奖励;
        SIGNALNAMES.ICEPLACE_ADD_MULTI_CARD,
        "REFRESH_NOT_CLOSE_GOODS_EVENT", --刷新材料页面
        "EVENT_TIME_UPDATE",
        "UNLOAD_ITEMS",
        "QUICK_ALL_ICE_PLAY"
	}

	return signals
end

local offsetX = (1334 - display.width) * 0.5
local offsetY = (1002 - display.height) * 0.5
local RAND_POSITIONS = {
    ['1'] = cc.p(180 - offsetX, display.height + offsetY - 642),
    ['2'] = cc.p(307 - offsetX, display.height + offsetY - 533),
    ['3'] = cc.p(480 - offsetX, display.height + offsetY - 620),
    ['4'] = cc.p(517 - offsetX, display.height + offsetY - 476),
    ['5'] = cc.p(696 - offsetX, display.height + offsetY - 603),
    ['6'] = cc.p(813 - offsetX, display.height + offsetY - 463),
    ['7'] = cc.p(871 - offsetX, display.height + offsetY - 429),
    ['8'] = cc.p(1113 - offsetX, display.height + offsetY - 587),
}

function IceRoomMediator:ProcessSignal(signal )
	local name = signal:GetName()
    local body = signal:GetBody()
	if name == SIGNALNAMES.IcePlace_Home_Callback then
		--更新UI
        self.rooms = body.icePlace --当前所有的冰场信息的功能逻辑
        self.leftEventRewardTimes = checkint(checktable(body).leftEventRewardTimes)
        gameMgr:GetUserInfo().iceVigourRecoverSeconds = checkint(checktable(body).iceVigourRecoverSeconds)
        --计时器中的数据刷新的操作,更新所有卡的活力值数据
        for roomId,v in pairs(self.rooms) do
            local beds = v.icePlaceBed
            if beds and table.nums(beds) > 0 then
                for id,v in pairs(beds) do
                    --更新卡的数据
                    gameMgr:UpdateCardDataById(checkint(id), {vigour = checkint(v.newVigour)})
                end
            end
        end
        self:SetIcePlaceBtnIsVisible()
	elseif name == SIGNALNAMES.IcePlace_AddCard_Callback then
        --添加卡牌到冰场成功后的逻辑
        --1添加到冰场上
        --2.刷新列表数据
        xTry(function()
            if body.errcode then
                --如果出错，再将加入的移出掉
                local card = gameMgr:GetCardDataById(body.data.requestData.playerCardId)
                if card then
                    self:GetViewComponent():RemoveBody(card.cardId)
                end
            else
                local card = gameMgr:GetCardDataById(body.requestData.playerCardId)
                if card then
                    local datas = {}
                    for k,v in pairs(self.cardsDatas) do
                        if checkint(v.cardId) ~= checkint(card.cardId) then
                            table.insert( datas,v )
                        end
                    end
                    if body.newPlayerCard then
                        gameMgr:UpdateCardDataById(body.newPlayerCard.playerCardId, {vigour = checkint(body.newPlayerCard.vigour)})
                        gameMgr:SetCardPlace({}, {{id = body.newPlayerCard.playerCardId}}, CARDPLACE.PLACE_ICE_ROOM)
                        if not self.rooms[tostring(self.roomId)].icePlaceBed then
                            --初始状态无数据的状态的逻辑
                            self.rooms[tostring(self.roomId)].icePlaceBed = {[tostring(body.newPlayerCard.playerCardId)] = {
                                playerCardId = playerCardId, vigour = checkint(body.newPlayerCard.vigour), recoverTime = checkint(body.newPlayerCard.recoverTime)
                            }}
                        else
                            --添加一个数据
                            self.rooms[tostring(self.roomId)].icePlaceBed[tostring(body.newPlayerCard.playerCardId)] = {
                                playerCardId = playerCardId, vigour = checkint(body.newPlayerCard.vigour), recoverTime = checkint(body.newPlayerCard.recoverTime)
                            }
                        end
                        if checkint(body.newPlayerCard.recoverTime) > 0 then
                            --添加新的q版到冰场上时，添加计时器
                            --添加恢复时间的逻辑
                            local id = checkint(body.newPlayerCard.playerCardId)
                            timerMgr:RemoveTimer(string.format('ICEROOM_%s',tostring(id))) --移除旧的计时器，活加新计时器
                            timerMgr:AddTimer({name = string.format('ICEROOM_%s',tostring(id)),countdown = checkint(body.newPlayerCard.recoverTime), tag = RemindTag.ICEROOM, autoDelete = true, isLosetime = false} )
                        end
                    end
                    if self.cardViewData then
                        self.cardsDatas = datas --新数据
                        self:ReloadDatas()
                    end
                    self:GetViewComponent():AddIceRoomBodes()
                end
            end
        end, __G__TRACKBACK__)
    elseif name == SIGNALNAMES.ICEPLACE_UnLoad then
        --卸载的操作
        if body.errcode then -- some error
             --如果出错，将不做卸载处理
        else
            for id,newVigour in pairs(body.newVigour) do --所有的床位人物去除
                timerMgr:RemoveTimer(string.format('ICEROOM_%s',tostring(id))) --移除旧的计时器，活加新计时器
                gameMgr:UpdateCardDataById(id, {vigour = checkint(newVigour)})
                gameMgr:DeleteCardPlace({{id = id}}, CARDPLACE.PLACE_ICE_ROOM)
                --刷新最下方的人物信息
                local card = gameMgr:GetCardDataById(id)
                if card then
                    --将删除的数据插入到列表项中去
                    table.insert( self.cardsDatas, 1, card )
                    self.cardsDatas = filterDatas(self.cardsDatas, {})
                    self:GetViewComponent():UnLoadCard(card.cardId)
                end
                self.rooms[tostring(self.roomId)].icePlaceBed[tostring(id)] = nil
            end

            -- if body.playerCardId then
                -- gameMgr:UpdateCardDataById(body.playerCardId, {vigour = checkint(body.newVigour)})
                -- gameMgr:DeleteCardPlace({{id = body.playerCardId}}, CARDPLACE.PLACE_ICE_ROOM)
                -- self.rooms[tostring(self.roomId)].icePlaceBed[tostring(body.playerCardId)] = nil
                -- local id = checkint(body.playerCardId)
                -- timerMgr:RemoveTimer(string.format('ICEROOM_%s',tostring(id))) --移除旧的计时器，活加新计时器
            -- end
            -- --刷新最下方的人物信息
            -- local card = gameMgr:GetCardDataById(body.playerCardId)
            -- if card then
                -- --将删除的数据插入到列表项中去
                -- table.insert( self.cardsDatas, 1, card )
                -- self.cardsDatas = filterDatas(self.cardsDatas, {})
                -- self:GetViewComponent():UnLoadCard(card.cardId)
            --[[ end ]]
            if body.requestData.hasTop and checkint(body.requestData.hasTop) == 1 then
                if self.cardViewData then
                    self:ReloadDatas()
                end
            end
            self:GetViewComponent():FreshBottomNodes(self.rooms[tostring(self.roomId)])
        end
        --刷新解锁的对话框页面
        local unlockView = self:GetViewComponent():GetGameLayerByTag(1234)
        if unlockView then
            unlockView:FreshUI(self.roomId,self.rooms)
        end
    elseif name == "UNLOAD_ITEMS" then
        --卸载快捷方式的操作逻辑
        local roomData = self.rooms[tostring(self.roomId)]
        if table.nums(checktable(roomData.icePlaceBed)) > 0 then
            if checkbool(body.single) then
                local id = checkint(body.id)
                if id > 0 then
                    AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, {icePlaceId = checkint(self.roomId), playerCardId = tostring(id), hasTop = 1},'unload')
                end
            else
                --很多人全部卸载下的逻辑
                local roomData = self.rooms[tostring(self.roomId)]
                local bedsData = checktable(roomData).icePlaceBed
                local idSeq = {}
                for id,val in pairs(bedsData) do --所有的床位人物去除
                    table.insert(idSeq, id)
                end
                --发送请求
                AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, {icePlaceId = checkint(self.roomId), playerCardId = table.concat(idSeq, ','), hasTop = 1},'unload')
            end
        end
    elseif name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then
        --刷新材料页面的逻辑
        xTry(function ()
            local unlockView = self:GetViewComponent():GetGameLayerByTag(1234)
            if unlockView then
                unlockView:FreshUI(self.roomId,self.rooms)
            end
        end,__G__TRACKBACK__)
    elseif name == SIGNALNAMES.IcePlace_RemoveCardOut_Callback then
        --- replace card
        if body.errcode then -- some error
             --如果出错，再将加入的移出掉
            local card = gameMgr:GetCardDataById(body.data.requestData.playerCardId)
            if card then
                self:GetViewComponent():RemoveBody(card.cardId)
            end
        else
            --更新疲劳值的本地恢复时间
            if body.newPlayerCard then
                gameMgr:UpdateCardDataById(body.newPlayerCard.playerCardId, {vigour = checkint(body.newPlayerCard.vigour)})
                gameMgr:SetCardPlace({}, {{id = body.newPlayerCard.playerCardId}}, CARDPLACE.PLACE_ICE_ROOM)
                if not self.rooms[tostring(self.roomId)].icePlaceBed then
                    --初始状态无数据的状态的逻辑
                    self.rooms[tostring(self.roomId)].icePlaceBed = {[tostring(body.newPlayerCard.playerCardId)] = {
                        playerCardId = playerCardId, vigour = checkint(body.newPlayerCard.vigour), recoverTime = checkint(body.newPlayerCard.recoverTime)
                    }}
                else
                    --添加一个数据
                    self.rooms[tostring(self.roomId)].icePlaceBed[tostring(body.newPlayerCard.playerCardId)] = {
                        playerCardId = playerCardId, vigour = checkint(body.newPlayerCard.vigour), recoverTime = checkint(body.newPlayerCard.recoverTime)
                    }
                end
                local id = checkint(body.newPlayerCard.playerCardId)
                timerMgr:RemoveTimer(string.format('ICEROOM_%s',tostring(id))) --移除旧的计时器，活加新计时器
                timerMgr:AddTimer({name = string.format('ICEROOM_%s',tostring(id)),countdown = checkint(body.newPlayerCard.recoverTime), tag = RemindTag.ICEROOM, autoDelete = true, isLosetime = false} )
            end
            if body.oldPlayerCard then
                --删除旧的数据
                gameMgr:UpdateCardDataById(body.oldPlayerCard.playerCardId, {vigour = checkint(body.oldPlayerCard.vigour)})
                gameMgr:DeleteCardPlace({{id = body.oldPlayerCard.playerCardId}}, CARDPLACE.PLACE_ICE_ROOM)
                self.rooms[tostring(self.roomId)].icePlaceBed[tostring(body.oldPlayerCard.playerCardId)] = nil
                local id = checkint(body.oldPlayerCard.playerCardId)
                timerMgr:RemoveTimer(string.format('ICEROOM_%s',tostring(id))) --移除旧的计时器，活加新计时器
            end
            --刷新最下方的人物信息
            self:GetViewComponent():FreshBottomNodes(self.rooms[tostring(self.roomId)])

            local card = gameMgr:GetCardDataById(body.requestData.playerCardId)
            local ocard = gameMgr:GetCardDataById(body.requestData.oldPlayerCardId)
            if card and ocard then
                local datas = {}
                for k,v in pairs(self.cardsDatas) do
                    if checkint(v.cardId) ~= checkint(card.cardId) then
                        table.insert( datas,v )
                    else
                        table.insert( datas,k, ocard ) --将旧的插入数据
                    end
                end
                if self.cardViewData then
                    self.cardsDatas = datas --新数据
                    self:ReloadDatas()
                end
                self:GetViewComponent():ReplaceCard(card.cardId)
            end
        end
    elseif name == "EVENT_TIME_UPDATE" then
        --修正时间
        local id = body.id
        local remain = body.time
        local roomDatas = checktable(self.rooms[tostring(self.roomId)].icePlaceBed)
        if roomDatas and roomDatas[tostring(id)] then
            roomDatas[tostring(id)].recoverTime = remain
        end
    elseif name == SIGNALNAMES.Hero_AddVigour_Callback then
        if body.errcode then -- some error
             --如果出错，再将加入的移出掉
        else
            --喂食成功后的逻辑,然后还要更新本地数据的数量与vigour
            local id = body.requestData.playerCardId
            local goodsId = body.requestData.goodsId
            local vigour = checkint(body.vigour)
            local recoverTime = checkint(body.recoverTime)
            self.rooms[tostring(self.roomId)].icePlaceBed[tostring(id)].recoverTime = recoverTime
            --更新道具数量本地缓存
            local card = gameMgr:GetCardDataById(id)
            gameMgr:UpdateCardDataById(id,{vigour = vigour})
            CommonUtils.DrawRewards({{goodsId = goodsId, num = -1}})
            --更新喂食面板
            self:GetViewComponent():VigourUpdate(true) --更新喂后的活力值新鲜度
            local foodView = self:GetViewComponent():GetGameLayerByTag(9876)
            if foodView then
                foodView:UpdateNumbers() --更新所有的数量
            end
            --更新q板的动作为兴奋状态
            if card then
                local roles = self:GetViewComponent():GetRolesCount()
                for k,v in pairs(roles) do
                    if v:getTag() == checkint(card.cardId) then
                        v:FeedSuccess()
                        CommonUtils.PlayCardSoundByCardId(card.cardId, SoundType.TYPE_ICEROOM_RANDOM, SoundChannel.CARD_FEED)
                        break
                    end
                end
            end
            self:GetViewComponent():FreshBottomNodes(self.rooms[tostring(self.roomId)])
        end
    elseif name == SIGNALNAMES.ICEPLACE_Rewards then
        --奖励弹出框
        if table.nums(checktable(checktable(body).rewards)) > 0 then
            self.leftEventRewardTimes = self.leftEventRewardTimes - 1
            if self.leftEventRewardTimes < 0 then self.leftEventRewardTimes = 0 end
            -- CommonUtils.DrawRewards(checktable(body).rewards) --先入到缓存
            uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(checktable(body).rewards)}, 90)
        end
    elseif name == SIGNALNAMES.ICEPLACE_UnLockPosition then
        --更新主面板的卡槽显示
        --更新数据
        --删除缓存消耗的材料
        local UpgradeDatas = dataMgr:GetConfigDataByFileName("icePlaceUpgrade", "iceBink")
        local placeId = checkint(checktable(body.requestData).placeId)
        local consumeData = UpgradeDatas[tostring(self.roomId)][tostring(placeId)]
        if consumeData and table.nums(checktable(consumeData.consume)) > 0 then
            --如果存在消耗
            for name,v in pairs(consumeData.consume) do
                CommonUtils.DrawRewards({{goodsId = checkint(v.targetId), num = -checkint(v.targetNum)}})
            end
        end
        self.rooms[tostring(self.roomId)].icePlaceBedNum = checkint(self.rooms[tostring(self.roomId)].icePlaceBedNum) + 1
        if checkint(self.rooms[tostring(self.roomId)].icePlaceBedNum) > 8 then
            self.rooms[tostring(self.roomId)].icePlaceBedNum = 8 --达到最大值时变为最大值
        end
        self:GetViewComponent():FreshBottomNodes(self.rooms[tostring(self.roomId)])
        local view = self:GetViewComponent():GetGameLayerByTag(1234)
        --更新解锁的回调更新界面
        if view then
            view:FreshUI(self.roomId, self.rooms)
        end
        self:SetIcePlaceBtnIsVisible()
    elseif name == "QUICK_ALL_ICE_PLAY" then
        local quickPlayer = {}
        local canPlayerRooms = {}
        local beds = {}
        local countRoom = table.nums(self.rooms)
        for roomId = 1 , countRoom  do
            v = self.rooms[tostring(roomId)]
            v.icePlaceBedNum = checkint(v.icePlaceBedNum)
            v.icePlaceBed = v.icePlaceBed or {}
            local count = table.nums(v.icePlaceBed)
            if v.icePlaceBedNum > count then
                canPlayerRooms[tostring(roomId)]  = v.icePlaceBedNum - count
            end
            for id, cardData in pairs(v.icePlaceBed) do
                beds[tostring(id)] = id
            end
        end
        if table.nums(canPlayerRooms) == 0  then
            app.uiMgr:ShowInformationTips(__('冰场已满'))
            return
        end
        for i, v in pairs(self.cardsDatas) do
            local maxVigour = checkint(app.restaurantMgr:GetMaxCardVigourById(v.id))
            local vigour = checkint(v.vigour)
            if maxVigour <= vigour then
                break
            else
                if not beds[tostring(v.id)] then
                    local isCan = app.gameMgr:CanSwitchCardStatus({id = v.id}, CARDPLACE.PLACE_ICE_ROOM)
                    if isCan then
                        quickPlayer[#quickPlayer+1] = v
                    end

                end
            end
        end
        local playerCount =  0
        local req = {}
        for roomId = 1, countRoom  do  -- in pairs(canPlayerRooms)
            local  num = checkint(canPlayerRooms[tostring(roomId)])
            for i = 1 , num do
                playerCount = playerCount + 1
                if quickPlayer[playerCount] then
                    if not req[tostring(roomId)] then
                        req[tostring(roomId)] = {}
                    end
                    req[tostring(roomId)][#req[tostring(roomId)]+1] =quickPlayer[playerCount].id
                end
            end
        end
        if table.nums(req) == 0  then
            app.uiMgr:ShowInformationTips(__('飨灵新鲜度已满'))
            return
        end
        dump(req)
        app:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE , {icePlaces = json.encode(req)  } , 'addMultiCard')
    elseif name == SIGNALNAMES.IcePlace_Unlock_Callback then
        local requestData = body.requestData
        local roomId = requestData.icePlaceId
        self.rooms[tostring(roomId)] = {
            icePlaceBed = {} ,
            icePlaceId =tostring(roomId),
            icePlaceName = "",
            icePlaceBedNum = 1
        }
        self:SwithBtnEvent(self.roomId , 1)
        self:SwithIcePlaceFloor(self.roomId  ,roomId )
        self:SetIcePlaceBtnIsVisible()
        -- 抽出解锁消耗掉的道具
        local  icePlaceUnlockOneConf = app.dataMgr:GetConfigDataByFileName("icePlaceUnlock", "iceBink")[tostring(roomId)] or {}
        local data = {}
        for k,v in pairs(icePlaceUnlockOneConf.unlockType) do
            if checkint(k) ~= UnlockTypes.AS_LEVEL and checkint(k) ~= UnlockTypes.PLAYER then
                if checkint(k) == UnlockTypes.GOLD then
                    data[#data+1] = {goodsId = GOLD_ID, showAmount = true ,  num  = - checkint(v.targetNum)}
                elseif checkint(k) == UnlockTypes.DIAMOND then
                    data[#data+1] = {goodsId = DIAMOND_ID,  showAmount = true , num  = - checkint(v.targetNum)}
                elseif checkint(k) == UnlockTypes.GOODS then
                    data[#data+1] = {goodsId = checkint(v.targetId),  showAmount = true , num  = -  checkint(v.targetNum)}
                end
            end
        end
        CommonUtils.DrawRewards(data)
    elseif name == SIGNALNAMES.ICEPLACE_ADD_MULTI_CARD then
        --- replace card
        if body.errcode then -- some error
            --如果出错，再将加入的移出掉
            local card = gameMgr:GetCardDataById(body.data.requestData.playerCardId)
            if card then
                self:GetViewComponent():RemoveBody(card.cardId)
            end
        else
            --更新疲劳值的本地恢复时间
            local positions = {1,2,3,4,5,6,7,8}
            if body.newPlayerCard then
                --刷新最下方的人物信息
                ---@type IceRoomScene
                local viewComponent = self:GetViewComponent()
                for i, cardData  in pairs(body.newPlayerCard) do
                    gameMgr:UpdateCardDataById(cardData.playerCardId, {vigour = checkint(cardData.vigour)})
                    gameMgr:SetCardPlace({}, {{id = cardData.playerCardId}}, CARDPLACE.PLACE_ICE_ROOM)
                    if not self.rooms[tostring(cardData.icePlaceId)].icePlaceBed then
                        self.rooms[tostring(cardData.icePlaceId)].icePlaceBed = {}
                    end
                    self.rooms[tostring(cardData.icePlaceId)].icePlaceBed[tostring(cardData.playerCardId)] = cardData
                    local id = checkint(cardData.playerCardId)
                    timerMgr:RemoveTimer(string.format('ICEROOM_%s',tostring(id))) --移除旧的计时器，活加新计时器
                    timerMgr:AddTimer({name = string.format('ICEROOM_%s',tostring(id)),countdown = checkint(cardData.recoverTime), tag = RemindTag.ICEROOM, autoDelete = true, isLosetime = false} )
                    if checkint(cardData.icePlaceId) == checkint(self.roomId)  then
                        local card = gameMgr:GetCardDataById(cardData.playerCardId)
                        local pos = math.random(1,#positions)
                        viewComponent:AddCardAtLocation(card.cardId , RAND_POSITIONS[tostring(positions[pos])])
                        table.remove(positions , pos)
                    end
                end
                local newPlayerCard =  body.newPlayerCard
                -- 去除已经在冰场的飨灵
                local beds = {}
                for i, v in pairs(newPlayerCard) do
                    beds[tostring(v.playerCardId)] =  v.playerCardId
                end
                local datas = {}
                for i, v in pairs(self.cardsDatas) do
                    if not  beds[tostring(v.id)]  then
                        table.insert(datas, #datas+1 ,v )
                    end
                end
                if self.cardViewData then
                    self.cardsDatas = datas --新数据
                    self:ReloadDatas()
                end
                viewComponent:FreshBottomNodes(self.rooms[tostring(self.roomId)])
                viewComponent:AddIceRoomBodes()
            end
        end
    end
end

function IceRoomMediator:SwithIcePlaceFloor(preRoomId , cuurrentRoomId)
    ---@type IceRoomScene
    local viewComponent = self:GetViewComponent()
    -- 卸载掉卡牌
    self.roomId = cuurrentRoomId
    viewComponent:UpdateRoomId( cuurrentRoomId)
    for i , v in pairs(self.rooms[tostring(preRoomId)].icePlaceBed or {}) do
        local cardData = app.gameMgr:GetCardDataById(i)
        viewComponent:UnLoadCard(cardData.cardId)
    end
    local beds = self.rooms[tostring(cuurrentRoomId)].icePlaceBed or {}
    local positions = {1,2,3,4,5,6,7,8}
    for i,v in pairs( beds) do
        local card = gameMgr:GetCardDataById(i)
        local pos = math.random(1,#positions)
        viewComponent:AddCardAtLocation(checkint(card.cardId), RAND_POSITIONS[tostring(positions[pos])])
        table.remove(positions, pos)
    end
    viewComponent:FreshBottomNodes(self.rooms[tostring(cuurrentRoomId)])
    viewComponent:AddIceRoomBodes()
end


function IceRoomMediator:Initial( key )
	self.super.Initial(self,key)
    self.rooms = {}
    self.roomId = 1 --当前的房间id
    self.cardViewData  = nil --卡牌的界面对象
    self.cardsDatas = {} --当前已有的卡牌
    self.pageNo   = 1 --当前页码
    self.unlockTypes = dataMgr:GetConfigDataByFileName("icePlaceUnlock", "iceBink")
    --会有一次过滤操作
     if self.payload then
        self.rooms = self.payload.icePlace --当前所有的冰场信息的功能逻辑
        self.leftEventRewardTimes = checkint(checktable(self.payload).leftEventRewardTimes)
        gameMgr:GetUserInfo().iceVigourRecoverSeconds = checkint(checktable(self.payload).iceVigourRecoverSeconds)
        if next(self.rooms) == nil then
            self.rooms = {['1'] = {}} --初始化第一个冰场给玩家
        end
        --更新所有卡的活力值数据
        for roomId,v in pairs(self.rooms) do
            if not v.icePlaceBed then v.icePlaceBed = {} end
            local beds = v.icePlaceBed
            if beds and table.nums(beds) > 0 then
                for id,v in pairs(beds) do
                    --更新卡的数据
                    gameMgr:UpdateCardDataById(checkint(id), {vigour = checkint(v.newVigour)})
                    if checkint(v.recoverTime) > 0 then
                        --添加计时器的逻辑
                        timerMgr:AddTimer({name = string.format('ICEROOM_%s',tostring(id)),countdown = checkint(v.recoverTime), tag = RemindTag.ICEROOM, autoDelete = true, isLosetime = false} )
                    end
                end
            end
        end
    end
    if gameMgr.userInfo and gameMgr.userInfo.cards then
        -- local excludes = checktable(gameMgr.userInfo.employee)
        self.cardsDatas = filterDatas(clone(gameMgr.userInfo.cards), {})
    end
    local viewComponent = uiMgr:SwitchToTargetScene('Game.views.IceRoomScene', {roomId = self.roomId, mediator = self})
	self:SetViewComponent(viewComponent)

	--绑定相关的事件
	local viewData = viewComponent.viewData
    viewData.heroButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
    viewData.roleNodes:setOnClickScriptHandler(handler(self, self.ButtonActions))
    viewData.unlockIcePlaceBtn:setOnClickScriptHandler(handler(self, self.ButtonActions))
    viewData.lastBtn:setOnClickScriptHandler(handler(self, self.ButtonActions))
    viewData.nextBtn:setOnClickScriptHandler(handler(self, self.ButtonActions))
    -- viewData.iceButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
    viewData.foodButton:setOnClickScriptHandler(handler(self, self.ButtonActions))
    self:SwithBtnEvent(self.roomId, 0)
    self:SetIcePlaceBtnIsVisible()
    if self.payload then
        -- self.rooms = self.payload.icePlace --当前所有的冰场信息的功能逻辑
        -- if next(self.rooms) == nil then
        --     self.rooms = {['1'] = {}} --初始化第一个冰场给玩家
        -- end
        -- dump(self.rooms)
        -- --更新所有卡的活力值数据
        -- for roomId,v in pairs(self.rooms) do
        --     local beds = v.icePlaceBed
        --     if beds and table.nums(beds) > 0 then
        --         for id,v in pairs(beds) do
        --             --更新卡的数据
        --             gameMgr:UpdateCardDataById(checkint(id), {vigour = checkint(v.newVigour)})
        --         end
        --     end
        -- end
        --更新冰场中的各卡牌对象
        -- 去除已经在冰场的卡牌
        local datas = {}
        local iceBed = {}
        for icePlaceId, room in pairs(self.rooms) do
            local icePlaceBed = room.icePlaceBed or {}
            for id , v in pairs(icePlaceBed) do
                iceBed[tostring(id)] = v
            end
        end
        for i ,v in pairs(self.cardsDatas) do
            if not iceBed[tostring(v.id)] then
                table.insert( datas,v)
            end
        end
        self.cardsDatas = datas
        if self.rooms[tostring(self.roomId)] and table.nums(checktable(self.rooms[tostring(self.roomId)].icePlaceBed)) > 0 then
            local positions = {1,2,3,4,5,6,7,8}
            utils.newrandomseed()
            --随机生成一个位置
            local loader = CCResourceLoader:getInstance()
            loader:registerScriptHandler(function ( event )
                --回调加载的进步以及是否完成的逻辑
                if event.event == 'done' then
                    for k,v in pairs(self.rooms[tostring(self.roomId)].icePlaceBed) do
                        local card = gameMgr:GetCardDataById(checkint(k))
                        local pos = math.random( #positions)
                        self:GetViewComponent():AddCardAtLocation(checkint(card.cardId), RAND_POSITIONS[tostring(positions[pos])])
                        table.remove( positions,pos )
                    end
                    self:GetViewComponent():AddIceRoomBodes() --再更新一下动态数据
                end
            end)
            for k,v in pairs(self.rooms[tostring(self.roomId)].icePlaceBed) do
                local card = gameMgr:GetCardDataById(checkint(k))
                local spinePath = CardUtils.GetCardSpinePathBySkinId(card.defaultSkinId)
                if app.gameResMgr:verifySpine(spinePath) then
                    loader:addCustomTask(cc.CallFunc:create(function ( )
                        SpineCache(SpineCacheName.GLOBAL):addCacheData(spinePath,tostring(card.defaultSkinId), 0.38)
                    end),0.05)
                end
            end
            loader:run() --执行循环
            self:GetViewComponent():FreshBottomNodes(self.rooms[tostring(self.roomId)])
        end

    end
end

--[[
--获取到当前的床数量
--]]
function IceRoomMediator:RetriveBedNums( )
    local initNum = checkint(self.unlockTypes[tostring(self.roomId)].unlockInitNum)
    if self.rooms[tostring(self.roomId)] then
        if checkint(self.rooms[tostring(self.roomId)].icePlaceBedNum) <= initNum then
            self.rooms[tostring(self.roomId)].icePlaceBedNum = initNum
        end
        initNum = checkint(self.rooms[tostring(self.roomId)].icePlaceBedNum)
    end
    return initNum
end

--[[
--更新底部条显示
--]]
function IceRoomMediator:FreshTopNodes( )
    local bedsData = self.rooms[tostring(self.roomId)]
    if bedsData.icePlaceBed then
        local maxLen = checkint(bedsData.icePlaceBedNum)
        local curUpLen = table.nums(checktable(bedsData.icePlaceBed))
        for k,itemNode in pairs(self.cardViewData.rolesItems) do
            itemNode.bgbutton:setUserTag(0)
            if k <= curUpLen then
                --已上阵的人物
                local Id = table.keys(bedsData.icePlaceBed)[k] --当前位置的数据id值
                local cardInfo = gameMgr:GetCardDataById(Id)
                itemNode.bgbutton:setUserTag(checkint(Id))
                if cardInfo then
                    itemNode.headerNode:setVisible(true)
                    itemNode.headerNode:updateImageView(cardInfo.cardId)
                    --还要判断活力值是否已满
                    local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
                    if checkint(cardInfo.vigour) >= maxVigour then
                        itemNode.checkedFlag:setVisible(true)
                    else
                        itemNode.checkedFlag:setVisible(false)
                    end
                end
            else
                if k <= maxLen then
                    --解锁的状态
                    itemNode.checkedFlag:setVisible(false)
                    itemNode.headerNode:setVisible(false)
                    itemNode.lockSprite:setVisible(false)
                else
                    --是锁定的状态
                    itemNode.checkedFlag:setVisible(false)
                    itemNode.headerNode:setVisible(false)
                    itemNode.lockSprite:setVisible(false)
                end
            end
        end
    end
end

--[[
--重置列表
--]]
function IceRoomMediator:ReloadDatas( )
    xTry(function()
        self:FreshTopNodes()
        local len = table.nums(self.cardsDatas)
        if len > 0 then
            local maxPage = math.floor((len + PAGE_SIZE - 1) / PAGE_SIZE)
            if self.pageNo < 0 then self.pageNo = 1 end -- 修正数据
            if self.pageNo > maxPage then self.pageNo = maxPage end --修正数据
            -- print("--pageNo======curpage == len == ", maxPage, self.pageNo, len)
            if self.pageNo <= maxPage then
                if self.pageNo == 1 then
                    -- self.cardViewData.leftArrow:setBackgroundImage(_res("ui/iceroom"))
                    self.cardViewData.leftButton:setEnabled(false)
                    self.cardViewData.rightButton:setEnabled(true)
                elseif self.pageNo == maxPage then
                    self.cardViewData.rightButton:setEnabled(false)
                    self.cardViewData.leftButton:setEnabled(true)
                else
                    self.cardViewData.leftButton:setEnabled(true)
                    self.cardViewData.rightButton:setEnabled(true)
                end
                -- local start = (self.pageNo - 1) * PAGE_SIZE + 1
                local maxEnd = self.pageNo * PAGE_SIZE
                if maxEnd > len then
                    maxEnd = len --超过范围的数据
                end
                local iteNo = maxEnd % PAGE_SIZE
                if iteNo == 0 then iteNo = PAGE_SIZE end
                for i=1,PAGE_SIZE do
                    local node = self.cardViewData.itemNodes[i]
                    if i > iteNo then
                        node:setVisible(false)
                    else
                        node:setVisible(true)
                        local index = (self.pageNo - 1) * PAGE_SIZE + i
                        local dd = self.cardsDatas[index]
                        if dd then
                            node:setTag(checkint(dd.cardId))
                            node:UpdateUI(dd)
                        end
                    end
                end
            else
                funLog(Logger.INFO, "-====== pagesize overed")
            end
        else
            self.cardViewData.leftButton:setEnabled(false)
            self.cardViewData.rightButton:setEnabled(false)
            for name,node in pairs(self.cardViewData.itemNodes) do
                node:setVisible(false)
            end
        end
    end,__G__TRACKBACK__)
end
--[[
主页面tab按钮的事件处理逻辑
@param sender button对象
--]]
function IceRoomMediator:ButtonActions( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local node = self:GetViewComponent():RemoveDialogByTag(1234)
    if node then
        node:removeFromParent()
        self.cardViewData = nil
    end
    if tag == 200 then
        --飨灵
        if table.nums(self.cardsDatas) > 0 then
            self.cardViewData = CreateCardsView()
            display.commonUIParams(self.cardViewData.contentView,{po = display.center})
            self.cardViewData.contentView:setLocalZOrder(60)
            self.cardViewData.contentView:setTag(1234)
            self:GetViewComponent():AddDialog(self.cardViewData.contentView)
            self.cardViewData.leftButton:setOnClickScriptHandler(function(sender)
                PlayAudioByClickNormal()
                -- left
                self.pageNo = self.pageNo - 1
                self:ReloadDatas()
            end)
            self.cardViewData.rightButton:setOnClickScriptHandler(function(sender)
                PlayAudioByClickNormal()
                --right
                self.pageNo = self.pageNo + 1
                self:ReloadDatas()
            end)
            self.cardViewData.touchLayout:setOnClickScriptHandler(function(sender)
                sender:setTouchEnabled(false)
                self.cardViewData.closeButton:setVisible(false)
                self.viewComponent:runAction(cc.Sequence:create(cc.Spawn:create(cc.TargetedAction:create(self.cardViewData.bgLayout,cc.MoveTo:create(0.2,cc.p(display.cx, -300))),
                cc.TargetedAction:create(self.cardViewData.topView,cc.MoveTo:create(0.2,cc.p(display.cx, display.height)))), cc.TargetedAction:create(self.cardViewData.contentView,cc.RemoveSelf:create()), cc.CallFunc:create(function()
                    self.cardViewData.contentView = nil
                    display.removeUnusedSpriteFrames() --清除一些缓存
                end)))
            end)
            self.cardViewData.closeButton:setOnClickScriptHandler(function(sender)
                PlayAudioByClickNormal()
                sender:setEnabled(false)
                sender:setVisible(false)
                self.viewComponent:runAction(cc.Sequence:create(cc.Spawn:create(cc.TargetedAction:create(self.cardViewData.bgLayout,cc.MoveTo:create(0.2,cc.p(display.cx, -300))),
                cc.TargetedAction:create(self.cardViewData.topView,cc.MoveTo:create(0.2,cc.p(display.cx, display.height)))), cc.TargetedAction:create(self.cardViewData.contentView,cc.RemoveSelf:create()), cc.CallFunc:create(function()
                    self.cardViewData.contentView = nil
                    display.removeUnusedSpriteFrames() --清除一些缓存
                end)))
            end)
            --更新单元格的数据
            self:ReloadDatas()
        else
            local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
            uiMgr:ShowInformationTips(__('您的所有飨灵都在冰场上了~~'))
        end
    elseif tag == 201 then --场景
        
    elseif tag == 202 then
        --喂食
        local node = self:GetViewComponent():GetGameLayerByTag(9876)
        if node then node:removeFromParent() end
        local view = require("Game.views.IceRoomFoodView").new()
        display.commonUIParams(view,{po = display.center})
        -- view:setLocalZOrder(60)
        view:setTag(9876)
        self:GetViewComponent():AddGameLayer(view)
    elseif tag == 203 then     -- 解锁下一层的消耗
        local countFloor = table.nums(self.unlockTypes)
        local currentUnlockFoor = table.nums(self.rooms)
        if countFloor <=  currentUnlockFoor then
            app.uiMgr:ShowInformationTips(__('已经解锁最高层'))
            return
        end
        local IceRoomUnlockPopUp = require("Game.views.icerRoom.IceRoomFloorUnlockPopUp").new({ roomId =currentUnlockFoor +1  })
        app.uiMgr:GetCurrentScene():AddDialog(IceRoomUnlockPopUp)
        IceRoomUnlockPopUp:setPosition(display.center)
    elseif tag == 204 then     -- 切换上一层
        self:SwithBtnEvent(self.roomId, -1)
        self:SwithIcePlaceFloor(self.roomId   ,self.roomId -1 )
    elseif tag == 205 then -- 切换下一层
        self:SwithBtnEvent(self.roomId, 1)
        self:SwithIcePlaceFloor(self.roomId  ,self.roomId +1 )
    else
        local dialog = require("Game.views.IceRoomUnlock").new({roomId = self.roomId, rooms = self.rooms})
        display.commonUIParams(dialog,{po = display.center})
        -- dialog:setLocalZOrder(60)
        dialog:setTag(1234)
        self:GetViewComponent():AddGameLayer(dialog)
    end
end
-- 切换btn 的事件
function IceRoomMediator:SwithBtnEvent( roomId  , direction)
    local lastEnable = false
    local nextEnable = false
    local currentRoomId = roomId + direction
    if self.rooms[tostring(currentRoomId - 1  )] then
        lastEnable = true
    end

    if self.rooms[tostring(currentRoomId + 1)] then
        nextEnable = true
    end
    ---@type IceRoomScene
    local viewComponent = self:GetViewComponent()
    viewComponent:SetSwithBtnStatus(lastEnable ,nextEnable )
    viewComponent:UpdateCurrentFloorLabel(currentRoomId)
end
function IceRoomMediator:SetIcePlaceBtnIsVisible()
    ---@type IceRoomScene 
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        local isVisible = self:CheckNextPlaceIsUnlock()

        viewComponent:SetIcePlaceBtnIsVisible(isVisible)
    end
end
--[[
    检测冰场下一层是否可以解锁
--]]
function IceRoomMediator:CheckNextPlaceIsUnlock()
    local maxPlace = table.nums(self.unlockTypes)
    local currentTotalPlace =  table.nums(self.rooms)
    if currentTotalPlace >=  maxPlace then
        return false
    else
        local icePlaceBedNum = checkint(checktable(self.rooms[tostring(currentTotalPlace)]).icePlaceBedNum)
        if ICE_PLACE_MAX_CARD == icePlaceBedNum then
            return true
        else
            return false
        end
    end    
end

function IceRoomMediator:GoogleBack()
    local node = self:GetViewComponent():GetDialogByTag(1234)
    if node then
        node:runAction(cc.RemoveSelf:create())
        self.cardViewData = nil
        return false
    end
    local unode = self:GetViewComponent():GetGameLayerByTag(1234)
    if unode then
        unode:runAction(cc.RemoveSelf:create())
        return false
    end

    local anode = self:GetViewComponent():GetGameLayerByTag(9876)
    if anode then
        anode:runAction(cc.RemoveSelf:create())
        return false
    end
    return true
end

function IceRoomMediator:OnRegist(  )
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
    local IceRoomCommand = require( 'Game.command.IceRoomCommand')
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_ICEPLACE, IceRoomCommand)

    GuideUtils.DispatchStepEvent()
end


function IceRoomMediator:OnUnRegist(  )
	--清除异步任务
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    CCResourceLoader:getInstance():abortAll()
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_ICEPLACE)
end

return IceRoomMediator
