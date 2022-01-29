--[[
通用分享按钮
@params table {
	clickCallback function 按钮回调
}
--]]
local CommonShareButton = class('CommonShareButton', function ()
	local node = CButton:create()
	node.name = 'common.CommonShareButton'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
contrustor
--]]
function CommonShareButton:ctor( ... )
	local args = unpack({...}) or {}

	self.clickCallback = args.clickCallback
	self.rewardRemindNode = nil

	self:InitUI()

	display.commonUIParams(self, {cb = function (sender)
		if nil ~= self.clickCallback then
			xTry(function ()
				self.clickCallback(sender)
			end, __G__TRACKBACK__)
		end
	end})

    AppFacade.GetInstance():RegistObserver('SHARE_REQUEST_RESPONSE', mvc.Observer.new(function(stage, signal)
        --分享成功后的事件响应,使幻晶石消失的逻辑
        self:ShowRewardRemind(checkint(gameMgr:GetUserInfo().shareData.shareNum) < 1)
    end, self))
end
---------------------------------------------------
-- logic init begin --
---------------------------------------------------
--[[
初始化样式
--]]
function CommonShareButton:InitUI()
	------------ 按钮底板 ------------
	self:setNormalImage('ui/common/common_btn_blue_default.png')
	------------ 按钮底板 ------------

	-- 按钮文字
	local shareLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('分享')}))
	display.commonUIParams(shareLabel, {po = utils.getLocalCenter(self)})
	self:addChild(shareLabel)

	self:ShowRewardRemind(checkint(gameMgr:GetUserInfo().shareData.shareNum) < 1)
end
--[[
增加奖励提示
@params show bool 是否显示奖励提示
--]]
function CommonShareButton:ShowRewardRemind(show)
	if nil == self.rewardRemindNode then
		local rewardBg = display.newImageView(_res('ui/common/share_bg_prize_icon.png'), 0, 0, {scale9 = true, size = cc.size(118, 28)})
		display.commonUIParams(rewardBg, {po = cc.p(
			utils.getLocalCenter(self).x,
			-rewardBg:getContentSize().height * 0.5
		)})
		rewardBg:setCascadeOpacityEnabled(true)
		self:addChild(rewardBg, -1)

		local shareRewards = checktable(gameMgr:GetUserInfo().shareData.rewards)
		local rewardInfo = {
			goodsId = checkint(checktable(shareRewards[1]).goodsId),
			amount  = checkint(checktable(shareRewards[1]).num)
		}

		local rewardLabel = display.newLabel(0, 0, fontWithColor('18', {text = string.format(__('奖励 %d'), rewardInfo.amount)}))
		rewardLabel:setCascadeOpacityEnabled(true)
		rewardBg:addChild(rewardLabel)

        local lwidth = display.getLabelContentSize(rewardLabel).width
        if lwidth < 118 then lwidth = 128 end
		local rewardIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(rewardInfo.goodsId)), 0, 0)
		rewardIcon:setScale(0.2)
		rewardBg:addChild(rewardIcon)

        rewardBg:setContentSize(cc.size(lwidth + 40, 28))
		display.setNodesToNodeOnCenter(rewardBg, {rewardLabel, rewardIcon})

		self.rewardRemindNode = rewardBg
	end

	self.rewardRemindNode:setVisible(show)
end
---------------------------------------------------
-- logic init end --
---------------------------------------------------

function CommonShareButton:onCleanup()
    --清除资源事件的情况
    AppFacade.GetInstance():UnRegistObserver('SHARE_REQUEST_RESPONSE', self)
end

return CommonShareButton
