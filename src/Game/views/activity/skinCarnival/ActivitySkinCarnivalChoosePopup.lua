--[[
 * author : liuzhipeng
 * descpt : 活动 皮肤嘉年华 秒杀二选一popup
--]]
local ActivitySkinCarnivalChoosePopup = class('ActivitySkinCarnivalChoosePopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.skinCarnival.ActivitySkinCarnivalChoosePopup'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG                     = _res('ui/common/common_bg_8.png'),
    REWARDS_BG             = _res('ui/common/common_bg_list_unselected.png'),
    COMMON_BTN_ORANGE      = _res('ui/common/common_btn_orange.png'),
    SELECTED_FRAME_SPN     = _spn('effects/activity/biankuang'),

}
--[[
@params map {
    title      string 标题
    descr      string 描述
    hasSkin    bool   是否拥有皮肤
    hasDrawn   int    是否领取  0：未领取 其他：领取的id
    rewardList list   奖励列表
    signal     string 选中后发送的信号
}
--]]
function ActivitySkinCarnivalChoosePopup:ctor( params )
    self.params = checktable(params)
    self.selectedId = nil -- 选中的奖励
    self:InitUI()
end
--[[
init ui
--]]
function ActivitySkinCarnivalChoosePopup:InitUI()
    local params = self.params
    local function CreateView()
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        -- view
        local view = CLayout:create(size)
        bg:setPosition(size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        -- 标题
        local titleLabel = display.newLabel(size.width / 2, size.height - 45, fontWithColor(6, {text = '测试标题'}))
        view:addChild(titleLabel, 5)
        -- 奖励背景
        local rewardsBg = display.newImageView(RES_DICT.REWARDS_BG, size.width / 2, size.height / 2 + 5, {scale9 = true, size = cc.size(366, 168)})
        view:addChild(rewardsBg, 1)
        -- 描述
        local descrLabel = display.newLabel(size.width / 2, size.height - 83, fontWithColor(8, {text = '测试描述'}))
        view:addChild(descrLabel, 5)
        -- 确认按钮
        local confirmBtn = display.newButton(size.width / 2, 40, {n = RES_DICT.COMMON_BTN_ORANGE})
        display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确认')}))
        view:addChild(confirmBtn, 5)
        -- 奖励
        local rewardComponentList = {}
        for i = 1, 2 do
            local data = params.rewardList[tostring(i)][1]
            local goodsNode = require('common.GoodNode').new({
                id = data.goodsId,
                num = data.num,
                showAmount = true, 
                callBack = handler(self, self.RewardsGoodsNodeCallback)
            })
            goodsNode:setTag(i)
            display.commonUIParams(goodsNode, {po = cc.p(size.width / 2 + (80 * math.pow(-1, i)), size.height / 2)})
            view:addChild(goodsNode, 5)
            local selectedFrame = sp.SkeletonAnimation:create(
                RES_DICT.SELECTED_FRAME_SPN.json, 
                RES_DICT.SELECTED_FRAME_SPN.atlas, 
                1
            )
            selectedFrame:update(0)
            selectedFrame:setAnimation(0, 'idle', true)
            view:addChild(selectedFrame, 10)
            selectedFrame:setPosition(cc.p(goodsNode:getPositionX(), goodsNode:getPositionY()))
            selectedFrame:setVisible(false)
            table.insert(rewardComponentList, {
                goodsNode     = goodsNode,
                selectedFrame = selectedFrame,
            })
        end
        return {
            view                = view,
            titleLabel          = titleLabel,
            descrLabel          = descrLabel,
            confirmBtn          = confirmBtn,
            rewardComponentList = rewardComponentList,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    eaterLayer:setOnClickScriptHandler(function (sender)
        self:runAction(cc.RemoveSelf:create())
    end)
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.confirmBtn:setOnClickScriptHandler(handler(self, self.ConfirmButtonCallback))
        display.commonLabelParams(self.viewData.titleLabel , {text = params.title ,reqW = 350 })
        self.viewData.descrLabel:setString(params.descr)
        -- 刷新道具状态
        if checkint(params.hasDrawn) ~= 0 then
            -- 奖励已领取
            for i, v in ipairs(self.viewData.rewardComponentList) do
                v.goodsNode:setEnabled(false)
                if i == checkint(params.hasDrawn) then
                    v.selectedFrame:setVisible(true)
                end
            end
        end
        -- action
        self.viewData.view:setScale(0.5)
        self.viewData.view:runAction(
            cc.EaseBackOut:create(cc.ScaleTo:create(0.25, 1))
        )
    end, __G__TRACKBACK__)
end
--[[
确认按钮点击回调
--]]
function ActivitySkinCarnivalChoosePopup:ConfirmButtonCallback( sender )
    PlayAudioByClickNormal()
    if self.params.hasSkin and checkint(self.params.hasDrawn) == 0 then
        -- 未领取
        if self.selectedId then
            app:DispatchObservers(self.params.signal, {id = self.selectedId})
            self:runAction(cc.RemoveSelf:create())
        else
            app.uiMgr:ShowInformationTips(__('选择奖励'))
        end
    else
        -- 已领取
        self:runAction(cc.RemoveSelf:create())
    end
end
--[[
奖励道具点击回调
--]]
function ActivitySkinCarnivalChoosePopup:RewardsGoodsNodeCallback( sender )
    PlayAudioByClickNormal()
    local viewData = self:GetViewData()
    local tag = sender:getTag()
    if not self.params.hasSkin then
        app.uiMgr:ShowInformationTipsBoard({
            targetNode = sender, iconId = self.params.rewardList[tostring(tag)][1].goodsId, type = 1	
        })
        return 
    end
    if self.selectedId == tag then return end
    if self.selectedId then
        viewData.rewardComponentList[self.selectedId].selectedFrame:setVisible(false)
    end
    viewData.rewardComponentList[tag].selectedFrame:setVisible(true)
    self.selectedId = tag
end
--[[
获取viewData
--]]
function ActivitySkinCarnivalChoosePopup:GetViewData()
    return self.viewData
end
return ActivitySkinCarnivalChoosePopup