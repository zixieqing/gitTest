--[[
 * author : panmeng
 * descpt : 猫屋邀请界面
]]

local CatHouseEventPopupView = class('CatHouseEventPopupView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseEventPopupView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME  = _res('ui/common/common_bg_7.png'),
    BACK_BTN    = _res('ui/common/common_btn_back.png'),
    TITLE_BAR   = _res('ui/common/common_bg_title_2.png'),
    LIST_FRAME  = _res('ui/common/common_bg_list_3.png'),
    BTN_CANCEL  = _res('ui/common/common_btn_white_default.png'),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
    TIP_BG      = _res('ui/catHouse/home/common_bg_goods.png'),
    HEAD_BG     = _res('ui/author/create_roles_head_down_default.png'),
    NAME_BG     = _res('ui/home/infor/personal_information_bg_name_bg.png'),
    TXT_BG      = _res('ui/catHouse/event/cat_even_time_bg.png'),
}


function CatHouseEventPopupView:ctor(args)
    args = checktable(args)
    -- create view
    self.eventData_ = checktable(args.eventData)
    self.eventType_ = args.eventType or CatHouseUtils.HOUSE_EVENT_TYPE.INVITE
    self.friendId_  = self.eventType_ == CatHouseUtils.HOUSE_EVENT_TYPE.INVITE and self.eventData_.refId or self.eventData_.friendId

    self.confirmCallback_ = args.confirmCallback
    self.ignoreCallback_  = args.ignoreCallback

    self.viewData_ = CatHouseEventPopupView.CreateView()
    self:addChild(self.viewData_.view)

    ui.bindClick(self:getViewData().blackLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmButtonHandler_))
    ui.bindClick(self:getViewData().ignoreBtn, handler(self, self.onClickIgnoreButtonHandler_))
    self:updateView()
    
    if self.eventType_ == CatHouseUtils.HOUSE_EVENT_TYPE.BREED then
        self.breedRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onbreedRefreshUpdateHandler_))
        self.breedRefreshClocker_:start()
    end
end


function CatHouseEventPopupView:getViewData()
    return self.viewData_
end


function CatHouseEventPopupView:updateView()
    local friendData = CommonUtils.GetFriendData(self.friendId_)
    if not friendData then
        return
    end

    local nameLabelSizeW = self:getViewData().nameLabel:getContentSize().width
    self:getViewData().nameLabel:updateLabel({text = tostring(friendData.name), reqW = nameLabelSizeW - 20})
    self:getViewData().levelLabel:setString(string.fmt(__("猫屋等级：_level_"), {_level_ = tostring(friendData.houseLevel)}))
    self:getViewData().headNode:RefreshUI({
        playerId    = checkint(friendData.friendId),
        avatar      = tostring(friendData.avatar),
        avatarFrame = tostring(friendData.avatarFrame),
        playerLevel = checkint(friendData.level),
        callback    = function()
            local mediator = require("Game.mediator.PersonInformationMediator").new({playerId = friendData.friendId})
            AppFacade.GetInstance():RegistMediator(mediator)
        end,
    })

    local eventConf = CONF.CAT_HOUSE.EVENT_TYPE:GetValue(self.eventType_)
    self:getViewData().tipDescrT:updateLabel({text = eventConf.descr, reqW = 480})

    self:getViewData().breedTip:setVisible(self.eventType_ == CatHouseUtils.HOUSE_EVENT_TYPE.BREED)
    self:getViewData().timeTitle:setVisible(self.eventType_ == CatHouseUtils.HOUSE_EVENT_TYPE.BREED)
    self:getViewData().tipDescrT:setPositionY(self.eventType_ == CatHouseUtils.HOUSE_EVENT_TYPE.BREED and 100 or 70)
end


function CatHouseEventPopupView:close()
    if self.breedRefreshClocker_ then
        self.breedRefreshClocker_:stop()
    end
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- handler

function CatHouseEventPopupView:onClickBackButtonHandler_(sender)
    PlayAudioByClickNormal()

    self:close()
end


function CatHouseEventPopupView:onClickConfirmButtonHandler_(sender)
    PlayAudioByClickNormal()

    if self.confirmCallback_ then
        self.confirmCallback_()
    end
    self:close()
end


function CatHouseEventPopupView:onClickIgnoreButtonHandler_(sender)
    PlayAudioByClickNormal()

    if self.ignoreCallback_ then
        self.ignoreCallback_()
    end
    self:close()
end


function CatHouseEventPopupView:onbreedRefreshUpdateHandler_()
    local leftSeconds = self.eventData_.timestamp - os.time()
    if leftSeconds <= 0 then
        self:close()
    else
        self:getViewData().timeTitle:updateLabel({text = CommonUtils.getTimeFormatByType(leftSeconds)})
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseEventPopupView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()

    -- blackLayer | blockLayer | view
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        viewFrameNode,
    })
    ui.flowLayout(cpos, backGroundGroup, {type = ui.flowC, ap = ui.cc})

    ------------------------------------------------- [center]
    local frameGroup = viewFrameNode:addList({
        ui.layer({size = cc.size(viewFrameSize.width - 50, 200)}),
        ui.layer({size = cc.size(viewFrameSize.width - 50, 140), bg = RES_DICT.TIP_BG, scale9 = true}),
        ui.layer({size = cc.size(viewFrameSize.width - 50, 150)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.ct), 0, -45), frameGroup, {type = ui.flowV, ap = ui.cb})

    
    local headNode = ui.playerHeadNode({showLevel = true})
    frameGroup[1]:addList(headNode):alignTo(nil, ui.lc, {offsetX = 50})

    local nameLabel = ui.title({img = RES_DICT.NAME_BG, ap = ui.lc, cut = cc.dir(5,5,5,5), size = cc.size(260,34)}):updateLabel({fnt = FONT.D7, color = "#5b3c25", fontSize = 22, ap = ui.lc, offset = cc.p(-120,0)})
    frameGroup[1]:addList(nameLabel):alignTo(headNode, ui.rc, {offsetX = 30, offsetY = 30})

    local levelLabel = ui.label({fnt = FONT.D6, fontSize = 24, text = "--", ap = ui.lc})
    frameGroup[1]:addList(levelLabel):alignTo(nameLabel, ui.lb, {offsetX = 25, offsetY = -30})

    local tipBg = frameGroup[2]
    local tipLabelGroup = tipBg:addList({
        ui.label({fnt = FONT.D7, color = "#c4514f", fontSize = 24, text = "--", mb = 15}),
        ui.label({fnt = FONT.D9, text = __("邀请倒计时"), color = "#5b3c25"}),
        ui.title({n = RES_DICT.TXT_BG}):updateLabel({fnt = FONT.D9, text = "--:--:--"}),
    })
    ui.flowLayout(cc.sizep(tipBg, ui.cc), tipLabelGroup, {type = ui.flowV, ap = ui.cc})

    -- cancel / confirm button
    local funcBtnGroup = frameGroup[3]:addList({
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __('接受'), reqW = 100}),
        ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __('忽略'), reqW = 100}),
    })
    ui.flowLayout(cc.sizep(frameGroup[3], ui.cc), funcBtnGroup, {ap = ui.cc, type = ui.flowH, gapW = 100})


    return {
        view       = view,
        blackLayer = backGroundGroup[1],
        blockLayer = backGroundGroup[2],
        --         = center
        headNode   = headNode,
        nameLabel  = nameLabel,
        levelLabel = levelLabel,
        tipDescrT  = tipLabelGroup[1],
        breedTip   = tipLabelGroup[2],
        timeTitle  = tipLabelGroup[3], 
        confirmBtn = funcBtnGroup[1],
        ignoreBtn  = funcBtnGroup[2],
    }
end


return CatHouseEventPopupView
