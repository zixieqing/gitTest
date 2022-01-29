--[[
活动副本地图关卡node
--]]
local ActivityMapStageNode = class('ActivityMapStageNode', function ()
	local node = CLayout:create()
	node.name = 'Game.views.activityMap.ActivityMapStageNode'
	node:enableNodeEvents()
	return node
end)
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function ActivityMapStageNode:ctor( ... )
	local args = unpack({...})
	self.stageDatas = checktable(args.stageDatas)
	self.stageType = checkint(self.stageDatas.questType or 1)
	self.stageId = checkint(self.stageDatas.id)
	self:InitUI()
end
--[[
init ui
--]]
function ActivityMapStageNode:InitUI()
	local stageType = self.stageType
	local stageDatas = self.stageDatas
	------------------------------
	-- stageDatas.isDrawFinalRewards = true
	------------------------------
	local function CreateView()
		local bgSize = nil
		local bgBtn = nil
		local resetBtn = nil
		local drawBtn = nil
		local view = CLayout:create()
		-- 标题
		local titleLabel = display.newLabel(0, 0, {fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, text = stageDatas.checkpointName})
		local titleSize = cc.size(display.getLabelContentSize(titleLabel).width + 34, display.getLabelContentSize(titleLabel).height + 6)
		local titleBg = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_name_bg.png'), 0, 0, {scale9 = true, size = titleSize})
		titleBg:addChild(titleLabel)
		titleLabel:setPosition(cc.p(titleSize.width/2, titleSize.height/2))
		if stageType == ActivityQuestType.BATTLE then -- 关卡
			local stageConf = CommonUtils.GetConfig('activityQuest', 'quest', checkint(self.stageId))
			local iconMonsterId = string.split(stageConf.icon, ';')[1]
			local iconMonsterConf = CardUtils.GetCardConfig(iconMonsterId)
			local icon = tostring(iconMonsterConf.drawId or iconMonsterId)
			if checkint(stageDatas.isPassed) > 0 then -- 是否通关
				bgSize = cc.size(110, 180)
				view:setContentSize(bgSize)
				self:setAnchorPoint(cc.p(0.5, 0.17))
				bgBtn = display.newButton(bgSize.width/2, 120, {n = _res('ui/common/maps_btn_pass_bg.png')})
				view:addChild(bgBtn, 3)
				-- 创建关卡怪物头像
				local headIconBg = display.newNSprite(_res('ui/common/maps_btn_pass_head.png'), 0, 0)
            	local headIconPath = AssetsUtils.GetCardHeadPath(icon)
				local headIcon = display.newNSprite(_res(headIconPath), 0, 0)

				local headClipNode = cc.ClippingNode:create()
				headClipNode:setContentSize(headIconBg:getContentSize())
				headClipNode:setAnchorPoint(cc.p(0.5, 0.5))
				headClipNode:setPosition(cc.p(
					bgSize.width * 0.5,
					130)) 
				view:addChild(headClipNode, 3)
	
				headIcon:setScale(0.575)
				headIcon:setPosition(utils.getLocalCenter(headClipNode))
				headClipNode:addChild(headIcon)
	
				headClipNode:setInverted(false)
				headClipNode:setAlphaThreshold(0.1)
				headIconBg:setPosition(utils.getLocalCenter(headClipNode))
				headClipNode:setStencil(headIconBg)
			else
				local scale = 0.4
				self:setAnchorPoint(cc.p(0.5, 0.17))
				bgBtn = display.newButton(0, 0, {n = _res('ui/common/story_tranparent_bg.png'), ap = cc.p(0.5, 0)})
				bgSize = cc.size(140, 140 + 20)
				view:setContentSize(bgSize)
				bgBtn:setContentSize(bgSize)
				self:setAnchorPoint(cc.p(0.5, 30/bgSize.height))
				bgBtn:setPosition(cc.p(bgSize.width/2, 40))
				view:addChild(bgBtn, 5)
				local bgImg = FilteredSpriteWithOne:create(AssetsUtils.GetCartoonPath(icon))
				bgImg:setPosition(bgSize.width/2, 10)
				bgImg:setAnchorPoint(cc.p(0.5, 0))
				--AssetsUtils.GetCartoonNode(icon, bgSize.width/2, 10, {ap = cc.p(0.5, 0)})
				bgImg:setScale(scale)
				bgBtn:addChild(bgImg)
				-- view:addChild(display.newLayer(bgSize.width/2, 40, {size= bgSize, color = cc.r4b(150), ap = cc.p(0.5,0)}))
				if stageDatas.isLock then
					bgImg:setFilter(GrayFilter:create())
				else
					bgImg:clearFilter()
				end
				if checkint(stageDatas.newestQuestId) > 0 then -- 是否为当前关卡

					-- 创建刀叉
					local forkSpine = sp.SkeletonAnimation:create('arts/effects/map_fighting_fork.json', 'arts/effects/map_fighting_fork.atlas', 1)
					forkSpine:update(0)
					forkSpine:addAnimation(0, 'idle', true)
					view:addChild(forkSpine, 5)
					forkSpine:setPosition(cc.p(bgSize.width/2, bgSize.height))
				end
				
			end
			-- 节点阴影
			local shadow = display.newNSprite(_res('ui/common/maps_ico_monster_shadow.png'), bgSize.width * 0.5, 58)
			shadow:setScale(0.7)
			view:addChild(shadow, 1)
			-- 添加标题
			view:addChild(titleBg, 5)
			display.commonUIParams(titleBg, {po = cc.p(bgSize.width/2, 18)})
		elseif stageType == ActivityQuestType.STORY or stageType == ActivityQuestType.PURE_STORY then -- 剧情
			bgSize = cc.size(130, 180)
			view:setContentSize(bgSize)
			self:setAnchorPoint(cc.p(0.5, 0.12))
			-- 头像
			bgBtn = display.newButton(bgSize.width/2, 110, {n = _res('ui/home/activity/activityQuest/activity_maps_btn_plot.png')})
			view:addChild(bgBtn, 3)
			local frame = display.newImageView(_res("ui/home/activity/activityQuest/activity_maps_btn_plot_up.png"), bgSize.width/2, 110)
			view:addChild(frame, 4)
			local iconId = string.split(stageDatas.icon, ';')[1]
			local headPath = nil
			local bgBtnSize = bgBtn:getContentSize()
			if checkint(iconId) < 10000 then
				local headIcon = FilteredSpriteWithOne:create(_res(headPath))
				headIcon:setPosition(bgBtnSize.width/2 , bgBtnSize.height/2)
				bgBtn:addChild(headIcon, 1)
				headIcon:setScale(0.575)
				if stageDatas.isLock then
					headIcon:setFilter(GrayFilter:create())
				else
					headIcon:clearFilter()
				end
			else 
				headPath = CardUtils.GetCardHeadPathBySkinId(iconId)
				if utils.isExistent(headPath) then
					-- 裁头像
					local headClipNode = cc.ClippingNode:create()
					headClipNode:setScale(0.84)
					headClipNode:setPosition(cc.p(bgBtn:getContentSize().width/2, bgBtn:getContentSize().height/2))
					bgBtn:addChild(headClipNode, 3)
			
					local stencilNode = display.newNSprite(_res('ui/home/activity/activityQuest/activity_maps_btn_plot.png'), 0, 0)
					stencilNode:setScale(1)
					headClipNode:setAlphaThreshold(0.1)
					headClipNode:setStencil(stencilNode)
					--local headNode = display.newImageView(headPath, 0, 0)
					local headNode = FilteredSpriteWithOne:create(headPath)
					headNode:setPosition(0,0)
					headNode:setScale(0.65)
					headClipNode:addChild(headNode)
					if stageDatas.isLock then
						headNode:setFilter(GrayFilter:create())
					else
						headNode:clearFilter()
					end
				end
			end
			-- 节点阴影
			local shadow = display.newNSprite(_res('ui/common/maps_ico_monster_shadow.png'), bgSize.width * 0.5, 58)
			shadow:setScale(0.7)
			view:addChild(shadow, 1)
			if stageDatas.isDrawn > 0 then -- 是否领取最终奖励
				local headMask = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_head_mask.png'), bgSize.width/2, 110)
				view:addChild(headMask, 10)
				headMask:setScale(0.89)
				bgBtn:setEnabled(false)
			else
				-- 重置按钮
				resetBtn = display.newButton(bgSize.width - 33, bgSize.height - 33, {n = _res('ui/home/activity/activityQuest/activity_maps_btn_refresh.png')})
				view:addChild(resetBtn, 5)
				bgBtn:setEnabled(false)
				if checkint(stageDatas.isPassed) > 0 then
					-- 好感度
					if stageDatas.content then
						local selectData = stageDatas.content.selected[tostring(stageDatas.content.lastSelectId)]
						local heartColor = 'gray'
						if checkint(selectData.point) > 0 then
							heartColor = stageDatas.roleColor[tostring(selectData.pointId)]
						end
						local heartBg = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_plot_rumber.png'), bgSize.width/2, 58)
						view:addChild(heartBg, 5)
						local heartImg = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_heart_' .. heartColor .. '.png'), 30, 26)
						heartBg:addChild(heartImg, 1)
						local heartPoint = display.newLabel(75, heartBg:getContentSize().height/2, {text = string.format('+%d', checkint(selectData.point)), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
						heartBg:addChild(heartPoint, 3)
					end
					if checkint(stageDatas.resetTimes) <= 0 then
						resetBtn:setVisible(false)
					end
				else
					resetBtn:setVisible(false)
					bgBtn:setEnabled(true)
				end
				local forkSpine
				if checkint(stageDatas.newestQuestId) > 0 then -- 是否为当前关卡
					-- 创建刀叉
					forkSpine= sp.SkeletonAnimation:create('arts/effects/map_fighting_fork.json', 'arts/effects/map_fighting_fork.atlas', 1)
					forkSpine:update(0)
					forkSpine:addAnimation(0, 'idle', true)
					view:addChild(forkSpine, 5)
					forkSpine:setPosition(cc.p(bgSize.width/2, bgSize.height))
				end
				if stageType == ActivityQuestType.PURE_STORY  then
					resetBtn:setVisible(false)
					forkSpine:setVisible(false)
				end
			end
			-- 添加标题
			view:addChild(titleBg, 5)
			display.commonUIParams(titleBg, {po = cc.p(bgSize.width/2, 22)})
		elseif stageType == ActivityQuestType.CHEST then -- 宝箱
			bgSize = cc.size(200, 220)
			view:setContentSize(bgSize)
			self:setAnchorPoint(cc.p(0.5, 0.3))
			local chestConfig = CommonUtils.GetConfig('activityQuest', 'questChest', stageDatas.zoneId)
			local roleId = chestConfig[tostring(stageDatas.id)].roleId
			local coordinateConfig = CommonUtils.GetConfig('activityQuest', 'coordinate', chestConfig[tostring(stageDatas.id)].roleId)
			local cardId = coordinateConfig.roleId
			local roleColor = stageDatas.roleColor[tostring(roleId)]
			local point = checkint(stageDatas.points[tostring(roleId)])
			local maxPoint = checkint(chestConfig[tostring(stageDatas.id)].point)
			stageDatas.chestReward = chestConfig[tostring(stageDatas.id)].rewards
			stageDatas.consume = chestConfig[tostring(stageDatas.id)].consume
			-- 宝箱
			bgBtn = display.newButton(bgSize.width/2, 170, {n = _res('arts/goods/goods_icon_191006.png')})
			view:addChild(bgBtn, 1)
			-- 进度条 --
        	local progressBar = CProgressBar:create(_res('ui/home/activity/activityQuest/activity_maps_bar_' .. roleColor .. '_s_2.png'))
        	progressBar:setBackgroundImage(_res('ui/home/activity/activityQuest/activity_maps_bar_s_3.png'))
        	progressBar:setDirection(eProgressBarDirectionLeftToRight)
        	progressBar:setAnchorPoint(cc.p(0.5, 0.5))
        	progressBar:setPosition(cc.p(bgSize.width/2 + 15, 112))
        	view:addChild(progressBar, 3)
    		progressBar:setMaxValue(maxPoint)
			progressBar:setValue(point)

        	-- 边框
        	local progressBarFrame = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_bar_s_1.png'), bgSize.width/2 + 15, 102)
        	view:addChild(progressBarFrame, 4)
        	-- 进度
        	local progressLabel = display.newLabel(bgSize.width/2 + 15, 112, {text = string.format('%s/%s', tostring(math.min(point, checkint(chestConfig[tostring(stageDatas.id)].point))), tostring(chestConfig[tostring(stageDatas.id)].point)), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
        	view:addChild(progressLabel, 5)
        	-- 头像
        	local headBg = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_head_' .. roleColor .. '.png'), 30, 112)
			view:addChild(headBg, 5)
			local headPath = CardUtils.GetCardHeadPathByCardId(cardId)
			if utils.isExistent(headPath) then
				-- 裁头像
				local headClipNode = cc.ClippingNode:create()
				headClipNode:setScale(0.75)
				headClipNode:setPosition(cc.p(headBg:getContentSize().width/2, headBg:getContentSize().height/2))
				headBg:addChild(headClipNode, 5)
		
				local stencilNode = display.newNSprite(_res('ui/home/activity/activityQuest/activity_maps_head_blue.png'), 0, 0)
				stencilNode:setScale(1)
				headClipNode:setAlphaThreshold(0.1)
				headClipNode:setStencil(stencilNode)
				--local headNode = display.newNSprite(_res(headPath), 0, 0)
				local headNode =  FilteredSpriteWithOne:create(_res(headPath))
				headNode:setScale(0.45)
				headClipNode:addChild(headNode)
				if stageDatas.isLock then
					headNode:setFilter(GrayFilter:create())
				else
					headNode:clearFilter()
				end
			end
			local headFrame = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_head_1.png'), headBg:getContentSize().width/2, headBg:getContentSize().height/2)
			headBg:addChild(headFrame, 5)
			-- 添加标题
			view:addChild(titleBg, 3)
			display.commonUIParams(titleBg, {po = cc.p(bgSize.width/2, 75)})

			if checkint(stageDatas.isPassed) > 0 then
				-- 奖励已经领取
				local drawImg = display.newImageView(_res('ui/home/activity/activity_love_lunch_ico_have.png'), bgSize.width/2, 170)
				view:addChild(drawImg, 5)
				drawImg:setRotation(-30)
				bgBtn:setEnabled(false)
			end
		end
		return {
			view     = view,
			bgSize   = bgSize,
			bgBtn    = bgBtn,
			resetBtn = resetBtn,
		}
	end
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:setContentSize(self.viewData_.bgSize)
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(self.viewData_.bgSize.width/2, self.viewData_.bgSize.height/2)
       	self.viewData_.bgBtn:setOnClickScriptHandler(handler(self, self.BgBtnCallback))
       	if self.viewData_.resetBtn then
       		self.viewData_.resetBtn:setOnClickScriptHandler(handler(self, self.StoryResetBtnCallback))
       	end
    end, __G__TRACKBACK__)
end
--[[
背景点击回调
--]]
function ActivityMapStageNode:BgBtnCallback( sender )
	PlayAudioByClickNormal()
	if self.stageType == ActivityQuestType.BATTLE then
		AppFacade.GetInstance():DispatchObservers(ACTIVITY_QUEST_BATTLE_EVENT, {stageDatas = self.stageDatas})
	elseif self.stageType == ActivityQuestType.STORY or self.stageType == ActivityQuestType.PURE_STORY then
		AppFacade.GetInstance():DispatchObservers(ACTIVITY_QUEST_STORY_EVENT, {stageDatas = self.stageDatas})
	elseif self.stageType == ActivityQuestType.CHEST then
		AppFacade.GetInstance():DispatchObservers(ACTIVITY_QUEST_CHEST_DRAW_EVENT, {stageDatas = self.stageDatas})
	end
end
--[[
剧情重置按钮回调
--]]
function ActivityMapStageNode:StoryResetBtnCallback( sender )
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers(ACTIVITY_QUEST_RESET_STORY_EVENT, {stageDatas = self.stageDatas})
end
return ActivityMapStageNode
