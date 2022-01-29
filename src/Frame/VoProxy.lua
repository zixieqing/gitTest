-- TODO 定义规范 和 demo
--[[
 * author : kaishiqi
 * descpt : vo结构代理
]]
local VoProxy = class('VoProxy', mvc.Proxy)

local MAX_STRUCT_LEVEL = 16

VoProxy.EVENTS = {
    CHANGE = 1,  -- set event
    DELETE = 2,  -- del event
    APPEND = 3,  -- add event
}


-- is type [_int, _num, _str, _map, _lst, _bol]
function VoProxy.IsTypeInt(voDefine)
    return voDefine and voDefine._int ~= nil or false
end
function VoProxy.IsTypeNum(voDefine)
    return voDefine and voDefine._num ~= nil or false
end
function VoProxy.IsTypeStr(voDefine)
    return voDefine and voDefine._str ~= nil or false
end
function VoProxy.IsTypeMap(voDefine)
    return voDefine and voDefine._map ~= nil or false
end
function VoProxy.IsTypeList(voDefine)
    return voDefine and voDefine._lst ~= nil or false
end
function VoProxy.IsTypeBool(voDefine)
    return voDefine and voDefine._bol ~= nil or false
end


-- get [_default]
function VoProxy.ValueDefault(voDefine)
    local default = voDefine and voDefine._default or nil
    if VoProxy.IsTypeMap(voDefine) or VoProxy.IsTypeList(voDefine) then
        if VoProxy.IsVariableKey(voDefine) then
            default = nil
        else
            default = type(default) == 'table' and clone(default) or {}
        end
    -- int
    elseif VoProxy.IsTypeInt(voDefine) then
        default = checkint(default)
    -- num
    elseif VoProxy.IsTypeNum(voDefine) then
        default = checknumber(default)
    -- str
    elseif VoProxy.IsTypeStr(voDefine) then
        default = checkstr(default)
    -- bool
    elseif VoProxy.IsTypeBool(voDefine) then
        default = checkbool(default)
    end
    return default
end


-- get [_key]
function VoProxy.ValueKeyword(voDefine)
    return voDefine and voDefine._key or ''
end


-- get [_uuid]
function VoProxy.GetDefineId(voDefine)
    if voDefine._uuid == nil then
        voDefine._uuid = ID(voDefine) .. '*' .. VoProxy.ValueKeyword(voDefine)
    end
    return voDefine._uuid
end


-- get [_event]
function VoProxy.GetEventId(voDefine, eventPrefix)
    if voDefine._event == nil then
        voDefine._event = '[VO]' .. VoProxy.GetDefineId(voDefine)
    end
    return eventPrefix .. voDefine._event
end


-- is variable key
function VoProxy.IsVariableKey(voDefine)
    return string.sub(VoProxy.ValueKeyword(voDefine), 0, 1) == '$'
end


-- is define attr
function VoProxy.IsDefineAttr(voDefineKey)
    return string.sub(voDefineKey, 0, 1) == '_'
end


-- is define table type
function VoProxy.IsDefineTable(voDefine)
    return type(voDefine) == 'table'
end


--[[
    bind event
    -- @param proxyName   : str    proxy name
    -- @param voDefineMap : map    [key : voDefine] = callback : function
    -- @param context     : any    event receiver
    ]]
    function VoProxy.EventBind(proxyName, voDefineMap, context)
        local methodList = {}
        for voDefine, bindMethod in pairs(voDefineMap) do
            local eventId = VoProxy.GetEventId(voDefine, proxyName)
            local handler = mvc.Observer.new(nil, context)
            if type(bindMethod) == 'table' then
                handler.methods = bindMethod
                table.insertto(methodList, bindMethod)
            else
                handler.method = bindMethod
                table.insert(methodList, bindMethod)
            end
            app:RegistObserver(eventId, handler)
        end
        return methodList
    end
    
    
--[[
    unbind event
    -- @param proxyName   : str    proxy name
    -- @param voDefineMap : map    [key : voDefine] = callback : function
    -- @param context     : any    event receiver
]]
function VoProxy.EventUnbind(proxyName, voDefineMap, context)
    for voDefine, bindMethod in pairs(voDefineMap) do
        local eventId = VoProxy.GetEventId(voDefine, proxyName)
        app:UnRegistObserver(eventId, context)
    end
end


-- dispatch event
--[[
    dispatch event
    -- @param proxyName : str      proxy name
    -- @param voDefine  : table    VoDefine object
    -- @param evtData   : any      event data
    -- @param evtType   : int      event type (optional)
]]
function VoProxy.EventDispath(proxyName, voDefine, evtData, evtType)
    local eventId = VoProxy.GetEventId(voDefine, proxyName)
    app:DispatchObservers(eventId, evtData, evtType)
end


-------------------------------------------------------------------------------
-- class method
-------------------------------------------------------------------------------

function VoProxy:ctor(proxyName, voStract, parentVoProxy, rootVoProxy, eventPrefix)
    self.super.ctor(self, proxyName)

    self.metaVoStract_   = voStract or {}       -- meta voStract
    self.parentVoProxy_  = parentVoProxy        -- parent voProxy
    self.rootVoProxy_    = rootVoProxy or self  -- root voProxy
    self.subVoProxyMap_  = {}                   -- subMap [key:ID(voDefine)] = sub VoProxy
    self.voDefineIdMap_  = {}                   -- defineMap [key:ID(voDefine)] = voProxy (only use to root)
    self.keysVoProxyMap_ = {}                   -- keys voProxy [dataKey:int/str] = sub VoProxy
    self.currentDataKey_ = nil
    self.eventPrefix_    = eventPrefix or proxyName

    self:parseVoStract_()
    
    if not parentVoProxy then
        -- init root stract data
        self:setData({})
        -- bind root voStract
        self:bindRootDefine_(voStract, self)
        -- update root stract
        self:update(VoProxy.ValueDefault(self.metaVoStract_), true)
    end
end


function VoProxy:getRootVoProxy()
    return self.rootVoProxy_
end


function VoProxy:getParentVoProxy()
    return self.parentVoProxy_
end


function VoProxy:key()
    return self.currentDataKey_
end


--[[
    has VoProxy data (valid on list or map type)
    -- @param voDefine : table      VoDefine object
    -- @param dataKey  : str/int    table data key (optional)
]]
function VoProxy:has(voDefine, dataKey)
    return self:size(voDefine, dataKey) > 0
end


--[[
    get VoProxy object (list or map type) or VoProxy data (other type)
    -- @param voDefine : table      VoDefine object
    -- @param dataKey  : str/int    table data key (optional)
]]
function VoProxy:get(voDefine, dataKey)
    local parentVoProxy = self:takeRootDefine_(voDefine)               -- on parent voProxy
    local parentVoData  = checktable(parentVoProxy:getData())          -- parent data
    local defineDatakey = dataKey or VoProxy.ValueKeyword(voDefine)    -- data key
    local defaultValue  = VoProxy.ValueDefault(voDefine)               -- default value
    local voProxyValue  = parentVoData[defineDatakey] or defaultValue  -- self data

    if VoProxy.IsTypeList(voDefine) or VoProxy.IsTypeMap(voDefine) then
        local isRootDefine  = parentVoProxy:getRootVoProxy().metaVoStract_ == voDefine
        local defineVoProxy = isRootDefine and parentVoProxy:getRootVoProxy() or parentVoProxy:takeSubVoProxy_(voDefine)
        if defineVoProxy then
            -- logs('[VoProxy]', '@@@@@@@@@@@@@@@@@@@@@@ .. ' .. defineVoProxy:getName() .. ' | ' .. tostring(dataKey))
            -- logs('[VoProxy]', '@@@@@@@@@@@@@@@@@@@@@@ .. ' .. tableToString(defineVoProxy:getData()))

            -- keys voProxy
            if VoProxy.IsVariableKey(defineVoProxy.metaVoStract_) and dataKey ~= nil then
                local keyVoProxy = defineVoProxy.keysVoProxyMap_[dataKey]
                if keyVoProxy == nil then
                    local keyProxyName = defineVoProxy:getName() .. '@' .. dataKey
                    local keyVoStract  = defineVoProxy.metaVoStract_
                    keyVoProxy = VoProxy.new(keyProxyName, keyVoStract, nil, nil, self.eventPrefix_)
                    defineVoProxy.keysVoProxyMap_[dataKey] = keyVoProxy
                end

                keyVoProxy:setData(isRootDefine and parentVoData or voProxyValue)
                keyVoProxy:update(keyVoProxy:getData(), true)
                keyVoProxy.currentDataKey_ = dataKey
                return keyVoProxy
                    
            -- default voProxy
            else
                defineVoProxy:setData(isRootDefine and parentVoData or voProxyValue)
                return defineVoProxy
            end
        end
    end
    return voProxyValue
end


--[[
    set VoProxy object (list or map type) or VoProxy data (other type).
    -- @param voDefine  : table      VoDefine object
    -- @param dataValue : any        want to reset data
    -- @param dataKey   : str/int    table data key (optional)
    -- @param ignoreEvt : boolean    ignore event (optional)
]]
function VoProxy:set(voDefine, dataValue, dataKey, ignoreEvt)
    local parentVoProxy = self:takeRootDefine_(voDefine)             -- on parent voProxy
    local parentVoData  = checktable(parentVoProxy:getData())        -- parent data
    local defineDatakey = dataKey or VoProxy.ValueKeyword(voDefine)  -- data key
    local defaultValue  = VoProxy.ValueDefault(voDefine)             -- default value
    local oldDataValue  = parentVoProxy:get(voDefine, dataKey)       -- old data value
    local newDataValue  = dataValue or defaultValue                  -- new data value

    -- map or list
    if VoProxy.IsTypeMap(voDefine) or VoProxy.IsTypeList(voDefine) then
        -- logs('[VoProxy]', 'op : ' .. parentVoProxy:getName())
        -- logs('[VoProxy]', 'sub : ' .. oldDataValue:getName())
        -- logs('[VoProxy]', 'key : ' .. tostring(defineDatakey))
        local defineVoProxy = oldDataValue
        oldDataValue = parentVoData[defineDatakey]
        
        -- reset subs (for change variable node)
        if oldDataValue ~= nil and oldDataValue ~= newDataValue then
            -- logs('[VoProxy]', '>>>>>> ' .. self:getName() .. ' : ' .. voDefine._key .. ' ' .. checkstr(dataKey))
            if (type(oldDataValue) == 'table' and next(oldDataValue) == nil and
                type(newDataValue) == 'table' and next(newDataValue) == nil) then
                -- empty table to empty table
                -- logs('[VoProxy]', '>>>>>> re-set ???????????????')
            else
                -- logs('[VoProxy]', '>>>>>> re-set +++++++++++++++')
                -- clean data, to reset
                self:del(voDefine, dataKey, ignoreEvt)
                oldDataValue = parentVoData[defineDatakey]
            end
        end

        -- udpate defineVoProxy
        local voProxyValue = checktable(oldDataValue)
        parentVoData[defineDatakey] = voProxyValue
        -- logs('[VoProxy]', tableToString(oldDataValue, 'oldDataValue'))
        -- logs('[VoProxy]', tableToString(newDataValue, 'newDataValue'))
        defineVoProxy:setData(voProxyValue)
        defineVoProxy:update(newDataValue, ignoreEvt)

        oldDataValue = nil
        newDataValue = defineVoProxy:getData()

    -- int
    elseif VoProxy.IsTypeInt(voDefine) then
        newDataValue = checkint(newDataValue)
    -- num
    elseif VoProxy.IsTypeNum(voDefine) then
        newDataValue = checknumber(newDataValue)
    -- str
    elseif VoProxy.IsTypeStr(voDefine) then
        newDataValue = checkstr(newDataValue)
    -- bool
    elseif VoProxy.IsTypeBool(voDefine) then
        newDataValue = checkbool(newDataValue)
    end

    -- update parent data
    local eventType = VoProxy.EVENTS.CHANGE
    if parentVoData[defineDatakey] == nil and newDataValue ~= nil then
        eventType = VoProxy.EVENTS.APPEND
    end
    parentVoData[defineDatakey] = newDataValue

    -- dispatch event
    if ignoreEvt ~= true and newDataValue ~= oldDataValue then
        self:event(voDefine, eventType, newDataValue, oldDataValue, dataKey)
    end
end


--[[
    delete VoProxy data
    -- @param voDefine : table      VoDefine object
    -- @param dataKey  : str/int    table data key (optional)
    -- @param ignoreEvt : boolean    ignore event (optional)
]]
function VoProxy:del(voDefine, dataKey, ignoreEvt)
    local isRootDefine  = self:getRootVoProxy().metaVoStract_ == voDefine
    local parentVoProxy = self:takeRootDefine_(voDefine)             -- on parent voProxy
    local parentVoData  = checktable(parentVoProxy:getData())        -- parent data
    local defineDatakey = dataKey or VoProxy.ValueKeyword(voDefine)  -- data key
    local defaultValue  = VoProxy.ValueDefault(voDefine)             -- default value
    local oldDataValue  = parentVoProxy:get(voDefine, dataKey)       -- old data value
    local newDataValue  = isRootDefine and {} or defaultValue        -- new data value
    
    if isRootDefine then
        -- logs('[VoProxy]', ' del root > ' .. parentVoProxy:getName() .. ' : ' .. voDefine._key ..' | '.. tostring(VoProxy.IsVariableKey(voDefine)) .. ' > ' .. tostring(dataKey))
        self:getRootVoProxy():setData(newDataValue)
        self:getRootVoProxy():update(defaultValue, ignoreEvt)

    else
        local defineVoProxy = parentVoProxy:takeSubVoProxy_(voDefine)
        -- logs('[VoProxy]', ' del node > ' .. parentVoProxy:getName() .. ' : ' .. voDefine._key ..' | '.. tostring(VoProxy.IsVariableKey(voDefine)) .. ' > ' .. tostring(dataKey))
        if VoProxy.IsTypeList(parentVoProxy.metaVoStract_) and dataKey then
            if #parentVoData >= checkint(dataKey) then
                table.remove(parentVoData, checkint(dataKey))
            end

            if defineVoProxy then
                local dataLength = #parentVoData
                for dataKey, _ in pairs(defineVoProxy.keysVoProxyMap_ or {}) do
                    if dataKey > dataLength then
                        defineVoProxy.keysVoProxyMap_[dataKey] = nil
                    end
                end
            end
            
        else
            if VoProxy.IsVariableKey(voDefine) then
                parentVoData[defineDatakey] = nil
                if defineVoProxy then
                    defineVoProxy.keysVoProxyMap_[defineDatakey] = nil
                end
            else
                parentVoData[defineDatakey] = newDataValue
            end
        end
    end

    -- dispatch event
    if ignoreEvt ~= true then
        self:event(voDefine, VoProxy.EVENTS.DELETE, newDataValue, oldDataValue, dataKey)
    end
end


--[[
    update self data. (only refresh tableData size, not reset all data)
    -- @param tableData : table      refresh data
    -- @param ignoreEvt : boolean    ignore event (optional)
]]
function VoProxy:update(tableData, ignoreEvt)
    local newProxyData = checktable(tableData)
    local isListStract = VoProxy.IsTypeList(self.metaVoStract_)
    for defineKey, voDefine in pairs(self.metaVoStract_) do
        -- top stract attr
        if VoProxy.IsDefineAttr(defineKey) then
        else
            if VoProxy.IsDefineTable(voDefine) then
                -- logs('[VoProxy]', 'update : ' .. self:getName() .. ' > ' .. defineKey .. ' = ' .. tostring(newProxyData[VoProxy.ValueKeyword(voDefine)]))
                if VoProxy.IsVariableKey(voDefine) then
                    if isListStract then
                        local index = 1
                        for _, dataValue in pairs(newProxyData) do
                            -- logs('[VoProxy]', 'update list : for : ' .. index)
                            self:set(voDefine, dataValue, index, ignoreEvt)
                            index = index + 1
                        end
                    else
                        for key, dataValue in pairs(newProxyData) do
                            -- logs('[VoProxy]', 'update map : for : ' .. key)
                            self:set(voDefine, dataValue, key, ignoreEvt)
                        end
                    end
                else
                    self:set(voDefine, newProxyData[VoProxy.ValueKeyword(voDefine)], nil, ignoreEvt)
                end
            end
        end
    end
end


--[[
    get VoProxy dataSize
    -- @param voDefine : table      VoDefine object
    -- @param dataKey  : str/int    table data key (optional)
]]
function VoProxy:size(voDefine, dataKey)
    local voProxyData = {}
    if voDefine then
        if VoProxy.IsTypeMap(voDefine) or VoProxy.IsTypeList(voDefine) then
            voProxyData = checktable(self:get(voDefine, dataKey):getData())
        end
    end
    return table.nums(voProxyData)
end


--[[
    dispatch event to VoProxy data change
    -- @param voDefine  : table      VoDefine object
    -- @param eventType : int        event type (optional)
    -- @param newValue  : any        new value (optional)
    -- @param oldValue  : any        old value (optional)
    -- @param dataKey   : str/int    table data key (optional)
    -- @see VoProxy.EVENTS
]]
function VoProxy:event(voDefine, eventType, newValue, oldValue, dataKey)
    local eventType = eventType or VoProxy.EVENTS.CHANGE
    local eventData = {
        target    = self,
        root      = self:getRootVoProxy(),
        voDefine  = voDefine,
        newValue  = newValue,
        oldValue  = oldValue,
        eventType = eventType,
        dataKey   = dataKey,
    }
    local logType = eventType == VoProxy.EVENTS.DELETE and '..' or '>'
    local logOldV = type(oldValue) == 'table' and 'table' or tostring(oldValue)
    local logNewV = type(newValue) == 'table' and 'table' or tostring(newValue)
    -- logs('[VoProxy]', string.fmt('%1(%2): %3 %5 %4', VoProxy.GetEventId(voDefine, self.eventPrefix_), checkstr(dataKey), logOldV, logNewV, logType))
    VoProxy.EventDispath(self.eventPrefix_, voDefine, eventData, eventType)
end


function VoProxy:dump(prefix)
    local dumpInfo  = {}
    local prefixStr = prefix or ''
    table.insert(dumpInfo, prefixStr .. string.fmt('[VoProxy : %1] = {', self:getName()))

    -- parent
    if self:getParentVoProxy() then
        table.insert(dumpInfo, prefixStr .. string.fmt('.parent = %1', self:getParentVoProxy():getName()))
    end

    -- root
    if self:getRootVoProxy() then
        table.insert(dumpInfo, prefixStr .. string.fmt('.rootVo = %1', self:getRootVoProxy():getName()))
    end

    -- key
    if self:key() then
        table.insert(dumpInfo, prefixStr .. string.fmt('.dataKey = %1', self:key()))
    end

    -- data
    if self:getData() then
        if type(self:getData()) == 'table' then
            local dataKeys = table.keys(self:getData())
            table.insert(dumpInfo, prefixStr .. string.fmt('.myData = %1', table.concat(dataKeys, ' | ') ))
        else
            table.insert(dumpInfo, prefixStr .. string.fmt('.value = %1', tostring(self:getData()) ))
        end
    end
    table.insert(dumpInfo, prefixStr)
    
    -- child
    table.insert(dumpInfo, prefixStr .. '.[subs voProxy]')
    for voDefineId, subVoProxyMap in pairs(self.subVoProxyMap_) do
        table.insert(dumpInfo, subVoProxyMap:dump(prefixStr .. '____'))
    end

    -- keys
    table.insert(dumpInfo, prefixStr .. '.[keys voProxy]')
    for dataKey, keyVoProxyMap in pairs(self.keysVoProxyMap_) do
        table.insert(dumpInfo, keyVoProxyMap:dump(prefixStr .. '____'))
    end

    table.insert(dumpInfo, prefixStr .. '}')
    table.insert(dumpInfo, prefixStr)

    -- root info
    if self:getParentVoProxy() == nil then

        -- : defineIdMap
        -- local index = 1
        -- for key, voProxy in pairs(self.voDefineIdMap_ or {}) do
        --     table.insert(dumpInfo, prefixStr .. string.format('root.idMap(%02d)[ %-40s] ( %s', index, key, voProxy:getName()))
        --     index = index + 1
        -- end
        
        -- : data
        table.insert(dumpInfo, (string.gsub(tableToString(self:getData(), 'root.data', 10), '- ', prefixStr)) )
        table.insert(dumpInfo, prefixStr)
    end

    return table.concat(dumpInfo, '\n')
end


-------------------------------------------------
-- private

-- sub voProxy
function VoProxy:bindSubVoProxy_(voDefine, subVoProxy)
    self.subVoProxyMap_[VoProxy.GetDefineId(voDefine)] = subVoProxy
end
function VoProxy:takeSubVoProxy_(voDefine)
    return self.subVoProxyMap_[VoProxy.GetDefineId(voDefine)]
end


-- root define
function VoProxy:bindRootDefine_(voDefine, voProxy)
    self:getRootVoProxy().voDefineIdMap_[VoProxy.GetDefineId(voDefine)] = voProxy
end
function VoProxy:takeRootDefine_(voDefine)
    return self:getRootVoProxy().voDefineIdMap_[VoProxy.GetDefineId(voDefine)]
end


-- parse voStract
function VoProxy:parseVoStract_()
    -- each child stract
    for defineKey, voDefine in pairs(self.metaVoStract_) do
        -- top stract attr
        if VoProxy.IsDefineAttr(defineKey) then
        else
            if VoProxy.IsDefineTable(voDefine) then

                -- create subVoProxy, to mapType or listType
                if VoProxy.IsTypeList(voDefine) or VoProxy.IsTypeMap(voDefine) then
                    -- get rootVoProxy
                    local loopCount   = 0
                    local rootVoProxy = self
                    while rootVoProxy:getParentVoProxy() and loopCount < MAX_STRUCT_LEVEL do
                        rootVoProxy = rootVoProxy:getParentVoProxy()
                        loopCount   = loopCount + 1
                    end

                    -- new subVoProxy
                    local subVoProxyName = self:getName() .. '#' .. defineKey
                    local newSubVoProxy  = VoProxy.new(subVoProxyName, voDefine, self, rootVoProxy, self.eventPrefix_)
                    self:bindSubVoProxy_(voDefine, newSubVoProxy)
                end

                -- bind to rootVoProxy
                self:bindRootDefine_(voDefine, self)
            end
        end
    end
end


return VoProxy
