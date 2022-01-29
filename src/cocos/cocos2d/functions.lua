---@type io
local io = io
---@type math
local math = math
---@type table
local table = table
---@type string
local string = string
--[[
]]
-- ### table.push
--
-- Add the `val` as the last item to the `tbl`.
--
-- - `tbl` is a table.
-- - `val` is a value.
--
function table.push(tbl, val)
    table.insert(tbl, val)
    return tbl
end

-- ### array.pop
--
-- Return and remove the last item in the `tbl`.
--
-- - `tbl` is a table.
--
function table.pop(tbl)
    return table.remove(tbl, #tbl)
end

-- ### array.shift
--
-- Return and remove the first item in the `tbl`.
--
-- - `tbl` is a table.
--
function table.shift(tbl)
    return table.remove(tbl, 1)
end

-- ### array.unshift
--
-- Add the `val` as the first item in the `tbl`.
--
-- - `tbl` is a table.
-- - `val` is a value.
--
function table.unshift(tbl, val)
    table.insert(tbl, 1, val)
    return tbl
end

-- ### array.reverse
--
-- Return a new table by reversing the order of the items in the `tbl`.
--
-- - `tbl` is a table.
--
function table.reverse(tbl)
    local results = {}
    for _, val in ipairs(tbl) do
        table.insert(results, 1, val)
    end
    return results
end

-- ### array.join
--
-- Return a string by joining the values in the `tbl` with the `separator`.
--
-- - `tbl`       is a table.
-- - `separator` is a string.
--
function table.join(tbl, separator)
    separator = separator or ''
    return table.concat(tbl, separator)
end

-- ### array.split
--
-- Return a table by splitting the `str` by the `separator`.
--
-- - `tbl`       is a table.
-- - `separator` is a string.
--
function table.split(str, separator)
    local results = {}
    local i = 1
    separator = separator or '%s'
    for val in str:gmatch('([^' .. separator .. ']+)') do
        results[i] = val
        i = i + 1
    end
    return results
end

-- ### array.slice
--
-- Return a specific portion of the `tbl`.
--
-- - `tbl`   is a table.
-- - `start` is a number.
-- - `stop`  is a number.
--
function table.slice(tbl, start, stop)
    local results = {}
    local length  = #tbl
    start = start or 1
    stop  = stop or length
    for i = start, stop do
        table.insert(results, tbl[i])
    end
    return results
end
--[[
--一个对象的内存地址
--]]
function ID( t )
    local name = tostring( t )
    local target = nil
    local pos = name:find('0x')
    if pos then
        target = string.sub( name, pos)
    else
        local pos = name:find(':')
        if pos then
            target = string.trim(string.sub(name, pos))
        end
    end
    if not target then target = name end
    return target
end
---####
--####
--
--
function printLog(tag, fmt, ...)
    local t = {
        "[",
        string.upper(tostring(tag)),
        "] ",
        string.format(tostring(fmt), ...)
    }
    print(table.concat(t))
end

function printError(fmt, ...)
    printLog("ERR", fmt, ...)
    print(debug.traceback("", 2))
end

function printInfo(fmt, ...)
    if type(DEBUG) ~= "number" or DEBUG < 2 then return end
    printLog("INFO", fmt, ...)
end

local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function dump(value, desciption, nesting)
    if type(DEBUG) ~= "number" or DEBUG < 1 then return end
    if type(nesting) ~= "number" then nesting = 4 end

    local lookupTable = {}
    local result = {}

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(desciption), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(desciption))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

function printf(fmt, ...)
    print(string.format(tostring(fmt), ...))
end

function checknumber(value, base)
    return tonumber(value, base) or 0
end

function checkint(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

function checkstr(value)
    return string.isEmpty(value) and '' or tostring(value)
end

function checkbool(value)
    return (value ~= nil and value ~= false)
end

function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end

function isset(hashtable, key)
    local t = type(hashtable)
    return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end

local setmetatableindex_
setmetatableindex_ = function(t, index)
    if type(t) == "userdata" then
        local peer = tolua.getpeer(t)
        if not peer then
            peer = {}
            tolua.setpeer(t, peer)
        end
        setmetatableindex_(peer, index)
    else
        local mt = getmetatable(t)
        if not mt then mt = {} end
        if not mt.__index then
            mt.__index = index
            setmetatable(t, mt)
        elseif mt.__index ~= index then
            setmetatableindex_(mt, index)
        end
    end
end
setmetatableindex = setmetatableindex_
--[[
--速度性能过慢TODO
--]]
---@generic T
---@param object T
---@return T
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local newObject = {}
        lookup_table[object] = newObject
        for key, value in pairs(object) do
            newObject[_copy(key)] = _copy(value)
        end
        return setmetatable(newObject, getmetatable(object))
    end
    return _copy(object)
end

function class(classname, ...)
    local cls = {__cname = classname}

    local supers = {...}
    for _, super in ipairs(supers) do
        local superType = type(super)
        assert(superType == "nil" or superType == "table" or superType == "function",
            string.format("class() - create class \"%s\" with invalid super class type \"%s\"",
                classname, superType))

        if superType == "function" then
            assert(cls.__create == nil,
                string.format("class() - create class \"%s\" with more than one creating function",
                    classname));
            -- if super is function, set it to __create
            cls.__create = super
        elseif superType == "table" then
            if super[".isclass"] then
                -- super is native class
                assert(cls.__create == nil,
                    string.format("class() - create class \"%s\" with more than one creating function or native class",
                        classname));
                cls.__create = function() return super:create() end
            else
                -- super is pure lua class
                cls.__supers = cls.__supers or {}
                cls.__supers[#cls.__supers + 1] = super
                if not cls.super then
                    -- set first super pure lua class as class.super
                    cls.super = super
                end
            end
        else
            error(string.format("class() - create class \"%s\" with invalid super type",
                classname), 0)
        end
    end

    cls.__index = cls
    if not cls.__supers or #cls.__supers == 1 then
        setmetatable(cls, {__index = cls.super})
    else
        setmetatable(cls, {__index = function(_, key)
            local supers = cls.__supers
            for i = 1, #supers do
                local super = supers[i]
                if super[key] then return super[key] end
            end
        end})
    end

    if not cls.ctor then
        -- add default constructor
        cls.ctor = function() end
    end
    cls.new = function(...)
        local instance
        if cls.__create then
            instance = cls.__create(...)
        else
            instance = {}
        end
        setmetatableindex(instance, cls)
        instance.class = cls
        instance:ctor(...)
        return instance
    end
    cls.create = function(_, ...)
        return cls.new(...)
    end

    return cls
end

local iskindof_
iskindof_ = function(cls, name)
    local __index = rawget(cls, "__index")
    if type(__index) == "table" and rawget(__index, "__cname") == name then return true end

    if rawget(cls, "__cname") == name then return true end
    local __supers = rawget(cls, "__supers")
    if not __supers then return false end
    for _, super in ipairs(__supers) do
        if iskindof_(super, name) then return true end
    end
    return false
end

function iskindof(obj, classname)
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then return false end

    local mt
    if t == "userdata" then
        if tolua.iskindof(obj, classname) then return true end
        mt = tolua.getpeer(obj)
    else
        mt = getmetatable(obj)
    end
    if mt then
        return iskindof_(mt, classname)
    end
    return false
end

function import(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
        if string.byte(moduleName, offset) ~= 46 then -- .
            moduleFullName = string.sub(moduleName, offset)
            if currentModuleNameParts and #currentModuleNameParts > 0 then
                moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
            end
            break
        end
        offset = offset + 1

        if not currentModuleNameParts then
            if not currentModuleName then
                local n,v = debug.getlocal(3, 1)
                currentModuleName = v
            end

            currentModuleNameParts = string.split(currentModuleName, ".")
        end
        table.remove(currentModuleNameParts, #currentModuleNameParts)
    end

    return require(moduleFullName)
end

function handler(obj, method)
    return function(...)
        if method then
            return method(obj, ...)
        end
    end
end

function math.newrandomseed()
    local ok, socket = pcall(function()
        return require("socket")
    end)

    if ok then
        math.randomseed(socket.gettime() * 1000)
    else
        math.randomseed(os.time())
    end
    math.random()
    math.random()
    math.random()
    math.random()
end

function math.round(value)
    value = checknumber(value)
    return math.floor(value + 0.5)
end

local pi_div_180 = math.pi / 180
function math.angle2radian(angle)
    return angle * pi_div_180
end

local pi_mul_180 = math.pi * 180
function math.radian2angle(radian)
    return radian / pi_mul_180
end

function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

function io.readfile(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function io.pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

function io.filesize(path)
    local size = false
    local file = io.open(path, "r")
    if file then
        local current = file:seek()
        size = file:seek("end")
        file:seek("set", current)
        io.close(file)
    end
    return size
end

function table.nums(t)
    local count = 0
    if t then
        for k, v in pairs(t) do
            count = count + 1
        end
    end
    return count
end

function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

function table.valuesAt(hashtable, key)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v[key]
    end
    return values
end

function table.each(t, func)
    for k,v in pairs(t) do
        func(k, v)
    end
end

function table.haskey(t, key)
    return type(t) == 'table' and t[key] ~= nil
end

function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

function table.insertto(dest, src, begin)
    begin = checkint(begin)
    if begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end

function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

function table.map(t, fn)
    for k, v in pairs(t) do
        t[k] = fn(v, k)
    end
end

function table.walk(t, fn)
    for k,v in pairs(t) do
        fn(v, k)
    end
end

function table.filter(t, fn)
    for k, v in pairs(t) do
        if not fn(v, k) then t[k] = nil end
    end
end

function table.unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end
function string.split2(input, delimiter)
    return string.len(input or '') == 0 and {} or string.split(input, delimiter)
end

function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.dcfirst(input)
    return string.lower(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end
function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

function string.utf8len(input)
    if utf8 and utf8.len then
        return utf8.len(input)
    else
        local len  = string.len(input)
        local left = len
        local cnt  = 0
        local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
        while left ~= 0 do
            local tmp = string.byte(input, -left)
            local i   = #arr
            while arr[i] do
                if tmp >= arr[i] then
                    left = left - i
                    break
                end
                i = i - 1
            end
            cnt = cnt + 1
        end
        return cnt
    end
end


-- 格式化字符串方法的扩展和封装。
-- [用法1] format 后面跟一个 hashMap。会以后面的tabel的key查找format，替换成对应的value。
--
-- 例子1：string.fmt('_name_ get a _goods_', {['_name_'] = 'test', ['_goods_'] = 'apple'})
-- 结果1：test get a apple
--
-- 例子2：string.fmt('pi is _value_', { ['_value_'] = {'%0.4f', 3.1415926} })
-- 结果2：pi is 3.1416
--
-- [用法2] 按照format中使用 %+数字 的方式，依次替换为对应位置的参数。
--
-- 例子1：string.fmt('%1 %2 (%3s-%4s)', 'xxx', 'life', 1950, 1970)
-- 结果1：xxx life (1950-1970)
--
-- 例子2：string.fmt('current time %1:%2', {'%02d', 2}, {'%02d', 34})
-- 结果2：current time 02:34
--
-- return string
function string.fmt(format, ...)
    local args   = {...}
    local result = tostring(format)

    -- 以hashMap结构，自定义key替换value
    if #args == 1 and type(args[1]) == 'table' then
        for k,v in pairs(args[1]) do
            local vstr = tostring(v)
            if type(v) == 'table' then
                vstr = string.format(tostring(v[1]), tostring(v[2]))
            end
            if xTry ~= nil then  -- 居然还有加载定义 xTry 之前就使用这个方法的时候
                xTry(function()
                    result = (string.gsub(tostring(result), tostring(k), vstr))
                end, function(msg)
                    result = tostring(result)
                    assert(false, 'string.fmt error, format = ' .. tostring(format)  .. ' , k = ' .. tostring(k) .. ' , vstr = ' .. tableToString(vstr))
                end)
            else
                result = (string.gsub(tostring(result), tostring(k), vstr))
            end
        end

    -- 以 %1 开始，按照参数顺序替换
    else
        local argsMap = {}
        for i,v in ipairs(args) do
            local vstr = tostring(v)
            if type(v) == 'table' then
                vstr = string.format(tostring(v[1]), tostring(v[2]))
            end
            argsMap['%'..i] = vstr
        end
        -- format = (string.gsub(tostring(format), '(%%[0-9]+)([ ^%%]+_)', '%1'))
        result = (string.gsub(tostring(format), '%%[0-9]+', argsMap))
    end

    return result
end

function string.isEmpty(value)
    return value == nil or string.len(tostring(value)) == 0
end


function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

--connvert int color #rrggbbaa to color4b
function ccc4FromInt(hex)
    hex = hex:gsub('#',"")
    local red = tonumber(hex:sub(1, 2),16)
    local green = tonumber(hex:sub(3,4),16)
    local blue = tonumber(hex:sub(5,6),16)
    local alpha = 255
    if #hex > 6 then
        alpha = tonumber(hex:sub(7,8),16)
    end
    return cc.c4b(red,green,blue,alpha)
end

function ccc3FromInt(hex)
    hex = hex:gsub('#',"")
    local red = tonumber(hex:sub(1, 2),16)
    local green = tonumber(hex:sub(3,4),16)
    local blue = tonumber(hex:sub(5,6),16)
    return cc.c3b(red,green,blue)
end

function ccc4fFromInt(hex)
    hex = hex:gsub('#',"")
    local red = tonumber(hex:sub(1, 2),16) / 255.0
    local green = tonumber(hex:sub(3,4),16) / 255.0
    local blue = tonumber(hex:sub(5,6),16) / 255.0
    local alpha = 1.0
    if #hex > 6 then
        alpha = tonumber(hex:sub(7,8),16) / 255.0
    end
    return cc.c4f(red,green,blue,alpha)
end

function doFile(path)
    local fileData = FTUtils:getFileData(path)
    if fileData then
        local fun = loadstring(fileData)
        local ret, flist = pcall(fun)
        if ret then
            return flist
        end
        return flist
    else
        return nil
    end
end

function shuffle(t)
    math.randomseed(os.time())
    assert(t, "table.shuffle() expected a table, got nil")
    local iterations = #t
    local j
    for i = iterations, 2, -1 do
        j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end


---[[--
-- 添加一排序方法
--]]
--升序排序 /quicksort  asc
--target: 目标table/target table such as {9, -1, 4, 5, 18, 1, 8, 0, 20, 31}
--low：起始下标/start position
--high：终止下标/end position
function quick_sort_ASC(target, low, high)
    local t = low or 1
    local r = high or #target
    local temp = target[t]

    if low < high then
        while(t < r) do
            while(target[r] >= temp and t < r) do
                r = r - 1
            end
            target[t] = target[r]
            while(target[t] <= temp and t < r) do
                t = t + 1
            end
            target[r] = target[t]
        end
        target[t] = temp
        quick_sort_ASC(target, low, t-1)
        quick_sort_ASC(target, r+1, high)
    end
end

--降序排序 /quicksort  desc
--target: 目标table/target table such as {9, -1, 4, 5, 18, 1, 8, 0, 20, 31}
--low：起始下标/start position
--high：终止下标/end position
function quick_sort_DESC(target, low, high)
    local t = low or 1
    local r = high or #target
    local temp = target[t]

    if low < high then
        while(t < r) do
            while(target[r] <= temp and t < r) do
                r = r - 1
            end
            target[t] = target[r]
            while(target[t] >= temp and t < r) do
                t = t + 1
            end
            target[r] = target[t]
        end
        target[t] = temp
        quick_sort_DESC(target, low, t-1)
        quick_sort_DESC(target, r+1, high)
    end
end

-- 判断utf8字符byte长度
-- 0xxxxxxx - 1 byte
-- 110yxxxx - 192, 2 byte
-- 1110yyyy - 225, 3 byte
-- 11110zzz - 240, 4 byte
local function chsize(char)
    if not char then
        print("not char")
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end

-- 计算utf8字符串字符数, 各种字符都按一个字符计算
-- 例如utf8len("1你好") => 3
function utf8len(str)
--[[
    -- 这个实现有bug，所以直接 return string.utf8len 的结果好了
    -- 比如 "กาเนอเล่" 返回的是16，而 string.utf8len 返回的是 8
    local len = 0
    local currentIndex = 1
    while currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + chsize(char)
        len = len +1
    end
    return len
]]
    return string.utf8len(str)
end

-- 截取utf8 字符串
-- str:         要截取的字符串
-- startChar:   开始字符下标,从1开始
-- numChars:    要截取的字符长度
function utf8sub(str, startChar, numChars)
    if utf8 and utf8.sub then
        return utf8.sub(str, startChar, numChars == 1 and startChar or numChars)
    else
        local startIndex = 1
        while startChar > 1 do
            local char = string.byte(str, startIndex)
            startIndex = startIndex + chsize(char)
            startChar = startChar - 1
        end
        
        local currentIndex = startIndex
        while numChars > 0 and currentIndex <= #str do
            local char = string.byte(str, currentIndex)
            currentIndex = currentIndex + chsize(char)
            numChars = numChars -1
        end
        return str:sub(startIndex, currentIndex - 1)
    end
end

function seperateString(message,numberChar)
    message = string.restorehtmlspecialchars(message)
    local len = string.utf8len(message)
    local linenumber = math.ceil(len/numberChar)
    local text = ''
    for i= 1, linenumber do
        text = text .. utf8sub(message,(i - 1) * numberChar + 1,numberChar) .. '\n'
    end
    return text
end
