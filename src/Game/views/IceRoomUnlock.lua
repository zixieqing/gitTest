--[[
冰箱人物解锁页面View
--]]
local IceRoomUnlock = class('IceRoomUnlock', function()
	local node = CLayout:create()
	node.name = 'Game.views.IceRoomUnlock'
	node:enableNodeEvents()
    return node
end)

local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr = shareFacade:GetManager("UIManager")

local RES_DICT = {
	BG        = 'ui/common/common_bg_3.png',
}

local IceRoomListNode = require("Game.views.IceRoomListNode")

local dataMgr = shareFacade:GetManager("DataManager")
local unlockConfigs = dataMgr:GetConfigDataByFileName("icePlaceUnlock", "iceBink")

function IceRoomUnlock:ctor(...)
    self.arg = unpack({...})
    self:setContentSize(display.size)
    local function CreateView()
        local contentView = CLayout:create(display.size)
        -- display.commonUIParams(contentView, {ap = display.CENTER_TOP, po = cc.p(display.cx, 0)})
        -- self:addChild(contentView,2)
        local size = cc.size(522,594)
        local view = CLayout:create(size)
        view:setContentSize(size)
        --添加标题
        local bg = display.newImageView(_res(RES_DICT.BG), size.width * 0.5, size.height * 0.5)
        display.commonUIParams(bg, {ap = display.CENTER_BOTTOM, po = cc.p(size.width * 0.5, 0)})
        view:addChild(bg)

        local titleBg = display.newButton(bg:getContentSize().width * 0.5, bg:getContentSize().height - 2, {n = _res('ui/common/common_bg_title_2.png'), enable = false})
        display.commonUIParams(titleBg, {ap = display.CENTER_TOP})
        display.commonLabelParams(titleBg, {ttf = true, font = TTF_GAME_FONT, text = __('冰场'), fontSize = 24, color = '#ffffff',offset = cc.p(0, -2)})
        bg:addChild(titleBg,2)

        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setOnClickScriptHandler(function(sender)
            self:runAction(cc.RemoveSelf:create())
        end)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
        eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
        self:addChild(eaterLayer, -1)

        display.commonUIParams(view, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height - NAV_BAR_HEIGHT - 24)})
        contentView:addChild(view, 10)

        local closeBtn = display.newButton(0, 0, {ap = display.LEFT_TOP,n = _res('ui/common/common_btn_quit.png'), cb = function(sender)
            sender:setEnabled(false)
            self:runAction(cc.RemoveSelf:create())
        end})
        display.commonUIParams(closeBtn, {ap = display.LEFT_TOP,po = cc.p(display.cx + size.width * 0.5 - 10,display.height - NAV_BAR_HEIGHT + 34)})
        contentView:addChild(closeBtn, 20)
        --添加listview列表
        local titleLabel = display.newLabel(size.width * 0.5, size.height , {ap = display.CENTER_TOP})
        display.commonLabelParams(titleLabel, {text = __("解锁更多空位供飨灵休养生息"),hAlign = display.TAC, w = 480 ,  fontSize = 20, color = "4c4c4c"})
        view:addChild(titleLabel, 2)
        local listList = CListView:create(cc.size(494,500))
        listList:setDirection(eScrollViewDirectionVertical)
        display.commonUIParams(listList, {ap = display.CENTER_TOP, po = cc.p(size.width * 0.5, size.height - 70)})
        view:addChild(listList)
        --添加解锁扩容的按钮

        local yy = - 20
        local closeLabel = display.newButton(size.width * 0.5 ,yy,{
            n = _res('ui/common/common_bg_black.png'),
        })
        closeLabel:setEnabled(false)
        display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
        view:addChild(closeLabel,10)
        return {
            contentView    = contentView,
            closeBtn       = closeBtn,
            itemList       = listList,
        }
    end
    self.viewData = CreateView()
    display.commonUIParams(self.viewData.contentView, {ap = display.CENTER_TOP, po = cc.p(display.cx, 0)})
    self:addChild(self.viewData.contentView,2)
    self.viewData.contentView:runAction(cc.EaseOut:create(cc.MoveTo:create(0.1,cc.p(display.cx, display.height)), 0.1))
end

function IceRoomUnlock:FreshUI(roomId, datas)
    self.viewData.itemList:removeAllNodes() --移除所有再更新
    self.arg.rooms = datas
    self.arg.roomId = roomId
    local datas = self.arg.rooms[tostring(self.arg.roomId)]
    local source = {}
    local beds = checktable(datas.icePlaceBed)
    for id,v in pairs(beds) do
        v.id = id
        table.insert( source,v )
    end
    sortByMember(source, "newVigour")
    local openNo = checkint(datas.icePlaceBedNum)
    if openNo == 0 then
        openNo = checkint(unlockConfigs[tostring(roomId)].unlockInitNum)
    end
    for i=1,8 do
        if i <= openNo then
            --已解锁的状态
            if source[i] then
                local viewNode = IceRoomListNode.new({state = "opened", data = {roomId = self.arg.roomId, id = i, cardData = source[i]}}) --将要解锁的页面
                self.viewData.itemList:insertNodeAtLast(viewNode)
                viewNode:StartInAction(i)
            else
                local viewNode = IceRoomListNode.new({state = "wait", data = {roomId = self.arg.roomId, id = i}}) --将要解锁的页面
                self.viewData.itemList:insertNodeAtLast(viewNode)
                viewNode:StartInAction(i)
            end
        elseif i == (openNo + 1) then
            --将要解锁的状态
            local viewNode = IceRoomListNode.new({state = "open", data = {roomId = self.arg.roomId, id = i}}) --将要解锁的页面
            self.viewData.itemList:insertNodeAtLast(viewNode)
            viewNode:StartInAction(i)
        else
            --未解锁
            local viewNode = IceRoomListNode.new({state = "locked", data = {roomId = self.arg.roomId, id = i}})
            self.viewData.itemList:insertNodeAtLast(viewNode)
            viewNode:StartInAction(i)
        end
        -- if i > table.nums(source) then
        --     --锁定的数据
        --     local viewNode = IceRoomListNode.new({lock = true, data = {}})
        --     listList:insertNodeAtLast(viewNode)
        --     viewNode:StartInAction(i)
        -- else
        --     local viewNode = IceRoomListNode.new({lock = false, data = source[i]})
        --     listList:insertNodeAtLast(viewNode)
        --     viewNode:StartInAction(i)
        -- end
    end
    self.viewData.itemList:reloadData()
end

function IceRoomUnlock:onEnter(  )
    self:FreshUI(self.arg.roomId, self.arg.rooms)
end
return IceRoomUnlock
