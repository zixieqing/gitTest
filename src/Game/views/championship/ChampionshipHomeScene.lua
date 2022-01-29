--[[
 * author : kaishiqi
 * descpt : 武道会 - 首页场景
]]
local CommonMoneyBar        = require('common.CommonMoneyBar')
local ChampionshipHomeScene = class('ChampionshipHomeScene', require('Frame.GameScene'))

local RES_DICT = {
    --            = top
    COM_BACK_BTN  = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR = _res('ui/common/common_title.png'),
    COM_TIPS_ICON = _res('ui/common/common_btn_tips.png'),
    --            = center
    BG_IMAGE      = _res('ui/championship/home/budo_bg_common_bg.jpg'),
    DOOR_SPINE    = _spn('ui/championship/home/budo_vs_door'),
}

local DOOR_ANIMATES = {
    IDLE  = 'idle',
    HIDE  = 'stop',
    CLOSE = 'play1',
    OPEN  = 'play2',
}


function ChampionshipHomeScene:ctor(args)
    self.super.ctor(self, 'Game.views.championship.ChampionshipHomeScene')

    -- create view
    self.viewData_ = ChampionshipHomeScene.CreateView()
    self:addChild(self.viewData_.view)

    -- add listener
    ui.bindSpine(self:getViewData().doorSpine, handler(self, self.onDoorSpineCompleteHandler_))
    
    -- update views
    self:getViewData().maskLayer:setVisible(false)
end


function ChampionshipHomeScene:getViewData()
    return self.viewData_
end


function ChampionshipHomeScene:showUI(endCB)
    local viewData = self:getViewData()
    viewData.topLayer:setPosition(viewData.topLayerHidePos)
    viewData.titleBtn:setPosition(viewData.titleBtnHidePos)
    viewData.titleBtn:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.titleBtnShowPos)))
    
    local actTime = 0.2
    self:runAction(cc.Sequence:create({
        cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerShowPos)),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    }))
end


function ChampionshipHomeScene:closeDoor(closeCB)
    self.closeDoorCB_ = closeCB
    self:getViewData().maskLayer:setVisible(true)
    self:getViewData().doorSpine:addAnimation(0, DOOR_ANIMATES.CLOSE, false)
end
function ChampionshipHomeScene:openDoor(openCB)
    self.openDoorCB_ = openCB
    self:getViewData().maskLayer:setVisible(true)
    self:getViewData().doorSpine:setAnimation(0, DOOR_ANIMATES.OPEN, false)
end


-------------------------------------------------
-- handler

function ChampionshipHomeScene:onDoorSpineCompleteHandler_(event)
    local eventName = event and event.animation or ''

    if eventName == DOOR_ANIMATES.CLOSE then
        if self.closeDoorCB_ then
            self.closeDoorCB_()
        end

    elseif eventName == DOOR_ANIMATES.OPEN then
        self:getViewData().maskLayer:setVisible(false)
        if self.openDoorCB_ then
            self.openDoorCB_()
        end
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipHomeScene.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)
    
    -- bg / block layer
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos}),
        ui.layer({color = cc.c4b(0,0,0,0), enable = true}),
    })
    

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- content layer
    local contentLayer = ui.layer()
    centerLayer:add(contentLayer)


    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('凌云争锋'), offset = cc.p(0,-10)})
    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    -- money bar
    local moneyBar = CommonMoneyBar.new()
    moneyBar:reloadMoneyBar({FOOD.GOODS.DEFINE.CHAMPIONSHIP_CURRENCY_ID, DIAMOND_ID}, true)
    topLayer:add(moneyBar)


    ------------------------------------------------- [mask]
    local maskLayer = ui.layer({color = cc.r4b(0), enable = true})
    view:add(maskLayer)

    -- door spine
    local doorSpine = ui.spine({p = cpos, path = RES_DICT.DOOR_SPINE, init = DOOR_ANIMATES.HIDE, loop = false})
    maskLayer:add(doorSpine)
    

    return {
        view            = view,
        --              = top
        topLayer        = topLayer,
        topLayerHidePos = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos = cc.p(topLayer:getPosition()),
        titleBtn        = titleBtn,
        titleBtnHidePos = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos = cc.p(titleBtn:getPosition()),
        backBtn         = backBtn,
        --              = center
        contentLayer    = contentLayer,
        --              = mask
        maskLayer       = maskLayer,
        doorSpine       = doorSpine,
    }
end


return ChampionshipHomeScene
