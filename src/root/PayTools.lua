local Paytools = {}


local STORE_KEY = "PAY_TOOLS_STORE_KEY"

local shareUserDefault = cc.UserDefault:getInstance()
function Paytools.StoreRecipt(transId, orderInfo)
    local data = shareUserDefault:getStringForKey(STORE_KEY)
    local t = {}
    if data then
        t = (json.decode(data) or {}) --解析出来表
    end
    if not t then t = {} end
    local have = 0
    for k, v in pairs( t ) do
        if v.transactionIdentifier == transId then
            have = 1
            break
        end
    end
    if have == 0 then
        orderInfo.transactionIdentifier = transId
        table.insert(t, orderInfo)
        -- table.insert(t, {transactionIdentifier = transId, receipt = crypto.encodeBase64(receipt)})
    end
    shareUserDefault:setStringForKey(STORE_KEY,json.encode(t))
    shareUserDefault:flush()
end

function Paytools.RemoveRecipt(transId)
    local data = shareUserDefault:getStringForKey(STORE_KEY)
    if data then
        local t = json.decode(data) --解析出来表
        if t and next(t) ~= nil then
            for k, v in pairs( t ) do
                if v.transactionIdentifier == transId then
                    t[k] = nil
                end
            end
            --store recipts
            if next(t) == nil then
                t = {}
            end
            shareUserDefault:setStringForKey(STORE_KEY, json.encode(t))
            shareUserDefault:flush()
        end
    end
end

function Paytools.RetriveRecipts()
    local data = shareUserDefault:getStringForKey(STORE_KEY)
    local t = {}
    if data then
        t = json.decode(data) --解析出来表
        if not t then
            t = {} --如果解析出错
        end
    end
    return t
end

return Paytools
