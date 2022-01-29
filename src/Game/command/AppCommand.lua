local SimpleCommand = mvc.SimpleCommand

local AppCommand = class("AppCommand", SimpleCommand)


function AppCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

local target = cc.Application:getInstance():getTargetPlatform()

local sharedDirector = cc.CSceneManager:getInstance()
local AndroidPlatform, IosPlatform = 3, 4
local eventDispatcher = sharedDirector:getEventDispatcher()


function AppCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
    local body = signal:GetBody()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_CACHE_MONEY  then--CACHE_MONEY
        local moneyType = checkint(body.type)
        if moneyType == HP_ID then
            --充值体力
            httpManager:Post("pay/buyHp",SIGNALNAMES.CACHE_MONEY, {id = HP_ID})
        elseif moneyType == GOLD_ID then
            --充值金币
            httpManager:Post("pay/buyGold",SIGNALNAMES.CACHE_MONEY, {id = GOLD_ID})
        elseif moneyType == DIAMOND_ID then
            --充值幻晶石
        end
    elseif name == COMMANDS.COMMAND_Story_SubmitMissions then
		local data = signal:GetBody()
		httpManager:Post("plotTask/submitPlotTask", SIGNALNAMES.Story_SubmitMissions_Callback, data)

	elseif name == COMMANDS.COMMAND_Regional_SubmitMissions then
		local data = signal:GetBody()
		httpManager:Post("branch/submitBranchTask", SIGNALNAMES.Story_SubmitMissions_Callback, data)	
    elseif name == COMMANDS.COMMAND_Friend_AssistanceList then
        httpManager:Post("friend/assistanceFriendList", SIGNALNAMES.Friend_AssistanceList_Callback)
    elseif name == COMMANDS.COMMAND_Friend_RequestAssistance then
        local data = signal:GetBody()
        httpManager:Post("friend/requestAssistance", SIGNALNAMES.Friend_RequestAssistance_Callback, data)
    elseif name == COMMANDS.COMMAND_WOLDMAP_UNLOCK then
        --解锁区域
        local data = signal:GetBody()
        httpManager:Post("player/unlockArea", SIGNALNAMES.WORLDMAP_UNLOCK_SIGNALS, data)
    elseif name == COMMANDS.COMMAND_Friend_DelFriend then
        -- 删除好友
        local data = signal:GetBody()
        httpManager:Post("friend/delFriend", SIGNALNAMES.Friend_DelFriend_Callback, data)
    elseif name == COMMANDS.COMMAND_Friend_PopupAddFriend then
        -- 添加好友
        local data = signal:GetBody()
        httpManager:Post("friend/addFriend", SIGNALNAMES.Friend_PopupAddFriend_Callback, data)
    elseif name == COMMANDS.COMMAND_Friend_AddBlacklist then
        -- 加为黑名单
        local data = signal:GetBody()
        httpManager:Post("friend/addBlacklist", SIGNALNAMES.Friend_AddBlacklist_Callback, data)
    elseif name == COMMANDS.COMMAND_Friend_DelBlacklist then
        -- 移除黑名单
        local data = signal:GetBody()
        httpManager:Post("friend/delBlacklist", SIGNALNAMES.Friend_DelBlacklist_Callback, data)
    elseif name == COMMANDS.COMMAND_Chat_GetPlayInfo then
        -- 聊天获取玩家信息
        local data = signal:GetBody()
        httpManager:Post("friend/playerInfo", SIGNALNAMES.Chat_GetPlayerInfo_Callback, data)
    elseif name == COMMANDS.COMMAND_Chat_Assistance then
        local data = signal:GetBody()
        httpManager:Post("friend/assistance",SIGNALNAMES.Chat_Assistance_Callback, data)
    elseif name == COMMANDS.COMMAND_Chat_Report then
        local data = signal:GetBody()
        httpManager:Post("player/report",SIGNALNAMES.Chat_Report_Callback, data)
    end
end

return AppCommand
