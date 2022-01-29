--[[
 * author : kaishiqi
 * descpt : 主界面 - 功能滑块
]]
local RemindIcon     = require('common.RemindIcon')
local HomeFuncSlider = class('HomeFuncSlider', function()
    return display.newLayer(0, 0, {name = 'home.HomeFuncSlider', enableEvent = true})
end)

local RES_DICT = {
    ALPHA_IMAGE         = 'ui/common/story_tranparent_bg.png',
    LOCK_ICON           = 'ui/common/common_ico_lock.png',
    BTN_FRAME           = 'ui/home/nmain/vip_main_bg_function_plate.png',
    WORLD_BOSS_IMG      = 'ui/worldboss/main/anime_warning.png',
    MAIN_TIME_BG_REWARD = 'ui/home/nmain/main_time_bg_reward.png',
    REMIND_ICON_PATH    = 'ui/common/common_hint_circle_red_ico.png',
}


local SLIDER_PAGES = 2
local BUTTON_GAP_W = 132
local BUTTON_GAP_H = 100

local CreateView         = nil
local CreateFrameButton  = nil
local CreateSimpleButton = nil


-------------------------------------------------
-- life cycle

function HomeFuncSlider:ctor(args)
    self.funcHideMap_     = args.funcHideMap or {}
    self.hideFuncIdList_  = {}
    self.isControllable_  = true

    -- create view
    self.viewData_ = CreateView()
    self.viewData_.view:setName('FuncSliderView')
    self:addChild(self.viewData_.view)

    -- update view
    -- self:setSliderPage(1)
    self:refreshModuleStatus()

    -- add listener
    AppFacade.GetInstance():RegistObserver(COUNT_DOWN_ACTION, mvc.Observer.new(self.onTimerCountdownHandler_, self))
    display.commonUIParams(self.viewData_.sliderBtn, {cb = handler(self, self.onClickSliderButtonHandler_)})
    display.commonUIParams(self.viewData_.capsuleBtn.view, {cb = handler(self, self.onClickCapsuleButtonHandler_)})
    display.commonUIParams(self.viewData_.cardsBtn.view, {cb = handler(self, self.onClickCardsButtonHandler_)})
    display.commonUIParams(self.viewData_.teamsBtn.view, {cb = handler(self, self.onClickTeamsButtonHandler_)})
    display.commonUIParams(self.viewData_.talentBtn.view, {cb = handler(self, self.onClickTalentButtonHandler_)})
    display.commonUIParams(self.viewData_.petBtn.view, {cb = handler(self, self.onClickPetButtonHandler_)})
    display.commonUIParams(self.viewData_.unionBtn.view, {cb = handler(self, self.onClickUnionButtonHandler_)})
    display.commonUIParams(self.viewData_.rankBtn.view, {cb = handler(self, self.onClickRankButtonHandler_)})
    display.commonUIParams(self.viewData_.backpackBtn.view, {cb = handler(self, self.onClickBackpackButtonHandler_)})
    display.commonUIParams(self.viewData_.takeHouseBtn.view, {cb = handler(self, self.onClickTakeHouseButtonHandler_)})
    display.commonUIParams(self.viewData_.worldMapBtn.view, {cb = handler(self, self.onClickWorldMapButtonHandler_)})
    display.commonUIParams(self.viewData_.orderBtn.view, {cb = handler(self, self.onClickOrderButtonHandler_)})
    display.commonUIParams(self.viewData_.moduleBtn.view, {cb = handler(self, self.onClickModuleButtonHandler_)})
    display.commonUIParams(self.viewData_.allRoundBtn.view, {cb = handler(self, self.onClickAllRoundButtonHandler_)})
    display.commonUIParams(self.viewData_.levelTaskBtn.view, {cb = handler(self, self.onClickLevelTaskButtonHandler_)})
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    local sliderPos = cc.p(display.SAFE_R - 60, 80)

    -------------------------------------------------
    -- left button define
    local leftBtnList   = {}
    local leftBtnDefine = {
        {
            {title = __('召唤'), tag = RemindTag.CAPSULE, name = 'BTN_CAPSULE', scale = 0.75, spine = 'ui/home/nmain/drawcard/drawcard'},
            {title = __('飨灵'), tag = RemindTag.CARDS,   name = 'BTN_CARDS',   scale = 1.20, image = 'ui/home/nmain/main_btn_team.png'},
            {title = __('编队'), tag = RemindTag.TEAMS,   name = 'BTN_TEAMS',   scale = 1.20, image = 'ui/home/nmain/main_btn_card.png'},
            {title = __('天赋'), tag = RemindTag.TALENT,  name = 'BTN_TALENT',  scale = 1.20, image = 'ui/home/nmain/main_btn_talent.png'},
            {title = __('堕神'), tag = RemindTag.PET,     name = 'BTN_PET',     scale = 1.20, image = 'ui/home/nmain/main_btn_ice_pet.png'},
            {title = __('工会'), tag = RemindTag.UNION,   name = 'BTN_UNION',   scale = 1.20, image = 'ui/home/nmain/main_btn_guild.png'},
        },
        {
            {title = __('塔可屋'), tag = RemindTag.TAKE_HOUSE, name = 'BTN_TAKE_HOUSE', scale = 1.2, image = 'ui/home/nmain/main_btn_diamond.png'},
            {title = __('排行'),   tag = RemindTag.RANK,       name = 'BTN_RANK',       scale = 1.3, image = 'ui/home/nmain/main_btn_rank.png'},
            {title = __('仓库'),   tag = RemindTag.BACKPACK,   name = 'BTN_BACKPACK',   scale = 1.4, image = 'ui/home/nmain/main_btn_bag.png'},
        }
    }
    if isEfunSdk() then
        -- leftBtnDefine[2][#leftBtnDefine[2]] = {title = __('facebook'), tag = RemindTag.HOME_FACEBOOK, name = 'HOME_FACEBOOK', scale = 0.85, image = 'ui/home/nmain/main_btn_fb'}
    end
    for page, funcDefine in ipairs(leftBtnDefine) do
        local funcBtnList = {}
        for i, btnDefine in ipairs(funcDefine) do
            local btnViewData = CreateFrameButton(btnDefine)
            btnViewData.view:setPositionX(sliderPos.x)
            btnViewData.view:setPositionY(sliderPos.y)
            btnViewData.view:setScale(0)
            view:addChild(btnViewData.view)
            funcBtnList[i] = btnViewData
        end
        leftBtnList[page] = funcBtnList
    end

    -------------------------------------------------
    -- up button define
    local upBtnList   = {}
    local upBtnDefine = {
        {
            {title = __('地图'),     tag = RemindTag.WORLDMAP,               name = 'BTN_WORLDMAP',    scale = 1, image = 'ui/home/nmain/main_btn_main_map.png'},
            {title = __('等级奖励'), tag = RemindTag.TIME_LIMIT_UPGRADE_TASK, name = 'BTN_LEVEL_TASK', scale = 1, image = 'ui/home/nmain/main_btn_ac_reward.png', countdown = true},
            {title = __('订单'),     tag = RemindTag.ORDER,                  name = 'BTN_ORDER',       scale = 1, image = 'ui/home/nmain/main_btn_order.png'},
            {title = __('历练'),     tag = RemindTag.MODELSELECT,            name = 'BTN_MODELSELECT', scale = 1, image = 'ui/home/nmain/main_btn_modeselect.png'},
            {title = __('全能王'),   tag = RemindTag.ALL_ROUND,              name = 'BTN_ALL_ROUND',   scale = 1, image = 'ui/home/nmain/main_btn_allround.png'},
        }
    }
    for page, funcDefine in ipairs(upBtnDefine) do
        local funcBtnList = {}
        for i, btnDefine in ipairs(funcDefine) do
            local btnViewData = CreateSimpleButton(btnDefine)
            btnViewData.view:setPositionX(sliderPos.x)
            btnViewData.view:setPositionY(sliderPos.y)
            btnViewData.view:setScale(0)
            view:addChild(btnViewData.view)
            funcBtnList[i] = btnViewData
        end
        upBtnList[page] = funcBtnList
    end

    -- worldMap button
    local worldMapBtn   = upBtnList[1][1]
    local worldBtnSize  = worldMapBtn.view:getContentSize()
    worldMapBtn.bossImg = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.WORLD_BOSS_IMG), worldBtnSize.width/2, worldBtnSize.height - 20, {scale = 0.5})
    worldMapBtn.view:addChild(worldMapBtn.bossImg)
    worldMapBtn.bossImg:setVisible(false)

    -------------------------------------------------
    -- slider button
    local sliderSpine = display.newCacheSpine(SpineCacheName.GLOBAL, 'ui/home/nmain/main_ico_summary')
    sliderSpine:setPosition(sliderPos)
    sliderSpine:setAnimation(0, 'idle1', true)
    view:addChild(sliderSpine)

    local sliderBtn = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMAGE), sliderPos.x, sliderPos.y, {scale9 = true, size = cc.size(100,100), enable = true})
    view:addChild(sliderBtn)

    RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = sliderBtn, tag = RemindTag.BACKPACK_PLATE,po = cc.p(sliderBtn:getContentSize().width - 25, sliderBtn:getContentSize().height - 15)})

    return {
        view         = view,
        sliderBtn    = sliderBtn,
        sliderPos    = sliderPos,
        sliderSize   = sliderBtn:getContentSize(),
        sliderSpine  = sliderSpine,
        leftBtnList  = leftBtnList,
        capsuleBtn   = leftBtnList[1][1],
        cardsBtn     = leftBtnList[1][2],
        teamsBtn     = leftBtnList[1][3],
        talentBtn    = leftBtnList[1][4],
        petBtn       = leftBtnList[1][5],
        unionBtn     = leftBtnList[1][6],
        takeHouseBtn = leftBtnList[2][1],
        rankBtn      = leftBtnList[2][2],
        backpackBtn  = leftBtnList[2][3],
        friendsBtn   = leftBtnList[2][4],
        upBtnList    = upBtnList,
        worldMapBtn  = upBtnList[1][1],
        levelTaskBtn = upBtnList[1][2],
        orderBtn     = upBtnList[1][3],
        moduleBtn    = upBtnList[1][4],
        allRoundBtn  = upBtnList[1][5],
    }
end


CreateSimpleButton = function(buttonDefine)
    local size = cc.size(120, 98)
    local view = display.newButton(0, 0, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMAGE), scale9 = true, size = size})
    view:setTag(checkint(buttonDefine.tag))
    view:setName(buttonDefine.name)

    -- 倒计时
    local countdownBg  = nil
    local countdownBar = nil
    if buttonDefine.countdown then
        countdownBg = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.MAIN_TIME_BG_REWARD), size.width/2, 50, {ap = display.RIGHT_CENTER})
        view:addChild(countdownBg)

        countdownBar = display.newLabel(70, 22, fontWithColor(3, {text = '00:00:00'}))
        countdownBg:addChild(countdownBar)
    end

    local normalImg = nil
    if buttonDefine.image then
        local scale = checknumber(buttonDefine.scale)
        normalImg   = display.newImageView(app.plistMgr:checkSpriteFrame(buttonDefine.image), size.width/2, size.height, {scale = scale, ap = display.CENTER_TOP})
        view:addChild(normalImg)
    end

    -- 名称标签
    local nameLabel = display.newLabel(size.width/2, 24, fontWithColor(20, {text = checkstr(buttonDefine.title), fontSize = 22 ,reqW = 105}))
    view:addChild(nameLabel)

    local lockIcon = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.LOCK_ICON), size.width/2, size.height/2 + 10)
    view:addChild(lockIcon)

    -- 红点标签
    RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = view, tag = view:getTag(), po = cc.p(size.width - 25, size.height - 15)})

    return {
        view         = view,
        normalImg    = normalImg,
        lockIcon     = lockIcon,
        countdownBg  = countdownBg,
        countdownBar = countdownBar,
    }
end


CreateFrameButton = function(buttonDefine)
    local size = cc.size(130, 124)
    local view = display.newButton(0, 0, {n = app.plistMgr:checkSpriteFrame(RES_DICT.ALPHA_IMAGE), scale9 = true, size = size})
    view:setTag(checkint(buttonDefine.tag))
    view:setName(buttonDefine.name)
    -- view:addChild(display.newLayer(0,0,{size=size,color=cc.r4b(150),ap=display.LEFT_BOTTOM}))
    local path = HOME_THEME_STYLE_DEFINE.FUNC_FRAME or app.plistMgr:checkSpriteFrame(RES_DICT.BTN_FRAME)
    view:addChild(display.newImageView(path, size.width/2, size.height/2))

    local normalImg = nil
    if buttonDefine.image then
        local scale = checknumber(buttonDefine.scale)
        normalImg   = display.newImageView(app.plistMgr:checkSpriteFrame(buttonDefine.image), size.width/2, size.height+6, {scale = scale, ap = display.CENTER_TOP})
        view:addChild(normalImg)

    elseif buttonDefine.spine then
        local imgScale = checknumber(buttonDefine.scale)
        local btnSpine = display.newCacheSpine(SpineCacheName.GLOBAL, buttonDefine.spine, imgScale)
        btnSpine:setPosition(size.width/2 - 2, size.height/2 + 10)
        btnSpine:setAnimation(0, 'animation', true)
        view:addChild(btnSpine)

        local particle = cc.ParticleSystemQuad:create('ui/home/nmain/drawcard/guangdian.plist')
        particle:setPosition(size.width/2, size.height/2)
        particle:setAutoRemoveOnFinish(true)
        particle:setScale(imgScale)
        view:addChild(particle)
    end

    local nameLabel = display.newLabel(size.width/2, 16, fontWithColor(20, {text = checkstr(buttonDefine.title), fontSize = 26}))
    view:addChild(nameLabel)

    local lockIcon = display.newImageView(app.plistMgr:checkSpriteFrame(RES_DICT.LOCK_ICON), size.width/2, size.height/2 + 10)
    view:addChild(lockIcon)

    RemindIcon.addRemindIcon({imgPath = RES_DICT.REMIND_ICON_PATH, parent = view, tag = view:getTag(), po = cc.p(size.width - 25, size.height - 15)})

    return {
        view       = view,
        normalImg  = normalImg,
        lockIcon   = lockIcon,
    }
end


-------------------------------------------------
-- get / set

function HomeFuncSlider:getViewData()
    return self.viewData_
end


function HomeFuncSlider:isHomeControllable()
    local homeMediator = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
    return homeMediator and homeMediator:isControllable()
end


function HomeFuncSlider:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end


function HomeFuncSlider:getSliderPage()
    return checkint(self.sliderPage_)
end
function HomeFuncSlider:setSliderPage(page, isFast)
    local oldPageNum = self.sliderPage_
    self.sliderPage_ = checkint(page)
    self:switchSliderPage_(oldPageNum, page, isFast)
end


-------------------------------------------------
-- public method

function HomeFuncSlider:refreshModuleStatus(isNeedReload)
    local viewData = self:getViewData()

    -- check capsule unlock
    local isUnlockCapsule = true
    local isHideCapsule   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.CAPSULE)])]
    self:updateButtonStatus_(viewData.capsuleBtn, isUnlockCapsule, isHideCapsule, MODULE_SWITCH.CAPSULE)
    
    -- check cards unlock
    local isUnlockCards = true
    local isHideCards   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.CARDS)])]
    self:updateButtonStatus_(viewData.cardsBtn, isUnlockCards, isHideCards, MODULE_SWITCH.CARDS)
    
    -- check teams unlock
    local isUnlockTeams = true
    local isHideTeams   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.TEAMS)])]
    self:updateButtonStatus_(viewData.teamsBtn, isUnlockTeams, isHideTeams, MODULE_SWITCH.TEAMS)
    
    -- check talent unlock
    local isUnlockTalent = CommonUtils.UnLockModule(RemindTag.TALENT)
    local isHideTalent   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.TALENT)])]
    self:updateButtonStatus_(viewData.talentBtn, isUnlockTalent, isHideTalent, MODULE_SWITCH.TALENT_BUSSINSS)
    
    -- check pet unlock
    local isUnlockPet = CommonUtils.UnLockModule(RemindTag.PET)
    local isHidePet   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.PET)])]
    self:updateButtonStatus_(viewData.petBtn, isUnlockPet, isHidePet, MODULE_SWITCH.PET)
    
    -- check union unlock
    local isUnlockUnion = CommonUtils.UnLockModule(RemindTag.UNION)
    local isHideUnion   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.UNION)])]
    self:updateButtonStatus_(viewData.unionBtn, isUnlockUnion, isHideUnion, MODULE_SWITCH.GUILD)
    
    
    -- check takeHouse unlock
    local isUnlockTake = CommonUtils.UnLockModule(RemindTag.TAKE_HOUSE)
    local isHideTake   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.TAKE_HOUSE)])]
    self:updateButtonStatus_(viewData.takeHouseBtn, isUnlockTake, isHideTake, MODULE_SWITCH.ARTIFACT)

    -- check rank unlock
    local isUnlockRank = true
    local isHideRank   = false
    self:updateButtonStatus_(viewData.rankBtn, isUnlockRank, isHideRank, MODULE_SWITCH.RANKING)

    -- check friend unlock
    local isUnlockFriend = true
    local isHideFriend   = false
    self:updateButtonStatus_(viewData.friendsBtn, isUnlockFriend, isHideFriend, MODULE_SWITCH.FRIEND)

    -- check backpack unlock
    local isUnlockBackpack = true
    local isHideBackpack   = false
    self:updateButtonStatus_(viewData.backpackBtn, isUnlockBackpack, isHideBackpack)

    -------------------------------------------------

    -- check worldMap unlock
    local isUnlockWorldMap = CommonUtils.UnLockModule(RemindTag.WORLDMAP)
    local isHideWorldMap   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.WORLDMAP)])]
    self:updateButtonStatus_(viewData.worldMapBtn, isUnlockWorldMap, isHideWorldMap, MODULE_SWITCH.WORLD)

    -- check order unlock
    local isUnlockOrder = CommonUtils.UnLockModule(RemindTag.ORDER)
    local isHideOrder   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.ORDER)])]
    self:updateButtonStatus_(viewData.orderBtn, isUnlockOrder, isHideOrder, {MODULE_SWITCH.PUBLIC_ORDER, MODULE_SWITCH.TAKEWAY})

    -- check module unlock
    local isUnlockModule = true
    local isHideModule   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.MODELSELECT)])]
    self:updateButtonStatus_(viewData.moduleBtn, isUnlockModule, isHideModule, MODULE_SWITCH.MODELSELECT)

    -- check allRound unlock
    local isUnlockAllRound = CommonUtils.UnLockModule(RemindTag.ALL_ROUND)
    local isHideAllRound   = self.funcHideMap_[tostring(MODULE_DATA[tostring(RemindTag.ALL_ROUND)])]
    if app.gameMgr:GetUserInfo().isCardCallOpen == 0  then
        isUnlockAllRound = false
        isHideAllRound   = true
    end
    self:updateButtonStatus_(viewData.allRoundBtn , isUnlockAllRound, isHideAllRound, MODULE_SWITCH.ALL_ROUND)

    -- check level task unlock
    local isUnlockLevelTask  = true
    local isHideLevelTask    = app.gameMgr:GetUserInfo().isShowTimeLimitUpgradeTask ~= true
    self:updateButtonStatus_(viewData.levelTaskBtn, isUnlockLevelTask, isHideLevelTask)

    -- check need reload
    if isNeedReload then
        self:setSliderPage(self:getSliderPage(), true)
    end
end


function HomeFuncSlider:setWorldBossTipVisible(isVisible)
    local worldMapBtn  = self:getViewData().worldMapBtn
    local worldBossImg = worldMapBtn and worldMapBtn.bossImg or nil
    if worldBossImg then
        worldBossImg:setVisible(isVisible == true)
    end
end


function HomeFuncSlider:hideFunc(funcId)
    table.insert(self.hideFuncIdList_, funcId)
end


function HomeFuncSlider:eraseHideFuncAt(moduleId)
    self.funcHideMap_[tostring(moduleId)] = false
    self:refreshModuleStatus()
    
    if moduleId == MODULE_DATA[tostring(RemindTag.TAKE_HOUSE)] then
        self:setSliderPage(2, true)
    else
        self:setSliderPage(1, true)
    end
end


function HomeFuncSlider:getFuncViewAt(moduleId)
    local viewData  = self:getViewData()
    local remindTag = 0
    if moduleId == MODULE_DATA[tostring(RemindTag.ORDER)] then -- 由于 ORDER 和 ROBBERY 是相同模块id，所以写死返回 ORDER
        remindTag = RemindTag.ORDER
    else
        remindTag = checkint(REMIND_TAG_MAP[tostring(moduleId)])
    end
    return self:getViewData().view:getChildByTag(remindTag)
end


function HomeFuncSlider:setWorldBossTipVisible(isVisible)
    local worldMapBtn  = self:getViewData().worldMapBtn
    local worldBossImg = worldMapBtn and worldMapBtn.bossImg or nil
    if worldBossImg then
        worldBossImg:setVisible(isVisible == true)
    end
end


-------------------------------------------------
-- private method

function HomeFuncSlider:updateButtonStatus_(btnViewData, isUnlock, isHideFunc, moduleSwitch)
    if not btnViewData then return end
    if moduleSwitch then
        if 'table' == type(moduleSwitch) then
            local isAllClose = true
            for k,v in pairs(moduleSwitch) do
                if CommonUtils.GetModuleAvailable(v) then
                    isAllClose = false
                    break
                end
            end
            if isAllClose then
                btnViewData.view:setVisible(false)
                return
            end
        else
            if not CommonUtils.GetModuleAvailable(moduleSwitch) then
                btnViewData.view:setVisible(false)
                return
            end
        end
    end
    btnViewData.view:setVisible(not isHideFunc)

    local isUnlockStatus = isUnlock == true
    if btnViewData.normalImg then
        btnViewData.normalImg:setVisible(isUnlockStatus)
    end
    if btnViewData.disableImg then
        btnViewData.disableImg:setVisible(not isUnlockStatus)
    end
    if btnViewData.lockIcon then
        btnViewData.lockIcon:setVisible(not isUnlockStatus)
    end

    if btnViewData.countdownBar then
        self:updateButtonCountDown_(btnViewData)
    end
end


function HomeFuncSlider:updateButtonCountDown_(btnViewData)
    if not btnViewData then return end

    local timerName = btnViewData.view:getName()
    local timerInfo = app.timerMgr:RetriveTimer(timerName) or {}
    local nowTime   = checkint(timerInfo.countdown)
    local endTime   = checkint(timerInfo.timeNum)

    if btnViewData.countdownBar then
        if 0 >= nowTime then
            display.commonLabelParams(btnViewData.countdownBar, {text = __('已结束')})
        else
            display.commonLabelParams(btnViewData.countdownBar, {text = CommonUtils.getTimeFormatByType(nowTime, 2)})
        end
    end
end


function HomeFuncSlider:upateRemindStatus_(remindIcon)
    if remindIcon then
        remindIcon:UpdateLocalData()
    end
end


function HomeFuncSlider:switchSliderPage_(oldPage, newPage, isFast)
    self.isControllable_ = false
    local oldPageNum     = checkint(oldPage)
    local newPageNum     = checkint(newPage)
    local viewData       = self:getViewData()
    local originPos      = viewData.sliderPos
    local sliderSize     = viewData.sliderSize
    local sliderSpine    = viewData.sliderSpine
    local oldUpBtnList   = viewData.upBtnList[oldPageNum]
    local newUpBtnList   = viewData.upBtnList[newPageNum]
    local oldLeftBtnList = viewData.leftBtnList[oldPageNum]
    local newLeftBtnList = viewData.leftBtnList[newPageNum]
    local forEachIndex   = 0
    local speedRatio     = isFast == true and 0 or 1


    -- hide action
    local hideActTime  = 0.03*2 * speedRatio
    local hideInterval = 0.02*1 * speedRatio
    local hideActList  = {}
    forEachIndex = 0
    for _, btnViewData in ipairs(oldUpBtnList or {}) do
        if btnViewData.view:isVisible() then
            forEachIndex     = forEachIndex + 1
            local actionTime = hideActTime + forEachIndex * hideInterval
            table.insert(hideActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.MoveTo:create(actionTime, originPos))))
            table.insert(hideActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 0))))
        end
    end
    forEachIndex = 0
    for _, btnViewData in ipairs(oldLeftBtnList or {}) do
        if btnViewData.view:isVisible() then
            forEachIndex     = forEachIndex + 1
            local actionTime = hideActTime + forEachIndex * hideInterval
            table.insert(hideActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.MoveTo:create(actionTime, originPos))))
            table.insert(hideActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 0))))
        end
    end

    -- show action
    local showActTime  = 0.05*2 * speedRatio
    local showInterval = 0.05*1 * speedRatio
    local showActList  = {}
    forEachIndex = 0
    for _, btnViewData in ipairs(newUpBtnList or {}) do
        if btnViewData.view:isVisible() then
            forEachIndex     = forEachIndex + 1
            local actionTime = showActTime + forEachIndex * showInterval
            local btnViewPos = cc.p(originPos.x, originPos.y + sliderSize.height/2 + (forEachIndex - 0.5) * BUTTON_GAP_H)
            table.insert(showActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.MoveTo:create(actionTime, btnViewPos))))
            table.insert(showActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 1))))
        end
    end
    forEachIndex = 0
    for _, btnViewData in ipairs(newLeftBtnList or {}) do
        if btnViewData.view:isVisible() then
            forEachIndex     = forEachIndex + 1
            local actionTime = showActTime + forEachIndex * showInterval
            local btnViewPos = cc.p(originPos.x - sliderSize.width/2 - (forEachIndex - 0.5) * BUTTON_GAP_W, originPos.y)
            table.insert(showActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.MoveTo:create(actionTime, btnViewPos))))
            table.insert(showActList, cc.TargetedAction:create(btnViewData.view, cc.EaseCubicActionOut:create(cc.ScaleTo:create(actionTime, 1))))
        end
    end

    -- run action
    local actionList = {}
    local finishCB   = function()
        self.isControllable_ = true
    end
    self:stopAllActions()

    if #hideActList > 0 then table.insert(actionList, cc.Spawn:create(hideActList)) end
    if #showActList > 0 then table.insert(actionList, cc.Spawn:create(showActList)) end
    if #actionList > 0 then table.insert(actionList, cc.CallFunc:create(finishCB)) else finishCB() end
    if #actionList > 0 then self:runAction(cc.Sequence:create(actionList)) end

    -- slider spine
    if oldPageNum > 0 then
        sliderSpine:setToSetupPose()
        if newPage % 2 == 0 then
            sliderSpine:setAnimation(0, 'play1', false)
            sliderSpine:addAnimation(0, 'idle2', true)
        else
            sliderSpine:setAnimation(0, 'play2', false)
            sliderSpine:addAnimation(0, 'idle1', true)
        end
    end
end


-------------------------------------------------
-- handler

function HomeFuncSlider:onCleanup()
    AppFacade.GetInstance():UnRegistObserver(COUNT_DOWN_ACTION, self)
end


function HomeFuncSlider:onTimerCountdownHandler_(signal)
    local dataBody  = signal:GetBody()
    local timerName = tostring(dataBody.timerName)

    local levelTaskBtnViewData = self:getViewData().levelTaskBtn
    if levelTaskBtnViewData and timerName == levelTaskBtnViewData.view:getName() and levelTaskBtnViewData.view:isVisible() then
        self:updateButtonCountDown_(levelTaskBtnViewData)
    end
end


function HomeFuncSlider:onClickSliderButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end
    if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_SLIDER_SLIDER) then return end

    if self:getSliderPage() >= SLIDER_PAGES then
        self:setSliderPage(1)
    else
        self:setSliderPage(self:getSliderPage() + 1)
    end
end


function HomeFuncSlider:onClickCapsuleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end
    if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_SLIDER_CAPSULE) then return end

    -- update remind icon
    self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
    
    if GAME_MODULE_OPEN.NEW_CAPSULE then
        local allGuideConfs     = CommonUtils.GetConfigAllMess('step', 'guide') or {}
        local drawcardGuideConf = checktable(allGuideConfs[tostring(GUIDE_MODULES.MODULE_DRAWCARD)])
        local drawcardNowStepId = checkint(GuideUtils.GetModuleData(GUIDE_MODULES.MODULE_DRAWCARD))
        local drawcardEndStepId = 0
        for stepId, _ in pairs(drawcardGuideConf) do
            drawcardEndStepId = math.max(drawcardEndStepId, checkint(stepId))
        end
        
        -- check finish drawcard guide
        if drawcardNowStepId > 0 and drawcardNowStepId >= drawcardEndStepId then
            self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleNewMediator'})
        else
            self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleMediator'})
        end
    else
        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleMediator'})
    end
end


function HomeFuncSlider:onClickCardsButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end
    if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_SLIDER_CARDS) then return end

    -- update remind icon
    self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
    
    self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'CardsListMediatorNew'})
    GuideUtils.DispatchStepEvent()
end


function HomeFuncSlider:onClickTeamsButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end
    if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.HOME_FUNC_SLIDER_TEAMS) then return end
    
    -- update remind icon
    self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))

    self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'TeamFormationMediator'})
end


function HomeFuncSlider:onClickTalentButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    if CommonUtils.UnLockModule(RemindTag.TALENT, true) then
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'TalentMediator'})
    end
end


function HomeFuncSlider:onClickPetButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    if CommonUtils.UnLockModule(RemindTag.PET, true) then
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'PetDevelopMediator'})
    end
end


function HomeFuncSlider:onClickUnionButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    if CommonUtils.UnLockModule(RemindTag.UNION, true) then
        -- update remind icon
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))

        -- check first open story
        local gameManager   = AppFacade.GetInstance():GetManager('GameManager')
        local unionOpenKey  = string.fmt('IS_FIRST_OPEN_UNION_%1', gameManager:GetUserInfo().playerId)
        local isOpenedUnion = cc.UserDefault:getInstance():getBoolForKey(unionOpenKey, false)
        local openUnionFunc = function()
            if gameManager:hasUnion() then
                self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'UnionLobbyMediator'})
            else
                self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'UnionCreateHomeMediator'})
            end
        end

        if isOpenedUnion then
            openUnionFunc()
        else
            -- show first open story
            local storyPath  = string.format('conf/%s/union/story.json', i18n.getLang())
            local storyStage = require('Frame.Opera.OperaStage').new({id = 1, path = storyPath, guide = true, cb = function(sender)
                cc.UserDefault:getInstance():setBoolForKey(unionOpenKey, true)
                cc.UserDefault:getInstance():flush()
                openUnionFunc()
            end})
            storyStage:setPosition(display.center)
            sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
        end
    end
end


function HomeFuncSlider:onClickRankButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    -- update remind icon
    self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))

    local rankingListMdt = require('Game.mediator.RankingListMediator').new()
    AppFacade.GetInstance():RegistMediator(rankingListMdt)
end


function HomeFuncSlider:onClickBackpackButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
    dataMgr:ClearRedDotNofication(tostring(RemindTag.BACKPACK),RemindTag.BACKPACK, 'HomeFuncSlider:onClickBackpackButtonHandler_')
    AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.BACKPACK})
    self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'BackPackMediator'})
end


function HomeFuncSlider:onClickTakeHouseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    if CommonUtils.UnLockModule(RemindTag.TAKE_HOUSE, true) then
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
        local tablePosition  = sender:convertToWorldSpace(utils.getLocalCenter(sender))
        local jewelEntryView = require('home.JewelEntryView').new({pos = tablePosition})
        jewelEntryView:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(jewelEntryView)
    end
end


function HomeFuncSlider:onClickWorldMapButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    if CommonUtils.UnLockModule(RemindTag.WORLDMAP, true) then
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'WorldMediator'})
    end
end


function HomeFuncSlider:onClickOrderButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    if CommonUtils.UnLockModule(RemindTag.ORDER, true) then
        self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'order.OrderMediator'})
    end
end


function HomeFuncSlider:onClickModuleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    -- update remind icon
    self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))

    self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'BattleAssembleExportMediator'})
    GuideUtils.DispatchStepEvent()
end


function HomeFuncSlider:onClickAllRoundButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'allRound.AllRoundHomeMediator'})
    self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))
end


function HomeFuncSlider:onClickLevelTaskButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self:isHomeControllable() or not self.isControllable_ then return end

    -- self:upateRemindStatus_(sender:getChildByTag(checkint(sender:getTag())))

    local pos = sender:convertToWorldSpace(utils.getLocalCenter(sender))
    local TimeLimitUpgradeTaskView = require( 'home.TimeLimitUpgradeTaskView' ).new({pos = pos})
    TimeLimitUpgradeTaskView:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(TimeLimitUpgradeTaskView)
end


return HomeFuncSlider
