local ChatPrivateItemView = class('ChatPrivateItemView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.chat.ChatPrivateItemView'
	node:enableNodeEvents()
	return node
end)

local labelparser = require("Game.labelparser")

local socketMgr = AppFacade.GetInstance():GetManager('ChatSocketManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
function ChatPrivateItemView:ctor( ... )
	local datas = unpack({...})
	local chatDatas = checktable(datas.chatDatas)
	local playerDatas = checktable(datas.playerDatas)
	self.chatDatas = chatDatas
	local idx = datas.index or 1
	self.viewData = nil
	local size = cc.size(498, 104)
	self:setContentSize(size)
	local function CreateView()
		local view = CLayout:create(size)
		-- 背景
		local bg = display.newButton(size.width/2, size.height - 10, {tag = checkint(idx), ap = cc.p(0.5, 1), n = _res('ui/home/chatSystem/dialogue_bg_friends_chat.png'), useS = false})
		bg:setUserTag(checkint(chatDatas.playerId))
		bg:setName(chatDatas.name)
		view:addChild(bg)
		-- 头像
		local friendType = nil
		if CommonUtils.GetIsFriendById(playerDatas.friendId) then
			friendType = HeadPopupType.FRIEND
		else
			friendType = HeadPopupType.STRANGER
		end
		local headImg = require('common.FriendHeadNode').new({
            enable = true, scale = 0.56, avatar = playerDatas.avatar, avatarFrame = playerDatas.avatarFrame, showLevel = true, level = playerDatas.level, callback = function ( sender )
				uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = checkint(playerDatas.friendId), type = friendType})
            end
        })
        headImg:setPosition(cc.p(78, 45))
        view:addChild(headImg, 10)
        -- 名称
        local nameLabel = display.newLabel(124, 70, {ap = cc.p(0, 0.5), fontSize = 22, color = '#d36c44', text = chatDatas.name})
        view:addChild(nameLabel, 10)
        -- 时间
        local timeLabel = display.newLabel(130 + display.getLabelContentSize(nameLabel).width, 68, {ap = cc.p(0, 0.5), fontSize = 20, color = '#a19b85', text = os.date(" %H:%M", chatDatas.sendTime + getLoginClientTime() - getLoginServerTime())})
        view:addChild(timeLabel, 10)


        if checkint(chatDatas.messagetype) == CHAT_MSG_TYPE.SOUND then
			local voiceIcon = display.newImageView(_res('ui/home/chatSystem/dialogue_ico_voice.png'), 138, 32)
			view:addChild(voiceIcon, 10)
			local voiceBg = display.newImageView(_res('ui/home/chatSystem/dialogue_bg_voice.png'), 160, 32, {ap = cc.p(0, 0.5)})
			view:addChild(voiceBg, 5)
			local time = display.newLabel(185, 32, {text = '14’', fontSize = 22, color = 'ffffff'})
			view:addChild(time, 10)
        else
			-- 消息
			local messageLabel = self:CreateMessageLabel(chatDatas)
			display.commonUIParams(messageLabel, {po = cc.p(124, 56)})
			view:addChild(messageLabel, 10)
        end
        local remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), 110, 80)
        view:addChild(remindIcon, 10)
        if checkint(ChatUtils.GetNewMessageByPlayerId(checkint(playerDatas.friendId)).hasNewMessage) == 1 then
			remindIcon:setVisible(true)
        else
			remindIcon:setVisible(false)
        end
		return {
			view 	   = view,
			bg  	   = bg,
			remindIcon = remindIcon
		}
	end

	self.viewData = CreateView()
	display.commonUIParams(self.viewData.view,{po = cc.p(size.width * 0.5, size.height * 0.5)})
	self:addChild(self.viewData.view)

end

--[[
获取最新聊天信息
--]]
function ChatPrivateItemView:CreateMessageLabel( chatDatas )
	local messageType = chatDatas.messagetype or CHAT_MSG_TYPE.TEXT
	local messageLabel = nil
	if checkint(messageType) ~= 2 then
		-- local text1 = "<guild id=12 32 >【hello,world】</guild><desc>发布了招募信息，寻找志同道合的御侍，共同守护世界，抗击堕神！</desc><look>【点击查看】</look>"
		local parsedtable = labelparser.parse(chatDatas.message)
		local tempTab = {}
		--过滤非法标签
		for i,v in ipairs(parsedtable) do
			if FILTERS[v.labelname] then
				table.insert(tempTab,v)
			end
		end
		local str = ''
		local color = '883e3e'
		for i,v in ipairs(tempTab) do
			if v.labelname == 'desc' then
                str = nativeSensitiveWords( v.content)
                if FILTER_COLORS[v.labelname] then
                    color = FILTER_COLORS[v.labelname]
                end
                break
			end
		end

        messageLabel = display.newLabel(0, 0,
            {w = 340,ap = cc.p(0, 1), maxL = 2, text = str, color = color, fontSize = 22}
        )
	else
		messageLabel = display.newLabel(0, 0,
			{w = 340,ap = cc.p(0, 1), maxL = 2, text = '                                 ', fontSize = 22, color = '#883e3e'}
		)
	end
	return messageLabel
end
return ChatPrivateItemView
