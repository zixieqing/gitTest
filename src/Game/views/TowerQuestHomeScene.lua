--[[
 * author : kaishiqi
 * descpt : 爬塔 - 首页场景
]]
local TowerQuestHomeScene = class('TowerQuestHomeScene', require('Frame.GameScene'))

local RES_DICT = {
    TITLE_BAR = 'ui/common/common_title.png',
    BTN_TIPS  = 'ui/common/common_btn_tips.png',
    SCORE_BAR = 'ui/tower/tower_btn_myscore.png',
    BTN_RANK  = 'ui/home/nmain/main_btn_rank.png',
    BTN_BACK  = 'ui/common/common_btn_back.png',
    BTN_GUIDE = 'guide/guide_ico_book.png',
}

local CreateView = nil


function TowerQuestHomeScene:ctor(...)
    self.super.ctor(self, 'Game.views.TowerQuestHomeScene')

    xTry(function ( )
        self.viewData_ = CreateView()
        self:AddUILayer(self.viewData_.view)

        self.viewData_.topUILayer:setPositionY(100)
        self.viewData_.titleBtn:setPositionY(display.height + 190)
	end, __G__TRACKBACK__)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    local topUILayer = display.newLayer()
    view:addChild(topUILayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res(RES_DICT.BTN_BACK)})
    topUILayer:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = _res(RES_DICT.TITLE_BAR), ap = display.LEFT_TOP})
    local titleBtnLabelSize = display.getLabelContentSize(titleBtn:getLabel())
    if titleBtnLabelSize.width > 180 then
        display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('邪神遗迹'), reqW = 180, offset = cc.p(-20,-10)}))
    else
        display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('邪神遗迹'), offset = cc.p(0,-10)}))
    end

    topUILayer:addChild(titleBtn)

    local titleSize = titleBtn:getContentSize()
    titleBtn:addChild(display.newImageView(_res(RES_DICT.BTN_TIPS), titleSize.width - 30, titleSize.height/2 - 10))

    -- guide button 
    local guideBtn = display.newButton(464 + display.SAFE_L, display.height - 42, {n = _res(RES_DICT.BTN_GUIDE)})
    display.commonLabelParams(guideBtn, fontWithColor(14, {text = __('指南'), fontSize = 25, offset = cc.p(10,-18)}))
    topUILayer:addChild(guideBtn)

    -- maxFloor label
    local scoreBarSize = cc.size(310 + display.width - display.SAFE_R, 66)
    topUILayer:addChild(display.newImageView(_res(RES_DICT.SCORE_BAR), display.width, size.height - 10, {ap = display.RIGHT_TOP, scale9 = true, size = scoreBarSize, capInsets = cc.rect(235,0,1,1)}))
    topUILayer:addChild(display.newLabel(display.SAFE_R - 80, size.height - 28, fontWithColor(9, {ap = display.RIGHT_CENTER, text = __('最高记录') ,reqW = 200 })))

    local maxFloorLabel = display.newLabel(display.SAFE_R - 80, size.height - 63, fontWithColor(9, {ap = display.RIGHT_CENTER}))
    topUILayer:addChild(maxFloorLabel)

    -- rank button
    local rankBtn = display.newButton(display.SAFE_R + 5, size.height, {n = _res(RES_DICT.BTN_RANK), ap = display.RIGHT_TOP})
    display.commonLabelParams(rankBtn, fontWithColor(14, {fontSize = 23, text = __('排行榜'), offset = cc.p(0, -40  )  , w = 110, hAlign = display.TAC , reqW = 75 }))
    topUILayer:addChild(rankBtn)

    return {
        view          = view,
        topUILayer    = topUILayer,
        backBtn       = backBtn,
        titleBtn      = titleBtn,
        guideBtn      = guideBtn,
        titleBtnX     = titleBtn:getPositionX(),
        rankBtn       = rankBtn,
        maxFloorLabel = maxFloorLabel,
    }
end


function TowerQuestHomeScene:getViewData()
    return self.viewData_
end


function TowerQuestHomeScene:showUI(endCB)
    local actTime  = 0.4

    self:runAction(cc.Sequence:create({
        cc.TargetedAction:create(self.viewData_.topUILayer, cc.MoveTo:create(actTime, cc.p(0, 0))),
        cc.TargetedAction:create(self.viewData_.titleBtn, cc.EaseBounceOut:create(cc.MoveTo:create(1, cc.p(self.viewData_.titleBtnX, display.height + 2))) ),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    }))
end


return TowerQuestHomeScene
