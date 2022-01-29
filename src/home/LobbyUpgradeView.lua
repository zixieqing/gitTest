local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

local LobbyUpgradeView = class('LobbyUpgradeView', function ()
    local clb = CLayout:create(cc.size(display.width, display.height))
    clb.name = 'common.LobbyUpgradeView'
    clb:enableNodeEvents()
    return clb
end)

local ViewStatus = {
    UPGRADE_ACTION = 1, -- 升级动画
    UPGRADE_END    = 2, -- 升级动画结束
    AVATAR_ACTION  = 3, -- avatar动画
    AVATAR_END     = 4, -- avatar动画结束
    CLOSE_ACTION   = 5


}
function LobbyUpgradeView:ctor(...)
    self.args = unpack({...})
    local function CreateView()
        local view = CLayout:create(display.size)
        -- spine 
        local upgradeSpine = sp.SkeletonAnimation:create(
            'effects/lobby/cantingshengji.json',
            'effects/lobby/cantingshengji.atlas',
            1)
        upgradeSpine:setPosition(cc.p(display.cx, display.cy - 200))
        view:addChild(upgradeSpine, 1)
        local restaurantLevel = cc.Label:createWithBMFont('font/levelup.fnt', checkint(gameMgr:GetUserInfo().restaurantLevel) - 1)
        restaurantLevel:setAnchorPoint(cc.p(0.5,0.5))
        restaurantLevel:setPosition(cc.p(display.cx,display.cy - 130))
        view:addChild(restaurantLevel, 10)

        local bgSize = cc.size(540, 500)
        local upgradeLayout = CLayout:create(bgSize)
        display.commonUIParams(upgradeLayout, {ap = display.CENTER, po = cc.p(display.cx + 320, display.cy-100)})
        view:addChild(upgradeLayout)
        local light = display.newImageView(_res('ui/common/common_reward_light.png'), bgSize.width/4*3, 480)
        light:setVisible(false)
        light:setScale(0.8)
        upgradeLayout:addChild(light, 1)
        local oldLevelImage =  display.newImageView(_res('ui/home/homeland/management_home_btn_restaurant_1.png'),bgSize.width/4*1, 480)
        upgradeLayout:addChild(oldLevelImage, 1)
        oldLevelImage:setScale(0.8)
        oldLevelImage:setOpacity(0)
        local newLevelImage =  display.newImageView(_res('ui/home/homeland/management_home_btn_restaurant_1.png'),bgSize.width/4*3, 480)
        upgradeLayout:addChild(newLevelImage, 1)
        local arrowTable  ={}
        for i=1, 3 do
            local arrow = display.newImageView(_res('ui/home/kitchen/cooking_level_up_ico_arrow.png'), bgSize.width/2 +(i - 0.5 -1.5) *12, 480)
            upgradeLayout:addChild(arrow, 10)
            arrowTable[#arrowTable+1] = arrow
        end
        newLevelImage:setOpacity(0)
        newLevelImage:setScale(0.8)
        local upgradeIcon = display.newImageView(_res('ui/home/lobby/information/restaurant_ico_level_up.png'), bgSize.width/2, 650)
        upgradeIcon:setVisible(false)
        upgradeLayout:addChild(upgradeIcon, 10)
        local upgradeBg = display.newImageView(_res('ui/home/lobby/information/restaurant_bg_attribute_promotion.png'), bgSize.width/2, 180)
        upgradeBg:setOpacity(0)
        upgradeLayout:addChild(upgradeBg, 5)

        local  levelUpLayout = CLayout:create(cc.size(bgSize.width, 60))
        levelUpLayout:setPosition(cc.p(bgSize.width/2, 295 - 50))
        levelUpLayout:setOpacity(120)
        levelUpLayout:setVisible(false)
        upgradeLayout:addChild(levelUpLayout, 10)
        local lobbyLvLabel = display.newLabel(50, 30, fontWithColor(19, {text = __('餐厅等级'), ap = cc.p(0, 0.5)}))
        levelUpLayout:addChild(lobbyLvLabel, 10)
        local newLvLabel = display.newLabel(260, 30, fontWithColor(18, {text = string.fmt(__('等级_num_'), {['_num_'] = checkint(gameMgr:GetUserInfo().restaurantLevel) - 1})}))
        levelUpLayout:addChild(newLvLabel, 10)
        for i=1, 3 do
            local arrow = display.newImageView(_res('ui/home/kitchen/cooking_level_up_ico_arrow.png'), 320+i*12, 30)
            levelUpLayout:addChild(arrow, 10)
        end
        local nextLvLabel = display.newLabel(430, 30, fontWithColor(18, {text = string.fmt(__('等级_num_'), {['_num_'] = checkint(gameMgr:GetUserInfo().restaurantLevel)})}))
        levelUpLayout:addChild(nextLvLabel, 10)
        local line = display.newImageView(_res('ui/home/lobby/information/restaurant_line.png'), bgSize.width/2, 270 - 50)
        line:setOpacity(120)
        line:setVisible(false)
        upgradeLayout:addChild(line, 10)

        local listSize = cc.size(520, 228)
        local listCellSize = cc.size(listSize.width, 38)
        local listView = CListView:create(listSize)
        listView:setDirection(eScrollViewDirectionVertical)
        listView:setBounceable(false)
        upgradeLayout:addChild(listView, 10)
        listView:setAnchorPoint(cc.p(0.5, 0))
        listView:setPosition(cc.p(bgSize.width * 0.5, 40))
        -- 赠送avatar
        local giftLabel = display.newLabel(bgSize.width/2, 285 - 50, fontWithColor(18, {text = __('长老送你的装饰，快去装点你的餐厅吧')}))
        giftLabel:setVisible(false)
        giftLabel:setOpacity(120)
        upgradeLayout:addChild(giftLabel, 10)
        local giftDatas = checktable(CommonUtils.GetConfigNoParser('restaurant', 'levelUp', gameMgr:GetUserInfo().restaurantLevel).avatarRewards)
        local giftLayout = CLayout:create(cc.size(112 + (#giftDatas-1)*132, 200))
        giftLayout:setVisible(false)
        giftLayout:setOpacity(120)
        upgradeLayout:addChild(giftLayout, 10)
        giftLayout:setPosition(cc.p(bgSize.width/2, 160 - 50))
        for i,v in ipairs(giftDatas) do
            local image = AssetsUtils.GetRestaurantSmallAvatarNode(v.goodsId, 56 + (i-1)*132, 140)
            image:setScale(0.7)
            giftLayout:addChild(image)
            local line = display.newImageView(_res('ui/home/lobby/information/restaurant_level_up_ico.line.png'), 56 + (i-1)*132, 84)
            giftLayout:addChild(line)  
            local name = CommonUtils.GetConfigNoParser('restaurant', 'avatar', v.goodsId).name
            if checkint(v.num) > 1 then
                name = name .. '×' .. tostring(v.num)
            end
            local nameLabel = display.newLabel(56 + (i-1)*132, 65, fontWithColor(18, {text = name}))
            giftLayout:addChild(nameLabel)
        end


        return {
            view            = view,
            bgSize          = bgSize,
            upgradeSpine    = upgradeSpine,
            upgradeLayout   = upgradeLayout,
            restaurantLevel = restaurantLevel,
            light           = light,
            upgradeIcon     = upgradeIcon,
            upgradeBg       = upgradeBg,
            levelUpLayout   = levelUpLayout,
            line            = line,
            listView        = listView,
            giftLayout      = giftLayout,
            oldLevelImage   = oldLevelImage,
            newLevelImage   = newLevelImage,
            arrowTable      = arrowTable,
            giftLabel       = giftLabel

        }
    end

    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setCascadeOpacityEnabled(true)
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(utils.getLocalCenter(self))
    eaterLayer:setOnClickScriptHandler(handler(self, self.CloseCallback))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer

    self.viewStatus = ViewStatus.UPGRADE_ACTION
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
    display.commonUIParams(self.viewData_.view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    self:EnterAction()
end
function LobbyUpgradeView:EnterAction()
    -- 添加音效
    PlayAudioClip(AUDIOS.UI.ui_restaurant_levelup.id)
    local viewData = self.viewData_
    viewData.upgradeLayout:setVisible(false)
    viewData.upgradeSpine:update(0)
    viewData.upgradeSpine:setAnimation(0, 'play', false)
    viewData.upgradeSpine:registerSpineEventHandler(handler(self, self.SpineEventHandler), sp.EventType.ANIMATION_EVENT)
    viewData.upgradeSpine:registerSpineEventHandler(handler(self, self.SpineEventEndHandler), sp.EventType.ANIMATION_END)
end
--[[
spine自定义事件回调
--]]
function LobbyUpgradeView:SpineEventHandler( event )
    if not event then return end
    if not event.eventData then return end
    if 'play' == event.eventData.name then
        local viewData = self.viewData_
        local tempNum = cc.Label:createWithBMFont('font/levelup.fnt', checkint(gameMgr:GetUserInfo().restaurantLevel))
        tempNum:setPosition(cc.p(display.cx,display.cy - 180))
        tempNum:setOpacity(0)
        viewData.view:addChild(tempNum, 10)
        viewData.restaurantLevel:runAction(
            cc.Sequence:create(
                cc.ScaleTo:create(0.1, 1.3, 0.7),
                cc.Spawn:create(
                    cc.ScaleTo:create(0.1, 1, 1),
                    cc.MoveBy:create(0.3, cc.p(0, 50)),
                    cc.Sequence:create(
                        cc.DelayTime:create(0.1),
                        cc.FadeOut:create(0.2)
                    ),
                    cc.TargetedAction:create(tempNum, 
                        cc.Spawn:create(
                            cc.FadeIn:create(0.1),
                            cc.MoveBy:create(0.3, cc.p(0, 50))
                        )
                    )
                ),
                cc.DelayTime:create(0.3),
                cc.CallFunc:create(function()
                    viewData.restaurantLevel:setPosition(cc.p(display.cx,display.cy - 130))
                    viewData.restaurantLevel:setString(gameMgr:GetUserInfo().restaurantLevel)
                    viewData.restaurantLevel:setOpacity(255)
                    local homeLandConf = CommonUtils.GetConfigAllMess('homeEntrance','business')
                    local oldPath =  string.format("ui/home/homeland/%s.png",homeLandConf["1"][tostring(gameMgr:GetUserInfo().restaurantLevel-1 )].icon )
                    local newPath =  string.format("ui/home/homeland/%s.png",homeLandConf["1"][tostring(gameMgr:GetUserInfo().restaurantLevel )].icon )
                    viewData.newLevelImage:setTexture(newPath)
                    viewData.oldLevelImage:setTexture(oldPath)
                    tempNum:setVisible(false)
                    tempNum:runAction(cc.RemoveSelf:create())
                    self:ShowUpgradeView()
                end)
            )
        )
    end 
end
--[[
spine结束回调
--]]
function LobbyUpgradeView:SpineEventEndHandler( event )
    if not event then return end
    local eventName = event.animation
    if eventName == 'play' then
        self:performWithDelay(
            function ()
                local viewData = self.viewData_
                viewData.upgradeSpine:update(0)
                viewData.upgradeSpine:setToSetupPose()
                self.viewData_.upgradeSpine:setAnimation(0, 'idle', true)
            end,
            (1 * cc.Director:getInstance():getAnimationInterval())
        )
    end
end
function LobbyUpgradeView:ShowUpgradeView()
    local viewData = self.viewData_
    self:runAction(
        cc.Sequence:create(
            cc.Spawn:create(
                cc.TargetedAction:create(viewData.upgradeSpine, cc.MoveTo:create(0.2, cc.p(display.cx - 300, display.cy - 200))),
                cc.TargetedAction:create(viewData.restaurantLevel, cc.MoveTo:create(0.2, cc.p(display.cx - 300, display.cy - 130)))
            ),
            cc.CallFunc:create(function()
                viewData.upgradeLayout:setVisible(true)
                viewData.light:setVisible(true)
                viewData.light:runAction(
                    cc.RepeatForever:create(
                        cc.RotateBy:create(1, 60)
                    )
                )
            end),
            cc.Spawn:create(
                cc.TargetedAction:create(
                    viewData.upgradeIcon, cc.Sequence:create(
                        cc.Show:create(),
                        cc.MoveTo:create(0.13, cc.p(viewData.bgSize.width/2, 320+280)),
                        cc.MoveTo:create(0.12, cc.p(viewData.bgSize.width/2, 400+280)),
                        cc.MoveTo:create(0.11, cc.p(viewData.bgSize.width/2, 360+280)),
                        cc.MoveTo:create(0.1, cc.p(viewData.bgSize.width/2, 370+280))
                    )
                ),
                cc.TargetedAction:create(
                    viewData.newLevelImage , cc.FadeIn:create(0.46)
                ),
                cc.TargetedAction:create(
                    viewData.oldLevelImage , cc.Sequence:create(
                                cc.CallFunc:create(function()
                                    for i =1 , #viewData.arrowTable do
                                        viewData.arrowTable[i]:runAction(self:GetIcoArrowAnimation(i ))
                                    end
                                end),
                                cc.FadeIn:create(0.46)
                        )
                )
            )   ,
            cc.TargetedAction:create(
                viewData.upgradeBg, cc.FadeIn:create(0.2)
            ),
            cc.Spawn:create(
                cc.TargetedAction:create(
                    viewData.levelUpLayout, cc.Spawn:create(
                        cc.Show:create(),
                        cc.FadeIn:create(0.1),
                        cc.MoveBy:create(0.15, cc.p(0, 50))
                    )
                ),
                cc.TargetedAction:create(
                    viewData.line, cc.Sequence:create(
                        cc.DelayTime:create(0.05),
                        cc.Spawn:create(
                            cc.Show:create(),
                            cc.FadeIn:create(0.1),
                            cc.MoveBy:create(0.15, cc.p(0, 50))
                        )
                    )
                ),
                cc.CallFunc:create(handler(self, self.UpdateListView))
            )
        )
    )
end
function LobbyUpgradeView:UpdateListView()
    local viewData = self.viewData_
    local restaurantDatas = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', gameMgr:GetUserInfo().restaurantLevel-1)
    local nextRestaurantDatas = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', gameMgr:GetUserInfo().restaurantLevel)
    local descrDatas = {
        {name = __('客流量'), nowNums = restaurantDatas.traffic, nextNums = nextRestaurantDatas.traffic},
        {name = __('座位数量'), nowNums = restaurantDatas.seatNum, nextNums = nextRestaurantDatas.seatNum},
        {name = __('橱窗出售菜品'), nowNums = restaurantDatas.sellFoodLimit, nextNums = nextRestaurantDatas.sellFoodLimit},
        {name = __('出售菜品数量'), nowNums = restaurantDatas.shopWindowLimit, nextNums = nextRestaurantDatas.shopWindowLimit}
    }
    for i,v in ipairs(descrDatas) do
        local size = cc.size(520, 38)
        local listLayout = CLayout:create(size)
        local layout = CLayout:create(size)
        layout:setVisible(false)
        layout:setPosition(cc.p(size.width/2, size.height/2 - 50))
        layout:setOpacity(120)
        listLayout:addChild(layout)
        local name = display.newLabel(45, 19, {text = v.name, fontSize = 24, color = '#ffeac5', ap = cc.p(0, 0.5)})
        layout:addChild(name)
        local numsLabel = display.newLabel(255, 19, fontWithColor(9, {text = v.nowNums, ap = cc.p(1, 0.5)}))
        layout:addChild(numsLabel)
        local arrow = display.newImageView(_res('ui/home/kitchen/cooking_level_up_ico_arrow.png'), 334, 19)
        layout:addChild(arrow)
        if v.nowNums == v.nextNums then
            local nextLabel = display.newLabel(430, 19, fontWithColor(9, {text = v.nextNums, ap = cc.p(1, 0.5)}))
            layout:addChild(nextLabel)
        else
            local bg = display.newImageView(_res('ui/home/lobby/information/restaurant_level_up_bg_name_light.png') ,size.width/2, 19)
            layout:addChild(bg, -1)
            local nextLabel = display.newLabel(430, 19, {text = v.nextNums, ap = cc.p(1, 0.5), color = '#ffbf25', fontSize = 22})
            layout:addChild(nextLabel)
        end
        viewData.listView:insertNodeAtLast(listLayout)  
        layout:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.05 + 0.05*i),
                cc.Show:create(),
                cc.Spawn:create(
                    cc.CallFunc:create(function()
                        if i > 6 then
                            viewData.listView:setContentOffsetInDuration(cc.p(0, 38*(#descrDatas - i)), 0.15)
                        end 

                    end),
                    cc.FadeIn:create(0.1),
                    cc.MoveBy:create(0.15, cc.p(0, 50))
                ),
                cc.CallFunc:create(function()
                    if i == #descrDatas then
                        self.viewStatus = ViewStatus.UPGRADE_END
                    end
                end)
            )
        )
        if i == #descrDatas then
            viewData.listView:reloadData()   
        end
    end
end
--[[
点击回调
--]]
function LobbyUpgradeView:CloseCallback()
    if self.viewStatus == ViewStatus.UPGRADE_ACTION then
    elseif self.viewStatus == ViewStatus.UPGRADE_END then
        self:SwitchView()
    elseif self.viewStatus == ViewStatus.AVATAR_ACTION then
    elseif self.viewStatus == ViewStatus.AVATAR_END then
        self.viewStatus = ViewStatus.CLOSE_ACTION
        self:runAction(
            cc.Sequence:create(
                cc.FadeOut:create(0.2),
                cc.RemoveSelf:create()
            )
        )
    end
end
function LobbyUpgradeView:SwitchView()
    self.viewStatus = ViewStatus.AVATAR_ACTION
    local viewData = self.viewData_
    self:runAction(
        cc.Sequence:create(
            cc.Spawn:create(
                cc.TargetedAction:create(
                    viewData.listView, cc.Sequence:create(
                        cc.Spawn:create(
                            cc.MoveBy:create(0.2, cc.p(0, -50)),
                            cc.FadeOut:create(0.2)
                        ),
                        cc.RemoveSelf:create()
                    )
                ),
                cc.TargetedAction:create(
                    viewData.line, cc.Sequence:create(
                        cc.Spawn:create(
                            cc.MoveBy:create(0.2, cc.p(0, -50)),
                            cc.FadeOut:create(0.2)
                        ),
                        cc.RemoveSelf:create()
                    )
                ),
                cc.TargetedAction:create(
                    viewData.levelUpLayout, cc.Sequence:create(
                        cc.Spawn:create(
                            cc.MoveBy:create(0.2, cc.p(0, -50)),
                            cc.FadeOut:create(0.2)
                        ),
                        cc.RemoveSelf:create()
                    )
                )
            ),
            cc.DelayTime:create(0.1),
            cc.Spawn:create(
                cc.TargetedAction:create(
                    viewData.giftLabel, cc.Spawn:create(
                        cc.Show:create(),
                        cc.MoveBy:create(0.15, cc.p(0, 50)),
                        cc.FadeIn:create(0.1)
                    )
                ),
                cc.TargetedAction:create(
                    viewData.giftLayout, cc.Sequence:create(
                        cc.DelayTime:create(0.05),
                        cc.Spawn:create(
                            cc.Show:create(),
                            cc.MoveBy:create(0.15, cc.p(0, 50)),
                            cc.FadeIn:create(0.1)
                        )
                    )
                )
            ),
            cc.CallFunc:create(function ()
                self.viewStatus = ViewStatus.AVATAR_END
            end)
        )
    )
end

function LobbyUpgradeView:GetIcoArrowAnimation(index)
    local ARROW_COUNT  = 3
    local repForAction =   cc.RepeatForever:create(cc.Sequence:create({
        cc.DelayTime:create((index-1) * 0.4),
        cc.FadeIn:create(0.8),
        cc.FadeOut:create(0.8),
        cc.DelayTime:create((ARROW_COUNT - index) * 0.4),
    }))
    return repForAction
end
return LobbyUpgradeView