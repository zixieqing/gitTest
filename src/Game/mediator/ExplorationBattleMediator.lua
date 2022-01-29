--[[
探索功能探索页面Mediator
--]]
local Mediator = mvc.Mediator

local ExplorationBattleMediator = class("ExplorationBattleMediator", Mediator)

local NAME = "ExplorationBattleMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local scheduler = require('cocos.framework.scheduler')
local STATUS = {
	explore    = 1, -- 探索中
	drawReward = 2, -- 领取奖励
	drawEnd    = 3, -- 领奖结束
	lastFloor  = 4, -- 底层
	Boss       = 5, -- boss出现
}
-- 背景移动速度
local BG_MOVE_SPEED = {
	8,
	4,
	3,
	2,
	4
}
-- 对话类型
local DIALOGUE_TYPE = {
	ExploreEnd     = 1,
	FindChest      = 2,
	EnterNextFloor = 3,
	BattleVictory  = 4,
	BattleFailed   = 5,
	BossAppeared   = 6,
	OpenChest      = 7,
}
-- 退出类型
local EXIT_TYPE = {
	END = 1,
	MIDDLE = 2
}
function ExplorationBattleMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.exploreDatas = params.exploreDatas
	self.cardSpine = {} -- 卡牌spine
	self.monsterSpine = {} -- 怪物spine
	self.chestSpine = {} -- 宝箱spine
	self.bossCost = 20 -- boss挑战花费
	self.exitType = nil -- 探索退出类型
end

function ExplorationBattleMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Exploration_DrawBaseReward_Callback,
		SIGNALNAMES.Exploration_DrawChestReward_Callback,
		SIGNALNAMES.Exploration_ExitExplore_Callback,
		SIGNALNAMES.Exploration_BuyBossFightNum_Callback,
		"CHANGE_PLAYER_SKILL",
		SIGNALNAMES.Quest_SwitchPlayerSkill_Callback
	}
	return signals
end

function ExplorationBattleMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if name == SIGNALNAMES.Exploration_DrawBaseReward_Callback then -- 基础奖励
		local datas = checktable(signal:GetBody())
		if next(datas.baseReward) ~= nil and checkint(datas.baseReward[1].num) ~= 0 then
			uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(datas.baseReward), msg = __('本次探索中获得了以下物品：')})
		end
		self.exploreDatas.currentFloorInfo.baseDrawn = 1
		self:UpdateRewardStatus()
		-- if not self.exploreDatas.currentFloorInfo.isBossQuest then
		-- 	self:UpdateRewardUi()
		-- end
		if not self.exploreDatas.currentFloorInfo.isBossQuest then -- 非boss关卡
			-- 添加宝箱
			self:AddChestReward()
			self:UpdateRewardUi()
		else -- boss关卡
			if self.exploreDatas.currentFloorInfo.fightStatus == 0 then -- 未战斗
				self:UpdateButtonStatus(STATUS.Boss)
			elseif self.exploreDatas.currentFloorInfo.fightStatus == 1 then -- 战斗胜利
				-- 添加宝箱
				self:AddChestReward()
				self:UpdateRewardUi()
			end
		end
	elseif name == SIGNALNAMES.Exploration_DrawChestReward_Callback then -- 宝箱奖励
		local datas = checktable(signal:GetBody())
		-- 更新宝箱状态
		self.exploreDatas.currentFloorInfo.chestReward[tostring(datas.requestData.chestKey)].hasDrawn = 1
		-- 领取奖励
		local roomData = CommonUtils.GetConfig('explore', 'exploreFloorRoom', self.exploreDatas.currentFloorInfo.roomId)
		datas.rewards.requestData = {}
		if datas.requestData.chestKey == 1 then
			datas.rewards.requestData.goodsId = roomData.chestRewards[1].goodsId
		elseif datas.requestData.chestKey == 2 then
			datas.rewards.requestData.goodsId = roomData.bossChestReward[1].goodsId
		else
			datas.rewards.requestData.goodsId = 190001
		end
		PlayAudioClip(AUDIOS.UI.ui_explore_treasure.id)
		uiMgr:AddDialog('common.RewardPopup', checktable(datas))
		self:UpdateRewardStatus()
		self:UpdateRewardUi()

	elseif name == SIGNALNAMES.Exploration_ExitExplore_Callback then -- 退出探索
		local datas = checktable(signal:GetBody())
		-- 更新本地定时器数据
		app.badgeMgr:ClearExploreAreaTimeAndRed(datas.requestData.areaFixedPointId)
		-- 判断退出探索类型
		if self.exitType == EXIT_TYPE.MIDDLE then
			local num = nil
			for k,v in pairs(datas.exploreRecord) do
				if num == nil then
					num = checkint(k)
				else
					if checkint(k) > checkint(num) then
						num = checkint(k)
					end
				end
			end
			datas.exploreRecord[tostring(num)] = nil
		end
		self:AddSettlementView(datas)
		if self.exploreDatas.explore.teamId then
			gameMgr:setMutualTakeAwayToTeam( self.exploreDatas.explore.teamId , CARDPLACE.PLACE_EXPLORATION,CARDPLACE.PLACE_TEAM)
		end
		if self.countdownScheduler then
			scheduler.unscheduleGlobal(self.countdownScheduler)
		end
		local explorationMediator = AppFacade.GetInstance():RetrieveMediator('ExplorationMediator')
		explorationMediator:SendSignal(COMMANDS.COMMAND_Exploration_Home)
	elseif name == SIGNALNAMES.Exploration_BuyBossFightNum_Callback then -- 购买战斗次数
		local datas = checktable(signal:GetBody())
		self.exploreDatas.currentFloorInfo.fightNum = datas.fightNum
		gameMgr:GetUserInfo().diamond = datas.diamond
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = datas.diamond})
		self:InitBattle()
	elseif "CHANGE_PLAYER_SKILL" == name then
		local datas = checktable(signal:GetBody())
		self.changePlayerSkillCallback = datas.responseCallback
		AppFacade.GetInstance():GetManager("HttpManager"):Post('quest/switchPlayerSkill', SIGNALNAMES.Quest_SwitchPlayerSkill_Callback, datas.requestData)
	elseif SIGNALNAMES.Quest_SwitchPlayerSkill_Callback == name then
		local datas = checktable(signal:GetBody())
		if self.changePlayerSkillCallback then
			self.changePlayerSkillCallback(datas)
		end
	end
end


function ExplorationBattleMediator:Initial( key )
	self.super.Initial(self,key)
	local roomData = CommonUtils.GetConfig('explore', 'exploreFloorRoom', self.exploreDatas.currentFloorInfo.roomId)
	local viewComponent  = require( 'Game.views.ExplorationBattleView' ).new({photo = roomData.photo})
	viewComponent:setTag(999)
	self:SetViewComponent(viewComponent)
	self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1/60)
	self.collisionScheduler = scheduler.scheduleGlobal(handler(self, self.CollisionDetection), 1/60)
	self.monsterScheduler = scheduler.scheduleGlobal(handler(self, self.MonsterScheduleCallback), 2)
end
--[[
更新UI
--]]
function ExplorationBattleMediator:UpdateUi()
	-- dump(self.exploreDatas)
	if self.exploreDatas.currentFloorInfo.needTime == 0 then -- 探索完成
		self:AddHeroSpine()
		self:ReachTheFinish()
	else -- 正在探索
		self:AddHeroSpine()
		self:UpdateButtonStatus(STATUS.explore)
	end

end
--[[
添加卡牌spine
--]]
function ExplorationBattleMediator:AddHeroSpine()
	local view = self:GetViewComponent().viewData_.view
	local teamCards = {}
	for _,v in orderedPairs(clone(self.exploreDatas.explore.teamCards)) do
		if v ~= '' then
			table.insert(teamCards, v)
		end
	end
	for i,card in ipairs(teamCards) do
		local cardData = gameMgr:GetCardDataById(card)
		local hero = AssetsUtils.GetCardSpineNode({skinId = cardData.defaultSkinId})
		hero:update(0)
		hero:setToSetupPose()
		hero:setPosition(cc.p(17+150*i + display.SAFE_L, view:getContentSize().height*0.4))
		hero:setAnimation(0, 'run', true)
		view:addChild(hero, 10- i)
		hero:setScale(0.55)
		table.insert(self.cardSpine, hero)
	end
end
--[[
抵达终点
--]]
function ExplorationBattleMediator:ReachTheFinish()
	-- 关闭定时器
	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
	end
	if self.collisionScheduler then
		scheduler.unscheduleGlobal(self.collisionScheduler)
	end
	if self.monsterScheduler then
		scheduler.unscheduleGlobal(self.monsterScheduler)
	end
	local view = self:GetViewComponent().viewData_.view
	-- 切换spine动作
	for _,spine in ipairs(self.cardSpine) do
		spine:setAnimation(0, 'idle', true)
	end
	-- 领取基本奖励
	if checkint(self.exploreDatas.currentFloorInfo.baseDrawn) == 0 then
		self:DrawBaseReward()
		return
	end
	if not self.exploreDatas.currentFloorInfo.isBossQuest then -- 非boss关卡
		-- 添加宝箱
		self:AddChestReward()
		self:UpdateRewardUi()
	else -- boss关卡
		if self.exploreDatas.currentFloorInfo.fightStatus == 0 then -- 未战斗
			self:UpdateButtonStatus(STATUS.Boss)
		elseif self.exploreDatas.currentFloorInfo.fightStatus == 1 then -- 战斗胜利
			-- 添加宝箱
			self:AddChestReward()
			self:UpdateRewardUi()
		end
	end
end
--[[
更新领奖Ui
--]]
function ExplorationBattleMediator:UpdateRewardUi()
	-- 奖励是全部领取
	if self.exploreDatas.currentFloorInfo.hasDrawn == 0 then -- 未领取
		self:UpdateButtonStatus(STATUS.drawReward)
	elseif self.exploreDatas.currentFloorInfo.hasDrawn == 1 then -- 已领取
		if checkint(self.exploreDatas.currentFloorInfo.isFinalLevel) == 0 then -- 非最后一层
			self:UpdateButtonStatus(STATUS.drawEnd)
		elseif checkint(self.exploreDatas.currentFloorInfo.isFinalLevel) == 1 then -- 最后一层
			self:UpdateButtonStatus(STATUS.lastFloor)
		end
	end
end
--[[
更新领奖状态
--]]
function ExplorationBattleMediator:UpdateRewardStatus()
	-- dump(self.exploreDatas)
	if not self.exploreDatas.currentFloorInfo.chestReward or next(self.exploreDatas.currentFloorInfo.chestReward) == nil then
		self.exploreDatas.currentFloorInfo.hasDrawn = 1
	else
		for k,v in orderedPairs(self.exploreDatas.currentFloorInfo.chestReward) do
			if v.hasDrawn == 0 then
				break
			end
			if tonumber(k) == table.nums(self.exploreDatas.currentFloorInfo.chestReward)-1 then
				self.exploreDatas.currentFloorInfo.hasDrawn = 1
			end
		end
	end
end
--[[
底部按钮回调
--]]
function ExplorationBattleMediator:ButtonCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == 6001 then -- 撤退
		if self.exploreDatas.currentFloorInfo.hasDrawn and checkint(self.exploreDatas.currentFloorInfo.hasDrawn)  == 0  then --未领取奖励的时候 谈提
			local scene = uiMgr:GetCurrentScene()
			local CommonTip  = require( 'common.NewCommonTip' ).new({
					text = __('确定要退出吗？'), extra = __('tips:探索的新鲜度已经被扣除，现在退出将不能获取任何奖励。'), isOnlyOK = false, callback = function ()
					if not self.exploreDatas.currentFloorInfo.isBossQuest and self.exploreDatas.currentFloorInfo.needTime <= 0  and self.exploreDatas.currentFloorInfo.hasDrawn == 0 then
						uiMgr:ShowInformationTips(__('已完成探索 ,请领取奖励'))
						return
					end
					if self.exploreDatas.currentFloorInfo.needTime <= 0 then
						self.exitType = EXIT_TYPE.END
					else
						self.exitType = EXIT_TYPE.MIDDLE
					end
					self:SendSignal(COMMANDS.COMMAND_Exploration_ExitExplore, {areaFixedPointId = self.exploreDatas.explore.areaFixedPointId})
				end})
			CommonTip:setPosition(display.center)
			scene:AddDialog(CommonTip)
		elseif  checkint(self.exploreDatas.currentFloorInfo.hasDrawn)  == 1  then
			if self.exploreDatas.currentFloorInfo.needTime <= 0 then
				self.exitType = EXIT_TYPE.END
			else
				self.exitType = EXIT_TYPE.MIDDLE
			end

			local scene = uiMgr:GetCurrentScene()
			local CommonTip  = require( 'common.NewCommonTip' ).new({
					text = __('确定要退出探索吗？'), isOnlyOK = false, callback = function ()
					self:SendSignal(COMMANDS.COMMAND_Exploration_ExitExplore, {areaFixedPointId = self.exploreDatas.explore.areaFixedPointId})
				end})
			CommonTip:setPosition(display.center)
			scene:AddDialog(CommonTip)
		end
	elseif tag == 6002 then -- 继续探索
		local explorationMediator = AppFacade.GetInstance():RetrieveMediator('ExplorationMediator')
		explorationMediator:SendSignal(COMMANDS.COMMAND_Exploration_EnterNextFloor, {areaFixedPointId = self.exploreDatas.explore.areaFixedPointId})
	elseif tag == 6003 then -- boss详情

	elseif tag == 6004 then -- 挑战
		self:InitBattle()
	elseif tag == 6005 then -- 再次挑战
		if gameMgr:GetUserInfo().diamond < self.bossCost then
			if GAME_MODULE_OPEN.NEW_STORE then
				app.uiMgr:showDiamonTips()
			else
				local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
					isOnlyOK = false, callback = function ()
						app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
					end})
				CommonTip:setPosition(display.center)
				app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
			end
		else
			local scene = uiMgr:GetCurrentScene()
			local strs = string.split(string.fmt(__('是否消耗|_num_|幻晶石继续挑战？'),{['_num_'] = self.bossCost}), '|')
 			local CommonTip  = require( 'common.NewCommonTip' ).new({richtext = {
 				{text = strs[1], fontSize = 22, color = '#4c4c4c'},
 				{text = strs[2], fontSize = 24, color = '#da3c3c'},
 				-- {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.2},
 				{text = strs[3], fontSize = 22, color = '#4c4c4c'}},
 				isOnlyOK = false, callback = function ()
    		print('确定')
    		self:SendSignal(COMMANDS.COMMAND_Exploration_BuyBossFightNum, {areaFixedPointId = self.exploreDatas.explore.areaFixedPointId, num = 1})
			end,
			cancelBack = function ()
			print('返回')
			end})
			CommonTip:setPosition(display.center)
			scene:AddDialog(CommonTip)
		end
	end
end
--[[
添加怪物
--]]
function ExplorationBattleMediator:AddMonsterSpine()
	local view = self:GetViewComponent().viewData_.view
	local roomData = CommonUtils.GetConfig('explore', 'exploreFloorRoom', self.exploreDatas.currentFloorInfo.roomId)
	local carouselMonsterId = checktable(roomData.carouselMonsterId)
	if next(carouselMonsterId) ~= nil then
		local monsterId = carouselMonsterId[math.random(#carouselMonsterId)]
		local monster = AssetsUtils.GetCardSpineNode({confId = monsterId})
		monster:update(0)
		monster:setToSetupPose()
		monster:setPosition(cc.p(display.width+200, view:getContentSize().height*0.4))
		monster:setAnimation(0, 'run', true)
		view:addChild(monster, 10)
		monster:setScale(0.55)
		monster:setScaleX(-0.55)
		table.insert(self.monsterSpine, monster)
		monster:runAction(cc.MoveBy:create(5, cc.p(-display.width-200, 0)))
	end
end
--[[
怪物生成定时器回调
--]]
function ExplorationBattleMediator:MonsterScheduleCallback()
	if self.exploreDatas.currentFloorInfo.needTime > 10 then
		self:AddMonsterSpine()
	end
end
--[[
背景定时器回调
--]]
function ExplorationBattleMediator:scheduleCallback()
	local viewData = self:GetViewComponent().viewData_
	if viewData then
		for i, layer in ipairs(viewData.bgTable) do
			for _,bg in ipairs(layer) do
				if bg:getPositionX() - BG_MOVE_SPEED[i] <= -viewData.bgSize.width then
					bg:setPositionX(bg:getPositionX() - BG_MOVE_SPEED[i] + 2*viewData.bgSize.width)
				else
					bg:setPositionX(bg:getPositionX() - BG_MOVE_SPEED[i])
				end
			end
		end
	end
end
--[[
碰撞检测
--]]
function ExplorationBattleMediator:CollisionDetection()
	for i,v in ipairs(self.monsterSpine) do
		local viewData = self:GetViewComponent().viewData_
		if cc.rectIntersectsRect( self.cardSpine[#self.cardSpine]:getBoundingBox(), v:getBoundingBox() ) then
			table.remove(self.monsterSpine, i)
			self:RemoveMonster(v, math.random(5))
		end
	end
end
--[[
倒计时
--]]
function ExplorationBattleMediator:CountdownCallback()
	if self.exploreDatas.currentFloorInfo.needTime > 0 then
		self.exploreDatas.currentFloorInfo.needTime = self.exploreDatas.currentFloorInfo.needTime - 1
		local view = self:GetViewComponent().viewData_.view
		if view:getChildByTag(5555) then
			local layout = view:getChildByTag(5555)
			if layout:getChildByTag(5600) then
				layout:getChildByTag(5600):setString(self:ChangeTimeFormat(self.exploreDatas.currentFloorInfo.needTime))
			end
		end
		if self.exploreDatas.currentFloorInfo.needTime == 0 then
			self:ReachTheFinish()
			scheduler.unscheduleGlobal(self.countdownScheduler)
		end
	end
end
function ExplorationBattleMediator:ChangeTimeFormat( remainSeconds )
	local hour   = math.floor(remainSeconds / 3600)
	local minute = math.floor((remainSeconds - hour*3600) / 60)
	local sec    = (remainSeconds - hour*3600 - minute*60)
	return string.format("%.2d:%.2d:%.2d", hour, minute, sec)
end
--[[
移除怪物
@params monster userdata 怪物spine
type int 动画类型
--]]
function ExplorationBattleMediator:RemoveMonster( monster, type )
	monster:stopAllActions()
	local action = nil
	if type == 1 then
		action = cc.Sequence:create(
			cc.Spawn:create(
				cc.MoveBy:create(1, cc.p(700, 700)),
				cc.RotateBy:create(1, 1800)
			),
			cc.RemoveSelf:create()
		)
	elseif type == 2 then
		action = cc.Sequence:create(
			cc.Spawn:create(
				cc.MoveBy:create(0.3, cc.p(200, 400)),
				cc.RotateBy:create(0.3, 540)
			),
			cc.Spawn:create(
				cc.MoveBy:create(0.7, cc.p(700, -700)),
				cc.RotateBy:create(0.7, 1360)
			),
			cc.RemoveSelf:create()
		)
	elseif type == 3 then
		action = cc.Sequence:create(
			cc.Spawn:create(
				cc.MoveBy:create(0.3, cc.p(200, 400)),
				cc.RotateBy:create(0.3, 720)
			),
			cc.Spawn:create(
				cc.MoveBy:create(0.7, cc.p(200, -300)),
				cc.RotateBy:create(0.7, 900)
			),
			cc.RemoveSelf:create()
		)
	elseif type == 4 then
		action = cc.Sequence:create(
			cc.Spawn:create(
				cc.MoveBy:create(0.8, cc.p(200, 400)),
				cc.RotateBy:create(0.8, 720),
				cc.ScaleTo:create(0.8, 0),
				cc.FadeOut:create(0.8)
			),
			cc.RemoveSelf:create()
		)
	elseif type == 5 then
		action = cc.Sequence:create(
			cc.Spawn:create(
				cc.MoveBy:create(0.6, cc.p(300, 30)),
				cc.RotateBy:create(0.6, 650),
				cc.ScaleTo:create(0.6, 3),
				cc.FadeOut:create(0.6)
			),
			cc.RemoveSelf:create()
		)
	end
	monster:runAction(action)

end
--[[
领取基础奖励
--]]
function ExplorationBattleMediator:DrawBaseReward()
	self:SendSignal(COMMANDS.COMMAND_Exploration_DrawBaseReward, {areaFixedPointId = self.exploreDatas.explore.areaFixedPointId})
end
--[[
添加宝箱
--]]
function ExplorationBattleMediator:AddChestReward()
	local view = self:GetViewComponent().viewData_.view
	for i,v in orderedPairs(self.exploreDatas.currentFloorInfo.chestReward) do
		local posX = display.width - 527 - display.SAFE_L + 170*checkint(i)
		if table.nums(self.exploreDatas.currentFloorInfo.chestReward) == 1 then
			posX = display.width - 527 - display.SAFE_L
		end

		if v.hasDrawn == 0 then -- 未领取
			local size = cc.size(150, 150)
			local prizeBtn = display.newButton(posX, view:getContentSize().height*0.45, {tag = 4000+i, size = size})
			view:addChild(prizeBtn, 15)
			prizeBtn:setOnClickScriptHandler(handler(self, self.DrawChestReward))
			local openIco = display.newImageView(_res('ui/common/discovery_ico_open.png'), size.width/2, 160)
			prizeBtn:addChild(openIco)
			local chestData = CommonUtils.GetConfig('goods', 'chest', v.reward.goodsId)
			local chest =  sp.SkeletonAnimation:create(
				'effects/xiaobaoxiang/box_'.. tostring(chestData.chestActId) .. '.json',
				'effects/xiaobaoxiang/box_'.. tostring(chestData.chestActId) .. '.atlas',
				1)
			chest:update(0)
			chest:setToSetupPose()
			chest:setPosition(cc.p(size.width/2, size.height/2))
			prizeBtn:addChild(chest, 10)
			chest:setScale(1.5)
			table.insert(self.chestSpine, chest)
			chest:setAnimation(0, 'idle', true)
			local moveBy = cc.MoveBy:create(0.5, cc.p(0, -5))
			openIco:runAction(
				cc.RepeatForever:create(
					cc.Sequence:create(
						moveBy,
						moveBy:reverse()
					)
				)
			)
			local openLabel = display.newLabel(size.width/2, 200, fontWithColor(20, {text = __('点击打开'), fontSize = 28, outline = '#734441'}))
			prizeBtn:addChild(openLabel)
		else -- 已领取
		end
	end
end
--[[
宝箱领奖
--]]
function ExplorationBattleMediator:DrawChestReward( sender )
	sender:setEnabled(false)
	sender:runAction(cc.FadeOut:create(1))
	local key = sender:getTag() - 4000
	self:SendSignal(COMMANDS.COMMAND_Exploration_DrawChestReward, {areaFixedPointId = self.exploreDatas.explore.areaFixedPointId, chestKey = key})

	local currentTeamId = checkint(self.exploreDatas.explore.teamId)
	local teamCardsInfo = gameMgr:getTeamCardsInfo(currentTeamId > 0 and currentTeamId or 1)
	for i,v in ipairs(teamCardsInfo) do
		local cardUuid = checkint(v.id)
		if cardUuid > 0 then
			local cardData = gameMgr:GetCardDataById(cardUuid)
			CommonUtils.PlayCardSoundByCardId(cardData.cardId, SoundType.TYPE_UPGRADE_STAR, SoundChannel.EXPLORATION_REWARD)
			break
		end
	end
end
--[[
更新按钮状态
--]]
function ExplorationBattleMediator:UpdateButtonStatus( status )
	local view = self:GetViewComponent().viewData_.view
	if view:getChildByTag(5555) then
		view:getChildByTag(5555):runAction(cc.RemoveSelf:create())
	end
	local layout = CLayout:create(display.size)
	layout:setPosition(cc.p(display.cx, display.cy))
	layout:setTag(5555)
	layout:setPosition(cc.p(view:getContentSize().width/2, view:getContentSize().height/2))
	view:addChild(layout, 20)
	--[[
	添加角色对话
	@params dialogueType int 对话类型
	--]]
	local function AddHeroDialogue(dialogueType)
		local dialogueBg = display.newImageView(_res('ui/home/exploration/dialogue_bg_6.png'), 60 + #self.cardSpine*150 + display.SAFE_L, display.cy + 200)
		layout:addChild(dialogueBg, 15)
		local dialogueDatas = CommonUtils.GetConfigAllMess('exploreLang', 'explore')
		local descrDatas = {}
		for _,v in pairs(dialogueDatas) do
			if checkint(v.triggerType) == dialogueType then
				table.insert(descrDatas, v.descr)
			end
		end
		local dialogueLabel = display.newLabel(dialogueBg:getContentSize().width/2, dialogueBg:getContentSize().height/2, fontWithColor(6, {ap = cc.p(0.5, 0.5), w = 290, text = descrDatas[math.random(#descrDatas)]}))
		dialogueBg:addChild(dialogueLabel)
	end

	if status == STATUS.explore then -- 探索中
		self.countdownScheduler = scheduler.scheduleGlobal(handler(self, self.CountdownCallback), 1)
		-- 如果时间小于五分钟，则增加3秒
		if self.exploreDatas.currentFloorInfo.needTime <= 300 then
			self.exploreDatas.currentFloorInfo.needTime = self.exploreDatas.currentFloorInfo.needTime + 3
		end
		local timeNum = cc.Label:createWithBMFont('font/battle_ico_time_1.fnt', self:ChangeTimeFormat(self.exploreDatas.currentFloorInfo.needTime))
		timeNum:setTag(5600)
		timeNum:setAnchorPoint(cc.p(0.5, 0.5))
		timeNum:setHorizontalAlignment(display.TAR)
		timeNum:setPosition(display.cx, display.height - 100)
		layout:addChild(timeNum, 10)
		timeNum:setScale(1)
		local bottomBg = display.newImageView(_res('ui/common/discovery_ready_dg_2.png'), display.width + 100, 50, {ap = cc.p(1, 0)})
		layout:addChild(bottomBg, 5)
		local retreatBtn = display.newButton(display.width - 140, 120, {tag = 6001, n = _res('ui/common/common_btn_orange.png')})
		layout:addChild(retreatBtn, 10)
		retreatBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
		display.commonLabelParams(retreatBtn, fontWithColor(14, {text = __('撤回')}))
	elseif status == STATUS.drawReward then -- 领奖
		AddHeroDialogue(DIALOGUE_TYPE.FindChest)
	elseif status == STATUS.drawEnd then -- 领奖结束
		local bottomBg = display.newImageView(_res('ui/common/discovery_ready_dg_2.png'), display.width, 50, {ap = cc.p(1, 0)})
		layout:addChild(bottomBg, 5)
		local retreatBtn = display.newButton(display.width - 270, 120, {tag = 6001, n = _res('ui/common/common_btn_orange.png')})
		layout:addChild(retreatBtn, 10)
		retreatBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
		display.commonLabelParams(retreatBtn, fontWithColor(14, {text = __('撤退')}))
		local continueBtn = display.newButton(display.width - 100, 120, {tag = 6002, n = _res('ui/common/common_btn_orange.png')})
		layout:addChild(continueBtn, 10)
		display.commonLabelParams(continueBtn, fontWithColor(14, {text = __('继续前进') ,w = 130 , reqH = 45, hAlign =display.TAC  }))
		continueBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
		AddHeroDialogue(DIALOGUE_TYPE.EnterNextFloor)
	elseif status == STATUS.lastFloor then -- 最后一层
		local bottomBg = display.newImageView(_res('ui/common/discovery_ready_dg_2.png'), display.width + 100, 50, {ap = cc.p(1, 0)})
		layout:addChild(bottomBg, 5)
		local retreatBtn = display.newButton(display.width - 140, 120, {tag = 6001, n = _res('ui/common/common_btn_orange.png')})
		layout:addChild(retreatBtn, 10)
		retreatBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
		display.commonLabelParams(retreatBtn, fontWithColor(14, {text = __('撤回')}))
		AddHeroDialogue(DIALOGUE_TYPE.ExploreEnd)
	elseif status == STATUS.Boss then -- boss战
		local bossId = self.exploreDatas.currentFloorInfo.bossId
		-- local drawId = CommonUtils.GetConfig('monster', 'monster', bossId).drawId
		local boss = AssetsUtils.GetCardSpineNode({confId = bossId})
		boss:update(0)
		boss:setToSetupPose()
		boss:setPosition(cc.p(display.width - 300 - display.SAFE_L, display.height/2 - 100))
		boss:setAnimation(0, 'idle', true)
		boss:setScale(0.55)
		boss:setScaleX(-0.55)
		layout:addChild(boss, 10)
		-- boss详情按钮
		-- local bossDescr = display.newButton(display.width - 250, display.height - 100, {tag = 6003, n = _res('ui/common/common_btn_orange.png')})
		-- layout:addChild(bossDescr, 10)
		-- bossDescr:setOnClickScriptHandler(handler(self, self.ButtonCallback))
		-- display.commonLabelParams(bossDescr, fontWithColor(16, {text = 'BOSS', offset = cc.p(0, 15)}))
		-- local bossDescrLabel = display.newLabel(bossDescr:getContentSize().width/2, bossDescr:getContentSize().height/2 - 10, {text = __('详情'), fontSize = 18, color = '#5b3c25'})
		-- bossDescr:addChild(bossDescrLabel)
		local retreatBtn = display.newButton(display.width - 100 - display.SAFE_L, display.height - 100, {tag = 6001, n = _res('ui/common/common_btn_orange.png')})
		layout:addChild(retreatBtn, 10)
		display.commonLabelParams(retreatBtn, fontWithColor(14, {tag = 6001, text = __('撤离')}))
		retreatBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
		local retreatBg = display.newImageView(_res('ui/common/discovery_bg_fight.png'), display.width + 60 - display.SAFE_L, 0, {ap = cc.p(1, 0)})
		layout:addChild(retreatBg, 5)
		-- 天气
		local weatherBg = display.newImageView(_res('ui/home/exploration/discovery_bg_weather.png'), 460 + display.SAFE_L, 0, {ap = cc.p(0.5, 0)})
		layout:addChild(weatherBg, 5)
		local weatherLabel = display.newLabel(370 + display.SAFE_L, 0, {ap = cc.p(0.5, 0), text = __('天气'), fontSize = 22, color = '#ffffff'})
		layout:addChild(weatherLabel, 10)
		local questData = CommonUtils.GetConfig('explore', 'exploreQuest', self.exploreDatas.currentFloorInfo.bossQuestId)
		for i,v in ipairs(questData.weatherId) do
			local weatherConf = CommonUtils.GetConfig('quest', 'weather', v)
			local weatherBg = display.newImageView(_res('ui/home/exploration/discovery_ico_weather.png'), 482 + display.SAFE_L + (i-1)*80, 48)
			layout:addChild(weatherBg, 10)
			local weatherIcon = display.newImageView(_res('ui/common/fight_ico_weather_' .. weatherConf.weatherProperty .. '.png'), weatherBg:getContentSize().width/2, weatherBg:getContentSize().height/2)
			weatherIcon:setScale(0.47)
			weatherBg:addChild(weatherIcon)
		end
		local challengeBtn = display.newButton(display.width - 95 - display.SAFE_L, 110, {tag = 6004, n = _res('ui/common/common_btn_explore.png')})
		layout:addChild(challengeBtn, 10)
		challengeBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
		display.commonLabelParams(challengeBtn, fontWithColor(14, {text = __('挑战')}))
		-- 判断挑战次数是否足够
		if checkint(self.exploreDatas.currentFloorInfo.fightNum) <= 0 then
			local diamondCostLabel = display.newRichLabel(display.width - 95, 20,
				{ap = cc.p(0.5, 0.5), r = true, c = {
					{text = tostring(self.bossCost), fontSize = 26, color = '#ffffff'},
					{img = _res('arts/goods/goods_icon_' .. DIAMOND_ID .. '.png'), scale = 0.2},
				}
			})
			layout:addChild(diamondCostLabel, 10)
			AddHeroDialogue(DIALOGUE_TYPE.BattleFailed)
			challengeBtn:setTag(6005)
		else
			AddHeroDialogue(DIALOGUE_TYPE.BossAppeared)
		end
		-- 主角技
		local skillBg = display.newImageView(_res('ui/common/discovery_bg_talent.png'), -60 + display.SAFE_L, 0, {ap = cc.p(0, 0)})
		layout:addChild(skillBg, 5)
		dump(gameMgr:GetUserInfo().skill)
		for i=1, 2 do
			local playerskillBg = display.newImageView(_res('ui/battle/battle_bg_skill_default.png'), 83+(i-1)*145 + display.SAFE_L, 145+(i-1)*-57)
			layout:addChild(playerskillBg, 5)
			local playerSkillFrame = display.newButton(83+(i-1)*145+display.SAFE_L, 145+(i-1)*-57, {n = _res('ui/map/team_lead_skill_frame_replace.png'), tag = i})
			layout:addChild(playerSkillFrame, 10)
			local frame = display.newImageView(_res('ui/battle/team_lead_skill_frame_l.png'), playerSkillFrame:getContentSize().width/2, playerSkillFrame:getContentSize().height/2)
			playerSkillFrame:addChild(frame, 10)
			if checkint(gameMgr:GetUserInfo().skill[i]) ~= 0 then
				local icon = require('common.PlayerSkillNode').new({id = gameMgr:GetUserInfo().skill[i]})
				icon:setTag(555)
				display.commonUIParams(icon, {po = utils.getLocalCenter(playerSkillFrame)})
				playerSkillFrame:addChild(icon, 5)
			else
				local icon = display.newImageView(_res('ui/common/maps_fight_btn_pet_add.png'), playerSkillFrame:getContentSize().width/2, playerSkillFrame:getContentSize().height/2, {tag = 555})
				playerSkillFrame:addChild(icon, 5)
			end
			playerSkillFrame:setOnClickScriptHandler(handler(self, self.ChangePlayerSkillCallback))
		end

	end
end
--[[
换技能按钮回调
--]]
function ExplorationBattleMediator:ChangePlayerSkillCallback(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local equipedPlayerSkills = {}
	for i,v in ipairs(gameMgr:GetUserInfo().skill) do
		equipedPlayerSkills[tostring(i)] = {skillId = checkint(v)}
	end
	local allSkills = self:convertPlayerSkillData(gameMgr:GetUserInfo().allSkill)
	self:ShowSelectPlayerSkillPopup({
		allSkills = allSkills.activeSkill,
		equipedPlayerSkills = equipedPlayerSkills,
		slotIndex = tag,
		changeEndCallback = function (responseData)
			-- 刷新本地主角技数据
			gameMgr:UpdatePlayer({skill = responseData.skill})
			for i,v in ipairs(responseData.skill) do
				local layout = self:GetViewComponent().viewData_.view:getChildByTag(5555)
				local playerSkillFrame = layout:getChildByTag(i)
				if playerSkillFrame:getChildByTag(555) then
					playerSkillFrame:getChildByTag(555):runAction(cc.RemoveSelf:create())
				end
				if gameMgr:GetUserInfo().skill[i] ~= '0' then
					local icon = require('common.PlayerSkillNode').new({id = gameMgr:GetUserInfo().skill[i]})
					icon:setTag(555)
					display.commonUIParams(icon, {po = utils.getLocalCenter(playerSkillFrame)})
					playerSkillFrame:addChild(icon, 5)
				else
					local icon = display.newImageView(_res('ui/common/maps_fight_btn_pet_add.png'), playerSkillFrame:getContentSize().width/2, playerSkillFrame:getContentSize().height/2, {tag = 555})
					playerSkillFrame:addChild(icon, 5)
				end
			end
		end
	})
end
--[[
显示更换主角技弹窗
@parmas data table 参数
--]]
function ExplorationBattleMediator:ShowSelectPlayerSkillPopup(data)
	data = data or {}
	local tag = 4002
	data.tag = tag
	local layer = require('Game.views.SelectPlayerSkillPopup').new(data)
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
转换激活的主角技数据结构
@params allSkill 所有激活的主角技数据
@return result table 转换后的数据结构
--]]
function ExplorationBattleMediator:convertPlayerSkillData(allSkill)
	local skillId = 0
	local skillConf = nil
	local result = {
		activeSkill = {},
		passiveSkill = {}
	}

	for i,v in ipairs(allSkill) do
		skillId = checkint(v)
		skillConf = CommonUtils.GetSkillConf(skillId)
		local skillInfo = {skillId = skillId}
		if ConfigSkillType.SKILL_HALO == checkint(skillConf.property) then
			-- 被动技能
			table.insert(result.passiveSkill, skillInfo)
		else
			-- 主动技能
			table.insert(result.activeSkill, skillInfo)
		end
	end

	return result
end
--[[
添加结算页面
--]]
function ExplorationBattleMediator:AddSettlementView( rewards )
	local layer = require('Game.views.ExplorationSettlementView').new({rewards = rewards, teamId = self.exploreDatas.explore.teamId, areaFixedPointId = self.exploreDatas.explore.areaFixedPointId})
	layer:setTag(7000)
	local scene = uiMgr:GetCurrentScene()
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	scene:AddDialog(layer)
	layer.viewData_.closeBtn:setOnClickScriptHandler(function ()
		-- 添加点击音效
		PlayAudioByClickClose()
		scene:RemoveDialogByTag(7000)
		-- local explorationMediator = AppFacade.GetInstance():RetrieveMediator('ExplorationMediator')
		-- explorationMediator:SendSignal(COMMANDS.COMMAND_Exploration_Home)
	end)
end
--[[
初始化战斗
--]]
function ExplorationBattleMediator:InitBattle()

	-- 初始化网络命令
	local serverCommand = BattleNetworkCommandStruct.New(
		POST.EXPLORATION_QUEST_AT.cmdName,
		{areaFixedPointId = self.exploreDatas.explore.areaFixedPointId},
		POST.EXPLORATION_QUEST_AT.sglName,
		POST.EXPLORATION_QUEST_GRADE.cmdName,
		{areaFixedPointId = self.exploreDatas.explore.areaFixedPointId},
		POST.EXPLORATION_QUEST_GRADE.sglName,
		nil,
		nil,
		nil
	)

	-- 初始化来回信息
	local fromToStruct = BattleMediatorsConnectStruct.New(
		'ExplorationMediator',
		'HomeMediator'
	)

	local battleConstructor = require('battleEntry.BattleConstructor').new()

	-- 判断是否可以进入战斗
	-- local canBattle, waringText = battleConstructor:CanEnterBattle(self.selectedTeamIdx)
	-- if not canBattle then
	-- 	if nil ~= waringText then
	-- 		uiMgr:ShowInformationTips(waringText)
	-- 	end
	-- 	return
	-- end

	-- 初始化构造器数据
	battleConstructor:InitByNormalStageIdAndTeamId(
		checkint(self.exploreDatas.currentFloorInfo.bossQuestId),
		checkint(self.exploreDatas.explore.teamId),
		serverCommand,
		fromToStruct
	)

	-- 初始化管理器
	self.enterBattleMediator = AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator')
	if not self.enterBattleMediator then
		self.enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
		AppFacade.GetInstance():RegistMediator(self.enterBattleMediator)
	end
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)

end
function ExplorationBattleMediator:EnterLayer()
	self:UpdateUi()
end
function ExplorationBattleMediator:OnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	local ExplorationBattleCommand = require('Game.command.ExplorationBattleCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_DrawBaseReward, ExplorationBattleCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_DrawChestReward, ExplorationBattleCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_ExitExplore, ExplorationBattleCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Exploration_BuyBossFightNum, ExplorationBattleCommand)
	self:EnterLayer()
end
function ExplorationBattleMediator:AutoHiddenState(  )
	return false
end
function ExplorationBattleMediator:OnUnRegist(  )
	print( "OnUnRegist" )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_DrawBaseReward)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_DrawChestReward)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_ExitExplore)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Exploration_BuyBossFightNum)
	if self.scheduler then
		scheduler.unscheduleGlobal(self.scheduler)
	end
	if self.collisionScheduler then
		scheduler.unscheduleGlobal(self.collisionScheduler)
	end
	if self.countdownScheduler then
		scheduler.unscheduleGlobal(self.countdownScheduler)
	end
	if self.monsterScheduler then
		scheduler.unscheduleGlobal(self.monsterScheduler)
	end
end
return ExplorationBattleMediator
