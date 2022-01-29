--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 主界面Scene
--]]
local GameScene = require('Frame.GameScene')
local SpringActivity20HomeScene = class('SpringActivity20HomeScene', GameScene)
local RES_DICT = {
    COMMON_TITLE                    = app.springActivity20Mgr:GetResPath('ui/common/common_title.png'),
    COMMON_TIPS       		        = app.springActivity20Mgr:GetResPath('ui/common/common_btn_tips.png'),
    BG                              = app.springActivity20Mgr:GetResPath('ui/springActivity20/home/garden_main_bg.jpg'),
    BOTTOM_BG                       = app.springActivity20Mgr:GetResPath('ui/springActivity20/home/garden_main_pic_bottom.jpg'),
    COMMON_BTN_BACK                 = app.springActivity20Mgr:GetResPath('ui/common/common_btn_back.png'),
    TOP_BTN_LINE                    = app.springActivity20Mgr:GetResPath('ui/springActivity20/home/garden_main_pic_right2.png'),
    TOP_BTN_BG                      = app.springActivity20Mgr:GetResPath('ui/springActivity20/home/garden_main_pic_right.png'),
    TOP_BTN_RANK                    = app.springActivity20Mgr:GetResPath('ui/springActivity20/home/main_btn_rank.png'),
    TOP_BTN_REWARD                  = app.springActivity20Mgr:GetResPath('ui/springActivity20/home/murder_main_btn_rewards.png'),
    TOP_BTN_STORY                   = app.springActivity20Mgr:GetResPath('ui/springActivity20/home/murder_main_btn_book.png'),
    BTN_TITLE_BG                    = app.springActivity20Mgr:GetResPath('ui/springActivity20/home/garden_main_btn_boss.png'),
    COMMON_BG_TIPS                  = app.springActivity20Mgr:GetResPath('ui/common/common_bg_tips.png'), 
    COMMON_BG_TIPS_HORN             = app.springActivity20Mgr:GetResPath('ui/common/common_bg_tips_horn.png'), 
    -- spine --
    LOTTERY_BTN_SPINE               = app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_main_btn_egg'),
    BOSS_BTN_SPINE                  = app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_main_ico_boss'),
    STAGE_BTN_SPINE                 = app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_main_ico_story'),
    BUFF_BTN_SPINE                  = app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_main_ico_buff'),
    GARDEN_LIGHT_SPINE              = app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_home_light'),
    CLOUD_SPINE                     = app.springActivity20Mgr:GetSpinePath('ui/union/wars/home/management')
}
local TOP_BTN_CONFIG = {
	{title = app.springActivity20Mgr:GetPoText(__('排行榜')),   image = RES_DICT.TOP_BTN_RANK,   tag = 1},
	{title = app.springActivity20Mgr:GetPoText(__('奖励入口')), image = RES_DICT.TOP_BTN_REWARD, tag = 2},
	{title = app.springActivity20Mgr:GetPoText(__('剧情收录')), image = RES_DICT.TOP_BTN_STORY,  tag = 3},
}
function SpringActivity20HomeScene:ctor( ... )
    self.super.ctor(self, 'views.springActivity20.SpringActivity20HomeScene')
    local args = unpack({...})
    self.animation = args.animation
	self:InitUI()
end
--[[
初始化ui
--]]
function SpringActivity20HomeScene:InitUI()
	local CreateView = function ()
		local size = display.size
		local view = CLayout:create(size)
		view:setPosition(size.width / 2, size.height / 2)
		-- 标题板
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = app.springActivity20Mgr:GetPoText(__('秘密花园')), fontSize = 30, color = '#473227',offset = cc.p(0,-10)})
		self:addChild(tabNameLabel, 20)
		-- 提示按钮
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 262, 29)
		tabNameLabel:addChild(tabtitleTips, 1)
		-- 背景
		local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
        view:addChild(bg, 1)

		local dragonSpineData = app.springActivity20Mgr:GetDragonSpine()
		if dragonSpineData then
			local dragonSpine = sp.SkeletonAnimation:create(dragonSpineData.json , dragonSpineData.atlas)
			view:addChild(dragonSpine, 1)
			dragonSpine:setPosition(display.center)
			dragonSpine:setAnimation(0,"idle" , true)
		end
        -- 下方背景
        local bottomBg = display.newImageView(RES_DICT.BOTTOM_BG, size.width / 2, 175)
        view:addChild(bottomBg, 1)
        -- 光点特效
        local lightSpine = sp.SkeletonAnimation:create(
			RES_DICT.GARDEN_LIGHT_SPINE.json,
			RES_DICT.GARDEN_LIGHT_SPINE.atlas,
            1
        )
        lightSpine:setAnimation(0, 'idle', true)
        lightSpine:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(lightSpine, 1)

        -- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
				{
					ap = display.LEFT_CENTER,
					n = RES_DICT.COMMON_BTN_BACK,
					scale9 = true, size = cc.size(90, 70),
					enable = true,
				})
        view:addChild(backBtn, 10)
        -- CommonMoneyBar
	    local moneyBar = require("common.CommonMoneyBar").new()
	    view:addChild(moneyBar, 20)
        ----------------------
        ---- buttonLayout ----
        local buttonLayout = CLayout:create(size)
		buttonLayout:setPosition(size.width / 2, size.height / 2)
		view:addChild(buttonLayout, 5)
        -- 顶部按钮创建	
        local topBtnLine = display.newImageView(RES_DICT.TOP_BTN_LINE, display.size.width - display.SAFE_L + 70, display.height - 80, {ap = display.RIGHT_CENTER})
        buttonLayout:addChild(topBtnLine, 1)
		local topBtnComponentList = {}
		for i, v in ipairs(TOP_BTN_CONFIG) do
			local bg = display.newImageView(RES_DICT.TOP_BTN_BG, 0, 0)
			local bgSize = bg:getContentSize()
            local layout = CLayout:create(bgSize)
			display.commonUIParams(layout, {ap = display.CENTER_TOP, po = cc.p(size.width - display.SAFE_L - (130 * i) + 50, size.height - 70)})
			buttonLayout:addChild(layout, 1)
			bg:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
			layout:addChild(bg, 1)
			local btn = display.newButton(bgSize.width / 2, 100, {n = v.image})
			layout:addChild(btn , 1)
			btn:setTag(v.tag)
			local titleLabel = display.newLabel(bgSize.width / 2, 58, {text = v.title, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, w = 100 , hAlign = display.TAC ,  outline = '#421A03', outlineSize = 1})
			layout:addChild(titleLabel, 1)
			table.insert(topBtnComponentList, {
				layout     = layout,
				btn        = btn, 
				titleLabel = titleLabel,
            })
        end
        -- 抽卡按钮spine
        local lotterySpine = sp.SkeletonAnimation:create(
			RES_DICT.LOTTERY_BTN_SPINE.json,
			RES_DICT.LOTTERY_BTN_SPINE.atlas,
            1
        )
        lotterySpine:setAnimation(0, 'idle', true)
        lotterySpine:setPosition(cc.p(size.width / 2 - 520, size.height / 2 - 270))
        buttonLayout:addChild(lotterySpine, 1)
        -- 抽卡按钮
        local lotteryBtn = display.newButton(size.width / 2 - 520, size.height / 2 - 245, {n = 'empty', scale9 = true, size = cc.size(220, 200)})
        buttonLayout:addChild(lotteryBtn, 1)
        local lotteryBtnLabel = display.newButton(size.width / 2 - 520, size.height / 2 - 325, {n = RES_DICT.BTN_TITLE_BG, enable = false})
        buttonLayout:addChild(lotteryBtnLabel, 2)
        display.commonLabelParams(lotteryBtnLabel, {text = app.springActivity20Mgr:GetPoText(__('卡布扭蛋')), fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#862438', outlineSize = 1, offset = cc.p(0, -3)})
        -- boss按钮spine
        local bossSpine = sp.SkeletonAnimation:create(
			RES_DICT.BOSS_BTN_SPINE.json,
			RES_DICT.BOSS_BTN_SPINE.atlas,
            1
        )
        bossSpine:setAnimation(0, 'idle', true)
        bossSpine:setPosition(cc.p(size.width / 2 + 273, size.height / 2 - 220))
        
        buttonLayout:addChild(bossSpine, 1)
        -- BOSS按钮
        local bossBtn = display.newButton(size.width / 2 + 273, size.height / 2 - 216, {n = 'empty', scale9 = true, size = cc.size(220, 200)})
        buttonLayout:addChild(bossBtn, 1)
        local BossBtnLabel = display.newButton(size.width / 2 + 273, size.height / 2 - 325, {n = RES_DICT.BTN_TITLE_BG, enable = false})
        buttonLayout:addChild(BossBtnLabel, 2)
        display.commonLabelParams(BossBtnLabel, {text = app.springActivity20Mgr:GetPoText(__('入侵通缉')), fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#862438', outlineSize = 1, offset = cc.p(0, -3)})
        -- 关卡按钮spine
        local stageSpine = sp.SkeletonAnimation:create(
			RES_DICT.STAGE_BTN_SPINE.json,
			RES_DICT.STAGE_BTN_SPINE.atlas,
            1
        )
        stageSpine:setAnimation(0, 'play', true)
        stageSpine:setPosition(cc.p(size.width / 2 + 534, size.height / 2 - 210))
        buttonLayout:addChild(stageSpine, 1)
        -- 关卡按钮
        local stageBtn = display.newButton(size.width / 2 + 530, size.height / 2 - 206, {n = 'empty', scale9 = true, size = cc.size(220, 200)})
        buttonLayout:addChild(stageBtn, 1)
        local stageBtnLabel = display.newButton(size.width / 2 + 530, size.height / 2 - 325, {n = RES_DICT.BTN_TITLE_BG, enable = false})
        buttonLayout:addChild(stageBtnLabel, 2)
        display.commonLabelParams(stageBtnLabel, {text = app.springActivity20Mgr:GetPoText(__('剧情活动')), fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#862438', outlineSize = 1, offset = cc.p(0, -3)})
        -- buffSpine
        local lotterySpine = sp.SkeletonAnimation:create(
			RES_DICT.BUFF_BTN_SPINE.json,
			RES_DICT.BUFF_BTN_SPINE.atlas,
            1
        )
        lotterySpine:setAnimation(0, 'idle', true)
		local buffSpinePos = app.springActivity20Mgr:GetBuffSpinePos()
        lotterySpine:setPosition(cc.p(size.width / 2 - 412 +buffSpinePos.x  , size.height / 2 + 182 + buffSpinePos.y))
        buttonLayout:addChild(lotterySpine, 1)
        -- 全服buff按钮
        local buffBtn = display.newButton(size.width / 2 - 408+ buffSpinePos.x , size.height / 2 + 195+ buffSpinePos.y, {n = 'empty', scale9 = true, size = cc.size(130, 130)})
        buttonLayout:addChild(buffBtn, 1)
        display.commonLabelParams(buffBtn, {text = '', color = '#613814', fontSize = 20, ttf = true, font = TTF_GAME_FONT, offset = cc.p(0, - 15)})
        ---- buttonLayout ----
        ----------------------
		return {
			view 	               = view,
            tabNameLabel           = tabNameLabel,
            topBtnComponentList    = topBtnComponentList,
            lotteryBtn             = lotteryBtn,
            bossSpine              = bossSpine,
            bossBtn                = bossBtn,
            stageBtn               = stageBtn,
            backBtn                = backBtn,
            moneyBar		       = moneyBar,
            buffBtn                = buffBtn,
		}
	end
	xTry(function ()
		self.viewData = CreateView()
        self:addChild(self.viewData.view)
        if self.animation then
            self:EnterAction()
        end
	end, __G__TRACKBACK__)
end
--[[
初始化货币栏
--]]
function SpringActivity20HomeScene:InitMoneyBar( moneyIdMap )
    local viewData = self:GetViewData()
    viewData.moneyBar:reloadMoneyBar(moneyIdMap)
end
--[[
刷新buff效果
@params int buff 当前buff效果
--]]
function SpringActivity20HomeScene:RefreshBuff( buff )
    local viewData = self:GetViewData()
    viewData.buffBtn:getLabel():setString(tostring(buff.descr))
end
--[[
刷新boss按钮spine状态
@params isUnlock bool 是否解锁
--]]
function SpringActivity20HomeScene:RefreshBossSpineState( isUnlock )
    local viewData = self:GetViewData()
    viewData.bossSpine:setToSetupPose()
    if isUnlock then
        local key = string.format('SPRING_ACTIVITY_20_UNLOCK_ANIMATION_%d_%d', app.gameMgr:GetUserInfo().playerId, app.springActivity20Mgr:GetActivityId())
        if cc.UserDefault:getInstance():getBoolForKey(key, false) then
            viewData.bossSpine:setAnimation(0, 'play2', true)
        else
            cc.UserDefault:getInstance():setBoolForKey(key, true)
            viewData.bossSpine:setAnimation(0, 'play1', false)
            viewData.bossSpine:addAnimation(0, 'play2', true)
        end
    else
        viewData.bossSpine:setAnimation(0, 'idle', true)
    end
end
--[[
入场动画
--]]
function SpringActivity20HomeScene:EnterAction()
	-- 添加点击屏蔽层
	app.uiMgr:GetCurrentScene():AddViewForNoTouch()
	local viewData = self:GetViewData()
	local tabNameLabelPos = cc.p(viewData.tabNameLabel:getPosition())
	viewData.tabNameLabel:setPositionY(display.height + 100)

	local cloudSpine = sp.SkeletonAnimation:create(
        RES_DICT.CLOUD_SPINE.json,
        RES_DICT.CLOUD_SPINE.atlas,
        1
    )
	cloudSpine:setAnimation(0, 'play', false)
	cloudSpine:setPosition(display.center)
    sceneWorld:addChild(cloudSpine, GameSceneTag.Dialog_GameSceneTag)
    
	cloudSpine:registerSpineEventHandler(function ()
    	-- 弹出标题板
		local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
		viewData.tabNameLabel:runAction( action )
		-- 移除spine自身
		cloudSpine:runAction(cc.RemoveSelf:create())
		-- 移除点击屏蔽层
		app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
	end, sp.EventType.ANIMATION_COMPLETE)
end
--[[
获取viewData
--]]
function SpringActivity20HomeScene:GetViewData()
	return self.viewData
end
return SpringActivity20HomeScene
