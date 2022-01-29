--[[
 * author : panmeng
 * descpt : 猫咪互动
]]
local CatModuleInteractView = class('CatModuleInteractView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleInteractView', enableEvent = true})
end)

local RES_DICT = {
    TITLE_BAR   = _res('ui/common/common_bg_title_2.png'),
    LIST_FRAME  = _res('ui/catHouse/friend/cat_tips_bg.png'),
    VIEW_FRAME  = _res('ui/common/common_bg_7.png'),
    BTN_DRIVE   = _res('ui/catHouse/friend/cat_house_ico_drive.png'),
    BTN_PLAY    = _res('ui/catHouse/friend/cat_house_ico_play.png'),
    BTN_FEED    = _res('ui/catHouse/friend/cat_house_ico_feed.png'),
    BG_ACTION   = _res('ui/catHouse/friend/team_frame_gongneng.png'),
}


function CatModuleInteractView:ctor(args)
    -- create view
    self.viewData_ = CatModuleInteractView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatModuleInteractView:getViewData()
    return self.viewData_
end


function CatModuleInteractView:updatePageView(friendCatData)
    local friendData = CommonUtils.GetFriendData(friendCatData.friendId)
    self:getViewData().titleBar:updateLabel({text = string.fmt(__("_name_的猫咪"), {_name_ = friendData.name}), paddingW = 50})
    
    local catSpineNode  = CatHouseUtils.GetCatSpineNode({catData = {gene = friendCatData.gene, catId = friendCatData.catId, age = friendCatData.age}})
    self:getViewData().catLayer:addList(catSpineNode):alignTo(nil, ui.cc)
    self:getViewData().catSpineNode = catSpineNode

    local isBindDriver = CatHouseUtils.IsHaveDisableDisperseByGeneList(friendCatData.gene)
    self:getViewData().driverBtn:setVisible(not isBindDriver)
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleInteractView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black layer| block layer | frame layer| cat layer
    local frameLayer = ui.layer({bg = RES_DICT.VIEW_FRAME})
    local frameSize  = frameLayer:getContentSize()
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.layer({size = frameSize, color = cc.r4b(0), enable = true}),
        frameLayer,
        ui.layer({bg = RES_DICT.LIST_FRAME, mb = 40}),
    })
    ui.flowLayout(cpos, backGroundGroup, {type = ui.flowC, ap = ui.cc})

    -- title bar
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D3, offset = cc.p(0,-2)})
    frameLayer:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -4})

    -- btn Group
    local btnDefines = {
        {text = __("喂食"), n = RES_DICT.BTN_FEED},
        {text = __('玩耍'), n = RES_DICT.BTN_PLAY},
        {text = __("驱赶"), n = RES_DICT.BTN_DRIVE},
    }
    local funcBtnGroup = {}
    for _, btnDefine in ipairs(btnDefines) do
        local button = ui.button({n = RES_DICT.BG_ACTION})
        local icon   = ui.image({img = btnDefine.n})
        button:addList(icon):alignTo(nil, ui.cc)

        local descr = ui.label({fnt = FONT.D14, text = btnDefine.text, reqW = 80})
        button:addList(descr):alignTo(nil, ui.cb)

        table.insert(funcBtnGroup, button)
    end
    frameLayer:addList(funcBtnGroup)
    ui.flowLayout(cc.rep(cc.sizep(frameLayer, ui.lb), 40, 30), funcBtnGroup, {ap = ui.lb, type = ui.flowH, gapW = 10})


    return {
        view       = view,
        blockLayer = backGroundGroup[1],
        --         = center
        feedBtn    = funcBtnGroup[1],
        playBtn    = funcBtnGroup[2],
        driverBtn  = funcBtnGroup[3],
        titleBar   = titleBar,
        catLayer   = backGroundGroup[4],
    }
end


return CatModuleInteractView
