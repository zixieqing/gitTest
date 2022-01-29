--[[
    燃战助战Mediator
--]]
local Mediator              = mvc.Mediator
---@class SaiMoeSupportMediator:Mediator
local SaiMoeSupportMediator = class("SaiMoeSupportMediator", Mediator)

local NAME                  = "saimoe.SaiMoeSupportMediator"

local shareFacade           = AppFacade.GetInstance()
---@type UIManager
local uiMgr                 = shareFacade:GetManager("UIManager")
local gameMgr               = app.gameMgr

local RES_DICT              = {
    COMMON_BTN_ORANGE         = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_ORANGE_DISABLE = _res('ui/common/common_btn_orange_disable.png'),
    DIALOGUE_BG               = _res('arts/stage/ui/dialogue_bg_2.png'),
    STARPLAN_HOMEPAGE_BTN_FIGHT2    = _res('ui/home/activity/saimoe/starplan_homepage_btn_fight2.png'),
}

local SUPPORT_REWARD_STATE  = {
    UNREACHED = 0,
    AVAILABLE = 1,
    MAX       = 2
}

function SaiMoeSupportMediator:ctor(params, viewComponent)
    self.super:ctor(NAME, viewComponent)
    self.datas = checktable(params) or {}
end

function SaiMoeSupportMediator:InterestSignals()
    local signals = {
        COUNT_DOWN_ACTION,
        SUPPORT_ITEM_SELECTED_EVENT,
        SAIMOE_SWEEP_POPUP_SHOWUP_EVENT,
        POST.SAIMOE_DONATION.sglName,
        POST.SAIMOE_DRAW_POINT_REWARD.sglName,
        POST.SAIMOE_BUY_HP.sglName,
        POST.SAIMOE_CLOSE_SHOP.sglName,
        'SAIMOE_SHOPPING',
        'QUEST_SWEEP_OVER',
        EVENT_PAY_MONEY_SUCCESS_UI,
    }

    return signals
end

function SaiMoeSupportMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    -- dump(body, name)
    if name == COUNT_DOWN_ACTION then
        local timerName = body.timerName
        if timerName == 'SAIMOE' then
            self:UpdateCountDown(body.countdown)
        end
    elseif name == SUPPORT_ITEM_SELECTED_EVENT then
        self:SendSignal(POST.SAIMOE_DONATION.cmdName, body)
    elseif name == SAIMOE_SWEEP_POPUP_SHOWUP_EVENT then
        local stageId = checkint(self.playerConf.questId[1])
        local tag     = 4001
        local layer   = require('Game.views.SweepPopup').new({
            tag                 = tag,
            stageId             = stageId,
            canSweepCB          = handler(self, self.CanSweepCallback),
            sweepRequestCommand = POST.SAIMOE_SWEEP.cmdName,
            sweepResponseSignal = POST.SAIMOE_SWEEP.sglName
        })
        display.commonUIParams(layer, { ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5) })
        layer:setTag(tag)
        layer:setName('SweepPopup')
        uiMgr:GetCurrentScene():AddDialog(layer)
    elseif name == POST.SAIMOE_DONATION.sglName then
        local goodsId = body.requestData.goodsId
        local num     = body.requestData.num
        CommonUtils.DrawRewards({ { goodsId = goodsId, num = -num } })

        local value      = checkint(self.playerConf.goodsPoints[tostring(goodsId)]) * num
        self.datas.point = self.datas.point and (checkint(self.datas.point) + value) or value
        self.datas.groupScore[tostring(self.datas.supportGroupId)] = checkint(self.datas.groupScore[tostring(self.datas.supportGroupId)]) + value

        --uiMgr:ShowInformationTips(__('应援成功'))
        local viewData = self:GetViewComponent().viewData
        viewData.votesLabel:setString(self.datas.point or 0)
        self:CheckSupportItem()
        self:UpdateBox(self:CheckSupportReward())

        local function ShowDialogue()
            if viewData.view:getChildByTag(6000) then
                viewData.view:getChildByTag(6000):removeFromParent()
            end
            local bubbleLines        = CommonUtils.GetConfigAllMess('bubbleLines', 'cardComparison')
            local startup = self.datas.supportGroupId == 1 and 0 or (table.nums(bubbleLines) / 2)
            local text = ''
            for i = table.nums(bubbleLines) / 2 + startup, 1+startup, -1 do
                if checkint(self.datas.point) >= checkint(bubbleLines[tostring(i)].effectPoint) then
                    text = bubbleLines[tostring(i)].message
                    break
                end
            end
            local time = utf8len(text) / 20
            local dialogBg = display.newImageView(RES_DICT.DIALOGUE_BG, 367 + display.SAFE_L, display.cy - 150, {tag = 6000})
            viewData.view:addChild(dialogBg, 10)
            dialogBg:setScale(0.5)
            dialogBg:runAction(
                    cc.Sequence:create(
                            cc.EaseBackOut:create(cc.ScaleTo:create(0.3, 1)),
                            cc.CallFunc:create(function ()
                                local dialogLabel = display.newLabel(70, 140, {ap = cc.p(0, 1), text = text, fontSize = 24, color = '#5b3c25', w = 384})
                                dialogBg:addChild(dialogLabel)
                                dialogLabel:setVisible(false)
                                dialogLabel:runAction(
                                        cc.Sequence:create(
                                                TypewriterAction:create(time),
                                                cc.DelayTime:create(1),
                                                cc.CallFunc:create(function ()
                                                    dialogLabel:setVisible(true)
                                                    dialogBg:runAction(cc.RemoveSelf:create())
                                                end)
                                        )
                                )
                            end)
                    )
            )
        end
        local animationName = 'play3'
        if checkint(goodsId) == 880079 then
            animationName = 'play3'
            PlayAudioClip(AUDIOS.AMB.Ty_gaoji.id)
        elseif checkint(goodsId) == 880095 then
            animationName = 'play1'
            PlayAudioClip(AUDIOS.AMB.Ty_diji.id)
        elseif checkint(goodsId) == 880096 then
            animationName = 'play2'
            PlayAudioClip(AUDIOS.AMB.Ty_diji.id)
        end
        viewData.aniLayer:setVisible(true)
        viewData.supportAni:setAnimation(0, animationName, false)
        viewData.supportAni:registerSpineEventHandler(function ( event )
            if event.animation == animationName then
                viewData.supportAni:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
                viewData.aniLayer:setVisible(false)
                ShowDialogue()
            end
        end, sp.EventType.ANIMATION_END)
    elseif name == POST.SAIMOE_DRAW_POINT_REWARD.sglName then
        uiMgr:AddDialog('common.RewardPopup', { rewards = body.rewards, addBackpack = true })

        table.insert(self.datas.pointRewards, body.requestData.pointId)
        self.drawRewards[tostring(body.requestData.pointId)] = true
        self:UpdateBox(self:CheckSupportReward())
    elseif name == POST.SAIMOE_BUY_HP.sglName then
        local questHpPrice        = CommonUtils.GetConfigAllMess('questHpPrice', 'cardComparison')
        local priceId             = table.nums(questHpPrice) - checkint(self.datas.remainBuyTimes) + 1
        local price               = questHpPrice[tostring(priceId)] or {}
        self.datas.questHp        = checkint(self.datas.questHp) + checkint(price.questHp)
        self.datas.remainBuyTimes = checkint(self.datas.remainBuyTimes) - 1

        -- 扣除钻石
        local diamonNum           = checkint(body.diamond)
        local ownerDiamond        = CommonUtils.GetCacheProductNum(DIAMOND_ID)
        CommonUtils.DrawRewards({ { goodsId = DIAMOND_ID, num = (diamonNum - ownerDiamond) } })

        self.moneyNodes[tostring(DIAMOND_ID)]:updataUi(DIAMOND_ID)
        self.moneyNodes[tostring(SAIMOE_POWER_ID)]:updataUi(SAIMOE_POWER_ID)
        uiMgr:ShowInformationTips(__('应援力购买成功'))
    elseif name == POST.SAIMOE_CLOSE_SHOP.sglName then
        self:CheckRedPoint()
    elseif name == 'SAIMOE_SHOPPING' then
        self:CheckSupportItem()
    elseif name == 'QUEST_SWEEP_OVER' then
        local data = body.responseData
        local stageId      = checkint(self.playerConf.questId[1])
        local consumeHp    = tonumber(CommonUtils.GetQuestConf(checkint(stageId)).consumeGoodsLoseNum)
        self.datas.questHp = self.datas.questHp - consumeHp * data.requestData.times
        self.moneyNodes[tostring(SAIMOE_POWER_ID)]:updataUi(SAIMOE_POWER_ID)
        self:CheckSupportItem()
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        if next(self.moneyNodes or {}) then
            if self.moneyNodes[tostring(DIAMOND_ID)] then
                self.moneyNodes[tostring(DIAMOND_ID)]:updataUi(DIAMOND_ID)
            end
        end
    end
end

function SaiMoeSupportMediator:Initial(key)
    self.super.Initial(self, key)
    local scene         = uiMgr:GetCurrentScene()
    local viewComponent = require('Game.views.saimoe.SaiMoeSupportView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData

    local supportGroupId = self.datas.supportGroupId
    local playerConf     = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]
    self.playerConf      = playerConf
    -- viewData.drawNode:RefreshAvatar({ cardId = playerConf.cardId })
    viewData.drawNode:RefreshAvatar({ skinId = CardUtils.GetCardSkinId(playerConf.cardId) })
    if checkint(playerConf.cardId) == 200020 then
        viewData.drawNode.avatar:setPosition(cc.p(display.SAFE_L - 40,display.cy - 325))
    elseif checkint(playerConf.cardId) == 200002 then
        viewData.drawNode.avatar:setPositionX(display.SAFE_L + 36)
    end

    viewData.tipsBtn:setOnClickScriptHandler(function( sender )
        PlayAudioClip(AUDIOS.UI.ui_window_open.id)

        uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.SAIMOE_MAIN})
    end)
    viewData.voteResultBtn:setOnClickScriptHandler(handler(self, self.VoteResultBtnClickHandler))
    viewData.normalBattleBtn:setOnClickScriptHandler(handler(self, self.NormalBattleBtnClickHandler))
    viewData.bossBattleBtn:setOnClickScriptHandler(handler(self, self.BossBattleBtnClickHandler))
    viewData.activitySupportBtn:setOnClickScriptHandler(handler(self, self.SupportBtnClickHandler))
    viewData.exclusiveSupportBtn:setOnClickScriptHandler(handler(self, self.SupportBtnClickHandler))
    self:CheckSupportItem()
    if 1 == checkint(self.datas.supportGroupId) then
        viewData.normalBattleBtn:setNormalImage(RES_DICT.STARPLAN_HOMEPAGE_BTN_FIGHT2)
        viewData.normalBattleBtn:setSelectedImage(RES_DICT.STARPLAN_HOMEPAGE_BTN_FIGHT2)
    end

    viewData.votesLabel:setString(self.datas.point or 0)

    viewData.clickLayer:setOnClickScriptHandler(handler(self, self.PreviewBtnClickHandle))
    viewData.rankingBtn:setOnClickScriptHandler(handler(self, self.RankingBtnClickHandle))

    self.drawRewards = {}
    for i, v in pairs(self.datas.pointRewards) do
        self.drawRewards[tostring(v)] = true
    end
    self:UpdateBox(self:CheckSupportReward())

    local stageId = checkint(playerConf.questId[1])
    local requestData = self.datas.requestData or {}
    local isFirst = requestData.isFirst or 0
    -- 第一次通关小怪关
    if 1 == isFirst and self.datas.quests[tostring(stageId)] then
        viewData.bottomBGL:setContentSize(cc.size(1081, 113))
        viewData.bossBtnBG:setVisible(true)
        viewData.bossBattleBtn:setVisible(false)

        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(cc.p(display.cx, display.cy))
        viewComponent:addChild(eaterLayer, 1000)

        viewData.unlockAni:setAnimation(0, 'idle', false)
        viewData.unlockAni:registerSpineEventHandler(function ( event )
            if event.animation == 'idle' then
                viewData.unlockAni:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
                eaterLayer:runAction(cc.RemoveSelf:create())
                viewData.bossBattleBtn:setVisible(true)
                viewData.unlockAni:setVisible(false)
            end
        end, sp.EventType.ANIMATION_END)
    else
        if self.datas.quests[tostring(stageId)] then
            viewData.bottomBGL:setContentSize(cc.size(1081, 113))
            viewData.bossBattleBtn:setVisible(true)
            viewData.bossBtnBG:setVisible(true)
        else
            viewData.bottomBGL:setContentSize(cc.size(1390, 113))
            viewData.bossBattleBtn:setVisible(false)
            viewData.bossBtnBG:setVisible(false)

            local spinePath = 'effects/shangdian'
            if not SpineCache(SpineCacheName.GLOBAL):hasSpineCacheData(spinePath) then
                SpineCache(SpineCacheName.GLOBAL):addCacheData(spinePath, spinePath, 1)
            end
            local buttonSpine = SpineCache(SpineCacheName.GLOBAL):createWithName(spinePath)
            buttonSpine:setPosition(76, 54)
            buttonSpine:setScale(1.4)
            buttonSpine:setAnimation(0, 'idle', true)
            viewData.normalBattleBtn:addChild(buttonSpine)
        end
        viewData.unlockAni:setVisible(false)
    end
    local openShop = requestData.openShop or 0
    if 1 == openShop then
        local SaiMoeBossMediator = require('Game.mediator.saimoe.SaiMoeBossMediator')
        local mediator           = SaiMoeBossMediator.new(self.datas)
        self:GetFacade():RegistMediator(mediator)
    end
    self:CheckRedPoint()
    self:UpdateCountDown(gameMgr:GetUserInfo().comparisonActivityTime)
end

function SaiMoeSupportMediator:CheckRedPoint()
    local isComposable = true
    if checkint(self.datas.isBossMapOpen) == 1 then
        isComposable = false
    elseif next(self.datas.shopList or {}) then
        isComposable = false
    else
        local supportGroupId = self.datas.supportGroupId
        local playerConf = CommonUtils.GetConfigAllMess('comparisonInfo', 'cardComparison')[tostring(supportGroupId)]
        for i,v in ipairs(playerConf.map) do
            local amount = gameMgr:GetAmountByGoodId(v)
            if 0 >= amount then
                isComposable = false
                break
            end
        end
    end
    shareFacade:DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.SAIMOE_COMPOSABLE, isComposable = isComposable })
end
--[[
判断是否可以扫荡
--]]
function SaiMoeSupportMediator:CanSweepCallback(stageId, times)
    local consumeHp = tonumber(CommonUtils.GetQuestConf(checkint(stageId)).consumeGoodsLoseNum)
    if self.datas.quests[tostring(stageId)] then
        if self.datas.questHp >= consumeHp * times then
            return true
        else
            uiMgr:ShowInformationTips(__("应援力不足"))
        end
    else
        uiMgr:ShowInformationTips(__("通关关卡才可开启扫荡功能"))
    end
end

function SaiMoeSupportMediator:UpdateCountDown(countdown)
    local viewData = self.viewComponent.viewData
    if countdown <= 0 then
        self:CheckSupportItem()
        display.reloadRichLabel(viewData.timeLabel , { c = {
            {
                text = __('已结束'),
                fontSize = 22,
                color = '#ffffff',
            }
        }})
    else
        if checkint(countdown) <= 86400 then
            display.reloadRichLabel(viewData.timeLabel , {width = 340 , c = {
                {
                    text = __('比赛剩余时间：'),
                    fontSize = 22,
                    color = '#ffffff',
                },
                {
                    text = string.formattedTime(checkint(countdown), '%02i:%02i:%02i'),
                    fontSize = 28,
                    color = '#ffd042',
                }
            }})
        else
            local day  = math.floor(checkint(countdown) / 86400)
            local hour = math.floor((countdown - day * 86400) / 3600)
            display.reloadRichLabel(viewData.timeLabel , {width = 340 ,  c = {
                {
                    text = __('比赛剩余时间：'),
                    fontSize = 22,
                    color = '#ffffff',
                },
                {
                    text = string.fmt(__('_day_天_hour_小时'), { _day_ = day, _hour_ = hour }),
                    fontSize = 28,
                    color = '#ffd042',
                }
            }})
        end
    end


end

function SaiMoeSupportMediator:CheckSupportItem()
    local viewData   = self:GetViewComponent().viewData
    local playerConf = self.playerConf
    viewData.activityItem:RefreshSelf({ goodsId = playerConf.goodsId[1], amount = CommonUtils.GetCacheProductNum(playerConf.goodsId[1]), showAmount = true })
    viewData.exclusiveItem:RefreshSelf({ goodsId = playerConf.goodsId[2], amount = CommonUtils.GetCacheProductNum(playerConf.goodsId[2]), showAmount = true })

    if gameMgr:GetUserInfo().comparisonActivityTime <= 0 then
        viewData.activitySupportBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
        viewData.activitySupportBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
        viewData.exclusiveSupportBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
        viewData.exclusiveSupportBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
        return
    end

    viewData.activitySupportBtn:setNormalImage(0 < gameMgr:GetAmountByGoodId(playerConf.goodsId[1]) and RES_DICT.COMMON_BTN_ORANGE or RES_DICT.COMMON_BTN_ORANGE_DISABLE)
    viewData.activitySupportBtn:setSelectedImage(0 < gameMgr:GetAmountByGoodId(playerConf.goodsId[1]) and RES_DICT.COMMON_BTN_ORANGE or RES_DICT.COMMON_BTN_ORANGE_DISABLE)
    viewData.exclusiveSupportBtn:setNormalImage(0 < gameMgr:GetAmountByGoodId(playerConf.goodsId[2]) and RES_DICT.COMMON_BTN_ORANGE or RES_DICT.COMMON_BTN_ORANGE_DISABLE)
    viewData.exclusiveSupportBtn:setSelectedImage(0 < gameMgr:GetAmountByGoodId(playerConf.goodsId[2]) and RES_DICT.COMMON_BTN_ORANGE or RES_DICT.COMMON_BTN_ORANGE_DISABLE)
end

function SaiMoeSupportMediator:UpdateBox(state)
    local viewData = self:GetViewComponent().viewData
    if state == SUPPORT_REWARD_STATE.UNREACHED then
        if 'stop' ~= viewData.rewardBox:getCurrent() then
            viewData.rewardBox:setAnimation(0, 'stop', true)
        end
    elseif state == SUPPORT_REWARD_STATE.AVAILABLE then
        if 'idle' ~= viewData.rewardBox:getCurrent() then
            viewData.rewardBox:setAnimation(0, 'idle', true)
        end
    elseif state == SUPPORT_REWARD_STATE.MAX then
        if 'stop' ~= viewData.rewardBox:getCurrent() then
            viewData.rewardBox:setAnimation(0, 'stop', true)
        end
    end
end

function SaiMoeSupportMediator:CheckSupportReward()
    local pointRewards = CommonUtils.GetConfigAllMess('pointRewards', 'cardComparison')[tostring(self.datas.supportGroupId)]
    local isAllDrawn = true
    for i, v in pairs(pointRewards) do
        if checkint(v.num) <= checkint(self.datas.point) then
            isAllDrawn = false
            if not self.drawRewards[tostring(v.id)] then
                return SUPPORT_REWARD_STATE.AVAILABLE
            end
        else
            isAllDrawn = false
        end
    end
    if isAllDrawn then
        return SUPPORT_REWARD_STATE.MAX
    else
        return SUPPORT_REWARD_STATE.UNREACHED
    end
end

function SaiMoeSupportMediator:VoteResultBtnClickHandler(sender)
    PlayAudioByClickNormal()

    local SaiMoePlatformMediator = require('Game.mediator.saimoe.SaiMoePlatformMediator')
    local mediator               = SaiMoePlatformMediator.new(self.datas)
    self:GetFacade():RegistMediator(mediator)
end

function SaiMoeSupportMediator:RankingBtnClickHandle(sender)
    PlayAudioByClickNormal()

    shareFacade:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'saimoe.SaiMoeRankMediator'})
end

function SaiMoeSupportMediator:NormalBattleBtnClickHandler(sender)
    PlayAudioByClickNormal()

    if gameMgr:GetUserInfo().comparisonActivityTime <= 0 then
        uiMgr:ShowInformationTips(__('活动已结束，记得领奖'))
        return
    end

    local playerConf      = self.playerConf
    local stageId         = checkint(playerConf.questId[1])
    -- 显示编队界面
    local battleReadyData = BattleReadyConstructorStruct.New(
            2,
            gameMgr:GetUserInfo().localCurrentBattleTeamId,
            nil,
            stageId,
            CommonUtils.GetQuestBattleByQuestId(stageId),
            nil,
            POST.SAIMOE_QUEST_AT.cmdName,
            { questId = stageId, isFirst = self.datas.quests[tostring(stageId)] and 0 or 1 },
            POST.SAIMOE_QUEST_AT.sglName,
            POST.SAIMOE_QUEST_GRADE.cmdName,
            { questId = stageId },
            POST.SAIMOE_QUEST_GRADE.sglName,
            NAME,
            NAME
    )
    local layer           = require('Game.views.saimoe.SaiMoeBattleReadyView').new(battleReadyData)
    layer:setPosition(cc.p(display.cx, display.cy))
    uiMgr:GetCurrentScene():AddDialog(layer)

    self.moneyNodes = layer:AddTopCurrency({ SAIMOE_POWER_ID, DIAMOND_ID }, self.datas)
end

function SaiMoeSupportMediator:BossBattleBtnClickHandler(sender)
    PlayAudioByClickNormal()

    if gameMgr:GetUserInfo().comparisonActivityTime <= 0 then
        uiMgr:ShowInformationTips(__('活动已结束，记得领奖'))
        return
    end

    local SaiMoeBossMediator = require('Game.mediator.saimoe.SaiMoeBossMediator')
    local mediator           = SaiMoeBossMediator.new(self.datas)
    self:GetFacade():RegistMediator(mediator)
end

function SaiMoeSupportMediator:SupportBtnClickHandler(sender)
    if gameMgr:GetUserInfo().comparisonActivityTime <= 0 then
        PlayAudioByClickNormal()
        uiMgr:ShowInformationTips(__('活动已结束，记得领奖'))
        return
    end
    local tag     = sender:getTag()
    local goodsId = self.playerConf.goodsId[tag]
    if 0 < gameMgr:GetAmountByGoodId(goodsId) then
        local scene              = uiMgr:GetCurrentScene()
        local SaiMoeSupportPopup = require('Game.views.SaiMoeSupportPopup').new({ tag = 6633, btnTag = tag, mediatorName = NAME, data = self.playerConf })
        display.commonUIParams(SaiMoeSupportPopup, { ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5) })
        scene:AddDialog(SaiMoeSupportPopup)
    else
        PlayAudioByClickNormal()
        uiMgr:ShowInformationTips(__('应援道具不足'))
    end
end

function SaiMoeSupportMediator:PreviewBtnClickHandle(sender)
    PlayAudioByClickNormal()

    local SaiMoeRewardMediator = require('Game.mediator.saimoe.SaiMoeRewardMediator')
    local mediator           = SaiMoeRewardMediator.new(self.datas)
    self:GetFacade():RegistMediator(mediator)
end

function SaiMoeSupportMediator:OnRegist()
    regPost(POST.SAIMOE_DONATION)
    regPost(POST.SAIMOE_DRAW_POINT_REWARD)
    regPost(POST.SAIMOE_BUY_HP)
    regPost(POST.SAIMOE_SWEEP)
end

function SaiMoeSupportMediator:OnUnRegist()
    unregPost(POST.SAIMOE_DONATION)
    unregPost(POST.SAIMOE_DRAW_POINT_REWARD)
    unregPost(POST.SAIMOE_BUY_HP)
    unregPost(POST.SAIMOE_SWEEP)
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveGameLayer(self.viewComponent)
end

return SaiMoeSupportMediator