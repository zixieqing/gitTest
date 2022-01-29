--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）信件view
--]]
local MurderMailView = class('MurderMailView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.murder.MurderMailView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    MAIL_BG      = app.murderMgr:GetResPath('ui/home/activity/murder/murder_open_bg.png'),
    MAIL_LINE    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_open_line_1.png'),
    COMMON_BTN_N = app.murderMgr:GetResPath('ui/common/common_btn_orange.png'),

}
function MurderMailView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function MurderMailView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local bg = display.newImageView(RES_DICT.MAIL_BG, size.width / 2, size.height / 2 - 45)
        view:addChild(bg, 1)

        local mailLayoutSize = cc.size(730, 520)
        local mailLayout = CLayout:create(mailLayoutSize)
        mailLayout:setPosition(cc.p(size.width / 2 - 60, size.height / 2 - 25))
        view:addChild(mailLayout, 1)
        local textLabel = display.newLabel(55, mailLayoutSize.height - 50, {text = app.murderMgr:GetPoText(__('时间分秒流失，\n在那不曾停止的滴答声中，\n又封存着多少不为人知的秘密呢？')), color = '#ffcc86', fontSize = 24, w = 605, ap = display.LEFT_TOP})
        mailLayout:addChild(textLabel, 3)
        local descrLabel = display.newLabel(55, 210, {text = app.murderMgr:GetPoText(__('信里附上了这些：')), fontSize = 20, color = '#dcc7a9', ap = display.LEFT_CENTER})
        mailLayout:addChild(descrLabel, 3)
        local line = display.newImageView(RES_DICT.MAIL_LINE, mailLayoutSize.width / 2, 195)
        mailLayout:addChild(line, 1)
        local drawBtn = display.newButton(mailLayoutSize.width - 130, 120, {n = RES_DICT.COMMON_BTN_N})
        mailLayout:addChild(drawBtn, 5)
        display.commonLabelParams(drawBtn, fontWithColor(14, {text = app.murderMgr:GetPoText(__('领取'))}))
        return {
            view             = view,
            mailLayout       = mailLayout,
            mailLayoutSize   = mailLayoutSize,
            drawBtn          = drawBtn,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:AddMailRewards()
    end, __G__TRACKBACK__)
end
--[[
信封奖励预览
--]]
function MurderMailView:AddMailRewards()
    local viewData = self:GetViewData()
    -- 奖励材料为第一次升级所需的材料
    local config = CommonUtils.GetConfig('newSummerActivity', 'building', 1)
    local consume = config.consume
    for i, v in ipairs(checktable(consume)) do
        local goodsNode = require('common.GoodNode').new({
			id = v.goodsId,
			amount = v.num,
			showAmount = true,
			callBack = function (sender)
				PlayAudioByClickNormal()
				app.uiMgr:ShowInformationTipsBoard({
					targetNode = sender, iconId = checkint(v.goodsId), type = 1	
				})
            end
        })
        goodsNode:setPosition(cc.p(-10 + 120 * i, 120))
        viewData.mailLayout:addChild(goodsNode, 10) 
    end
end
--[[
获取viewData
--]]
function MurderMailView:GetViewData()
    return self.viewData
end
return MurderMailView