---
--- Created by xingweihao.
--- DateTime: 16/08/2017 12:00 PM
---
---@class PurchaseLiveView :Node
local PurchaseLiveView = class('PurchaseLiveView',
function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.PurchaseLiveView'
    node:enableNodeEvents()
    return node
end
)
local RES_DICT = {
    BTN_CANCEL  = _res("ui/common/common_btn_white_default.png") ,
    BG_IMAGE  = _res('ui/tower/ready/result_bg_black.png') ,
    BG_BLACK =  _res('ui/tower/ready/result_bg_fail_revive.png') ,
    BTN_SURE =  _res("ui/common/common_btn_green.png"),
}

local BUTTON_TAG = {
    CANCEL_BTN  = 1 ,
    PURCHASELIVE_BTN  = 2 ,
    CLOSE_BTN = 3 ,
}
function PurchaseLiveView:ctor()
    self.purchaseLiveData = CommonUtils.GetConfigAllMess('towerBuyLiveConsume', "tower") -- 购买次数
    self:initUi()
end

function PurchaseLiveView:initUi()
    --吞噬曾
    local swallowLayer = display.newLayer(display.cx, display.cy, { ap = display.CENTER  ,size = display.size ,color = cc.c4b(0,0,0,100) ,enable = true ,cb = function ()
        self:removeFromParent()
    end })
    self:addChild(swallowLayer)
    local bgSize = cc.size(920, 480)
    local bgLayout = CLayout:create(bgSize)
    bgLayout:setPosition(cc.p(display.cx, display.cy))
    self:addChild(bgLayout,2)
    -- 内部的吞噬层
    local contentSwallow = display.newLayer(bgSize.width/2,bgSize.height, {ap = display.CENTER , size = bgSize ,color = cc.c4b(0,0,0,0)  ,enable = true } )
    bgLayout:addChild(contentSwallow)
    --添加背景图片
    local bgImage = display.newImageView(RES_DICT.BG_IMAGE)
    local bgImageSize = bgImage:getContentSize()
    local bgImageLayout = CLayout:create(bgImageSize)
    bgImage:setPosition(cc.p(bgImageSize.width/2 , bgImageSize.height/2))
    bgImageLayout:addChild(bgImage)
    bgImageLayout:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
    bgLayout:addChild(bgImageLayout)
    local topLabel = display.newLabel(bgImageSize.width/2 , bgImageSize.height- 30, fontWithColor(9, { text = __('是否消耗幻晶石复活所有的飨灵继续战斗?')}))
    bgImageLayout:addChild(topLabel)
    -- 下面的label 创建
    local bottomLable =  display.newLabel(bgImageSize.width/2 , 30, fontWithColor(9, { text = "今日剩余购买次数：2" , color = "fbe2c0" , fontSize = 22}))
    bgImageLayout:addChild(bottomLable)
    local blackImage = display.newImageView(RES_DICT.BG_BLACK, bgImageSize.width/2, 50 ,{ ap = display.CENTER_BOTTOM})
    bgImageLayout:addChild(blackImage)
    -- 取消的按钮 放弃复活
    local btnCancel = display.newButton(bgSize.width/2 -187, 50, { n = RES_DICT.BTN_CANCEL ,s = RES_DICT.BTN_CANCEL ,enable = true })
    bgLayout:addChild(btnCancel)
    display.commonLabelParams(btnCancel, fontWithColor('14',{ text = __('放弃')}) )
    -- 确定复活
    local makeSureBtn =  display.newButton(bgSize.width/2 +187, 50, { n = RES_DICT.BTN_SURE ,s = RES_DICT.BTN_SURE ,enable = true } )
    bgLayout:addChild(makeSureBtn)
    local  btnSize  = makeSureBtn:getContentSize()
    local diamondRichLabel = display.newRichLabel(btnSize.width/2, btnSize.height/2,  {c = { fontWithColor('14', { text =  "  "})}  })
    makeSureBtn:addChild(diamondRichLabel)
    btnCancel:setTag( BUTTON_TAG.CANCEL_BTN )
    makeSureBtn:setTag( BUTTON_TAG.PURCHASELIVE_BTN)
    swallowLayer:setTag( BUTTON_TAG.CLOSE_BTN)
    self.viewData = {
        bottomLable = bottomLable ,
        makeSureBtn = makeSureBtn ,
        btnCancel = btnCancel ,
        diamondRichLabel = diamondRichLabel ,
        swallowLayer = swallowLayer
    }
end
--[[
    更新界面的信息
--]]
function PurchaseLiveView:UpdateView(data)

    local times =  data.residueTime or 0
    if times == 0  then
        display.commonLabelParams(self.viewData.bottomLable, { text = string.format(__('今日剩余购买次数：%d' , times))})
        display.reloadRichLabel(self.viewData.diamondRichLabel, { c = {  fontWithColor(14, { text =  __("确定")  })  }})
    else
        local time = data.currentTime
        local purchaseData = self.purchaseLiveData[tostring(time)]
        if not purchaseData then
            return
        else
            display.commonLabelParams(self.viewData.bottomLable, { text = string.format(__('今日剩余购买次数：%d') , times)})
            display.reloadRichLabel(self.viewData.diamondRichLabel, { c = {  fontWithColor(14, { text = purchaseData.consumeNum  } ) , 
                { img = CommonUtils.GetGoodsIconPathById(purchaseData.consume) ,scale = 0.2 }  }})
        end

    end




end
return PurchaseLiveView
