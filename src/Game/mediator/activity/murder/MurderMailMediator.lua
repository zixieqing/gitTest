--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）信件Mediator
]]
local MurderMallMediator = class('MurderMallMediator', mvc.Mediator)

function MurderMallMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'MurderMallMediator', viewComponent)
end
-------------------------------------------------
-- inheritance method

function MurderMallMediator:Initial(key)
    self.super.Initial(self, key)
	local viewComponent = require('Game.views.activity.murder.MurderMailView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
end

function MurderMallMediator:InterestSignals()
    local signals = {
        POST.MURDER_DRAW_MAIL_REWARDS.sglName,
	}
	return signals
end
function MurderMallMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.MURDER_DRAW_MAIL_REWARDS.sglName then
        -- 领取奖励
        self:DrawMailRewards(checktable(body.rewards))
    end
end

function MurderMallMediator:OnRegist()
    regPost(POST.MURDER_DRAW_MAIL_REWARDS)
end
function MurderMallMediator:OnUnRegist()
    -- 移除界面
	local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
    unregPost(POST.MURDER_DRAW_MAIL_REWARDS)
end
-------------------------------------------------
-- handler method
--[[
领取按钮点击回调
--]]
function MurderMallMediator:DrawButtonCallback( sender )
    PlayAudioByClickNormal()
    self:SendSignal(POST.MURDER_DRAW_MAIL_REWARDS.cmdName)
end
-------------------------------------------------
-- get /set

-------------------------------------------------
-- private method
--[[
领取信件奖励
@params rewards table 奖励
--]]
function MurderMallMediator:DrawMailRewards( rewards )
    app.uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
    app:UnRegsitMediator("MurderMallMediator")
end
-------------------------------------------------
-- public method


return MurderMallMediator
