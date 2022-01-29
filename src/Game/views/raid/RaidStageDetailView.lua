--[[
组队本关卡详情界面
@params {
	stageId int 关卡id
	gotRareReward int 是否获得关卡稀有掉落
	leftNormalDropTimes int 剩余保底普通奖励掉落次数
	enableDropWaring bool 是否启用基础掉落警告模块
	enableBuyNormalDropTimes bool 是否启用购买基础掉落次数模块
}
--]]
local RaidStageDetailView = class('RaidStageDetailView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.raid.RaidStageDetailView'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
local BgPathConfig = {
	[RaidQuestDifficulty.EASY] 		= 'ui/raid/hall/raid_boss_info_bg_easy.png',
	[RaidQuestDifficulty.NORMAL] 	= 'ui/raid/hall/raid_boss_info_bg_normal.png',
	[RaidQuestDifficulty.HARD] 		= 'ui/raid/hall/raid_boss_info_bg_hard.png'
}
local DrawCoverPathConfig = {
	[RaidQuestDifficulty.EASY] 		= '',
	[RaidQuestDifficulty.NORMAL] 	= 'ui/raid/hall/raid_boss_info_ico_normal.png',
	[RaidQuestDifficulty.HARD] 		= 'ui/raid/hall/raid_boss_info_ico_hard.png'
}
------------ define ------------

--[[
constructor
--]]
function RaidStageDetailView:ctor( ... )
	local args = unpack({...})

	self.stageId = checkint(args.stageId)
	self.gotRareReward = checkint(args.gotRareReward) == 1
	self.leftNormalDropTimes = checkint(args.leftNormalDropTimes)
	self.enableDropWaring = args.enableDropWaring or false
	self.enableBuyNormalDropTimes = args.enableBuyNormalDropTimes or false

	self:InitUI()

	-- 注册信号回调
	self:RegisterSignal()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function RaidStageDetailView:InitUI()
	local stageConfig = CommonUtils.GetQuestConf(self.stageId)
	local difficulty = checkint(stageConfig.difficulty)

	local CreateView = function ()

		-- 遮罩图
		local fg = display.newImageView(_res('ui/raid/hall/raid_boss_info_bg_cover.png'), 0, 0)
		local size = fg:getContentSize()

		self:setContentSize(size)

		-- 背景图
		local bgPath = BgPathConfig[difficulty]
		local bg = display.newImageView(_res(bgPath), 0, 0)
		display.commonUIParams(bg, {po = utils.getLocalCenter(self)})
		self:addChild(bg)

		display.commonUIParams(fg, {po = utils.getLocalCenter(self)})
		self:addChild(fg, 20)

		-- boss立绘
		local bossDrawNode = AssetsUtils.GetRaidBossPreviewDrawNode(stageConfig.skin)
		display.commonUIParams(bossDrawNode, {po = cc.p(
			size.width * 0.5,
			size.height * 0.55
		)})
		self:addChild(bossDrawNode, 10)

		local drawCoverPath = DrawCoverPathConfig[difficulty]
		local bossDrawCover = display.newImageView(_res(drawCoverPath), 0, 0)
		display.commonUIParams(bossDrawCover, {po = cc.p(
			bossDrawNode:getPositionX(),
			bossDrawNode:getPositionY()
		)})
		self:addChild(bossDrawCover, 21)

		------------ 顶部信息 ------------
		-- 标题
		local titleLabel = display.newLabel(0, 0,
			{text = tostring(stageConfig.name), fontSize = 46, color = '#60413a', ttf = true, font = TTF_GAME_FONT})
		display.commonUIParams(titleLabel, {ap = cc.p(0, 0), po = cc.p(
			70,
			size.height - 130
		)})
		fg:addChild(titleLabel)

		-- 难度
		local diffLabel = display.newLabel(0, 0, fontWithColor('18', {text = tostring(RaidDifficultyDescrConfig[difficulty])}))
		display.commonUIParams(diffLabel, {po = cc.p(
			87,
			size.height - 56
		)})
		fg:addChild(diffLabel)

		-- 需求等级
		local levelLimitLabel = display.newLabel(0, 0,
			{text = string.format(__('要求等级%d级'), checkint(stageConfig.unlockLevel)), fontSize = 20, color = '#b0917d'})
		display.commonUIParams(levelLimitLabel, {ap = cc.p(0, 1), po = cc.p(
			155,
			size.height - 45
		)})
		fg:addChild(levelLimitLabel)

		-- 难度星级
		local diffStars = {}
		local starAmount = checkint(stageConfig.recommendCombatValue)
		for i = 1, starAmount do
			local star = display.newNSprite(_res('ui/raid/hall/boss_info_star_bk.png'), 0, 0)
			display.commonUIParams(star, {ap = cc.p(0, 0), po = cc.p(
				size.width - 100 - (i - 1) * 30,
				titleLabel:getPositionY() + 10
			)})
			fg:addChild(star)

			table.insert(diffStars, {star = star})
		end

		-- 天气图标
		local weatherIcons = {}
		for i, weatherId in ipairs(stageConfig.weatherId) do
			local weatherConf = CommonUtils.GetConfig('quest', 'weather', checkint(weatherId))

			local weatherBtnBg = display.newNSprite(_res('ui/battle/battle_bg_weather.png'), 0, 0)
			display.commonUIParams(weatherBtnBg, {po = cc.p(
				size.width - 100 - (i - 1) * (weatherBtnBg:getContentSize().width + 5),
				size.height - 140 - weatherBtnBg:getContentSize().height * 0.5
			)})
			self:addChild(weatherBtnBg, 25)

			local weatherBtn = display.newButton(0, 0, {
				n = _res(string.format('ui/common/fight_ico_weather_%d.png', checkint(weatherConf.weatherProperty))),
				cb = function (sender)
					PlayAudioByClickNormal()
					uiMgr:ShowInformationTipsBoard({targetNode = sender, title = weatherConf.name, descr = weatherConf.descr, type = 5})
				end
			})
			display.commonUIParams(weatherBtn, {po = cc.p(
				weatherBtnBg:getPositionX(),
				weatherBtnBg:getPositionY()
			)})
			weatherBtn:setScale(weatherBtnBg:getContentSize().width / weatherBtn:getContentSize().width)
			self:addChild(weatherBtn, 26)

			table.insert(weatherIcons, {weatherBtnBg = weatherBtnBg, weatherBtn = weatherBtn})
		end

		-- 额外掉落
		local extraDropBg = display.newImageView(_res('ui/raid/hall/raid_boss_bg_loots_bonus.png'), 0, 0)
		display.commonUIParams(extraDropBg, {po = cc.p(
			size.width - 75 - extraDropBg:getContentSize().width * 0.5,
			size.height - 190 - extraDropBg:getContentSize().height * 0.5
		)})
		self:addChild(extraDropBg, 25)

		local extraDropLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('额外掉落')}))
		display.commonUIParams(extraDropLabel, {ap = cc.p(0.5, 1), po = cc.p(
			extraDropBg:getPositionX(),
			extraDropBg:getPositionY() + extraDropBg:getContentSize().height * 0.5 - 7
		)})
		self:addChild(extraDropLabel, 26)

		local extraGoodsIcon = nil
		if nil ~= stageConfig.extraRewards and 0 < #stageConfig.extraRewards then
			for i,v in ipairs(stageConfig.extraRewards) do
				extraGoodsIcon = require('common.GoodNode').new({
					goodsId = v.goodsId, showAmount = false, callBack = function (sender)
						PlayAudioByClickNormal()
						uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(v.goodsId), type = 1})
					end
				})
				extraGoodsIcon:setScale(0.8)
				display.commonUIParams(extraGoodsIcon, {po = cc.p(
					extraDropBg:getPositionX(),
					extraDropBg:getPositionY() - 15
				)})
				self:addChild(extraGoodsIcon, 26)
				break
			end
		else
			extraDropBg:setVisible(false)
			extraDropLabel:setVisible(false)
		end

		------------ 顶部信息 ------------

		------------ 底部信息 ------------
		local bottomSplitLine = display.newNSprite(_res('ui/common/common_ico_line_1.png'), 0, 0)
		display.commonUIParams(bottomSplitLine, {po = cc.p(
			size.width - 45 - bottomSplitLine:getContentSize().width * 0.5,
			215
		)})
		fg:addChild(bottomSplitLine)

		local dropLabel = display.newLabel(0, 0,
			{text = __('普通奖励'), fontSize = 20, color = '#b0917d'})
		display.commonUIParams(dropLabel, {ap = cc.p(0, 0), po = cc.p(
			bottomSplitLine:getPositionX() - bottomSplitLine:getContentSize().width * 0.5,
			bottomSplitLine:getPositionY() + bottomSplitLine:getContentSize().height * 0.5 + 2
		)})
		fg:addChild(dropLabel)

		-- 掉落警告
		local dropWaringBg = display.newImageView(_res('ui/home/materialScript/material_label_warning_2'), 0, 0 , {scale9 = true })
		display.commonUIParams(dropWaringBg, {po = cc.p(
			bottomSplitLine:getPositionX(),
			bottomSplitLine:getPositionY() - 50
		)})
		self:addChild(dropWaringBg, 30)

		local dropWaringLabel = display.newLabel(0, 0,
			{text = __('今日普通奖励次数已用完\n继续挑战仍有可能获得超稀有奖励'), fontSize = 20, color = '#ffffff', w = dropWaringBg:getContentSize().width, hAlign = display.TAC})
		local dropWaringLabelSize = display.getLabelContentSize(dropWaringLabel)
		dropWaringBg:setContentSize(cc.size(dropWaringLabelSize.width + 30 ,dropWaringLabelSize.height  ))
		dropWaringBg:addChild(dropWaringLabel)
		display.commonUIParams(dropWaringLabel, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(dropWaringBg)})


		-- 掉落信息
		local dropGoodsNodes = {}
		local rewardsAmount = math.min(4, #stageConfig.rewards)
		for i = 1, rewardsAmount do
			local rewardConfig = stageConfig.rewards[i]
			local goodsNode = require('common.GoodNode').new({
				id = checkint(rewardConfig.goodsId),
				amount = checkint(rewardConfig.num),
				showAmount = true,
				callBack = function (sender)
					PlayAudioByClickNormal()
					uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(rewardConfig.goodsId), type = 1})
				end
			})
			local gooodsNodeScale = 75 / goodsNode:getContentSize().width
			goodsNode:setScale(gooodsNodeScale)
			display.commonUIParams(goodsNode, {po = cc.p(
				bottomSplitLine:getPositionX() - bottomSplitLine:getContentSize().width * 0.5 + (i - 0.5) * (goodsNode:getContentSize().width * gooodsNodeScale + 10),
				bottomSplitLine:getPositionY() - bottomSplitLine:getContentSize().height * 0.5 - 10 - goodsNode:getContentSize().height * 0.5 * gooodsNodeScale
			)})
			self:addChild(goodsNode, 26)

			table.insert(dropGoodsNodes, {goodsNode = goodsNode})
		end

		-- 购买剩余普通奖励次数
		local buyBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_add.png'), cb = handler(self, self.BuyLeftNormalDropTimesClickHandler)})
		display.commonUIParams(buyBtn, {po = cc.p(
			bottomSplitLine:getPositionX() + bottomSplitLine:getContentSize().width * 0.5 - buyBtn:getContentSize().width * 0.5,
			bottomSplitLine:getPositionY() + buyBtn:getContentSize().height * 0.5 +30
		)})
		self:addChild(buyBtn, 26)

		local leftTimesLabel = display.newLabel(0, 0,
			fontWithColor('6', {text = string.format(__('剩余普通奖励次数:%d'), self.leftNormalDropTimes), fontSize = 20}))
		display.commonUIParams(leftTimesLabel, {ap = cc.p(1, 0.5), po = cc.p(
			buyBtn:getPositionX() - buyBtn:getContentSize().width * 0.5 ,
			buyBtn:getPositionY() - 5
		)})
		self:addChild(leftTimesLabel, 26)
		------------ 底部信息 ------------

		-- 关卡评论按钮
		local stageCommentBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png'), cb = handler(self, self.StageCommentBtnClickHandler)})
		display.commonUIParams(stageCommentBtn, {po = cc.p(
			bottomSplitLine:getPositionX() - bottomSplitLine:getContentSize().width * 0.5 + stageCommentBtn:getContentSize().width * 0.5 + 10,
			bottomSplitLine:getPositionY() - 130
		)})
		display.commonLabelParams(stageCommentBtn, fontWithColor('14', {text = __('关卡评论')}))
		self:addChild(stageCommentBtn, 26)

		-- boss详情按钮
		local bossDetailBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png'), cb = handler(self, self.BossDetailBtnClickHandler)})
		display.commonUIParams(bossDetailBtn, {po = cc.p(
			bottomSplitLine:getPositionX() + bottomSplitLine:getContentSize().width * 0.5 - bossDetailBtn:getContentSize().width * 0.5 - 15,
			stageCommentBtn:getPositionY()
		)})
		display.commonLabelParams(bossDetailBtn, fontWithColor('14', {text = __('boss详情')}))
		self:addChild(bossDetailBtn, 26)

		return {
			fg = fg,
			bg = bg,
			bossDrawNode = bossDrawNode,
			bossDrawCover = bossDrawCover,
			titleLabel = titleLabel,
			diffLabel = diffLabel,
			levelLimitLabel = levelLimitLabel,
			diffStars = diffStars,
			weatherIcons = weatherIcons,
			dropGoodsNodes = dropGoodsNodes,
			bottomSplitLine = bottomSplitLine,
			rareRewardBg = nil,
			gotRewardLabel = nil,
			rareRewardGoodsNode = nil,
			dropWaringBg = dropWaringBg,
			buyBtn = buyBtn,
			leftTimesLabel = leftTimesLabel,
			extraDropBg = extraDropBg,
			extraDropLabel = extraDropLabel,
			extraGoodsIcon = extraGoodsIcon
		}
	end

	xTry(function ()
		self.viewData = CreateView()

		self:RefreshRareReward(self.stageId, self.gotRareReward)
		self:RefreshLeftNormalDropTimes(self.leftNormalDropTimes)

	end, __G__TRACKBACK__)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新ui
@params stageId int 关卡id
@params gotRareReward int 是否获得稀有奖励 1 有 0 没有
@params leftNormalDropTimes int 剩余普通奖励掉落次数
--]]
function RaidStageDetailView:RefreshUI(stageId, gotRareReward, leftNormalDropTimes)
	self.stageId = stageId
	self.gotRareReward = 1 == checkint(gotRareReward)

	self:RefreshUIByStageId(self.stageId)
	self:RefreshRareReward(self.stageId, self.gotRareReward)
	self:RefreshLeftNormalDropTimes(leftNormalDropTimes)
end
--[[
根据关卡id刷新界面
@params stageId int 关卡id
--]]
function RaidStageDetailView:RefreshUIByStageId(stageId)
	local stageConfig = CommonUtils.GetQuestConf(stageId)
	local difficulty = checkint(stageConfig.difficulty)

	local size = self:getContentSize()

	-- 背景图
	local bgPath = BgPathConfig[difficulty]
	self.viewData.bg:setTexture(_res(bgPath))

	-- 立绘
	self.viewData.bossDrawNode:setTexture(CardUtils.GetRaidBossPreviewDrawPathBySkinId(checkint(stageConfig.skin)))

	-- 立绘遮罩
	self.viewData.bossDrawCover:setTexture(DrawCoverPathConfig[difficulty])
	-- 标题
 	display.commonLabelParams(self.viewData.titleLabel, {text = tostring(stageConfig.name) , reqW = 340})
	-- 难度
	self.viewData.diffLabel:setString(tostring(RaidDifficultyDescrConfig[difficulty]))

	-- 需求等级
	self.viewData.levelLimitLabel:setString(string.format(__('要求等级%d级'), checkint(stageConfig.unlockLevel)))

	-- 难度星级
	for i,v in ipairs(self.viewData.diffStars) do
		v.star:removeFromParent()
	end
	self.viewData.diffStars = {}
	local starAmount = checkint(stageConfig.recommendCombatValue)
	for i = 1, starAmount do
		local star = display.newNSprite(_res('ui/raid/hall/boss_info_star_bk.png'), 0, 0)
		display.commonUIParams(star, {ap = cc.p(0, 0), po = cc.p(
			size.width - 100 - (i - 1) * 30,
			self.viewData.titleLabel:getPositionY() + 10
		)})
		self.viewData.fg:addChild(star)

		table.insert(self.viewData.diffStars, {star = star})
	end

	-- 天气图标
	for i,v in ipairs(self.viewData.weatherIcons) do
		v.weatherBtnBg:removeFromParent()
		v.weatherBtn:removeFromParent()
	end
	self.viewData.weatherIcons = {}
	for i, weatherId in ipairs(stageConfig.weatherId) do
		local weatherConf = CommonUtils.GetConfig('quest', 'weather', checkint(weatherId))

		local weatherBtnBg = display.newNSprite(_res('ui/battle/battle_bg_weather.png'), 0, 0)
		display.commonUIParams(weatherBtnBg, {po = cc.p(
			size.width - 100 - (i - 1) * (weatherBtnBg:getContentSize().width + 5),
			size.height - 140 - weatherBtnBg:getContentSize().height * 0.5
		)})
		self:addChild(weatherBtnBg, 25)

		local weatherBtn = display.newButton(0, 0, {
			n = _res(string.format('ui/common/fight_ico_weather_%d.png', checkint(weatherConf.weatherProperty))),
			cb = function (sender)
				PlayAudioByClickNormal()
				uiMgr:ShowInformationTipsBoard({targetNode = sender, title = weatherConf.name, descr = weatherConf.descr, type = 5})
			end
		})
		display.commonUIParams(weatherBtn, {po = cc.p(
			weatherBtnBg:getPositionX(),
			weatherBtnBg:getPositionY()
		)})
		weatherBtn:setScale(weatherBtnBg:getContentSize().width / weatherBtn:getContentSize().width)
		self:addChild(weatherBtn, 26)

		table.insert(self.viewData.weatherIcons, {weatherBtnBg = weatherBtnBg, weatherBtn = weatherBtn})
	end

	-- 额外奖励
	if nil ~= stageConfig.extraRewards and 0 < #stageConfig.extraRewards then
		self.viewData.extraDropBg:setVisible(true)
		self.viewData.extraDropLabel:setVisible(true)

		if nil ~= self.viewData.extraGoodsIcon then
			self.viewData.extraGoodsIcon:removeFromParent()
			self.viewData.extraGoodsIcon = nil
		end

		for i,v in ipairs(stageConfig.extraRewards) do
			local extraGoodsIcon = require('common.GoodNode').new({
				goodsId = v.goodsId, showAmount = false, callBack = function (sender)
					PlayAudioByClickNormal()
					uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(v.goodsId), type = 1})
				end
			})
			extraGoodsIcon:setScale(0.8)
			display.commonUIParams(extraGoodsIcon, {po = cc.p(
				self.viewData.extraDropBg:getPositionX(),
				self.viewData.extraDropBg:getPositionY() - 15
			)})
			self:addChild(extraGoodsIcon, 26)
			self.viewData.extraGoodsIcon = extraGoodsIcon
			break
		end
	else
		if nil ~= self.viewData.extraGoodsIcon then
			self.viewData.extraGoodsIcon:setVisible(false)
		end
		self.viewData.extraDropBg:setVisible(false)
		self.viewData.extraDropLabel:setVisible(false)
	end

	-- 奖励图标
	for i,v in ipairs(self.viewData.dropGoodsNodes) do
		v.goodsNode:removeFromParent()
	end
	self.viewData.dropGoodsNodes = {}
	local rewardsAmount = math.min(4, #stageConfig.rewards)
	for i = 1, rewardsAmount do
		local rewardConfig = stageConfig.rewards[i]
		local goodsNode = require('common.GoodNode').new({
			id = checkint(rewardConfig.goodsId),
			amount = checkint(rewardConfig.num),
			showAmount = true,
			callBack = function (sender)
				PlayAudioByClickNormal()
				uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(rewardConfig.goodsId), type = 1})
			end
		})
		local gooodsNodeScale = 75 / goodsNode:getContentSize().width
		goodsNode:setScale(gooodsNodeScale)
		display.commonUIParams(goodsNode, {po = cc.p(
			self.viewData.bottomSplitLine:getPositionX() - self.viewData.bottomSplitLine:getContentSize().width * 0.5 + (i - 0.5) * (goodsNode:getContentSize().width * gooodsNodeScale + 10),
			self.viewData.bottomSplitLine:getPositionY() - self.viewData.bottomSplitLine:getContentSize().height * 0.5 - 10 - goodsNode:getContentSize().height * 0.5 * gooodsNodeScale
		)})
		self:addChild(goodsNode, 26)

		table.insert(self.viewData.dropGoodsNodes, {goodsNode = goodsNode})
	end
end
--[[
刷新稀有奖励
@params stageId int 关卡id
@params gotRareReward bool 是否获得了超稀有奖励
--]]
function RaidStageDetailView:RefreshRareReward(stageId, gotRareReward)
	local stageConfig = CommonUtils.GetQuestConf(stageId)
	local rareRewardConfig = nil
	if 0 ~= checkint(stageConfig.group) then
		rareRewardConfig = CommonUtils.GetConfig('quest', 'teamBossGroupReward', checkint(stageConfig.group))
	end

	if nil == self.viewData.rareRewardBg then
		-- 稀有掉落

		local rareRewardBg = display.newImageView(_res('ui/raid/hall/raid_boss_bg_loots.png'), 0, 0)
		local  rareRewardBgSize = rareRewardBg:getContentSize()
		display.commonUIParams(rareRewardBg, {po = cc.p(
			55 + rareRewardBgSize.width * 0.5,
			55 + rareRewardBgSize.height * 0.5
		)})
		self:addChild(rareRewardBg, 20)

		local rareRewardTitleLabel = display.newLabel(0, 0, {text = __('超稀有奖励'),reqW = 150, fontSize = 20, color = '#60413a'})
		display.commonUIParams(rareRewardTitleLabel, {po = cc.p(
				rareRewardBgSize.width * 0.5,
				rareRewardBgSize.height - 30
		)})
		rareRewardBg:addChild(rareRewardTitleLabel)

		local gotRewardLabel = display.newLabel(0, 0, {text = __('已获得'), fontSize = 20, color = '#c07431'})
		display.commonUIParams(gotRewardLabel, {po = cc.p(
			rareRewardTitleLabel:getPositionX(),
			25
		)})
		rareRewardBg:addChild(gotRewardLabel)
		if utils.isExistent( _res('ui/home/activity/doubleActivity/raid_activity_label_slice')) then
			local raidActivityButton = display.newButton(rareRewardBgSize.width /2 , rareRewardBgSize.height - 180 , {n = _res('ui/home/activity/doubleActivity/raid_activity_label_slice') , scale9 =true  })
			rareRewardBg:addChild(raidActivityButton )

			local raidActivityButtonSize = raidActivityButton:getContentSize()
			local raidActivityLabel = display.newButton(raidActivityButtonSize.width/2 , raidActivityButtonSize.height/2 , {n = _res('ui/home/activity/doubleActivity/raid_activity_label_star') })
			raidActivityButton:addChild(raidActivityLabel)
			raidActivityButton:setVisible(false)
			display.commonLabelParams(raidActivityButton , fontWithColor('14' , {text = __('限时概率up！'),fontSize = 21  , paddingW = 18  }))
			self.viewData.raidActivityButton = raidActivityButton
		end

		self.viewData.rareRewardBg = rareRewardBg
		self.viewData.gotRewardLabel = gotRewardLabel
	end
	self.viewData.gotRewardLabel:setVisible(gotRareReward)

	if nil == rareRewardConfig then
		self.viewData.rareRewardBg:setVisible(false)
		if nil ~= self.viewData.rareRewardGoodsNode then
			self.viewData.rareRewardGoodsNode:setVisible(false)
		end
	else
		self.viewData.rareRewardBg:setVisible(true)
		---@type RaidHallMediator
		local mediator = app:RetrieveMediator("RaidHallMediator")
		local callfunc = function()
			if self.viewData.raidActivityButton then
				self.viewData.raidActivityButton:setVisible(false)
			end
			mediator = app:RetrieveMediator("RaidHallMediator")
			if mediator then
				local  raidData = mediator.raidData[1] or {}
				local activityGroups = raidData.activityGroups  or {}
				for index , groupId  in pairs(activityGroups) do
					-- 检测是否有详情的groupId
					if checkint(groupId) ==  checkint(stageConfig.group) then
						if self.viewData.raidActivityButton then
							self.viewData.raidActivityButton:setVisible(true)
						end
					end
				end
			end
		end
		if not  gotRareReward then
			if mediator then
				callfunc()
			else
				self:runAction(
					cc.Sequence:create(
						cc.DelayTime:create(0.1 ) ,
						cc.CallFunc:create(
							function()
								callfunc()
							end
						)
					)
				)
			end
		else
			if self.viewData.raidActivityButton then
				self.viewData.raidActivityButton:setVisible(false)
			end
		end
		if nil == self.viewData.rareRewardGoodsNode then
			local rareRewardGoodsNode = require('common.GoodNode').new({
				goodsId = checkint(rareRewardConfig.reward.goodsId),
				amount = checkint(rareRewardConfig.reward.num),
				showAmount = true,
				callBack = function (sender)
					PlayAudioByClickNormal()

					local stageConfig = CommonUtils.GetQuestConf(self.stageId)
					local rareRewardConfig = CommonUtils.GetConfig('quest', 'teamBossGroupReward', checkint(stageConfig.group))
					uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(rareRewardConfig.reward.goodsId), type = 1})
				end
			})
			display.commonUIParams(rareRewardGoodsNode, {po = cc.p(
				self.viewData.rareRewardBg:getPositionX(),
				self.viewData.rareRewardBg:getPositionY()
			)})
			self:addChild(rareRewardGoodsNode, 26)
			self.viewData.rareRewardGoodsNode = rareRewardGoodsNode
		else
			self.viewData.rareRewardGoodsNode:setVisible(true)
			self.viewData.rareRewardGoodsNode:RefreshSelf({
				goodsId = checkint(rareRewardConfig.reward.goodsId),
				amount = checkint(rareRewardConfig.reward.num)
			})
		end
	end
end
--[[
刷新剩余次数
@params leftNormalDropTimes bool 是否显示
--]]
function RaidStageDetailView:RefreshLeftNormalDropTimes(leftNormalDropTimes)
	self.leftNormalDropTimes = leftNormalDropTimes

	self.viewData.buyBtn:setVisible(self.enableBuyNormalDropTimes)
	self.viewData.leftTimesLabel:setVisible(self.enableBuyNormalDropTimes)
	--self.viewData.leftTimesLabel:setString(string.format(__('剩余普通奖励次数:%d'), leftNormalDropTimes))
    display.commonLabelParams(self.viewData.leftTimesLabel , {text =  string.format(__('剩余普通奖励次数:%d'), leftNormalDropTimes) ,  w =230,hAlign = display.TAC })
	self:ShowDropWaring(leftNormalDropTimes)
end
--[[
刷新基础掉落警告
@params leftNormalDropTimes bool 是否显示
--]]
function RaidStageDetailView:ShowDropWaring(leftNormalDropTimes)
	self.viewData.dropWaringBg:setVisible(0 >= checkint(leftNormalDropTimes) and self.enableDropWaring)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- handler end --
---------------------------------------------------
--[[
注册信号回调
--]]
function RaidStageDetailView:RegisterSignal()
	------------ 购买剩余购买次数成功 ------------
	AppFacade.GetInstance():RegistObserver('RAID_REFRESH_LEFT_CHALLENGE_TIMES', mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		self:RefreshLeftNormalDropTimes(checkint(data.currentTimes))
	end, self))
	------------ 购买剩余购买次数成功 ------------
end
--[[
注销信号
--]]
function RaidStageDetailView:UnRegistSignal()
	AppFacade.GetInstance():UnRegistObserver('RAID_REFRESH_LEFT_CHALLENGE_TIMES', self)
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
关卡评论按钮回调
--]]
function RaidStageDetailView:StageCommentBtnClickHandler(sender)
	PlayAudioByClickNormal()

	local difficultyConfig = {
	    ['1'] = __('简单'),
	    ['2'] = __('普通'),
	    ['3'] = __('困难')
	}
	local stageConfig = CommonUtils.GetQuestConf(self.stageId)
	local stageTitleText = string.format('%s(%s)', tostring(stageConfig.name), difficultyConfig[tostring(stageConfig.difficulty)])

	local data = {
		stageId = self.stageId,
		stageTitleText = stageTitleText
	}
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.QuestComment_CommentView, data)
end
--[[
boss详情按钮回调
--]]
function RaidStageDetailView:BossDetailBtnClickHandler(sender)
	PlayAudioByClickNormal()

	local stageConfig = CommonUtils.GetQuestConf(self.stageId)
	AppFacade.GetInstance():RegistMediator(
		require('Game.mediator.BossDetailMediator').new({questId = self.stageId})
	)
end
--[[
购买剩余挑战次数按钮回调
--]]
function RaidStageDetailView:BuyLeftNormalDropTimesClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('RAID_SHOW_BUY_CHALLENGE_TIMES')
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------
function RaidStageDetailView:onCleanup()
	-- 注销信号
	self:UnRegistSignal()
end

return RaidStageDetailView
