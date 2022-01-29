--[[
 * author : kaishiqi
 * descpt : 玩家升级 中介者
]]
local UpgradeLevelView     = require('Game.views.UpgradeLevelView')
local UpgradeLevelMediator = class('UpgradeLevelMediator', mvc.Mediator)


function UpgradeLevelMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'UpgradeLevelMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method

function UpgradeLevelMediator:Initial(key)
    self.super.Initial(self, key)

    -- parse args
    local gameManager    = self:GetFacade():GetManager('GameManager')
    self.oldPlayerLevel_ = math.max(1, checkint(self.ctorArgs_.oldLevel))
    self.newPlayerLevel_ = checkint(gameManager:GetUserInfo().level)

    local levelRewardConfs   = CommonUtils.GetConfigAllMess('levelReward', 'player') or {}
    local oldLevelRewardConf = levelRewardConfs[tostring(self.oldPlayerLevel_)] or {}
    local newLevelRewardConf = levelRewardConfs[tostring(self.newPlayerLevel_)] or {}
    self.isFromHomeMdt_      = AppFacade.GetInstance():RetrieveMediator('HomeMediator')
    self.isControllable_     = true

    -- create view
    local uiManager   = self:GetFacade():GetManager('UIManager')
    self.ownerScene_  = uiManager:GetCurrentScene()
    self.upgradeView_ = UpgradeLevelView.new()
    self.ownerScene_:AddDialog(self.upgradeView_)
    self:SetViewComponent(self.upgradeView_)

    -- update views
    local upgradeViewData = self:getUpgradeView():getViewData()
    self:getUpgradeView():updateLevelInfo(self.oldPlayerLevel_, self.newPlayerLevel_)
    self:getUpgradeView():updateHealthInfo(oldLevelRewardConf.hpUpperLimit, newLevelRewardConf.hpUpperLimit)

    -- add listener
    display.commonUIParams(upgradeViewData.blockLayer, {cb = handler(self, self.onClickBlockLayerHandler_), animate = false})
    display.commonUIParams(upgradeViewData.gotoHomeBtn, {cb = handler(self, self.onClickGotoHomeButtonHandler_)})
    
    -- show upgradeFrame
    self.isControllable_ = false
    self:getUpgradeView():showUpgradeFrame(
        function()
            --local upgradeRewardsData = self:checkUpgradeRewardsData_(newLevelRewardConf)
            local upgradeRewardsData = {} 
            
            for  i =  self.oldPlayerLevel_+1  ,self.newPlayerLevel_ do
                local currentLevelRewardsConf = levelRewardConfs[tostring(i)] or {}
                for index, reward in pairs(currentLevelRewardsConf.rewards) do
                    local goodsId = reward.goodsId
                    if not  upgradeRewardsData[tostring(goodsId)] then
                         upgradeRewardsData[tostring(goodsId)] = 0
                    end
                    upgradeRewardsData[tostring(goodsId)] =upgradeRewardsData[tostring(goodsId)]  + reward.num
                end
            end
            local listData = {}
            for goodsId, num  in pairs(upgradeRewardsData) do
                table.insert(listData ,{goodsId = goodsId , num = num } )
            end
            self:getUpgradeView():updateRewardsInfo(listData)  -- have action
        end, 
        function()
            local openedModuleIdList = self:checkOpenedModuleIdList_(self.newPlayerLevel_)
            if #openedModuleIdList > 0 then
                self:getUpgradeView():updateUnlockFunctionInfo(openedModuleIdList[1])
                self:getUpgradeView():showUnlockFrame(function()
                    self.isControllable_ = true
                end)
            else
                self:getUpgradeView():showCloseFrame(function()
                    self.isControllable_ = true
                end)
            end
        end
    )
end


function UpgradeLevelMediator:CleanupView()
    if self.upgradeView_  and (not tolua.isnull(self.upgradeView_))  then
        self.upgradeView_:runAction(cc.RemoveSelf:create())
        self.upgradeView_ = nil  
        self.ownerScene_ = nil
    end 
end


function UpgradeLevelMediator:OnRegist()
    local gameManager   = self:GetFacade():GetManager('GameManager')
    local playerLevel   = checkint(gameManager:GetUserInfo().level)
    
    -- 剧情结束后出引导
    if playerLevel == CONDITION_LEVELS.ACCEPT_STORY_TASK then
        GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_LOBBY)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_DRAWCARD)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_TEAM)
        GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_ACCEPT_STORY)

    elseif playerLevel == CONDITION_LEVELS.FINISH_STORY_TASK then
        GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_LOBBY)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_DRAWCARD)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_TEAM)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_ACCEPT_STORY)
        GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_FINISH_STORY)
        --EVENTLOG.Log(EVENTLOG.EVENTS.newBieGuideEnd)
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.GUIDE_END)
    elseif playerLevel == CONDITION_LEVELS.DISCOVER_DISH then
        GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_LOBBY)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_DRAWCARD)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_TEAM)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_ACCEPT_STORY)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_FINISH_STORY)
        GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_DISCOVERY)

    end
end
function UpgradeLevelMediator:OnUnRegist()
    if 0 < checkint(SUBPACKAGE_LEVEL) and cc.UserDefault:getInstance():getBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), false) == false then
        local gameManager   = self:GetFacade():GetManager('GameManager')
        local playerLevel   = checkint(gameManager:GetUserInfo().level)
        if playerLevel >= checkint(SUBPACKAGE_LEVEL) then
            local uiMgr = self:GetFacade():GetManager("UIManager")
            local scene = uiMgr:GetCurrentScene()
            local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('您已经初步体验了我们的游戏，如需体验更多更优质的游戏内容，还需继续下载完整游戏包～'),
                isOnlyOK = true, isForced = true, callback = function ()
                    if cc.UserDefault:getInstance():getBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), false) == false then
                        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'ResourceDownloadMediator', params = {
                            closeFunc = function (  )
                                -- clear UpgradeData
                                app.passTicketMgr:SetUpgradeData()
                                AppFacade.GetInstance():BackHomeMediator()
                            end
                        }})
                    end
                end})
            CommonTip:setPosition(display.center)
            scene:AddDialog(CommonTip)
        end
    else
        app:DispatchObservers(SGL.HANDLER_UPGRADE_LEVEL_POP, {isFromHomeMdt = app:RetrieveMediator('HomeMediator') and 1 or 0})
    end

    if self.isFromHomeMdt_ then
        AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
    end
end


function UpgradeLevelMediator:InterestSignals()
    return {}
end
function UpgradeLevelMediator:ProcessSignal(signal)
end


-------------------------------------------------
-- get / set

function UpgradeLevelMediator:getUpgradeView()
    return self.upgradeView_
end


-------------------------------------------------
-- public method

function UpgradeLevelMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private method

function UpgradeLevelMediator:checkOpenedModuleIdList_(levelNum)
    local openIdList  = {}
    local playerLevel = checkint(levelNum)
    local moduleConfs = CommonUtils.GetConfigAllMess('module') or {}
    for moduleId, moduleConf in pairs(moduleConfs) do
        if playerLevel == checkint(moduleConf.openLevel) and checkint(moduleConf.display) == 1 then
            if CommonUtils.GetModuleAvailable(MODULE_REFLECT[tostring(moduleId)]) then
                table.insert(openIdList, checkint(moduleId))
            end
            break
        end
    end
    return openIdList
end


function UpgradeLevelMediator:checkUpgradeRewardsData_(levelRewardConf)
    local upgradeRewardsData = {
        goodsRewards = {},
        hpRewardNum  = 0,
    }
    for _, reward in ipairs(checktable(levelRewardConf).rewards or {}) do
        --if checkint(reward.goodsId) == HP_ID then
        --    upgradeRewardsData.hpRewardNum = upgradeRewardsData.hpRewardNum + checkint(reward.num)
        --else
            table.insert(upgradeRewardsData.goodsRewards, reward)
        --end
    end
    return upgradeRewardsData
end


function UpgradeLevelMediator:refreshLevelChestData_()
    local gameManager  = self:GetFacade():GetManager('GameManager')
    local playerLevel  = checkint(gameManager:GetUserInfo().level)
    local lvChestConfs = CommonUtils.GetConfigAllMess('levelChestOpen' ,'activity') or {}
    for level, _ in pairs(lvChestConfs) do
        if checkint(level) <= playerLevel and checkint(level) > self.oldPlayerLevel_ then
            self:SendSignal(POST.LEVEL_GIFT_CHEST.cmdName, {})
            break
        end
    end
end


function UpgradeLevelMediator:refreshUnlockModuleData_()
    local takeawayMgr = self:GetFacade():GetManager('TakeawayManager')
    local gameManager = self:GetFacade():GetManager('GameManager')
    local playerLevel = checkint(gameManager:GetUserInfo().level)
    local moduleConfs = CommonUtils.GetConfigAllMess('module') or {}

    local getModuleOpenLevel = function(moduleTag)
        local moduleConf = moduleConfs[tostring(MODULE_DATA[tostring(moduleTag)])] or {}
        return checkint(moduleConf.openLevel)
    end

    if getModuleOpenLevel(PUBLIC_ORDER) == playerLevel then
        takeawayMgr:FreshData()
    elseif getModuleOpenLevel(CARVIEW) == playerLevel then
        takeawayMgr:FreshData()
    end
end


-------------------------------------------------
-- handler

function UpgradeLevelMediator:onClickBlockLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    -- check inGuiding
    if GuideUtils.IsGuiding() then return end

    -- refresh data
    self:refreshLevelChestData_()
    self:refreshUnlockModuleData_()
    
    -- close self
    self:close()
end


function UpgradeLevelMediator:onClickGotoHomeButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    -- refresh data
    self:refreshLevelChestData_()
    self:refreshUnlockModuleData_()
    
    -- back to home
    self:GetFacade():DispatchObservers(GUIDE_HANDLE_SYSTEM)

end


return UpgradeLevelMediator
