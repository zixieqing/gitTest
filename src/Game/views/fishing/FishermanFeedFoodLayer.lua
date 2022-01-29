local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr = shareFacade:GetManager("UIManager")

local RES_DICT          = {
    FF_BG_DETAIL        = _res('ui/common/common_bg_tips'),
    FF_IMG_ARROW        = _res('ui/common/common_bg_tips_horn'),
    FF_IMG_NUMBER       = _res('ui/common/common_bg_number_01'),
}

local FishermanFeedFoodLayer = class('FishermanFeedFoodLayer', function()
    local layout = CLayout:create()
    layout.name = 'FishermanFeedFoodLayer'
    layout:enableNodeEvents()
    return layout
end)

function FishermanFeedFoodLayer:ctor(...)
    local args = unpack({...})
    self.id = args.id --卡牌的id
    self.tag = args.tag

    local size = cc.size(560, 176)
    self:setContentSize(size)
    local function CreateFoodView()
        --创建食物页面
        -- local size = cc.size(600, 176)
        local view = CLayout:create(size)
        -- view:setBackgroundColor(cc.c4b(200,100,100,100))
        local bg = display.newImageView(RES_DICT.FF_BG_DETAIL, 0,0,{enable = true, scale9= true, size = size})
        display.commonUIParams(bg, {ap = display.LEFT_BOTTOM})
        view:addChild(bg,1)

        local arrowIcon = display.newImageView(RES_DICT.FF_IMG_ARROW,size.width * 0.5,14, {
            ap = display.CENTER_TOP,
        })
        arrowIcon:setFlippedY(true)
        view:addChild(arrowIcon)

        local tipLabel = display.newLabel(size.width * 0.5, 152, fontWithColor(5,{text = __('选择食物给飨灵喂食')}))
        view:addChild(tipLabel,2)

        local listView = CListView:create(cc.size(size.width, 160))
        listView:setBounceable(false)
        listView:setDirection(eScrollViewDirectionHorizontal)
        display.commonUIParams(listView, {ap = display.CENTER_BOTTOM, po = cc.p(size.width * 0.5, 4)})
        view:addChild(listView,2)

        return {
            view = view,
            listView = listView,
        }
    end
    self.viewData = CreateFoodView()
    display.commonUIParams(self.viewData.view, {po = utils.getLocalCenter(self)})
    self:addChild(self.viewData.view,1)

    self:FreshData()

    self.touchEventListener = cc.EventListenerTouchOneByOne:create()
    self.touchEventListener:registerScriptHandler(function(touch,event)
        return true
    end,cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchEventListener:registerScriptHandler(function(touch, event)
        --处理点其他区域的逻辑
        local pos = touch:getLocation()
        local rect = self:getBoundingBox()
        if not cc.rectContainsPoint(rect, pos) then
            self:removeFromParent()
        end
    end, cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithFixedPriority(self.touchEventListener,1)

end

function FishermanFeedFoodLayer:FreshData()
    self.viewData.listView:removeAllNodes()
    local size = self:getContentSize()
    for idx,val in ipairs(VIGOUR_RECOVERY_GOODS_ID) do
        local len = #VIGOUR_RECOVERY_GOODS_ID
        local lsize = cc.size( size.width / len, 134)
        local view = CLayout:create(cc.size(size.width/ len, 140))
        --goodsIcon
        local goodsIcon = display.newButton(lsize.width * 0.5, 80, {
            n = CommonUtils.GetGoodsIconPathById(val)
        })
        goodsIcon:setTag(val)
        display.commonUIParams(goodsIcon, {ap = display.CENTER, po = cc.p(lsize.width * 0.5, 80)})
        goodsIcon:setScale(0.9)
        view:addChild( goodsIcon, 3)
        goodsIcon:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
            local goodsId = sender:getTag()
            local no = gameMgr:GetAmountByGoodId(goodsId)
            if no > 0 then
                local cardInfo = gameMgr:GetCardDataById(self.id)
                if cardInfo then
                    local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
                    if checkint(cardInfo.vigour) < maxVigour then
                        shareFacade:DispatchSignal(COMMANDS.COMMAND_FEED_AVATAR,{playerCardId = self.id, goodsId = goodsId, num = 1, tag = self.tag}, 'vigour')
                    else
                        uiMgr:ShowInformationTips(__('当前飨灵新鲜度已满'))
                    end
                end
            else
                uiMgr:AddDialog("common.GainPopup", {goodId = goodsId})
                -- uiMgr:ShowInformationTips(__('当前的道具数量不足，不能为飨灵补充新鲜度'))
            end
        end)

        local numberBg = display.newSprite(RES_DICT.FF_IMG_NUMBER)
        display.commonUIParams(numberBg, { po = cc.p( lsize.width * 0.5, 20)})
        view:addChild( numberBg, 3)

        local no = gameMgr:GetAmountByGoodId(val)
        local numberLabel = display.newLabel(70,12, {ap = display.RIGHT_CENTER, fontSize = 20, text = tostring(no), color = "ffffff"})
        numberBg:addChild(numberLabel, 4)

        self.viewData.listView:insertNodeAtLast(view)
    end

    self.viewData.listView:reloadData()
end

function FishermanFeedFoodLayer:onCleanup()
    if self.touchEventListener then
        self:getEventDispatcher():removeEventListener(self.touchEventListener)
    end
end

return FishermanFeedFoodLayer