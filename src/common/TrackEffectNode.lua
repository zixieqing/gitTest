--[[
 * author : kaishiqi
 * descpt : 轨迹特效Node
]]
local TrackEffectNode = class('TrackEffectNode', function()
	local node = cc.Node:create()
	node.name  = 'TrackEffectNode'
	node:setCascadeOpacityEnabled(true)
	return node
end)


function TrackEffectNode:ctor(args)
	local args     = checktable(args)
	self.range_    = checkint(args.range)
	self.texPath_  = tostring(args.texPath)
	self.delay_    = checknumber(args.delay)
	self.lifespan_ = checknumber(args.lifespan)
	self.texScale_ = args.texScale and checknumber(args.texScale) or 1  -- optional

	self.mainTex_ = self:createTex_()
	self:addChild(self.mainTex_, 10)

	self.createDelay_ = 0
	self:scheduleUpdateWithPriorityLua(handler(self, self.createParticle_), 0)
end

-------------------------------------------------

function TrackEffectNode:getMainTex()
	return self.mainTex_
end


function TrackEffectNode:fadeOutOver(delay)
	self:unscheduleUpdate()
	self:runAction(cc.Sequence:create(
		cc.TargetedAction:create(self.mainTex_, cc.FadeOut:create(delay)),
		cc.TargetedAction:create(self.mainTex_, cc.RemoveSelf:create()),
		cc.CallFunc:create(function()
			self:scheduleUpdateWithPriorityLua(handler(self, self.checkRemoveParticle_), 0)
		end)
	))
end

-------------------------------------------------
-- private method

function TrackEffectNode:createTex_()
	return display.newImageView(self.texPath_, 0, 0, {scale = self.texScale_})
end


function TrackEffectNode:createParticle_(dt)
	self.createDelay_ = self.createDelay_ + dt
	if self.createDelay_ < self.delay_ then return end
	self.createDelay_ = self.createDelay_ - self.delay_

	local particle = self:createTex_()
	particle:setPosition(self.mainTex_:getPosition())
	self:addChild(particle)

	local endPosX = particle:getPositionX() + math.random(-self.range_, self.range_)
	local endPosY = particle:getPositionY() + math.random(-self.range_, self.range_)
	particle:runAction(cc.Sequence:create(
		cc.Spawn:create({
			cc.MoveTo:create(self.lifespan_, cc.p(endPosX, endPosY)),
			cc.FadeOut:create(self.lifespan_)
		}),
		cc.RemoveSelf:create(true)
	))
end


function TrackEffectNode:checkRemoveParticle_(dt)
	if self:getChildrenCount() == 0 then
		self:unscheduleUpdate()
		self:removeFromParent()
	end
end


return TrackEffectNode
