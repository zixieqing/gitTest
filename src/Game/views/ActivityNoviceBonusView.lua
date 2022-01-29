--[[
新手签到活动view
--]]
local ActivityNoviceBonusView = class('ActivityNoviceBonusView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityNoviceBonusView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	-- 背景
	local bg = display.newImageView(_res('ui/home/activity/activity_bg_sign2.jpg'), size.width/2, size.height/2)
	view:addChild(bg, 1)
    -- 标题(宽度自适应) --
    local titleLayout = CLayout:create()
    view:addChild(titleLayout, 10)
    local frontTitle = display.newLabel(0, 25, {text = __('連續'), fontSize = 34, color = 'ffecb1', font = TTF_GAME_FONT, ttf = true, outline = '3e1212', outlineSize = 1, ap = cc.p(0, 0.5)})
    local signInNumBg = display.newImageView(_res('ui/home/activity/draw_card_ico_new.png'), 0, 30)
	signInNumBg:setVisible(false)
	local signInNumLabel = display.newLabel(0, 25, {text = '15', fontSize = 50, color = '#fff3e4', font = TTF_GAME_FONT, ttf = true, outline = '3e1212', outlineSize = 1})
    local afterTitle = display.newLabel(0, 25, {ap = display.LEFT_CENTER,text = __('天登錄可獲得'), fontSize = 34, color = 'ffecb1', font = TTF_GAME_FONT, ttf = true, outline = '3e1212', outlineSize = 1})
    local titleLayoutWidth = display.getLabelContentSize(frontTitle).width + signInNumBg:getContentSize().width + display.getLabelContentSize(afterTitle).width
    local titleLayoutHeight = 50
    local titleWidthMax = 470
    local titleLayoutSize = cc.size(titleLayoutWidth, titleLayoutHeight)
    titleLayout:setContentSize(titleLayoutSize)
    frontTitle:setPositionX(0)
    titleLayout:addChild(frontTitle, 2)
    signInNumBg:setPositionX(frontTitle:getContentSize().width + signInNumBg:getContentSize().width/2)
    titleLayout:addChild(signInNumBg, 1)
    signInNumLabel:setPositionX(frontTitle:getContentSize().width + signInNumBg:getContentSize().width/2 - 5)
    titleLayout:addChild(signInNumLabel, 3)
    afterTitle:setPositionX(frontTitle:getContentSize().width + signInNumBg:getContentSize().width)
    titleLayout:addChild(afterTitle, 2)
    titleLayout:setPosition(cc.p(240, 560))
    if titleLayoutWidth > titleWidthMax then
    	titleLayout:setScale(titleWidthMax/titleLayoutWidth)
    end
	--------------------------------------------
	local cardId = 200043 -- 卡牌ID
	if Platform.id == 4001 or Platform.id == 4002 then
		cardId = 200069
	end
	local qualityIcon = display.newImageView(CardUtils.GetCardQualityTextPathByCardId(cardId), 30, 20, {ap = cc.p(0, 0.5)})
	qualityIcon:setScale(0.35)
	local nameLabel = display.newLabel(qualityIcon:getContentSize().width*(0.31)+35, 20, fontWithColor(16, {ap = cc.p(0, 0.5), text = CommonUtils.GetConfig('cards','card',cardId).name}))
	local nameBgWidth = display.getLabelContentSize(nameLabel).width + qualityIcon:getContentSize().width*(0.31) + 75
	local nameBg = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_name.png'), 126, 140, {ap = cc.p(0.5, 0.5), scale9 = true, size = cc.size(nameBgWidth, 40)})
	view:addChild(nameBg, 10)
	nameBg:addChild(qualityIcon, 10)
	nameBg:addChild(nameLabel, 10)
	local skinBg = display.newImageView(_res('ui/home/activity/activity_skin_bg_light.png'), 250, 250)
	view:addChild(skinBg, 10)
	local skinLabel = display.newLabel(250, 250, {text = __('限定皮肤'), fontSize = 26, color = '#ffecb1', font = TTF_GAME_FONT, ttf = true, outline = '#3e1212', outlineSize = 1})
	view:addChild(skinLabel, 10)
	local skinNameBg = display.newImageView(_res('ui/home/activity/activity_sign_bg_card_name.png'), 250, 200, {scale9 = true })
	view:addChild(skinNameBg, 10)
	local skinId = 250433 -- 皮肤Id
	if Platform.id == 4001 or Platform.id == 4002 then
		skinId = 250693
	end
	local skinNameLabel = display.newLabel(250, 200, fontWithColor(18, {text = CommonUtils.GetConfig('goods','cardSkin',skinId).name}))
	view:addChild(skinNameLabel, 10)
	local skinNameLabelSize = display.getLabelContentSize(skinNameLabel)
	if skinNameLabelSize.width > 150 then
		skinNameBg:setContentSize(cc.size(skinNameLabelSize.width + 40 , 30 ))
	end
	--------------------------------------------
	local timeBg = display.newImageView(_res('ui/home/activity/activity_sign_bg_time.png'), 256, 26)
	view:addChild(timeBg, 7)
	local timeLabel = display.newRichLabel(256, 26, {
	})
	view:addChild(timeLabel, 10)
	-- 签到列表
    local gridViewSize = cc.size(556, 627)
    local gridViewCellSize = cc.size(556, 150)
    local gridView = CGridView:create(gridViewSize)
    gridView:setAnchorPoint(cc.p(1, 0))
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(size.width, 5))
    gridView:setColumns(1)
    gridView:setAutoRelocate(true)
    view:addChild(gridView, 10)

	return {
		view 			 = view,
		gridView         = gridView,
		-- cardDrawNode     = cardDrawNode,
		signInNumLabel   = signInNumLabel,
		-- cvBg  			 = cvBg,
		-- cvLabel			 = cvLabel,
		-- fragmentIcon     = fragmentIcon,
		timeLabel        = timeLabel
	}
end

function ActivityNoviceBonusView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

return ActivityNoviceBonusView
