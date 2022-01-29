--[[
个人设置 其他页签View
--]]
---@class PersonOtherView
local PersonOtherView = class('home.PersonOtherView',function ()
    local node = CLayout:create( cc.size(982,562) ) --cc.size(984,562)
    node.name = 'Game.views.PersonOtherView'
    node:enableNodeEvents()
    return node
end)
local BUTTON_CLICK = {
   CUSTOM_SERVICE    = 1001, -- 客服
   FAQ               = 1002, -- 问题解答
   RANK              = 1003, -- 排行榜
   POLICY            = 1004, -- 用户协议
   HIDE_VIDEO_BTN    = 1005, -- 录像按钮隐藏
   FB                = 1006, -- 跳转到FB
   DISCORD           = 1007, -- 跳转到DISCORD
}
local BUTTON_TYPE = {
    DEFAULT = 'white_default',
    DISABLE = 'orange_disable'
}
local ICON_PATH = {
    ACHIEVEMENT = 'achievement'
}
local isEURegion = checkint(AppFacade.GetInstance():GetManager("GameManager"):GetUserInfo().isEURegion)
local BUTTON_DATA = {
    {name = __('客服'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.CUSTOM_SERVICE, isShow = true},
    {name = __('F&Q'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.FAQ, isShow = true},
    -- {name = __('成就'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.RANK, isShow = true},
    {name = __('用户协议'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.POLICY, isShow = ( isEURegion == 1 ) or (isEURegion == 2)},
    -- {name = __('录像按钮隐藏'), buttonType = BUTTON_TYPE.DISABLE, tag = BUTTON_CLICK.HIDE_VIDEO_BTN, isShow = true},
}
function PersonOtherView:ctor()
    local isAvailable = require('root.AppSDK').GetInstance():isReplayKitAvailable()
    if isAvailable then
        --ios平台
        if isNewUSSdk() then
            BUTTON_DATA = {
                -- {name = __('客服'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.CUSTOM_SERVICE, isShow = true},
                -- {name = __('F&Q'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.FAQ, isShow = true},
                -- {name = __('成就'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.RANK, isShow = true},
                -- {name = __('用户协议'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.POLICY, isShow = checkint(AppFacade.GetInstance():GetManager("GameManager"):GetUserInfo().isEURegion) == 1},
                -- {name = __('录像按钮隐藏'), buttonType = BUTTON_TYPE.DISABLE, tag = BUTTON_CLICK.HIDE_VIDEO_BTN, isShow = true},
                {name = __('录像按钮开启'), buttonType = BUTTON_TYPE.DISABLE, tag = BUTTON_CLICK.HIDE_VIDEO_BTN, isShow = true},
            }
        elseif isElexSdk() then
            BUTTON_DATA = {
                {name = __('客服'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.CUSTOM_SERVICE, isShow = true},
                {name = __('F&Q'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.FAQ, isShow = true},
                {name = __('成就'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.RANK, isShow = true},
                {name = __('用户协议'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.POLICY, isShow = true },
                {name ="FaceBook", buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.FB, isShow = true},
                {name ="Discord" , buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.DISCORD, isShow = true},
                -- {name = __('录像按钮隐藏'), buttonType = BUTTON_TYPE.DISABLE, tag = BUTTON_CLICK.HIDE_VIDEO_BTN, isShow = true},
                {name = __('录像按钮开启'), buttonType = BUTTON_TYPE.DISABLE, tag = BUTTON_CLICK.HIDE_VIDEO_BTN, isShow = true},

            }
        end     
    else
        --否则是android平台而且如果是google平台的时候才显示成就的逻辑
        if checkint(Platform.id) == ElexAndroid or checkint(Platform.id) == ElexIos then
            BUTTON_DATA = {
                {name = __('客服'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.CUSTOM_SERVICE, isShow = true},
                {name = __('F&Q'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.FAQ, isShow = true},
                {name = __('成就'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.RANK, isShow = true, iconPath = ICON_PATH.ACHIEVEMENT},
                {name = __('用户协议'), buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.POLICY, isShow = true},
                {name ="FaceBook", buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.FB, isShow = true},
                {name ="Discord" , buttonType = BUTTON_TYPE.DEFAULT, tag = BUTTON_CLICK.DISCORD, isShow = true},
            }
        end
    end

    self:initUI()
end

function PersonOtherView:initUI()
    local layoutSize = cc.size(982,562)
    local view = display.newLayer(layoutSize.width/2 , layoutSize.height/2,{ ap =  display.CENTER , size = layoutSize,  enable  = true })
    self:addChild(view)
    -- 按钮
    local buttons = {}
    local num = 0
    for i, v in ipairs(BUTTON_DATA) do
        if v.isShow then
            num = num + 1
            local path = string.format('ui/common/common_btn_%s_2.png', v.buttonType)
            local btn = display.newButton(layoutSize.width/2, layoutSize.height + 20 - 85 * num, {n = _res(path) , scale9 = true , size = cc.size(250 , 62)})
            btn:setTag(v.tag)
            display.commonLabelParams(btn, fontWithColor(14, {text = v.name , w = 185 , hAlign = display.TAC , h = 45 }))
            if v.iconPath then
                local iconPath = string.format('ui/common/icon_%s.png', v.iconPath)
                local iconImage = ui.image({img = iconPath, scale9 = true , size = cc.size(48, 48)})
                btn:addList(iconImage):alignTo(nil, ui.lc)
            end
            view:addChild(btn)
            table.insert(buttons, btn)
        end
    end

    self.viewData =  {
        view    = view,
        buttons = buttons,
    }
end
return PersonOtherView
