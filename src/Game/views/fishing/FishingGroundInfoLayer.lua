local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr = shareFacade:GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local fishingMgr = AppFacade.GetInstance():GetManager("FishingManager")
local fishConfigParser = require('Game.Datas.Parser.FishConfigParser')
---@class FishingGroundInfoLayer
local FishingGroundInfoLayer = class('FishingGroundInfoLayer', function()
    local layout = CLayout:create()
    layout.name = 'FishingGroundInfoLayer'
    layout:enableNodeEvents()
    return layout
end)

local RES_DICT          = {
    I_BG_DETAIL         = _res('ui/common/common_bg_tips'),
    I_IMG_WEATHER       = _res('ui/battle/battle_bg_weather'),
    I_IMG_NO_WEATHER    = _res('ui/home/fishing/fishing_main_ico_noweather'),
    I_IMG_TIME          = _res('avatar/ui/recipeMess/restaurant_ico_selling_timer'),
    I_IMG_BAIT          = _res('ui/home/fishing/fishing_main_ico_account_bait'),
    I_IMG_LEAF          = _res('avatar/ui/recipeMess/restaurant_ico_selling_leaf'),
    I_IMG_TYPE          = _res('avatar/ui/recipeMess/restaurant_ico_selling_frame'),
    I_IMG_CUTLINE       = _res('avatar/ui/recipeMess/restaurant_ico_selling_line'),
    I_IMG_BAIT_EMPTY    = _res('avatar/ui/recipeMess/restaurant_ico_selling_foodempty'),
    I_IMG_LOCK          = _res('ui/common/common_ico_lock'),
    I_IMG_              = _res('ui/home/fishing/fishing_main_ico_account_bait'),
    
    I_FONT_NUMBER       = 'font/small/common_text_num.fnt',
}
local weatherConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRAY , 'fish')
for k,v in pairs(weatherConfig) do
    RES_DICT['I_IMG_WEATHER_'..k] = _res('ui/common/' .. v.icon)
end

function FishingGroundInfoLayer:ctor(...)
    local args = unpack({...}) or {}
    self.isAction = true 
    self:setContentSize(display.size)
    local eaterLayer = CButton:create()
    eaterLayer:setContentSize(display.size)
    --CColorView:create(cc.c4b(0, 0, 0, 0))
    --eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function(sender)
        if not  self.isAction then
            self.isAction = true
            eaterLayer:setEnabled(false)
            self:OnExitAction()

        end
    end)
    
    local function CreateFoodView()
        local size = cc.size(720, 410)
        local view = CLayout:create(size)
        -- view:setBackgroundColor(cc.c4b(200,100,100,100))
        local bg = display.newImageView(RES_DICT.I_BG_DETAIL, 0,0,{enable = true, scale9= true, size = size})
        display.commonUIParams(bg, {ap = display.LEFT_BOTTOM})
        view:addChild(bg)

        local weatherBG = display.newImageView(RES_DICT.I_IMG_WEATHER, 54, 364)
        view:addChild(weatherBG)

        local weatherSize = weatherBG:getContentSize()
        local weatherImage = display.newImageView(RES_DICT.I_IMG_NO_WEATHER,0,0)
        display.commonUIParams(weatherImage,{po = cc.p(weatherSize.width / 2, weatherSize.height / 2)})
        weatherBG:addChild(weatherImage)

        local ys = {271, 163, 39}
        local imgs = {RES_DICT.I_IMG_TIME, RES_DICT.I_IMG_BAIT, RES_DICT.I_IMG_LEAF}
        for i=1,3 do
            local typeBG = display.newImageView(RES_DICT.I_IMG_TYPE, 40, ys[i])
            view:addChild(typeBG)
            local typeSize = typeBG:getContentSize()
            local iconImage = display.newImageView(imgs[i],0,0)
            display.commonUIParams(iconImage,{po = cc.p(typeSize.width / 2, typeSize.height / 2)})
            typeBG:addChild(iconImage)
        end

        local cutlineImage = display.newImageView(RES_DICT.I_IMG_CUTLINE, 376, 365)
        view:addChild(cutlineImage)

        local ys = {54, 178, 286}
        for i=1,3 do
            local cutlineImage = display.newImageView(RES_DICT.I_IMG_CUTLINE, 338, ys[i])
            view:addChild(cutlineImage)
        end

        local baitImages = {}
        local baitNumLabels = {}
        for i=1,3 do
            local baitImage = display.newImageView(RES_DICT.I_IMG_BAIT_EMPTY, 257+(i-1)*92, 217)
            view:addChild(baitImage)
            table.insert( baitImages, baitImage )

			local baitNumLabel = display.newLabel(257+(i-1)*92, 162, fontWithColor(5, {text = __('空')}))
			view:addChild(baitNumLabel)
            table.insert( baitNumLabels, baitNumLabel )
        end

        local cardHeads = {}
        local vigourLabels = {}
        for i=1,5 do
            local cardHead = require('home.BackpackCell').new()
            cardHead:setPosition(cc.p(216+(i-1)*93, 55))
            cardHead:setScale(0.8)
            view:addChild(cardHead)
            table.insert( cardHeads, cardHead )

            local lockImage = display.newImageView(RES_DICT.I_IMG_LOCK, 260+(i-1)*93, 100)
            view:addChild(lockImage)
            cardHead.lockImage = lockImage

			local vigourLabel = display.newLabel(258+(i-1)*93, 40, fontWithColor(5, {text = __('未解锁')}))
			view:addChild(vigourLabel)
            table.insert( vigourLabels, vigourLabel )
        end

        local ys = {300, 192, 69}
        local texts = {__('预计垂钓时间'), __('钓饵数'), __('钓手新鲜度')}
        for i=1,3 do
			local typeLabel = display.newLabel(24, ys[i], fontWithColor(6, {text = texts[i], ap = cc.p(0, 0.5)}))
			view:addChild(typeLabel)
        end

        local numLabels = {}
        local ys = {270, 162, 38}
        for i=1,3 do
            local numLabel = cc.Label:createWithBMFont(RES_DICT.I_FONT_NUMBER, '')
            numLabel:setAnchorPoint(cc.p(0, 0.5))
            numLabel:setPosition(cc.p(61, ys[i]))
			view:addChild(numLabel)
            table.insert( numLabels, numLabel )
        end

		local weatherTitleLabel = display.newLabel(100, 378, fontWithColor(6, {text = __('天气效果:'), ap = cc.p(0, 0.5)}))
		view:addChild(weatherTitleLabel)

        local weatherLabel = display.newLabel(weatherTitleLabel:getPositionX() + display.getLabelContentSize(weatherTitleLabel).width + 6, 378, 
            fontWithColor(6, {text = '', color = 'ee6f6f', ap = cc.p(0, 0.5)}))
        view:addChild(weatherLabel)

		local weatherDesrLabel = display.newLabel(100, 350, fontWithColor(15, {text = '', ap = cc.p(0, 0.5)}))
		view:addChild(weatherDesrLabel)
        
        local durationLabel = cc.Label:createWithBMFont(RES_DICT.I_FONT_NUMBER, '00:00:00')
        durationLabel:setAnchorPoint(cc.p(1, 0.5))
        durationLabel:setPosition(cc.p(666, 379))
        view:addChild(durationLabel)

		local durationTitleLabel = display.newLabel(durationLabel:getPositionX() - durationLabel:getContentSize().width - 6, 380, fontWithColor(6, {text = __('持续时间:'), ap = cc.p(1, 0.5)}))
        view:addChild(durationTitleLabel)
        
        return {
            view                = view,
            weatherTitleLabel   = weatherTitleLabel,
            weatherImage        = weatherImage,
            weatherLabel        = weatherLabel,
            weatherDesrLabel    = weatherDesrLabel,
            durationLabel       = durationLabel,
            durationTitleLabel  = durationTitleLabel,
            baitImages          = baitImages,
            baitNumLabels       = baitNumLabels,
            numLabels           = numLabels,
            cardHeads           = cardHeads,
            vigourLabels        = vigourLabels,
        }
    end
    self.viewData = CreateFoodView()
    display.commonUIParams(self.viewData.view, {po = cc.p(display.SAFE_R - 10, display.height - 150), ap = cc.p(1, 1)})
    self:addChild(self.viewData.view,1)
    self:OnEnterAction()

end

function FishingGroundInfoLayer:RefreshLayer( ... )
    local viewData = self.viewData
    local baitImages = viewData.baitImages
    local baitNumLabels = viewData.baitNumLabels
    local numLabels = viewData.numLabels
    local cardHeads = viewData.cardHeads
    local vigourLabels = viewData.vigourLabels
    local durationLabel = viewData.durationLabel

    local args = unpack({...}) or {}
    local buff = args.buff or {}
    local bait = args.fishBaits or {}
    local fishermen = args.fishCards or {}
    local groundLevel = checkint(args.level)
    -- 天气
    self:UpdateWeather(buff)

    local expectedTime = fishingMgr:GetEstimatedtime()
    numLabels[1]:setString(string.formattedTime(checkint(expectedTime),'%02i:%02i:%02i'))
    -- 钓饵
    local index = 1
    local totalNum = 0
    for k,v in pairs(bait) do
        baitImages[index]:setTexture(CommonUtils.GetGoodsIconPathById(k))
        baitImages[index]:setScale(0.5)
        baitNumLabels[index]:setString(v)
        index = index + 1
        totalNum = totalNum + v
    end
    for i=index,table.nums(baitImages) do
        baitImages[i]:setTexture(RES_DICT.I_IMG_BAIT_EMPTY)
        baitNumLabels[i]:setString(__('空'))
        baitImages[i]:setScale(1)
    end
    numLabels[2]:setString(totalNum)

    -- 钓手
    local totalVigour = 0
    local totalMaxVigour = 0
    local levelConfig = CommonUtils.GetConfig('fish', fishConfigParser.TYPE.LEVEL, tostring(groundLevel))
    for i=1,checkint(levelConfig.seatNum) do
        local fisherman = fishermen[tostring(i)] or {}
        local cardHead = cardHeads[i]
        cardHead.lockImage:setVisible(false)
        if next(fisherman) then
            local card
            if fisherman.cardId then
                card = gameMgr:GetCardDataByCardId(fisherman.cardId)
            elseif fisherman.playerCardId then
                card = gameMgr:GetCardDataById(fisherman.playerCardId)
            end
            if card then
                local headPath = CardUtils.GetCardHeadPathBySkinId(card.defaultSkinId)
                cardHead.goodsImg:setTexture(headPath)
                cardHead.goodsImg:setVisible(true)
                local maxVigour = app.restaurantMgr:getCardVigourLimit(card.id)
                vigourLabels[i]:setString(card.vigour)
                totalVigour = totalVigour + card.vigour
                totalMaxVigour = totalMaxVigour + maxVigour
            end
        else
            cardHead.goodsImg:setVisible(false)
            vigourLabels[i]:setString(__('空'))
        end
    end
    for i=checkint(levelConfig.seatNum)+1,5 do
        local cardHead = cardHeads[i]
        cardHead.lockImage:setVisible(true)
        cardHead.goodsImg:setVisible(false)
        vigourLabels[i]:setString(__('未解锁'))
    end
    numLabels[3]:setString(totalVigour .. '/' .. totalMaxVigour)
end

function FishingGroundInfoLayer:UpdateWeather( ... )
    local buff = unpack({...}) or {}
    local viewData = self.viewData
    local weatherImage = viewData.weatherImage
    local weatherTitleLabel = viewData.weatherTitleLabel
    local weatherLabel = viewData.weatherLabel
    local weatherDesrLabel = viewData.weatherDesrLabel
    local durationLabel = viewData.durationLabel
    local durationTitleLabel = viewData.durationTitleLabel

    -- 天气
    if next(buff) then
        local weatherConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRAY , 'fish')[tostring(buff.buffId)]
        weatherImage:setTexture(RES_DICT['I_IMG_WEATHER_'..tostring(buff.buffId)])
        weatherImage:setScale(0.4)
		weatherTitleLabel:setString(__('天气效果:'))
        weatherLabel:setString(weatherConfig.name)
        weatherDesrLabel:setString(weatherConfig.descr)
        durationLabel:setString(string.formattedTime(checkint(buff.leftSeconds),'%02i:%02i:%02i'))
        durationTitleLabel:setVisible(true)
    else
        weatherImage:setTexture(RES_DICT.I_IMG_NO_WEATHER)
        weatherImage:setScale(1)
		weatherTitleLabel:setString(__('当前没有天气效果'))
		weatherLabel:setString('')
        weatherDesrLabel:setString('')
        durationLabel:setString('')
        durationTitleLabel:setVisible(false)
    end
end
function FishingGroundInfoLayer:OnExitAction()
    self:runAction(
        cc.Sequence:create(
            cc.Spawn:create(
                cc.FadeIn:create(0.1),
                cc.TargetedAction:create( self.viewData.view ,cc.ScaleTo:create(0.1,1,0))
            ),
            cc.RemoveSelf:create()
        )
    )
end
function FishingGroundInfoLayer:OnEnterAction()
    self.viewData.view:setScaleY(0)
    self.viewData.view:setOpacity(125)
    self.viewData.view:runAction(
        cc.Sequence:create(
            cc.Spawn:create(
                cc.EaseBackOut:create( cc.ScaleTo:create(0.3,1,1)),
                cc.FadeIn:create(0.3)
            ),
            cc.CallFunc:create(
                function()
                    self.isAction = false
                end
            )
        )

    )
end

return FishingGroundInfoLayer