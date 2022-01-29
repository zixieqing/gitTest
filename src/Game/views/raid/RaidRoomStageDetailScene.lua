--[[
房间内查看boss详情的界面
@params {
	stageId int 关卡id
	leftChallengeTimes int 剩余挑战次数
	bossRareReward table 稀有掉落信息
}
--]]
local GameScene = require('Frame.GameScene')
local RaidRoomStageDetailScene = class('RaidRoomStageDetailScene', GameScene)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function RaidRoomStageDetailScene:ctor( ... )
	local args = unpack({...})

	self.stageId = checkint(args.stageId)
	self.leftChallengeTimes = checkint(args.leftChallengeTimes)
	self.bossRareReward = checktable(args.bossRareReward)

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function RaidRoomStageDetailScene:InitUI()

	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.75))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 0.5))
	eaterLayer:setPosition(cc.p(display.cx, display.cy))
	self:addChild(eaterLayer)
	self.eaterLayer = eaterLayer

	local stageConfig = CommonUtils.GetQuestConf(self.stageId)
	local groupId = 0
	if nil ~= stageConfig then
		groupId = checkint(stageConfig.group)
	end

	local CreateView = function ()

		local size = self:getContentSize()

		-- back button
		local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52,
			{n = _res('ui/common/common_btn_back.png'), cb = handler(self, self.CloseSelfClickHandler)})
		self:addChild(backBtn)

		local raidStageDetailView = require('Game.views.raid.RaidStageDetailView').new({
			stageId = self.stageId,
			gotRareReward = checkint(self.bossRareReward[tostring(groupId)]),
			leftNormalDropTimes = self.leftChallengeTimes,
			enableDropWaring = true,
			enableBuyNormalDropTimes = true
		})
		display.commonUIParams(raidStageDetailView, {ap = cc.p(0.5, 0.5), po = cc.p(
			size.width * 0.5,
			size.height * 0.5
		)})
		self:addChild(raidStageDetailView)

		return {
			raidStageDetailView = raidStageDetailView
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
返回按钮回调
--]]
function RaidRoomStageDetailScene:CloseSelfClickHandler(sender)
	PlayAudioByClickNormal()
	self:CloseSelf()
end
--[[
关闭自己
--]]
function RaidRoomStageDetailScene:CloseSelf()
	uiMgr:GetCurrentScene():RemoveDialog(self)
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

return RaidRoomStageDetailScene
