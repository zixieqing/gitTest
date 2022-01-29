--[[
活动副本配表解析器
--]]
local AbstractBaseParser = require('Game.Datas.Parser')
---@class CardCallConfigParser : Parser
local CardCallConfigParser  = class('CardCallConfigParser', AbstractBaseParser)

CardCallConfigParser.NAME = 'CardCallConfigParser'

CardCallConfigParser.TYPE = {
    REWARD = "reward",
    TASK   = "task",
    GROUP  = "group",
    ROUTE  = "route"
}

function CardCallConfigParser:ctor()
    self.super.ctor(self, table.values(CardCallConfigParser.TYPE))
end

--[[
获取vo路径
@params name 配表名字
--]]
function CardCallConfigParser:GetVoPath(name)
    local path = 'Game/Datas/vo/' .. string.ucfirst(name) .. 'Vo.lua'
    if not utils.isExistent(path) and string.ucfirst(name) ~= 'Quest' then
        path = 'Game.Datas.Vo'
    else
        path = 'Game.Datas.vo.' .. string.ucfirst(name) .. 'Vo'
    end
    return path
end


return CardCallConfigParser