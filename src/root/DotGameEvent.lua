----@class DotGameEvent
local DotGameEvent = {}
DotGameEvent.GAME_UUIDS = {
	RETURN_FACTORY = "91e0d2c9b16f64021965cac4ed0b5804",
}
function DotGameEvent.CommonParams()
	local user_id, player_id , server  , player_level , open_id = 0, 0 , 0 , 0, 0
	local player_create_time = 0
	if AppFacade then
		---@type GameManager
		local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
		if gameMgr and gameMgr.userInfo then
			local userInfo = gameMgr.userInfo
			user_id = checkint(userInfo.userId)
			player_id = checkint(userInfo.playerId)
			server = checkint(userInfo.serverId)
			player_level = checkint(userInfo.level)
			open_id = checkint(userInfo.userSdkId)
			player_create_time = checkint(userInfo.roleCtime)
		end
	end
	local commonParam = FTUtils:getCommParamters({channelId = Platform.id ,appVersion=FTUtils:getAppVersion()}) or {}
	local platform = 4 -- 其他
	if device.platform == "ios" then
		platform = 1
	elseif device.platform == "android" then
		platform = 2
	end
	local t = {
		user_id            = tostring(user_id),                               -- 用户ID
		player_id          = tostring(player_id),                             -- 玩家ID
		open_id            = tostring(open_id),                               -- 平台用户ID
		server             = tostring(server ),                               -- 服
		udid               = tostring(commonParam.udid or ""),            -- 设备ID
		idfa               = tostring(commonParam.idfa or ""),            -- 广告idfa
		os_version         = tostring(commonParam.osVer or ""),           -- 系统版本
		app_version        = tostring(FTUtils:getAppVersion()),               -- 游戏大版本
		version            = tostring(DotGameEvent.getLocalVersion()),        -- 游戏小版本
		channel            = tostring(Platform.id),                -- 渠道
		merchant           = tostring(commonParam.merchant or ""),        -- 运营商
		player_create_time = tostring(player_create_time),                    -- 创角时间
		event_time         = tostring(os.time()),                             -- 事件时间
		network            = tostring(commonParam.networkType or '6'),    -- 网络情况
		game_uuid          = tostring("aaf4952dc81db95fe1b736c3ccbec50d"),-- 游戏uuid
		imei               = tostring(commonParam.imei or "") ,           -- imei
		player_level       = tostring(player_level),
		android_id         = tostring(commonParam.androidId or "") ,      -- androidId
		platform           = tostring(platform)
	}
	return t
end

function DotGameEvent.getLocalVersion()
	local fileUtils = cc.FileUtils:getInstance()
	local uroot = fileUtils:getWritablePath()
	local resinfoPath = table.concat({uroot , "res" ,"resinfo.md5"  } , "/")
	if fileUtils:isFileExist(resinfoPath) then
		local resInfoTxt = FTUtils:getFileDataWithoutDec(resinfoPath)
		local localResInfo = assert(loadstring(resInfoTxt))()
		return localResInfo.version
	end
	return FTUtils:getAppVersion()
end


--[[--
将 table转为urlencode的数据
@param t table
@see string.urlencode
]]
function DotGameEvent.tabletourlencode(t)
	local args = {}
	local i = 1
	local keys = table.keys(t)
	table.sort(keys)
	if next( keys ) ~= nil then
		for k, key in pairs( keys ) do
			args[i] = string.urlencode(key) .. '=' .. string.urlencode(t[key])
			i = i + 1
		end
	end
	return table.concat(args,'&')
end

DotGameEvent.generateSign = function ( t )
	for key, value in pairs(t) do
		-- 检测是否有boolean 类型
		if type(value) == "boolean" then
			t[key] =  t[key] and "1" or "0"
		end
	end
	local keys = table.keys(t)
	table.sort(keys)
	local retstring = "";
	local tempt = {}
	for _,v in ipairs(keys) do
		tempt[#tempt+1] = v .."=" ..  t[v]
	end
	if table.nums(tempt) > 0 then
		tempt[#tempt+1] =  '8e5367f42b66cd5e881f69738eeed4d2'
		retstring = table.concat(tempt,'&')
	end
	return CCCrypto:MD5Lua(retstring, false)
end


DotGameEvent.EVENTS = {
	LAUNCH_GAME   = {
		key ="LAUNCH_GAME",
		event_id = "1-001",
		event_content = "launch_game"
	},      --打开app
	INITIALIZE    = {
		key ="INITIALIZE",
		event_id = "1-002",
		event_content = "initialize"
	},      --游戏初始化完成
	REGISTER      = {
		key ="REGISTER",
		event_id = "1-003",
		event_content = "register"
	},         -- 注册账号
	IDENTIFY      = {
		key ="IDENTIFY",
		event_id = "1-004",
		event_content = "identify"
	},         -- 实名认证完成
	CREATE_ROLE   = {
		key ="CREATE_ROLE",
		event_id = "1-005",
		event_content = "create_role"
	},      --创角完成
	LOADING_START = {
		key ="LOADING_START",
		event_id = "1-006",
		event_content = "loading_start"
	},    --loading 开始
	LOADING_END   = {
		key ="LOADING_END",
		event_id = "1-007",
		event_content = "loading_end"
	},      --loading 结束进入游戏页面
	GUIDE_START   = {
		key ="GUIDE_START",
		event_id = "1-008",
		event_content = "guide_start"
	},      --开始新手引导
	GUIDE_END     = {
		key ="GUIDE_END",
		event_id = "1-009",
		event_content = "guide_end"
	}, --引导完成
	AD_CLOSE     = {
		key ="AD_CLOSE",
		event_id = "1-021",
		event_content = "ad_close"
	}, --广告图关闭
	FISRT_LOADING = {
		key ="FISRT_LOADING",
		event_id = "1-022",
		event_content = "first_loading"
	}, --载入游戏
	FINISH_LOADING = {
		key ="FINISH_LOADING",
		event_id = "1-023",
		event_content = "finish_loading"
	}, --载入完成跳出登录界面
	CLICK_REGISTER = {
		key ="CLICK_REGISTER",
		event_id = "1-023",
		event_content = "click_register"
	}, --点击一键注册

	--- 返场狂欢活动埋点 -----
	RETURN_HOME_PAGE = {
		key = "RETURN_HOME_PAGE" ,
		event_id = "2_001" ,
		event_content = "home_page",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_ACTIVITY = {
		key = "RETURN_ACTIVITY" ,
		event_id = "2_002" ,
		event_content = "activity",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_BANNER = {
		key = "RETURN_BANNER" ,
		event_id = "2_003" ,
		event_content = "banner",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_DIALY_ACTIVE = {
		key = "RETURN_DIALY_ACTIVE" ,
		event_id = "2_100" ,
		event_content = "dialy_active",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_LOTTERY = {
		key = "RETURN_LOTTERY" ,
		event_id = "2_200" ,
		event_content = "lottery",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_CHANGE = {
		key = "RETURN_CHANGE" ,
		event_id = "2_300" ,
		event_content = "change",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_MALL = {
		key = "RETURN_MALL" ,
		event_id = "2_400" ,
		event_content = "mall",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_LOTTERY_ONE = {
		key = "RETURN_LOTTERY_ONE" ,
		event_id = "2_201" ,
		event_content = "lottery",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_LOTTERY_TEN = {
		key = "RETURN_LOTTERY_TEN" ,
		event_id = "2_202" ,
		event_content = "lottery",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_LOTTERY_LUXURY = {
		key = "RETURN_LOTTERY_LUXURY" ,
		event_id = "2_203" ,
		event_content = "lottery",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_DIAMOND_PAY_0= {
		key = "RETURN_DIAMOND_PAY_0" ,
		event_id = "2_dia_0" ,
		event_content = "diamond_pay",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	},
	RETURN_DIAMOND_PAY_1 = {
		key = "RETURN_DIAMOND_PAY_1" ,
		event_id = "2_dia_1" ,
		event_content = "diamond_pay",
		game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY
	}
}


--[[
--是否是国内
--]]
function DotGameEvent.isQuickSdk()
	local platformId = checkint(Platform.id)
	local isQuick = false
	if (platformId < 888 and platformId ~= YSSDKChannel) or platformId == QuickVirtualChannel then
		isQuick = true
	end
	return isQuick
end

--[[
--是否是国内
--]]
function DotGameEvent.isChinaSdk()
	local platformId = checkint(Platform.id)
	local isChina = true
	if platformId >=  4001 and platformId <= 4999 then
		isChina = false
	end
	return isChina
end
function DotGameEvent.GetParams(eventName)
	if DotGameEvent.isChinaSdk() and (not DotGameEvent.isQuickSdk()) then
		local eventKeyDefine = DotGameEvent.EVENTS
		eventKeyDefine = DotGameEvent.EVENTS[eventName]
		dump(eventKeyDefine)
		if eventKeyDefine then
			DotGameEvent.Log(eventKeyDefine)
		end
	end

end

function DotGameEvent.Log(parameters)
	local params = DotGameEvent.CommonParams()
	if parameters then
		table.merge(params, clone(parameters))
		params.key = nil
	end
	local sign = DotGameEvent.generateSign(params)
	params.sign = sign
	local ret = json.encode(params)
	local url = 'http://new-data-event.dddwan.com/event'
	local xhr = cc.XMLHttpRequest:new()
	xhr.timeout = 30
	xhr:open("POST", url)
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xhr:setRequestHeader('Content-Type', 'application/json')
	xhr:send(ret)
end
---@param eventName table or string
function DotGameEvent.SendEvent(eventName)
	if DotGameEvent.isChinaSdk() and (not DotGameEvent.isQuickSdk()) then
		if type(eventName) == "table" and  eventName.key then
			DotGameEvent.GetParams(eventName.key)
			return
		end
		if type(eventName) == "string" then
			DotGameEvent.GetParams(eventName)
		end
	end
end

function DotGameEvent.DynamicSendEvent(data)
	if DotGameEvent.isChinaSdk() and (not DotGameEvent.isQuickSdk()) then
		DotGameEvent.Log(data)
	end
end
function DotGameEvent.SDKButtonEvent(data)
	-- sdk的点击事件收集  eventKeyValues key 为sdk点击事件名 value 为收集上传事件值
	local eventKeyValues = {
		xp_tv_login_onekey_register = DotGameEvent.EVENTS.CLICK_REGISTER,
	}
	local eventName = data.event_name
	local eventGameValue = eventKeyValues[eventName]
	if eventGameValue then
		DotGameEvent.SendEvent(eventGameValue)
	end
end
return DotGameEvent
