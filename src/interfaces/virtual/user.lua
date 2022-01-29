--[[
 * author : kaishiqi
 * descpt : 关于 用户数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 账户登录
virtualData['user/login'] = function(args)
    print("131313")
    local data = {
        sessionId         = virtualData.userData.sessionId,
        userId            = virtualData.userData.userId,
        lastLoginServerId = virtualData.userData.lastLoginServerId,
        servers           = virtualData.userData.servers,
        isGuest           = virtualData.userData.isGuest,
    }
    logt(data,13131)
    return t2t(data)
end
