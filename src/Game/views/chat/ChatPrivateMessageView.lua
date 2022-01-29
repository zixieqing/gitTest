local ChatPrivateMessageView = class('ChatPrivateMessageView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.chat.ChatPrivateMessageView'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local socketMgr = AppFacade.GetInstance('AppFacade'):GetManager('ChatSocketManager')
function ChatPrivateMessageView:ctor( ... )
	local datas = checktable(unpack({...}))
	local playerId = datas.playerId
	local playerName = datas.playerName
	local function CreateView()
		local size = cc.size(508,display.size.height)
		self:setContentSize(size)
		local view = CLayout:create(size)

		local bg = display.newImageView(_res('ui/common/common_bg_4.png'), 0, 0,
			{scale9 = true, size = size, enable = true})
		display.commonUIParams(bg, {ap = cc.p(0, 0), po = cc.p(0, 0)})
		view:addChild(bg)
		--聊天list
		local listSize = cc.size(size.width - 6, size.height - 85)
 		local chatListView = CListView:create(listSize)
 		chatListView:setDirection(eScrollViewDirectionVertical)
 		chatListView:setBounceable(false)
 		chatListView:setAnchorPoint(cc.p(0.5, 1))
 		chatListView:setPosition(cc.p(size.width/2, size.height - 5))
 		view:addChild(chatListView, 10)
    	-- 输入框
 		local chatInputView = require( 'Game.views.chat.ChatInputView' ).new({inputType = CHAT_CHANNELS.CHANNEL_PRIVATE, playerId = playerId, playerName = playerName})
 		display.commonUIParams(chatInputView, {po = cc.p(size.width * 0.5, 40)})
 		view:addChild(chatInputView, 10)
		return {
			view          = view,
			chatInputView = chatInputView,
			chatListView  = chatListView
		}
	end
    xTry(function()
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
        display.commonUIParams(self.viewData_.view, {ap = cc.p(0, 0), po = cc.p(0, 0)})
    end, __G__TRACKBACK__)
end

return ChatPrivateMessageView
