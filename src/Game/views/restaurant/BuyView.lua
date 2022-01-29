local CommonDialog = require('common.CommonDialog')
local BuyView = class('BuyView', CommonDialog)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local RES_DICT = {
	BTN_ADD			= 'avatar/ui/market_sold_btn_plus.png',
	BTN_MINUS 		= 'avatar/ui/market_sold_btn_sub',
	BG_NUM 			= 'ui/common/bag_bg_number.png',
}

--[[
override
initui
--]]
function BuyView:InitialUI()
    -- local view = require("common.TitlePanelBg").new({ title = __('购买'), type = 13})
    -- view.viewData.closeBtn:setOnClickScriptHandler(CloseSelf)
    -- display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	-- self:addChild(view)
    self:setName('BUY_VIEW')
    local avatarInfo = CommonUtils.GetConfigNoParser('restaurant', 'avatar', self.args.avatarId)
    local function CreateView()
        local size = cc.size(1066, 634)
        ---正式的内容页面
        local cview = CLayout:create(size)
        local bg = display.newImageView(_res(string.format( "ui/common/common_bg_%d.png", 13)), 0, 0)
        display.commonUIParams(bg, { ap = display.LEFT_BOTTOM, po = cc.p(0, 0)})
        cview:setName("CONTENT_VIEW")
        cview:addChild(bg)
        -- title
        local offsetY = 4 
        local titleBg = display.newButton(bg:getContentSize().width * 0.5 + 12, size.height - offsetY, {n = _res('ui/common/common_bg_title_2.png'), enable = false})
        display.commonUIParams(titleBg, {ap = display.CENTER_TOP})
        titleBg:setEnabled(false)
        display.commonLabelParams(titleBg, fontWithColor(1,{fontSize = 24, text = __('购买'), color = 'ffffff',offset = cc.p(0, -2)}))
        bg:addChild(titleBg,2)
        -- cview:setBackgroundColor(cc.c4b(100,100,100,100))
                -- 领取按钮
        local getBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
        display.commonUIParams(getBtn, {po = cc.p(size.width * 0.5, 92)})
        display.commonLabelParams(getBtn, fontWithColor(14,{text = __('购买')}))
        getBtn:setName('GET_BUTTON')
        cview:addChild(getBtn)
        getBtn:setTag(103)
        getBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))

        local imageAvatar = AssetsUtils.GetRestaurantSmallAvatarNode(self.args.avatarId)
        display.commonUIParams(imageAvatar, {po = cc.p(178, 414)})
        cview:addChild(imageAvatar,1)
        
        local nameLabel = display.newLabel(182, 314, {text = avatarInfo.name, color = '5c5c5c', fontSize = 26})
        cview:addChild(nameLabel,2)

        local effectImage = display.newButton(386, 476, {n = _res('ui/common/common_bg_list_title'), ap = display.LEFT_CENTER,enable = false})
        -- display.commonLabelParams(effectImage, {text = __('效果'), color = '3c3c3c', fontSize = 26, offset = cc.p(- 90,0)})
        display.commonLabelParams(effectImage, {text = __('描述'), color = '3c3c3c', fontSize = 26, offset = cc.p(- 90,0)})
        cview:addChild(effectImage,1)
        --[[
        if avatarInfo.buffType then
            for idx,val in pairs(avatarInfo.buffType) do
                local x = 392
                local y = 432 - (idx - 1) * 24
                local bufferType = CommonUtils.GetConfigNoParser('restaurant', 'buffType', val.targetType)
                local text = CommonUtils.GetBufferDescription(bufferType.descr, val)
                local label = display.newLabel(x,y, {text = string.format('%d.%s',idx, text), color = '5c5c5c', fontSize = 24, ap = display.LEFT_CENTER})
                cview:addChild(label, 10)
            end
        end
        --]]
        local x = 392
        local y = 432 
        local label = display.newLabel(x,y, {text = avatarInfo.descr,color = '5c5c5c', fontSize = 24, ap = display.LEFT_TOP, w = 300, h = 130})
        cview:addChild(label, 10)

        local priceLabel = display.newLabel(size.width * 0.5 + 10, 44, fontWithColor(14,{ap = display.RIGHT_CENTER, text = tostring(avatarInfo.payPrice), color = 'ffffff'}))
        cview:addChild(priceLabel,10)
        local priceIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)),size.width * 0.5 + 30, 44)
        if checkint(avatarInfo.payType) == 2 then
            priceIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)))
        end
        priceIcon:setScale(0.2)
        cview:addChild(priceIcon,10)
        
        local titleLabel = display.newButton(544,244, {
            n = _res('ui/common/common_title_3'),enable = false
        })
        display.commonLabelParams(titleLabel, {text = __('购买数量'), color = '4c4c4c', fontSize = 26})
        cview:addChild(titleLabel,1)
        --减号btn
        local btn_minus = display.newButton(0, 0, {n = _res(RES_DICT.BTN_MINUS)})
        display.commonUIParams(btn_minus, {po = cc.p(458, 190)})
        cview:addChild(btn_minus, 1)
        btn_minus:setTag(101)
        btn_minus:setOnClickScriptHandler(handler(self, self.ButtonAction))
        --选择数量
        local btn_num = display.newButton(0, 0, {n = _res(RES_DICT.BG_NUM),enable = false, scale9 = true,size = cc.size(120,44)})
        display.commonUIParams(btn_num, {po = cc.p(btn_minus:getPositionX() + btn_minus:getContentSize().width * 0.5 - 8, btn_minus:getPositionY()),ap = cc.p(0,0.5)})
        display.commonLabelParams(btn_num, {text = '1', fontSize = 28, color = '#7c7c7c'})
        cview:addChild(btn_num)
        --加号btn
        local btn_add = display.newButton(0, 0, {n = _res(RES_DICT.BTN_ADD)})
        display.commonUIParams(btn_add, {po = cc.p(btn_num:getPositionX() + btn_num:getContentSize().width - 8, btn_minus:getPositionY()),ap = cc.p(0,0.5)})
        cview:addChild(btn_add,1)
        btn_add:setTag(102)
        btn_add:setOnClickScriptHandler(handler(self, self.ButtonAction))

        return {
            view = cview,
            avatarImageView = imageAvatar,
            purchageButton = getBtn,
            priceLabel = priceLabel,
            priceIcon = priceIcon,
            minusButton = btn_minus,
            numberButton = btn_num,
            plusButton = btn_add
        }
    end

    self.viewData = CreateView()
    local avatarInfo = CommonUtils.GetConfigNoParser('restaurant', 'avatar', self.args.avatarId)
    local nType = RestaurantUtils.GetAvatarSubType(avatarInfo.mainType, avatarInfo.subType)
    if nType == RESTAURANT_AVATAR_TYPE.WALL or nType == RESTAURANT_AVATAR_TYPE.CEILING or nType == RESTAURANT_AVATAR_TYPE.FLOOR or nType == RESTAURANT_AVATAR_TYPE.DECORATION_PET then
        self.viewData.minusButton:setVisible(false)
        self.viewData.plusButton:setVisible(false)
    end

end

function BuyView:ButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local curNo = checkint(self.viewData.numberButton:getText())
    local avatarInfo = CommonUtils.GetConfigNoParser('restaurant', 'avatar', self.args.avatarId)
    if tag == 101 then
        --减
        if curNo > 1 then
            curNo = curNo - 1
            self.viewData.numberButton:setText(tostring(curNo))
        end
        self.viewData.priceLabel:setString(tostring(curNo * checkint(avatarInfo.payPrice)))
    elseif tag == 102 then
        --加
        if curNo > 99 then
            uiMgr:ShowInformationTips(__('当前部件最多只能购买99个'))
        else
            curNo = curNo + 1
            self.viewData.numberButton:setText(tostring(curNo))
            self.viewData.priceLabel:setString(tostring(curNo * checkint(avatarInfo.payPrice)))
        end
    elseif tag == 103 then
        --买的逻辑
        GuideUtils.DispatchStepEvent()
        local nType = RestaurantUtils.GetAvatarSubType(avatarInfo.mainType, avatarInfo.subType)
        if nType == RESTAURANT_AVATAR_TYPE.WALL or nType == RESTAURANT_AVATAR_TYPE.CEILING or nType == RESTAURANT_AVATAR_TYPE.FLOOR or nType == RESTAURANT_AVATAR_TYPE.DECORATION_PET then
            -- 只能购买一个
            if app.restaurantMgr:GetAvatarAmoutById(self.args.avatarId) == 0 then
                AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_BUY_AVATAR, {goodsId = self.args.avatarId, num = 1})
            end
        else
            --可以购买多个
            AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_BUY_AVATAR, {goodsId = self.args.avatarId, num = curNo})
        end
    end
end

function BuyView:onEnter()
end

return BuyView


