local Mediator = mvc.Mediator

local AvatarFeedMediator = class("AvatarFeedMediator", Mediator)

local NAME = "AvatarFeedMediator"

local killGoodsId = 890005


local shareFacade = AppFacade.GetInstance()
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local socketMgr = AppFacade.GetInstance():GetManager('SocketManager')
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local GameScene = require( "Frame.GameScene" )
local AvatarFeedView = class('AvatarFeedView', GameScene)


local FoodView = class('FoodView', function()
    local layout = CLayout:create()
    layout.name = 'FoodView'
    layout:enableNodeEvents()
    return layout
end)

function FoodView:ctor(...)
    local args = unpack({...})
    self.id = args.id --卡牌的id

    local size = cc.size(560, 176)
    self:setContentSize(size)
    local function CreateFoodView()
        --创建食物页面
        -- local size = cc.size(600, 176)
        local view = CLayout:create(size)
        -- view:setBackgroundColor(cc.c4b(200,100,100,100))
        local bg = display.newImageView(_res('ui/common/common_bg_tips'), 0,0,{enable = true, scale9= true, size = size})
        display.commonUIParams(bg, {ap = display.LEFT_BOTTOM})
        view:addChild(bg,1)

        local arrowIcon = display.newImageView(_res('ui/common/common_bg_tips_horn'),size.width * 0.5,14, {
            ap = display.CENTER_TOP,
        })
        arrowIcon:setFlippedY(true)
        view:addChild(arrowIcon)

        local tipLabel = display.newLabel(size.width * 0.5, 152, fontWithColor(5,{text = __('选择食物给飨灵喂食')}))
        view:addChild(tipLabel,2)

        local listView = CListView:create(cc.size(size.width, 160))
        listView:setBounceable(false)
        listView:setDirection(eScrollViewDirectionHorizontal)
        display.commonUIParams(listView, {ap = display.CENTER_BOTTOM, po = cc.p(size.width * 0.5, 4)})
        view:addChild(listView,2)

        return {
            view = view,
            listView = listView,
        }
    end
    self.viewData = CreateFoodView()
    display.commonUIParams(self.viewData.view, {po = utils.getLocalCenter(self)})
    self:addChild(self.viewData.view,1)

    self:FreshData()

    self.touchEventListener = cc.EventListenerTouchOneByOne:create()
    self.touchEventListener:registerScriptHandler(function(touch,event)
        return true
    end,cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchEventListener:registerScriptHandler(function(touch, event)
        --处理点其他区域的逻辑
        local pos = touch:getLocation()
        local rect = self:getBoundingBox()
        if not cc.rectContainsPoint(rect, pos) then
            self:removeFromParent()
        end
    end, cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithFixedPriority(self.touchEventListener,1)

end

function FoodView:FreshData()
    self.viewData.listView:removeAllNodes()
    local size = self:getContentSize()
    for idx,val in ipairs(VIGOUR_RECOVERY_GOODS_ID) do
        local len = #VIGOUR_RECOVERY_GOODS_ID
        local lsize = cc.size( size.width / len, 134)
        local view = CLayout:create(cc.size(size.width/ len, 140))
        --goodsIcon
        local goodsIcon = display.newButton(lsize.width * 0.5, 80, {
            n = _res(string.format("arts/goods/goods_icon_%d.png", val))
        })
        goodsIcon:setTag(val)
        display.commonUIParams(goodsIcon, {ap = display.CENTER, po = cc.p(lsize.width * 0.5, 80)})
        goodsIcon:setScale(0.9)
        view:addChild( goodsIcon, 3)
        goodsIcon:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
            local goodsId = sender:getTag()
            local no = gameMgr:GetAmountByGoodId(goodsId)
            if no > 0 then
                local cardInfo = gameMgr:GetCardDataById(self.id)
                if cardInfo then
                    local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
                    if checkint(cardInfo.vigour) < maxVigour then
                        shareFacade:DispatchSignal(COMMANDS.COMMAND_FEED_AVATAR,{playerCardId = self.id, goodsId = goodsId, num = 1},'vigour')
                    else
                        uiMgr:ShowInformationTips(__('当前的他的活力值已满'))
                    end
                end
            else
                uiMgr:AddDialog("common.GainPopup", {goodId = goodsId})
            end
        end)

        local numberBg = display.newSprite(_res("ui/common/common_bg_number_01.png"))
        display.commonUIParams(numberBg, { po = cc.p( lsize.width * 0.5, 20)})
        view:addChild( numberBg, 3)

        local no = gameMgr:GetAmountByGoodId(val)
        local numberLabel = display.newLabel(70,12, {ap = display.RIGHT_CENTER, fontSize = 20, text = tostring(no), color = "ffffff"})
        numberBg:addChild(numberLabel, 4)

        self.viewData.listView:insertNodeAtLast(view)
    end

    self.viewData.listView:reloadData()
end

function FoodView:onCleanup()
    if self.touchEventListener then
        self:getEventDispatcher():removeEventListener(self.touchEventListener)
    end
end


-------------------------------------------------
-- AvatarFeedMediator
-------------------------------------------------

function AvatarFeedView:ctor(...)
	self.super.ctor(self,'views.AvatarFeedView')
    local args = unpack({...})
    local touchView = CColorView:create(cc.c4b(100,100,100,0))
    touchView:setContentSize(display.size)
    touchView:setTouchEnabled(true)
    display.commonUIParams(touchView, { po = display.center})
    touchView:setOnClickScriptHandler(function(sender)
        AppFacade.GetInstance():UnRegsitMediator(NAME)
    end)
    self:addChild(touchView)

    -- dump(args)
    self.isRequesting = false -- 正在请求中的逻辑
    local vType = checkint(args.type)
    self.friendData = args.friendData
    self.vType = vType

    -------------------------------------------------
    --服务员界面的逻辑
    if vType == 1 then
        self.id = args.id --喂的卡的id

        local bgImage = display.newImageView(_res('avatar/ui/restaurant_info_bg'), -60, 0,{ap = display.LEFT_BOTTOM})
        self:addChild(bgImage,1)
        if bgImage:getContentSize().width < 60 + display.width then
            bgImage:setPositionX(display.width - bgImage:getContentSize().width)
        end

        --添加卡牌页面
        local cardInfo = self.friendData and {} or gameMgr:GetCardDataById(self.id)
        local skinId = self.friendData and self.friendData.skinId or cardInfo.defaultSkinId
        local role = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
        role:setToSetupPose()
        role:setAnimation(0, 'idle', true)
        display.commonUIParams(role, {po = cc.p(display.SAFE_L + 122, 30)})
        self:addChild(role,1)

        local progressBG = display.newImageView(_res('avatar/ui/recovery_bg'), {
            scale9 = true, size = cc.size(168,32)
        })
        display.commonUIParams(progressBG, {po = cc.p(display.SAFE_L + 106, 24)})
        self:addChild(progressBG,2)

        local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_red.png'))
        operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
        operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        operaProgressBar:setAnchorPoint(cc.p(0, 0.5))
        operaProgressBar:setMaxValue(100)
        operaProgressBar:setValue(0)
        operaProgressBar:setPosition(cc.p(display.SAFE_L + 26, 24))
        self:addChild(operaProgressBar,5)

        local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
        vigourProgressBarTop:setAnchorPoint(cc.p(0,0.5))
        vigourProgressBarTop:setPosition(cc.p(display.SAFE_L + 24,24))
        self:addChild(vigourProgressBarTop,6)

        local vigourNum   = self.friendData and self.friendData.vigour or cardInfo.vigour
        local vigourLabel = display.newLabel(display.SAFE_L + 26 + operaProgressBar:getContentSize().width + 4, operaProgressBar:getPositionY(),{
            ap = display.LEFT_CENTER, fontSize = 18, color = 'ffffff', text = tostring(vigourNum)
        })
        self:addChild(vigourLabel, 6)

        local cardId = self.friendData and self.id or cardInfo.cardId
        local nameLabel = display.newLabel(display.SAFE_L + 260, 78, fontWithColor(14, {text = CardUtils.GetCardConfig(checkint(cardId)).name, fontSize = 28, color = '9b552f'}))
        display.commonUIParams(nameLabel, {ap = display.LEFT_BOTTOM})
        self:addChild(nameLabel, 2)
        self.nameLabelParams = fontWithColor(14, {fontSize = 28, color = '9b552f', fontSizeN = 28, colorN = '9b552f'})
        if not self.friendData then
            CommonUtils.SetCardNameLabelStringById(nameLabel, gameMgr:GetCardDataByCardId(cardId).id, self.nameLabelParams)
        else
            if self.friendData.cardName then
                CommonUtils.SetCardNameLabelStringByIdUseSysFont(nameLabel, 0, self.nameLabelParams, self.friendData.cardName)
            end
        end

        local text = __('服务员')
        if not self.friendData then
            local supervisor = checktable(gameMgr:GetUserInfo().supervisor)
            local chef = checktable(gameMgr:GetUserInfo().chef)
            for name,val in pairs(supervisor) do
                if checkint(val) == checkint(self.id) then
                    text = __('主管')
                    break
                end
            end
            for name,val in pairs(chef) do
                if checkint(val) == checkint(self.id) then
                    text = __('厨师')
                    break
                end
            end
        end

        local descrLabel = display.newLabel(display.SAFE_L + 260 + nameLabel:getContentSize().width + 10, 70, fontWithColor(4,{text = text}))
        display.commonUIParams(descrLabel, {ap = display.LEFT_BOTTOM})
        self:addChild(descrLabel, 2)

        -------------------------------------------------
        -- function buttons

        -- food
        local feedButton = display.newButton(display.SAFE_R - 186, 60,{
            n = _res('avatar/ui/refresh_main_ico_eat_food')
        })
        self:addChild(feedButton,2)
        local textLabel = display.newButton(feedButton:getContentSize().width * 0.5, 16,{
            n = _res('avatar/ui/card_bar_bg'),enable = false
        })
        display.commonLabelParams(textLabel, fontWithColor(14,{text = __('喂食'),color = 'ffffff'}))
        feedButton:addChild(textLabel)
        feedButton:setOnClickScriptHandler(function(sender)
            --显示喂食页面
            PlayAudioByClickNormal()
            local node = self:getChildByTag(8888)
            if node then node:removeFromParent() end
            local foodView = FoodView.new({id = self.id})
            display.commonUIParams(foodView, {ap = display.CENTER_BOTTOM, po = cc.p(992, 140)})
            foodView:setTag(8888)
            self:addChild(foodView, 20)
        end)

        -- effect
        local effectButton = display.newButton(display.SAFE_R - 344, 66,{
            n = _res('avatar/ui/card_btn_tabs_skill_selected')
        })
        self:addChild(effectButton,2)
        local textLabel = display.newButton(effectButton:getContentSize().width * 0.5, 16,{
            n = _res('avatar/ui/card_bar_bg'),enable = false
        })
        display.commonLabelParams(textLabel, fontWithColor(14,{text = __('效果'),color = 'ffffff'}))
        effectButton:addChild(textLabel)
        effectButton:setOnClickScriptHandler(function(sender)
            --效果页面
            PlayAudioByClickNormal()
            local node = self:getChildByTag(8889)
            if node then node:removeFromParent() end
            if self.friendData then
                node = require('common.CardKitchenNode').new({friendData = self.friendData})
            else
                node = require('common.CardKitchenNode').new({id = self.id})
            end
            display.commonUIParams(node, {po = display.center})
            node:setTag(8889)
            self:addChild(node, 20)
        end)

        if self.friendData then
            feedButton:setVisible(false)
            effectButton:setPosition(feedButton:getPosition())
        end

        -- ice
        local iceButton = display.newButton(display.SAFE_R - 502, 66,{
            n = _res("ui/home/nmain/restaurant_info_btn_go_to_rest.png")
        })
        self:addChild(iceButton,2)
        local textLabel = display.newButton(iceButton:getContentSize().width * 0.5, 16,{
            n = _res('avatar/ui/card_bar_bg'),enable = false
        })
        display.commonLabelParams(textLabel, fontWithColor(14,{text = __('进入冰场'),color = 'ffffff'}))
        iceButton:addChild(textLabel)
        iceButton:setOnClickScriptHandler(function(sender)
            --效果页面
            PlayAudioByClickNormal()
            if self.isRequesting then return end
            self.isRequesting = true
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function()
                self.isRequesting = false
            end)))
            if CommonUtils.UnLockModule(RemindTag.ICEROOM, true) then
                for k,v in pairs( gameMgr:GetUserInfo().employee ) do
                    if checkint(v) == checkint(self.id) then
                        app:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE_HOME , {employeeId = k ,isIcePlace = 1 })
                        --socketMgr:SendPacket( NetCmd.RequestEmploySwich, {employeeId = k, icePlaceId = 1, isIcePlace = 1})
                        break
                    end
                end
            end
        end)

        if self.friendData or not CommonUtils.GetModuleAvailable(MODULE_SWITCH.ICEROOM) then
            iceButton:setVisible(false)
        end

        self.viewData = {
            roleNode = role,
            vigourProgressBar = operaProgressBar,
            vigourLabel = vigourLabel,
            nameLabel = nameLabel,
            timeLabel = timeLabel,
            feedButton = feedButton,
        }

    -------------------------------------------------
    --凳子的信息的逻辑
    elseif vType == 2 then
        self.id = args.id --喂的卡的id
        local bgImage = display.newImageView(_res('avatar/ui/restaurant_info_bg'), -60, 0,{ap = display.LEFT_BOTTOM})
        self:addChild(bgImage,1)
        if bgImage:getContentSize().width < 60 + display.width then
            bgImage:setPositionX(display.width - bgImage:getContentSize().width)
        end
        --添加卡牌页面
        local role = AssetsUtils.GetRestaurantSmallAvatarNode(self.id,0,0)
        display.commonUIParams(role, {po = cc.p(display.SAFE_L + 122, 100)})
        self:addChild(role,1)

        local avatarInfo = CommonUtils.GetConfigNoParser("restaurant", 'avatar', self.id)
        local nameLabel = display.newLabel(display.SAFE_L + 260, 78, fontWithColor(14, {text = avatarInfo.name, fontSize = 28, color = '9b552f'}))
        display.commonUIParams(nameLabel, {ap = display.LEFT_BOTTOM})
        self:addChild(nameLabel, 2)

        -- local descrLabel = display.newLabel(260 + nameLabel:getContentSize().width + 10, 70, fontWithColor(4,{text = __('')}))
        -- display.commonUIParams(descrLabel, {ap = display.LEFT_BOTTOM})
        -- self:addChild(descrLabel, 2)

        local effects = checktable(avatarInfo.buffType)
        local text = ''
        for name,val in pairs(effects) do
            local buffInfo = CommonUtils.GetConfigNoParser('restaurant', 'buffType', val.targetType)
            if buffInfo then
                local descr = CommonUtils.GetBufferDescription(buffInfo.descr, val)
                text = descr .. '\n'
            end
        end
        -- local timeLabel = display.newLabel(260, 16,{text = string.format("效果：%s", text), fontSize = 22, color = '5c5c5c', font = TTF_GAME_FONT, ttf = true})
        local timeLabel = display.newLabel(display.SAFE_L + 260, 36,{text = tostring(avatarInfo.descr), fontSize = 22, color = '5c5c5c'})--, font = TTF_GAME_FONT, ttf = true
        display.commonUIParams(timeLabel, {ap = display.LEFT_BOTTOM})
        self:addChild(timeLabel,2)

        self.viewData = {
            roleNode = role,
            nameLabel = nameLabel,
            timeLabel = timeLabel,
        }


    -------------------------------------------------
    --霸王餐的逻辑特殊餐
    elseif vType == 3 then
        local tempNameLabel = nil
        self.data = args.data --客人的相关显示的逻辑
        local seatInfo = checktable(self.data.seatInfo)
        -- dump(seatInfo)
        local bgImage = display.newImageView(_res('avatar/ui/restaurant_info_bg'), -60, 0,{ap = display.LEFT_BOTTOM, enable = true})
        self:addChild(bgImage,1)
        if bgImage:getContentSize().width < 60 + display.width then
            bgImage:setPositionX(display.width - bgImage:getContentSize().width)
        end
        --添加卡牌页面
        local pathPrefix = string.format("avatar/visitors/%s", tostring(seatInfo.customerId))
        local descr = ''
        if checkint(seatInfo.isSpecialCustomer) == 1 then
            local customerData = CommonUtils.GetConfigNoParser('restaurant', 'specialCustomer', seatInfo.customerId)
            if customerData and customerData.type then
                pathPrefix = string.format('avatar/visitors/%s', tostring(customerData.type))
                local avatarInfo = CommonUtils.GetConfigNoParser("restaurant", 'customer', customerData.type)
                descr = tostring(avatarInfo.descr)
                local nameLabel = display.newLabel(display.SAFE_L + 260, 78, fontWithColor(14, {text = customerData.name, fontSize = 28, color = '9b552f'}))
                display.commonUIParams(nameLabel, {ap = display.LEFT_BOTTOM})
                self:addChild(nameLabel, 2)
                tempNameLabel = nameLabel
            end
        else
            local avatarInfo = CommonUtils.GetConfigNoParser("restaurant", 'customer', seatInfo.customerId)
            descr = tostring(avatarInfo.descr)
            local nameLabel = display.newLabel(display.SAFE_L + 260, 78, fontWithColor(14, {text = avatarInfo.name, fontSize = 28, color = '9b552f'}))
            display.commonUIParams(nameLabel, {ap = display.LEFT_BOTTOM})
            self:addChild(nameLabel, 2)
            tempNameLabel = nameLabel
        end

        if utils.isExistent(string.format("%s.json", pathPrefix)) then
            local role = sp.SkeletonAnimation:create(string.format("%s.json", pathPrefix),string.format('%s.atlas', pathPrefix), 0.5)
            role:setToSetupPose()
            role:setAnimation(0, 'run', true)
            display.commonUIParams(role, {po = cc.p(display.SAFE_L + 120, 20)})
            self:addChild(role,1)
        end

        local updateHelpInfo = function()
        end
        --[[
        -- 霸王餐客人来打我的逻辑
        --]]
        if seatInfo.questEventId then
            --霸王餐的逻辑
            local questEventInfos = CommonUtils.GetConfigNoParser('restaurant', 'questEvent', seatInfo.questEventId)
            local rewardsLabel = display.newButton(display.SAFE_L + 670, 104, {
                n = _res('ui/common/common_title_5'), enable = false , scale9 = true
            })
            display.commonLabelParams(rewardsLabel, fontWithColor(2,{text = __('可能获得'), color = '6c6c6c',paddingW = 30 }))
            self:addChild(rewardsLabel,3)



            local speakBtn = display.newButton(display.SAFE_L + 210, 280, {n = _res('ui/home/lobby/cooking/common_ico_expression_1.png'), enable = false})
            self:addChild(speakBtn,1)
            display.commonLabelParams(speakBtn,fontWithColor(2,{text = __('来打我呀，来打我呀'), color = '#5c5c5c',fontSize = 22,hAlign = cc.TEXT_ALIGNMENT_CENTER,offset = cc.p(0,0),w = 250,h = 50}))
            --添加奖励
            local rewards = {}
            if self.friendData then
                local restaurantEventConf = CommonUtils.GetConfigAllMess('restaurantEvent', 'friend') or {}
                rewards = checktable(restaurantEventConf.rewards)
            else
                local questInfo = CommonUtils.GetConfigNoParser('restaurant', 'quest', questEventInfos.questId) or {}
                rewards = checktable(questInfo.rewards)
            end
            if table.nums(rewards) > 0 then
                local distanceWidth = 100
                local needSize = cc.size(distanceWidth * #rewards, 108)
                local layout = CLayout:create(needSize)

                for i =1 , #rewards do
                    local data = rewards[i]
                    local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = true})
                    display.commonUIParams(goodNode, {animate = false, cb = function (sender)
                        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
                    end})
                    goodNode:setAnchorPoint(cc.p(0.5,0.5))
                    goodNode:setPosition(cc.p((i-0.5)*distanceWidth ,needSize.height/2))
                    goodNode:setScale(0.76)
                    layout:addChild(goodNode)
                end
                display.commonUIParams(layout, {ap = display.LEFT_BOTTOM, po = cc.p(display.SAFE_L + 520, -10)})
                self:addChild(layout,3)
            end

            -- set free buttom
            local letGoButton = display.newButton(display.SAFE_L + 1010, 40, {n = _res('ui/common/common_btn_white_default.png'),ap = display.RIGHT_BOTTOM , scale9 = true })
            display.commonLabelParams(letGoButton, fontWithColor(14, {text = __('让他离开')}))
            local letGoButtonLabelSize = display.getLabelContentSize(letGoButton:getLabel())
            local letGoButtonSize =  letGoButton:getContentSize()
            if letGoButtonLabelSize.width+20  >  letGoButtonSize.width  then

                if letGoButtonLabelSize.width > 160 then
                    display.commonLabelParams(letGoButton, fontWithColor(14, {text = __('让他离开') , reqW =160 }))
                    letGoButton:setContentSize(cc.size(160+ 20 ,letGoButtonSize.height ))
                else
                    display.commonLabelParams(letGoButton, fontWithColor(14, {text = __('让他离开') ,paddingW = 20  }))
                end
            end

            letGoButton:setOnClickScriptHandler(function(sender)
                PlayAudioByClickNormal()
                local mediator = AppFacade.GetInstance():RetrieveMediator(NAME)
                if mediator then
                    if mediator.isLeaved == 0 then
                        local seatInfo = checktable(self.data.seatInfo)
                        AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_CANCEL_QUEST, {seatId = seatInfo.seatId})
                    else
                        uiMgr:ShowInformationTips(__('当前霸王餐客人已离开'))
                    end
                end
            end)
            self:addChild(letGoButton,3)

            -- help button
            local helpButton = display.newButton(letGoButton:getPositionX()+85 , letGoButton:getPositionY(),
                {n = _res('ui/common/common_btn_orange.png'), d = _res('ui/common/common_btn_orange_disable.png'), ap = display.CENTER_BOTTOM})
            self:addChild(helpButton,3)

            local helpCountLabel = display.newLabel(helpButton:getPositionX()-90, helpButton:getPositionY() - 18, fontWithColor(6))
            self:addChild(helpCountLabel,3)

            updateHelpInfo = function()
                local helpCount = checkint(gameMgr:GetUserInfo().restaurantEventNeedHelpLeftTimes)
                display.commonLabelParams(helpCountLabel, {text = string.fmt(__('今日剩余_num_次'),  {_num_ = helpCount}   ) , reqW= 350 })

                local hasHelp  = checkint(gameMgr:GetUserInfo().avatarCacheData.hasEventHelp) == 1
                display.commonLabelParams(helpButton, fontWithColor(14, {text = hasHelp and __('求助中') or __('求助')}))

                helpButton:setEnabled(helpCount > 0 and hasHelp == false)
            end
            updateHelpInfo()

            if CommonUtils.GetModuleAvailable(MODULE_SWITCH.FRIEND) then
                display.commonUIParams(helpButton, {cb = function(sender)
                    PlayAudioByClickNormal()
                    local mediator = AppFacade.GetInstance():RetrieveMediator(NAME)
                    if mediator then
                        mediator:SendSignal(POST.RESTAURANT_QUEST_HELP.cmdName)
                    end
                end})
            else
                helpButton:setVisible(false)
            end
            display.commonUIParams(helpButton, {cb = function(sender)
                PlayAudioByClickNormal()
                local mediator = AppFacade.GetInstance():RetrieveMediator(NAME)
                if mediator then
                    mediator:SendSignal(POST.RESTAURANT_QUEST_HELP.cmdName)
                end
            end})

            -- to quest button
            local kickButton = display.newButton(display.SAFE_R - 10, 20, {n = _res('ui/common/common_btn_explore'),ap = display.RIGHT_BOTTOM})
            display.commonLabelParams(kickButton, fontWithColor(14, {text = __('揍他'), offset = cc.p(-5,0)}))
            self:addChild(kickButton,3)
            kickButton:setOnClickScriptHandler(function(sender)
                PlayAudioByClickNormal()
                local toBattleFunc = function(isFriend)
                    ------------ 战斗准备界面 ------------
                    local mediator = AppFacade.GetInstance():RetrieveMediator(NAME)
                    if mediator then
                        if mediator.isLeaved == 0 then
                            local battleReadyData = BattleReadyConstructorStruct.New(
                                1,
                                gameMgr:GetUserInfo().localCurrentBattleTeamId,
                                gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
                                checkint(questEventInfos.questId),
                                CommonUtils.GetQuestBattleByQuestId(questEventInfos.questId),
                                nil,
                                isFriend and POST.RESTAURANT_HELP_QUEST_AT.cmdName or POST.RESTAURANT_QUEST_AT.cmdName,
                                isFriend and {friendId = self.friendData.friendId} or {},
                                isFriend and POST.RESTAURANT_HELP_QUEST_AT.sglName or POST.RESTAURANT_QUEST_AT.sglName,
                                isFriend and POST.RESTAURANT_HELP_QUEST_GRADE.cmdName or POST.RESTAURANT_QUEST_GRADE.cmdName,
                                isFriend and {friendId = self.friendData.friendId} or {},
                                isFriend and POST.RESTAURANT_HELP_QUEST_GRADE.sglName or POST.RESTAURANT_QUEST_GRADE.sglName,
                                NAME,
                                "AvatarMediator"
                            )
                            ------------ 战斗准备界面 ------------
                            AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_UI_Create_Battle_Ready, battleReadyData)

                        else
                            uiMgr:ShowInformationTips(__('当前霸王餐客人已离开'))
                        end
                    end
                end

                if self.friendData then
                    if checkint(gameMgr:GetUserInfo().restaurantEventHelpLeftTimes) > 0 then
                        local friendTip = __('帮助好友打霸王餐将会消耗一个今日次数，是否继续帮忙？')
                        local commonTip = require('common.CommonTip').new({text = friendTip, callback = function()
                            gameMgr:GetUserInfo().avatarFriendCacheData_ = {friendId = checkint(self.friendData.friendId)}
                            toBattleFunc(true)
                        end})
                        commonTip:setPosition(display.center)
                        uiMgr:GetCurrentScene():AddDialog(commonTip)
                    else
                        uiMgr:ShowInformationTips(__('今日帮忙打霸王餐次数已用光'))
                    end
                    return
                else
                    toBattleFunc()
                end
            end)

            -- name tips
            if tempNameLabel then
                local tipsButton = display.newButton(tempNameLabel:getPositionX() + tempNameLabel:getBoundingBox().width + 2, 70, {
                    n = _res('ui/common/common_btn_tips'),ap = display.LEFT_BOTTOM
                })
                tipsButton:setOnClickScriptHandler(function(sender)
                    PlayAudioByClickNormal()
                    uiMgr:ShowInformationTipsBoard({targetNode = sender, descr = __('这是霸王餐描述'), type = 5})
                end)
                self:addChild(tipsButton,2)
            end

            if self.friendData then
                helpButton:setVisible(false)
                letGoButton:setVisible(false)
                helpCountLabel:setVisible(false)

                local hasEventHelp = false
                for _, friend in ipairs(gameMgr:GetUserInfo().friendList) do
                    if checkint(friend.friendId) == checkint(self.friendData.friendId) then
                        hasEventHelp = checkint(friend.restaurantQuestEvent) > 1
                        break
                    end
                end
                kickButton:setVisible(hasEventHelp)
            end

        else
            --显不描述的逻辑
            local labelParser = require("Game.labelparser")
            local parseData = labelParser.parse(descr)
            if parseData and table.nums(parseData) > 0 then
                local t = {}
                for idx,v in ipairs(parseData) do
                    local x = fontWithColor(6,{text = v.content , fontSize = 22, color = '5c5c5c',descr = v.labelname})
                    if v.labelname == 'b' then
                        x = fontWithColor(6,{text = v.content , fontSize = 22, color = 'ff4848',descr = v.labelname})
                    end
                    table.insert(t,x)
                end
                local timeLabel = display.newRichLabel(display.SAFE_L + 260, 70,
                    { w = 95 ,sp = 10,ap = display.LEFT_TOP, c = t
                })
                self:addChild(timeLabel,2)
                timeLabel:reloadData()
            end
            if tempNameLabel then
                local tipsButton = display.newButton(tempNameLabel:getPositionX() + tempNameLabel:getBoundingBox().width + 2, 70, {
                    n = _res('ui/common/common_btn_tips'),ap = display.LEFT_BOTTOM
                })
                tipsButton:setOnClickScriptHandler(function(sender)
                    PlayAudioByClickNormal()
                    uiMgr:ShowInformationTipsBoard({targetNode = sender, descr = __('菜品越符合顾客的喜好，拿到的小费就越多哦'), type = 5})
                end)
                self:addChild(tipsButton,2)
            end
            -- local timeLabel = display.newLabel(260, 36,{text = descr, fontSize = 22, color = '5c5c5c', font = TTF_GAME_FONT, ttf = true})
            -- display.commonUIParams(timeLabel, {ap = display.LEFT_BOTTOM})
            -- self:addChild(timeLabel,2)
        end
        -- local descrLabel = display.newLabel(260 + nameLabel:getContentSize().width + 10, 70, fontWithColor(4,{text = __('')}))
        -- display.commonUIParams(descrLabel, {ap = display.LEFT_BOTTOM})
        -- self:addChild(descrLabel, 2)

        -- local timeLabel = display.newLabel(260, 16,{text = string.format("效果：%s", text), fontSize = 22, color = '5c5c5c', font = TTF_GAME_FONT, ttf = true})
        -- display.commonUIParams(timeLabel, {ap = display.LEFT_BOTTOM})
        -- [[ self:addChild(timeLabel,2) ]]

        self.viewData = {
            roleNode = role,
            nameLabel = nameLabel,
            timeLabel = timeLabel,
            updateHelpInfo = updateHelpInfo,
        }


    -------------------------------------------------
    --餐厅虫子
    elseif vType == 4 then
        local restaurantBugConf = CommonUtils.GetConfigAllMess('restaurantBug', 'friend') or {}

        self.id = args.id  -- bug area id
        local bgImage = display.newImageView(_res('avatar/ui/restaurant_info_bg'), -60, 0,{ap = display.LEFT_BOTTOM, enable = true})
        self:addChild(bgImage)
        if bgImage:getContentSize().width < 60 + display.width then
            bgImage:setPositionX(display.width - bgImage:getContentSize().width)
        end

        -- head
        local bugSpinePath    = 'avatar/ui/spine/cangying'
        local shareSpineCache = SpineCache(SpineCacheName.GLOBAL)
        if not shareSpineCache:hasSpineCacheData(bugSpinePath) then
            shareSpineCache:addCacheData(bugSpinePath, bugSpinePath, 1)
        end
        local bugSpine = shareSpineCache:createWithName(bugSpinePath)
        bugSpine:setAnimation(0, 'idle', true)
        bugSpine:setPosition(cc.p(display.SAFE_L + 120, 20))
        bugSpine:setScale(0.7)
        self:addChild(bugSpine)

        local speakBar = display.newButton(display.SAFE_L + 210, 280, {n = _res('ui/home/lobby/cooking/common_ico_expression_1.png'), enable = false})
        display.commonLabelParams(speakBar, fontWithColor(2,{text = __('打我呀，来打我呀！'), color = '#5c5c5c', fontSize = 22, hAlign = display.TAC, offset = cc.p(0,0), w = 250}))
        self:addChild(speakBar)

        -- rewards
        local rewardsLabel = display.newButton(display.SAFE_L + 720, 105, {n = _res('ui/common/common_title_5'), enable = false})
        display.commonLabelParams(rewardsLabel, fontWithColor(2,{text = __('奖励'), color = '6c6c6c'}))
        self:addChild(rewardsLabel)

        local killRewards = checktable(restaurantBugConf.rewards)
        local rewardLayer = display.newLayer(rewardsLabel:getPositionX(), 44, {ap = display.CENTER})
        self:addChild(rewardLayer)

        if table.nums(killRewards) > 0 then
            local goodsNodeGap = 100
            local goodsOffsetX = rewardLayer:getContentSize().width/2 - (#killRewards * goodsNodeGap)/2
            local goodsOffsetY = rewardLayer:getContentSize().height/2
            for i, goodsData in ipairs(killRewards) do
                local goodsNode = require('common.GoodNode').new({id = checkint(goodsData.goodsId), amount = checkint(goodsData.num), showAmount = true})
                goodsNode:setPosition(cc.p(goodsOffsetX + (i-0.5)*goodsNodeGap, goodsOffsetY))
                goodsNode:setAnchorPoint(display.CENTER)
                goodsNode:setScale(0.76)
                rewardLayer:addChild(goodsNode)

                display.commonUIParams(goodsNode, {animate = false, cb = function (sender)
                    uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(goodsData.goodsId), type = 1})
                end})
            end
        end

        -- name
        local nameLabel = display.newLabel(display.SAFE_L + 260, 78, fontWithColor(14, {text = tostring(restaurantBugConf.name), fontSize = 28, color = '9b552f', ap = display.LEFT_BOTTOM}))
        self:addChild(nameLabel)

        local tipsButton = display.newButton(nameLabel:getPositionX() + display.getLabelContentSize(nameLabel).width + 25, 95, {n = _res('ui/common/common_btn_tips')})
        tipsButton:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
            uiMgr:ShowInformationTipsBoard({targetNode = sender, type = 5, descr = tostring(restaurantBugConf.descr)})
        end)
        self:addChild(tipsButton)

        -- help button
        local helpButton = display.newButton(display.SAFE_R - 360, 75, {n = _res('ui/common/common_btn_orange.png'), d = _res('ui/common/common_btn_orange_disable.png')})
        display.commonLabelParams(helpButton, fontWithColor(14, {text = __('求助')}))
        self:addChild(helpButton)

        -- kill button
        local killButton = display.newButton(helpButton:getPositionX() + 150, helpButton:getPositionY(), {n = _res('ui/common/common_btn_white_default.png')})
        display.commonLabelParams(killButton, fontWithColor(14, {text = __('猎杀')}))
        self:addChild(killButton)

        local helpStatusLabel = display.newLabel(helpButton:getPositionX() -20 , helpButton:getPositionY() - 50, fontWithColor(6))
        display.commonLabelParams(helpStatusLabel, {text = __('已发送求助') , reqW = 230})
        self:addChild(helpStatusLabel)

        local iconPath = CommonUtils.GetGoodsIconPathById(killGoodsId)
        local killIcon = display.newImageView(_res(iconPath), killButton:getPositionX() - 15, helpStatusLabel:getPositionY(), {ap = display.RIGHT_CENTER, scale = 0.28})
        self:addChild(killIcon)

        local propCountLabel = display.newLabel(killButton:getPositionX() - 15, killIcon:getPositionY(), fontWithColor(19, {ap = display.LEFT_CENTER}))
        self:addChild(propCountLabel)

        local helpCountLabel = display.newLabel(killButton:getPositionX(), killButton:getPositionY() - 52, fontWithColor(6))
        self:addChild(helpCountLabel,3)

        -------------------------------------------------
        local updateHelpButton = function()
            local hasBugHelp = checkint(checktable(gameMgr:GetUserInfo().avatarCacheData).hasBugHelp) == 1
            helpButton:setEnabled(not hasBugHelp)
            helpStatusLabel:setVisible(hasBugHelp)
        end

        local updatePropCount = function()
            local propCount = checkint(gameMgr:GetAmountByGoodId(killGoodsId))
            display.commonLabelParams(propCountLabel, {text = string.fmt('x_num_', {_num_ = propCount})})

            local killButtonImg = propCount > 0 and _res('ui/common/common_btn_white_default.png') or _res('ui/common/common_btn_orange_disable.png')
            killButton:setNormalImage(killButtonImg)
            killButton:setSelectedImage(killButtonImg)
        end

        local updateHelpInfo = function()
            local helpCount = checkint(gameMgr:GetUserInfo().restaurantCleaningLeftTimes)
            display.commonLabelParams(helpCountLabel, {text = string.fmt(__('今日剩余_num_次'), {_num_ = helpCount})})
        end

        if self.friendData then
            updateHelpInfo()
            helpButton:setVisible(not CommonUtils.GetModuleAvailable(MODULE_SWITCH.FRIEND))
            killIcon:setVisible(false)
            propCountLabel:setVisible(false)
            helpStatusLabel:setVisible(false)
        else
            updatePropCount()
            updateHelpButton()
            helpCountLabel:setVisible(false)
        end

        -------------------------------------------------
        if CommonUtils.GetModuleAvailable(MODULE_SWITCH.FRIEND) then
            display.commonUIParams(helpButton, {cb = function(sender)
                PlayAudioByClickNormal()
                local mediator = AppFacade.GetInstance():RetrieveMediator(NAME)
                if mediator then
                    mediator:SendSignal(POST.RESTAURANT_BUG_HELP.cmdName)
                end
            end})
        else
            helpButton:setVisible(false)
        end

        display.commonUIParams(killButton, {cb = function(sender)
            local mediator = AppFacade.GetInstance():RetrieveMediator(NAME)
            if mediator then
                if self.friendData then
                    if checkint(gameMgr:GetUserInfo().restaurantCleaningLeftTimes) > 0 then
                        local friendTip = __('帮助好友打扫将会消耗一个今日次数，是否继续帮忙打扫？')
                        local commonTip = require('common.CommonTip').new({text = friendTip, callback = function()
                            mediator:SendSignal(POST.RESTAURANT_BUG_CLEAN.cmdName, {bugId = checkint(self.id), friendId = checkint(self.friendData.friendId)})
                        end})
                        commonTip:setPosition(display.center)
                        uiMgr:GetCurrentScene():AddDialog(commonTip)
                    else
                        uiMgr:ShowInformationTips(__('今日帮忙打扫次数已用光'))
                    end
                else
                    local propCount = checkint(gameMgr:GetAmountByGoodId(killGoodsId))
                    if propCount > 0 then
                        mediator:SendSignal(POST.RESTAURANT_BUG_CLEAN.cmdName, {bugId = checkint(self.id)})
                    else
                        local goodsConf = CommonUtils.GetConfig('goods', 'other', killGoodsId) or {}
                        uiMgr:ShowInformationTips(string.fmt(__('道具【_name_】不足，请多留意商城~'), {_name_ = tostring(goodsConf.name)}))
                    end
                end
            end
        end})

        self.viewData = {
            updatePropCount  = updatePropCount,
            updateHelpButton = updateHelpButton,
        }

    end
end

function AvatarFeedView:UpdateVigour(id, vigour)
    if self.vType == 1 then
        --喂食的逻辑
        self.viewData.vigourLabel:setString(tostring(vigour))
        local maxVigour = app.restaurantMgr:getCardVigourLimit(id)
        self:UpdateFriendValue(maxVigour, vigour)
    end
end
function AvatarFeedView:UpdateFriendValue(maxVigour, vigour)
    if self.vType == 1 then
        local ratio = (vigour / maxVigour) * 100
        self.viewData.vigourProgressBar:setValue(rangeId(ratio, 100))
        if (ratio > 40 and (ratio <= 60)) then
            self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_yellow.png')
        elseif ratio > 60 then
            self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_green.png')
        end
    end
end

function AvatarFeedView:onCleanup()
    --清除相关计时器的逻辑
end


-------------------------------------------------
-- AvatarFeedMediator
-------------------------------------------------

function AvatarFeedMediator:ctor( data, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.data = data
    self.id = data.id
    self.isLeaved = 0
    self.type = checkint(data.type)
    self.friendData = data.friendData
end

function AvatarFeedMediator:VisitorIsLeave(isLeave)
    self.isLeaved = checkint(isLeave)
end



function AvatarFeedMediator:InterestSignals()
	local signals = {
        SIGNALNAMES.Exploration_AddVigour_Callback,
        EVENT_EAT_FOODS,
        SIGNALNAMES.IcePlace_Home_Callback,
        POST.RESTAURANT_BUG_HELP.sglName,
        POST.RESTAURANT_BUG_CLEAN.sglName,
        POST.RESTAURANT_QUEST_HELP.sglName,
	}
	return signals
end

function AvatarFeedMediator:ProcessSignal(signal )
	local name = signal:GetName()
    local body = signal:GetBody()
    -- dump(body)
    if name == SIGNALNAMES.Exploration_AddVigour_Callback then
        --喂食卡牌
        local id = body.requestData.playerCardId
        local goodsId = body.requestData.goodsId
        local vigour = checkint(body.vigour)
        --更新道具数量本地缓存
        local card = gameMgr:GetCardDataById(id)
        gameMgr:UpdateCardDataById(id,{vigour = vigour})
        CommonUtils.DrawRewards({{goodsId = goodsId, num = -1}})
        --更新喂食面板
        self:GetViewComponent():UpdateVigour(card.id,vigour) --更新喂后的活力值新鲜度
        --更新活动值人物状态
        local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
        avatarMediator:ChangeWaiterState(id)
        local foodView = self.viewComponent:getChildByTag(8888)
        if foodView then
            foodView:FreshData() --刷新列表的逻辑
        end
        if shareFacade:RetrieveMediator('AvatarMediator') then
            shareFacade:RetrieveMediator('AvatarMediator'):PushRequestQueue(6007)
            shareFacade:DispatchObservers(EVENT_EAT_FEED,{cardId = self.id})
        end
        CommonUtils.PlayCardSoundByCardId(card.cardId, SoundType.TYPE_ICEROOM_RANDOM, SoundChannel.CARD_FEED)

    elseif name == EVENT_EAT_FOODS then
        --喂食的逻辑
         --更新喂食面板
        local card = gameMgr:GetCardDataById(self.id)
        self:GetViewComponent():UpdateVigour(card.id,checkint(card.vigour))

    elseif name == POST.RESTAURANT_BUG_HELP.sglName then
        checktable(gameMgr:GetUserInfo().avatarCacheData).hasBugHelp = 1
        self:GetViewComponent().viewData:updateHelpButton()

    elseif name == POST.RESTAURANT_BUG_CLEAN.sglName then
        if self.friendData then
            local friendAvatarMediator = shareFacade:RetrieveMediator('FriendAvatarMediator')
            friendAvatarMediator:removeBugAt(self.id)

            gameMgr:GetUserInfo().restaurantCleaningLeftTimes = checkint(gameMgr:GetUserInfo().restaurantCleaningLeftTimes) - 1
            friendAvatarMediator:updateFriendInfo()

            gameMgr:GetUserInfo().avatarFriendVisitData_ = gameMgr:GetUserInfo().avatarFriendVisitData_ or {}
            gameMgr:GetUserInfo().avatarFriendVisitData_[tostring(AVATAR_FRIEND_MESSAGE_TYPE.TYPE_PERISH_RESTAURANT_BUG)] = true

            if shareFacade:RetrieveMediator('AvatarMediator') then
                local curFriendData = friendAvatarMediator:getCurrentFriendData()
                local bugList = checktable(curFriendData).bug or {}
                if #bugList == 0 then
                    shareFacade:RetrieveMediator('AvatarMediator'):updateFriendListState(NetCmd.RequestRestaurantBugClear, self.friendData.friendId, 0)
                end
            end
        else
            gameMgr:UpdateBackpackByGoodId(killGoodsId, -1)
            self:GetViewComponent().viewData:updatePropCount()
            local avatarMediator = shareFacade:RetrieveMediator('AvatarMediator')
            avatarMediator:removeBugAt(self.id)
        end

        -- TODO_吸入奖励动画
        uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})

        PlayAudioClip(AUDIOS.UI.ui_lubi_disappear.id)

        -- close self
        AppFacade.GetInstance():UnRegsitMediator(NAME)

    elseif name ==  SIGNALNAMES.IcePlace_Home_Callback then
        local body = checktable(signal:GetBody())
        local icePlace = body.icePlace
        local countNum =  table.nums(icePlace)
        local restaurantMgr =  app.restaurantMgr
        local isHave = false
        for icePlaceId = 1 , countNum  do
            local icePlaceBed = icePlace[tostring(icePlaceId)].icePlaceBed or {}
            local icePlaceBedNum = checkint( icePlace[tostring(icePlaceId)].icePlaceBedNum)
            body.requestData.icePlaceId = icePlaceId
            if icePlaceBedNum > table.nums(icePlaceBed)  then
                isHave = true
            else
                for id , vigourData in pairs(icePlaceBed) do
                    local maxVigour = restaurantMgr:getCardVigourLimit(id)
                    if checkint(maxVigour) <=  checkint(vigourData.newVigour) then
                        isHave = true
                        break
                    end
                end
            end
            if isHave then
                break
            end
        end
        if isHave then
            socketMgr:SendPacket( NetCmd.RequestEmploySwich,  body.requestData)
        else
            app.uiMgr:ShowInformationTips(__('冰场已满'))
        end
    elseif name == POST.RESTAURANT_QUEST_HELP.sglName then
        local helpCount = checkint(gameMgr:GetUserInfo().restaurantEventNeedHelpLeftTimes)
        gameMgr:GetUserInfo().restaurantEventNeedHelpLeftTimes = helpCount - 1
        gameMgr:GetUserInfo().avatarCacheData.hasEventHelp     = 1

        self:GetViewComponent().viewData:updateHelpInfo()
    end
end
function AvatarFeedMediator:Initial( key )
	self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
	local viewComponent  = AvatarFeedView.new({type = self.type, id = self.id, data = self.data.data, friendData = self.friendData})
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
    -- scene:AddGameLayer(viewComponent)
    scene:AddDialog(viewComponent)

end

function AvatarFeedMediator:OnRegist(  )
	local AvatarFeedCommand = require( 'Game.command.AvatarFeedCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_FEED_AVATAR, AvatarFeedCommand)

    if self.type == 1 then
        --初始化下数据的逻辑
        if self.friendData then
            self:GetViewComponent():UpdateFriendValue(self.friendData.maxVigour, self.friendData.vigour)
        else
            local card = gameMgr:GetCardDataById(self.id)
            self:GetViewComponent():UpdateVigour(card.id,checkint(card.vigour))
        end
    end

    regPost(POST.RESTAURANT_BUG_HELP)
    regPost(POST.RESTAURANT_BUG_CLEAN)
    regPost(POST.RESTAURANT_QUEST_HELP)
end
function AvatarFeedMediator:OnUnRegist(  )
	--称出命令
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveDialog(self.viewComponent)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_FEED_AVATAR)
    unregPost(POST.RESTAURANT_BUG_HELP)
    unregPost(POST.RESTAURANT_BUG_CLEAN)
    unregPost(POST.RESTAURANT_QUEST_HELP)
    AppFacade.GetInstance():DispatchObservers("EXPRESSION_OBSERVER")
end

return AvatarFeedMediator
