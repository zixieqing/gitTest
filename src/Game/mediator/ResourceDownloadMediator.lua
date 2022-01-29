--[[
    下载资源scene
]]
local ResourceDownloadMediator = class('ResourceDownloadMediator', mvc.Mediator)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")

function ResourceDownloadMediator:ctor(params, viewComponent)
	self.super:ctor('ResourceDownloadMediator',viewComponent)
	self.args = checktable(params) or {}
end


-------------------------------------------------
-- inheritance method

function ResourceDownloadMediator:Initial(key)
    self.super.Initial(self, key)

    uiMgr:removeDownloaderSubRes()

	local viewComponent = uiMgr:SwitchToTargetScene('Game.views.ResourceDownloadView')
    self:SetViewComponent(viewComponent)

    local sceneNode = require('root.Downloader').new(handler(self, self.close), checkint(SUBPACKAGE_LEVEL) > 0)
    sceneNode:setPosition(display.center)
    viewComponent:addChild(sceneNode)
end


function ResourceDownloadMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    uiMgr:UpdateBackButton(false)
end


function ResourceDownloadMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
end


function ResourceDownloadMediator:InterestSignals()
    return {}
end
function ResourceDownloadMediator:ProcessSignal(signal)
end


function ResourceDownloadMediator:_updateHandler(event)
    local state = event.event
end

function ResourceDownloadMediator:close()
    if self.args.closeFunc then
        self.args.closeFunc()
    end
    -- AppFacade.GetInstance():BackHomeMediator()
end

return ResourceDownloadMediator
