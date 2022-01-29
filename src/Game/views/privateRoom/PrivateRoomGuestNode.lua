--[[
包厢 顾客node
--]]
local PrivateRoomGuestNode = class('PrivateRoomGuestNode', function()
    local node = CLayout:create()
    node:enableNodeEvents()
    node:setAnchorPoint(cc.p(0.5, 0))
    node.name = 'PrivateRoomGuestNode'
    return node
end)

local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local cardMgr = shareFacade:GetManager("CardManager")
local DEFAULT_WIDTH = 1334
local SPEED = 250
local D_WIDTH = (display.width - DEFAULT_WIDTH) / 2

local SPINE_ANIMATION = {
    IDLE = 'idle',
    IDLE_TWO = 'idle2',
    SIT  = 'idle3',
    RUN  = 'run', 
    EAT  = 'eat',
}
--[[
@params guestId int 顾客id
@params sitPos int 座位位置
@params isMainGuest bool 是否是主要客人
@params callback function 点击回调
@params defaultPosY int 主要客人y轴初始位置
--]]
function PrivateRoomGuestNode:ctor(...)
    local args = unpack({...})
    self.guestId = args.guestId -- 顾客id
    self.sitPos = args.sitPos or cc.p(0, 0) -- 座位pos
    self.isMainGuest = args.isMainGuest -- 是否为主要顾客
    self.callback = args.callback
    self.defaultPos = {
        FIRST = cc.p(DEFAULT_WIDTH + D_WIDTH  + 200, args.defaultPosY),
        SECOND = cc.p(DEFAULT_WIDTH + D_WIDTH + 200, 400)
    }
    self:Init()
    self:SetDefaultPos()
    self:SetSpineAnimation(SPINE_ANIMATION.RUN)
end
function PrivateRoomGuestNode:Init()
    local size = cc.size(200, 250)
    self:setContentSize(size)
    local touchNode = CColorView:create(cc.c4b(100,100,100,0))
    touchNode:setContentSize(size)
    touchNode:setPosition(utils.getLocalCenter(self))
    self:addChild(touchNode)
    touchNode:setTouchEnabled(false)
    self.touchView = touchNode
	self.touchView:setOnClickScriptHandler(function(sender)
		if self.callback then
			self.callback(self:GetGuestId())
		end
	end)
    -- spine
	local pathPrefix = string.format("avatar/visitors/%s", self.guestId)
	self.spine = sp.SkeletonAnimation:create(string.format("%s.json", pathPrefix),string.format('%s.atlas', pathPrefix), 0.7)
    self.spine:setToSetupPose()
    self.spine:setPosition(cc.p(size.width / 2, 0))
    self:addChild(self.spine, 3)
end  
--[[
获取guestId
--]]
function PrivateRoomGuestNode:GetGuestId()
	return self.guestId
end
--[[
设置spine动作
@params animation SPINE_ANIMATION spine动作
--]]
function PrivateRoomGuestNode:SetSpineAnimation( animation )
    if not animation then return end
    self.spine:setToSetupPose()
    self.spine:setAnimation(0, animation, true)
end
--[[
设为默认位置
--]]
function PrivateRoomGuestNode:SetDefaultPos( )
    self.spine:setScaleX(-1)
    self:SetSpineAnimation(SPINE_ANIMATION.IDLE)
    if self.isMainGuest then 
        self:setPosition(self.defaultPos.FIRST)
    else
        self:setPosition(self.defaultPos.SECOND)
    end
end
--[[
设为座位
--]]
function PrivateRoomGuestNode:SetSitPos()
    self:SetSpineAnimation(SPINE_ANIMATION.IDLE)
    self:setPosition(self.sitPos)
    if self.isMainGuest then 
        self.spine:setScaleX(-1)
    else
        self.spine:setScaleX(1)
    end 
end
--[[
移动至默认位置
--]]
function PrivateRoomGuestNode:MoveToDefaultPos()
    self.spine:setScaleX(1)
    self:SetSpineAnimation(SPINE_ANIMATION.RUN)
    local act = nil 
    if self.isMainGuest then
        local defaultPos = self.defaultPos.FIRST
        local sitPos = self.sitPos
        act = cc.Sequence:create(
            cc.MoveTo:create((sitPos.y - defaultPos.y) / SPEED, cc.p(sitPos.x, defaultPos.y)),
            cc.MoveTo:create((defaultPos.x - sitPos.x) / SPEED, defaultPos),
            cc.CallFunc:create(function ()
                AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_LEAVE_ACT_END, {guestId = self:GetGuestId()})
            end)
        )
    else
        local defaultPos = self.defaultPos.SECOND
        local sitPos = self.sitPos
        act = cc.Sequence:create(
            cc.MoveTo:create((defaultPos.y - sitPos.y) / SPEED, cc.p(sitPos.x, defaultPos.y)),
            cc.CallFunc:create(function ()
                self.spine:setScaleX(1)
                self:setLocalZOrder(1)
            end),
            cc.MoveTo:create((defaultPos.x - sitPos.x) / SPEED, defaultPos),
            cc.CallFunc:create(function ()
                AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_LEAVE_ACT_END, {guestId = self:GetGuestId()})
            end)
        )
    end
    self:runAction(act)
end
--[[
移动至座位
--]]
function PrivateRoomGuestNode:MoveToSitPos()
    self.spine:setScaleX(-1)
    self:SetSpineAnimation(SPINE_ANIMATION.RUN)
    local act = nil 
    if self.isMainGuest then
        local defaultPos = self.defaultPos.FIRST
        local sitPos = self.sitPos
        act = cc.Sequence:create(
            cc.MoveTo:create((defaultPos.x - sitPos.x) / SPEED, cc.p(sitPos.x, defaultPos.y)),
            cc.MoveTo:create((sitPos.y - defaultPos.y) / SPEED, sitPos),
            cc.CallFunc:create(function ()
                self:SetSpineAnimation(SPINE_ANIMATION.IDLE)
                AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_ARRIVAL_ACT_END, {guestId = self:GetGuestId()})
            end)
        )
    else
        local defaultPos = self.defaultPos.SECOND
        local sitPos = self.sitPos
        self:setLocalZOrder(1)
        act = cc.Sequence:create(
            cc.MoveTo:create((defaultPos.x - sitPos.x) / SPEED, cc.p(sitPos.x, defaultPos.y)),
            cc.CallFunc:create(function ()
                self.spine:setScaleX(1)
                self:setLocalZOrder(10)
            end),
            cc.MoveTo:create((defaultPos.y - sitPos.y) / SPEED, sitPos),
            cc.CallFunc:create(function ()
                self:SetSpineAnimation(SPINE_ANIMATION.IDLE)
                AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_ARRIVAL_ACT_END, {guestId = self:GetGuestId()})
            end)
        )
    end
    self:runAction(act)
end
--[[
拒单离开
--]]
function PrivateRoomGuestNode:LeavePrivateRoom()
    self:ShowExpression(3)
    self:MoveToDefaultPos()
end
--[[
--显示表情节点的逻辑
--@id 表情节点的id
--]]
function PrivateRoomGuestNode:ShowExpression(id)
        if self:getChildByName('EXPRESSION_TAG_NAME') then
            self:removeChildByName('EXPRESSION_TAG_NAME')
        end
        local prefix = string.format('avatar/animate/common_ico_expression_%d',checkint(id))
        local animateNode = sp.SkeletonAnimation:create(string.format("%s.json", prefix),string.format("%s.atlas",prefix), 0.8)
        animateNode:setAnimation(0, 'idle', true)
        animateNode:setName('EXPRESSION_TAG_NAME')
        animateNode:setPosition(10, 200)
        self:addChild(animateNode,10)
end
return PrivateRoomGuestNode