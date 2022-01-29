--[[
 * author : liuzhipeng
 * descpt : 活动 全能活动View
--]]
local ActivityAllRoundView = class('ActivityAllRoundView', function()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.allRound.ActivityAllRoundView'
    node:enableNodeEvents()
    return  node
end)

local RES_DICT = {
    COMMON_TITLE                    = _res('ui/common/common_title.png'),
    COMMON_TIPS                     = _res('ui/common/common_btn_tips.png'),
    COMMON_BTN_BACK                 = _res('ui/common/common_btn_back.png'),
    BG                              = _res('ui/artifact/card_weapon_bg.jpg'),
    BG_CIRCLE_BIG                   = _res('ui/artifact/card_weapon_bg_circle_1'),
    BG_CIRCLE_SMALL                 = _res('ui/artifact/card_weapon_bg_circle_2'),
    ALLROUND_ICO_BOOK_1             = _res('ui/home/allround/allround_ico_book_1.png'),
    ALLROUND_ICO_BOOK_2             = _res('ui/home/allround/allround_ico_book_2.png'),
    ALLROUND_ICO_BOOK_3             = _res('ui/home/allround/allround_ico_book_3.png'),
    ALLROUND_ICO_BOOK_4             = _res('ui/home/allround/allround_ico_book_4.png'),
    -- spine --
}
function ActivityAllRoundView:ctor( ... )
    self:InitUI()
end
--[[
初始化ui
--]]
function ActivityAllRoundView:InitUI()
    local CreateView = function ()
        local size = display.size
        local view = CLayout:create(size)
        view:setPosition(size.width / 2, size.height / 2)
        -- 返回按钮
        local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
                {
                    ap = display.LEFT_CENTER,
                    n = RES_DICT.COMMON_BTN_BACK,
                    scale9 = true, size = cc.size(90, 70),
                    enable = true,
                })
        view:addChild(backBtn, 10)
        -- 标题板
        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('活动收集'), fontSize = 30, color = '#473227',offset = cc.p(0,-10)})
        self:addChild(tabNameLabel, 20)
        -- 提示按钮
        local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 29)
        tabNameLabel:addChild(tabtitleTips, 1)
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- 背景的圆圈
        local circleB = display.newImageView(RES_DICT.BG_CIRCLE_BIG, size.width / 2, size.height / 2)
        circleB:setScale(2)
        view:addChild(circleB, 2)
        local circleS = display.newImageView(RES_DICT.BG_CIRCLE_SMALL, size.width / 2, size.height / 2)
        circleS:setScale(2)
        view:addChild(circleS, 2)
        circleB:runAction(
            cc.RepeatForever:create(
                cc.Spawn:create(
                        cc.TargetedAction:create( circleS, cc.RotateBy:create(10,-180)),
                        cc.RotateBy:create(10,180)
                )
            )
        )
        return {
            view                = view,
            backBtn             = backBtn,
            tabNameLabel        = tabNameLabel,
            bg                  = bg,  
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ()
        self.viewData = CreateView()
        self:addChild(self.viewData.view)
    end, __G__TRACKBACK__)
end
--[[
创建奖励layout
@params pathList list 路线数据
@params activityId int 活动id
@return nodeList list 节点列表
--]]
function ActivityAllRoundView:CreatePathLayout( pathList, activityId )
    local nodeList = {}
    local view = self:GetViewData().view
    for i, v in ipairs(pathList or {}) do
        local pathNode = require('Game.views.activity.allRound.ActivityAllRoundPathNode').new({pathData = v, activityId = activityId})
        view:addChild(pathNode, 5)
        table.insert(nodeList, pathNode)
    end
    return nodeList
end
--[[
获取viewData
--]]
function ActivityAllRoundView:GetViewData()
    return self.viewData
end
return ActivityAllRoundView