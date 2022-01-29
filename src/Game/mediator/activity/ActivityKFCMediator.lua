--[[
 * author : liuzhipeng
 * descpt : KFC签到活动 Mediator
--]]
local Mediator = mvc.Mediator
local NAME = "ActivityKFCMediator"
local ActivityKFCMediator = class(NAME, Mediator)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
--[[
@params table{
}
--]]
function ActivityKFCMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    local data = params or {}
    self.activityData = {} -- 活动数据
    self.activityHomeData = checktable(data.activityHomeData)
    self.activityId = checkint(data.activityHomeData.activityId) -- 活动Id
    self.rewardCellDict_   = {}
end

function ActivityKFCMediator:InterestSignals()
	local signals = {
        POST.ACTIVITY_GEO_HOME.sglName,
        POST.ACTIVITY_GEO_DRAW.sglName,
        APP_ENTER_FOREGROUND,
	}
	return signals
end

function ActivityKFCMediator:ProcessSignal(signal)
local name = signal:GetName()
	local body = signal:GetBody()
    if name == POST.ACTIVITY_GEO_HOME.sglName then
        self.activityData = body
        self:RefreshView()
        self:RewardCheck()
    elseif name == POST.ACTIVITY_GEO_DRAW.sglName then
        uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards, closeCallback = function ()
            self:EnterLayer()
        end})
    elseif name == APP_ENTER_FOREGROUND then
        self:EnterLayer()
	end
end

function ActivityKFCMediator:Initial(key)
	self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.ActivityKFCView').new({})
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)
	
    viewComponent:getViewData().enterBtn:setOnClickScriptHandler(handler(self, self.EnterButtonCallback))
    viewComponent:getViewData().gridView:setDataSourceAdapterScriptHandler(handler(self, self.RewardListViewDataSource))
    viewComponent:setTimeLabel(self.activityHomeData.leftSeconds)
    viewComponent:setBackground(self.activityHomeData.backgroundImage[i18n.getLang()])
    viewComponent:setRule(self.activityHomeData.detail[i18n.getLang()])
end
------------------------------------------
-- private
function ActivityKFCMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:getViewData()
    local activityData = self.activityData
    viewData.gridView:setCountOfCell(table.nums(activityData.punchList))
    viewData.gridView:reloadData()
end
------------------------------------------

------------------------------------------
-- handler
--[[
前往按钮点击回调
--]]
function ActivityKFCMediator:EnterButtonCallback( sender )
	PlayAudioByClickNormal()
	local activityId = self.activityId
	local activityData = self.activityData
	-- 跳转至外部浏览器
	local link = 'http://_platform_/kfc/index.html?_playerId_&_host_&_activeId_'
	link = string.gsub(link, '_platform_', string.fmt('notice-%1', Platform.serverHost), 1)
	local str = string.fmt('playerId=%1', app.gameMgr:GetUserInfo().encryptPlayerId)
    str = string.gsub(str, '%%', '%%%%')
	link = string.gsub(link, '_playerId_', str, 1)
	link = string.gsub(link, '_host_', string.fmt('host=%1', Platform.serverHost), 1)
	link = string.gsub(link, '_activeId_', string.fmt('activeId=%1', activityId), 1)
    FTUtils:openUrl(link)
end
--[[
检测是否有可领取的奖励
--]]
function ActivityKFCMediator:RewardCheck()
    local activityData = self.activityData
    local punchTimes = checkint(self.activityData.punchTimes)
    for i, v in ipairs(activityData.punchList) do
        if i <= punchTimes and checkint(v.hasDrawn) == 0 then
            self:SendSignal(POST.ACTIVITY_GEO_DRAW.cmdName, {activityId = self.activityId, punchId = v.punchId})
            return 
        end
    end
end
--[[
列表数据处理
--]]
function ActivityKFCMediator:RewardListViewDataSource( p_convertview, idx )
    local index = idx + 1
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:getViewData()
    local rewardListCell = viewComponent:createRewardCell(viewData.rewrdListCellSize)
    local rewardData = self.activityData.punchList[index]
    local nextIndex = 1
    for i, v in ipairs(self.activityData.punchList) do
        if checkint(v.hasDrawn) == 0 then
            break
        else
            nextIndex = nextIndex + 1
        end
    end

    cell = rewardListCell.view
    self.rewardCellDict_[cell] = rewardListCell
    -- update cell
    local rewardListCell = self.rewardCellDict_[cell]
    xTry(function()
        if rewardListCell then
            local numColor = '#5b3c25' 
            if index == nextIndex then
                numColor = '#d23d3d'
            end
            local strs = string.split(string.fmt(__('第|_num_|次'), {['_num_'] = index}), '|')
            display.reloadRichLabel(rewardListCell.timeRichLabel, {c = {
                {fontSize = 22, color = '#5b3c25', text = strs[1]},
                {fontSize = 22, color = numColor, text = strs[2]},
                {fontSize = 22, color = '#5b3c25', text = strs[3]}
            }})
    
            local goodsData = rewardData.rewards[1]
            rewardListCell.goodsNode:RefreshSelf({
                goodsId = checkint(goodsData.goodsId),
                amount = checkint(goodsData.num),
            })
            rewardListCell.goodsNode.callBack = function(goodsNode)
                uiMgr:ShowInformationTipsBoard({targetNode = goodsNode, iconId = goodsData.goodsId, type = 1})
            end
            rewardListCell.mask:setVisible(checkint(rewardData.hasDrawn) == 1)
            rewardListCell.goodsNode:setEnabled(not (checkint(rewardData.hasDrawn) == 1))
        end
    end,__G__TRACKBACK__)
    return cell
end
------------------------------------------
function ActivityKFCMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITY_GEO_HOME.cmdName, {activityId = self.activityId})
end
function ActivityKFCMediator:OnRegist()
	regPost(POST.ACTIVITY_GEO_HOME)
    regPost(POST.ACTIVITY_GEO_DRAW)
    self:EnterLayer()
end
function ActivityKFCMediator:OnUnRegist()
	unregPost(POST.ACTIVITY_GEO_HOME)
	unregPost(POST.ACTIVITY_GEO_DRAW)
end
return ActivityKFCMediator
