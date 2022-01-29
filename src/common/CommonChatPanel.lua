local CommonChatPanel = class('CommonChatPanel', function()
    return display.newLayer(0, 0, {name = 'common.CommonChatPanel', enableEvent = true})
end)

local labelparser    = require("Game.labelparser")
local shareFacade    = AppFacade.GetInstance()

local uiMgr          = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr        = AppFacade.GetInstance():GetManager("GameManager")
local socketMgr      = AppFacade.GetInstance('AppFacade'):GetManager('ChatSocketManager')

local RES_DIR = {
    BTN_CHAT         = _res('ui/home/chatSystem/common_btn_chat'),
    BG               = _res('ui/home/chatSystem/main_bg_common_dialogue.png'),
    CHANNEL_NAME_BG  = _res('ui/home/chatSystem/main_bg_common_dialogue_name.png'),
}

local CreateView       = nil
local CreateButtonView = nil

local NORMAL_STATE  = 1  -- 正常状态
local STRETCH_STATE = 2  -- 伸展状态
local BUTTON_STATE  = 3  -- 按钮状态

local MAX_MSG_COUNT = 5

local PANEL_BG_SIZE_STATE_NORMAL  = cc.size(358, 86)   -- 未伸展 状态的 最大值
local PANEL_BG_SIZE_STATE_STRETCH = cc.size(358, 172)  -- 伸展后 最大值

local CHANNEL_TYPE_CONF = {
    -- KEY  聊天频道类型                        VALUE  需要 监听的聊天频道类型
    [tostring(CHAT_CHANNELS.CHANNEL_WORLD)]  = {CHAT_CHANNELS.CHANNEL_WORLD},
    [tostring(CHAT_CHANNELS.CHANNEL_TEAM)]   = {CHAT_CHANNELS.CHANNEL_WORLD, CHAT_CHANNELS.CHANNEL_TEAM},
    [tostring(CHAT_CHANNELS.CHANNEL_UNION)]  = {CHAT_CHANNELS.CHANNEL_UNION},
    [tostring(CHAT_CHANNELS.CHANNEL_HOUSE)]  = {CHAT_CHANNELS.CHANNEL_HOUSE},
}

--==============================--
--desc:
--time:2017-12-12 11:58:01
--@args:
    -- @params defDelayInit 是否在创建时 加载数据   为 false  则需要 调用 在其他界面调用 delayRenderingList()
    -- @params 
--@return 
--==============================--- 
function CommonChatPanel:ctor( ... )
    self.args = unpack({...}) or {}

    self.datas = {}
    self.state = self.args.state or NORMAL_STATE
    
    self.isTopmost_ = self.args.isTopmost == true
    self.channelId  = self.args.channelId or CHAT_CHANNELS.CHANNEL_WORLD

    -- 找不到配置 走世界
    self.curChanelConf = CHANNEL_TYPE_CONF[tostring(self.channelId)] or {CHAT_CHANNELS.CHANNEL_WORLD}
    
    self:initUi()
    self:setControllable(true)
    
    -- -- 默认直接 延迟初始化
    -- local defDelayInit = self.args.defDelayInit == nil and true or self.args.defDelayInit
    -- if defDelayInit then
    --     self:delayInit()
    -- end
end

function CommonChatPanel:initUi()
    local viewData_ = nil
    if self.state == BUTTON_STATE then
        viewData_ = CreateButtonView()
        local btn = viewData_.btn
        display.commonUIParams(btn,     {cb = handler(self, self.OnEnterChatAction)})
    else
        viewData_ = CreateView()
        local touchView = viewData_.touchView
        display.commonUIParams(touchView,     {cb = handler(self, self.OnEnterChatAction)})
    end
    self:addChild(viewData_.layer)
    self:setContentSize(viewData_.layer:getContentSize())
    self.viewData_ = viewData_
end

function CommonChatPanel:delayInit()
    if self.state ~= BUTTON_STATE then
        
        self:delayRenderingList()
    end
end


function CommonChatPanel:isControllable()
	return self.isControllable_
end
function CommonChatPanel:setControllable(isControllable)
	self.isControllable_ = isControllable == true
end

function CommonChatPanel:isListenData(chanel)
    
    local isListen = false
    for i,v in ipairs(self.curChanelConf) do
        if v == checkint(chanel) then
            isListen = true
            break
        end
    end
    return isListen
end

--==============================--
--desc: 处理更新的 聊天消息
--time:2017-11-29 03:32:39
--@stage:
--@signal:
--@return 
--==============================-- 
function CommonChatPanel:ChatSendMessageCallback(stage, signal)
    if tolua.isnull(self) then return end
    
	local name = signal:GetName()
    local body = signal:GetBody()
    local channel = checkint(body.channel)
    -- dump(body)

    
    if self:isListenData(channel) then
        local chatListView = self.viewData_.chatListView
        chatListView:setVisible(true)
        self:UpdateChatList(body)
        self:updateChatListSize()
    end
end

function CommonChatPanel:UpdateChatList(chatDatas)
    if CommonUtils.IsInBlacklist( chatDatas.playerId ) then
        return
    end
    local chatListView = self.viewData_.chatListView
    local size = cc.size(chatListView:getContentSize().width, 27)
    if chatDatas then
        local index = chatListView:getNodeCount()
        if index >= MAX_MSG_COUNT then
            chatListView:removeNodeAtIndex(0)
        end
        -- dump(chatDatas, 'ChatSendMessageCallbackccc')
        local view = require('Game.views.chat.ChatPanelItemView').new({size = size, chatDatas = chatDatas, index = index, channelId = self.channelId, isTopmost = self.isTopmost_})
		chatListView:insertNodeAtLast(view)
		chatListView:reloadData()
        chatListView:setContentOffsetToBottom()

        return view
	end
end


function CommonChatPanel:updateChatListSize( ... )
    local chatListView = self.viewData_.chatListView
    local isNormalState = self.state == NORMAL_STATE
    local listNodes     = chatListView:getNodes()
    
    local chatListViewSize = chatListView:getContentSize()

    local realListSize = cc.size(chatListViewSize.width, 0)
    for i,node in ipairs(listNodes) do
       local nodeSize = node:getContentSize()
       realListSize.height = realListSize.height + nodeSize.height
       
        if isNormalState then
            if realListSize.height > PANEL_BG_SIZE_STATE_NORMAL.height then
                realListSize = PANEL_BG_SIZE_STATE_NORMAL
                break
            end
        else
            if realListSize.height > PANEL_BG_SIZE_STATE_STRETCH.height then
                realListSize = PANEL_BG_SIZE_STATE_STRETCH
                break
            end
        end
       
    end

    local height = isNormalState and PANEL_BG_SIZE_STATE_NORMAL.height or PANEL_BG_SIZE_STATE_STRETCH.height
    chatListView:setContentSize(realListSize)
    chatListView:setPosition(cc.p(chatListView:getPositionX(), height))

    self:updateChatListContentOffset()
end


function CommonChatPanel:updateChatListContentOffset()
    local chatListView = self.viewData_.chatListView
    local index = chatListView:getNodeCount()

    local node = chatListView:getNodeAtIndex(index - 1)
    if node then
        chatListView:setContentOffset(cc.p(0, -node:getContentSize().height + 28))
    end

end

function CommonChatPanel:delayRenderingList()
    local datas = socketMgr:GetMessageByChannel(self.channelId) -- socketMgr:GetWorldMessage()
    local dataLens = #datas
    local isShowList = dataLens ~= 0
    -- dump(datas, isShowList)s

    local startIndex = 1
    if dataLens > MAX_MSG_COUNT then
        startIndex = dataLens - MAX_MSG_COUNT + startIndex
    end
    local chatListView = self.viewData_.chatListView
    local count = 0
    local height = 0
    local function delayTimeLoad()
        if dataLens >= (startIndex + count) then
            self:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(0.3),
                    cc.CallFunc:create(function ()
                        local cell = self:UpdateChatList(datas[startIndex + count])
                        if cell then
                            local cellSize = cell:getContentSize()
                            height = cellSize.height + height
                            if height > PANEL_BG_SIZE_STATE_NORMAL.height then
                                chatListView:setContentSize(PANEL_BG_SIZE_STATE_NORMAL)
                            else
                                chatListView:setContentSize(cc.size(cellSize.width, height))
                            end
                        end
                        count = count + 1
                        delayTimeLoad()
                    end)
                    )
                )
        else
            --  监听 聊天消息更新
            shareFacade:RegistObserver(SIGNALNAMES.Chat_GetMessage_Callback, mvc.Observer.new(handler(self, self.ChatSendMessageCallback), self))
            self:updateChatListSize()
        end
    end
    self.datas = datas
    if isShowList then
        chatListView:setVisible(true)
        delayTimeLoad()
    else
        --  监听 聊天消息更新
        shareFacade:RegistObserver(SIGNALNAMES.Chat_GetMessage_Callback, mvc.Observer.new(handler(self, self.ChatSendMessageCallback), self))
    end
end

function CommonChatPanel:OnEnterChatAction(sender)
    PlayAudioByClickNormal()
    if not self:isControllable() then return end
    self:showChatView()
end


function CommonChatPanel:showChatView()
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
function CommonChatPanel:removeChatView()
    if self.isTopmost_ then
        local chatView = sceneWorld:getChildByTag(GameSceneTag.Top_Chat_GameSceneTag)
        if chatView and not tolua.isnull(chatView) then
            chatView:RemoveChatView()
        end
    else
        local chatView = sceneWorld:getChildByTag(GameSceneTag.Chat_GameSceneTag)
        if chatView and not tolua.isnull(chatView) then
            chatView:RemoveChatView()
        end
    end
end


function CommonChatPanel:onCleanup()
	shareFacade:UnRegistObserver(SIGNALNAMES.Chat_GetMessage_Callback, self)
end

CreateView = function ()
    local size = cc.size(358, display.height)
    local layer = display.newLayer(display.SAFE_L, display.height / 2, {ap = display.LEFT_CENTER, size = size})

    -- local btn = display.newButton(2, size.height / 2, {n = RES_DIR.BTN_CHAT, ap = display.LEFT_BOTTOM})
    -- layer:addChild(btn)

    local bgSize = cc.size(358, 86)
    
    local bg = display.newImageView(RES_DIR.BG, 0, 0, {ap = display.LEFT_BOTTOM, scale9 = true, size = bgSize, enable = false})
    layer:addChild(bg)

    local touchView = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = bgSize, color = cc.c4b(0, 0, 0, 0), enable = true})
    layer:addChild(touchView)

    local listSize = cc.size(bgSize.width - 2, 30)
    local chatListView = CListView:create(listSize)
    chatListView:setPosition(cc.p(bgSize.width / 2, bgSize.height))
    chatListView:setDirection(eScrollViewDirectionVertical)
    chatListView:setAnchorPoint(display.CENTER_TOP)
    chatListView:setBounceable(false)
    layer:addChild(chatListView)
    -- chatListView:setBackgroundColor(cc.c3b(100,100,200))
    chatListView:setVisible(false)
    return {
        layer = layer,
        touchView = touchView,
        bg    = bg,
        chatListView = chatListView,

        -- btn = btn,

        bgSize = bgSize,
    }
end

CreateButtonView = function ()
    -- local size = cc.size(358, display.height)
    local layer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM})
    local btn = display.newButton(0, 0, {n = RES_DIR.BTN_CHAT, ap = display.LEFT_BOTTOM})
    layer:addChild(btn)

    layer:setContentSize(btn:getContentSize())

    return {
        layer = layer,
        btn = btn,

    }
end

return CommonChatPanel
