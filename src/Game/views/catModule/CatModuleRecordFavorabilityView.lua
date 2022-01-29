local VIEW_SIZE = cc.size(960, 600)
local CatModuleRecordFavorabilityView = class('CatModuleRecordFavorabilityView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleRecordFavorabilityView', enableEvent = true, size = VIEW_SIZE})
end)

local RES_DICT = {
    TITLE_BG   = _res('ui/catModule/catRecord/grow_cat_record_love_bg_tips.png'),
    FRAME_BG   = _res('ui/catModule/catRecord/grow_cat_record_love_bg_list.png'),
    SORT_IMG   = _res('ui/catModule/catRecord/grow_cat_record_love_btn_down.png'),
    DETAIL_BTN = _res('ui/catModule/catRecord/grow_cat_record_love_btn_friend.png'),
    DEL_BTN    = _res('avatar/ui/decorate_btn_delete.png'),
    LINE_IMG   = _res('ui/catModule/catRecord/grow_cat_record_love_line_list.png'),
    EMPTY_BG   = _res("ui/catModule/catRecord/grow_cat_record_love_bg_book_empty.png"),
}


function CatModuleRecordFavorabilityView:ctor(args)
    -- create view
    self.viewData_ = CatModuleRecordFavorabilityView.CreateView()
    self:addChild(self.viewData_.view)

    self:getViewData().friendGridView:resetCellCount(5)
end


function CatModuleRecordFavorabilityView:getViewData()
    return self.viewData_
end

function CatModuleRecordFavorabilityView:setFriendDataNum(dataNum)
    self:getViewData().lineImg:setVisible(dataNum > 0)
    self:getViewData().emptyTip:setVisible(dataNum <= 0)
    self:getViewData().friendGridView:resetCellCount(dataNum)
end


function CatModuleRecordFavorabilityView:updateFriendCell(cellIndex, cellViewData, friendId)
    local friendData = CommonUtils.GetFriendData(friendId)
    if not friendData or next(friendData) == nil then
        return
    end
    cellViewData.nameLabel:updateLabel({text = friendData.name, reqW = 230})
    cellViewData.lvlLabel:updateLabel({text = string.fmt(__("猫屋等级:_level_"), {_level_ = friendData.houseLevel}), reqW = 230})
    cellViewData.playerHeadNode:RefreshSelf({avatar = friendData.avatar, level = friendData.level, avatarFrame = friendData.avatarFrame})
    cellViewData.playerHeadNode:setTag(friendId)
    cellViewData.detailBtn:setTag(friendData.friendId)
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CatModuleRecordFavorabilityView.CreateFriendCell(cellParent)
    local size = cellParent:getContentSize()
    local view = ui.layer({bg = RES_DICT.FRAME_BG})
    cellParent:addList(view):alignTo(nil, ui.cc, {offsetX = 40})

    local frameGroup = view:addList({
        ui.layer({size = cc.size(80, 80), zorder = 1}),
        ui.layer({size = cc.size(240, 80)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.lt), 30, -40), frameGroup, {type = ui.flowH, ap = ui.lt, gapW = 0})

    local infoLayer = frameGroup[2]
    local infoGroup = infoLayer:addList({
        ui.label({fnt = FONT.D4, color = "#a66b4d", text = "--", mt = 5, ap = ui.lc}),
        ui.label({fnt = FONT.D9, color = "#5c5b59", text = "--", mt = 12, ap = ui.lc}),
    })
    ui.flowLayout(cc.rep(cc.sizep(infoLayer, ui.lt), 13, 0), infoGroup, {type = ui.flowV, ap = ui.lb})

    local btnDetail = ui.button({n = RES_DICT.DETAIL_BTN}):updateLabel({fnt = FONT.D6, color = "#cdb78f", text = __("好友详情"), reqW = 190})
    view:addList(btnDetail):alignTo(nil, ui.cb, {offsetY = 40, offsetX = -40})

    local playerLayer = frameGroup[1]
    local playerHeadNode  = require('common.FriendHeadNode').new({enable = true, scale = 0.5, showLevel = true, callback = function ( sender )
        local mediator = require("Game.mediator.PersonInformationMediator").new({playerId = sender:getTag()})
        AppFacade.GetInstance():RegistMediator(mediator)
    end})
    playerLayer:addList(playerHeadNode):alignTo(nil, ui.cc)

    return {
        view           = view,
        nameLabel      = infoGroup[1],
        lvlLabel       = infoGroup[2],
        playerHeadNode = playerHeadNode,
        detailBtn      = btnDetail,
    }
end

function CatModuleRecordFavorabilityView.CreateView()
    local view = ui.layer({size = VIEW_SIZE})

    local viewFrameGroup = view:addList({
        ui.title({n = RES_DICT.TITLE_BG, ml = -10}):updateLabel({fnt = FONT.D9, color = "#DDBC89", paddingW = 50, text = __("好感度等级达到代数需求才可繁育")}),
        ui.gridView({size = cc.size(930, 480), dir = display.SDIR_V, cols = 2, csizeH = 180, mt = -16}),
    })
    ui.flowLayout(cc.rep(cc.sizep(VIEW_SIZE, ui.lt), 20, -4), viewFrameGroup, {type = ui.flowV, ap = ui.lb, gapH = 20})

    local lineImg = ui.image({img = RES_DICT.LINE_IMG})
    view:addList(lineImg):alignTo(nil, ui.cc)

    local friendGridView = viewFrameGroup[2]
    friendGridView:setCellCreateHandler(CatModuleRecordFavorabilityView.CreateFriendCell)

    local emptyTip = ui.title({img = RES_DICT.EMPTY_BG}):updateLabel({fnt = FONT.D4, color = "#cfc6bb", text = __("尚无好感列表"), reqW = 320, offset = cc.p(50, 5)})
    view:addList(emptyTip):alignTo(nil, ui.cc)

    return {
        view           = view,
        friendGridView = friendGridView,
        progress       = viewFrameGroup[1],
        lineImg        = lineImg,
        emptyTip       = emptyTip,
    }
end


return CatModuleRecordFavorabilityView
