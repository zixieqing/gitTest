--[[
 * author : kaishiqi
 * descpt : 本地数据 - 相关定义
]]
---@class LocalProxy
local LocalProxy = {}


function LocalProxy:GetKeywordFormat()
    return checkstr(self.format)
end
function LocalProxy:GetKeywordData()
    return self.keyData
end
function LocalProxy:GetDefaultValue()
    return self.default
end
function LocalProxy:GetMethodType()
    return self.methodType
end


function LocalProxy:GetKey()
    local gamePlayerId = (app and app.gameMgr) and app.gameMgr:GetPlayerId() or 0
    local keywordData  = { playerId = gamePlayerId }
    table.merge(keywordData, self:GetKeywordData() or {})
    return string.fmt(self:GetKeywordFormat(), keywordData)
end


function LocalProxy:Load()
    local methodName = string.fmt('get%1ForKey', self:GetMethodType())
    local methodFunc = cc.UserDefault:getInstance()[methodName]
    local localValue = methodFunc(cc.UserDefault:getInstance(), self:GetKey(), self:GetDefaultValue())
    return localValue
end


function LocalProxy:Save(value)
    local methodName = string.fmt('set%1ForKey', self:GetMethodType())
    local methodFunc = cc.UserDefault:getInstance()[methodName]
    -- false ~= nil
    if value == nil then
        value = self:GetDefaultValue()
    end
    methodFunc(cc.UserDefault:getInstance(), self:GetKey(), value)
    cc.UserDefault:getInstance():flush()
end


function LocalProxy:Del()
    cc.UserDefault:getInstance():deleteValueForKey(self:GetKey())
end


--[[
    定义数据体
    @param keywordFormat : str 关键字格式
    @param defaultValue  : bool,str,int 默认值
    @return function( keywordData : table) 
        return define : LocalProxy
    end
]]
---@return LocalProxy
local LocalDefine = function(keywordFormat, defaultValue)
    local methodType = ''
    local valueType  = type(defaultValue)
    if valueType == 'boolean' then
        methodType = 'Bool'
    elseif valueType == 'number' then
        methodType = 'Integer'
    elseif valueType == 'string' then
        methodType = 'String'
    end

    return function(keywordData)
        local define = {
            format     = checkstr(keywordFormat),
            default    = defaultValue,
            keyData    = keywordData,
            methodType = methodType,
        }
        setmetatable(define, {__index = LocalProxy})
        return define
    end
end


------------------------------------------------------------------------------
-- local defines
------------------------------------------------------------------------------
LOCAL = {
    
    -------------------------------------------------
    -- championship
    CHAMPIONSHIP = {
        SCHEDULE_POPUP_NAME = LocalDefine('championshipSchedulePopupName_seasonId_playerId', ''),
    },

    -- anniv20HangOpenAnim
    ANNIV2020 = {
        IS_OPENED_HOME_POSTER         = LocalDefine('IS_OPENED_ANNIVERSARY2020_POSTER_playerId', false),
        IS_ALREADY_PLAY_OPEN_ANIM     = LocalDefine('anniversary2020_already_play_open_animation_playerId', false),
        EXPLORE_CHAPTER_OPEN_PROGRESS = LocalDefine('anniversary2020_explore_chapter_open_progress_playerId', 0),
        PUZZLE_UNLOCKED_ANIM_PROGRESS = LocalDefine('anniversary2020_puzzle_unlocked_animation_progress_playerId', 0),
    },

    CAT_HOUSE = {
        IS_OPENED_CHOOSE_CAT = LocalDefine('IS_OPENED_CHOOSE_CAT_playerId', false),
    },

    NEW_KOF_ARENA = {
        IS_FIRST_ENTER = LocalDefine('IS_FIRST_ENTER_HOME_NEW_KOF_ARENA_playerId', true),
    },

    AUTHORMEDIATOR = {
        IS_AGREE_PRIVACY = LocalDefine('IS_AGREE_PRIVACY_TO_GAME44_playerId', false),
    },
    
    -- card
    CARDLIST = {
        IS_SHOW_MORE_CARD_VERSION = LocalDefine('IS_SHOW_MORE_CARD_VERSION_playerId', false),
        IS_SHOW_LEVEL_UP_TIPS     = LocalDefine('IS_SHOW_LEVEL_UP_TIPS_playerId', true),
        IS_SHOW_SKILL_UP_TIPS     = LocalDefine('IS_SHOW_SKILL_UP_TIPS_playerId', true),
        IS_SHOW_STAR_UP_TIPS      = LocalDefine('IS_SHOW_STAR_UP_TIPS_playerId', true),
        IS_SHOW_FEL_GOD_TIPS      = LocalDefine('IS_SHOW_FEL_GOD_TIPS_playerId', true),
    }
}
