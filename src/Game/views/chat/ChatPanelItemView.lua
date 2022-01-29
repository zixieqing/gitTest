local ChatPanelItemView = class('ChatPanelItemView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.chat.ChatPanelItemView'
	-- node:setBackgroundColor(cc.c4b(0,100,0,0))
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    BTN_CHAT         = _res('ui/home/chatSystem/common_btn_chat'),
    BG               = _res('ui/home/chatSystem/main_bg_common_dialogue.png'),
    CHANNEL_NAME_BG  = _res('ui/home/chatSystem/main_bg_common_dialogue_name.png'),
}

local labelparser = require("Game.labelparser")

local CreateListCell = nil
local isSystemInfo   = nil
local isVoice        = nil

function ChatPanelItemView:ctor( ... )
    local datas = unpack({...})

    local CreateView    = function (size, chatDatas, index)
        local view          = display.newLayer(0, size.height, {ap = display.LEFT_TOP, size = size})

        local messagetype  = chatDatas.messagetype
        local name         = chatDatas.name or chatDatas.playerName or ''
        local channel      = checkint(chatDatas.channel)
        local message      = nil
        local messageSize  = nil
        local msgTouchView = nil
        local tempTab      = nil
        if isVoice(messagetype) then

            -- message
            messageSize = cc.size(290, 30)

            message = display.newLayer(0, 0, {size = messageSize, ap = display.LEFT_TOP})

            local nameLabel = display.newLabel(0, messageSize.height, {text = string.format( "[%s]：", name) , fontSize = 20, color = '#ffffff' , ap = display.LEFT_TOP})
            local nameLabelSize = display.getLabelContentSize(nameLabel)

            local messageBtn = display.newButton(nameLabelSize.width, messageSize.height, {
                n = _res('ui/home/chatSystem/dialogue_bg_voice.png'), scale9 = true, size = cc.size(messageSize.width - nameLabelSize.width, 30), ap = display.LEFT_TOP})
            messageBtn:setEnabled(false)
            messageBtn:setName('message' .. index)

            msgTouchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, size = messageSize, ap = display.LEFT_TOP})

            if chatDatas.time then
                display.commonLabelParams(messageBtn, fontWithColor(5, {text = string.format("%.1f'",checknumber(chatDatas.time)), color = '#ffffff'}))
            end

            message:addChild(nameLabel)
            message:addChild(messageBtn)

        else
            message, tempTab = CreateListCell(chatDatas, index)
            -- message:setOnTextRichClickScriptHandler(handler(self,self.FilterLabelCallBack))
            messageSize = display.getLabelContentSize(message)
        end

        if messageSize.height > size.height then
            size.height = messageSize.height + 10
        end

        local cellTouchView = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = size, color = cc.c4b(0, 0, 0, 0), enable = true, cb = handler(self, self.OnEnterChatAction)})
        view:addChild(cellTouchView, 1)

        local channelNameLabel = display.newLabel(0, 0, {color = '#eb855d', text = ChatUtils.GetChannelTypeName(channel) , fontSize = 20, ap = display.CENTER})
        local channelNameLabelSize = display.getLabelContentSize(channelNameLabel)
        local channelNameBgSize    = cc.size(channelNameLabelSize.width + 6, channelNameLabelSize.height + 4)
        local channelNameBg    = display.newImageView(RES_DIR.CHANNEL_NAME_BG, 0, size.height - 2, {ap = display.LEFT_TOP, scale9 = true, size = channelNameBgSize})
        display.commonUIParams(channelNameLabel, {po = utils.getLocalCenter(channelNameBg)})
        channelNameBg:addChild(channelNameLabel)
        view:addChild(channelNameBg)

        display.commonUIParams(view, {po = cc.p(0, size.height - 2)})
        view:setContentSize(size)

        local messageViewSize = cc.size(size.width - (channelNameBgSize.width + 10), messageSize.height - 10)
        local messageView = display.newLayer(channelNameBgSize.width + 8, size.height - 2, {size = messageViewSize, ap = display.LEFT_TOP})
        view:addChild(messageView)

        display.commonUIParams(message, {po = cc.p(0, messageViewSize.height)})
        messageView:addChild(message)

        if msgTouchView then
            messageView:addChild(msgTouchView)
        end

        return {
            view  = view,
            message = message,
            cellTouchView = cellTouchView,

            tempTab = tempTab,

            size  = size,
        }
    end

    local chatDatas = datas.chatDatas
    local size = datas.size
    local index = datas.index
    self.chatDatas = chatDatas
    self.channelId = datas.channelId
    self.viewData_ = CreateView(size, chatDatas, index)

    self.isTopmost_ = datas.isTopmost == true
    self.tempTab_ = self.viewData_.tempTab

    self:setContentSize(self.viewData_.size)
    self:addChild(self.viewData_.view)
end

function ChatPanelItemView:FilterLabelCallBack( sender ,descr )
	-- body
    print('------------->>>', descr, sender:getTag())

	if descr ~= nil then
        local tempTab = self.tempTab_

		if descr == 'look' then--点击查看
		elseif descr == 'joinnow' then	--点击加入
        elseif descr == 'desc' then	-- 进入聊天界面
            self:OnEnterChatAction()
        elseif descr == 'playname' then	--玩家详情
		elseif descr == 'guild' then--公会详情
		elseif descr == 'stage' then--副本名详情
		elseif descr == 'activity' then--活动详情
            local activityId = tempTab[FILTER_LABELS.ACTIVITY]
            AppFacade.GetInstance():DispatchObservers('REMOVE_CHAT_VIEW')
            AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"},
                {name = "ActivityMediator" , params = {activityId = activityId}})
		end
	end
end

function ChatPanelItemView:OnEnterChatAction(sender)
    if sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag) then return end
    if sceneWorld:getChildByTag(GameSceneTag.Top_Chat_GameSceneTag) then return end
    local chatView = require('Game.views.chat.ChatView').new({channelId = self.channelId})
    display.commonUIParams(chatView, {po = display.center})
    if self.isTopmost_ then
        sceneWorld:addChild(chatView, GameSceneTag.Top_Chat_GameSceneTag, GameSceneTag.Top_Chat_GameSceneTag)
    else
        sceneWorld:addChild(chatView, GameSceneTag.Chat_GameSceneTag, GameSceneTag.Chat_GameSceneTag)
    end
end

function ChatPanelItemView:getChatDatas()
    return self.chatDatas
end

function ChatPanelItemView:getViewData()
    return self.viewData_
end

CreateListCell = function (chatDatas, index)
    local isSelf = checkint(chatDatas.sender)
	local messageType = chatDatas.messagetype or CHAT_MSG_TYPE.TEXT
	local messageLabel = nil
	local anchorPoint = display.LEFT_TOP
	-- if isSelf == MSG_TYPES.MSG_TYPE_SELF then
	-- 	anchorPoint = cc.p(0, 0.5)
	-- else
	-- 	anchorPoint = cc.p(1, 0.5)
    -- end
    local name = tostring(chatDatas.name or chatDatas.playerName)
    local playerId = chatDatas.playerId
    local msg = nil
    local tempMsg = nil
    -- if name ~= nil and name ~= '' and playerId ~= nil then
    --     tempMsg = string.format("<playname id=%s >[%s]：</playname>", playerId, name)
    --     -- chatDatas.message = string.format("<playname id=%s >[%s]：</playname>", playerId, name) .. chatDatas.message
    -- end
    local tempTab = {}
	if checkint(messageType) ~= 2 then
        -- local text1 = "<guild id=12 32 >【hello,world】</guild><desc>发布了招募信息，寻找志同道合的御侍，共同守护世界，抗击堕神！</desc><look>【点击查看】</look>"

        if name ~= nil and name ~= '' and playerId ~= nil  then
            -- local tempparsedtable = labelparser.parse(chatDatas.message)
            table.insert( tempTab, {
                content   = string.format( "[%s]：", name),
                id        = playerId,
                labelname = "playname"
            })
        end
		local parsedtable = labelparser.parse(chatDatas.message)

		--过滤非法标签
        for i,v in ipairs(parsedtable) do
            -- if index == 2 then
            --     dump(FILTERS[v.labelname], v.labelname)
            -- end
			if FILTERS[v.labelname] then
				table.insert(tempTab,v)
			end
        end
        -- chatDatas.name or chatDatas.playerName)
        -- if index == 1 then
        --     dump(parsedtable, 'parsedtableparsedtable1')
        --     dump(tempTab, 'parsedtableparsedtable2')
        -- end
		local t = {
            -- {text = string.format("<playName id=%s >【%s】</playName>", playerId, name), fontSize = 20, color = '#ffffff'}
        }
		local str = ''
		for i,v in ipairs(tempTab) do
            if v.labelname ~= 'fileid' and v.labelname ~= 'messagetype' then
                local isPlayName = v.labelname == 'playname'
                local text = isPlayName and nativeSensitiveWords(v.content) or nativeSensitiveWords( v.content)
                local color = '#fffad5' --'883e3e'

                if isPlayName then
                    color = '#ffffff'
                elseif FILTER_COLORS[v.labelname] then
                    color = FILTER_COLORS[v.labelname]
                end
                -- print('color', color)
				local x = {text = text , fontSize = 20, color = color,descr = v.labelname}
				str = str..text
				table.insert(t,x)
			end
		end
		if table.nums(t) <= 0 then
			table.insert(t,{text = '                                 ', fontSize = 20, color = '#883e3e'})
		end

        msg = t

	else
        msg = {{text = '                                 ', fontSize = 20, color = '#883e3e'}}
    end
    -- dump(msg)
    messageLabel = display.newRichLabel(0, 0, {
        w = 30, ap = anchorPoint, c = msg
    })
    messageLabel:setTag(index + 1)
    messageLabel:reloadData()
	return messageLabel, tempTab
end

-- 用于判断 是否是系统消息
isSystemInfo = function (channel)
    return checkint(channel) == CHAT_CHANNELS.CHANNEL_SYSTEM
end

isVoice      = function (messagetype)
    return checkint(messagetype) == 2
end

return ChatPanelItemView
