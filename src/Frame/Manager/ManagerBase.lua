---@class ManagerBase
local ManagerBase = class('ManagerBase')



function ManagerBase:ctor( ... )
end

function ManagerBase:GetAudioManager(  )
	return AppFacade.GetInstance():GetManager("AudioManager")
end
---@return Facade
function ManagerBase:GetFacade(  )
    return AppFacade.GetInstance()
end
---@return DataManager
function ManagerBase:GetDataManager(  )
	return AppFacade.GetInstance():GetManager("DataManager")
end
---@return GameManager
function ManagerBase:GetGameManager(  )
	return AppFacade.GetInstance():GetManager("GameManager")
end
---@return TimerManager
function ManagerBase:GetTimerManager(  )
	return AppFacade.GetInstance():GetManager("TimerManager")
end
---@return UIManager
function ManagerBase:GetUIManager(  )
	return AppFacade.GetInstance():GetManager("UIManager")
end
---@return SocketManager
function ManagerBase:GetSocketManager(  )
	return AppFacade.GetInstance():GetManager("SocketManager")
end
---@return ChatSocketManager
function ManagerBase:GetChatSocketManager(  )
	return AppFacade.GetInstance():GetManager("ChatSocketManager")
end
---@return HttpManager
function ManagerBase:GetHttpManager(  )
	return AppFacade.GetInstance():GetManager("HttpManager")
end

return ManagerBase
