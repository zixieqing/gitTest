--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 排行榜Mediator
--]]
local AssemblyActivityRankMediator = class('AssemblyActivityRankMediator', mvc.Mediator)
local NAME = 'activity.assemblyActivity.AssemblyActivityRankMediator'

function AssemblyActivityRankMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
    self.activityId = checkint(args.activityId)
end
-------------------------------------------------
------------------ inheritance ------------------
function AssemblyActivityRankMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.activity.assemblyActivity.AssemblyActivityRankView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    -- 绑定
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.CloseButtonCallback))
    viewData.rewardsPreviewBtn:setOnClickScriptHandler(handler(self, self.RewardsPreviewButtonCallback))
    viewData.rankTableView:setCellUpdateHandler(handler(self, self.OnUpdateRankListCellHandler))
end
    
function AssemblyActivityRankMediator:InterestSignals()
    local signals = {
        POST.ASSEMBLY_ACTIVITY_RANK_HOME.sglName,
    }
    return signals
end
function AssemblyActivityRankMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ASSEMBLY_ACTIVITY_RANK_HOME.sglName then
        self:SetHomeData(body)
        self:InitView()
    end
end

function AssemblyActivityRankMediator:OnRegist()
    regPost(POST.ASSEMBLY_ACTIVITY_RANK_HOME)
    self:EnterLayer()
end
function AssemblyActivityRankMediator:OnUnRegist()
    unregPost(POST.ASSEMBLY_ACTIVITY_RANK_HOME)
    -- 移除界面
    local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
关闭按钮点击回调
--]]
function AssemblyActivityRankMediator:CloseButtonCallback( sender )
	PlayAudioByClickNormal()
	app:UnRegsitMediator(NAME)
end
--[[
奖励预览按钮点击回调
--]]
function AssemblyActivityRankMediator:RewardsPreviewButtonCallback( sender )
    PlayAudioByClickNormal()
    local scene = app.uiMgr:GetCurrentScene()
    local rewardsDatas = CommonUtils.GetConfigAllMess('rankReward', 'springActivity2020')
    local title = __("追击竞速排行奖励")
    local LobbyRewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, rewardsDatas = rewardsDatas, title = title})
    LobbyRewardListView:setTag(1200)
    LobbyRewardListView:setPosition(display.center)
    scene:AddDialog(LobbyRewardListView)
end
--[[
列表刷新处理
--]]
function AssemblyActivityRankMediator:OnUpdateRankListCellHandler( cellIndex, cellViewData )
    local homeData = self:GetHomeData()
    local cellData = checktable(homeData.rank)[cellIndex]
    if not cellData then return end
    cellViewData.nameLabel:setString(cellData.playerName)
    cellViewData.rankLabel:setString(cellData.rank)
    cellViewData.lotteryTimesLabel:setString(string.fmt(__('抽奖次数：_num_次'), {['_num_'] = cellData.score}))
    cellViewData.reawrdsLayer:removeAllChildren()
    local rankRewards = app.springActivity20Mgr:GetRankRewards(cellData.rank)
    if rankRewards then
        for i, v in ipairs(rankRewards) do
            local goodsNode = require('common.GoodNode').new({
                id = checkint(v.goodsId),
                amount = checkint(v.num),
                showAmount = true,
                callBack = function (sender)
                    app.uiMgr:ShowInformationTipsBoard({
                        targetNode = sender, iconId = checkint(v.goodsId), type = 1
                    })
                end
            })
            goodsNode:setPosition(cc.p(50 + (i - 1) * 100, cellViewData.reawrdsLayer:getContentSize().height / 2))
            goodsNode:setScale(0.8)
            cellViewData.reawrdsLayer:addChild(goodsNode, 1)
        end
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function AssemblyActivityRankMediator:InitView()
    self:InitRankList()
    self:RefreshMyRank()
end
--[[
初始化排行列表
--]]
function AssemblyActivityRankMediator:InitRankList()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    local homeData = self:GetHomeData()
    viewData.rankTableView:setCountOfCell(#homeData.rank)
    viewData.rankTableView:reloadData()
end
--[[
刷新玩家排名
--]]
function AssemblyActivityRankMediator:RefreshMyRank()
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    local params = {
        rank = homeData.myRank,
        score = homeData.myScore,
    }
    viewComponent:RefreshMyRank(params)
end
--[[
进入页面
--]]
function AssemblyActivityRankMediator:EnterLayer()
    self:SendSignal(POST.ASSEMBLY_ACTIVITY_RANK_HOME.cmdName, {activityId = self.activityId})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function AssemblyActivityRankMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function AssemblyActivityRankMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return AssemblyActivityRankMediator