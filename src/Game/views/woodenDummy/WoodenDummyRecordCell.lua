---@class WoodenDummyRecordCell
local WoodenDummyRecordCell = class('home.WoodenDummyRecordCell',function ()
	local pageviewcell = CGridViewCell:new()
	pageviewcell.name = 'home.WoodenDummyRecordCell'
	pageviewcell:enableNodeEvents()
	return pageviewcell
end)
local DummyTypeConf = CommonUtils.GetConfigAllMess('dummyType' , 'player')
local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newLayer = display.newLayer
local RES_DICT = {
	COMMON_BG_GOODS               = _res('ui/common/common_bg_goods.png'),
	COMMCON_BG_TEXT               = _res('ui/common/common_bg_list.png'),
	COMMON_BG_TITLE_2             = _res('ui/common/common_bg_title_2.png'),
	COMMON_BG_5                   = _res('ui/common/common_bg_5.png'),
	EXERCISES_RECORD_BG_TALENT    = _res('ui/home/cardslistNew/woodenDummy/exercises_record_bg_talent.png'),
	TEAM_LEAD_SKILL_FRAME_L       = _res('avatar/ui/team_lead_skill_frame_l.png'),
	BATTLE_BG_SKILL_DEFAULT       = _res("ui/battle/battle_bg_skill_default.png"),
	EXERCISES_RECORD_BG_NUM       = _res('ui/home/cardslistNew/woodenDummy/exercises_record_bg_num.png')
}
function WoodenDummyRecordCell:ctor()
	self:setContentSize( cc.size(870, 169))
	local cellLayout = newLayer(0,0,
			{ ap = display.LEFT_BOTTOM, size = cc.size(870, 169) })
	local bgImage = newImageView(RES_DICT.COMMCON_BG_TEXT, 0, 0,
			{ ap = display.LEFT_BOTTOM, tag = 444, enable = false  ,size = cc.size(870,167) , scale9 = true})
	cellLayout:addChild(bgImage)
	self:addChild(cellLayout)

	local talentLayout = newLayer(601, 9,
			{ ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(260, 110), enable = true })
	cellLayout:addChild(talentLayout)

	local talentbgImage = newNSprite(RES_DICT.EXERCISES_RECORD_BG_TALENT, 0, 0,
			{ ap = display.LEFT_BOTTOM, tag = 445  })
	talentbgImage:setScale(1, 1)
	talentLayout:addChild(talentbgImage)

	local talentText = newLabel(130, 93,
			fontWithColor(8,{ ap = display.CENTER, text = __('天赋'), reqW = 90 ,  fontSize = 20, tag = 447 }))
	talentLayout:addChild(talentText)

	local oneTalentSkillLayout = newLayer(52, 50,
			{ ap = display.CENTER, color = cc.r4b(0), size = cc.size(84, 84), enable = true })
	talentLayout:addChild(oneTalentSkillLayout)
	oneTalentSkillLayout:setScale(0.8)

	local skillBg = newImageView(RES_DICT.BATTLE_BG_SKILL_DEFAULT, 42, 41,
			{ ap = display.CENTER, tag = 449, enable = false })
	oneTalentSkillLayout:addChild(skillBg)
	skillBg:setName("skillBg")
	local skillImage = newImageView(RES_DICT.TEAM_LEAD_SKILL_FRAME_L, 42, 41,
			{ ap = display.CENTER, tag = 450, enable = false })
	oneTalentSkillLayout:addChild(skillImage)
	skillImage:setName("skillImage")
	skillImage:setScale(0.7)
	local skillFrame = newImageView(RES_DICT.TEAM_LEAD_SKILL_FRAME_L, 42, 41,
			{ ap = display.CENTER, tag = 451, enable = false })
	oneTalentSkillLayout:addChild(skillFrame)
	skillFrame:setName("skillFrame")

	local twoTalentSkillLayout = newLayer(205, 50,
			{ ap = display.CENTER, color = cc.r4b(0), size = cc.size(84, 84), enable = true })
	talentLayout:addChild(twoTalentSkillLayout)
	twoTalentSkillLayout:setScale(0.8)
	local skillBg = newImageView(RES_DICT.BATTLE_BG_SKILL_DEFAULT, 42, 41,
			{ ap = display.CENTER, tag = 453, enable = false })
	twoTalentSkillLayout:addChild(skillBg)
	skillBg:setName("skillBg")

	local skillImage = newImageView(RES_DICT.TEAM_LEAD_SKILL_FRAME_L, 42, 41,
			{ ap = display.CENTER, tag = 454, enable = false })
	twoTalentSkillLayout:addChild(skillImage)
	skillImage:setName("skillImage")
	skillImage:setScale(0.7)

	local skillFrame = newImageView(RES_DICT.TEAM_LEAD_SKILL_FRAME_L, 42, 41,
			{ ap = display.CENTER, tag = 455, enable = false })
	twoTalentSkillLayout:addChild(skillFrame)
	skillFrame:setName("skillFrame")

	local battlePointBg = newImageView(RES_DICT.EXERCISES_RECORD_BG_NUM, 754, 145,
			{ ap = display.CENTER, tag = 456, enable = false })
	cellLayout:addChild(battlePointBg)

	local battleEffect = newLabel(686, 143,
			{ ap = display.LEFT_CENTER, color = '#ffffff', text = "1111", fontSize = 24, tag = 457 })
	cellLayout:addChild(battleEffect)

	local battleEffectLabel = newLabel(635, 143,
			fontWithColor(10,{ ap = display.RIGHT_CENTER, text = "2222", fontSize = 24, tag = 458 }))
	cellLayout:addChild(battleEffectLabel)

	local battleTime = newLabel(18, 143,
			fontWithColor(6,{ ap = display.LEFT_CENTER,  text = "1111", fontSize = 20, tag = 459 }))
	cellLayout:addChild(battleTime)

	local cardHeadNodes  = {}
	local width = 120
	local offsetWith = 0
	for i = 1 , 5 do
		---@type CardHeadNode
		local cardHeadNode = require('common.CardHeadNode').new({
			cardData = {
				cardId = 200001,
			},
			showBaseState = false,
			showActionState = false,
			showVigourState = false
		})
		cardHeadNode:setTag(i)
		cardHeadNode:setPosition(width * (i - 0.5 ) + offsetWith  ,7 )
		cardHeadNode:setScale(0.6)
		cardHeadNode:setAnchorPoint(display.CENTER_BOTTOM)
		cellLayout:addChild(cardHeadNode)
		display.commonUIParams(cardHeadNode , {animate = false,  cb =  handler(self, self.CardIndexClick)})
		cardHeadNodes[#cardHeadNodes+1] = cardHeadNode
	end
	self.viewData =  {
		cellLayout              = cellLayout,
		talentLayout            = talentLayout,
		cardHeadNodes           = cardHeadNodes,
		talentbgImage           = talentbgImage,
		talentText              = talentText,
		oneTalentSkillLayout    = oneTalentSkillLayout,
		twoTalentSkillLayout    = twoTalentSkillLayout,
		battlePointBg           = battlePointBg,
		battleEffect            = battleEffect,
		battleEffectLabel       = battleEffectLabel,
		battleTime              = battleTime,
	}
end

function WoodenDummyRecordCell:UpdateCell(data , battleType,index )
	local text = ""
	local textValue  = ""
	local bigType  =DummyTypeConf[tostring(battleType)]  and  DummyTypeConf[tostring(battleType)].type  or 1
	bigType = checkint(bigType)
	if bigType == 1 then
		text = __('造成伤害')
	elseif  bigType == 2 then
		text = __('承受伤害')
	elseif  bigType == 3 then
		text = __('治疗总量')
	end
	textValue = data.totalDamage
	local talents = data.talents or {}
	self:UpdateTalentSkill(talents[1] , 1)
	self:UpdateTalentSkill(talents[2] , 2)
	for i = 1, #self.viewData.cardHeadNodes do
		---@type CardHeadNode
		local cardHeadNode =self.viewData.cardHeadNodes[i]
		local cardData = data.team[i] or {}
		if next(cardData) ~= nil  then
			cardHeadNode:setVisible(true)
			cardHeadNode:RefreshUI({
				cardData = cardData,
				showBaseState = true,
				showActionState = false,
				showVigourState = false
			})
		else
			cardHeadNode:setVisible(false)
		end
	end
	local distanceTime = CommonUtils.getTimeFormatByType(getServerTime() -  data.createTimestamp)
	self.viewData.battleTime:setString(distanceTime)
	self.viewData.battleEffect:setString(textValue)
	self.viewData.battleEffectLabel:setString(text)
	self.viewData.cellLayout:setTag(index)
	local talents = data.talents or {}
	self:UpdateTalentSkill(talents[1],1)
	self:UpdateTalentSkill(talents[2],2)
end
function WoodenDummyRecordCell:CardIndexClick(sender)
	local pos = sender:getTag()
	local parent = sender:getParent()
	local cellIndex = parent:getTag()
	AppFacade.GetInstance():DispatchObservers("DUMMY_CLICK_INDEX_EVENT" , { pos = pos , cellIndex = cellIndex })
end
function WoodenDummyRecordCell:UpdateTalentSkill(skillId , index)
	skillId = checkint(skillId)
	local talentNode = self.viewData.oneTalentSkillLayout
	if index == 2 then
		talentNode = self.viewData.twoTalentSkillLayout
	end
	local skillBg = talentNode:getChildByName("skillBg")
	local skillImage = talentNode:getChildByName("skillImage")
	local skillFrame = talentNode:getChildByName("skillFrame")
	if skillId == 0 then
		skillBg:setVisible(true)
		skillImage:setVisible(false)
		skillFrame:setVisible(false)
	else
		skillBg:setVisible(false)
		skillImage:setVisible(true)
		skillFrame:setVisible(true)
		skillImage:setTexture(CommonUtils.GetSkillIconPath(skillId))
	end

end
return WoodenDummyRecordCell
