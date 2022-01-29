--[[
活动重置剧情tips
@params table {
    title string 标题
    rewards table 奖励
    consume table 消耗
    isGray bool 按钮是置灰
    callback function 按钮回调   
}
--]]
local ActivityMapChestPopup = class('ActivityMapChestPopup', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activityMap.ActivityMapChestPopup'
    node:enableNodeEvents()
    return node
end)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
function ActivityMapChestPopup:ctor( ... )
    self.args = unpack({...})
    self.title = self.args.title
    self.rewards = checktable(self.args.rewards)
    self.consume = checktable(self.args.consume)
    self.isGray = self.args.isGray
    self.callback = self.args.callback
    self:InitUI()
end
--[[
init ui
--]]
function ActivityMapChestPopup:InitUI()
	  local function CreateView()
		    local bg = display.newImageView(_res('ui/common/common_bg_7.png'), 0, 0, {enable = true})
        local bgSize = bg:getContentSize()
        local view = CLayout:create(bgSize)
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        view:addChild(bg, 1)
        local title = display.newButton(bgSize.width/2, bgSize.height - 20, {enable = false, n = _res("ui/common/common_bg_title_2.png")})
        view:addChild(title, 10)
        display.commonLabelParams(title, fontWithColor(18, {text = __('关卡名称')}))
        -- 奖励预览 --
        local rewardLayoutSize = cc.size(505, 197)
        local rewardLayout = CLayout:create(rewardLayoutSize)
        rewardLayout:setPosition(cc.p(bgSize.width/2, bgSize.height - 148))
        view:addChild(rewardLayout, 3)
        local rewardLayoutBg = display.newImageView(_res('ui/common/common_bg_list_3.png'), rewardLayoutSize.width/2, rewardLayoutSize.height/2, {scale9 = true, size = rewardLayoutSize})
        rewardLayout:addChild(rewardLayoutBg, 1)
        local rewardLayoutLabel = display.newLabel(rewardLayoutSize.width/2, rewardLayoutSize.height - 28, fontWithColor(16, {text = __('奖励预览')}))
        rewardLayout:addChild(rewardLayoutLabel, 3)
        -- 奖励
        local previewLayoutSize = cc.size(#self.rewards * 108 + (#self.rewards - 1) * 14, 110)
        local previewLayout = CLayout:create(previewLayoutSize)
        previewLayout:setPosition(rewardLayoutSize.width/2, 84)
        rewardLayout:addChild(previewLayout, 5)
        for i, v in ipairs(self.rewards) do
            local goodsNode = require('common.GoodNode').new({
                id = v.goodsId,
                showAmount = true,
                amount = v.num,
                callBack = function (sender)
                    uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
                end
            })
            goodsNode:setAnchorPoint(0, 0.5)
            goodsNode:setPosition(cc.p(122 * (i - 1), previewLayoutSize.height/2))
            previewLayout:addChild(goodsNode)
        end
        -- 需求道具 --
        local consumeTitle = display.newButton(bgSize.width/2, 250, {enable = false, n = _res("ui/common/common_title_3.png")})
        view:addChild(consumeTitle, 5)
        display.commonLabelParams(consumeTitle, fontWithColor(16, {text = __('需要材料'), reqW = 140}))
        -- consumeLayout
        local consumeGoodsScale = 0.8
        local goodsSize = cc.size(108, 108)
        local wordSpace = 24
        local consumeLayoutSize = cc.size(#self.consume * 108 * consumeGoodsScale + (#self.consume - 1) * wordSpace, 120)
        local consumeLayout = CLayout:create(consumeLayoutSize)
        consumeLayout:setPosition(bgSize.width/2, 180)
        view:addChild(consumeLayout, 5)
        for i, v in ipairs(self.consume) do
            local goodsNode = require('common.GoodNode').new({
                id = v.goodsId,
                showAmount = false,
                callBack = function (sender)
                    AppFacade.GetInstance():GetManager("UIManager"):AddDialog("common.GainPopup", {goodId = v.goodsId})
                end
            })
            goodsNode:setScale(consumeGoodsScale)
            goodsNode:setAnchorPoint(0, 0.5)
            goodsNode:setPosition(cc.p((goodsSize.width * consumeGoodsScale + wordSpace) * (i - 1), consumeLayoutSize.height/2))
            consumeLayout:addChild(goodsNode)
            local hasNums = checkint(gameMgr:GetAmountByGoodId(v.goodsId))
            local colorKey = hasNums < checkint(v.num) and 10 or 16
            local richLabel = display.newRichLabel(goodsSize.width * consumeGoodsScale / 2 + (goodsSize.width * consumeGoodsScale + wordSpace) * (i - 1), 4,
                {ap = cc.p(0.5, 0.5), r = true, c = {
                    fontWithColor(colorKey, {text = hasNums}),
                    fontWithColor(16, {text = '/' .. tostring(v.num)})
                }
            })
            consumeLayout:addChild(richLabel)
        end
        local drawBtn = display.newButton(bgSize.width/2, 64, {n = _res('ui/common/common_btn_orange.png')})
        view:addChild(drawBtn, 5)
        display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('打开')}))
   		  return {
			      view     = view,
            drawBtn  = drawBtn
	      }
	  end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
    end)
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(display.center)
        self.viewData_.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
    end, __G__TRACKBACK__)
end
function ActivityMapChestPopup:DrawButtonCallback( sender )
    if self.callback then
        self.callback(sender)
        self:runAction(cc.RemoveSelf:create())
    end
end

return ActivityMapChestPopup