----@class DotEventLog
local DotEventLog = {}
function DotEventLog.CommonParams()
	local userId, playerId = 0, 0
	if AppFacade then
		local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
		if gameMgr and gameMgr.userInfo then
			userId = checkint(gameMgr.userInfo.userId)
			playerId = checkint(gameMgr.userInfo.playerId)
		end
	end
	local t = {
		udid = CCNative:getOpenUDID(),
		event_time = os.time(),
		game_id = CommonUtils.GetGameId(),
		channel = FTUtils:getChannelId(),
		server = app.gameMgr:GetUserInfo().serverId ,
		player_id = app.gameMgr:GetUserInfo().playerId,
	}
	return t
end
--[[--
将 table转为urlencode的数据
@param t table
@see string.urlencode
]]
function DotEventLog.tabletourlencode(t)
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

DotEventLog.generateSign = function ( t )
	-- body
	local saltkey = function (  )
		-- body
		return '2c494560e450dcc9fe1415b220a6f706'
		--return '864e6d965332c8c90750a397e7ef4c31'
	end
	local keys = table.keys(t)
	table.sort(keys)
	local retstring = "";
	local tempt = {}
	for _,v in ipairs(keys) do
		tempt[#tempt+1] = v .."=" ..  t[v]
		--table.insert(tempt,t[v])
	end

	if table.nums(tempt) > 0 then
		tempt[#tempt+1] =  saltkey()
		retstring = table.concat(tempt,'&')
	end
	return CCCrypto:MD5Lua(retstring, false)
end


DotEventLog.EVENTS = {

	-- 邪神遗迹
	["31"] = {
		["01"] = {
			event_id = "31-01",
			event_content = "邪神遗迹" ,
		} ,
		["02"] = {
			event_id = "31-02",
			event_content = "邪神遗迹" ,
		}
	},
	-- 空运
	["41"] = {
		["01"] = {
			event_id = "41-01",
			event_content = "空运" ,
		} ,
		["02"] = {
			event_id = "41-02",
			event_content = "空运" ,
		}
	},
	-- 皇家对决
	["42"] = {
		["01"] = {
			event_id = "42-01",
			event_content = "皇家对决" ,
		} ,
		["02"] = {
			event_id = "42-02",
			event_content = "皇家对决" ,
		}
	},
	-- 订单
	["45"] = {
		["01"] = {
			event_id = "45-01",
			event_content = "订单" ,
		} ,
		["02"] = {
			event_id = "45-02",
			event_content = "订单" ,
		}
	},
	-- 协力作战
	["46"] = {
		M1 = {  -- 暴食
			["01"] = {
				event_id = "46-M1-01",
				event_content = "协力作战——暴食" ,
			} ,
			["02"] = {
				event_id = "46-M1-02",
				event_content = "协力作战——暴食" ,
			}
		},
		M2 = {  -- 暴饮
			["01"] = {
				event_id = "46-M2-01",
				event_content = "协力作战——暴饮" ,
			} ,
			["02"] = {
				event_id = "46-M2-02",
				event_content = "" ,
			}
		},
		M3 = {  -- 土蜘蛛
			["01"] = {
				event_id = "46-M3-01",
				event_content = "协力作战——土蜘蛛" ,
			} ,
			["02"] = {
				event_id = "46-M3-02",
				event_content = "协力作战——土蜘蛛" ,
			}
		},
		M4 = {  -- 雷鸟
			["01"] = {
				event_id = "46-M4-01",
				event_content = "协力作战——雷鸟" ,
			} ,
			["02"] = {
				event_id = "46-M4-02",
				event_content = "协力作战——雷鸟" ,
			}
		},
		M5 = {  -- 叶海皇
			["01"] = {
				event_id = "46-M5-01",
				event_content = "协力作战——叶海皇" ,
			} ,
			["02"] = {
				event_id = "46-M5-02",
				event_content = "协力作战——叶海皇" ,
			}
		},
		M6 = {  -- 暴食强化
			["01"] = {
				event_id = "46-M6-01",
				event_content = "协力作战——暴食强化" ,
			} ,
			["02"] = {
				event_id = "46-M6-02",
				event_content = "协力作战——暴食强化" ,
			}
		},
		M7 = {  -- 犬神
			["01"] = {
				event_id = "46-M7-01",
				event_content = "协力作战——犬神" ,
			} ,
			["02"] = {
				event_id = "46-M7-02",
				event_content = "协力作战——犬神" ,
			}
		},
		M8 = {  -- 犬神
			["01"] = {
				event_id = "46-M8-01",
				event_content = "协力作战——断刀" ,
			} ,
			["02"] = {
				event_id = "46-M8-02",
				event_content = "协力作战——断刀" ,
			}
		},
		M9 = {  -- 犬神
			["01"] = {
				event_id = "46-M9-01",
				event_content = "协力作战——幽骸" ,
			} ,
			["02"] = {
				event_id = "46-M9-02",
				event_content = "协力作战——幽骸" ,
			}
		},
		M10 = {  -- 追击蛇君
			["01"] = {
				event_id = "46-M10-01",
				event_content = "协力作战——蛇君" ,
			} ,
			["02"] = {
				event_id = "46-M10-02",
				event_content = "协力作战——蛇君" ,
			}
		},
		M11 = {  -- 疯狂小丑
			["01"] = {
				event_id = "46-M11-01",
				event_content = "协力作战——疯狂小丑" ,
			} ,
			["02"] = {
				event_id = "46-M11-02",
				event_content = "协力作战——疯狂小丑" ,
			}
		},
		M12 = {  -- 木灵
			["01"] = {
				event_id = "46-M12-01",
				event_content = "协力作战——木灵" ,
			} ,
			["02"] = {
				event_id = "46-M12-02",
				event_content = "协力作战——木灵" ,
			}
		},
	},
	-- 学院补给
	["47"] = {
		M1 = {  -- 经验瓶
			["01"] = {
				event_id = "47-M1-01",
				event_content = "学院补给——经验瓶" ,
			} ,
			["02"] = {
				event_id = "47-M1-02",
				event_content = "学院补给——经验瓶" ,
			}
		},
		M2 = {  -- 灵体
			["01"] = {
				event_id = "47-M2-01",
				event_content = "学院补给——灵体" ,
			} ,
			["02"] = {
				event_id = "47-M2-02",
				event_content = "学院补给——灵体" ,
			}
		},
		M3 = {  -- 调味料补给
			["01"] = {
				event_id = "47-M3-01",
				event_content = "学院补给——调味料补给" ,
			} ,
			["02"] = {
				event_id = "47-M3-02",
				event_content = "学院补给——调味料补给" ,
			}
		},
		M4 = {  -- 外观券
			["01"] = {
				event_id = "47-M4-01",
				event_content = "学院补给——外观券" ,
			} ,
			["02"] = {
				event_id = "47-M4-02",
				event_content = "学院补给——外观券" ,
			}
		},
		M6 = {  -- 塔克夹
			["01"] = {
				event_id = "47-M6-01",
				event_content = "学院补给——塔克夹" ,
			} ,
			["02"] = {
				event_id = "47-M6-02",
				event_content = "学院补给——塔克夹" ,
			}
		},
		M7 = {  -- 特殊调味料
			["01"] = {
				event_id = "47-M7-01",
				event_content = "学院补给——特殊调味料" ,
			} ,
			["02"] = {
				event_id = "47-M7-02",
				event_content = "学院补给——特殊调味料" ,
			}
		},
	},
	--工会派对
	["52"] = {
		["01"] = {
			event_id = "52-01",
			event_content = "工会派对" ,
		} ,
		["02"] = {
			event_id = "52-02",
			event_content = "工会派对" ,
		}
	},
	-- 工会狩猎
	["53"] = {
		["01"] = {
			event_id = "53-01",
			event_content = "工会狩猎" ,
		} ,
		["02"] = {
			event_id = "53-02",
			event_content = "工会狩猎" ,
		}

	},
	-- 灾祸
	["60"] = {
		["01"] = {
			event_id = "60-01",
			event_content = "灾祸" ,
		} ,
		["02"] = {
			event_id = "60-02",
			event_content = "灾祸" ,
		}
	},
	-- 天城演武
	["63"] = {
		["01"] = {
			event_id = "63-01",
			event_content = "天城演武" ,
		} ,
		["02"] = {
			event_id = "63-02",
			event_content = "天城演武" ,
		}
	},
	-- 探索
	["73"] = {
		["01"] = {
			event_id = "73-01",
			event_content = "探索" ,
		} ,
		["02"] = {
			event_id = "73-02",
			event_content = "探索" ,
		}
	},
	-- 工会竞赛
	["87"] = {
		["01"] = {
			event_id = "87-01",
			event_content = "工会竞赛" ,
		} ,
		["02"] = {
			event_id = "87-02",
			event_content = "工会竞赛" ,
		}
	},
	-- 巅峰对决
	["94"] = {
		["01"] = {
			event_id = "94-01",
			event_content = "巅峰对决" ,
		} ,
		["02"] = {
			event_id = "94-02",
			event_content = "巅峰对决" ,
		}
	},
	-- 战斗演练
	["1002"] = {
		M1 = {  -- 单人
			["01"] = {
				event_id = "1002-M1-01",
				event_content = "战斗演练——单人" ,
			} ,
			["02"] = {
				event_id = "1002-M1-02",
				event_content = "战斗演练——单人" ,
			}
		},
		M2 = {  -- 群体
			["01"] = {
				event_id = "1002-M2-01",
				event_content = "战斗演练——群体" ,
			} ,
			["02"] = {
				event_id = "1002-M2-02",
				event_content = "战斗演练——群体" ,
			}
		},
		M3 = {  -- 守备
			["01"] = {
				event_id = "1002-M3-01",
				event_content = "战斗演练——守备" ,
			} ,
			["02"] = {
				event_id = "1002-M3-02",
				event_content = "战斗演练——守备" ,
			}
		},
		M4 = {  -- 治疗
			["01"] = {
				event_id = "1002-M4-01",
				event_content = "战斗演练——治疗" ,
			} ,
			["02"] = {
				event_id = "1002-M4-02",
				event_content = "战斗演练——治疗" ,
			}
		}
	},
	-- 常驻卡池
	["1003"] = { -- 抽卡+1
		["01"] = {
			event_id = "1003-01",
			event_content = "常驻卡池——抽卡" ,
		}
	},
	-- 活动卡池
	["1004"] = {
		M1 = {  -- 选卡卡池
			["01"] = {
				event_id = "1004-M1-01",
				event_content = "活动卡池——选卡卡池" ,
			}
		},
		M2 = {  -- 限购卡池
			["01"] = {
				event_id = "1004-M2-01",
				event_content = "活动卡池——限购卡池" ,
			} ,
			["02"] = {
				event_id = "1004-M2-02",
				event_content = "活动卡池——限购卡池" ,
			}
		},
		M3 = {  -- 阶段卡池
			["01"] = {
				event_id = "1004-M3-01",
				event_content = "活动卡池——阶段卡池" ,
			} ,
			["02"] = {
				event_id = "1004-M3-02",
				event_content = "活动卡池——阶段卡池" ,
			}
		},
		M4 = {  -- 超得卡池
			["01"] = {
				event_id = "1004-M4-01",
				event_content = "活动卡池——超得卡池" ,
			} ,
			["02"] = {
				event_id = "1004-M4-02",
				event_content = "活动卡池——超得卡池" ,
			}
		}
	},
	-- 创世巡典录
	--["1005"] = {
	--	["01"] = {
	--		event_id = "1005-01",
	--		event_content = "创世巡典录" ,
	--	}
	--} ,
	-- 试炼之门
	["1006"] = {
		["01"] = {
			event_id = "1006-01",
			event_content = "试炼之门" ,
		},
		["02"] = {
			event_id = "1006-02",
			event_content = "试炼之门" ,
		}
	} ,
	-- 游乐园
	["1007"] = {
		["01"] = {
			event_id = "1007-01",
			event_content = "游乐园" ,
		},
		["02"] = {
			event_id = "1007-02",
			event_content = "游乐园" ,
		}
	} ,
	-- 为活动埋点
	['1008'] = {
		["01"] = {
			event_id = "1008-01",
			event_content = "前往活动页",
		},
		["02"] = {
			event_id = "1008-02",
			event_content = "关闭活动打脸页滑动页",
		}
	}
}
function DotEventLog.GetParams(eventId ,addition)
	if isChinaSdk() then
		local array =  table.split(eventId ,"-")
		if #array > 0 then
			local eventKeyDefine = DotEventLog.EVENTS
			local hasAllkey = true
			for i=1 , #array do
				if eventKeyDefine[array[i]] and (type(eventKeyDefine) == "table") then
					eventKeyDefine = eventKeyDefine[array[i]]
				else
					hasAllkey = false
					break
				end
			end
			if hasAllkey then
				logInfo.add(5 , "dot:" ..  eventId )
				if addition then
					eventKeyDefine.event_id =table.concat({eventKeyDefine.event_id ,addition}, "-")
				end
				DotEventLog.Log(eventKeyDefine)
			else
				DotEventLog.Log({
					event_id = eventId ,
					event_content = ""
				})
				if DEBUG > 0  then
					assert(false , "dot:" ..  eventId  .. "缺失" )
				else
					logInfo.add(1 , "dot:" ..  eventId  .. "缺失")
				end
			end
		end
	end
end
function DotEventLog.Log(parameters)
	--local params = {event = eventName}
	local params = DotEventLog.CommonParams()
	--table.merge(params,t)
	if parameters then
		table.merge(params, parameters)
	end
	local sign = DotEventLog.generateSign(params)
	params.event = nil
	local ret = DotEventLog.tabletourlencode(params)
	ret = string.format("%s&sign=%s",ret,sign)
	if DEBUG and DEBUG > 0 then
		-- print('------------>>>', ret)
	end
	local url = ""
	-- 测试服与正式服的上报地址不一样
	local channelId = checkint(Platform.id)
	if channelId == Android or  channelId == BetaAndroid or channelId == BetaIos then
		url = table.concat({'http://data-event.duobaogame.com/event?', '', ret},'')	
	else 
		url = table.concat({'http://data-event.dddwan.com/event?', '', ret},'')		
	end 	
	
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = 4
	xhr.timeout = 30
	xhr:open("GET", url)
	xhr:send()
end

function DotEventLog.RegistObserver()
	if isChinaSdk() then
		-- 战斗的完成通过时间来获取到
		AppFacade.GetInstance():RegistObserver("BATTLE_COMPLETE_RESULT" , mvc.Observer.new(function (_, signal)
			if DotEventLog.dotLogEventStr and  string.len(DotEventLog.dotLogEventStr) > 0 then
				DotEventLog.GetParams(DotEventLog.dotLogEventStr)
				DotEventLog.dotLogEventStr = ""
			end
		end, DotEventLog))

		-- 发送打点事件
		AppFacade.GetInstance():RegistObserver("DOT_LOG_EVENT_SEND" , mvc.Observer.new(function (_, signal)
			local data =signal:GetBody()
			local eventId = data.eventId
			local addition = data.addition
			DotEventLog.GetParams(eventId , addition)
		end, DotEventLog))
		-- 设置打点事件
		AppFacade.GetInstance():RegistObserver("DOT_SET_LOG_EVENT" , mvc.Observer.new(function (_, signal)
			local data =signal:GetBody()
			local eventId = data.eventId
			DotEventLog.SetDotEventId(eventId)
		end, DotEventLog))
	end
end
function DotEventLog.SetDotEventId(eventId)
	DotEventLog.dotLogEventStr = eventId
end
return DotEventLog
