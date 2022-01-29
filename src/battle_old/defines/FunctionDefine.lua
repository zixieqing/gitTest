--[[
客户端用到的一些工具函数定义
--]]

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

unpack = table.unpack

--[[
对table进行排序
--]]
function sortByKey(t, asc)
    local temp = {}
    for key,_ in pairs(t) do table.insert(temp,key) end
    if asc then
        table.sort(temp,function(a,b) return checkint(a) > checkint(b) end)
    else
        table.sort(temp,function(a,b) return checkint(a) < checkint(b) end)
    end
    return temp
end

--[[
获取table的key数量
--]]
function table.nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

































