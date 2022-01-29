--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
---@class CardSkillMediator :Mediator
local CardSkillMediator = class("CardSkillMediator", Mediator)
local NAME = "CardSkillMediator"
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
function CardSkillMediator:ctor(param ,  viewComponent )
	self.super:ctor(NAME,viewComponent)

end

function CardSkillMediator:InterestSignals()
	local signals = {
		"REMOVE_QBG_SPINE_EVENT"
	}
	return signals
end

function CardSkillMediator:ProcessSignal( signal )
	local name = signal:GetName()
	if name ==  "REMOVE_QBG_SPINE_EVENT" then
		local viewComponent = self:GetViewComponent()
		if viewComponent and (not tolua.isnull(viewComponent)) then
			local viewData = viewComponent.viewData
			local qBg 	= viewData.qBg
			qBg:removeAllChildren()
		end
	end
end


function CardSkillMediator:Initial( key )
	self.super.Initial(self, key)
	local viewComponent = require("Game.views.cardList.CardSkillView").new()
	self:SetViewComponent(viewComponent)
	local cardListMediator = self:GetFacade():RetrieveMediator("CardsListMediatorNew")
	local cardListViewData  = cardListMediator:GetViewComponent().viewData
	local scaleRate = (display.width - 1334) / 1334
	local isScaleRole = scaleRate > 0
	local scale = isScaleRole and 1 + scaleRate + 0.06 or 1
	local heroScale  = cardListViewData.heroScale
	local heroAvataePos  = cardListViewData.heroAvataePos
	local skillBgScale = isScaleRole and scale or heroScale
	viewComponent.viewData.skillBg:setScale(skillBgScale)
	viewComponent.viewData.skillBg:setPosition(heroAvataePos.x , heroAvataePos.y +22)
	local view =   cardListViewData.view
	view:addChild(viewComponent)
	viewComponent:setAnchorPoint(cc.p(0,0.5))
	viewComponent:setPosition(cc.p(display.SAFE_L, display.size.height * 0.5))
end

function CardSkillMediator:OnRegist()
end

--刷新当前卡牌技能描述和立绘
--index 当前卡牌第几个技能
--切换卡牌刷新页面方法
function CardSkillMediator:UpdataSkillUi( data , index  )
	--dump(data)
	if not data.skill then
		return
	end
	local TSkillDataTab = {}
	for i,v in pairs(data.skill) do
		local tablee = {}
		tablee.skillId = i
		tablee.skillLevel = v.level
		table.insert(TSkillDataTab,tablee)
	end
	table.sort(TSkillDataTab, function(a, b)
		return checkint(a.skillId) < checkint(b.skillId)
	end)
	dump(TSkillDataTab)
	if not TSkillDataTab[index] then
		return
	end
	local index = index or 1
	local skillId = TSkillDataTab[index].skillId
	local skillLevel = TSkillDataTab[index].skillLevel
	local skillData = CardUtils.GetSkillConfigBySkillId(skillId)
	local viewComponent = self:GetViewComponent()
	local skillNameLabel = viewComponent.viewData.skillNameLabel
	local descrLabel 	= viewComponent.viewData.descrLabel
	local nameBtn 		= viewComponent.viewData.nameBtn
	local nameLabelParams 		= viewComponent.viewData.nameLabelParams
	local jobImg 		= viewComponent.viewData.jobImg
	local bgJob 		= viewComponent.viewData.bgJob
	skillNameLabel:setString(skillData.name)
	descrLabel:setString(cardMgr.GetSkillDescr(skillId, skillLevel))
	CommonUtils.SetCardNameLabelStringById(nameBtn:getLabel(), data.id, nameLabelParams)
	bgJob:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(data.cardId))
	jobImg:setTexture(CardUtils.GetCardCareerIconPathByCardId(data.cardId))

	local qBg 	= viewComponent.viewData.qBg
	qBg:removeAllChildren()
	local cardInfo = gameMgr:GetCardDataById(data.id)
	local qAvatar  = AssetsUtils.GetCardSpineNode({skinId = cardInfo.defaultSkinId, scale = 0.7})
	qAvatar:update(0)
	qAvatar:setTag(1)
	qAvatar:setAnimation(0, 'idle', true)
	qAvatar:setPosition(cc.p(qBg:getContentSize().width * 0.5, 15))
	qBg:addChild(qAvatar)
	qBg:setTouchEnabled(true)
	qBg:setOnClickScriptHandler(function( sender )
		xTry(function()
			CommonUtils.PlayCardSoundByCardId(data.cardId, cardMgr.GetCouple(data.id) and SoundType.TYPE_JIEHUN or SoundType.TYPE_TOUCH, SoundChannel.HOME_SCENE)
		end,__G__TRACKBACK__)
	end)
end

--刷新当前卡牌技能描述和立绘
--skillIndex 当前卡牌第几个技能
--当前卡牌进行技能相关操作时刷新页面方法
function CardSkillMediator:UpdataSkillUi_1( cardsData ,  skillIndex , model)
	if not model then
		return
	end
	local data  = cardsData
	local TSkillDataTab = {}
	if model == 2 then
		local t = CommonUtils.GetBusinessSkillByCardId(data.cardId, {from = 3})
		table.sort(t, function(a, b)
			return checkint(a.skillId) < checkint(b.skillId)
		end)
		for i,v in ipairs(t) do
			local tablee = {}
			tablee = v
			tablee.skillId = v.skillId
			tablee.skillLevel = v.level
			table.insert(TSkillDataTab,tablee)
		end
	elseif model == 1 then
		if not data.skill then
			return
		end

		for i,v in pairs(data.skill) do
			local tablee = {}
			tablee.skillId = i
			tablee.skillLevel = v.level
			table.insert(TSkillDataTab,tablee)
		end

		table.sort(TSkillDataTab, function(a, b)
			return checkint(a.skillId) < checkint(b.skillId)
		end)
	end

	if not TSkillDataTab[skillIndex] then
		return
	end

	local index = skillIndex or 1
	local skillId = TSkillDataTab[index].skillId
	local skillLevel = TSkillDataTab[index].skillLevel
	local skillData = nil
	if model == 2 then
		skillData = CommonUtils.GetConfig('business', 'assistantSkill',skillId)
	elseif model == 1 then
		skillData = CardUtils.GetSkillConfigBySkillId(skillId)
	end
	local cardData =CommonUtils.GetConfig('cards', 'card', data.cardId)

	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local skillNameLabel = viewData.skillNameLabel
	local descrLabel 	= viewData.descrLabel
	local concertSkillLabel 	= viewData.concertSkillLabel
	local nameBtn 		= viewData.nameBtn
	local nameLabelParams 		= viewData.nameLabelParams
	local jobImg 		= viewData.jobImg
	local bgJob 		= viewData.bgJob
	skillNameLabel:setString(skillData.name)
	if model == 1 then
		descrLabel:setString(cardMgr.GetSkillDescr(skillId, skillLevel))
	elseif model == 2 then
		descrLabel:setString(TSkillDataTab[index].descr)
	end
	CommonUtils.SetCardNameLabelStringById(nameBtn:getLabel(), data.id, nameLabelParams)
	concertSkillLabel:setVisible(false)
	if model == 1 then
		if index == 3 then
			local tempStr = ''
			local concertSkillTable =  CommonUtils.GetConfig('cards', 'card', data.cardId).concertSkill
			if table.nums(concertSkillTable) > 0  then
				concertSkillLabel:setVisible(true)
			else
				concertSkillLabel:setVisible(false)
			end
			for i,k in ipairs(concertSkillTable) do
				local cardDate = CommonUtils.GetConfig('cards', 'card', k)

				local cardName = ''
				if nil == cardDate then
					------------ 卡牌表不存在连携对象 ------------
					cardName = __('???')
					------------ 卡牌表不存在连携对象 ------------
				else
					cardName = tostring(cardDate.name)
				end

				if i == 1 then
					tempStr = cardName
				else
					tempStr = tempStr..','.. cardName
				end
			end
			concertSkillLabel:setString(string.fmt(__('_des_一起进入战斗时，该技能激活，并替换能量技。'),{_des_ = cardData.name..'，'..tempStr})  )
		end
	end
	bgJob:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(data.cardId))
	jobImg:setTexture(CardUtils.GetCardCareerIconPathByCardId(data.cardId))
	local qBg 	= viewComponent.viewData.qBg
	if not qBg:getChildByTag(1) then
		local cardInfo = gameMgr:GetCardDataById(data.id)
		local qAvatar  = AssetsUtils.GetCardSpineNode({skinId = cardInfo.defaultSkinId, scale = 0.7})
		qAvatar:update(0)
		qAvatar:setTag(1)
		qAvatar:setAnimation(0, 'idle', true)
		qAvatar:setPosition(cc.p(qBg:getContentSize().width * 0.5, 15))
		qBg:addChild(qAvatar)
		qBg:setTouchEnabled(true)
		qBg:setOnClickScriptHandler(function( sender )
			xTry(function()
				CommonUtils.PlayCardSoundByCardId(data.cardId, cardMgr.GetCouple(data.id) and SoundType.TYPE_JIEHUN or SoundType.TYPE_TOUCH, SoundChannel.HOME_SCENE)
			end,__G__TRACKBACK__)
		end)
	else
		if model == 1 then
			local actionName = cardMgr.GetCardSpineAnimationName(checkint(data.cardId), checkint(data.defaultSkinId), checkint(skillId))
			qBg:getChildByTag(1):setToSetupPose()
			qBg:getChildByTag(1):setAnimation(0, actionName, false)
			qBg:getChildByTag(1):registerSpineEventHandler(function (event)
				qBg:getChildByTag(1):setAnimation(0, 'idle', true)
			end,sp.EventType.ANIMATION_COMPLETE)
		end
	end
end

function CardSkillMediator:OnUnRegist()
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:runAction(
				cc.RemoveSelf:create()
		)
	end
end



return CardSkillMediator
