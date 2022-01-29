--[[
常驻奖励页面view
--]]
local CumulativeRechargeRewardView = class('CumulativeRechargeRewardView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CumulativeRechargeRewardView'
    node:enableNodeEvents()
    return node
end)

function CumulativeRechargeRewardView:ctor( ... )
    self.args = unpack({...})
    self.baseRewards = {} -- 基础奖励
    self.specialRewards = {} -- 特殊奖励
    self.hasDrawn = 0 -- 是否领取 
    self.selectedReward  = 0 -- 选中的奖励
    self:InitUI()
end
--[[
init ui
--]]
function CumulativeRechargeRewardView:InitUI()
    local function CreateView()
        local size = cc.size(520, 480)
        local view = CLayout:create(size)
        view:setPosition(cc.p(size.width/2, size.height/2))
        -- 特殊奖励 -- 
        local choiceLayoutBg = display.newImageView(_res('ui/home/recharge/recharge_choice_reward_bg.png'), 0, 0)
        local choiceLayoutSize = choiceLayoutBg:getContentSize()
        local choiceLayout = CLayout:create(choiceLayoutSize)
        choiceLayoutBg:setPosition(cc.p(choiceLayoutSize.width/2, choiceLayoutSize.height/2))
        choiceLayout:addChild(choiceLayoutBg, 1)
        view:addChild(choiceLayout, 1)
        local choiceMask = display.newImageView(_res('ui/home/recharge/recharge_choice_reward_bg_select.png'), choiceLayoutSize.width/2, choiceLayoutSize.height/2, {enable = true})
        choiceLayout:addChild(choiceMask, 10)
        display.commonUIParams(choiceLayout, {ap = cc.p(0, 0), po = cc.p(20, 252)})
        local choiceLayoutTitle = display.newButton(choiceLayoutSize.width/2, choiceLayoutSize.height - 7, {ap = cc.p(0.5, 1),scale9 = true ,   enable = false, n = _res('ui/home/recharge/recharge_title_choice.png')})
        choiceLayout:addChild(choiceLayoutTitle, 3)
        display.commonLabelParams(choiceLayoutTitle, {text = __('选择特殊奖励'), fontSize = 20, color = '#ff0000' , paddingW  = 30 })
        -- 奖励列表
        local choiceTableViewSize = cc.size(336, 166)
        local choiceTableViewCellSize = cc.size(choiceTableViewSize.width/3, choiceTableViewSize.height)
        local choiceTableView = CTableView:create(choiceTableViewSize)
        choiceTableView:setAnchorPoint(cc.p(0.5, 0))   
        choiceTableView:setDirection(eScrollViewDirectionHorizontal)
        choiceTableView:setSizeOfCell(choiceTableViewCellSize)
        choiceTableView:setPosition(cc.p(choiceLayoutSize.width/2, 10))  
        choiceTableView:setBounceable(false)
        choiceLayout:addChild(choiceTableView, 5)
        -- 边框特效
        local frameEffect = sp.SkeletonAnimation:create(
          'effects/cumulativeRecharge/leichong.json',
          'effects/cumulativeRecharge/leichong.atlas',
          1)
        frameEffect:setAnimation(0, 'idle', true)
        frameEffect:setPosition(cc.p(choiceLayoutSize.width/2, choiceLayoutSize.height/2))
        choiceLayout:addChild(frameEffect, 10)
        -- 基础奖励 -- 
        local baseLayoutBg = display.newImageView(_res('ui/home/recharge/recharge_basics_reward_bg.png'), 0, 0)
        local baseLayoutSize = baseLayoutBg:getContentSize()
        local baseLayout = CLayout:create(baseLayoutSize)
        baseLayoutBg:setPosition(cc.p(baseLayoutSize.width/2, baseLayoutSize.height/2))
        baseLayout:addChild(baseLayoutBg, 1)
        view:addChild(baseLayout, 1)
        local baseMask = display.newImageView(_res('ui/home/recharge/recharge_basics_reward_bg_select.png'), baseLayoutSize.width/2, baseLayoutSize.height/2, {enable = true})
        baseLayout:addChild(baseMask, 10)
        display.commonUIParams(baseLayout, {ap = cc.p(0, 0), po = cc.p(20, 78)})
        local baseLayoutTitle = display.newButton(baseLayoutSize.width/2, baseLayoutSize.height - 7, {ap = cc.p(0.5, 1), enable = false, n = _res('ui/home/recharge/recharge_title_basics.png')})
        baseLayout:addChild(baseLayoutTitle, 3)
        display.commonLabelParams(baseLayoutTitle, {text = __('普通奖励'), fontSize = 20, color = '#5b3c25'})
        -- 奖励列表
        local baseTableViewSize = cc.size(392, 110)
        local baseTableViewCellSize = cc.size(baseTableViewSize.width/4, baseTableViewSize.height)
        local baseTableView = CTableView:create(baseTableViewSize)
        baseTableView:setAnchorPoint(cc.p(0.5, 0))   
        baseTableView:setDirection(eScrollViewDirectionHorizontal)
        baseTableView:setSizeOfCell(baseTableViewCellSize)
        baseTableView:setPosition(cc.p(baseLayoutSize.width/2, 14))  
        baseTableView:setBounceable(false)
        baseLayout:addChild(baseTableView, 5)

        return {
            view                    = view, 
            size                    = size,
            choiceLayout            = choiceLayout,
            choiceTableView         = choiceTableView,
            choiceMask              = choiceMask,
            baseLayout              = baseLayout,
            baseTableView           = baseTableView,
            baseMask                = baseMask,
            choiceTableViewCellSize = choiceTableViewCellSize,
            baseTableViewCellSize   = baseTableViewCellSize,
            frameEffect             = frameEffect,
        }
    end 
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:setContentSize(self.viewData_.size)
        self:addChild(self.viewData_.view)
        self.viewData_.choiceTableView:setDataSourceAdapterScriptHandler(handler(self, self.ChoiceListDataSource))
        self.viewData_.baseTableView:setDataSourceAdapterScriptHandler(handler(self, self.BaseListDataSource))
    end, __G__TRACKBACK__)
end
--[[
特殊奖励列表处理
--]]
function CumulativeRechargeRewardView:ChoiceListDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self.viewData_.choiceTableViewCellSize
    if pCell == nil then
        pCell = require('home.RechargeSpecialRewardCell').new(cSize)
        pCell.goodsIcon.callBack = handler(self, self.specialRewardsBtnCallback)
        pCell.previewBtn:setOnClickScriptHandler(handler(self, self.SpecialPreBtnCallback))
    end
    xTry(function()
        local datas = self.specialRewards[index]
        if checkint(self.selectedReward) > 0 then
            if checkint(index) == checkint(self.selectedReward) then
                pCell.selectFrame:setVisible(true)
                pCell.goodsIcon.icon:setColor(cc.c3b(255, 255, 255))
                pCell.goodsIcon.bg:setColor(cc.c3b(255, 255, 255))
                pCell.goodsIcon.fragmentImg:setColor(cc.c3b(255, 255, 255))
            else
                pCell.selectFrame:setVisible(false)
                pCell.goodsIcon.icon:setColor(cc.c3b(160, 160, 160))
                pCell.goodsIcon.bg:setColor(cc.c3b(160, 160, 160))
                pCell.goodsIcon.fragmentImg:setColor(cc.c3b(160, 160, 160))
            end
        else
            pCell.selectFrame:setVisible(false)
            pCell.goodsIcon.icon:setColor(cc.c3b(255, 255, 255))
            pCell.goodsIcon.bg:setColor(cc.c3b(255, 255, 255))
            pCell.goodsIcon.fragmentImg:setColor(cc.c3b(255, 255, 255))
        end
        if checkint(datas.hasDrawn) == 1 then
            pCell.selectFrame:setVisible(true)
        end
        pCell.goodsIcon:RefreshSelf({goodsId = datas.goodsId, amount = datas.num})
        pCell.goodsIcon:setTag(index)
        pCell.previewBtn:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end
--[[
基础奖励列表处理
--]]
function CumulativeRechargeRewardView:BaseListDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self.viewData_.baseTableViewCellSize
    if pCell == nil then
        pCell = require('home.RechargeBaseRewardCell').new(cSize)
    end
    xTry(function()
        local datas = self.baseRewards[index]
        pCell.goodsIcon:RefreshSelf({goodsId = datas.goodsId, amount = datas.num})
        pCell.goodsIcon.callBack = function ( sender ) 
            PlayAudioByClickNormal()
            AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = datas.goodsId, type = 1})
        end
    end,__G__TRACKBACK__)
    return pCell
end
--[[
更新页面
@params rewardsData table {
    baseRewards table 基础奖励
    rewards table 特殊奖励
    hasDrawn int 是否领取
}
--]]
function CumulativeRechargeRewardView:RefreshView( rewardsData )
    self.baseRewards = checktable(rewardsData.baseRewards)
    self.specialRewards = checktable(rewardsData.rewards)
    self.hasDrawn = checkint(rewardsData.hasDrawn)
    self.selectedReward = 0
    local viewData = self.viewData_

    if checkint(rewardsData.hasDrawn) > 0 then
        viewData.baseMask:setVisible(true)
        viewData.choiceMask:setVisible(true)
        viewData.frameEffect:setVisible(false)
    else
        viewData.baseMask:setVisible(false)
        viewData.choiceMask:setVisible(false)
        viewData.frameEffect:setVisible(true)
    end
    viewData.baseLayout:setVisible(true)
    viewData.choiceLayout:setVisible(true)
    if next(self.baseRewards) ~= nil and next(self.specialRewards) ~= nil then
        viewData.baseLayout:setPositionY(78)
        viewData.choiceLayout:setPositionY(252)

        -- 更新特殊奖励
        viewData.choiceTableView:setCountOfCell(#self.specialRewards)
        viewData.choiceTableView:reloadData()
        viewData.baseTableView:setCountOfCell(#self.baseRewards)
        viewData.baseTableView:reloadData()
    else
        if next(self.baseRewards) ~= nil then
            viewData.choiceLayout:setVisible(false)
            viewData.baseLayout:setPositionY(194)
            viewData.baseTableView:setCountOfCell(#self.baseRewards)
            viewData.baseTableView:reloadData()
        elseif next(self.specialRewards) ~= nil then
            viewData.baseLayout:setVisible(false)
            viewData.choiceLayout:setPositionY(178)
            viewData.choiceTableView:setCountOfCell(#self.specialRewards)
            viewData.choiceTableView:reloadData()
        end
    end
end
--[[
特殊奖励点击回调
--]]
function CumulativeRechargeRewardView:specialRewardsBtnCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    self.selectedReward = tag
    self.viewData_.choiceTableView:reloadData()
    AppFacade.GetInstance():DispatchObservers(CUMULATIVE_RECHARGE_CHOICE_REWARD, {selectedReward = self.selectedReward})
end
--[[
特殊奖励预览按钮回调
--]]
function CumulativeRechargeRewardView:SpecialPreBtnCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local scene = AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene()

    local gtype = CommonUtils.GetGoodTypeById(self.specialRewards[tag].goodsId)
    if tostring(gtype) == GoodsType.TYPE_CARD_FRAGMENT then -- 判断奖励是否为卡牌碎片
        AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = self.specialRewards[tag].goodsId, type = 1})
    else
        local cumulativeRechargeCardView = require('Game.views.CumulativeRechargeCardView').new({cardId = self.specialRewards[tag].goodsId})
        display.commonUIParams(cumulativeRechargeCardView, {po = display.center})
        scene:AddDialog(cumulativeRechargeCardView)
    end    
end
return CumulativeRechargeRewardView