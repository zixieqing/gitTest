--[[
--聊天长按的输入状态的逻辑节点
--]]
local ChatAnimate = class('ChatAnimate', function ()
	local node = CLayout:create(cc.size(234,234))
	node.name = 'Game.views.chat.ChatAnimate'
	-- node:setBackgroundColor(cc.c4b(0,100,0,100))
	node:enableNodeEvents()
	return node
end)

function ChatAnimate:ctor(...)
    local size = cc.size(234,234)
    self:setContentSize(size)

    local bg = display.newImageView(_res('ui/home/chatSystem/chat_tips_bg'),size.width * 0.5, size.height * 0.5)
    self:addChild(bg)

    local descrLabel = display.newLabel(size.width * 0.5, size.height - 10, fontWithColor(5,{color = 'ffffff',fontSize = 24,ap = display.CENTER_TOP,
        text = __('手指滑开取消发送语音时间最长10秒'), w = 200,h = 66}))
    self:addChild(descrLabel)

    local animateNode = sp.SkeletonAnimation:create("ui/home/chatSystem/yu.json","ui/home/chatSystem/yu.atlas", 0.6)
    animateNode:setToSetupPose()
    animateNode:setAnimation(0, 'play', true)
    display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.5, 100)})
    self:addChild(animateNode,2)

    -- local stateImage =display.newNSprite(_res('ui/home/chatSystem/chat_ico_voice'),size.width * 0.5,58)
    -- display.commonUIParams(stateImage, {ap = display.CENTER_BOTTOM})
    -- self:addChild(stateImage,1)

    local recordLabel = display.newLabel(size.width * 0.5, 32, fontWithColor(5,{color = 'ffffff',fontSize = 26,ap = display.CENTER,
        text = __('录音中...')}))
    self:addChild(recordLabel)

end

return ChatAnimate

