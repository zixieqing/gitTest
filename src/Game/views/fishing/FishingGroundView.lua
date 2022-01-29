--[[
    钓场主界面
--]]
local GameScene = require( "Frame.GameScene" )
---@class FishingGroundView :GameScene
local FishingGroundView = class("FishingGroundView", GameScene)
local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local fishingMgr = shareFacade:GetManager("FishingManager")
local uiMgr = shareFacade:GetManager("UIManager")

local RemindIcon = require('common.RemindIcon')
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local FishingPositionNode = require('Game.views.fishing.FishingPositionNode')
local fishConfigParser = require('Game.Datas.Parser.FishConfigParser')
local fishingSpineCache = SpineCache(SpineCacheName.FISHING)

local VIEW_SIZE = cc.size(1334, 1002)

local RES_DICT          = {
    BG_SKY              = _res('ui/home/fishing/fishing_main_bg_sky'),
    BG_DESK             = _res('ui/home/fishing/fishing_main_bg_boat'),
    IMG_CLOUD_1         = _res('ui/home/fishing/fishing_main_bg_cloud_1'),
    IMG_CLOUD_2         = _res('ui/home/fishing/fishing_main_bg_cloud_2'),
    BG_SHIP             = _res('ui/home/fishing/fishing_main_fg_boat'),
    IMG_BOX             = _res('ui/home/fishing/fishing_main_bg_corner'),
    BTN_BOX_EMPTY       = _res('ui/home/fishing/fishing_main_ico_box_empty'),
    BTN_ADD_BAIT_EMPTY  = _res('ui/home/fishing/fishing_main_ico_bait_empty'),
    BTN_WISH            = _res('ui/home/fishing/fishing_main_ico_weather'),
    BTN_INFO            = _res('ui/home/fishing/fishing_main_ico_info'),
    BTN_SHOP            = _res('ui/home/fishing/fishing_main_ico_shop'),
    IMG_PLATE           = _res('ui/home/fishing/vip_main_bg_function_plate'),
    IMG_NAME            = _res('ui/home/fishing/vip_main_bg_function'),
    IMG_FRIEND_NAME     = _res('avatar/ui/restaurant_friends_bg_avator_name.png'),
    IMG_FRIEND_HEAD     = _res('ui/common/common_avatar_frame_bg'),
    IMG_HELP            = _res('avatar/ui/restaurant_friend_bg_clean_number'),
    IMG_WEATHER         = _res('ui/battle/battle_bg_weather'),
    IMG_NO_WEATHER      = _res('ui/home/fishing/fishing_main_ico_noweather'),
    IMG_CURRENCY        = _res('ui/home/nmain/main_bg_money'),
    IMG_INFO            = _res('ui/home/fishing/fishing_main_bg_account'),
    IMG_CUTLINE         = _res('avatar/ui/recipeMess/restaurant_ico_selling_line2'),
    IMG_TIME            = _res('avatar/ui/recipeMess/restaurant_ico_selling_timer'),
    IMG_BAIT            = _res('ui/home/fishing/fishing_main_ico_account_bait'),
    IMG_LEAF            = _res('avatar/ui/recipeMess/restaurant_ico_selling_leaf'),
    BTN_DETAIL          = _res('ui/common/raid_boss_btn_search'),
    IMG_DROP_DOWN       = _res('ui/home/fishing/fishing_main_ico_triangle'),
    BTN_FRIEND          = _res('avatar/ui/restaurant_btn_my_friends'),
    IMG_TABLET          = _res('ui/common/common_title'),
    IMG_TIPS            = _res('ui/common/common_btn_tips.png'),

    SPINE_CLOUD         = _spn('effects/fishing/yun'),

    FONT_NUMBER         = 'font/small/common_text_num.fnt',
}
local weatherConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRAY , 'fish')
for k,v in pairs(weatherConfig) do
    RES_DICT['IMG_WEATHER_'..k] = _res('ui/common/' .. v.icon)
end

local FISH_TAG = {
    ADD_BAIT = 1001,
    WISH     = 1002,
    INFO     = 1003,
    SHOP     = 1004,
    REWARDS  = 1005,
    FRIEND   = 1010,
}
function FishingGroundView:ctor( ... )
	GameScene.ctor(self, 'Game.views.fishing.FishingGroundView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function FishingGroundView:InitUI()
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        view:setName('FishingGroundView')
        self:addChild(view)

        local uiBg = display.newImageView(RES_DICT.BG_SKY, display.cx, display.height - (display.height - VIEW_SIZE.height) / 2)
        display.commonUIParams(uiBg, {ap = display.CENTER_TOP})
        view:addChild(uiBg)

        local uiBg = display.newImageView(RES_DICT.BG_DESK, display.cx, display.cy + 40)
        display.commonUIParams(uiBg, {ap = display.CENTER})
        view:addChild(uiBg, 3)

        local cloudPosY = display.cy + 80
        local cloudLayout = CLayout:create(display.size)
        display.commonUIParams(cloudLayout, { ap = display.LEFT_CENTER, po = cc.p(0, display.cy)})
        view:addChild(cloudLayout,2)
        local cloudLayoutR = CLayout:create(cc.size(100, display.height))
        display.commonUIParams(cloudLayoutR, { ap = display.LEFT_CENTER, po = cc.p(0, display.cy)})
        cloudLayout:addChild(cloudLayoutR)
        local cloudImageL = display.newImageView(RES_DICT.IMG_CLOUD_1, 0, cloudPosY)
        display.commonUIParams(cloudImageL, {ap = display.LEFT_CENTER})
        cloudLayoutR:addChild(cloudImageL)
        local cloudLSize = cloudImageL:getContentSize()
        local cloudImageR = display.newImageView(RES_DICT.IMG_CLOUD_2, cloudLSize.width, cloudPosY)
        display.commonUIParams(cloudImageR, {ap = display.LEFT_CENTER})
        cloudLayoutR:addChild(cloudImageR)
        local cloudRSize = cloudImageR:getContentSize()
        local cloudWidth = cloudLSize.width + cloudRSize.width

        local cloudLayoutL = CLayout:create(cc.size(cloudWidth, display.height))
        display.commonUIParams(cloudLayoutL, { ap = display.RIGHT_CENTER, po = cc.p(0, display.cy)})
        cloudLayout:addChild(cloudLayoutL)
        local cloudImageL = display.newImageView(RES_DICT.IMG_CLOUD_1, 0, cloudPosY)
        display.commonUIParams(cloudImageL, {ap = display.LEFT_CENTER})
        cloudLayoutL:addChild(cloudImageL)
        local cloudImageR = display.newImageView(RES_DICT.IMG_CLOUD_2, cloudLSize.width, cloudPosY)
        display.commonUIParams(cloudImageR, {ap = display.LEFT_CENTER})
        cloudLayoutL:addChild(cloudImageR)

        local speed = 80
        local cloudWidth = cloudLSize.width + cloudRSize.width
        local timeW = display.width / speed
        local timeC = cloudWidth / speed
        cloudLayout:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.MoveBy:create(timeW, cc.p(display.width, 0)),
            cc.CallFunc:create(function (  )
                cloudLayoutR:setPositionX(-2 * cloudWidth)
            end),
            cc.MoveBy:create(timeC - timeW, cc.p(cloudWidth - display.width, 0)),
            cc.CallFunc:create(function (  )
                cloudLayout:setPositionX(0)
                cloudLayoutL:setPositionX(0)
                cloudLayoutR:setPositionX(0)
            end)
        )))

        local cloudSpinePath = tostring(RES_DICT.SPINE_CLOUD)
        fishingSpineCache:addCacheData(cloudSpinePath, cloudSpinePath, 1)
        local cloudSpine = fishingSpineCache:createWithName(cloudSpinePath)
        cloudSpine:update(0)
        cloudSpine:setToSetupPose()
        cloudSpine:setAnimation(0, 'idle', true)
        display.commonUIParams(cloudSpine, {po = cc.p(display.cx, display.cy - 120)})
        view:addChild(cloudSpine, 6)

        local uiBg = display.newImageView(RES_DICT.BG_SHIP, display.cx, (display.height - VIEW_SIZE.height) / 2)
        display.commonUIParams(uiBg, {ap = display.CENTER_BOTTOM})
        view:addChild(uiBg, 4)

        -------------------------------------------------
        ---底层的视图
        local bottomView = CLayout:create(display.size)
        display.commonUIParams(bottomView, { ap = display.CENTER_BOTTOM, po = cc.p(display.cx, 0)})
        bottomView:setName('BottomView')
        view:addChild(bottomView,10)
        
		local boxBG = display.newImageView(RES_DICT.IMG_BOX, display.SAFE_R + 60, 0, {ap = cc.p(1, 0)})
		bottomView:addChild(boxBG)
		
        local rewardButton = display.newButton(boxBG:getPositionX() - 136, 73,{n = RES_DICT.BTN_BOX_EMPTY})
        rewardButton:setName('rewardButton')
        bottomView:addChild(rewardButton,1)
        rewardButton:setTag(FISH_TAG.REWARDS)
        display.commonLabelParams(rewardButton, fontWithColor(14, {text = __('收获'), outline = '2d1414', outlineSize = 2, offset = cc.p(0, -50)}))
       
        -- buttons
        local tt = {
            { id = FISH_TAG.ADD_BAIT, name = 'ADD_BAIT', pos = cc.p(658, 90), image = RES_DICT.BTN_ADD_BAIT_EMPTY, text = __('添加钓饵') },
            { id = FISH_TAG.WISH, name = 'WISH', pos = cc.p(524, 90), image = RES_DICT.BTN_WISH, text = __('祈愿') },
            { id = FISH_TAG.SHOP, name = 'SHOP', pos = cc.p(390, 90), image = RES_DICT.BTN_SHOP, text = __('商店') },
            { id = FISH_TAG.INFO, name = 'INFO', pos = cc.p(256, 90), image = RES_DICT.BTN_INFO, text = __('信息'), remind = RemindTag.BTN_FISH_UPGRADE },
        }
        local actionButtons = {}
        for idx,val in ipairs(tt) do
            local actionLayout = CColorView:create(cc.r4b(0))
            actionLayout:setContentSize(cc.size(134, 140))
            actionLayout:setTouchEnabled(true)
            display.commonUIParams(actionLayout, {ap = cc.p(0.5, 0), po = cc.p(display.SAFE_R - val.pos.x, 0)})
            bottomView:addChild(actionLayout)

            local btn = FilteredSpriteWithOne:create()
            btn:setTexture(val.image)
            btn:setTag(val.id)
            btn:setPosition(cc.p(67, 90))
            actionLayout:addChild(btn, 2)
            actionLayout:setName(val.name)
            actionLayout:setTag(val.id)
            if val.remind then
                RemindIcon.addRemindIcon({parent = btn, tag = val.remind, po = cc.p(btn:getContentSize().width * 0.5 + 28, btn:getContentSize().height * 0.5 + 24)})
            end
			local plateImage = display.newImageView(RES_DICT.IMG_PLATE, 64, 86)
			actionLayout:addChild(plateImage)
			local nameBG = display.newImageView(RES_DICT.IMG_NAME, btn:getPositionX(), btn:getPositionY() - 60)
			actionLayout:addChild(nameBG)
			local nameLabel = display.newLabel(nameBG:getPositionX(), nameBG:getPositionY() - 4, fontWithColor(14, {text = val.text, outline = '2d1414', outlineSize = 2}))
			actionLayout:addChild(nameLabel)
            table.insert( actionButtons, actionLayout )
        end

        -- 聊天入口
        local chatBtn = nil
        if ChatUtils.IsModuleAvailable() then
            chatBtn = require('common.CommonChatPanel').new()
            display.commonUIParams(chatBtn, {po = cc.p(0, 4), ap = display.LEFT_BUTTOM})
            bottomView:addChild(chatBtn)
        end
        
        -------------------------------------------------
        ---好友底层的视图
        local friendBottomView = CLayout:create(display.size)
        display.commonUIParams(friendBottomView, { ap = display.CENTER_BOTTOM, po = cc.p(display.cx, 0)})
        friendBottomView:setName('friendBottomView')
        view:addChild(friendBottomView,10)

        local friendRNameBar = display.newButton(0, 10, {n = RES_DICT.IMG_FRIEND_NAME, ap = display.CENTER_BOTTOM, scale9 = true, enable = false})
        display.commonLabelParams(friendRNameBar, fontWithColor(16))
        friendBottomView:addChild(friendRNameBar)
        
        local friendHeaderNode = require('root.CCHeaderNode').new({bg = RES_DICT.IMG_FRIEND_HEAD, pre = '', tsize = cc.size(90,90)})
        friendHeaderNode:setPosition(50, 50)
        friendBottomView:addChild(friendHeaderNode)
    
        local friendLevelLable = cc.Label:createWithBMFont(RES_DICT.FONT_NUMBER, '')
        friendLevelLable:setAnchorPoint(display.RIGHT_BOTTOM)
        friendLevelLable:setPosition(92, 3)
        friendBottomView:addChild(friendLevelLable)

        -------------------------------------------------
        ---好友顶层的视图
        local friendTopView = CLayout:create(display.size)
        display.commonUIParams(friendTopView, { ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
        view:addChild(friendTopView, 10)

        local sendCountLable = display.newLabel(display.SAFE_R - 10, display.height - 20, fontWithColor(19, {ap = display.RIGHT_CENTER, text = '0'}))
        local helpQuestTipLable   = display.newLabel(display.SAFE_R - 50, display.height - 20, fontWithColor(1, {ap = display.RIGHT_CENTER, text = __('剩余可派遣飨灵数：')}))
        friendTopView:addChild(sendCountLable, 2)
        friendTopView:addChild(helpQuestTipLable, 2)

        local helpInfoSize = cc.size(display.getLabelContentSize(helpQuestTipLable).width + 60 + 120, 41)
        local helpInfoBar  = display.newImageView(RES_DICT.IMG_HELP, display.SAFE_R + 60, display.height, {scale9 = true, size = helpInfoSize, ap = display.RIGHT_TOP})
        friendTopView:addChild(helpInfoBar)
        
        local friendWeatherBtn = display.newButton(0,0, {n = RES_DICT.IMG_WEATHER})
        display.commonUIParams(friendWeatherBtn,{po = cc.p(display.cx, display.height - 8), ap = cc.p(0.5, 1)})
        friendTopView:addChild(friendWeatherBtn)

        local weatherSize = friendWeatherBtn:getContentSize()
        local friendWeatherImage = display.newImageView(RES_DICT.IMG_NO_WEATHER,0,0)
        display.commonUIParams(friendWeatherImage,{po = cc.p(weatherSize.width / 2, weatherSize.height / 2)})
        friendWeatherBtn:addChild(friendWeatherImage)

        -------------------------------------------------
        ---顶层的视图
        local topView = CLayout:create(display.size)
        display.commonUIParams(topView, { ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
        topView:setName('TopView')
        view:addChild(topView,10)

        -- top icon
        local currencyBG = display.newImageView(RES_DICT.IMG_CURRENCY,0,0,{enable = false, scale9 = true, size = cc.size(860 + display.SAFE_L,54)})
        display.commonUIParams(currencyBG,{ap = cc.p(1.0,1.0), po = cc.p(display.width, display.height)})
        topView:addChild(currencyBG)
        local moneyNods = {}
        local iconData = {WATER_CRYSTALLIZATION_ID,WIND_CRYSTALLIZATION_ID, RAY_CRYSTALLIZATION_ID, FISH_POPULARITY_ID}
        for i,v in ipairs(iconData) do
            local purchaseNode = GoodPurchaseNode.new({id = v, animate = true})
            purchaseNode:updataUi(checkint(v))
            display.commonUIParams(purchaseNode,
            {ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( 4 - i) * (purchaseNode:getContentSize().width + 16)), currencyBG:getPositionY()- 26)})
            topView:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNods[tostring( v )] = purchaseNode
        end

        -- 概况
        local infoBG = display.newImageView(RES_DICT.IMG_INFO,0,0)
        display.commonUIParams(infoBG,{ap = cc.p(1.0,1.0), po = cc.p(display.SAFE_R - 28, display.height - 60)})
        topView:addChild(infoBG)

        local weatherBG = display.newImageView(RES_DICT.IMG_WEATHER,0,0)
        display.commonUIParams(weatherBG,{po = cc.p(38, 44)})
        infoBG:addChild(weatherBG)

        local weatherSize = weatherBG:getContentSize()
        local weatherImage = display.newImageView(RES_DICT.IMG_NO_WEATHER,0,0)
        display.commonUIParams(weatherImage,{po = cc.p(weatherSize.width / 2, weatherSize.height / 2)})
        weatherBG:addChild(weatherImage)

        for i=1,2 do
            local cutlineImage = display.newImageView(RES_DICT.IMG_CUTLINE,0,0, {scale9 = true, size = cc.size(140, 1)})
            display.commonUIParams(cutlineImage,{po = cc.p(154, 28 + (i-1)*26)})
            infoBG:addChild(cutlineImage)
        end

        local timeImage = display.newImageView(RES_DICT.IMG_TIME,0,0)
        display.commonUIParams(timeImage,{po = cc.p(95, 68)})
        infoBG:addChild(timeImage)

        local baitImage = display.newImageView(RES_DICT.IMG_BAIT,0,0)
        display.commonUIParams(baitImage,{po = cc.p(95, 42)})
        infoBG:addChild(baitImage)
        
        local leafImage = display.newImageView(RES_DICT.IMG_LEAF,0,0)
        display.commonUIParams(leafImage,{po = cc.p(95, 16)})
        infoBG:addChild(leafImage)
        
        local durationLabel = display.newLabel(220, 68, fontWithColor(14,{text = '', fontSize = 22, outline = '#432323', ap = cc.p(1, 0.5)}))
        infoBG:addChild(durationLabel)

        local baitNum = cc.Label:createWithBMFont(RES_DICT.FONT_NUMBER, '')
        baitNum:setAnchorPoint(cc.p(1, 0.5))
        baitNum:setPosition(220, 42)
        infoBG:addChild(baitNum)

        local leafNum = cc.Label:createWithBMFont(RES_DICT.FONT_NUMBER, '')
        leafNum:setAnchorPoint(cc.p(1, 0.5))
        leafNum:setPosition(220, 16)
        infoBG:addChild(leafNum)

        local detailView = CColorView:create(cc.r4b(0))
        detailView:setContentSize(cc.size(286, 80))
        detailView:setTouchEnabled(true)
        display.commonUIParams(detailView, { po = cc.p(display.SAFE_R - 170, display.height - 105)})
        topView:addChild(detailView, 10)

        local detailButton = display.newButton(display.SAFE_R - 54, display.height - 90,{n = RES_DICT.BTN_DETAIL})
        topView:addChild(detailButton,10)

        local downImage = display.newImageView(RES_DICT.IMG_DROP_DOWN,0,0)
        display.commonUIParams(downImage,{po = cc.p(253, 16)})
        infoBG:addChild(downImage)

        -------------------------------------------------
        --- 钓手
        local friendSeatNode = FishingPositionNode.new({tag = 0})
        display.commonUIParams(friendSeatNode,{ap = cc.p(0.5, 0.5), po = cc.p(display.cx - 550, display.cy + 18)})
        view:addChild(friendSeatNode, 5)

        local initPox = display.cx - 304
        local offset = 204
        local seats = {}
        for i=1,5 do
            local seatNode = FishingPositionNode.new({tag = i})
            display.commonUIParams(seatNode,{ap = cc.p(0.5, 0.5), po = cc.p(initPox + (i-1)*offset, display.cy - 36)})
            view:addChild(seatNode, 5)
            table.insert(seats, seatNode)
        end
        
        -------------------------------------------------
        -- 好友
        local friendBtn = display.newButton(display.SAFE_R + 4, (display.size.height - TOP_HEIGHT) / 2, {n = RES_DICT.BTN_FRIEND, ap = display.RIGHT_CENTER})
        friendBtn:setTag(FISH_TAG.FRIEND)
        self:addChild(friendBtn, 50)
        -- RemindIcon.addRemindIcon({parent = friendBtn, tag = RemindTag.LOBBY_FRIEND, po = cc.p(friendBtn:getContentSize().width * 0.5 + 28, friendBtn:getContentSize().height * 0.5 + 24)})

		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height + 2 ,{n = RES_DICT.IMG_TABLET, ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('钓场'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel,50)
        -- tips
        local tipsBtn = display.newButton(tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10, {n = RES_DICT.IMG_TIPS})
        tabNameLabel:addChild(tipsBtn, 10)
        
		return {
            view                = view,
            bottomView          = bottomView,
            chatBtn             = chatBtn,
            tabNameLabel        = tabNameLabel,
            tabNameLabelPos 	= cc.p(tabNameLabel:getPosition()),
            seats               = seats,
            friendSeatNode      = friendSeatNode,
            actionButtons       = actionButtons,
            rewardButton        = rewardButton,
            topView             = topView,
            friendTopView       = friendTopView,
            friendWeatherImage  = friendWeatherImage,
            friendBottomView    = friendBottomView,
            friendRNameBar      = friendRNameBar,
            friendHeaderNode    = friendHeaderNode,
            friendLevelLable    = friendLevelLable,
            detailView          = detailView,
            detailButton        = detailButton,
            friendWeatherBtn    = friendWeatherBtn,
            weatherImage        = weatherImage,
            durationLabel       = durationLabel,
            baitNum             = baitNum,
            leafNum             = leafNum,
            sendCountLable      = sendCountLable,
            friendBtn           = friendBtn,
            moneyNods           = moneyNods,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
    
        self.viewData.tabNameLabel:setPositionY(display.height + 100)
        local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
        self.viewData.tabNameLabel:runAction( action )

        -- self.viewData.topView:setVisible(false)
        -- self.viewData.bottomView:setVisible(false)
        self.viewData.friendTopView:setVisible(false)
        self.viewData.friendBottomView:setVisible(false)

        self.viewData.tabNameLabel:setOnClickScriptHandler(function( sender )
            uiMgr:ShowIntroPopup({moduleId = JUMP_MODULE_DATA.FISHING_GROUND})
        end)
	end, __G__TRACKBACK__)
end

function FishingGroundView:RefreshInfoBar( args, type )
    local viewData = self.viewData
    local weatherImage = viewData.weatherImage
    local durationLabel = viewData.durationLabel
    local buff = args.buff or {}
    -- 天气
    local function WeatherEnd(  )
        weatherImage:setTexture(RES_DICT.IMG_NO_WEATHER)
        weatherImage:setScale(1)
        weatherImage:setTag(0)
    end
    -- DATA_TYPE.NONE 0     DATA_TYPE.BUFF 1
    if 0 == type or 1 == type then
        if next(buff) then
            if 0 < checkint(buff.leftSeconds) then
                -- if weatherImage:getTag() ~= checkint(buff.buffId) then
                    weatherImage:setTexture(RES_DICT['IMG_WEATHER_'..tostring(buff.buffId)])
                    weatherImage:setTag(checkint(buff.buffId))
                    weatherImage:setScale(0.4)
                -- end
            else
                WeatherEnd()
            end
        else
            WeatherEnd()
        end
    end
    -- 钓饵
    -- DATA_TYPE.NONE 0     DATA_TYPE.BAIT 3
    if 0 == type or 3 == type then
        local totalNum = 0
        local bait = args.fishBaits or {}
        local baitNum = viewData.baitNum
        for k,v in pairs(bait) do
            totalNum = totalNum + v
        end
        baitNum:setString(totalNum)
    end
    -- 钓手
    -- DATA_TYPE.NONE 0     DATA_TYPE.CARD 2    DATA_TYPE.START_FISHING 5
    if 0 == type or 2 == type or 5 == type then
        local totalVigour = 0
        local fishermen = args.fishCards or {}
        local leafNum = viewData.leafNum
        for k,v in pairs(fishermen) do
            if next(v) then
                local cardInfo
                if v.cardId then
                    cardInfo = gameMgr:GetCardDataByCardId(v.cardId)
                elseif v.playerCardId then
                    cardInfo = gameMgr:GetCardDataById(v.playerCardId)
                end
                if cardInfo then
                    totalVigour = totalVigour + cardInfo.vigour
                end

            end
        end
        leafNum:setString(totalVigour)
    end
    local expectedTime = fishingMgr:GetEstimatedtime()
    durationLabel:setString(string.formattedTime(checkint(expectedTime),'%02i:%02i:%02i'))
end

function FishingGroundView:RefreshFriendView( args, type, friendGroundId )
    local viewData = self.viewData
    local friendWeatherBtn = viewData.friendWeatherBtn
    local friendWeatherImage = viewData.friendWeatherImage
    local sendCountLable = viewData.sendCountLable
    local buff = args.buff or {}
    local function WeatherEnd(  )
        friendWeatherBtn:setVisible(false)
        friendWeatherImage:setTexture(RES_DICT.IMG_NO_WEATHER)
        friendWeatherImage:setTag(0)
        friendWeatherImage:setScale(1)
    end
    if next(buff) then
        if 0 < checkint(buff.leftSeconds) then
            friendWeatherBtn:setVisible(true)
            if friendWeatherImage:getTag() ~= checkint(buff.buffId) then
                friendWeatherImage:setTexture(RES_DICT['IMG_WEATHER_'..tostring(buff.buffId)])
                friendWeatherImage:setTag(checkint(buff.buffId))
                friendWeatherImage:setScale(0.4)
            end
        else
            WeatherEnd()
        end
    else
        WeatherEnd()
    end
    -- DATA_TYPE.BUFF 1
    if 1 ~= type then
        -- 剩余可派遣数量
        self:RefreshCountTime(args)
        for _, friend in ipairs(gameMgr:GetUserInfo().friendList or {}) do
            if checkint(friend.friendId) == checkint(friendGroundId) then
                local friendRNameBar = viewData.friendRNameBar
                local friendHeaderNode = viewData.friendHeaderNode
                local friendLevelLable = viewData.friendLevelLable
                friendHeaderNode.headerSprite:setWebURL(friend.avatar)
                friendHeaderNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(friend.avatarFrame)))
                local nameText = string.fmt(__('_name_的_level_级钓场'), {_name_ = friend.name, _level_ = args.level})
                display.commonLabelParams(friendRNameBar, {text = nameText, paddingW = 30, safeW = 160})
                friendRNameBar:setPositionX(friendRNameBar:getContentSize().width/2 + 80)
                display.commonLabelParams(friendLevelLable, {text = tostring(friend.level)})
                break
            end
        end
    end
end
function FishingGroundView:RefreshCountTime(args)
    args = args or {}
    local  myFriendFish = args.myFriendFish or  app.fishingMgr:GetHomeDataByKey('myFriendFish')
    if myFriendFish  then
        local viewData = self.viewData
        local sendCountLable = viewData.sendCountLable
        local totalSendNum = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PARAM_CONFIG , 'fish')[tostring(1)].dispatched
        local sentNum = table.nums(myFriendFish or {})
        sendCountLable:setString(checkint(totalSendNum) - sentNum)
    end
end

return FishingGroundView