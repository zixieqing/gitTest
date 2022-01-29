--[[
包厢 服务员node
--]]
local PrivateRoomWaiterNode = class('PrivateRoomWaiterNode', function()
    local node = CLayout:create()
    node:enableNodeEvents()
    node:setAnchorPoint(cc.p(0.5, 0))
    node.name = 'PrivateRoomWaiterNode'
    return node
end)

local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local cardMgr = shareFacade:GetManager("CardManager")
local DEFAULT_WIDTH = 1334
local SPEED = 400
local D_WIDTH = (display.width - DEFAULT_WIDTH) / 2
local SPINE_ANIMATION = {
    IDLE = 'idle',
    RUN  = 'run', 
}
function PrivateRoomWaiterNode:ctor(...)
    local args = unpack({...})
    self.cardSkinId = args.cardSkinId
    self.servePos = args.servePos or cc.p(0, 0)
    self.defaultPos = cc.p(250 - D_WIDTH + display.SAFE_L, 250)
    self.callback = args.callback
    self:Init()
    self:SetDefaultPos()
    self:SetSpineAnimation(SPINE_ANIMATION.IDLE)
end
function PrivateRoomWaiterNode:Init()
    local size = cc.size(200, 250)
    self:setContentSize(size)
    local touchNode = CColorView:create(cc.c4b(100,100,100,0))
    touchNode:setContentSize(size)
    touchNode:setPosition(utils.getLocalCenter(self))
    self:addChild(touchNode)
    touchNode:setTouchEnabled(true)
    self.touchView = touchNode
	self.touchView:setOnClickScriptHandler(function(sender)
		if self.callback then
			self.callback(self:GetCardSkinId())
		end
	end)
    -- spine
    self.spine = AssetsUtils.GetCardSpineNode({skinId = self:GetCardSkinId(), scale = 0.7})
    self.spine:setToSetupPose()
    self.spine:setPosition(cc.p(size.width / 2, 0))
    self:addChild(self.spine, 3)
end  
--[[
设置是否可以点击
--]]
function PrivateRoomWaiterNode:SetEnabled( enabled )
    self.touchView:setTouchEnabled(enabled)
end
--[[
获取spine卡牌数据库id
--]]
function PrivateRoomWaiterNode:GetCardSkinId()
	return self.cardSkinId
end
--[[
设置spine动作
@params animation SPINE_ANIMATION spine动作
--]]
function PrivateRoomWaiterNode:SetSpineAnimation( animation )
    if not animation then return end
    self.spine:setAnimation(0, animation, true)
end
--[[
设为默认位置
--]]
function PrivateRoomWaiterNode:SetDefaultPos( )
    self:setPosition(self.defaultPos)
end
--[[
设为服务位置
--]]
function PrivateRoomWaiterNode:SetServePos()
    self:setPosition(self.servePos)
end
--[[
移动至默认位置
--]]
function PrivateRoomWaiterNode:MoveToDefaultPos()
    self:setScaleX(-1)
    self:SetSpineAnimation(SPINE_ANIMATION.RUN)
    self:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(2, cc.p(self.defaultPos.x, self.servePos.y)),
            cc.MoveTo:create(0.5, self.defaultPos),
            cc.CallFunc:create(function ()
                self:setScaleX(1)
                self:SetSpineAnimation(SPINE_ANIMATION.IDLE)
            end)
        )
    )
end
--[[
移动至服务位置
--]]
function PrivateRoomWaiterNode:MoveToServePos()
    self:setScaleX(1)
    self:SetSpineAnimation(SPINE_ANIMATION.RUN)
    self:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.5, cc.p(self.defaultPos.x, self.servePos.y)),
            cc.MoveTo:create(2, self.servePos),
            cc.CallFunc:create(function ()
                self:SetSpineAnimation(SPINE_ANIMATION.IDLE)
            end)
        )
    )
end
--[[
上菜
--]]
function PrivateRoomWaiterNode:ServeTheDishAction()
    local servePos = self.servePos
    self:runAction(
        cc.Sequence:create(
            cc.CallFunc:create(function ()
                self:setScaleX(-1)
                self:SetSpineAnimation(SPINE_ANIMATION.RUN)
            end),
            cc.MoveTo:create((servePos.x + D_WIDTH + 100) / SPEED, cc.p(-D_WIDTH - 100, servePos.y)),
            cc.CallFunc:create(function ()
                self:setScaleX(1)
            end),
            cc.MoveTo:create((servePos.x + D_WIDTH + 100) / SPEED, servePos),
            cc.CallFunc:create(function ()
                self:SetSpineAnimation(SPINE_ANIMATION.IDLE)
                AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_SERVE_EVENT_END)
            end)
        )
    )
end
return PrivateRoomWaiterNode
