--[[
主角技模型
--]]
local BaseSkill = __Require('battle.skill.BaseSkill')
local PlayerSkill = class('PlayerSkill', BaseSkill)

--[[
@override
技能索敌
@params isEnemy bool 这个技能本身的敌我性
@params seekRule SeekRuleStruct 索敌规则
@params extra table 附加参数
@return _ table 所对应的目标
--]]
function PlayerSkill:SeekCastTargets(isEnemy, seekRule, extra)

	if 0 < self:GetSkillInfectTime() then

		return BattleExpression.GetSortedTargets(
			BattleExpression.GetFriendlyTargetsForPlayerSkill(isEnemy, seekRule.ruleType, self:GetSkillId(), extra.o),
			seekRule.sortType,
			seekRule.maxValue,
			extra
		)

	else

		return BattleExpression.GetSortedTargets(
			BattleExpression.GetFriendlyTargetsForPlayerSkill(isEnemy, seekRule.ruleType, nil, extra.o),
			seekRule.sortType,
			seekRule.maxValue,
			extra
		)

	end
	
end
--[[
墓地系技能索敌
@params isEnemy bool 这个技能本身的敌我性
@params seekRule SeekRuleStruct 索敌规则
@params extra table 附加参数
@return _ table 所对应的目标
--]]
function PlayerSkill:SeekCastDeadTargets(isEnemy, seekRule, extra)
	return BattleExpression.GetSortedTargets(
		BattleExpression.GetDeadFriendlyTargetsForPlayerSkill(isEnemy, seekRule.ruleType, extra.o),
		seekRule.sortType,
		seekRule.maxValue,
		extra
	)
end

return PlayerSkill