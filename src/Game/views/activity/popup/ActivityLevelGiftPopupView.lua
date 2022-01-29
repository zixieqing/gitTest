--[[
活动弹出页 首充 view
--]]
local ActivityLevelGiftPopupView = class('ActivityLevelGiftPopupView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.ActivityLevelGiftPopupView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG                              = _res('ui/home/activity/activity_open_bg_mifan.png'),
    BACK_BTN                        = _res('ui/home/activity/activity_open_btn_quit.png'),
    RULE_BG                         = _res('ui/home/activity/activity_open_bg_rule.png'),
    RULE_LINE                       = _res('ui/home/activity/activity_open_line_rule.png'),
}
function ActivityLevelGiftPopupView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function ActivityLevelGiftPopupView:InitUI()
    local function CreateView()
        local bgSize = cc.size(1269, 804)
        local view = CLayout:create(bgSize)
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, bgSize.width/2, bgSize.height/2)
        view:addChild(bg, 1)
        -- 标题
        local title = display.newImageView(_res('ui/home/activity/activity_mifan_ttile.png'), 240, 208)
        view:addChild(title, 10)

        local listSize = cc.size(674, 500)
        local gridLayout = display.newLayer(bgSize.width - 90, bgSize.height - 155, { size = listSize , ap = display.RIGHT_TOP})
        view:addChild(gridLayout,10)
    
        local listCellSize = cc.size(260, 500)
        local gridView = CTableView:create(listSize)
        gridView:setSizeOfCell(listCellSize)
        gridView:setAutoRelocate(true)
        gridView:setDirection(eScrollViewDirectionHorizontal)
        gridView:setAnchorPoint(display.CENTER)
        gridView:setPosition(cc.p(listSize.width /2 , listSize.height /2))
        gridLayout:addChild(gridView, 10)
        -- 活动规则
        local descrBg = display.newImageView(RES_DICT.RULE_BG, bgSize.width / 2 + 20, 30, {ap = display.CENTER_BOTTOM})
        view:addChild(descrBg, 1)
        local descrLine = display.newImageView(RES_DICT.RULE_LINE, 155, descrBg:getContentSize().height / 2)
        descrBg:addChild(descrLine, 1)
        local descrLabel = display.newLabel(80, descrBg:getContentSize().height / 2, {text = __('规则说明'), fontSize = 20, color = '#ffbf50'})
        descrBg:addChild(descrLabel)
        local descrViewSize  = cc.size(980, 70)
        local descrContainer = cc.ScrollView:create()
        descrContainer:setPosition(cc.p(230, 40))
        descrContainer:setDirection(eScrollViewDirectionVertical)
        descrContainer:setAnchorPoint(display.LEFT_BOTTOM)
        descrContainer:setViewSize(descrViewSize)
        view:addChild(descrContainer, 1)
    
        local adWordsTipLabel = display.newLabel(20, 160, fontWithColor(18, {w = 980, text = __('等级达到10级后解锁等级礼包。每个等级礼包只能购买一次，礼包首次出现时，会有12小时的打折活动，一旦超过12小时，打折活动即会消失，但等级礼包仍可购买。（购买等级礼包，也可以享受首充奖励的福利。）')}))
        descrContainer:setContainer(adWordsTipLabel)
        local descrScrollTop = descrViewSize.height - display.getLabelContentSize(adWordsTipLabel).height
        descrContainer:setContentOffset(cc.p(0, descrScrollTop))
        -- 返回按钮
        local backBtn = display.newButton(bgSize.width - 50, bgSize.height - 145, {n = RES_DICT.BACK_BTN})
        view:addChild(backBtn, 10)
        return {
            view 	  = view,
            gridView  = gridView,
            backBtn   = backBtn,
        }
    end
    xTry(function ( )
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
        eaterLayer:setContentSize(display.size)
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setPosition(utils.getLocalCenter(self))
        self.eaterLayer = eaterLayer
        self:addChild(eaterLayer, -1)
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
创建cell
--]]
function ActivityLevelGiftPopupView:CreateGridCell()
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
    local disCountImage = display.newButton(5, 125, { n =  _res('ui/home/commonShop/shop_tag_sale.png'), s=  _res('ui/home/commonShop/shop_tag_sale.png') , enable = false , ap =display.LEFT_CENTER})
    bgLayot:addChild(disCountImage)
    local onlyOneLabel = display.newLabel(120, 125 , fontWithColor('11',{ ap = display.LEFT_CENTER , text = __('(限购1次)')}) )
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
    local priceLabel = display.newLabel(buyBtnSize.width/4 , buyBtnSize.height/2 , fontWithColor('6' , {ap = display.CENTER})  )
    buyBtnLayout:addChild(priceLabel)
    local lineImage = display.newImageView(_res('ui/home/commonShop/shop_sale_line.png'), buyBtnSize.width/4 , buyBtnSize.height/2 )
    buyBtnLayout:addChild(lineImage )
    lineImage:setScaleX(0.5)
    -- 折扣价格
    local discountPriceLabel = display.newLabel(buyBtnSize.width*3/4 , buyBtnSize.height/2 , fontWithColor('14' , {fontSize = 26 ,ap = display.CENTER, outlineSize = 1}))
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
--[[
更新cell表
--]]
function ActivityLevelGiftPopupView:UpdateCell(gridCell , data)
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
    display.commonLabelParams(gridCell.titleImage ,fontWithColor('10',{fontSize = 22 , color = "ffffff" , text = string.format(__('%d级特惠礼包') , checkint(data.openLevel))}) )
    if app.gameMgr:GetUserInfo().level >= checkint(data.openLevel) then
        gridCell.buyBtn:setEnabled(true)
        if checkint(data.hasPurchased)   == 0  then    -- 是否购买
            if checkint(data.discountLeftSeconds) > 0  or  checkint(data.discountLeftSeconds) == -1 then -- 在折扣的时间内
                local buyBtnSize = gridCell.buyBtn:getContentSize()
                gridCell.lineImage:setVisible(true)
                gridCell.priceLabel:setString(string.format(__("￥%s") ,tostring(data.price) ) )
                gridCell.discountPriceLabel:setPosition(cc.p(buyBtnSize.width * 3/4  , buyBtnSize.height/2 ))
                gridCell.discountPriceLabel:setString( __("￥") .. tostring(data.discountPrice))
                gridCell.bgImage:setTexture(_res('ui/home/activity/activity_mifan_sale_bg.png'))
                self:SetButtonImage(gridCell.buyBtn , _res("ui/common/common_btn_orange.png") )
                self:SetButtonImage(gridCell.titleImage,_res('ui/home/activity/mifan_title_level.png'))
                display.commonLabelParams(gridCell.disCountImage ,fontWithColor('14', {text = string.format(__('%s折' ), tostring(checkint(data.discount) / 10))
                }) )
                gridCell.qAvatar:setVisible(true)
                gridCell.onlyOneLabel:setVisible(true)
                gridCell.onlyOneLabel:setAnchorPoint(display.LEFT_CENTER)
                gridCell.onlyOneLabel:setPosition(cc.p(120  , 125))
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
                gridCell.discountPriceLabel:setString(string.format(__("￥%s") ,tostring(data.price) ) )
                gridCell.discountPriceLabel:setVisible(true)

                local buyBtnSize = gridCell.buyBtn:getContentSize()
                gridCell.discountPriceLabel:setPosition(cc.p(buyBtnSize.width/2 , buyBtnSize.height/2))
                gridCell.onlyOneLabel:setVisible(true)
                gridCell.onlyOneLabel:setAnchorPoint(display.CENTER)
                gridCell.onlyOneLabel:setPosition(cc.p(gridCell.bgSize.width/2 , 125))
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
function ActivityLevelGiftPopupView:SetButtonImage(btn , str)
    btn:setNormalImage(str)
    btn:setSelectedImage(str)
    btn:setDisabledImage(str)
end
--[[
创建数据
--]]
function ActivityLevelGiftPopupView:needGoods(gridCell, data)
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
                app.uiMgr:AddDialog("common.GainPopup", {goodId = v.goodsId})
            end})
            contentLayout:addChild(goodNode, 10)
        end

    end
end
--[[
获取viewData
--]]
function ActivityLevelGiftPopupView:GetViewData()
    return self.viewData
end
--[[
进入动画
--]]
function ActivityLevelGiftPopupView:EnterAction()
    local viewData = self:GetViewData()
	viewData.view:setScale(0.8)
	viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.25, 1)
			)
		)
	)
end
return ActivityLevelGiftPopupView