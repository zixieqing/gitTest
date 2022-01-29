--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 关卡选择Scene
--]]
local GameScene = require('Frame.GameScene')
local SpringActivity20StageScene = class('SpringActivity20StageScene', GameScene)

local DIFFICULTY_TYPE = {
    EASY = 1,
    HARD = 2
}
local STAGE_LOCK_STAGE = {
    LOCK = 1,
    UNLOCK = 2,
}
local RES_DICT = {
    COMMON_TITLE                    = app.springActivity20Mgr:GetResPath('ui/common/common_title.png'),
	COMMON_TIPS       		        = app.springActivity20Mgr:GetResPath('ui/common/common_btn_tips.png'),
	COMMON_BTN_BACK                 = app.springActivity20Mgr:GetResPath('ui/common/common_btn_back.png'),
	BG_EASY                         = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_bg_easy.png'),
	BG_HARD                         = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_bg_hard.png'),
	LIST_BG  						= app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_bg_left.png'),
	DIFFCULTY_BTN_LINE              = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_line_easy.png'),
	EASY_BTN_N                      = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_btn_easy.png'),
	EASY_BTN_S                      = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_btn_easy_light.png'),
	HARD_BTN_N                      = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_btn_hard.png'),
	HARD_BTN_S                      = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_btn_hard_light.png'),
	LIST_CELL_BG_N                  = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_btn_stoy.png'),
	LIST_CELL_BG_S                  = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_btn_stoy_light.png'),
	LIST_CELL_LINE_G 			    = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_line_story.png'),
	LIST_CELL_LINE_L 			    = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_line_story_light.png'),
	STAGE_BG                        = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_bg_paper.png'),
	TEAM_BG                         = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_bg_bottom.png'),
	BUFF_BTN_BG                     = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_bg_buff.png'),
	BUFF_BTN                        = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_ico_buff.png'),
	LEVEL_UP_ARROW					= app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_pic_lv.png'),
	BUFF_PROGRESS_BAR_BG            = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_line_lv_bottom.png'),
	BUFF_PROGRESS_BAR               = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_line_lv_top.png'),
	ADD_ICON          			    = app.springActivity20Mgr:GetResPath('ui/common/maps_fight_btn_pet_add.png'),
	CARD_HEAD_BG    			    = app.springActivity20Mgr:GetResPath('ui/common/kapai_frame_bg_nocard.png'),
	COMMON_BTN_ORANGE               = app.springActivity20Mgr:GetResPath('ui/common/common_btn_orange.png'),
	COMMON_BTN_ORANGE_D             = app.springActivity20Mgr:GetResPath('ui/common/common_btn_orange_disable.png'),
	LEFT_TIMES_LABEL_BG             = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_prince_bg_number.png'),
	REWARDS_BG 						= app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_bg_reward.png'),
	REWARDS_DRAW_BG                 = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_prince_bg_get.png'),
	COMMON_TITLE_BG_3               = app.springActivity20Mgr:GetResPath('ui/common/common_title_3.png'),
	COMMON_REWARDS_BG   		    = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_prince_bg_preview.png'),
	CELL_LOCK_MASK                  = app.springActivity20Mgr:GetResPath('ui/springActivity20/stage/garden_story_bg_stoy_grey.png'),
	CELL_LOCK_ICON                  = app.springActivity20Mgr:GetResPath('ui/common/common_ico_lock.png'),

	-- spine --
}
local CreateStageCell = nil
function SpringActivity20StageScene:ctor( ... )
    self.super.ctor(self, 'views.springActivity20.SpringActivity20StageScene')
	local args = unpack({...})
	self:InitUI()
end
--[[
初始化ui
--]]
function SpringActivity20StageScene:InitUI()
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
		local bg = display.newImageView(RES_DICT.BG_EASY, size.width / 2, size.height / 2)
        view:addChild(bg, 1)

		----------------------
		----- listLayout -----
		local listLayoutSize = cc.size(315, 656)
		local listLayout = CLayout:create(listLayoutSize)
		listLayout:setAnchorPoint(display.CENTER_BOTTOM)
		listLayout:setPosition(cc.p(size.width / 2 - 515, 10))
		view:addChild(listLayout, 3)
		-- bg
		local listBg = display.newImageView(RES_DICT.LIST_BG, listLayoutSize.width / 2, listLayoutSize.height / 2)
		listLayout:addChild(listBg, 1)
		-- 选择难度
		local chooseDifficultyLabel = display.newLabel(listLayoutSize.width / 2 - 8, listLayoutSize.height - 33, {text = app.springActivity20Mgr:GetPoText(__('选择难度')), fontSize = 20, color = '#402D21'})
		listLayout:addChild(chooseDifficultyLabel, 5)
		-- 简单难度按钮
		local easyBtnLine = display.newImageView(RES_DICT.DIFFCULTY_BTN_LINE, listLayoutSize.width / 2 - 50, listLayoutSize.height - 66)
		listLayout:addChild(easyBtnLine, 1)
		local easyBtn = display.newButton(listLayoutSize.width / 2 - 50, listLayoutSize.height - 110, {n = RES_DICT.EASY_BTN_N})
		easyBtn:setTag(DIFFICULTY_TYPE.EASY)
		listLayout:addChild(easyBtn, 5)
		display.commonLabelParams(easyBtn, {text = app.springActivity20Mgr:GetPoText(__("普通")), fontSize = 24, color = '#FFFFFF', font = TTF_GAME_FONT, ttf = true, outline = '#461A10', outlineSize = 1, offset = cc.p(0, -6)})
		-- 困难难度按钮
		local hardBtnLine = display.newImageView(RES_DICT.DIFFCULTY_BTN_LINE, listLayoutSize.width / 2 + 50, listLayoutSize.height - 66)
		listLayout:addChild(hardBtnLine, 1)
		local hardBtn = display.newButton(listLayoutSize.width / 2 + 50, listLayoutSize.height - 110, {n = RES_DICT.HARD_BTN_N})
		hardBtn:setTag(DIFFICULTY_TYPE.HARD)
		listLayout:addChild(hardBtn, 5)
		display.commonLabelParams(hardBtn, {text = app.springActivity20Mgr:GetPoText(__("困难")), fontSize = 24, color = '#FFFFFF', font = TTF_GAME_FONT, ttf = true, outline = '#461A10', outlineSize = 1, offset = cc.p(0, -6)})
		-- 选择故事
		local chooseStoryLabel = display.newLabel(listLayoutSize.width / 2 - 8, listLayoutSize.height - 200, {text = app.springActivity20Mgr:GetPoText(__("选择故事")), fontSize = 20, color = '#402D21'})
		listLayout:addChild(chooseStoryLabel, 5)
		-- 关卡列表
		local stageTableViewSize = cc.size(265, 426)
		local stageTableViewCellSize = cc.size(stageTableViewSize.width, 94)
        local stageTableView = display.newTableView(listLayoutSize.width / 2 - 8, 8, {size = stageTableViewSize, csize = stageTableViewCellSize, dir = display.SDIR_V, ap = display.CENTER_BOTTOM})
		stageTableView:setCellCreateHandler(CreateStageCell)
		listLayout:addChild(stageTableView, 5)
		----- listLayout -----
		----------------------

		-----------------------
		----- stageLayout -----
		local stageLayoutSize = cc.size(492, 462)
		local stageLayout = CLayout:create(stageLayoutSize)
		stageLayout:setPosition(cc.p(size.width / 2 + 30, size.height / 2 + 50))
		view:addChild(stageLayout, 3)
		-- bg
		local stageBg = display.newImageView(RES_DICT.STAGE_BG, stageLayoutSize.width / 2, stageLayoutSize.height / 2)
		stageLayout:addChild(stageBg, 1)
		-- bossImg
		local stageImg = display.newImageView('empty', stageLayoutSize.width / 2 + 10, stageLayoutSize.height / 2 + 50)
		stageLayout:addChild(stageImg, 5)
		-- 怪物描述
		local monsterDescrLabel = display.newLabel(stageLayoutSize.width / 2 + 40, 110, {text = app.springActivity20Mgr:GetPoText(__('需要打败的怪物')),w = 250 ,hAlign = display.TAC ,  fontSize = 22, color = '#621812'})
		stageLayout:addChild(monsterDescrLabel, 5)
		-- 怪物名称
		local monsterNameLabel = display.newLabel(stageLayoutSize.width / 2 + 40, 65, {text = '', fontSize = 24, color = '#FFFFFF', font = TTF_GAME_FONT, ttf = true, outline = '#381327', outlineSize = 2})
		stageLayout:addChild(monsterNameLabel, 5)
		----- stageLayout -----
		-----------------------

		----------------------
		---- battleLayout ----
		local battleLayoutSize = cc.size(size.width, 230)
		local battleLayout = CLayout:create(battleLayoutSize)
		battleLayout:setAnchorPoint(display.CENTER_BOTTOM)
		battleLayout:setPosition(cc.p(size.width / 2, 0))
		view:addChild(battleLayout, 2)
		-- bg
		local teamBg = display.newImageView(RES_DICT.TEAM_BG, battleLayoutSize.width / 2, 0, {ap = display.CENTER_BOTTOM})
		battleLayout:addChild(teamBg, 1)
		local buffPosTable = app.springActivity20Mgr:GetBuffPosTable()
		-- buff按钮背景
		local buffBtnBg = display.newImageView(RES_DICT.BUFF_BTN_BG, battleLayoutSize.width / 2 - 175 + buffPosTable.buffBtnBg.x ,  175+  buffPosTable.buffBtnBg.y)
		battleLayout:addChild(buffBtnBg, 1)
		-- buff按钮
		local buffBtn = display.newButton(battleLayoutSize.width / 2 - 320+ buffPosTable.buffBtn.x,  185+buffPosTable.buffBtn.y, {n = RES_DICT.BUFF_BTN})
		battleLayout:addChild(buffBtn, 3)
		display.commonLabelParams(buffBtn, {text = '', fontSize = 18, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#421A03', outlineSize = 1, offset= cc.p(5, -20)})

		-- 当前buff加成
		local currentBuffLabel = display.newLabel(buffBtnBg:getContentSize().width / 2 - 20, buffBtnBg:getContentSize().height - 18, {text = '', fontSize = 20, color = '#FFFFFF', ap = display.RIGHT_CENTER})
		buffBtnBg:addChild(currentBuffLabel, 5)
		-- 升级箭头
		local arrowIcon = display.newImageView(RES_DICT.LEVEL_UP_ARROW, buffBtnBg:getContentSize().width / 2, buffBtnBg:getContentSize().height - 18)
		buffBtnBg:addChild(arrowIcon, 5)
		-- 下级buff加成
		local nextBuffLabel = display.newLabel(buffBtnBg:getContentSize().width / 2 + 20, buffBtnBg:getContentSize().height - 18, {text = '', fontSize = 20, color = '#FFFFFF', ap = display.LEFT_CENTER})
		buffBtnBg:addChild(nextBuffLabel, 5)
		-- buff进度条
        local accProgressBar = CProgressBar:create(RES_DICT.BUFF_PROGRESS_BAR)
        accProgressBar:setBackgroundImage(RES_DICT.BUFF_PROGRESS_BAR_BG)
        accProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        accProgressBar:setPosition(cc.p(buffBtnBg:getContentSize().width / 2, 16))
		buffBtnBg:addChild(accProgressBar, 5)
		-- 满级提示
		local buffMaxTipsLabel = display.newLabel(buffBtnBg:getContentSize().width / 2, 25, {text = app.springActivity20Mgr:GetPoText(__('BUFF值已达到上限')), fontSize = 20, color = '#FFFFFF'})
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
		local costRichLabel = display.newRichLabel(battleLayoutSize.width / 2 + 430, 123)
		battleLayout:addChild(costRichLabel, 5)
		-- 挑战按钮
		local battleBtn = display.newButton(battleLayoutSize.width / 2 + 440, 78, {n = RES_DICT.COMMON_BTN_ORANGE})
		battleLayout:addChild(battleBtn, 5)
		display.commonLabelParams(battleBtn, fontWithColor(14, {text = app.springActivity20Mgr:GetPoText(__('挑战'))}))
		-- 扫荡按钮
		local sweepBtn = display.newButton(battleLayoutSize.width / 2 + 584, 80, {n = RES_DICT.COMMON_BTN_ORANGE_D})
		battleLayout:addChild(sweepBtn, 5)
		display.commonLabelParams(sweepBtn, fontWithColor(14, {text = app.springActivity20Mgr:GetPoText(__('快速挑战'))}))
		-- 剩余次数
		local leftTimesLabelBg = display.newImageView(RES_DICT.LEFT_TIMES_LABEL_BG, battleLayoutSize.width / 2 + 512, 25)
		battleLayout:addChild(leftTimesLabelBg, 3)
		local leftTimesLabel = display.newLabel(leftTimesLabelBg:getContentSize().width / 2, leftTimesLabelBg:getContentSize().height / 2, {text = '', fontSize = 22, color = '#D0CBC2'})
		leftTimesLabelBg:addChild(leftTimesLabel, 3)
		---- battleLayout ----
		----------------------
		
		-----------------------
		---- rewardsLayout ----
		local rewardsLayoutSize = cc.size(280, 362)
		local rewardsLayout = CLayout:create(rewardsLayoutSize)
		rewardsLayout:setAnchorPoint(display.CENTER_BOTTOM)
		rewardsLayout:setPosition(cc.p(size.width / 2 + 510, 140))
		view:addChild(rewardsLayout, 3)
		-- bg
		local rewardsBg = display.newImageView(RES_DICT.REWARDS_BG, rewardsLayoutSize.width / 2, rewardsLayoutSize.height / 2)
		rewardsLayout:addChild(rewardsBg, 1)
		-- 首通奖励
		local firstRewardsLabelBg = display.newImageView(RES_DICT.COMMON_TITLE_BG_3, rewardsLayoutSize.width / 2, rewardsLayoutSize.height - 40 ,{scale9 = true ,  size = cc.size(260, 31)} )
		rewardsLayout:addChild(firstRewardsLabelBg, 3)
		local firstRewardsLabel = display.newLabel(firstRewardsLabelBg:getContentSize().width / 2, firstRewardsLabelBg:getContentSize().height / 2, { reqW = 220 , text = app.springActivity20Mgr:GetPoText(__('首通奖励')), fontSize = 22, color = '#3A1B12'})
		firstRewardsLabelBg:addChild(firstRewardsLabel, 1)
		local drawTips = display.newImageView(RES_DICT.REWARDS_DRAW_BG, rewardsLayoutSize.width / 2, rewardsLayoutSize.height - 110)
		rewardsLayout:addChild(drawTips, 5)
		local drawTipsLabel = display.newLabel(drawTips:getContentSize().width / 2, drawTips:getContentSize().height / 2, {text = app.springActivity20Mgr:GetPoText(__('已领取')), fontSize = 24, color = '#353535'})
		drawTips:addChild(drawTipsLabel, 1)
		-- 普通奖励bg
		local commonRewardsBg = display.newImageView(RES_DICT.COMMON_REWARDS_BG, rewardsLayoutSize.width / 2, 110)
		rewardsLayout:addChild(commonRewardsBg, 2)
		-- 普通奖励
		local commonRewardsLabelBg = display.newImageView(RES_DICT.COMMON_TITLE_BG_3, rewardsLayoutSize.width / 2, 155,{scale9 = true ,  size = cc.size(260, 31)})
		rewardsLayout:addChild(commonRewardsLabelBg, 3)
		local commonRewardsLabel = display.newLabel(commonRewardsLabelBg:getContentSize().width / 2, commonRewardsLabelBg:getContentSize().height / 2, {reqW = 220 , text = app.springActivity20Mgr:GetPoText(__('普通奖励')), fontSize = 22, color = '#3A1B12'})
		commonRewardsLabelBg:addChild(commonRewardsLabel, 1)
		-- 奖励layer
		local rewardsLayer = display.newLayer(rewardsLayoutSize.width / 2, rewardsLayoutSize.height / 2, {size = rewardsLayoutSize, ap = display.CENTER})
		rewardsLayout:addChild(rewardsLayer, 4)
		---- rewardsLayout ----
		-----------------------
		return {
			view 	            = view,
			moneyBar		    = moneyBar,
			backBtn             = backBtn,
			tabNameLabel        = tabNameLabel,
			bg                  = bg,  
			stageTableViewSize  = stageTableViewSize,
			stageTableViewCellSize = stageTableViewCellSize,
			stageTableView      = stageTableView,
			easyBtn             = easyBtn,
			hardBtn  	        = hardBtn,
			stageImg            = stageImg,
			monsterNameLabel    = monsterNameLabel,
			drawTips            = drawTips,
			rewardsLayer        = rewardsLayer,
			battleBtn           = battleBtn,
			sweepBtn            = sweepBtn,
			cardHeadBtnlist     = cardHeadBtnlist,
			cardHeadLayout      = cardHeadLayout,
			leftTimesLabelBg    = leftTimesLabelBg,
			leftTimesLabel      = leftTimesLabel,
			costRichLabel       = costRichLabel,
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
创建列表cell
--]]
CreateStageCell = function( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    -- 背景
    local bg = display.newImageView(RES_DICT.LIST_CELL_BG_N, size.width / 2, size.height / 2)
	view:addChild(bg, 2)
	local line = display.newImageView(RES_DICT.LIST_CELL_LINE_G, size.width / 2, 1)
	view:addChild(line, 1)
	local btn = display.newButton(size.width / 2, size.height / 2, {n = 'empty', size = size})
	view:addChild(btn, 5)
	local stageBg = display.newImageView('empty', size.width / 2, size.height / 2)
	view:addChild(stageBg, 2)
	local stageTitle = display.newLabel(size.width / 2 , 10, {text = '', fontSize = 20, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#381307', outlineSize = 2,w = 210 , hAlign = display.TAC ,  ap = display.CENTER_BOTTOM})
	view:addChild(stageTitle, 3)
	local lockMask = display.newImageView(RES_DICT.CELL_LOCK_MASK, size.width / 2, size.height / 2)
	view:addChild(lockMask, 3)
	local lockIcon = display.newImageView(RES_DICT.CELL_LOCK_ICON, lockMask:getContentSize().width / 2, lockMask:getContentSize().height / 2)
	lockMask:addChild(lockIcon, 1)
    return {
		view       = view,
		bg         = bg,
		line       = line,
		btn        = btn,
		stageBg    = stageBg,
		stageTitle = stageTitle,
		lockMask   = lockMask,
    }
end
--[[
初始化货币栏
--]]
function SpringActivity20StageScene:InitMoneyBar( moneyIdMap )
    local viewData = self:GetViewData()
    viewData.moneyBar:reloadMoneyBar(moneyIdMap)
end
--[[
刷新关卡列表cell
@params cellViewData map  cell组件
@params config  map {
	name string 关卡名称
	smallPic string 关卡小图
}
@params isSelected   bool 是否选中
@params isLast       bool 是否是最后一个关卡
@params lockState    STAGE_LOCK_STAGE 关卡锁定状态
@params nextStageLockState STAGE_LOCK_STAGE 下一关锁定状态
--]]
function SpringActivity20StageScene:RefreshStageCell( cellViewData, config, isSelected, isLast, lockState, nextStageLockState )
	cellViewData.stageBg:setTexture(app.springActivity20Mgr:GetResPath(string.format('ui/springActivity20/stage/bossSmall/%s.png', tostring(config.smallPic))))
	cellViewData.stageTitle:setString(config.name)
	if isSelected then 
		-- 选中状态
		cellViewData.bg:setTexture(RES_DICT.LIST_CELL_BG_S)
		cellViewData.lockMask:setVisible(false)
	else  
		-- 通常状态
		cellViewData.bg:setTexture(RES_DICT.LIST_CELL_BG_N)
		if lockState == STAGE_LOCK_STAGE.LOCK then
			cellViewData.lockMask:setVisible(true)
		elseif lockState == STAGE_LOCK_STAGE.UNLOCK then
			cellViewData.lockMask:setVisible(false)
		end
	end
	-- 判断后续cell是否解锁
	if nextStageLockState == STAGE_LOCK_STAGE.LOCK then
		cellViewData.line:setVisible(true)
		cellViewData.line:setTexture(RES_DICT.LIST_CELL_LINE_G)
	elseif nextStageLockState == STAGE_LOCK_STAGE.UNLOCK then
		cellViewData.line:setVisible(true)
		cellViewData.line:setTexture(RES_DICT.LIST_CELL_LINE_L)
	else
		cellViewData.line:setVisible(false)
	end
	cellViewData.line:setVisible(not isLast)
end
--[[
刷新难度按钮状态
--]]
function SpringActivity20StageScene:RefreshDifficulty( difficulty )
	local viewData = self:GetViewData()
	if difficulty == DIFFICULTY_TYPE.EASY then
		viewData.easyBtn:setNormalImage(RES_DICT.EASY_BTN_S)
		viewData.easyBtn:setSelectedImage(RES_DICT.EASY_BTN_S)
		viewData.hardBtn:setNormalImage(RES_DICT.HARD_BTN_N)
		viewData.hardBtn:setSelectedImage(RES_DICT.HARD_BTN_N)
		viewData.bg:setTexture(RES_DICT.BG_EASY)
	elseif difficulty == DIFFICULTY_TYPE.HARD then
		viewData.easyBtn:setNormalImage(RES_DICT.EASY_BTN_N)
		viewData.easyBtn:setSelectedImage(RES_DICT.EASY_BTN_N)
		viewData.hardBtn:setNormalImage(RES_DICT.HARD_BTN_S)
		viewData.hardBtn:setSelectedImage(RES_DICT.HARD_BTN_S)
		viewData.bg:setTexture(RES_DICT.BG_HARD)
	end
end
--[[
刷新关卡列表
@params cellNum int cell数量
@params stageIndex int 选中的关卡序号
--]]
function SpringActivity20StageScene:RefreshStageList( cellNum, stageIndex )
	local viewData = self:GetViewData()
	local list_H = viewData.stageTableViewSize.height
	local cell_H = viewData.stageTableViewCellSize.height
	viewData.stageTableView:resetCellCount(cellNum)
	local contentOffset = cc.p(0, math.min(-(cellNum - stageIndex + 1) * cell_H + list_H, 0))
    viewData.stageTableView:setContentOffset(contentOffset)
end
--[[
刷新关卡信息
@params config  map {
	largePic           string 关卡大图
	word               string 怪物名称
	firstRewards       list   首次奖励
	rewards            list   普通奖励
	consumeHpNum       int    关卡消耗
	challengeTime      int    关卡挑战次数
	leftChallengeTimes int    剩余关卡挑战次数
	isPassed           int    是否通过
}
--]]
function SpringActivity20StageScene:RefreshStageInfo( config )
	self:RefreshMonsterInfo(config)
	self:RefreshBattleInfo(config)
	self:RefreshStageRewards(config)
end
--[[
刷新怪物信息
@params config  map {
	largePic           string 关卡大图
	word               string 怪物名称
	firstRewards       list   首次奖励
	rewards            list   普通奖励
	consumeHpNum       int    关卡消耗
	challengeTime      int    关卡挑战次数
	leftChallengeTimes int    剩余关卡挑战次数
	isPassed           int    是否通过
}
--]]
function SpringActivity20StageScene:RefreshMonsterInfo( config )
	local viewData = self:GetViewData()
	viewData.stageImg:setTexture(app.springActivity20Mgr:GetResPath(string.format('ui/springActivity20/stage/boss/%s.png', tostring(config.largePic))))
	viewData.monsterNameLabel:setString(config.word)
end
--[[
刷新战斗信息
@params config  map {
	largePic           string 关卡大图
	word               string 怪物名称
	firstRewards       list   首次奖励
	rewards            list   普通奖励
	consumeHpNum       int    关卡消耗
	challengeTime      int    关卡挑战次数
	leftChallengeTimes int    剩余关卡挑战次数
	isPassed           int    是否通过
}
--]]
function SpringActivity20StageScene:RefreshBattleInfo( config )
	local viewData = self:GetViewData()
	display.reloadRichLabel(viewData.costRichLabel, {c = {
		{img = CommonUtils.GetGoodsIconPathById(app.springActivity20Mgr:GetHPGoodsId()), scale = 0.18},
		{text = 'x' .. tostring(config.consumeHpNum), fontSize = 22, color = '#261B0D', ttf = true, font = TTF_GAME_FONT, ap = display.LEFT_CENTER}
	}})
	if config.leftChallengeTimes and checkint(config.challengeTime) > 0 then
		viewData.leftTimesLabelBg:setVisible(true)
		viewData.leftTimesLabel:setString(string.fmt(app.springActivity20Mgr:GetPoText(__('今日剩余次数:_num1_/_num2_')), {['_num1_'] = config.leftChallengeTimes, ['_num2_'] = config.challengeTime}))
	else
		viewData.leftTimesLabelBg:setVisible(false)
	end
	if config.isPassed then
		viewData.sweepBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE)
		viewData.sweepBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE)
	else
		viewData.sweepBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE_D)
		viewData.sweepBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE_D)
	end
	
end
--[[
刷新关卡奖励
@params config  map {
	largePic           string 关卡大图
	word               string 怪物名称
	firstRewards       list   首次奖励
	rewards            list   普通奖励
	consumeHpNum       int    关卡消耗
	challengeTime      int    关卡挑战次数
	leftChallengeTimes int    剩余关卡挑战次数
	isPassed           int    是否通过
}
--]]
function SpringActivity20StageScene:RefreshStageRewards( config )
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
		goodsNode:setPosition(cc.p(viewData.rewardsLayer:getContentSize().width / 2 - 174 + i * 87, viewData.rewardsLayer:getContentSize().height - 110))
		goodsNode:setScale(0.7)
		viewData.rewardsLayer:addChild(goodsNode, 1)
	end
	viewData.drawTips:setVisible(config.isPassed)
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
		goodsNode:setPosition(cc.p(viewData.rewardsLayer:getContentSize().width / 2 - 174 + i * 87, 80))
		goodsNode:setScale(0.7)
		viewData.rewardsLayer:addChild(goodsNode, 1)
	end
end
--[[
刷新编队
@params team list 编队信息
--]]
function SpringActivity20StageScene:RefreshTeam( team )
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
刷新buff
@params buff map buff数据
--]]
function SpringActivity20StageScene:RefreshBuff( buff )
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
获取viewData
--]]
function SpringActivity20StageScene:GetViewData()
	return self.viewData
end
return SpringActivity20StageScene
