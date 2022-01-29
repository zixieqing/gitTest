--[[
 * author : liuzhipeng
 * descpt : 联动 pop子 关卡奖励View
--]]
local PopTeamStageRewardsView = class('PopTeamStageRewardsView', function ()
    local node = CLayout:create(display.size)
    node.name = 'PopTeamStageRewardsView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG                     = _res('ui/link/popTeam/stage/pop_title_bg.png'),
    TITLE_BG               = _res('ui/common/common_title_3.png'),
    COMMON_BTN             = _res('ui/common/common_btn_orange.png'),
}
local CreateRewardsCell = nil
function PopTeamStageRewardsView:ctor( ... )
    local args = unpack({...})
    dump(args)
    self.questId = args.questId
    self.rewards = args.rewards
    self.isLock = args.isLock
    self.drawCB = args.drawCB
    self:InitUI()
end
--[[
init ui
--]]
function PopTeamStageRewardsView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, coEnable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --
        
        -- title 
        local title = display.newButton(size.width / 2, size.height / 2 + 60, {n = RES_DICT.TITLE_BG})
        display.commonLabelParams(title, fontWithColor(4, {text = __('奖励预览')}))
        view:addChild(title, 5)
        -- 提示
        local tipsLabel = display.newLabel(size.width / 2, 115, fontWithColor(4, {text = __('通关全部关卡后可领取'), fontSize = 20}))
        view:addChild(tipsLabel, 5)
        -- 确认按钮
        local confirmBtn = display.newButton(size.width / 2, 65, {n = RES_DICT.COMMON_BTN})
        display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确定')}))
        view:addChild(confirmBtn, 5)
        -- 奖励列表
        local rewardsGridViewSize = cc.size(466, 190)
		local rewardsGridViewCellSize = cc.size(rewardsGridViewSize.width / 5, 90)
        local rewardsGridView = display.newGridView(size.width / 2 - 8, 120, {size = rewardsGridViewSize, csize = rewardsGridViewCellSize, dir = display.SDIR_V, ap = display.CENTER_BOTTOM, cols = 5})
		rewardsGridView:setCellCreateHandler(CreateRewardsCell)
        view:addChild(rewardsGridView, 5)
        
        return {
            view                     = view,
            confirmBtn               = confirmBtn,
            rewardsGridViewSize      = rewardsGridViewSize,
            rewardsGridViewCellSize  = rewardsGridViewCellSize,
            rewardsGridView          = rewardsGridView,
        }
    end
    -- eaterLayer
    
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true, cb = handler(self, self.CloseAction), coEnable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.confirmBtn:setOnClickScriptHandler(handler(self, self.ConfirmButtonCallback))
        self.viewData.rewardsGridView:setCellUpdateHandler(handler(self, self.OnUpdateRewardsListCellHandler))
        self:RefershView()
        self:EnterAction()
    end, __G__TRACKBACK__)
end

CreateRewardsCell = function( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    local goodsNode = require('common.GoodNode').new({
        id = GOLD_ID,
        amount = 1,
        showAmount = true,
        callBack = function (sender)
        end
    })
    goodsNode:setPosition(size.width / 2, size.height / 2)
    goodsNode:setScale(0.75)
    view:addChild(goodsNode, 1)
    return {
        view       = view,
        goodsNode  = goodsNode,
	}
end
--[[
刷新页面
--]]
function PopTeamStageRewardsView:RefershView()
    local viewData = self:GetViewData()
    viewData.rewardsGridView:resetCellCount(#self.rewards)
    if self.isLock then
        display.commonLabelParams(viewData.confirmBtn, fontWithColor(14, {text = __('确定')}))
    else
        display.commonLabelParams(viewData.confirmBtn, fontWithColor(14, {text = __('领取')}))
    end
end
--[[
列表刷新处理
--]]
function PopTeamStageRewardsView:OnUpdateRewardsListCellHandler( cellIndex, cellViewData )
    local data = self.rewards[cellIndex]
    cellViewData.goodsNode:RefreshSelf({goodsId = data.goodsId, amount = data.num, callBack = function (sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
    end})
end
--[[
确认按钮点击回调
--]]
function PopTeamStageRewardsView:ConfirmButtonCallback( sender )
    PlayAudioByClickNormal()
    if not self.isLock then
        self.drawCB(self.questId)
    end
    self:CloseAction()
end
--[[
进入动画
--]]
function PopTeamStageRewardsView:EnterAction(  )
    local viewData = self:GetViewData()
    self:setOpacity(255 * 0.3)
    self.eaterLayer:setOpacity(0)
    self:runAction(
        cc.FadeIn:create(0.2)
    )
    self.eaterLayer:runAction(
        cc.FadeTo:create(0.2, 255 * 0.6)
    )
end
--[[
关闭动画
--]]
function PopTeamStageRewardsView:CloseAction()
    local viewData = self:GetViewData()
    self.eaterLayer:runAction(
        cc.FadeOut:create(0.1)
    )
    self:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.1),
            cc.CallFunc:create(function()
                local scene = app.uiMgr:GetCurrentScene()
                scene:RemoveDialog(self)
            end)
        )
    )
end
--[[
获取viewData
--]]
function PopTeamStageRewardsView:GetViewData()
    return self.viewData
end
return PopTeamStageRewardsView