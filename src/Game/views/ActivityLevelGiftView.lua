---
--- Created by xingweihao.
--- DateTime: 16/10/2017 5:39 PM
---
--[[
限时超得活动view
--]]
---@class ActivityLevelGiftView
local ActivityLevelGiftView = class('ActivityLevelGiftView', function ()
    local node = CLayout:create(cc.size(1035, 637))
    node:setAnchorPoint(cc.p(0, 0))
    node.name = 'home.ActivityLevelGiftView'
    node:enableNodeEvents()
    return node
end)
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
    local bgSize = cc.size(1035, 637)
    local view = CLayout:create(bgSize)
    -- 背景
    local bg = display.newImageView(_res('ui/home/activity/activity_bg_mifan.png'), bgSize.width/2, bgSize.height/2)
    view:addChild(bg, 1)
    -- 标题
    local title = display.newImageView(_res('ui/home/activity/activity_mifan_ttile.png'), 220, bgSize.height - 60 )
    view:addChild(title, 10)
    -- 标题
    local roleImage  = display.newImageView(_res('ui/home/activity/activity_mifan_2.png'), 5 , bgSize.height /2-4 , { ap = display.LEFT_CENTER} )
    view:addChild(roleImage, 9 )
    -- 活动规则
    local acivityButton  = display.newButton(20,170, { n = _res('ui/home/activity/activity_exchange_bg_rule_title.png') ,enable = true , scale9 = true , ap = display.LEFT_CENTER  } )
    display.commonLabelParams(acivityButton, fontWithColor('14',{text= __('活动规则') , offset = cc.p( -15, 0) ,paddingW = 30}) )
    view:addChild(acivityButton, 9 )
    -- 规则图片
    local ruleImage = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule.png'), bgSize.width/2 +  0.5, 5, { ap = display.CENTER_BOTTOM} )
    view:addChild(ruleImage, 9 )


    local ruleImageSize = ruleImage:getContentSize()
    local listSize = cc.size(550, 500)
    local gridLayout = display.newLayer(bgSize.width -5, bgSize.height + 5, { size = listSize , ap = display.RIGHT_TOP})
    view:addChild(gridLayout,10)

    -- 下面的灰色底板
    local baseboard =  display.newImageView(_res('ui/home/activity/activity_mifan_black_1.png'), listSize.width, listSize.height/2, { ap = display.RIGHT_CENTER} )
    gridLayout:addChild(baseboard)
    -- 上面的灰色蒙版
    local baseboardtwo =  display.newImageView(_res('ui/home/activity/activity_mifan_black_2.png'), listSize.width , listSize.height/2, { ap = display.RIGHT_CENTER} )
    gridLayout:addChild(baseboardtwo,11)

    local listCellSize = cc.size(260, 500)
    local gridView = CTableView:create(listSize)
    gridView:setSizeOfCell(listCellSize)
    gridView:setAutoRelocate(true)
    gridView:setDirection(eScrollViewDirectionHorizontal)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setPosition(cc.p(listSize.width /2 , listSize.height /2))
    gridLayout:addChild(gridView, 10)
    -- 活动规则
    local ruleLabel  = display.newLabel(0,0 ,fontWithColor('18', { fontSize = 22, ap =  display.CENTER , w = 970,hAlign = display.TAL, text = __('等级达到10级后解锁等级礼包。每个等级礼包只能购买一次，礼包首次出现时，会有12小时的打折活动，一旦超过12小时，打折活动即会消失，但等级礼包仍可购买。（购买等级礼包，也可以享受首充奖励的福利。）') } )  )
    --ruleImage:addChild(ruleLabel)

    local ruleSize = display.getLabelContentSize( ruleLabel)
    local ruleLayout  = display.newLayer(0, 0,{size = ruleSize ,ap = cc.p(0, 1)})
    ruleLayout:addChild(ruleLabel)
    ruleLabel:setPosition(ruleSize.width/2 ,ruleSize.height/2)
    local listViewSize = cc.size(970 , 130)
    local listView = CListView:create(listViewSize)
    listView:setBounceable(true )
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setAnchorPoint(display.LEFT_TOP)
    listView:setPosition(34, 142)
    view:addChild(listView  , 10 )
    listView:insertNodeAtLast(ruleLayout)
    listView:reloadData()

    return {
        view 	  = view,
        ruleLayout = ruleLayout ,
        listView  = listView ,
        gridView = gridView ,
    }
end
--创建cell
function ActivityLevelGiftView:CreateGridCell()
    local gridCell = CTableViewCell:new()
    local gridSize = cc.size(260 , 500)
    gridCell:setContentSize(gridSize)
    -- 背景图片
    local bgImage =  display.newImageView(_res('ui/home/activity/activity_mifan_sale_bg.png'))
    local bgSize = bgImage:getContentSize()
    bgImage:setPosition(cc.p(bgSize.width/2 , bgSize.height/2))
    -- 背景的图片

    local bgLayot = display.newLayer(gridSize.width/2 ,gridSize.height/2, { ap = display.CENTER , size = bgSize })
    bgLayot:addChild(bgImage)
    gridCell:addChild(bgLayot)
    bgLayot:setPosition(cc.p(gridSize.width/2 ,gridSize.height/2))
    -- 标题的名称
    local titleImage = display.newButton(bgSize.width/2 , bgSize.height -13 , { n =  _res('ui/home/activity/mifan_title_level.png') ,enale = false , ap = display.CENTER_TOP })
    bgLayot:addChild(titleImage)
    display.commonLabelParams(titleImage, fontWithColor('18',{ color = "#ffffff" , text = ""}))
    local goodsLayoutSize =  cc.size(215, 285 )
    -- 道具存放的内容
    local goodsLayout = display.newLayer(bgSize.width/2 , bgSize.height -50 , { size = goodsLayoutSize  , ap = display.CENTER_TOP } )
    bgLayot:addChild(goodsLayout)
    local qAvatar = sp.SkeletonAnimation:create(_res('effects/dengjilibao_effect.json'), 'effects/dengjilibao_effect.atlas', 1.0)
    qAvatar:setPosition(utils.getLocalCenter(bgLayot))
    qAvatar:setToSetupPose()
    qAvatar:setAnimation(0, 'idle', true)
    bgLayot:addChild(qAvatar)
    qAvatar:setVisible(false)

    -- 折扣的label
    local disCountImage = display.newButton(0, 140, { n =  _res('ui/home/commonShop/shop_tag_sale.png'), s=  _res('ui/home/commonShop/shop_tag_sale.png') ,s =  _res('ui/home/commonShop/shop_tag_sale.png')  , enable = false ,scale9  = true , size = cc.size(140,35) ,ap =display.LEFT_CENTER})
    bgLayot:addChild(disCountImage)
    local onlyOneLabel = display.newLabel(120, 110 , fontWithColor('11',{ ap = display.LEFT_CENTER , text = __('(限购1次)')}) )
    bgLayot:addChild(onlyOneLabel)
    disCountImage:setVisible(false)

    -- 购买按钮
    local buyBtn = display.newButton( 0, 0 , { n = _res("ui/common/common_btn_orange.png") ,size = cc.size(140,60) ,scale9 = true } )
    local buyBtnSize = buyBtn:getContentSize()
    local buyBtnLayout = display.newLayer(bgSize.width/2 ,65, {ap = display.CENTER , size = buyBtnSize} )
    buyBtn:setPosition(cc.p(buyBtnSize.width/2 , buyBtnSize.height/2))
    buyBtnLayout:addChild(buyBtn)
    bgLayot:addChild(buyBtnLayout)
    -- 价格
    local priceLabel = display.newLabel(buyBtnSize.width/4 , buyBtnSize.height/2 , fontWithColor('6' , {text =  '￥30',ap = display.CENTER})  )
    buyBtnLayout:addChild(priceLabel)
    local lineImage = display.newImageView(_res('ui/home/commonShop/shop_sale_line.png'), buyBtnSize.width/4 , buyBtnSize.height/2 )
    buyBtnLayout:addChild(lineImage )
    lineImage:setScaleX(0.5)
    -- 折扣价格
    local discountPriceLabel = display.newLabel(buyBtnSize.width*3/4 , buyBtnSize.height/2 , fontWithColor('14' , {text =  '￥30' ,fontSize = 26 ,ap = display.CENTER, outlineSize = 1}))
    buyBtnLayout:addChild(discountPriceLabel)
    -- 倒计时时间
    local countTimeLabel = display.newRichLabel(bgSize.width/2 , 22 , {  c= { fontWithColor('6',{text = "daddasd"})}})
    bgLayot:addChild(countTimeLabel)

    --购买的label
    local buyLabel = display.newLabel(buyBtnSize.width/2 , buyBtnSize.height/2 , fontWithColor('14' ,{ text = __('已购买') , fontSize =22 , outline = false }) )
    buyBtnLayout:addChild(buyLabel)
    buyLabel:setVisible(false)
    -- 蒙版
    local blockLayer = display.newImageView(_res('ui/home/activity/activity_mifan_by_bg.png') ,bgSize.width/2 , bgSize.height/2 )
    bgLayot:addChild(blockLayer)
    blockLayer:setVisible(false)

    gridCell.bgLayot = bgLayot
    gridCell.titleImage = titleImage
    gridCell.goodsLayout = goodsLayout
    gridCell.bgImage = bgImage
    gridCell.priceLabel = priceLabel
    gridCell.discountPriceLabel = discountPriceLabel
    gridCell.countTimeLabel = countTimeLabel
    gridCell.buyLabel = buyLabel
    gridCell.blockLayer = blockLayer
    gridCell.buyBtn = buyBtn
    gridCell.disCountImage = disCountImage
    gridCell.onlyOneLabel = onlyOneLabel
    gridCell.titleImage = titleImage
    gridCell.bgSize = bgSize
    gridCell.lineImage = lineImage
    gridCell.qAvatar = qAvatar
    return gridCell

end
--- 更新cell表
function ActivityLevelGiftView:UpdateCell(gridCell , data)
    -- 首次要重置数据
    gridCell.priceLabel:setVisible(false)
    gridCell.discountPriceLabel:setVisible(false)
    gridCell.countTimeLabel:setVisible(false)
    gridCell.blockLayer:setVisible(false)
    gridCell.buyLabel:setVisible(false)
    gridCell.disCountImage:setVisible(false)
    gridCell.onlyOneLabel:setVisible(false)
    gridCell.lineImage:setVisible(false)
    gridCell.qAvatar:setVisible(false)
    data = data or {}
    display.commonLabelParams(gridCell.titleImage ,fontWithColor('10',{fontSize = 22 , color = "ffffff"  , text = string.format(__('%d级特惠礼包') , checkint(data.openLevel))}) )
    if display.getLabelContentSize(gridCell.titleImage:getLabel()).width > 180 then
        display.commonLabelParams(gridCell.titleImage ,fontWithColor('10',{fontSize = 20 , color = "ffffff", reqW = 180 , hAlign = display.TAC   , text = string.format(__('%d级特惠礼包') , checkint(data.openLevel))}) )
    end
    if gameMgr:GetUserInfo().level >= checkint(data.openLevel) then
        gridCell.buyBtn:setEnabled(true)
        if checkint(data.hasPurchased)   == 0  then    -- 是否购买
            local originalPrice = tostring(data.price)
            local discountPrice = tostring(data.discountPrice)
            local priceData = {}
            if isElexSdk() then
                priceData= clone(data)
                priceData.originalPrice = data.price
                priceData.price = priceData.discountPrice
                discountPrice , originalPrice = CommonUtils.GetCurrentAndOriginPriceDByPriceData(priceData)
            end
            if checkint(data.discountLeftSeconds) > 0  or  checkint(data.discountLeftSeconds) == -1 then -- 在折扣的时间内


                local buyBtnSize = gridCell.buyBtn:getContentSize()
                gridCell.lineImage:setVisible(true)
                if isElexSdk() then
                    if CommonUtils.IsGoldSymbolToSystem() then
                        CommonUtils.SetCardNameLabelStringByIdUseSysFont(gridCell.discountPriceLabel ,nil ,{fontSizeN = 24 , colorN = "ffffff" } , discountPrice)
                        CommonUtils.SetCardNameLabelStringByIdUseSysFont(gridCell.priceLabel , nil,{fontSizeN = 24 , colorN = "ffffff" } , originalPrice)
                    else
                        gridCell.priceLabel:setString(originalPrice )
                        gridCell.discountPriceLabel:setString( discountPrice)
                    end
                else
                    if CommonUtils.IsGoldSymbolToSystem() then
                        CommonUtils.SetCardNameLabelStringByIdUseSysFont(gridCell.discountPriceLabel ,nil ,{fontSizeN = 24 , colorN = "ffffff" } , __("￥") .. discountPrice)
                        CommonUtils.SetCardNameLabelStringByIdUseSysFont(gridCell.priceLabel , nil,{fontSizeN = 24 , colorN = "ffffff" } , string.format(__("￥%s") ,originalPrice ))
                    else
                        gridCell.priceLabel:setString(string.format(__("￥%s") , originalPrice ) )
                        gridCell.discountPriceLabel:setString( __("￥") .. discountPrice )
                    end
                end
                gridCell.discountPriceLabel:setPosition(cc.p(buyBtnSize.width * 3/4  , buyBtnSize.height/2 ))
                --gridCell.discountPriceLabel:setString( __("￥") .. tostring(data.discountPrice))
                gridCell.bgImage:setTexture(_res('ui/home/activity/activity_mifan_sale_bg.png'))
                self:SetButtonImage(gridCell.buyBtn , _res("ui/common/common_btn_orange.png") )
                self:SetButtonImage(gridCell.titleImage,_res('ui/home/activity/mifan_title_level.png'))

                display.commonLabelParams(gridCell.disCountImage, fontWithColor( '14',{ap = display.LEFT_CENTER ,reqH = 140 , text = string.format(__('%s折' ),  CommonUtils.GetDiscountOffFromCN(data.discount))}))
                gridCell.disCountImage:getLabel():setPosition(cc.p(5, 17 ))

                gridCell.qAvatar:setVisible(true)
                gridCell.onlyOneLabel:setAnchorPoint(display.CENTER)
                gridCell.onlyOneLabel:setPosition(cc.p(gridCell.bgSize.width/2  , 110))
                gridCell.disCountImage:setVisible(true)
                gridCell.onlyOneLabel:setVisible(true)
                gridCell.buyBtn:setVisible(true)
                gridCell.priceLabel:setVisible(true)
                gridCell.discountPriceLabel:setVisible(true)
                gridCell.discountPriceLabel:setAnchorPoint(cc.p(0.6, 0.5))
                if  checkint(data.discountLeftSeconds) > 0 then
                    gridCell.countTimeLabel:setVisible(true)
                    display.reloadRichLabel(gridCell.countTimeLabel , { c= {
                        fontWithColor('6',{text = __('限时折扣  ')} ) ,
                        fontWithColor('10',{text = string.formattedTime(data.discountLeftSeconds, "%02i:%02i:%02i")} )
                    } })
                    gridCell.countTimeLabel:runAction(cc.RepeatForever:create(
                            cc.Sequence:create(
                                    cc.DelayTime:create(1) , cc.CallFunc:create(function ()
                                        display.reloadRichLabel(gridCell.countTimeLabel , { c= {
                                            fontWithColor('6',{text = __('限时折扣  ')} ) ,
                                            fontWithColor('10',{text = string.formattedTime(data.discountLeftSeconds, "%02i:%02i:%02i")} )
                                        } })
                                        if checkint(data.discountLeftSeconds)   ==  0  then
                                            self:UpdateCell(gridCell, data)
                                        end
                                    end)
                            )
                    ))
                else
                    gridCell.countTimeLabel:setVisible(false)
                end
            else -- 在折扣的范围内
                -- 设置价格的位置
                if isElexSdk() then
                    if CommonUtils.IsGoldSymbolToSystem() then
                        CommonUtils.SetCardNameLabelStringByIdUseSysFont(gridCell.discountPriceLabel , nil,{fontSizeN = 24 , colorN = "ffffff" , outline = '#734441'} , originalPrice)
                    else
                        gridCell.discountPriceLabel:setString(originalPrice)
                    end
                else
                    if CommonUtils.IsGoldSymbolToSystem() then
                        CommonUtils.SetCardNameLabelStringByIdUseSysFont(gridCell.discountPriceLabel , nil,{fontSizeN = 24 , colorN = "ffffff" , outline = '#734441'} , string.format(__("￥%s") ,originalPrice ))
                    else
                        gridCell.discountPriceLabel:setString(string.format(__("￥%s") ,originalPrice))
                    end
                end
                gridCell.discountPriceLabel:setVisible(true)

                local buyBtnSize = gridCell.buyBtn:getContentSize()
                gridCell.discountPriceLabel:setPosition(cc.p(buyBtnSize.width/2 , buyBtnSize.height/2))
                gridCell.onlyOneLabel:setVisible(true)
                gridCell.onlyOneLabel:setAnchorPoint(display.CENTER)
                gridCell.onlyOneLabel:setPosition(cc.p(gridCell.bgSize.width/2 , 110))
                gridCell.discountPriceLabel:setPosition(cc.p(buyBtnSize.width/2 , buyBtnSize.height/2))
                gridCell.bgImage:setTexture(_res('ui/home/activity/activity_mifan_bg.png'))
                self:SetButtonImage(gridCell.buyBtn , _res("ui/common/common_btn_orange.png") )
                self:SetButtonImage(gridCell.titleImage,_res('ui/home/activity/mifan_title_level.png'))
            end
        elseif checkint(data.hasPurchased) == 1 then -- 已经够买的显示
            gridCell.buyBtn:setEnabled(false)
            self:SetButtonImage(gridCell.buyBtn , _res("ui/home/activity/activity_mifan_by_ico.png") )
            gridCell.bgImage:setTexture(_res('ui/home/activity/activity_mifan_unlock_bg.png'))
            gridCell.buyLabel:setString(__('已购买'))
            gridCell.buyLabel:setVisible(true)
            gridCell.blockLayer:setVisible(true)
            self:SetButtonImage(gridCell.titleImage,_res('ui/home/activity/mifan_title_unlock.png'))
        end
    else  -- 等级尚未达到的时候
        local buyBtnSize = gridCell.buyBtn:getContentSize()
        gridCell.discountPriceLabel:setVisible(true)
        gridCell.discountPriceLabel:setPosition(cc.p(buyBtnSize.width/2 , buyBtnSize.height/2))
        gridCell.discountPriceLabel:setString("???")
        gridCell.buyBtn:setEnabled(false)
        self:SetButtonImage(gridCell.buyBtn,_res('ui/common/common_btn_orange_disable.png'))
        gridCell.bgImage:setTexture(_res('ui/home/activity/activity_mifan_unlock_bg.png'))

    end
    self:needGoods(gridCell,data.rewards)
end
function ActivityLevelGiftView:SetButtonImage(btn , str)
    btn:setNormalImage(str)
    btn:setSelectedImage(str)
    btn:setDisabledImage(str)
end
-- 创建数据
function ActivityLevelGiftView:needGoods(gridCell, data)
    local contentLayout = gridCell.goodsLayout
    contentLayout:removeAllChildren()
    data = data or {}
    local countNum = table.nums(data)
    if countNum > 0  then
        local bgSize = cc.size(215, 285 )
        local width = bgSize.width/2
        local height = bgSize.height /3
        for k ,v  in  pairs(data)  do
            local goodNode = require('common.GoodNode').new({id = v.goodsId,num = v.num, showAmount = true})
            goodNode:setAnchorPoint(cc.p(0.5,0.5))
            goodNode:setPosition(cc.p(  (width * ((k - 0.5)  %2) ), bgSize.height - height * ( 0.5 + math.floor((k - 0.5)/2  )) ) )
            goodNode:setScale(0.8)
            display.commonUIParams(goodNode, {animate = false, cb = function (sender)
                uiMgr:AddDialog("common.GainPopup", {goodId = v.goodsId})
            end})
            contentLayout:addChild(goodNode, 10)
        end

    end
end

function ActivityLevelGiftView:ctor( ... )
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view, 1)
    self.viewData_.view:setPosition(utils.getLocalCenter(self))
end


return ActivityLevelGiftView
