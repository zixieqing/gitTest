--[[
组队战斗渲染管理器
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
local BattleRenderManager = __Require('battle.manager.BattleRenderManager')
local RaidBattleRenderManager = class('RaidBattleRenderManager', BattleRenderManager)

------------ import ------------
------------ import ------------

------------ define ------------
local GAME_RESULT_LAYER_TAG = 2321
local READY_LAYER_TAG = 3301
local READY_RESULT_LAYER_TAG = 3303
local BATTLE_SUCCESS_VIEW_TAG = 3302
------------ define ------------

--[[
construtor
--]]
function RaidBattleRenderManager:ctor( ... )
	BattleRenderManager.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数据
--]]
function RaidBattleRenderManager:InitValue()
	BattleRenderManager.InitValue(self)

	self.startRaidBattleCountdownLabel = nil
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------

---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- wait teammate begin --
---------------------------------------------------
--[[
初始化等待其他玩家的逻辑
@params countdown int 倒计时
--]]
function RaidBattleRenderManager:ShowWaitingOtherMember()
	local uiLayer = self:GetBattleScene().viewData.uiLayer

	local waitingBg = display.newImageView(_res('ui/battle/battle_bg_black.png'), display.width * 0.5, display.height * 0.5,
		{scale9 = true, size = cc.size(display.width, 144)})
	uiLayer:addChild(waitingBg)

	waitingBg:setTag(READY_LAYER_TAG)

	local waitingLabel = display.newLabel(0, 0,
		{text = __('等待其他玩家'), fontSize = 30, ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25'})
	display.commonUIParams(waitingLabel, {po = utils.getLocalCenter(waitingBg)})
	waitingBg:addChild(waitingLabel)
end
--[[
开始进行开始战斗的倒计时
@params countdown int 倒计时秒数
--]]
function RaidBattleRenderManager:BeginStartRaidBattleCountdown(countdown)
	if nil == self.startRaidBattleCountdownLabel then

		local uiLayer = self:GetBattleScene().viewData.uiLayer
		local parentNode = uiLayer:getChildByTag(READY_LAYER_TAG)

		if nil ~= parentNode then
			local label = CLabelBMFont:create(
				tostring(countdown),
				'font/battle_ico_time_1.fnt'
			)
			label:setBMFontSize(36)
			label:setAnchorPoint(cc.p(1, 0))
			label:setPosition(cc.p(
				parentNode:getContentSize().width - 20,
				10
			))
			parentNode:addChild(label)

			self.startRaidBattleCountdownLabel = label
		end

	end
end
--[[
移除准备提示 开始战斗
--]]
function RaidBattleRenderManager:RemoveReadyStateAtStart()
	-- 移除准备界面
	self.startRaidBattleCountdownLabel = nil
	self:GetBattleScene().viewData.uiLayer:removeChildByTag(READY_LAYER_TAG)
end
--[[
初始化战斗结束等待其他玩家的逻辑
--]]
function RaidBattleRenderManager:ShowWaitingOtherMemberOver()
	local uiLayer = self:GetBattleScene().viewData.uiLayer

	local waitingBg = display.newImageView(_res('ui/battle/battle_bg_black.png'), display.width * 0.5, display.height * 0.5,
		{scale9 = true, size = cc.size(display.width, 144)})
	uiLayer:addChild(waitingBg)

	waitingBg:setTag(READY_RESULT_LAYER_TAG)

	local waitingLabel = display.newLabel(0, 0,
		{text = __('正在与队友同步战斗结果...'), fontSize = 30, ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25'})
	display.commonUIParams(waitingLabel, {po = utils.getLocalCenter(waitingBg)})
	waitingBg:addChild(waitingLabel)
end
--[[
开始进行结束战斗的倒计时
@params countdown int 倒计时秒数
--]]
function RaidBattleRenderManager:BeginOverRaidBattleCountdown(countdown)
	if nil == self.overRaidBattleCountdownLabel then

		local uiLayer = self:GetBattleScene().viewData.uiLayer
		local parentNode = uiLayer:getChildByTag(READY_RESULT_LAYER_TAG)

		if nil ~= parentNode then
			local label = CLabelBMFont:create(
				tostring(self.startRaidBattleCountdown),
				'font/battle_ico_time_1.fnt')
			label:setBMFontSize(36)
			label:setAnchorPoint(cc.p(1, 0))
			label:setPosition(cc.p(
				parentNode:getContentSize().width - 20,
				10
			))
			parentNode:addChild(label)

			self.overRaidBattleCountdownLabel = label
		end

	end
end
--[[
移除准备提示 结束战斗
--]]
function RaidBattleRenderManager:RemoveReadyStateAtOver()
	-- 移除等待结算界面
	self.overRaidBattleCountdownLabel = nil
	self:GetBattleScene().viewData.uiLayer:removeChildByTag(READY_RESULT_LAYER_TAG)
end
---------------------------------------------------
-- wait teammate end --
---------------------------------------------------

---------------------------------------------------
-- battle result begin --
---------------------------------------------------
--[[
@override
显示战斗胜利界面
@params responseData table 服务器返回数据
@params playerRewardsData table 缓存的玩家奖励数据
@params canShowNormalRewards table 缓存的玩家显示普通奖励标识位
--]]
function RaidBattleRenderManager:ShowGameSuccess(responseData, playerRewardsData, canShowNormalRewards)
	self:CreateBattleSuccessView(responseData, playerRewardsData, canShowNormalRewards)
end
--[[
@override
创建战斗胜利界面
@params responseData table 服务器返回数据
@params playerRewardsData table 缓存的玩家奖励数据
@params canShowNormalRewards table 缓存的玩家显示普通奖励标识位
--]]
function RaidBattleRenderManager:CreateBattleSuccessView(responseData, playerRewardsData, canShowNormalRewards)
	local className = 'battle.view.RaidBattleSuccessView'
	local playersData = self:GetBattleConstructor():GetMemberData()

	local viewType = ConfigBattleResultType.RAID

	local layer = __Require(className).new({
		viewType = viewType,
		cleanCondition = nil,
		showMessage = false,
		canRepeatChallenge = false,
		teamData = self:GetBattleMembers(false, 1),
		trophyData = responseData,
		playersData = playersData,
		playerRewardsData = playerRewardsData,
		canShowNormalRewards = canShowNormalRewards
	})
	layer:setTag(BATTLE_SUCCESS_VIEW_TAG)

	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetBattleScene():AddUILayer(layer)
end
--[[
@override
显示战斗失败
@params responseData table 服务器返回数据
@params playerRewardsData table 缓存的玩家奖励数据
@params canShowNormalRewards table 缓存的玩家显示普通奖励标识位
--]]
function RaidBattleRenderManager:ShowGameFail(responseData, playerRewardsData, canShowNormalRewards)
	self:CreateBattleFailView(responseData, playerRewardsData, canShowNormalRewards)
end
--[[
@override
创建战斗失败界面
@params responseData table 服务器返回数据
@params playerRewardsData table 缓存的玩家奖励数据
@params canShowNormalRewards table 缓存的玩家显示普通奖励标识位
--]]
function RaidBattleRenderManager:CreateBattleFailView(responseData, playerRewardsData, canShowNormalRewards)
	local className = 'battle.view.RaidBattleFailView'

	-- 结算类型
	local viewType = ConfigBattleResultType.NO_EXP

	local layer = __Require(className).new({
		viewType = ConfigBattleResultType.NO_EXP,
		cleanCondition = nil,
		showMessage = false,
		canRepeatChallenge = false,
		teamData = self:GetBattleMembers(false, 1),
		trophyData = responseData
	})
	layer:setTag(GAME_RESULT_LAYER_TAG)

	display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	self:GetBattleScene():AddUILayer(layer)
end
---------------------------------------------------
-- battle result end --
---------------------------------------------------

---------------------------------------------------
-- countdown handler begin --
---------------------------------------------------
--[[
开局等待队友的update处理
@params dt number delta time
--]]
function RaidBattleRenderManager:RefreshStartRaidBattleCountdownLabel(countdown)
	if nil ~= self.startRaidBattleCountdownLabel then
		self.startRaidBattleCountdownLabel:setString(tostring(countdown))
	end
end
--[[
最后等待队友的update处理
@params dt number delta time
--]]
function RaidBattleRenderManager:RefreshOverRaidBattleCountdownLabel(countdown)
	if nil ~= self.overRaidBattleCountdownLabel then
		self.overRaidBattleCountdownLabel:setString(tostring(countdown))
	end
end
---------------------------------------------------
-- countdown handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取组队战斗结算界面
@return _ cc.node 结算界面
--]]
function RaidBattleRenderManager:GetRaidBattleSuccessView()
	if nil ~= self:GetBattleScene() then
		return self:GetBattleScene():GetUIByTag(BATTLE_SUCCESS_VIEW_TAG)
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- app background begin --
---------------------------------------------------
--[[
显示强制退出的对话框
--]]
function RaidBattleRenderManager:ShowForceQuitLayer()
	-- 组队本不处理
end
---------------------------------------------------
-- app background end --
---------------------------------------------------

return RaidBattleRenderManager
