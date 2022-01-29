--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 卡皮商店中介者
]]
local CardSkinStoreView     = require('Game.views.stores.CardSkinStoreView')
local CardSkinStoreMediator = class('CardSkinStoreMediator', mvc.Mediator)

---@type CardSkinShopCell
local CardSkinShopCell = require('Game.views.stores.CardSkinShopCell')

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function CardSkinStoreMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CardSkinStoreMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local function filterSkinData(origin)
    local data = {}
    local hasedList = {}
    for i,v in ipairs(origin) do
        if app.cardMgr.IsHaveCardSkin(v.goodsId) then
            table.insert(hasedList, v)
        else
            table.insert(data, v)
        end
    end

    if #hasedList > 0 then
        table.insertto(data, hasedList)
    end

    return data
end

-------------------------------------------------
-- inheritance method

function CardSkinStoreMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true
    self.shopData = nil
    self.allShelfLeftSeconds = {} --全部商品限时上架剩余秒数.
    self.allPreLeftSeconds = {} --全部商品限时上架 上次剩余秒数.
    self.gridContentOffset = cc.p(0,0)
    -- create view
    if self.ownerNode_ then
        self.storesView_ = CardSkinStoreView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self.storesView_)
    end
end


function CardSkinStoreMediator:CleanupView()
    if self.storesView_  and (not tolua.isnull(self.storesView_)) then
        self.storesView_:runAction(cc.RemoveSelf:create())
        self.storesView_ = nil
    end
end


function CardSkinStoreMediator:OnRegist()
    local ShopCommand = require( 'Game.command.ShopCommand')
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_All_Shop_Buy, ShopCommand)
end


function CardSkinStoreMediator:OnUnRegist()
    if self.scheduler then
        scheduler.unscheduleGlobal(self.scheduler)
        self.scheduler = nil
    end
    local curScene = uiMgr:GetCurrentScene()
    if curScene then 
        local layer = curScene:GetDialogByTag(8282)
        if nil ~= layer then
            layer:setVisible(false)
            layer:runAction(cc.RemoveSelf:create())
        end
    end
end


function CardSkinStoreMediator:InterestSignals()
    return {
        SIGNALNAMES.All_Shop_Buy_Callback,
    }
end
function CardSkinStoreMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == SIGNALNAMES.All_Shop_Buy_Callback then
        if signal:GetBody().requestData.name ~= 'CardSkinShopView' then return end
        -- uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        local data = {}
        for i,v in ipairs(self.shopData) do
            if checkint(v.productId) == checkint(body.requestData.productId) then
                if checkint(v.type) == 2 then--一个一个购买否则一次性全部购买
                    self.shopData[i].todayLeftPurchasedNum = v.todayLeftPurchasedNum - body.requestData.num
                else
                    self.shopData[i].todayLeftPurchasedNum = 0
                end
                data = clone(v)
                break
            end
        end
        local Trewards = {}
        if next(data) ~= nil then
            if body.requestData.currency then
                local useDiscountGoods = checkint(body.requestData.useDiscountGoods)
                local goodsDiscount = 1
                -- 默认道具折扣是1   如果使用折扣道具 则计算 道具折扣比例
                if useDiscountGoods > 0 then
                    --  扣除折扣道具
                    table.insert(Trewards, {goodsId = checkint(data.goodsDiscountGoodsId), num = -checkint(data.goodsDiscountGoodsNum)})
                    goodsDiscount = self:GetGoodsDiscount(data)
                end
                
                local price_ = self:GetGoodsPrice(checknumber(data.sale[tostring(body.requestData.currency)]), checknumber(data.discount), checknumber(data.memberDiscount), goodsDiscount)
                table.insert(Trewards,{goodsId = body.requestData.currency, num = -price_})
            end
        end
        for i,v in ipairs(body.rewards) do
            table.insert(Trewards,{goodsId = v.goodsId, num = v.num})
        end

        CommonUtils.DrawRewards(Trewards)
        self.shopData = filterSkinData(self.shopData)
        --更新皮肤券的数量显示
        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
        local scene = uiMgr:GetCurrentScene()
        if scene:GetDialogByTag( 5001 ) then
            scene:GetDialogByTag( 5001 ):runAction(cc.RemoveSelf:create())--购买详情弹出框
        end


        self:getStoresViewData().gridView:reloadData()
        self:getStoresViewData().gridView:setContentOffset(self.gridContentOffset)

        -- 购买成功 显示获取界面
        self:BuyCardSkinCallback(checkint(data.goodsId))

        AppFacade.GetInstance():DispatchObservers(EVENT_PAY_SKIN_SUCCESS)
    end
end


-------------------------------------------------
-- get / set

function CardSkinStoreMediator:getStoresView()
    return self.storesView_
end
function CardSkinStoreMediator:getStoresViewData()
    return self:getStoresView() and self:getStoresView():getViewData() or {}
end


-------------------------------------------------
-- public

function CardSkinStoreMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end

function CardSkinStoreMediator:setStoreData(storeData)
    self.dataTimestamp_  = checkint(storeData.dataTimestamp)
    
    self.allShelfLeftSeconds = {}
    self.shopData = filterSkinData(storeData.storeData)
    for i,v in ipairs(self.shopData) do
        if v.shelfLeftSeconds then
            if v.shelfLeftSeconds >= 0 then
                self.allShelfLeftSeconds[tostring(i)] = v
            end
        end
    end
    -- dump(self.shopData)

    local gridView = self:getStoresViewData().gridView
    -- gridView:setSizeOfCell(cc.size(206, 420))--206
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
    gridView:setCountOfCell(table.nums(self.shopData))
    gridView:reloadData()

    if self.scheduler then
        scheduler.unscheduleGlobal(self.scheduler)
        self.scheduler = nil
    end
    if next(self.allShelfLeftSeconds) ~= nil then
        -- for k,v in pairs(self.allShelfLeftSeconds) do
        --     self.allPreLeftSeconds[k] = self.dataTimestamp_
        -- end
        self.scheduler = scheduler.scheduleGlobal(handler(self, self.scheduleCallback), 1)
    end
end

function CardSkinStoreMediator:getLimitLeftTime(shelfLeftSeconds)
    local targetTime  = self.dataTimestamp_ + checkint(shelfLeftSeconds)
    return checkint(targetTime - os.time())
end

--[[
定时器回调
--]]
function CardSkinStoreMediator:scheduleCallback()
    local gridView = self:getStoresViewData().gridView
    -- local num  = 0
    for k,v in pairs(self.allShelfLeftSeconds) do

        local cell = gridView:cellAtIndex(checkint(k) - 1)
        if cell then
            local leftTimeNum  = self:getLimitLeftTime(v.shelfLeftSeconds)
            local leftTimeText = leftTimeNum >= 0 and CommonUtils.getTimeFormatByType(leftTimeNum) or __('已结束')
            display.commonLabelParams(cell.refreshTimeLabel, {text = leftTimeText})
        end

        -- if  v.shelfLeftSeconds ~= -1 then
        --     if v.shelfLeftSeconds > 0 then

        --         local curTime = os.time()
        --         local preTime = self.allPreLeftSeconds[k]
        --         v.shelfLeftSeconds = v.shelfLeftSeconds - (curTime - preTime)
        --         self.allPreLeftSeconds[k] = curTime
        --     end
        --     local cell = gridView:cellAtIndex(checkint(k) - 1)
        --     if cell then
        --         if v.shelfLeftSeconds <= 0 then
        --             num  = num + 1
        --             v.shelfLeftSeconds = 0
        --             cell.refreshTimeLabel:setString(__('已结束'))
        --         else
        --             -- cell.refreshTimeLabel:setString(string.formattedTime(checkint(v.shelfLeftSeconds),'%02i:%02i:%02i'))
        --             cell.refreshTimeLabel:setString(formatTime(checkint(v.shelfLeftSeconds)))
        --         end

        --     end
        -- else
        --     num  = num + 1
        -- end
    end

    -- if num == table.nums(self.allShelfLeftSeconds) then
    --     scheduler.unscheduleGlobal(self.scheduler)
    --     self.scheduler = nil
    --     self.allPreLeftSeconds = {}
    -- end

    -- print('1')
    -- dump(self.shopData)
end

function CardSkinStoreMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(234 , 558)
    local tempData = self.shopData[index]
    if pCell == nil then
        pCell = CardSkinShopCell.new(sizee)
        display.commonUIParams(pCell.toggleView, {animate = false, cb = handler(self, self.CellButtonAction)})
    end
    xTry(function()
        local skinId   = checkint(tempData.goodsId)
        local drawPath = CardUtils.GetCardDrawPathBySkinId(skinId)
        pCell.imgHero:setTexture(drawPath)

        local skinConf = CardUtils.GetCardSkinConfig(skinId) or {}
        local cardDrawName = ""
        if skinConf then
            cardDrawName = skinConf.photoId
        end

        local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardDrawName)
        if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
            print('\n**************\n', '立绘坐标信息未找到', cardDrawName, '\n**************\n')
            locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
        else
            locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
        end
        pCell.imgHero:setScale(locationInfo.scale/100)
        pCell.imgHero:setRotation( (locationInfo.rotate))
        pCell.imgHero:setPosition(cc.p(locationInfo.x ,(-1)*(locationInfo.y-540) -20))

        local cardConf  = CardUtils.GetCardConfig(skinConf.cardId) or {}
        local qualityId = cardConf.qualityId
        pCell.imgBg:setTexture(CardUtils.GetCardTeamBgPathBySkinId(skinId))

        pCell.toggleView:setTag(index)
        pCell:setTag(index)
        pCell.orImage:setVisible(false)
        pCell.discountTwoBg:setVisible(false)
        local priceTable = {}
        local span = 1
        -- tempData.discount = 80
        pCell.discountTwoBg:getChildByName("LINE"):setVisible(false)
        pCell.discountOneBg:getChildByName("LINE"):setVisible(false)
        for goodsId, price in pairs(tempData.sale or {}) do
            local originPrice = checknumber(price)
            local discountedPrice = self:GetGoodsPrice(checknumber(price), checknumber(tempData.discount), checknumber(tempData.memberDiscount))


            if span == 1 then --第一行价格
                local cData = {}
                cData[#cData + 1] = fontWithColor('14' , {text = discountedPrice, fontSize = 22})
                cData[#cData + 1] = {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.2 }
                local priceRichLabel = pCell.discountOneBg:getChildByName("PRICE")
                if next(cData)  then
                    display.reloadRichLabel(priceRichLabel , {
                        c = cData
                    })
                end
                local isCenter = 0
                if tempData.discount then--有折扣价格
                    if checkint(tempData.discount) < 100 and checkint(tempData.discount) > 0 then
                        local discountRichLabel = pCell.discountOneBg:getChildByName("DISCOUNT")
                        pCell.discountOneBg:getChildByName("LINE"):setVisible(true)
                        discountRichLabel:setVisible(true)
                        display.reloadRichLabel(discountRichLabel, {
                            c = {
                                fontWithColor('14' , {text = originPrice, fontSize = 22}),
                                {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.2 }
                            }
                        })
                         CommonUtils.AddRichLabelTraceEffect(discountRichLabel)
                    else
                        isCenter = 1
                    end
                end
                if isCenter == 1 then
                    priceRichLabel:setAnchorPoint(cc.p(0.5,0.5))
                    priceRichLabel:setPositionX(100)
                else
                    priceRichLabel:setAnchorPoint(cc.p(1,0.5))
                end
                CommonUtils.AddRichLabelTraceEffect(priceRichLabel)
            end

            if span == 2 then
                --存在两种货币购买
                pCell.orImage:setVisible(true)
                pCell.discountTwoBg:setVisible(true)
                local cData = {}
                cData[#cData + 1] = fontWithColor('14' , {text = discountedPrice, fontSize = 22})
                cData[#cData + 1] = {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.16 }
                local priceRichLabel = pCell.discountTwoBg:getChildByName("PRICE")
                if next(cData)  then
                    display.reloadRichLabel(priceRichLabel , {
                        c = cData
                    })
                end
                local isCenter = 0
                if tempData.discount then--有折扣价格
                    if checkint(tempData.discount) < 100 and checkint(tempData.discount) > 0 then
                        local discountRichLabel = pCell.discountTwoBg:getChildByName("DISCOUNT")
                        discountRichLabel:setVisible(true)
                        pCell.discountTwoBg:getChildByName("LINE"):setVisible(true)
                        display.reloadRichLabel(discountRichLabel, {
                            c = {
                                fontWithColor('14' , {text = originPrice, fontSize = 22}),
                                {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.16 }
                            }
                        })
                         CommonUtils.AddRichLabelTraceEffect(discountRichLabel)
                    else
                        isCenter = 1
                    end
                end
                if isCenter == 1 then
                    priceRichLabel:setAnchorPoint(cc.p(0.5,0.5))
                    priceRichLabel:setPositionX(100)
                else
                    priceRichLabel:setAnchorPoint(cc.p(1,0.5))
                end
                CommonUtils.AddRichLabelTraceEffect(priceRichLabel)
            else
                pCell.orImage:setVisible(false)
                pCell.discountTwoBg:setVisible(false)
            end
            span = span + 1
        end

        pCell.skinNameLabel:setString(tostring(skinConf.name))
        pCell.cardNameLabel:setString(tostring(cardConf.name))
        local markerBtn = pCell.markerBtn
        markerBtn:getLabel():setString((tempData.iconTitle ~= '') and tempData.iconTitle or __('热卖'))
        local img = _res('ui/stores/cardSkin/shop_tag_hot.png')
        if checkstr(tempData.icon) ~= '' then
            img = _res(string.format('ui/stores/base/%s', tostring(tempData.icon)))
        end
        markerBtn:setNormalImage(img)
        markerBtn:setSelectedImage(img)

        display.commonLabelParams(pCell.skinNameLabel , {text = skinConf.name , reqW = 190})
        display.commonLabelParams(pCell.cardNameLabel , {text = cardConf.name , reqW = 190})
        local markerBtn = pCell.markerBtn
        display.commonLabelParams(pCell.markerBtn:getLabel() , {text = (tempData.iconTitle ~= '') and tempData.iconTitle or __('热卖') ,reqW = 120})
        local img = _res('ui/stores/cardSkin/shop_tag_hot.png')
        if checkstr(tempData.icon) ~= '' then
            img = _res(string.format('ui/stores/base/%s', tostring(tempData.icon)))
        end
        markerBtn:setNormalImage(img)
        markerBtn:setSelectedImage(img)
        if tempData.shelfLeftSeconds and tempData.shelfLeftSeconds >= 0 then--限时上架剩余秒数.
            local leftTimeNum  = self:getLimitLeftTime(tempData.shelfLeftSeconds)
            local leftTimeText = leftTimeNum >= 0 and CommonUtils.getTimeFormatByType(leftTimeNum) or __('已结束')
            display.commonLabelParams(pCell.refreshTimeLabel, {text = leftTimeText})
            pCell.topBg:setVisible(true)
        else
            pCell.topBg:setVisible(false)
        end


        local bottonHeight = 20
        pCell.isHasLabel:setVisible(false)
        pCell.isHasImg:setVisible(false)
        markerBtn:setVisible(true)
        if app.cardMgr.IsHaveCardSkin(tempData.goodsId) then
            markerBtn:setVisible(false)
            pCell.isHasImg:setVisible(true)
            pCell.isHasLabel:setVisible(true)
            pCell.discountLayout:setVisible(false)
            -- pCell.topBg:setVisible(false)
        else
            pCell.discountLayout:setVisible(true)
            -- pCell.topBg:setVisible(true)
        end

    end,__G__TRACKBACK__)

    return pCell
end

-------------------------------------------------
-- handler
function CardSkinStoreMediator:CellButtonAction(sender)
    local tag = sender:getTag()
    local data = self.shopData[tag]

    self.gridContentOffset = self:getStoresViewData().gridView:getContentOffset()

    self.clickIndex = tag
    if app.cardMgr.IsHaveCardSkin(data.goodsId) then
        uiMgr:ShowInformationTips(__('已经拥有该皮肤'))
        return
    end
    if checkint(data.todayLeftPurchasedNum) > 0 or checkint(data.lifeStock) == -1 then
        local callBack = function( sender )
            print(self.clickIndex)
            self:PurchaseBtnCallback( )
        end
        local cancelCallback = function( sender )
            self.ShowCardSkinLayer = nil
        end
        local priceTable = {}
        for i, v in pairs(data.sale or {}) do
            priceTable[tostring(i)] = self:GetGoodsPrice(checknumber(v), checknumber(data.discount), checknumber(data.memberDiscount))
        end

        local discountGoodsData
        if self:IsEnableGoodsDiscount() and checkint(data.goodsDiscountGoodsId) > 0 then
            discountGoodsData = {
                discountGoods = data.goodsDiscountGoodsId,
                discountGoodNum = data.goodsDiscountGoodsNum,
                discount = data.goodsDiscount,
            }
        end
        
        local ShowCardSkinLayer = require('common.CommonCardGoodsDetailView').new({
            goodsId = checkint(data.goodsId),
            consumeConfig = {
                priceTable = priceTable ,
            },
            confirmCallback = handler(self, self.PurchaseBtnClickHandler),
            discountGoodsData = discountGoodsData,
            cancelCallback = cancelCallback
        })
        ShowCardSkinLayer:setTag(8282)
        ShowCardSkinLayer:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(ShowCardSkinLayer)
        ShowCardSkinLayer:setPosition(display.center)

        --scene:AddDialog(ShowCardSkinLayer)
        self.ShowCardSkinLayer = ShowCardSkinLayer
    else
        uiMgr:ShowInformationTips(__('已购买'))
    end

end
--[[
购买按钮回调
--]]
function CardSkinStoreMediator:PurchaseBtnClickHandler(sender)
    local tag = self.clickIndex
    local data = self.shopData[tag]

    ------------ 检查商品是否可以购买 ------------
    -- 库存
    if (0 >= checkint(data.stock)) or
        (-1 ~= checkint(data.lifeStock) and 0 >= checkint(data.lifeStock)) then

        uiMgr:ShowInformationTips(__('库存不足!!!'))
        return

    end

    -- 购买次数
    if 0 >= checkint(data.todayLeftPurchasedNum) or
        (-1 ~= checkint(data.lifeLeftPurchasedNum) and 0 >= checkint(data.lifeLeftPurchasedNum)) then

        uiMgr:ShowInformationTips(__('购买次数不足!!!'))
        return

    end

    -- 上架时间
    if 0 == checkint(data.shelfLeftSeconds) then

        uiMgr:ShowInformationTips(__('商品已下架!!!'))
        return

    end

    -- 货币是否足够
    local discount, memberDiscount = 100, 100

    if 0 ~= checkint(data.discountLeftSeconds) then
        discount, memberDiscount = checknumber(data.discount), checknumber(data.memberDiscount)
    end
    
    -- 只有在出弹出框时才检查是否有道具折扣
    local goodsDiscount = self:GetGoodsDiscount(data)
    local consumeGoodsId = sender:getTag()
    local price = self:GetGoodsPrice(checkint(data.sale[tostring(consumeGoodsId)]), discount, memberDiscount, goodsDiscount)
    local consumeGoodsConfig = CommonUtils.GetConfig('goods', 'goods', consumeGoodsId)
    if price > gameMgr:GetAmountByGoodId(consumeGoodsId) then
        -- if GAME_MODULE_OPEN.NEW_STORE and checkint(consumeGoodsId) == DIAMOND_ID then
        --     app.uiMgr:showDiamonTips()  -- 商城内不走提示跳转
        -- else
            uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), tostring(consumeGoodsConfig.name)))
            uiMgr:AddDialog("common.GainPopup", {goodId = checkint(consumeGoodsId)})
        -- end
        return
    end
    ------------ 检查商品是否可以购买 ------------
    local goodsDiscountGoodsId = checkint(data.goodsDiscountGoodsId)
    if self:IsEnableGoodsDiscount() and  goodsDiscountGoodsId > 0 then

        self:HandleGoodsDiscountBuyPop(goodsDiscountGoodsId, price, data, consumeGoodsId)

        return
    end

    -- 可以购买 弹出确认框
    local commonTip = require('common.CommonTip').new({
        text = __('确认购买?'),
        descrRich = {fontWithColor('8',{ text =__('购买前请再次确认价格') .. "\n" }) ,
                     fontWithColor('14',{ text = price}) ,
                     { img = CommonUtils.GetGoodsIconPathById(consumeGoodsId) , scale = 0.2 }

        } ,
        descrRichOutLine = {price},
        callback = function ()
            self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId, num = 1, name = 'CardSkinShopView' , currency = consumeGoodsId })
        end
    })
    CommonUtils.AddRichLabelTraceEffect(commonTip.descrTip , nil , nil ,{2})
    commonTip:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(commonTip)

end

function CardSkinStoreMediator:HandleGoodsDiscountBuyPop(goodsDiscountGoodsId, price, data, consumeGoodsId)
    local goodsDiscountGoodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsDiscountGoodsId) or {}
    local priceData = self:InitGoodsPriceData(goodsDiscountGoodsId, price, data, consumeGoodsId)
    local isOwnGoodsDiscount = checkint(priceData.discountPrice) > 0 and 1 or 0

    local text, cancelBack
    if checkint(priceData.discountPrice) > 0 then
        text = string.format(__('tips:你拥有%s, 可享受折扣购买, 购买后扣除相应道具。'), tostring(goodsDiscountGoodsConfig.name)) 
        cancelBack = function ()
            -- 原价购买
            self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId, num = 1, name = 'CardSkinShopView' , currency = consumeGoodsId, useDiscountGoods = 0 })
        end
    else
        text = string.format(__('tips:你没有%s, 不可享受折扣购买。'), tostring(goodsDiscountGoodsConfig.name))
    end

    local commonTip = require('common.CommonPopTip').new({
        viewType = 2,
        title = __('是否确认购买?'), 
        text = text,
        textW = 320,
        priceData = priceData,
        callback = function (sender)
            -- 判断是否有折扣道具 有则折扣道具购买 无则原价购买
            local useDiscountGoods = checkint(priceData.discountPrice) > 0 and 1 or 0
            self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId, num = 1, name = 'CardSkinShopView' , currency = consumeGoodsId, useDiscountGoods = useDiscountGoods })
        end,
        ------------------------
        -- 拥有折扣道具才会赋值
        cancelBack = cancelBack,
        ------------------------
    })
    commonTip:setName('CommonPopTip')
    commonTip:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(commonTip)
end

function CardSkinStoreMediator:PurchaseBtnCallback(  )
    local tag = self.clickIndex
    local data = self.shopData[tag]
    local money = gameMgr:GetAmountByGoodId(SKIN_COUPON_ID)
    local des = __('外观券')
    if checkint(data.currency) == SKIN_COUPON_ID then
        local price = data.price
        if data.discount  then--有折扣价格
            if checkint(data.discount) < 100 and checkint(data.discount) > 0 then
                price = data.discount * data.price / 100
            end
        end
        if checkint(money) >= checkint(price) then
            self:SendSignal(COMMANDS.COMMANDS_All_Shop_Buy,{productId = data.productId,num = 1,name = 'CardSkinShopView'})
        else
            local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
            uiMgr:AddDialog("common.GainPopup", {goodId = checkint(data.currency)})
        end
    end
end

formatTime = function (seconds)
    local c = nil
    if seconds >= 86400 then
        local day = math.floor(seconds/86400)
        local overflowSeconds = seconds - day * 86400
        local hour = math.floor(overflowSeconds / 3600)

        c = string.fmt(__('_num1_天'), {['_num1_'] = tostring(day)})
    else
        local hour   = math.floor(seconds / 3600)
        local minute = math.floor((seconds - hour*3600) / 60)
        local sec    = (seconds - hour*3600 - minute*60)
        c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
    end
    return c
end

--[[
皮肤购买成功
@params skinId int 皮肤id
--]]
function CardSkinStoreMediator:BuyCardSkinCallback(skinId)
    -- 关闭购买界面
    if nil ~= self.ShowCardSkinLayer then
        self.ShowCardSkinLayer:setVisible(false)
        self.ShowCardSkinLayer:runAction(cc.RemoveSelf:create())
        self.ShowCardSkinLayer = nil
    end

    uiMgr:ShowInformationTips(__('购买成功!!!'))

    local layerTag = 7218
    local getCardSkinView = require('common.CommonCardGoodsShareView').new({
        goodsId = skinId,
        confirmCallback = function (sender)
            -- 确认按钮 关闭此界面
            local layer = uiMgr:GetCurrentScene():GetDialogByTag(layerTag)
            if nil ~= layer then
                layer:setVisible(false)
                layer:runAction(cc.RemoveSelf:create())
            end
        end
    })
    display.commonUIParams(getCardSkinView, {ap = cc.p(0.5, 0.5), po = display.center})
    uiMgr:GetCurrentScene():AddDialog(getCardSkinView)
    getCardSkinView:setTag(layerTag)
end

--[[
获取道具购买价格
@params price int 原始价格
@params discount int 普通折扣 百分数
@params memberDiscount int 会员折扣 百分数
@params goodsDiscount  int 道具折扣 小数
@return dicountedPrice, discount int, int 打折后的真实价格, 折扣 百分数
--]]
function CardSkinStoreMediator:GetGoodsPrice(price, discount, memberDiscount, goodsDiscount)
    local discountedPrice = checknumber(price)
    local discount_ = 100
    local discountOldPrice = discountedPrice
    local reverse_ = 0.01

    if nil ~= memberDiscount then
        if (0 < checknumber(memberDiscount) and 100 > checknumber(memberDiscount)) then
            -- 有会员打折
            discountedPrice = math.round(discountedPrice * memberDiscount * reverse_)
            discount_ = memberDiscount
        end
    end

    if nil ~= discount and 100 <= discount_ then
        -- 当不存在会员打折时 检查是否存在普通打折
        if (0 < checknumber(discount) and 100 > checknumber(discount)) then
            -- 有普通打折
            discountedPrice = math.round(discountedPrice * discount * reverse_)
            discount_ = discount
        end
    end

    if nil ~= goodsDiscount then
        -- 其他折扣 计算 完成后再计算 道具折扣
        local goodsDiscount_  = checknumber(goodsDiscount)
        if (0 < goodsDiscount_) and (1 > goodsDiscount) then
            discountedPrice = math.round(discountedPrice * goodsDiscount_)
        end
    end

    return discountedPrice, discount_
end

function CardSkinStoreMediator:InitGoodsPriceData(goodsDiscountGoodsId, discountPrice, data, consumeGoodsId)
    local originPrice = checkint(data.sale[tostring(consumeGoodsId)])
    local priceTipText, discountPrice_, originalPriceTipText
    if app.gameMgr:GetAmountByIdForce(goodsDiscountGoodsId) >= checkint(data.goodsDiscountGoodsNum) then
        priceTipText = __('折扣价')
        discountPrice_ = discountPrice
        originalPriceTipText = string.format(__('原价: %s'), originPrice)
    else
        priceTipText = __('原价')
    end
    return  {
        currencyId = consumeGoodsId,
        originalPriceTipText = originalPriceTipText,
        originalPrice = originPrice,
        priceTipText = priceTipText, 
        discountPrice = discountPrice_
    }
end

function CardSkinStoreMediator:GetGoodsDiscount(data)
    local goodsDiscount = 1
    local goodsDiscountGoodsId = checkint(data.goodsDiscountGoodsId)
    if goodsDiscountGoodsId > 0 and app.gameMgr:GetAmountByIdForce(goodsDiscountGoodsId) >= checkint(data.goodsDiscountGoodsNum) then
        goodsDiscount = checknumber(data.goodsDiscount)
    end
    return goodsDiscount
end

--[[
是否启用道具折扣
@return isEnable bool 是否启用
--]]
function CardSkinStoreMediator:IsEnableGoodsDiscount()
    return true
end

return CardSkinStoreMediator
