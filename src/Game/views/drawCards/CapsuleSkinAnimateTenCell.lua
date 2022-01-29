--[[
皮肤抽卡十连view
--]]
local CapsuleSkinAnimateTenCell = class('CapsuleSkinAnimateTenCell', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleSkinAnimateTenCell'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    SKIP_BTN         = _res('arts/stage/ui/opera_btn_skip.png'),
    COMMON_BTN       = _res('ui/common/common_btn_orange.png')
}
function CapsuleSkinAnimateTenCell:ctor( ... )
    local args = unpack({...}) or {}
    self.reward = args.reward or {}
    self.cb = args.cb
    self.showAnimation = args.showAnimation or false
    self:InitUI()
end
--[[
init ui
--]]
function CapsuleSkinAnimateTenCell:InitUI()
    local reward = self.reward
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local coinList = {}
        for i = 1, 10 do
            view:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(i*0.1),
                    cc.CallFunc:create(function()
                        local coinNode = require('Game.views.drawCards.CapsuleSkinAnimateCoinNode').new({reward = reward[i]})
                        local posX = size.width / 2 + ((-2 + (i - 1) % 5) * 250)
                        local posY = size.height / 2 + 190 - math.floor((i - 1) / 5) * 310
                        display.commonUIParams(coinNode, {po = cc.p(posX, posY)})
                        view:addChild(coinNode, 1)
                        table.insert(coinList, coinNode)
                    end)
                )
            )
        end
        -- 跳过按钮
        local skipBtn = display.newButton(display.width - display.SAFE_L, 75, {n = RES_DICT.SKIP_BTN, scale9 = true , size = cc.size(206,60), ap = cc.p(1, 0.5)})
        view:addChild(skipBtn, 10)
        local skipLabel = display.newLabel(skipBtn:getContentSize().width - 10, skipBtn:getContentSize().height / 2, {text = __('跳过'), fontSize = 24, color = '#ffffff', ap = display.RIGHT_CENTER ,  font = TTF_GAME_FONT, ttf = true, outline = '#4e2e1e', outlineSize = 2})
        skipBtn:addChild(skipLabel, 1)
        -- 确定按钮
        local confirmBtn = display.newButton(display.width / 2, 60, {n = RES_DICT.COMMON_BTN})
        confirmBtn:setVisible(false)
        view:addChild(confirmBtn, 10)
        local confirmLabel = display.newLabel(confirmBtn:getContentSize().width / 2, confirmBtn:getContentSize().height / 2, fontWithColor(14, {text = __('确认')}))
        confirmBtn:addChild(confirmLabel, 1)
        return {
            view             = view,
            skipBtn          = skipBtn,
            confirmBtn       = confirmBtn,
            coinList         = coinList,
        }
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.skipBtn:setOnClickScriptHandler(handler(self, self.SkipButtonCallback))
        self.viewData.confirmBtn:setOnClickScriptHandler(handler(self, self.ConfirmButtonCallback))
        AppFacade.GetInstance():RegistObserver(CAPSULE_SKIN_COIN_CLICK, mvc.Observer.new(handler(self, self.CoinClickEvent), self))
    end, __G__TRACKBACK__)
end
--[[
跳过按钮点击回调
--]]
function CapsuleSkinAnimateTenCell:SkipButtonCallback( sender )
    PlayAudioByClickNormal()
    local viewData = self.viewData 
    local coinList = viewData.coinList
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    viewData.skipBtn:setVisible(false)
    local num = 0
    for i, v in ipairs(coinList) do
        if not v:IsCoinShow() then
            num = num + 1
            v:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(num * 0.15),
                    cc.CallFunc:create(function () 
                        v:CoinClickAction()
                    end)
                )
            )
        end
    end
    if num > 0 then
        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(num * 0.15 + 0.1),
                cc.CallFunc:create(function () 
                    self:UpdateButtonState()
                    app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
                end)
            )
        )
    else
        app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
        self:UpdateButtonState()
    end
end
--[[
确定按钮点击回调
--]]
function CapsuleSkinAnimateTenCell:ConfirmButtonCallback( sender )
    PlayAudioByClickNormal()
    if self.cb then
        self.cb()
    end
    self:runAction(cc.RemoveSelf:create())
end
--[[
硬币点击事件处理
--]]
function CapsuleSkinAnimateTenCell:CoinClickEvent( stage, signal )
    if tolua.isnull(self) then return end
    self:UpdateButtonState()
end
--[[
更新按钮状态
--]]
function CapsuleSkinAnimateTenCell:UpdateButtonState()
    local viewData = self.viewData 
    local coinList = viewData.coinList
    local num = 0
    for i, v in ipairs(coinList) do
        if not v:IsCoinShow() then
            num = num + 1
        end
    end
    viewData.confirmBtn:setVisible(not (num > 0))
    viewData.skipBtn:setVisible(num > 0)
end
function CapsuleSkinAnimateTenCell:onCleanup()
	--清理逻辑
    AppFacade.GetInstance():UnRegistObserver(CAPSULE_SKIN_COIN_CLICK, self)
end
return CapsuleSkinAnimateTenCell