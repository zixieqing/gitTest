--[[
特殊活动 登陆礼包活动页签view
--]]
local SpActivityLoginPageView = class('SpActivityLoginPageView', function ()
    local node = CLayout:create()
    node.name = 'home.SpActivityLoginPageView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BOTTOM_BG         = _res("ui/home/specialActivity/unni_activity_bg_login_get.png"),
    PROGRESS_BG       = _res('ui/home/specialActivity/unni_activity_bg_loading_login_get_1.png'),
    PROGRESS_IMG      = _res('ui/home/specialActivity/unni_activity_bg_loading_login_get_2.png'),
    CHEST_NORMAL      = _res('arts/goods/goods_icon_191002.png'),
    CHEST_RARE        = _res('arts/goods/goods_icon_190003.png'),
    CHEST_OPEN        = _res('ui/home/specialActivity/unni_activity_box_opened.png'),
    CHEST_TEXT_BG     = _res('ui/home/specialActivity/unni_acitity_bg_text.png'),
    CHEST_SHADOW      = _res('ui/home/specialActivity/unni_acitity_login_get_bg_goods.png'),
    ARROW             = _res('ui/home/specialActivity/unni_activity_ico_arrow.png'),
    PRIZE_GOODS_BG    = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg.png'),
    PRIZE_GOODS_LIGHT = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg_light.png'),
}
function SpActivityLoginPageView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end
 
function SpActivityLoginPageView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        -- bottomLayer
        local bottomLayer = display.newLayer(size.width / 2, 15, {bg = RES_DICT.BOTTOM_BG, ap = cc.p(0.5, 0)})
        view:addChild(bottomLayer, 1) 
        local bottomLayerSize = bottomLayer:getContentSize()
        -- 进度条
        local progressBar = CProgressBar:create(RES_DICT.PROGRESS_IMG)
        progressBar:setBackgroundImage(RES_DICT.PROGRESS_BG)
        progressBar:setDirection(eProgressBarDirectionLeftToRight)
        progressBar:setAnchorPoint(cc.p(0.5, 0.5))
        progressBar:setPosition(cc.p(bottomLayerSize.width / 2, bottomLayerSize.height / 2))
        bottomLayer:addChild(progressBar, 2)
        local progressBarSize = progressBar:getContentSize()
        -- rewardLayer
        local rewardLayer = display.newLayer(bottomLayerSize.width / 2, bottomLayerSize.height / 2, {size = bottomLayerSize, ap = display.CENTER})
        bottomLayer:addChild(rewardLayer, 3)


        
        return {      
            view                 = view,
            bottomLayer          = bottomLayer,
            bottomLayerSize      = bottomLayerSize,
            progressBar          = progressBar,
            progressBarSize      = progressBarSize,
            rewardLayer          = rewardLayer,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end
--[[
刷新奖励进度条
--]]
function SpActivityLoginPageView:RefreshRewardsProgress( rewardData )
    if not rewardData then return end
    local viewData = self.viewData
    local rewardLayer = viewData.rewardLayer
    local progress = checkint(rewardData.today)
    local maxValue = checkint(#rewardData.loginRewardList)
    viewData.progressBar:setMaxValue(math.max(1, maxValue - 1))
    viewData.progressBar:setValue(math.max(0, progress - 1))
    rewardLayer:removeAllChildren()    
    local defualtX = viewData.bottomLayerSize.width / 2 - viewData.progressBarSize.width / 2
    local spacing  = viewData.progressBarSize.width / (maxValue - 1)
    for i, v in ipairs(rewardData.loginRewardList) do
        local chestIcon = FilteredSpriteWithOne:create()
        chestIcon:setScale(0.7)
        local posX = defualtX + (i - 1) * spacing
        local posY = viewData.bottomLayerSize.height / 2
        -- chestIcon:setAnchorPoint(cc.p(0.5, 0))
        chestIcon:setPosition(cc.p(posX, posY))
        rewardLayer:addChild(chestIcon, 3)
        local shadow = display.newImageView(RES_DICT.CHEST_SHADOW, posX, posY - 37)
        rewardLayer:addChild(shadow, 1)
        local dateLabel = display.newLabel(posX, viewData.bottomLayerSize.height - 30, {text = string.fmt(__('第_num_天'), {['_num_'] = i}), fontSize = 22, color = '#FCD5A2'})
        rewardLayer:addChild(dateLabel, 3)
        local drawBtn = display.newButton(posX, posY, {n = 'empty', size = cc.size(100, 100), cb = function(sender) 
            AppFacade.GetInstance():DispatchObservers(SP_ACTIVITY_LOGIN_REWARD_CLICK, {tag = sender:getTag(), sender = sender})
        end})
        drawBtn:setTag(i)
        rewardLayer:addChild(drawBtn, 10)
        if checkint(v.hasDrawn) == 0 then
            if progress > i then
                drawBtn:setVisible(false)
                chestIcon:setTexture(RES_DICT.CHEST_NORMAL)
                chestIcon:setFilter(GrayFilter:create())
                local textBg = display.newImageView(RES_DICT.CHEST_TEXT_BG, posX, posY)
                local textLabel = display.newLabel(textBg:getContentSize().width / 2, textBg:getContentSize().height / 2, {text = __("已过期"), color = '#ffffff', fontSize = 20})
                textBg:addChild(textLabel, 1)
                rewardLayer:addChild(textBg, 5)
            else
                if maxValue == i then
                    chestIcon:setTexture(RES_DICT.CHEST_RARE)
                else
                    chestIcon:setTexture(RES_DICT.CHEST_NORMAL)
                end
                if progress == i then
                    -- 高亮
                    dateLabel:setVisible(false)
                    local arrow = display.newImageView(RES_DICT.ARROW, posX, viewData.bottomLayerSize.height - 60, {})
                    rewardLayer:addChild(arrow, 5)
                    local drawLabel = display.newLabel(posX, viewData.bottomLayerSize.height - 30, {text = __("点击领取"), fontSize = 20, color = '#ffffff'})
                    rewardLayer:addChild(drawLabel, 5)
                    local lightBg = display.newImageView(RES_DICT.PRIZE_GOODS_BG, posX, posY)
                    lightBg:setScale(0.7)
                    rewardLayer:addChild(lightBg, 2)
                    local light = display.newImageView(RES_DICT.PRIZE_GOODS_LIGHT,posX, posY)
                    light:setScale(0.7)
                    light:runAction(cc.RepeatForever:create(
                        cc.RotateBy:create(1, 30)
                    ))
                    rewardLayer:addChild(light, 2)
                end
            end
        elseif checkint(v.hasDrawn) == 1 then
            drawBtn:setVisible(false)
            chestIcon:setTexture(RES_DICT.CHEST_OPEN)
            local textBg = display.newImageView(RES_DICT.CHEST_TEXT_BG, posX, posY)
            local textLabel = display.newLabel(textBg:getContentSize().width / 2, textBg:getContentSize().height / 2, {text = __("已领取"), color = '#ffffff', fontSize = 20})
            textBg:addChild(textLabel, 1)
            rewardLayer:addChild(textBg, 5)
        end
    end

end

return SpActivityLoginPageView
