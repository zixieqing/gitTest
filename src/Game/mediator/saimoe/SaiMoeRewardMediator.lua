---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by pengjixian.
--- DateTime: 2018/10/18 4:30 PM
---
--[[
    燃战应援查看奖励界面
--]]
local Mediator = mvc.Mediator
---@class SaiMoeRewardMediator:Mediator
local SaiMoeRewardMediator = class("SaiMoeRewardMediator", Mediator)

local NAME = "SaiMoeRewardMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr
local cardMgr = app.cardMgr

function SaiMoeRewardMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.datas = checktable(params) or {}
end

function SaiMoeRewardMediator:InterestSignals()
    local signals = {
        POST.SAIMOE_DRAW_POINT_REWARD.sglName,
    }

    return signals
end

function SaiMoeRewardMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    -- dump(body, name)
    if name == POST.SAIMOE_DRAW_POINT_REWARD.sglName then
        self.drawRewards[tostring(body.requestData.pointId)] = true
        local index = -1
        for i, v in pairs(self.pointRewards) do
            if tostring(v.id) == tostring(body.requestData.pointId) then
                index = i
                break
            end
        end
        local cell = self.viewComponent.viewData.rewardList:cellAtIndex(index-1)
        if cell then
            self:UpdateListCell(cell, self.pointRewards[index])
        end
    end
end

function SaiMoeRewardMediator:Initial( key )
    self.super.Initial(self, key)
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require('Game.views.saimoe.SaiMoeRewardView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)

    local viewData = viewComponent.viewData
    viewData.supportNumLabel:setString(tostring(checkint(self.datas.point)))

    self.drawRewards = {}
    for i, v in pairs(self.datas.pointRewards) do
        self.drawRewards[tostring(v)] = true
    end
    local rewardList = viewData.rewardList
    rewardList:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
    local pointRewards = CommonUtils.GetConfigAllMess('pointRewards', 'cardComparison')[tostring(self.datas.supportGroupId)]
    self.pointRewards = {}
    for i, v in pairs(pointRewards) do
        table.insert(self.pointRewards, v)
    end
    table.sort(self.pointRewards, function(a, b) 
        if self.drawRewards[tostring(a.id)] ~= self.drawRewards[tostring(b.id)] then
            return self.drawRewards[tostring(b.id)]
        else
            return checkint(a.id) < checkint(b.id)
        end
    end)
    rewardList:setCountOfCell(table.nums(self.pointRewards))
    rewardList:reloadData()
end

function SaiMoeRewardMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    if nil ==  pCell  then
        pCell = self.viewComponent:CreateOneCell(self.pointRewards[index])
        pCell.viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.RewardBtnClickHandle))
    end

    xTry(function()
        self:UpdateListCell(pCell, self.pointRewards[index])
    end,__G__TRACKBACK__)
    return pCell
end

function SaiMoeRewardMediator:RewardBtnClickHandle(sender)
    PlayAudioByClickNormal()

    local pointId = sender:getTag()
    if self.drawRewards[tostring(pointId)] then
        uiMgr:ShowInformationTips(__('已领取'))
    else
        local pointRewards = CommonUtils.GetConfigAllMess('pointRewards', 'cardComparison')[tostring(self.datas.supportGroupId)]
        if checkint(pointRewards[tostring(pointId)].num) > checkint(self.datas.point) then
            uiMgr:ShowInformationTips(__('活动票数不足'))
        else
            self:SendSignal(POST.SAIMOE_DRAW_POINT_REWARD.cmdName, { pointId = sender:getTag() })
        end
    end
end

--[[
   更新cell 的显示
--]]
function SaiMoeRewardMediator:UpdateListCell(cell , data)
    cell.viewData.starPoint:setString(data.num)
    cell.viewData.rewardBtn:setTag(checkint(data.id))
    local goodsIcons = cell.viewData.goodsIcons
    local frameImageSize = cell.viewData.frameImageSize
    local goodSize = cc.size(95,100)
    if #goodsIcons < #data.rewards then
        local reward = data.rewards or {}
        for i = #goodsIcons + 1, #data.rewards do
            local goodsIcon = require('common.GoodNode').new({id = reward[i].goodsId, amount = reward[i].num, showAmount = true })
            goodsIcon:setAnchorPoint(display.CENTER)
            goodsIcon:setPosition(cc.p(frameImageSize.width / 2 - (#reward-1)*goodSize.width/2 + (i-1)*goodSize.width, frameImageSize.height/2 ))
            cell.viewData.frameLayout:addChild(goodsIcon)
            goodsIcon:setScale(0.8)
            goodsIcon:setTag(reward[i].goodsId)
            display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
                PlayAudioByClickNormal()
                uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender:getTag(), type = 1})
            end})
            table.insert(cell.viewData.goodsIcons, goodsIcon)
        end
    end
    for i = 1, #data.rewards do
        goodsIcons[i]:setVisible(true)
        goodsIcons[i]:RefreshSelf(data.rewards[i])
        goodsIcons[i]:setTag(data.rewards[i].goodsId)
        goodsIcons[i]:setPositionX(frameImageSize.width / 2 - (#data.rewards-1)*goodSize.width/2 + (i-1)*goodSize.width)
    end
    for i = #data.rewards+1, #goodsIcons do
        goodsIcons[i]:setVisible(false)
    end
    local rewardBtn = cell.viewData.rewardBtn
    if checkint(data.num) > checkint(self.datas.point) then
        rewardBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
        rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
        rewardBtn:setDisabledImage(_res('ui/common/common_btn_orange_disable'))
        display.commonLabelParams(rewardBtn, fontWithColor('14' ,{ text = __('未达到') , paddingW = 10 , safeW  = 100  }) )
        rewardBtn:setEnabled(true)
    else
        if self.drawRewards[tostring(data.id)] then
            rewardBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico'))
            rewardBtn:setSelectedImage(_res('ui/common/activity_mifan_by_ico'))
            rewardBtn:setDisabledImage(_res('ui/common/activity_mifan_by_ico'))
            rewardBtn:setDisabledImage(_res('ui/common/activity_mifan_by_ico'))
            display.commonLabelParams(rewardBtn,fontWithColor('14',{text = __('已领取') , paddingW = 10 , safeW  = 100}) )
            rewardBtn:setEnabled(false)
        else
            rewardBtn:setNormalImage(_res('ui/common/common_btn_orange'))
            rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange'))
            rewardBtn:setDisabledImage(_res('ui/common/common_btn_orange'))
            rewardBtn:setDisabledImage(_res('ui/common/common_btn_orange'))
            display.commonLabelParams(rewardBtn,fontWithColor('14',{text = __('领取') , paddingW = 10 , safeW  = 100}) )
            rewardBtn:setEnabled(true)
        end
    end
end

function SaiMoeRewardMediator:OnRegist(  )
    regPost(POST.SAIMOE_DRAW_POINT_REWARD)
end

function SaiMoeRewardMediator:OnUnRegist(  )
    unregPost(POST.SAIMOE_DRAW_POINT_REWARD)
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveGameLayer(self.viewComponent)
end

return SaiMoeRewardMediator