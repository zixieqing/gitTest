--[[
 * author : kaishiqi
 * descpt : 吸入特效Node
]]
local AbsorbEffectNode = class('AbsorbEffectNode', function()
	local node = cc.Node:create()
	node.name  = 'AbsorbEffectNode'
	return node
end)


function AbsorbEffectNode:ctor(args)
	local args      = checktable(args)
    self.texPath_   = tostring(args.path)
    self.buildNum_  = checkint(args.num)
    self.initRange_ = checkint(args.range)
    self.beginPos_  = args.beginPos or cc.p(0,0)
    self.endedPos_  = args.endedPos or cc.p(display.width, display.height)
    self.initScale_ = args.scale or 1 -- optional

    --
	self.buildedCount_ = 0
    self.destoryCount_ = 0
    self:createParticle_()
end


-------------------------------------------------
-- private method

function AbsorbEffectNode:createImg_()
	return display.newImageView(self.texPath_)
end


function AbsorbEffectNode:createParticle_()
    local particleActList = {}
    for i = 1, self.buildNum_ do
        -- create particle
        local particle = self:createImg_()
        particle:setPosition(self.beginPos_)
        particle:setScale(0)
        particle:setOpacity(0)
        self:addChild(particle)

        -- action particle
        local showTime  = math.random(100, 200) / 1000
        local delayTime = math.random(100, 200) / 1000
        local moveTime  = math.random(400, 600) / 1000
        local showPosX  = self.beginPos_.x + math.random(-self.initRange_, self.initRange_)
        local showPosY  = self.beginPos_.y + math.random(-self.initRange_, self.initRange_)
        table.insert(particleActList, cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(particle, cc.FadeIn:create(showTime)),
                cc.TargetedAction:create(particle, cc.ScaleTo:create(showTime, self.initScale_)),
                cc.TargetedAction:create(particle, cc.MoveTo:create(showTime, cc.p(showPosX, showPosY)))
            }),
            cc.DelayTime:create(delayTime),
            cc.TargetedAction:create(particle, cc.MoveTo:create(moveTime, self.endedPos_)),
            cc.TargetedAction:create(particle, cc.RemoveSelf:create()),
        }))
    end
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(particleActList),
        cc.RemoveSelf:create()
    ))
end


return AbsorbEffectNode
