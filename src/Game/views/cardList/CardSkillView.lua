---@class CardSkillView
local CardSkillView = class('CardSkillView', function()
	local layout = CLayout:create(cc.size(1002,display.size.height))
	return layout
end)
function CardSkillView:ctor(params )
	self:InitUI()
end
function CardSkillView:InitUI()
	local leftSkillView = CLayout:create(cc.size(1002,display.size.height))
	--leftSkillView:setAnchorPoint(cc.p(0,0.5))
	--leftSkillView:setPosition(cc.p(display.SAFE_L, display.size.height * 0.5))
	leftSkillView:setAnchorPoint(display.LEFT_BOTTOM)
	leftSkillView:setPosition(0,0)
	self:addChild(leftSkillView)
	local llsize = leftSkillView:getContentSize()
	local bottomImg = display.newImageView(_res('ui/cards/skillNew/card_skill_bg_q.png'),0, 0)--kitchen_bg_1 hall_bg_1
	leftSkillView:addChild(bottomImg,6)
	bottomImg:setAnchorPoint(cc.p(0.5,0))
	bottomImg:setPosition(cc.p( llsize.width * 0.27,30))
	--卡牌类型
	local line = display.newImageView(_res('ui/cards/skillNew/card_skill_ico_skill_name.png'), 40, llsize.height - 150,
			{ap = cc.p(0, 0)
			})
	leftSkillView:addChild(line,6)
	local skillNameLabel = display.newLabel(80,llsize.height - 140,
			{text = '', fontSize = 30, color = '#5b3c25', ap = cc.p(0, 0)})
	leftSkillView:addChild(skillNameLabel,6)
	local tempBtn1 = display.newButton(0, 0,
			{n = _res('ui/cards/skillNew/common_bg_font_name_2.png')})
	display.commonUIParams(tempBtn1, {ap = cc.p(0,0),po = cc.p(50 , line:getPositionY() - 55)})
	display.commonLabelParams(tempBtn1, {text = __('技能描述 '), fontSize = 22, color = '#ffffff',offset = cc.p(-20,0)})
	tempBtn1:getLabel():enableOutline(cc.c4b(0, 0, 0, 255), 1)
	leftSkillView:addChild(tempBtn1,6)
	tempBtn1:setVisible(false)
	local descrLabel = display.newLabel(50, tempBtn1:getPositionY()+40,
			{text = ' ', fontSize = 22, color = '#5c5c5c',
			 ap = cc.p(0, 1), hAlign = display.TAL, w = 580,h = 260})
	leftSkillView:addChild(descrLabel,6)
	local concertSkillLabel = display.newLabel(50, tempBtn1:getPositionY() - 70,
			{text = ' ', fontSize = 20, color = '#ffffff',
			 ap = cc.p(0, 1), hAlign = display.TAL, w = 580,h = 60})
	leftSkillView:addChild(concertSkillLabel,6)
	--卡牌类型
	local bgJob = display.newImageView(_res(CardUtils.CAREER_ICON_FRAME_PATH_MAP[tostring(CardUtils.CAREER_TYPE.DEFEND)]), 40, tempBtn1:getPositionY() - 210,
			{ap = cc.p(0, 0)
			})
	bgJob:setScale(1.5)
	leftSkillView:addChild(bgJob,6)

	local jobImg = display.newImageView(_res(CardUtils.CAREER_ICON_PATH_MAP[tostring(CardUtils.CAREER_TYPE.DEFEND)]),utils.getLocalCenter(bgJob).x ,  utils.getLocalCenter(bgJob).y  ,
			{ap = cc.p(0.5, 0.5)
			})
	jobImg:setScale(0.8)
	bgJob:addChild(jobImg)

	local nameBtn = display.newButton(0, 0,
			{n = _res('ui/cards/skillNew/common_bg_font_name_2.png')})
	display.commonUIParams(nameBtn, {ap = cc.p(0,0),po = cc.p(90 ,  tempBtn1:getPositionY() - 200)})
	display.commonLabelParams(nameBtn, {text = (' '),ap = cc.p(0,0.5),ttf = true, font = TTF_GAME_FONT, fontSize = 32, color = '#ffcc60',offset = cc.p(-60,6)})
	nameBtn:getLabel():enableOutline(cc.c4b(0, 0, 0, 255), 1)
	leftSkillView:addChild(nameBtn,6)
	local nameLabelParams = {font = TTF_GAME_FONT, fontSize = 32, color = '#ffcc60', outline = cc.c4b(0, 0, 0, 255), fontSizeN = 32, colorN = '#ffcc60'}
	-- q版立绘
	local qBg = display.newImageView(_res('ui/common/comon_bg_frame_gey.png'), 0, 0, {scale9 = true, size = cc.size(219, 191)})
	display.commonUIParams(qBg, {ap = cc.p(0.5, 1), po = cc.p(0, 0)})
	leftSkillView:addChild(qBg,16)
	qBg:setPosition(cc.p(llsize.width * 0.27,nameBtn:getPositionY() - nameBtn:getContentSize().height - 100))
	qBg:setOpacity(0)
	qBg:setCascadeOpacityEnabled(true)
	--技能默认背景
	local scaleRate = (display.width - 1334) / 1334
	local isScaleRole = scaleRate > 0
	local scale = isScaleRole and 1 + scaleRate + 0.06 or 1
	local skillBgScale = isScaleRole and scale or 2
	local skillBg = display.newImageView(_res('cards/card/common_bg_card_large.png'), llsize.width *0.5, llsize.height * 0.5)--kitchen_bg_1 hall_bg_1
	leftSkillView:addChild(skillBg)
	skillBg:setScale(skillBgScale)
	skillBg:setAnchorPoint(cc.p(0,0.5))
	local skillBg_1 = display.newImageView(_res('ui/cards/skillNew/card_skill_bg_text_describe.png'),0, llsize.height)--kitchen_bg_1 hall_bg_1
	leftSkillView:addChild(skillBg_1,1)
	skillBg_1:setScale(scale)
	skillBg_1:setAnchorPoint(cc.p(0,1))
	self.viewData = {
		skillNameLabel  = skillNameLabel,
		descrLabel 		= descrLabel,
		concertSkillLabel = concertSkillLabel,
		nameBtn 		= nameBtn,
		nameLabelParams	= nameLabelParams,
		qBg 			= qBg,
		jobImg 			= jobImg,
		bgJob 			= bgJob,
		skillBg         = skillBg
	}
end


return CardSkillView
