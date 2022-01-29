--[[
宝箱领奖界面
@params table {
	chestType int 宝箱类型，1：大堂宝箱，2：任务宝箱，3：满星奖励宝箱
	rewards table 宝箱奖励
}
--]]
local ChestPopup = class('ChestPopup', function ()
	local clb = CLayout:create(cc.size(display.width,display.height))
    clb.name = 'common.ChestPopup'
    clb:enableNodeEvents()
    return clb
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")

function ChestPopup:ctor( ... )
	self.args = unpack({...})
	self.rewards = self.args.rewards
	self.closeCallback = self.args.closeCallback
	self.chestType = tostring(self.args.chestType) -- 1：大堂宝箱，2：任务宝箱，3：满星奖励宝箱
	local bg = CColorView:create(cc.c4b(0, 0, 0, 100))
	bg:setTouchEnabled(true)
    bg:setContentSize(display.size)
    bg:setPosition(cc.p(display.cx, display.cy))
    self:addChild(bg, -1)
	local chest = sp.SkeletonAnimation:create(
		'effects/dabaoxiang/box_' .. self.chestType .. '.json',
		'effects/dabaoxiang/box_' .. self.chestType ..'.atlas',
		1)
	chest:update(0)
	chest:setToSetupPose()
	chest:setAnimation(0, 'idle', false)
	chest:setPosition(cc.p(display.cx, display.cy))
	chest:registerSpineEventHandler(handler(self, self.spineEventEndHandler), sp.EventType.ANIMATION_END)
 	bg:addChild(chest)
end

---
function ChestPopup:spineEventEndHandler( event )
	self:performWithDelay(
        function ()
           	uiMgr:AddDialog('common.RewardPopup', {rewards = self.rewards,addBackpack = false, closeCallback = self.closeCallback , tag = self.args.tag})
			self:setOpacity(0) 
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2),cc.RemoveSelf:create())) 
        end,
        (1 * cc.Director:getInstance():getAnimationInterval())
    )
end
return ChestPopup
