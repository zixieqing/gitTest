--[[
 * author : panmeng
 * descpt : 猫屋选猫
]]
local CatModuleChoiceView = class('CatModuleChoiceView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleChoiceView', enableEvent = true})
end)

local RES_DICT = {
    --             = top
    COM_BACK_BTN   = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR  = _res('ui/common/common_title.png'),
    COM_TIPS_ICON  = _res('ui/common/common_btn_tips.png'),
    --             = center
    BG_IMAGE       = _res('ui/catModule/choose/grow_start_cat.jpg'),
    IMG_TITLE      = _res('ui/catModule/choose/grow_start_cat_head.png'),
    --             = cat cell
    BTN_CONFIRM    = _res('ui/common/common_btn_orange.png'),
    BG_SELECTED    = _res('ui/catModule/choose/cat_light.png'),
    IMG_SHADOW     = _res('ui/catModule/choose/grow_start_cat_shadow.png'),
    --             = anim
    OPEN_VIEW_ANIM = _spn('ui/catModule/choose/anim/cat_grow_start_cat'),
}

local CAT_INFO_ZORDER = {
    CAT_NODE     = 1,
    CAT_BLOCK    = 2,
    CAT_LIGHT    = 3,
    CAT_SELECTED = 4,
    CAT_OPERATOR = 5,
}

function CatModuleChoiceView:ctor(args)
    -- create view
    self.viewData_ = CatModuleChoiceView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatModuleChoiceView:getViewData()
    return self.viewData_
end


function CatModuleChoiceView:showUI(endCB)
    local playTopAnimFunc = function()
        self:getViewData().topLayer:setVisible(true)
        self:getViewData().centerLayer:setVisible(true)

        local viewData = self:getViewData()
        viewData.topLayer:setPosition(viewData.topLayerHidePos)
        -- viewData.titleBtn:setPosition(viewData.titleBtnHidePos)
        -- viewData.titleBtn:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.titleBtnShowPos)))
        
        local actTime = 0.2
        self:runAction(cc.Sequence:create({
            cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerShowPos)),
            cc.CallFunc:create(function()
                if endCB then endCB() end
            end)
        }))
    end

    -- init views
    self:getViewData().topLayer:setVisible(false)
    self:getViewData().centerLayer:setVisible(false)

    local playOpenAnimFunc = function()
        local spine = ui.spine({path = RES_DICT.OPEN_VIEW_ANIM, init = "paly", loop = false})
        self:addList(spine):alignTo(nil, ui.cc)
    
        spine:registerSpineEventHandler(function()
            spine:runAction(cc.RemoveSelf:create())
            playTopAnimFunc()
        end, sp.EventType.ANIMATION_COMPLETE)
    end
    playOpenAnimFunc()
end

-------------------------------------------------
-- public

function CatModuleChoiceView:updateSelectedState(selectedCatId)
    local catNode = self:getCatNodeByCatId(selectedCatId)
    local visible = catNode ~= nil
    self:getViewData().selectedBg:setVisible(visible)
    self:getViewData().confirmBtn:setVisible(visible)

    if catNode ~= nil then
        self:getViewData().selectedBg:alignTo(catNode, ui.cc)
        self:getViewData().confirmBtn:alignTo(catNode, ui.cb)

        for catId, catNode in pairs(self:getViewData().arrCatCell) do
            local zorder = checkint(catId) == checkint(selectedCatId) and 4 or 1
            catNode:setLocalZOrder(zorder)
        end
    end
end

function CatModuleChoiceView:getCatNodeByCatId(catId)
    return self:getViewData().arrCatCell[checkint(catId)]
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatModuleChoiceView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)


    -- bgImg / centerLayer / topLayer
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos, enable = true}),
        ui.layer(),
        ui.layer(),
    })


    ------------------------------------------------- [center]
    local centerLayer = backGroundGroup[2]

    local backLayer = ui.layer({color = cc.c4b(0, 0, 0, 190)})
    centerLayer:addChild(backLayer, CAT_INFO_ZORDER.CAT_BLOCK)

    local selectedBg = ui.image({img = RES_DICT.BG_SELECTED})
    centerLayer:addList(selectedBg, CAT_INFO_ZORDER.CAT_LIGHT)

    -- 根据表的数据，设置当前选中的id
    local initPos    = {cc.p(-400, -140), cc.p(-160, 70), cc.p(160, -70), cc.p(400, 170)}
    local delta      = display.SAFE_RECT.width / CONF.CAT_HOUSE.CAT_INIT:GetLength()
    local arrCatCell = {}

    for index, catInfo in pairs(CONF.CAT_HOUSE.CAT_INIT:GetAll()) do
        local catId        = checkint(catInfo.id)
        local catPosDefine = checktable(initPos[checkint(index)])
        local catCell      = CatModuleChoiceView.CreateCatCell(catInfo, cc.rep(display.center, checkint(catPosDefine.x), checkint(catPosDefine.y)))
        catCell:setTag(catId)
        centerLayer:add(catCell, CAT_INFO_ZORDER.CAT_NODE)
        arrCatCell[catId] = catCell
    end

    local operatorLayer = ui.layer()
    centerLayer:add(operatorLayer, CAT_INFO_ZORDER.CAT_OPERATOR)

    local confirmBtn = ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("确认")})
    operatorLayer:add(confirmBtn)

    local chooseBg    = ui.image({img = RES_DICT.IMG_TITLE})
    operatorLayer:addList(chooseBg):alignTo(nil, ui.ct, {offsetY = 30})
    local chooseTitle = ui.colorBtn({color = cc.r4b(0), size = cc.size(320, 70)}):updateLabel({fnt = FONT.D14, color = "#ffffff", text = __('请选择一只猫咪'), reqW = 260})
    operatorLayer:addList(chooseTitle):alignTo(chooseBg, ui.cb, {offsetY = 80})

    ------------------------------------------------- [top]
    local topLayer = backGroundGroup[3]
    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15})

    -- title button
    -- local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('猫咪养成'), offset = cc.p(0,-10)})
    -- topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})
    -- titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})
   
    return {
        view            = view,
        --              = top
        topLayer        = topLayer,
        topLayerHidePos = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos = cc.p(topLayer:getPosition()),
        -- titleBtn        = titleBtn,
        -- titleBtnHidePos = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        -- titleBtnShowPos = cc.p(titleBtn:getPosition()),
        backBtn         = backBtn,
        --              = center
        centerLayer     = centerLayer,
        confirmBtn      = confirmBtn,
        selectedBg      = selectedBg,
        arrCatCell      = arrCatCell,
    }
end


function CatModuleChoiceView.CreateCatCell(catInitConf, pos)
    local catNodeCell = ui.layer({size = cc.size(300, 300), color = cc.r4b(0), p = pos, ap = ui.cc, enable = true})

    local catShadow  = ui.image({img = RES_DICT.IMG_SHADOW})
    catNodeCell:addList(catShadow):alignTo(nil, ui.cb)

    local catNode = CatHouseUtils.GetCatSpineNode({catData = {catId = catInitConf.id, scale = 1.3}})
    catNodeCell:addList(catNode):alignTo(nil, ui.cc)

    return catNodeCell
end


return CatModuleChoiceView
