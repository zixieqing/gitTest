--[[
 * author : liuzhipeng   
 * descpt : 新抽卡 - 铸池卡池
--]]
local CapsuleRandomPoolView = class('CapsuleRandomPoolView', function ()
    local node = CLayout:create()
    node.name = 'home.CapsuleRandomPoolView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG                = _res('ui/home/capsuleNew/randomPool/b_main_bg_qianximimeng.jpg'),
    COMMON_BTN_BIG_N  = _res('ui/common/common_btn_orange_big.png'),
    COMMON_BTN_BIG_D  = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    BTN_BG            = _res('ui/home/capsuleNew/randomPool/b_main_bg_start_circle.png'),
       
    BG_SPINE          = _spn('ui/home/capsuleNew/randomPool/effects/kczh_effect'),
    POOL_SPINE        = _spn('ui/home/capsuleNew/randomPool/effects/kczh_touxiang'),
    
    FINISHED_ICON     = _res('ui/home/capsuleNew/randomPool/b_main_circle_ico_finished.png'),
    
    COMMON_BTN_N      = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_D      = _res('ui/common/common_btn_orange_disable.png'),
}
local POOL_LAYER_OFFSET = {
    ['1'] = {x = 10  , y = 129},
    ['2'] = {x = -100, y = -166},
    ['3'] = {x = 210 , y = -116},
}
function CapsuleRandomPoolView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self.poolLayerDict = {}
    self:InitUI()
end
 
function CapsuleRandomPoolView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        local centerPos = app.capsuleMgr:GetPageViewCenter()
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, size.width / 2 - 145, size.height / 2 + 40)
        view:addChild(bg, 1)
        -- 背景spine
        local bgSpine = sp.SkeletonAnimation:create(RES_DICT.BG_SPINE.json, RES_DICT.BG_SPINE.atlas, 1)
        bgSpine:setPosition(centerPos)
        view:addChild(bgSpine, 1)
        bgSpine:setVisible(false)
        -- 按钮背景
        local btnBg = display.newImageView(RES_DICT.BTN_BG, size.width - 110 - display.SAFE_L, 170)
        view:addChild(btnBg, 2)
        btnBg:setVisible(false)
        -- 抽卡按钮
        local drawBtn = display.newButton(size.width - 90 - display.SAFE_L, 150, {n = RES_DICT.COMMON_BTN})
        view:addChild(drawBtn, 3)
        drawBtn:setVisible(false)
        local btnLabel = display.newLabel(size.width - 90 - display.SAFE_L, 164, fontWithColor(14, {text = __('铸池召唤')}))
        view:addChild(btnLabel, 10)
        btnLabel:setVisible(false)
        local drawTimeLabel = display.newLabel(size.width - 90 - display.SAFE_L, 136, fontWithColor(14, {text = ''}))
        view:addChild(drawTimeLabel, 10)
        drawTimeLabel:setVisible(false)
        -- 抽卡消耗
        local costRichLabel = display.newRichLabel(size.width - 90 - display.SAFE_L, 90)
        view:addChild(costRichLabel, 10)
        costRichLabel:setVisible(false)
        -- 重置Layout
        local resetLayoutSize = cc.size(200, 150)
        local resetLayout = CLayout:create(resetLayoutSize)
        resetLayout:setPosition(cc.p(size.width - 90 - display.SAFE_L, size.height - 180))
        resetLayout:setVisible(false)
        view:addChild(resetLayout, 5)
        local resetBtn = display.newButton(resetLayoutSize.width / 2, resetLayoutSize.height - 40, {n = RES_DICT.COMMON_BTN_N})
        resetLayout:addChild(resetBtn, 5)
        local resetBtnLabel = display.newLabel(resetLayoutSize.width / 2, resetLayoutSize.height - 40, fontWithColor(14, {text = __('重置'), fontSize = 20}))
        resetLayout:addChild(resetBtnLabel, 5)
        local resetCostRichLabel = display.newRichLabel(resetLayoutSize.width / 2, resetLayoutSize.height - 80)
        resetLayout:addChild(resetCostRichLabel, 5)
        local resetTimeLabel = display.newLabel(resetLayoutSize.width / 2, resetLayoutSize.height - 50, {fontSize = 20, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#734441'})
        resetLayout:addChild(resetTimeLabel, 5)
        
        return {      
            view                 = view,
            btnBg                = btnBg,
            drawBtn              = drawBtn,
            btnLabel             = btnLabel,
            drawTimeLabel        = drawTimeLabel,
            costRichLabel        = costRichLabel,
            resetLayout          = resetLayout,
            resetBtn             = resetBtn, 
            resetBtnLabel        = resetBtnLabel,
            resetTimeLabel       = resetTimeLabel, 
            resetCostRichLabel   = resetCostRichLabel,
            bgSpine              = bgSpine,  
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end
--[[
刷新Ui
@params pools map key为卡池编号，值为卡池数据
--]]
function CapsuleRandomPoolView:RefreshUI( pools )
    if app.capsuleMgr:GetRandomPoolState() then
        -- 展示进入动画
        self:EnterAction(pools)
    else
        -- 跳过动画直接显示
        self:ShowUI(pools)
    end
end
--[[
刷新抽卡按钮
@params currentTime int  当前卡池抽取次数
@oarams maxTime     int  最大卡池抽取次数
@oarams consume     map  抽卡消耗
--]]
function CapsuleRandomPoolView:RefreshDrawButton( currentTime, maxTime, comsume )
    local viewData = self:GetViewData()
    viewData.drawTimeLabel:setString(string.format('(%d/%d)', maxTime - currentTime, maxTime))
    if currentTime == maxTime then
        viewData.drawBtn:setNormalImage(RES_DICT.COMMON_BTN_BIG_D)
        viewData.drawBtn:setSelectedImage(RES_DICT.COMMON_BTN_BIG_D)
    else
        viewData.drawBtn:setNormalImage(RES_DICT.COMMON_BTN_BIG_N)
        viewData.drawBtn:setSelectedImage(RES_DICT.COMMON_BTN_BIG_N)
        if next(checktable(comsume[1])) ~= nil then
            -- 显示花费
            display.reloadRichLabel(viewData.costRichLabel, { c  = {
                {text = __('消耗'), fontSize = 22, color = '#ffffff'},
                {text = comsume[1].num, fontSize = 22, color = '#d9bc00'},
                {img = _res(CommonUtils.GetGoodsIconPathById(comsume[1].goodsId)), scale = 0.18}
            }})
        else
            -- 首次免费
            display.reloadRichLabel(viewData.costRichLabel, { c  = {
                { text = __('首次免费'), fontSize = 22, color = '#c6c3a7' }
            }})
        end
    end
end
--[[
刷新resetLayout
@params leftResetTimes  int 剩余重置的次数.-1表示无限
@oarams totalResetTimes int 总重置的次数.-1表示无限
@oarams resetConsume    map 重置消耗
--]]
function CapsuleRandomPoolView:RefreshResetLayout( leftResetTimes, totalResetTimes, resetConsume )
    local viewData = self:GetViewData()
    if checkint(leftResetTimes) == -1 or checkint(totalResetTimes) == -1 then
        viewData.resetTimeLabel:setVisible(false)
        display.commonLabelParams(viewData.resetBtnLabel, fontWithColor(14, {text = __('重置')}))
        viewData.resetBtnLabel:setPositionY(viewData.resetBtn:getPositionY())
    else
        viewData.resetTimeLabel:setVisible(true)
        viewData.resetTimeLabel:setString(string.format('(%d/%d)', leftResetTimes, totalResetTimes))
        display.commonLabelParams(viewData.resetBtnLabel, fontWithColor(14, {text = __('重置'), fontSize = 20}))
        viewData.resetBtnLabel:setPositionY(viewData.resetBtn:getPositionY() + 12)
    end
    display.reloadRichLabel(viewData.resetCostRichLabel, { c  = {
        {text = __('消耗'), fontSize = 22, color = '#ffffff'},
        {text = resetConsume.num, fontSize = 22, color = '#ffffff'},
        {img = _res(CommonUtils.GetGoodsIconPathById(resetConsume.goodsId)), scale = 0.18}
    }})
end
--[[
刷新重置按钮状态
@params enabled bool 是否可是点击
--]]
function CapsuleRandomPoolView:RefreshResetBtnState( enabled )
    local viewData = self:GetViewData()
    if enabled then
        viewData.resetBtn:setNormalImage(RES_DICT.COMMON_BTN_N)
        viewData.resetBtn:setSelectedImage(RES_DICT.COMMON_BTN_N)
    else
        viewData.resetBtn:setNormalImage(RES_DICT.COMMON_BTN_D)
        viewData.resetBtn:setSelectedImage(RES_DICT.COMMON_BTN_D)
    end
end
--[[
刷新卡池
@params pools map key为卡池编号，值为卡池数据
--]]
function CapsuleRandomPoolView:RefreshPools( pools )
    -- 直接移除
    for i, v in pairs(self.poolLayerDict) do
        v.layer:runAction(cc.RemoveSelf:create())
    end
    self.poolLayerDict = {}

    local viewData = self:GetViewData()
    local centerPos = app.capsuleMgr:GetPageViewCenter()
    for k, poolData in pairs(checktable(pools)) do
        -- if self.poolLayerDict[tostring(k)] then
        --     self:RefreshPoolLayer(self.poolLayerDict[tostring(k)], poolData)
        -- else
            local poolLayer = self:CreatePoolLayer(poolData)
            poolLayer.layer:setPosition(cc.p(centerPos.x + POOL_LAYER_OFFSET[tostring(k)].x, centerPos.y + POOL_LAYER_OFFSET[tostring(k)].y))
            poolLayer.layer:setTag(checkint(k))
            viewData.view:addChild(poolLayer.layer, 10)
            self.poolLayerDict[tostring(k)] = poolLayer
        -- end        
    end
end
--[[
刷新卡池layer
@params poolLayer map 卡池layer
@params pool  map {
    poolId    int  卡池ID
    hasDrawn  int  是否领取
    isRefresh int  进入卡池刷新状态 （0否， 1是）
    dropCards list 卡池掉落的卡牌
}
--]]
function CapsuleRandomPoolView:RefreshPoolLayer( poolLayer, pool )
    if not pool then return end
    local poolConfig = CommonUtils.GetConfig('gambling', 'randBuffChildPool', checkint(pool.poolId))
    poolLayer.poolTitle:setString(poolConfig.name)
    poolLayer.cardImg:setTexture(_res(string.format('ui/home/capsuleNew/randomPool/role/%s.png', poolConfig.frameView)))
    -- 判断卡池是否领取
    poolLayer.finishedIcon:setVisible(checkint(pool.hasDrawn) == 1)
    
end
--[[
进入动画
--]]
function CapsuleRandomPoolView:EnterAction( pools )
    -- 判断是否需要展示动画
    local viewData = self:GetViewData()
    viewData.bgSpine:update(0)
    viewData.bgSpine:setToSetupPose()
    viewData.bgSpine:setAnimation(0, 'attack', false)
    viewData.bgSpine:addAnimation(0, 'idle', true)
    viewData.bgSpine:setVisible(true)
    self:stopAllActions()
    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(1),
            cc.CallFunc:create(function ()
                self:RefreshPools(pools)
                for k, v in orderedPairs(self.poolLayerDict) do
                    v.layer:setVisible(false)
                    v.layer:runAction(
                        cc.Sequence:create(
                            cc.DelayTime:create((checkint(k) - 1) * 0.1), 
                            cc.CallFunc:create(function ()
                                v.layer:setVisible(true)
                                v.poolSpine:setToSetupPose()
                                v.poolSpine:setAnimation(0, 'attack', false)
                                v.poolSpine:addAnimation(0, 'idle', true)
                            end)
                        ) 
                    )
                end
            end),
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(function ()
                viewData.btnBg:setVisible(true)
                viewData.drawBtn:setVisible(true)
                viewData.btnLabel:setVisible(true)
                viewData.drawTimeLabel:setVisible(true)
                viewData.costRichLabel:setVisible(true)
                viewData.resetLayout:setVisible(true)
                app.capsuleMgr:SetRandomPoolState(false)
            end)
        )
    )
end
--[[
展示UI
--]]
function CapsuleRandomPoolView:ShowUI( pools )
    local viewData = self:GetViewData()
    viewData.bgSpine:setVisible(true)
    viewData.bgSpine:addAnimation(0, 'idle', true)
    viewData.btnBg:setVisible(true)
    viewData.drawBtn:setVisible(true)
    viewData.btnLabel:setVisible(true)
    viewData.drawTimeLabel:setVisible(true)
    viewData.costRichLabel:setVisible(true)
    viewData.resetLayout:setVisible(true)
    self:RefreshPools(pools)
end
--[[
创建卡池
@params pool  map {
    poolId    int  卡池ID
    hasDrawn  int  是否领取
    isRefresh int  进入卡池刷新状态 （0否， 1是）
    dropCards list 卡池掉落的卡牌
}
@return poolLayer map 卡池layer
--]]
function CapsuleRandomPoolView:CreatePoolLayer( pool )
    local size = cc.size(240, 240)
    local layer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), size = size, ap = display.CENTER, enable = true, cb = function (sender)
        AppFacade.GetInstance():DispatchObservers(CAPSULE_RANDOM_POOL_PREVIEW, {
	    	poolNum = sender:getTag()
        })
    end})
    local poolSpine = sp.SkeletonAnimation:create(RES_DICT.POOL_SPINE.json, RES_DICT.POOL_SPINE.atlas, 1)
    poolSpine:setAnimation(0, 'idle', true)
    poolSpine:setPosition(size.width / 2, size.height / 2)
    layer:addChild(poolSpine, 1)
    local cardImg = display.newImageView('', size.width / 2, size.height / 2)
    layer:addChild(cardImg, 2)
    local poolTitle = display.newLabel(size.width / 2, 70, {text = '', fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#931818', outlineSize = 2})
    layer:addChild(poolTitle, 3)
    local finishedIcon = display.newImageView(RES_DICT.FINISHED_ICON, size.width / 2, -10)
    layer:addChild(finishedIcon, 4)
    local poolLayer = {
        layer        = layer, 
        poolSpine    = poolSpine, 
        cardImg      = cardImg,
        poolTitle    = poolTitle,
        finishedIcon = finishedIcon,
    }
    if pool then
        self:RefreshPoolLayer(poolLayer, pool)
    end
    return poolLayer
end
--[[
获取viewData
--]]
function CapsuleRandomPoolView:GetViewData()
    return self.viewData
end
return CapsuleRandomPoolView
