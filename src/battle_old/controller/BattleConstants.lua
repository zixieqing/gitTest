--[[
战斗有关的常量
--]]
CARD_DEFAULT_SCALE = 0.5
ELITE_DEFAULT_SCALE = 0.75
BOSS_DEFAULT_SCALE = 0.9

-- 物体基础特征
BattleObjectFeature = {
	BASE 					= 0, -- 基本
	MELEE 					= 1, -- 近战
	REMOTE 					= 2, -- 远程
	HEALER 					= 3  -- 治疗
}

BattleObjectFSMState = {
	BASE 					= 0,
	SEEK_ATTACK_TARGET 		= 1,
	MOVE 					= 2,
	ATTACK 					= 3,
	CAST 					= 4,
	CAST_CONNECT_SKILL 		= 5,
	CHANT 					= 6,
	DIE 					= 7,
	WIN 					= 8
}

-- 战斗物体朝向 朝向坐标轴正方向为1
BattleObjTowards = {
	BASE 					= 0, -- 基础
	FORWARD 				= 1, -- 正方向
	NEGATIVE 				= -1 -- 负方向
}

-- 战斗元素类型
BattleElementType = {
	BET_BASE 				= 0, -- 基础
	BET_CARD 				= 1, -- 卡牌
	BET_PLAYER 				= 2, -- 主角
	BET_WEATHER 			= 3, -- 天气
	BET_BULLET 				= 4, -- 子弹
	BET_OB 					= 99  -- OB物体处于逻辑之外
}

BKIND = {
	BASE 					= 0,
	INSTANT 				= 1, -- 瞬时伤害治疗
	OVERTIME 				= 2, -- 延时伤害治疗
	SILENT 					= 3, -- 沉默
	STUN 					= 4, -- 眩晕
	SHIELD 					= 5, -- 护盾
	IMMUNE 					= 6, -- 无敌
	DISPEL 					= 7, -- 驱散
	ABILITY 				= 8, -- 属性增强
	FREEZE 					= 9, -- 冻结
	REVIVE 					= 10, -- 复活
	ENCHANTING 				= 11, -- 魅惑
	EXECUTE 				= 12, -- 斩杀不会分段 特殊处理
	ATTACK_CHARGE 			= 13, -- 平砍效果充能
	TRIGGER 				= 14  -- 触发buff
}

BuffCauseEffectTime = {
	BASE 					= 0,
	ADD2OBJ 				= 1, 		-- buff加到obj时立刻生效
	DELAY 					= 2, 		-- buff加到obj时不立刻生效
	INSTANT 				= 3 		-- 直接生效
}

BuffIconType = {
	BASE 					= 0,
	EFFECT_ATTACK 			= 1,
	EFFECT_DEFENCE 			= 2,
	EFFECT_MAX_HP 			= 3,
	EFFECT_CRIT_RATE 		= 4,
	EFFECT_ATTACK_RATE  	= 5,
	EFFECT_CRIT_DAMAGE  	= 6,
	EFFECT_DOT 				= 7,
	EFFECT_HOT 				= 8,
	EFFECT_CDAMAGE 			= 9,
	EFFECT_GDAMAGE 			= 10,
	IMMUNE 					= 11,
	STUN 					= 12,
	SILENT 					= 13,
	SHIELD 					= 14,
	INSTANT_DAMAGE 			= 15,
	INSTANT_HEAL 			= 16,
	DISPEL 					= 17,
}

GState = {
	READY 					= 1,
	START 					= 2,
	OVER 					= 3,
	TRANSITION 				= 4,
	BLOCK 					= 5,
	SUCCESS 				= 6,
	FAIL 					= 7
}

-- 法术免疫类型
ImmuneType = {
	IT_SKILL 				= 1, -- 一般法术免疫 根据buff类型判断
	IT_WEATHER 				= 2  -- 天气法术免疫 根据天气id判断
}

-- 行为触发类型
ActionTriggerType = {
	HP 						= 1, -- 血量触发
	CD 						= 2, -- cd触发
	DIE 					= 3, -- 死亡触发
	SKILL 					= 4, -- 技能触发
	ATTACK 					= 98, -- 攻击触发
	CONNECT 				= 99 -- 连携技触发
}

-- 战斗结果
BattleResult = {
	BR_BASE 				= 0, -- 默认
	BR_CONTINUE 			= 1, -- 没有结束 继续游戏
	BR_NEXT_WAVE 			= 2, -- 没有结束 但是需要创建下一波
	BR_SUCCESS 				= 3, -- 战斗结束 成功
	BR_FAIL 				= 4, -- 战斗结束 失败
	BR_RESCUE 				= 5  -- 抢救状态 准备失败
}

-- 变色类型
BattleObjTintType = {
	BOTT_BASE 				= 0, -- 默认
	BOTT_INSTANT 			= 1, -- 瞬时
	BOTT_BG 				= 2, -- 持续底色变色 可与瞬时叠加
	BOTT_COVER 				= 3  -- 持续变色全覆盖 不叠加
}

-- 变色样式
BattleObjTintPattern = {
	BOTP_BASE 				= 0, -- 默认
	BOTP_BLOOD 				= 1, -- 出血
	BOTP_DARK 				= 2  -- 黑化
}

BattleObjActionTag = {
	BOAT_BASE 				= 0, 	-- 默认
	BOAT_TINT 				= 1001  -- 变色
}

-- 伤害类型
DamageType = {
	INVALID 				= 0, 	-- 无效伤害类型
	ATTACK_PHYSICAL			= 1, 	-- 普通攻击 物理伤害
	ATTACK_HEAL 			= 2, 	-- 普通攻击 治疗
	SKILL_PHYSICAL 			= 3,	-- 技能 物理伤害
	SKILL_HEAL 				= 4, 	-- 技能 治疗
	PHYSICAL 				= 90, 	-- 所有物理伤害
	HEAL 					= 91 	-- 所有治疗
}

-- 数值意义
ValueConstants = {
	V_INFINITE 				= -1, 	-- 无限
	V_NONE 					= 0, 	-- 无
	V_NORMAL 				= 1 	-- 正常
}

-- 时间点意义
TimeAxisConstants = {
	TA_ENTER 				= 1,  	-- 之前 准备开始
	TA_ACTION 				= 2,	-- 之中 正在进行
	TA_EXIT 				= 3  	-- 之后 已经结束
}

-- 攻击特效类型
AttackModifierType = {
	AMT_BASE 				= 0, 	-- 基础类型
	AMT_HIT_AND_HEAL 		= 1, 	-- 击回
	AMT_HIT_GAIN_ENERGY 	= 2, 	-- 能量击回
	AMT_CERTAIN_CRITICAL 	= 3,	-- 必定暴击
	AMT_ATK_B 				= 4,	-- 攻击力增加或减少X点
	AMT_ULTIMATE_DAMAGE 	= 5 	-- 最终伤害
}

-- loading图id
BattleLoadingSceneType = {
	FIRST_PERFORMANCE 		= -2, 	-- 首场大战loading图
	BATTLE_REMIND 			= -1, 	-- 战斗教学提示
	NORMAL 					= 0 	-- 正常随机
}

-- 战斗驱动类型
BattleDriverType = {
	BASE 					= 0, 	-- 基础
	END_DRIVER 				= 1, 	-- 战斗结束判定条件
	RES_LOADER 				= 2, 	-- 资源加载驱动
	SHIFT_DRIVER 			= 3 	-- 切波驱动
}

-- 是否通过了战斗
PassedBattle = {
	NO_RESULT 				= -1, 	-- 指代还未结束
	FAIL 					= 0, 	-- 失败
	SUCCESS  				= 1 	-- 胜利
}

---------------------------------------------------
-- 配表解释值 --
---------------------------------------------------

-- obj 属性系数
ObjPP = {
	ATTACK_A 					= 1, 						-- 攻击乘法系数
	ATTACK_B 					= 2, 						-- 攻击加法系数
	DEFENCE_A 					= 3, 						-- 防御乘法系数
	DEFENCE_B 					= 4, 						-- 防御加法系数
	CDAMAGE_UP 					= 5, 						-- 平a伤害增加 乘法系数 公式系数 在等级碾压前生效
	CDAMAGE_DOWN 				= 6, 						-- 平a伤害降低 乘法系数 公式系数
	GDAMAGE_UP 					= 7, 						-- 受到平a伤害增加 乘法系数 公式系数
	GDAMAGE_DOWN 				= 8, 						-- 受到平a伤害降低 乘法系数 公式系数
	SKILL_UP 					= 9, 						-- 技能伤害增加 乘法系数 公式系数
	SKILL_DOWN 					= 10, 						-- 技能伤害降低 乘法系数 公式系数
	OHP_A 						= 11, 						-- 最大生命乘法系数
	OHP_B 						= 12, 						-- 最大生命加法系数
	CR_RATE_A 					= 13, 						-- 暴击率乘法系数
	CR_RATE_B 					= 14, 						-- 暴击率加法系数
	CR_DAMAGE_A 				= 15, 						-- 暴击伤害乘法系数
	CR_DAMAGE_B 				= 16,						-- 暴击伤害加法系数
	ATK_RATE_A 					= 17, 						-- 攻速乘法系数
	ATK_RATE_B 					= 18,						-- 攻速加法系数
	GET_DAMAGE_ATTACK 			= 19, 						-- 受到平a伤害增加 乘法系数 最终系数 在计算伤害的最后生效
	GET_DAMAGE_SKILL 			= 20,						-- 受到技能伤害增加 乘法系数 最终系数
	GET_DAMAGE_PHYSICAL 		= 21, 						-- 受到所有伤害增加 乘法系数 最终系数
	CAUSE_DAMAGE_ATTACK 		= 22, 						-- 平a伤害增加 乘法系数 最终系数
	CAUSE_DAMAGE_SKILL 			= 23,						-- 技能伤害增加 乘法系数 最终系数
	CAUSE_DAMAGE_PHYSICAL 		= 24, 						-- 所有伤害增加 乘法系数 最终系数最终系数
	CDP_2_CARD 					= 100, 						-- 对卡牌的伤害增加
	CDP_2_MONSER 				= 101, 						-- 对小怪的伤害增加
	CDP_2_ELITE 				= 102, 						-- 对精英怪的伤害增加
	CDP_2_BOSS 					= 103, 						-- 对BOSS的伤害增加
	CDP_2_CHEST 				= 107 						-- 对宝箱的伤害增加
}

-- 弱点效果id
ConfigWeakPointId = {
	BREAK 					= 101, -- 打断
	HALF_EFFECT 			= 102, -- 减半
	NONE 	 				= 103  -- 无效果
}

-- 技能类型
ConfigSkillType = {
	SKILL_NORMAL 			= 1, -- 普通小技能
	SKILL_HALO 				= 2, -- 光环技能
	SKILL_CUTIN 			= 3, -- cutin大技能
	SKILL_CONNECT 			= 4, -- 连携技能
	SKILL_WEAK 				= 5, -- 展示弱点的技能
	SKILL_PLAYER 			= 6, -- 主动主角技
	SKILL_SCENE 			= 7  -- 情景类技能
}

-- 技能触发类型
ConfigSkillTriggerType = {
	RESIDENT 				= 1, -- 常驻
	RANDOM 					= 2, -- 概率触发
	ENERGY 					= 3, -- 能量限制
	CD 						= 4, -- CD触发
	LOST_HP 				= 5, -- 损失血量触发
	COST_HP 				= 6, -- 消耗固定血量触发
	COST_CHP 				= 7, -- 消耗当前血量百分比触发
	COST_OHP 				= 8  -- 消耗最大血量百分比触发
}

-- 特效子弹类型
ConfigEffectBulletType = {
	BASE 					= 0, -- 基础
	SPINE_EFFECT 			= 1, -- 特效 直接播一段特效 不做碰撞
	SPINE_PERSISTANCE 		= 2, -- 持续性特效 直到效果结束
	SPINE_UFO_STRAIGHT 		= 3, -- 直线投掷物 做碰撞
	SPINE_UFO_CURVE 		= 4, -- 抛物线投掷物 做碰撞
	SPINE_WINDSTICK 		= 5, -- 回旋镖投掷物 做碰撞
	SPINE_LASER 			= 6  -- 激光 不做碰撞
}

-- 特效指向类型
ConfigEffectCauseType = {
	BASE 					= 0, -- 基础
	POINT 					= 1, -- 单体指向
	SINGLE 					= 2, -- 群体指向连线中点
	SCREEN 					= 3  -- 全屏
}

-- 怪物类型
ConfigMonsterType = {
	CARD 					= -1, -- 卡牌
	BASE 					= 0, -- 基础
	NORMAL 					= 1, -- 普通小怪
	ELITE 					= 2, -- 精英怪
	BOSS 					= 3, -- boss
	SCARECROW_TANK 			= 4, -- 坦克木桩
	SCARECROW_DPS 			= 5, -- 伤害木桩
	SCARECROW_HEALER		= 6, -- 治疗木桩
	CHEST 					= 7  -- 宝箱怪
}

-- 怪物形象类型
ConfigMonsterFormType = {
	BASE 					= 0, -- 基础
	NORMAL 					= 1, -- 正常
	COMMODE 				= 2  -- 马桶怪 不显示阴影
}

-- 卡牌职业
ConfigCardCareer = {
	BASE 					= 0, -- 基本类型
	TANK 					= 1, -- 坦克
	MELEE 					= 2, -- 近战
	RANGE	 				= 3, -- 远程
	HEALER 					= 4  -- 治疗
}

-- 天气触发类型
ConfigWeatherTriggerType = {
	HALO 					= 1, -- 常驻
	RANDOM 					= 2  -- 随机突发
}

-- 天气种类 区分做免疫
ConfigWeatherType = {
	SUNSHINE 				= 1, -- 风和日丽
	HEAT 					= 2, -- 炎热
	COLD 					= 3, -- 寒冷
	HUMID 					= 4, -- 潮湿
	THUNDER 				= 5, -- 雷电
	HAZE 					= 6, -- 雾霾
	HURRICANE 				= 7  -- 飓风
}

-- 索敌敌友性
ConfigSeekTargetRule = {
	BASE 					= 0, -- 基础
	T_OBJ_SELF 				= 1, -- 自身
	T_OBJ_ENEMY 			= 2, -- 敌方
	T_OBJ_FRIEND 			= 3, -- 友方
	T_OBJ_ALL 				= 4, -- 所有单位
	T_OBJ_FRIEND_TANK 		= 5, -- 友方防御系目标
	T_OBJ_FRIEND_MELEE 		= 6, -- 友方力量系目标
	T_OBJ_FRIEND_REMOTE 	= 7, -- 友方敏捷系目标
	T_OBJ_FRIEND_HEALER 	= 8, -- 友方辅助系目标
	T_OBJ_ENEMY_TANK 		= 9, -- 敌方防御系目标
	T_OBJ_ENEMY_MELEE 		= 10, -- 敌方力量系目标
	T_OBJ_ENEMY_REMOTE 		= 11, -- 敌方敏捷系目标
	T_OBJ_ENEMY_HEALER 		= 12, -- 敌方辅助系目标
	T_OBJ_FRIEND_PLAYER 	= 13, -- 友方主角
	T_OBJ_ENEMY_PLAYER 		= 14, -- 敌方主角
	T_OBJ_ATTACKER 			= 15, -- 当前攻击者 平a对象为发起本次索敌物体的单位
	T_OBJ_ATTACK_TARGET 	= 16, -- 当前攻击对象
	T_OBJ_TRIGGER_ATTACKER 	= 17  -- 触发本次索敌的攻击者单位
}

-- 索敌规则 排序
SeekSortRule = {
	S_NONE 					= 1, 		-- 不排序
	S_DISTANCE_MIN 			= 2, 		-- 距离最近
	S_DISTANCE_MAX 			= 3, 		-- 距离最远
	S_HP_PERCENT_MAX  		= 4, 		-- 当前生命百分比最高
	S_HP_PERCENT_MIN 		= 5, 		-- 当前生命百分比最低
	S_ATTACK_MAX 			= 6, 		-- 当前攻击力最高
	S_ATTACK_MIN 			= 7, 		-- 当前攻击力最低
	S_DEFENCE_MAX 			= 8, 		-- 当前防御力最高
	S_DEFENCE_MIN 			= 9, 		-- 当前防御力最低
	S_CHP_MAX 				= 10, 		-- 当前生命值最高
	S_CHP_MIN 				= 11, 		-- 当前生命值最低
	S_OHP_MAX 				= 12, 		-- 生命总值最高
	S_OHP_MIN 				= 13, 		-- 生命总值最低
	S_BATTLE_POINT_MAX 		= 14, 		-- 战斗力最高的目标
	S_BATTLE_POINT_MIN 		= 15, 		-- 战斗力最低的目标
	S_ATTACK_RATE_MAX 		= 16, 		-- 当前攻击速度最高的目标
	S_ATTACK_RATE_MIN 		= 17, 		-- 当前攻击速度最低的目标
	S_HATE_MAX 				= 18, 		-- 当前仇恨值最高的目标
	S_HATE_MIN 				= 19, 		-- 当前仇恨值最低的目标
	S_FOR_HEAL 				= 99 		-- 治疗的索敌规则
}

-- 特殊的特效卡牌id
ConfigSpecialCardId = {
	PLAYER 					= 900001, -- 主角技
	WEATHER 				= 900002  -- 天气
}

-- 增减益配置值
ConfigIsDebuff = {
	BUFF 					= 1, -- buff
	DEBUFF 					= 2, -- debuff
	VALUE 					= 3  -- 由数值判断是否是减益效果
}

-- buff类型配表值
ConfigBuffType = {
	BASE 					= 0,	--基础类型
	ATTACK_B 				= 1, 	--攻击力增加或减少X点
	ATTACK_A 				= 2,	--攻击力增加或减少X%
	DEFENCE_B 				= 3,	--防御力增加或减少X点
	DEFENCE_A 				= 4,	--防御力增加或减少X%
	OHP_B 					= 5,	--血量上限增加或减少X点
	OHP_A 					= 6,	--血量上限增加或减少X%
	CR_RATE_B 				= 7,	--暴击率增加或减少X点
	CR_RATE_A 				= 8,	--暴击率增加或减少X%
	ATK_RATE_B 				= 9,	--攻速增加或减少X点
	ATK_RATE_A 				= 10,	--攻速增加或减少X%
	CR_DAMAGE_B 			= 11,	--暴击伤害增加或减少X点
	CR_DAMAGE_A 			= 12,	--暴击伤害增加或减少X%
	CDAMAGE_A 				= 13,	--当前伤害增加X%
	GDAMAGE_A 				= 14,	--当前受害增加X%
	ISD 					= 15,	--造成X点伤害 这条会有两个参数
	ISD_LHP 				= 16,	--造成当前损失血量X%伤害
	ISD_CHP 				= 17,	--造成当前血量X%伤害
	ISD_OHP 				= 18,	--造成最大血量X%伤害
	DOT 					= 19,	--每秒造成X点伤害 这条会有两个参数
	DOT_CHP 				= 20,	--每秒造成当前血量的X%伤害
	DOT_OHP 				= 21,	--每秒造成最大血量的X%伤害
	HEAL 					= 22,	--治疗X点
	HEAL_LHP 				= 23,	--治疗当前损失血量X%
	HEAL_OHP 				= 24,	--治疗最大血量X%
	HOT 					= 25,	--每秒治疗X点
	HOT_LHP 				= 26,	--每秒治疗当前损失血量X%
	HOT_OHP 				= 27,	--每秒治疗最大血量X%
	DISPEL_DEBUFF 			= 28,	--驱散当前角色全部debuff
	DISPEL_BUFF 			= 29,	--驱散当前角色全部buff
	IMMUNE 					= 30,	--无敌
	STUN 					= 31,	--眩晕
	SILENT 					= 32,	--沉默
	SHIELD 					= 33,	--吸收X点伤害
	HEAL_BY_ATK 			= 34,	--造成当前攻击力（施法者）X%治疗+造成Y点治疗
	HEAL_BY_DFN 			= 35,	--造成当前防御力（施法者）X%治疗+造成Y点治疗
	HEAL_BY_CHP 			= 36,	--造成当前血量（施法者）X%治疗+造成Y点治疗
	FREEZE 					= 37, 	--冻结
	DISPEL_QTE 				= 38, 	--驱散qte
	BECKON 					= 39, 	--召唤
	DISPEL_BECKON 			= 40, 	--驱散召唤物
	REVIVE 					= 41, 	--复活
	ENCHANTING 				= 42, 	--魅惑
	EXECUTE 				= 43, 	--斩杀
	ENERGY_ISTANT 			= 45, 	--瞬时增加或减少多少能量
	ENERGY_CHARGE_RATE		= 46, 	--增加或减少能量回复速度
	ATK_CR_RATE_CHARGE 		= 47, 	--使目标下X次普通攻击必定暴击
	ATK_ATTACK_B_CHARGE 	= 48, 	--使目标下X次普通攻击时 每次攻击攻击力提升X点
	ATK_ISD_CHARGE 			= 49, 	--使目标下X次普通攻击时 每次攻击附加X点伤害
	ATK_HEAL_CHARGE 		= 50, 	--使目标下X次普通攻击时 每次攻击恢复X点血量
	ATK_ENERGY_CHARGE 		= 51, 	--使目标下X次普通攻击时 每次攻击增加X点能量
	IMMUNE_ATTACK_PHYSICAL 	= 52, 	--免疫所有普通攻击伤害
	IMMUNE_SKILL_PHYSICAL 	= 53, 	--免疫所有技能攻击伤害
	IMMUNE_ATTACK_HEAL 		= 54, 	--免疫所有普通治疗
	IMMUNE_SKILL_HEAL 		= 55, 	--免疫所有技能治疗
	IMMUNE_HEAL 			= 56, 	--免疫所有治疗
	GET_DAMAGE_ATTACK 		= 57, 	--受到的攻击伤害增加X%
	GET_DAMAGE_SKILL 		= 58, 	--受到的技能伤害增加X%
	GET_DAMAGE_PHYSICAL 	= 59, 	--所有受到的伤害增加X%
	CAUSE_DAMAGE_ATTACK 	= 60, 	--造成攻击伤害增加X%
	CAUSE_DAMAGE_SKILL  	= 61, 	--造成技能伤害增加X%
	CAUSE_DAMAGE_PHYSICAL 	= 62, 	--造成所有伤害增加X%
	STAGGER 				= 101,  --醉拳 船长大 >>>吸收[1%]伤害 以dot形式在[2]秒内返还 1秒1跳<<<
	SACRIFICE 				= 102,  --牺牲 >>>替队友承受[1%]伤害<<<
	SPIRIT_LINK 			= 103, 	--灵魂链接 >>>重新分配所有带buff单位的生命值至百分比一致<<<
	UNDEAD 					= 104, 	--春哥 >>>不会死亡 正常扣血<<<
	DOT_FINISHER 			= 105, 	--dot hot终结 >>>终结dothot类buff 使目标身上的[6, 7, 8, 9, ...]buff结算一次驱散 效果增强[5%] 并[4 1会 0不会]传染给下一个[索敌规则 1索敌类型 2最大目标数 3排序类型]目标 <<<
	CRITICAL_COUNTER 		= 106,  --保底暴击 >>>[1]次平a未造成暴击后 下一次平a必定暴击<<<
	-- BUFF_ENHANCE_TIME 		= 107,  --buff持续时间延长 >>>使类型为[1]的buff延长[2]秒 使类型为[3]的buff延长[4]秒 使类型为[5]的buff延长[6]秒...<<<
	MULTISHOT  				= 108,  --多重 >>>对当前攻击对象[索敌规则 1索敌类型 2最大目标数 3排序类型]的对象进行倍率[4%]的多重攻击<<<
	ATTACK_SEEK_RULE 		= 109,  --改变平a索敌规则 >>>改变目标平a索敌规则[索敌规则 1索敌类型 2最大目标数 3排序类型]<<<
	HEAL_SEEK_RULE 			= 110,  --改变治疗索敌规则 >>>改变目标平a索敌规则[索敌规则 1索敌类型 2最大目标数 3排序类型]<<<
	CHANGE_SKILL_TRIGGER 	= 111,  --改变技能的触发数据 >>>改变[1]技能id的 {[2]触发类型 [3]触发值(delta) [4]触发类型 [5]触发值(delta) [6]触发类型 [7]触发值(delta) ...}<<<
	CHANGE_PP 				= 112,  --改变属性系数 >>>改变目标[1]类型属性系数 改变值为[2]<<<
	DAMAGE_NO_TRIGGER 		= 113,  --不会触发触发器的伤害 脆弱 >>>受到[1%]目标数值和[2]点伤害 此伤害不会触发受伤触发器<<<
	HEAL_NO_TRIGGER 		= 114,  --不会触发触发器的治疗 >>>受到[1%]目标数值和[2]点治疗 此治疗不会触发受治疗触发器<<<
	HOT_EXTEND 				= 115, 	--hot类刷新持续时间buff >>><<<
	SLAY_DAMAGE_SPLASH 		= 116,  --击杀伤害溢出 >>>造成的击杀伤害如果溢出 溢出的[4%] + [5]点伤害会对杀死目标[索敌规则 1索敌类型 2最大目标数 3排序类型]的目标造成一个溢出的伤害<<<
	SLAY_BUFF_INFECT 		= 117,  --击杀buff传染 >>>击杀带有[4, 5, 6, ...]buff类型的单位 对应的buff会传染给[索敌规则 1索敌类型 2最大目标数 3排序类型]的目标<<<
	ENHANCE_NEXT_SKILL 		= 118,  --强化技能系数 >>>强化下[1]次[4, 5, 6, ...技能类型 ConfigSkillType]技能的额外系数额外值为[2%] + [3]点<<<
	OVERFLOW_HEAL_2_SHIELD 	= 119, 	--受到溢出治疗转护盾 >>>溢出的治疗量的[4%] + [5]点对[索敌规则 1索敌类型 2最大目标数 3排序类型]的目标转化为护盾持续[6]秒并且不会超过最大生命值的[7]<<<
	OVERFLOW_HEAL_2_DAMAGE 	= 120,  --受到溢出治疗转伤害 >>>溢出的治疗量的[4%] + [5]点对[索敌规则 1索敌类型 2最大目标数 3排序类型]的目标转化为伤害并且不会超过最大生命值的[6]<<<
	SLAY_CAST_ECHO 			= 121,  --回响 >>>[1技能类型]技能击杀单位时有[3%]几率立即释放一个[2技能类型]技能<<<
	MARKING 				= 122,  --标记此类型只是一个标记 空buff效果 >>><<<
	CHANGE_PP_BY_PROPERTY 	= 123,  --根据属性变化改变属性系数 >>>[1]属性(物体属性 基础6属性 能量等)变化会造成[2]属性系数(系数)变化 当属性为0时 系数变化值为[3] 当属性为当前属性初始值时 系数变化值为[4]<<<
	ENHANCE_BUFF_TIME_CAUSE = 124,  --使自己造成的buff时间得到强化 >>>使自身造成的[1]buff类型持续时间延长[2]秒 [3]buff类型持续时间延长[4]秒 [5]buff类型持续时间延长[6]秒 ...<<<
	ENHANCE_BUFF_TIME_GET 	= 125,  --使自己受到的buff时间得到强化 >>>使自身受到的[1]buff类型持续时间延长[2]秒 [3]buff类型持续时间延长[4]秒 [5]buff类型持续时间延长[6]秒 ...<<<
	ENHANCE_BUFF_VALUE_CAUSE= 126, 	--使自己造成的buff值得到强化 >>>使自身造成的[1]buff类型效果值增强 [2]乘法系数 [3] 加法系数 使自身造成的[4]buff类型效果值增强 [5]乘法系数 [6] 加法系数 ...<<<
	ENHANCE_BUFF_VALUE_GET 	= 127,  --使自己受到的buff值得到强化 >>>使自身受到的[1]buff类型效果值增强 [2]乘法系数 [3] 加法系数 使自身受到的[4]buff类型效果值增强 [5]乘法系数 [6] 加法系数 ...<<<
	CHANGE_BUFF_SUCCESS_RATE= 128,  --改变buff释放成功率(不是技能的释放成功率) >>>改变[1]技能id[2]buff类型的[3%]成功率(delta) 改变[3]技能id[4]buff类型的[5%]成功率(delta)<<<
	PROPERTY_CONVERT 		= 129,  --属性转换 >>>将[1]基础属性(属性id)的[3]转换为[2]基础属性 转换比例为[4] 将[5]基础属性(属性id)的[7]转换为[6]基础属性 转换比例为[8] ...<<<
	IMMUNE_BUFF_TYPE 		= 130, 	--免疫buff类型的buff >>>免疫[1, 2, 3 ...] 类型的buff<<<
	LIVE_CHEAT_FREE 		= 10001,--前X次买活免费
	BATTLE_TIME 			= 10002,--战斗时间增加/缩短X%
	TRIGGER_BUFF 			= 99999 --触发buff类型
}

-- buff图标类型
ConfigBuffIconType = {
	BASE 					= 0,
	EFFECT_ATTACK 			= 1,
	EFFECT_DEFENCE 			= 2,
	EFFECT_MAX_HP 			= 3,
	EFFECT_CRIT_RATE 		= 4,
	EFFECT_ATTACK_RATE  	= 5,
	EFFECT_CRIT_DAMAGE  	= 6,
	EFFECT_DOT 				= 7,
	EFFECT_HOT 				= 8,
	EFFECT_CDAMAGE 			= 9,
	EFFECT_GDAMAGE 			= 10,
	IMMUNE 					= 11,
	STUN 					= 12,
	SILENT 					= 13,
	SHIELD 					= 14,
	INSTANT_DAMAGE 			= 15,
	INSTANT_HEAL 			= 16,
	DISPEL 					= 17,
}

-- 战斗物体触发类型
ConfigObjectTriggerActionType = {
	BASE 					= 0,
	ATTACK 					= 1, 		-- 造成攻击 此类型一次攻击只会触发一次
	ATTACK_HIT 				= 2, 		-- 攻击命中 此类型一次攻击会由分段触发多次
	ATTACK_CRITICAL 		= 3, 		-- 造成暴击 此类型一次攻击只会触发一次
	GOT_DAMAGE 				= 4, 		-- 受到伤害
	GOT_DAMAGE_CRITICAL 	= 5,  		-- 受到暴击
	GOT_HEAL 				= 6, 		-- 受到治疗
	GOT_HEAL_CRITICAL 		= 7, 		-- 受到治疗暴击
	CAST 					= 8, 		-- 施法
	GOT_DEADLY_DAMAGE 		= 9, 		-- 受到致死伤害
	DEAD 					= 10, 		-- 死亡
	WAVE_SHIFT 				= 11,  		-- 波数转换
	GOT_BUFF 				= 12,  		-- 获得buff
	REFRESH_BUFF			= 13,  		-- 刷新buff
	CAST_SKILL_NORMAL 		= 14, 		-- 释放技能 ConfigSkillType.SKILL_NORMAL
	CAST_SKILL_CUTIN 		= 15, 		-- 释放技能 ConfigSkillType.SKILL_CUTIN
	CAST_SKILL_CONNECT 		= 16, 		-- 释放技能 ConfigSkillType.SKILL_CONNECT
	SLAY_OBJECT 			= 17, 		-- 击杀单位
	SHIELD_OVERPLUS 		= 18 		-- 护盾持续时间结束还有剩余
}

-- buff触发条件类型
ConfigObjectTriggerConditionType = {
	BASE 					= 0,		-- 基础
	HP_MORE_THAN 			= 1, 		-- 血量百分比大于等于
	HP_LESS_THAN 			= 2, 		-- 血量百分比小于等于
	HAS_BUFF 				= 3 		-- 物体存在某种buff类型的buff
}

-- 满足类型
ConfigMeetConditionType = {
	BASE 					= 0, 		-- 基础
	ONE 					= 1, 		-- 至少一个
	ALL 					= 2 		-- 全部
}

-- 转阶段触发条件
ConfigPhaseTriggerType = {
	BASE 					= 0, -- 基础类型 无意义
	LOST_HP 				= 1, -- 指定怪物损失血量达到一定百分比时
	APPEAR_TIME 			= 2, -- 战斗到达某一个时间点时
	OBJ_DIE 				= 3, -- 指定怪物死亡
	OBJ_SKILL 				= 4  -- 指定怪物释放技能
}

-- 转阶段类型
ConfigPhaseType = {
	TALK_DEFORM 			= 1, -- 喊话变身
	TALK_ESCAPE 			= 2, -- 喊话逃跑
	TALK_ONLY 				= 3, -- 纯喊话
	BECKON_ADDITION_FORCE 	= 4, -- 强制召唤add 死亡后也会执行
	BECKON_ADDITION 		= 5, -- 召唤add 死亡后不会执行
	BECKON_CUSTOMIZE 		= 6, -- 定制化召唤add
	EXEUNT_CUSTOMIZE 		= 7, -- 定制化怪物退场
	DEFORM_CUSTOMIZE 		= 8, -- 定制化变身
	PLOT 					= 9  -- 剧情对话
}

-- 变身子类型
ConfigDeformType = {
	HOLD_HP 				= 1, -- 保持血量百分比
	RECOVER_HP 				= 2  -- 回满血
}

-- 逃跑子类型
ConfigEscapeType = {
	ESCAPE 	 				= 1, -- 彻底逃跑 不再出现在该关卡
	RETREAT 				= 2  -- 战略性撤退特定回合
}

-- 结算界面
ConfigBattleResultType = {
	NORMAL 					= 1, -- 正常 含有结果三星条件 卡牌经验 掉落道具
	NONE_STAR 				= 2, -- 上一种类型1不含有三星条件
	NO_DROP 				= 3, -- 上一种类型2没有掉落
	RAID					= 4, -- 组队结算 翻牌子
	NO_EXP 					= 5, -- 没有经验界面(相当于只有结果)
	POINT_HAS_RESULT 		= 6, -- 点数结算 显示战斗结果
	POINT_NO_RESULT 		= 7, -- 点数结算 不显示战斗结果
	ONLY_RESULT 			= 8, -- 只有战斗结果
	NO_RESULT_DAMAGE_COUNT 	= 9  -- 没有战斗结果 只统计伤害和获得的道具
}

-- 等级碾压机制 等级上下限
ConfigBattleLevelRolling = {
	HIGHER_MAX 				= 30, -- 高等级碾压 最大差值80
	LOWER_MIN 				= -60 -- 低等级被碾压 最大差值60
}

-- 模块配置类型
ConfigBattleFunctionModuleType = {
	DEFAULT 				= 0, -- 默认
	ACCELERATE_GAME			= 1, -- 加速
	PLAYER_SKILL 			= 2, -- 主角技
	PAUSE_GAME 				= 3, -- 暂停
	WAVE 					= 4, -- 波数
	STAGE_CLEAR_TARGET 		= 5  -- 过关条件
}

-- 全局buff类型
ConfigGlobalBuffType = {
	BASE 					= 0, -- 基础
	BATTLE_TIME_A 			= 1, -- 增加或减少X%战斗时间
	OHP_A 					= 2, -- 最大生命值上限增加X%
	ATTACK_A 				= 3, -- 增加X%攻击力
	DEFENCE_A 				= 4, -- 增加X%防御力
	IMMUNE_ATTACK_PHYSICAL 	= 5, -- 免疫所有普通攻击伤害
	IMMUNE_SKILL_PHYSICAL 	= 6, -- 免疫所有技能攻击伤害
	CDAMAGE_A 				= 7  -- 造成伤害增加
}

-- 全局buff对象类型
ConfigGlobalBuffSeekTargetRule = {
	BASE 					= 0, -- 基础
	T_OBJ_FRIEND 			= 1, -- 所有友方
	T_OBJ_ENEMY 			= 2, -- 所有敌方
	T_OBJ_ALL 				= 3, -- 所有战斗单位
	T_OBJ_OTHER 			= 4  -- 其他
}

-- 全局效果类型表
ConfigGlobalEffectType = {
	BASE 					= 0, -- 基础
	OUTSIDE 				= 1, -- 战斗外逻辑
	INSIDE 					= 2  -- 战斗内逻辑
}

-- 过关类型
ConfigStageCompleteType = {
	BASE 					= 0, -- 基础
	NORMAL 					= 1, -- 正常类型 某方团灭视为失败
	SLAY_ENEMY 				= 2, -- 消灭所有指定物体
	HEAL_FRIEND 			= 3, -- 治疗所有指定物体
	ALIVE 					= 4, -- 指定时间段内存活
	TAG_MATCH 				= 5  -- 车轮战
}

-- 配表敌友性
ConfigCampType = {
	BASE 					= 0, -- 基础
	FRIEND 					= 1, -- 友方
	ENEMY 					= 2, -- 敌方
	NEUTRAL 				= 3  -- 中立的
}

-- 配表中镜头特效类型
ConfigCameraActionType = {
	BASE 					= 0, -- 基础
	SHAKE 					= 1, -- 抖动
	SHAKE_ZOOM 				= 2  -- 抖动+变焦
}

-- 镜头触发类型
ConfigCameraTriggerType = {
	BASE 					= 0, -- 基础
	PHASE_CHANGE 			= 1, -- 紧跟某个阶段转换
	OBJ_SKILL 				= 2  -- 紧跟某个技能
}

-- 记录怪物血量变化 发送给服务器
ConfigMonsterRecordDeltaHP = {
	DONT 					= 0, -- 不记录
	DO 						= 1, -- 记录
}
---------------------------------------------------
-- 配表解释值 --
---------------------------------------------------

---------------------------------------------------
-- 服务器校验相关的常量 --
---------------------------------------------------
-- 伤害模式
BDDamageType = {
	N_ATTACK 				= 1, -- 普攻
	C_ATTACK 				= 2, -- 普攻暴击
	N_SKILL 				= 3, -- 技能
	O_SKILL 				= 4  -- 卡牌技能效果结束
}
---------------------------------------------------
-- 服务器校验相关的常量 --
---------------------------------------------------

OState = {
	SLEEP 					= 1, 		-- 睡眠状态
	NORMAL 					= 2, 		-- 正常状态
	BATTLE 					= 3, 		-- 战斗状态
	MOVING 					= 4, 		-- 移动状态
	ATTACKING 				= 5, 		-- 攻击状态
	CASTING 				= 6, 		-- 施法状态
	MOVE_BACK 				= 7, 		-- 吹出战场 走回来的状态
	CHANTING				= 8, 		-- 读条中
	MOVE_FORCE 				= 9, 		-- 强制移动状态
	DIE 					= 10  		-- 死亡状态
}

ATTACK_MODIFIER_TAG 		= 0 		-- 攻击特效
TRIGGER_TAG 				= 0 		-- 触发器tag

FRIEND_TAG 					= 0 		-- 友方obj
ENEMY_TAG 					= 1000 		-- 敌方obj
OTHER_ENEMY_TAG 			= 2000 		-- 非qte召唤物
BECKON_TAG 					= 3000 		-- qte召唤物
WEATHER_TAG 				= 4000 		-- 天气
FRIEND_PLAYER_TAG 			= 5000 		-- 友方主角
ENEMY_PLAYER_TAG 			= 6000 		-- 敌方主角
OBSERVER_TAG 				= 7000 		-- 引导ob
GLOBAL_EFFECT_TAG 			= 8000 		-- 全局效果obj
DIRECTOR_TAG 				= 8100 		-- 导演obj
BULLET_TAG 					= 10000 	-- 子弹

-- 最大召唤物数量限制
MAX_BECKON_AMOUNT_LIMIT 	= 5

MAX_ENERGY = 100
LEADER_ENERGY_ADD = 50
ENERGY_PER_S = 1
ENERGY_PER_KILL = 20
ENERGY_PER_HURT = 3
ENERGY_PER_ATTACK = (4/3)
PLAYER_ENERGY_PER_S = 1
PLAYER_ENERGY_BY_NORMAL_SKILL = 1
PLAYER_ENERGY_BY_CI_SKILL = 3

BattleFormation = {
	[1] = {r = 4, c = 12},
	[2] = {r = 2, c = 12},
	[3] = {r = 5, c = 7},
	[4] = {r = 1, c = 7},
	[5] = {r = 3, c = 4},
}

-- 分隔距离 X个纵向单位
MELEE_STANCE_OFF_Y = 0.4

-- 时间精确度
TIME_ACCURACY = 10000
RE_TIME_ACCURACY = 0.0001

-- 血条最大值
HP_BAR_MAX_VALUE = 10000

-- spine
sp.AnimationName = {
	attack 				= 'attack',
	attacked 			= 'attacked',
	die 				= 'die',
	idle 				= 'idle',
	run 				= 'run',
	skill 				= 'skill',
	skill1 				= 'skill1',
	skill2 				= 'skill2',
	win 				= 'win',
	chant 				= 'chant',
	slaytarget 			= 'red',
	healtarget 			= 'green'
}
sp.CustomEvent = {
	cause_effect = 'cause_effect',
}
sp.CustomName = {
	BULLET_BONE_NAME = 'bullet',
	VIEW_BOX = 'viewBox',
	COLLISION_BOX = 'collisionBox'
}
sp.LaserAnimationName = {
	laserHead 	= '_laser_head',
	laserBody 	= '_laser_body',
	laserEnd 	= '_laser_end'
}

-- event
ObjectEvent = {
	OBJECT_DIE 					= 'OBJECT_DIE', 			-- 死亡事件
	OBJECT_REVIVE 				= 'OBJECT_REVIVE', 			-- 复活事件
	OBJECT_CAST_ENTER 			= 'OBJECT_CAST_ENTER', 		-- 施法事件
	OBJECT_CHANT_ENTER 			= 'OBJECT_CHANT_ENTER',		-- 读条事件
	OBJECT_CREATED 				= 'OBJECT_CREATED', 		-- 物体被创建事件
	OBJECT_PHASE_CHANGE 		= 'OBJECT_PHASE_CHANGE', 	-- 物体进行阶段转换
	OBJECT_LURK 				= 'OBJECT_LURK' 			-- 物体隐匿
}

-- 首场演示大战关卡id
FIRST_PERFORMANCE_STAGE_ID = 8999

-- 战斗胜利后引导至世界地图的关卡
GUIDE_QUEST_SUCCESS_WORLD_MAP = 53




if nil == rbqn_1 then
	rbqn_1 = RBQN.New(1)
end
if nil == rbqn_2000 then
	rbqn_2000 = RBQN.New(2000)
end
if nil == rbqn_1_5 then
	rbqn_1_5 = RBQN.New(1.5)
end
if nil == rbqn_0_01 then
	rbqn_0_01 = RBQN.New(0.01)
end
if nil == rbqn_0_1 then
	rbqn_0_1 = RBQN.New(0.1)
end
if nil == rbqn_10_1 then
	rbqn_10_1 = RBQN.New(10.1)
end
if nil == rbqn_0_5 then
	rbqn_0_5 = RBQN.New(0.5)
end
if nil == rbqn_1_1 then
	rbqn_1_1 = RBQN.New(1.1)
end
if nil == rbqn_4_1 then
	rbqn_4_1 = RBQN.New(4.1)
end
if nil == rbqn_1_7411 then
	rbqn_1_7411 = RBQN.New(1.7411)
end
if nil == rbqn_300 then
	rbqn_300 = RBQN.New(300)
end
if nil == rbqn_0_002 then
	rbqn_0_002 = RBQN.New(0.002)
end
if nil == rbqn_100 then
	rbqn_100 = RBQN.New(100)
end
if nil == rbqn_255 then
	rbqn_255 = RBQN.New(255)
end
if nil == rbqn_1_2 then
	rbqn_1_2 = RBQN.New(1.2)
end
if nil == rbqn_0_9 then
	rbqn_0_9 = RBQN.New(0.9)
end
if nil == rbqn_0_03 then
	rbqn_0_03 = RBQN.New(0.03)
end
if nil == rbqn_5_1 then
	rbqn_5_1 = RBQN.New(5.1)
end
if nil == rbqn_2_903784 then
	rbqn_2_903784 = RBQN.New(2.903784)
end
if nil == rbqn_0_00003515 then
	rbqn_0_00003515 = RBQN.New(0.00003515)	
end
if nil == rbqn_17222 then
	rbqn_17222 = RBQN.New(17222)
end
if nil == rbqn_0_0233 then
	rbqn_0_0233 = RBQN.New(0.0233)
end
if nil == rbqn_4_6115 then
	rbqn_4_6115 = RBQN.New(4.6115)
end
if nil == rbqn_0_00125 then
	rbqn_0_00125 = RBQN.New(0.00125)
end
if nil == rbqn_10000 then
	rbqn_10000 = RBQN.New(10000)
end
if nil == rbqn_0_0001 then
	rbqn_0_0001 = RBQN.New(0.0001)
end
if nil == rbqn_0_4999 then
	rbqn_0_4999 = RBQN.New(0.4999)
end
if nil == rbqn_0_333 then
	rbqn_0_333 = RBQN.New(1 / 3)
end
if nil == rbqn_855 then
	rbqn_855 = RBQN.New(855)
end
if nil == rbqn_0_0153 then
	rbqn_0_0153 = RBQN.New(0.0153)
end
if nil == rbqn_754_6965 then
	rbqn_754_6965 = RBQN.New(754.6965)
end
if nil == rbqn_246 then
	rbqn_246 = RBQN.New(246)
end
if nil == rbqn_0_027 then
	rbqn_0_027 = RBQN.New(0.027)
end
if nil == rbqn_751_4534 then
	rbqn_751_4534 = RBQN.New(751.4534)
end
if nil == rbqn_500 then
	rbqn_500 = RBQN.New(500)
end
if nil == rbqn_25750 then
	rbqn_25750 = RBQN.New(25750)
end
if nil == rbqn_1_05 then
	rbqn_1_05 = RBQN.New(1.05)
end
if nil == rbqn_36 then
	rbqn_36 = RBQN.New(36)
end
if nil == rbqn_0_7 then
	rbqn_0_7 = RBQN.New(0.7)
end
if nil == rbqn_45 then
	rbqn_45 = RBQN.New(45)
end
if nil == rbqn_0_23 then
	rbqn_0_23 = RBQN.New(0.23)
end
if nil == rbqn_0_4 then
	rbqn_0_4 = RBQN.New(0.4)
end
if nil == rbqn_280 then
	rbqn_280 = RBQN.New(280)
end