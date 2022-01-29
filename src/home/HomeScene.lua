--[[
 * author : kaishiqi
 * descpt : 主页 - 主界面场景
]]
local RemindIcon       = require('common.RemindIcon')
local HomeMapPanel     = require('home.HomeMapPanel')
local HomeFuncBar      = require('home.HomeFuncBar')
local HomeFuncSlider   = require('home.HomeFuncSlider')
local HomeExtraPanel   = require('home.HomeExtraPanel')
local CommonChatPanel  = require('common.CommonChatPanel')
local VoiceWordNode    = require('common.VoiceWordNode')
local CardSkinL2dNode  = require('common.CardSkinL2dNode')
local CardSkinDrawNode = require('common.CardSkinDrawNode')
local HomeScene        = class('HomeScene', require('Frame.GameScene'))

local RES_DICT = {
    ALPHA_IMG          = 'ui/common/story_tranparent_bg.png',
    LEFT_FRAME         = 'arts/common/main_ico_light_left.png',
    NAME_FRAME         = 'share/main_bg_go_restaurant.png',
    SLIDER_ARROW       = 'ui/home/nmain/main_btn_switch_left_arrow.png',
    TASK_BAR           = 'ui/home/nmain/main_bg_main_task.png',
    DAILY_BTN          = 'ui/home/nmain/main_btn_diary_task.png',
    BTN_CLOSE_INFO     = 'ui/home/nmain/main_btn_warning_close.png',
    GATEWAY_BG_LIGHT   = 'ui/home/nmain/main_vavle_bg_light.png',
    GATEWAY_BTN_TITLE  = 'ui/home/nmain/main_bg_name_ico_l.png',
    GATEWAY_BTN_FRAME  = 'ui/home/nmain/vip_main_bg_function_plate.png',
    BTN_GATEWAY        = 'ui/home/nmain/main_ico_vavle.png',
    BTN_RESTURANT      = 'ui/home/nmain/main_ico_resturant.png',
    BTN_WATER_BAR      = 'ui/home/nmain/main_ico_bar.png',
    BTN_CAT_HOUSE      = 'ui/home/nmain/main_ico_cat.png',
    BTN_BOX_ROOM       = 'ui/home/nmain/main_ico_vip_room.png',
    BTN_FISHING        = 'ui/home/nmain/fishing_main_ico_bait_full.png',
    LOCK_ICON          = 'ui/common/common_ico_lock.png',
    MAP_CLOUD          = 'ui/home/nmain/main_bg_cloud.png',
    BOSS_INFO_FRAME    = 'ui/worldboss/main/main_worldboss_frame_bg.png',
    MATCH_INFO_FRAME   = 'ui/home/nmain/main_3v3_frame_bg.png',
    MAIN_GOLD_FRAME_BG = 'ui/home/nmain/main_gold_frame_bg.png',
    MARRY_MAGIC        = 'ui/cards/marry/anime_fazhen.png',
    REMIND_ICON_PATH   = 'ui/common/common_hint_circle_red_ico.png',
    MAIN_FREE_FRAME_BG = 'ui/home/nmain/main_new_card_bg.png',
}

local CreateView         = nil
local CreateGatewayView  = nil
local AUTO_PLAY_INTERVAL = 60
local HOME_ASSETS_PLISTS = {
    'ui/home/nmain/homeButtons.plist',
    'ui/home/nmain/homeAssets.plist',
}


-------------------------------------------------
-- life cycle

function HomeScene:ctor(args)
    self.super.ctor(self, 'home.HomeScene')
    
    -- pre-load plist
    local spriteFrameCache = cc.SpriteFrameCache:getInstance()
    for _, plistPath in ipairs(HOME_ASSETS_PLISTS) do
        spriteFrameCache:addSpriteFrames(plistPath)
        -- 需要提前将 plist 中的每个 frame 提前 retain 一次，防止使用前被清空纹理时释放掉。（因为释放机制是清除没用到的 frame，而不是 plist 依赖的）
        local absolutePath = app.fileUtils:fullPathForFilename(plistPath)
        local plistDict = app.fileUtils:getValueMapFromFile(absolutePath)
        for frameKey, _ in pairs(plistDict.frames) do
            local frameObj = spriteFrameCache:getSpriteFrame(frameKey)
            if frameObj then
                frameObj:retain()
            end
        end
    end
    
    -- parse args
    local hideFuncMap  = {}
    local hideFuncList = checktable(args.hideFuncList)
    for _, moduleId in ipairs(hideFuncList) do
        hideFuncMap[tostring(moduleId)] = checkint(moduleId)
    end

    local funcHideStatusMap = {}
    for moduleId, from in pairs(HOME_FUNC_FROM_MAP) do
        funcHideStatusMap[tostring(from)] = funcHideStatusMap[tostring(from)] or {}
        funcHideStatusMap[tostring(from)][tostring(moduleId)] = hideFuncMap[tostring(moduleId)] ~= nil
    end

    self.funcHideMap_ = funcHideStatusMap['HOME_SCENE'] or {}
    self.isInited_    = false

    -- create view
    self.viewData_ = CreateView(funcHideStatusMap)
    self.viewData_.view:setName('HomeSceneView')
    self:AddGameLayer(self.viewData_.view)

    self.funcOwnerObjMap_ = {
        ['HOME_MAP']    = self:getMapPanel(),
        ['FUNC_BAR']    = self:getFuncBar(),
        ['FUNC_SLIDER'] = self:getFuncSlider(),
        ['EXTRA_PANEL'] = self:getExtraPanel(),
    }

    -- update view
    self:refreshNoticeBoardsStatus()

    if self.viewData_.chatPanel then self.viewData_.chatPanel:setControllable(false) end
    self.viewData_.gatewayBtn:setVisible(CommonUtils.GetModuleAvailable(MODULE_SWITCH.HOMELAND) and CommonUtils.UnLockModule(JUMP_MODULE_DATA.HOME_LAND))

    -- add listener
    local unfoldBtn = self:getViewData().unfoldBtn
    local foldBtn   = self.viewData_.extraPanel:getViewData().foldBtn
    display.commonUIParams(foldBtn, {cb = handler(self, self.onClickFoldButtonHandler_)})
    display.commonUIParams(unfoldBtn, {cb = handler(self, self.onClickUnfoldButtonHandler_)})
    display.commonUIParams(self.viewData_.taskBar, {cb = handler(self, self.onClickTaskButtonHandler_)})
    display.commonUIParams(self.viewData_.dailyBtn, {cb = handler(self, self.onClickDailyButtonHandler_)})
    display.commonUIParams(self.viewData_.gatewayBtn, {cb = handler(self, self.onClickGatewayButtonHandler_), animate = false})
    display.commonUIParams(self.viewData_.gotoBossBtn, {cb = handler(self, self.onClickGotoWorldBossButtonHandler_)})
    display.commonUIParams(self.viewData_.closeBossBtn, {cb = handler(self, self.onClickCloseWorldBossButtonHandler_)})
    display.commonUIParams(self.viewData_.gotoMatchBtn, {cb = handler(self, self.onClickGoto3v3MatchBattleButtonHandler_)})
    display.commonUIParams(self.viewData_.closeMatchBtn, {cb = handler(self, self.onClickClose3v3MatchBattleButtonHandler_)})
    display.commonUIParams(self.viewData_.closeBlackGoldBtn, {cb = handler(self, self.onClickCloseBlackGoldButtonHandler_)})
    display.commonUIParams(self.viewData_.gotoBlackGoldBtn, {cb = handler(self, self.onClickGotoBlackGoldButtonHandler_)})
    display.commonUIParams(self.viewData_.gotoFreeNewbieBtn, {cb = handler(self, self.onClickGotoFreeNewbieButtonHandler_)})
    display.commonUIParams(self.viewData_.closeFreeNewbieBtn, {cb = handler(self, self.onClickCloseFreeNewbieButtonHandler_)})
    self.viewData_.mainCardNode:setClickCallback(handler(self, self.onClickMainCardNodeCallback_))
    self.viewData_.l2dDrawNode:setClickCallback(handler(self, self.onClickMainL2dNodeCallback_))
end


CreateView = function(funcHideStatusMap)
    local view = display.newLayer()
    local size = view:getContentSize()

    -- map panel
    local mapPanel = HomeMapPanel.new({funcHideMap = funcHideStatusMap['HOME_MAP']})
    mapPanel:setName('home.HomeMapPanel')
    view:addChild(mapPanel)

    local cloudImgSize = cc.size(1624, 164)
    local upCloudImg   = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.MAP_CLOUD), size.width/2, display.height, {ap = display.CENTER_BOTTOM, scale = -1, alpha = 125, scale9 = true, size = cloudImgSize})
    local downCloudImg = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.MAP_CLOUD), size.width/2, 0, {ap = display.CENTER_BOTTOM, alpha = 165, scale9 = true, size = cloudImgSize})
    view:addChild(downCloudImg)
    view:addChild(upCloudImg)

    -------------------------------------------------
    -- task bar
    local taskSize = cc.size(120, 52)
    local taskBar  = display.newLayer(display.SAFE_R, size.height - 180, {color = cc.r4b(0), size = taskSize, ap = display.RIGHT_CENTER, enable = true})
    taskBar:setTag(RemindTag.STORY_TASK)
    taskBar:setName('BTN_STORY')
    taskBar:setScaleX(0)
    view:addChild(taskBar)

    local taskBarFrame = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.TASK_BAR), 0, 0, {ap = display.LEFT_BOTTOM, scale9 = true})
    taskBar:addChild(taskBarFrame)

    local taskTypeLabel = display.newLabel(taskSize.width/2 - 50, taskSize.height/2 + 11, fontWithColor(7, {fontSize = 19, color = '#F8CA38'}))
    taskBar:addChild(taskTypeLabel)
    
    local taskNameLable = display.newLabel(taskSize.width/2 - 50, taskSize.height/2 - 12, fontWithColor(14, {fontSize = 21, color = '#FFFFFF'}))
    taskBar:addChild(taskNameLable)

    RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = taskBar, tag = RemindTag.STORY, po = cc.p(25, taskSize.height - 5)})


    -- daily button
    local dailyBtn = display.newButton(display.SAFE_R - 177, taskBar:getPositionY(), {n = app.plistMgr:checkSpriteFrame(RES_DICT.DAILY_BTN), ap = display.RIGHT_CENTER, scale9 = true})
    dailyBtn:getNormalImage():setCapInsets(cc.rect(60,2,40,50))
    dailyBtn:setContentSize(dailyBtn:getNormalImage():getOriginalSize())
    display.commonLabelParams(dailyBtn, fontWithColor(20, {fontSize = 22, color = '#FFF0A8', outline = '#811908', text = __('日常'), paddingW = 30, offset = cc.p(35,0), safeW = 50}))
    dailyBtn:setTag(RemindTag.TASK)
    dailyBtn:setScaleX(0)
    view:addChild(dailyBtn)

    RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = dailyBtn, tag = RemindTag.TASK, po = cc.p(15, taskSize.height - 5)})
    
    -------------------------------------------------

    -- extra panel
    local extraPanel = HomeExtraPanel.new({funcHideMap = funcHideStatusMap['EXTRA_PANEL']})
    extraPanel:setName('home.HomeExtraPanel')
    extraPanel:setOpacity(0)
    extraPanel:foldView()
    view:addChild(extraPanel)
    
    -- marry magic image
    local marryMagicImg = display.newImageView(_res(RES_DICT.MARRY_MAGIC), display.SAFE_L + display.cx, display.cy - 50, {ap = display.RIGHT_CENTER})
    marryMagicImg:setVisible(false)
    view:addChild(marryMagicImg)

    -- signboard layer
    local signboardLayer = display.newLayer(display.SAFE_L + display.cx, 0, {ap = display.CENTER_BOTTOM})
    view:addChild(signboardLayer)
    
    -- l2d drawNode
    local l2dDrawNode = CardSkinL2dNode.new({coordinateType = COORDINATE_TYPE_LIVE2D_HOME, notRefresh = true})
    signboardLayer:addChild(l2dDrawNode)
    l2dDrawNode:setVisible(false)
    
    -- main cardNode
    local mainCardNode = CardSkinDrawNode.new({coordinateType = COORDINATE_TYPE_HOME, notRefresh = true})
    signboardLayer:addChild(mainCardNode)
    mainCardNode:setVisible(false)
    
    -- marry spine
    local marrySpine  = nil
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.MARRY) and utils.isExistent('effects/marry/fly.atlas') then
        marrySpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
        marrySpine:setPosition(display.center)
        marrySpine:setAnimation(0, 'idle2', true)
        marrySpine:update(0)
        marrySpine:setToSetupPose()
        marrySpine:setVisible(false)
        signboardLayer:addChild(marrySpine)
    end


    -------------------------------------------------
    -- func slider
    local funcSlider = HomeFuncSlider.new({funcHideMap = funcHideStatusMap['FUNC_SLIDER']})
    funcSlider:setName('home.HomeFuncSlider')
    view:addChild(funcSlider)

    -- func bar
    local funcBar = HomeFuncBar.new({funcHideMap = funcHideStatusMap['FUNC_BAR']})
    funcBar:setName('home.HomeFuncBar')
    view:addChild(funcBar)


    -------------------------------------------------
    -- left view
    local leftSize = cc.size(display.SAFE_L + 140, size.height)
    local leftView = display.newLayer(0, size.height/2, {size = leftSize, ap = display.LEFT_CENTER})
    leftView:setName('LeftView')
    view:addChild(leftView)

    local leftFrameSize = cc.size(display.SAFE_L + 95, size.height)
    local leftFrameImg  = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.LEFT_FRAME), 0, leftSize.height/2, {scale9 = true, size = leftFrameSize, ap = display.LEFT_CENTER})
    leftView:addChild(leftFrameImg)
    
    local leftParticle = cc.ParticleSystemQuad:create('ui/guangdian.plist')
    display.commonUIParams(leftParticle, {po = cc.p(0, leftSize.height/2), ap = display.LEFT_CENTER})
    leftView:addChild(leftParticle)
    
    -- unfold button
    local unfoldSize = cc.size(140, 100)
    local unfoldBtn  = display.newButton(leftSize.width, leftSize.height/2 + 35, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMG), scale9 = true, size = unfoldSize, ap = display.RIGHT_CENTER})
    unfoldBtn:setName('Button')
    leftView:addChild(unfoldBtn)

    local unfoldSpine = display.newCacheSpine(SpineCacheName.GLOBAL, 'ui/home/nmain/main_signs')
    unfoldSpine:setAnimation(0, 'idle', true)
    unfoldBtn:addChild(unfoldSpine)

    unfoldBtn:addChild(display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.SLIDER_ARROW), unfoldSize.width/2, unfoldSize.height/2 - 5))
    local unfoldNameBar = display.newButton(unfoldSize.width/2, 0, {n = RES_DICT.NAME_FRAME, enable = false})
    display.commonLabelParams(unfoldNameBar, fontWithColor(14, {text = __('去经营'), paddingW = 20}))
    unfoldBtn:addChild(unfoldNameBar)

    RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = unfoldBtn, tag = RemindTag.MANAGER, po = cc.p(unfoldSize.width/2 + 40, unfoldSize.height/2 + 28)})


    -- gateway lightBg
    local gatewayLightBg = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.GATEWAY_BG_LIGHT), display.SAFE_L, leftSize.height/2 + 175, {ap = display.LEFT_CENTER, scale9 = true, capInsets = cc.rect(60, 60, 120, 100)})
    leftView:addChild(gatewayLightBg)
    gatewayLightBg:setVisible(false)

    -- gateway button
    local gatewayBtn = display.newButton(leftSize.width, gatewayLightBg:getPositionY(), {n = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_GATEWAY), ap = display.RIGHT_CENTER})
    gatewayBtn:setName('gatewayButton')
    leftView:addChild(gatewayBtn)

    local gatewayNameBar = display.newButton(gatewayBtn:getContentSize().width/2, 25, {n = app.plistMgr:checkSpriteFrame(RES_DICT.NAME_FRAME), enable = false})
    display.commonLabelParams(gatewayNameBar, fontWithColor(14, {text = __('传送门'), paddingW = 20}))
    gatewayBtn:addChild(gatewayNameBar)
    

    -------------------------------------------------
    -- chat panel
    local chatPanel = nil
    if ChatUtils.IsModuleAvailable() then
        chatPanel = CommonChatPanel.new()
        view:addChild(chatPanel)
    end

    -------------------------------------------------
    local noticeBoardsBasePos = cc.p(display.SAFE_L + 210, 140)
    local noticeBoardsPosList = {
        cc.p(0, -10),
        cc.p(0, 78),
        cc.p(0, 166),
        cc.p(0, 254),
    }

    -- bossInfo layer
    local bossInfoLayer = display.newLayer()
    bossInfoLayer:setVisible(false)
    view:addChild(bossInfoLayer)
    
    local gotoBossBtn = display.newButton( noticeBoardsBasePos.x, noticeBoardsBasePos.y, {n = app.plistMgr:checkSpriteFrame(RES_DICT.BOSS_INFO_FRAME)})
    bossInfoLayer:addChild(gotoBossBtn)

    local bossTimeLabel = display.newLabel(noticeBoardsBasePos.x , noticeBoardsBasePos.y - 15, fontWithColor(9, {text = '--:--:--'}))
    bossInfoLayer:addChild(display.newLabel(bossTimeLabel:getPositionX(), noticeBoardsBasePos.y + 13, fontWithColor(5, {color = '#FFDFAA', text = __('灾祸出现中！')})))
    bossInfoLayer:addChild(bossTimeLabel)

    local closeBossBtn = display.newButton(noticeBoardsBasePos.x - 170, noticeBoardsBasePos.y , {n = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_CLOSE_INFO)})
    bossInfoLayer:addChild(closeBossBtn)


    -- matchInfo layer
    local matchInfoLayer = display.newLayer()
    matchInfoLayer:setVisible(false)
    view:addChild(matchInfoLayer)

    local gotoMatchBtn =  display.newButton(noticeBoardsBasePos.x, noticeBoardsBasePos.y, {n = app.plistMgr:checkSpriteFrame(RES_DICT.MATCH_INFO_FRAME)})
    matchInfoLayer:addChild(gotoMatchBtn)

    local matchTimeLabel = display.newLabel(noticeBoardsBasePos.x , noticeBoardsBasePos.y - 15, fontWithColor(9, {text = '--:--:--'}))
    matchInfoLayer:addChild(matchTimeLabel)

    local matchDescrLabel = display.newLabel(matchTimeLabel:getPositionX(), noticeBoardsBasePos.y + 13, fontWithColor(5))
    matchInfoLayer:addChild(matchDescrLabel)

    local closeMatchBtn = display.newButton(noticeBoardsBasePos.x - 170, noticeBoardsBasePos.y , {n = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_CLOSE_INFO)})
    matchInfoLayer:addChild(closeMatchBtn)


    -- blackGold layer
    local blackGoldLayer = display.newLayer()
    blackGoldLayer:setVisible(false)
    view:addChild(blackGoldLayer)

    local gotoBlackGoldBtn = display.newButton( noticeBoardsBasePos.x, noticeBoardsBasePos.y, { n = app.plistMgr:checkSpriteFrame(RES_DICT.MAIN_GOLD_FRAME_BG)})
    blackGoldLayer:addChild(gotoBlackGoldBtn)

    local blackGoldTimeLabel = display.newLabel(noticeBoardsBasePos.x, noticeBoardsBasePos.y - 15, fontWithColor(9, {text = '--:--:--'}))
    blackGoldLayer:addChild(blackGoldTimeLabel)

    local blackGoldDescrLabel = display.newLabel(matchTimeLabel:getPositionX(), noticeBoardsBasePos.y + 13, fontWithColor(5))
    blackGoldLayer:addChild(blackGoldDescrLabel)

    local closeBlackGoldBtn = display.newButton(noticeBoardsBasePos.x - 170, noticeBoardsBasePos.y , {n = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_CLOSE_INFO)})
    blackGoldLayer:addChild(closeBlackGoldBtn)
    
    
    -- freeNewbie layer
    local freeNewbieLayer = ui.layer()
    freeNewbieLayer:setVisible(false)
    view:addChild(freeNewbieLayer)
    
    local gotoFreeNewbieBtn = display.newButton( noticeBoardsBasePos.x, noticeBoardsBasePos.y, { n = app.plistMgr:checkSpriteFrame(RES_DICT.MAIN_FREE_FRAME_BG)})
    freeNewbieLayer:addChild(gotoFreeNewbieBtn)

    local freeNewbieDescrLabel = display.newLabel(matchTimeLabel:getPositionX(), noticeBoardsBasePos.y, fontWithColor(5))
    freeNewbieLayer:addChild(freeNewbieDescrLabel)

    local closeFreeNewbieBtn = display.newButton(noticeBoardsBasePos.x - 170, noticeBoardsBasePos.y , {n = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_CLOSE_INFO)})
    freeNewbieLayer:addChild(closeFreeNewbieBtn)

    return {
        view                = view,
        mapPanel            = mapPanel,
        funcSlider          = funcSlider,
        extraPanel          = extraPanel,
        signboardLayer      = signboardLayer,
        marryMagicImg       = marryMagicImg,
        mainCardNode        = mainCardNode,
        l2dDrawNode         = l2dDrawNode,
        marrySpine          = marrySpine,
        funcBar             = funcBar,
        leftView            = leftView,
        unfoldBtn           = unfoldBtn,
        gatewayBtn          = gatewayBtn,
        gatewayLightBg      = gatewayLightBg,
        taskBar             = taskBar,
        dailyBtn            = dailyBtn,
        taskDefaultSize     = taskSize,
        taskBarFrame        = taskBarFrame,
        taskTypeLabel       = taskTypeLabel,
        taskNameLable       = taskNameLable,
        chatPanel           = chatPanel,
        noticeBoardsPosList = noticeBoardsPosList,
        bossInfoLayer       = bossInfoLayer,
        bossTimeLabel       = bossTimeLabel,
        gotoBossBtn         = gotoBossBtn,
        closeBossBtn        = closeBossBtn,
        matchInfoLayer      = matchInfoLayer,
        matchTimeLabel      = matchTimeLabel,
        matchDescrLabel     = matchDescrLabel,
        gotoMatchBtn        = gotoMatchBtn,
        closeMatchBtn       = closeMatchBtn,
        blackGoldLayer      = blackGoldLayer,
        blackGoldTimeLabel  = blackGoldTimeLabel,
        blackGoldDescrLabel = blackGoldDescrLabel,
        gotoBlackGoldBtn    = gotoBlackGoldBtn,
        closeBlackGoldBtn   = closeBlackGoldBtn,
        freeNewbieLayer     = freeNewbieLayer,
        gotoFreeNewbieBtn   = gotoFreeNewbieBtn,
        freeNewbieDescrLabel= freeNewbieDescrLabel,
        closeFreeNewbieBtn  = closeFreeNewbieBtn,
    }
end


CreateGatewayView = function()
    local view = display.newLayer()

    -- block bg
    local blockBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(blockBg)

    -- function button
    local funcBtnSize   = cc.size(120, 120)
    local createBtnFunc = function(buttonDefine)
        local size = funcBtnSize
        local view = display.newButton(0, 0, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMG), scale9 = true, size = size})
        local path = HOME_THEME_STYLE_DEFINE.FUNC_FRAME or app.plistMgr:checkSpriteFrame(RES_DICT.GATEWAY_BTN_FRAME)
        view:setTag(checkint(buttonDefine.tag))
        view:addChild(display.newImageView(path, size.width/2, size.height/2))

        local normalImg = display.newImageView(buttonDefine.image, size.width/2, size.height/2 + 10)
        view:addChild(normalImg)

        local nameBar = display.newButton(size.width/2, 20, {n = app.plistMgr:checkSpriteFrame(RES_DICT.GATEWAY_BTN_TITLE), enable = false})
        display.commonLabelParams(nameBar, fontWithColor(20, {text = checkstr(buttonDefine.title), fontSize = 22}))
        view:addChild(nameBar)

        local lockIcon = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.LOCK_ICON), size.width/2, size.height/2 + 10)
        view:addChild(lockIcon)

        RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = view, tag = view:getTag(), po = cc.p(size.width - 25, size.height - 15)})

        return {
            view       = view,
            normalImg  = normalImg,
            lockIcon   = lockIcon,
        }
    end

    local funBtnList = {}
    local btnDefines = {
        {title = __('餐厅'), tag = RemindTag.MANAGER,    image = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_RESTURANT), funcKey = 'resturant'},
        {title = __('包厢'), tag = RemindTag.BOX_MODULE, image = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_BOX_ROOM), funcKey = 'boxRoom'},
        {title = __('钓场'), tag = RemindTag.FISH_GROUP, image = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_FISHING), funcKey = 'fishGroup'},
    }
    if GAME_MODULE_OPEN.WATER_BAR then
        table.insert(btnDefines, {title = __('水吧'), tag = RemindTag.WATER_BAR,  image = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_WATER_BAR), funcKey = 'waterBar'})
    end
    if GAME_MODULE_OPEN.CAT_HOUSE then
        table.insert(btnDefines, {title = __('御屋'), tag = RemindTag.CAT_HOUSE,  image = app.plistMgr:checkSpriteFrame(RES_DICT.BTN_CAT_HOUSE), funcKey = 'catHouse'})
    end
    for i, btnDefine in ipairs(btnDefines) do
        local btnViewData   = createBtnFunc(btnDefine)
        btnViewData.funcKey = btnDefine.funcKey
        view:addChild(btnViewData.view)
        table.insert(funBtnList, btnViewData)
    end

    local findFunBtn = function(funcKey)
        local btnNode = nil
        for _, btnViewData in ipairs(funBtnList) do
            if btnViewData.funcKey == funcKey then
                btnNode = btnViewData.view
                break
            end
        end
        return btnNode
    end

    return {
        view         = view,
        blockBg      = blockBg,
        funBtnList   = funBtnList,
        funcBtnSize  = funcBtnSize,
        resturantBtn = findFunBtn('resturant'),
        boxRoomBtn   = findFunBtn('boxRoom'),
        fishingBtn   = findFunBtn('fishGroup'),
        waterBarBtn  = findFunBtn('waterBar'),
        catHouseBtn  = findFunBtn('catHouse'),
    }
end


-------------------------------------------------
-- get / set

function HomeScene:getViewData()
    return self.viewData_
end


function HomeScene:getMapPanel()
    return self:getViewData().mapPanel
end


function HomeScene:getExtraPanel()
    return self:getViewData().extraPanel
end


function HomeScene:getFuncSlider()
    return self:getViewData().funcSlider
end


function HomeScene:getFuncBar()
    return self:getViewData().funcBar
end


function HomeScene:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end


function HomeScene:isHomeControllable()
    local homeMediator = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
    return homeMediator and homeMediator:isControllable()
end
function HomeScene:setHomeControllable(isControllable)
    local homeMediator = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
    if homeMediator then
        homeMediator:setControllable(isControllable)
    end
end


function HomeScene:isInited()
    return self.isInited_ == true
end


-------------------------------------------------
-- public method

function HomeScene:directInit()
    self:initStep1_()
    self:initStep2_()
    self:initStep3_()
end


function HomeScene:delayInit()
    local step1Delay = 0.1
    local step2Delay = 0.1
    local stepTime1  = 0.2
    local stepTime2  = 0.2

    -- run init action
    self:runAction(cc.Sequence:create({
        cc.DelayTime:create(step1Delay),
        cc.CallFunc:create(function()
            self:initStep1_(stepTime1)
        end),
        cc.DelayTime:create(stepTime1 + step2Delay),
        cc.CallFunc:create(function()
            self:initStep2_(stepTime2)
        end)
    }))
end


function HomeScene:refreshModuleStatus()
    self:refreshMainTask()
end
function HomeScene:refreshAllModuleStatus()
    self:refreshModuleStatus()
    self:getMapPanel():refreshModuleStatus()
    self:getExtraPanel():refreshModuleStatus()
    self:getFuncSlider():refreshModuleStatus()
    self:getFuncBar():refreshModuleStatus()
end


function HomeScene:refreshMainCard()
    local marrySpine   = self.viewData_.marrySpine
    local mainCardNode = self.viewData_.mainCardNode
    local l2dDrawNode  = self.viewData_.l2dDrawNode
    local homeCardUuid = checkint(app.gameMgr:GetUserInfo().signboardId)
    local homeCardData = app.gameMgr:GetCardDataById(homeCardUuid) or {}
    local hasCardData  = next(homeCardData) ~= nil

    if hasCardData then
        local checkShowMarrySpineFunc = function()
            if app.cardMgr.GetCouple(homeCardUuid) then
                local cardCoordConf = CommonUtils.GetConfig('cards', 'coordinate', homeCardData.cardId) or {}
                local coordTeamConf = cardCoordConf[COORDINATE_TYPE_TEAM] or {}
                local coordHomeConf = cardCoordConf[COORDINATE_TYPE_HOME] or {}
                if marrySpine then
                    marrySpine:setPositionX(-checkint(coordTeamConf.x) / checkint(coordTeamConf.scale) * checkint(coordHomeConf.scale) + checkint(coordHomeConf.x) + 80)
                    marrySpine:setPositionY(checkint((display.height - CC_DESIGN_RESOLUTION.height) / 2))
                    marrySpine:setOpacity(0)
                    marrySpine:setVisible(true)
                    marrySpine:stopAllActions()
                    marrySpine:runAction(cc.Sequence:create(
                        cc.DelayTime:create(0.2),
                        cc.FadeIn:create(0.2)
                    ))
                end
            else
                if marrySpine then marrySpine:setVisible(false) end
            end
        end

        local playHomeMainCardSoundFunc = function()
            if not app.gameMgr:GetUserInfo().isPlayHomeMainCardSound_ then
                self:showMainCardVoiceWord_(SoundType.TYPE_HOME_CARD_CHANGE)
                app.gameMgr:GetUserInfo().isPlayHomeMainCardSound_ = true
            end
            self:startAutoPlayMainCardVoice_()
        end
        
        -- live2dNode
        if CardUtils.IsShowCardLive2d(homeCardData.defaultSkinId) then
            if l2dDrawNode then
                l2dDrawNode:setOpacity(0)
                l2dDrawNode:setVisible(true)
                l2dDrawNode:stopAllActions()
                l2dDrawNode:runAction(cc.Sequence:create(
                    -- cc.DelayTime:create(0.5),
                    cc.CallFunc:create(function()
                        l2dDrawNode:refreshL2dNode({skinId = homeCardData.defaultSkinId, motion = "Start"})
                    end),
                    cc.Spawn:create(
                        cc.FadeIn:create(0.5),
                        cc.CallFunc:create(checkShowMarrySpineFunc)
                    ),
                    cc.CallFunc:create(playHomeMainCardSoundFunc)
                ))
            end

            if mainCardNode then mainCardNode:setVisible(false) end
            
        -- drawNode
        else
            local cardDrawPath = CardUtils.GetCardDrawPathBySkinId(homeCardData.defaultSkinId)
            if mainCardNode then
                mainCardNode:setVisible(true)
                display.loadImage(cardDrawPath, function(texture)
                    if mainCardNode.RefreshAvatar then
                        mainCardNode:RefreshAvatar({skinId = homeCardData.defaultSkinId})
                    end
    
                    if mainCardNode.GetAvatar and mainCardNode:GetAvatar() then
                        mainCardNode:GetAvatar():setOpacity(0)
                        mainCardNode:GetAvatar():stopAllActions()
                        mainCardNode:GetAvatar():runAction(cc.Sequence:create(
                            cc.Spawn:create(
                                cc.FadeIn:create(0.2),
                                cc.CallFunc:create(checkShowMarrySpineFunc)
                            ),
                            cc.CallFunc:create(function()
                                playHomeMainCardSoundFunc()
                                mainCardNode:GetAvatar():runAction(cc.RepeatForever:create(cc.Sequence:create(
                                    cc.MoveBy:create(2, cc.p(0, 15)),
                                    cc.MoveBy:create(2, cc.p(0, -15))
                                )))
                            end)
                        ))
                    end
                end)
            end

            if l2dDrawNode then l2dDrawNode:setVisible(false) end
        end

    -- hide card node
    else
        if mainCardNode and mainCardNode:GetAvatar() then
            mainCardNode:GetAvatar():stopAllActions()
            mainCardNode:GetAvatar():setVisible(false)
        end
        if l2dDrawNode then
            l2dDrawNode:stopAllActions()
            l2dDrawNode:setVisible(false)
        end
        if marrySpine then
            marrySpine:stopAllActions()
            marrySpine:setVisible(false)
        end
    end
end


function HomeScene:refreshNoticeBoardsStatus()
    local playerLevel = checkint(app.gameMgr:GetUserInfo().level)

    -- refresh worldBoss
    if playerLevel >= CommonUtils.GetModuleOpenLevel(MODULE_SWITCH.WORLD_BOSS) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.WORLD_BOSS) then
        self:updateWorldBossStatus_()
        self:startWorldBossCountdown_()
    end
    
    -- refresh 3v3 matchBattle
    if playerLevel >= CommonUtils.GetModuleOpenLevel(MODULE_SWITCH.TAG_MATCH) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.TAG_MATCH) then
        self:update3v3MatchBattleStatus_()
        self:start3v3MatchBattleCountdown_()
    end

    -- refresh blackGold
    if playerLevel >= CommonUtils.GetModuleOpenLevel(MODULE_SWITCH.BLACK_GOLD) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.BLACK_GOLD) then
        self:updateBlackGoldStatus_()
    end

    -- refresh freeNewbie
    self:updateFreeNewbieStatus_()
    
    -- re-sort position
    local bossInfoLayer       = self:getViewData().bossInfoLayer
    local matchInfoLayer      = self:getViewData().matchInfoLayer
    local blackGoldLayer      = self:getViewData().blackGoldLayer
    local freeNewbieLayer     = self:getViewData().freeNewbieLayer
    local noticeBoardsPosList = self:getViewData().noticeBoardsPosList
    local layerTable = {
        {node = bossInfoLayer  , pos = 1},
        {node = matchInfoLayer , pos = 1},
        {node = blackGoldLayer , pos = 1},
        {node = freeNewbieLayer, pos = 1},
    }
    local visibleCount = 0
    for _, v in pairs(layerTable) do
        if v.node and v.node:isVisible() then
            visibleCount = visibleCount + 1
            v.pos = visibleCount
        end
    end
    for i, v in pairs(layerTable) do
        if v.node then
            v.node:setPosition(noticeBoardsPosList[v.pos])
        end
    end
    --if bossInfoLayer:isVisible() then
    --    matchInfoLayer:setPosition(noticeBoardsPosList[2])
    --else
    --    matchInfoLayer:setPosition(noticeBoardsPosList[1])
    --end
end


function HomeScene:refreshMainTask()
    local taskType    = ''
	local taskName    = ''
	local gameManager = AppFacade.GetInstance():GetManager('GameManager')
	local newPlotTask = gameManager:GetUserInfo().newestPlotTask or {}
	local branchList  = gameManager:GetUserInfo().branchList or {}

	-- check plot task
    if next(newPlotTask) ~= nil then
		local plotTaskId   = checkint(newPlotTask.taskId)
		local plotTaskConf = CommonUtils.GetConfig('quest', 'questPlot', plotTaskId) or {}

		if checkint(newPlotTask.hasDrawn) == 0 then
			taskType = __('主线任务')
			taskName = tostring(plotTaskConf.name)
		end
	end

	-- check branch task
	if string.len(taskType) == 0 then
		local branchIdList = {}
		for branchId, branchData in pairs(branchList) do
			if checkint(branchData.hasDrawn) == 0  then
                local branchConf = CommonUtils.GetConfig('quest', 'branch', branchId)
                if branchConf then
                    table.insert(branchIdList, checkint(branchId))
                end
			end
		end

		if #branchIdList > 0 then
			table.sort(branchIdList, function(a, b) return a < b end)
			local branchConf = CommonUtils.GetConfig('quest', 'branch', branchIdList[1]) or {}
			taskType = __('支线任务')
			taskName = tostring(branchConf.name)
		end
	end

	-- next plot task
	if string.len(taskType) == 0 then
		local nextPlotConf = CommonUtils.GetConfig('quest', 'questPlot', checkint(newPlotTask.taskId) + 1)
		taskType = __('剧情任务')
		taskName = nextPlotConf and tostring(nextPlotConf.name) or __('点击查看详情')
    end
    
    -- update task baar
    self:updateTaskBarInfo_(taskType, taskName)
end


function HomeScene:getFuncViewAt(moduleId)
    local funcFrom = checkstr(HOME_FUNC_FROM_MAP[checkint(moduleId)])
    if funcFrom == 'HOME_SCENE' then
        local viewData  = self:getViewData()
        local remindTag = checkint(REMIND_TAG_MAP[tostring(moduleId)])
        return self:getViewData().view:getChildByTag(remindTag)
    else
        local ownerObj = self.funcOwnerObjMap_[tostring(funcFrom)]
        if ownerObj and ownerObj.getFuncViewAt then
            return ownerObj:getFuncViewAt(moduleId)
        end
    end
    return nil
end


function HomeScene:eraseHideFuncAt(moduleId)
    local funcFrom = checkstr(HOME_FUNC_FROM_MAP[checkint(moduleId)])
    if funcFrom == 'HOME_SCENE' then
        self.funcHideMap_[tostring(moduleId)] = false
        self:refreshModuleStatus()
    else
        local ownerObj = self.funcOwnerObjMap_[tostring(funcFrom)]
        if ownerObj then
            if ownerObj.eraseHideFuncAt then
                ownerObj:eraseHideFuncAt(moduleId)
            end
            if ownerObj.refreshModuleStatus then
                ownerObj:refreshModuleStatus()
            end
        end
    end
end


-------------------------------------------------
-- private method

function HomeScene:initStep1_(actTime)
    -- pre init other views
    self:refreshMainTask()
    self:getFuncBar():reloadBar()
    self:getFuncSlider():setSliderPage(1)

    -- show homeTopLayer ui
    local appMediator  = AppFacade.GetInstance():RetrieveMediator('AppMediator')
    local homeTopLayer = appMediator and appMediator:GetViewComponent() or nil
    if homeTopLayer then
        homeTopLayer:initShow(actTime or 0.2)
    end
    
    -- show homeMap node
    if self:getViewData().mapPanel then
        self:getViewData().mapPanel:delayInit()
    end
end
function HomeScene:initStep2_(actTime)
    local extraPanel = self:getViewData().extraPanel
    if extraPanel then
        extraPanel:delayInit()

        if actTime then
            -- update fold status
            self:updateFoldStatus_()

            -- unfold extralPanel
            local isUnfold = CommonUtils.ModulePanelIsOpen()
            if isUnfold then
                extraPanel:foldView()
                extraPanel:unfoldView(actTime)
            end

            -- show extralPanel
            self:runAction(cc.Sequence:create({
                cc.TargetedAction:create(extraPanel, cc.FadeIn:create(actTime)),
                cc.CallFunc:create(function()
                    self:initStep3_()
                end)
            }))
        else
            -- update fold status
            extraPanel:setOpacity(255)
            self:updateFoldStatus_()
        end

    else
        -- update fold status
        self:updateFoldStatus_()
    end
end
function HomeScene:initStep3_()
    local homeMdt = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
    if homeMdt then
        homeMdt:initHomeWorkflow()
    end

    -- update mainCardNode
    self:refreshMainCard()
    
    -- init chatPanel
    local chatPanel = self:getViewData().chatPanel
    if chatPanel then
        chatPanel:delayInit()
        chatPanel:setControllable(true)
    end

    -- mark init finished
    self.isInited_ = true
end


function HomeScene:updateFoldStatus_()
    local viewData = self:getViewData()
    local isUnfold = CommonUtils.ModulePanelIsOpen()
    if viewData.funcBar then viewData.funcBar:setVisible(not isUnfold) end
    if viewData.leftView then viewData.leftView:setVisible(not isUnfold) end
    if viewData.funcSlider then viewData.funcSlider:setVisible(not isUnfold) end
    if viewData.signboardLayer then viewData.signboardLayer:setVisible(not isUnfold) end
    viewData.marryMagicImg:stopAllActions()
    viewData.marryMagicImg:setVisible(false)
    if viewData.extraPanel then
        if isUnfold then
            viewData.extraPanel:unfoldView()
        else
            viewData.extraPanel:foldView()
        end
    end
end


function HomeScene:updateTaskBarInfo_(taskType, taskName)
    local taskType = checkstr(taskType)
    local taskName = checkstr(taskName)
    local viewData = self:getViewData()
    local hasTask  = string.len(taskType) > 0 or string.len(taskName) > 0
    display.commonLabelParams(viewData.taskTypeLabel, {text = taskType})
    display.commonLabelParams(viewData.taskNameLable, {text = taskName, maxW = 220})

    local taskBarSize     = viewData.taskBar:getContentSize()
    local nameLabelSize   = display.getLabelContentSize(viewData.taskNameLable)
    local typeLabelSize   = display.getLabelContentSize(viewData.taskTypeLabel)
    local taskDefaultSize = viewData.taskDefaultSize
    taskBarSize.width     = math.max(taskDefaultSize.width, math.max(nameLabelSize.width, typeLabelSize.width)) + 70
    viewData.taskBar:setContentSize(taskBarSize)
    viewData.taskBarFrame:setContentSize(taskBarSize)
    viewData.taskTypeLabel:setPositionX(taskBarSize.width/2 - 15)
    viewData.taskNameLable:setPositionX(taskBarSize.width/2 - 15)
    
    local isUnlockDaily  = CommonUtils.UnLockModule(RemindTag.TASK)
    local dailyBtnAction = cc.TargetedAction:create(viewData.dailyBtn, cc.ScaleTo:create(0.2, isUnlockDaily and 1 or 0, 1))
    if hasTask then
        viewData.dailyBtn:setPositionX(viewData.taskBar:getPositionX() - taskBarSize.width + 14)

        local taskActList = {}
        if viewData.taskBar:getScaleX() <= 0 then
            table.insert(taskActList, cc.ScaleTo:create(0.2, 1, 1))
        end
        table.insert(taskActList, dailyBtnAction)
        viewData.taskBar:runAction(cc.Sequence:create(taskActList))

    else
        viewData.dailyBtn:setPosition(viewData.taskBar:getPosition())

        local taskActList = {}
        if viewData.taskBar:getScaleX() > 0 then
            table.insert(taskActList, cc.ScaleTo:create(0.2, 0, 1))
        end
        table.insert(taskActList, dailyBtnAction)
        viewData.taskBar:runAction(cc.Sequence:create(taskActList))
    end

    local isHideFunc = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.STORY_TASK)])]
    viewData.taskBar:setVisible(not isHideFunc)
end


function HomeScene:showMainCardVoiceWord_(soundType)
    local homeCardUuid   = checkint(app.gameMgr:GetUserInfo().signboardId)
    local homeCardData   = app.gameMgr:GetCardDataById(homeCardUuid) or {}
    local mainCardId     = checkint(homeCardData.cardId)
    local signboardLayer = self.viewData_.signboardLayer
    local tipeNode       = signboardLayer and signboardLayer:getChildByName('TIP_NODE') or nil
    if  (not tipeNode or not tipeNode.canRemove) and self:getExtraPanel():isFoldView()
        and not app:RetrieveMediator('Anniversary19HomePosterMediator') 
        and not app:RetrieveMediator('AnniversaryHomePosterMediator') 
        and not app:RetrieveMediator('CapsuleNewMediator')
        and not app:RetrieveMediator('CapsuleMediator')
        and not self:GetGameLayerByName('operaStage') then
            
        -- play voice
        local time, voiceId = CommonUtils.PlayCardSoundByCardId(mainCardId, soundType, SoundChannel.HOME_SCENE)
        if checkint(time) > 0 then
            local voiceNode = VoiceWordNode.new({cardId = mainCardId, time = time + 1, voiceId = voiceId})
            voiceNode:setPosition(display.width * 0.45, display.cy)
            voiceNode:setName('TIP_NODE')
            if signboardLayer then
            signboardLayer:addChild(voiceNode)
            end
            self.autoPlayMainCardVoiceStartTime_ = os.time() - checkint(time)
        end
    else
        self.autoPlayMainCardVoiceStartTime_ = os.time()
    end
end


function HomeScene:startAutoPlayMainCardVoice_()
    if self.autoPlayMainCardVoiceUpdateHandler_ then return end
    self.autoPlayMainCardVoiceStartTime_     = os.time()
    self.autoPlayMainCardVoiceUpdateHandler_ = scheduler.scheduleUpdateGlobal(function()
        if os.time() - self.autoPlayMainCardVoiceStartTime_ > AUTO_PLAY_INTERVAL then
            self:showMainCardVoiceWord_(SoundType.TYPE_KAN_BAN)
        end
    end)
end
function HomeScene:stopAutoPlayMainCardVoice_()
    if self.autoPlayMainCardVoiceUpdateHandler_ then
        scheduler.unscheduleGlobal(self.autoPlayMainCardVoiceUpdateHandler_)
        self.autoPlayMainCardVoiceUpdateHandler_ = nil
    end
end


function HomeScene:startWorldBossCountdown_()
    if self.worldBossCountdownHandler_ then return end
    self.worldBossCountdownHandler_ = scheduler.scheduleGlobal(function()
        self:updateWorldBossStatus_()
    end, 1)
end
function HomeScene:stopWorldBossCountdown_()
    if self.worldBossCountdownHandler_ then
        scheduler.unscheduleGlobal(self.worldBossCountdownHandler_)
        self.worldBossCountdownHandler_ = nil
    end
end
function HomeScene:updateWorldBossStatus_()
    local bossInfoLayer = self:getViewData().bossInfoLayer
    local bossTimeLabel = self:getViewData().bossTimeLabel
    local isUnlockBoss  = CommonUtils.UnLockModule(RemindTag.WORLD_BOSS) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.WORLD_BOSS) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.WORLD)
    
    -- update boss time
    if isUnlockBoss then
        -- update worldBoss iconTip
        local bossMapData = app.gameMgr:getWorldBossMapData() or {}
        local serverTime  = getServerTime()
        local isOpenBoss  = false
        for _, bossData in pairs(bossMapData) do
            if (serverTime >= checkint(bossData.startTime) and 
                serverTime < checkint(bossData.endTime)) then
                isOpenBoss = true

                -- update leftTime
                local leftSeconds = checkint(bossData.endTime) - serverTime
                display.commonLabelParams(bossTimeLabel, {text = string.formattedTime(leftSeconds, '%02i:%02i:%02i')})
                break
            end
        end
        self:getFuncSlider():setWorldBossTipVisible(isOpenBoss)

        -- update worldInfo infoFrame
        if app.gameMgr:isIgnoreTodayWorldBoss() then
            bossInfoLayer:setVisible(false)
        else
            bossInfoLayer:setVisible(isOpenBoss)
        end

    else
        bossInfoLayer:setVisible(false)
    end
end


function HomeScene:start3v3MatchBattleCountdown_()
    if self.matchBattle3v3CountdownHandler_ then return end
    self.matchBattle3v3CountdownHandler_ = scheduler.scheduleGlobal(function()
        self:update3v3MatchBattleStatus_()
    end, 1)
end
function HomeScene:stop3v3MatchBattleCountdown_()
    if self.matchBattle3v3CountdownHandler_ then
        scheduler.unscheduleGlobal(self.matchBattle3v3CountdownHandler_)
        self.matchBattle3v3CountdownHandler_ = nil
    end
end
function HomeScene:update3v3MatchBattleStatus_()
    local matchInfoLayer  = self:getViewData().matchInfoLayer
    local matchTimeLabel  = self:getViewData().matchTimeLabel
    local matchDescrLabel = self:getViewData().matchDescrLabel
    local isUnlock3v3     = CommonUtils.UnLockModule(RemindTag.TAG_MATCH) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.TAG_MATCH)
    
    -- update match time
    if isUnlock3v3 then
        local matchData    = app.gameMgr:get3v3MatchBattleData() or {}
        local matchSection = checkint(matchData.section)
        local isMatchApply = checkint(matchData.isApply)
        if not app.gameMgr:isIgnoreToday3v3MatchBattle(matchSection) then
            
            -- update leftTime
            local serverTime      = getServerTime()
            local leftSeconds = checkint(matchData.endTime) - serverTime
            display.commonLabelParams(matchTimeLabel, {text = string.formattedTime(leftSeconds, '%02i:%02i:%02i')})
            
            -- update matchDescr / infoFrame
            local matchDescrText = ''
            if matchSection == MATCH_BATTLE_3V3_TYPE.APPLY then
                display.commonLabelParams(matchDescrLabel, {color = '#FFDFAA', text = __('天城演武报名中！')})
                matchInfoLayer:setVisible(isMatchApply ~= 1)
    
            elseif matchSection == MATCH_BATTLE_3V3_TYPE.BATTLE then
                display.commonLabelParams(matchDescrLabel, {color = '#FF5F11', text = __('天城演武开战中！')})
                matchInfoLayer:setVisible(true)
    
            else
                matchInfoLayer:setVisible(false)
            end
            
        else
            matchInfoLayer:setVisible(false)
        end

    else
        matchInfoLayer:setVisible(false)
    end
end


function HomeScene:updateBlackGoldStatus_()
    local blackGoldLayer      = self:getViewData().blackGoldLayer
    local blackGoldTimeLabel  = self:getViewData().blackGoldTimeLabel
    local blackGoldDescrLabel = self:getViewData().blackGoldDescrLabel
    local isUnlockBlackGold   = CommonUtils.UnLockModule(RemindTag.BLACK_GOLD) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.BLACK_GOLD)

    -- update time
    if isUnlockBlackGold and not app.gameMgr:isIgnoreTodayBlackGold(app.blackGoldMgr:GetStatus()) then
        if table.nums(app.blackGoldMgr:GetHomeData()) > 0 then
            
            -- update leftTime
            local leftSeconds = app.blackGoldMgr:GetLeftSeconds()
            display.commonLabelParams(blackGoldTimeLabel, {text = string.formattedTime(leftSeconds, '%02i:%02i:%02i')})
            
            -- update descr / infoFrame
            if app.blackGoldMgr:GetIsTrade() then
                display.commonLabelParams(blackGoldDescrLabel, {color = '#FFDFAA', text = __('商船靠岸中，赶快前去投资！')})
                blackGoldLayer:setVisible(true)
            else
                display.commonLabelParams(blackGoldDescrLabel, {color = '#FF5F11', text = __('商船已出海')})
                blackGoldLayer:setVisible(false)
            end
            
        else
            blackGoldLayer:setVisible(false)
        end

    else
        blackGoldLayer:setVisible(false)
    end
end


function HomeScene:updateFreeNewbieStatus_()
    local freeNewbieLayer      = self:getViewData().freeNewbieLayer
    local freeNewbieDescrLabel = self:getViewData().freeNewbieDescrLabel

    -- update
    if not app.gameMgr:isIgnoreTodayFreeNewbie() then
        if app.gameMgr:hasFreeNewbieCapsule() then
            
            -- update descr / infoFrame
            display.commonLabelParams(freeNewbieDescrLabel, {color = '#FF5F11', text = __('新手卡池开启中\n超强UR免费领！')})
            freeNewbieLayer:setVisible(true)
        else
            freeNewbieLayer:setVisible(false)
        end
    else
        freeNewbieLayer:setVisible(false)
    end
end


-------------------------------------------------
-- handler

function HomeScene:onCleanup()
    self:stopAutoPlayMainCardVoice_()
    self:stop3v3MatchBattleCountdown_()
    self:stopWorldBossCountdown_()

    if self.gatewayViewData_ then
        self.gatewayViewData_.view:runAction(cc.RemoveSelf:create(true))
        self.gatewayViewData_ = nil
    end

    -- 不能用 app.fileUtils，因为在注销的时候 app 也会被清空，但是 app.fileUtils:xxxxx 不正常执行也不报错……坑
    local spriteFrameCache = cc.SpriteFrameCache:getInstance()
    for _, plistPath in ipairs(HOME_ASSETS_PLISTS) do
        local absolutePath = cc.FileUtils:getInstance():fullPathForFilename(plistPath)
        local plistDict = cc.FileUtils:getInstance():getValueMapFromFile(absolutePath)
        for frameKey, _ in pairs(plistDict.frames) do
            local frameObj = spriteFrameCache:getSpriteFrame(frameKey)
            if frameObj then
                frameObj:release()
            end
        end
        spriteFrameCache:removeSpriteFramesFromFile(plistPath)
    end
end


function HomeScene:onClickMainCardNodeCallback_(cardId)
    local mainCardNode  = self.viewData_.mainCardNode
    local marryMagicImg = self.viewData_.marryMagicImg
    if self:isHomeControllable() and mainCardNode and checkint(cardId) > 0 then
        local cardManager  = AppFacade.GetInstance():GetManager('CardManager')
        local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
        self:showMainCardVoiceWord_((cardManager.GetCouple(gameManager:GetCardDataByCardId(cardId).id)) and SoundType.TYPE_JIEHUN or SoundType.TYPE_TOUCH)

        -- run marry magicImg action
        if cardManager.GetCouple(gameManager:GetCardDataByCardId(cardId).id) then
            marryMagicImg:stopAllActions()
            marryMagicImg:setOpacity(0)
            marryMagicImg:runAction(cc.Sequence:create(
                cc.Show:create(),
                cc.FadeTo:create(1, 150),
                cc.DelayTime:create(1),
                cc.FadeOut:create(1),
                cc.Hide:create()
            ))
        end

        -- run mainCard action
        mainCardNode:stopAllActions()
        mainCardNode:setScale(1)
		mainCardNode:runAction(cc.Sequence:create({
			cc.ScaleTo:create(0.1, 1.005, 0.995),
			cc.ScaleTo:create(0.1, 0.995, 1.005),
			cc.ScaleTo:create(0.1, 1, 1)
		}))
    end
end


function HomeScene:onClickMainL2dNodeCallback_(cardId)
    local l2dDrawNode   = self.viewData_.l2dDrawNode
    local marryMagicImg = self.viewData_.marryMagicImg
    if self:isHomeControllable() and l2dDrawNode and checkint(cardId) > 0 then
        local cardManager  = AppFacade.GetInstance():GetManager('CardManager')
        local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
        self:showMainCardVoiceWord_((cardManager.GetCouple(gameManager:GetCardDataByCardId(cardId).id)) and SoundType.TYPE_JIEHUN or SoundType.TYPE_TOUCH)

        -- run marry magicImg action
        if cardManager.GetCouple(gameManager:GetCardDataByCardId(cardId).id) then
            marryMagicImg:stopAllActions()
            marryMagicImg:setOpacity(0)
            marryMagicImg:runAction(cc.Sequence:create(
                cc.Show:create(),
                cc.FadeTo:create(1, 150),
                cc.DelayTime:create(1),
                cc.FadeOut:create(1),
                cc.Hide:create()
            ))
        end

        -- run live2dNode action
        l2dDrawNode:onClickCallback()
    end
end


function HomeScene:onClickFoldButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not CommonUtils.ModulePanelIsOpen() then return end
    
    -- switch cache data
    self:setHomeControllable(false)
    CommonUtils.ModulePanelIsOpen(true)
    
    -- init view status
    local viewData = self:getViewData()
    viewData.leftView:setOpacity(0)
    viewData.leftView:setVisible(true)
    viewData.signboardLayer:setOpacity(0)
    viewData.signboardLayer:setVisible(true)
    viewData.marryMagicImg:stopAllActions()
    viewData.marryMagicImg:setVisible(false)
    viewData.funcSlider:setVisible(false)
    viewData.funcBar:setVisible(false)

    -- run fold action
    local actionTime = 0.2
    self:runAction(cc.Sequence:create(
        cc.CallFunc:create(function()
            viewData.extraPanel:foldView(actionTime)
        end),
        cc.Spawn:create(
            cc.TargetedAction:create(viewData.leftView, cc.FadeIn:create(actionTime)),
            cc.TargetedAction:create(viewData.signboardLayer, cc.FadeIn:create(actionTime))
        ),
        cc.CallFunc:create(function()
            self:updateFoldStatus_()
            self:setHomeControllable(true)
            GuideUtils.DispatchStepEvent()
            AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
        end)
    ))
end


function HomeScene:onClickUnfoldButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or CommonUtils.ModulePanelIsOpen() then return end
    
    -- switch cache data
    self:setHomeControllable(false)
    CommonUtils.ModulePanelIsOpen(true)
    
    -- init view status
    local viewData = self:getViewData()
    viewData.leftView:setOpacity(255)
    viewData.leftView:setVisible(true)
    viewData.signboardLayer:setOpacity(255)
    viewData.signboardLayer:setVisible(true)
    viewData.funcSlider:setVisible(false)
    viewData.funcBar:setVisible(false)

    -- run unfold action
    local actionTime = 0.2
    self:runAction(cc.Sequence:create(
        cc.CallFunc:create(function()
            viewData.extraPanel:unfoldView(actionTime)
        end),
        cc.Spawn:create(
            cc.TargetedAction:create(viewData.leftView, cc.FadeOut:create(actionTime)),
            cc.TargetedAction:create(viewData.signboardLayer, cc.FadeOut:create(actionTime))
        ),
        cc.CallFunc:create(function()
            self:updateFoldStatus_()
            self:setHomeControllable(true)
            GuideUtils.DispatchStepEvent()
            AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
        end)
    ))
end


function HomeScene:onClickTaskButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end
    if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_SCENE_TASK) then return end

    -- update remind icon
    local remindIcon = sender:getChildByTag(checkint(sender:getTag()))
    if remindIcon then
        remindIcon:UpdateLocalData() 
    end

    self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'StoryMissionsMediator'})
end


function HomeScene:onClickDailyButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end

    -- update remind icon
    local remindIcon = sender:getChildByTag(checkint(sender:getTag()))
    if remindIcon then
        remindIcon:UpdateLocalData() 
    end

    if CommonUtils.UnLockModule(RemindTag.TASK , true) then
		self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'task.TaskHomeMediator', params = {isGameLayer = 1, isExecuteDefSingle = 1}})
	end
end


function HomeScene:onClickGotoWorldBossButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end
    
    app.router:Dispatch({name = 'HomeMediator'}, {name = 'WorldMediator'})
end


function HomeScene:onClickCloseWorldBossButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end
    
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    cc.UserDefault:getInstance():setStringForKey(gameManager:getWorldBossTodayKey(), gameManager:getWorldBossTodayValue())
    cc.UserDefault:getInstance():flush()

    self:refreshNoticeBoardsStatus()
end


function HomeScene:onClickGoto3v3MatchBattleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end
    
    app.router:Dispatch({name = 'HomeMediator'}, {name = 'ActivityMediator', params = {activityId = ACTIVITY_ID.TAG_MATCH}})
end


function HomeScene:onClickGotoBlackGoldButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end

    display.loadImage(_res('ui/home/blackShop/gold_home_fg_boat.png'))
    display.loadImage(_res('ui/home/blackShop/gold_home_bg_leave.png'))
    display.loadImage(_res('ui/home/blackShop/gold_home_bg.png'))
    display.loadImage(_res('ui/home/blackShop/gold_home_bg_boat.png'))
    app.blackGoldMgr:AddSpineCache()
    
    app.router:Dispatch({name = 'HomeMediator'}, {name = 'blackGold.BlackGoldHomeMeditor'})
end


function HomeScene:onClickGotoFreeNewbieButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end
    
    app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {type = ACTIVITY_TYPE.FREE_NEWBIE_CAPSULE}})
end


function HomeScene:onClickClose3v3MatchBattleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end
    
    local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
    local matchData    = gameManager:get3v3MatchBattleData() or {}
    local matchSection = checkint(matchData.section)
    cc.UserDefault:getInstance():setStringForKey(gameManager:get3v3MatchBattleTodayKey(matchSection), gameManager:get3v3MatchBattleTodayValue())
    cc.UserDefault:getInstance():flush()

    self:refreshNoticeBoardsStatus()
end


function HomeScene:onClickCloseBlackGoldButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end

    local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
    cc.UserDefault:getInstance():setStringForKey(gameManager:getBlackGoldTodayKey(app.blackGoldMgr:GetStatus()), gameManager:getBlackGoldTodayValue())
    cc.UserDefault:getInstance():flush()

    self:refreshNoticeBoardsStatus()
end


function HomeScene:onClickCloseFreeNewbieButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end

    local gameManager  = AppFacade.GetInstance():GetManager('GameManager')
    cc.UserDefault:getInstance():setStringForKey(gameManager:getFreeNewbieTodayKey(), gameManager:getFreeNewbieTodayValue())
    cc.UserDefault:getInstance():flush()

    self:refreshNoticeBoardsStatus()
end


function HomeScene:onClickGatewayButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() then return end
    if self.gatewayViewData_ then return end
    
    -- create gateway view
    self.gatewayViewData_ = CreateGatewayView()
    self:AddDialog(self.gatewayViewData_.view)
    
    -- init view status
    local BUTTON_GAP_W = self.gatewayViewData_.funcBtnSize.width + 20
    local originBtnPos = cc.pAdd(self.viewData_.gatewayBtn:convertToWorldSpaceAR(cc.p(0,0)), cc.p(-BUTTON_GAP_W/2,-5))
    for i, btnViewData in ipairs(self.gatewayViewData_.funBtnList) do
        btnViewData.lockIcon:setVisible(not CommonUtils.UnLockModule(MODULE_DATA[tostring(btnViewData.view:getTag())]))
        btnViewData.view:setPosition(originBtnPos)
        btnViewData.view:setScale(0)
    end

    local gatewayBtnCount = #self.gatewayViewData_.funBtnList
    local gatewayLightBg  = self.viewData_.gatewayLightBg
    local gatewayLightBgW = gatewayBtnCount * BUTTON_GAP_W + self.viewData_.gatewayBtn:getContentSize().width + 80
    gatewayLightBg:setContentSize(cc.size(gatewayLightBgW, gatewayLightBg:getContentSize().height))
    gatewayLightBg:setVisible(true)
    gatewayLightBg:setOpacity(0)
    gatewayLightBg:setScaleX(0)


    -- show gatewayBar function
    local showActTime  = 0.1
    local showInterval = 0.05
    local showGatewayBarFunc = function()
        local showActList = {}
        for i, btnViewData in ipairs(self.gatewayViewData_.funBtnList) do
            local actionTime = showActTime + i * showInterval
            local btnViewPos = cc.p(originBtnPos.x + (i) * BUTTON_GAP_W, originBtnPos.y)
            table.insert(showActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 1))))
            table.insert(showActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.MoveTo:create(actionTime, btnViewPos))))
        end
        
        local gatewayLightBgShowTime = showActTime + gatewayBtnCount * showInterval
        table.insert(showActList, cc.TargetedAction:create(gatewayLightBg, cc.EaseCubicActionOut:create(cc.FadeIn:create(gatewayLightBgShowTime))))
        table.insert(showActList, cc.TargetedAction:create(gatewayLightBg, cc.EaseCubicActionOut:create(cc.ScaleTo:create(gatewayLightBgShowTime, 1))))

        self.gatewayViewData_.view:runAction(cc.Sequence:create(
            cc.Spawn:create(showActList)
        ))
    end


    -- hide gatewayBar function
    local hideActTime  = 0.06
    local hideInterval = 0.02
    local hideGatewayBarFunc = function()
        local hideActList  = {}
        if self.gatewayViewData_ then
            for i, btnViewData in ipairs(self.gatewayViewData_.funBtnList) do
                local actionTime = hideActTime + i * hideInterval
                table.insert(hideActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 0))))
                table.insert(hideActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.MoveTo:create(actionTime, originBtnPos))))
            end
        end

        local gatewayLightBgHideTime = hideActTime + gatewayBtnCount * hideInterval
        table.insert(hideActList, cc.TargetedAction:create(gatewayLightBg, cc.EaseCubicActionOut:create(cc.FadeOut:create(gatewayLightBgHideTime))))
        table.insert(hideActList, cc.TargetedAction:create(gatewayLightBg, cc.EaseCubicActionOut:create(cc.ScaleTo:create(gatewayLightBgHideTime, 0, 1))))
        
        if self.gatewayViewData_ then
            self.gatewayViewData_.view:runAction(cc.Sequence:create(
                cc.Spawn:create(hideActList),
                cc.CallFunc:create(function()
                    self.gatewayViewData_ = nil
                end),
                cc.RemoveSelf:create(true)
            ))
        end
    end


    -- add listener
    display.commonUIParams(self.gatewayViewData_.blockBg, {cb = function(sender)
        sender:setTouchEnabled(false)
        hideGatewayBarFunc()
    end})

    display.commonUIParams(self.gatewayViewData_.resturantBtn, {cb = function(sender)
        PlayAudioByClickNormal()
        if tolua.isnull(self) or not self:isHomeControllable() then return end

        hideGatewayBarFunc()
        app.router:Dispatch({name = 'AvatarMediator'}, {name = 'AvatarMediator'})
    end})
    
    display.commonUIParams(self.gatewayViewData_.boxRoomBtn, {cb = function(sender)
        PlayAudioByClickNormal()
        if tolua.isnull(self) or not self:isHomeControllable() then return end

        if CommonUtils.UnLockModule(MODULE_DATA[tostring(sender:getTag())], true) then
            hideGatewayBarFunc()
			app.router:Dispatch({name = 'HomeMediator'}, {name = 'privateRoom.PrivateRoomHomeMediator'})
		end
    end})

    display.commonUIParams(self.gatewayViewData_.fishingBtn, {cb = function(sender)
        PlayAudioByClickNormal()
        if tolua.isnull(self) or not self:isHomeControllable() then return end

        if CommonUtils.UnLockModule(MODULE_DATA[tostring(sender:getTag())], true) then
            hideGatewayBarFunc()
			app.router:Dispatch({name = 'HomeMediator'}, {name = 'fishing.FishingGroundMediator', params = {queryPlayerId = app.gameMgr:GetUserInfo().playerId}})
		end
    end})

    display.commonUIParams(self.gatewayViewData_.waterBarBtn, {cb = function(sender)
        PlayAudioByClickNormal()
        if tolua.isnull(self) or not self:isHomeControllable() then return end

        if CommonUtils.UnLockModule(MODULE_DATA[tostring(sender:getTag())], true) then
            hideGatewayBarFunc()
            app.router:Dispatch({name = 'HomeMediator'}, {name = 'waterBar.WaterBarHomeMediator'})
        end
    end})
    display.commonUIParams(self.gatewayViewData_.catHouseBtn, {cb = function(sender)
        PlayAudioByClickNormal()
        if tolua.isnull(self) or not self:isHomeControllable() then return end
        
        if CommonUtils.UnLockModule(MODULE_DATA[tostring(sender:getTag())], true) then
            hideGatewayBarFunc()
            app.router:Dispatch({name = 'HomeMediator'}, {name = 'catHouse.CatHouseHomeMediator'})
        end
    end})

    -- show
    showGatewayBarFunc()
end


return HomeScene
