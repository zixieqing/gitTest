--[[
世界boss主场景
--]]
local GameScene = require( "Frame.GameScene" )
local WorldBossScene = class("WorldBossScene", GameScene)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------

------------ define ------------
local SceneZorder = {
	BASE 				= 1,
	MONSTER_SPINE 		= 2,
	UI 					= 20,
	TOP 				= 90
}

local cardHeadNodeSize = cc.size(96, 96)
------------ define ------------

--[[
constructor
--]]
function WorldBossScene:ctor(...)
	local args = unpack({...})

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function WorldBossScene:InitUI()

	local function CreateView()
		local size = self:getContentSize()

		local bg = display.newImageView(_res('ui/worldboss/home/worldboss_bg.jpg'), 0, 0)
		-- local bg = display.newImageView(_res('ui/home/handbook/pokedex_monster_bg.jpg'), 0, 0)
		display.commonUIParams(bg, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(bg)

		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height + 100,{n = _res('ui/common/common_title_new.png'), enable = true, ap = cc.p(0, 0)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('灾祸'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, SceneZorder.TOP)

		tabNameLabel:addChild(display.newImageView(_res('ui/common/common_btn_tips.png'), tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10))

		-- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res('ui/common/common_btn_back.png'), cb = handler(self, self.BackBtnClickHandler)})
		self:addChild(backBtn, SceneZorder.TOP + 10)

		-- 底部选卡界面
		local bottomBg = display.newImageView(_res('ui/worldboss/home/worldboss_bg_below.png'), 0, 0, {scale9 = true})
		display.commonUIParams(bottomBg, {po = cc.p(
			size.width * 0.5,
			bottomBg:getContentSize().height * 0.5
		)})
		self:addChild(bottomBg, SceneZorder.UI)
		bottomBg:setContentSize(cc.size(size.width, bottomBg:getContentSize().height))

		local teamBg = display.newImageView(_res('ui/worldboss/home/worldboss_team_bg.png'), 0, 0)
		display.commonUIParams(teamBg, {po = cc.p(
			display.SAFE_L - 60 + teamBg:getContentSize().width * 0.5,
			teamBg:getContentSize().height * 0.5
		)})
		self:addChild(teamBg, SceneZorder.UI)

		local emptyCardNodes = {}
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			local emptyCardHeadBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'))
			local scale = cardHeadNodeSize.width / emptyCardHeadBg:getContentSize().width
			emptyCardHeadBg:setScale(scale)
			display.commonUIParams(emptyCardHeadBg, {po = cc.p(
				teamBg:getPositionX() + (emptyCardHeadBg:getContentSize().width * scale + 10) * (i - 0.5 - MAX_TEAM_MEMBER_AMOUNT * 0.5),
				teamBg:getPositionY() - 30
			)})
			self:addChild(emptyCardHeadBg, SceneZorder.UI + 1)

			local emptyCardHeadFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), 0, 0)
			display.commonUIParams(emptyCardHeadFrame, {po = utils.getLocalCenter(emptyCardHeadBg)})
			emptyCardHeadBg:addChild(emptyCardHeadFrame)

			local addIcon = display.newNSprite(_res('ui/common/maps_fight_btn_pet_add.png'), 0, 0)
			display.commonUIParams(addIcon, {po = utils.getLocalCenter(emptyCardHeadBg)})
			addIcon:setScale(1 / scale)
			emptyCardHeadBg:addChild(addIcon)

			local btn = display.newButton(0, 0, {size = cardHeadNodeSize, cb = handler(self, self.EditTeamMemberClickHandler)})
			display.commonUIParams(btn, {po = cc.p(
				emptyCardHeadBg:getPositionX(),
				emptyCardHeadBg:getPositionY()
			)})
			self:addChild(btn, SceneZorder.UI + 2)

			-- 添加队长标识
			if 1 == i then
				local captainMark = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
				display.commonUIParams(captainMark, {po = cc.p(
					emptyCardHeadBg:getPositionX(),
					emptyCardHeadBg:getPositionY() + emptyCardHeadBg:getContentSize().height * 0.5 * scale
				)})
				self:addChild(captainMark, SceneZorder.TOP)
			end

			emptyCardNodes[i] = {emptyCardHeadBg = emptyCardHeadBg}
		end

		if GAME_MODULE_OPEN.PRESET_TEAM and CommonUtils.UnLockModule(JUMP_MODULE_DATA.PRESET_TEAM_WB) then
			-- 预设队伍按钮
			local presetTeamBtn = require("Game.views.presetTeam.PresetTeamEntranceButton").new({isSelectMode = true})
			display.commonUIParams(presetTeamBtn, {po = cc.p(
				teamBg:getPositionX() + teamBg:getContentSize().width * 0.5 + 10,
				bottomBg:getPositionY() - 15
			)})
			display.commonLabelParams(presetTeamBtn, fontWithColor('14', {text = __('预设队伍')}))
			self:addChild(presetTeamBtn, SceneZorder.TOP)
		end

		-- 下一步按钮
		local templabel = display.newLabel(0, 0, fontWithColor(14, {text = __('下一步')}))
		local tempLabelW = display.getLabelContentSize(templabel).width
		local nextBtn = display.newButton(0, 0,
			{n = _res('ui/common/common_btn_orange.png'), d = _res('ui/common/common_btn_orange_disable.png'), cb = handler(self, self.NextBtnClickHandler), scale9 = true, size = cc.size(math.max(123, tempLabelW + 20), 60)})
		display.commonUIParams(nextBtn, {po = cc.p(
			display.SAFE_R - 150 - nextBtn:getContentSize().width * 0.5,
			bottomBg:getPositionY() - 15
		)})
		display.commonLabelParams(nextBtn, fontWithColor('14', {text = __('下一步')}))
		self:addChild(nextBtn, SceneZorder.TOP)

		local leftChallengeLabel = display.newLabel(0, 0, fontWithColor('9', {text = '今日剩余次数:8'}))
		display.commonUIParams(leftChallengeLabel, {ap = cc.p(0.5, 1), po = cc.p(
			nextBtn:getPositionX(),
			nextBtn:getPositionY() - nextBtn:getContentSize().height * 0.5
		)})
		self:addChild(leftChallengeLabel, SceneZorder.TOP)

		-- 本次挑战伤害
		local splitLine = display.newNSprite(_res('ui/worldboss/home/world_boss_ico_line.png'), 0, 0)
		display.commonUIParams(splitLine, {po = cc.p(
			nextBtn:getPositionX() - nextBtn:getContentSize().width * 0.5 - 80 - splitLine:getContentSize().width * 0.5,
			nextBtn:getPositionY()
		)})
		self:addChild(splitLine, SceneZorder.TOP)

		local currentDamageTitleLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('本次挑战造成伤害'), fontSize = 24}))
		display.commonUIParams(currentDamageTitleLabel, {ap = cc.p(0.5, 0), po = cc.p(
			splitLine:getPositionX(),
			splitLine:getPositionY() + 5
		)})
		self:addChild(currentDamageTitleLabel, SceneZorder.TOP)

		local currentDamageLabel = display.newLabel(0, 0, fontWithColor('14', {text = '88888888', fontSize = 26, outline = '#593d3b'}))
		display.commonUIParams(currentDamageLabel, {ap = cc.p(0.5, 1), po = cc.p(
			splitLine:getPositionX(),
			splitLine:getPositionY() - 5
		)})
		self:addChild(currentDamageLabel, SceneZorder.TOP)

		-- 奖励 说明部分
		local descrBg = display.newImageView(_res('ui/union/hunt/guild_hunt_bg_moster_info.png'), 0, 0)
		local descrLayerSize = descrBg:getContentSize()

		local descrLayer = display.newLayer(0, 0, {size = descrLayerSize})
		display.commonUIParams(descrLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			display.SAFE_L + descrLayerSize.width * 0.5 + 10,
			bottomBg:getPositionY() + bottomBg:getContentSize().height * 0.5 + descrLayerSize.height * 0.5 - 20
		)})
		self:addChild(descrLayer, SceneZorder.TOP)

		display.commonUIParams(descrBg, {po = utils.getLocalCenter(descrLayer)})
		descrLayer:addChild(descrBg)

		-- 宝箱图标
		local rewardIcon = display.newButton(0, 0, {n = _res('ui/worldboss/home/worldboss_ico_rewards.png'), cb = handler(self, self.RewardReviewBtnClickHandler)})
		display.commonUIParams(rewardIcon, {po = cc.p(
			10 + rewardIcon:getContentSize().width * 0.5,
			10 + rewardIcon:getContentSize().height * 0.5
		)})
		descrLayer:addChild(rewardIcon)

		local rewardLabel = display.newLabel(0, 0, fontWithColor('19', {text = __('奖励预览'), fontSize = 22 ,reqW = 180}))
		display.commonUIParams(rewardLabel, {ap = cc.p(0.4, 0), po = cc.p(
			rewardIcon:getContentSize().width * 0.5,
			-20
		)})
		rewardIcon:addChild(rewardLabel)

		-- 关卡信息
		local stageTitleLabel = display.newLabel(0, 0, fontWithColor('20', {text = '测试：测试关卡', fontSize = 48, outline = '#593d3b'}))
		display.commonUIParams(stageTitleLabel, {ap = cc.p(0, 1), po = cc.p(
			rewardIcon:getPositionX() + rewardIcon:getContentSize().width * 0.5 + 5,
			descrLayerSize.height - 5
		)})
		descrLayer:addChild(stageTitleLabel)

		-- 血条
		local hpBar = CProgressBar:create(_res('ui/union/hunt/guild_hunt_bg_loading_blood_l.png'))
		hpBar:setAnchorPoint(cc.p(0, 0.5))
		hpBar:setBackgroundImage(_res('ui/union/hunt/guild_hunt_bg_blood_l.png'))
		hpBar:setDirection(eProgressBarDirectionLeftToRight)
		hpBar:setPosition(cc.p(
			stageTitleLabel:getPositionX(),
			hpBar:getContentSize().height * 0.5 + 12
		))
		descrLayer:addChild(hpBar)
		hpBar:setMaxValue(100)
		hpBar:setValue(73)

		local hpPercentLabel = display.newLabel(0, 0, fontWithColor('14', {text = '88.88%', fontSize = 22, outline = '#593d3b'}))
		display.commonUIParams(hpPercentLabel, {po = cc.p(
			hpBar:getPositionX() + hpBar:getContentSize().width * 0.5,
			hpBar:getPositionY()
		)})
		descrLayer:addChild(hpPercentLabel)

		local hpLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('剩余血量'), fontSize = 20, outline = '#593d3b'}))
		display.commonUIParams(hpLabel, {ap = cc.p(0, 0.5), po = cc.p(
			hpBar:getPositionX() + 5,
			hpBar:getPositionY()
		)})
		descrLayer:addChild(hpLabel)

		-- 剩余时间
		local leftTimeTitleLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('剩余时间'), fontSize = 22}))
		display.commonUIParams(leftTimeTitleLabel, {ap = cc.p(0.5, 1), po = cc.p(
			descrLayerSize.width - 310,
			descrLayerSize.height - 10
		)})
		descrLayer:addChild(leftTimeTitleLabel)

		local leftTimeLabel = display.newLabel(0, 0, fontWithColor('14', {text = '88:88:88', fontSize = 26, outline = '#593d3b'}))
		display.commonUIParams(leftTimeLabel, {ap = cc.p(0.5, 1), po = cc.p(
			leftTimeTitleLabel:getPositionX(),
			leftTimeTitleLabel:getPositionY() - 25
		)})
		descrLayer:addChild(leftTimeLabel)

		-- boss详情按钮
		local bossDetailBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png'), cb = handler(self, self.BossDetailBtnClickHandler)})
		display.commonUIParams(bossDetailBtn, {po = cc.p(
			descrLayerSize.width - 25 - bossDetailBtn:getContentSize().width * 0.5,
			descrLayerSize.height - 5 - bossDetailBtn:getContentSize().height * 0.5
		)})
		display.commonLabelParams(bossDetailBtn, fontWithColor('14', {text = __('boss详情')}))
		descrLayer:addChild(bossDetailBtn)

		-- 顶部伤害
		local scoreBarSize = cc.size(236 + display.width - display.SAFE_R, 66)
		local damageBar = display.newImageView(_res('ui/tower/tower_btn_myscore.png'), 0, 0, {scale9 = true, size = scoreBarSize, capInsets = cc.rect(235,0,1,1)})
		display.commonUIParams(damageBar, {ap = cc.p(1, 1), po = cc.p(
			display.width, size.height - 10
		)})
		self:addChild(damageBar, SceneZorder.TOP)

		local damageTitleLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('最高伤害')}))
		display.commonUIParams(damageTitleLabel, {ap = cc.p(1, 0.5), po = cc.p(
			display.SAFE_R - 80, size.height - 28
		)})
		self:addChild(damageTitleLabel, SceneZorder.TOP)

		local maxDamageLabel = display.newLabel(0, 0, fontWithColor('9', {text = '----'}))
		display.commonUIParams(maxDamageLabel, {ap = cc.p(1, 0.5), po = cc.p(
			display.SAFE_R - 80, size.height - 63
		)})
		self:addChild(maxDamageLabel, SceneZorder.TOP)

		local rankBtn = display.newButton(display.SAFE_R + 5, size.height, {n = _res('ui/home/nmain/main_btn_rank.png'), ap = display.RIGHT_TOP, cb = handler(self, self.RankBtnClickHandler)})
		display.commonLabelParams(rankBtn, fontWithColor(14, {fontSize = 23, text = __('排行榜'), offset = cc.p(0, -46)}))
		self:addChild(rankBtn, SceneZorder.TOP)

		if CommonUtils.UnLockModule(RemindTag.WORLD_BOSS_MANUAL, false) then
			-- 灾祸手册入口
			local manualBtn = display.newButton(display.SAFE_R - 100, size.height - 168, {n = _res('ui/worldboss/manual/wordboss_ico_btn.png'), ap = display.CENTER, cb = handler(self, self.ManualBtnClickHandler)})
			local manualBtnSize = manualBtn:getContentSize()
			self:addChild(manualBtn, SceneZorder.TOP)
			require('common.RemindIcon').addRemindIcon({parent = manualBtn, tag = RemindTag.WORLD_BOSS_MANUAL, po = cc.p(manualBtnSize.width - 16, manualBtnSize.height - 15)})
	
			local manualNameBg = display.newImageView(_res('ui/worldboss/manual/boosstrategy_ranks_name_bg.png'), manualBtn:getPositionX(), manualBtn:getPositionY() - manualBtn:getContentSize().height / 2 + 3, {ap = display.CENTER})
			local manualNameBgSize = manualNameBg:getContentSize()
			self:addChild(manualNameBg, SceneZorder.TOP)
			manualNameBg:addChild(display.newLabel(manualNameBgSize.width / 2, manualNameBgSize.height / 2, {ap = display.CENTER, color = '#ffffff', fontSize = 20, reqW = 180 ,  text = __('灾祸手册')}))
		end

		return {
			tabNameLabel = tabNameLabel,
			bossSpineNode = nil,
			bossBgSpineNode = nil,
			bossFgSpineNode = nil,
			stageTitleLabel = stageTitleLabel,
			hpPercentLabel = hpPercentLabel,
			leftTimeLabel = leftTimeLabel,
			hpBar = hpBar,
			nextBtn = nextBtn,
			leftChallengeLabel = leftChallengeLabel,
			bottomBg = bottomBg,
			maxDamageLabel = maxDamageLabel,
			splitLine = splitLine,
			currentDamageTitleLabel = currentDamageTitleLabel,
			currentDamageLabel = currentDamageLabel,
			teamCardHeadNodes = {},
			emptyCardNodes = emptyCardNodes
		}
	end

	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	-- 弹出标题班
	local action = cc.Sequence:create(
		cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 130, display.height - 80))),
		cc.CallFunc:create(function ()
			display.commonUIParams(self.viewData.tabNameLabel, {cb = function (sender)
				uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.WORLD_BOSS)]})
			end})
		end)
	)
	self.viewData.tabNameLabel:runAction(action)

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据关卡id和boss信息刷新界面
@params questId
@params bossData table boss信息
--]]
function WorldBossScene:RefreshUI(questId, bossData)
	-- 刷新关卡信息
	self:RefreshQuestInfo(questId, bossData)
	-- 刷新中间boss spine
	self:RefreshBossSpine(questId)
end
--[[
根据关卡id boss信息刷新界面
@params questId int 关卡id
@params bossData table boss信息
--]]
function WorldBossScene:RefreshQuestInfo(questId, bossData)
	local questConfig = CommonUtils.GetQuestConf(questId)
	if nil ~= questConfig then
		-- 关卡名
		self.viewData.stageTitleLabel:setString(tostring(questConfig.name))
		-- boss血量
		self:RefreshHpBar(checkint(bossData.remainHp), cardMgr.GetShareBossTotalHpByQuestId(questId))
		-- 剩余时间
		self:RefreshLeftTime(checkint(bossData.leftSeconds))
		-- 最大伤害
		self:RefreshMaxDamage(checkint(bossData.maxDamage))
		-- 当前伤害
		self:RefreshCurDamage(checkint(bossData.currentDamage))
		-- 刷新挑战次数
		self:RefreshLeftChallengeTime(checkint(bossData.leftTimes))
	end
end
--[[
刷新剩余时间
@params second int 剩余秒数
--]]
function WorldBossScene:RefreshLeftTime(second)
	self.viewData.leftTimeLabel:setString(self:GetFormattedTimeStr(second))
end
--[[
根据血量刷新世界Boss血条
@params curHp int 当前血量
@params totalHp int 总血量
--]]
function WorldBossScene:RefreshHpBar(curHp, totalHp)
	-- 转换一次数据
	local percent = math.max(0.01, math.ceil(curHp / totalHp * 10000) * 0.01)

	local maxValue = 10000
	local value = maxValue * percent * 0.01

	self.viewData.hpBar:setMaxValue(maxValue)
	self.viewData.hpBar:setValue(value)
	self.viewData.hpPercentLabel:setString(
		string.format('%s%%', tostring(percent))
	)
end
--[[
刷新最高伤害
@params damage int 伤害
--]]
function WorldBossScene:RefreshMaxDamage(damage)
	local str = damage > 0 and tostring(damage) or '----'
	self.viewData.maxDamageLabel:setString(str)
end
--[[
刷新当前伤害
--]]
function WorldBossScene:RefreshCurDamage(damage)
	self.viewData.currentDamageLabel:setString(tostring(damage))
end
--[[
刷新挑战次数
@params leftChallengeTime int 剩余挑战次数
--]]
function WorldBossScene:RefreshLeftChallengeTime(time)
	self.viewData.leftChallengeLabel:setString(string.format(__('今日剩余次数:%d'), time))
	if 0 == time then
		self.viewData.nextBtn:setEnabled(false)
		self.viewData.nextBtn:getLabel():setString(__('已挑战'))

		self.viewData.splitLine:setVisible(true)
		self.viewData.currentDamageTitleLabel:setVisible(true)
		self.viewData.currentDamageLabel:setVisible(true)
	else
		self.viewData.nextBtn:setEnabled(true)
		self.viewData.nextBtn:getLabel():setString(__('下一步'))

		self.viewData.splitLine:setVisible(false)
		self.viewData.currentDamageTitleLabel:setVisible(false)
		self.viewData.currentDamageLabel:setVisible(false)
	end
end
--[[
刷新队伍阵容界面
@params teamData table
--]]
function WorldBossScene:RefreshTeamMember(teamData)
	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		local cardHeadNode = self.viewData.teamCardHeadNodes[i]
		if nil ~= cardHeadNode then
			cardHeadNode:removeFromParent()
		end
	end
	self.viewData.teamCardHeadNodes = {}

	for i,v in ipairs(teamData) do
		local nodes = self.viewData.emptyCardNodes[i]

		if nil ~= v.id and 0 ~= checkint(v.id) then
			local c_id = checkint(v.id)
			local cardHeadNode = require('common.CardHeadNode').new({
				id = c_id,
				showBaseState = true,
				showActionState = false,
				showVigourState = false
			})
			local scale = (cardHeadNodeSize.width) / cardHeadNode:getContentSize().width
			cardHeadNode:setScale(scale)
			display.commonUIParams(cardHeadNode, {po = cc.p(
				nodes.emptyCardHeadBg:getPositionX(),
				nodes.emptyCardHeadBg:getPositionY()
			)})
			self:addChild(cardHeadNode, SceneZorder.UI + 1)

			self.viewData.teamCardHeadNodes[i] = cardHeadNode
		end
	end
end
--[[
根据关卡id刷新中间spine
@params questId
--]]
function WorldBossScene:RefreshBossSpine(questId)
	local size = self:getContentSize()

	if nil == self.viewData.bossBgSpineNode then
		local bgSpineNode = sp.SkeletonAnimation:create(
			'ui/worldboss/spine/wb_bg_spine.json',
			'ui/worldboss/spine/wb_bg_spine.atlas',
			1
		)
		bgSpineNode:update(0)
		bgSpineNode:setPosition(cc.p(
			size.width * 0.675,
			display.cy + 300
		))
		self:addChild(bgSpineNode, SceneZorder.BASE)
		self.viewData.bossBgSpineNode = bgSpineNode

		bgSpineNode:setAnimation(0, 'play2', true)

		local fgSpineNode = sp.SkeletonAnimation:create(
			'ui/worldboss/spine/guangyun.json',
			'ui/worldboss/spine/guangyun.atlas',
			1
		)
		fgSpineNode:update(0)
		fgSpineNode:setPosition(cc.p(
			bgSpineNode:getPositionX(),
			bgSpineNode:getPositionY()
		))
		self:addChild(fgSpineNode, SceneZorder.BASE + 1)
		self.viewData.bossFgSpineNode = fgSpineNode

		fgSpineNode:setAnimation(0, 'play2', true)
	end

	local questConfig = CommonUtils.GetQuestConf(questId)
	if nil ~= questConfig then
		if nil ~= self.viewData.bossSpineNode then
			self.viewData.bossSpineNode:removeFromParent()
			self.viewData.bossSpineNode = nil
		end

		local monsterId = checkint(questConfig.showMonster[1])
		local spineNode = AssetsUtils.GetCardSpineNode({confId = monsterId})
		spineNode:update(0)
		spineNode:setScaleX(-1 * spineNode:getScaleX())

		local viewBox = spineNode:getBorderBox('viewBox')

		spineNode:setPosition(cc.p(
			size.width * 0.675,
			size.height * 0.5 - viewBox.height * 0.5 - viewBox.y
		))
		self:addChild(spineNode, SceneZorder.BASE)
		self.viewData.bossSpineNode = spineNode

		spineNode:setAnimation(0, 'idle', true)

		-- 修正一次spine火位置
		if nil ~= self.viewData.bossBgSpineNode then
			self.viewData.bossBgSpineNode:setPosition(cc.p(
				spineNode:getPositionX(),
				spineNode:getPositionY()
			))
		end
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
选卡按钮回调
--]]
function WorldBossScene:EditTeamMemberClickHandler(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('WB_SHOW_EDIT_TEAM_MEMBER')
end
--[[
下一步按钮回调
--]]
function WorldBossScene:NextBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('WB_SHOW_READY_ENTER_BATTLE')
end
--[[
boss详情按钮回调
--]]
function WorldBossScene:BossDetailBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('WB_SHOW_BOSS_DETAIL')
end
--[[
奖励语言按钮回调
--]]
function WorldBossScene:RewardReviewBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('WB_SHOW_REWARD_REVIEW')
end
--[[
排行榜按钮回调
--]]
function WorldBossScene:RankBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('WB_SHOW_RANK')
end
--[[
手册按钮回调
--]]
function WorldBossScene:ManualBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('WB_SHOW_MANUAL')
end
--[[
返回按钮回调
--]]
function WorldBossScene:BackBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'WorldBossMediator'}, {name = 'WorldMediator'})
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据剩余秒数获取格式化后的时间文字
@params second
--]]
function WorldBossScene:GetFormattedTimeStr(second)
	local str = ''
	local h = math.floor(second / 3600)
	local m = math.floor((second - h * 3600) / 60)
	local s = second - h * 3600 - m * 60
	str = string.format('%02d:%02d:%02d', h, m, s)
	return str
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return WorldBossScene
