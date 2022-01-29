--[[
 * author : liuzhipeng
 * descpt : type nameView
--]]
local CatHouseBreedListNode = class('CatHouseBreedListNode', function ()
    return ui.layer({name = 'CatHouseDragNode', enableEvent = true, ap = display.CENTER})
end)
-------------------------------------------------
-------------------- define ---------------------
local RES_DICT = {
    BG_WOOD_L     = _res('ui/catHouse/breed/grow_birth_mian_bg_wood_1.png'),
    BG_WOOD_C     = _res('ui/catHouse/breed/grow_birth_mian_bg_wood_2.png'),
    BG_WOOD_R     = _res('ui/catHouse/breed/grow_birth_mian_bg_wood_3.png'),
    STATE_BG      = _res('ui/catHouse/breed/grow_birth_mian_bg_now.png'),
    AMOUNT_BG     = _res('ui/catHouse/breed/grow_birth_mian_bg_number.png'),
    COUNT_DOWN_BG = _res('ui/catHouse/breed/grow_birth_mian_bg_time.png'),
    ADD_ICON      = _res('ui/catHouse/breed/grow_birth_list_btn_add'),
    -- spine --     
    CATTERY_SPINE = _spn('ui/catHouse/breed/spine/cat_grow_main_house'),
}
-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedListNode:ctor( ... )
    local args = unpack({...})
    local size = args.size or {}
    self:InitUI(size)
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
背景按钮点击回调
--]]
function CatHouseBreedListNode:BgButtonCallback( sender )
    local callback = self:GetClickHandler()
    if callback then
        callback(sender)
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
init ui
--]]
function CatHouseBreedListNode:InitUI( size )
    local function CreateView()
        local view = CLayout:create(size)
        -- 木板
        local bottomWood = display.newImageView(RES_DICT.BG_WOOD_L, size.width / 2, size.height / 2 - 36)
        view:addChild(bottomWood, 1)
        -- bgBtn
        local bgBtn = display.newButton(size.width / 2, size.height / 2 + 40, {n = 'empty', size = cc.size(310, 200)})
        view:addChild(bgBtn, 1)
        -- 状态
        local stateBg = display.newImageView(RES_DICT.STATE_BG, size.width / 2, 0, {ap = display.CENTER_BOTTOM})
        view:addChild(stateBg, 1)
        local stateLabel = display.newLabel(stateBg:getContentSize().width / 2, stateBg:getContentSize().height / 2 + 5, {text = '', color = '#FFFFFF', fontSize = 24})
        stateBg:addChild(stateLabel, 1)
        -- 猫屋数量
        local amountBg = display.newImageView(RES_DICT.AMOUNT_BG, -9, size.height / 2 - 56, {ap = display.LEFT_CENTER})
        view:addChild(amountBg, 5)
        local amountLabel = display.newLabel(amountBg:getContentSize().width / 2, amountBg:getContentSize().height / 2, {text = '', color = '#F4C490', fontSize = 24})
        amountBg:addChild(amountLabel, 1)
        -- 倒计时
        local countDownBg = display.newImageView(RES_DICT.COUNT_DOWN_BG, size.width / 2, size.height / 2 - 56)
        view:addChild(countDownBg, 5)
        local countDownLabel = display.newLabel(countDownBg:getContentSize().width / 2, countDownBg:getContentSize().height / 2, {text = '00:00:00', color = '#b7a892', fontSize =22})
        countDownBg:addChild(countDownLabel, 1)
        -- 猫窝spine
        local catterySpine = sp.SkeletonAnimation:create(
            RES_DICT.CATTERY_SPINE.json,
            RES_DICT.CATTERY_SPINE.atlas,
            0.6
        )
        catterySpine:setPosition(size.width / 2, size.height / 2 + 30)
        catterySpine:setAnimation(0, 'idle', true)
        view:addChild(catterySpine, 3)
        local addIcon = display.newImageView(RES_DICT.ADD_ICON, size.width / 2 + 25, size.height / 2 + 18)
        addIcon:setScale(0.6)
        view:addChild(addIcon, 3)
        return {
            view                = view,
            bottomWood          = bottomWood,
            bgBtn               = bgBtn,
            amountBg            = amountBg,
            amountLabel         = amountLabel,
            countDownBg         = countDownBg,
            stateBg             = stateBg,
            countDownLabel      = countDownLabel,
            stateLabel          = stateLabel,
            catterySpine        = catterySpine,
            addIcon             = addIcon,
        }
    end
    xTry(function ( )
        self:setContentSize(size)
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(cc.p(size.width / 2, size.height / 2))
        self.viewData.bgBtn:setOnClickScriptHandler(handler(self, self.BgButtonCallback))
    end, __G__TRACKBACK__)
end
--[[
刷新node
--]]
function CatHouseBreedListNode:RefreshNode( params )
    local viewData = self:GetViewData()
    self.params = params
    local index = checkint(params.index)
    -- 判断cell位置
    local type = (index - 1) % 3
    local texture = RES_DICT.BG_WOOD_L
    if type == 1 then
        texture = RES_DICT.BG_WOOD_C
    elseif type == 2 then
        texture = RES_DICT.BG_WOOD_R
    end
    viewData.bottomWood:setTexture(texture)
    viewData.bgBtn:setTag(index)
    self:RefreshNodeState(params.breedData)
end
--[[
刷新node状态
@params breedData map {
    state int 状态
    catModel HouseCatModel 猫咪模块
}
--]]
function CatHouseBreedListNode:RefreshNodeState( breedData )
    local viewData = self:GetViewData()
    -- 判断cell状态
    viewData.stateBg:setVisible(true)
    viewData.bgBtn:setEnabled(true)
    if breedData.state == CatHouseUtils.CAT_BREED_STATE.CREATE then
        viewData.stateLabel:setString(__('空闲房'))
        viewData.countDownBg:setVisible(false)
        viewData.amountBg:setVisible(true)
        viewData.addIcon:setVisible(true)
        local amount = app.goodsMgr:GetGoodsAmountByGoodsId(CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].goodsId)
        viewData.amountLabel:setString(amount)
        viewData.catterySpine:setVisible(true)
        viewData.catterySpine:update(0)
        viewData.catterySpine:setAnimation(0, 'idle', true)
    elseif breedData.state == CatHouseUtils.CAT_BREED_STATE.PAIRING then
        viewData.stateLabel:setString(__('等待配对'))
        viewData.countDownBg:setVisible(true)
        viewData.amountBg:setVisible(false)
        viewData.addIcon:setVisible(false)
        viewData.catterySpine:setVisible(true)
        viewData.catterySpine:update(0)
        viewData.catterySpine:setAnimation(0, 'idle', true)
        self:UpdateCountdown(breedData.catModel:getHouseLeftSeconds())
    elseif breedData.state == CatHouseUtils.CAT_BREED_STATE.BREEDING then
        viewData.stateLabel:setString(__('孕育中'))
        viewData.countDownBg:setVisible(true)
        viewData.amountBg:setVisible(false)
        viewData.addIcon:setVisible(false)
        viewData.catterySpine:setVisible(true)
        viewData.catterySpine:update(0)
        viewData.catterySpine:setAnimation(0, 'play1', true)
        self:UpdateCountdown(breedData.catModel:getMatingLeftSeconds())
    elseif breedData.state == CatHouseUtils.CAT_BREED_STATE.FINISH then
        viewData.stateLabel:setString(__('生育完成'))
        viewData.countDownBg:setVisible(false)
        viewData.amountBg:setVisible(false)
        viewData.addIcon:setVisible(false)
        viewData.catterySpine:setVisible(true)
        viewData.catterySpine:update(0)
        viewData.catterySpine:setAnimation(0, 'play2', true)
    elseif breedData.state == CatHouseUtils.CAT_BREED_STATE.EMPTY then
        viewData.countDownBg:setVisible(false)
        viewData.amountBg:setVisible(false)
        viewData.stateBg:setVisible(false)
        viewData.bgBtn:setEnabled(false)
        viewData.addIcon:setVisible(false)
        viewData.catterySpine:setVisible(false)
    end
end
--[[
更新倒计时
--]]
function CatHouseBreedListNode:UpdateCountdown( countdown )
    local viewData = self:GetViewData()
    viewData.countDownLabel:setString(CommonUtils.getTimeFormatByType(countdown))
end

-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取viewData
--]]
function CatHouseBreedListNode:GetViewData()
    return self.viewData
end
--[[
设置点击回调
--]]
function CatHouseBreedListNode:SetClickHandler( cb )
    self.clickHandler = cb
end
--[[
获取点击回调
--]]
function CatHouseBreedListNode:GetClickHandler()
    return self.clickHandler
end

------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedListNode