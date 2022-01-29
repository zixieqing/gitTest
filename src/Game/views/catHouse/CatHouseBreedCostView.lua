--[[
 * author : liuzhipeng
 * descpt : 猫屋 繁殖消耗View
--]]
local CatHouseBreedCostView = class('CatHouseBreedCostView', function ()
    return ui.layer({name = 'Game.views.catHouse.CatHouseBreedCostView', enableEvent = true, ap = display.CENTER})
end)
-------------------------------------------------
-------------------- define ---------------------
local RES_DICT = {
    BG            = _res('ui/catHouse/breed/grow_birth_sure_bg.png'),
    TEXT_BG       = _res('ui/catHouse/breed/grow_birth_sure_bg_list.png'),
    COMMON_BTN_W  = _res('ui/common/common_btn_white_default.png'),
    COMMON_BTN    = _res('ui/common/common_btn_orange.png'),
    WARNING_BG    = _res('ui/catHouse/breed/grow_birth_sure_bg_dead.png')

}
-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedCostView:ctor( ... )
    self:InitUI()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
init ui
--]]
function CatHouseBreedCostView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- 时间消耗
        local timeCostTitle = display.newLabel(65, size.height - 52, {text = __('生育耗时'), color = '#683320', fontSize = 24, ap = display.LEFT_CENTER})
        view:addChild(timeCostTitle, 5)
        local timeCostBg = display.newImageView(RES_DICT.TEXT_BG, size.width / 2, size.height - 90, {scale9 = true, size = cc.size(506, 40), capInsets = cc.rect(10, 10, 486, 79)})
        view:addChild(timeCostBg, 1)
        local timeCostLabel = display.newLabel(65, timeCostBg:getPositionY(), {text = "", color = '#FFFFFF', fontSize = 24, ttf = true, font = TTF_GAME_FONT, outline = '#532211', outlineSize = 1, ap = display.LEFT_CENTER})
        view:addChild(timeCostLabel, 5)
        -- 点数消耗
        local pointCostTitle = display.newLabel(65, size.height - 150, {text = __('消耗点数'), color = '#683320', fontSize = 24, ap = display.LEFT_CENTER})
        view:addChild(pointCostTitle, 5)
        local pointCostBg = display.newImageView(RES_DICT.TEXT_BG, size.width / 2, size.height - 220, {scale9 = true, size = cc.size(506, 102), capInsets = cc.rect(10, 10, 486, 79)})
        view:addChild(pointCostBg, 5)
        local warningSign = display.newImageView(RES_DICT.WARNING_BG, size.width / 2, size.height - 220)
        view:addChild(warningSign, 5)
        local warningSignLabel = display.newLabel(warningSign:getContentSize().width / 2, warningSign:getContentSize().height / 2, {text = __('猫咪可能死亡'), fontSize = 22, color = '#FFFFFF'})
        warningSign:setCascadeOpacityEnabled(true)
        warningSign:addChild(warningSignLabel, 1)
        warningSign:runAction(
            cc.RepeatForever:create(
                cc.Sequence:create(
                    cc.DelayTime:create(1),
                    cc.FadeTo:create(0.6, 0),
                    cc.DelayTime:create(0.3),
                    cc.FadeTo:create(0.6, 255)
                )
            )
        )
        -- local pointCostTipsBg = display.newImageView(RES_DICT.TEXT_BG, size.width / 2, size.height - 302, {scale9 = true, size = cc.size(506, 60), capInsets = cc.rect(10, 10, 486, 79)})
        -- view:addChild(pointCostTipsBg, 5)
        -- local pointCostTipsLabel = display.newLabel(size.width / 2, pointCostTipsBg:getPositionY(), {text = __('耐力、饱腹、心情、社交随时间消耗数值'), color = '#FFFFFF', fontSize = 22})
        -- view:addChild(pointCostTipsLabel, 5)
        -- 取消按钮
        local cancelBtn = display.newButton(size.width / 2 - 115, 70, {n = RES_DICT.COMMON_BTN_W})
        view:addChild(cancelBtn, 5)
        display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __('取消')}))
        -- 确认按钮
        local confirmBtn = display.newButton(size.width / 2 + 115, 70, {n = RES_DICT.COMMON_BTN})
        view:addChild(confirmBtn, 5)
        display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确认')}))
        
        return {
            view                = view,
            cancelBtn           = cancelBtn,
            confirmBtn          = confirmBtn,
            timeCostLabel       = timeCostLabel,
            pointCostBg         = pointCostBg,
            warningSign         = warningSign,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function CatHouseBreedCostView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
---[[
---@description 刷新页面
---@params catModel catModel 猫咪模块
---]]
function CatHouseBreedCostView:RefreshView( catModel )
    local generation = catModel:getGeneration()
    local catBirthConf = CONF.CAT_HOUSE.CAT_BIRTH:GetValue(generation)
    self:RefreshConsumeTime(catBirthConf.birthTime)
    self:RefreshConsumeAttr(catModel, catBirthConf.consumeAttr)
end
---[[
---@description 刷新消耗时间
---@params birthTime int 消耗的时间
---]]
function CatHouseBreedCostView:RefreshConsumeTime( birthTime )
    local viewData = self:GetViewData()
    viewData.timeCostLabel:setString(CommonUtils.getTimeFormatByType(checkint(birthTime), 3))
end
---[[
---@description 刷新属性状态
---@params catModel catModel 猫咪模块
---@params consumeAttr map 消耗的属性值
---]]
function CatHouseBreedCostView:RefreshConsumeAttr( catModel, consumeAttr )
    local viewData = self:GetViewData()
    -- 刷新消耗
    local attrGroup = {}
    local warning = false
    for id, v in orderedPairs(consumeAttr) do
        local isRed = catModel:getAttrNum(id) <= checkint(v)
        if isRed then 
            warning = true
        end
        local attrIcon = ui.image({img = CatHouseUtils.GetCatAttrTypeIconPath(id, isRed)})
        table.insert(attrGroup, attrIcon)
        local costLabel = display.newLabel(attrIcon:getContentSize().width - 10, 20, {text = v, collor = '#FFFFFF', fontSize = 24, ttf = true, font = TTF_GAME_FONT, outline = '#532211', outlineSize = 1})
        attrIcon:addChild(costLabel, 1)
    end
    viewData.pointCostBg:addList(attrGroup)
    ui.flowLayout(cc.p(viewData.pointCostBg:getContentSize().width / 2 - 10, viewData.pointCostBg:getContentSize().height / 2), attrGroup, {type = ui.flowH, ap = ui.cc, gapW = 0})
    -- 警告
    viewData.warningSign:setVisible(warning)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取viewData
--]]
function CatHouseBreedCostView:GetViewData()
    return self.viewData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedCostView    