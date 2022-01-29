local Mediator = mvc.Mediator

local CardMarrySuccessMediator = class("CardMarrySuccessMediator", Mediator)

local NAME = "CardMarrySuccessMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local MesConfig = {
	{key =   'hp'			,des = 	__('生命值提升_tarNum_%')},
	{key =   'attack'		,des = 	__('攻击力提升_tarNum_%')},
	{key =   'defence'	  	,des =	__('防御力提升_tarNum_%')},
	{key =   'critRate'	  	,des =	__('暴击率提升_tarNum_%')},
	{key =   'critDamage'	,des =	__('暴击伤害提升_tarNum_%')},
	{key =   'attackRate'	,des =	__('攻击速度提升_tarNum_%')},
}

function CardMarrySuccessMediator:ctor(param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.cardData = {}
	if param and checktable(param) then
		self.cardData = param.data or {}
	end
end


function CardMarrySuccessMediator:InterestSignals()
	local signals = {
		-- POST.ALTER_CARD_NICKNAME.sglName , -- 修改飨灵昵称
	}

	return signals
end

function CardMarrySuccessMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	-- dump(signal:GetBody())
	-- if name == POST.ALTER_CARD_NICKNAME.sglName then
    --     uiMgr:ShowInformationTips(__('昵称修改成功'))
        
	-- 	local scene = uiMgr:GetCurrentScene()
	-- 	scene:RemoveDialogByName('AlterNicknamePopup')
    -- end
end

function CardMarrySuccessMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.CardMarrySuccessView' ).new(self.cardData)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local viewData = self.viewComponent.viewData
	
	viewData.backBtn:setOnClickScriptHandler(function(sender)
        PlayAudioByClickClose()
		AppFacade.GetInstance():UnRegsitMediator(NAME)
	end)

    viewData.alterNicknameButton:setOnClickScriptHandler(function(sender)
        PlayAudioByClickNormal()

		app.uiMgr:AddChangeNamePopup({
			renameCB  = function(newName)
				AppFacade.GetInstance():DispatchSignal(POST.ALTER_CARD_NICKNAME.cmdName , {cardName = newName, playerCardId = checkint(self.cardData.id)})
			end,
			title        = __("飨灵昵称"),
			preName      = CommonUtils.GetCardNameById(self.cardData.id),
		})
	end)

	local function startViewAction()
		-- PlayAudioClip(AUDIOS.UI.ui_vow_settlement.id)

		local str = self:GetBuffDes( self.cardData.favorabilityLevel  )
		local unlockStr = {__('新的主页触摸语音'), __('开启了飨灵故事' .. 'Ⅴ'), __('开启了专属昵称')}
		if CardUtils.IsLinkCard(self.cardData.cardId) then
			unlockStr = {}
		end
		viewComponent:AddBuffDesr(unlockStr, str)
	end
	startViewAction()
end

function CardMarrySuccessMediator:GetBuffDes( favorabilityLevel )
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
	local str = {}
	for i,v in ipairs(MesConfig) do
		if atrrData[v.key] then
			local tempStr =  string.gsub(v.des, '_tarNum_', atrrData[v.key]*100)
			table.insert(str, tempStr)
		end
	end
	return str
	-- body
end

function CardMarrySuccessMediator:OnRegist(  )
end

function CardMarrySuccessMediator:OnUnRegist(  )
	PlayBGMusic()

	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return CardMarrySuccessMediator
