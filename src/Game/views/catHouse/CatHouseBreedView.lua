--[[
 * author : liuzhipeng
 * descpt : 猫屋 繁殖View
--]]
local CatHouseBreedView = class('CatHouseBreedView', function ()
    return ui.layer({name = 'Game.views.catHouse.CatHouseDressShopView', enableEvent = true, ap = display.CENTER})
end)

-------------------------------------------------
-------------------- import ---------------------
local CatHouseBreedListNode = require('Game.views.catHouse.CatHouseBreedListNode')
-------------------- import ---------------------
-------------------------------------------------

-------------------------------------------------
-------------------- define ---------------------
local RES_DICT = {
    BG          = _res('ui/catHouse/breed/grow_birth_mian_bg_house.png'),
    FG          = _res('ui/catHouse/breed/grow_birth_mian_bg_house_front.png'),
    SPLIT_LINE  = _res('ui/catHouse/breed/grow_birth_mian_line_wood.png'),
    -- spine --     
    CATTERY_SPINE = _spn('ui/catHouse/breed/spine/cat_grow_main_house'),
}
local CreateListCell = nil
-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedView:ctor( ... )
    self:InitUI()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
init ui
--]]
function CatHouseBreedView:InitUI()
    local function CreateView() 
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local bgSize = bg:getContentSize()
        local size = cc.size(bgSize.width - 100, bgSize.height)
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- 前景
        local fg = display.newImageView(RES_DICT.FG, size.width / 2, size.height - 5, {ap = display.CENTER_TOP})
        view:addChild(fg, 10)
        -- 列表
        local catteryGridViewSize = cc.size(1075, 590)
        local catteryGridView = ui.gridView({x = size.width / 2, y = size.height / 2 - 6, size = catteryGridViewSize, cols = 3, csizeH = 296, auto = true})
        catteryGridView:setCellCreateHandler(CreateListCell)
        view:addChild(catteryGridView, 3)
        -- 分割线
        local splitLineL = display.newImageView(RES_DICT.SPLIT_LINE, size.width / 2 - 177, size.height / 2 - 7, {scale9 = true, size = cc.size(10, 585)})
        view:addChild(splitLineL, 5)
        local splitLineR = display.newImageView(RES_DICT.SPLIT_LINE, size.width / 2 + 177, size.height / 2 - 7, {scale9 = true, size = cc.size(10, 585)})
        view:addChild(splitLineR, 5)
        return {
            view                = view,
            catteryGridView       = catteryGridView,
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
        self.viewData.catteryGridView:resetCellCount(6)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function CatHouseBreedView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end

CreateListCell = function ( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    local breedListNode = CatHouseBreedListNode.new({size = size})
    breedListNode:setName('breedListNode')
    breedListNode:setPosition(cc.p(size.width / 2, size.height / 2))
    view:addChild(breedListNode, 1)
    return {
        size           = size,
        view           = view,
        breedListNode  = breedListNode,
    }
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
--[[
生育结束动画
--]]
function CatHouseBreedView:BreedEndAnimation( playerCatId, closeFunc )
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    local catterySpine = sp.SkeletonAnimation:create(
        RES_DICT.CATTERY_SPINE.json,
        RES_DICT.CATTERY_SPINE.atlas,
        1
    )
    catterySpine:setAnimation(0, 'play3', false)
    catterySpine:setPosition(display.center)
    self:addChild(catterySpine, 3)
    catterySpine:registerSpineEventHandler(function (event)
        if event.animation == 'play3' then
            self:performWithDelay(
                function ()
                    if not tolua.isnull(catterySpine) then
                        catterySpine:removeFromParent()
                    end
                    if playerCatId then
                        local catUuid = CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), playerCatId)
                        catPreviewPopup = require('Game.views.catModule.cat.CatPreviewPopup').new({
                            isRetain      = false,
                            catUuid       = catUuid,
                            closeCallback = closeFunc
                        })
                        app.uiMgr:GetCurrentScene():AddDialog(catPreviewPopup)
                    end
                    app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
                end,
                (1 * cc.Director:getInstance():getAnimationInterval())
            )
        end
    end, 
    sp.EventType.ANIMATION_END)
end
-------------------- public ---------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取viewData
--]]
function CatHouseBreedView:GetViewData()
    return self.viewData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedView