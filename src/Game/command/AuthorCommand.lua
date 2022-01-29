local SimpleCommand = mvc.SimpleCommand

local AuthorCommand = class("AuthorCommand", SimpleCommand)

function AuthorCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function AuthorCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    local gameManager = AppFacade.GetInstance():GetManager("GameManager")
    if COMMANDS.COMMAND_Login == name then
        local data = signal:GetBody()
        if data then
            httpManager:Post('user/login', SIGNALNAMES.Login_Callback, data)
        end
    elseif COMMANDS.COMMAND_CheckPlay == name then
        httpManager:Post('player/checkPlay', SIGNALNAMES.CheckPlay_Callback)
    elseif COMMANDS.COMMAND_Checkin == name then
        local userInfo = gameManager:GetUserInfo()
        local userId = userInfo.userId
        local sessionId = userInfo.sessionId
        gameManager:RestorePlayerData()
        httpManager:Post('player/checkin', SIGNALNAMES.Checkin_Callback, {lang = i18n.getLang(), userId = userId, sessionId = sessionId})
    elseif COMMANDS.COMMAND_GetUserByUdid == name then
        httpManager:Post('user/getUserByUdid', SIGNALNAMES.GetUserByUdid_Callback)
    elseif COMMANDS.COMMAND_Regist == name then
        local data = signal:GetBody()
        if data then
            httpManager:Post('user/register', SIGNALNAMES.Regist_Callback, data)
        end
    elseif COMMANDS.COMMAND_CreateRole == name then
        local data = signal:GetBody()
        if data then
            local userInfo = {playerId = 0}
            gameManager:UpdateAuthorInfo(userInfo)
            httpManager:Post('Player/create', SIGNALNAMES.CreateRole_Callback, data, true)
        end
    elseif COMMANDS.COMMAND_SDK_LOGIN == name then
        --sdk的登录操作
        local data = signal:GetBody()
        httpManager:Post('User/channelLogin', SIGNALNAMES.Channel_Login_Callback, data)
    elseif COMMANDS.COMMAND_RandomRoleName == name then
        local data = signal:GetBody()
        -- todo  添加 协议相关字段
        httpManager:Post('player/name', SIGNALNAMES.RandomRoleName_Callback, data) 
    elseif COMMANDS.COMMAND_European_Agreement == name then
        local data = signal:GetBody()
        -- 欧盟隐私协议通过
        httpManager:Post('user/zmEuropeanAgreement', SIGNALNAMES.European_Agreement_Callback, data) 
    elseif COMMANDS.COMMAND_SERVER_APPOINT == name then
        local data = signal:GetBody()
        httpManager:Post('user/reservationInfo', SIGNALNAMES.SERVER_APPOINT_Callback, data, true)
    end
end

return AuthorCommand
