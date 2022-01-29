--[[
 * author : kaishiqi
 * descpt : 主界面 - 扩展界面
]]
local RemindIcon     = require('common.RemindIcon')
local ThemeFunction  = require('home.HomeThemeFunction')
local HomeExtraPanel = class('HomeExtrelPanel', function()
    return display.newLayer(0, 0, {name = 'home.HomeExtraPanel', enableEvent = true})
end)

local RES_DICT = {
    ALPHA_IMG          = 'ui/common/story_tranparent_bg.png',
    BTN_GROUP_IMG      = 'ui/common/main_second_bg.png',
    BTN_PET            = 'ui/home/nmain/main_ico_pet.png',
    BTN_FUNCTION_N     = 'ui/home/nmain/main_bg_function_default.png',
    BTN_FUNCTION_D     = 'ui/home/nmain/main_bg_function_locked.png',
    FOLD_ARROW         = 'ui/home/nmain/main_btn_switch_left_arrow.png',
    TASTING_TOUR       = 'ui/home/nmain/main_bg_function_fishtravel.png',
    TASTING_TOUR_LOCK  = 'ui/home/nmain/main_bg_function_fishtravel_lock.png',
    NAME_FRAME         = 'share/main_bg_go_restaurant.png',
    ICON_LOCK          = 'ui/common/common_ico_lock.png',
    MAIN_IMG_HOME      = 'arts/common/main_img_home.jpg',
    MAIN_IMG_RESAURANT = 'arts/common/main_img_resaurant.jpg',
    REMIND_ICON_PATH   = 'ui/common/common_hint_circle_red_ico.png',
    CARD_ALBUM_BTN     = 'ui/home/nmain/collect_ico_entrance.png',
}

local CreateView = nil

-- 附加主题样式
local SKIN_MASK = nil
if HOME_THEME_STYLE_DEFINE.HOME_DECORATE then
    SKIN_MASK = {count = 2, path = HOME_THEME_STYLE_DEFINE.HOME_DECORATE}
end


-------------------------------------------------
-- life cycle

function HomeExtraPanel:ctor(args)
    self.isControllable_ = true
    self.funcHideMap_    = args.funcHideMap or {}

    -- create blackLayer
    self.blackLayer_ = display.newLayer(0, 0, {color = cc.c4b(0,0,0,180), enable = true})
    self.blackLayer_:setCascadeOpacityEnabled(true)
    self:addChild(self.blackLayer_)

    -- create view
    self.viewData_ = CreateView()
    self.viewData_.view:setName('HomeExtraPanelView')
    self:addChild(self.viewData_.view)
    self.viewData_.restaurantSpine:registerSpineEventHandler(function(event)
        if event.animation == 'play' and event.type == 'end' then
            if  CommonUtils.GetModuleAvailable(MODULE_SWITCH.HOMELAND) and CommonUtils.UnLockModule(JUMP_MODULE_DATA.HOME_LAND)  then
                self:getViewData().restaurantSpine:setToSetupPose()
                local texture = cc.RenderTexture:create(display.width, display.height)
                texture:setPosition(display.cx, display.cy)
                texture:setAnchorPoint(display.CENTER)

                -- render outScene to its texturebuffer
                texture:clear(0, 0, 0, 0)
                texture:begin()
                sceneWorld:visit()
                texture:endToLua()
                local renderTexture =  texture:getSprite():getTexture()
                renderTexture:setAntiAliasTexParameters()

                local management = display.newCacheSpine(SpineCacheName.GLOBAL, 'ui/home/homeland/effect/management')
                management:setPosition( display.cx , display.cy)
                app.uiMgr:GetCurrentScene():AddDialog(management)
                management:setAnimation(0, 'play', false)
                management:registerSpineEventHandler(function(event)
                    if event.animation == 'play' then
                        management:runAction(cc.RemoveSelf:create())
                    end
                end,sp.EventType.ANIMATION_COMPLETE)
                local spriteImage = display.newNSprite(renderTexture , display.cx , display.cy )
                spriteImage:setFlippedY(true)
                --spriteImage:setBlendFunc( {src = gl.ONE, dst = gl.ONE_MINUS_SRC_ALPHA} )
                app.uiMgr:GetCurrentScene():AddDialog(spriteImage)
                app.uiMgr:GetCurrentScene():runAction(cc.Sequence:create(
                    cc.CallFunc:create(function()
                        self:getViewData().restaurantSpine:setAnimation(0, 'idle', true)
                    end)
                ))
                self:getAppRouter():Dispatch({name = 'HomelandMediator'}, {name = 'HomelandMediator' , params = {delayTimes = 0.8 }})
                self.viewData_.restaurantBtn:setEnabled(true)
                local  scene = app.uiMgr:GetCurrentScene()
                scene:setScale(0.85)
                sceneWorld:runAction(
                    cc.Spawn:create(
                        cc.TargetedAction:create( spriteImage ,
                            cc.Sequence:create(
                                cc.Spawn:create(
                                        cc.FadeOut:create(0.3) ,
                                        cc.ScaleTo:create(0.3, 3)
                                ),
                                cc.DelayTime:create(0.1),
                                cc.RemoveSelf:create()
                            )
                        ),
                        cc.TargetedAction:create(
                            scene , cc.Sequence:create(
                                cc.DelayTime:create(0.1),
                                cc.ScaleTo:create(0.3,1),
                                cc.DelayTime:create(0.1)
                            )
                        )

                    )
                )
            else
                AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = 'AvatarMediator'}, {name = 'AvatarMediator'})
            end

        end
    end,sp.EventType.ANIMATION_END)

    -- update view
    self:unfoldView()
    self:refreshModuleStatus()

    -- add listener
    display.commonUIParams(self.viewData_.marketLockBtn, {cb = handler(self, self.onClickMarketButtonHandler_)})
    display.commonUIParams(self.viewData_.marketUnlockBtn, {cb = handler(self, self.onClickMarketButtonHandler_)})
    display.commonUIParams(self.viewData_.iceRoomLockBtn, {cb = handler(self, self.onClickIceRoomButtonHandler_)})
    display.commonUIParams(self.viewData_.iceRoomUnlockBtn, {cb = handler(self, self.onClickIceRoomButtonHandler_)})
    display.commonUIParams(self.viewData_.discoverLockBtn, {cb = handler(self, self.onClickDiscoverButtonHandler_)})
    display.commonUIParams(self.viewData_.discoverUnlockBtn, {cb = handler(self, self.onClickDiscoverButtonHandler_)})
    display.commonUIParams(self.viewData_.handbookBtn, {cb = handler(self, self.onClickHandbookButtonHandler_), animate = false})
    display.commonUIParams(self.viewData_.restaurantBtn, {cb = handler(self, self.onClickRestaurantButtonHandler_), animate = false})
    display.commonUIParams(self.viewData_.tastingTourBtn, {cb = handler(self, self.onClickTastingTourButtonHandler_), animate = false})
    display.commonUIParams(self.viewData_.tastingTourUnLockBtn, {cb = handler(self, self.onClickTastingTourButtonHandler_), animate = false})
    if GAME_MODULE_OPEN.CARD_ALBUM then
        display.commonUIParams(self.viewData_.cardAlbumBtn, {cb = handler(self, self.onClickCardAlbumButtonHandler_)})
    end
    -- add theme function
    if HOME_THEME_STYLE_DEFINE.EXTRA_PANEL_THEME_FUNC then
        HOME_THEME_STYLE_DEFINE.EXTRA_PANEL_THEME_FUNC(self.viewData_.uiLayer)
    end
end


CreateView = function()
    local size = cc.size(1900, 1002)
    local view = display.newLayer(0, display.cy, {size = size, ap = display.LEFT_CENTER})

    local getFontStyle = function(args)
        local fontStyle = {fontSize = 24, color = '#5b3c25', ttf = true, font = TTF_GAME_FONT}
        table.merge(fontStyle, args)
        return fontStyle
    end

    -- bg layer
    local bgLayer = display.newLayer(0, 0, {size = size})
    view:addChild(bgLayer)

    -- pet button
    local petPath = HOME_THEME_STYLE_DEFINE.PET_BTN or app.plistMgr:checkSpriteFrame(RES_DICT.BTN_PET)
    local petBtn = display.newButton(1350, size.height - 140, {n = petPath, ap = display.CENTER_TOP, enable = false})
    view:addChild(petBtn)

    -- ui layer
    local uiLayer = display.newLayer(0, 0, {size = size})
    uiLayer:setName('uiLayer')
    view:addChild(uiLayer)

    -------------------------------------------------
    -- fold button
    local foldSize = cc.size(140, 100)
    local foldBtn  = display.newButton(1265, 595, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMG), scale9 = true, size = foldSize})
    foldBtn:setName('CLOSE_SLIDE')
    uiLayer:addChild(foldBtn)

    local foldSpine = display.newCacheSpine(SpineCacheName.GLOBAL, 'ui/home/nmain/main_signs')
    foldSpine:setAnimation(0, 'idle', true)
    foldBtn:addChild(foldSpine)

    local arrowImg = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.FOLD_ARROW), foldSize.width/2, foldSize.height/2 - 5)
    arrowImg:setScaleX(-1)
    foldBtn:addChild(arrowImg)

    local foldName = display.newButton(foldSize.width/2, 0, {n = app.plistMgr:checkSpriteFrame(RES_DICT.NAME_FRAME), enable = false, isFlipX = true})
    display.commonLabelParams(foldName, fontWithColor(14, {text = __('返回'), paddingW = 20}))
    foldBtn:addChild(foldName)

    -------------------------------------------------
    -- handbook button
    local handbookSize = cc.size(280, 280)
    local handbookBtn  = display.newButton(330, 458, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMG), scale9 = true, size = handbookSize})
    handbookBtn:setTag(RemindTag.HANDBOOK)
    handbookBtn:setName('HANDBOOK')
    uiLayer:addChild(handbookBtn)

    local handbookSpine = display.newCacheSpine(SpineCacheName.GLOBAL, 'ui/home/nmain/tujian')
    handbookSpine:setPositionX(handbookSize.width/2)
    handbookSpine:setAnimation(0, 'idle', true)
    handbookBtn:addChild(handbookSpine)

    local handbookNameSize = cc.size(160, 50)
    local handbookNameBar  = display.newButton(handbookSize.width/2, 42, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMG), scale9 = true, size = handbookNameSize, enable = false})
    handbookNameBar:addChild(display.newLabel(handbookNameSize.width/2, handbookNameSize.height/2, getFontStyle({text = __('图鉴')})))
    handbookBtn:addChild(handbookNameBar)

    RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = handbookNameBar, tag = RemindTag.HANDBOOK, po = cc.p(handbookNameSize.width/2 + 40, handbookNameSize.height/2 + 28)})

    -------------------------------------------------
    -- cardAlbum button
    local cardAlbumBtn = nil
    if GAME_MODULE_OPEN.CARD_ALBUM then
        cardAlbumBtn = display.newButton(580, 386, {n = app.plistMgr:checkSpriteFrame(RES_DICT.CARD_ALBUM_BTN)})
        display.commonLabelParams(cardAlbumBtn, getFontStyle({text = __('游记')}))
        cardAlbumBtn:setTag(RemindTag.CARD_ALBUM)
        uiLayer:addChild(cardAlbumBtn)
        
        local cardAlbumSpine = display.newCacheSpine(SpineCacheName.GLOBAL, 'ui/home/nmain/book_open')
        cardAlbumSpine:setAnimation(0, 'idle', true)
        cardAlbumBtn:addList(cardAlbumSpine):alignTo(nil, ui.ct)

        RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = cardAlbumBtn, tag = RemindTag.CARD_ALBUM, po = cc.p(cardAlbumBtn:getContentSize().width/2 + 40, cardAlbumBtn:getContentSize().height/2 + 28)})
    end
    -------------------------------------------------
    -- restaurant button
    local restaurantSize = cc.size(250, 600)
    local restaurantBtn  = display.newButton(780, 350, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMG), scale9 = true, size = restaurantSize})
    restaurantBtn:setTag(RemindTag.MANAGER)
    restaurantBtn:setName('MANAGER')
    uiLayer:addChild(restaurantBtn)

    local restaurantSpine = display.newCacheSpine(SpineCacheName.GLOBAL, 'ui/home/nmain/cantin')
    restaurantSpine:setPosition(14, restaurantSize.height -150)
    restaurantSpine:setAnimation(0, 'idle', true)
    restaurantBtn:addChild(restaurantSpine)

    local restaurantNameSize = cc.size(160, 50)
    local restaurantNameBar  = display.newButton(restaurantSize.width/2, restaurantSize.height/2 +150+ 75, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMG), scale9 = true, size = restaurantNameSize, enable = false})
    local text =  __('餐厅')
    local remindTag = RemindTag.MANAGER
    local path = app.plistMgr:checkSpriteFrame(RES_DICT.MAIN_IMG_RESAURANT)
    if  CommonUtils.GetModuleAvailable(MODULE_SWITCH.HOMELAND) and CommonUtils.UnLockModule(JUMP_MODULE_DATA.HOME_LAND)  then
        text =  __('家园')
        remindTag =  RemindTag.HOME_LAND
        path = app.plistMgr:checkSpriteFrame(RES_DICT.MAIN_IMG_HOME)
    end
    restaurantNameBar:addChild(display.newLabel(restaurantNameSize.width/2, restaurantNameSize.height/2, getFontStyle{text = text}))
    restaurantBtn:addChild(restaurantNameBar)
    RemindIcon.addRemindIcon({parent = restaurantNameBar, tag = remindTag , po = cc.p(restaurantNameSize.width/2 + 40, restaurantNameSize.height/2 + 28)})

    local restaurantImage = display.newImageView(_res(path) ,780, 325,{ap = display.CENTER}  )
    bgLayer:addChild(restaurantImage ,-1)
    -------------------------------------------------
    -- function button group
    uiLayer:addChild(display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.BTN_GROUP_IMG), 1060, 642, {ap = display.CENTER_TOP}))

    local functionBtnPos  = cc.p(1068, 560)
    local functionBtnData = {
        {text = __('研究'), tag = RemindTag.DISCOVER, name = 'DISCOVER'},
        {text = __('市场'), tag = RemindTag.MARKET,   name = 'MARKET'},
        {text = __('冰场'), tag = RemindTag.ICEROOM,  name = 'ICEROOM_BUTTON'},
    }

    local funcLockBtnList   = {}
    local funcUnlockBtnList = {}
    for i, btnData in ipairs(functionBtnData) do
        -- function lock button
        local funcLockBtn = display.newButton(functionBtnPos.x, functionBtnPos.y - (i-1)*90, {n = RES_DICT.BTN_FUNCTION_D})
        display.commonLabelParams(funcLockBtn, getFontStyle({text = btnData.text, color = '#FFFFFF', ap = display.CENTER, reqW = 100, outline = '#5b3c25', outlineSize = 1, offset = cc.p(20,0)}))
        local funcLockBtnLabelSize = display.getLabelContentSize(funcLockBtn:getLabel())
        if funcLockBtnLabelSize.width > 140  then
            display.commonLabelParams(funcLockBtn, getFontStyle({text = btnData.text, color = '#FFFFFF', fontSize = 22 , w = 130 , reqW = 100 ,  ap = display.LEFT_CENTER,  outline = '#5b3c25', outlineSize = 1, offset = cc.p(-45,0)}))
        end

        funcLockBtn:addChild(display.newImageView(_res(RES_DICT.ICON_LOCK), 44, 34, {scale = 0.8}))
        funcLockBtn:setTag(btnData.tag)
        uiLayer:addChild(funcLockBtn)

        -- function unlock button
        local funcUnlockBtn = display.newButton(funcLockBtn:getPositionX(), funcLockBtn:getPositionY(), {n = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_FUNCTION_N)})
        display.commonLabelParams(funcUnlockBtn, getFontStyle({text = btnData.text,w = 155 ,reqW = 140  ,reqH = 50,hAlign= display.TAC}))
        funcUnlockBtn:setName(btnData.name)
        funcUnlockBtn:setTag(btnData.tag)
        uiLayer:addChild(funcUnlockBtn)

        funcLockBtnList[i]   = funcLockBtn
        funcUnlockBtnList[i] = funcUnlockBtn
        local funtionBtnSize = funcUnlockBtn:getContentSize()
        RemindIcon.addRemindIcon({parent = funcUnlockBtn, tag = btnData.tag, po = cc.p(funtionBtnSize.width/2 + 40, funtionBtnSize.height/2 + 28)})
    end


    --------料理副本入口--------------
    local tastingTourBtn = display.newButton(display.SAFE_R, size.height/2 - display.size.height/2, {ap = display.RIGHT_BOTTOM, n = app.plistMgr:checkSpriteFrame(RES_DICT.TASTING_TOUR_LOCK)})
    uiLayer:add(tastingTourBtn,100)
    display.commonLabelParams(tastingTourBtn, getFontStyle({text = __('品鉴'), color = '#ffffff', outline = '#5b3c25', outlineSize = 1, offset = cc.p(10,- 55)}))
    tastingTourBtn:setTag(RemindTag.TASTINGTOUR)
    local tastingTourBtnSize =  tastingTourBtn:getContentSize()
    tastingTourBtn:addChild(display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.ICON_LOCK), 95, 46))

    RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = tastingTourBtn, tag =RemindTag.TASTINGTOUR, po = cc.p(tastingTourBtnSize.width/2 + 40, tastingTourBtnSize.height/2 + 28)})

    local tastingTourUnLockBtn = display.newButton(display.SAFE_R, size.height/2 - display.size.height/2, {ap = display.RIGHT_BOTTOM, n = app.plistMgr:checkSpriteFrame(RES_DICT.TASTING_TOUR)})
    uiLayer:add(tastingTourUnLockBtn,100)
    display.commonLabelParams(tastingTourUnLockBtn, getFontStyle({text =__('品鉴')  ,offset = cc.p(0,-55) }))
    tastingTourUnLockBtn:setTag(RemindTag.TASTINGTOUR)

    local qAvatar = display.newCacheSpine(SpineCacheName.GLOBAL, 'ui/home/nmain/fishtravel_entrance')
    qAvatar:update(0)
    qAvatar:setTag(1)
    qAvatar:setAnimation(0, 'idle', true)
    qAvatar:setName("qAvatar")
    qAvatar:setPosition(cc.p(tastingTourBtnSize.width/2 , tastingTourBtnSize.height/2-20 ))
    tastingTourUnLockBtn:addChild(qAvatar)

    RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = tastingTourUnLockBtn, tag =RemindTag.TASTINGTOUR, po = cc.p(tastingTourBtnSize.width/2 + 40, tastingTourBtnSize.height/2 + 28)})

    return {
        view                 = view,
        viewFoldPos          = cc.p(-900, view:getPositionY()),
        viewUnfoldPos        = cc.p(view:getPosition()),
        bgLayer              = bgLayer,
        uiLayer              = uiLayer,
        petBtn               = petBtn,
        foldBtn              = foldBtn,
        handbookBtn          = handbookBtn,
        restaurantBtn        = restaurantBtn,
        restaurantSpine      = restaurantSpine,
        restaurantImage      = restaurantImage ,
        discoverLockBtn      = funcLockBtnList[1],
        discoverUnlockBtn    = funcUnlockBtnList[1],
        marketLockBtn        = funcLockBtnList[2],
        marketUnlockBtn      = funcUnlockBtnList[2],
        iceRoomLockBtn       = funcLockBtnList[3],
        iceRoomUnlockBtn     = funcUnlockBtnList[3],
        tastingTourBtn       = tastingTourBtn,
        tastingTourUnLockBtn = tastingTourUnLockBtn,
        cardAlbumBtn         = cardAlbumBtn,
    }
end


-------------------------------------------------
-- get / set

function HomeExtraPanel:getViewData()
    return self.viewData_
end


function HomeExtraPanel:isFoldView()
    return self.isFoldView_ == true
end


function HomeExtraPanel:isHomeControllable()
    local homeMediator = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
    return homeMediator and homeMediator:isControllable()
end


function HomeExtraPanel:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end


-------------------------------------------------
-- public method

function HomeExtraPanel:delayInit(endCB)
    local init1Func = function(cb)
        local preLoadCount = 4
        local preLoadIndex = 0
        for i = 1, preLoadCount do
            local imgPath = string.fmt('arts/common/main_bg_room_%1.png', string.format('%02d', i))
            display.loadImage(_res(imgPath), function(texture)
                preLoadIndex = preLoadIndex + 1
                if preLoadIndex >= preLoadCount then
                    if cb then cb() end
                end
            end)
        end
    end

    local init2Func = function(cb)
        if SKIN_MASK then
            local preLoadIndex = 0
            local preLoadCount = SKIN_MASK.count
            for i = 1, preLoadCount do
                local imgPath = string.fmt('%1_%2.png', SKIN_MASK.path, string.format('%02d', i))
                display.loadImage(_res(imgPath), function(texture)
                    preLoadIndex = preLoadIndex + 1
                    if preLoadIndex >= preLoadCount then
                        if cb then cb() end
                    end
                end)
            end
        else
            if cb then cb() end
        end
    end

    local init3Func = function()
        self:directInit()
        if endCB then endCB() end
    end

    init1Func(init2Func(init3Func()))
end
function HomeExtraPanel:directInit()
    local bgLayer   = self.viewData_.bgLayer
    local bgImgSize = bgLayer:getContentSize()

    local bgImgView = require('common.SliceBackground').new({size = bgImgSize, count = 4, cols = 2, pic_path_name = 'arts/common/main_bg_room'})
    bgImgView:setAnchorPoint(display.LEFT_CENTER)
    bgImgView:setPositionY(bgImgSize.height/2)
    bgLayer:addChild(bgImgView)

    if SKIN_MASK then
        local bgMaskView = require('common.SliceBackground').new({size = bgImgSize, count = 4, cols = SKIN_MASK.count, pic_path_name = SKIN_MASK.path})
        bgMaskView:setAnchorPoint(display.LEFT_CENTER)
        bgMaskView:setPositionY(bgImgSize.height/2)
        bgLayer:addChild(bgMaskView)
    end
end


function HomeExtraPanel:refreshModuleStatus()
    local viewData = self:getViewData()

    -- check market unlock
    local isUnlockMarket = CommonUtils.UnLockModule(RemindTag.MARKET)
    local isHideMarket   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.MARKET)])]
    viewData.marketLockBtn:setVisible(not isHideMarket and not isUnlockMarket and CommonUtils.GetModuleAvailable(MODULE_SWITCH.MARKET))
    viewData.marketUnlockBtn:setVisible(not isHideMarket and isUnlockMarket and CommonUtils.GetModuleAvailable(MODULE_SWITCH.MARKET))

    -- check discover unlock
    local isUnlockDiscover = CommonUtils.UnLockModule(RemindTag.DISCOVER)
    local isHideDiscover   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.DISCOVER)])]
    viewData.discoverLockBtn:setVisible(not isHideDiscover and not isUnlockDiscover and CommonUtils.GetModuleAvailable(MODULE_SWITCH.RESEARCH))
    viewData.discoverUnlockBtn:setVisible(not isHideDiscover and isUnlockDiscover and CommonUtils.GetModuleAvailable(MODULE_SWITCH.RESEARCH))

    -- check iceRoom unlock
    local isUnlockIceRoom = CommonUtils.UnLockModule(RemindTag.ICEROOM)
    local isHideIceRoom   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.ICEROOM)])]
    viewData.iceRoomLockBtn:setVisible(not isHideIceRoom and not isUnlockIceRoom and CommonUtils.GetModuleAvailable(MODULE_SWITCH.ICEROOM))
    viewData.iceRoomUnlockBtn:setVisible(not isHideIceRoom and isUnlockIceRoom and CommonUtils.GetModuleAvailable(MODULE_SWITCH.ICEROOM))

    -- check tasting tour
    local isUnlockTastingTour = CommonUtils.UnLockModule(RemindTag.TASTINGTOUR)
    local isHideTastingTour   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.TASTINGTOUR)])]
    viewData.tastingTourBtn:setVisible(not isHideTastingTour and not isUnlockTastingTour and CommonUtils.GetModuleAvailable(MODULE_SWITCH.TASTING_TOUR))
    viewData.tastingTourUnLockBtn:setVisible(not isHideTastingTour and isUnlockTastingTour and CommonUtils.GetModuleAvailable(MODULE_SWITCH.TASTING_TOUR))

    -- check handbook
    local isHideHandbook   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.HANDBOOK)])]
    viewData.handbookBtn:setVisible(not isHideHandbook and CommonUtils.GetModuleAvailable(MODULE_SWITCH.HANDBOOK))

    -- check derestauran
    local isHiderestaurant = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.MANAGER)])]
    viewData.restaurantBtn:setVisible(not isHiderestaurant and CommonUtils.GetModuleAvailable(MODULE_SWITCH.RESTAURANT))
end


function HomeExtraPanel:foldView(actionTime)
    self:stopAllActions()
    self.isFoldView_ = true
    self.blackLayer_:setOpacity(180)
    self.blackLayer_:setVisible(true)
    
    local viewData   = self:getViewData()
    local actionTime = checknumber(actionTime)
    viewData.uiLayer:setVisible(true)

    local finishedCB = function()
        self.isControllable_ = false
        self.blackLayer_:setVisible(false)
        viewData.uiLayer:setOpacity(0)
        viewData.uiLayer:setVisible(false)
        viewData.view:setPosition(viewData.viewFoldPos)
    end

    if actionTime > 0 then
        self:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(viewData.view, cc.MoveTo:create(actionTime, viewData.viewFoldPos)),
                cc.TargetedAction:create(viewData.uiLayer, cc.FadeOut:create(actionTime)),
                cc.TargetedAction:create(self.blackLayer_, cc.FadeOut:create(actionTime))
            }),
            cc.CallFunc:create(finishedCB)
        }))
    else
        finishedCB()
    end
end
function HomeExtraPanel:unfoldView(actionTime)
    self:stopAllActions()
    self.isFoldView_ = false
    self.blackLayer_:setOpacity(0)
    self.blackLayer_:setVisible(true)

    local viewData   = self:getViewData()
    local actionTime = checknumber(actionTime)
    viewData.uiLayer:setVisible(true)
    
    local finishedCB = function()
        self.isControllable_ = true
        self.blackLayer_:setOpacity(180)
        viewData.uiLayer:setOpacity(255)
        viewData.view:setPosition(viewData.viewUnfoldPos)
    end

    if actionTime > 0 then
        self:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(viewData.view, cc.MoveTo:create(actionTime, viewData.viewUnfoldPos)),
                cc.TargetedAction:create(viewData.uiLayer, cc.FadeIn:create(actionTime)),
                cc.TargetedAction:create(self.blackLayer_, cc.FadeTo:create(actionTime, 180))
            }),
            cc.CallFunc:create(finishedCB)
        }))
    else
        finishedCB()
    end
end


function HomeExtraPanel:eraseHideFuncAt(moduleId)
    self.funcHideMap_[tostring(moduleId)] = false
    self:refreshModuleStatus()
end


function HomeExtraPanel:getFuncViewAt(moduleId)
    local viewData  = self:getViewData()
    local remindTag = checkint(REMIND_TAG_MAP[tostring(moduleId)])
	return self:getViewData().uiLayer:getChildByTag(remindTag)
end


-------------------------------------------------
-- private method

function HomeExtraPanel:upateRemindStatus_(remindIcon)
    if remindIcon then
        remindIcon:UpdateLocalData()
    end
end


-------------------------------------------------
-- handler

function HomeExtraPanel:onClickMarketButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end
    if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_EXTRA_PANEL_NORMAL) then return end

    if CommonUtils.UnLockModule(RemindTag.MARKET, true) then
        -- update remind icon
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))

        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'MarketMediator'})
    end
end


function HomeExtraPanel:onClickTastingTourButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end
    if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_EXTRA_PANEL_NORMAL) then return end

    if CommonUtils.UnLockModule(RemindTag.TASTINGTOUR, true) then
        -- update remind icon
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))

        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'tastingTour.TastingTourChooseRecipeStyleMediator'})
    end
end


function HomeExtraPanel:onClickIceRoomButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end
    if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_EXTRA_PANEL_NORMAL) then return end

    if CommonUtils.UnLockModule(RemindTag.ICEROOM, true) then
        -- update remind icon
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))

        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'IceRoomMediator'})
    end
end


function HomeExtraPanel:onClickDiscoverButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    if CommonUtils.UnLockModule(RemindTag.DISCOVER, true) then
        -- update remind icon
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))

        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'RecipeResearchAndMakingMediator'})
    end
end


function HomeExtraPanel:onClickHandbookButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end
    if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_EXTRA_PANEL_NORMAL) then return end

    self:getAppRouter():Dispatch({name = 'HandbookMediator'}, {name = 'HandbookMediator'})
end


function HomeExtraPanel:onClickRestaurantButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    local styleCount  = 0
    local styleConfs  = CommonUtils.GetConfigAllMess('style', 'cooking') or {}
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    for styleId, styleData in pairs (gameManager:GetUserInfo().cookingStyles or {}) do
        local styleConf = styleConfs[styleId] or {}
        if styleConf and checkint(styleConf.initial) == 1 then
            styleCount = styleCount + 1
        end
    end

    -- 如果是0，则去选择一个菜系解锁
    if styleCount == 0 then
        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'RecipeResearchAndMakingMediator'})
    else
        sender:setEnabled(false)
        self:getViewData().restaurantSpine:setAnimation(0, 'play', false)
    end
end

function HomeExtraPanel:onClickCardAlbumButtonHandler_(sender)
    PlayAudioByClickNormal()
    self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'collection.cardAlbum.CardAlbumMediator'})
end

return HomeExtraPanel
