---
--- Created by xingweihao.
--- DateTime: 18/08/2017 6:21 PM
---
---@class DiamondLimitShopCell
local DiamondLimitShopCell = class('Game.views.DiamondLimitShopCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'Game.views.DiamondLimitShopCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

local FeatureName = {
	["shop_tag_iconid_1"] = __('推荐'),
	["shop_tag_iconid_2"] = __('热卖'),
	["shop_tag_iconid_3"] = __('超值'),
	["shop_tag_iconid_4"] = __('特惠'),
	["shop_tag_iconid_5"] = __('限购一次'),
	["shop_tag_iconid_6"] = __('每日限购')
}

function DiamondLimitShopCell:ctor(...)
    local arg = {...}
    self.type = 1 or 2
    local size = arg[1] or cc.size(208 , 256)
    self:setContentSize(size)
    self:setPosition(display.center)
    self:setAnchorPoint(display.CENTER)


    local toggleView = display.newButton(size.width * 0.5,size.height * 0.5,{--
        n = _res('ui/home/commonShop/shop_btn_diamonds_default.png')
    })
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
    local bg_Diamond = display.newImageView(_res("ui/home/commonShop/shop_btn_goods_sale_float.png"), size.width/2, 3,{ ap = display.CENTER_BOTTOM})
    local bg_DiamondSize = bg_Diamond:getContentSize()
    self.eventnode:addChild(bg_Diamond)
    self.diamondLabelBg = bg_Diamond
    --local sellLabel = display.newLabel(bg_DiamondSize.width/2, bg_DiamondSize.height /2  ,
    --fontWithColor(14,{text = __('￥648') , ap = display.CENTER}))
    local sellLabel = display.newRichLabel(bg_DiamondSize.width/2, bg_DiamondSize.height/2, { c = {fontWithColor('19', {text = ""})}})
    self.eventnode:addChild(sellLabel)
    self.sellLabel = sellLabel

    -- 上部分的
    local tag_Double = display.newImageView(_res('ui/home/commonShop/shop_tag_double.png'), 0, size.height - 7 , { ap = display.LEFT_TOP })
    self.eventnode:addChild(tag_Double)
    local tag_DoubleSize = tag_Double:getContentSize()
    local firstBuyLabel = display.newLabel(tag_DoubleSize.width/2 - 10, tag_DoubleSize.height/2, fontWithColor('14', { fontSize = 20 , text = __('首充双倍')  , color = "ffffff" , outline =  false}) )
    tag_Double:addChild(firstBuyLabel)
    self.tag_Double = tag_Double
    self.firstBuyLabel = firstBuyLabel
    self.tag_Double:setVisible(false)

    local discountBg = display.newNSprite(_res('ui/home/commonShop/shop_tag_sale'), 2, size.height - 10)
    discountBg:setAnchorPoint(cc.p(0,1))
    self.eventnode:addChild(discountBg, 5)
    self.discountBg = discountBg
    discountBg:setVisible(false)
    local discountNum = display.newLabel(utils.getLocalCenter(discountBg).x, utils.getLocalCenter(discountBg).y, fontWithColor(14, {text = '', ap = cc.p(0.5, 0.5), fontSize = 20}))
    discountBg:addChild(discountNum)
    self.discountNum = discountNum

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
    fight_num:setString("")
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

    local priceHotImage = display.newImageView(_res('ui/home/commonShop/shop_limit_bg_time.png'), size.width * 0.5 + 4, size.height- 6, {
        ap = display.CENTER_TOP})
    local priceHotLabel = display.newLabel(size.width * 0.5 + 4, size.height- 12,fontWithColor(6 , {text = "", ap = display.CENTER_TOP}))
    self:addChild(priceHotLabel,1235)
    priceHotLabel:setVisible(false)
    priceHotLabel:setName("HOTIMAGELABEL")
    self:addChild(priceHotImage, 1234)
    priceHotImage:setVisible(false)
    priceHotImage:setName('HOTIMAGE')
end
function DiamondLimitShopCell:enableOutline(node,params)
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
function DiamondLimitShopCell:RefreshShopCell(data,isForeign,isAnyDouble,index, startPoc)
    self.numLabel:setString( data.num)
    self.numLabel:setVisible(true)
    local size = self.numLabel:getContentSize()

    local fight_numSize = cc.size(size.width*0.35,size.height*0.35)
    display.getLabelContentSize(self.numLabel)
    local size =  self.diamondImage:getContentSize()
    local diamondImageSize = cc.size(size.width * 0.2, size.height*0.2)
    self.contentLayout:setContentSize(cc.size(fight_numSize.width + diamondImageSize.width, 40))
    self.numLabel:setPosition(cc.p( diamondImageSize.width +  fight_numSize.width/2 , 20))
    self.diamondImage:setPosition(cc.p( diamondImageSize.width/2 , 20) )
    local priceHotImage = self:getChildByName('HOTIMAGE')
    local leftTimesLabel = self:getChildByName('HOTIMAGELABEL')
    if priceHotImage then
        priceHotImage:setVisible(false)
        leftTimesLabel:setVisible(false)
    end
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
            display.reloadRichLabel(self.diamondLabel, { c = {fontWithColor('8', { color = "8f715b" ,fontSize = 20 , text =string.format( __('首充额外赠送%d'), checkint(data.num))
            }) ,{ img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID) ,scale = 0.12 }}  })

        else
            self.diamondLabel:setVisible(false)
            self.tag_Double:setVisible(false)
        end
    end
    self.diamondLabelBg:setTexture(_res('ui/home/commonShop/shop_btn_goods_sale_float.png'))
    self.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_diamonds_default.png'))
    self.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_diamonds_default.png'))

    local  str = ""
    if data.ismember then
        --月卡的情况
        local picId = checkint(data.startIndex) - 100
        str = _res(string.format('ui/home/commonShop/shop_diamonds_ico_card_%d.png' , picId) )
        self.lightImage:setTexture(_res('ui/home/commonShop/shop_recharge_light_red.png'))
        self.contentLayout:setVisible(false)
        self.diamondLabel:setVisible(true)
        self.diamondLabelBg:setTexture(_res('ui/home/commonShop/shop_bg_money_diamonds.png'))
        local str = data.name or ""
        display.reloadRichLabel(self.diamondLabel, { c = {fontWithColor('19', {text = str , color = "934714"}) } })
        if checkint(data.leftSeconds) == 0   then
            display.reloadRichLabel(self.sellLabel, {
                c = {
                    fontWithColor(14, {text = string.format( __('￥%s'),data.price ) })
                }  })

        else
            display.reloadRichLabel(self.sellLabel, {
                c = {
                    fontWithColor(14, {text = __('剩余') }) ,
                    fontWithColor(14, {text = math.floor(checkint(data.leftSeconds) /(86400)) ,color = "ffcc42" }) ,
                    fontWithColor(14, {text = __("天")  }) ,

                }  })
        end
    elseif data.sequence then

        local picId = checkint(data.startIndex) - 100
        str = _res(string.format('ui/home/commonShop/shop_diamonds_ico_card_%d.png' , picId) )
        self.lightImage:setTexture(_res('ui/home/commonShop/shop_recharge_light_red.png'))
        self.diamondLabelBg:setTexture(_res('ui/home/commonShop/shop_bg_money_diamonds.png'))
        self.toggleView:setNormalImage(_res('ui/home/commonShop/shop_btn_diamonds_limit.png'))
        self.toggleView:setSelectedImage(_res('ui/home/commonShop/shop_btn_diamonds_limit.png'))
        -- self.contentLayout:setVisible(false)
        self.diamondLabel:setVisible(false)
        -- local str = data.name or ""
        display.reloadRichLabel(self.diamondLabel, { c = {{fontSize = 20, text = "", color = "#934714"}}})
        -- if checkint(data.leftSeconds) == 0   then
        display.reloadRichLabel(self.sellLabel, {
                c = {
                    fontWithColor(14, {text = string.format( __('￥%s'),data.price ) })
            }  })

        -- end
        --倒计时的逻辑
        self:stopAllActions()
        if checkint(data.leftSeconds) > 0 then
            --处理倒计时显示
            local priceHotImage = self:getChildByName('HOTIMAGE')
            local leftTimesLabel = self:getChildByName('HOTIMAGELABEL')
            if priceHotImage then
                priceHotImage:setVisible(true)
                leftTimesLabel:setVisible(true)
                -- display.commonLabelParams(leftTimesLabel , fontWithColor('14', {text = (data.iconTitle ~= '' and data.iconTitle) or FeatureName[data.icon]}))
                -- local contentSize = display.getLabelContentSize( leftTimesLabel)
                -- local priceHotImageSize = priceHotImage:getContentSize()
                -- priceHotImage:setScaleX((contentSize.width + 20 )/ priceHotImageSize.width)
            else
                if priceHotImage then
                    leftTimesLabel:setVisible(false)
                    priceHotImage:setVisible(false)
                end
            end

            --这个用来显示限购次数
            -- self.diamondLabel:setVisible(true)
            local totalNum = checkint(data.lifeLeftPurchasedNum)
            local todayNum = checkint(data.todayLeftPurchasedNum)
            local purchargeLabel = self.diamondLabel
            if todayNum >= totalNum then
                --限购次数显示
                if purchargeLabel and totalNum > 0 then
                    purchargeLabel:setVisible(true)
                    display.reloadRichLabel(purchargeLabel, {
                            c = {
                                {text = string.fmt(__("限购_num_次"), {_num_ = totalNum}), fontSize = 20, color = '5c5c5c'}
                        }})

                end
                if totalNum > 0 then
                    display.reloadRichLabel(self.sellLabel, {
                            c = {
                                fontWithColor(14, {text = string.fmt( __('￥_num1_'),{_num1_ = tostring(data.price)} ) })
                        }})
                else
                    if totalNum == 0 then
                        display.reloadRichLabel(self.sellLabel, {
                                c = {
                                    fontWithColor(14, {text = __('已售罄') })
                            }})
                    else
                        purchargeLabel:setVisible(true)
                        display.reloadRichLabel(purchargeLabel, {
                            c = {
                                {text = string.fmt(__("今日可购_num_次"), {_num_ = todayNum}),fontSize = 20, color = '5c5c5c'}
                        }})

                    end
                end
            else
                if purchargeLabel and todayNum > 0 then
                    purchargeLabel:setVisible(true)
                    display.reloadRichLabel(purchargeLabel, {
                            c = {
                                {text = string.fmt(__("今日可购_num_次"), {_num_ = todayNum}),fontSize = 20, color = '5c5c5c'}
                        }})

                elseif purchargeLabel and todayNum == 0 then
                    purchargeLabel:setVisible(true)
                    display.reloadRichLabel(purchargeLabel, {
                            c = {
                                {text = string.fmt(__("今日可购_num_次"), {_num_ = todayNum}),fontSize = 20, color = '5c5c5c'}
                        }})

                end
                if todayNum > 0 then
                    display.reloadRichLabel(self.sellLabel, {
                            c = {
                                fontWithColor(14, {text = string.fmt( __('￥_num1_'),{_num1_ = tostring(data.price)} ) })
                        }})
                else
                    display.reloadRichLabel(self.sellLabel, {
                            c = {
                                fontWithColor(14, {text = __('已售罄') })
                        }})

                end
            end

            local shareUserDefault = cc.UserDefault:getInstance()
            self:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function()
                local recordTime = shareUserDefault:getIntegerForKey("DIAMOND_KEY_ID", 0)
                local spanTime = os.time() - recordTime
                local leftSeconds = checkint(data.leftSeconds) - spanTime
                if leftSeconds > 0 then
                    leftTimesLabel:setVisible(true)
                    if checkint(leftSeconds) <= 86400 then
                        display.commonLabelParams(leftTimesLabel, {fontSize = 20, text = __('剩余时间:') .. string.formattedTime(leftSeconds,'%02i:%02i:%02i'), color = "#934714"})
                    else
                        local day = math.floor(checkint(leftSeconds)/86400)
                        local hour = math.floor((leftSeconds - day * 86400) / 3600)
                        display.commonLabelParams(leftTimesLabel, {fontSize = 20, text = __('剩余时间:') .. string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}), color = "#934714"})
                    end
                else
                    self:stopAllActions()
                    leftTimesLabel:setVisible(false)
                end
            end), cc.DelayTime:create(1))))
        end
    else
        local picId = 1
        if data.sequence then
            picId = checkint(data.sequence)
        else
            picId = index - startPoc
        end
        display.reloadRichLabel(self.sellLabel, {
            c = {
                fontWithColor(14, {text = string.format( __('￥%s'),tostring(data.price)) })
            }  })
        str = _res(string.format('ui/home/commonShop/shop_diamonds_ico_%d.png' , picId) )
        self.lightImage:setTexture(_res('ui/home/commonShop/shop_recharge_light_blue.png'))
    end
    self:enableOutline(self.sellLabel)
    local isTrue  =  FTUtils:isPathExistent(str)
    if not isTrue  then
        str = _res(string.format('ui/home/commonShop/shop_diamonds_ico_%d.png' , 1) )
    end
    self.goodNode:setScale(0.8)
    self.goodNode:setTexture(str)
    -- if checkint(data.isFirst) == 0 and checkint(data.discount) ~= 100 and data.ismember == nil then
        --打折状态
        -- self.discountBg:setVisible(true)
        -- self.discountNum:setString(string.fmt('_num_% Off', {_num_ = (100 - checkint(data.discount))}))
    -- end
end


return DiamondLimitShopCell
