local FriendMessageItemView = class('FriendMessageItemView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.chat.FriendMessageItemView'
	node:enableNodeEvents()
	return node
end)

local labelparser = require("Game.labelparser")
local socketMgr = AppFacade.GetInstance():GetManager('ChatSocketManager')
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local voiceChatMgr = AppFacade.GetInstance():GetManager("GlobalVoiceManager")
local voiceEngine = voiceChatMgr:GetVoiceNode()

function FriendMessageItemView:ctor( ... )
	local datas = unpack({...})
	local chatDatas = datas.chatDatas
    self.chatDatas = chatDatas
	local iIndex = datas.index
	self.viewData = nil
	local size = cc.size(580, 146)
	local function CreateView()
		local view = CLayout:create(size)
		local timeLabel = nil
		local bgVoice = nil
		local icoVoice = nil

		local messageLabel = self:CreateListCell(chatDatas, iIndex)--chatDatas.sender,2,chatDatas
		local messageSize = display.getLabelContentSize(messageLabel)
		messageLabel:setOnTextRichClickScriptHandler(handler(self,self.FilterLabelCallBack))
		messageSize.width = messageSize.width*2
		messageSize.height = messageSize.height*2
		if messageSize.height > size.height then
			size.height = messageSize.height
		end
		view:setContentSize(size)
		self:setContentSize(size)
		local offsetX = 20
        local offsetY = -20
		timeLabel = display.newLabel(size.width * 0.5, size.height - 6, {ap = cc.p(0.5, 1), text = os.date("%Y-%m-%d %X", chatDatas.sendTime+ getLoginClientTime() - getLoginServerTime()), fontSize = 20, color = '#d23d3d'})
		view:addChild(timeLabel)
		display.commonUIParams(view,{po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(view)

		local tempTab = {}
		local friendType = nil
		if CommonUtils.GetIsFriendById(chatDatas.friendId) then
			friendType = HeadPopupType.FRIEND
		else
			friendType = HeadPopupType.STRANGER
		end
		local headImg = require('common.FriendHeadNode').new({
            enable = true, scale = 0.6, showLevel = false, avatar = chatDatas.avatar, avatarFrame = chatDatas.avatarFrame, callback = function ( sender )
				if checkint(chatDatas.playerId) ~= checkint(gameMgr:GetUserInfo().playerId) then
					uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = chatDatas.playerId, type = friendType})
				end
            end
        })
		if checkint(chatDatas.sender) == MSG_TYPES.MSG_TYPE_SELF then
			headImg:setAnchorPoint(cc.p(1.0,1.0))
			headImg:setPosition(cc.p(size.width - 16, size.height - 10 + offsetY))
		else
			headImg:setAnchorPoint(cc.p(0, 1.0))
			headImg:setPosition(cc.p(16, size.height - 10 + offsetY))
        end
        view:addChild(headImg)
		headImg:setTag(iIndex)
        local nameLabel = display.newRichLabel(0, 0,
            {w = 30,ap = cc.p(1.0,1.0), r = true, c = {
                    {text = (chatDatas.name or chatDatas.playerName), fontSize = 22, color = 'd36c44'},
                    {text = '', fontSize = 20, color = 'a19b85'},
                }
            })
		view:addChild(nameLabel)
        local messageView = CLayout:create(cc.size(messageSize.width/2+30, messageSize.height/2+20))
        -- messageView:setBackgroundColor(cc.c4b(100,100,100,100))
        view:addChild(messageView)
		local messageBg = display.newImageView(_res('ui/home/chatSystem/dialogue_bg_text.png'), size.width - 84, size.height - 35 + offsetY,
		{ap = cc.p(0.5, 0.5), scale9 = true, size = cc.size(messageSize.width/2+30, messageSize.height/2+30), capInsets = cc.rect(10, 10, 310, 19)})
        messageBg:setPosition(FTUtils:getLocalCenter(messageView))
		messageView:addChild(messageBg)
        display.commonUIParams(messageLabel, {ap = cc.p(0,1), po = cc.p(14,messageBg:getContentSize().height - 18)})
		messageView:addChild(messageLabel, 5)
		messageBg:setTouchEnabled(false)
        local arrow = display.newImageView(_res('ui/home/chatSystem/dialogue_ico_text_point.png'), messageBg:getContentSize().width, size.height - 50+ offsetY, {ap = cc.p(0, 1)})
        messageView:addChild(arrow,1)
        --显示语音消息相关ui
		if tonumber(chatDatas.messagetype) == CHAT_MSG_TYPE.SOUND then
			messageLabel:setVisible(false)
            messageView:setContentSize(cc.size(250,50))
			messageBg:setContentSize(cc.size(250,50))
            messageBg:setPosition(FTUtils:getLocalCenter(messageView))
			bgVoice = display.newButton(0,0, {
                    n = _res('ui/home/chatSystem/dialogue_bg_voice.png'),scale9 = true, size = cc.size(180, 30),ap = cc.p(0.5, 0.5)})
            bgVoice:setEnabled(false)
            display.commonLabelParams(bgVoice, fontWithColor(5, {text = "", color = 'ffffff'}))
			messageView:addChild(bgVoice)
            messageBg:setTag(iIndex)
            if chatDatas.time then
                display.commonLabelParams(bgVoice, fontWithColor(5, {text = string.format("%.1f'",checknumber(chatDatas.time)), color = 'ffffff'}))
            end

			icoVoice = display.newImageView(_res('ui/home/chatSystem/dialogue_ico_voice.png'), 100, 25 , {ap = cc.p(0.5, 0.5)})
			messageView:addChild(icoVoice,1)
            messageBg:setTag(iIndex)

            if checkint(chatDatas.sender) == MSG_TYPES.MSG_TYPE_SELF then
                icoVoice:setScale(-1)
                bgVoice:setPosition(125-12, 25)
                icoVoice:setPosition(cc.p(250 - 24, 25))
            else
                bgVoice:setPosition(125+ 12, 25)
                icoVoice:setPosition(cc.p(24, 25))
            end
			messageBg:setTouchEnabled(true)
            local shareUserDefault = cc.UserDefault:getInstance()
            messageBg:setOnClickScriptHandler(function( sender )
                if voiceEngine then

					if VoiceType.Messages ~= voiceChatMgr:GetMode() then
						uiMgr:ShowInformationTips(__('您当前处于实时语音，无法使用其他语音功能。'))
						return
					end

                    local succ = voiceEngine:ApplyMessageKey() --开始key然后录音的逻辑
                    -- print('----------->>>',succ)
                    if succ == 0 then
                        voiceEngine:StartUpdate()
                        ---如果key应用成功的时候，然后开始才开始播放音频的逻辑
                        local downloadFile = AUDIO_ABSOLUTE_PATH .. tostring(chatDatas.fileid)
                        if not utils.isExistent(downloadFile) then
                            voiceEngine:DownloadRecordedFile(chatDatas.fileid,downloadFile)
                        else
                            --如果已经下载完成的文件直接播放
							app.audioMgr:PauseBGMusic()
                            voiceEngine:PlayRecordedFile(downloadFile)
                        end
                        AppFacade.GetInstance():DispatchObservers(CHAT_AUDIO_PLAY, {fileid = chatDatas.fileid})
                    end
                end
            end)
		end
        if checkint(chatDatas.sender) == MSG_TYPES.MSG_TYPE_SELF then
            --自已发的消息
            arrow:setScaleX(-1)
            display.commonUIParams(nameLabel, {ap = display.RIGHT_TOP, po = cc.p(size.width - 120 + offsetX, size.height - 12 + offsetY)})
            -- display.reloadRichLabel(nameLabel, {c = {
            -- 	{text = gameMgr:GetUserInfo().playerName, fontSize = 22, color = 'd36c44'},
            --     {text = '', fontSize = 20, color = 'a19b85'},
            -- }})
            display.commonUIParams(arrow, {ap = display.RIGHT_TOP, po = cc.p(messageBg:getContentSize().width - 3, messageBg:getContentSize().height - 14)})
            display.commonUIParams(messageView, {ap = display.RIGHT_TOP, po = cc.p(size.width - 146 + offsetX, size.height - 44 + offsetY)})
			messageBg:setPosition(FTUtils:getLocalCenter(messageView))
        else
            --收到的消息
            display.commonUIParams(arrow, {ap = display.RIGHT_TOP, po = cc.p(4, messageBg:getContentSize().height - 14)})
            display.commonUIParams(nameLabel, {ap = display.LEFT_TOP, po = cc.p(120 - offsetX, size.height - 12 + offsetY)})
            display.commonUIParams(messageView, {ap = display.LEFT_TOP, po = cc.p(146 - offsetX, size.height - 44 + offsetY)})
            messageBg:setPosition(FTUtils:getLocalCenter(messageView))
        end
        -- nameLabel:reloadData()
		return {
			view = view,
			headImg = headImg,
			arrow = arrow,
			timeLabel = timeLabel,
			messageLabel = messageLabel,
			nameLabel = nameLabel,
			messageBg = messageBg,
			bgVoice = bgVoice,
			icoVoice = icoVoice,
			messageView = messageView
		}
	end

	self.viewData = CreateView()
	if checkint(chatDatas.messagetype) == CHAT_MSG_TYPE.SOUND then
		--注册时间
		AppFacade.GetInstance():RegistObserver(CHAT_AUDIO_PLAY, mvc.Observer.new(handler(self, self.AudioPlayAction), self))
		AppFacade.GetInstance():RegistObserver(CHAT_AUDIO_END, mvc.Observer.new(handler(self, self.AudioEndAction), self))
	end
end




function FriendMessageItemView:FilterLabelCallBack( lender ,descr )
	-- body
    -- print('------------->>>', descr)
	if descr ~= nil then
        local parsedtable = labelparser.parse(self.chatDatas.message)
        local tempTab = {}
        --过滤非法标签
        for i,v in ipairs(parsedtable) do
            if FILTERS[v.labelname] then
                table.insert(tempTab,v)
            end
        end
		if descr == 'look' then--点击查看

		elseif descr == 'joinNow' then	--点击加入
		elseif descr == 'playName' then	--玩家详情
		elseif descr == 'guild' then--公会详情
		elseif descr == 'stage' then--副本名详情
		elseif descr == 'activity' then--活动详情
            local activityId = tempTab[FILTER_LABELS.ACTIVITY]
            AppFacade.GetInstance():DispatchObservers('REMOVE_CHAT_VIEW')
            AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"},
                {name = "ActivityMediator" , params = {activityId = activityId}})
		end
	end
	dump(descr)
end

function FriendMessageItemView:CreateListCell(chatDatas, idx)
	local isSelf = checkint(chatDatas.sender)
	local messageType = chatDatas.messagetype or CHAT_MSG_TYPE.TEXT
	local messageLabel = nil
	local anchorPoint = cc.p(1,1)
	if isSelf == MSG_TYPES.MSG_TYPE_SELF then
		anchorPoint = cc.p(0,1)
	else
		anchorPoint = cc.p(1,1)
	end
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
		local t = {}
		local str = ''
		for i,v in ipairs(tempTab) do
			if v.labelname ~= 'fileid' and v.labelname ~= 'messagetype' then
                local text = nativeSensitiveWords( v.content)
                local color = '883e3e'
                if FILTER_COLORS[v.labelname] then
                    color = FILTER_COLORS[v.labelname]
                end
				local x = {text = text , fontSize = 20, color = color,descr = v.labelname}
				local xx = CommonUtils.dealWithEmoji({fontSize = x.fontSize, color = x.color, descr = x.descr}, x.text)
				str = str..text
				for _, val in ipairs(xx) do
					table.insert(t, val)
				end

			end
		end
		if table.nums(t) <= 0 then
			table.insert(t,{text = '                                 ', fontSize = 20, color = '#883e3e'})
		end
        messageLabel = display.newRichLabel(0, 0,
            {w = 30,ap = anchorPoint, c = t
            })
        messageLabel:setTag(idx)
        messageLabel:reloadData()
	else
		messageLabel = display.newRichLabel(0, 0,
			{w = 30,ap = anchorPoint, c = {
				{text = '                                 ', fontSize = 20, color = '#883e3e'},
			}
		})
		messageLabel:setTag(idx)
		messageLabel:reloadData()
	end
	return messageLabel
end
--[[
音频播放开始事件
--]]
function FriendMessageItemView:AudioPlayAction( stage, signal )
	if self.chatDatas.fileid == signal:GetBody().fileid then
		self:PlayAnimate()
	else
		self:RemoveAnimate()
	end
end
--[[
音频播放结束事件
--]]
function FriendMessageItemView:AudioEndAction( stage, signal )
	self:RemoveAnimate()
end
--[[
添加播放语音的动画
--]]
function FriendMessageItemView:PlayAnimate()
	self.viewData.icoVoice:setVisible(false)
    local voiceSpine = sp.SkeletonAnimation:create(
		'effects/chatSystem/bofang.json',
		'effects/chatSystem/bofang.atlas',
		1)
    voiceSpine:update(0)
    voiceSpine:setToSetupPose()
    voiceSpine:setAnimation(0, 'play', true)
    voiceSpine:setName('voiceSpine')
    self.viewData.messageView:addChild(voiceSpine, 10)
    if checkint(self.chatDatas.sender) == MSG_TYPES.MSG_TYPE_SELF then
        voiceSpine:setPosition(cc.p(250 - 24, 25))
    else
		voiceSpine:setScale(-1)
        voiceSpine:setPosition(cc.p(24, 25))
    end

end
--[[
移除播放语音动画
--]]
function FriendMessageItemView:RemoveAnimate()
	self.viewData.icoVoice:setVisible(true)
	if self.viewData.messageView:getChildByName('voiceSpine') then
		self.viewData.messageView:getChildByName('voiceSpine'):removeFromParent()
	end
end
function FriendMessageItemView:onCleanup()
	if self:getReferenceCount() <= 2 then
		if checkint(self.chatDatas.messagetype) == CHAT_MSG_TYPE.SOUND then
			AppFacade.GetInstance():UnRegistObserver(CHAT_AUDIO_PLAY,self)
			AppFacade.GetInstance():UnRegistObserver(CHAT_AUDIO_END,self)
		end
	end
end
return FriendMessageItemView