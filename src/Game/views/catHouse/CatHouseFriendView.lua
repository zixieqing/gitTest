--[[
 * author : panmeng
 * descpt : 猫屋 好友 界面
]]
local CatHouseFriendView = class('CatHouseFriendView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseFriendView', enableEvent = true})
end)

local RES_DICT = {
    --           = frame
    TITLE_IMG    = _res('ui/common/common_title_5.png'),
    CARD_BAR_BG  = _res('avatar/ui/card_bar_bg.png'),
    MESSAGE_BOOK = _res('avatar/ui/friends_btn_messagebook.png'),
    BG_IMG       = _res('ui/common/common_bg_botton-m.png'),
    BG_FRAME     = _res('avatar/ui/restaurant_avatar_frame_default.png'),
    LINE_BG      = _res('ui/cards/propertyNew/card_ico_attribute_line.png'),
    --           = friendCell
    CELL_BG      = _res('avatar/ui/restaurant_bg_friends_list.png'),
    CELL_BG_S    = _res('avatar/ui/restaurant_bg_friends_list_selected.png'),
    HEAD_BG      = _res('ui/author/create_roles_head_down_default.png'),
    INVITE_BTN   = _res('ui/catHouse/friend/shop_package_ico_sale.png'),
    TRAVEL_BTN   = _res('ui/catHouse/friend/restaurant_friends_ico_kill_visit.png'),
    TRAVEL_BG    = _res('ui/catHouse/friend/restaurant_friends_ico_kill_insect.png'),
}


function CatHouseFriendView:ctor(args)
    -- create view
    self.viewData_ = CatHouseFriendView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatHouseFriendView:getViewData()
    return self.viewData_
end


function CatHouseFriendView:updateCellSelctedStatue(newSelectedFriend)
    local oldSelectedFriend = checkint(self.selectedFriendId)
    self.selectedFriendId   = checkint(newSelectedFriend)

    for _, cellViewData in pairs(self:getViewData().friendTableView:getCellViewDataDict()) do
        local firendId = checkint(cellViewData.toggleFrameBtn:getTag())
        if firendId == checkint(oldSelectedFriend) then
            cellViewData.toggleFrameBtn:setChecked(false)
        elseif firendId == checkint(newSelectedFriend) then
            cellViewData.toggleFrameBtn:setChecked(true)
        end
    end
end


function CatHouseFriendView:updateFriendCellViewData(cellIndex, cellViewData, friendData)
    cellViewData.friendNameLabel:setString(tostring(friendData.name))

    local outCatUuid  = 0
    local isHasOutCat = false
    for _, catModule in pairs(app.catHouseMgr:getCatsModelMap()) do
        if catModule:getOutFriendId() == friendData.friendId then
            isHasOutCat = true
            outCatUuid  = catModule:getUuid()
            break
        end
    end
    cellViewData.onTravelBtn:setVisible(isHasOutCat)
    cellViewData.onTravelBtn.outCatUuid = outCatUuid

    cellViewData.headNode:RefreshUI({
        playerId    = checkint(friendData.friendId),
        avatar      = tostring(friendData.avatar),
        avatarFrame = tostring(friendData.avatarFrame),
        playerLevel = checkint(friendData.level),
        callback    = function()
            local mediator = require("Game.mediator.PersonInformationMediator").new({playerId = friendData.friendId})
            AppFacade.GetInstance():RegistMediator(mediator)
        end,
    })
    cellViewData.toggleFrameBtn:setChecked(friendData.friendId == app.catHouseMgr:getHouseOwnerId())
    cellViewData.toggleFrameBtn:setTag(friendData.friendId)
    cellViewData.buttonLayer:setTag(friendData.friendId)
    cellViewData.view:setTag(cellIndex)
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseFriendView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- block layer / block layer/ layer
    local FRAME_SIZE      = cc.size(412, display.height)
    local backGroundGroup = view:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer({size = FRAME_SIZE, p = cc.p(display.SAFE_R, 0), ap = ui.rb, color = cc.r4b(0), enable = true}),
        ui.layer({size = FRAME_SIZE, p = cc.p(display.SAFE_R, 0), ap = ui.rb}),
    })

    local frameLayer = backGroundGroup[3]
    local bgGroup    = frameLayer:addList({
        ui.image({img = RES_DICT.BG_IMG, scale9 = true, size = FRAME_SIZE}),
        ui.image({img = RES_DICT.BG_FRAME, scale9 = true, size = FRAME_SIZE}),
    })
    ui.flowLayout(cc.sizep(frameLayer, ui.cc), bgGroup, {type = ui.flowC, ap = ui.cc})
    
    local title = ui.title({img = RES_DICT.TITLE_IMG, scale9 = true}):updateLabel({fnt = FONT.D4, text = __("我的好友"), reqW = 170})
    frameLayer:addList(title):alignTo(nil, ui.ct, {offsetY = -15})

    -- 好友人数
    local friendCount = ui.label({fnt = FONT.D4, text = "--", ap = ui.lt})
    frameLayer:addList(friendCount):alignTo(nil, ui.lt, {offsetY = -70, offsetX = 20})

    -- local messageBtn = ui.button({n = RES_DICT.MESSAGE_BOOK})
    -- frameLayer:addList(messageBtn):alignTo(nil, ui.rt)

    -- local messageTitle = ui.title({bg = RES_DICT.CARD_BAR_BG, scale9 = true}):updateLabel({fnt = FONT.D12, text = __("留言簿"), reqW = 110})
    -- frameLayer:addList(messageTitle):alignTo(nil, ui.cb)

    local lineImg = ui.image({img = RES_DICT.LINE_BG})
    frameLayer:addList(lineImg):alignTo(nil, ui.ct, {offsetY = -100})
    

    -- 好友列表
    local tableViewSize = cc.size(FRAME_SIZE.width  - 20, FRAME_SIZE.height - 110)
    local firendTableView = ui.tableView({size = tableViewSize, csizeH = 93, dir = display.SDIR_V})
    frameLayer:addList(firendTableView):alignTo(nil, ui.cb, {offsetY = 5})

    firendTableView:setCellCreateHandler(CatHouseFriendView.CreateFirendCell)

    return {
        view            = view,
        friendTableView = firendTableView,
        touchLayer      = backGroundGroup[1],
        friendCountLb   = friendCount,
        --messageBook     = messageBtn,
    }
end


function CatHouseFriendView.CreateFirendCell(parent)
    local size = parent:getContentSize()
    local view = ui.layer({size = size})
    parent:add(view)

    local toggleFrameBtn = ui.tButton({n = RES_DICT.CELL_BG, s = RES_DICT.CELL_BG_S})
    view:addList(toggleFrameBtn):alignTo(nil, ui.cc)

    local bgFrameGroup = view:addList({
        ui.layer({size = cc.size(80, 80)}),
        ui.layer({size = cc.resize(size, -100, 0)})
    })
    ui.flowLayout(cc.sizep(size, ui.cc), bgFrameGroup, {type = ui.flowH, ap = ui.cc, gapW = 5})

    local headNode = ui.playerHeadNode({showLevel = true, scale = 0.5})
    bgFrameGroup[1]:addList(headNode):alignTo(nil, ui.cc)

    local infoBgGroup = bgFrameGroup[2]:addList({
        ui.label({fnt = FONT.D11, text = "--", ap = ui.lc}),
        ui.layer({size = cc.resize(size, -110, -50)}),
    })
    ui.flowLayout(cc.sizep(bgFrameGroup[2], ui.lc), infoBgGroup, {type = ui.flowV, ap = ui.lc, gapH = 5})

    local btnGroups = infoBgGroup[2]:addList({
        ui.button({n = RES_DICT.INVITE_BTN}):updateLabel({fnt = FONT.D14, text = __("拜访"), reqW = 70}),
        ui.button({n = RES_DICT.INVITE_BTN}):updateLabel({fnt = FONT.D14, text = __("邀请"), reqW = 70}),
        ui.button({n = RES_DICT.TRAVEL_BTN, ml = -5}),
        ui.button({n = RES_DICT.TRAVEL_BG, ml = -10}),
    })
    ui.flowLayout(cc.sizep(infoBgGroup[2], ui.lc), btnGroups, {type = ui.flowH, ap = ui.lc, gapW = 10})

    return {
        view            = view,
        visitBtn        = btnGroups[1],
        inviteBtn       = btnGroups[2],
        friendNameLabel = infoBgGroup[1],
        headNode        = headNode,
        headLayer       = bgFrameGroup[1],
        toggleFrameBtn  = toggleFrameBtn,
        buttonLayer     = infoBgGroup[2],
        toTravelBtn     = btnGroups[3],
        onTravelBtn     = btnGroups[4],
    }
end


return CatHouseFriendView
