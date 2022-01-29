--[[
周年庆剧情mediator
--]]
local Mediator = mvc.Mediator
---@class CastleStoryMeditaor :Mediator
local CastleStoryMeditaor = class("CastleStoryMeditaor", Mediator)
local NAME = "Game.mediator.castle.CastleStoryMeditaor"

local uiMgr = app.uiMgr

function CastleStoryMeditaor:ctor(params,  viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.ctorArgs_ = checktable(params)
end

function CastleStoryMeditaor:InterestSignals()
    local signals = {
        POST.SPRING_ACTIVITY_UNLOCK_STORY.sglName
    }
    return signals
end

function CastleStoryMeditaor:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    if POST.SPRING_ACTIVITY_UNLOCK_STORY.sglName == name then
        local requestData = body.requestData or {}
        local groupIndex = requestData.groupIndex
        local storyIndex = requestData.storyIndex
        local groupData   = self.datas[groupIndex] or {}
        local storyDatas  = groupData.storyDatas or {}
        local data        = storyDatas[storyIndex] or {}
        data.isNotUnlocked = nil
    end
end

function CastleStoryMeditaor:Initial( key )
    self.super:Initial(key)
    
    self.datas = {}
    self.curSelectGroupIndex = 1

    ---@type AnniversaryStoryView
    local viewComponent  = require('Game.views.anniversary.AnniversaryStoryView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})

    self.ownerScene_ = uiMgr:GetCurrentScene()
    self:getOwnerScene():AddDialog(viewComponent)

    self:initGroupData_(self.ctorArgs_.homeData or {})
    self:initView_()

end

-------------------------------------------------
-- private method

function CastleStoryMeditaor:initGroupData_(homeData)
    local serPlotPointRewards = {}

    -- 通过点数 检查剧情是否解锁
    local curPoint = nil
    -- 通过服务端缓存数据 检查剧情是否解锁
    local serUnlockStory = {}
    local serStory = homeData.story or {}
    local serUnlockStory = {}
    for i, v in ipairs(serStory) do
        serUnlockStory[tostring(v)] = v
    end
    
    local plotConfs = CommonUtils.GetConfigAllMess('plot', 'springActivity') or {}
    local plotTable = {}
    for index, value in pairs(plotConfs) do
        plotTable[tostring(value.storyId)] = value
    end

    local storyCollectConfs = CommonUtils.GetConfigAllMess('storyCollect', 'springActivity') or {}

    local groupDatas = {}
    local groupIds = {}
    for i, storyCollectConf in orderedPairs(storyCollectConfs) do
        local storyId   = tostring(storyCollectConf.storyId)
        local chapterId = storyCollectConf.chapterId
        if groupDatas[chapterId] == nil then
            groupDatas[chapterId] = {}
            groupDatas[chapterId].storyCount = 0
            groupDatas[chapterId].unlockStoryCount = 0
            groupDatas[chapterId].groupId = chapterId
            groupDatas[chapterId].storyDatas = {}
            -- todo 获取 配表数据
            local chapterName = storyCollectConf.chapterName
            groupDatas[chapterId].groupConfData = {name = chapterName, title = chapterName, descr = chapterName}
            table.insert(groupIds, chapterId)
        end
        groupDatas[chapterId].storyCount = groupDatas[chapterId].storyCount + 1
        table.insert(groupDatas[chapterId].storyDatas, {
            storyConfData = storyCollectConf
        })

        local plotData = plotTable[storyId]
        local isUnlocked = serUnlockStory[storyId]
        
        if plotData then
            local goodsId  = plotData.goodsId
            local goodsNum = plotData.goodsNum
            if curPoint == nil then
                curPoint = app.gameMgr:GetAmountByGoodId(goodsId)
            end
            if curPoint >= checkint(goodsNum) then
                groupDatas[chapterId].storyDatas[groupDatas[chapterId].storyCount].unlockStoryId = storyId
                groupDatas[chapterId].storyDatas[groupDatas[chapterId].storyCount].isNotUnlocked = not isUnlocked
                groupDatas[chapterId].unlockStoryCount = groupDatas[chapterId].unlockStoryCount + 1
            end

        elseif isUnlocked then
            groupDatas[chapterId].storyDatas[groupDatas[chapterId].storyCount].unlockStoryId = storyId
            groupDatas[chapterId].unlockStoryCount = groupDatas[chapterId].unlockStoryCount + 1
        end
    end

    table.sort(groupIds, function (a, b)
        return checkint(a) < checkint(b)
    end)
    
    self.datas = {}
    for i, chapterId in ipairs(groupIds) do
        table.insert(self.datas, groupDatas[chapterId])
    end

    
end

function CastleStoryMeditaor:initView_()
    local viewData     = self:getViewData()
    local shallowLayer = viewData.shallowLayer
    display.commonUIParams(shallowLayer, {cb = handler(self, self.onCloseAction)})
    
    local groupTableView  = viewData.groupTableView
    groupTableView:setDataSourceAdapterScriptHandler(handler(self, self.groupTableViewwDataAdapter))
    groupTableView:setCountOfCell(#self.datas)
    groupTableView:reloadData()

    local storyTableView  = viewData.storyTableView
    storyTableView:setDataSourceAdapterScriptHandler(handler(self, self.storyTableViewDataAdapter))
    self:GetViewComponent():updateStoryList(checktable(self.datas[self.curSelectGroupIndex]).storyDatas or {})
end

function CastleStoryMeditaor:groupTableViewwDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local groupTableView = self:getViewData().groupTableView
        pCell = self:GetViewComponent():CreateGroupCell(groupTableView:getSizeOfCell())
        display.commonUIParams(pCell.viewData.touchView, {cb = handler(self, self.onClickGroupCellAction)})
    end

    xTry(function()
        local data = self.datas[index] or {}
        local viewData = pCell.viewData
        self:GetViewComponent():updateGroupCell(viewData, data, app.activityMgr:CastleResEx(string.format("ui/castle/plotReward/castle_plot_icon_%d", checkint(data.groupId))))
        self:GetViewComponent():updateGroupCellBg(viewData, self.curSelectGroupIndex == index)
        viewData.touchView:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

function CastleStoryMeditaor:storyTableViewDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local storyTableView = self:getViewData().storyTableView
        pCell = self:GetViewComponent():CreateStoryCell(storyTableView:getSizeOfCell())
        display.commonUIParams(pCell.viewData.touchView, {cb = handler(self, self.onClickStoryCellAction)})
    end

    xTry(function()
        local groupData   = self.datas[self.curSelectGroupIndex] or {}
        local storyDatas  = groupData.storyDatas or {}
        local data        = storyDatas[index] or {}
        local viewData = pCell.viewData
        self:GetViewComponent():updateStoryCell(viewData, data)
        
        viewData.touchView:setTag(index)
    end,__G__TRACKBACK__)

    return pCell
end

function CastleStoryMeditaor:onClickGroupCellAction(sender)
    local tag  = sender:getTag()

    local viewComponent = self:GetViewComponent()
    viewComponent:updateGroupBgByIndex(self.curSelectGroupIndex, false)
    viewComponent:updateGroupBgByIndex(tag, true)

    self.curSelectGroupIndex = tag
    local data = self.datas[tag] or {}
    viewComponent:updateStoryList(data.storyDatas or {})

end

function CastleStoryMeditaor:onClickStoryCellAction(sender)
    local tag = sender:getTag()
    -- todo 进入剧情
    local groupData   = self.datas[self.curSelectGroupIndex] or {}
    local storyDatas  = groupData.storyDatas or {}
    local data        = storyDatas[tag] or {}
    local unlockStoryId = data.unlockStoryId
    local isNotUnlocked = data.isNotUnlocked
    if unlockStoryId then
        local path = string.format("conf/%s/springActivity/story.json",i18n.getLang())
        local stage = require( "Frame.Opera.OperaStage" ).new({id = unlockStoryId, path = path, guide = false, isHideBackBtn = true, cb = function ()
            -- play bg music
            PlayBGMusic(AUDIOS.WYS.FOOD_WYS_GUILINGGAO_SAD.id)

            if isNotUnlocked ~= nil and isNotUnlocked ~= false then
                self:SendSignal(POST.SPRING_ACTIVITY_UNLOCK_STORY.cmdName , {
                    storyId = unlockStoryId, groupIndex = self.curSelectGroupIndex, storyIndex = tag
                })
            end
        end})
        stage:setPosition(cc.p(display.cx, display.cy))
        sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
    else
        local conf = data.storyConfData or {}
        uiMgr:ShowInformationTips(tostring(conf.resume))
    end

end

function CastleStoryMeditaor:onCloseAction(sender)
    app:UnRegsitMediator(NAME)
end

-------------------------------------------------
-- get / set

function CastleStoryMeditaor:getViewData()
    return self.viewData_
end

function CastleStoryMeditaor:getOwnerScene()
    return self.ownerScene_
end

function CastleStoryMeditaor:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function CastleStoryMeditaor:OnRegist()
    regPost(POST.SPRING_ACTIVITY_UNLOCK_STORY)
end

function CastleStoryMeditaor:OnUnRegist()
    self:cleanupView()
end

return CastleStoryMeditaor
