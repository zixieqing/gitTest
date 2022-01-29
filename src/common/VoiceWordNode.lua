--[[
--主界面上的人物的显示的tips
--]]
local VoiceWordNode = class('VoiceWordNode', function ()
	local node = CLayout:create()
	node.name = 'common.VoiceWordNode'
	node:enableNodeEvents()
    node:setName(node.name)
    -- node:setBackgroundColor(cc.c4b(100,100,100,100))
	return node
end)


function VoiceWordNode:ctor(...)
    local args = unpack({...})
    self.time  = math.floor(args.time)
    local cardId   = args.cardId
    local voiceId  = args.voiceId
    self.canRemove = true

    local descr = CommonUtils.GetCurrentCvLinesByVoiceId(cardId, voiceId)
    local fontSize = 24
    local borderW = 40
    local contentLabel = display.newLabel(0,0, fontWithColor(8, {color = 'ffffff', fontSize = fontSize,text = descr, w = 420}))
    local size = display.getLabelContentSize(contentLabel)
    size.height = math.max(80 + borderW, size.height + borderW)
    self:setContentSize(cc.size(size.width, size.height))
    display.commonUIParams(contentLabel, {ap = display.LEFT_TOP, po = cc.p(borderW, size.height - borderW / 2)})
    self:addChild(contentLabel, 2)

    local bgImageView = display.newImageView(_res('ui/home/nmain/main_bg_dialogue'), 0, 0, {
        scale9 = true, size = cc.size(size.width + borderW*2, size.height)
    })
    display.commonUIParams(bgImageView, {ap = display.LEFT_BOTTOM})
    self:addChild(bgImageView)
end


function VoiceWordNode:onEnter()
    --执行事件
    self:runAction(cc.Sequence:create(cc.DelayTime:create(self.time), cc.CallFunc:create(function()
        self.canRemove = false
    end), cc.RemoveSelf:create()))
end


return VoiceWordNode


