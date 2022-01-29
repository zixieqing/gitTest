local GameScene = require( "Frame.GameScene" )

local AddPowerPopup = class('AddPowerPopup', GameScene)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function AddPowerPopup:ctor( ... )
    local arg = unpack({...})
    self.args = arg
    self.name = "Game.AddPowerPopup"
    self:init()
end


function AddPowerPopup:init()
    self.payId        = self.args.payId or GOLD_ID
    self.callback     = self.args.callback
    self.cancelback   = self.args.cancelback
    self.leftBuyTimes = self.args.leftBuyTimes or 0
    self.totalBuyLimit = self.args.totalBuyLimit or 0
    self.goodsNum     = checkint(self.args.goodsNum) -- 获得物品数量
    self.costNum      = checkint(self.args.costNum) -- 消耗物品数量
    self.costId       = checkint(self.args.costId or DIAMOND_ID)


    local commonBG = require('common.CloseBagNode').new({callback = function()
        if self.cancelback then
            self.cancelback()
        end
        self:runAction(cc.RemoveSelf:create())
    end})
    commonBG:setPosition(utils.getLocalCenter(self))
    self:addChild(commonBG)


    --view
    local view = CLayout:create()
    view:setPosition(display.cx, display.cy)
    view:setAnchorPoint(display.CENTER)
    self.view = view

    local outline = display.newImageView(_res('ui/common/common_bg_8.png'),{
         enable = true
    })
    local size   = outline:getContentSize()
    outline:setAnchorPoint(display.LEFT_BOTTOM)
    view:addChild(outline)
    view:setContentSize(size)
    commonBG:addContentView(view)

    -- entry button
    local entryBtn = display.newButton(size.width * 0.5,53,{
       n = _res('ui/common/common_btn_orange.png'),
       d = _res('ui/common/common_btn_orange_disable.png'),
       cb = function(sender)
            if self.callback then
                self.callback()
            end
            self:runAction(cc.RemoveSelf:create())
        end
    })
    display.commonLabelParams(entryBtn,fontWithColor(14,{text = ('50'),offset = cc.p(-25,0)}))
    view:addChild(entryBtn)

    local payMoney = display.newImageView(_res('arts/goods/goods_icon_'..self.costId..'.png'))
    payMoney:setScale(0.3)
    payMoney:setPosition(cc.p(100,entryBtn:getContentSize().height * 0.5))
    entryBtn:addChild(payMoney)

	local effectLabel = display.newRichLabel(size.width * 0.5, 250,{ap = cc.p(0.5, 0.5),w = 40,sp = 12})
	view:addChild(effectLabel)

    local numBtn = display.newButton(size.width * 0.5,113,{
       n = _res('ui/common/common_bg_number_01.png'),
    })
    display.commonLabelParams(numBtn,{fontSize = 22, color = '#ffffff', text = '50'})
    view:addChild(numBtn)

    -- local limitData  = CommonUtils.GetConfig('player', 'vip',1)
    
    -------------------------------------------------
    -- 金币
    if self.payId == GOLD_ID then
        if gameMgr:GetUserInfo().buyGoldRestTimes <= 0 then
            gameMgr:GetUserInfo().buyGoldRestTimes = 0
            entryBtn:getLabel():setString('- -')
            numBtn:getLabel():setString('- -')
        else
            -- local getGold = checkint(gameMgr:GetUserInfo().level) * 100 + (51 - checkint(gameMgr:GetUserInfo().level))*5
            local getGold = (math.floor((checkint(gameMgr:GetUserInfo().level) / 30) * 100 + 0.5)* 0.01) * 10000 * checkint(checkint(gameMgr:GetUserInfo().level) / 30) + 15000
            numBtn:getLabel():setString(tostring(getGold))

            -- math.ceil
            local totalBuyGoldLimit = CommonUtils.getVipTotalLimitByField('buyGoldLimit')
            local needDiamond = (math.ceil((totalBuyGoldLimit - gameMgr:GetUserInfo().buyGoldRestTimes)/3.0) - 1) * 5 + 10
            entryBtn:getLabel():setString(tostring(needDiamond))
        end

        local leftBuyTimes = checkint(gameMgr:GetUserInfo().buyGoldRestTimes)
        local descrArray   = string.split(string.fmt(__('今日还可以购买|_num_|次'), {_num_ = leftBuyTimes}), '|')
        display.reloadRichLabel(effectLabel, {c = {
            {text = checkstr(descrArray[1]), fontSize = 22, color = '#5c5c5c'},
            {text = checkstr(descrArray[2]), fontSize = 22, color = '#ba5c5c'},
            {text = checkstr(descrArray[3]), fontSize = 22, color = '#5c5c5c'},
        }})

    -------------------------------------------------
    -- 体力相关
    elseif app.activityHpMgr:GetHpDefineMap(self.payId) then
        local hpDefine   = app.activityHpMgr:GetHpDefineMap(self.payId)
        local isGetMore  = hpDefine.isGetMore == true
        local isDrawType = hpDefine.isDrawType == true

        if isDrawType then
            payMoney:setVisible(false)
            display.commonLabelParams(entryBtn,fontWithColor(14,{text = __('领取'),offset = cc.p(25,0)}))

        elseif self.totalBuyLimit ~= -1 and self.leftBuyTimes <= 0 then
            if isGetMore then
                display.commonLabelParams(entryBtn,fontWithColor(14,{text = __('更多获取'),offset = cc.p(25,0)}))
            else
                display.commonLabelParams(entryBtn,fontWithColor(14,{text = __('今日售罄'),offset = cc.p(25,0)}))
                entryBtn:setEnabled(false)
            end
            payMoney:setVisible(false)

        else
            entryBtn:getLabel():setString(tostring(self.costNum))
        end

        numBtn:getLabel():setString(tostring(self.goodsNum))

        if self.totalBuyLimit ~= -1 then
            local typeDescr  = isDrawType and __('今日还可以领取|_num_|次') or __('今日还可以购买|_num_|次')
            local descrArray = string.split(string.fmt(typeDescr, {_num_ = self.leftBuyTimes}), '|')
            display.reloadRichLabel(effectLabel, {c = {
                {text = checkstr(descrArray[1]), fontSize = 22, color = '#5c5c5c'},
                {text = checkstr(descrArray[2]), fontSize = 22, color = '#ba5c5c'},
                {text = checkstr(descrArray[3]), fontSize = 22, color = '#5c5c5c'},
            }})
        else
            local getTypeDescr = isDrawType and __('领取_name_') or __('购买_name_')
            local goodsName = GoodsUtils.GetGoodsNameById(self.payId)
            display.reloadRichLabel(effectLabel, {c = {
                {text = string.fmt(getTypeDescr, {_name_ = goodsName}), fontSize = 22, color = '#5c5c5c'}
            }})
        end

    -------------------------------------------------
    -- 其他
    else
        entryBtn:getLabel():setString(tostring(self.costNum))
        numBtn:getLabel():setString(tostring(self.goodsNum))

        local descrArray = string.split(string.fmt(__('今日还可以购买|_num_|次'), {_num_ = self.leftBuyTimes}), '|')
        display.reloadRichLabel(effectLabel, {c = {
            {text = checkstr(descrArray[1]), fontSize = 22, color = '#5c5c5c'},
            {text = checkstr(descrArray[2]), fontSize = 22, color = '#ba5c5c'},
            {text = checkstr(descrArray[3]), fontSize = 22, color = '#5c5c5c'},
        }})

    end
	local imgPower = require('common.GoodNode').new({id = self.payId})
	imgPower:setScale(0.8)
    view:addChild(imgPower)
   	display.commonUIParams(imgPower, {po = cc.p(size.width * 0.5,126), ap = cc.p(0.5, 0)})
end


return AddPowerPopup

