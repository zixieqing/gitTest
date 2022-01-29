-- LobbyFriendMediator
-- todo 请求好友数据后  更新 gameMg 中的好友信息

local Mediator = mvc.Mediator
local LobbyFriendMediator = class("LobbyFriendMediator", Mediator)

local NAME = "LobbyFriendMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local nodePosToWorldPos = nil
local getOnlineCount = nil
local getRestaurantBugState = nil
local getRestaurantQuestEventState = nil
local getCellIndexByFriendId = nil

local restaurantVisitConf = CommonUtils.GetConfigAllMess('restaurantVisit', 'friend') or {}
local VISIT_TYPE = {   -- 访问的类型
    LOBBY_TYPE = 1,       -- 从餐厅进入
    FISH_TYPE  = 2,       -- 从钓场进入
    PRIVATEROOM_TYPE = 3, -- 从包厢进入
}
local FISH_VIST_TYPE = {
    ADD_FISH_CARD_TYPE = 1 , -- 好友在玩家钓场添加卡牌
    KICK_FISH_CARD_TYPE = 2 -- 玩家的卡牌在好友的钓场中被卸下
}
function LobbyFriendMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)

    self.args = checktable(params)
    -- 访问类型
    self.visitType = self.args.visitType or VISIT_TYPE.LOBBY_TYPE
    self.descIndex = -1
    self.friendCellIndex = 0

end


function LobbyFriendMediator:InterestSignals()
	local signals = {
        SIGNALNAMES.Friend_List_Callback,
        SIGNALNAMES.SIGNALNAME_FRIEND_MESSAGEBOOK,
        SIGNALNAMES.SIGNALNAME_FRIEND_AVATAR_STATE,
        POST.FISHPLACE_FRIENDS_FISH_LOG.sglName ,
        -- 更新 餐厅好友列表 虫子 和 
        UPDATE_LOBBY_FRIEND_BUG_STATE,
        UPDATE_LOBBY_FRIEND_LIST_SELECT_STATE,
        FISH_FRIEND_CARD_UNLOAD_AND_LOAD_EVENT
	}

	return signals
end

function LobbyFriendMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = checktable(signal:GetBody())

    if name == SIGNALNAMES.Friend_List_Callback then

        self.friendList = checktable(body.friendList)
        -- dump(self.friendList)
        gameMgr:GetUserInfo().friendList = self.friendList
        self:ShowFriendList()

    elseif name == SIGNALNAMES.SIGNALNAME_FRIEND_MESSAGEBOOK then

        self:UpdateMassageView(body)
    elseif name == POST.FISHPLACE_FRIENDS_FISH_LOG.sglName then
        local friendsFishLog = body.friendsFishLog
        for i, v in pairs(friendsFishLog) do
            v.messageType = checkint(v.fishType)
        end
        self:UpdateMassageView(body)
    elseif name == UPDATE_LOBBY_FRIEND_BUG_STATE then
        if self.visitType == VISIT_TYPE.LOBBY_TYPE then
            local cmd = checkint(body.cmd)
            local friendId = checkint(body.friendId)

            local restaurantBug = getRestaurantBugState(cmd)
            local restaurantQuestEvent = getRestaurantQuestEventState(cmd)

            local data = {{friendId = friendId, restaurantBug = restaurantBug, restaurantQuestEvent = restaurantQuestEvent}}

            -- 1. 更新好友列表数据
            self:updateFriendCellState(data)
        end

    elseif name == UPDATE_LOBBY_FRIEND_LIST_SELECT_STATE then
        print("UPDATE_LOBBY_FRIEND_LIST_SELECT_STATE")
        -- todo  更新 好友状态
        local friendId = body.friendId
        local friendCellIndex = getCellIndexByFriendId(friendId, self.friendList)

        -- 从别的地方切换 好友餐厅 成功 则 保存 当前好友id
        gameMgr:GetUserInfo().avatarFriendId_ = checkint(friendId)

        if friendCellIndex ~= self.friendCellIndex then
            local gridView = self.viewData.gridView
            local cell = gridView:cellAtIndex(friendCellIndex - 1)
            -- 1。 更新好友cell  选中装填
            self:updateCellBgSelectState(cell, self.friendCellIndex)
            self.friendCellIndex = friendCellIndex
        end
    elseif name == FISH_FRIEND_CARD_UNLOAD_AND_LOAD_EVENT then
        -- 在好友钓场添加卡牌和被好友踢出的事件
        local index = body.index
        local viewComponent = self:GetViewComponent()
        local viewData = viewComponent.viewData
        local cell = viewData.gridView:cellAtIndex(index  -1)
        if cell and (not tolua.isnull(cell) ) then
            self:SortFriendList()
            local gridView         = self.viewData.gridView
            gridView:reloadData()
        end
    end
end
--[[
　　---@Description: 给好友列表排序
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/9/26 10:37 AM
--]]
function LobbyFriendMediator:SortFriendList()
    local friendList = gameMgr:GetUserInfo().friendList
    local collectFishFriendList  = {}
    local collectWeatherTable = {}
    local curentTime = getServerTime()
    for i = #friendList , 1, -1 do
        if  friendList[i].friendFish  and table.nums( friendList[i].friendFish)  > 0
        and   checkint(friendList[i].fishPlaceLevel) > 0  and checkint(friendList[i].friendFish.playerCardId) > 0  then
            if CommonUtils.JuageMySelfOperation(friendList[i].friendFish.friendId)  then
                collectFishFriendList[#collectFishFriendList+1] = table.remove(friendList , i )
            end
        elseif friendList[i].friendFishPlace  then
            local buff = friendList[i].friendFishPlace.buff

            if buff and  checkint(buff.startTime) < curentTime and curentTime < checkint(buff.endTime)  then
                collectWeatherTable[#collectWeatherTable+1] = table.remove(friendList , i )
            end     
        end
    end
    table.sort(collectWeatherTable , function(aPray, bPray )
        local abuff = aPray.friendFishPlace.buff
        local bbuff = bPray.friendFishPlace.buff
        return checkint(abuff.buffId) < checkint(bbuff.buffId)
    end)
    for i = #collectWeatherTable , 1, -1 do
        table.insert(friendList , 1, collectWeatherTable[i])
    end
    for i = 1 , #collectFishFriendList do
        table.insert(friendList , 1, collectFishFriendList[i])
    end
end

--[[
　　---@Description: 给好友列表排序
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/9/26 10:37 AM
--]]
function LobbyFriendMediator:SortFriendListByLobby()
    local friendList = gameMgr:GetUserInfo().friendList
    local restaurantQuestEvent = 0
    local restaurantBug = 0
    local friendKinddTable = {{}, {}, {}, {}}
    for i = #friendList , 1, -1 do
        local friendData = {}
        friendData = friendList[i]
        if  friendData  then
            restaurantBug = checkint(friendData.restaurantBug)
            restaurantQuestEvent = checkint(friendData.restaurantQuestEvent)
            if restaurantBug > 1 and restaurantQuestEvent > 1   then
                friendKinddTable[1][#(friendKinddTable[1])+1] = friendData
            elseif restaurantBug > 1 then
                friendKinddTable[2][#(friendKinddTable[2])+1] = friendData
            elseif restaurantQuestEvent > 1 then
                friendKinddTable[3][#(friendKinddTable[3])+1] = friendData
            else
                friendKinddTable[4][#(friendKinddTable[4])+1] = friendData
            end
        end
    end
    local sortList = {}
    for i = 1, #friendKinddTable do
        local data = friendKinddTable[i]
        for i = 1, #data do
            sortList[#sortList+1] = data[i]
        end
    end     
    gameMgr:GetUserInfo().friendList = sortList
    self.friendList = sortList
end

--[[
　　---@Description: 获取消息几率的标题
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/30 2:33 PM
--]] 
function LobbyFriendMediator:GetMessageTitle()
    if self.visitType == VISIT_TYPE.LOBBY_TYPE then
        return __('访客记录')
    elseif self.visitType == VISIT_TYPE.FISH_TYPE then
        return  __('钓场记录')
    elseif self.visitType == VISIT_TYPE.PRIVATEROOM_TYPE then
        return __('包厢记录')
    end
end
--[[
　　---@Description: 更新访问记录或者钓鱼记录
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/30 2:03 PM
--]]
function LobbyFriendMediator:UpdateMassageView(data)
    data = data or {}
    self.messages= {}
    local params = {mediatorName = "LobbyFriendMediator", tag = 54321,name  = self:GetMessageTitle() }
    local layer = require('Game.views.MessageBookView').new(params)
    display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
    layer:setTag(params.tag)
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(layer)
    local msgBookViewData = layer.viewData
    local totalVisitor = msgBookViewData.totalVisitor
    local todayVisitor = msgBookViewData.todayVisitor
    local msgGridView = msgBookViewData.msgGridView
    local visitorBg = msgBookViewData.visitorBg
    if self.visitType == VISIT_TYPE.LOBBY_TYPE then
        local totalVisit = checkint(data.totalVisit)
        local todayVisit = checkint(data.todayVisit)
        self.messages = checktable(data.messages)
        display.commonLabelParams(totalVisitor, {text = string.format( __('总访客量: %s'), totalVisit)})
        display.commonLabelParams(todayVisitor, {text = string.format( __('今日访客: %s'), todayVisit)})
    elseif self.visitType == VISIT_TYPE.FISH_TYPE then
        self.messages = checktable(data.friendsFishLog)
        totalVisitor:setVisible(false)
        todayVisitor:setVisible(false)
        visitorBg:setVisible(false)
        local msgGridViewSize  =   msgGridView:getContentSize()
        msgGridView:setContentSize(cc.size(msgGridViewSize.width , msgGridViewSize.height + 40) )
    end
    msgGridView:setDataSourceAdapterScriptHandler(handler(self, self.OnMsgBookDataSource))
    msgGridView:setCountOfCell(#self.messages)
    msgGridView:reloadData()
    if #self.messages == 0  then
        layer:AddNotVisitorView(self:GetMessageTitle())
    end

end

function LobbyFriendMediator:Initial( key )
	self.super.Initial(self,key)

    local scene = uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.LobbyFriendView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

    self.viewData = viewComponent.viewData
    self.friendCellData = viewComponent.friendCellData
    self:initUi()
end

--==============================--
--desc: 初始化好友界面UI
--time:2017-09-22 05:04:19
--@return 
--==============================--
function LobbyFriendMediator:initUi()
    local touchLayer       = self.viewData.touchLayer
    local gridView         = self.viewData.gridView
    local messageBook      = self.viewData.messageBook
    local robetViewData    = self.viewData.robetViewData
    local chooseCookerBtn  = self.viewData.chooseCookerBtn
    local messageLabel     = self.viewData.messageLabel
    local officialBtn      = robetViewData.cellBg
    local headerButton     = robetViewData.headerButton
    local friendLvLabel    = robetViewData.friendLvLabel
    local nameLabel        = robetViewData.nameLabel

    gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    
    display.commonUIParams(touchLayer, {cb = function ()
        self:hideFriendDesc()
        self:GetViewComponent():setVisible(false)
    end})
    
    display.commonUIParams(messageBook, {cb = handler(self, self.OnMessageBookAction)})
    display.commonLabelParams(messageLabel , {text = self:GetMessageTitle() , reqW  = 150 })
    display.commonUIParams(officialBtn, {cb = handler(self, self.onClickOfficialButtonHandler_), animate = false})
    display.commonUIParams(chooseCookerBtn,{cb = handler(self, self.OnAddFriendAction)})
    if self.visitType == VISIT_TYPE.PRIVATEROOM_TYPE then
        messageBook:setVisible(false)
    end

    if self.visitType == VISIT_TYPE.LOBBY_TYPE then
        local officialConfs = CommonUtils.GetConfigAllMess('show', 'restaurant') or {}
        display.commonLabelParams(nameLabel, {text = officialConfs.name, color = '#425336'})
        display.commonLabelParams(friendLvLabel, {text = officialConfs.level or 1})
        headerButton.headerSprite:setWebURL(officialConfs.avatar)
        headerButton:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(officialConfs.avatarFrame or '')))
    else
        local cellBg = robetViewData.cellBg
        cellBg:setVisible(false)
        headerButton:getParent():setVisible(false)
        local size = cc.size(412, display.height)
        gridView:setContentSize(cc.size(size.width * 0.96, size.height * 0.86))
    end

    if not self.args.isFirstLookFriend then
        self.friendList = gameMgr:GetUserInfo().friendList
        local friendId = gameMgr:GetUserInfo().avatarFriendId_
        self.friendCellIndex = friendId and getCellIndexByFriendId(friendId, self.friendList) or 0
        self:ShowFriendList()
    end
end 

--==============================--
--desc: 进入好友 详情
--time:2017-09-22 03:51:58
--@sender:
--@return 
--==============================
function LobbyFriendMediator:enterFriendDesc(index)
    PlayAudioByClickNormal()
    if self.descIndex == index then return end

    local data = self.friendList[index]
    local gridView = self.viewData.gridView
    local cell = gridView:cellAtIndex(index - 1)

    local poss = nodePosToWorldPos(cell, cc.p(0.5, 0.5))
    local cSize = cell:getContentSize()

    local x, y = poss.x, poss.y + 5
    local function checkY(y, minOffsetY)
        return y <= minOffsetY and minOffsetY or y
    end

    local function realPos(x, y, node)
        local nSize = node:getContentSize()
        return cc.p(x, checkY(y, nSize.height))
    end

    local scene = uiMgr:GetCurrentScene()
    local layer = scene:GetDialogByTag(123456)

    self.descIndex = index
    -- 存在 则更新
    if layer then
        layer:setVisible(true)
        layer:setPosition(realPos(x, y, layer))

        self:updateFriendDesc(layer, data)

        return
    end
    
    local layer = self:GetViewComponent():CreateFriendDesc()
    layer:setPosition(realPos(x, y, layer))
    layer:setTag(123456)
    scene:AddDialog(layer)

    self:updateFriendDesc(layer, data, true)

end

function LobbyFriendMediator:hideFriendDesc()
    if  uiMgr:GetCurrentScene():GetDialogByTag(123456) then
        self.descIndex = -1
        uiMgr:GetCurrentScene():GetDialogByTag(123456):setVisible(false)
    end
end

--==============================--
--desc: 进入好友餐厅
--time:2017-09-26 02:39:13
--@friendId: 好友 id  注意 当它为 -1 时 表示数据错乱
--@return 
--==============================-- 
function LobbyFriendMediator:enterFriendAvatar(friendId)
    if gameMgr:GetUserInfo().avatarFriendId_ == friendId then
        return
    end
    
    self:hideFriendDesc()

    print(friendId, 'friendIdfriendId')
    -- save visitLog by switch friendAvatar before
    if self.visitType == VISIT_TYPE.LOBBY_TYPE then
        if checkint(gameMgr:GetUserInfo().avatarFriendId_) > 0 then
            local avatarMdt = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
            avatarMdt:uploadFriendVisitLog()
        end
        gameMgr:GetUserInfo().avatarFriendId_ = friendId

        -- switch friendAvatar
        local friendAvatarMdt = AppFacade.GetInstance():RetrieveMediator('FriendAvatarMediator')
        if friendAvatarMdt then
            friendAvatarMdt:setCurrentFriendId(friendId)
        else
            friendAvatarMdt = require('Game.mediator.FriendAvatarMediator').new({friendId = friendId})
            AppFacade.GetInstance():RegistMediator(friendAvatarMdt)
        end
    elseif self.visitType == VISIT_TYPE.FISH_TYPE  then
        self:SendSignal(POST.FISHPLACE_HOME.cmdName ,{queryPlayerId = friendId})
    elseif self.visitType == VISIT_TYPE.PRIVATEROOM_TYPE then
        local friendAvatarMdt = AppFacade.GetInstance():RetrieveMediator('PrivateRoomFriendMediator')
        if friendAvatarMdt then
            friendAvatarMdt:SetCurrentFriendId(friendId)
        else
            friendAvatarMdt = require('Game.mediator.privateRoom.PrivateRoomFriendMediator').new({friendId = friendId})
            AppFacade.GetInstance():RegistMediator(friendAvatarMdt)
        end
    end
end

function LobbyFriendMediator:enterLayer()
    -- self:GetFacade():DispatchObservers(SIGNALNAMES.Friend_List_Callback)
    
    self:SendSignal(COMMANDS.COMMAND_Friend_List)
end

function LobbyFriendMediator:ShowFriendList()
    -- self.friendMap = {}
    -- for i,v in ipairs(self.friendList) do
    --     v.listIndex = i
    --     self.friendMap[v.friendId] = v
    -- end
    
    local friendCount = #self.friendList
    local addFriendLayer = self.viewData.addFriendLayer
    local gridView = self.viewData.gridView
    gridView:setVisible(friendCount ~= 0)
    addFriendLayer:setVisible(friendCount == 0)
    if friendCount ~= 0 then
        table.sort(self.friendList, function (a, b)
            return a.restaurantLevel > b.restaurantLevel
        end)
        local friendCountLb = self.viewData.friendCountLb
        gridView:setCountOfCell(friendCount)
        if self.visitType == VISIT_TYPE.FISH_TYPE then
            self:SortFriendList()
        elseif self.visitType == VISIT_TYPE.LOBBY_TYPE then
            self:SortFriendListByLobby()
        end
        gridView:reloadData()
        display.commonLabelParams(friendCountLb, { reqW =280, text = string.format(__("好友人数: %s/%s"), getOnlineCount(self.friendList), #self.friendList)})
    end
end

--==============================--
--desc: 更新好友详情
--time:2017-09-26 03:16:47
--@parent: 
--@data: 好友数据
--@isFirst: 是否是第一次进入
--@return 
--==============================--
function LobbyFriendMediator:updateFriendDesc(parent, data, isFirst)
    local viewData = parent.viewData
    local nameLabel = viewData.nameLabel
    local onlineLabel = viewData.onlineLabel
    local avatarLv = viewData.avatarLv
    local intimacy = viewData.intimacy
    local friendLvLabel = viewData.friendLvLabel
    local headerButton = viewData.headerButton
    -- local noticeImage = viewData.noticeImage
    headerButton.headerSprite:setWebURL(data.avatar)
    headerButton:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(data.avatarFrame or '')))

    display.commonLabelParams(nameLabel, {text = tostring(data.name)})
    display.commonLabelParams(onlineLabel, {text = data.isOnline == 1 and __("在线") or __("离线")})
    display.commonLabelParams(avatarLv, {text = string.format(__('餐厅等级:%s'), data.restaurantLevel or 1)})
    display.commonLabelParams(intimacy, {text = string.format(__('亲密度:%s'), checkint(data.closePoint))})
    display.commonLabelParams(friendLvLabel, {text = data.level or 1})
    
    if isFirst then
        local actionBtns = viewData.actionBtns
        for i,v in pairs(actionBtns) do
            display.commonUIParams(v, {cb = handler(self, self.OnFriendDescAction)})
        end
    end
end

function LobbyFriendMediator:updateFriendCellState(data)
    local friendData = self:getCellsByFriendData(data)
    for i,v in ipairs(friendData) do
        local cell = v.cell
        if cell then
            local cellViewData = cell.viewData
            local tipLayer = cellViewData.tipLayer
            
            local restaurantBug = v.restaurantBug
            local restaurantQuestEvent = v.restaurantQuestEvent
            local bugTips = {restaurantBug, restaurantQuestEvent}
            self:GetViewComponent():CreateTipImg(tipLayer, bugTips)
        end
    end
    -- local cellViewData = cell.viewData
    -- local tipLayer = cellViewData.tipLayer

    -- local bugTips = {data.restaurantBug, data.restaurantQuestEvent}
    -- self:GetViewComponent():CreateTipImg(tipLayer, bugTips)
end

function LobbyFriendMediator:updateSelectState(cell, isSelect)
    if cell == nil then
        return
    end
    local cellViewData = cell.viewData
    local cellBg_s = cellViewData.cellBg_s
    local cellSelectedFrame = cellViewData.cellSelectedFrame
    cellBg_s:setVisible(isSelect)
    cellSelectedFrame:setVisible(isSelect)
end

function LobbyFriendMediator:updateCellBgSelectState(newCell, oldIndex)

    local gridView = self.viewData.gridView
    if oldIndex ~= -1 then
        local oldCell = gridView:cellAtIndex(oldIndex - 1)
        if oldCell then
            self:updateSelectState(oldCell, false)
        end
    end

    self:updateSelectState(newCell, true)
end
--==============================--
--desc: 好友列表数据源
--time:2017-09-22 05:03:56
--@p_convertview:
--@idx:
--@return 
--==============================-- 
function LobbyFriendMediator:OnDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateCell(1)
        display.commonUIParams(pCell.viewData.cellBg, {cb = handler(self, self.OnCellBgAction)})
    end

    xTry(function()
        local cellViewData = pCell.viewData
        local descLabel = cellViewData.descLabel
        local tipLayer = cellViewData.tipLayer
        local cellBg_s = cellViewData.cellBg_s
        local cellSelectedFrame = cellViewData.cellSelectedFrame
        local nameLabel = cellViewData.nameLabel
        local headerButton = cellViewData.headerButton
        local friendLvLabel = cellViewData.friendLvLabel
        cellBg_s:setVisible(self.friendCellIndex == index)
        cellSelectedFrame:setVisible(self.friendCellIndex == index)

        local data = self.friendList[index]
        local callback = function ()
            PlayAudioByClickNormal()
            local mediator = require("Game.mediator.PersonInformationMediator").new({playerId = data.friendId})
            AppFacade.GetInstance():RegistMediator(mediator)
        end
        headerButton:setClickCallback(callback)
        headerButton.headerSprite:setWebURL(data.avatar)
        headerButton:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(data.avatarFrame)))
        -- 头像
        display.commonLabelParams(nameLabel, {text = tostring(data.name)})
        local descr = ""
        if self.visitType ==  VISIT_TYPE.LOBBY_TYPE then
            descr =  string.format(__('餐厅等级:%s'), checkint(data.restaurantLevel))
            local bugTips = {data.restaurantBug, data.restaurantQuestEvent}
            self:GetViewComponent():CreateTipImg(tipLayer, bugTips)
        elseif self.visitType == VISIT_TYPE.PRIVATEROOM_TYPE then
            descr =  string.format(__('包厢等级:%s'), checkint(data.restaurantLevel))
            local moduleConf = CommonUtils.GetConfigAllMess('module')[JUMP_MODULE_DATA.BOX] or {}
            if checkint(data.restaurantLevel)  >= checkint(moduleConf.openRestaurantLevel) then
                descr =  string.format(__('包厢等级:%s'), data.restaurantLevel)
            else
                descr =  __('包厢尚未解锁')
            end
        else
            self:GetViewComponent():CreateFishIcon(tipLayer, data)
            if checkint(data.fishPlaceLevel)  > 0  then
                descr =  string.format(__('钓场等级:%s'), data.fishPlaceLevel)
            else
                descr =  __('钓场尚未解锁')
            end
        end
        display.commonLabelParams(descLabel, {text = descr  , ap = cc.p(0, 0.7)})
        display.commonLabelParams(friendLvLabel, {text = data.level or 1})
        pCell:setTag(index)
	end,__G__TRACKBACK__)
    return pCell
end


--==============================--
--desc: 留言簿数据源
--time:2017-09-22 04:43:27
--@p_convertview:
--@idx:
--@return 
--==============================
function LobbyFriendMediator:OnMsgBookDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateCell(2)
    end
    
    xTry(function()
        local cellViewData = pCell.viewData
        local descLabel = cellViewData.descLabel
        local nameLabel = cellViewData.nameLabel
        local timeLabel = cellViewData.timeLabel
        local headerButton = cellViewData.headerButton
        local friendLvLabel = cellViewData.friendLvLabel




        local msg           = self.messages[index]
        local messageType   = msg.messageType
        local friendName    = msg.friendName
        local friendAvatar  = msg.friendAvatar or ''
        local avatarFrame   = msg.friendAvatarFrame or ''

        display.commonLabelParams(timeLabel, {text = tostring(os.date("%Y-%m-%d %H:%M:%S", checkint(msg.createTime)))})
        display.commonLabelParams(nameLabel, {text = tostring(friendName)})
        display.commonLabelParams(descLabel, {text = self:GetMsgByMessageType(messageType, friendName)})
        display.commonLabelParams(friendLvLabel, {text = checkint(msg.friendLevel)})
        headerButton.headerSprite:setWebURL(friendAvatar)
        headerButton:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(avatarFrame)))
        pCell:setTag(index)
	end,__G__TRACKBACK__)

    return pCell
end
function LobbyFriendMediator:GetMsgByMessageType(messageType, name)
    if self.visitType == VISIT_TYPE.LOBBY_TYPE then
        local desc = restaurantVisitConf[tostring(messageType)]
        return string.fmt(tostring(desc), {_player_name_ = tostring(name)})
    elseif self.visitType == VISIT_TYPE.FISH_TYPE  then

        if messageType == FISH_VIST_TYPE.ADD_FISH_CARD_TYPE then
            return string.fmt(__('_name_ 在你钓场钓鱼') , {_name_ = name})
        elseif messageType == FISH_VIST_TYPE.KICK_FISH_CARD_TYPE then
            return string.fmt(__('你的飨灵从 _name_ 的钓场返回了') , {_name_ = name})
        end
    end
end
--==============================--
--desc: 好友列表点击事件
--time:2017-09-22 04:46:08
--@sender:
--@return 
--==============================
function LobbyFriendMediator:OnCellBgAction(sender)
    PlayAudioByClickNormal()
    local cell = sender:getParent():getParent()
    local index = cell:getTag()

    if index == self.friendCellIndex then return end
    if self.visitType == VISIT_TYPE.FISH_TYPE then
        local data = self.friendList[index]
        if checkint(data.fishPlaceLevel) <= 0   then
            app.uiMgr:ShowInformationTips(__('好友钓场尚未解锁'))
            return
        end
    elseif self.visitType == VISIT_TYPE.PRIVATEROOM_TYPE then
        local data = self.friendList[index]
        local moduleConf = CommonUtils.GetConfigAllMess('module')[JUMP_MODULE_DATA.BOX] or {}
        if checkint(data.restaurantLevel) < checkint(moduleConf.openRestaurantLevel) then
            app.uiMgr:ShowInformationTips(__('好友包厢尚未解锁'))
            return 
        end
        self:updateCellBgSelectState(cell, self.friendCellIndex)
        self.friendCellIndex = index
    else
        self:updateCellBgSelectState(cell, self.friendCellIndex)
        self.friendCellIndex = index
    end
   

    local friendId = self.friendList[index] and checkint(self.friendList[index].friendId) or -1
    
    self:enterFriendAvatar(friendId)
    -- if  uiMgr:GetCurrentScene():GetDialogByTag(123456) then
    --     -- self:enterFriendDesc(index)
    --     uiMgr:GetCurrentScene():GetDialogByTag(123456):setVisible(false)
    -- end
end

--==============================--
--desc: 官方帐号按钮点击事件
--==============================
function LobbyFriendMediator:onClickOfficialButtonHandler_(sender)
    PlayAudioByClickNormal()

    local officialId = -1
    if officialId == self.friendCellIndex then return end
    
    self:updateCellBgSelectState(nil, self.friendCellIndex)
    self.friendCellIndex = officialId

    self:enterFriendAvatar(officialId)
end

--==============================--
--desc: 好友详情 按钮 点击事件
--time:2017-09-22 05:00:57
--@sender:
--@return 
--==============================
function LobbyFriendMediator:OnFriendDescAction(sender)
    local tag = sender:getTag()
    PlayAudioByClickNormal()
    if tag == 33331 then
        local data = self.friendList[self.descIndex]
        if data then
            local gridView = self.viewData.gridView
            local cell = gridView:cellAtIndex(self.descIndex - 1)
            -- 1。 更新好友cell  选中装填
            self:updateCellBgSelectState(cell, self.friendCellIndex)
            -- 2. 更新 好友cell 下标
            self.friendCellIndex = self.descIndex
            self:enterFriendAvatar(data.friendId)
        end
    elseif tag == 33332 then
        uiMgr:ShowInformationTips(__('未开放'))
    elseif tag == 33333 then
        uiMgr:ShowInformationTips(__('未开放'))
    elseif tag == 33334 then
        uiMgr:ShowInformationTips(__('未开放'))
    elseif tag == 33335 then
        uiMgr:ShowInformationTips(__('未开放'))
    elseif tag == 33336 then
        uiMgr:ShowInformationTips(__('未开放'))
    end
end

--==============================--
--desc: 前往留言簿
--time:2017-09-22 05:03:18
--@return 
--==============================--
function LobbyFriendMediator:OnMessageBookAction()
    -- 1. 发送请求 留言簿 接口
    -- self:GetFacade():DispatchObservers(SIGNALNAMES.SIGNALNAME_FRIEND_MESSAGEBOOK)
    --
    PlayAudioByClickNormal()
    if self.visitType == VISIT_TYPE.LOBBY_TYPE then
        self:SendSignal(COMMANDS.COMMANDS_FRIEND_MESSAGEBOOK)
    elseif self.visitType == VISIT_TYPE.FISH_TYPE then
        self:SendSignal(POST.FISHPLACE_FRIENDS_FISH_LOG.cmdName , {})
    end


end

function LobbyFriendMediator:OnAddFriendAction()
    -- local AvatarMediator = self:GetFacade():RetrieveMediator('AvatarMediator')
    -- if AvatarMediator then
    --     AvatarMediator:GetViewComponent().viewData.friendBtn:setVisible(false)
    -- end
    self:GetFacade():DispatchObservers(FRIEND_UPDATE_LOBBY_FRIEND_BTN_STATE, {showBtn = false})
    self:GetFacade():UnRegsitMediator(NAME)

    local mediator = require( 'Game.mediator.FriendMediator' ).new({friendListType = FriendListViewType.ADD_FRIENDS})
    self:GetFacade():RegistMediator(mediator)
end

function LobbyFriendMediator:getCellsByFriendData(data)
    local gridView = self.viewData.gridView
    
    local friendDatas = {}
    for i, v in ipairs(checktable(data)) do
        for ii,vv in ipairs(checktable(self.friendList)) do
           
            if vv.friendId == v.friendId then
                local restaurantBug = v.restaurantBug
                local restaurantQuestEvent = v.restaurantQuestEvent
                if restaurantBug then
                    self.friendList[ii].restaurantBug = restaurantBug
                end
                if restaurantQuestEvent then
                    self.friendList[ii].restaurantQuestEvent = restaurantQuestEvent
                end
               
                table.insert(friendDatas, {index = ii, cell = gridView:cellAtIndex(ii - 1), restaurantBug = self.friendList[ii].restaurantBug, restaurantQuestEvent = self.friendList[ii].restaurantQuestEvent})
                break
            end
            
        end
        
    end

    return friendDatas
end

nodePosToWorldPos = function (node, anc)
    local x,y = node:getPosition()
    local pp = cc.p(x, y)
    pp = node:convertToWorldSpaceAR(cc.p(0,0))
    local anchor = anc or node:getAnchorPoint()
    local size = node:getContentSize()
    local tx = checkint(pp.x - size.width * (anchor.x - 0.5))
    local ty = checkint(pp.y - size.height * (anchor.y - 0.5))

    return cc.p(tx, ty)
end

getOnlineCount = function (list)
    local onlineCount = 0
    for i,v in ipairs(list) do
        local isOnline = v.isOnline
        if isOnline == 1 then
            onlineCount = onlineCount + 1
        end
    end
    return onlineCount
end

getRestaurantBugState = function (cmd)
    local restaurantBug = nil
    if cmd == NetCmd.RequestRestaurantBugClear then
        restaurantBug = 1
    end
    if cmd == NetCmd.RequestRestaurantBugAppear then
        restaurantBug = 2
    end
    if cmd == NetCmd.RequestRestaurantBugHelp then
        restaurantBug = 3
    end
    return restaurantBug
end

getRestaurantQuestEventState = function (cmd)
    local restaurantQuestEvent = nil
    if cmd == NetCmd.Request2027 then
        restaurantQuestEvent = 1    
    end
    if cmd == NetCmd.RequestRestaurantQuestEventHelp then
        restaurantQuestEvent = 2
    end
    if cmd == NetCmd.RequestRestaurantQuestEventFighting then
        restaurantQuestEvent = 3
    end
    return restaurantQuestEvent
end

getCellIndexByFriendId = function (friendId, friendList)
    for i,v in ipairs(friendList) do
        if friendId == v.friendId then
            return i
        end
    end
    return -1
end

function LobbyFriendMediator:initFriendIndexState()
    if checkint(self.friendCellIndex) > 0 then
        local gridView = self.viewData.gridView
        local cell = gridView:cellAtIndex(self.friendCellIndex - 1)
        self:updateSelectState(cell, false)
    end
    self.descIndex = -1
    self.friendCellIndex = 0
end

function LobbyFriendMediator:OnRegist(  )
    local AvatarCommand = require( 'Game.command.AvatarCommand')
    local FriendCommand = require('Game.command.FriendCommand')
    regPost(POST.FISHPLACE_FRIENDS_FISH_LOG)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Friend_List, FriendCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_FRIEND_MESSAGEBOOK, AvatarCommand)

    -- 第一次进入好友界面 才主动请求
    if self.args.isFirstLookFriend then self:enterLayer() end
end

function LobbyFriendMediator:OnUnRegist(  )
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Friend_List)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_FRIEND_MESSAGEBOOK)
    unregPost(POST.FISHPLACE_FRIENDS_FISH_LOG)
    local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)
    scene:RemoveDialogByTag(123456)
end

return LobbyFriendMediator