---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2019/4/4 2:44 PM
---

---@class ExchangeActivityCardView
local ExchangeActivityCardView = class('ExchangeActivityCardView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.exchange.ExchangeActivityCardView'
    node:enableNodeEvents()
    node:setAnchorPoint(display.CENTER)
    return node
end)
local GoodNode = require('common.GoodNode')
local RES_DICT = {
    ACTIVITY_DEBRIS_BG               = _res("ui/home/activity/exchangeCard/activity_debris_bg.png"),
    ACTIVITY_DEBRIS_BTN_ADD          = _res("ui/home/activity/exchangeCard/activity_debris_btn_add.png"),
    ACTIVITY_DEBRIS_BTN_MINUS        = _res("ui/home/activity/exchangeCard/activity_debris_btn_minus.png"),
    ACTIVITY_DEBRIS_EXCHANGE         = _res("ui/home/activity/exchangeCard/activity_debris_exchange.png"),
    ACTIVITY_DEBRIS_EXCHANGE_BG      = _res("ui/home/activity/exchangeCard/activity_debris_exchange_bg.png"),
    ACTIVITY_DEBRIS_GOODS_BG_DEFAULT = _res("ui/home/activity/exchangeCard/activity_debris_goods_bg_default.png"),
    ACTIVITY_DEBRIS_GOODS_BG_SELECT  = _res("ui/home/activity/exchangeCard/activity_debris_goods_bg_select.png"),
    ACTIVITY_DEBRIS_ICON_UR          = _res("ui/home/activity/exchangeCard/activity_debris_icon_ur.png"),
    ACTIVITY_DEBRIS_LIST_BG          = _res("ui/home/activity/exchangeCard/activity_debris_list_bg.png"),
    ACTIVITY_DEBRIS_Q_MIFAN          = _res("ui/home/activity/exchangeCard/activity_debris_q_mifan.png"),
    ACTIVITY_DEBRIS_RUMBER_BG        = _res("ui/home/activity/exchangeCard/activity_debris_rumber_bg.png"),
    ACTIVITY_DEBRIS_RUMBER_BG_SHADOW = _res("ui/home/activity/exchangeCard/activity_debris_rumber_bg_shadow.png"),
    COOKING_LEVEL_UP_ICO_ARROW       = _res("ui/home/activity/exchangeCard/cooking_level_up_ico_arrow.png"),
}

function ExchangeActivityCardView:ctor( ... )
    local function CreateView()
        local bgSize = cc.size(1075,616)
        local bgLayout = display.newLayer(display.cx ,display.cy  , {ap = display.CENTER , size = bgSize})
        local swallowLayout  = display.newLayer(bgSize.width/2 ,bgSize.height/2  , {ap = display.CENTER , size = bgSize , color =cc.c4b(0,0,0,0) , enable = true })
        bgLayout:addChild(swallowLayout)

        local bgImage = display.newImageView(RES_DICT.ACTIVITY_DEBRIS_BG , bgSize.width/2 , bgSize.height/2 )
        bgLayout:addChild(bgImage)

        local exchangeRichLabel = display.newRichLabel(bgSize.width -20 , bgSize.height - 35 , { ap = display.RIGHT_CENTER , c = {
            fontWithColor(14, {text = ""})
        }})
        bgLayout:addChild(exchangeRichLabel)

        local titleLabel = display.newLabel( bgSize.width /2, bgSize.height - 30 ,   fontWithColor(14, {outline = false ,  ap = display.CENTER ,color = '#5b3c25'  , text = __('飨灵碎片兑换商店') }))
        bgLayout:addChild(titleLabel)
        local centerSize = cc.size(1064 , 420 )
        local centerLayout = display.newLayer(bgSize.width/2 , bgSize.height - 60 , {ap  = display.CENTER_TOP, size = centerSize })
        bgLayout:addChild(centerLayout)

        local centerBgImage = display.newImageView(RES_DICT.ACTIVITY_DEBRIS_LIST_BG , centerSize.width/2 , centerSize.height/2 )
        centerLayout:addChild(centerBgImage)

        local gridViewSize = cc.size(centerSize.width  , centerSize.height -25  )
        local gridView = CGridView:create(gridViewSize)
        gridView:setSizeOfCell(cc.size(178, 180))
        gridView:setDirection(eScrollViewDirectionVertical)
        gridView:setPosition(centerSize.width/2 , 20 )
        gridView:setColumns(6)
        centerLayout:addChild(gridView, 10)
        gridView:setAnchorPoint(display.CENTER_BOTTOM)

        local bottomSize = cc.size(1064 , 160 )
        local bottomLayout = display.newLayer( bgSize.width/2 , 3 , {ap = display.CENTER_BOTTOM , size = bottomSize })
        bgLayout:addChild(bottomLayout)

        local bottomImage = display.newImageView(RES_DICT.ACTIVITY_DEBRIS_EXCHANGE_BG , bottomSize.width/2 , bottomSize.height/2 ,{ap = display.CENTER})
        bottomLayout:addChild(bottomImage)

        local exchangeSize = cc.size(439, 105 )
        local exchangeLayout = display.newLayer( 140  , bottomSize.height/2 + 7  , {ap = display.LEFT_CENTER , size = exchangeSize , color = cc.c4b(0,0,0,0)})
        local exchangeImage = display.newImageView( RES_DICT.ACTIVITY_DEBRIS_EXCHANGE , exchangeSize.width/2 , exchangeSize.height/2 , {ap = display.CENTER})
        exchangeLayout:addChild(exchangeImage)
        bottomLayout:addChild(exchangeLayout)

        local distanceWith = 52
        local leftLabel = display.newRichLabel(distanceWith, -20 , {c = {
            fontWithColor(16 , {text = ""})
        }})
        exchangeLayout:addChild(leftLabel)
        local exchangeDetail = display.newLabel(exchangeSize.width/2 , exchangeSize.height/2 , fontWithColor(16, {text = ''}))
        exchangeLayout:addChild(exchangeDetail)
        local arrowImageTable = {}
        for i = 1, 3 do
            local arrowImage = display.newImageView(RES_DICT.COOKING_LEVEL_UP_ICO_ARROW , exchangeSize.width /2 - 45 - 15 * (4- i) , exchangeSize.height/2 )
            exchangeLayout:addChild(arrowImage)
            arrowImageTable[#arrowImageTable+1] = arrowImage
        end
        for i = 1, 3 do
            local arrowImage = display.newImageView(RES_DICT.COOKING_LEVEL_UP_ICO_ARROW , exchangeSize.width /2 + 45 + 15 * i , exchangeSize.height/2 )
            exchangeLayout:addChild(arrowImage)
            arrowImageTable[#arrowImageTable+1] = arrowImage
        end


        local rightLabel = display.newRichLabel(exchangeSize.width - distanceWith, -20 , {  c = {
            fontWithColor(16 , {text = ":"})
        }})
        exchangeLayout:addChild(rightLabel)

        local leftGoodNode =GoodNode.new({goodsId = GOLD_ID})
        exchangeLayout:addChild(leftGoodNode)
        leftGoodNode:setPosition(distanceWith ,exchangeSize.height/2+2)
        leftGoodNode.fragmentImg:setTexture(_res('common/common_ico_fragment_4.png'))
        leftGoodNode.icon:setTexture(RES_DICT.ACTIVITY_DEBRIS_ICON_UR)
        local rightGoodNode =GoodNode.new({goodsId = GOLD_ID})
        exchangeLayout:addChild(rightGoodNode)
        rightGoodNode:setPosition(exchangeSize.width - distanceWith ,exchangeSize.height/2+2)
        rightGoodNode:setScale(0.85)
        leftGoodNode:setScale(0.85)
        exchangeLayout:setVisible(false)
        local exchangeBtn = display.newButton(bottomSize.width - 237 , bottomSize.height/2 +  7  , { n = _res('ui/common/common_btn_orange')})
        display.commonLabelParams(exchangeBtn , fontWithColor(14 , {text = __('兑换')}))
        bottomLayout:addChild(exchangeBtn)


        local exchangeLabel = display.newLabel(bottomSize.width - 237 , 15 ,fontWithColor('6' , {text = ""}) )
        bottomLayout:addChild(exchangeLabel)

        return {
            bgLayout = bgLayout ,
            gridView = gridView ,
            leftGoodNode = leftGoodNode ,
            exchangeLabel = exchangeLabel ,
            rightGoodNode = rightGoodNode ,
            leftLabel = leftLabel ,
            rightLabel = rightLabel,
            exchangeLayout = exchangeLayout,
            exchangeBtn = exchangeBtn,
            arrowImageTable = arrowImageTable,
            centerLayout = centerLayout,
            exchangeRichLabel = exchangeRichLabel,
            exchangeDetail = exchangeDetail
        }
    end

    xTry(function ( )
        local viewData = CreateView()
        self.viewData = viewData
        local view = CLayout:create(display.size)
        self:addChild(view,2)
        view:setPosition(display.center)
        view:addChild(viewData.bgLayout , 2)
        local swallowLayer = display.newLayer(display.cx , display.cy , { ap = display.CENTER,  color = cc.c4b(0,0,0,175) , enable = true})
        view:addChild(swallowLayer)
        self.viewData.swallowLayer = swallowLayer

    end, __G__TRACKBACK__)

end
--==============================--
---@Description: 更新UI
---@param selectNum number 当前的选中的数量
---@param exchangeId number 兑换的id
---@parma totalNum number 总的兑换数量 
---@param exchangeNum number 已经兑换数量
---@param ratioNum number 兑换比率
---@author : xingweihao
---@date : 2019/4/4 5:35 PM
--==============================--
function ExchangeActivityCardView:UpdateUI(selectNum , exchangeId , totalNum , exchangeNum ,ratioNum   )
    self:UpdateExchageCardNum(selectNum ,ratioNum )
    self:UpdateUpdateExchangeId(exchangeId)
    self:UpdateExchageNum(totalNum , exchangeNum)
    self:UpdateExchangeRatio(ratioNum ,exchangeId)
    self:RunActionArrow()
end
function ExchangeActivityCardView:RunActionArrow()
    local interval = 0.5
    for i = 1 ,6 do
        local icon_Up = self.viewData.arrowImageTable[i]
        icon_Up:setOpacity(0)
        icon_Up:runAction(cc.Sequence:create(
                cc.DelayTime:create(interval*i ) , cc.CallFunc:create(
                        function ()
                                icon_Up:stopAllActions()
                                icon_Up:runAction(cc.RepeatForever:create(
                                        cc.Sequence:create(cc.FadeIn:create(1.5 *2),cc.FadeOut:create(1.5*2))
                                )
                            )
                        end
                )
        ) )
    end
end
function ExchangeActivityCardView:UpdateExchangeRatio( ratioNum,exchangeId )
    display.commonLabelParams(self.viewData.exchangeDetail , fontWithColor(16 , {text = string.fmt(__('_num1_兑_num2_') , {_num1_ = ratioNum ,_num2_ = 1 })}))
    local cardFragmentConf = CommonUtils.GetConfigAllMess('cardFragment' , 'goods')
    display.reloadRichLabel(self.viewData.exchangeRichLabel , {
        c= {
            fontWithColor('16', {text = __('兑换规则:')  }),
            fontWithColor('10', {text = string.fmt(__('_num1_张') , {_num1_ = ratioNum }) }),
            fontWithColor('16', {text = __('UR碎片=') }),
            fontWithColor('10', {text = __('1个')}),
            fontWithColor('16', {text = cardFragmentConf[tostring(exchangeId)].name }),
        }
    })
end
--==============================--
---@Description: 更新兑换的卡牌碎片
---@param exchangeId number 兑换的id
---@author : xingweihao
---@date : 2019/4/4 5:35 PM
--==============================--
function ExchangeActivityCardView:UpdateUpdateExchangeId(exchangeId )
    local viewData = self.viewData
    viewData.rightGoodNode:RefreshSelf({goodsId = exchangeId })
    viewData.exchangeLayout:setVisible(true)
end
--==============================--
---@Description: 更新可以兑换的数量
---@param selectNum number 选中的碎片
---@author : xingweihao
---@date : 2019/4/4 5:35 PM
--==============================--
function ExchangeActivityCardView:UpdateExchageCardNum(selectNum , exchangeFragementNum )
    selectNum = checkint(selectNum)
    local viewData = self.viewData
    display.reloadRichLabel(viewData.rightLabel , { c= {
        fontWithColor(16 , {text = __('可获得：')}),
        fontWithColor(10 , {text = math.floor(selectNum/exchangeFragementNum)})
    }})

    display.reloadRichLabel(viewData.leftLabel , { c= {
        fontWithColor(16 , {text = __('已经选择碎片：')}),
        fontWithColor(10 , {text = selectNum })
    }})
end

--==============================--
---@Description: 更新可以兑换次数
---@param totalNum number 总的兑换次数
---@param exchangeNum number 已经兑换的次数
---@author : xingweihao
---@date : 2019/4/4 5:35 PM
--==============================--
function ExchangeActivityCardView:UpdateExchageNum(totalNum , exchangeNum )
    totalNum = checkint(totalNum)
    local viewData = self.viewData
   display.commonLabelParams(viewData.exchangeLabel , fontWithColor(16, {text = string.fmt(__('可兑换数量 _num1_ / _num2_'),{ _num1_ =  totalNum - exchangeNum  , _num2_ =  totalNum} ) }))
end

function ExchangeActivityCardView:CreateEmptyView()
    local centerLayout = self.viewData.centerLayout
    local centerLayoutSize = centerLayout:getContentSize()

    if not  self.viewData.emptyLabel then
        local emptyLabel = display.newRichLabel(centerLayoutSize.width/2 , centerLayoutSize.height - 10 , { r = true ,
            c= { {img = _res('arts/cartoon/card_q_3.png') , scale = 0.8, ap = cc.p(0.0,0.5)},
                    fontWithColor('14', { fontSize = 30 , ap = cc.p(-10,0), text = __('暂无UR碎片')})
                }})
        centerLayout:addChild(emptyLabel,1000)
        self.viewData.emptyLabel = emptyLabel
        CommonUtils.AddRichLabelTraceEffect(self.viewData.emptyLabel )
    else
        self.viewData.emptyLabel:setVisible(true)
    end
end
return ExchangeActivityCardView