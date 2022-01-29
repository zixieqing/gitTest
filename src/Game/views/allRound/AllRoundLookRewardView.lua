---@class AllRoundLookRewardView
local AllRoundLookRewardView = class('AllRoundLookRewardView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.allRound.AllRoundLookRewardView'
    node:enableNodeEvents()
    return node
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newNSprite = display.newNSprite
local newButton = display.newButton
local newLayer = display.newLayer
local RES_DICT = {
    COMMON_BG_9                   = _res('ui/common/common_bg_9.png'),
    COMMON_BG_TITLE_2             = _res('ui/common/common_bg_title_2.png'),
    COMMON_RECORD_BG_AVATOR       = _res('ui/common/common_bg_goods.png'),
}
function AllRoundLookRewardView:ctor( param )
    local param = param or {}
    local routeId =  param.routeId or 1
    self.routeId = routeId
    self:InitUI()
    self:CreateGoodNode()
end
function AllRoundLookRewardView:InitUI()
    local view = newLayer(display.cx, display.cy,{ap = display.CENTER, size = display.size})
    local closeLayer = newLayer(display.cx , display.cy , { ap = display.CENTER, color = cc.c4b(0,0,0, 175),  size = cc.size(display.width, display.height), enable = true , cb = function()
                                  self:removeFromParent()
    end })
    view:addChild(closeLayer)
    self:addChild(view)
    local contentLayer = newLayer(667, 375,
                                  { ap = display.CENTER, size = cc.size(450, 547) })
    contentLayer:setPosition(display.cx + 0, display.cy + 0)
    view:addChild(contentLayer)

    local sawallowLayer = newLayer(0, 0,
                                   { ap = display.LEFT_BOTTOM, color = cc.r4b(0), size = cc.size(450, 547), enable = true })
    contentLayer:addChild(sawallowLayer)

    local bgImage = newNSprite(RES_DICT.COMMON_BG_9, 225, 273,
                               { ap = display.CENTER, tag = 918 })
    bgImage:setScale(1, 1)
    contentLayer:addChild(bgImage)

    local bottomImage = newImageView(RES_DICT.COMMON_RECORD_BG_AVATOR, 225, 242,
                                     { ap = display.CENTER, tag = 924, enable = false, scale9 = true, size = cc.size(384, 432) })
    contentLayer:addChild(bottomImage)
    local titleNameTable = {
        __('日常路线'),
        __('战斗路线'),
        __('经营路线'),
        __('堕神路线'),
    }
    local titleBtn = newButton(228, 526, { ap = display.CENTER ,  n = RES_DICT.COMMON_BG_TITLE_2, d = RES_DICT.COMMON_BG_TITLE_2, s = RES_DICT.COMMON_BG_TITLE_2})
    display.commonLabelParams(titleBtn, {text =titleNameTable[checkint(self.routeId)], fontSize = 24, color = '#ffffff'})
    contentLayer:addChild(titleBtn)

    local closeLabel = newLabel(222, -15,
                                { ap = display.CENTER, color = '#ffffff', text = __('点击空白处关闭'), fontSize = 20, tag = 922 })
    closeLabel:setPosition(222, -15)
    contentLayer:addChild(closeLabel)
    local str =  __('完成所有任务可得：')
    if checkint(self.routeId )~= 5 then
        str =  string.format(__('完成%s的所有任务可获得：') ,titleNameTable[checkint(self.routeId)] )
    end
    local descrLabel = newLabel(22, 484,
                                fontWithColor(6, { ap = cc.p(-0.100000 ,0.500000) ,text = str, fontSize = 20, tag = 925 }))
    descrLabel:setPosition(22, 484)
    contentLayer:addChild(descrLabel)

    local rewardLayout = newLayer(225, 242,
                                  { ap = display.CENTER, size = cc.size(384, 432) })
    contentLayer:addChild(rewardLayout)

    self.viewData =  {
        closeLayer              = closeLayer,
        contentLayer            = contentLayer,
        sawallowLayer           = sawallowLayer,
        bgImage                 = bgImage,
        bottomImage             = bottomImage,
        titleBtn                = titleBtn,
        closeLabel              = closeLabel,
        descrLabel              = descrLabel,
        rewardLayout            = rewardLayout,
    }
end
function AllRoundLookRewardView:CreateGoodNode()
    local rewardLayout = self.viewData.rewardLayout
    local rewardLayoutSize = rewardLayout:getContentSize()
    local goodNodeWidth = (rewardLayoutSize.width -20 )/ 3
    local goodNodeHeight = 110
    local rewardConfig = CommonUtils.GetConfigAllMess('reward' , 'cardCall')
    local  rewards = rewardConfig[tostring(self.routeId)].rewards
    local  count = #rewards
    for i = 1, count do
        rewards[i].showAmount = true
        local goodNode = require('common.GoodNode').new(rewards[i])
        local  index = i - 0.5
        local  lineY =   math.floor(index / 3)
        local  lineX =index % 3
        display.commonUIParams(goodNode, {animate = false,  cb = function(sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = rewards[i].goodsId, type = 1})
        end})
        goodNode:setPosition( goodNodeWidth  * lineX  + 10  , 432 -  goodNodeHeight  * (  (lineY +  0.5) ) -10 )
        goodNode:setScale(0.9)
        rewardLayout:addChild(goodNode)
    end
end

return AllRoundLookRewardView