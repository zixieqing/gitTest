--[[
 * author : liuzhipeng
 * descpt : 特殊活动 皮肤卡池页签mediator
]]
local SpActivitySkinPoolPageMediator = class('SpActivitySkinPoolPageMediator', mvc.Mediator)

local SpActivitySkinPoolPageView = require("Game.views.specialActivity.SpActivitySkinPoolPageView")

function SpActivitySkinPoolPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivitySkinPoolPageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivitySkinPoolPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local centerPos = self.ownerNode_:convertToNodeSpace(cc.p(display.cx, display.cy))
        local view = SpActivitySkinPoolPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.enterBtn:setOnClickScriptHandler(handler(self, self.EnterButtonCallback))
        viewData.shopBtn:setOnClickScriptHandler(handler(self, self.ShopButtonCallback))
    end
end


function SpActivitySkinPoolPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivitySkinPoolPageMediator:OnRegist()
end
function SpActivitySkinPoolPageMediator:OnUnRegist()
end


function SpActivitySkinPoolPageMediator:InterestSignals()
    local signals = {
	}
	return signals
end
function SpActivitySkinPoolPageMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
end


-------------------------------------------------
-- handler method

-------------------------------------------------
-- get /set
-------------------------------------------------
-- private method
--[[
前往按钮回调
--]]
function SpActivitySkinPoolPageMediator:EnterButtonCallback( sender )
    PlayAudioByClickNormal()
    app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {activityId = self.typeData_.activityId}})
end
--[[
商城按钮回调
--]]
function SpActivitySkinPoolPageMediator:ShopButtonCallback( sender )
    PlayAudioByClickNormal()
    if GAME_MODULE_OPEN.NEW_STORE then
		app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.CARD_SKIN})
    else
        app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator" ,params = { goShopIndex = 'cardSkin' }})
    end
end
-------------------------------------------------
-- public method
function SpActivitySkinPoolPageMediator:resetHomeData(homeData)
    self.homeData_ = homeData
end


return SpActivitySkinPoolPageMediator
