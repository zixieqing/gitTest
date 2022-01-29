local Mediator = mvc.Mediator

local CardContractDetailMediator = class("CardContractDetailMediator", Mediator)


local NAME = "CardContractDetailMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")


local MesConfig = {
	{key =   'hp'			,des = 	__('契约效果：生命值提升_tarNum_%')},
	{key =   'attack'		,des = 	__('契约效果：攻击力提升_tarNum_%')},
	{key =   'defence'	  	,des =	__('契约效果：防御力提升_tarNum_%')},
	{key =   'critRate'	  	,des =	__('契约效果：暴击率提升_tarNum_%')},
	{key =   'critDamage'	,des =	__('契约效果：暴击伤害提升_tarNum_%')},
	{key =   'attackRate'	,des =	__('契约效果：攻击速度提升_tarNum_%')},
}


function CardContractDetailMediator:ctor(param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.cardData = param or {}
end


function CardContractDetailMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Hero_MARRIAGE_CALLBACK,
		SIGNALNAMES.CACHE_MAGIC_INK_UPDATE,
	}

	return signals
end

function CardContractDetailMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	if name == SIGNALNAMES.Hero_MARRIAGE_CALLBACK then
		-- 扣除消耗道具
		local marryCostConfig = cardMgr.GetMarryCostConfig()
		CommonUtils.DrawRewards({
			{goodsId = marryCostConfig.goodsId, num = -marryCostConfig.num}
		})
		local playerCardId =  signal:GetBody().requestData.playerCardId
		local marryTime = os.time()
		gameMgr:UpdateCardDataById(playerCardId ,{favorabilityLevel = signal:GetBody().favorabilityLevel  , marryTime  = marryTime})
		AppFacade.GetInstance():DispatchObservers(EVENT_CARD_MARRY, {playerCardId = playerCardId, favorabilityLevel = tostring(signal:GetBody().favorabilityLevel)})
		local mediator = require( 'Game.mediator.CardMemoryMediator' ).new({data = self.cardData, cb = 'CardMarrySuccessMediator'})
		AppFacade.GetInstance():RegistMediator(mediator)

		self:GetFacade():UnRegsitMediator(NAME)
	elseif name == SIGNALNAMES.CACHE_MAGIC_INK_UPDATE then
		local marryCostConfig = cardMgr.GetMarryCostConfig()
		local viewData = self.viewComponent.viewData
		local marryCostLabel = viewData.marryCostLabel
		if marryCostLabel then
			marryCostLabel:setString(gameMgr:GetAmountByGoodId(marryCostConfig.goodsId) .. '/' .. marryCostConfig.num)
		end
	end
end


function CardContractDetailMediator:updataview( )

end

function CardContractDetailMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.CardContractDetailView' ).new(self.cardData)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    viewComponent.eaterLayer:setOnClickScriptHandler(function(sender)
        PlayAudioByClickNormal()
		AppFacade.GetInstance():UnRegsitMediator("CardContractDetailMediator")
	end)

	if cardMgr.GetMarriable(self.cardData.id) then
		viewComponent:AddMarryUI()
	end
    local viewData = self.viewComponent.viewData
	local desLabel = viewData.desLabel
	local unlockStoryLabel = viewData.unlockStoryLabel
	local contractBuffLabel = viewData.contractBuffLabel
	local titleLabel = viewData.titleLabel
	local upImg = viewData.upImg
	local loveLabel = viewData.loveLabel
	local tempLabel = viewData.tempLabel
	local tipsButton = viewData.tipsButton
	local lineImg = viewData.lineImg


	viewData.bgSpine:registerSpineEventHandler(function (event)
		if event.animation == "attack" then
			viewData.bgSpine:setAnimation(0, 'idle', true)
			contractBuffLabel:runAction(cc.FadeIn:create(1))
			unlockStoryLabel:runAction(cc.FadeIn:create(1))
			desLabel:runAction(cc.FadeIn:create(1))
			titleLabel:runAction(cc.FadeIn:create(1))
			upImg:runAction(cc.FadeIn:create(1))
			loveLabel:runAction(cc.FadeIn:create(1))
			tempLabel:runAction(cc.FadeIn:create(1))
			tipsButton:runAction(cc.FadeIn:create(1))
			if 1 < tonumber(self.cardData.favorabilityLevel) then
				lineImg:runAction(cc.FadeIn:create(1))
			end
			if cardMgr.GetMarriable(self.cardData.id) then
				local marryBtnBG = viewData.marryBtnBG
				marryBtnBG:runAction(cc.FadeIn:create(1))

				local particleSpine = viewData.particleSpine
				particleSpine:runAction(cc.Sequence:create(
					cc.DelayTime:create(0.5),
					cc.FadeIn:create(1)
				))

				local marryButton = viewData.marryButton
				marryButton:runAction(cc.Sequence:create(cc.FadeIn:create(1),
				cc.CallFunc:create(function ()
					marryButton:setOnClickScriptHandler(handler(self, self.MarryClickCallback))
				end)))
			end
		end
    end, sp.EventType.ANIMATION_COMPLETE)

	-- self.cardData.favorabilityLevel = self.cardData.favorabilityLevel +1
    local favorabilityLvData = CommonUtils.GetConfig('cards', 'favorabilityLevel', self.cardData.favorabilityLevel)
	local cardConf = CONF.CARD.CARD_INFO:GetValue(self.cardData.cardId)
    local favorabilityBuffData = CommonUtils.GetConfig('cards', 'favorabilityCareerBuff', cardConf.career)
    local messData = favorabilityBuffData[tostring(self.cardData.favorabilityLevel)]
    titleLabel:setString(favorabilityLvData.name or '契约')

    local str = string.gsub(messData.descr, '_target_id_', (CommonUtils.GetConfig('cards', 'card', self.cardData.cardId).name or ''))
    desLabel:setString(str)

	local str = self:GetBuffDes( self.cardData.favorabilityLevel  )
	--buff收益
	contractBuffLabel:setString(str)
	--解锁剧情
	local romanNum = {'Ⅰ','Ⅱ','Ⅲ','Ⅳ','Ⅴ'}
	if CardUtils.IsLinkCard(self.cardData.cardId) then
		unlockStoryLabel:setString('')
	else
		if romanNum[tonumber(self.cardData.favorabilityLevel) - 1] then
			unlockStoryLabel:setString(__('已解锁飨灵故事').. romanNum[tonumber(self.cardData.favorabilityLevel) - 1])
		else
			unlockStoryLabel:setString('')
			contractBuffLabel:setPositionX(contractBuffLabel:getPositionX() + 18)
		end
	end

	

	tipsButton:setOnClickScriptHandler(function( sender )
        PlayAudioByClickNormal()
		uiMgr:ShowInformationTipsBoard({targetNode = sender, descr = __('携带该飨灵获得战斗的胜利，或者赠送精致的料理都可以提高好感度。'), type = 5})
	end)

    if checkint(self.cardData.favorabilityLevel) >= table.nums( CommonUtils.GetConfigAllMess('favorabilityLevel', 'cards') ) then
		viewData.nextContractBtn:setOnClickScriptHandler(function( sender )
            PlayAudioByClickNormal()
			uiMgr:ShowInformationTips(__('契约已达到满级'))
		end)
    else
		viewData.nextContractBtn:setOnClickScriptHandler(function( sender )
            PlayAudioByClickNormal()
			local favorabilityLvData = CommonUtils.GetConfig('cards', 'favorabilityLevel', self.cardData.favorabilityLevel+1)
			local str = self:GetBuffDes( self.cardData.favorabilityLevel + 1 )
			local nextfavorabilityLvData = CommonUtils.GetConfig('cards', 'favorabilityLevel', self.cardData.favorabilityLevel+ 1)
			--local unlockDes =  string.fmt(__('解锁条件：好感度达到_num_'),{ _num_ = nextfavorabilityLvData.totalExp})
			uiMgr:ShowInformationTipsBoard({targetNode = sender,unlockDes = nextfavorabilityLvData.totalExp,
				storyLockDes = __('解锁剧情：飨灵故事').. romanNum[tonumber(self.cardData.favorabilityLevel)],
				buffDes = str ,title = favorabilityLvData.name, descr = str, type = 8})
		end)
	end

end

function CardContractDetailMediator:GetBuffDes( favorabilityLevel )
	local cardConf = CONF.CARD.CARD_INFO:GetValue(self.cardData.cardId)
    local favorabilityBuffData = CommonUtils.GetConfig('cards', 'favorabilityCareerBuff', cardConf.career)
    local messData = favorabilityBuffData[tostring(favorabilityLevel)]

	-- dump(messData)
	local atrrData = {}
	if messData then
		if checknumber(messData.attack) > 0 then
			atrrData.attack = messData.attack
		end

		if checknumber(messData.defence) > 0 then
			atrrData.defence = messData.defence
		end

		if checknumber(messData.hp) > 0 then
			atrrData.hp = messData.hp
		end

		if checknumber(messData.critRate) > 0 then
			atrrData.critRate = messData.critRate
		end

		if checknumber(messData.attackRate) > 0 then
			atrrData.attackRate = messData.attackRate
		end

		if checknumber(messData.critDamage) > 0 then
			atrrData.critDamage = messData.critDamage
		end
	end
	local str = ''
	for i,v in ipairs(MesConfig) do
		if atrrData[v.key] then
			local tempStr =  string.gsub(v.des, '_tarNum_', atrrData[v.key]*100)
			if str == '' then
				str = str..tempStr
			else
				str = str..'\n'..tempStr
			end
		end
	end
	return str
	-- body
end

--[[
主页面tab按钮的事件处理逻辑
@param sender button对象
--]]
function CardContractDetailMediator:ButtonActions( sender )
	local tag = sender:getTag()
	print(tag)
end
--[[
结婚按钮回调
--]]
function CardContractDetailMediator:MarryClickCallback(sender)
	PlayAudioByClickNormal()
	
	-- 判断是否可以结婚
	if not cardMgr.GetMarriable(self.cardData.id) then
		uiMgr:ShowInformationTips(__('!!!好感度不足!!!'))
		return
	end

	-- -- 结婚道具不足
	local marryCostConfig = cardMgr.GetMarryCostConfig()
	if marryCostConfig.num > gameMgr:GetAmountByGoodId(marryCostConfig.goodsId) then
		uiMgr:AddDialog("common.GainPopup", {goodId = marryCostConfig.goodsId})
		return
	end

    local str = string.gsub(__('确定要与_target_id_签订誓约么?'), '_target_id_', (CommonUtils.GetConfig('cards', 'card', self.cardData.cardId).name or ''))
	-- 确定弹窗
	local commonTip = require('common.NewCommonTip').new({
		costDesr = __(str),
		cost = marryCostConfig,
		callback = function ()
			self:SendSignal(COMMANDS.COMMAND_HERO_MARRIAGE, {playerCardId = self.cardData.id})

			-- local mediator = require( 'Game.mediator.CardMemoryMediator' ).new({data = self.cardData, cb = 'CardMarrySuccessMediator'})
			-- AppFacade.GetInstance():RegistMediator(mediator)

			-- self:GetFacade():UnRegsitMediator(NAME)
		end
	})

	commonTip:setName('NewCommonTip')
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
end

function CardContractDetailMediator:OnRegist(  )
	local CardsListCommand = require( 'Game.command.CardsListCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_HERO_MARRIAGE, CardsListCommand)
end

function CardContractDetailMediator:OnUnRegist(  )
	--称出命令
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_HERO_MARRIAGE)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return CardContractDetailMediator
