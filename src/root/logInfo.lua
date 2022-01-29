logInfo = {}

logInfo.dataCache = {}
logInfo.pingCache = {}

-- 最大信息条数
logInfo.LINE_MAX = 100000

-- 自动换行的字数
logInfo.WRAP_CHARS = 98

-- 事件：日志更新
logInfo.EVENT_LOG_UPDATE = 'logInfo.EVENT_LOG_UPDATE'
logInfo.PING_SEND_UPDATE = 'logInfo.PING_SEND_UPDATE'
logInfo.PING_TAKE_UPDATE = 'logInfo.PING_TAKE_UPDATE'

-- 信息类型
logInfo.Types = {
    ERROR   = 1, -- 错误日志
    HTTP    = 2, -- 短链接
    GAME    = 3, -- 通用长链接
    CHAT    = 4, -- 聊天长链接
    TEAM    = 5, -- 副本长链接
    DEBUG   = 8, -- 调试日志
    TIMEOUT = 9, -- 短链超时（临时）
}

local socket = require('socket')


-- 添加日志信息
-- @param logType 信息类型
-- @param logStr 信息内容
--
logInfo.add = function(logType, logStr)
    logType    = checkint(logType)
    logStr     = checkstr(logStr)
	-- isAutoWrap = isAutoWrap ~= false
	if logType == 1 or logType == 2 or logType == 3 or logType == 5 then
        -- add log time
        local ostime  = socket.gettime()
        local mstime  = string.format('%0.3f', (ostime - math.floor(ostime)))
        local timeStr = string.format('[%s.%s] ', os.date('%m-%d %X'), string.sub(mstime, 3))
        logStr = timeStr .. logStr
        wwritefile(logStr .. '\n')
    end
	if checkint(DEBUG) == 0 and (logType ~= logInfo.Types.ERROR and logType ~= logInfo.Types.TIMEOUT) then return end


    logInfo.dataCache[logType] = logInfo.dataCache[logType] or {}
	local logInfoData = logInfo.dataCache[logType]
	
    -- append log info
	local logInfoLen = #logInfoData
    local logStrList = string.split(tostring(logStr), '\n')
    for i,v in ipairs(logStrList) do
        -- if isAutoWrap then
        --     local lines = math.ceil(utf8len(v) / logInfo.WRAP_CHARS)
        --     for i=1,lines do
        --         local str = utf8sub(v, (i-1)*logInfo.WRAP_CHARS, logInfo.WRAP_CHARS)
        --         table.insert(logInfoData, str)
        --     end
        -- else
			logInfoData[logInfoLen + i] = v
        -- end
    end

    -- clean out range
	local excessSize = #logInfoData - logInfo.LINE_MAX
	if excessSize > 0 then
		for index = 1, logInfo.LINE_MAX do
			logInfoData[index] = logInfoData[excessSize + index]
		end
		for index = logInfo.LINE_MAX + 1, #logInfoData do
			logInfoData[index] = nil
		end
	end

    -- dispatch event
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    local customEvent     = cc.EventCustom:new(logInfo.EVENT_LOG_UPDATE)
    customEvent.data      = {logType = logType}
	eventDispatcher:dispatchEvent(customEvent)
end


logInfo.ping = function(logType, pingModel)
	if checkint(DEBUG) == 0 then return end

	logType = checkint(logType)

	-- add log time
    local ostime  = socket.gettime()
    local mstime  = string.format('%0.3f', (ostime - math.floor(ostime)))
    local timeStr = string.format('[%s.%s] ', os.date('%m-%d %X'), string.sub(mstime, 3))

    logInfo.pingCache[logType] = logInfo.pingCache[logType] or {}
	local logInfoData = logInfo.pingCache[logType]
	local customEvent = nil

	-- 1 : send
	if pingModel == 1 then
		logInfoData.pingSendTimeStr = timeStr
		logInfoData.pingStacksCount = checkint(logInfoData.pingStacksCount) + 1
		customEvent = cc.EventCustom:new(logInfo.PING_SEND_UPDATE)
		
	-- 2 : take
	elseif pingModel == 2 then
		logInfoData.pingTakeTimeStr = timeStr
		logInfoData.pingStacksCount = 0
		customEvent = cc.EventCustom:new(logInfo.PING_TAKE_UPDATE)
	end

	if customEvent then
		customEvent.data = {logType = logType}
		cc.Director:getInstance():getEventDispatcher():dispatchEvent(customEvent)
	end
end


logInfo.cmdNameMap = {
    -------------------------------------------------
    -- socket base
    [1000] = '空命令',
    [1100] = '发生错误',
    [1002] = '断开连接',
    [1004] = '连通验证',
    [1005] = '玩家登陆',
    [1001] = '同步信息',
    [1999] = '心跳检测',
    [9999] = '远程调试',
	-------------------------------------------------
	-- game info
	[2001] = '日常任务通知',
	[2002] = '主线任务通知',
	[2003] = '满星奖励通知',
	[2004] = '新的奖励通知',
	[2006] = '好友私信通知',
	[2007] = '好友请求通知',
	[2008] = '帐号下线通知',
	[2009] = '剧情任务解锁',
	[2010] = '剧情任务完成',
	[2011] = '支线任务解锁',
	[2012] = '支线任务完成',
	[2013] = '市场道具已售',
	[2014] = '餐厅任务进度',
	[2015] = '餐厅新鲜耗尽',
	[2016] = '餐厅特殊客人',
    [2019] = '充值成功',
    [2020] = '餐厅出售完菜',
    [2021] = '新手任务进度',
    [2022] = '餐厅虫子出现',
    [2023] = '餐厅虫子求助',
    [2024] = '餐厅虫子清除',
    [2025] = '餐厅霸王餐求助',
    [2026] = '餐厅霸王餐战斗',
    [2027] = '餐厅霸王餐结算',
    [2028] = '困难本满星奖励',
	[2029] = '限时礼包刷线',
	[2030] = '个人留言板',
	[2031] = '好友请求捐助',
	[2032] = '好友发送捐助',
	[2033] = '全服活动任务',
	[2034] = '全服游戏公告',
	[2998] = '踢人操作号令',
	-------------------------------------------------
	-- game chat
	[5001] = '聊天功能进入',
	[5002] = '聊天发送消息',
	[5003] = '聊天收到消息',
	[5004] = '聊天功能退出',
	[5006] = '聊天发送私信',
	[5007] = '聊天收到私信',
	[5008] = '聊天确认私信',
	[5009] = '聊天系统消息',
	[5010] = '聊天世界人数',
	[5011] = '聊天注册数据',
	-------------------------------------------------
	-- team boss
	[4001] = '副本组队参与',
	[4002] = '副本成员变动',
	[4003] = '副本卡牌变更',
	[4004] = '副本卡牌通知',
	[4005] = '副本主角技变更',
	[4006] = '副本主角技通知',
	[4007] = '副本准备变更',
	[4008] = '副本准备通知',
	[4009] = '副本进入战斗',
	[4010] = '副本进入通知',
	[4011] = '副本踢出成员',
	[4012] = '副本踢人通知',
	[4022] = '副本BOSS变更',
	[4023] = '副本BOSS通知',
	[4024] = '副本退出组队',
	[4025] = '副本退出通知',
	[4026] = '副本队长变更',
	[4027] = '副本队长通知',
	[4031] = '副本密码变更',
	[4032] = '副本密码通知',
	[4033] = '副本次数购买',
	[4034] = '副本次数通知',
    [4013] = '上传帧数据',
    [4014] = '下发帧数据',
    -------------------------------------------------
    -- restuarant
    [6001] = '餐厅客人到达',
    [6002] = '餐厅客人离开',
    [6003] = '餐厅界面关闭',
    [6004] = '餐厅添加道具',
    [6005] = '餐厅撤下道具',
    [6006] = '餐厅移动道具',
    [6007] = '餐厅招待客人',
    [6008] = '餐厅桌子信息',
    [6009] = '餐厅服务员更换',
    [6010] = '餐厅服务员解锁',
    [6011] = '餐厅消息上传',
    [6012] = '餐厅清空布局',
    -------------------------------------------------
    -- union
    [7001] = '申请工会结果',
	[7002] = '工会加入房间',
	[7003] = '工会房间人数',
	[7004] = '工会入会申请',
	[7005] = '工会踢人通知',
	[7006] = '工会职位变更',
	[7007] = '工会退出房间',
	[7008] = '工会任务完成',
	[7009] = '工会角色移动发送',
	[7010] = '工会角色移动接收',
	[7012] = '工会堕神等级改变',
	[7013] = '工会大厅形象改变',
	[7014] = '工会派对堕神结果',
	[7015] = '工会派对ROLL结果',
	[7016] = '工会进出大厅',
	[7017] = '工会战 报名成功通知',
	[7018] = '工会战 进攻敌方 开始',
	[7019] = '工会战 被敌方攻击 开始',
	[7020] = '工会战 进攻敌方 结束',
	[7021] = '工会战 被敌方进攻 结束',
	[7022] = '工会弹劾 当前投票人数',
	[7023] = '工会弹劾 会长上线',
	-------------------------------------------------
	-- tag match
	[8001] = '天城演武玩家排名变化',
	[8002] = '天城演武防守生命值变化',
	-------------------------------------------------
	-- ttGame
	[10999] = '打牌 网络握手',
	[10021] = '打牌 网络同步',
	[10008] = '打牌 对手匹配通知',
	[10014] = '打牌 出牌操作',
	[10015] = '打牌 出牌通知',
	[10016] = '打牌 结果通知',
	[10017] = '打牌 主动认输',
	[10001] = '打牌 pve进入',
	[10007] = '打牌 pvp匹配',
	[10002] = '打牌 房间创建',
	[10003] = '打牌 房间进入',
	[10004] = '打牌 房间进入通知',
	[10005] = '打牌 房间准备',
	[10006] = '打牌 房间准备通知',
	[10009] = '打牌 房间发送心情',
	[10010] = '打牌 房间心情通知',
	[10019] = '打牌 房间离开',
	[10020] = '打牌 房间离开通知',
	-------------------------------------------------
	-- house
	[2053]  = '猫屋 任务进度通知',
	[11001] = '猫屋 添置avatar',
	[11002] = '猫屋 撤下avatar',
	[11003] = '猫屋 移动avatar',
	[11004] = '猫屋 清空avatar',
	[11007] = '猫屋 变更avatar',
	[11005] = '猫屋 访客列表',
	[11006] = '猫屋 访客来访',
	[11008] = '猫屋 访客离开',
	[11011] = '猫屋 访客改头像',
	[11012] = '猫屋 访客改气泡',
	[11010] = '猫屋 访客移动',
	[11013] = '猫屋 访客改身份',
	[11014] = '猫屋 邀请通知',
	[11009] = '猫屋 自己移动',
	[11015] = '猫屋 猫咪状态通知',
	[11016] = '猫屋 好友接受生育邀请',
	[11017] = '猫屋 猫咪好感度变化',
}


logInfo.redMap = {
	["901"]       = "卡牌",
	["902"]       = "抽卡",
	["903"]       = "堕神",
	["904"]       = "商城",
	["905"]       = "邮件",
	["906"]       = "任务",
	["907"]       = "图鉴",
	["908"]       = "设置",
	["909"]       = "地图 冒险",
	["910"]       = "经营",
	["911"]       = "编队",
	["912"]       = "背包",
	["913"]       = "公告 暂时",
	["914"]       = "冰场",
	["915"]       = "天赋",
	["916"]       = "定单",
	["917"]       = "剧情",
	["918"]       = "好友",
	["919"]       = "世界地图",
	["920"]       = "主线剧情",
	["921"]       = "支线剧情",
	["922"]       = "打劫按钮的刷新",
	["923"]       = "市场",
	["925"]       = "打劫历史",
	["926"]       = "组队副本入口",
	["927"]       = "研究",
	["928"]       = "车库",
	["929"]       = "满星奖励",
	["930"]       = "探索",
	["931"]       = "菜谱研发",
	["932"]       = "排行榜",
	["934"]       = "爬塔",
	["935"]       = "新手七天任务",
	["936"]       = "飞艇",
	["937"]       = "模块列表",
	["938"]       = "离线竞技场",
	["939"]       = "活动",
	["940"]       = "主线任务",
	["941"]       = "工会",
	["942"]       = "组队",
	['3001']      = "工会信息",
	['3002']      = "工会任务",
	['3003']      = "工会神兽",
	['3004']      = "工会建设",
	['3005']      = "工会活动",
	['3006']      = "工会战斗",
	['3007']      = "工会商店",
	['3008']      = "工会狩猎",
	["100001"]    = "外卖计时器的功能逻辑",
	["1000"]      = "外卖下次刷新的时间的逻辑",
	["1100"]      = "餐厅任务",
	["1101"]      = "备菜",
	["1102"]      = "备菜",
	["1103"]      = "备菜",
	["1104"]      = "困难本",
	["1105"]      = "餐厅小费商城",
	["1106"]      = "餐厅好友",
	["1107"]      = "公有订单",
	["1108"]      = "餐厅活动",
	["1109"]      = "餐厅活动 预览",
	["1110"]      = "餐厅代理店长",
	["11001"]     = "餐厅装修的tag值",
	["11002"]     = "餐厅装修的tag值",
	["11003"]     = "卡牌升级按钮",
	["11004"]     = "卡牌升星按钮",
	["11005"]     = "等级礼包按钮",
	["100000"]    = "绑定手机号的倒计时",
	["100000001"] = "限时礼包的识别ID",
	["100000002"] = "个人信息查看",
	["2000001"]   = "餐盘的地方显示小红点",
	["20001"]     = "好友请求红点",
}


logs = function(...)
	local resultArray = {}
	for index, value in ipairs({...}) do
		resultArray[index] = tostring(value)
	end
	logInfo.add(logInfo.Types.DEBUG, table.concat(resultArray, ', '))
	if checkint(DEBUG) > 0 then print(...) end
end

logt = function(table, desciption, nesting)
	logInfo.add(logInfo.Types.DEBUG, tableToString(table, desciption, nesting))
	if checkint(DEBUG) > 0 then dump(table, desciption, nesting) end
end


-- develop use
logInfo.reloadFiles = {
	'root.logInfo',
	'Frame.Manager.DataManager',
}
