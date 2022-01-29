---
--- Created by xingweihao.
--- DateTime: 25/10/2017 3:29 PM
---
---@class ExchangeView
local ExchangeView = class('home.ExchangeView',function ()
    local node = CLayout:create( cc.size(982,562) ) --cc.size(984,562)
    node.name = 'Game.views.ExchangeView'
    node:enableNodeEvents()
    return node
end)
local BUTTON_CLICK = {
   INPUT_EXCHANGE = 100011 ,
   MAKE_SURE = 100022,
}

function ExchangeView:ctor()
    self:initUI()
end

function ExchangeView:initUI()
    -- body
    --local closeLayer = display.newLayer(display.cx, display.cy ,{ ap =  display.CENTER , size = display.size , color = cc.c4b(0,0,0,0 ) , enable  = true ,cb = function ()
    --    self:removeFromParent()
    --end})
    --closeLayer:setPosition(display.center)
    --self:addChild(closeLayer)
    local layoutSize = cc.size(982,562)
    local layout = display.newLayer(layoutSize.width/2 , layoutSize.height/2,{ ap =  display.CENTER , size = layoutSize,  enable  = true })
    -- 背景图片
    local bgImageOne = display.newImageView(_res("ui/home/infor/agent_bg_code.png") )

    -- 内容的content
    local contentSize = bgImageOne:getContentSize()
    bgImageOne:setPosition(contentSize.width/2 ,contentSize.height/2 )
    local contentLayout = display.newLayer(layoutSize.width/2 , layoutSize.height/2 + 45 , { ap  = display.CENTER, size =  contentSize})
    contentLayout:addChild(bgImageOne)
    layout:addChild(contentLayout)

    -- 兑换按钮
    local  makeSureBtn  =display.newButton(contentSize.width/2,60 ,{n = _res('ui/common/common_btn_orange.png'), ap = display.CENTER } )
    contentLayout:addChild(makeSureBtn)
    display.commonLabelParams(makeSureBtn , fontWithColor('14',{text = __('确认') }) )
    makeSureBtn:setTag(BUTTON_CLICK.MAKE_SURE)


    local editBoxBg = display.newImageView(_res('ui/home/market/market_main_bg_research.png'))
    local editBoxBgSize = editBoxBg:getContentSize()

    local editBoxLayout = display.newLayer(contentSize.width/2 , 132 , { ap = display.CENTER_BOTTOM , size = editBoxBgSize })
    editBoxBg:setPosition(cc.p(editBoxBgSize.width/2 , editBoxBgSize.height/2))
    editBoxLayout:addChild(editBoxBg)
    local editBox = ccui.EditBox:create(cc.size(295, 35), 'empty')
    display.commonUIParams(editBox, {po = cc.p(4 , editBoxBgSize.height/2),ap = cc.p(0,0.5)})
    editBox:setFontSize(22)
    editBox:setTag(BUTTON_CLICK.INPUT_EXCHANGE)
    editBox:setFontColor(ccc3FromInt('#4c4c4c'))
    editBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    editBox:setPlaceHolder(__('输入关键字'))
    editBox:setPlaceholderFontSize(22)
    editBox:setPlaceholderFontColor(ccc3FromInt('#4c4c4c'))
    editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    editBox:setMaxLength(10)
    editBoxLayout:addChild(editBox)
    contentLayout:addChild(editBoxLayout)

    local label = display.newLabel(contentSize.width/2 + 20 , 130, { color = "#ba5c5c", fontSize = 26 ,
        ap = display.CENTER_BOTTOM , text = __('输入兑换码，领取礼品奖励'), w = 400, h = 120}  )
    contentLayout:addChild(label)

    --基本设置标签
    self:addChild(layout)
    self.viewData =  {
        view = layout ,
        contentLayout = contentLayout,
        makeSureBtn  =makeSureBtn ,
        editBox = editBox
    }
end
return ExchangeView
