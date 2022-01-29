local Mediator = mvc.Mediator
local NAME = "TastingTourZoneStarRewardMediator"
---@class TastingTourZoneStarRewardMediator :Mediator
local TastingTourZoneStarRewardMediator = class(NAME, Mediator)
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type TastingTourManager
local tastingTourMgr = AppFacade.GetInstance():GetManager("TastingTourManager")
--[[
    {
        zoneId = 1
    }
--]]
function TastingTourZoneStarRewardMediator:ctor(params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    params = params or {}
    self.starCount = 0         -- 获取当前区域所有的星数
    self.zoneRewardData = {}   -- 区域的奖励收入
    self.zoneId = params.zoneId or 1
    self.isCloseAction = false
end

function TastingTourZoneStarRewardMediator:InterestSignals()
    local signals = {
       POST.CUISINE_DRAWTOTALREWARD.sglName ,
    }
    return signals
end

function TastingTourZoneStarRewardMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    --- 领取奖励接口
    if name == POST.CUISINE_DRAWTOTALREWARD.sglName then
        local requestData = body.requestData
        if requestData then
            local fieldData = self:GetFieleIdById(requestData.totalRewardId)
            if fieldData then
                fieldData.hasDrawn = 1
            else
                fieldData = {}
                fieldData.hasDrawn = 1
                fieldData.id = requestData.totalRewardId
                tastingTourMgr:SetTotalRewardsMapOneDataByZoneId(self.zoneId, fieldData)
            end
            local viewData = self.viewComponent.viewData
            viewData.rewardList:removeAllNodes()
            uiMgr:AddDialog('common.RewardPopup',{rewards = body.rewards })
            self:UpdateListView()
        end
    end
end
--[[
    获取sort的排列方式
--]]
function TastingTourZoneStarRewardMediator:GetSortTable()
    local totalRewards =self:GetCurrentRewardsConfig() or {}
    local zonetable = {}
    for i, v in pairs(totalRewards) do
        zonetable[#zonetable+1] = v
    end

    table.sort(zonetable,
    function (a, b )
        if  checkint(a.starNum) <  checkint(b.starNum) then
            return true
        end
        return false
    end)
    return zonetable
end

function TastingTourZoneStarRewardMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type TastingTourZoneStarRewardView
    local viewComponent = require('Game.views.tastingTour.TastingTourZoneStarRewardView').new()
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = cc.p(display.width * 0.5, display.height * 0.5)})
    self.viewComponent = viewComponent
    viewComponent:setOpacity(0)
    uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:runAction(cc.Sequence:create(
    cc.FadeIn:create(0.3),
    cc.CallFunc:create(
        function()
            local viewData  = self.viewComponent.viewData
            viewData.closeLayer:setOnClickScriptHandler(
            function (sender)
                if not self.isCloseAction then
                    self:GetViewComponent():setVisible(false)
                    self:GetFacade():UnRegsitMediator(NAME)
                    self.isCloseAction = true
                end
            end)
            self.zoneRewardData =  tastingTourMgr:GetStyleHomeData().totalRewards[tostring(self.zoneId)] or {}
            self.starCount = self:GetStarNumCount()
            display.reloadRichLabel(self.viewComponent.viewData.richLabel , {  c= {
                fontWithColor('10', {text= __('当前星标:') , fontSize = 24 , color = "#5b3c24"}),
                fontWithColor('14', {text= self.starCount , color =  "#ffdf75" , fontSize = 26 })
            }})
            CommonUtils.AddRichLabelTraceEffect(self.viewComponent.viewData.richLabel , nil , nil ,{2})
            self:UpdateZoneRewardStatus()
            local zonetable = self:GetSortTable()
            self.zonetable = zonetable
            self:UpdateListView()
        end
    ) ))

end
--[[
    判断档位的领取状态
--]]
function TastingTourZoneStarRewardMediator:GetFieleIdById(id)
    for k ,v in pairs(self.zoneRewardData) do
        if checkint(v.id) == checkint(id) then
            return v
        end
    end
end
--[[
    更新区域的领取状态
--]]

function TastingTourZoneStarRewardMediator:GetCurrentRewardsConfig()
    local totalRewardConfig = tastingTourMgr:GetConfigDataByName(tastingTourMgr:GetConfigParse().TYPE.TOTAL_REWARDS)
    local tatalZoneRewards = {}
    for i, v in pairs(totalRewardConfig) do
        if checkint(v.zoneId ) == checkint(self.zoneId)  then
            tatalZoneRewards[tostring(i)] = v
        end
    end
    return tatalZoneRewards or {}
end
function TastingTourZoneStarRewardMediator:UpdateZoneRewardStatus()
   local tatalZoneRewards =self:GetCurrentRewardsConfig() or {}
    -- 档位的状态
    for i, v in pairs(tatalZoneRewards) do
        local fileIdData = self:GetFieleIdById(v.id)
        if not  fileIdData then
            local data = {}
            data.id = v.id
            data.starNum = v.starNum
            data.hasDrawn = 0
            fileIdData = data
            tastingTourMgr:SetTotalRewardsMapOneDataByZoneId(self.zoneId, data)
        end
        local hasDrawn = checkint(fileIdData.hasDrawn)
        -- 0. hasDrawn 不可以领取   1. 已经领取 2. 可以领取未领取
        if hasDrawn ~= 1 then
            -- 优先取的档位的星数奖励
            local starNum = v.starNum
            if  self.starCount  >= checkint(starNum) then
                hasDrawn = 2
            else
                hasDrawn = 0
            end
            fileIdData.hasDrawn = hasDrawn
        end
    end
end
function TastingTourZoneStarRewardMediator:UpdateListView()
    local viewData = self.viewComponent.viewData
    for i, v in pairs(self.zonetable) do
        local cell = self.viewComponent:CreateOneCell(v)
        self:UpdateListCell(cell,v)
        viewData.rewardList:insertNodeAtLast(cell)
    end
    viewData.rewardList:reloadData()
end
function TastingTourZoneStarRewardMediator:GetStarNumCount()
    local homeData = tastingTourMgr:GetStyleHomeData()
    local cuisineStars = homeData.cuisineStars
    local zoneData = cuisineStars[tostring(self.zoneId)]
    local starNum = 0
    for i, v in pairs(zoneData) do
        starNum = checkint(v) + starNum
    end
    return starNum
end
--[[
   更新cell 的显示
--]]
function TastingTourZoneStarRewardMediator:UpdateListCell(cell , data)
    local id = data.id
    local rewardOneData = self:GetFieleIdById(data.id) or {}
    cell.viewData.rewardBtn:setTag(checkint(id))
    if checkint(rewardOneData.hasDrawn) == 0 then
        cell.viewData.rewardBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
        cell.viewData.rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
        cell.viewData.rewardBtn:setDisabledImage(_res('ui/common/common_btn_orange_disable'))
        cell.viewData.rewardBtn:setEnabled(false)
    elseif checkint(rewardOneData.hasDrawn ) == 1 then
        cell.viewData.rewardBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico'))
        cell.viewData.rewardBtn:setSelectedImage(_res('ui/common/activity_mifan_by_ico'))
        cell.viewData.rewardBtn:setDisabledImage(_res('ui/common/activity_mifan_by_ico'))
        display.commonLabelParams(cell.viewData.rewardBtn,fontWithColor('14',{text = __('已领取')}) )
        cell.viewData.rewardBtn:setEnabled(false)
    else
        cell.viewData.rewardBtn:setEnabled(true)
        cell.viewData.rewardBtn:setOnClickScriptHandler(function (sender)
            self:SendSignal(POST.CUISINE_DRAWTOTALREWARD.cmdName, {totalRewardId = sender:getTag()})
        end)
    end


end


-----------------------------------

-- regist/unRegist
function TastingTourZoneStarRewardMediator:OnRegist()
    regPost(POST.CUISINE_DRAWTOTALREWARD)
end
function TastingTourZoneStarRewardMediator:OnUnRegist()
    unregPost(POST.CUISINE_DRAWTOTALREWARD)
    AppFacade.GetInstance():DispatchObservers(SGL.TASTING_TOUR_ZONE_REWARD_LAYER_EVENT , {})
    -- 发送检测事件 用来判断其他的区域是否还有奖励领取
    if self.isCloseAction and  self.viewComponent and (not tolua.isnull(self.viewComponent)) then
        self.isCloseAction = false
        self.viewComponent:stopAllctions()
        self.viewComponent:runAction(cc.RemoveSelf:create() )
    end
end
return TastingTourZoneStarRewardMediator