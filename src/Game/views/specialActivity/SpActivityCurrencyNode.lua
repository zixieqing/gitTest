--[[
特殊活动 货币node
--]]
local SpActivityCurrencyNode = class('SpActivityCurrencyNode', function ()
    local node = CLayout:create(cc.size(200, 50))
    node.name = 'home.SpActivityCurrencyNode'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    NORMAL_BG = _res('ui/home/specialActivity/common_btn_huobi_2.png'),
    BTN_BG    = _res('ui/home/specialActivity/common_btn_huobi.png'),
}
--[[
@params goodsId int 道具id

--]]
function SpActivityCurrencyNode:ctor( ... )
    self.args = unpack({...}) or {}
    self.goodsId = checkint(self.args.goodsId or GOLD_ID) 
    self:InitUI()
end
--[[
init ui
--]]
function SpActivityCurrencyNode:InitUI()
    local function CreateView()
        local size = cc.size(200, 50)
        local view = CLayout:create(size)
        local currencyBtn = display.newButton(size.width, size.height / 2, {n = RES_DICT.BTN_BG, ap = cc.p(1, 0.5)})
        view:addChild(currencyBtn, 1)
        local countLabel = display.newLabel(size.width - 55, size.height / 2, {ap = cc.p(1, 0.5), ttf = true, font = TTF_GAME_FONT, text = "", fontSize = 21, color = '#ffffff'})
        view:addChild(countLabel, 3)
        local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), 30, size.height / 2)
        goodsIcon:setScale(0.25)
        view:addChild(goodsIcon, 3)
        return {
            view             = view,
            currencyBtn      = currencyBtn,
            countLabel       = countLabel,
            goodsIcon        = goodsIcon,
        }
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self.viewData.currencyBtn:setOnClickScriptHandler(handler(self, self.BgButtonCallback))
        self:RefreshUI()
    end, __G__TRACKBACK__)
end
--[[
刷新ui
--]]
function SpActivityCurrencyNode:RefreshUI()
    local goodsId = self.goodsId
    local viewData = self.viewData
    viewData.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
    viewData.countLabel:setString(tostring(GetMoneyFormat(checkint(app.gameMgr:GetAmountByIdForce(goodsId)))))
end
--[[
点击回调
--]]
function SpActivityCurrencyNode:BgButtonCallback( sender )
    PlayAudioByClickNormal()
    local goodsId = self.goodsId 
    if goodsId == GOLD_ID then
        if not app.uiMgr:GetCurrentScene():getChildByName('MoneyTreeView') and CommonUtils.GetModuleAvailable(MODULE_SWITCH.MONEYTREE) then
			local layer = require( 'Game.views.MoneyTreeView' ).new({callback = function ()
				AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMAND_CACHE_MONEY, {type = GOLD_ID})
			end
			})
			layer:setPosition(display.center)
			app.uiMgr:GetCurrentScene():AddDialog(layer)
			layer:setName('MoneyTreeView')
		end
    elseif goodsId == DIAMOND_ID then
        if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PAY) and CommonUtils.GetModuleAvailable(MODULE_SWITCH.SHOP) then
            if GAME_MODULE_OPEN.NEW_STORE then
                app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.DIAMOND})
            else
                app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
            end
		end
    end
end
return SpActivityCurrencyNode