--[[
天气技能
@params weatherId int 天气id
--]]
local BaseSkill = __Require('battle.skill.BaseSkill')
local WeatherSkill = class('WeatherSkill', BaseSkill)
--[[
@override
处理数据结构
--]]
function WeatherSkill:InitValue()
	BaseSkill.InitValue(self)
end

---------------------------------------------------
-- struct logic begin --
---------------------------------------------------
--[[
获取该技能是否是光环
@params _ bool 是否是光环
--]]
function WeatherSkill:IsSkillHalo()
	local weatherConf = CommonUtils.GetConfig('quest', 'weather', self:GetSkillWeatherId())
	return checkint(weatherConf.weatherType) == ConfigWeatherTriggerType.HALO and true or false
end
---------------------------------------------------
-- struct logic end --
---------------------------------------------------

return WeatherSkill
