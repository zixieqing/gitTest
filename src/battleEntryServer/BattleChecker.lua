--[[
战斗校验器
--]]
serveralog('here battle checker come!!!')
------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

local BattleChecker = class('BattleChecker')
--[[
constructor
--]]
function BattleChecker:ctor( ... )
	self:Init()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function BattleChecker:Init()
	--初始化一些import
	self:InitImport()

end

--[[
import一些必要的文件
--]]
function BattleChecker:InitImport()
	__Require('battle.defines.ImportDefine')
end

---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- check begin --
---------------------------------------------------
--[[
检查一场战斗
@params stageId int 关卡id
@params constructorJson json 由客户端传入的构造器json
@params friendTeamJson json 友方阵容json
@params enemyTeamJson json 敌方阵容json
@params loadedResourcesJson json 加载的资源表 -> 客户端转换的数据
@params playerOperateJson json 玩家的手操信息
@return resultJson json {
	"battleResult" 	: int, 			//1 胜利 0 失败 -1 未完成 -2 出错
	"fightData" 	: string 		//脚本生成的fightData 结构和客户端请求quest/grade传的fightData相同
} 
--]]
function BattleChecker:RunOneBattle(stageId, constructorJson, friendTeamJson, enemyTeamJson, loadedResourcesJson, playerOperateJson)
	local battleResult = PassedBattle.NO_RESULT

	local loadedResources = String2TableNoMeta(loadedResourcesJson)
	local playerOperate = String2TableNoMeta(playerOperateJson)

	if not (loadedResources and playerOperate) then return end

	-- 起构造器
	local battleConstructor = require('battleEntryServer.BattleConstructor').new()
	battleConstructor:InitCheckerData(
		stageId,
		constructorJson,
		friendTeamJson,
		enemyTeamJson
	)

	local battleManager = __Require('battle.manager.BattleManager_Checker').new({
		battleConstructor = battleConstructor
	})

	-- 调用开始战斗
	battleManager:EnterBattle()
	-- 初始化一些客户端数据
	battleManager:InitClientBasedData(
		loadedResources,
		playerOperate
	)

	------------ 开始检查战斗 ------------
	local checkResult, fightData  = battleManager:StartCheckRecord()
	battleResult = checkResult ~= nil and checkResult or -2
	------------ 开始检查战斗 ------------

	local resultJson = json.encode({
		battleResult = battleResult,
		fightData = fightData
	})

	--[[

	-- 异常处理

	local callresult = xpcall(
		function ()

			local loadedResources = json.decode(loadedResourcesJson)
			local playerOperate = json.decode(playerOperateJson)

			if not (loadedResources and playerOperate) then return end

			-- 起构造器
			local battleConstructor = require('battleEntryServer.BattleConstructor').new()
			battleConstructor:InitCheckerData(
				stageId,
				constructorJson,
				friendTeamJson,
				enemyTeamJson
			)

			local battleManager = __Require('battle.manager.BattleManager_Checker').new({
				battleConstructor = battleConstructor
			})

			-- 调用开始战斗
			battleManager:EnterBattle()
			-- 初始化一些客户端数据
			battleManager:InitClientBasedData(
				loadedResources,
				playerOperate
			)

			------------ 开始检查战斗 ------------
			local checkResult = battleManager:StartCheckRecord()
			battleResult = checkResult and checkResult or -2
			------------ 开始检查战斗 ------------

		end,
		function ()

			battleResult = -2

		end
	)
	--]]

	return resultJson
end
--[[
服务器自发的发起一场自动战斗的逻辑 没有playerOperate的方法
@params stageId int 关卡id
@params constructorJson T2S 由客户端传入的构造器json
@params friendTeamJson json 友方阵容json
@params enemyTeamJson json 敌方阵容json
@params loadedResourcesJson T2S 加载的资源表 -> 客户端转换的数据
@return resultJson json {
	"battleResult" 	: int, 			//1 胜利 0 失败 -1 未完成 -2 出错
	"fightData" 	: string 		//脚本生成的fightData 结构和客户端请求quest/grade传的fightData相同
	"operateStr" 	: string 		//脚本生成的playerOperate数据 用于下发给客户端
} 
--]]
function BattleChecker:CalcOneBattle(stageId, constructorJson, friendTeamJson, enemyTeamJson, loadedResourcesJson)
	-- debug --
	-- stageId = 112

	-- constructorJson = '{["canBuyCheat"]=false,["rechallengeTime"]=1,["questBattleType"]=35,["enemyPlayerSkill"]={["activeSkill"]={},["passiveSkill"]={}},["randomConfig"]={["randomseed"]="4924634951"},["time"]=360,["friendPlayerSkill"]={["activeSkill"]={},["passiveSkill"]={}},["autoConnect"]=false,["canRechallenge"]=false,["enableConnect"]=true,["buyRevivalTimeMax"]=0,["openLevelRolling"]=false,["buyRevivalTime"]=0,["gameTimeScale"]=2}'
	-- friendTeamJson = '[[{"id":"770","playerId":"100493","cardId":"200111","level":"1","exp":"0","breakLevel":"0","vigour":"100","skill":{"10221":{"level":1},"10222":{"level":1}},"businessSkill":[],"favorability":"1770","favorabilityLevel":"6","createTime":"2019-04-10 19:03:57","cardName":null,"defaultSkinId":"251110","marryTime":"1554895637","isArtifactUnlock":"0","lunaTowerHp":"1.0000","lunaTowerEnergy":"0.0000","artifactTalent":[],"attack":128,"defence":17,"hp":552,"critRate":1580,"critDamage":2187,"attackRate":1365},{"id":"756","playerId":"100493","cardId":"200043","level":"80","exp":"532000","breakLevel":"5","vigour":"100","skill":{"10085":{"level":1},"10086":{"level":1},"90043":{"level":1}},"businessSkill":{"30101":{"level":1}},"favorability":"0","favorabilityLevel":"1","createTime":"2019-01-15 19:04:11","cardName":null,"defaultSkinId":"250430","marryTime":null,"isArtifactUnlock":"0","lunaTowerHp":"1.0000","lunaTowerEnergy":"0.0000","artifactTalent":[],"attack":543,"defence":193,"hp":2897,"critRate":5772,"critDamage":5538,"attackRate":5676},{"id":"740","playerId":"100493","cardId":"200048","level":"2","exp":"50","breakLevel":"0","vigour":"100","skill":{"10095":{"level":1},"10096":{"level":1},"90048":{"level":1}},"businessSkill":{"30096":{"level":1}},"favorability":"0","favorabilityLevel":"1","createTime":"2018-12-25 14:39:20","cardName":null,"defaultSkinId":"250480","marryTime":null,"isArtifactUnlock":"0","lunaTowerHp":"1.0000","lunaTowerEnergy":"0.0000","artifactTalent":[],"attack":87,"defence":16,"hp":542,"critRate":1259,"critDamage":1507,"attackRate":1072},{"id":"843","playerId":"100493","cardId":"200127","level":"59","exp":"205400","breakLevel":"5","vigour":"100","skill":{"10253":{"level":1},"10254":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2019-06-18 23:12:23","cardName":null,"defaultSkinId":"251270","marryTime":null,"isArtifactUnlock":"1","lunaTowerHp":"1.0000","lunaTowerEnergy":"0.0000","artifactTalent":{"8":{"id":"589","playerId":"100493","playerCardId":"843","talentId":"8","level":"3","type":"1","fragmentNum":"87","gemstoneId":null,"createTime":"2019-06-18 23:13:11"},"6":{"id":"587","playerId":"100493","playerCardId":"843","talentId":"6","level":"1","type":"2","fragmentNum":"100","gemstoneId":null,"createTime":"2019-06-18 23:13:01"},"2":{"id":"583","playerId":"100493","playerCardId":"843","talentId":"2","level":"2","type":"1","fragmentNum":"27","gemstoneId":null,"createTime":"2019-06-18 23:12:51"},"4":{"id":"585","playerId":"100493","playerCardId":"843","talentId":"4","level":"2","type":"1","fragmentNum":"36","gemstoneId":null,"createTime":"2019-06-18 23:12:57"},"7":{"id":"588","playerId":"100493","playerCardId":"843","talentId":"7","level":"2","type":"1","fragmentNum":"51","gemstoneId":null,"createTime":"2019-06-18 23:13:09"},"5":{"id":"586","playerId":"100493","playerCardId":"843","talentId":"5","level":"2","type":"1","fragmentNum":"42","gemstoneId":null,"createTime":"2019-06-18 23:12:59"},"1":{"id":"582","playerId":"100493","playerCardId":"843","talentId":"1","level":"2","type":"1","fragmentNum":"21","gemstoneId":null,"createTime":"2019-06-18 23:12:49"},"3":{"id":"584","playerId":"100493","playerCardId":"843","talentId":"3","level":"1","type":"2","fragmentNum":"50","gemstoneId":null,"createTime":"2019-06-18 23:12:54"},"9":{"id":"590","playerId":"100493","playerCardId":"843","talentId":"9","level":"1","type":"2","fragmentNum":"200","gemstoneId":"283210","createTime":"2019-06-18 23:13:15"}},"attack":658,"defence":197,"hp":5644,"critRate":7332,"critDamage":2728,"attackRate":6994},{"id":"759","playerId":"100493","cardId":"200045","level":"3","exp":"150","breakLevel":"5","vigour":"100","skill":{"10089":{"level":1},"10090":{"level":1},"90045":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2019-03-05 15:46:37","cardName":null,"defaultSkinId":"250450","marryTime":null,"isArtifactUnlock":"1","lunaTowerHp":"1.0000","lunaTowerEnergy":"0.0000","artifactTalent":{"11":{"id":"370","playerId":"100493","playerCardId":"759","talentId":"11","level":"3","type":"1","fragmentNum":"120","gemstoneId":null,"createTime":"2019-03-05 15:48:21"},"4":{"id":"363","playerId":"100493","playerCardId":"759","talentId":"4","level":"2","type":"1","fragmentNum":"36","gemstoneId":null,"createTime":"2019-03-05 15:48:00"},"8":{"id":"367","playerId":"100493","playerCardId":"759","talentId":"8","level":"3","type":"1","fragmentNum":"87","gemstoneId":null,"createTime":"2019-03-05 15:48:13"},"16":{"id":"373","playerId":"100493","playerCardId":"759","talentId":"16","level":"4","type":"1","fragmentNum":"216","gemstoneId":null,"createTime":"2019-03-05 15:48:29"},"15":{"id":"372","playerId":"100493","playerCardId":"759","talentId":"15","level":"4","type":"1","fragmentNum":"186","gemstoneId":null,"createTime":"2019-03-05 15:48:26"},"17":{"id":"374","playerId":"100493","playerCardId":"759","talentId":"17","level":"4","type":"1","fragmentNum":"243","gemstoneId":null,"createTime":"2019-03-05 15:48:33"},"5":{"id":"364","playerId":"100493","playerCardId":"759","talentId":"5","level":"2","type":"1","fragmentNum":"42","gemstoneId":null,"createTime":"2019-03-05 15:48:03"},"3":{"id":"362","playerId":"100493","playerCardId":"759","talentId":"3","level":"1","type":"2","fragmentNum":"50","gemstoneId":null,"createTime":"2019-03-05 15:47:07"},"1":{"id":"360","playerId":"100493","playerCardId":"759","talentId":"1","level":"2","type":"1","fragmentNum":"21","gemstoneId":null,"createTime":"2019-03-05 15:47:02"},"2":{"id":"361","playerId":"100493","playerCardId":"759","talentId":"2","level":"2","type":"1","fragmentNum":"27","gemstoneId":null,"createTime":"2019-03-05 15:47:04"},"6":{"id":"365","playerId":"100493","playerCardId":"759","talentId":"6","level":"1","type":"2","fragmentNum":"100","gemstoneId":null,"createTime":"2019-03-05 15:48:05"},"18":{"id":"375","playerId":"100493","playerCardId":"759","talentId":"18","level":"1","type":"2","fragmentNum":"800","gemstoneId":"283010","createTime":"2019-03-05 15:48:36"},"7":{"id":"366","playerId":"100493","playerCardId":"759","talentId":"7","level":"2","type":"1","fragmentNum":"51","gemstoneId":null,"createTime":"2019-03-05 15:48:10"},"14":{"id":"371","playerId":"100493","playerCardId":"759","talentId":"14","level":"1","type":"2","fragmentNum":"400","gemstoneId":null,"createTime":"2019-03-05 15:48:24"},"9":{"id":"368","playerId":"100493","playerCardId":"759","talentId":"9","level":"1","type":"2","fragmentNum":"200","gemstoneId":null,"createTime":"2019-03-05 15:48:16"},"10":{"id":"369","playerId":"100493","playerCardId":"759","talentId":"10","level":"3","type":"1","fragmentNum":"105","gemstoneId":null,"createTime":"2019-03-05 15:48:18"}},"attack":352,"defence":81,"hp":2503,"critRate":11566,"critDamage":10214,"attackRate":12196}]]'
	-- enemyTeamJson = '[[{"id":"455","playerId":"100451","cardId":"200199","level":"100","exp":"1120400","breakLevel":"5","vigour":"300","skill":{"10397":{"level":34},"10398":{"level":34},"90199":{"level":34}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2019-11-18 19:01:18","cardName":null,"defaultSkinId":"251990","marryTime":null,"isArtifactUnlock":"0","lunaTowerHp":"0.9515","lunaTowerEnergy":"0.8996","artifactTalent":[],"attack":3328,"defence":517,"hp":10056,"critRate":5812,"critDamage":7606,"attackRate":6805},{"id":"502","playerId":"100451","cardId":"200207","level":"100","exp":"1120200","breakLevel":"5","vigour":"100","skill":{"10413":{"level":1},"10414":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2020-01-06 20:16:38","cardName":null,"defaultSkinId":"252070","marryTime":null,"isArtifactUnlock":"1","lunaTowerHp":"0.9485","lunaTowerEnergy":"0.2921","artifactTalent":{"11":{"id":"216","playerId":"100451","playerCardId":"502","talentId":"11","level":"3","type":"1","fragmentNum":"120","gemstoneId":null,"createTime":"2020-01-09 18:41:14"},"4":{"id":"209","playerId":"100451","playerCardId":"502","talentId":"4","level":"2","type":"1","fragmentNum":"36","gemstoneId":null,"createTime":"2020-01-09 18:40:48"},"8":{"id":"213","playerId":"100451","playerCardId":"502","talentId":"8","level":"3","type":"1","fragmentNum":"87","gemstoneId":null,"createTime":"2020-01-09 18:41:01"},"16":{"id":"219","playerId":"100451","playerCardId":"502","talentId":"16","level":"4","type":"1","fragmentNum":"216","gemstoneId":null,"createTime":"2020-01-09 18:41:25"},"15":{"id":"218","playerId":"100451","playerCardId":"502","talentId":"15","level":"4","type":"1","fragmentNum":"186","gemstoneId":null,"createTime":"2020-01-09 18:41:22"},"17":{"id":"220","playerId":"100451","playerCardId":"502","talentId":"17","level":"4","type":"1","fragmentNum":"243","gemstoneId":null,"createTime":"2020-01-09 18:41:29"},"5":{"id":"210","playerId":"100451","playerCardId":"502","talentId":"5","level":"2","type":"1","fragmentNum":"42","gemstoneId":null,"createTime":"2020-01-09 18:40:52"},"3":{"id":"208","playerId":"100451","playerCardId":"502","talentId":"3","level":"1","type":"2","fragmentNum":"50","gemstoneId":null,"createTime":"2020-01-09 18:40:45"},"1":{"id":"206","playerId":"100451","playerCardId":"502","talentId":"1","level":"2","type":"1","fragmentNum":"21","gemstoneId":null,"createTime":"2020-01-09 18:40:38"},"2":{"id":"207","playerId":"100451","playerCardId":"502","talentId":"2","level":"2","type":"1","fragmentNum":"27","gemstoneId":null,"createTime":"2020-01-09 18:40:41"},"6":{"id":"211","playerId":"100451","playerCardId":"502","talentId":"6","level":"1","type":"2","fragmentNum":"100","gemstoneId":null,"createTime":"2020-01-09 18:40:55"},"18":{"id":"221","playerId":"100451","playerCardId":"502","talentId":"18","level":"1","type":"2","fragmentNum":"800","gemstoneId":null,"createTime":"2020-01-09 18:41:32"},"7":{"id":"212","playerId":"100451","playerCardId":"502","talentId":"7","level":"2","type":"1","fragmentNum":"51","gemstoneId":null,"createTime":"2020-01-09 18:40:59"},"14":{"id":"217","playerId":"100451","playerCardId":"502","talentId":"14","level":"1","type":"2","fragmentNum":"400","gemstoneId":null,"createTime":"2020-01-09 18:41:18"},"9":{"id":"214","playerId":"100451","playerCardId":"502","talentId":"9","level":"1","type":"2","fragmentNum":"200","gemstoneId":null,"createTime":"2020-01-09 18:41:06"},"10":{"id":"215","playerId":"100451","playerCardId":"502","talentId":"10","level":"3","type":"1","fragmentNum":"105","gemstoneId":null,"createTime":"2020-01-09 18:41:11"}},"attack":3473,"defence":405,"hp":9479,"critRate":12140,"critDamage":12961,"attackRate":11448},{"id":"360","playerId":"100451","cardId":"200116","level":"91","exp":"814784","breakLevel":"5","vigour":"100","skill":{"10231":{"level":1},"10232":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2018-09-14 18:22:28","cardName":null,"defaultSkinId":"251160","marryTime":null,"isArtifactUnlock":"0","lunaTowerHp":"1.0000","lunaTowerEnergy":"0.0000","artifactTalent":[],"attack":1758,"defence":489,"hp":7180,"critRate":8925,"critDamage":8881,"attackRate":5158},{"id":"448","playerId":"100451","cardId":"200122","level":"100","exp":"1119546","breakLevel":"5","vigour":"100","skill":{"10243":{"level":35},"10244":{"level":35},"90122":{"level":35}},"businessSkill":[],"favorability":"1750","favorabilityLevel":"5","createTime":"2019-07-10 11:34:11","cardName":null,"defaultSkinId":"251220","marryTime":null,"isArtifactUnlock":"1","lunaTowerHp":"1.0000","lunaTowerEnergy":"1.0000","artifactTalent":{"16":{"id":"119","playerId":"100451","playerCardId":"448","talentId":"16","level":"4","type":"1","fragmentNum":"258","gemstoneId":null,"createTime":"2019-07-17 00:02:35"},"15":{"id":"118","playerId":"100451","playerCardId":"448","talentId":"15","level":"4","type":"1","fragmentNum":"228","gemstoneId":null,"createTime":"2019-07-17 00:02:31"},"5":{"id":"108","playerId":"100451","playerCardId":"448","talentId":"5","level":"2","type":"1","fragmentNum":"42","gemstoneId":null,"createTime":"2019-07-17 00:02:03"},"12":{"id":"114","playerId":"100451","playerCardId":"448","talentId":"12","level":"3","type":"1","fragmentNum":"120","gemstoneId":null,"createTime":"2019-07-17 00:02:19"},"3":{"id":"106","playerId":"100451","playerCardId":"448","talentId":"3","level":"1","type":"2","fragmentNum":"50","gemstoneId":"280010","createTime":"2019-07-17 00:01:57"},"1":{"id":"104","playerId":"100451","playerCardId":"448","talentId":"1","level":"2","type":"1","fragmentNum":"21","gemstoneId":null,"createTime":"2019-07-17 00:01:52"},"2":{"id":"105","playerId":"100451","playerCardId":"448","talentId":"2","level":"2","type":"1","fragmentNum":"27","gemstoneId":null,"createTime":"2019-07-17 00:01:54"},"6":{"id":"109","playerId":"100451","playerCardId":"448","talentId":"6","level":"1","type":"2","fragmentNum":"100","gemstoneId":"282110","createTime":"2019-07-17 00:02:06"},"13":{"id":"115","playerId":"100451","playerCardId":"448","talentId":"13","level":"3","type":"1","fragmentNum":"138","gemstoneId":null,"createTime":"2019-07-17 00:02:22"},"7":{"id":"110","playerId":"100451","playerCardId":"448","talentId":"7","level":"2","type":"1","fragmentNum":"51","gemstoneId":null,"createTime":"2019-07-17 00:02:09"},"14":{"id":"117","playerId":"100451","playerCardId":"448","talentId":"14","level":"1","type":"2","fragmentNum":"400","gemstoneId":"284010","createTime":"2019-07-17 00:02:28"},"9":{"id":"112","playerId":"100451","playerCardId":"448","talentId":"9","level":"1","type":"2","fragmentNum":"200","gemstoneId":"283010","createTime":"2019-07-17 00:02:14"},"10":{"id":"113","playerId":"100451","playerCardId":"448","talentId":"10","level":"3","type":"1","fragmentNum":"105","gemstoneId":null,"createTime":"2019-07-17 00:02:16"},"17":{"id":"120","playerId":"100451","playerCardId":"448","talentId":"17","level":"4","type":"1","fragmentNum":"288","gemstoneId":null,"createTime":"2019-07-17 00:02:38"},"8":{"id":"111","playerId":"100451","playerCardId":"448","talentId":"8","level":"3","type":"1","fragmentNum":"87","gemstoneId":null,"createTime":"2019-07-17 00:02:11"},"4":{"id":"107","playerId":"100451","playerCardId":"448","talentId":"4","level":"2","type":"1","fragmentNum":"36","gemstoneId":null,"createTime":"2019-07-17 00:02:01"},"11":{"id":"116","playerId":"100451","playerCardId":"448","talentId":"11","level":"3","type":"1","fragmentNum":"153","gemstoneId":null,"createTime":"2019-07-17 00:02:24"},"18":{"id":"121","playerId":"100451","playerCardId":"448","talentId":"18","level":"1","type":"2","fragmentNum":"800","gemstoneId":"280210","createTime":"2019-07-17 00:02:41"}},"attack":5429,"defence":226,"hp":9255,"critRate":17366,"critDamage":12665,"attackRate":10548},{"id":"573","playerId":"100451","cardId":"200196","level":"1","exp":"0","breakLevel":"5","vigour":"100","skill":{"10391":{"level":1},"10392":{"level":1},"90196":{"level":1}},"businessSkill":[],"favorability":"0","favorabilityLevel":"1","createTime":"2020-06-09 21:42:36","cardName":null,"defaultSkinId":"251961","marryTime":null,"isArtifactUnlock":"1","lunaTowerHp":"1.0000","lunaTowerEnergy":"0.0000","artifactTalent":[],"attack":127,"defence":29,"hp":700,"critRate":6812,"critDamage":8431,"attackRate":5943}]]'
	-- -- enemyTeamJson = "[[{\"cardId\":\"301042\",\"campType\":null,\"level\":\"37\",\"attrGrow\":\"2.02\",\"skillGrow\":\"2.02\",\"placeId\":\"33\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"300009\",\"campType\":null,\"level\":\"37\",\"attrGrow\":\"2.02\",\"skillGrow\":\"2.02\",\"placeId\":\"25\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"300009\",\"campType\":null,\"level\":\"37\",\"attrGrow\":\"2.02\",\"skillGrow\":\"2.02\",\"placeId\":\"15\",\"initialHp\":0,\"initialHpValue\":null}]]"
	-- loadedResourcesJson = "{[1]={[\"boss_weak\"]=true,[\"effect_200085\"]=true,[\"200085\"]=true,[\"200004\"]=true,[\"300010\"]=true,[\"200110_1_1\"]=true,[\"hurt_8\"]=true,[\"200110_1_2\"]=true,[\"effect_80002\"]=true,[\"hurt_15\"]=true,[\"boss_chant_progressBar\"]=true,[\"300011\"]=true,[\"320002\"]=true,[\"effect_200082\"]=true,[\"effect_200149\"]=true,[\"200082\"]=true,[\"effect_80004\"]=true,[\"hurt_7\"]=true,[\"effect_300009\"]=true,[\"200149\"]=true,[\"hurt_2\"]=true,[\"300009\"]=true,[\"hurt_16\"]=true,[\"hurt_3\"]=true,[\"hurt_5\"]=true,[\"hurt_28\"]=true,[\"hurt_10\"]=true,[\"effect_200004\"]=true,[\"hurt_30\"]=true}}"
	-- debug --

	local battleResult = PassedBattle.NO_RESULT

	local loadedResources = String2TableNoMeta(loadedResourcesJson)
	local playerOperate = String2TableNoMeta(playerOperateJson)

	if not (loadedResources) then return end

	------------ 处理一次随机种子 ------------
	local constructorData = String2TableNoMeta(constructorJson)
	local constructorSeed = checktable(constructorData.randomConfig).randomseed
	local randomseed = constructorSeed or string.reverse(tostring(os.time()))
	constructorData.randomConfig = BattleRandomConfigStruct.New(randomseed)
	local constructorJson_ = Table2StringNoMeta(constructorData)
	------------ 处理一次随机种子 ------------

	-- 起构造器
	local battleConstructor = require('battleEntryServer.BattleConstructor').new()
	battleConstructor:InitCheckerData(
		stageId,
		constructorJson_,
		friendTeamJson,
		enemyTeamJson,
		true
	)

	local battleManager = __Require('battle.manager.BattleManager_Calculator').new({
		battleConstructor = battleConstructor
	})

	-- 调用开始战斗
	battleManager:EnterBattle()
	-- 初始化一些客户端数据
	battleManager:InitClientBasedData(
		loadedResources
	)

	------------ 开始检查战斗 ------------
	local checkResult, fightData, operateStr = battleManager:StartCheckRecord()
	battleResult = checkResult ~= nil and checkResult or -2
	------------ 开始检查战斗 ------------

	-- 伤害统计数据
	local skadaResult = json.encode(battleManager:StartCheckSkada())


	local resultJson = json.encode({
		battleResult = battleResult,
		fightData = fightData,
		operateStr = operateStr,
		skadaResult = skadaResult,
		constructorJson = constructorJson_
	})

	return resultJson
end
--[[
将两方多队的res数据表合并
@params friendLoadedResourcesJson string 友军加载的资源表 -> 客户端转换的数据
@params enemyLoadedResourcesJson string 敌军加载的资源表 -> 客户端转换的数据
@return loadedResources table 加载的资源表 -> 脚本直接能用的lua结构
--]]
function BattleChecker.MergeLoadedResources(friendLoadedResourcesJson, enemyLoadedResourcesJson)
	local friendLoadedResources = String2TableNoMeta(friendLoadedResourcesJson)
	local enemyLoadedResources = String2TableNoMeta(enemyLoadedResourcesJson)

	-- 合并资源
	local loadedResources = {}
	local teamAmount = math.max(
		table.nums(friendLoadedResources),
		table.nums(enemyLoadedResources)
	)
	local fres = nil
	local eres = nil

	for teamIndex = 1, teamAmount do

		local mergedRes = {}

		-- 友军资源
		fres = friendLoadedResources[teamIndex]
		if nil ~= fres then
			for spineCacheName, exist in pairs(fres) do
				if nil == mergedRes[spineCacheName] then
					mergedRes[spineCacheName] = exist
				else
					mergedRes[spineCacheName] = mergedRes[spineCacheName] or exist
				end
			end
		end

		-- 敌军资源
		eres = enemyLoadedResources[teamIndex]
		if nil ~= eres then
			for spineCacheName, exist in pairs(eres) do
				if nil == mergedRes[spineCacheName] then
					mergedRes[spineCacheName] = exist
				else
					mergedRes[spineCacheName] = mergedRes[spineCacheName] or exist
				end
			end
		end

		loadedResources[teamIndex] = mergedRes

	end

	return loadedResources
end
--[[
将两方多队的res数据表合并
@params friendLoadedResourcesJson string 友军加载的资源表 -> 客户端转换的数据
@params enemyLoadedResourcesJson string 敌军加载的资源表 -> 客户端转换的数据
@return loadedResourcesJson string 加载的资源表 -> 客户端转换的数据
--]]
function BattleChecker.MergeLoadedResourcesJson(friendLoadedResourcesJson, enemyLoadedResourcesJson)
	local loadedResourcesJson = Table2StringNoMeta(BattleChecker.MergeLoadedResources(
		friendLoadedResourcesJson, enemyLoadedResourcesJson
	))
	return loadedResourcesJson
end
---------------------------------------------------
-- check over --
---------------------------------------------------

---------------------------------------------------
-- debug begin --
---------------------------------------------------
function BattleChecker:DebugBattle()
	local serverdatajson = '{"questId": 112}'
	local serverData = json.decode(serverdatajson)

	local loadedResourcesJson = "{[1]={[\"boss_weak\"]=true,[\"effect_200085\"]=true,[\"200085\"]=true,[\"200004\"]=true,[\"300010\"]=true,[\"200110_1_1\"]=true,[\"hurt_8\"]=true,[\"200110_1_2\"]=true,[\"effect_80002\"]=true,[\"hurt_15\"]=true,[\"boss_chant_progressBar\"]=true,[\"300011\"]=true,[\"320002\"]=true,[\"effect_200082\"]=true,[\"effect_200149\"]=true,[\"200082\"]=true,[\"effect_80004\"]=true,[\"hurt_7\"]=true,[\"effect_300009\"]=true,[\"200149\"]=true,[\"hurt_2\"]=true,[\"300009\"]=true,[\"hurt_16\"]=true,[\"hurt_3\"]=true,[\"hurt_5\"]=true,[\"hurt_28\"]=true,[\"hurt_10\"]=true,[\"effect_200004\"]=true,[\"hurt_30\"]=true}}"
	local loadedResources = String2TableNoMeta(loadedResourcesJson)

	local playerOperateJson = "{[0]={[1]={[\"maxParams\"]=0,[\"managerName\"]=\"G_BattleLogicMgr\",[\"functionName\"]=\"RenderReadyStartNextWaveHandler\",[\"variableParams\"]={}}},[115]={[1]={[\"maxParams\"]=1,[\"managerName\"]=\"G_BattleLogicMgr\",[\"functionName\"]=\"RenderSetTempTimeScaleHandler\",[\"variableParams\"]={[1]=1}}},[25]={[1]={[\"maxParams\"]=0,[\"managerName\"]=\"G_BattleLogicMgr\",[\"functionName\"]=\"RenderStartNextWaveHandler\",[\"variableParams\"]={}}},[201]={[1]={[\"maxParams\"]=0,[\"managerName\"]=\"G_BattleLogicMgr\",[\"functionName\"]=\"RenderStartNextWaveHandler\",[\"variableParams\"]={}}},[178]={[1]={[\"maxParams\"]=0,[\"managerName\"]=\"G_BattleLogicMgr\",[\"functionName\"]=\"RenderWaveTransitionOverHandler\",[\"variableParams\"]={}},[2]={[\"maxParams\"]=0,[\"managerName\"]=\"G_BattleLogicMgr\",[\"functionName\"]=\"RenderRecoverTempTimeScaleHandler\",[\"variableParams\"]={}}},[144]={[1]={[\"maxParams\"]=0,[\"managerName\"]=\"G_BattleLogicMgr\",[\"functionName\"]=\"RenderWaveTransitionStartHandler\",[\"variableParams\"]={}}}}"
	local playerOperate = String2TableNoMeta(playerOperateJson)

	local constructorJson = "{[\"canBuyCheat\"]=false,[\"rechallengeTime\"]=-1,[\"questBattleType\"]=1,[\"randomConfig\"]={[\"randomseed\"]=\"4772635751\"},[\"time\"]=300,[\"friendPlayerSkill\"]={[\"activeSkill\"]={[1]={[\"skillId\"]=80069},[2]={[\"skillId\"]=80025}},[\"passiveSkill\"]={[1]={[\"skillId\"]=80001},[2]={[\"skillId\"]=80045},[3]={[\"skillId\"]=80050},[4]={[\"skillId\"]=80051},[5]={[\"skillId\"]=80092},[6]={[\"skillId\"]=80100},[7]={[\"skillId\"]=80102}}},[\"weather\"]={[1]=\"9\"},[\"autoConnect\"]=false,[\"canRechallenge\"]=true,[\"enableConnect\"]=true,[\"buyRevivalTimeMax\"]=0,[\"openLevelRolling\"]=true,[\"buyRevivalTime\"]=0,[\"gameTimeScale\"]=2,[\"phaseChangeDatas\"]={}}"
	local friendTeamJson = "[[{\"id\":\"568\",\"playerId\":\"100196\",\"cardId\":\"200082\",\"level\":\"97\",\"exp\":\"1010670\",\"breakLevel\":\"5\",\"vigour\":\"100\",\"skill\":{\"10163\":{\"level\":33},\"10164\":{\"level\":33},\"90082\":{\"level\":1}},\"businessSkill\":[],\"favorability\":\"1750\",\"favorabilityLevel\":\"5\",\"createTime\":\"2018-07-09 16:11:42\",\"cardName\":null,\"defaultSkinId\":\"250820\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"lunaTowerHp\":\"1.0000\",\"lunaTowerEnergy\":\"0.0000\",\"pets\":{\"1\":{\"petId\":\"210060\",\"level\":\"30\",\"breakLevel\":\"15\",\"character\":\"1\",\"attr\":[{\"type\":\"1\",\"num\":\"70\",\"quality\":\"5\"},{\"type\":\"1\",\"num\":\"70\",\"quality\":\"5\"},{\"type\":\"1\",\"num\":\"70\",\"quality\":\"5\"},{\"type\":\"1\",\"num\":\"70\",\"quality\":\"5\"}],\"isEvolution\":\"1\",\"playerPetId\":\"666\"}},\"artifactTalent\":[],\"playerPetId\":\"666\",\"attack\":5007,\"defence\":433,\"hp\":8297,\"critRate\":3543,\"critDamage\":3140,\"attackRate\":1944},{\"id\":\"520\",\"playerId\":\"100196\",\"cardId\":\"200004\",\"level\":\"97\",\"exp\":\"1010670\",\"breakLevel\":\"5\",\"vigour\":\"100\",\"skill\":{\"10007\":{\"level\":33},\"10008\":{\"level\":33},\"90004\":{\"level\":1}},\"businessSkill\":[],\"favorability\":\"1750\",\"favorabilityLevel\":\"5\",\"createTime\":\"2018-06-24 22:51:31\",\"cardName\":null,\"defaultSkinId\":\"250040\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"lunaTowerHp\":\"1.0000\",\"lunaTowerEnergy\":\"0.0000\",\"pets\":{\"1\":{\"petId\":\"210060\",\"level\":\"30\",\"breakLevel\":\"10\",\"character\":\"3\",\"attr\":[{\"type\":\"3\",\"num\":\"700\",\"quality\":\"5\"},{\"type\":\"3\",\"num\":\"700\",\"quality\":\"5\"},{\"type\":\"3\",\"num\":\"700\",\"quality\":\"5\"},{\"type\":\"3\",\"num\":\"700\",\"quality\":\"5\"}],\"isEvolution\":\"0\",\"playerPetId\":\"229\"}},\"artifactTalent\":[],\"playerPetId\":\"229\",\"attack\":784,\"defence\":945,\"hp\":24253,\"critRate\":3337,\"critDamage\":3618,\"attackRate\":1835},{\"id\":\"760\",\"playerId\":\"100196\",\"cardId\":\"200149\",\"level\":\"100\",\"exp\":\"1119546\",\"breakLevel\":\"5\",\"vigour\":\"100\",\"skill\":{\"10297\":{\"level\":34},\"10298\":{\"level\":34}},\"businessSkill\":[],\"favorability\":\"1750\",\"favorabilityLevel\":\"5\",\"createTime\":\"2019-03-14 16:01:30\",\"cardName\":null,\"defaultSkinId\":\"251490\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"lunaTowerHp\":\"1.0000\",\"lunaTowerEnergy\":\"0.0000\",\"artifactTalent\":[],\"attack\":2252,\"defence\":535,\"hp\":7236,\"critRate\":10281,\"critDamage\":5924,\"attackRate\":4784},{\"id\":\"870\",\"playerId\":\"100196\",\"cardId\":\"200110\",\"level\":\"100\",\"exp\":\"1119546\",\"breakLevel\":\"5\",\"vigour\":\"100\",\"skill\":{\"10219\":{\"level\":34},\"10220\":{\"level\":34},\"90110\":{\"level\":34}},\"businessSkill\":[],\"favorability\":\"1750\",\"favorabilityLevel\":\"5\",\"createTime\":\"2019-09-08 19:35:39\",\"cardName\":null,\"defaultSkinId\":\"251100\",\"marryTime\":null,\"isArtifactUnlock\":\"1\",\"lunaTowerHp\":\"1.0000\",\"lunaTowerEnergy\":\"0.0000\",\"artifactTalent\":{\"16\":{\"id\":\"26\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"16\",\"level\":\"4\",\"type\":\"1\",\"fragmentNum\":\"258\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:55\"},\"12\":{\"id\":\"22\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"12\",\"level\":\"3\",\"type\":\"1\",\"fragmentNum\":\"138\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:41\"},\"10\":{\"id\":\"20\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"10\",\"level\":\"3\",\"type\":\"1\",\"fragmentNum\":\"105\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:35\"},\"9\":{\"id\":\"19\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"9\",\"level\":\"1\",\"type\":\"2\",\"fragmentNum\":\"200\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:33\"},\"13\":{\"id\":\"23\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"13\",\"level\":\"3\",\"type\":\"1\",\"fragmentNum\":\"153\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:44\"},\"2\":{\"id\":\"12\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"2\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"27\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:40:55\"},\"15\":{\"id\":\"25\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"15\",\"level\":\"4\",\"type\":\"1\",\"fragmentNum\":\"228\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:51\"},\"14\":{\"id\":\"24\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"14\",\"level\":\"1\",\"type\":\"2\",\"fragmentNum\":\"400\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:46\"},\"8\":{\"id\":\"18\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"8\",\"level\":\"3\",\"type\":\"1\",\"fragmentNum\":\"87\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:27\"},\"1\":{\"id\":\"11\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"1\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"21\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:40:51\"},\"6\":{\"id\":\"16\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"6\",\"level\":\"1\",\"type\":\"2\",\"fragmentNum\":\"100\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:15\"},\"11\":{\"id\":\"21\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"11\",\"level\":\"3\",\"type\":\"1\",\"fragmentNum\":\"120\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:38\"},\"5\":{\"id\":\"15\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"5\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"42\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:12\"},\"3\":{\"id\":\"13\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"3\",\"level\":\"1\",\"type\":\"2\",\"fragmentNum\":\"50\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:40:58\"},\"4\":{\"id\":\"14\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"4\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"36\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:10\"},\"7\":{\"id\":\"17\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"7\",\"level\":\"2\",\"type\":\"1\",\"fragmentNum\":\"51\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:22\"},\"17\":{\"id\":\"27\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"17\",\"level\":\"4\",\"type\":\"1\",\"fragmentNum\":\"288\",\"gemstoneId\":null,\"createTime\":\"2019-09-08 19:41:59\"},\"18\":{\"id\":\"28\",\"playerId\":\"100196\",\"playerCardId\":\"870\",\"talentId\":\"18\",\"level\":\"1\",\"type\":\"2\",\"fragmentNum\":\"800\",\"gemstoneId\":\"285010\",\"createTime\":\"2019-09-08 19:42:09\"}},\"attack\":3422,\"defence\":387,\"hp\":11031,\"critRate\":11052,\"critDamage\":12236,\"attackRate\":10227},{\"id\":\"571\",\"playerId\":\"100196\",\"cardId\":\"200085\",\"level\":\"97\",\"exp\":\"1010670\",\"breakLevel\":\"4\",\"vigour\":\"100\",\"skill\":{\"10169\":{\"level\":33},\"10170\":{\"level\":33}},\"businessSkill\":[],\"favorability\":\"1050\",\"favorabilityLevel\":\"4\",\"createTime\":\"2018-07-11 15:26:22\",\"cardName\":null,\"defaultSkinId\":\"250850\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"lunaTowerHp\":\"1.0000\",\"lunaTowerEnergy\":\"0.0000\",\"pets\":{\"1\":{\"petId\":\"210040\",\"level\":\"30\",\"breakLevel\":\"15\",\"character\":\"1\",\"attr\":[{\"type\":\"1\",\"num\":\"70\",\"quality\":\"5\"},{\"type\":\"1\",\"num\":\"70\",\"quality\":\"5\"},{\"type\":\"1\",\"num\":\"70\",\"quality\":\"5\"},{\"type\":\"1\",\"num\":\"70\",\"quality\":\"5\"}],\"isEvolution\":\"1\",\"playerPetId\":\"667\"}},\"artifactTalent\":[],\"playerPetId\":\"667\",\"attack\":4184,\"defence\":175,\"hp\":5185,\"critRate\":5777,\"critDamage\":3384,\"attackRate\":5501}]]"
	local enemyTeamJson = "[[{\"cardId\":\"301042\",\"campType\":null,\"level\":\"37\",\"attrGrow\":\"2.02\",\"skillGrow\":\"2.02\",\"placeId\":\"33\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"300009\",\"campType\":null,\"level\":\"37\",\"attrGrow\":\"2.02\",\"skillGrow\":\"2.02\",\"placeId\":\"25\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"300009\",\"campType\":null,\"level\":\"37\",\"attrGrow\":\"2.02\",\"skillGrow\":\"2.02\",\"placeId\":\"15\",\"initialHp\":0,\"initialHpValue\":null}],[{\"cardId\":\"301043\",\"campType\":null,\"level\":\"37\",\"attrGrow\":\"1.8\",\"skillGrow\":\"1.8\",\"placeId\":\"49\",\"initialHp\":0,\"initialHpValue\":null}]]"

	-- test --
	local stageId = nil

	local battleConstructor = require('battleEntryServer.BattleConstructor').new()
	battleConstructor:InitCheckerData(
		stageId,
		constructorJson,
		friendTeamJson,
		enemyTeamJson
	)

	local battleManager = __Require('battle.manager.BattleManager_Checker').new({
		battleConstructor = battleConstructor
	})

	battleManager:EnterBattle()

	battleManager:InitClientBasedData(
		loadedResources,
		playerOperate
	)

	------------ 开始检查战斗 ------------
	local checkResult, fightData  = battleManager:StartCheckRecord()
	------------ 开始检查战斗 ------------

	print('here check fight result\n', checkResult, '\n', fightData, '\n')
	-- test --
end
--[[
获取debug的队伍信息
@return teamData
--]]
function BattleChecker:GetDebugTeamData()
	local teamJson = "[[{\"id\":\"444\",\"playerId\":\"100183\",\"cardId\":\"200080\",\"level\":\"85\",\"exp\":\"647936\",\"breakLevel\":\"5\",\"vigour\":\"100\",\"skill\":{\"10159\":{\"level\":29},\"10160\":{\"level\":29},\"90080\":{\"level\":29}},\"businessSkill\":[],\"favorability\":\"0\",\"favorabilityLevel\":\"1\",\"createTime\":\"2018-02-09 00:02:17\",\"cardName\":null,\"defaultSkinId\":\"250800\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"artifactTalent\":[],\"attack\":547,\"defence\":281,\"hp\":4209,\"critRate\":1892,\"critDamage\":1638,\"attackRate\":2446},{\"id\":\"438\",\"playerId\":\"100183\",\"cardId\":\"200076\",\"level\":\"85\",\"exp\":\"647936\",\"breakLevel\":\"5\",\"vigour\":\"100\",\"skill\":{\"10151\":{\"level\":29},\"10152\":{\"level\":29},\"90076\":{\"level\":29}},\"businessSkill\":[],\"favorability\":\"0\",\"favorabilityLevel\":\"1\",\"createTime\":\"2018-02-07 14:53:08\",\"cardName\":null,\"defaultSkinId\":\"250760\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"artifactTalent\":[],\"attack\":631,\"defence\":217,\"hp\":3185,\"critRate\":3424,\"critDamage\":2588,\"attackRate\":3899},{\"id\":\"435\",\"playerId\":\"100183\",\"cardId\":\"200072\",\"level\":\"85\",\"exp\":\"647936\",\"breakLevel\":\"5\",\"vigour\":\"100\",\"skill\":{\"10143\":{\"level\":1},\"10144\":{\"level\":1},\"90072\":{\"level\":1}},\"businessSkill\":[],\"favorability\":\"0\",\"favorabilityLevel\":\"1\",\"createTime\":\"2018-02-03 00:20:58\",\"cardName\":null,\"defaultSkinId\":\"250720\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"artifactTalent\":[],\"attack\":519,\"defence\":140,\"hp\":3768,\"critRate\":3234,\"critDamage\":4007,\"attackRate\":6159},{\"id\":\"437\",\"playerId\":\"100183\",\"cardId\":\"200044\",\"level\":\"65\",\"exp\":\"275778\",\"breakLevel\":\"5\",\"vigour\":\"100\",\"skill\":{\"10087\":{\"level\":22},\"10088\":{\"level\":22}},\"businessSkill\":[],\"favorability\":\"0\",\"favorabilityLevel\":\"1\",\"createTime\":\"2018-02-07 14:37:13\",\"cardName\":null,\"defaultSkinId\":\"250440\",\"marryTime\":null,\"isArtifactUnlock\":\"0\",\"artifactTalent\":[],\"attack\":286,\"defence\":67,\"hp\":2154,\"critRate\":4000,\"critDamage\":3594,\"attackRate\":3752}]]"
	return teamJson
end
--[[
获取debug的构造器数据
--]]
function BattleChecker:GetDebugConstructorData()
	return '{"canBuyCheat":false,"rechallengeTime":-1,"questBattleType":1,"randomConfig":{"randomseed":"4102750551"},"time":300,"friendPlayerSkill":{"activeSkill":[{"skillId":80025},{"skillId":80135}],"passiveSkill":[{"skillId":80001},{"skillId":80045},{"skillId":80050},{"skillId":80051},{"skillId":80092},{"skillId":80100},{"skillId":80102}]},"weather":["1"],"autoConnect":false,"canRechallenge":true,"enableConnect":true,"buyRevivalTimeMax":0,"openLevelRolling":true,"buyRevivalTime":0,"gameTimeScale":2,"phaseChangeDatas":{}}'
end
--[[
获取debug的资源信息
--]]
function BattleChecker:GetDebugLoadedResources()
	return json.decode('[{"hurt_2":true,"effect_300023":true,"effect_200080":true,"300026":true,"hurt_17":true,"boss_cutin_1":true,"effect_80002":true,"200072":true,"200044":true,"hurt_27":true,"boss_chant_progressBar":true,"boss_weak":true,"effect_300026":true,"300027":true,"200080":true,"200076":true,"boss_cutin_2":true,"hurt_9":true,"300028":true,"300023":true,"hurt_28":true,"hurt_3":true,"effect_80010":true,"effect_200076":true,"hurt_11":true,"boss_cutin_mask":true,"effect_200072":true}]')
end
--[[
获取debug的渲染层操作信息
--]]
function BattleChecker:GetDebugPlayerOperate()
	return json.decode('{"0":[{"maxParams":0,"managerName":"G_BattleLogicMgr","functionName":"RenderReadyStartNextWaveHandler","variableParams":{}}],"396":[{"maxParams":0,"managerName":"G_BattleLogicMgr","functionName":"RenderStartNextWaveHandler","variableParams":{}}],"229":[{"maxParams":1,"managerName":"G_BattleLogicMgr","functionName":"RenderSetTempTimeScaleHandler","variableParams":[1]}],"350":[{"maxParams":0,"managerName":"G_BattleLogicMgr","functionName":"RenderWaveTransitionOverHandler","variableParams":{}},{"maxParams":0,"managerName":"G_BattleLogicMgr","functionName":"RenderRecoverTempTimeScaleHandler","variableParams":{}}],"48":[{"maxParams":0,"managerName":"G_BattleLogicMgr","functionName":"RenderStartNextWaveHandler","variableParams":{}}],"289":[{"maxParams":0,"managerName":"G_BattleLogicMgr","functionName":"RenderWaveTransitionStartHandler","variableParams":{}}]}')
end
--[[
获取debug的敌方配置信息
@params stageId int 关卡id
--]]
function BattleChecker:GetDebugEnemyData(stageId)
	return  "[[{\"cardId\":\"300027\",\"campType\":null,\"level\":\"6\",\"attrGrow\":\"0.5\",\"skillGrow\":\"0.5\",\"placeId\":\"17\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"300027\",\"campType\":null,\"level\":\"6\",\"attrGrow\":\"0.5\",\"skillGrow\":\"0.5\",\"placeId\":\"45\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"300026\",\"campType\":null,\"level\":\"6\",\"attrGrow\":\"0.5\",\"skillGrow\":\"0.5\",\"placeId\":\"35\",\"initialHp\":0,\"initialHpValue\":null}],[{\"cardId\":\"300028\",\"campType\":null,\"level\":\"6\",\"attrGrow\":\"0.5\",\"skillGrow\":\"0.5\",\"placeId\":\"17\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"300028\",\"campType\":null,\"level\":\"6\",\"attrGrow\":\"0.5\",\"skillGrow\":\"0.5\",\"placeId\":\"45\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"300026\",\"campType\":null,\"level\":\"6\",\"attrGrow\":\"0.5\",\"skillGrow\":\"0.5\",\"placeId\":\"21\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"300026\",\"campType\":null,\"level\":\"6\",\"attrGrow\":\"0.5\",\"skillGrow\":\"0.5\",\"placeId\":\"49\",\"initialHp\":0,\"initialHpValue\":null},{\"cardId\":\"301005\",\"campType\":null,\"level\":\"6\",\"attrGrow\":\"0.5\",\"skillGrow\":\"0.5\",\"placeId\":\"39\",\"initialHp\":0,\"initialHpValue\":null}]]"
	-- local teamsData = {}

	-- local enemyConfig = CommonUtils.GetConfig('quest', 'enemy', stageId)
	-- local totalWave = table.nums(enemyConfig)
	-- for i = 1, totalWave do

	-- 	local waveConfig = enemyConfig[tostring(i)]
	-- 	local teamData = {}

	-- 	for _, cardData in ipairs(waveConfig.npc) do

	-- 		local t = {
	-- 			cardId = checkint(cardData.npcId),
	-- 			campType = checkint(cardData.campType),
	-- 			initialHp = checkint(cardData.initialHp),
	-- 			level = checkint(cardData.level),
	-- 			placeId = checkint(cardData.placeId),
	-- 			attrGrow = checknumber(cardData.attrGrow),
	-- 			skillGrow = checknumber(cardData.skillGrow),
	-- 			initialHpValue = nil
	-- 		}
	-- 		table.insert(teamData, t)

	-- 	end

	-- 	teamsData[i] = teamData

	-- end

	-- return json.encode(teamsData), nil
end
---------------------------------------------------
-- debug end --
---------------------------------------------------








return BattleChecker
