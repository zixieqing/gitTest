--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 Boss选择Scene
--]]
local GameScene = require('Frame.GameScene')
local SpringActivity20BossScene = class('SpringActivity20BossScene', GameScene)

local STAGE_LOCK_STATE = {
    LOCK = 1,
    UNLOCK = 2,
}
local RES_DICT = {
    COMMON_TITLE                    = app.springActivity20Mgr:GetResPath('ui/common/common_title.png'),
	COMMON_TIPS       		        = app.springActivity20Mgr:GetResPath('ui/common/common_btn_tips.png'),
    COMMON_BTN_BACK                 = app.springActivity20Mgr:GetResPath('ui/common/common_btn_back.png'),
    BG                              = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg.jpg'),
    BOSS_INFO_BG                    = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_paper.png'),
	BOSS_LIST_BG                    = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_lv.png'),
	BOSS_IMG  						= app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_boss.png'),
	BOSS_NAME_BG   					= app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_name.png'),
	BOSS_DETAIL_BG 					= app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_btn_search.png'),
	REWARDS_BG 						= app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_awad.png'),
	REWARDS_DRAW_BG                 = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_prince_bg_get.png'),
	COMMON_TITLE_BG_3 			    = app.springActivity20Mgr:GetResPath('ui/common/common_title_3.png'),
	COMMON_REWARDS_BG   		    = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_prince_bg_preview.png'),
	SP_BOSS_BG  					= app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_bird.png'),
	SP_BOSS_NAME_BG 				= app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_bird_head.png'),
	TEAM_BG                         = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_bottom.png'),
	BUFF_BG                         = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_buff.png'),
	BUFF_ICON   				    = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_ico_buff.png'),
	LEVEL_UP_ARROW					= app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_pic_lv.png'),
	BUFF_PROGRESS_BAR_BG            = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_line_lv_bottom.png'),
	BUFF_PROGRESS_BAR               = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_line_lv_top.png'),
	ADD_ICON          			    = app.springActivity20Mgr:GetResPath('ui/common/maps_fight_btn_pet_add.png'),
	CARD_HEAD_BG    			    = app.springActivity20Mgr:GetResPath('ui/common/kapai_frame_bg_nocard.png'),
	COST_BG                         = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_ticket.png'),
	DIFFICULTY_CELL_BG_N			= app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_btn_boss.png'),
	DIFFICULTY_CELL_BG_S			= app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_btn_boss_light.png'),
	DIFFICULTY_CELL_MASK			= app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_boss_grey.png'),
	LEVEL_CELL_BG                   = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_bg_lv_top.png'),
	LOCK_IMG 					    = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/common_ico_lock.png'),
	LEVEL_SELECTED_FRAME            = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_btn_lv_light.png'),
	LEVEL_SPLIT_LINE                = app.springActivity20Mgr:GetResPath('ui/springActivity20/boss/garden_boss_line_lv.png'),
	-- spine --
	BOSS_APPEAR_SPINE   			= app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_boss_bg'),
	BOSS_LAMP_SPINE   		     	= app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_boss_lamp'),
	BOSS_GHOST_SPINE   		     	= app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_boss_ghost'),
	BOSS_SPINE           			= app.springActivity20Mgr:GetSpinePath('ui/springActivity20/spine/garden_boss_cage'),
}
local CreateStageCell = nil
function SpringActivity20BossScene:ctor( ... )
    self.super.ctor(self, 'views.springActivity20.SpringActivity20BossScene')
	local args = unpack({...})
	self:InitUI()
end
--[[
初始化ui
--]]
function SpringActivity20BossScene:InitUI()
	local CreateView = function ()
		local size = display.size
		local view = CLayout:create(size)
		view:setPosition(size.width / 2, size.height / 2)
		-- CommonMoneyBar
	    local moneyBar = require("common.CommonMoneyBar").new()
		view:addChild(moneyBar, 20)
		-- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
				{
					ap = display.LEFT_CENTER,
					n = RES_DICT.COMMON_BTN_BACK,
					scale9 = true, size = cc.size(90, 70),
					enable = true,
				})
        view:addChild(backBtn, 10)
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
        
        ----------------------
        --- bossInfoLayout ---
        local bossInfoLayoutSize = cc.size(1022, 510)
		local bossInfoLayout = CLayout:create(bossInfoLayoutSize)
		bossInfoLayout:setAnchorPoint(display.CENTER)
		bossInfoLayout:setPosition(cc.p(size.width / 2 - 120, size.height / 2 + 35))
		view:addChild(bossInfoLayout, 2)
		-- boss情报背景
		local bossInfoBg = display.newImageView(RES_DICT.BOSS_INFO_BG, bossInfoLayoutSize.width / 2, bossInfoLayoutSize.height / 2)
		bossInfoLayout:addChild(bossInfoBg, 1)
		-- boss立绘
		local bossImg = display.newImageView(RES_DICT.BOSS_IMG, 268, 15, {ap = display.LEFT_BOTTOM})
		bossInfoLayout:addChild(bossImg, 2)
		-- 等级level
		local bossLevelLabel = display.newLabel(500, 152, {text = '', fontSize = 22, color = '#FFE5A6', font = TTF_GAME_FONT, ttf = true, outline = '#56120D', outlineSize = 2})
		bossInfoLayout:addChild(bossLevelLabel, 5)
		-- boss名称背景
		local bossNameBg = display.newImageView(RES_DICT.BOSS_NAME_BG, 500, 102)
		bossInfoLayout:addChild(bossNameBg, 3)
		-- boss名称
		local bossNameLabel = display.newLabel(bossNameBg:getContentSize().width / 2, bossNameBg:getContentSize().height - 24, {text = '', fontSize = 22, color = '#FFEACF', font = TTF_GAME_FONT, ttf = true, outline = '#56120D', outlineSize = 1})
		bossNameBg:addChild(bossNameLabel, 1)
		-- boss难度
		local bossDifficultyLabel = display.newLabel(bossNameBg:getContentSize().width / 2, 22, {text = '', fontSize = 20, color = '#FAAC58'})
		bossNameBg:addChild(bossDifficultyLabel, 1)
		-- boss详情
		local bossDetailBtn = display.newButton(365, 35, {scale9 = true ,  scale9 = true ,size =  cc.size(200, 45) ,n = RES_DICT.BOSS_DETAIL_BG})
		bossInfoLayout:addChild(bossDetailBtn, 5)
		display.commonLabelParams(bossDetailBtn, {text = app.springActivity20Mgr:GetPoText(__('BOSS详情')), fontSize = 20, color = '#FFFFFF', offset = cc.p(10, -2)})
        --- bossInfoLayout ---
		----------------------
		
		----------------------
		--- bossListLayout ---
		local bossListLayoutSize = cc.size(242, 483)
		local bossListLayout = CLayout:create(bossListLayoutSize)
		bossListLayout:setAnchorPoint(display.CENTER)
		bossListLayout:setPosition(cc.p(135, bossInfoLayoutSize.height / 2 + 7))
		bossInfoLayout:addChild(bossListLayout, 5)
		-- boss列表背景
        local bossListBg = display.newImageView(RES_DICT.BOSS_LIST_BG, bossListLayoutSize.width / 2, bossListLayoutSize.height / 2)
		bossListLayout:addChild(bossListBg, 2)
		-- boss列表标题
		local bossListTitle = display.newLabel(bossListLayoutSize.width / 2, bossListLayoutSize.height - 30, { w = 240 , hAlign = display.TAC , text = app.springActivity20Mgr:GetPoText(__('选择缉拿难度')), fontSize = 24, color = '#3C2C1B'})
		bossListLayout:addChild(bossListTitle, 5)

        -- boss列表
        local bossListViewSize = cc.size(bossListLayoutSize.width, 420)
		local bossListView = CListView:create(bossListViewSize)
        bossListView:setDirection(eScrollViewDirectionVertical)
        bossListView:setAnchorPoint(display.CENTER_BOTTOM)   
        bossListView:setPosition(cc.p(bossListLayoutSize.width / 2, 5))  
        bossListLayout:addChild(bossListView, 10)
		--- bossListLayout ---
		----------------------

		---------------------
		--- rewardsLayout ---
		local rewardsLayoutSize = cc.size(269, 360)
		local rewardsLayout = CLayout:create(rewardsLayoutSize)
		rewardsLayout:setAnchorPoint(display.CENTER)
		rewardsLayout:setPosition(cc.p(bossInfoLayoutSize.width  - 164, bossInfoLayoutSize.height - 200))
		bossInfoLayout:addChild(rewardsLayout, 5)
		-- bg
		local rewardsBg = display.newImageView(RES_DICT.REWARDS_BG, rewardsLayoutSize.width / 2, rewardsLayoutSize.height / 2)
		rewardsLayout:addChild(rewardsBg, 1)
		-- 首通奖励
		local firstRewardsLabelBg = display.newImageView(RES_DICT.COMMON_TITLE_BG_3, rewardsLayoutSize.width / 2, rewardsLayoutSize.height - 40 , {scale9 = true , size = cc.size(240,31) })
		rewardsLayout:addChild(firstRewardsLabelBg, 3)
		local firstRewardsLabel = display.newLabel(firstRewardsLabelBg:getContentSize().width / 2, firstRewardsLabelBg:getContentSize().height / 2, { text = app.springActivity20Mgr:GetPoText(__('首通奖励')),  reqW = 200, fontSize = 22, color = '#3A1B12'})
		firstRewardsLabelBg:addChild(firstRewardsLabel, 1)
		local drawTips = display.newImageView(RES_DICT.REWARDS_DRAW_BG, rewardsLayoutSize.width / 2, rewardsLayoutSize.height - 110)
		rewardsLayout:addChild(drawTips, 5)
		local drawTipsLabel = display.newLabel(drawTips:getContentSize().width / 2, drawTips:getContentSize().height / 2, {text = app.springActivity20Mgr:GetPoText(__('已领取')), fontSize = 24, color = '#353535'})
		drawTips:addChild(drawTipsLabel, 1)
		-- 普通奖励bg
		local commonRewardsBg = display.newImageView(RES_DICT.COMMON_REWARDS_BG, rewardsLayoutSize.width / 2, 100, {scale9 = true, size = cc.size(260, 180)})
		rewardsLayout:addChild(commonRewardsBg, 2)
		-- 普通奖励
		local commonRewardsLabelBg = display.newImageView(RES_DICT.COMMON_TITLE_BG_3, rewardsLayoutSize.width / 2, 155 , {scale9 = true , size = cc.size(240,31) })
		rewardsLayout:addChild(commonRewardsLabelBg, 3)
		local commonRewardsLabel = display.newLabel(commonRewardsLabelBg:getContentSize().width / 2, commonRewardsLabelBg:getContentSize().height / 2, {text = app.springActivity20Mgr:GetPoText(__('普通奖励')), fontSize = 22 , reqW = 200 , color = '#3A1B12'})
		commonRewardsLabelBg:addChild(commonRewardsLabel, 1)
		-- 奖励layer
		local rewardsLayer = display.newLayer(rewardsLayoutSize.width / 2, rewardsLayoutSize.height / 2, {size = rewardsLayoutSize, ap = display.CENTER})
		rewardsLayout:addChild(rewardsLayer, 4)
		--- rewardsLayout ---
		---------------------

		----------------------
		---- spBossLayout ----
		local spBossLayoutSize = cc.size(332, 406)
		local spBossLayout = CLayout:create(spBossLayoutSize)
		spBossLayout:setAnchorPoint(display.RIGHT_TOP)
		spBossLayout:setPosition(cc.p(size.width + 30 - display.SAFE_L, size.height))
		view:addChild(spBossLayout, 5)
		-- bg
		local spBossBtn = display.newButton(spBossLayoutSize.width / 2, spBossLayoutSize.height / 2, {n = RES_DICT.SP_BOSS_BG})
		spBossLayout:addChild(spBossBtn, 1)
		-- spBoss名称
		local spBossNameBg = display.newImageView(RES_DICT.SP_BOSS_NAME_BG, 0, spBossLayoutSize.height - 50, {ap = display.LEFT_TOP})
		spBossLayout:addChild(spBossNameBg, 5)
		local spBossNameLabel = display.newLabel(spBossNameBg:getContentSize().width / 2 - 10, spBossNameBg:getContentSize().height / 2, { w = 160 , hAlign = display.TAL , text = app.springActivity20Mgr:GetPoText(__('追击三炙鸟')), fontSize = 22, color = '#FBA5A5'})
		spBossNameBg:addChild(spBossNameLabel, 1)
		-- 剩余回合数
		local leftTurnLabel = display.newLabel(spBossLayoutSize.width / 2 - 20, 64, {text = '', fontSize = 20,color = '#F4C47E', ttf = true, font = TTF_GAME_FONT, outline = '#3A1B12', outlineSize = 2})
		spBossLayout:addChild(leftTurnLabel, 1)
		---- spBossLayout ----
		----------------------

		----------------------
		---- battleLayout ----
		local battleLayoutSize = cc.size(size.width, 260)
		local battleLayout = CLayout:create(battleLayoutSize)
		battleLayout:setAnchorPoint(display.CENTER_BOTTOM)
		battleLayout:setPosition(cc.p(size.width / 2, 0))
		view:addChild(battleLayout, 2)
		-- bg
		local teamBg = display.newImageView(RES_DICT.TEAM_BG, battleLayoutSize.width / 2, 0, {ap = display.CENTER_BOTTOM})
		battleLayout:addChild(teamBg, 1)
		-- buff按钮背景
		local buffBtnBg = display.newImageView(RES_DICT.BUFF_BG, battleLayoutSize.width / 2 - 515,  75)
		battleLayout:addChild(buffBtnBg, 2)
		-- buff图标
		local buffBtn = display.newButton(battleLayoutSize.width / 2 - 515,  115, {n = RES_DICT.BUFF_ICON})
		battleLayout:addChild(buffBtn, 3)
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
		buffMaxTipsLabel:setVisible(false)
		buffBtnBg:addChild(buffMaxTipsLabel, 5)
		-- 卡牌头像背景
        local cardHeadBtnlist = {}
        for i = 1, 5 do
            local cardHeadBtn = display.newButton(battleLayoutSize.width / 2  + ((i - 3) * 102), 72, {n = RES_DICT.CARD_HEAD_BG})
            cardHeadBtn:setScale(0.52)
            battleLayout:addChild(cardHeadBtn, 5)
            local addIcon = display.newImageView(RES_DICT.ADD_ICON, battleLayoutSize.width / 2  + ((i - 3) * 102), 72)
            battleLayout:addChild(addIcon, 5)
            table.insert(cardHeadBtnlist, cardHeadBtn)
        end
        -- cardHeadLayout
		local cardHeadLayout = CLayout:create(cc.size(502, 120))
        cardHeadLayout:setPosition(battleLayoutSize.width / 2, 72)
		battleLayout:addChild(cardHeadLayout, 5)
		-- 关卡消耗
		local costBg = display.newImageView(RES_DICT.COST_BG, battleLayoutSize.width / 2 + 515, 22)
		battleLayout:addChild(costBg, 3)
		local costRichLabel = display.newRichLabel(battleLayoutSize.width / 2 + 515, 22)
		battleLayout:addChild(costRichLabel, 5)
		-- 挑战按钮
		local battleBtn = require('common.CommonBattleButton').new({
			pattern = 1,
		})
		battleBtn:setPosition(cc.p(battleLayoutSize.width / 2 + 515, 115))
		battleLayout:addChild(battleBtn, 5)
		---- battleLayout ----
		----------------------
		return {
			view 	            = view,
			moneyBar		    = moneyBar,
			backBtn             = backBtn,
			tabNameLabel        = tabNameLabel,
			bg                  = bg,  
			rewardsLayer        = rewardsLayer, 
			drawTips            = drawTips,
			cardHeadBtnlist     = cardHeadBtnlist,
			cardHeadLayout      = cardHeadLayout,
			costRichLabel       = costRichLabel,
			battleBtn           = battleBtn,
			bossDetailBtn       = bossDetailBtn,
			spBossBtn           = spBossBtn,
			bossListViewSize    = bossListViewSize,
			bossListView	    = bossListView,
			bossImg             = bossImg,
			bossLevelLabel      = bossLevelLabel,
			bossNameLabel       = bossNameLabel,
			bossDifficultyLabel = bossDifficultyLabel,
			spBossLayoutSize    = spBossLayoutSize,
			spBossLayout        = spBossLayout,
			leftTurnLabel       = leftTurnLabel,
			buffBtn             = buffBtn,
			currentBuffLabel    = currentBuffLabel,
			arrowIcon           = arrowIcon,
			nextBuffLabel       = nextBuffLabel,
			accProgressBar      = accProgressBar,
			buffMaxTipsLabel    = buffMaxTipsLabel,
		}
	end
	xTry(function ()
		self.viewData = CreateView()
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end
--[[
初始化货币栏
--]]
function SpringActivity20BossScene:InitMoneyBar( moneyIdMap )
    local viewData = self:GetViewData()
	viewData.moneyBar:reloadMoneyBar(moneyIdMap)
	viewData.moneyBar:setEnableGainPopup(true)
end
--[[
刷新编队
@params team list 编队信息
--]]
function SpringActivity20BossScene:RefreshTeam( team )
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
刷新boss列表
@params params map {
	bossData list 列表数据
	difficulty int 选择难度
	stageIndex int 关卡序号
	difficultyCb function 难度按钮点击回调
	stageCb function 关系点击回调
}
--]]
function SpringActivity20BossScene:RefreshBossList( params )
	local viewData = self:GetViewData()
	local bossListView = viewData.bossListView
	bossListView:removeAllNodes()
	for i, v in ipairs(params.bossData) do
		local cell = self:CreateDifficultyCell(v, i, i == params.difficulty, params.difficultyCb)
		bossListView:insertNodeAtLast(cell)
		if i == params.difficulty then
			local levelCell = self:CreateLevelCell(v.stages, params.stageIndex, params.stageCb)
			bossListView:insertNodeAtLast(levelCell)
		end
	end
	bossListView:reloadData()
end
--[[
创建难度cell
data map cell数据
index int 难度序号
isSelected bool 是否选中
cb function 点击回调
--]]
function SpringActivity20BossScene:CreateDifficultyCell( data, index, isSelected, cb )
	local viewData = self:GetViewData()
	local cell = nil
	local size = nil
	if isSelected then
		size = cc.size(viewData.bossListViewSize.width, 82)
		cell = CLayout:create(size)
		local bg = display.newImageView(RES_DICT.DIFFICULTY_CELL_BG_S, size.width / 2, size.height / 2)
		bg:setTag(index)
		cell:addChild(bg, 1)
		local bossImg = display.newImageView(app.springActivity20Mgr:GetResPath(string.format('ui/springActivity20/boss/bossSmall/%s.png', data.pic)), size.width / 2 - 10, size.height / 2)
		cell:addChild(bossImg, 2)
	else
		size = cc.size(viewData.bossListViewSize.width, 81)
		cell = CLayout:create(size)
		local bg = display.newImageView(RES_DICT.DIFFICULTY_CELL_BG_N, size.width / 2, size.height / 2)
		bg:setTag(index)
		cell:addChild(bg, 1)
		local bossImg = display.newImageView(app.springActivity20Mgr:GetResPath(string.format('ui/springActivity20/boss/bossSmall/%s.png', data.pic)), size.width / 2, size.height / 2)
		cell:addChild(bossImg, 2)
	end
	local bgBtn = display.newButton(size.width / 2, size.height / 2, {n = 'empty', size = size, cb = cb})
	bgBtn:setTag(index)
	cell:addChild(bgBtn, 3)

	local textLabel = display.newLabel(size.width / 2 + 60, size.height / 2 - 18, {text = data.word, fontSize = 22, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#381307', outlineSize = 2})
	cell:addChild(textLabel, 5)
	if data.stages[1].lockState == STAGE_LOCK_STATE.LOCK then
		local mask = display.newImageView(RES_DICT.DIFFICULTY_CELL_MASK, size.width / 2, size.height / 2)
		cell:addChild(mask, 5)
	end
	return cell
end
--[[
创建等级cell
--]]
function SpringActivity20BossScene:CreateLevelCell( data, stageIndex, cb )
	local viewData = self:GetViewData()
	local size = cc.size(viewData.bossListViewSize.width, 10 + #data * 44)
	local cell = CLayout:create(size)
	local bgSize = cc.size(192, size.height)
	local bg = display.newImageView(RES_DICT.LEVEL_CELL_BG, size.width / 2, size.height / 2, {scale9 = true, size = bgSize, capInsets = cc.rect(10, 10, 172, 320)})
	cell:addChild(bg, 1)
	for i, v in ipairs(data) do
		local btn = display.newButton(size.width / 2, size.height - i * 44 + 17, {n = 'empty', size = cc.size(bgSize.width, 44), cb = cb})
		btn:setTag(i)
		cell:addChild(btn, 3)
		local levelLabel = display.newLabel(size.width / 2, btn:getPositionY(), {text = string.fmt(app.springActivity20Mgr:GetPoText(__('_num_级')), {['_num_'] = i}), fontSize = 20, color = '#D9C7B4', ttf = true, font = TTF_GAME_FONT})
		cell:addChild(levelLabel, 5)
		-- 锁定标识
		if v.lockState == STAGE_LOCK_STATE.LOCK then
			local lockImg = display.newImageView(RES_DICT.LOCK_IMG, size.width / 2 - 50, btn:getPositionY() + 3)
			cell:addChild(lockImg, 5)
		end
		-- 分割线
		if i ~= #data then
			local splitLine = display.newImageView(RES_DICT.LEVEL_SPLIT_LINE, size.width / 2, size.height - 5 - i * 44)
			cell:addChild(splitLine, 5)
		end
		-- 选中框
		if i == stageIndex then
			local selectedFrame = display.newImageView(RES_DICT.LEVEL_SELECTED_FRAME, size.width / 2, btn:getPositionY())
			cell:addChild(selectedFrame, 5)
		end
	end
	return cell
end
--[[
刷新关卡信息
@params map {
	data map boss数据
	stageIndex int 关卡序号
}
--]]
function SpringActivity20BossScene:RefreshStageInfo( params )
	local questConfig = CommonUtils.GetConfig('springActivity2020', 'quest', params.data.stages[params.stageIndex].questId)
	self:RefershBossInfo(questConfig, params.stageIndex, params.data.word, params.difficulty)
	self:RefershBossRewards(questConfig, params.data.stages[params.stageIndex].isPassed)
	self:RefreshBattleInfo(questConfig)
end
--[[
刷新boss信息
@params config map 关卡数据
@params stageIndex int 关卡序号
@params word string 难度名称
@params pic string boss图片名称
--]]
function SpringActivity20BossScene:RefershBossInfo( config, stageIndex, word, difficulty)
	local viewData = self:GetViewData()
	viewData.bossLevelLabel:setString(string.fmt(__('等级: _num_'), {['_num_'] = stageIndex}))
	viewData.bossNameLabel:setString(config.name)
	viewData.bossDifficultyLabel:setString(string.format('(%s)', word))
	if GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020 then
		viewData.bossImg:setTexture(app.springActivity20Mgr:GetResPath(string.format('ui/springActivity20/boss/garden_boss_bg_boss_%d.png' , checkint(difficulty))))
	end
end
--[[
刷新关卡奖励
@params config map 关卡数据
--]]
function SpringActivity20BossScene:RefershBossRewards( config, isPassed )
	local viewData = self:GetViewData()
	viewData.rewardsLayer:removeAllChildren()
	-- 刷新首通奖励
	for i, v in ipairs(checktable(config.firstRewards)) do
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
		goodsNode:setPosition(cc.p(viewData.rewardsLayer:getContentSize().width / 2 - 162 + i * 108, viewData.rewardsLayer:getContentSize().height - 110))
		goodsNode:setScale(0.9)
		viewData.rewardsLayer:addChild(goodsNode, 1)
	end
	viewData.drawTips:setVisible(isPassed)
	-- 刷新普通奖励
	for i, v in ipairs(checktable(config.rewards)) do
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
		goodsNode:setPosition(cc.p(viewData.rewardsLayer:getContentSize().width / 2 - 162 + i * 108, 80))
		goodsNode:setScale(0.9)
		viewData.rewardsLayer:addChild(goodsNode, 1)
	end
end
--[[
刷新战斗信息
@params config map 关卡数据
--]]
function SpringActivity20BossScene:RefreshBattleInfo( config )
	local viewData = self:GetViewData()
	display.reloadRichLabel(viewData.costRichLabel, {c = {
		{img = CommonUtils.GetGoodsIconPathById(config.consumeGoodsId), scale = 0.18},
		{text = 'x' .. tostring(config.consumeGoodsNum), fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, ap = display.LEFT_CENTER}
	}})
end
--[[
刷新特殊boss
@params spBossData   map  特殊boss数据
@params times        int  距离下次
@params spBossAppear bool 是否显示特殊boss出场动画
@params isSpBossPassed bool 特殊boss是否通过
--]]
function SpringActivity20BossScene:RefreshSpBoss( spBossData, times, spBossAppear, isSpBossPassed )
	local viewData = self:GetViewData()
	local spBossSpine = sp.SkeletonAnimation:create(
		RES_DICT.BOSS_GHOST_SPINE.json,
		RES_DICT.BOSS_GHOST_SPINE.atlas,
		1
	)
	spBossSpine:setPosition(cc.p(viewData.spBossLayoutSize.width / 2, viewData.spBossLayoutSize.height / 2))
	spBossSpine:setName('spBossSpine')
	viewData.spBossLayout:addChild(spBossSpine, 1)

	viewData.leftTurnLabel:setString(string.fmt(app.springActivity20Mgr:GetPoText(__('剩余回合：_num_')), {['_num_'] = times}))
	if spBossData then
		viewData.leftTurnLabel:setVisible(false)
		if spBossAppear then 
			self:SpBossAppearAnimation()
		else
			spBossSpine:setAnimation(0, 'play2', true)
		end
	else
		if isSpBossPassed then
			viewData.leftTurnLabel:setVisible(false)
			spBossSpine:setAnimation(0, 'play2', true)
		else
			viewData.leftTurnLabel:setVisible(true)
			spBossSpine:setAnimation(0, 'idle', true)
		end
	end
end
--[[
刷新buff
@params buff map buff数据
--]]
function SpringActivity20BossScene:RefreshBuff( buff )
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
spBoss出场动画
--]]
function SpringActivity20BossScene:SpBossAppearAnimation()
	app.uiMgr:GetCurrentScene():AddViewForNoTouch()
	local viewData = self:GetViewData()
	local spBossSpine = viewData.spBossLayout:getChildByName('spBossSpine')
	spBossSpine:registerSpineEventHandler(function (event)
		if event.animation == 'play1' then
			self:SpBossBanner()
		end
	end, sp.EventType.ANIMATION_END)
	spBossSpine:setAnimation(0, 'play1', false)
	spBossSpine:addAnimation(0, 'play2', true)
end
--[[
特殊boss条幅
--]]
function SpringActivity20BossScene:SpBossBanner()
	local viewData = self:GetViewData()
	local bannerLayer = display.newLayer(display.cx,display.cy, {size = display.size, enable = true, color = cc.c4b(0, 0, 0, 255 * 0.6), ap = display.CENTER})
	viewData.view:addChild(bannerLayer, 5)
	-- 背景
	local bannerSpine = sp.SkeletonAnimation:create(
		RES_DICT.BOSS_APPEAR_SPINE.json,
		RES_DICT.BOSS_APPEAR_SPINE.atlas,
		1
	)
	bannerSpine:setPosition(cc.p(display.cx, display.cy))
	bannerSpine:setAnimation(0, 'idle', false)
	bannerLayer:addChild(bannerSpine, 1)
	-- 警灯
	local lampSpine = sp.SkeletonAnimation:create(
		RES_DICT.BOSS_LAMP_SPINE.json,
		RES_DICT.BOSS_LAMP_SPINE.atlas,
		1
	)
	lampSpine:setPosition(cc.p(display.cx, display.cy + 430))
	lampSpine:setAnimation(0, 'idle', true)
	bannerLayer:addChild(lampSpine, 1)
	lampSpine:runAction(cc.Sequence:create(
		cc.MoveBy:create(0.3, cc.p(0, - 200)),
		cc.DelayTime:create(1.25),
		cc.FadeOut:create(0.25),
		cc.RemoveSelf:create()
	))
	-- 标题
	local title = display.newLabel(display.cx - 400, display.cy, {text = app.springActivity20Mgr:GetPoText(__('追击三炙鸟')), fontSize = 60, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#7A1818', outLineSize = 2})
	title:setVisible(false)
	bannerLayer:addChild(title, 5)
	title:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.3),
		cc.Show:create(),
		cc.Spawn:create(
			cc.MoveBy:create(1.3, cc.p(170, 0)),
			cc.Sequence:create(
				cc.DelayTime:create(0.6),
				cc.FadeOut:create(0.7)
			)
		),
		cc.RemoveSelf:create()
	))
	-- boss
	local bossSpine = sp.SkeletonAnimation:create(
		RES_DICT.BOSS_SPINE.json,
		RES_DICT.BOSS_SPINE.atlas,
		1
	)
	bossSpine:setPosition(cc.p(display.cx + 300, display.cy - 130))
	bossSpine:setAnimation(0, 'idle', true)
	bossSpine:setVisible(false)
	bannerLayer:addChild(bossSpine, 5)
	bossSpine:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.3),
		cc.Show:create(),
		cc.DelayTime:create(1.0),
		cc.FadeTo:create(0.2, 230),
		cc.RemoveSelf:create()
	))
	bannerLayer:runAction(cc.Sequence:create(
		cc.DelayTime:create(1.5),
		cc.FadeOut:create(1),
		cc.CallFunc:create(function()
			app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
		end),
		cc.RemoveSelf:create()
	))
end
--[[
捕捉特殊boss
--]]
function SpringActivity20BossScene:CatchSpBoss()
	local viewData = self:GetViewData()
	local spBossSpine = viewData.spBossLayout:getChildByName('spBossSpine')
	spBossSpine:setToSetupPose()
	spBossSpine:clearTrack(0)
	spBossSpine:setAnimation(0, 'play3', false)
	spBossSpine:addAnimation(0, 'idle', true)
	viewData.leftTurnLabel:setVisible(true)
	viewData.leftTurnLabel:setOpacity(0)
	viewData.leftTurnLabel:runAction(cc.Sequence:create(
		cc.DelayTime:create(1),
		cc.FadeIn:create(1)
	))
end
--[[
获取viewData
--]]
function SpringActivity20BossScene:GetViewData()
	return self.viewData
end
return SpringActivity20BossScene
