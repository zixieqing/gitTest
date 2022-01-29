local Mediator = mvc.Mediator

local FishermanFeedMediator = class("FishermanFeedMediator", Mediator)

local NAME = "FishermanFeedMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = shareFacade:GetManager("UIManager")
local socketMgr = shareFacade:GetManager('SocketManager')
local gameMgr = shareFacade:GetManager("GameManager")
local cardMgr = shareFacade:GetManager("CardManager")

function FishermanFeedMediator:ctor( data, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.data = data
end

function FishermanFeedMediator:InterestSignals()
	local signals = {
        SIGNALNAMES.Exploration_AddVigour_Callback,
        POST.FISHPLACE_CALLBACK.sglName ,
	}
	return signals
end

function FishermanFeedMediator:ProcessSignal(signal )
	local name = signal:GetName()
    local body = signal:GetBody()
    -- dump(body)
    if name == SIGNALNAMES.Exploration_AddVigour_Callback then
        --喂食卡牌
        local id = body.requestData.playerCardId
        local goodsId = body.requestData.goodsId
        local vigour = checkint(body.vigour)
        --更新道具数量本地缓存
        local card = gameMgr:GetCardDataById(id)
        gameMgr:UpdateCardDataById(id,{vigour = vigour})
        CommonUtils.DrawRewards({{goodsId = goodsId, num = -1}})
        --更新喂食面板
        self:GetViewComponent():UpdateVigour(card.id,vigour) --更新喂后的活力值新鲜度

        --更新活动值人物状态
        local foodView = self.viewComponent:getChildByTag(8888)
        if foodView then
            foodView:FreshData() --刷新列表的逻辑
        end
        shareFacade:DispatchObservers(FISHERMAN_VIGOUR_RECOVER_EVENT, body)
        CommonUtils.PlayCardSoundByCardId(card.cardId, SoundType.TYPE_ICEROOM_RANDOM, SoundChannel.CARD_FEED)
    elseif name == POST.FISHPLACE_CALLBACK.sglName then
        shareFacade:DispatchObservers(FISHERMAN_RECALL_EVENT, body)
        shareFacade:UnRegsitMediator(NAME)
    end
end

function FishermanFeedMediator:Initial( key )
	self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.fishing.FishermanFeedView' ).new(self.data)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)

    local viewData = viewComponent.viewData
    local switchBtn = viewData.switchBtn
    local kickoutBtn = viewData.kickoutBtn
    if switchBtn then viewData.switchBtn:setOnClickScriptHandler(handler(self, self.ButtonAction)) end
    if kickoutBtn then 
        viewData.kickoutBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    end
    --初始化下数据的逻辑
    local friendFish = self.data.friendFish
    local card = self.data.card
    if friendFish then
        self:GetViewComponent():UpdateFriendValue(friendFish.maxVigour ~= nil and friendFish.maxVigour or friendFish.vigour, friendFish.vigour)
    elseif self.data.operational and 0 ~= self.data.tag then
        local cardInfo
        if card.cardId then
            cardInfo = gameMgr:GetCardDataByCardId(card.cardId)
        elseif card.playerCardId then
            cardInfo = gameMgr:GetCardDataById(card.playerCardId)
        end
        if cardInfo then
            self:GetViewComponent():UpdateFriendValue(app.restaurantMgr:getCardVigourLimit(cardInfo.id), cardInfo.vigour)
        else
            self:GetViewComponent():UpdateFriendValue(100, 0)
        end
    else
        self:GetViewComponent():UpdateFriendValue(card.maxVigour ~= nil and card.maxVigour or card.vigour, card.vigour)
    end
    local recallBtn = viewData.recallBtn
    if recallBtn then
        if checkint(self.data.friendFish.friendId) == checkint(gameMgr:GetUserInfo().playerId) then
            recallBtn:setVisible(true)
            viewData.recallBtn:setOnClickScriptHandler(handler(self, self.RecallButtonAction))
        end
    end
end

function FishermanFeedMediator:RecallButtonAction( sender )
    PlayAudioByClickNormal()
    local scene = uiMgr:GetCurrentScene()
    local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('是否召回该飨灵？'), extra = __('使用中的钓饵不会返还'),
        isOnlyOK = false, callback = function ()
            self:SendSignal(POST.FISHPLACE_CALLBACK.cmdName, {friendId = self.data.friendGroundId})
        end})
    CommonTip:setPosition(display.center)
    scene:AddDialog(CommonTip)

    CommonTip.extra:setHorizontalAlignment(display.TAC)
end

function FishermanFeedMediator:ButtonAction( sender )
    PlayAudioByClickNormal()
    shareFacade:DispatchObservers(FISHERMAN_SWITCH_EVENT, self.data)
    shareFacade:UnRegsitMediator(NAME)
end

function FishermanFeedMediator:OnRegist(  )
    regPost(POST.FISHPLACE_CALLBACK)
	local AvatarFeedCommand = require( 'Game.command.AvatarFeedCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_FEED_AVATAR, AvatarFeedCommand)
end

function FishermanFeedMediator:OnUnRegist(  )
	unregPost(POST.FISHPLACE_CALLBACK)
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveDialog(self.viewComponent)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_FEED_AVATAR)
end

return FishermanFeedMediator
