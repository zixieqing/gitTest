---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2020/6/30 6:04 PM
---
--- 换皮工作会涉及到 3各方面
---1. po 文档修改
---2. spine 对应的修改
---3. pos 的位置修改
local podTable = {
	po = {
		[__("更换")] = __("更换"),
		[__("一周年回顾")] = __("一周年回顾"),
		[__("黑市商人")] = __("黑市商人"),
		[__("主线关卡已经结束")] = __("主线关卡已经结束"),
		[__("支线剧情奖励:")] = __("支线剧情奖励:"),
		[__("当前的庆典积分")] = __("当前的物语烛火"),
		[__("难度%d")] = __("难度%d"),
		[__("设置售卖员")] = __("设置售卖员"),
		[__("本轮已选择的支线类型不会出现。")] = __("本轮已选择的支线类型不会出现。"),
		[__("达到")] = __("达到"),
		[__("每日摊位排名")] = __("每日摊位排名"),
		[__("销售成功率")] = __("销售成功率"),
		[__("快速挑战仅能挑战已通过的最高难度关卡，仅会获得通关收益")] = __("快速挑战仅能挑战已通过的最高难度关卡，仅会获得通关收益"),
		[__("全部支线关卡难度20通关可解锁快速游玩，快速游玩仅能获得难度20时关卡的通关奖励。")] = __("全部支线关卡难度20通关可解锁快速游玩，快速夜游仅能获得难度20时关卡的通关奖励。"),
		[__("替换")] = __("替换"),
		[__("雇佣")] = __("雇佣"),
		[__("保存设置")] = __("保存设置"),
		[__("当前排名")] = __("当前排名"),
		[__("摊位总排名")] = __("摊位总排名"),
		[__("主线故事")] = __("主线故事"),
		[__("已超过售价上限")] = __("已超过售价上限"),
		[__("输入数字1 - 999")] = __("输入数字1 - 999"),
		[__("描述：")] = __("描述："),
		[__("奖励已领取")] = __("奖励已领取"),
		[__("困难_num_")] = __("困难_num_"),
		[__("关卡暂未解锁")] = __("关卡暂未解锁"),
		[__("排行榜")] = __("排行榜"),
		[__("庆典积分排行奖励")] = __("物语烛火排行奖励"),
		[__("诞生年代：")] = __("诞生年代："),
		[__("%d小时后解锁")] = __("%d小时后解锁"),
		[__("排名奖励")] = __("排名奖励"),
		[__("正在游戏中")] = __("正在游戏中"),
		[__("每日摊位排行奖励")] = __("每日摊位排行奖励"),
		[__("主线关卡已经通关")] = __("主线关卡已经通关"),
		[__("奖励一览")] = __("奖励一览"),
		[__("是否保存数据？")] = __("是否保存数据？"),
		[__("只能选择一种购买")] = __("只能选择一种购买"),
		[__("消耗%d")] = __("消耗%d"),
		[__("庆典")] = __("绯樱百物语"),
		[__("总排行榜")] = __("总排行榜"),
		[__("回看")] = __("回看"),
		[__("添加食物")] = __("添加食物"),
		[__("庆典排行榜")] = __("游说排行榜"),
		[__("行动")] = __("行动"),
		[__("熟练度 + %d ")] = __("熟练度 + %d "),
		[__("请点击你的目的地")] = __("请点击你的目的地"),
		[__("环游飞艇")] = __("环游马车"),
		[__("已通关")] = __("已通关"),
		[__("是否消耗%d个%s重新抽？")] = __("是否消耗%d个%s重新抽？"),
		[__("稀有")] = __("稀有"),
		[__("售卖记录每小时更新一次")] = __("售卖记录每小时更新一次"),
		[__("请选择前往的目的地")] = __("请选择前往的目的地"),
		[__("请先通关当前关卡")] = __("请先通关当前关卡"),
		[__("公布线索%d")] = __("公布线索%d"),
		[__("前进")] = __("前进"),
		[__("取消")] = __("取消"),
		[__("未达到领取条件")] = __("未达到领取条件"),
		[__("收集奖励")] = __("收集奖励"),
		[__("奖励预览")] = __("奖励预览"),
		[__("未入榜")] = __("未入榜"),
		[__("售价:")] = __("售价:"),
		[__("食谱商店")] = __("食谱商店"),
		[__("描述")] = __("描述"),
		[__("翻开一张牌，决定游玩的区域")] = __("翻开一张牌，决定夜游的区域"),
		[__("剩余数量：%d")] = __("剩余数量：%d"),
		[__("排名规则")] = __("排名规则"),
		[__("今日推荐料理")] = __("今日推荐料理"),
		[__("营业时间：%s:%s~%s:%s")] = __("营业时间：%s:%s~%s:%s"),
		[__("%s不足")] = __("%s不足"),
		[__("昨日排行榜")] = __("昨日排行榜"),
		[__("格瑞洛舞台区")] = __("格瑞洛舞台区"),
		[__("今日推荐")] = __("今日推荐"),
		[__("请不要忘记添加料理哦")] = __("请不要忘记添加料理哦"),
		[__("昨日摊位排行奖励")] = __("昨日摊位排行奖励"),
		[__("庆典积分榜")] = __("物语烛火榜"),
		[__("后退")] = __("后退"),
		[__("编辑队伍")] = __("编辑队伍"),
		[__("普通")] = __("普通"),
		[__("当前还有支线关卡未通关难度20")] = __("当前还有支线关卡未通关难度20"),
		[__("当前已通过的最高难度:")] = __("当前已通过的最高难度:"),
		[__("通关难度1后可以使用")] = __("通关难度1后可以使用"),
		[__("庆典积分")] = __("物语烛火"),
		[__("挑战_num_次")] = __("挑战_num_次"),
		[__("请先通关全部支线难度关卡")] = __("请先通关全部支线难度关卡"),
		[__("摊位排行榜")] = __("摊位排行榜"),
		[__("剧情解锁奖励")] = __("剧情解锁奖励"),
		[__("概率")] = __("概率"),
		[__("快速挑战")] = __("快速挑战"),
		[__("今日庆典代币")] = __("今日绯樱币"),
		[__("上架")] = __("上架"),
		[__("向前")] = __("向前"),
		[__("剧情目录")] = __("剧情目录"),
		[__("购买")] = __("购买"),
		[__("道具不足")] = __("道具不足"),
		[__("熟练度： %d+%d")] = __("熟练度： %d+%d"),
		[__("确定")] = __("确定"),
		[__("熟练度：%d + %d")] = __("熟练度：%d + %d"),
		[__("庆典积分奖励")] = __("物语烛火奖励"),
		[__("累计套圈奖励")] = __("累计小妖恶戏奖励"),
		[__("点击领取")] = __("点击领取"),
		[__("换一个")] = __("换一个"),
		[__("已购买过商品 请继续游戏")] = __("已购买过商品 请继续游戏"),
		[__("套1次")] = __("套1次"),
		[__("套9次")] = __("套9次"),
		[__("要消耗%d%s购买商品么")] = __("要消耗%d%s购买商品么"),
		[__("神秘套圈")] = __("小妖恶戏"),
		[__("游玩庆典")] = __("夜行游说"),
		[__("经营时间已经结束")] = __("经营时间已经结束"),
		[__("剧情")] = __("剧情"),
		[__("关卡进行中")] = __("关卡进行中"),
		[__("摊位")] = __("摊位"),
		[__("持有")] = __("持有"),
		[__("神秘套圈时间已经结束")] = __("小妖恶戏时间已经结束"),
		[__("游玩")] = __("夜游"),
		[__("经营总排行奖励")] = __("经营总排行奖励"),
		[__("已领取")] = __("已领取"),
		[__("售菜成功率：")] = __("售菜成功率："),
		[__("跳过")] = __("跳过"),
		[__("日期")] = __("日期"),
		[__("更改难度")] = __("更改难度"),
		[__("前 往")] = __("前 往"),
		[__("_name_ 不足")] = __("_name_ 不足"),
		[__("销售数量")] = __("销售数量"),
		[__("当前阶段：%s")] = __("当前阶段：%s"),
		[__("未能及时做好今日营业准备，本摊位暂停售卖。")] = __("未能及时做好今日营业准备，本摊位暂停售卖。"),
		[__("庆典积分排名")] = __("物语烛火排名"),
		[__("请添加飨灵")] = __("请添加飨灵"),
		[__("源地：")] = __("源地："),
		[__("领取奖励")] = __("领取奖励"),
		[__("售卖食物")] = __("售卖食物"),
		[__("单价")] = __("单价"),
		[__("进行中")] = __("进行中"),
		[__("通关后获得超丰富奖励")] = __("通关后获得超丰富奖励"),
		[__("完成主线剧情可以获得:")] = __("完成主线剧情可以获得:"),
		[__("距离开市:")] = __("距离开市:"),
		[__("卡牌详情")] = __("卡牌详情"),
		[__("类型：")] = __("类型："),
		[__("放弃")] = __("放弃"),
		[__("_name_不足")] = __("_name_不足"),
		[__("向后")] = __("向后"),
		[__("点击领取奖励")] = __("点击领取奖励"),
		[__("难度")] = __("难度"),
		[__("过关奖励")] = __("过关奖励"),
		[__("超出当前关卡可选难度范围")] = __("超出当前关卡可选难度范围"),
		[__("确定要放弃该章节么？")] = __("确定要放弃该章节么？"),
		[__("售卖记录")] = __("售卖记录"),
		[__("已经没有新的支线类型了")] = __("已经没有新的支线类型了"),
		[__("添加料理")] = __("添加料理"),
		[__("外观：")] = __("外观："),
		[__("领取收益")] = __("领取收益"),
		[__("超级快速")] = __("超级快速"),
		[__("可获得: ")] = __("可获得: "),
		[__("主线关卡正在进行中")] = __("主线关卡正在进行中"),
		[__("商品已经售罄")] = __("商品已经售罄"),
		[__("售卖价格不能为0")] = __("售卖价格不能为0"),
		[__("支线关卡已经结束")] = __("支线关卡已经结束"),
		[__("当前")] = __("当前"),
		[__("主线")] = __("主线"),
		[__("庆典代币")] = __("绯樱币"),
		[__("确定放弃购买商店物品么？")] = __("确定放弃购买商店物品么？"),
		[__("消耗_num_")] = __("消耗_num_"),
		[__("今日排行榜")] = __("今日排行榜"),
		[__("请输入价格:")] = __("请输入价格:"),
	},
	spine = {
		ANNI_FEICHUAN       = 'effects/anniversary/anni_feichuan',
		ANNI_MAIN_BOX       = 'effects/anniversary/anni_main_box',
		ANNI_MAIN_CARD      = 'effects/anniversary/anni_main_card',
		ANNI_MAIN_CHANGE    = 'effects/anniversary/anni_main_change',
		ANNI_MAIN_OPEN      = 'effects/anniversary/anni_main_open',
		ANNI_MAIN_WALKING   = 'effects/anniversary/anni_main_walking',
		ANNI_MAPS_ICON_DICE = 'effects/anniversary/anni_maps_icon_dice',
		ANNI_CATIN_BG       = 'effects/anniversary/anni_catin_bg',
		ANNI_CATIN_ZHUAN    = 'effects/anniversary/anni_catin_zhuan',
		ANNI_MAIN_UP_TOP    = 'effects/anniversary/anni_main_up_top',
		ANNI_MAIN_UP_BOTTOM = 'effects/anniversary/anni_main_up_bottom',
		FFALL               = 'effects/anniversary/Ffall',
	},
	pos = {
	},
	dialogIndex = "3",
	entryViewData = {
		cardId = "200208",
		isNpc = false ,
		mainBgImage = "arts/stage/bg/main_bg_163.jpg",
		npcPos = cc.p(display.width - 200, display.cy - 150)
	},
	capsuleDrawNode = "200208" ,
	branchDrawNode = "200261",
	dayAndNight = false ,
	isAddSpotSpine = false ,
}
return podTable