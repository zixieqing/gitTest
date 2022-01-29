local socket = require("socket")

require('cocos.cocos2d.functions')

local connection = {}


local sharedScheduler = cc.Director:getInstance():getScheduler()


local function connection_test(ip, port, callback, timeout)
    if not timeout then timeout = 1000 end --1秒的测试
    local connect = assert(socket.tcp())
    connect:settimeout(0)
    local result = connect:connect(ip, port)
	local t
    t = sharedScheduler:scheduleScriptFunc(function()
        local r, w, e = socket.select(nil, {connect}, 0)
        print('--------->>', timeout)
        if w[1] or timeout == 0 then
            connect:close()
            if t > 0 then
                sharedScheduler:unscheduleScriptEntry(t)
            end
            print('--------->>', timeout)
            callback(timeout > 0)
        end
        timeout = timeout - 100
        end, 0.1, false)
end


function connection.network_test(ip, port, callback)
    connection_test(ip, port, callback)
end

return connection
