---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/10/15 2:07 PM
---
--[[
扭蛋系统mediator
--]]
local Mediator                      = mvc.Mediator
---@class AnniversaryMainMediator :Mediator
local AnniversaryMainMediator = class("AnniversaryMainMediator", Mediator)
local anniversaryManager = app.anniversaryMgr
local NAME                          = "AnniversaryMainMediator"
local BUTTON_TAG                    = {
    REWARD_PRE   = 10011, -- 奖励预览
    RANK_BTN     = 10012, -- 排行榜
    PLOT_BTN     = 10013, -- 剧情
    BLOCK_MARKET = 10014, --黑市商店
    MYSTERIOUS   = 10015, -- 神秘套圈
    BRANCH_LINE  = 10016, -- 支线
    MAIN_LINE    = 10017, -- 主线
    CLOSE_LAYER  = 10018, -- 关闭按钮
    TIP_BUTTON   = 10019
}
local ANNIVERSART_MODULE  ={
    RECIPE_MARKET = "1",  -- 经营
    MAIN_LINE     = "2",  -- 主线
    BRANCH_LINE   = "3",  -- 支线
    MYSTERIOUS    = "4",  -- 抽奖
}
local BLOCK_STATUSE = {
    NOT_REWARDS = 0 ,      --不可以领取
    CAN_REAWADS = 1 ,      --可以领取
}
local CHAPTER_STATUS = {
    NOT_CHOOSE = 0 , --未选择为零
    MAIN_LINE = 1 , -- 1、为主线  大于1为支线
}
local ANNIVERSAY_SPINE_TABLE   = {
    ANNI_MAIN_BOX =  app.anniversaryMgr:GetSpinePath('effects/anniversary/anni_main_box').path
}
function AnniversaryMainMediator:ctor(param, viewComponent)
    self.super:ctor(NAME, viewComponent)
    anniversaryManager:PlayAnniversaryMainBGM()
    anniversaryManager:AddSpineCache()
end

function AnniversaryMainMediator:InterestSignals()
    local signals = {
        POST.ANNIVERSARY_HOME.sglName  ,
        POST.ANNIVERSARY_DRAW_CHAPTER_REWARDS.sglName ,
        POST.ANNIVERSARY_DRAW_SHOP_REWARDS.sglName ,
        ANNIVERSARY_CLOSE_PICTH_RECIPE_View_EVENT ,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT , 
        COUNT_DOWN_ACTION,
        ANNIVERSARY_BGM_EVENT
    }
    return signals
end

function AnniversaryMainMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.ANNIVERSARY_HOME.sglName  then
        local freeTickets =  data.freeTickets
        data.freeTickets = {}
        anniversaryManager:InitData(data)
        app.gameMgr:UpdatePlayer({ voucherNum  = data.voucherNum})
        if type(freeTickets) == 'table' and table.nums(freeTickets) > 0  then
            app.uiMgr:AddDialog('common.RewardPopup',{rewards = freeTickets})
        end
        self:UpdateUI()
        app.badgeMgr:CheckAnniversaryExtraRewardTipRed()
    elseif name == COUNT_DOWN_ACTION then
        if data.timerName == "Anniversay_Left_Second" then
            local countdown = data.countdown
            local viewComponent = self:GetViewComponent()
            local viewData = viewComponent.viewData
            local view = viewData.view
            local blockMarket = view:getChildByName("blockMarket")
            local blockMarketViewData = blockMarket.viewData
            if blockMarketViewData and (not tolua.isnull(blockMarketViewData.distanceStartLanel) ) then
                display.reloadRichLabel(blockMarketViewData.distanceStartLanel ,  {
                    c = {
                        fontWithColor('10', {color = "854e28" , text = app.anniversaryMgr:GetPoText(__('距离开市:')) .. " "}) ,
                        fontWithColor('14' , {text = string.toMinutesSecondsMilliseconds(countdown)})
                    }
                })
                CommonUtils.AddRichLabelTraceEffect(blockMarketViewData.distanceStartLanel,nil, nil , {2} )
                if countdown == 0  then  --进入售卖阶段

                    self:SendSignal(POST.ANNIVERSARY_HOME.cmdName, {})
                end
            end
        end
    elseif name == POST.ANNIVERSARY_DRAW_SHOP_REWARDS.sglName then
        local recipeVoucher  = data.recipeVoucher
        local curentRecipeVoucher = CommonUtils.GetCacheProductNum(app.anniversaryMgr:GetIncomeCurrencyID())
        local rewardRecipeVoucher = checkint(recipeVoucher)  - checkint(curentRecipeVoucher)
        if rewardRecipeVoucher > 0  then
            app.uiMgr:AddDialog('common.RewardPopup' , {
                rewards = {
                    { goodsId = app.anniversaryMgr:GetIncomeCurrencyID() ,
                      num =rewardRecipeVoucher }
                }
            })
        end
        anniversaryManager.homeData.isBlackMarketHasDrawn = BLOCK_STATUSE.NOT_REWARDS
        self:UpdateBlockLayout()
    elseif name == POST.ANNIVERSARY_DRAW_CHAPTER_REWARDS.sglName then
        local chapterType =  anniversaryManager.homeData.chapterType
        local chapterId = anniversaryManager.homeData.chapters[tostring(chapterType)]
        local maxChapterSort = anniversaryManager:GetChapterSortByChapterIdChapterType(chapterId , chapterType )
        local chapterSort =  anniversaryManager.homeData.chapterSort
        local  curChapterId = anniversaryManager:GetChpterIdByChapeterTypeChapterSort(chapterType , chapterSort)
        if checkint(chapterSort)  > checkint(maxChapterSort)   then
            anniversaryManager.homeData.chapters[tostring(chapterType)] = curChapterId
        end
        anniversaryManager.homeData.chapterType = 0
        anniversaryManager.homeData.chapterSort = 0
        anniversaryManager.homeData.chapterGrids = {}
        anniversaryManager.homeData.chapterQuest = {}
        local rewards = data.rewards
        local parserConfig = anniversaryManager:GetConfigParse()
        local chapterConfig =  anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
        local chapterData = chapterConfig[tostring(curChapterId)] or {}
        local data = {num = checkint(chapterData.score) , goodsId = app.anniversaryMgr:GetAnniversaryScoreId()}
        anniversaryManager.homeData.challengePoint = checkint(anniversaryManager.homeData.challengePoint ) +  checkint(chapterData.score)
        rewards[#rewards+1] = data
        app.uiMgr:AddDialog('common.RewardPopup',{ rewards = rewards , closeCallback = function()
            if CHAPTER_STATUS.MAIN_LINE ~= checkint(chapterType) then
                anniversaryManager.homeData.branchRefresh = {}
                self:UpdateUI()
            else
                cc.UserDefault:getInstance():setBoolForKey(app.gameMgr:GetUserInfo().playerId ..  'ANNIVERSARY_MAIN_LINE_CHAPTER_' .. curChapterId  ,  true )
                self:UpdateMainQuset()

            end
        end })
    elseif name == ANNIVERSARY_CLOSE_PICTH_RECIPE_View_EVENT then
        local recipeId  =  checkint(data.recipeId)
        local priceValue  =  checkint(data.priceValue)
        if recipeId > 0  then
            anniversaryManager.homeData.recipeId  =  recipeId
            anniversaryManager.homeData.priceValue  =  priceValue
            self:UpdateBlockLayout()
        end
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:UpdateMySteriousLayout()
    elseif name == ANNIVERSARY_BGM_EVENT then
        local mediator = app:RetrieveMediator('AnniversaryCapsuleMediator')
        if mediator  then
            anniversaryManager:PlayAnniversaryCapsuleBGM()
        else
            anniversaryManager:PlayAnniversaryMainBGM()
        end
    end
end
function AnniversaryMainMediator:UpdateMainQuset()
    ---@type AnniversaryMainView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local view = viewData.view
    local  mainlineIcon = view:getChildByName('mainlineIcon')
    local homeData = anniversaryManager.homeData
    local chapters = homeData.chapters
    local chapterId = checkint(chapters[tostring(CHAPTER_STATUS.MAIN_LINE)])
    local mainWalkingSpine = mainlineIcon.viewData.mainWalkingSpine
    mainWalkingSpine:setVisible(true)
    mainWalkingSpine:setToSetupPose()
    if  chapterId <= 9  then
        mainWalkingSpine:setAnimation(0, 'anni_main_walking_' .. (chapterId + 1 )  , false)
    end
end
function AnniversaryMainMediator:MainQuestSpineEvent(event)
    self:UpdateUI()
end
function AnniversaryMainMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type AnniversaryMainView
    local viewComponent = require('Game.views.anniversary.AnniversaryMainView').new()
    self:SetViewComponent(viewComponent)
    app.uiMgr:SwitchToScene( viewComponent)

    local viewData = viewComponent.viewData
    local rewardPre = viewData.rewardPre
    rewardPre:setTag(BUTTON_TAG.REWARD_PRE)
    local rankBtn = viewData.rankBtn
    rankBtn:setTag(BUTTON_TAG.RANK_BTN)
    local plotBtn = viewData.plotBtn
    plotBtn:setTag(BUTTON_TAG.PLOT_BTN)
    local backBtn = viewData.backBtn
    backBtn:setTag(BUTTON_TAG.CLOSE_LAYER)
    local tabNameLabel = viewData.tabNameLabel
    tabNameLabel:setTag(BUTTON_TAG.TIP_BUTTON)
    local blockMarketBtn = viewComponent:CreateBlockMarketLayout()
    blockMarketBtn:setTag(BUTTON_TAG.BLOCK_MARKET)

    local branchLineBtn  = viewComponent:CreateBranchLineLayout()
    branchLineBtn:setTag(BUTTON_TAG.BRANCH_LINE)
    local mainLineBtn  = viewComponent:CreateMainLineLayout()
    local mainlineIconTouch  = mainLineBtn.viewData.mainlineIconTouch
    mainlineIconTouch:setTag(BUTTON_TAG.MAIN_LINE)
    local mySteriousBtn  = viewComponent:CreateMySteriousLayout()
    mySteriousBtn:setTag(BUTTON_TAG.MYSTERIOUS)
    display.commonUIParams(rewardPre , {cb  = handler(self, self.ButtonAction)})
    display.commonUIParams(tabNameLabel , {cb  = handler(self, self.ButtonAction)})
    display.commonUIParams(rankBtn , {cb  = handler(self, self.ButtonAction)})
    display.commonUIParams(plotBtn , {cb  = handler(self, self.ButtonAction)})
    display.commonUIParams(blockMarketBtn , {cb  = handler(self, self.ButtonAction)})
    display.commonUIParams(branchLineBtn , {cb  = handler(self, self.ButtonAction)})
    display.commonUIParams(mainlineIconTouch , {cb  = handler(self, self.ButtonAction)})
    display.commonUIParams(mySteriousBtn , {cb  = handler(self, self.ButtonAction)})
    display.commonUIParams( backBtn, {cb  = handler(self, self.ButtonAction)})
end

--==============================--
---@Description: 更新背景
---@author : xingweihao 
---@date : 2018/10/23 2:03 PM 
--==============================--
function AnniversaryMainMediator:UpdateMainViewBgImage()
    local currentTime = anniversaryManager.homeData.currentTime
    local dateTable = os.date("*t" ,currentTime )
    ---@type AnniversaryMainView
    local viewComponent =self:GetViewComponent()
    local bgImage = viewComponent.bgImage
    -- 定义为白天
    local bgPath = app.anniversaryMgr:GetResPath('ui/anniversary/main/anni_main_bg_night.jpg')
    local changeSkinTable = app.anniversaryMgr.changeSkinTable
    local dayAndNight = true
    if changeSkinTable then
        dayAndNight = changeSkinTable.dayAndNight
    end
    if dayAndNight then
        if checkint(dateTable.hour) > 6 and checkint(dateTable.hour) < 18  then
            bgPath = app.anniversaryMgr:GetResPath('ui/anniversary/main/anni_main_bg_day.jpg')
        end
    else
        bgPath = app.anniversaryMgr:GetResPath('ui/anniversary/main/anni_main_bg_day.jpg')
    end

    bgImage:setTexture(bgPath)
end
--==============================--
---@Description: 获取服务器上的当前时间
---@author : xingweihao
---@date : 2018/12/15 1:34 AM
--==============================--

function AnniversaryMainMediator:GetTimeSeverTime(timeStr)
   return  anniversaryManager:GetTimeSeverTime(timeStr)
end
function AnniversaryMainMediator:UpdateBlockLayout()
    ---@type AnniversaryMainView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local view = viewData.view
    local blockMarket = view:getChildByName("blockMarket")
    blockMarket:setVisible(true)
    local blockMarketViewData = blockMarket.viewData
    local currentTime = checkint(anniversaryManager.homeData.currentTime)
    local parserConfig = anniversaryManager:GetConfigParse()
    local paramConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.PARAMETER)["1"]
    local isBlackMarketHasDrawn = checkint(anniversaryManager.homeData.isBlackMarketHasDrawn)
    local readySpine  =  blockMarket:getChildByName("readySpine")
    if  not readySpine then
        readySpine = SpineCache(SpineCacheName.ANNIVERSARY):createWithName(anniversaryManager.spineTable.ANNI_MAIN_BOX)
        readySpine:setPosition( 50, 43)
        readySpine:setName("readySpine")
        blockMarket:addChild(readySpine)
        readySpine:setAnimation(0,"anni_main_stall_preparing" , true )
    end
    -- 是否功能已经关闭
    if not self:CheckModuleIsClose(ANNIVERSART_MODULE.RECIPE_MARKET) then
        readySpine:setVisible(false)
        blockMarketViewData.statusBtn:setVisible(false)
        blockMarketViewData.distanceStartLanel:setVisible(false)
        return
    end
    if  isBlackMarketHasDrawn == BLOCK_STATUSE.NOT_REWARDS  then
        local prepareStartTime = self:GetTimeSeverTime(paramConfig.prepareStart)
        local prepareEnableTime = self:GetTimeSeverTime(paramConfig.prepareEnd)
        local managementStarteTime = self:GetTimeSeverTime(paramConfig.managementStart)
        local managementEndTime = self:GetTimeSeverTime(paramConfig.managementEnd)

        local currentRecipeId = checkint(anniversaryManager.homeData.recipeId)
        if currentRecipeId > 0  then
            readySpine:setVisible(true)
        else
            readySpine:setVisible(false)
        end
        -- 在准备阶段
        if currentTime >= prepareStartTime    and  currentTime < prepareEnableTime   then
            readySpine:setToSetupPose()
            readySpine:setAnimation(0,"anni_main_stall_preparing" , true )
            blockMarketViewData.statusBtn:setVisible(true)
            display.commonLabelParams(blockMarketViewData.statusBtn , {text = ""})
            blockMarketViewData.distanceStartLanel:setVisible(true)
            local leftSeconds = prepareEnableTime - currentTime
            app.timerMgr:AddTimer({ name = "Anniversay_Left_Second" , countdown = leftSeconds })
        elseif currentTime >=   managementStarteTime  and  currentTime < managementEndTime  then  -- 在售卖阶段
            readySpine:setToSetupPose()
            readySpine:setAnimation(0,"anni_main_stall_selling" , true )
            blockMarketViewData.statusBtn:setVisible(false)
            blockMarketViewData.distanceStartLanel:setVisible(false)
        end
    elseif isBlackMarketHasDrawn == BLOCK_STATUSE.CAN_REAWADS then
        readySpine:setToSetupPose()
        readySpine:setAnimation(0,"anni_main_box_get" , true )
        blockMarketViewData.statusBtn:setVisible(true)
        display.commonLabelParams(blockMarketViewData.statusBtn , {text = app.anniversaryMgr:GetPoText(__('领取收益')) })
        blockMarketViewData.distanceStartLanel:setVisible(false)
    end
end
function AnniversaryMainMediator:UpdateUI()
    self:UpdateBlockLayout()
    self:UpdateBranchLayout()
    self:UpdateMainLineLayout()
    self:UpdateMainViewBgImage()
    self:UpdateMySteriousLayout()
end
--==============================--
---@Description:  更新神秘套圈
---@author : xingweihao
---@date : 2018/10/22 4:22 PM
--==============================--

function AnniversaryMainMediator:UpdateMySteriousLayout()
    ---@type AnniversaryMainView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local view = viewData.view
    local mysteriousRing = view:getChildByName("mysteriousRing")
    mysteriousRing:setVisible(true)
    local mysteriousRingViewData = mysteriousRing.viewData
    local goldRichLabl = mysteriousRingViewData.goldRichLabl
    display.reloadRichLabel(goldRichLabl , {
        c = {
            fontWithColor(14, {text = CommonUtils.GetCacheProductNum(app.anniversaryMgr:GetRingGameID())}) ,
            {img = CommonUtils.GetGoodsIconPathById(app.anniversaryMgr:GetRingGameID()) , scale = 0.2  }
        } })
end
--==============================--
---@Description: 更新主线数据
---@author : xingweihao
---@date : 2018/10/23 10:39 AM
--==============================--

function AnniversaryMainMediator:UpdateMainLineLayout()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local view = viewData.view
    local mainlineIcon = view:getChildByName("mainlineIcon")

    local mainlineIconViewData = mainlineIcon.viewData
    local homeData = anniversaryManager.homeData
    local chapterType = checkint(homeData.chapterType)
    local chapters = homeData.chapters or {}
    local chapterId =  chapters[tostring(CHAPTER_STATUS.MAIN_LINE)]
    -- 表示暂未选择关卡 那么就是从第一关开始
    if  checkint(chapterId) == 0  then
        chapterId = 1
    else
        chapterId = chapterId + 1
    end
    local  days =   anniversaryManager.homeData.day
    local chapterSort = anniversaryManager:GetChapterSortByChapterIdChapterType(chapterId , CHAPTER_STATUS.MAIN_LINE )
    chapterId = chapterSort ~= 0 and chapterId  or   chapters[tostring(CHAPTER_STATUS.MAIN_LINE)]
    local parserConfig =  anniversaryManager:GetConfigParse()
    local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
    local chapterData = chapterConfig[tostring(chapterId)] or {}
    -- 节点的名字
    local name = chapterData.name or ""
    display.commonLabelParams(mainlineIconViewData.titleBtn , {text =  name})
    mainlineIconViewData.headIcon:setTexture(AssetsUtils.GetCardHeadPath(chapterData.icon))
    mainlineIconViewData.mainWalkingSpine:registerSpineEventHandler(handler(self, self.MainQuestSpineEvent), sp.EventType.ANIMATION_COMPLETE)
    local locationGrid  = checkint(homeData.chapterQuest.locationGrid)
    local gridStatus = checkint(homeData.chapterQuest.gridStatus)
    local mode =  locationGrid %24
    -- 便是已通关
    local statusBtn = mainlineIconViewData.statuBtn
    statusBtn:setVisible(true)
    local curPos = anniversaryManager:ConverUIPosToGamePos(chapterData.location)
    mainlineIcon:setPosition(curPos)
    mainlineIconViewData.mainTaskMaskImage:setVisible(false)
    mainlineIconViewData.unlockInfoBtn:setVisible(false)
    if chapterType == CHAPTER_STATUS.MAIN_LINE then
        -- 当前关卡是在领取奖励状态
        if mode == 0 and days >= chapterSort and gridStatus ==  1   then
            display.commonLabelParams(statusBtn , {text = app.anniversaryMgr:GetPoText(__('点击领取奖励'))})
            mainlineIcon:setVisible(true)
        else
            -- 正在进行中
            display.commonLabelParams(statusBtn , {text = app.anniversaryMgr:GetPoText(__('进行中'))})
            mainlineIcon:setVisible(true)
            mainlineIcon:setVisible(true)
        end
    elseif chapterType == CHAPTER_STATUS.NOT_CHOOSE  or chapterType > CHAPTER_STATUS.MAIN_LINE  then
        if chapterSort == 0  then
            display.commonLabelParams(mainlineIconViewData.titleBtn , {text = app.anniversaryMgr:GetPoText(__('已通关'))}  )
            statusBtn:setVisible(false)
            mainlineIcon:setVisible(true)
            local completeImage = display.newImageView(app.anniversaryMgr:GetResPath('ui/common/raid_room_ico_ready.png') , 80,80 )
            mainlineIconViewData.headIcon:addChild(completeImage)
            completeImage:setScale(1.5)
        else
            -- 当前不可以进行的章节
            if chapterType == CHAPTER_STATUS.NOT_CHOOSE then
                local preChapterId =  chapters[tostring(CHAPTER_STATUS.MAIN_LINE)]
                if preChapterId then
                    local isMapComplete = cc.UserDefault:getInstance():getBoolForKey( app.gameMgr:GetUserInfo().playerId ..  'ANNIVERSARY_MAIN_LINE_CHAPTER_' .. preChapterId  ,                   false  )
                    if not isMapComplete then
                        cc.UserDefault:getInstance():setBoolForKey(app.gameMgr:GetUserInfo().playerId ..  'ANNIVERSARY_MAIN_LINE_CHAPTER_' .. preChapterId  ,  true )
                        self:MainLineAcition()
                    else
                        local days = checkint(anniversaryManager.homeData.day)
                        if days < chapterId then
                            mainlineIconViewData.mainTaskMaskImage:setVisible(true)
                            mainlineIconViewData.unlockInfoBtn:setVisible(true)
                            local currentTime =  anniversaryManager.homeData.currentTime
                            local endTime = anniversaryManager:GetTimeSeverTime('24:00')
                            display.commonLabelParams(mainlineIconViewData.unlockInfoBtn , { text = string.format(app.anniversaryMgr:GetPoText(__('%d小时后解锁')), math.ceil((endTime - currentTime)/3600)  )})
                        end
                        mainlineIcon:setVisible(true)
                        mainlineIcon:setOpacity(255)
                    end
                else
                    mainlineIcon:setVisible(true)
                end
            else
                if days < chapterId then
                    mainlineIconViewData.mainTaskMaskImage:setVisible(true)
                    mainlineIconViewData.unlockInfoBtn:setVisible(true)
                    local currentTime =  anniversaryManager.homeData.currentTime
                    local endTime = anniversaryManager:GetTimeSeverTime('24:00')
                    display.commonLabelParams(mainlineIconViewData.unlockInfoBtn , { text = string.format(app.anniversaryMgr:GetPoText(__('%d小时后解锁')), math.ceil((endTime - currentTime)/3600)  )})
                end
                mainlineIcon:setVisible(true)
            end
            statusBtn:setVisible(false)
        end
    end
end
function AnniversaryMainMediator:MainLineAcition()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local view = viewData.view
    local mainlineIcon = view:getChildByName("mainlineIcon")
    mainlineIcon:setVisible(true)
    mainlineIcon:setOpacity(255)
    local mainlineIconViewData = mainlineIcon.viewData
    local homeData = anniversaryManager.homeData
    local chapters = homeData.chapters or {}
    local chapterId =  chapters[tostring(CHAPTER_STATUS.MAIN_LINE)]
    local parserConfig =  anniversaryManager:GetConfigParse()
    local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
    local chapterData = chapterConfig[tostring(chapterId)] or {}
    local curPos = anniversaryManager:ConverUIPosToGamePos(chapterData.location)
    mainlineIcon:setPosition(curPos)
    local name = chapterData.name or ""
    display.commonLabelParams(mainlineIconViewData.titleBtn , {text =  name})
    mainlineIconViewData.headIcon:setTexture(AssetsUtils.GetCardHeadPath(chapterData.icon))
    mainlineIconViewData.mainWalkingSpine:registerSpineEventHandler(handler(self, self.MainQuestSpineEvent), sp.EventType.ANIMATION_COMPLETE)
    local statusBtn = mainlineIconViewData.statuBtn
    statusBtn:setVisible(false)
    mainlineIcon:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.5),
            cc.CallFunc:create(function()
                self:UpdateMainQuset()
            end )
        )
    )
end
--==============================--
---@Description: 更新支线数据
---@author : xingweihao
---@date : 2018/10/23 10:39 AM
--==============================--
function AnniversaryMainMediator:UpdateBranchLayout()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local view = viewData.view
    local branchLine = view:getChildByName("branchLine")
    branchLine:setVisible(true)
    local branchLineViewData = branchLine.viewData
    -- 支线区域的label
    local areaLabel = branchLineViewData.areaLabel
    local branchLine = branchLineViewData.branchLine
    local lineImage = branchLineViewData.lineImage
    areaLabel:setVisible(true)
    branchLine:setVisible(true)
    lineImage:setVisible(true)

    local  parserConfig = anniversaryManager:GetConfigParse()
    local chapSortConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER_SORT)
    local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
    local homeData = anniversaryManager.homeData
    local chapterType = checkint(homeData.chapterType)
    branchLineViewData.branchLine:setVisible(true)
    local titleBtnnSize = branchLineViewData.titleBtn:getContentSize()
    if chapterType >  CHAPTER_STATUS.MAIN_LINE then
        local chapterSort = homeData.chapterSort
        local chapterQuest = homeData.chapterQuest
        local locationGrid = checkint(chapterQuest.locationGrid)
        local gridStatus = checkint(chapterQuest.gridStatus)
        local chapterSortData = chapSortConfig[tostring(chapterType)] or {}
        local chapterId = chapterSortData[ tostring(chapterSort)]
        local chapterData = chapterConfig[tostring(chapterId)] or {}
        local name = chapterData.name or ""
        if locationGrid %24 == 0 and locationGrid  > 0 and gridStatus == 1 then
            display.commonLabelParams(branchLineViewData.statuBtn ,{text = app.anniversaryMgr:GetPoText(__('点击领取奖励'))})
        else
            display.commonLabelParams(branchLineViewData.statuBtn ,{text = app.anniversaryMgr:GetPoText(__('进行中'))})
        end
        display.commonLabelParams(branchLineViewData.areaLabel ,{text = name })
        branchLineViewData.titleBtn:getLabel():setPosition(titleBtnnSize.width/2 , titleBtnnSize.height/2 - 5 )
    else
        lineImage:setVisible(false)
        display.commonLabelParams(branchLineViewData.areaLabel ,{text = "" })
        display.commonLabelParams(branchLineViewData.statuBtn ,{text = "" })
        branchLineViewData.titleBtn:getLabel():setPosition(titleBtnnSize.width/2 , titleBtnnSize.height/2 + 4 )
        branchLineViewData.statuBtn:setVisible(false)
    end
end

--==============================--
---@Description: 判断当前关卡的状态
---@param chapterType number @ 1、  为主线关卡 非1为支线关卡
---@author : xingweihao
---@date : 2018/10/23 11:24
--==============================--
function AnniversaryMainMediator:JuageCurentStatusByType(chapterType)
    local homeData = anniversaryManager.homeData
    local curChapterType = checkint(homeData.chapterType)
    local chapterQuest = homeData.chapterQuest
    local chapterSort = homeData.chapterSort
    local locationGrid = checkint(chapterQuest.locationGrid)
    local gridStatus = checkint(chapterQuest.gridStatus)
    local parserConfig =  anniversaryManager:GetConfigParse()
    local chapterSortConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER_SORT)
    if (curChapterType == CHAPTER_STATUS.MAIN_LINE and chapterType == curChapterType)  or
    (curChapterType > CHAPTER_STATUS.MAIN_LINE  and  chapterType > CHAPTER_STATUS.MAIN_LINE) then -- 1. 为主线关卡
        local chapterId = chapterSortConfig[tostring(curChapterType)][tostring(chapterSort)]
        if locationGrid %24 == 0 and  locationGrid  > 0  and gridStatus == 1 then
            -- 直接领取奖励
            self:SendSignal(POST.ANNIVERSARY_DRAW_CHAPTER_REWARDS.cmdName , {chapterId = chapterId  , chapterType = curChapterType } )
        else
            ---@type Router
            local Router  =   app:RetrieveMediator("Router")
            Router:Dispatch({ name = "anniversary.AnniversaryTeamMediator" } ,
                            {name =  "anniversary.AnniversaryMainLineMapMediator" , params = { chapterId = chapterId  , chapterType = curChapterType , chapterSort = chapterSort  }  })
        end
    elseif  curChapterType == CHAPTER_STATUS.NOT_CHOOSE  then
        if chapterType > CHAPTER_STATUS.MAIN_LINE  then
            --  进入到支线选选关界面
            local notChoose = anniversaryManager:GetNotChooseBranchTable()
            local maxNum = anniversaryManager:GetMaxBranchTypeKinds()
            local notChooseNum = table.nums(notChoose)
            if notChooseNum   == maxNum  then
                local chooseBranchTypeView = require('Game.views.anniversary.AnniversaryChooseBranchTypeView').new({ openType = 1})
                app.uiMgr:GetCurrentScene():AddDialog(chooseBranchTypeView)
                chooseBranchTypeView:setPosition(display.center)
            elseif maxNum > notChooseNum and notChooseNum  >= 0 then
                local branchRefresh = anniversaryManager.homeData.branchRefresh  or {}
                curChapterType = checkint(branchRefresh.type)
                local chapterId , chapterSort = anniversaryManager:GetNewChapterIdAndChapterSortByType(curChapterType)
                local mediator = require("Game.mediator.anniversary.AnniversaryTeamMediator").new(
                        {chapterId = chapterId , chapterSort = chapterSort , chapterType =curChapterType}
                )
                app:RegistMediator(mediator)
            end
        else
            local chapterId  = checkint(homeData.chapters[tostring(CHAPTER_STATUS.MAIN_LINE)]) + 1
            local chapterSort =  anniversaryManager:GetChapterSortByChapterIdChapterType(chapterId ,CHAPTER_STATUS.MAIN_LINE )
            if chapterSort == 0 and checkint(chapterId) > 0  then
                -- 已经通关
                app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('主线关卡已经通关')))
            else
                local days = anniversaryManager.homeData.day
                 --未通关 进入到主线关卡
                if days >=  chapterSort then
                    local mediator = require("Game.mediator.anniversary.AnniversaryTeamMediator").new(
                            {chapterId = chapterId , chapterSort = chapterSort , chapterType = CHAPTER_STATUS.MAIN_LINE}
                    )
                    app:RegistMediator(mediator)
                else
                    app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('关卡暂未解锁')))
                end
            end
            --  进入到主线关卡界面
        end
    else
        if curChapterType == CHAPTER_STATUS.MAIN_LINE then
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('主线关卡正在进行中')))
        else
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('关卡进行中')))
        end
    end
end
function AnniversaryMainMediator:ButtonAction(sender)


    local tag = sender:getTag()
    if tag ~= BUTTON_TAG.CLOSE_LAYER then
        PlayAudioByClickNormal()
    else
        PlayAudioByClickClose()
    end
    if tag == BUTTON_TAG.CLOSE_LAYER then
        PlayBGMusic()
        app:BackHomeMediator()
        anniversaryManager:RemoveSpineCache()
    elseif tag == BUTTON_TAG.MYSTERIOUS then  -- 神秘套圈
        if self:CheckModuleIsClose(ANNIVERSART_MODULE.MYSTERIOUS) then
            local mediator = require( 'Game.mediator.anniversary.AnniversaryCapsuleMediator').new()
            app:RegistMediator(mediator)
        else
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('神秘套圈时间已经结束')))
        end
    elseif tag == BUTTON_TAG.MAIN_LINE then  -- 主线关卡
        local homeData =   anniversaryManager.homeData
        local locationGrid  = checkint(homeData.chapterQuest.locationGrid)
        local chapterType  = checkint(homeData.chapterQuest.chapterType)
        local gridStatus = checkint(homeData.chapterQuest.gridStatus)
        if locationGrid %24 == 0 and  locationGrid  > 0  and gridStatus == 1  and chapterType == CHAPTER_STATUS.MAIN_LINE then
            self:JuageCurentStatusByType(CHAPTER_STATUS.MAIN_LINE )
        else
            if self:CheckModuleIsClose(ANNIVERSART_MODULE.MAIN_LINE) then
                self:JuageCurentStatusByType(CHAPTER_STATUS.MAIN_LINE )
            else
                app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('主线关卡已经结束')))
            end
        end
    elseif tag == BUTTON_TAG.PLOT_BTN then   -- 剧情回顾
        local mediator = require( 'Game.mediator.anniversary.AnniversaryStoryMeditaor').new()
		app:RegistMediator(mediator)
    elseif tag == BUTTON_TAG.BRANCH_LINE then -- 支线
        local homeData =   anniversaryManager.homeData
        local locationGrid  = checkint(homeData.chapterQuest.locationGrid)
        local chapterType  = checkint(homeData.chapterQuest.chapterType)
        local gridStatus = checkint(homeData.chapterQuest.gridStatus)
        if locationGrid %24 == 0 and  locationGrid  > 0  and gridStatus == 1  and chapterType > CHAPTER_STATUS.MAIN_LINE then
            self:JuageCurentStatusByType(2)
        else
            if self:CheckModuleIsClose(ANNIVERSART_MODULE.BRANCH_LINE) then
                self:JuageCurentStatusByType(2)
            else
                app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('支线关卡已经结束')))
            end
        end
    elseif tag == BUTTON_TAG.REWARD_PRE then  -- 奖励预览
        local mediator = require( 'Game.mediator.anniversary.AnniversaryRewardPreviewMeditaor').new()
		app:RegistMediator(mediator)
    elseif tag == BUTTON_TAG.BLOCK_MARKET then -- 黑市商店
        local isBlackMarketHasDrawn = checkint(anniversaryManager.homeData.isBlackMarketHasDrawn)
        if isBlackMarketHasDrawn == BLOCK_STATUSE.CAN_REAWADS  then
            self:SendSignal(POST.ANNIVERSARY_DRAW_SHOP_REWARDS.cmdName, {})
        else
            if self:CheckModuleIsClose(ANNIVERSART_MODULE.RECIPE_MARKET) then
                local mediator =require('Game.mediator.anniversary.AnniversaryPitchRecipeMediator').new()
                app:RegistMediator(mediator)
            else
                app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('经营时间已经结束')))
            end
        end
    elseif tag == BUTTON_TAG.RANK_BTN then  -- 排行榜
        local mediator = require("Game.mediator.anniversary.AnniversayRankMediator").new({selectedRankType = -5 })
        app:RegistMediator(mediator)
    elseif  tag == BUTTON_TAG.TIP_BUTTON then
        app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.ANNIVERSARY})
    end
end
function AnniversaryMainMediator:CheckModuleIsClose(id )
    local days                  = anniversaryManager.homeData.day
    local parserConfig          = anniversaryManager:GetConfigParse()
    local scheduleOpenConfig    = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.SCHEDULE_OPEN)
    local scheduleOpenOneConfig = scheduleOpenConfig[tostring(id)]
    local isOpen = false
    if scheduleOpenOneConfig then
        if days >= checkint(scheduleOpenOneConfig.startDay) and days <= checkint(scheduleOpenOneConfig.endDay) then
            isOpen = true
        end
    end
    return isOpen

end
function AnniversaryMainMediator:OnRegist()
    regPost(POST.ANNIVERSARY_HOME)
    regPost(POST.ANNIVERSARY_DRAW_CHAPTER_REWARDS)
    regPost(POST.ANNIVERSARY_DRAW_SHOP_REWARDS)
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    self:SendSignal(POST.ANNIVERSARY_HOME.cmdName , {})
    local shareSpineCache = SpineCache(SpineCacheName.ANNIVERSARY)
    for spineName , spinePath in pairs(ANNIVERSAY_SPINE_TABLE) do
        if not shareSpineCache:hasSpineCacheData(spinePath) then
            shareSpineCache:addCacheData(spinePath, spinePath, 1)
        end
    end
end

function AnniversaryMainMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY_HOME)
    unregPost(POST.ANNIVERSARY_DRAW_CHAPTER_REWARDS)
    unregPost(POST.ANNIVERSARY_DRAW_SHOP_REWARDS)
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    app.timerMgr:RemoveTimer("Anniversay_Left_Second")
end

return AnniversaryMainMediator
