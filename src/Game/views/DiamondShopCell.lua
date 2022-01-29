---
--- Created by xingweihao.
--- DateTime: 18/08/2017 6:21 PM
---
---@class DiamondShopCell
local DiamondShopCell = class('Game.views.DiamondShopCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'Game.views.DiamondShopCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function DiamondShopCell:ctor(...)
    local arg = {...}
    self.type = 1 or 2
    local size = arg[1] or cc.size(208 , 256)
    self:setContentSize(size)
    self:setPosition(display.center)
    self:setAnchorPoint(display.CENTER)


    local toggleView = display.newButton(size.width * 0.5,size.height * 0.5,{--
        n = _res('ui/home/commonShop/shop_btn_diamonds_default.png') , scale9 = true
    })
    if arg[2] then
        toggleView:setContentSize(cc.size(size.width - 5 , size.height - 10 ) )
    end
    self.toggleView = toggleView
    local size = toggleView:getContentSize()
    toggleView:setPosition(cc.p(size.width/2 , size.height/2))
    local eventNode =  display.newLayer(0, 0, { ap = display.CENTER , size = size  })
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    self.eventnode:addChild(self.toggleView)

    -- 刷新时间
    local refreshLabel = display.newLabel(15, size.height - 5, {text = __('剩余时间'), fontSize = 22, color = '#5b3c25', ap = display.LEFT_TOP})
    refreshLabel:setVisible(false)
    self:addChild(refreshLabel)
    local refreshTimeLabel = display.newLabel(size.width * 0.75, size.height - 5, {text = '00:00:00', fontSize = 22, color = '#d23d3d', ap = display.CENTER_TOP})
    refreshTimeLabel:setVisible(false)
    self:addChild(refreshTimeLabel)
    self.refreshLabel = refreshLabel
    self.refreshTimeLabel = refreshTimeLabel

    -- 中部幻晶石的包和光
    local lightPos = cc.p(size.width/2 , size.height/2 + 20 )
    local lightImage = display.newImageView(_res('ui/home/commonShop/shop_recharge_light_red.png'), lightPos.x , lightPos.y+10)
    eventNode:addChild(lightImage)
    local goodNode = display.newImageView(_res('ui/home/commonShop/shop_diamonds_ico_1.png') ,lightPos.x , lightPos.y+10,{scale =  0.3} )
    eventNode:addChild(goodNode)
    --goodNode:setScale(0.25)
    self.lightImage = lightImage
    self.goodNode = goodNode


    --下部分的幻晶石
    local bg_Diamond = display.newImageView(_res("ui/home/commonShop/shop_bg_money_diamonds.png"), size.width/2, 3,{ ap = display.CENTER_BOTTOM})
    local bg_DiamondSize = bg_Diamond:getContentSize()
    self.eventnode:addChild(bg_Diamond)
    --local sellLabel = display.newLabel(bg_DiamondSize.width/2, bg_DiamondSize.height /2  ,
    --fontWithColor(14,{text = __('￥648') , ap = display.CENTER}))
    local sellLabel = display.newRichLabel(bg_DiamondSize.width/2, bg_DiamondSize.height/2, { c = {{fontSize = 28, color = 'ffffff', text = ""}}})
    self.eventnode:addChild(sellLabel)
    self.sellLabel = sellLabel

    -- 上部分的
    local tag_Double = display.newImageView(_res('ui/home/commonShop/shop_tag_double.png'), 0, size.height - 7 , { ap = display.LEFT_TOP })
    self.eventnode:addChild(tag_Double)
    local tag_DoubleSize = tag_Double:getContentSize()
    local firstBuyLabel = display.newLabel(tag_DoubleSize.width/2 - 10, tag_DoubleSize.height/2, fontWithColor('14', { fontSize = 20 , text = __('首充双倍')  , color = isJapanSdk() and "ffde21" or "ffffff", outline =  false}) )
    tag_Double:addChild(firstBuyLabel)
    local motherTab = display.newButton(0, size.height - 7 , {n= _res('ui/home/commonShop/shop_tag_double.png'), ap = display.LEFT_TOP , scale9 = true } )
    self.eventnode:addChild(motherTab)
    display.commonLabelParams(motherTab , fontWithColor('14', { fontSize = 20 , text = __('月卡')  , color = isJapanSdk() and "ffde21" or "ffffff", outline =  false , paddingW = 20 }))
    --local motherLabel = display.newLabel(tag_DoubleSize.width/2 - 10, tag_DoubleSize.height/2, fontWithColor('14', { fontSize = 20 , text = __('月卡')  , color = isJapanSdk() and "ffde21" or "ffffff", outline =  false}) )
    --motherTab:addChild(motherLabel)


    self.tag_Double = tag_Double
    self.motherTab = motherTab
    self.motherTab:setVisible(false)
    self.firstBuyLabel = firstBuyLabel
    self.tag_Double:setVisible(false)

    -- 管内简简洁的介绍
    local diamondLabel = display.newRichLabel(size.width/2, bg_DiamondSize.height +5,{ ap = display.CENTER_BOTTOM , r = true ,  c = {fontWithColor('8', { color = "8f715b" ,fontSize = 20 , text = __('首充额外赠送500')
        }) ,{ img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID) ,scale = 0.12 }}  })
    self.eventnode:addChild(diamondLabel)
    diamondLabel:setVisible(false)
    self.diamondLabel = diamondLabel
    -- 幻晶石的数量

    local fight_num = cc.Label:createWithBMFont('font/team_ico_fight_figure_2.fnt', '')--
    fight_num:setAnchorPoint(cc.p(0.5, 0.5))
    fight_num:setHorizontalAlignment(display.TAR)
    fight_num:setPosition(cc.p(bg_DiamondSize.width * 0.5 ,bg_DiamondSize.height*0.5))
    fight_num:setString("8888")
    fight_num:setVisible(false)
    fight_num:setScale(0.35)
    self.numLabel = fight_num
    local contentLayout = display.newLayer(size.width/2, 80, { ap = display.CENTER , size = cc.size(200, 40) })
    contentLayout:addChild(fight_num)
    self.eventnode:addChild(contentLayout)
    contentLayout:setVisible(false)
    local diamondImage = display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID))
    contentLayout:addChild(diamondImage)
    diamondImage:setAnchorPoint(display.CENTER)
    diamondImage:setPosition(cc.p(100 ,20))
    diamondImage:setScale(0.12)
    contentLayout:setVisible(true)
    self.diamondImage = diamondImage
    self.contentLayout = contentLayout
    self.fight_num = fight_num

    local purchargeLabel = display.newLabel(size.width * 0.5, size.height - 12,fontWithColor(7, {fontSize = 20, color = '6c6c6c', text = ''}))
    purchargeLabel:setName('NUMLABEL')
    self:addChild(purchargeLabel,80)
    purchargeLabel:setVisible(false)
    local priceHotImage = display.newImageView(_res('ui/home/commonShop/shop_tag_iconid_1'), size.width + 4, size.height, {
        ap = display.RIGHT_TOP})
    local priceHotLabel = display.newLabel(size.width-2 , size.height- 3,fontWithColor('14' , {ttf =  false , text = "", ap = display.RIGHT_TOP }))
    self:addChild(priceHotLabel,1235)
    priceHotLabel:setVisible(false)
    priceHotLabel:setName("HOTIMAGELABEL")
    self:addChild(priceHotImage, 1234)
    priceHotImage:setVisible(false)
    priceHotImage:setName('HOTIMAGE')
end
function DiamondShopCell:enableOutline(node,params)
    local collectElement = node:getChildren()
    for k , v in pairs (collectElement) do
        if tolua.type(v) == "ccw.CLabel" then
            local label = v
            if not  params then
                params = {}
                params.outline = "734441"
                params.outlineSize = 1
            end
            local outlineSize = math.max(1, checkint(params.outlineSize))
            label:enableOutline(ccc4FromInt(params.outline), outlineSize)
        end
    end
end
--刷新幻晶石商城界面 需要判断是国内还是国外
function DiamondShopCell:RefreshShopCell(data,isForeign,isAnyDouble,index,isCardNum )
    self.numLabel:setString( data.num)
    self.numLabel:setVisible(true)
    local size = self.numLabel:getContentSize()
    self.motherTab:setVisible(false)
    local fight_numSize = cc.size(size.width*0.35,size.height*0.35)
    display.getLabelContentSize(self.numLabel)
    local size =  self.diamondImage:getContentSize()
    local diamondImageSize = cc.size(size.width * 0.2, size.height*0.2)
    self.contentLayout:setContentSize(cc.size(fight_numSize.width + diamondImageSize.width, 40))
    self.numLabel:setPosition(cc.p( diamondImageSize.width +  fight_numSize.width/2 , 20))
    self.diamondImage:setPosition(cc.p( diamondImageSize.width/2 , 20) )
    if  isForeign then
        if isAnyDouble then
            self.tag_Double:setVisible(true)
        end
        local x,y = self.contentLayout:getPosition()
        self.contentLayout:setPosition(cc.p(x, y - 30))

    else
        if checkint(data.isFirst) == 1  then -- 是否是第一次购买
            self.tag_Double:setVisible(true)
            self.diamondLabel:setVisible(true)
            if isJapanSdk() then
                display.reloadRichLabel(self.diamondLabel, { c = {
                    fontWithColor('8', { color = "8f715b" ,fontSize = 20 , text ='首充钻石' }) ,
                    { img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID) ,scale = 0.12 }  ,
                    fontWithColor('8', { color = "8f715b" ,fontSize = 20 , text = string.format( '%d奖励', checkint(data.num))}),
                }})
            else
                display.reloadRichLabel(self.diamondLabel, { c = {fontWithColor('8', { color = "8f715b" ,fontSize = 20 , text =string.format( __('首充额外赠送%d'), checkint(data.num))
                }) ,{ img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID) ,scale = 0.12 }}  })
            end
            if self.diamondLabel then
                CommonUtils.SetNodeScale(self.diamondLabel , {width  = 180})
            end
        else
            self.diamondLabel:setVisible(false)
            self.tag_Double:setVisible(false)
        end
    end
    local priceHotImage = self:getChildByName('HOTIMAGE')
    if data.icon and string.len(data.icon) > 0 then
        local filePath = _res(string.format('ui/home/commonShop/%s.png',data.icon))
        if priceHotImage then
            if cc.FileUtils:getInstance():isFileExist(filePath) then
                priceHotImage:setVisible(true)
                priceHotImage:setTexture(filePath)
            else
                priceHotImage:setVisible(false)
            end
        end
    else
        if priceHotImage then
            priceHotImage:setVisible(false)
        end
    end
    local  str = ""
    if  data.ismember then
        if isElexSdk()  then
            self.motherTab:setVisible(true)
        end
        str = _res(string.format('ui/home/commonShop/shop_diamonds_ico_card_%d.png' , index) )
        self.lightImage:setTexture(_res('ui/home/commonShop/shop_recharge_light_red.png'))
        self.contentLayout:setVisible(false)
        self.diamondLabel:setVisible(true)
        local vipJosn = CommonUtils.GetConfigAllMess('vip', "player")
        local str = data.name or ""
        display.reloadRichLabel(self.diamondLabel, { c = {fontWithColor('18', {text = str , color = "934714"}) } })
        local diamondLabelChild = self.diamondLabel:getChildren()[1]
        local diamondLabelSize = display.getLabelContentSize(diamondLabelChild)
        if diamondLabelSize.width > 350 then
            local currentScale = diamondLabelChild:getScale()
            local tScale = 350/diamondLabelSize.width * currentScale
            self.diamondLabel:setScale(tScale)
        end

        if checkint(data.leftSeconds) == 0   then
            local price = tostring(data.price)
            if isElexSdk() then
                local sdkInstance = require("root.AppSDK").GetInstance()
                if sdkInstance.loadedProducts[tostring(data.channelProductId)] then
                    price = sdkInstance.loadedProducts[tostring(data.channelProductId)].priceLocale
                else
                    price = string.format( __('￥%s'),price )
                end
            else
                price = string.format( __('￥%s'),price )
            end

            display.reloadRichLabel(self.sellLabel, {
                        c = {
                            fontWithColor(18, {fontSize = 28,text = price, color = '#ffffff'})
                    }  })

        else
            display.reloadRichLabel(self.sellLabel, {
                c = {
                    fontWithColor(14, {text = __('剩余') }) ,
                    fontWithColor(14, {text = math.floor(checkint(data.leftSeconds) /(86400)) ,color = "ffcc42" }) ,
                    fontWithColor(14, {text = __("天")  }) ,

                }  })
        end
    else
        local price = tostring(data.price)
        if isElexSdk() then
            local sdkInstance = require("root.AppSDK").GetInstance()
            if sdkInstance.loadedProducts[tostring(data.channelProductId)] then
                price = sdkInstance.loadedProducts[tostring(data.channelProductId)].priceLocale
            else
                price = string.format( __('￥%s'),price )
            end
        else
            price = string.format( __('￥%s'),price )
        end
        display.reloadRichLabel(self.sellLabel, {
                c = {
                    fontWithColor(18, {fontSize = 28,text = price, color = 'ffffff' })
            }  })
        str = _res(string.format('ui/home/commonShop/shop_diamonds_ico_%d.png' , index - isCardNum  ) )
        self.lightImage:setTexture(_res('ui/home/commonShop/shop_recharge_light_blue.png'))
    end
    self:enableOutline(self.sellLabel)
    local isTrue  =  FTUtils:isPathExistent(str)
    if not isTrue  then
        for  i = index-1 ,1,-1 do
            str = string.gsub(str, "%d+",i )
            isTrue  =  FTUtils:isPathExistent(str)
            if isTrue then
                break
            end
        end
    end
    self.goodNode:setScale(0.8)
    self.goodNode:setTexture(str)
end


return DiamondShopCell
