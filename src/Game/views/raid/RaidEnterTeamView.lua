--[[
组队进入队伍界面
@params table {
	stageId int 关卡id
	gotRareReward int 是否获得了稀有奖励
	leftChallengeTimes int 剩余挑战次数
	teamId int 队伍id
	rlData table 队长信息 {
		playerId int 玩家id
		playerName string 玩家名
		playerLevel int 玩家等级
		playerAvatar string 玩家头像
		playerAvatarFrame string 玩家头像框
	}
}
--]]
local GameScene = require('Frame.GameScene')
local RaidEnterTeamView = class('RaidEnterTeamView', GameScene)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function RaidEnterTeamView:ctor( ... )
	local args = unpack({...})

	self.stageId = checkint(args.stageId)
	self.teamId = checkint(args.teamId)
	self.gotRareReward = checkint(args.gotRareReward)
	self.leftChallengeTimes = checkint(args.leftChallengeTimes)
	self.rlData = args.rlData

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function RaidEnterTeamView:InitUI()

	self:setBackgroundColor(cc.c4b(0, 0, 0, 255 * 0.75))

	local CreateView = function ()
		local size = self:getContentSize()
		-- 创建屏蔽按钮
		local eaterLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), size = size, enable = true, cb = function (sender)
			PlayAudioByClickClose()
			-- 关闭自己
			self:setVisible(false)
			uiMgr:GetCurrentScene():RemoveDialog(self)
		end})
		display.commonUIParams(eaterLayer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(self)})
		self:addChild(eaterLayer)

		-- local eaterBtn = display.newButton(0, 0, {size = size, animate = false, cb = function (sender)
		-- 	PlayAudioByClickClose()
		-- 	-- 关闭自己
		-- 	self:setVisible(false)
		-- 	uiMgr:GetCurrentScene():RemoveDialog(self)
		-- end})
		-- display.commonUIParams(eaterBtn, {po = utils.getLocalCenter(self)})
		-- self:addChild(eaterBtn)

		-- 创建关卡详情界面
		local raidStageDetailView = require('Game.views.raid.RaidStageDetailView').new({
			stageId = self.stageId,
			gotRareReward = self.gotRareReward,
			leftNormalDropTimes = self.leftChallengeTimes,
			enableDropWaring = true,
			enableBuyNormalDropTimes = true
		})
		display.commonUIParams(raidStageDetailView, {ap = cc.p(0.5, 0.5), po = cc.p(
			size.width * 0.4,
			size.height * 0.5
		)})
		self:addChild(raidStageDetailView, 10)

		-- 触摸屏蔽层
		local raidStageDetailView_ = display.newLayer(0, 0, {size = raidStageDetailView:getContentSize(), color = cc.c4b(0, 0, 0, 0), enable = true})
		display.commonUIParams(raidStageDetailView_, {ap = cc.p(0.5, 0.5), po = cc.p(
			raidStageDetailView:getPositionX(),
			raidStageDetailView:getPositionY()
		)})
		self:addChild(raidStageDetailView_, 9)

		-- 创建玩家信息界面
		local playerInfoBg = display.newImageView(_res('ui/raid/hall/raid_boss_bg_searchresult.png'), 0, 0, {enable = true, animate = false})
		display.commonUIParams(playerInfoBg, {po = cc.p(
			raidStageDetailView:getPositionX() + raidStageDetailView:getContentSize().width * 0.5 + playerInfoBg:getContentSize().width * 0.5,
			raidStageDetailView:getPositionY() - 74
		)})
		self:addChild(playerInfoBg, 10)

		local playerInfoLayer = display.newLayer(0, 0, {size = playerInfoBg:getContentSize()})
		display.commonUIParams(playerInfoLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
			playerInfoBg:getPositionX(),
			playerInfoBg:getPositionY()
		)})
		self:addChild(playerInfoLayer, 15)

		local playerHeadNodeScale = 0.8
		local playerHeadNode = require('common.PlayerHeadNode').new({
			playerId = checkint(self.rlData.playerId),
			avatar = self.rlData.playerAvatar,
			avatarFrame = self.rlData.playerAvatarFrame,
			showLevel = true,
			playerLevel = self.rlData.playerLevel,
			defaultCallback = true
		})
		playerHeadNode:setScale(playerHeadNodeScale)
		display.commonUIParams(playerHeadNode, {po = cc.p(
			utils.getLocalCenter(playerInfoLayer).x,
			playerInfoLayer:getContentSize().height - 25 - playerHeadNode:getContentSize().height * 0.5 * playerHeadNodeScale
		)})
		playerInfoLayer:addChild(playerHeadNode, 5)

		local rlMark = display.newNSprite(_res('ui/raid/room/raid_room_label_owner.png'), 0, 0)
		display.commonUIParams(rlMark, {po = cc.p(
			playerHeadNode:getPositionX() + playerHeadNode:getContentSize().width * 0.5 + rlMark:getContentSize().width * 0.5 - 15,
			playerHeadNode:getPositionY() + playerHeadNode:getContentSize().height * 0.5 - rlMark:getContentSize().height * 0.5 - 30
		)})
		playerInfoLayer:addChild(rlMark, 4)

		local playerNameLabel = display.newLabel(0, 0, fontWithColor('18', {text = tostring(self.rlData.playerName)}))
		display.commonUIParams(playerNameLabel, {po = cc.p(
			playerHeadNode:getPositionX(),
			playerHeadNode:getPositionY() - playerHeadNode:getContentSize().height * 0.5 * playerHeadNodeScale - 20
		)})
		playerInfoLayer:addChild(playerNameLabel, 5)

		local joinBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(joinBtn, {po = cc.p(
			playerHeadNode:getPositionX(),
			playerHeadNode:getPositionY() - playerHeadNode:getContentSize().height * 0.5 * playerHeadNodeScale - 40 - joinBtn:getContentSize().height * 0.5
		), cb = handler(self, self.JoinBtnClickHandler)})
		display.commonLabelParams(joinBtn, fontWithColor('14', {text = __('加入')}))
		playerInfoLayer:addChild(joinBtn, 5)

		return {

		}
	end

	xTry(function ()
		self.viewData = CreateView()
	end, __G__TRACKBACK__)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
加入队伍按钮回调
--]]
function RaidEnterTeamView:JoinBtnClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('RAID_JOIN_TEAM', {teamId = self.teamId, stageId = self.stageId})
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

return RaidEnterTeamView
