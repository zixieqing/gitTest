--[[
 * author : liuzhipeng
 * descpt : 活动 连续活跃活动 rewardNode
--]]
local ActivityContinuousActiveRewardNode = class('ActivityContinuousActiveRewardNode', function()
    local node = CLayout:create()
    node:enableNodeEvents()
    node:setAnchorPoint(cc.p(0.5, 0.5))
    node.name = 'ActivityContinuousActiveRewardNode'
    return node
end)
local NODE_SIZE = cc.size(200, 200)
local RES_DICT = {
    GET_BG                       = _res('ui/home/activity/continuousActive/activeness_bg_prize_get.png'),
    FINISH_BG                    = _res('ui/home/activity/continuousActive/activeness_bg_prize_finish.png'),
    UNFINISH_BG                  = _res('ui/home/activity/continuousActive/activeness_bg_prize_unfinish.png'),
    ARROW_ICON                   = _res('ui/home/activity/continuousActive/activeness_img_arrow.png'),
    CHECKBOX_SELECTED            = _res('ui/home/activity/continuousActive/common_btn_check_selected.png'),
    PRIZE_GOODS_BG               = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg.png'),
    PRIZE_GOODS_BG_LIGHT         = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg_light.png'),
    COMMON_BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),

}
function ActivityContinuousActiveRewardNode:ctor(...)
    local args = unpack({...})
    self.callback = nil 
    self:InitUI()
end
--[[
初始化UI
--]]
function ActivityContinuousActiveRewardNode:InitUI()
    local CreateView = function (size)
        local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        view:setVisible(false)
        local rewardBg = display.newImageView(RES_DICT.UNFINISH_BG, size.width / 2, size.height / 2)
        view:addChild(rewardBg, 1)

        local rewardGoodsBg = display.newImageView(RES_DICT.PRIZE_GOODS_BG, size.width / 2, size.height / 2)
        view:addChild(rewardGoodsBg, 2)
        local rewardGoodsBgLight = display.newImageView(RES_DICT.PRIZE_GOODS_BG_LIGHT, rewardGoodsBg:getContentSize().width / 2, rewardGoodsBg:getContentSize().height / 2)
        rewardGoodsBg:addChild(rewardGoodsBgLight, 2)
        rewardGoodsBgLight:runAction(
            cc.RepeatForever:create(
                cc.RotateBy:create(10, 180)
            )
        )
        local titleLabel = display.newLabel(size.width / 2, size.height - 30, {text = '', fontSize = 20, color = '#debaa0'})
        view:addChild(titleLabel, 5)
        local goodsNode = require('common.GoodNode').new({callBack = function () end})
        display.commonUIParams(goodsNode, {po = cc.p(size.width / 2, size.height / 2)})
        view:addChild(goodsNode, 3)
        local drawBtn = display.newButton(size.width / 2, 45, {n = RES_DICT.COMMON_BTN_ORANGE})
        view:addChild(drawBtn, 5)
        display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('领取')}))
        local arrowIcon = display.newImageView(RES_DICT.ARROW_ICON, size.width, size.height / 2)
        view:addChild(arrowIcon, 5)
        local checkbox = display.newImageView(RES_DICT.CHECKBOX_SELECTED, size.width / 2 + 6, 45)
        view:addChild(checkbox, 5)
        return {
            view          = view,
            rewardBg      = rewardBg,
            rewardGoodsBg = rewardGoodsBg,
            goodsNode     = goodsNode,
            titleLabel    = titleLabel,
            drawBtn       = drawBtn,
            arrowIcon     = arrowIcon,
            checkbox      = checkbox,
        }
    end
    xTry(function ( )
        self.viewData = CreateView(NODE_SIZE)
        self:setContentSize(NODE_SIZE)
        self:addChild(self.viewData.view)
        self.viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
	end, __G__TRACKBACK__)
end  
--[[
初始化节点
@params {
    day int 连续天数
    rewards map 奖励
    state int 节点状态
    showArrow bool 是否显示箭头
    callback function 领取按钮点击回调
}
--]]
function ActivityContinuousActiveRewardNode:RefreshNode( params )
    local viewData = self:GetViewData()
    viewData.arrowIcon:setVisible(params.showArrow and true or false)
    viewData.titleLabel:setString(string.fmt(__('_num_天'), {['_num_'] = params.day}))
    viewData.drawBtn:setTag(checkint(params.day))
    local rewards = checktable(params.rewards)
    viewData.goodsNode:RefreshSelf({
        goodsId = rewards.goodsId,
        amount = rewards.num,
        showAmount = true,
        callBack = function ( sender )
            AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = rewards.goodsId, type = 1})
        end
    })
    if params.callback then
        self.callback = params.callback
    end
    if params.state then
        self:SetState(params.state)
    end
    viewData.view:setVisible(true)
end
--[[
设置节点状态
@params state int 节点状态 1：已领取 2：待领取 3：不能领取
--]]
function ActivityContinuousActiveRewardNode:SetState( state )
    local viewData = self:GetViewData()
    if checkint(state) == 1 then
        viewData.titleLabel:setColor(ccc3FromInt('#debaa0'))
        viewData.titleLabel:setPosition(cc.p(NODE_SIZE.width / 2, NODE_SIZE.height - 30))
        viewData.goodsNode:setPosition(cc.p(NODE_SIZE.width / 2, NODE_SIZE.height / 2))
        viewData.rewardBg:setTexture(RES_DICT.GET_BG)
        viewData.rewardGoodsBg:setVisible(false)
        viewData.drawBtn:setVisible(false)
        viewData.checkbox:setVisible(true)
    elseif checkint(state) == 2 then
        viewData.titleLabel:setColor(ccc3FromInt('#ffffff'))
        viewData.rewardBg:setTexture(RES_DICT.FINISH_BG)
        viewData.titleLabel:setPosition(cc.p(NODE_SIZE.width / 2, NODE_SIZE.height - 30))
        viewData.goodsNode:setPosition(cc.p(NODE_SIZE.width / 2, NODE_SIZE.height / 2))
        viewData.rewardGoodsBg:setVisible(true)
        viewData.drawBtn:setVisible(true)
        viewData.checkbox:setVisible(false)
    elseif checkint(state) == 3 then
        viewData.titleLabel:setColor(ccc3FromInt('#debaa0'))
        viewData.rewardBg:setTexture(RES_DICT.UNFINISH_BG)
        viewData.titleLabel:setPosition(cc.p(NODE_SIZE.width / 2, NODE_SIZE.height - 40))
        viewData.goodsNode:setPosition(cc.p(NODE_SIZE.width / 2, NODE_SIZE.height / 2 - 10))
        viewData.rewardGoodsBg:setVisible(false)
        viewData.drawBtn:setVisible(false)
        viewData.checkbox:setVisible(false)
    end
end
--[[
领取按钮点击回调
--]]
function ActivityContinuousActiveRewardNode:DrawButtonCallback( sender )
    if self.callback then
        self.callback(sender)
    end
end
--[[
获取viewData
--]]
function ActivityContinuousActiveRewardNode:GetViewData()
    return self.viewData
end
return ActivityContinuousActiveRewardNode