--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 主界面View
--]]
local GameScene = require('Frame.GameScene')
local ActivitySkinCarnivalScene = class('ActivitySkinCarnivalScene', GameScene)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
    COMMON_TITLE                    = _res('ui/common/common_title.png'),
    COMMON_TIPS       		        = _res('ui/common/common_btn_tips.png'),
	BG                              = 'ui/home/activity/skinCarnival/home/story_home_bg.jpg',
	BG_LEFT                         = 'ui/home/activity/skinCarnival/home/story_home_bg_cloth_left.png',
	BG_RIGHT                        = 'ui/home/activity/skinCarnival/home/story_home_bg_cloth_right.png',
	BG_BOTTOM                       = 'ui/home/activity/skinCarnival/home/story_home_bg_floor.png',
	CHEST_BTN 	 	 	 	 	 	= _res('ui/home/activity/skinCarnival/story_home_ico_box.png'),
	CHEST_BTN_LIGHT 	 	 	    = _res('ui/home/activity/skinCarnival/story_home_light_box.png'),
	REWARD_BG 	 	 	 	 	 	= _res('ui/home/activity/skinCarnival/story_home_bg_box.png'),
	CHECK_ICON 	 	 	 	 	 	= _res('ui/home/activity/skinCarnival/common_btn_check_selected.png'),
	ENTRY_TITLE_BG 	 	 	 	 	= _res('ui/home/activity/skinCarnival/story_home_bg_name.png'),
	REMIND_ICON                     = _res('ui/common/common_hint_circle_red_ico.png'),
	REWARD_PROGRESS_BG     		    = _res('ui/home/activity/skinCarnival/story_cinderella_line_box_bg.png'),
    REWARD_PROGRESS_BAR    		    = _res('ui/home/activity/skinCarnival/story_cinderella_line_box.png'),
	REWARD_PROGRESS_TOP    		    = _res('ui/home/activity/skinCarnival/story_cinderella_line_box_top.png'),
	SKIN_ICON                       = _res('ui/home/activity/skinCarnival/story_home_ico_pifu.png'),
	BACK_BTN                        = _res('ui/common/common_btn_back.png'),
}
-- 主题标题
local THEME_TITLE = {
	[tostring(SKIN_CASRNIVAL_THEME.FAIRY_TALE)] = __('童话颂歌'),
	[tostring(SKIN_CASRNIVAL_THEME.SKIN_20_1)] 	= __('唤醒时刻'),
	[tostring(SKIN_CASRNIVAL_THEME.SKIN_20_2)] 	= __('童谣绮梦'),
	[tostring(SKIN_CASRNIVAL_THEME.SKIN_21_1)] 	= __('残损之痕'),
}
-- 主题入口配置
local THEME_ENTRY_CONFIG = {
	[tostring(SKIN_CASRNIVAL_THEME.FAIRY_TALE)] = {
		{x = display.cx - 510, y = display.cy + 120, name = 'srory_home_prince_1',   size = cc.size(225, 270), titlePosX = 6,  defaultAnimation = 'idle'}, 
		{x = display.cx - 510, y = display.cy - 162, name = 'story_home_prince_2',   size = cc.size(225, 270), titlePosX = 10, defaultAnimation = 'idle'}, 
		{x = display.cx - 225, y = display.cy - 115, name = 'story_home_swan',       size = cc.size(300, 370), titlePosX = 10, defaultAnimation = 'play'}, 
		{x = display.cx + 125, y = display.cy - 20,  name = 'story_home_cap',        size = cc.size(370, 460), titlePosX = 20, defaultAnimation = 'play'}, 
		{x = display.cx + 500, y = display.cy - 210, name = 'story_home_sleep',      size = cc.size(305, 250), titlePosX = 10, defaultAnimation = 'idle'}, 
		{x = display.cx + 435, y = display.cy + 70,  name = 'story_home_cinderella', size = cc.size(225, 270), titlePosX = 10, defaultAnimation = 'idle'}, 
	},
}
function ActivitySkinCarnivalScene:ctor( ... )
    self.super.ctor(self, 'views.activity.skinCarnival.ActivitySkinCarnivalScene')
	local args = unpack({...})
	self.themeComponent = {} -- 主题组件
	self.entryComponentList = {} -- 入口组件
	self.themeId = nil       -- 主题Id
	self:InitUI()
end
--[[
初始化ui
--]]
function ActivitySkinCarnivalScene:InitUI()
	local CreateView = function ()
		local size = display.size
		local view = CLayout:create(size)
		view:setPosition(size.width / 2, size.height / 2)
		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('童话颂歌'), reqW = 190 ,fontSize = 30, color = '#473227',offset = cc.p(-20,-8)})
		self:addChild(tabNameLabel, 20)
		-- 提示按钮
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 28)
		tabNameLabel:addChild(tabtitleTips, 1)
		-- 入口layout
		local entryLayout = CLayout:create(size)
		entryLayout:setPosition(cc.p(size.width / 2, size.height / 2))
		view:addChild(entryLayout, 3)
		-- 奖励宝箱
		local chestBtn = display.newButton(size.width - display.SAFE_L - 80, size.height - 85, {n = RES_DICT.CHEST_BTN})
		view:addChild(chestBtn, 5)
		display.commonLabelParams(chestBtn, fontWithColor(14, {text = __('收集奖励'),w = 150,hAlign = display.TAC , offset = cc.p(0, - 38)}))
		local chestLight = display.newImageView(RES_DICT.CHEST_BTN_LIGHT, chestBtn:getPositionX(), chestBtn:getPositionY())
		chestLight:setVisible(false)
		view:addChild(chestLight, 3)
		chestLight:runAction(cc.RepeatForever:create(
			cc.RotateBy:create(1, 30)
		))
		local remindIcon = display.newImageView(RES_DICT.REMIND_ICON, chestBtn:getPositionX() + 40, chestBtn:getPositionY() + 40)
		remindIcon:setVisible(false)
		view:addChild(remindIcon, 5)
		-- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.BACK_BTN, cb = handler(self, self.BackClickHandler)})
		self:addChild(backBtn, 10)
		return {
			view 	            = view,
			tabNameLabel        = tabNameLabel,
			chestBtn	 	    = chestBtn,
			chestLight          = chestLight,
			remindIcon          = remindIcon, 
			entryLayout         = entryLayout,
			backBtn             = backBtn, 
		}
	end

	xTry(function ()
		self.viewData = CreateView()
		self:addChild(self.viewData.view)
		self:EnterAction()
	end, __G__TRACKBACK__)
end
--[[
入场动画
--]]
function ActivitySkinCarnivalScene:EnterAction()
    -- 弹出标题板
	local tabNameLabelPos = cc.p(self.viewData.tabNameLabel:getPosition())
	self.viewData.tabNameLabel:setPositionY(display.height + 100)
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
	self.viewData.tabNameLabel:runAction( action )
end
--[[
刷新页面
@params skinData list     皮肤数据
@params themeId  int      主题Id
@params tips     map      入口红点数据
@params callback function 皮肤活动入口点击回调
--]]
function ActivitySkinCarnivalScene:RefreshView(skinData, themeId, tips, callback)
	self:SetThemeId(themeId)
	self:CreateThemeComponent(themeId)
	self:CreateSkinEntry(skinData, themeId, callback)
	self:RefreshSkinEntry(skinData, tips)
end
--[[
刷新宝箱
@params collect          list     奖励列表
@params collectedSkinNum int      收集到的皮肤数量
--]]
function ActivitySkinCarnivalScene:RefreshChest( collect, collectedSkinNum )
	local viewData = self:GetViewData()
	local canDraw = false
	for i, v in ipairs(collect) do
		if not v.hasDrawn and collectedSkinNum >= checkint(v.targetNum) then
			canDraw = true
			break
		end
	end
	if canDraw then
		viewData.chestLight:setVisible(true)
		viewData.remindIcon:setVisible(true)
	else
		viewData.chestLight:setVisible(false)
		viewData.remindIcon:setVisible(false)
	end
end
--[[
创建主题组件
--]]
function ActivitySkinCarnivalScene:CreateThemeComponent( themeId )
	local viewData = self:GetViewData()
	local themeComponent = {}
	local spinePath = THEME_SPINE_PATH[tostring(themeId)]
	-- 修改标题
	viewData.tabNameLabel:getLabel():setString(THEME_TITLE[tostring(themeId)])
	
	if checkint(themeId) == SKIN_CASRNIVAL_THEME.SKIN_20_2 then
		local bg = display.newImageView(_resEx(RES_DICT.BG, nil, THEME_SPINE_PATH[tostring(themeId)]), display.cx, display.cy)
		viewData.view:addChild(bg, 1)
		local bgBottom = display.newImageView(_resEx(RES_DICT.BG_BOTTOM, nil, THEME_SPINE_PATH[tostring(themeId)]), display.cx, display.cy - 501, {ap = display.CENTER_BOTTOM})
		viewData.view:addChild(bgBottom, 2)
		local bgLeft = display.newImageView(_resEx(RES_DICT.BG_LEFT, nil, THEME_SPINE_PATH[tostring(themeId)]), display.cx - 812, display.cy + 501, {ap = display.LEFT_TOP})
		viewData.view:addChild(bgLeft, 2)
		local bgRight = display.newImageView(_resEx(RES_DICT.BG_RIGHT, nil, THEME_SPINE_PATH[tostring(themeId)]), display.cx + 812, display.cy + 501, {ap = display.RIGHT_TOP})
		viewData.view:addChild(bgRight, 2)
		local effect = sp.SkeletonAnimation:create(
			string.format('ui/home/activity/skinCarnival/spine/%s/snow.json', spinePath),
			string.format('ui/home/activity/skinCarnival/spine/%s/snow.atlas', spinePath),
			1)
		effect:setAnimation(0, 'idle', true)
		effect:setPosition(cc.p(display.cx, display.cy))
		viewData.view:addChild(effect, 5)
		themeComponent = {
			bgBottom = bgBottom,
			bgLeft   = bgLeft,
			bgRight  = bgRight,
		}
	else
		local bg = display.newImageView(_resEx(RES_DICT.BG, nil, THEME_SPINE_PATH[tostring(themeId)]), display.cx, display.cy)
		viewData.view:addChild(bg, 1)
		local bgBottom = display.newImageView(_resEx(RES_DICT.BG_BOTTOM, nil, THEME_SPINE_PATH[tostring(themeId)]), display.cx, display.cy - 501, {ap = display.CENTER_BOTTOM})
		viewData.view:addChild(bgBottom, 2)
		local effect1 = sp.SkeletonAnimation:create(
			string.format('ui/home/activity/skinCarnival/spine/%s/story_home_bg.json', spinePath),
			string.format('ui/home/activity/skinCarnival/spine/%s/story_home_bg.atlas', spinePath),
			1)
		effect1:setAnimation(0, 'play1', true)
		effect1:setPosition(cc.p(display.cx, display.cy))
		viewData.view:addChild(effect1, 2)
		local bgLeft = display.newImageView(_resEx(RES_DICT.BG_LEFT, nil, THEME_SPINE_PATH[tostring(themeId)]), display.cx - 812, display.cy + 501, {ap = display.LEFT_TOP})
		viewData.view:addChild(bgLeft, 2)
		local bgRight = display.newImageView(_resEx(RES_DICT.BG_RIGHT, nil, THEME_SPINE_PATH[tostring(themeId)]), display.cx + 812, display.cy + 501, {ap = display.RIGHT_TOP})
		viewData.view:addChild(bgRight, 2)
		local effect2 = sp.SkeletonAnimation:create(
			string.format('ui/home/activity/skinCarnival/spine/%s/story_home_bg.json', spinePath),
			string.format('ui/home/activity/skinCarnival/spine/%s/story_home_bg.atlas', spinePath),
			1)
		effect2:setAnimation(0, 'play2', true)
		effect2:setPosition(cc.p(display.cx, display.cy))
		viewData.view:addChild(effect2, 5)
		themeComponent = {
			bgBottom = bgBottom,
			bgLeft   = bgLeft,
			bgRight  = bgRight,
		}
	end
	self:SetThemeComponent(themeComponent)
end

--[[
创建皮肤活动入口
--]]
function ActivitySkinCarnivalScene:CreateSkinEntry( skinData, themeId, callback )
	local viewData = self:GetViewData()
	viewData.entryLayout:removeAllChildren()
	local configList = self:GetThemeEntryConfig(themeId)
	local spinePath = THEME_SPINE_PATH[tostring(themeId)]
	local entryComponentList = {}
	-- if checkint(themeId) == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
		for i, v in ipairs(checktable(skinData)) do
			local config = configList[i]
			-- node
			local entryNode = CLayout:create(config.size)
			entryNode:setPosition(cc.p(config.x, config.y))
			viewData.entryLayout:addChild(entryNode, 1)
			-- spine 
			local spine = sp.SkeletonAnimation:create(
				string.format('ui/home/activity/skinCarnival/spine/%s/%s.json', spinePath, config.name),
				string.format('ui/home/activity/skinCarnival/spine/%s/%s.atlas', spinePath, config.name),
				1)
			spine:setAnimation(0, config.defaultAnimation, true)
			spine:setPosition(cc.p(config.size.width / 2, config.size.height / 2))
			entryNode:addChild(spine, 2)
			-- btn
			local btn = display.newButton(config.size.width / 2, config.size.height / 2, {n = 'empty', size = config.size})
			entryNode:addChild(btn, 2)
			btn:setTag(i)
			btn:setOnClickScriptHandler(callback)
			-- titleBg 
			local titleBgH = 75
			local titleBg = display.newImageView(RES_DICT.ENTRY_TITLE_BG, config.size.width / 2, config.titlePosX, {ap = display.CENTER_BOTTOM, size = cc.size(config.size.width, titleBgH), scale9 = true, capInsets = cc.rect(5, 15, 218, 50)})
			entryNode:addChild(titleBg, 3)
			-- tltleLabel 
			local titleLabelPosY = config.titlePosX + titleBgH / 2
			local titleLabel = display.newLabel(config.size.width / 2, titleLabelPosY, {text = v.title, fontSize = 24, color = '#ffcc52', ttf = true, font = TTF_GAME_FONT, outline = '#452331', outlineSize = 1})
			entryNode:addChild(titleLabel, 5)
			local getLabel = display.newLabel(config.size.width / 2, config.titlePosX + 22, {text = __('（已获得）'), fontSize = 18, color = '#FFCC52'})
			getLabel:setVisible(false)
			entryNode:addChild(getLabel, 5)
			local titleEffect = nil
			local effectPath = string.format('ui/home/activity/skinCarnival/spine/%s/story_home_effect.json', spinePath)
			if utils.isExistent(effectPath) then
				titleEffect = sp.SkeletonAnimation:create(
					string.format('ui/home/activity/skinCarnival/spine/%s/story_home_effect.json', spinePath),
					string.format('ui/home/activity/skinCarnival/spine/%s/story_home_effect.atlas', spinePath),
				1)
			else
				titleEffect = sp.SkeletonAnimation:create(
					string.format('ui/home/activity/skinCarnival/spine/%s/story_home_effect.json', THEME_SPINE_PATH[tostring(SKIN_CASRNIVAL_THEME.FAIRY_TALE)]),
					string.format('ui/home/activity/skinCarnival/spine/%s/story_home_effect.atlas', THEME_SPINE_PATH[tostring(SKIN_CASRNIVAL_THEME.FAIRY_TALE)]),
				1)
			end
			titleEffect:setAnimation(0, 'idle', true)
			titleEffect:setPosition(cc.p(config.size.width / 2, config.titlePosX + 160))
			entryNode:addChild(titleEffect, 5)
			titleEffect:setVisible(false)
			-- remindIcon
			local remindIcon = display.newImageView(RES_DICT.REMIND_ICON, config.size.width - 5, config.size.height - 5)
			remindIcon:setVisible(false)
			entryNode:addChild(remindIcon, 5)
			table.insert(entryComponentList, {
				entryNode   = entryNode,
				spine       = spine,
				btn         = btn,
				titleEffect = titleEffect,
				getLabel    = getLabel,
				titleLabel  = titleLabel,
				titleLabelPosY = titleLabelPosY,
				remindIcon  = remindIcon,
			})
		end
		self:SetEntryComponentList(entryComponentList)
	-- end
end
--[[
刷新皮肤入口
@params skinData list     皮肤数据
@params tips     map      小红点数据
--]]
function ActivitySkinCarnivalScene:RefreshSkinEntry( skinData, tips )
	local entryComponentList = self:GetEntryComponentList()
	for i, v in ipairs(skinData) do
		local entryComponent = entryComponentList[i]
		if app.cardMgr.IsHaveCardSkin(v.skinId) then
			entryComponent.spine:setAnimation(0, 'play', true)
			entryComponent.titleEffect:setVisible(true)
			entryComponent.getLabel:setVisible(true)
			entryComponent.titleLabel:setColor(ccc3FromInt('#ffcc52'))
			entryComponent.titleLabel:setPositionY(entryComponent.titleLabelPosY + 12)
		else
			entryComponent.getLabel:setVisible(false)
			entryComponent.titleLabel:setColor(ccc3FromInt('#E8DCC9'))
			entryComponent.titleLabel:setPositionY(entryComponent.titleLabelPosY)
		end
		if tips and tips[tostring(i)] then
			entryComponent.remindIcon:setVisible(true)
		else
			entryComponent.remindIcon:setVisible(false)
		end
	end
end
--[[
添加奖励栏
collect          list     奖励列表
collectedSkinNum int      收集到的皮肤数量
callback         function 奖励点击回调
--]]
function ActivitySkinCarnivalScene:AddRewardLayout( collect, collectedSkinNum, callback )
	local viewData = self:GetViewData()
	self:RemoveRewardLayout()
	local size = cc.size(180 * #collect + 210, 189)
	local rewardLayout = CLayout:create(size)
	display.commonUIParams(rewardLayout, {po = cc.p(viewData.chestBtn:getPositionX() - 70, viewData.chestBtn:getPositionY() - 25), ap = display.RIGHT_CENTER})
	rewardLayout:setName('rewardLayout')
	viewData.view:addChild(rewardLayout, 10)
	-- 背景
	local layoutBg = display.newImageView(RES_DICT.REWARD_BG, size.width / 2, size.height / 2, {scale9 = true, size = size, capInsets = cc.rect(30, 30, 351, 129)})
	rewardLayout:addChild(layoutBg, 1)  
	-- 标题
	local titleLabel = display.newLabel(40, size.height - 20, {text = __('收集皮肤，领取奖励'), color = '#F5E098', fontSize = 22, ap = display.LEFT_CENTER})
	rewardLayout:addChild(titleLabel, 1)
	-- 进度条
	local scaleX = (180 * #collect) / 450
	local rewardProgressBar = CProgressBar:create(RES_DICT.REWARD_PROGRESS_BAR)
	rewardProgressBar:setBackgroundImage(RES_DICT.REWARD_PROGRESS_BG)
	rewardProgressBar:setDirection(eProgressBarDirectionLeftToRight)
	rewardProgressBar:setPosition(size.width / 2 - 5, size.height / 2 - 10)
	rewardProgressBar:setScaleX(scaleX)
	rewardProgressBar:setMaxValue(collect[#collect].targetNum)
	rewardProgressBar:setValue(collectedSkinNum)
	rewardLayout:addChild(rewardProgressBar, 1)
	local rewardPorgressTop = display.newImageView(RES_DICT.REWARD_PROGRESS_TOP, size.width / 2 - 5, size.height / 2 - 10)
	rewardPorgressTop:setScaleX(scaleX)
	rewardLayout:addChild(rewardPorgressTop, 2)
	-- 皮肤icon
	local skinIcon = display.newImageView(RES_DICT.SKIN_ICON, 100, size.height / 2 - 5)
	rewardLayout:addChild(skinIcon, 5)
	-- 奖励
	for i, v in ipairs(collect) do
		local highlight = (not v.hasDrawn) and (collectedSkinNum >= checkint(v.targetNum)) and 1 or 0
		local goodsNode = require('common.GoodNode').new({
			id = v.rewards[1].goodsId,
			amount = v.rewards[1].num,
			showAmount = checkint(v.rewards[1].num) > 0,
			callBack = callback,
			highlight = highlight
		})
		rewardLayout:addChild(goodsNode, 3)
		goodsNode:setTag(i)
		goodsNode:setPosition(cc.p(280 + (i - 1) * 180, size.height / 2 - 5))
		if v.hasDrawn then -- 是否领取
			local mask = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.3))
			display.commonUIParams(mask, {ap = display.CENTER, po = utils.getLocalCenter(goodsNode)})
			mask:setContentSize(cc.size(108, 108))
			goodsNode:addChild(mask, 10)
			local checkIcon = display.newImageView(RES_DICT.CHECK_ICON, goodsNode:getContentSize().width / 2, goodsNode:getContentSize().height / 2)
			goodsNode:addChild(checkIcon, 10)
			goodsNode:setEnabled(false)
		end
		local numLabel = display.newLabel(goodsNode:getPositionX(), 20, {text = string.format('%d/%d', math.min(checkint(v.targetNum), collectedSkinNum), v.targetNum), fontSize = 20, color = '#ffffff'})
		rewardLayout:addChild(numLabel, 10)
	end
end
--[[
移除奖励栏
--]]
function ActivitySkinCarnivalScene:RemoveRewardLayout()
	local viewData = self:GetViewData()
	if viewData.view:getChildByName('rewardLayout') then 
		viewData.view:getChildByName('rewardLayout'):runAction(cc.RemoveSelf:create())
	end
end
--[[
皮肤活动进入动画
@params index int 选中的入口序号
--]]
function ActivitySkinCarnivalScene:ChildActivityEnterAction( index )
	local themeId = self:GetThemeId()
	local themeComponent = self:GetThemeComponent()
	local entryComponentList = self:GetEntryComponentList()
	-- 屏蔽所有点击事件
	app.uiMgr:GetCurrentScene():AddViewForNoTouch()
	-- 移除奖励栏
	self:RemoveRewardLayout()
	-- if themeId == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
		for i, v in ipairs(entryComponentList) do
			if i == index then
				-- todo -- 入口spine发光，现在还不知道要怎么发
			else
				-- 其他的spine渐隐
				v.entryNode:runAction(cc.FadeOut:create(0.3))
			end
		end
		-- 背景动画
		self:runAction(
			cc.Spawn:create(
				cc.TargetedAction:create(themeComponent.bgLeft, cc.MoveBy:create(0.3, cc.p(-themeComponent.bgLeft:getContentSize().width, 0))),
				cc.TargetedAction:create(themeComponent.bgRight, cc.MoveBy:create(0.3, cc.p(themeComponent.bgRight:getContentSize().width, 0))),
				cc.TargetedAction:create(themeComponent.bgBottom, cc.MoveBy:create(0.3, cc.p(0, -themeComponent.bgBottom:getContentSize().height))),
				cc.Sequence:create(
					cc.DelayTime:create(0.1),
					cc.CallFunc:create(function()
						local config = self:GetThemeEntryConfig(themeId)[index]
						app:DispatchObservers(ACTIVITY_SKIN_CARNIVAL_ENTER_ACTION_END , {index = index, pos = cc.p(config.x, config.y)})
					end)
				)
			)
		)
	-- end
end
--[[
皮肤活动返回动画
--]]
function ActivitySkinCarnivalScene:ChildActivityBackAction()
	local themeId = self:GetThemeId()
	local themeComponent = self:GetThemeComponent()
	local entryComponentList = self:GetEntryComponentList()
	-- if themeId == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
		for i, v in ipairs(entryComponentList) do
			v.entryNode:runAction(cc.FadeIn:create(0.3))
		end
		-- 背景动画
		self:runAction(
			cc.Spawn:create(
				cc.TargetedAction:create(themeComponent.bgLeft, cc.MoveBy:create(0.3, cc.p(themeComponent.bgLeft:getContentSize().width, 0))),
				cc.TargetedAction:create(themeComponent.bgRight, cc.MoveBy:create(0.3, cc.p(-themeComponent.bgRight:getContentSize().width, 0))),
				cc.TargetedAction:create(themeComponent.bgBottom, cc.MoveBy:create(0.3, cc.p(0, themeComponent.bgBottom:getContentSize().height))),
				cc.Sequence:create(
					cc.DelayTime:create(0.3),
					cc.CallFunc:create(function()
						app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
					end)
				)
			)
		)
	-- end
end
---[[
---获取入口配置
---@param themeId number @主题id
---]]
function ActivitySkinCarnivalScene:GetThemeEntryConfig( themeId )
	if THEME_ENTRY_CONFIG[tostring(themeId)] then
		return THEME_ENTRY_CONFIG[tostring(themeId)]
	else
		return THEME_ENTRY_CONFIG[tostring(SKIN_CASRNIVAL_THEME.FAIRY_TALE)]
	end
end
--[[
设置主题Id
--]]
function ActivitySkinCarnivalScene:SetThemeId( themeId )
	self.themeId = checkint(themeId)
end
--[[
获取主题Id
--]]
function ActivitySkinCarnivalScene:GetThemeId()
	return self.themeId
end
--[[
设置主题组件
@params themeComponent map 主题组件
--]]
function ActivitySkinCarnivalScene:SetThemeComponent( themeComponent )
	self.themeComponent = themeComponent
end
--[[
获取主题组件
--]]
function ActivitySkinCarnivalScene:GetThemeComponent()
	return self.themeComponent
end
--[[
设置入口组件
@params entryComponentList list 入口组件列表
--]]
function ActivitySkinCarnivalScene:SetEntryComponentList( entryComponentList )
	self.entryComponentList = entryComponentList
end
--[[
获取入口组件
--]]
function ActivitySkinCarnivalScene:GetEntryComponentList()
	return self.entryComponentList 
end
--[[
获取viewData
--]]
function ActivitySkinCarnivalScene:GetViewData()
	return self.viewData
end
return ActivitySkinCarnivalScene
