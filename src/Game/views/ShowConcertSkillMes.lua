--[[
连携技信息弹窗
--]]
local CommonDialog = require('common.CommonDialog')
local ShowConcertSkillMes = class('ShowConcertSkillMes', CommonDialog)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
--[[
override
initui
--]]
function ShowConcertSkillMes:InitialUI()

	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_3.png'), 0, 0)
		local bgSize = bg:getContentSize()

		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)

		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 - 10)})
		display.commonLabelParams(titleBg,
			{text = __('连携技能'),
			fontSize = 24,color = fontWithColor('BC').color,ttf = true, font = TTF_GAME_FONT,
			offset = cc.p(0, -2)})
		bg:addChild(titleBg)

		-- own label
		local skillTobBg = display.newImageView(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_jineng_top.png'),66, 501)
		view:addChild(skillTobBg, 5)
		skillTobBg:setAnchorPoint(cc.p(0,0))

		local skillBottomBg = display.newImageView(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_jineng_bottom.png'), 70, 505)
		skillBottomBg:setAnchorPoint(cc.p(0,0))
		view:addChild(skillBottomBg, 5)

		local skillimg = display.newImageView(_res('ui/home/teamformation/concertSkillMess/common_btn_tips.png'), skillBottomBg:getContentSize().width * 0.5 , skillBottomBg:getContentSize().height * 0.5 )
		skillimg:setAnchorPoint(cc.p(0.5,0.5))
		skillimg:setScale(0.45)
		skillBottomBg:addChild(skillimg, 6)

		local skillNameLabel = display.newLabel(104, 472,
			{text = (''), fontSize = 22, color = '#76553b', ap = cc.p(0.5, 0)})
		view:addChild(skillNameLabel, 6)


		-- local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_miaoshu_frame.png')})
		-- display.commonUIParams(dialogue_tips, {ap = cc.p(0,0),po = cc.p(163,510),scale9 = true, size = cc.size(337,62)})
  		--       view:addChild(dialogue_tips, 6)
		-- display.commonLabelParams(dialogue_tips,
		-- 	{text = (''),
		-- 	fontSize = 20,color = '5c5c5c',
		-- 	offset = cc.p(-140,0),ap = cc.p(0,0.5),w = 300,maxL = 2})
  		--       dialogue_tips:setTouchEnabled(false)

        local descrViewSize  = cc.size(330, 116)
        local descrContainer = cc.ScrollView:create()
        descrContainer:setPosition(cc.p(163,472))
        descrContainer:setDirection(eScrollViewDirectionVertical)
        -- descrContainer:setAnchorPoint(display.CENTER_TOP)
        descrContainer:setViewSize(descrViewSize)
        view:addChild(descrContainer, 6)

		local dialogue_tips = display.newLabel(0,0,
			{text = "",fontSize = 20, color = '#5c5c5c', hAlign = display.TAL, w = descrViewSize.width})
        descrContainer:setContainer(dialogue_tips)
		-- descrContainer:addChild(dialogue_tips, 6)



		local line = display.newImageView(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_line.png'), bgSize.width * 0.5 , 470)
		line:setAnchorPoint(cc.p(0.5,0.5))
		view:addChild(line, 6)


		local concertSkillBg = display.newImageView(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_fazheng.png'),104, 93)
		view:addChild(concertSkillBg, 5)
		concertSkillBg:setAnchorPoint(cc.p(0,0))


		local imgBgBottom = display.newImageView(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_zhujue_bottom.png'), concertSkillBg:getContentSize().width * 0.5 , concertSkillBg:getContentSize().height * 0.5 )
		imgBgBottom:setAnchorPoint(cc.p(0.5,0.5))
		concertSkillBg:addChild(imgBgBottom, 4)

		local imgBgTop = display.newImageView(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_zhujue_top.png'), concertSkillBg:getContentSize().width * 0.5 , concertSkillBg:getContentSize().height * 0.5 )
		imgBgTop:setAnchorPoint(cc.p(0.5,0.5))
		concertSkillBg:addChild(imgBgTop, 6)

		local imgBgLight = display.newImageView(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_zhujue_light.png'), concertSkillBg:getContentSize().width * 0.5 , concertSkillBg:getContentSize().height * 0.5 )
		imgBgLight:setAnchorPoint(cc.p(0.5,0.5))
		concertSkillBg:addChild(imgBgLight, 5)


		local headIconBg = display.newNSprite(_res('ui/home/teamformation/concertSkillMess/biandui_lianxiskill_mengban.png'), 0, 0)
		local roleClippingNode = cc.ClippingNode:create()
		roleClippingNode:setContentSize(headIconBg:getContentSize())
		roleClippingNode:setAnchorPoint(0.5, 0.5)
		roleClippingNode:setPosition(concertSkillBg:getContentSize().width * 0.5 , concertSkillBg:getContentSize().height * 0.5)
		roleClippingNode:setInverted(false)
		concertSkillBg:addChild(roleClippingNode, 5)
		roleClippingNode:setAlphaThreshold(0.1)

		local ownImg = FilteredSpriteWithOne:create()
		-- ownImg:setTexture(headPath)
		ownImg:setScale(0.55)
		ownImg:setPosition(utils.getLocalCenter(roleClippingNode))
		roleClippingNode:addChild(ownImg)

		headIconBg:setPosition(utils.getLocalCenter(roleClippingNode))
		roleClippingNode:setStencil(headIconBg)


		local ownButtn = display.newButton(0, 0, {n = _res('ui/home/teamformation/concertSkillMess/common_bg_font_name.png'), animation = false})
		display.commonUIParams(ownButtn, {po = cc.p(imgBgTop:getContentSize().width * 0.5, - 20)})
		display.commonLabelParams(ownButtn,
			{text = (''),
			fontSize = 20,color = 'b1613a',
			offset = cc.p(0, -2)})
		imgBgTop:addChild(ownButtn)


		local desLabel = display.newLabel(bgSize.width * 0.5, 58,
			{text = __('一起进入战斗时，该技能激活，并替换能量技。'), fontSize = 20, color = '#4c4c4c', ap = cc.p(0.5, 1.0), w = 450, h = 80})
		view:addChild(desLabel, 6)

		local allCardNameLabel = display.newLabel(bgSize.width * 0.5, 70,
			{text = (' '), fontSize = 20, color = '#b1613a', ap = cc.p(0.5, 0.5)})
		view:addChild(allCardNameLabel, 6)


		return {
			view = view,
			concertSkillBg = concertSkillBg,
			skillimg 		= skillimg,
			skillNameLabel  = skillNameLabel,
			ownImg 			= ownImg,
			ownNameLabel    = ownButtn:getLabel(),
			allCardNameLabel = allCardNameLabel,
            descrContainer  = descrContainer,
			dialogue_tips 	= dialogue_tips,
			skillTobBg = skillTobBg,
			skillBottomBg = skillBottomBg,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)


	self:UpdataUi()
end

function ShowConcertSkillMes:UpdataUi()
	local tempStr = ''
	local myName = ''
	local size = self.viewData.concertSkillBg:getContentSize()

	local tabPos = {
		{cc.p(size.width * 0.5, size.height - 35 )},
		{cc.p(10, size.height * 0.5),cc.p(size.width - 10, size.height * 0.5)},
		{cc.p(30, size.height * 0.25),cc.p(size.width * 0.5, size.height - 35 ),cc.p(size.width - 30, size.height * 0.25)},
		{cc.p(30, size.height * 0.75),cc.p(size.width - 30, size.height * 0.75),cc.p(30, size.height * 0.25),cc.p(size.width - 30, size.height * 0.25)},
	}
	myName = CommonUtils.GetConfig('cards', 'card', self.args.cardId).name

	local cardData = gameMgr:GetCardDataById(self.args.id)
	if CardUtils.GetCardConnectSkillId(self.args.cardId) then
		local skillId = CardUtils.GetCardConnectSkillId(self.args.cardId)
		if cardData.skill[tostring(skillId)] and cardData.skill[tostring(skillId)].level then
			self.viewData.dialogue_tips:setString(cardMgr.GetSkillDescr(skillId,cardData.skill[tostring(skillId)].level))
            local descrContainer = self.viewData.descrContainer
            local descrScrollTop = descrContainer:getViewSize().height - display.getLabelContentSize(self.viewData.dialogue_tips).height
            descrContainer:setContentOffset(cc.p(0, descrScrollTop))
            self.viewData.skillimg:setTexture(CommonUtils.GetSkillIconPath(skillId))
        end
	else
		self.viewData.dialogue_tips:setString('')
		self.viewData.skillimg:setVisible(false)
		self.viewData.skillBottomBg:setVisible(false)
		self.viewData.skillTobBg:setVisible(false)
	end

	local num = table.nums(CommonUtils.GetConfig('cards', 'card', self.args.cardId).concertSkill)
	for i,k in ipairs(CommonUtils.GetConfig('cards', 'card', self.args.cardId).concertSkill) do
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

		local tobBg = FilteredSpriteWithOne:create()
		tobBg:setTexture(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_juese_top.png'))
		tobBg:setPosition(tabPos[num][i])
		self.viewData.concertSkillBg:addChild(tobBg, 6)

		local bottomBg = FilteredSpriteWithOne:create()
		bottomBg:setTexture(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_juese_bottom.png'))
		bottomBg:setPosition(tabPos[num][i])
		self.viewData.concertSkillBg:addChild(bottomBg, 4)

		local headIconBg = display.newNSprite(_res('ui/home/teamformation/concertSkillMess/biandui_lianxiskill_mengban.png'), 0, 0)
		headIconBg:setScale(0.8)
		local roleClippingNode = cc.ClippingNode:create()
		roleClippingNode:setContentSize(headIconBg:getContentSize())
		roleClippingNode:setAnchorPoint(0.5, 0.5)
		roleClippingNode:setPosition(tabPos[num][i])
		roleClippingNode:setInverted(false)
		self.viewData.concertSkillBg:addChild(roleClippingNode, 5)
		roleClippingNode:setAlphaThreshold(0.1)

		local headPath = ''
		if nil ~= cardDate then
			headPath = CardUtils.GetCardHeadPathByCardId(cardDate.id)
		else
			headPath = _res('arts/goods/goods_icon_error.png')
		end
		local img = FilteredSpriteWithOne:create()
		img:setTexture(headPath)
		img:setScale(0.5)
		img:setPosition(utils.getLocalCenter(roleClippingNode))
		roleClippingNode:addChild(img)

		headIconBg:setPosition(utils.getLocalCenter(roleClippingNode))
		roleClippingNode:setStencil(headIconBg)

		local labelButtn = display.newButton(0, 0, {n = _res('ui/home/teamformation/concertSkillMess/common_bg_font_name.png'), animation = false})
		display.commonUIParams(labelButtn, {po = cc.p(tobBg:getContentSize().width * 0.5, - 14)})
		display.commonLabelParams(labelButtn,
			{text = cardName,
			fontSize = 20,color = 'b1613a',
			offset = cc.p(0, -2)})
		tobBg:addChild(labelButtn)

		local grayFilter = GrayFilter:create()
		if not gameMgr:GetCardDataByCardId(k) then
			tobBg:setFilter(grayFilter)
			bottomBg:setFilter(grayFilter)
			img:setFilter(grayFilter)
		end
	end
	self.viewData.ownNameLabel:setString(myName)
	self.viewData.allCardNameLabel:setString(myName..'，'..tempStr)

	local skinId   = cardMgr.GetCardSkinIdByCardId(self.args.cardId)
	local headPath = CardUtils.GetCardHeadPathBySkinId(skinId)
	self.viewData.ownImg:setTexture(headPath)
end


return ShowConcertSkillMes
