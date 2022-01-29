--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 Boss选择Scene
--]]
local SpringActivity20SpBossView = class('SpringActivity20SpBossView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.murder.SpringActivity20SpBossView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BOSS_BG              = app.springActivity20Mgr:GetResPath('ui/springActivity20/spBoss/garden_bird_bg_door.png'),
    BOTTOM_BG            = app.springActivity20Mgr:GetResPath('ui/springActivity20/spBoss/garden_bird_bg_table.png'),
    PROGRESS_BAR_BG      = app.springActivity20Mgr:GetResPath('ui/springActivity20/spBoss/garden_bird_line_hp_bottom.png'),
    PROGRESS_BAR         = app.springActivity20Mgr:GetResPath('ui/springActivity20/spBoss/garden_bird_line_hp_top.png'),
    BOSS_DETAIL_BG 		 = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_btn_search.png'),
    BUFF_BG              = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_buff.png'),
    BUFF_ICON   	     = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_ico_buff.png'),
    LEVEL_UP_ARROW		 = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_pic_lv.png'),
    BUFF_PROGRESS_BAR_BG = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_line_lv_bottom.png'),
    BUFF_PROGRESS_BAR    = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_line_lv_top.png'),
    ADD_ICON             = app.springActivity20Mgr:GetResPath('ui/common/maps_fight_btn_pet_add.png'),
	CARD_HEAD_BG         = app.springActivity20Mgr:GetResPath('ui/common/kapai_frame_bg_nocard.png'),
    COST_BG              = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_ticket.png'),
    TEAM_BG              = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_bottom.png'),
    SPLIT_LINE           = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_line_lv.png'),
    REWARDS_BG           = app.springActivity20Mgr:GetResPath('ui/springActivity20/spBoss/garden_bird_bg_reward.png'),
    RANK_TEXT_BG         = app.springActivity20Mgr:GetResPath('ui/springActivity20/spBoss/garden_bird_bg_list.png'),
    COMMON_TITLE_5       = app.springActivity20Mgr:GetResPath('ui/common/common_title_5.png'),
    COMMON_BTN_BACK      = app.springActivity20Mgr:GetResPath('ui/common/common_btn_back.png'),

    -- spine --     
    BOSS_SPINE           = app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_boss_cage'),
}
function SpringActivity20SpBossView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function SpringActivity20SpBossView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)

        		-- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
        {
            ap = display.LEFT_CENTER,
            n = RES_DICT.COMMON_BTN_BACK,
            scale9 = true, size = cc.size(90, 70),
            enable = true,
        })
        view:addChild(backBtn, 10)
        ----------------------
		----- bossLayout -----
		local bossLayoutSize = cc.size(521, 476)
        local bossLayout = CLayout:create(bossLayoutSize)
		bossLayout:setAnchorPoint(display.CENTER)
		bossLayout:setPosition(cc.p(size.width / 2, size.height / 2 + 102))
        view:addChild(bossLayout, 5)
        local bossBg = display.newImageView(RES_DICT.BOSS_BG, bossLayoutSize.width / 2, bossLayoutSize.height / 2)
        bossLayout:addChild(bossBg, 1)
        local bossSpine = sp.SkeletonAnimation:create(
            RES_DICT.BOSS_SPINE.json,
            RES_DICT.BOSS_SPINE.atlas,
            1
        )
        bossSpine:setAnimation(0, 'idle', true)
        bossSpine:setPosition(cc.p(bossLayoutSize.width / 2, 20))
        bossLayout:addChild(bossSpine, 1)
        local bossLabel = display.newLabel(bossLayoutSize.width / 2, bossLayoutSize.height - 100, {text = app.springActivity20Mgr:GetPoText(__('立即阻止三炙鸟')), fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#2B1711', outlineSize = 2})
        bossLayout:addChild(bossLabel, 1)
		-- boss详情
		local bossDetailBtn = display.newButton(0, 0, {scale9 = true ,  scale9 = true ,size =  cc.size(200, 45) ,n = RES_DICT.BOSS_DETAIL_BG, ap = display.LEFT_BOTTOM})
		bossLayout:addChild(bossDetailBtn, 5)
		display.commonLabelParams(bossDetailBtn, {text = app.springActivity20Mgr:GetPoText(__('BOSS详情')), fontSize = 20, color = '#FFFFFF', offset = cc.p(10, -2)})
		----- bossLayout -----
        ----------------------

        ----------------------
        ---- bottomLayout ----
        local bottomLayoutSize = size
        local bottomLayout = CLayout:create(bottomLayoutSize)
		bottomLayout:setAnchorPoint(display.CENTER)
		bottomLayout:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bottomLayout, 5)
        -- bg
        local bottomLayoutBg = display.newImageView(RES_DICT.BOTTOM_BG, size.width / 2, 0, {ap = display.CENTER_BOTTOM})
        bottomLayout:addChild(bottomLayoutBg, 1)
        -- 排行数据
        local rankBg = display.newImageView(RES_DICT.REWARDS_BG, display.width / 2 - 520, 60, {ap = display.CENTER_BOTTOM})
        bottomLayout:addChild(rankBg, 1)
		local rankBgSize = rankBg:getContentSize()
        local leastCatchTimeTextLabel = display.newLabel(rankBgSize.width / 2, rankBgSize.height - 60, {text = app.springActivity20Mgr:GetPoText(__("最短阻止次数")), fontSize = 20, color = '#CDBC97', ttf = true, font = TTF_GAME_FONT, outline = '#4C0F0E', outlineSize = 1})
        rankBg:addChild(leastCatchTimeTextLabel, 1)
        local leastCatchTimeBg = display.newImageView(RES_DICT.RANK_TEXT_BG, rankBgSize.width / 2 - 10, rankBgSize.height - 100)
        rankBg:addChild(leastCatchTimeBg, 1)
        local leastCatchTimeLabel = display.newLabel(leastCatchTimeBg:getContentSize().width / 2, leastCatchTimeBg:getContentSize().height / 2, {text = '', fontSize = 22, color = '#FFFFFF'})
        leastCatchTimeBg:addChild(leastCatchTimeLabel, 1)
        local splitLine = display.newImageView(RES_DICT.SPLIT_LINE, rankBgSize.width / 2, rankBgSize.height - 144)
        splitLine:setScale(1.5)
        rankBg:addChild(splitLine, 1)
        local fastestCatchTimeTextLabel = display.newLabel(rankBgSize.width / 2, rankBgSize.height - 184, {text = app.springActivity20Mgr:GetPoText(__("最快阻止时间")), fontSize = 20, color = '#CDBC97', ttf = true, font = TTF_GAME_FONT, outline = '#4C0F0E', outlineSize = 1})
        rankBg:addChild(fastestCatchTimeTextLabel, 1)
        local fastestCatchTimeBg = display.newImageView(RES_DICT.RANK_TEXT_BG, rankBgSize.width / 2 - 10, rankBgSize.height - 224)
        rankBg:addChild(fastestCatchTimeBg, 1)
        local fastestCatchTimeLabel = display.newLabel(fastestCatchTimeBg:getContentSize().width / 2, fastestCatchTimeBg:getContentSize().height / 2, {text = '', fontSize = 22, color = '#FFFFFF'})
        fastestCatchTimeBg:addChild(fastestCatchTimeLabel, 1)
        -- 击败奖励
        local rewardsBg = display.newImageView(RES_DICT.REWARDS_BG, display.width / 2 + 520, 60, {ap = display.CENTER_BOTTOM})
        bottomLayout:addChild(rewardsBg, 1)
        local rewardsTitle = display.newButton(rewardsBg:getContentSize().width / 2, rewardsBg:getContentSize().height - 60, { scale9 = true , n = RES_DICT.COMMON_TITLE_5})
        rewardsBg:addChild(rewardsTitle, 1)
        display.commonLabelParams(rewardsTitle, {paddingW = 25 ,  text = app.springActivity20Mgr:GetPoText(__('击败奖励')), fontSize = 20, color = '#76553b'})
        local rewardsLayer = display.newLayer(display.width / 2 + 520, 60, {size = rewardsBg:getContentSize(), ap = display.CENTER_BOTTOM})
		bottomLayout:addChild(rewardsLayer, 5)
		-- 编队背景
		local teamBg = display.newImageView(RES_DICT.TEAM_BG, bottomLayoutSize.width / 2, 0, {ap = display.CENTER_BOTTOM})
		bottomLayout:addChild(teamBg, 1)
		-- buff按钮背景
		local buffBtnBg = display.newImageView(RES_DICT.BUFF_BG, bottomLayoutSize.width / 2 - 515,  75)
		bottomLayout:addChild(buffBtnBg, 2)
	    -- buff图标
		local buffBtn = display.newButton(bottomLayoutSize.width / 2 - 515,  115, {n = RES_DICT.BUFF_ICON})
		bottomLayout:addChild(buffBtn, 3)
		display.commonLabelParams(buffBtn, {text = '', fontSize = 18, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#421A03', outlineSize = 1, offset= cc.p(5, -20)})
		-- 当前buff加成
		local currentBuffLabel = display.newLabel(buffBtnBg:getContentSize().width / 2 - 20, 50, {text = '', fontSize = 20, color = '#FFFFFF', ap = display.RIGHT_CENTER})
		buffBtnBg:addChild(currentBuffLabel, 5)
		-- 升级箭头
		local arrowIcon = display.newImageView(RES_DICT.LEVEL_UP_ARROW, buffBtnBg:getContentSize().width / 2, 50)
		buffBtnBg:addChild(arrowIcon, 5)
		-- 下级buff加成
		local nextBuffLabel = display.newLabel(buffBtnBg:getContentSize().width / 2 + 20, 50, {text = '', fontSize = 20, color = '#FFFFFF', ap = display.LEFT_CENTER})
		buffBtnBg:addChild(nextBuffLabel, 5)
		-- buff进度条
        local accProgressBar = CProgressBar:create(RES_DICT.BUFF_PROGRESS_BAR)
        accProgressBar:setBackgroundImage(RES_DICT.BUFF_PROGRESS_BAR_BG)
        accProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        accProgressBar:setPosition(cc.p(buffBtnBg:getContentSize().width / 2, 28))
        buffBtnBg:addChild(accProgressBar, 5)
        -- 满级提示
		local buffMaxTipsLabel = display.newLabel(buffBtnBg:getContentSize().width / 2, 40, {text = app.springActivity20Mgr:GetPoText(__('BUFF值已达到上限')), fontSize = 20, color = '#FFFFFF'})
		buffBtnBg:addChild(buffMaxTipsLabel, 5)
		-- 卡牌头像背景
        local cardHeadBtnlist = {}
        for i = 1, 5 do
            local cardHeadBtn = display.newButton(bottomLayoutSize.width / 2  + ((i - 3) * 102), 72, {n = RES_DICT.CARD_HEAD_BG})
            cardHeadBtn:setScale(0.52)
            bottomLayout:addChild(cardHeadBtn, 5)
            local addIcon = display.newImageView(RES_DICT.ADD_ICON, bottomLayoutSize.width / 2  + ((i - 3) * 102), 72)
            bottomLayout:addChild(addIcon, 5)
            table.insert(cardHeadBtnlist, cardHeadBtn)
        end
        -- cardHeadLayout
		local cardHeadLayout = CLayout:create(cc.size(502, 120))
        cardHeadLayout:setPosition(bottomLayoutSize.width / 2, 72)
		bottomLayout:addChild(cardHeadLayout, 5)
		-- 挑战按钮
		local battleBtn = require('common.CommonBattleButton').new({
			pattern = 1,
		})
		battleBtn:setPosition(cc.p(bottomLayoutSize.width / 2 + 515, 115))
        bottomLayout:addChild(battleBtn, 5)
        -- boss血条
        local bossHpBar = CProgressBar:create(RES_DICT.PROGRESS_BAR)
        bossHpBar:setBackgroundImage(RES_DICT.PROGRESS_BAR_BG)
        bossHpBar:setDirection(eProgressBarDirectionLeftToRight)
        bossHpBar:setPosition(cc.p(bottomLayoutSize.width / 2, 222))
        bottomLayout:addChild(bossHpBar, 5)
        local bossHpLabel = display.newLabel(bossHpBar:getContentSize().width / 2, bossHpBar:getContentSize().height / 2, {text = '0/1000', fontSize = 20, color = '#2A180F'})
        bossHpBar:addChild(bossHpLabel, 1)
        ---- bottomLayout ----
        ----------------------
        
        return {
            size                  = size,
            view                  = view,
            bossDetailBtn         = bossDetailBtn,
            leastCatchTimeLabel   = leastCatchTimeLabel,
            fastestCatchTimeLabel = fastestCatchTimeLabel,
            rewardsLayer          = rewardsLayer,
            cardHeadBtnlist       = cardHeadBtnlist,
            cardHeadLayout        = cardHeadLayout,
            bossHpBar             = bossHpBar,
            bossHpLabel           = bossHpLabel,
            backBtn               = backBtn,
            battleBtn             = battleBtn,
            buffBtn               = buffBtn,
            currentBuffLabel      = currentBuffLabel,
            arrowIcon             = arrowIcon,
            nextBuffLabel         = nextBuffLabel,
            accProgressBar        = accProgressBar,
            buffMaxTipsLabel      = buffMaxTipsLabel,
            bossSpine             = bossSpine,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self.viewData.view:setPosition(display.center)
        self:addChild(self.viewData.view)
    end, __G__TRACKBACK__)
end
--[[
刷新编队
@params team list 编队信息
--]]
function SpringActivity20SpBossView:RefreshTeam( team )
	local viewData = self:GetViewData()
	viewData.cardHeadLayout:removeAllChildren()
    for i, v in ipairs(team[1]) do
        if v.id and checkint(v.id) > 0 then
            local cardHeadNode = require('common.CardHeadNode').new({id = checkint(v.id), showActionState = false})
            cardHeadNode:setPosition(cc.p(47 + 102 * (i - 1), viewData.cardHeadLayout:getContentSize().height / 2))
            cardHeadNode:setEnabled(false)
            cardHeadNode:setScale(0.5)
            viewData.cardHeadLayout:addChild(cardHeadNode)
        end
    end
end
--[[
刷新特殊boss信息
--]]
function SpringActivity20SpBossView:RefreshSpBossInfo( spBossData )
    local viewData = self:GetViewData()
    viewData.leastCatchTimeLabel:setString(string.fmt(app.springActivity20Mgr:GetPoText(__('_num_次')), {['_num_'] = checkint(spBossData.times) == 0 and '--' or checkint(spBossData.times)}))
    viewData.fastestCatchTimeLabel:setString(string.fmt(app.springActivity20Mgr:GetPoText(__('_num_秒')), {['_num_'] = checkint(spBossData.duration) == 0 and '--' or checkint(spBossData.duration)}))
    if spBossData.hp then
        viewData.bossHpBar:setMaxValue(checkint(spBossData.maxHp))
        viewData.bossHpBar:setValue(checkint(spBossData.hp))
        viewData.bossHpLabel:setString(string.format('%d/%d', checkint(spBossData.hp), checkint(spBossData.maxHp)))
    else
        viewData.bossHpBar:setVisible(false)
    end
    for i, v in ipairs(spBossData.rewards) do
		local goodsNode = require('common.GoodNode').new({
			id = checkint(v.goodsId),
			amount = checkint(v.num),
			showAmount = true,
			callBack = function (sender)
				app.uiMgr:ShowInformationTipsBoard({
					targetNode = sender, iconId = checkint(v.goodsId), type = 1
				})
			end
		})
		goodsNode:setPosition(cc.p(viewData.rewardsLayer:getContentSize().width / 2 -184 + i * 92, viewData.rewardsLayer:getContentSize().height - 155))
		goodsNode:setScale(0.8)
		viewData.rewardsLayer:addChild(goodsNode, 1)
    end
end
--[[
刷新buff
--]]
function SpringActivity20SpBossView:RefreshBuff( buff )
    local viewData = self:GetViewData()
	local hasNextLevel = buff.nextCollectNum and true or false
	viewData.currentBuffLabel:setVisible(hasNextLevel)
	viewData.arrowIcon:setVisible(hasNextLevel)
	viewData.nextBuffLabel:setVisible(hasNextLevel)
	viewData.accProgressBar:setVisible(hasNextLevel)
	viewData.buffMaxTipsLabel:setVisible(not hasNextLevel)
	if buff.nextCollectNum then
		viewData.currentBuffLabel:setString(buff.descr)
		viewData.nextBuffLabel:setString(buff.nextDescr)
		viewData.accProgressBar:setMaxValue(checkint(buff.nextCollectNum))
		viewData.accProgressBar:setValue(checkint(buff.damagePlus))
	end
	viewData.buffBtn:getLabel():setString(buff.descr)
end
--[[
捕捉特殊boss
--]]
function SpringActivity20SpBossView:CatchSpBoss()
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    local viewData = self:GetViewData()
    viewData.bossSpine:setToSetupPose()
    viewData.bossSpine:clearTrack(0)
    viewData.bossSpine:registerSpineEventHandler(function (event)
        if event.animation == 'play3' then
            app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
            app:DispatchObservers('SPRING_ACTIVITY_20_CATCH_SP_BOSS')
            app:UnRegsitMediator("springActivity20.SpringActivity20SpBossMediator")
		end
	end, sp.EventType.ANIMATION_END)
    viewData.bossSpine:setAnimation(0, 'play1', false)
    viewData.bossSpine:addAnimation(0, 'play3', false)
end
--[[
获取viewData
--]]
function SpringActivity20SpBossView:GetViewData()
    return self.viewData
end
return SpringActivity20SpBossView