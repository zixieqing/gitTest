--[[
卡牌图鉴立绘展示界面
@params table {
	cardId 卡牌id
	breakLevel 突破等级
}
--]]
local GameScene = require( "Frame.GameScene" )
local CardManualView = class("CardManualView", GameScene)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
constructor
--]]
function CardManualView:ctor( ... )
	GameScene.ctor(self, 'Game.views.CardManualView')
	self.args = unpack({...})

	self.cardId = self.args.cardId

	self.showAvatarIdx = 0

	self:InitUI()
end
--[[
init ui
--]]
function CardManualView:InitUI()

	local cardConf = CardUtils.GetCardConfig(self.cardId)

	local function CreateView()
		local view = CLayout:create(display.size)
		view:setCascadeOpacityEnabled(true)
		view:enableNodeEvents()
		-- bg mask
		local bgMask = display.newImageView(_res('ui/home/handbook/pokedex_card_bg.jpg'), utils.getLocalCenter(self).x, utils.getLocalCenter(self).y, {isFull = true})
		view:addChild(bgMask)

		-- card draw
		local cardDraw = require( "common.CardSkinDrawNode" ).new({confId = self.cardId, coordinateType = COORDINATE_TYPE_CAPSULE})
		cardDraw:setPositionX(50 + display.SAFE_L)
		view:addChild(cardDraw, 5)

		local particleSpine = nil
		local data = gameMgr:GetCardDataByCardId(self.cardId)
		if cardMgr.GetCouple(data.id) then
			local designSize = cc.size(1334, 750)
			local winSize = display.size
			local deltaHeight = (winSize.height - designSize.height) * 0.5
	
			particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
			-- particleSpine:setTimeScale(2.0 / 3.0)
			particleSpine:setPosition(cc.p (420 + display.SAFE_L, deltaHeight))
			view:addChild(particleSpine, 5)
			particleSpine:setAnimation(0, 'idle2', true)
			particleSpine:update(0)
			particleSpine:setToSetupPose()
			particleSpine:setVisible(false)
		end
		-- card btn
		local cardBtn = display.newButton(50 + display.SAFE_L, display.cy, {scale9 = true, size = cc.size(600, display.height*0.8), ap = cc.p(0, 0.5)})
		view:addChild(cardBtn, 10)

		-- back btn
		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
		display.commonUIParams(backBtn, {po = cc.p(backBtn:getContentSize().width * 0.5 + 30 + display.SAFE_L, display.height - 53)})
		view:addChild(backBtn, 20)
		-- switch btn
		local switchBtn = display.newButton(254 + display.SAFE_L, 86, {n = _res('ui/home/handbook/pokedex_card_btn_qban.png')})
		view:addChild(switchBtn, 10)
		-- name label
		local nameLabelBg = display.newButton(446 + display.SAFE_L, 62, {n = _res('ui/home/handbook/pokedex_card_bg_name.png'), enable = false, ap = cc.p(0.5, 0) , scale9 = true })
		view:addChild(nameLabelBg, 5)
		display.commonLabelParams(nameLabelBg, {text = CommonUtils.GetCardNameById(gameMgr:GetCardDataByCardId(self.cardId).id), fontSize = 26, color = '671919' , paddingW = 50 })
		-- cv label
		if cardConf.cv then
			local cvBg = display.newButton(446 + display.SAFE_L, 38, {n = _res('ui/home/handbook/pokedex_card_bg_cv_name.png'), enable = false})
			view:addChild(cvBg, 5)
			display.commonLabelParams(cvBg, fontWithColor(18,{text = CommonUtils.GetCurrentCvAuthorByCardId(self.cardId) }))
			if string.len(cardConf.cv) <= 0 then
				cvBg:getLabel():setString(__('CV:???'))
			end
		end
		-- forum button
		-- local forumBtn = display.newButton(76, 160, {n = _res('ui/home/handbook/pokedex_card_btn_forum.png')})
		-- view:addChild(forumBtn, 5)
		-- display.commonLabelParams(forumBtn, {text = __('评论'), fontSize = 22, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, offset = cc.p(-6, 10)})
		-- left Layout
		local leftLayoutSize = cc.size(137, 552)
		local leftLayout = CLayout:create(leftLayoutSize)
		leftLayout:setCascadeOpacityEnabled(true)
		leftLayout:setAnchorPoint(cc.p(0, 0.5))
		leftLayout:setPosition(20 + display.SAFE_L, display.height/2 - 30)
		view:addChild(leftLayout, 10)
		local progressBg = display.newImageView(_res('ui/home/handbook/pokedex_card_skin_title.png'), leftLayoutSize.width/2, leftLayoutSize.height, {ap = cc.p(0.5, 1)})
		progressBg:setCascadeOpacityEnabled(true)
		leftLayout:addChild(progressBg, 3)
		local progressName = display.newLabel(leftLayoutSize.width/2, 42, {text = __('外观进度'), fontSize = 20, ttf = true, font = TTF_GAME_FONT, color = '#ffffff'})
		progressName:setCascadeOpacityEnabled(true)
		local progressNameSize = display.getLabelContentSize(progressName)
		if progressNameSize.width >120 then
			local currentScale = progressName:getScale()
			progressName:setScale(currentScale *120/ progressNameSize.width)
		end
		progressBg:addChild(progressName, 10)
		local progressNum = display.newLabel(leftLayoutSize.width/2, 18, {text = '', fontSize = 22, ttf = true, font = TTF_GAME_FONT, color = '#ffffff'})
		progressNum:setCascadeOpacityEnabled(true)
		progressBg:addChild(progressNum, 10)
		local skinListBg = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_skin.png'), leftLayoutSize.width/2, 0, {ap = cc.p(0.5, 0)})
		leftLayout:addChild(skinListBg, 3)

    	local gridViewSize = skinListBg:getContentSize()
    	local gridViewCellSize = cc.size(gridViewSize.width, 140)
    	local skinGridView = CGridView:create(gridViewSize)
    	skinGridView:setAnchorPoint(cc.p(0.5, 0))
    	skinGridView:setSizeOfCell(gridViewCellSize)
    	skinGridView:setPosition(cc.p(leftLayoutSize.width/2, 2))
    	skinGridView:setColumns(1)
    	skinGridView:setAutoRelocate(true)
    	leftLayout:addChild(skinGridView, 10)
  		-- jump Layout
		local jumpLayoutSize = cc.size(523, 90)
		local jumpLayout = CLayout:create(jumpLayoutSize)
		view:addChild(jumpLayout, 10)
		jumpLayout:setPosition(446 + display.SAFE_L, 200)
		local jumpBg = display.newImageView(_res('ui/home/handbook/pokedex_card_skin_have_bg.png'), jumpLayoutSize.width/2, jumpLayoutSize.height/2)
		jumpLayout:addChild(jumpBg, 5)
		local jumpBtn = display.newButton(jumpLayoutSize.width/2, jumpLayoutSize.height/2, {n = _res('ui/common/common_btn_orange.png')})
		jumpLayout:addChild(jumpBtn, 10)
		display.commonLabelParams(jumpBtn, fontWithColor(14, {text = __('去获取')}))

		-- bottom Layout
		local bottomLayout = CLayout:create(cc.size(600, 100))
		bottomLayout:setPosition(display.width, 0)
		bottomLayout:setAnchorPoint(cc.p(1, 0))
		view:addChild(bottomLayout, 10)
		-- bottom button
		local bottomBg = display.newImageView(_res('ui/cards/propertyNew/card_bg_tabs.png'), 596, 0, {ap = cc.p(1, 0)})
		bottomLayout:addChild(bottomBg, 5)
		-- tab button
		local tabsData = {
			{name = __('故事'), tag = 1001, iconName = 'story'},
			{name = __('音频'), tag = 1002, iconName = 'voice'},
			{name = __('资料'), tag = 1003, iconName = 'summary'}
		}
		local tabButtons = {}
		for i,v in ipairs(tabsData) do
			local tabButton = display.newCheckBox(210+(i-1)*120, 58,
				{n = _res('ui/home/handbook/pokedex_card_btn_' .. v.iconName .. '_default.png'), s = _res('ui/home/handbook/pokedex_card_btn_' .. v.iconName .. '_selected.png')}
			)
			bottomLayout:addChild(tabButton, 10)
			tabButton:setTag(v.tag)
			tabButton:setScale(0.9)
			tabButtons[tostring( v.tag )] = tabButton
			local nameBg = display.newImageView(_res('ui/home/handbook/card_bar_bg_small.png'), 210+(i-1)*120, 22)
			bottomLayout:addChild(nameBg, 10)
			local nameLabel = display.newLabel(210+(i-1)*120, 22, {text = v.name, fontSize = 20, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '311717'})
			bottomLayout:addChild(nameLabel, 10)
		end


		-- local prevBtn = display.newButton(72, 64, {n = _res('ui/home/cardslistNew/card_skill_btn_switch.png')})
		-- view:addChild(prevBtn, 10)
		-- local nextBtn = display.newButton(694, 64, {n = _res('ui/home/cardslistNew/card_skill_btn_switch.png')})
		-- nextBtn:setScaleX(-1)
		-- view:addChild(nextBtn, 10)
		-- 立绘全身像数据
		-- local drawsInfo = {}
		-- 插一张默认立绘
		-- local defaultDrawInfo = {
		-- 	avatarPath = cardMgr.GetCardDrawPath(self.cardId),
		-- 	bgPath = cardMgr.GetCardDrawBackgroundPath(self.cardId) or _res('cards/card/common_bg_card_large.png')
		-- }
		-- table.insert(drawsInfo, defaultDrawInfo)
		-- if self.breakLevel > 0 then
		-- 	for i = 1, self.breakLevel do
		-- 		-- 解锁满突立绘插入数据
		-- 		if false ~= cardMgr.CheckCardDrawByBreakLevel(self.cardId, i) then
		-- 			local breakDrawInfo = {
		-- 				avatarPath = cardMgr.GetCardDrawPath(self.cardId, {breakLevel = i}),
		-- 				bgPath = cardMgr.GetCardDrawBackgroundPath(self.cardId, {breakLevel = i}) or _res('cards/card/common_bg_card_large.png')
		-- 			}
		-- 			table.insert(drawsInfo, breakDrawInfo)
		-- 		end
		-- 	end
		-- end

		-- 缩放区域
		-- local avatarZoomSize = cc.size(1334, 1002)
		-- local avatarZoom = PanOrZoomController:create()
		-- avatarZoom:setPanBoundsRect(-avatarZoomSize.width, -avatarZoomSize.height, avatarZoomSize.width, avatarZoomSize.height)
		-- avatarZoom:setMinZoomLimit(1.0)
		-- avatarZoom:setMaxZoomLimit(2.0)
		-- self:addChild(avatarZoom, 21)

		-- local avatars = {}
		-- for i,v in ipairs(drawsInfo) do
		-- 	local avatarBg = display.newImageView(_res(v.bgPath), display.cx, display.cy)
		--	-- avatarZoom:addChild(avatarBg)
		-- 	self:addChild(avatarBg, 21)
		-- 	avatarBg:setRotation(-90)

		-- 	local avatar = display.newImageView(_res(v.avatarPath), utils.getLocalCenter(avatarBg).x, utils.getLocalCenter(avatarBg).y)
		-- 	avatarBg:addChild(avatar)

		-- 	avatarBg:setVisible(false)

		-- 	table.insert(avatars, avatarBg)
		-- end


		return {
			-- avatars = avatars
			view         = view,
			tabButtons   = tabButtons,
			backBtn      = backBtn,
			cardBtn      = cardBtn,
			cardDraw     = cardDraw,
			particleSpine= particleSpine,
			bottomLayout = bottomLayout,
			leftLayout   = leftLayout,
			jumpLayout   = jumpLayout,
			switchBtn    = switchBtn,
			skinGridView = skinGridView,
			progressNum  = progressNum,
			jumpBtn      = jumpBtn
		}

	end
	-- eaterLayer
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
	xTry(function ( )
		self.viewData = CreateView( )
		self:addChild(self.viewData.view)
		self.viewData.view:setPosition(display.center)
	end, __G__TRACKBACK__)
end
---------------------------------------------------
-- init end --
---------------------------------------------------
--[[
底部切换按钮点击回调
--]]
function CardManualView:BottomButtonCallback( sender )
	local tag = sender:getTag()

end
---------------------------------------------------
-- callback begin --
---------------------------------------------------
--[[
显示下一张立绘
--]]
function CardManualView:ShowNextDraw()
	self.showAvatarIdx = self.showAvatarIdx + 1
	if self.showAvatarIdx <= table.nums(self.viewData.avatars) then
		for i,v in ipairs(self.viewData.avatars) do
			v:setVisible(i == self.showAvatarIdx)
		end
	else
		self.showAvatarIdx = 0
		for i,v in ipairs(self.viewData.avatars) do
			v:setVisible(false)
		end
	end
end
---------------------------------------------------
-- callback end --
---------------------------------------------------


return CardManualView
