--[[
处理checkin的carddata的一些 方法 定义 和 配置
--]]

local CheckinCardData = {}

--[[
获取checkin返回的cardData的信息
@return _ table checkin卡牌数据的配置信息
--]]
function CheckinCardData.GetCheckinCardDataInfo()
    local fieldFormat = {
        -- 卡牌等级
        ['level']               = {
            fieldName = 'level',
            initNecessary = true, forceInit = false, initDefaultVal = 1, initFunc = nil,
            needCheckint = true, needChecknumber = false, updateFunc = nil
        },
        -- 卡牌星级
        ['breakLevel']          = {
            fieldName = 'breakLevel',
            initNecessary = true, forceInit = true, initDefaultVal = 0, initFunc = nil,
            needCheckint = false, needChecknumber = false, updateFunc = CheckinCardData.UpdateFuncBreakLevel
        },
        -- 卡牌经验
        ['exp']                 = {
            fieldName = 'exp',
            initNecessary = true, forceInit = false, initDefaultVal = 0, initFunc = nil,
            needCheckint = true, needChecknumber = false, updateFunc = nil
        },
        -- 卡牌新鲜度
        ['vigour']              = {
            fieldName = 'vigour',
            initNecessary = false, forceInit = false, initDefaultVal = nil, initFunc = nil,
            needCheckint = false, needChecknumber = false, updateFunc = nil
        },
        -- 卡牌技能
        ['skill']               = {
            fieldName = 'skill',
            initNecessary = true, forceInit = true, initDefaultVal = nil, initFunc = CheckinCardData.InitFuncSkill,
            needCheckint = false, needChecknumber = false, updateFunc = CheckinCardData.UpdateFuncSkill
        },
        -- 卡牌经营技能
        ['businessSkill']       = {
            fieldName = 'businessSkill',
            initNecessary = true, forceInit = false, initDefaultVal = nil, initFunc = CheckinCardData.InitFuncBusinessSkill,
            needCheckint = false, needChecknumber = false, updateFunc = nil
        },
        -- 卡牌好感度等级 当前等级经验
        ['favorability']        = {
            fieldName = 'favorability',
            initNecessary = true, forceInit = false, initDefaultVal = 0, initFunc = nil,
            needCheckint = true, needChecknumber = false, updateFunc = nil
        },
        -- 卡牌好感度等级
        ['favorabilityLevel']   = {
            fieldName = 'favorabilityLevel',
            initNecessary = true, forceInit = false, initDefaultVal = 1, initFunc = nil,
            needCheckint = true, needChecknumber = false, updateFunc = nil
        },
        -- 当前皮肤id
        ['defaultSkinId']       = {
            fieldName = 'defaultSkinId',
            initNecessary = true, forceInit = false, initDefaultVal = nil, initFunc = CheckinCardData.InitDefaultSkin,
            needCheckint = true, needChecknumber = false, updateFunc = nil
        },
        -- 是否解锁神器
        ['isArtifactUnlock']    = {
            fieldName = 'isArtifactUnlock',
            initNecessary = false, forceInit = false, initDefaultVal = nil, initFunc = nil,
            needCheckint = false, needChecknumber = false, updateFunc = nil
        },
        -- 契约纪念日
        ['marryTime']           = {
            fieldName = 'marryTime',
            initNecessary = false, forceInit = false, initDefaultVal = nil, initFunc = nil,
            needCheckint = false, needChecknumber = false, updateFunc = nil
        },
        -- luna塔保存的血量
        ['lunaTowerHp']         = {
            fieldName = 'lunaTowerHp',
            initNecessary = true, forceInit = false, initDefaultVal = 1, initFunc = nil,
            needCheckint = false, needChecknumber = true, updateFunc = nil
        },
        -- luna塔保存的能量
        ['lunaTowerEnergy']     = {
            fieldName = 'lunaTowerEnergy',
            initNecessary = true, forceInit = false, initDefaultVal = 0, initFunc = nil,
            needCheckint = false, needChecknumber = true, updateFunc = nil
        }
    }

    return fieldFormat
end


--[[
根据字段名获取字段信息
@param fieldKey string 字段名
@return fieldInfo table 字段信息
--]]
function CheckinCardData.GetFieldInfoByFieldName(fieldKey)
    return CheckinCardData.GetCheckinCardDataInfo()[fieldKey]
end


---------------------------------------------------
-- update card data begin --
---------------------------------------------------
--[[
通用的更新方法
@param fieldKey string 字段名
@param newVal any 新的数据
@param oldVal any 老的数据
@param fieldInfo table 字段信息
@return val any 更新后的数据
--]]
function CheckinCardData.CommonUpdateCardData(fieldKey, newVal, oldVal)
    local val = nil
    local fieldInfo = CheckinCardData.GetFieldInfoByFieldName(fieldKey)
    if nil ~= fieldInfo then

        if nil ~= fieldInfo.updateFunc and 'function' == type(fieldInfo.updateFunc) then

            -- 自定义的数据更新
            val = fieldInfo.updateFunc(newVal, oldVal)

        else

            -- 通用更新逻辑
            if true == needCheckint then
                val = checkint(newVal)
            elseif true == needChecknumber then
                val = checknumber(newVal)
            else
                val = newVal
            end

        end

    end
    return val
end


--[[
更新星级
@param newVal any 新的数据
@param oldVal any 老的数据
@return _ map 更新完之后的数据
--]]
function CheckinCardData.UpdateFuncBreakLevel(newVal, oldVal)
    if (type(newVal) == 'number' or type(newVal) == 'string') then
        return newVal
    else
        return nil
    end
end


--[[
更新卡牌数据skill字段
@param newVal any 新的数据
@param oldVal any 老的数据
@return _ map 更新完之后的数据
--]]
function CheckinCardData.UpdateFuncSkill(newVal, oldVal)
    if nil == oldVal then oldVal = {} end
    for skillId, skillInfo in pairs(newVal) do
        if nil ~= oldVal[skillId] then
            if nil ~= skillInfo.level then
                oldVal[skillId].level = skillInfo.level
            end
        else
            oldVal[skillId] = {}
        end
    end
    return oldVal
end


---------------------------------------------------
-- create card data begin --
---------------------------------------------------
--[[
创建一张卡牌 构造checkin的cardData
@param id int 卡牌数据库id
@param data table 外部传入的卡牌初始数据 覆盖默认数据
@return cardData table 构造完成的卡牌数据
--]]
function CheckinCardData.CommonCreateCardData(id, data)
    local cardDataInfo = CheckinCardData.GetCheckinCardDataInfo()

    for fieldName, fieldInfo in pairs(cardDataInfo) do

        if nil == data[fieldName] then
            
            -- 数据中没有必须的字段
            if true == fieldInfo.initNecessary then

                -- 需要初始化该字段
                CheckinCardData.CommonCreateCardData_(id, data, fieldName, fieldInfo)
                
            end

        else

            -- 数据中有该字段
            if true == fieldInfo.forceInit then

                -- 需要强制初始化
                CheckinCardData.CommonCreateCardData_(id, data, fieldName, fieldInfo)
                
            end

        end

    end

    return data
end

--[[
初始化卡牌数据
@param id int 卡牌数据库id
@param data table 外部传入的卡牌初始数据 覆盖默认数据
@param fieldName string 字段名
@param fieldInfo table 字段信息
--]]
function CheckinCardData.CommonCreateCardData_(id, data, fieldName, fieldInfo)
    -- 需要初始化该字段
    if nil ~= fieldInfo.initFunc and 'function' == type(fieldInfo.initFunc) then

        -- 自定义方法初始化
        fieldInfo.initFunc(data)

    elseif nil ~= fieldInfo.initDefaultVal then

        -- 直接初始化默认值
        data[fieldName] = fieldInfo.initDefaultVal

    else

        -- 不做处理


    end
end


--[[
初始化卡牌的技能信息
@param data table 外部传入的卡牌初始数据 覆盖默认数据
--]]
function CheckinCardData.InitFuncSkill(data)
    local skill = {}
    if nil ~= data.skill then
        for i, v in ipairs(data.skill) do
            skill[v] = {level = 1}
        end
    end
    data.skill = skill
end


--[[
初始化卡牌的经营技能信息
@param data table 外部传入的卡牌初始数据 覆盖默认数据
--]]
function CheckinCardData.InitFuncBusinessSkill(data)
    data.businessSkill = {}
    -- TODO --
    -- 外部初始化
    -- TODO --
end


--[[
默认皮肤
@param data table 外部传入的卡牌初始数据 覆盖默认数据
--]]
function CheckinCardData.InitDefaultSkin(data)
    if nil ~= data.skin then
        for key, value in pairs(data.skin) do
            -- 取第一个皮肤为默认皮肤
            if '1' == key then
                for _, skinId in pairs(value) do
                    data.defaultSkinId = skinId
                end
                break
            end
        end
    end
end


return CheckinCardData