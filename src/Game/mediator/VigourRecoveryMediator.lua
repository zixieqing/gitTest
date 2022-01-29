---
--- Created by xingweihao.
--- DateTime: 26/09/2017 3:00 PM
--- 新鲜度恢复界面 
local Mediator = mvc.Mediator
---@class VigourRecoveryMeiator :Mediator
local VigourRecoveryMeiator = class("VigourRecoveryMeiator", Mediator)
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type TakeawayManager
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')

---@type TimerManager
local timerMgr = AppFacade.GetInstance():GetManager('TimerManager')
local NAME = "VigourRecoveryMeiator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local WaitingShipping  = 1  -- 等待配送 
local CompleteOrder = 4     -- 完成订单 领取奖励
local PublicOrder = 2  -- 公有订单
local PrivateOrder =1  -- 私有订单
local BTN_TAG = {
    CHANGE_TEAM = 1101 ,
    MOUDLE_GOTO = 1102 ,
    PRE_TEAM_BTN = 1103 ,  --向前切换队伍的按钮
    NEXT_TEAM_BTM = 1104 , -- 向后切换编队
    TIPS_BTN = 1105 , -- 弹出tips 的提示
}
local RECOVER_TAKEAWAY_TYPE = 1   --- 外卖新鲜度恢复
--[[
param = {
    type =  1 ,  --类型
    vigourCost =10 , -- 新鲜度扣除
    selectedTeam =  2 , --选中的队伍
}
--]]
function VigourRecoveryMeiator:ctor(param ,viewComponent )
    self.super:ctor(NAME,viewComponent)
    param = param or {}
    self.type  =  checkint(param.type) -- 1. 为外卖的新鲜度恢复
    self.vigourCost = tonumber(param.vigourCost) --- 恢复的百分比
    self.selectedTeam = param.selectedTeam -- 传入队伍的参数
end


function VigourRecoveryMeiator:InterestSignals()
    local signals = {
        SIGNALNAMES.Exploration_AddVigour_Callback ,
        SIGNALNAMES.Exploration_DiamondRecover_Callback,
        "CLOSE_TEAM_FORMATION" ,
        HomeScene_ChangeCenterContainer_TeamFormation
    }

    return signals
end

function VigourRecoveryMeiator:ProcessSignal(signal )
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == SIGNALNAMES.Exploration_AddVigour_Callback then -- 使用恢复道具
        local datas = checktable(signal:GetBody())
        gameMgr:UpdateCardDataById(tonumber(datas.requestData.playerCardId), {vigour = tonumber(datas.vigour)})
        CommonUtils.DrawRewards({{goodsId = datas.requestData.goodsId, num = -datas.requestData.num}})
        --更新UI
        self:RefreshTeamViewFormation()
        --self:RefreshTeamFormation()

        local cardData = gameMgr:GetCardDataById(datas.requestData.playerCardId)
        CommonUtils.PlayCardSoundByCardId(cardData.cardId, SoundType.TYPE_ICEROOM_RANDOM, SoundChannel.CARD_FEED)


    elseif  name == SIGNALNAMES.Exploration_DiamondRecover_Callback  then
        local datas = checktable(signal:GetBody())
        -- 更新卡牌活力值
        for id, value in pairs(datas.newVigour) do
            gameMgr:UpdateCardDataById(tonumber(id), {vigour = tonumber(value)})

            local cardData = gameMgr:GetCardDataById(id)
            CommonUtils.PlayCardSoundByCardId(cardData.cardId, SoundType.TYPE_ICEROOM_RANDOM, SoundChannel.CARD_FEED, false)
        end
        gameMgr:GetUserInfo().diamond = datas.diamond
        self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = datas.diamond})
        --更新UI
        self:RefreshTeamViewFormation()
        --self:RefreshTeamFormation()


    elseif name ==  "CLOSE_TEAM_FORMATION" then
        self:GetFacade():DispatchObservers(TeamFormationScene_ChangeCenterContainer)

    elseif name == HomeScene_ChangeCenterContainer_TeamFormation then
        local viewData = self.viewComponent.viewData_
        local teamFormationDatas = gameMgr:GetUserInfo().teamFormation
        if table.nums(teamFormationDatas) ~= table.nums(viewData.dotDatas) then
            if viewData.dotLayout then
                viewData.dotLayout:runAction(cc.RemoveSelf:create())
            end
            local dotDatas = {}
            local dotLayout = CLayout:create(cc.size((table.nums(teamFormationDatas)*2-1)*20, 20))
            dotLayout:setPosition(cc.p(viewData.size.width/2, 320))
            viewData.view:addChild(dotLayout, 10)
            for i = 1, table.nums(teamFormationDatas) do
                local dot = display.newImageView(_res('ui/common/maps_fight_ico_round_default.png'), 10+(i-1)*40, 10)
                dotLayout:addChild(dot, 10)
                table.insert(dotDatas, i, dot)
            end
            viewData.dotDatas = dotDatas
            viewData.dotLayout = dotLayout
        end
        self:RefreshTeamSelectedState(self.selectedTeam)
        if  self.viewComponent then
            self.viewComponent:setVisible(true)
        end
    end
end

function VigourRecoveryMeiator:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    ---@type VigourRecoveryView
    local VigourRecoveryView  = require('Game.views.VigourRecoveryView').new({ moduleCallback = handler(self, self.TeamViewBtnCallback) })
    self.viewComponent = VigourRecoveryView
    display.commonUIParams(VigourRecoveryView, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    VigourRecoveryView:setTag(2001)
    scene:AddDialog(VigourRecoveryView)
    local viewData = VigourRecoveryView.viewData_
    viewData.switchBtnL:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
    viewData.switchBtnR:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
    viewData.changeBtn:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
    viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.TeamViewBtnCallback))
    viewData.quickRecoveryBtn:setOnClickScriptHandler(handler(self, self.RecoveryCallback))
    self:RefreshDiamondCost()
    local canClick = true
    VigourRecoveryView.eaterLayer:setOnClickScriptHandler(function( sender )
        if canClick then
            canClick = false
            if self.isRecovery then
                self.isRecovery = false
            end
            -- 添加点击音效
            PlayAudioByClickClose()
            local viewData = self:GetViewComponent().viewData_
            local view = VigourRecoveryView.viewData_.view
            scene:GetDialogByTag(2001):runAction(
            cc.Sequence:create(
            cc.TargetedAction:create(view, cc.EaseBackIn:create(cc.MoveTo:create(0.3, cc.p(display.cx, 0)))),
            cc.CallFunc:create(
                function ()
                    self:GetFacade():DispatchObservers("REFRESH_SELECT_TEAM" ,{ selectedTeamIdx =  self.selectedTeam} )
                    self:GetFacade():UnRegsitMediator(NAME)
                end
            )
            )
            )
        end
    end)
    -- 动作
    self:RefreshTeamSelectedState(self.selectedTeam)
    viewData.view:setPosition(cc.p(display.cx, 0))
    --viewData.view:runAction(cc.EaseBackOut:create(cc.MoveTo:create(0.3, cc.p(display.cx, 260))))
    self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self.viewComponent)
    self:RefreshCardVigour()
    self.viewComponent.viewData_.bottomLayout:setVisible(true)
    self.viewComponent.viewData_.view:runAction(cc.MoveTo:create(0.2, cc.p(display.cx, 560)))
    self.viewComponent.viewData_.dotLayout:runAction(cc.MoveTo:create(0.2, cc.p(display.cx, 290)))
    self.isRecovery = true
    self:RefreshDiamondCost()
end


--[[
刷新弹出界面编队信息
--]]
function VigourRecoveryMeiator:RefreshTeamViewFormation( )
    local view = self.viewComponent.viewData_.view
    local teamDatas = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
    for i = 2151, 2155 do
        if view:getChildByTag(i) then
            view:getChildByTag(i):runAction(cc.RemoveSelf:create())
        end
    end
    --添加头像
    local totalBattlePoint = 0
    for i,card in ipairs(teamDatas.cards) do
        if card.id then
            local cardHeadNode = require('common.CardHeadNode').new({id = checkint(card.id),
                showActionState = true})
            cardHeadNode:setPosition(cc.p(display.cx-330+(i-1)*165, 410))
            cardHeadNode:setScale(0.75)
            cardHeadNode:setTag(2150 + i)
            view:addChild(cardHeadNode, 10)
            -- 计算战斗力
            totalBattlePoint = totalBattlePoint + cardMgr.GetCardStaticBattlePointById(checkint(card.id))
        else
            local cardHeadBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'), display.cx-330+(i-1)*165, 410)
            cardHeadBg:setTag(2150 + i)
            cardHeadBg:setScale(0.75)
            view:addChild(cardHeadBg, 10)
            local cardHeadFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), cardHeadBg:getContentSize().width/2, cardHeadBg:getContentSize().height/2)
            cardHeadBg:addChild(cardHeadFrame)
        end
    end
    -- 刷新战斗力
    self.viewComponent.viewData_.battlePoint:setString(totalBattlePoint)
    -- 刷新新鲜度
    self:RefreshCardVigour()
    self:RefreshDiamondCost()
end


--[[
活力值幻晶石恢复
--]]
function VigourRecoveryMeiator:RecoveryCallback( sender )
    -- 添加点击音效
    PlayAudioByClickNormal()
    local scene = uiMgr:GetCurrentScene()
    local diamondCost = CommonUtils.GetTeamDiamondRecoverVigourCost(self.selectedTeam)
    if diamondCost == 0 then
        uiMgr:ShowInformationTips(__('新鲜度已满'))
    else
        if gameMgr:GetUserInfo().diamond >= diamondCost then
            local strs = string.split(string.fmt(__('是否消耗|_num_|幻晶石恢复当前编队飨灵新鲜度？'),{['_num_'] = diamondCost}), '|')
            local CommonTip  = require( 'common.NewCommonTip' ).new({richtext = {
                {text = strs[1], fontSize = 22, color = '#4c4c4c'},
                {text = strs[2], fontSize = 24, color = '#da3c3c'},
                -- {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.2},
                {text = strs[3], fontSize = 22, color = '#4c4c4c'}},
                isOnlyOK = false, callback = function ()
                    print('确定')
                    local teamFormationData = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
                    local cardstr = nil
                    for i,v in ipairs(teamFormationData.cards) do
                        if v.id then
                            if cardstr then
                                cardstr = string.format('%s,%s', cardstr, tostring(v.id))
                            else
                                cardstr = tostring(v.id)
                            end
                        end
                    end
                    self:SendSignal(COMMANDS.COMMAND_Exploration_DiamondRecover, {playerCardId = cardstr})
                end,
                cancelBack = function ()
                    print('返回')
                end})
            CommonTip:setPosition(display.center)
            scene:AddDialog(CommonTip)
        else
            if GAME_MODULE_OPEN.NEW_STORE then
                app.uiMgr:showDiamonTips()
            else
                local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
                    isOnlyOK = false, callback = function ()
                        app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
                    end})
                CommonTip:setPosition(display.center)
                app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
            end
        end
    end

end

--[[
刷新卡牌新鲜度
--]]
function VigourRecoveryMeiator:RefreshCardVigour()
    local teamFormationData = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
    local scene = uiMgr:GetCurrentScene()
    local viewData = self.viewComponent.viewData_
    local view = viewData.view
    local bottomLayout = viewData.bottomLayout
    for i,v in ipairs(VIGOUR_RECOVERY_GOODS_ID) do
        local numLabel = bottomLayout:getChildByTag(2700+i)
        local goodsNum = gameMgr:GetAmountByGoodId(v)
        numLabel:setString(tostring(goodsNum))
    end
    for i = 2161, 2165 do
        if view:getChildByTag(i) then
            view:getChildByTag(i):runAction(cc.RemoveSelf:create())
        end
    end
    for i,card in ipairs(teamFormationData.cards) do
        if card.id and checkint(card.id) ~= 0 then
            local cardData = gameMgr:GetCardDataById(card.id)
            local vigourView = CLayout:create(cc.size(156, 30))
            vigourView:setTag(2160+i)
            display.commonUIParams(vigourView, { po = cc.p(display.cx-330+(i-1)*165, 322)})
            view:addChild(vigourView, 10)
            local progressBG = display.newImageView(_res('avatar/ui/recovery_bg.png'), vigourView:getContentSize().width/2, vigourView:getContentSize().height/2, {
                scale9 = true, size = cc.size(156, 28)
            })
            vigourView:addChild(progressBG, 2)
            local maxVigour = app.restaurantMgr:getCardVigourLimit(card.id)
            local ratio = (checkint(cardData.vigour) / maxVigour)* 100
            local color = nil
            if ratio >=0 and ratio <= 29 then
                color = 'red'
            elseif ratio >=30 and ratio <= 60 then
                color = 'yellow'
            elseif ratio >=60 then
                color = 'green'
            else
                color = 'green'
            end
            local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_' .. color .. '.png'))
            operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
            operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
            operaProgressBar:setAnchorPoint(cc.p(0, 0.5))
            operaProgressBar:setMaxValue(100)
            operaProgressBar:setValue(ratio)
            operaProgressBar:setPosition(cc.p(6, vigourView:getContentSize().height/2))
            vigourView:addChild(operaProgressBar, 5)
            local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
            vigourProgressBarTop:setAnchorPoint(cc.p(0,0.5))
            vigourProgressBarTop:setPosition(cc.p(2, vigourView:getContentSize().height/2))
            vigourView:addChild(vigourProgressBarTop,6)

            local vigourLabel = display.newLabel(operaProgressBar:getContentSize().width + 22, operaProgressBar:getPositionY()+1,{
                ap = cc.p(0.5, 0.5), fontSize = 18, color = 'ffffff', text = math.ceil(checkint(cardData.vigour)/maxVigour * 10000) /100  .. "%"
            })
            vigourView:addChild(vigourLabel, 6)
        end
    end
end
--[[
编队页面按钮回调
--]]
function VigourRecoveryMeiator:TeamViewBtnCallback( sender )
    -- 添加点击音效
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == BTN_TAG.CHANGE_TEAM then -- 调整队伍
        self.viewComponent:setVisible(false)
        local TeamFormationMediator = require( 'Game.mediator.TeamFormationMediator')
        local mediator = TeamFormationMediator.new({isCommon = true,jumpTeamIndex = self.selectedTeam})
        self:GetFacade():RegistMediator(mediator)
    elseif tag == BTN_TAG.MOUDLE_GOTO  then -- 探索
        -- 判断新鲜度是否足够
        local teamFormationData = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
        local teamCards = 0 -- 队伍卡牌数目

        for i,card in ipairs(teamFormationData.cards) do
            if card.id then
                teamCards = teamCards + 1
                local cardData = gameMgr:GetCardDataById(card.id)
                if self.floorNum  == 1 then -- 只有当层数为1的时候才会进行编队互斥判断
                    ------------ 互斥判断 ------------
                    local ifMutex, placeId = gameMgr:CanSwitchCardStatus(
                    {id = card.id},
                    CARDPLACE.PLACE_EXPLORATION
                    )

                    local ifMutex1, placeId1 = gameMgr:CanSwitchCardStatus(
                    {id = card.id},
                    CARDPLACE.PLACE_EXPLORE_SYSTEM
                    )
                    if (false == ifMutex and placeId) or (false == ifMutex1 and placeId1) then
                        -- 互斥
                        local placeName = gameMgr:GetModuleName(placeId or placeId1)
                        uiMgr:ShowInformationTips(string.format(__('您的队伍正在%s, 不能出战'), tostring(placeName)))
                        return
                    end
                    ------------ 互斥判断 ------------
                end
            end
        end
        if teamCards == 0 then
            uiMgr:ShowInformationTips(__('队伍不能为空'))
            return
        end
        if app.restaurantMgr:HasEnoughVigourToExplore(self.selectedTeam,self.vigourCost) then
            -------------屏蔽按钮点击事件------------
            --TODO  这个地方做的是前往模块
            if self.type == RECOVER_TAKEAWAY_TYPE then

                self:GetFacade():DispatchObservers("SENDER_TAKEAWAY_ORDER", {selectedTeamIdx = self.selectedTeam})
                self:GetFacade():UnRegsitMediator(NAME)
            end
        else
            uiMgr:ShowInformationTips(__('队伍新鲜度不足'))
        end

    elseif tag == BTN_TAG.PRE_TEAM_BTN then -- 上翻
        self:RefreshTeamSelectedState(math.max(1, self.selectedTeam - 1))
    elseif tag == BTN_TAG.NEXT_TEAM_BTM then -- 下翻
        self:RefreshTeamSelectedState(math.min(table.nums(gameMgr:GetUserInfo().teamFormation), self.selectedTeam + 1))
    elseif tag == BTN_TAG.TIPS_BTN then -- 提示

        local scene = uiMgr:GetCurrentScene()
        local worldPos = self.viewComponent.viewData_.view:convertToWorldSpace(cc.p(sender:getPositionX(), sender:getPositionY()))
        local pos = cc.p(worldPos.x, worldPos.y + 30)
        local tipsView = require("home.ExplorationVigourTipsView").new({teamId = self.selectedTeam, teamVigourCost = self.vigourCost, pos = pos})
        scene:AddDialog(tipsView)
    end
end
--[[
刷新选中状态
--]]
function VigourRecoveryMeiator:RefreshTeamSelectedState( index )
    local scene = uiMgr:GetCurrentScene()
    local explorationTeamView = scene:GetDialogByTag(2001)
    local viewData = explorationTeamView.viewData_
    -- 刷新选中状态
    local preCircle = viewData.dotDatas[self.selectedTeam]
    if preCircle then
        preCircle:setTexture(_res('ui/common/maps_fight_ico_round_default.png'))
    end
    local curCircle = viewData.dotDatas[index]
    if curCircle then
        curCircle:setTexture(_res('ui/common/maps_fight_ico_round_select.png'))
    end

    if table.nums(gameMgr:GetUserInfo().teamFormation) <= 1 then
        viewData.switchBtnL:setVisible(false)
        viewData.switchBtnR:setVisible(false)
    elseif index == 1 then
        viewData.switchBtnL:setVisible(false)
        viewData.switchBtnR:setVisible(true)
    elseif index == table.nums(gameMgr:GetUserInfo().teamFormation) then
        viewData.switchBtnL:setVisible(true)
        viewData.switchBtnR:setVisible(false)
    else
        viewData.switchBtnL:setVisible(true)
        viewData.switchBtnR:setVisible(true)
    end
    self.selectedTeam = index
    -- 刷新队伍信息
    viewData.teamNameLabel:setString(string.format(__('队伍%d'), self.selectedTeam))
    self:RefreshTeamViewFormation()
end
function VigourRecoveryMeiator:RefreshDiamondCost(  )
    if self.viewComponent then
        local diamondCost = CommonUtils.GetTeamDiamondRecoverVigourCost(self.selectedTeam)
        self.viewComponent.viewData_.diamondNum:setString(tostring(diamondCost))
    end
end
function VigourRecoveryMeiator:onTouchBegan_(touch, event)
    local point = touch:getLocation()
    local goodsDatas = self.viewComponent.viewData_.goodsDatas
    for i,icon in pairs(goodsDatas) do
        if cc.rectContainsPoint(icon:getBoundingBox(), point) then
            self.selectedGoods = i
            if gameMgr:GetAmountByGoodId(VIGOUR_RECOVERY_GOODS_ID[i]) > 0 then
                return true
            else
                return false
            end
        end
    end
end
function VigourRecoveryMeiator:RefreshTeamFormation()
    local viewData = self:GetViewComponent().viewData_
    viewData.bottomLayout:setVisible(true)
    if viewData.bottomLayout:getChildByTag(5555) then
        viewData.bottomLayout:getChildByTag(5555):runAction(cc.RemoveSelf:create())
    end
    local data = gameMgr:GetUserInfo().teamFormation[self.selectedTeam]
    local layout = CLayout:create(cc.size(600, 100))
    layout:setTag(5555)
    viewData.bottomLayout:addChild(layout, 10)
    layout:setPosition(cc.p(viewData.bottomLayout:getContentSize().width/2, 80))
    --for i,card in ipairs(data.cards) do
    --    if card.id then
    --        local cardHeadNode = require('common.CardHeadNode').new({id = checkint(card.id),
    --            showActionState = false, })
    --        cardHeadNode:setScale(0.55)
    --        cardHeadNode:setPosition(cc.p(80+(i-1)*110, 50))
    --        layout:addChild(cardHeadNode, 10)
    --    else
    --        local cardHeadBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'), 80+(i-1)*110, 50)
    --        cardHeadBg:setScale(0.55)
    --        layout:addChild(cardHeadBg, 10)
    --        local cardHeadFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), cardHeadBg:getContentSize().width/2, cardHeadBg:getContentSize().height/2)
    --        cardHeadBg:addChild(cardHeadFrame)
    --    end
    --end
end
function VigourRecoveryMeiator:onTouchMoved_(touch, event)

    local view = self.viewComponent.viewData_.view
    if view:getChildByTag(2222) then
        view:getChildByTag(2222):setPosition(touch:getLocation())
    else
        local icon = display.newImageView(_res('arts/goods/goods_icon_' .. tostring(VIGOUR_RECOVERY_GOODS_ID[self.selectedGoods]) .. '.png'), touch:getLocation().x, touch:getLocation().y, {tag = 2222})
        view:addChild(icon, 15)
    end
end
function VigourRecoveryMeiator:onTouchEnded_(touch, event)
    local view = self.viewComponent.viewData_.view

    local point = touch:getLocation()
    for i = 2150, 2155 do
        if view:getChildByTag(i) then
            if cc.rectContainsPoint(view:getChildByTag(i):getBoundingBox(), point) then
                local cardId = gameMgr:GetUserInfo().teamFormation[self.selectedTeam].cards[i- 2150].id
                if cardId and cardId ~= '' then
                    local cardData = gameMgr:GetCardDataById(cardId)
                    local maxVigour = app.restaurantMgr:getCardVigourLimit(cardData.id)
                    if checkint(cardData.vigour) >= checkint(maxVigour) then
                        uiMgr:ShowInformationTips(__("此飨灵活力值已满"))
                    else
                        httpManager:Post("backpack/cardVigourMagicFoodRecover",SIGNALNAMES.Exploration_AddVigour_Callback,{ playerCardId = cardId, goodsId = VIGOUR_RECOVERY_GOODS_ID[self.selectedGoods],num = 1})
                    end
                end
            end
        end
    end

    if view:getChildByTag(2222) then
        view:getChildByTag(2222):runAction(cc.RemoveSelf:create())
    end
    self.selectedGoods = nil
end

--[[
显示编队界面
--]]
function VigourRecoveryMeiator:ShowTeamFormation(jumpTeamIndex)
    local TeamFormationMediator = require( 'Game.mediator.TeamFormationMediator')
    local mediator = TeamFormationMediator.new({isCommon = true,jumpTeamIndex = jumpTeamIndex})
    self:GetFacade():RegistMediator(mediator)
    self.teamMediator = mediator
    self:ShowStartDeliveryOrderView(false)
end
function VigourRecoveryMeiator:OnRegist(  )
    local ExplorationChooseCommand = require('Game.command.ExplorationChooseCommand')
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_DiamondRecover, ExplorationChooseCommand)
end

function VigourRecoveryMeiator:OnUnRegist(  )
    if self.touchListener_ then
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:removeEventListener(self.touchListener_)
    end
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_DiamondRecover)
    if self.viewComponent and ( not  tolua.isnull(self.viewComponent)) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return VigourRecoveryMeiator

