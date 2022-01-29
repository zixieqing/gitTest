---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/10/15 2:07 PM
---
--[[
扭蛋系统mediator
--]]
local Mediator                      = mvc.Mediator
---@class AnniversaryTeamMediator :Mediator
local AnniversaryTeamMediator = class("AnniversaryTeamMediator", Mediator)
local NAME                          = "AnniversaryTeamMediator"
local anniversaryManager = app.anniversaryMgr
local BUTTON_TAG                    = {
    LEFT_BTN       = 10011, -- 向左
    RIGHT_BTN      = 10012, -- 向右
    CLOSE_LAYER    = 10018, -- 关闭按钮
    REFRESH_BRANCH = 10019, --刷新支线数据
    TIP_BUTTON     = 10020, --刷新支线数据
    SWEEP_BUTTON   = 10021, --扫荡按钮
}
local QUEST_TYPE = {
    MAIN_QUEST_TYPE = 1 ,
}
--[[
param = {
    chapterType = 1 ,  -- 1. 主线战斗 、 2、3、4、5、6  支线战斗
    chapterId = 1001  , 章节id
    chapterSort = 1001  , 章节id
}
--]]
function AnniversaryTeamMediator:ctor(param, viewComponent)
    self.super:ctor(NAME, viewComponent)
    param = param or {}
    self.chapterType = param.chapterType or 1
    self.chapterId = param.chapterId or 1
    self.chapterSort = param.chapterSort
end

function AnniversaryTeamMediator:InterestSignals()
    local signals = {
        ANNIVERSARY_CHANGE_BRANCH_CHAPTERID_EVENT,
        POST.ANNIVERSARY_SET_CONFIG.sglName ,
        POST.ANNIVERSARY_REFRESH_BRANCH_TYPE.sglName , 
        POST.ANNIVERSARY_SET_MAIN_CHAPTER.sglName ,
        POST.ANNIVERSARY_SET_BRANCH_CHAPTER.sglName ,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI
    }

    return signals
end

function AnniversaryTeamMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == ANNIVERSARY_CHANGE_BRANCH_CHAPTERID_EVENT  then
        self.chapterType = data.questType
        self.chapterId =  data.chapterId
        local viewComponent = self:GetViewComponent()
        local viewData = viewComponent.viewData
        local view = viewData.view
        local branchPanel = view:getChildByName("branchPanel")
        local branchViewData = branchPanel.viewData
        local  leftBtn                 = branchViewData.leftBtn
        leftBtn:setTag(BUTTON_TAG.LEFT_BTN)
        local  rightBtn                =  branchViewData.rightBtn
        rightBtn:setTag(BUTTON_TAG.RIGHT_BTN)
        display.commonUIParams(leftBtn ,{cb = handler(self,self.ButtonAction)})
        display.commonUIParams(rightBtn ,{cb = handler(self,self.ButtonAction)})
        self:UpdateUI()
    elseif name == POST.ANNIVERSARY_SET_CONFIG.sglName then
        anniversaryManager:SetQusetTeamAndSkill(data.requestData)
        local parserConfig =  anniversaryManager:GetConfigParse()
        local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)[tostring(self.chapterId)]
        local consume = chapterConfig.consume  or {}
        for index , goodData in pairs(consume) do
            local goodsId = goodData.goodsId
            local ownerNum = CommonUtils.GetCacheProductNum(goodsId)
            local num = checkint(goodData.num)
            if ownerNum < num  then
                if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
                    app.uiMgr:showDiamonTips()
                else
                    app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('道具不足')))
                end
                return
            end
        end
        if self.chapterType == QUEST_TYPE.MAIN_QUEST_TYPE then
            self:SendSignal(POST.ANNIVERSARY_SET_MAIN_CHAPTER.cmdName , {chapterId = self.chapterId , chapterSort = self.chapterSort, chapterType = self.chapterType})
        else
            self:SendSignal(POST.ANNIVERSARY_SET_BRANCH_CHAPTER.cmdName , {chapterId = self.chapterId , sortId = self.chapterSort, chapterType = self.chapterType})
        end
    elseif name == POST.ANNIVERSARY_SET_MAIN_CHAPTER.sglName then
        local parserConfig =  anniversaryManager:GetConfigParse()
        local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)[tostring(self.chapterId)]
        local consume = clone(chapterConfig.consume)   or {}
        for index , goodData in pairs(consume) do
            goodData.num = - goodData.num
        end
        CommonUtils.DrawRewards(consume)

        local requestData = data.requestData
        local chapterSort = requestData.chapterSort
        local chapterType = requestData.chapterType
        local homeData = app.anniversaryMgr.homeData
        local chapter = data.chapter
        homeData.chapterGrids = chapter
        homeData.chapterSort = chapterSort
        homeData.chapterType = chapterType
        homeData.chapterQuest = {locationGrid = 1 , gridStatus = 0  }
        local storyId =checkint(chapterConfig.startStoryId)
        local callback = function()
            ---@type Router
            local Router  =   app:RetrieveMediator("Router")
            Router:Dispatch({ name = "anniversary.AnniversaryTeamMediator" } ,
                            {name =  "anniversary.AnniversaryMainLineMapMediator" , params = { chapterType = self.chapterType ,chapterSort = self.chapterSort , chapterId = self.chapterId }  })
        end
        if storyId > 0 and ( (not  homeData.story) or   (not  homeData.story[tostring(storyId)]))  then
            anniversaryManager:ShowOperaStage(storyId ,callback )
        else
            callback()
        end
    elseif name == POST.ANNIVERSARY_SET_BRANCH_CHAPTER.sglName  then
        local parserConfig =  anniversaryManager:GetConfigParse()
        local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)[tostring(self.chapterId)]
        local consume = clone(chapterConfig.consume)   or {}
        for index , goodData in pairs(consume) do
            goodData.num = - goodData.num
        end
        CommonUtils.DrawRewards(consume)

        local requestData = data.requestData
        local chapterType = requestData.chapterType
        local chapterSort = requestData.sortId
        local homeData = app.anniversaryMgr.homeData
        local chapter = data.chapter
        homeData.chapterGrids = chapter
        homeData.chapterSort = chapterSort
        homeData.chapterType = chapterType
        homeData.chapterQuest = {locationGrid = 1, gridStatus = 0  }
        ---@type Router
        local Router  =   app:RetrieveMediator("Router")
        Router:Dispatch({ name = "anniversary.AnniversaryTeamMediator" } ,
                        {name =  "anniversary.AnniversaryMainLineMapMediator" , params = { chapterType = self.chapterType ,chapterSort = self.chapterSort , chapterId = self.chapterId }  })
    elseif name ==  SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        if self.viewComponent then
            self.viewComponent:UpdateCountUI()
        end
    elseif name == POST.ANNIVERSARY_REFRESH_BRANCH_TYPE.sglName   then
        local notChoose = anniversaryManager:GetNotChooseBranchTable()
        local maxNum = anniversaryManager:GetMaxBranchTypeKinds()
        local index = maxNum - table.nums(notChoose)
        local parserConfig = anniversaryManager:GetConfigParse()
        local refreshConsumeConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.REFRESH_CONSUME)
        local refreshConsumeData   = clone(refreshConsumeConfig[tostring(index)].consume)
        for i, v in ipairs(refreshConsumeData) do
            v.num =  -v.num
        end
        CommonUtils.DrawRewards(refreshConsumeData)
        local callfunc = function()
            local chapterType = data.questType
            local chapterId , chapterSort = anniversaryManager:GetNewChapterIdAndChapterSortByType(chapterType)
            self.chapterType = chapterType
            self.chapterSort = chapterSort
            self.chapterId = chapterId
            self:UpdateUI()
        end
        local viewComponent =  self:GetViewComponent()
        if viewComponent and (not tolua.isnull(viewComponent)) then
            viewComponent:runAction(cc.Sequence:create(
                    cc.DelayTime:create(1.2),
                    cc.CallFunc:create(
                        function()
                            callfunc()
                        end
                    )
            ))
        end
    end
end
function AnniversaryTeamMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type AnniversaryTeamView
    local viewComponent = require('Game.views.anniversary.AnniversaryTeamView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    local backBtn = viewData.backBtn
    backBtn:setTag(BUTTON_TAG.CLOSE_LAYER)
    display.commonUIParams( backBtn, {cb  = handler(self, self.ButtonAction)})
    if self.chapterType == QUEST_TYPE.MAIN_QUEST_TYPE  then
        viewComponent:CreateMainQuestLayout()
    else
        viewComponent:CreateBranchLayout()
        local view = viewData.view
        local branchPanel = view:getChildByName("branchPanel")
        local branchViewData = branchPanel.viewData
        local  leftBtn                 = branchViewData.leftBtn
        leftBtn:setTag(BUTTON_TAG.LEFT_BTN)
        local  rightBtn                =  branchViewData.rightBtn
        rightBtn:setTag(BUTTON_TAG.RIGHT_BTN)
        local  sweepBtn                =  viewData.sweepBtn
        sweepBtn:setTag(BUTTON_TAG.SWEEP_BUTTON)
        local  branchrefreshLayout                =  branchViewData.branchrefreshLayout
        branchrefreshLayout:setTag(BUTTON_TAG.REFRESH_BRANCH)
        display.commonUIParams(leftBtn ,{cb = handler(self,self.ButtonAction)})
        display.commonUIParams(rightBtn ,{cb = handler(self,self.ButtonAction)})
        display.commonUIParams(sweepBtn ,{cb = handler(self,self.ButtonAction)})
        display.commonUIParams(branchrefreshLayout ,{cb = handler(self,self.ButtonAction)})
        self:UpdateLeftAndRightButton(self.chapterId)
    end
    local sendData = self:ProcessingSendData()
    local battleScriptTeamMediator = require("Game.mediator.BattleScriptTeamMediator")
    local parserConfig = anniversaryManager:GetConfigParse()
    local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
    local chapterOneConfig = chapterConfig[tostring(self.chapterId or 1)]
    sendData.goodsData = chapterOneConfig.consume
    sendData.pattern =  6
    sendData.battleFontSize = 46
    sendData.battleText = app.anniversaryMgr:GetPoText(__('游玩'))
    sendData.battleTitle = app.anniversaryMgr:GetPoText(__('编辑队伍'))
    local mediator = battleScriptTeamMediator.new(sendData)
    self:GetFacade():RegistMediator(mediator)
    self:UpdateUI()
end
function AnniversaryTeamMediator:UpdateUI()
    if self.chapterType == QUEST_TYPE.MAIN_QUEST_TYPE  then
        self:UpdateMainQuestLayout()
    else
        self:UpdateBranchQuestLayout()
    end
    self:UpdateRightLayout()
end

--[[
    向BattleScriptTeamMediator 传输数据
--]]
function AnniversaryTeamMediator:ProcessingSendData()

    local teamData = { -- 加工具有的基本卡牌数据格式
        {},
        {},
        {},
        {},
        {},
    }
    local equipedPlayerSkills = { -- 加工具有的基本的技能的数据格式
        ["1"] =  {},
        ["2"] =  {}
    }
    local teamDatas =anniversaryManager.homeData.teamCards or {}
    for k , v in pairs (teamDatas) do
        if teamData[checkint(k)] then
            teamData[checkint(k)].id = v
        end
    end
    local skill =anniversaryManager.homeData.skill or {}
    for k , v in  pairs (skill) do
        if equipedPlayerSkills[tostring(k)] then
            equipedPlayerSkills[tostring(k)].skillId = v
        end
    end
    local  needData = {
        teamData = teamData ,
        equipedPlayerSkills = equipedPlayerSkills ,
        callback = handler(self, self.BattleCallBack) ,-- 开启战斗的回调设置
        battleType = BATTLE_SCRIPT_TYPE.TAG_MATCH,
        scriptType  = 2
    }
    return needData
end
function AnniversaryTeamMediator:BattleCallBack(data)
    local teamStr = ""
    for i = 1 , 5 do
        if i ==5  then
            teamStr = teamStr  ..  ( data.cards[tostring(i)] or "")
        else
            teamStr = teamStr  ..  ( data.cards[tostring(i)] or "") .. ","
        end
    end
    local skillStr = ""
    for i = 1 , 2 do
        if i ==2  then
            skillStr = skillStr  ..  ( data.skill[tostring(i)] or "")
        else
            skillStr = skillStr  ..  ( data.skill[tostring(i)] or "") .. ","
        end
    end
    self:SendSignal(POST.ANNIVERSARY_SET_CONFIG.cmdName , { teamCards = teamStr  , skill = skillStr})
end
function AnniversaryTeamMediator:UpdateMainQuestLayout()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local parserConfig = anniversaryManager:GetConfigParse()
    local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
    local chapterOneConfig = chapterConfig[tostring(self.chapterId or 1)]
    local name =  chapterOneConfig.name
    local mapId  =  chapterOneConfig.map
    local view = viewData.view
    local mainLineLayout = view:getChildByName("mainLineLayout")
    local mainLineViewData = mainLineLayout.viewData
    local areaLabel = mainLineViewData.areaLabel
    local areaImage = mainLineViewData.areaImage
    local headIcon  = mainLineViewData.headIcon
    local tipBtn  = mainLineViewData.tipBtn
    tipBtn:setTag(BUTTON_TAG.TIP_BUTTON)
    display.commonLabelParams(areaLabel, {text = name})
    if checkint(self.chapterId) ==  10  then
        mapId = 5
    else
        mapId = 10 + self.chapterId
    end
    display.commonUIParams(tipBtn , {cb = handler(self, self.ButtonAction)})
    areaImage:setTexture(app.anniversaryMgr:GetResPath(string.format('ui/anniversary/task/anni_task_ico_area_%s.png' , tostring(mapId)) ))
    headIcon:setTexture(AssetsUtils.GetCardHeadPath(chapterOneConfig.icon))
end
function AnniversaryTeamMediator:UpdateBranchQuestLayout()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local parserConfig = anniversaryManager:GetConfigParse()
    local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
    local chapterOneConfig = chapterConfig[tostring(self.chapterId or 1)]
    local name =  chapterOneConfig.name
    local mapId  =  chapterOneConfig.map
    local view = viewData.view
    local branchPanel = view:getChildByName("branchPanel")
    local branchViewData = branchPanel.viewData
    local areaLabel = branchViewData.areaLabel
    local branchrefreshLayout = branchViewData.branchrefreshLayout
    local tipBtn =  branchViewData.tipBtn
    tipBtn:setTag(BUTTON_TAG.TIP_BUTTON)
    local areaImage = branchViewData.areaImage
    local comsumeRichLabel = branchViewData.comsumeRichLabel
    display.commonLabelParams(areaLabel, {text = name})
    self:UpdateLeftAndRightButton(self.chapterId)
    areaImage:setTexture(app.anniversaryMgr:GetResPath(string.format('ui/anniversary/task/anni_task_ico_area_%s.png' , tostring(mapId)) ))
    local diffcultBtn =  branchViewData.diffcultBtn
    display.commonLabelParams(diffcultBtn , {text = string.format(app.anniversaryMgr:GetPoText(__('难度%d')  ) , self.chapterSort) })
    local notChoose = anniversaryManager:GetNotChooseBranchTable()
    local maxNum = anniversaryManager:GetMaxBranchTypeKinds()
    local canHaveNum = table.nums(notChoose)
    local refreshCardSpine = branchViewData.refreshCardSpine
    refreshCardSpine:setVisible(true)
    refreshCardSpine:setToSetupPose()
    refreshCardSpine:setAnimation(0,"anni_main_change_" .. canHaveNum , false  )
    local refreshConsumeConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.REFRESH_CONSUME)
    local index =  maxNum  - canHaveNum
    if index == maxNum  then
        branchrefreshLayout:setVisible(false)
    else
        branchrefreshLayout:setVisible(true)
        local refreshConsumeData   = refreshConsumeConfig[tostring(index)].consume
        local goodsId = refreshConsumeData[1].goodsId
        local num = refreshConsumeData[1].num
        display.reloadRichLabel(comsumeRichLabel , {
            c = {
                fontWithColor(10 ,{ color = "ffffff" ,fontSize = 24 ,   text = string.format(app.anniversaryMgr:GetPoText(__('消耗%d')) , num) }),
                {img = CommonUtils.GetGoodsIconPathById(goodsId)  , scale = 0.2}
            }
        })
    end
    display.commonUIParams(tipBtn, {cb = handler(self, self.ButtonAction)})


end
function AnniversaryTeamMediator:UpdateRightLayout()
    ---@type AnniversaryTeamView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local parserConfig = anniversaryManager:GetConfigParse()
    local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
    local chapterOneConfig = chapterConfig[tostring(self.chapterId or 1)]
    local rewardsData = clone(chapterOneConfig.rewards or {})
    local data = {num = checkint(chapterOneConfig.score) , goodsId = app.anniversaryMgr:GetAnniversaryScoreId()}
    data.showAmount = true
    rewardsData[#rewardsData+1] = data
    local goodNodeLayout = viewData.goodNodeLayout
    local passDescrLabel = viewData.passDescrLabel

    local str            = chapterOneConfig.descr or ""
    display.commonLabelParams(passDescrLabel , {text = str , fontSize = 22,w = 300 , hAlign = display.TAL })
    goodNodeLayout:removeAllChildren()
    for k , v in pairs(rewardsData) do
        v.showAmount = true
        local goodNode = require('common.GoodNode').new(v)
        goodNodeLayout:addChild(goodNode)
        goodNode:setScale(0.8)
        goodNode:setPosition( (k- 0.5) * 96 , 60  )
        display.commonUIParams(goodNode , {  animate =false ,
            cb = function(sender)
              app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
        end
        })
    end
    if self.chapterType >  QUEST_TYPE.MAIN_QUEST_TYPE then
        local sweepBtn       = viewData.sweepBtn
        sweepBtn:setVisible(true)
        local homeData = app.anniversaryMgr:GetHomeData()
        local chapters = homeData.chapters
        local chapterId = chapters[tostring(self.chapterType)]
        if checkint(chapterId) > 0  then
            viewData.sweepBtn:setNormalImage(app.anniversaryMgr:GetResPath('ui/common/common_btn_green'))
            viewData.sweepBtn:setSelectedImage(app.anniversaryMgr:GetResPath('ui/common/common_btn_green'))
        else
            viewData.sweepBtn:setNormalImage(app.anniversaryMgr:GetResPath('ui/common/common_btn_orange_disable'))
            viewData.sweepBtn:setSelectedImage(app.anniversaryMgr:GetResPath('ui/common/common_btn_orange_disable'))
        end
    end

end

function AnniversaryTeamMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.CLOSE_LAYER then
        local mediator = self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
        if mediator then -- 如果存在就要删除战队编辑界面
            app:UnRegsitMediator("BattleScriptTeamMediator")
        end
        app:UnRegsitMediator(NAME)
    elseif tag == BUTTON_TAG.LEFT_BTN then
        local   isChange = self:CheckChapterId(self.chapterId , -1)
        local chapterId =   self.chapterId - 1
        if isChange then
            self.chapterId = chapterId
            self:UpdateLeftAndRightButton(chapterId)
            self.chapterSort =  anniversaryManager:GetChapterSortByChapterIdChapterType(self.chapterId , self.chapterType)
            self:UpdateUI()
        else
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('超出当前关卡可选难度范围')))
        end
    elseif tag == BUTTON_TAG.RIGHT_BTN then

        local   isChange = self:CheckChapterId( self.chapterId , 1)
        local chapterId =   self.chapterId +1
        if isChange then
            self.chapterId = chapterId
            self:UpdateLeftAndRightButton(chapterId)
            self.chapterSort =  anniversaryManager:GetChapterSortByChapterIdChapterType(self.chapterId , self.chapterType)
            self:UpdateUI()
        else
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('超出当前关卡可选难度范围')))
        end
    elseif tag == BUTTON_TAG.SWEEP_BUTTON then
        local homeData = app.anniversaryMgr:GetHomeData()
        local chapters = homeData.chapters
        local chapterId = chapters[tostring(self.chapterType)]
        if checkint(chapterId) > 0  then
            local view = require('Game.views.anniversary.AnniversarySweepQuestView').new({
                isQuickSweep = false ,
                isCanQuickSweep = false ,
                chapterType = self.chapterType
            })
            view:setPosition(display.center)
            app.uiMgr:GetCurrentScene():AddDialog(view)
        else
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('通关难度1后可以使用')))
        end
    elseif tag == BUTTON_TAG.TIP_BUTTON then
        app.uiMgr:ShowIntroPopup({moduleId = -11 })
    elseif tag == BUTTON_TAG.REFRESH_BRANCH then
        local notChoose = anniversaryManager:GetNotChooseBranchTable()
        local maxNum = anniversaryManager:GetMaxBranchTypeKinds()
        local canHaveNum = table.nums(notChoose)
        if  canHaveNum == 0   then
            app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('已经没有新的支线类型了')))
        else
            local index = maxNum  - canHaveNum
            local parserConfig = anniversaryManager:GetConfigParse()
            local refreshConsumeConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.REFRESH_CONSUME)
            local refreshConsumeData   = refreshConsumeConfig[tostring(index)].consume
            local num = refreshConsumeData[1].num
            local goodsId = refreshConsumeData[1].goodsId
            local ownNum = CommonUtils.GetCacheProductNum(goodsId)
            local goodData  = CommonUtils.GetConfig('goods','goods',goodsId) or {}
            local name = goodData.name or ""
            if num > ownNum  then
                if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
                    app.uiMgr:showDiamonTips()
                else
                    app.uiMgr:ShowInformationTips( string.fmt(app.anniversaryMgr:GetPoText(__('_name_ 不足')) , { _name_  = name}))
                end
            else
                app.uiMgr:AddCommonTipDialog({
                   descr = app.anniversaryMgr:GetPoText(__('本轮已选择的支线类型不会出现。')),
                   text = string.format(app.anniversaryMgr:GetPoText(__('是否消耗%d个%s重新抽？')),num , name) ,
                   callback = function()
                        local chooseBranchTypeView = require('Game.views.anniversary.AnniversaryChooseBranchTypeView').new({ openType = 2})
                        app.uiMgr:GetCurrentScene():AddDialog(chooseBranchTypeView)
                        chooseBranchTypeView:setPosition(display.center)
                   end }
                )
            end
        end
    end
end

function AnniversaryTeamMediator:CheckChapterId(chapterId ,direction )
    local chapterSort = anniversaryManager:GetChapterSortByChapterIdChapterType(chapterId , self.chapterType)
    local nextChpterSort = anniversaryManager:GetChapterSortByChapterIdChapterType(chapterId + 1 , self.chapterType)
    local homeData  = anniversaryManager.homeData
    local chapters = homeData.chapters
    local currChapterId =chapters[tostring(self.chapterType)]
    local currChapterSort =  anniversaryManager:GetChapterSortByChapterIdChapterType(currChapterId , self.chapterType)
    if direction == 1 then
        if currChapterSort + 1  > chapterSort and nextChpterSort > 0    then
            return true
        else
            return false
        end
    else
        if chapterSort > 1 then
            return true
        else
            return false
        end
    end
end
function AnniversaryTeamMediator:UpdateLeftAndRightButton(chapterId)
    local parserConfig  = anniversaryManager:GetConfigParse()
    local  chapterTypeConfig =anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER_SORT)
    if chapterTypeConfig[tostring(self.chapterType)] then
        local chapters =  anniversaryManager.homeData.chapters or {}
        local viewData =self:GetViewComponent().viewData
        local view = viewData.view
        local branchPanel = view:getChildByName("branchPanel")
        local branchViewData = branchPanel.viewData
        local  leftBtn                 = branchViewData.leftBtn
        local  rightBtn                =  branchViewData.rightBtn
        leftBtn:setEnabled(true)
        rightBtn:setEnabled(true)
        leftBtn:setNormalImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_active.png'))
        leftBtn:setSelectedImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_active.png'))
        rightBtn:setNormalImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_active.png'))
        rightBtn:setSelectedImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_active.png'))
        if checkint(chapters[tostring(self.chapterType)])  ==  0  then
            leftBtn:setNormalImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_lock.png'))
            leftBtn:setSelectedImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_lock.png'))
            rightBtn:setNormalImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_lock.png'))
            rightBtn:setSelectedImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_lock.png'))
        else
            local currChapterId = checkint(chapters[tostring(self.chapterType)])
            local currChapterSort = anniversaryManager:GetChapterSortByChapterIdChapterType(currChapterId , self.chapterType)
            local chapterSort = anniversaryManager:GetChapterSortByChapterIdChapterType(chapterId , self.chapterType)
            if not  (chapterSort  > 1)    then
                leftBtn:setNormalImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_lock.png'))
                leftBtn:setSelectedImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_lock.png'))
            end
            if not  (currChapterSort  - chapterSort >= 0   and  chapterSort ~= 0)    then
                rightBtn:setNormalImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_lock.png'))
                rightBtn:setSelectedImage(app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_btn_arrow_lock.png'))
            end
        end
    end
    return false
end
function AnniversaryTeamMediator:OnRegist()
    regPost(POST.ANNIVERSARY_SET_CONFIG)
    regPost(POST.ANNIVERSARY_SET_BRANCH_CHAPTER)
    regPost(POST.ANNIVERSARY_SET_MAIN_CHAPTER)
    regPost(POST.ANNIVERSARY_REFRESH_BRANCH_TYPE)
end
function AnniversaryTeamMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY_SET_CONFIG)
    unregPost(POST.ANNIVERSARY_SET_BRANCH_CHAPTER)
    unregPost(POST.ANNIVERSARY_SET_MAIN_CHAPTER)
    unregPost(POST.ANNIVERSARY_REFRESH_BRANCH_TYPE)
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    app:DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return AnniversaryTeamMediator