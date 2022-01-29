--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 排行榜Mediator
]]
local SpringActivity20Mediator = class('SpringActivity20Mediator', mvc.Mediator)
local NAME = "springActivity20.SpringActivity20Mediator"
function SpringActivity20Mediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
end
-------------------------------------------------
------------------ inheritance ------------------
function SpringActivity20Mediator:Initial( key )
    self.super.Initial(self, key)
	local viewComponent  = require('Game.views.springActivity20.SpringActivity20RankView').new()
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    -- 绑定
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.CloseButtonCallback))
    viewData.rewardsPreviewBtn:setOnClickScriptHandler(handler(self, self.RewardsPreviewButtonCallback))
    viewData.rankTableView:setCellUpdateHandler(handler(self, self.OnUpdateRankListCellHandler))
end

function SpringActivity20Mediator:InterestSignals()
    local signals = {
        POST.SPRING_ACTIVITY_20_RANK.sglName
	}
	return signals
end
function SpringActivity20Mediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SPRING_ACTIVITY_20_RANK.sglName then -- home
        self:SetHomeData(body)
        self:InitView()
    end
end

function SpringActivity20Mediator:OnRegist()
    regPost(POST.SPRING_ACTIVITY_20_RANK)
    self:EnterLayer()
end
function SpringActivity20Mediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_20_RANK)
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
function SpringActivity20Mediator:CloseButtonCallback( sender )
	PlayAudioByClickNormal()
	app:UnRegsitMediator(NAME)
end
--[[
奖励预览按钮点击回调
--]]
function SpringActivity20Mediator:RewardsPreviewButtonCallback( sender )
    PlayAudioByClickNormal()
    local scene = app.uiMgr:GetCurrentScene()
    local rewardsDatas = CommonUtils.GetConfigAllMess('rankReward', 'springActivity2020')
    local title = app.springActivity20Mgr:GetPoText(__("追击竞速排行奖励"))
    local LobbyRewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, rewardsDatas = rewardsDatas, title = title})
    LobbyRewardListView:setTag(1200)
    LobbyRewardListView:setPosition(display.center)
    scene:AddDialog(LobbyRewardListView)
end
--[[
列表刷新处理
--]]
function SpringActivity20Mediator:OnUpdateRankListCellHandler( cellIndex, cellViewData )
    local homeData = self:GetHomeData()
    local cellData = checktable(homeData.ranks)[cellIndex]
    if not cellData then return end
    cellViewData.nameLabel:setString(cellData.playerName)
    cellViewData.rankLabel:setString(cellData.rank)
    cellViewData.captureTimesLabel:setString(string.fmt(app.springActivity20Mgr:GetPoText(__('阻止次数：_num_次')), {['_num_'] = cellData.times}))
    cellViewData.totalTimes:setString(string.fmt(app.springActivity20Mgr:GetPoText(__('总耗时：_num_秒')), {['_num_'] = cellData.duration}))
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
function SpringActivity20Mediator:InitView()
    self:InitRankList()
    self:RefreshMyRank()
end
--[[
初始化排行列表
--]]
function SpringActivity20Mediator:InitRankList()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    local homeData = self:GetHomeData()
    viewData.rankTableView:setCountOfCell(#homeData.ranks)
    viewData.rankTableView:reloadData()
end
--[[
刷新玩家排名
--]]
function SpringActivity20Mediator:RefreshMyRank()
    local viewComponent = self:GetViewComponent()
    local homeData = self:GetHomeData()
    viewComponent:RefreshMyRank(checktable(homeData.myRank))
end
--[[
进入界面
--]]
function SpringActivity20Mediator:EnterLayer()
    self:SendSignal(POST.SPRING_ACTIVITY_20_RANK.cmdName)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function SpringActivity20Mediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function SpringActivity20Mediator:GetHomeData()
    return self.homeData or {}
end
------------------- get / set -------------------
-------------------------------------------------
return SpringActivity20Mediator
