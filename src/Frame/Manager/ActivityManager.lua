--[[
 * author : kaishiqi
 * descpt : 活动 管理器
]]
local BaseManager     = require('Frame.Manager.ManagerBase')
---@class ActivityManager  : BaseManager
local ActivityManager = class('ActivityManager', BaseManager)


-------------------------------------------------
-- manager method

ActivityManager.DEFAULT_NAME = 'ActivityManager'
ActivityManager.instances_   = {}


function ActivityManager.GetInstance(instancesKey)
    instancesKey = instancesKey or ActivityManager.DEFAULT_NAME

    if not ActivityManager.instances_[instancesKey] then
        ActivityManager.instances_[instancesKey] = ActivityManager.new(instancesKey)
    end
    return ActivityManager.instances_[instancesKey]
end


function ActivityManager.Destroy(instancesKey)
    instancesKey = instancesKey or ActivityManager.DEFAULT_NAME

    if ActivityManager.instances_[instancesKey] then
        ActivityManager.instances_[instancesKey]:release()
        ActivityManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function ActivityManager:ctor(instancesKey)
    self.super.ctor(self)

    if ActivityManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
    self.castleChangeSkinData = nil

end


function ActivityManager:initial()
    cc.UserDefault:getInstance():setBoolForKey(CV_SHARE_ACTIVITY_KEY, false) -- 重置分享活动标识
end


function ActivityManager:release()
end


-------------------------------------------------
-- public method


function ActivityManager:GetActivityIdByType(activityType)
    local activitHomeData = app.gameMgr:GetUserInfo().activityHomeData.activity or {}
    activityType = checkint(activityType)
    for k , v in pairs(activitHomeData) do
        if checkint(v.type ) == activityType then
            return v.activityId
        end
    end
    return nil
end
--获取 更具模块id 获取宝箱活动对应的数据
function ActivityManager:GetChestTypeTablesByModuleId(moduleId)
    local activitHomeData = app.gameMgr:GetUserInfo().activityHomeData.activity or {}
    local chestType = tostring(ACTIVITY_TYPE.CHEST_ACTIVITY)
    local chests = {}  -- <activityId,moduleId >
    moduleId = checkint(moduleId)
    if moduleId > 0  then
        for k , v in pairs(activitHomeData) do
            if tostring(v.type) == chestType then
                if checkint(v.crBoxModuleId) == moduleId then
                    chests[tostring(v.activityId)] = v.crBoxModuleId
                end
            end
        end
    end
    return chests
end


-- 更新等级礼包的数据
function ActivityManager:UpdateLevelChestData(data)
    local userInfo = app.gameMgr:GetUserInfo()
    userInfo.levelChestData  = data or {}
end
-- 获取到等级礼包的数据
function ActivityManager:GetLevelChestData()
    local userInfo = app.gameMgr:GetUserInfo()
    return userInfo.levelChestData
end


-- 排序等级包厢数据
function ActivityManager:SortChestData()
    local levelChestData = self:GetLevelChestData()
    for i, v in ipairs(levelChestData) do
        if v.discountLeftSeconds == 0 then
            v.sortIndex = 1
        else
            v.sortIndex = 2 --其他
        end

        if checkint( v.openLevel ) <= app.gameMgr:GetUserInfo().level then
            v.sortIndexForLv = 1
        else
            v.sortIndexForLv = 2
        end
    end

    table.sort(levelChestData, function(a, b)
        local r
        local ah  = tonumber(a.hasPurchased)
        local bh  = tonumber(b.hasPurchased)
        local ao  = tonumber(a.openLevel)
        local bo  = tonumber(b.openLevel)

        local as  = tonumber(a.sortIndex)
        local bs  = tonumber(b.sortIndex)

        local asl = tonumber(a.sortIndexForLv)
        local bsl = tonumber(b.sortIndexForLv)

        if ah == bh then
            if asl == bsl then
                if as == bs then
                    r = ao < bo
                else
                    r = as > bs
                end
            else
                r = asl < bsl
            end
        else
            r = ah < bh
        end
        return r
    end)
    app.badgeMgr:AddChestLevelDataRed()
end


function ActivityManager:AddLimiteGiftTimer(chestData)
    local timerName   = string.format("Limit_Gift_%d_%d_%d", checkint(chestData.productId), checkint(chestData.iconId), checkint(chestData.uiTplId))
    local leftSeconds = checkint(chestData.discountLeftSeconds)

    app.timerMgr:RemoveTimer(timerName)
    if leftSeconds > 0 then
        local callFunc = function(countdown, remindTag, timeNum, datas, timerName)
            local findIndex = 0
            for i, chestData in ipairs(app.gameMgr:GetUserInfo().triggerChest or {}) do
				if checkint(chestData.productId) == checkint(datas.productId) and checkint(chestData.uiTplId) == checkint(datas.uiTplId) then
					findIndex = i
				end
            end

            if findIndex > 0 then
                local chestData = checktable(checktable(app.gameMgr:GetUserInfo().triggerChest)[findIndex])
                chestData.discountLeftSeconds = countdown

                AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = countdown, tag = remindTag, timeNum = timeNum, datas = chestData, timerName = timerName})

                if countdown <= 0 then
                    table.remove(app.gameMgr:GetUserInfo().triggerChest, findIndex)
                    AppFacade.GetInstance():DispatchObservers(SGL.REFRES_LIMIT_GIFT_ICON, { countdown = 0, tag = RemindTag.Limite_Time_GIFT_BG})
                end
            end
        end
        app.timerMgr:AddTimer({name = timerName, tag = RemindTag.Limite_Time_GIFT_BG, callback = callFunc, countdown = leftSeconds, isLosetime = false, datas = chestData})
    end
    AppFacade.GetInstance():DispatchObservers(SGL.REFRES_LIMIT_GIFT_ICON, { countdown = 0, tag = RemindTag.Limite_Time_GIFT_BG})
end


--[[
获取季活领取的时间的数据
--]]
function ActivityManager:GetTicketReciveData()
    local ticketReceiveData = CommonUtils.GetConfigAllMess('ticketReceive' , 'seasonActivity')
    local cloneCopy = clone(ticketReceiveData)
    for k ,v in pairs(cloneCopy) do
        local startTime  = v.startTime
        local endTime    = v.endTime
        local serverTimeSecond = getServerTime()
        local startTimeText    = checkstr(startTime)
        local endedTimeText    = checkstr(endTime)
        local startTimeData    = string.split(string.len(startTimeText) > 0 and startTimeText or '00:00', ':')
        local endedTimeData    = string.split(string.len(endedTimeText) > 0 and endedTimeText or '00:00', ':')
        local serverTimestamp  = os.date('!%Y-%m-%d _H_:_M_:00', serverTimeSecond + getServerTimezone())
        local startTimestamp   = string.fmt(serverTimestamp, {_H_ = startTimeData[1], _M_ = startTimeData[2]})
        local endedTimestamp   = string.fmt(serverTimestamp, {_H_ = endedTimeData[1], _M_ = endedTimeData[2]})
        local startTimeSecond  = timestampToSecond(startTimestamp) - getServerTimezone()
        local endedTimeSecond  = timestampToSecond(endedTimestamp) - getServerTimezone()
        if startTimeSecond >= endedTimeSecond then
            endedTimeSecond = endedTimeSecond + 3600 * 24
        end
        v.startTime = startTimeSecond
        v.endTime = endedTimeSecond
    end
    return cloneCopy
end


--[[
判断奖励是否可以领取 如果可以领取的 返回位置位置
--]]
function ActivityManager:JudageSeasonFoodIsReward()
    if not app.gameMgr:GetUserInfo().seasonActivityTickets  then
        return  0
    end
    local severTime = getServerTime()
    for k , v in pairs(app.gameMgr:GetUserInfo().seasonActivityTickets) do
        if checkint(v) == 0 then
            local data = checktable(app.gameMgr:GetUserInfo().seasonTicketData)[k] or {}
            if checkint(severTime) >= checkint(data.startTime)  and  checkint(severTime) < checkint(data.endTime) then
                return 1 , checkint(k)
            end
        end
    end
    return  0
end


--[[
获得binggo 最终奖励图片
--]]
function ActivityManager:getBinngoFinalRewardImgBySkinId(skinId)
    local path = _res(string.format('ui/home/activity/puzzle/puzzlePop/finalReward/activity_puzzle_skin_%s.png', skinId))
    if not utils.isExistent(path) then
        path = _res('ui/home/activity/puzzle/puzzlePop/finalReward/activity_puzzle_skin_250433.png')
    end
    return path
end


--[[
创建活动页签奖励列表
--]]
function ActivityManager:CreateActivityRewardList(rewardDatas)
    local listSize = cc.size(474, 200)
    local cellSize = cc.size(listSize.width/5, listSize.height/2 - 4)
    local gridView = CGridView:create(listSize)
    gridView:setSizeOfCell(cellSize)
    gridView:setColumns(5)
    gridView:setAutoRelocate(true)
    gridView:setAnchorPoint(cc.p(0.5, 0.5))
    gridView:setDataSourceAdapterScriptHandler(function (p_convertview, idx)
        local pCell = p_convertview
        local index = idx + 1
        local cSize = cellSize
        if pCell == nil then
            pCell = CGridViewCell:new()
            pCell:setContentSize(cellSize)
        end
        xTry(function()
            local datas = rewardDatas[index]
            local goodsNode = require('common.GoodNode').new({id = datas.goodsId, showAmount = false, callBack = function ( sender )
                app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = datas.goodsId, type = 1})
            end})
            goodsNode:setScale(0.75)
            goodsNode:setPosition(cc.p(cSize.width/2, cSize.height/2 - 4))
            pCell:addChild(goodsNode, 10)

        end,__G__TRACKBACK__)
        return pCell
    end)
    gridView:setCountOfCell(#rewardDatas)
    gridView:reloadData()
    return gridView
end


--[[
插入剧情
@params table {
	activityId int 活动id
	storyId int 剧情id
	storyType string 剧情类型
	callback function 剧情结束后回调
}
--]]
function ActivityManager:ShowActivityStory(params)
	-- 判断是否跳过剧情
    local actStoryKey = string.format('IS_%s_ACTIVITY_%s_STORY_SHOWED_%s', tostring(params.activityId), tostring(params.storyType), tostring(app.gameMgr:GetUserInfo().playerId))
    local isSkipStory = cc.UserDefault:getInstance():getBoolForKey(actStoryKey, false)
    if isSkipStory then
    	if params.callback then
    		params.callback()
    	end
    else
        local storyPath  = string.format('conf/%s/activity/festivalStory.json', i18n.getLang())
        local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(params.storyId), path = storyPath, guide = true, cb = function(sender)
            cc.UserDefault:getInstance():setBoolForKey(actStoryKey, true)
            if params.callback then
            	params.callback()
            end
        end})
        storyStage:setPosition(display.center)
        sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
    end
end


function ActivityManager:StopSummerActivityTimer()
    if app.timerMgr:RetriveTimer('SUMMER_ACTIVITY') then
        app.timerMgr:RemoveTimer('SUMMER_ACTIVITY')
    end
end
function ActivityManager:AddSummerActivityTimer()
    local summerActivityLeftTime = app.gameMgr:GetUserInfo().summerActivity
    -- 移除倒计时
    if summerActivityLeftTime <= 0 then
        self:StopSummerActivityTimer()
    else
        local callfunc = function( countdown, remindTag, timeNum, datas, timerName)
            app.gameMgr:GetUserInfo().summerActivity = countdown
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = countdown, tag = remindTag, timeNum = timeNum, timerName = timerName})

            if (countdown % 86400) == 0 then
                AppFacade.GetInstance():DispatchObservers('SA_SYNC_DATA')
            end

            if countdown <= 0 then
                AppFacade.GetInstance():DispatchObservers(SGL.REFRES_SUMMER_ACTIVITY_ICON, { countdown = 0, tag = RemindTag.SUMMER_ACTIVITY })
            end
        end
        app.timerMgr:AddTimer({ tag = RemindTag.SUMMER_ACTIVITY, callback = callfunc, name = "SUMMER_ACTIVITY", countdown = summerActivityLeftTime })
    end
end


function ActivityManager:StopPTDungeonTimer()
    if app.timerMgr:RetriveTimer('PTDungeon') then
        app.timerMgr:RemoveTimer('PTDungeon')
    end
end
function ActivityManager:AddPTDungeonTimer()
    local PTDungeonTimerActivityLeftTime = app.gameMgr:GetUserInfo().PTDungeonTimerActivityTime
    -- 移除倒计时
    if PTDungeonTimerActivityLeftTime <= 0 then
        self:StopPTDungeonTimer()
    else
        local callfunc = function( countdown, remindTag, timeNum, datas, timerName)
            app.gameMgr:GetUserInfo().PTDungeonTimerActivityTime = countdown
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = countdown, tag = remindTag, timeNum = timeNum, timerName = timerName})
        end
        app.timerMgr:AddTimer({ tag = RemindTag.PTDUNGEON, callback = callfunc, name = "PTDungeon", countdown = PTDungeonTimerActivityLeftTime, autoDelete = true })
    end
end


function ActivityManager:StopSaiMoeTimer()
    if app.timerMgr:RetriveTimer('SAIMOE') then
        app.timerMgr:RemoveTimer('SAIMOE')
    end
end
function ActivityManager:AddSaiMoeTimer()
    local comparisonActivityLeftTime = app.gameMgr:GetUserInfo().comparisonActivityTime
    -- 移除倒计时
    if comparisonActivityLeftTime <= 0 then
        self:StopSaiMoeTimer()
    else
        local callfunc = function( countdown, remindTag, timeNum, datas, timerName)
            app.gameMgr:GetUserInfo().comparisonActivityTime = countdown
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = countdown, tag = remindTag, timeNum = timeNum, timerName = timerName})
        end
        app.timerMgr:AddTimer({ tag = RemindTag.SAIMOE, callback = callfunc, name = "SAIMOE", countdown = comparisonActivityLeftTime })
    end
end

function ActivityManager:StopSaiMoeCloseTimer()
    if app.timerMgr:RetriveTimer('SAIMOE_CLOSE') then
        app.timerMgr:RemoveTimer('SAIMOE_CLOSE')
    end
end
function ActivityManager:AddSaiMoeCloseTimer()
    local comparisonActivityLeftTime = app.gameMgr:GetUserInfo().comparisonActivity
    -- 移除倒计时
    if comparisonActivityLeftTime <= 0 then
        self:StopSaiMoeCloseTimer()
    else
        local callfunc = function( countdown, remindTag, timeNum, datas, timerName)
            app.gameMgr:GetUserInfo().comparisonActivity = countdown
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = countdown, tag = remindTag, timeNum = timeNum, timerName = timerName})
        end
        app.timerMgr:AddTimer({ tag = RemindTag.SAIMOE, callback = callfunc, name = "SAIMOE_CLOSE", countdown = comparisonActivityLeftTime })
    end
end


-- 更新活动数据
function ActivityManager:UpdateActivity(data)
    local userInfo = app.gameMgr:GetUserInfo()
    local len = table.nums(checktable(checktable(data).activity))
    if len > 0 then
        local index = 0
        local activityIds = {}
        for name,val in pairs(checktable(data).activity) do
            index = index +1
            local activityId = val.activityId
            activityIds[tostring(activityId)] = activityId
            local isHave = false
            for i =#userInfo.activityHomeData.activity,  1, -1 do
                if checkint(userInfo.activityHomeData.activity[i].activityId) == checkint(val.activityId)   then
                    userInfo.activityHomeData.activity[i] =  val
                    isHave = true
                    break
                end
            end

            if not  isHave   then
                table.insert(userInfo.activityHomeData.activity, index, val) --初始插入一个图标用来当入口
            end

            self:checkActivityEntryDataRequestStates(activityId, tostring(val.type))
            self:startActivityCountdownByType(tostring(val.type), val.leftSeconds, activityId)
        end

        -- update activity redPoint
        app.badgeMgr:checkActivityRedPoint(activityIds)
        app.badgeMgr:AddAllCrBoxTimer()

        -- update spActivity openTime
        for i, v in ipairs(userInfo.activityHomeData.activity) do
            if v.type == ACTIVITY_TYPE.SP_ACTIVITY then
                userInfo.activityHomeData.spActivityOpenTime = checkint(v.fromTime)
                break
            end
        end

    else
        userInfo.activityHomeData = {activity = {
            {activityId = -1, image = {[tostring(i18n.getLang())] = ''}, type = -1}
        }}
    end
end


-- 根据活动的id 获取活动的类型
function ActivityManager:GetActivityDataByType(activityType)
    local data = {}
    local time = getServerTime()
    local userInfo = app.gameMgr:GetUserInfo()
    for index, activityData  in pairs(userInfo.activityHomeData.activity or {}) do
        if checkint(activityType ) == checkint(activityData.type) and  checkint(activityData.fromTime) <= time and time <=  checkint(activityData.toTime) then
            data[#data+1] = activityData
        end
    end
    return data
end

function ActivityManager:GetHomeActivityIconTimerName(activityId, activityType)
    return string.format('ACTIVITY_%d_%d', checkint(activityId), checkint(activityType))
end

-- 更新主界面活动图标
function ActivityManager:UpdateHomeActivityIcon(data)
    local userInfo = app.gameMgr:GetUserInfo()
    local activityIconData = checktable(checktable(data).activity)
    userInfo.activityHomeIconData = activityIconData
    -- logInfo.add(5, tableToString(activityIconData))
    
    -- clear all activity home icon timer
    for timerName, _ in pairs(userInfo.activityHomeIconTimerMap_ or {}) do
        app.timerMgr:RemoveTimer(timerName)
    end

    userInfo.activityHomeIconTimerMap_ = {}

    for i, v in pairs(activityIconData) do
        local leftSeconds = checkint(v.leftSeconds)
        local activityId = v.activityId
        local activityType = v.type
        if leftSeconds > 0 then
            local timerName = self:GetHomeActivityIconTimerName(v.activityId, v.type)
            app.timerMgr:AddTimer({name = timerName, countdown = leftSeconds, datas = {activityId = activityId, activityType = activityType}})
        end
        self:checkActivityEntryDataRequestStates(activityId, activityType)
    end
    
    AppFacade.GetInstance():DispatchObservers(SGL.FRESH_HOME_ACTIVITY_ICON)
end


--[[
检查是否是节日菜谱
--]]
function ActivityManager:checkIsFestivalRecipe(id)
    local userInfo = app.gameMgr:GetUserInfo()
    local data = userInfo.restaurantActivityMenuData[tostring(id)]
    return data ~= nil
end


-- 是否开启 餐厅活动
function ActivityManager:isOpenLobbyFestivalActivity()
    local userInfo = app.gameMgr:GetUserInfo()
    return table.nums(userInfo.restaurantActivity) > 0
end


-- 是否是 餐厅活动菜谱
function ActivityManager:getLobbyFestivalMenuData(id)
    local userInfo = app.gameMgr:GetUserInfo()
    return userInfo.restaurantActivityMenuData[tostring(id)]
end


-- 是否是否拥有餐厅活动菜谱
function ActivityManager:checkIsOwnLobbyFestivalMenu()
    local userInfo = app.gameMgr:GetUserInfo()
    return #checktable(userInfo.cookingStyles[FESTIVAL_RECIPE_STYLE]) > 0
end


-- 是否默认选中餐厅活动菜谱
function ActivityManager:isDefaultSelectFestivalMenu()
    return (self:isOpenLobbyFestivalActivity() and self:checkIsOwnLobbyFestivalMenu() and not GuideUtils.IsGuiding())
end


-- 是否默认选中节日菜谱
function ActivityManager:isOpenLobbyFestivalPreviewActivity()
    local userInfo = app.gameMgr:GetUserInfo()
    return table.nums(userInfo.restaurantActivityPreview) > 0
end


--[[
添加餐厅活动数据
--]]
function ActivityManager:AddLobbyActivityData()
    if self:isOpenLobbyFestivalActivity() then
        local userInfo = app.gameMgr:GetUserInfo()
        userInfo.cookingStyles[FESTIVAL_RECIPE_STYLE] = {}
        userInfo.cookingStyles[ALL_RECIPE_STYLE] = userInfo.cookingStyles[ALL_RECIPE_STYLE] or {}
        -- 从所有菜谱中取数据
        for i,v in ipairs(userInfo.cookingStyles[ALL_RECIPE_STYLE]) do
            local recipeId = tostring(v.recipeId)
            if self:checkIsFestivalRecipe(recipeId) then
                table.insert(userInfo.cookingStyles[FESTIVAL_RECIPE_STYLE], v)
            end
        end
    end
end

function ActivityManager:RemoveLobbyActivityData()
    local userInfo = app.gameMgr:GetUserInfo()
    userInfo.restaurantActivity = {}
    userInfo.restaurantActivityMenuData = {}
    userInfo.cookingStyles[FESTIVAL_RECIPE_STYLE] = nil
end

--==============================--
--desc: 判断夏活是否显示
--time:2017-12-18 03:50:27
--@return
--==============================--
function ActivityManager:getExchangeCardActivityIsShow(leftSeconds)
    if checkint(leftSeconds) > 0  then
        if app.gameMgr:GetUserInfo().accumulativePayTwo  > 0 then
            return true
        end
    end
    return false
end

--==============================--
--desc: 开启餐厅节日活动倒计时
--time:2017-12-18 03:50:27
--@return
--==============================--
function ActivityManager:startLobbyFestivalActivity(seconds)
    local userInfo = app.gameMgr:GetUserInfo()
    if seconds ~= nil then
        userInfo.restaurantActivity.leftSeconds = checkint(seconds)
    end

    if app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_LOBBY_FESTIVAL_ACTIVITY) then
        app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_LOBBY_FESTIVAL_ACTIVITY)
    end
    
    local leftTime = checkint(userInfo.restaurantActivity.leftSeconds)
    if leftTime > 0 then
        app.timerMgr:AddTimer({name = COUNT_DOWN_TAG_LOBBY_FESTIVAL_ACTIVITY, countdown = leftTime, tag = RemindTag.LOBBY_FESTIVAL_ACTIVITY})
    else
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.LOBBY_FESTIVAL_ACTIVITY})
    end

end

--==============================--
--desc: 开启餐厅节日预览活动倒计时
--time:2017-12-18 03:50:27
--@return
--==============================--
function ActivityManager:startLobbyFestivalPreviewActivity(seconds)
    local userInfo = app.gameMgr:GetUserInfo()
    if seconds ~= nil then
        userInfo.restaurantActivityPreview.leftSeconds = checkint(seconds)
    end

    if app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_LOBBY_FESTIVAL_PREVIEW_ACTIVITY) then
        app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_LOBBY_FESTIVAL_PREVIEW_ACTIVITY)
    end
    
    local leftTime = checkint(userInfo.restaurantActivityPreview.leftSeconds)
    if leftTime > 0 then
        app.timerMgr:AddTimer({name = COUNT_DOWN_TAG_LOBBY_FESTIVAL_PREVIEW_ACTIVITY, countdown = leftTime, tag = RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW})
    else
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.LOBBY_FESTIVAL_ACTIVITY_PREVIEW})
    end
end

--==============================--
--desc: 显示返回HomeUI

--@return
--==============================--
function ActivityManager:ShowBackToHomeUI()
    local commonTip  = require( 'common.NewCommonTip' ).new({
        text =__('活动已过期, 点击确定返回主界面'), isForced = true,
        isOnlyOK = true, callback = function ()
            AppFacade.GetInstance():BackMediator()
    end})
    commonTip:setPosition(display.center)
    sceneWorld:addChild(commonTip, GameSceneTag.Dialog_GameSceneTag)
end

--==============================--
--desc: 根据活动类型获得活动倒计时名称配置 (基础名称)
--@params type string 活动类型
--@return countdownNameConf table 倒计时名称配置
--==============================--
function ActivityManager:getActivityCountdownNameConfByType(type)
    local activityCountdownNameConfs = {
        --                                          倒计时名称                       是否拼接活动             RemindTag
        [ACTIVITY_TYPE.ANNIVERSARY]    = { name = 'COUNT_DOWN_TAG_ANNIVERSARY', isSplicingActivityId = false, tag = nil },
        [ACTIVITY_TYPE.BAR_VISITOR]    = { name = 'COUNT_DOWN_TAG_VISTOR', isSplicingActivityId = false, tag = nil },
        [ACTIVITY_TYPE.CHEST_ACTIVITY] = { name = 'COUNT_DOWN_TAG_CHEST_ACTIVITY', isSplicingActivityId = true, tag = nil },
        -- [ACTIVITY_TYPE.PASS_TICKET] = {name = 'COUNT_DOWN_PASS_TICKET',     isSplicingActivityId = false, tag = nil},
    }
    return activityCountdownNameConfs[type]
end

--==============================--
--desc: 根据活动类型获得活动倒计时名称 (基础名称)
--@params type string 活动类型
--@return countdownName string 倒计时名称
--==============================--
function ActivityManager:getActivityCountdownNameByType(type, activityId)
    local countdownNameConf = self:getActivityCountdownNameConfByType(type)
    if countdownNameConf == nil then return end
    local countdownName   = countdownNameConf.name
    local isSplicingActivityId = countdownNameConf.isSplicingActivityId
    if isSplicingActivityId and activityId then
        countdownName = table.concat({countdownName, activityId})
    end
    return countdownName
end

--==============================--
--desc: 根据活动类型开启活动倒计时
--@params type       string 活动类型
--@params seconds    int    剩余时间
--@params activityId int    活动id
--@return
--==============================--
function ActivityManager:startActivityCountdownByType(type, seconds, activityId)
    local countdownName = self:getActivityCountdownNameByType(type, activityId)
    if countdownName == nil then return end
    
    self:createCountdownTemplate(seconds, countdownName)
end

--==============================--
--desc: 创建倒计时模板
--@params seconds    int    剩余时间
--@params name       string 倒计时名称
--@params tag        int    remind tag
--@return
--==============================--
function ActivityManager:createCountdownTemplate(seconds, name, tag)
    name = tostring(name)
    self:stopCountdown(name)
    local leftTime = checkint(seconds)
    if leftTime > 0 then
        app.timerMgr:AddTimer({name = name, countdown = leftTime, tag = tag})
    else
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, name = name, tag = tag})
    end
end

--==============================--
--desc: 停止倒计时
--@params name       string 倒计时名称
--@return
--==============================--
function ActivityManager:stopCountdown(name)
    name = tostring(name)
    if app.timerMgr:RetriveTimer(name) then
        app.timerMgr:RemoveTimer(name)
    end
end

--==============================--
--desc: 检查活动入口数据请求状态
--@params activityId string 活动id
--@params activityType string 活动类型
--@return
--==============================--
function ActivityManager:checkActivityEntryDataRequestStates(activityId, activityType)
    local activityEntryDataRequestStates = app.gameMgr:GetUserInfo().activityEntryDataRequestStates or {}

    activityId = tostring(activityId)
    local state = checkint(activityEntryDataRequestStates[activityId])
    if state > 0 then return end

    if tostring(activityType) == ACTIVITY_TYPE.PASS_TICKET then
        activityEntryDataRequestStates[activityId] = 1
        app.httpMgr:Post('Activity/passTicket', SGL.SYNC_ACTIVITY_PASS_TICKET, {activityId = activityId}, true)
    elseif tostring(activityType) == ACTIVITY_TYPE.TIME_LIMIT_UPGRADE_TASK then
        local timeLimitLvUpgradeConf = CommonUtils.GetConfigAllMess("timeLimitLvUpgrade", "activity")
        
        -- 检查当前的等级是否在要求的等级内
        local isCanRequest = false
        local level = app.gameMgr:GetUserInfo().level
        for key, value in pairs(timeLimitLvUpgradeConf) do
            if level >= checkint(value.startLv) and level < checkint(value.targetLv) then
                isCanRequest = true
                break
            end
        end	

        if not isCanRequest then return end

        app.httpMgr:Post('Activity/timeLimitLvUpgradeHome', POST.ACTIVITY_TIME_LIMIT_LV_UPGRADE_HOME.sglName, {}, true)
    end
end
--==============================--
--desc: 获取首充卡牌
--@return cardId int 卡牌id
--==============================--
function ActivityManager:getFirstPaymentCard()
    local firstPayRewards = app.gameMgr:GetUserInfo().firstPayRewards
    for i, v in ipairs(checktable(firstPayRewards)) do
        if CommonUtils.GetGoodTypeById(checkint(v.goodsId)) == GoodsType.TYPE_CARD then
            return checkint(v.goodsId)
        end 
    end
end

--==============================--
--desc: 通过计时器名称检查活动是否结束
--@params timerName string 计时器名称
--@return isEnd     bool   活动是否结束 
--==============================--
function ActivityManager:CheckActivityEndByTimerName(timerName)
    local timerMgr  = app.timerMgr
    local timerInfo = timerMgr:RetriveTimer(timerName)
    if timerInfo and checkint(checktable(timerInfo).countdown) == 0 then
        app.uiMgr:ShowInformationTips(__('活动已过期'))
        return true
    end
    return false
end

function ActivityManager:CastleResEx(resPath)
    return _resEx(resPath , nil , GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN)
end
function ActivityManager:CastleSpnEx(spinPath)
    return _spnEx(spinPath , GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN)
end
function ActivityManager:GetChangeSkinData()
    if not self.castleChangeSkinData then
        self.castleChangeSkinData = require("changeSkin.castle."  .. GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN)
    end
    return self.castleChangeSkinData
end
function ActivityManager:GetCastleText(text)
    local castleChangeSkinData = self:GetChangeSkinData()
    local podTable = castleChangeSkinData.po
    if podTable == nil then
        return text
    end
    return podTable[text] or text
end
function ActivityManager:GetCastleIconPosTable()
    local CASTLE_SKIN = GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN
    if CASTLE_SKIN and string.len( CASTLE_SKIN) > 0  then
        local castleChangeSkinData = self:GetChangeSkinData()
        return castleChangeSkinData.iconPosTable
    end
    return  {
        cc.p(display.cx + 74, display.cy - 220),
        cc.p(display.cx -270, display.cy + 50),
        cc.p(display.cx + 241, display.cy + 44),
        cc.p(display.cx + 514, display.cy + 128)
    }
end

function ActivityManager:GetCastleDrawSpinePos()
    local CASTLE_SKIN = GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN
    if CASTLE_SKIN and string.len( CASTLE_SKIN) > 0  then
        local castleChangeSkinData = self:GetChangeSkinData()
        return castleChangeSkinData.drawSpinePos
    end
    return cc.p(480, 130)
end
function ActivityManager:GetCastleMainPos()
    local CASTLE_SKIN = GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN
    if CASTLE_SKIN and string.len( CASTLE_SKIN) > 0  then
        local castleChangeSkinData = self:GetChangeSkinData()
        return castleChangeSkinData.mainPosTable
    end
    return {
        rightModulePos = cc.p(215, 27),
        leftModulePos  = cc.p(215, 27),
    }

end
function ActivityManager:GetCastleDrawPosConf()
    local CASTLE_SKIN = GAME_MOUDLE_EXCHANGE_SKIN.CASTLE_SKIN
    if CASTLE_SKIN and string.len( CASTLE_SKIN) > 0  then
        local castleChangeSkinData = self:GetChangeSkinData()
        return castleChangeSkinData.drawPosConf
    end
    return {
        belowBgPos = cc.p(display.cx, 0),
        belowBgAP = display.CENTER_BOTTOM,
        rewardPreviewPos = cc.p(display.SAFE_L + 150, 71),
        connerLayerPos = cc.p(display.SAFE_R + 60, 0),
        connerLayerAP = display.RIGHT_BOTTOM,
        flowerImgPos = cc.p(274, 221),
        flowerImgScale = 0.62,
        needleImgScale = 0.6,
        needleImgPos = cc.p(460, 223),
        flowerNumPos = cc.p(284, 152),
        needleNumPos = cc.p(468, 152),
        purifyOneTimesBtnPos = cc.p(215, 85),
        purifyTenTimesBtnPos = cc.p(513, 86),
        purifyTipLabelPos = cc.p(599, 15),
        fragmentIconPos = cc.p(626, 19),
    }
end

---IsCanPopTimeLimitUpgradeTaskView
---是否能弹出显示等级奖励
function ActivityManager:IsCanPopTimeLimitUpgradeTaskView()
    local userInfo = app.gameMgr:GetUserInfo()
    local curKey = app.activityMgr:GetTimeLimitUpgradeConfKey()
    if curKey < 0 then
        return false
    end

    local key = self:GetTimeLimitUpgradeTaskLocalKey(curKey)
    if cc.UserDefault:getInstance():getBoolForKey(key) then
        return false
    end

    if self:GetActivityIdByType(ACTIVITY_TYPE.TIME_LIMIT_UPGRADE_TASK) and userInfo.isShowTimeLimitUpgradeTask then
        cc.UserDefault:getInstance():setBoolForKey(key, true)
        cc.UserDefault:getInstance():flush()
        return true
    end
    --                       有活动                                                       符合弹出条件               
    return  false
end

function ActivityManager:GetTimeLimitUpgradeTaskLocalKey(curKey)
    local key = tostring(app.gameMgr:GetUserInfo().playerId) .. "TIME_LIMIT_UPGRADE_" .. tostring(curKey)
    return key
end

---GetTimeLimitUpgradeConfKeyByLevel
---获取限时升级奖励 配表key
function ActivityManager:GetTimeLimitUpgradeConfKey()
    local curKey = -1
    local level = app.gameMgr:GetUserInfo().level
    local timeLimitLvUpgradeConf = CommonUtils.GetConfigAllMess("timeLimitLvUpgrade", "activity")
    for key, value in pairs(timeLimitLvUpgradeConf) do
        local startLv = checkint(value.startLv)
        if level >= startLv and level < checkint(value.targetLv) then
            curKey = checkint(key)
            break
        end
    end
    return curKey
end

-------------------------------------------------
-- private method


return ActivityManager
