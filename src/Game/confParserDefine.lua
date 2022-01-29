--[[
 * author : kaishiqi
 * descpt : 配表解析定义
]]
confParserDefine = {}

local DOC_PATCH = ''
local jsonData  = json.decode(FTUtils:getFileDataWithoutDec('config.json'))
if jsonData and jsonData.eaterDocPath then
    DOC_PATCH = tostring(jsonData.eaterDocPath)
end
confParserDefine.DOC_PATCH = DOC_PATCH


---@param sheetName string @default 'Sheet1' @see ExcelUtils.ExcelToConfTable
---@param convertTable table convert rule define
---{
--- child   包含子节点，会忽略value
--- share   是否共享节点，用于 map 结构
--- key     $开头 表示根据表头变量取值
--- value   $开头 表示根据表头变量取值
--- default 取值为 nil 时的默认值（可选）
--- filter  可自定义一层过滤规则（可选）
---}
local ConfDefine = function(excelPath, sheetName, convertTable, subConfRule)
    local define = {
        excelPath    = excelPath,
        sheetName    = sheetName or 'Sheet1',
        convertTable = convertTable,
        subConfRule  = subConfRule,
    }
    return define
end


-------------------------------------------------
-- plot
do
    confParserDefine['quest/questStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/主线剧情文案.xlsx', '主线剧情文案',
        {key = '$id', share = true, child = {
            {share = true, child = {
                {key = 'id',              value = '$id',              default = ''},
                {key = 'type',            value = '$type',            default = ''},
                {key = 'name',            value = '$name',            default = ''},
                {key = 'replace',         value = '$replace',         default = ''},
                {key = 'left',            value = '$left',            default = ''}, --
                {key = 'flip',            value = '$flip',            default = ''},
                {key = 'scale',           value = '$scale',           default = ''},
                {key = 'offset', child = {
                    {key = 'x', value = function(rowMap) return string.split2(checkstr(rowMap['offset']), ',')[1] end, default = nil},
                    {key = 'y', value = function(rowMap) return string.split2(checkstr(rowMap['offset']), ',')[2] end, default = nil},
                }},
                {key = 'face',            value = '$face',            default = ''},
                {key = 'dialogbox',       value = '$dialogbox',       default = ''}, --
                {key = 'dialogboxplaces', value = '$dialogboxplaces', default = ''},
                {key = 'desc',            value = '$desc',            default = ''},
                {key = 'setting',         value = '$setting',         default = ''},
                {key = 'filter',          value = '$filter',          default = ''},
                {key = 'voice',           value = '$voice',           default = ''}, --
                {key = 'sound',           value = '$sound',           default = ''},
                {key = 'music',           value = '$music',           default = ''},
                {key = 'controlmusic',    value = '$controlmusic',    default = ''},
                {key = 'characteranime',  value = '$characteranime',  default = ''}, --
                {key = 'sceneanime',      value = '$sceneanime',      default = ''},
                {key = 'specialeffects',  value = '$specialeffects',  default = ''},
                {key = 'displaycolor',    value = '$displaycolor',    default = ''},
                {key = 'spineanime',      value = '$spineanime',      default = ''},
                {key = 'CG',              value = '$CG',              default = ''},
                {key = 'displayitems',    value = '$displayitems',    default = ''}, --
                {key = 'func',            value = '$function',        default = ''},
                {key = 'select', value = function(rowMap)
                    local optionMap = {}
                    for i = 1, 3 do
                        local selectData = rowMap['select-' .. tostring(i)]
                        if selectData then
                            optionMap[tostring(i)] = string.split2(selectData, ';')
                        end
                    end
                    return optionMap
                end},
            }},
        }}
    )

    confParserDefine['quest/branchStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/支线剧情文案.xlsx', '支线剧情文案',
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['plot/collectCoordinate'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/新剧情/新主线收录坐标表.xlsx', nil,
        {key = '$Id', child = {
            {key = 'id',         value = '$Id'},
            {key = 'name',       value = '$name'},
            {key = 'areaId',     value = '$areaId'},
            {key = 'background', value = '$background'},
            {key = 'descr',      value = '$desc'},
            {key = 'pos', child = {
                {value = '$posX'},
                {value = '$posY'},
            }},
        }}
    )

    confParserDefine['plot/storyReward'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/新剧情/关卡剧情关联表.xlsx', '关卡剧情关联表',
        {key = '$id', child = {
            {key = 'id',        value = '$id'},
            {key = 'areaId',    value = '$areaId'},
            {key = 'name',      value = '$name'},
            {key = 'descr',     value = '$descr'},
            {key = 'icon',      value = '$icon'},
            {key = 'cgId',      value = function(rowMap) return string.split2(checkstr(rowMap['cgId']), ';') end},
            {key = 'chapterId', value = '$chapterId'},
            {key = 'unlock',    value = '$unlock'},
            {key = 'rewards',   value = function(rowMap)
                local rewardList = string.split2(checkstr(rowMap['rewards']), ';')
                local numberList = string.split2(checkstr(rowMap['rewardNum']), ';')
                local rewards    = {}
                for i, goodsId in ipairs(rewardList) do
                    if string.len(goodsId) > 0 then
                        table.insert(rewards, { goodsId = goodsId, num = numberList[i] })
                    end
                end
                return rewards
            end},
            {key = 'position',  child = {
                {value = '$xcoord'},
                {value = '$ycoord'},
            }},
        }}
    )

    confParserDefine['plot/storyVoice'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/新剧情/四选一语音.xlsx', nil,
        {key = '$id', child = {
            {key = 'id',      value = '$id'},
            {key = 'cardId',  value = '$cardId'},
            {key = 'voice',   value = '$voice'},
            {key = 'storyId', value = '$storyId'},
        }}
    )

    confParserDefine['plot/plotGoods'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/新剧情/剧情物品道具表.xlsx', nil,
        {key = '$id', child = {
            {key = 'id',    value = '$id'},
            {key = 'icon',  value = '$icon'},
            {key = 'name',  value = '$name'},
            {key = 'descr', value = '$desc'},
        }}
    )
    
    confParserDefine['plot/role'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/角色ID表.xlsx', '角色ID表',
        {key = '$roleId', child = {
            {key = 'roleId',   value = '$roleId'},
            {key = 'image',    value = '$image'},
            {key = 'headIcon', value = '$headIcon'},
            {key = 'roleName', value = '$roleName'},
            {key = 'type',     value = '$type'},
            {key = 'info',     value = '$info'},
            {key = 'takeaway', child = {
                {key = 'x',     value = '$x1'},
                {key = 'y',     value = '$y1'},
                {key = 'scale', value = '$scale1'},
            }},
        }}
    )

    for i = 0, 20 do
        confParserDefine['plot/story' .. i] = ConfDefine(
            DOC_PATCH .. string.fmt('/数值表/剧情表/新剧情/新主线_%1章.xlsx', i), '主线剧情文案',
            confParserDefine['quest/questStory'].convertTable
        )
    end

    confParserDefine['collection/spStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/图鉴/SP飨灵剧情文案表.xlsx', '主线剧情文案',
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['bar/customerStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/经营/酒吧/顾客剧情表.xlsx', nil,
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['plot/historyActivityDailyStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/往期活动剧情收录/往期日常活动剧情表.xlsx', '主线剧情文案',
        clone(confParserDefine['quest/questStory'].convertTable),
        function(aConf)
            return string.format('%d', math.ceil(checkint(aConf[1].id) / 100))
        end
    )

    confParserDefine['plot/historyActivityPTStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/往期活动剧情收录/往期PT本活动剧情表.xlsx', '主线剧情文案',
        clone(confParserDefine['quest/questStory'].convertTable),
        function(aConf)
            return string.format('%d', math.ceil(checkint(aConf[1].id) / 100))
        end
    )

    confParserDefine['plot/historyActivityStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/剧情表/往期活动剧情收录/往期大型活动剧情表.xlsx', '主线剧情文案',
        clone(confParserDefine['quest/questStory'].convertTable),
        function(aConf)
            return string.format('%d', math.ceil(checkint(aConf[1].id) / 100))
        end
    )
end


-------------------------------------------------
-- restaurant
do
    confParserDefine['restaurant/avatar'] = ConfDefine(
        DOC_PATCH .. '/数值表/经营/餐厅/餐厅avatar信息表.xlsx', '餐厅avatar信息表',
        {key = '$id', child = {
            {key = 'id',                  value = '$id'},
            {key = 'mainType',            value = function(rowMap) return string.split2(checkstr(rowMap['type']), ';')[1] end},
            {key = 'subType',             value = function(rowMap) return string.split2(checkstr(rowMap['type']), ';')[2] end},
            {key = 'theme',               value = '$theme'},
            {key = 'name',                value = '$name'},
            {key = 'descr',               value = '$descr'},
            {key = 'quality',             value = '$quality'},
            {key = 'max',                 value = '$max'},
            {key = 'unique',              value = '$unique'},
            {key = 'openRestaurantLevel', value = '$openRestaurantLevel'},
            {key = 'payType',             value = '$payType'},
            {key = 'payPrice',            value = '$payPrice'},
            {key = 'beautyNum',           value = '$beautyNum'},
            {key = 'unlockType',          value = function(rowMap) return { [tostring(rowMap['unlockType'])] = { targetNum = rowMap['unlockNum'] } } end},
            {key = 'sellType',            value = function(rowMap) return { [tostring(rowMap['sellType'])] = rowMap['sellType'] } end},
            {key = 'buffType',            value = function(rowMap) return {} end },
        }}
    )

    confParserDefine['restaurant/avatarLocation'] = ConfDefine(
        DOC_PATCH .. '/数值表/经营/餐厅/餐厅avatar位置表.xlsx', nil,
        {key = '$id', child = {
            {key = 'id',                 value = '$id'},
            {key = 'collisionBoxLength', value = '$collisionBoxLength'},
            {key = 'collisionBoxWidth',  value = '$collisionBoxWidth'},
            {key = 'objectLength',       value = '$objectLength'},
            {key = 'objectWidth',        value = '$objectWidth'},
            {key = 'offset',             value = function(rowMap) return {string.split2(checkstr(rowMap['offset']), ';')[1]} end, default = {'0,0'}},
            {key = 'location',           value = function(rowMap) return {string.split2(checkstr(rowMap['location']), ';')[1]} end, default = {'0,0'}},
            {key = 'canPut',             value = '$canPut'},
            {key = 'hasAddition',        value = '$hasAddition'},
            {key = 'additionNum',        value = '$additionNum'},
            {key = 'initAnimation',      value = '$initAnimation'},
            {key = 'particle',           value = '$particle'},
            {key = 'putThings',          value = function(rowMap)
                local thingList = string.split2(checkstr(rowMap['putThings']), ';')
                local pointList = string.split2(checkstr(rowMap['putLocation']), ';')
                local putThings = {}
                for i, thingId in ipairs(thingList) do
                    if string.len(thingId) > 0 then
                        local point = string.split2(checkstr(pointList[i]), ',')
                        table.insert(putThings, { thingId = thingId, x = point[1], y = point[2] })
                    end
                end
                return putThings
            end},
            {key = 'additions',          value = function(rowMap)
                local additionList  = string.split2(checkstr(rowMap['additionId']), ';')
                local directionList = string.split2(checkstr(rowMap['additionDirection']), ';')
                local locationList  = string.split2(checkstr(rowMap['sitLocation']), ';')
                local additions     = {}
                for i, additionId in ipairs(additionList) do
                    if string.len(additionId) > 0 then
                        table.insert(additions, { additionId = additionId, additionDirection = directionList[i], sitLocation = locationList[i] })
                    end
                end
                return additions
            end},
        }}
    )

    confParserDefine['restaurant/avatarAnimation'] = ConfDefine(
        DOC_PATCH .. '/数值表/经营/餐厅/餐厅avatar动画表.xlsx', nil,
        {key = '$id', share = true, child = {
            {key = '$name', child = {
                {key = 'id',           value = '$id'},
                {key = 'name',         value = '$name'},
                {key = 'to',           value = '$to'},
                {key = 'loop',         value = '$loop'},
                {key = 'autoJump',     value = '$autoJump'},
                {key = 'audioId',      value = '$audioId'},
                {key = 'audioTime',    value = '$audioTime'},
                {key = 'fullEffectId', value = '$fullEffectId'}
            }}
        }}
    )
end


-------------------------------------------------
-- activity
do
    confParserDefine['quest/story'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/季度活动配表/春季活动剧情文案.xlsx', '主线剧情文案',
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['summerActivity/mainStoryCollection'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/18夏活配表/夏活剧情收录表.xlsx', nil,
        {child = {
            {key = 'name',    value = '$name'},
            {key = 'resume',  value = '$resume'},
            {key = 'icon',    value = '$icon', default = 0},
            {key = 'storyId', value = '$storyId'},
        }, filter = function(rowMap) return checkint(rowMap['storyId']) <= 16 end}
    )

    confParserDefine['newSummerActivity/mainStoryCollection'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/19夏活配表/19夏活剧情收录表.xlsx', nil,
        confParserDefine['summerActivity/mainStoryCollection'].convertTable
    )

    confParserDefine['summerActivity/branchStoryCollection'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/18夏活配表/夏活剧情收录表.xlsx', nil,
        {child = {
            {key = 'name',    value = '$name'},
            {key = 'resume',  value = '$resume'},
            {key = 'icon',    value = '$icon', default = 0},
            {key = 'storyId', value = '$storyId'},
        }, filter = function(rowMap) return checkint(rowMap['storyId']) > 16 end}
    )
    
    confParserDefine['newSummerActivity/branchStoryCollection'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/19夏活配表/19夏活剧情收录表.xlsx', nil,
        confParserDefine['summerActivity/branchStoryCollection'].convertTable
    )
    
    -------------------------------------------------
    -- 夏活
    confParserDefine['summerActivity/summerStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/18夏活配表/夏活剧情表.xlsx', '主线剧情文案',
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['newSummerActivity/story'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/19夏活配表/19夏活剧情表.xlsx', '19夏活剧情表',
        confParserDefine['quest/questStory'].convertTable
    )

    -------------------------------------------------
    -- 春活
    confParserDefine['seasonActivity/springStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/季度活动配表/春季活动剧情文案.xlsx', '主线剧情文案',
        confParserDefine['quest/questStory'].convertTable
    )
    
    confParserDefine['springActivity/story'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/19春活配表/春活剧情文案.xlsx', '主线剧情文案',
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['springActivity2020/story'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/20春活配表/20春活剧情表.xlsx', '20春活剧情表',
        confParserDefine['quest/questStory'].convertTable
    )

    -------------------------------------------------
    -- 周年庆
    confParserDefine['anniversary/anniversaryStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/周年庆/周年庆剧情表.xlsx', '主线剧情文案',
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['anniversary2/story'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/19周年庆/19周年庆剧情表.xlsx', '19夏活剧情表',
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['anniversary2020/story'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/20周年庆/20周年庆剧情表.xlsx', '19夏活剧情表',
        confParserDefine['quest/questStory'].convertTable
    )

    -------------------------------------------------
    -- 其他
    local cardWordsConvertTable = clone(confParserDefine['quest/questStory'].convertTable)
    cardWordsConvertTable.key = '$taskId'
    cardWordsConvertTable.child[1].child[1].value = '$taskId'
    confParserDefine['activityQuest/cardWords'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/活动副本/飨灵物语.xlsx', '飨灵物语',
        cardWordsConvertTable,
        function(aConf)
            return string.format('%d', math.ceil(checkint(aConf[1].id) / 10))
        end
    )

    confParserDefine['cardComparison/comparisonStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/飨灵比拼/飨灵比拼剧情表.xlsx', nil,
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['activity/festivalStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/腊八节活动配表/腊八节活动剧情文案.xlsx', '腊八节活动剧情文案',
        confParserDefine['quest/questStory'].convertTable
    )

    confParserDefine['activity/farmStory'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/种菜副本/种菜副本剧情表.xlsx', '种菜副本剧情表',
        confParserDefine['quest/questStory'].convertTable
    )
    
    confParserDefine['pt/story'] = ConfDefine(
        DOC_PATCH .. '/数值表/活动配表/PT活动表/日服PT剧情表.xlsx', nil,
        confParserDefine['quest/questStory'].convertTable
    )
end


-------------------------------------------------
-- union
do
    confParserDefine['union/warsCoordinates'] = ConfDefine(
        DOC_PATCH .. '/数值表/工会/工会竞赛/工会竞赛据点坐标表.xlsx', nil,
        {key = '$page', share = true, child = {
            {key = 'site', share = true, child = {
                {key = '$Id', child = {
                    {key = 'id',   value = '$Id'},
                    {key = 'name', value = '$name'},
                    {key = 'pos',  child = {
                        {value = '$posX'},
                        {value = '$posY'},
                    }},
                }}
            }, filter = function(rowMap) return checkint(rowMap['Id']) < 100 end},
            {key = 'boss', child = {
                {key = 'id',   value = '$Id'},
                {key = 'name', value = '$name'},
                {key = 'pos',  value = {'%1,%2', '$posX','$posY'}},
            }, filter = function(rowMap) return checkint(rowMap['Id']) > 100 end},
        }}
    )
end
