--[[
主线地图的界面
@params table {
	chapterId int 章节id
}
--]]
local GameScene = require( 'Frame.GameScene' )
---@class MapView :GameScene
local MapView = class('MapView', GameScene)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
constructor
--]]
function MapView:ctor( ... )
	self.super.ctor(self, 'Game.views.map.MapView')
	self.args = unpack({...})
	self.viewData = nil

	self:setContentSize(display.size)
	self:InitUI()
end
--[[
init ui
--]]
function MapView:InitUI()

	local function CreateView()

		local size = self:getContentSize()

		-- 返回按钮
		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
		display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
		self:addChild(backBtn, 20)
        backBtn:setName('BACK_BTN')
		backBtn:setVisible(false)

		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('主线地图'), fontSize = 28, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, 20)

		-- 满星奖励
		local starRewardBtnOffsetY = -20
		local starRewardBtnBottom = display.newNSprite(_res('ui/map/map_bg_star_prize.png'), 0, 0, {scale9 = true, size = cc.size(130,60)})
		local starRewardBtnTop = display.newNSprite(_res('ui/map/map_ico_star_cup.png'), 0, 0)
		local starRewardBtnSize = cc.size(starRewardBtnBottom:getContentSize().width, starRewardBtnBottom:getContentSize().height + starRewardBtnTop:getContentSize().height + starRewardBtnOffsetY)
		local starRewardBtn = display.newButton(0, 0, {
			size = starRewardBtnSize,
		})
		display.commonUIParams(starRewardBtnBottom, {ap = cc.p(0.5, 0), po = cc.p(starRewardBtnSize.width * 0.5, 0)})
		display.commonUIParams(starRewardBtnTop, {ap = cc.p(0.5, 0), po = cc.p(starRewardBtnSize.width * 0.5, starRewardBtnBottom:getContentSize().height + starRewardBtnOffsetY)})
		display.commonUIParams(starRewardBtn, {po = cc.p(display.SAFE_L + 10 + starRewardBtnSize.width * 0.5, 10 + starRewardBtnSize.height * 0.5)})
		self:addChild(starRewardBtn, 20)
		starRewardBtn:addChild(starRewardBtnBottom)
		starRewardBtnBottom:addChild(starRewardBtnTop)
		------------ 小红点 ------------
		require('common.RemindIcon').addRemindIcon({parent = starRewardBtn, tag = RemindTag.STAR_REWARD, po = cc.p(starRewardBtnBottom:getContentSize().width - 10, starRewardBtnBottom:getContentSize().height)})
		------------ 小红点 ------------


		local starsDescrLabel = display.newLabel(starRewardBtnSize.width * 0.5, starRewardBtnBottom:getContentSize().height - 5,
			fontWithColor(8,{text = __('满星奖励'),reqW = 100,  ap = cc.p(0.5, 1)}))
		starRewardBtnBottom:addChild(starsDescrLabel)
        local lwidth = display.getLabelContentSize(starsDescrLabel).width
        if lwidth < 130 then lwidth = 130 end
        if lwidth > 130 then lwidth = lwidth + 20 end
        starRewardBtnBottom:setContentSize(cc.size(lwidth, 60))
        starsDescrLabel:setPositionX(lwidth * 0.5)
		-- local starsLabel = display.newLabel(starsDescrLabel:getPositionX(), starsDescrLabel:getPositionY() - display.getLabelContentSize(starsDescrLabel).height,
		local starsLabel = display.newLabel(starsDescrLabel:getPositionX(), 10,
			fontWithColor(10,{text = '00/00', ap = cc.p(0.5, 0) }))
        starRewardBtnBottom:setName('FULL_REWARD_BUTTON')
		starRewardBtnBottom:addChild(starsLabel)

		-- 难度按钮
        --[[
		local diffcultyInfo = {
			{name = __('普通'), buttonPath = 'ui/map/maps_btn_difficulty_1.png', tag = 1},
			{name = __('困难'), buttonPath = 'ui/map/maps_btn_difficulty_2.png', tag = 2},
			-- {name = __('团本'), buttonPath = 'ui/map/maps_btn_difficulty_3.png', tag = 3}
		}
		local diffButtons = {}
		local diffInfo = nil
		for i = table.nums(diffcultyInfo), 1, -1 do
			diffInfo = diffcultyInfo[i]

			local button = display.newButton(0, 0, {n = _res(diffInfo.buttonPath)})
			display.commonUIParams(button, {
				po = cc.p(
					size.width - button:getContentSize().width * 0.5 - 15 + (button:getContentSize().width + 20) * (i - table.nums(diffcultyInfo)),
					15 + button:getContentSize().height * 0.5)
			})
			self:addChild(button, 20)
			button:setTag(diffInfo.tag)

			local diffLabel = display.newLabel(button:getContentSize().width * 0.5, 10,
				{text = diffInfo.name, ttf = true, font = _res(TTF_GAME_FONT), fontSize = 28, color = '#ffffff'})
			diffLabel:enableOutline(ccc3FromInt('#673f2d'), 1)
			button:addChild(diffLabel, 10)

			local disableCover = display.newNSprite(_res('ui/map/maps_btn_difficulty_not_select.png'), utils.getLocalCenter(button).x, utils.getLocalCenter(button).y)
			disableCover:setTag(3)
			disableCover:setVisible(false)
			button:addChild(disableCover, 5)

			table.insert(diffButtons, button)
		end
        --]]

		-- 地图page view
		local pageSize = self:getContentSize()
		local mapPageView = CPageView:create(pageSize)
		mapPageView:setAnchorPoint(cc.p(0.5, 0.5))
		mapPageView:setPosition(cc.p(pageSize.width * 0.5, pageSize.height * 0.5))
		mapPageView:setDirection(eScrollViewDirectionHorizontal)
		mapPageView:setSizeOfCell(pageSize)
        mapPageView:setName('CPAGE_VIEW')
		mapPageView:setBounceable(false)
		-- mapPageView:setDragable(false)
		-- mapPageView:setAutoRelocate(false)

		self:addChild(mapPageView, 5)

		-- 翻页按钮
		local prevBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch_right.png')})
		prevBtn:setScaleX(-1)
		display.commonUIParams(prevBtn, {po = cc.p(display.SAFE_L + 15 + prevBtn:getContentSize().width * 0.5, size.height * 0.5)})
		self:addChild(prevBtn, 20)
		prevBtn:setTag(2001)
		-- prevBtn:setVisible(false)

		local nextBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch_right.png')})
		display.commonUIParams(nextBtn, {po = cc.p(display.SAFE_R - 15 - nextBtn:getContentSize().width * 0.5, size.height * 0.5)})
		self:addChild(nextBtn, 20)
		nextBtn:setTag(2002)
		-- nextBtn:setVisible(false)
		local  doubleExpTwoImage = nil
		if  utils.isExistent(_res("ui/home/activity/doubleActivity/raid_activity_label_slice")) then
			doubleExpTwoImage = display.newButton(display.cx , display.cy - 300 , {n =  _res("ui/home/activity/doubleActivity/maps_double_x2") } )
			self:addChild(doubleExpTwoImage , 21)
			doubleExpTwoImage:setVisible(false)

			display.commonLabelParams(doubleExpTwoImage ,fontWithColor(10 , {color = '#ffffff' , text = __('当前的双倍经验开放中')} ))
			local doubleExpTwoImageSize = doubleExpTwoImage:getContentSize()
			local expImage = display.newImageView(_res('ui/common/common_ico_exp.png') , 0 , doubleExpTwoImageSize.height/2 +20  , {scale = 0.4 })
			doubleExpTwoImage:addChild(expImage)

			local expSpine = sp.SkeletonAnimation:create("ui/home/activity/doubleActivity/cooking_x2.json" ,"ui/home/activity/doubleActivity/cooking_x2.atlas",1 )
			expSpine:setAnimation(0,'idle' , true  )
			doubleExpTwoImage:addChild(expSpine)
			expSpine:setPosition(0 ,10 )

			local levelSpine = sp.SkeletonAnimation:create("ui/home/activity/doubleActivity/cooking_level.json" ,"ui/home/activity/doubleActivity/cooking_level.atlas",1 )
			levelSpine:setAnimation(0,'idle' , true  )
			doubleExpTwoImage:addChild(levelSpine)
			levelSpine:setPosition(doubleExpTwoImageSize .width - 40  ,doubleExpTwoImageSize.height/2 )

		end
        return {
			backBtn = backBtn,
			tabNameLabel = tabNameLabel,
			tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
			mapPageView = mapPageView,
			-- touchLayer = touchLayer,
			doubleExpTwoImage = doubleExpTwoImage ,
			prevBtn = prevBtn,
			nextBtn = nextBtn,
			starRewardBtn = starRewardBtn,
			starsLabel = starsLabel,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	-- 弹出标题班
	self.viewData.tabNameLabel:setPositionY(display.height + 100)
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
	self.viewData.tabNameLabel:runAction( action )

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
显示满星奖励小红点
@params bool show bool 是否显示
--]]
function MapView:ShowStarRewardRemindIcon(show)
	self.viewData.starRewardBtn:getChildByTag(RemindTag.STAR_REWARD):setVisible(show)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

return MapView
