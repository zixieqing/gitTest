--[[
战斗配置工具
--]]
BattleConfigUtils = {}

---------------------------------------------------
-- module begin --
---------------------------------------------------
--[[
是否能启用录像功能
@return _ bool 是否能启用
--]]
function BattleConfigUtils.IsScreenRecordEnable()
	------------ 平台判断 ------------
	local enablePlatform = {
		['ios'] = true
	}
	if true ~= enablePlatform[device.platform] then
		return false
	end
	------------ 平台判断 ------------

	------------ 渠道判断 ------------
	if nil == isElexSdk or 'function' ~= type(isElexSdk) or not isElexSdk() then
		return false
	end
	------------ 渠道判断 ------------

	return true
end
--[[
是否开启后台暂停的逻辑
@return _ bool 是否开启后台暂停战斗的功能
--]]
function BattleConfigUtils.IsAppEnterBackgroundPauseGame()
	------------ 渠道 ------------
	-- 开启的语言
	local enableLang = {
		['ko-kr'] = true,
		['ja-jp'] = true
	}

	if isElexSdk() then
        return true
    else
        return true == enableLang[i18n.getLang()]
    end
	------------ 渠道 ------------
end
--[[
是否开启返回键弹出退出提示的逻辑
@return _ bool 是否开启返回键弹出退出提示的逻辑
--]]
function BattleConfigUtils.IsGoogleBackQuitBattleEnable()
	------------ 渠道 ------------
	-- 开启的语言
	local enableLang = {
		['ko-kr'] = true,
		['ja-jp'] = true
	}

    if isElexSdk() then
        return true
    else
        return true == enableLang[i18n.getLang()]
    end
	------------ 渠道 ------------
end
--[[
是否使用elex版的本地化逻辑
@return _ bool 
--]]
function BattleConfigUtils:UseElexLocalize()
	------------ 语言 ------------
	local enableLang = {
		['ko-kr'] = true
	}
	------------ 语言 ------------

	------------ 渠道 ------------
	return isElexSdk() or (true == enableLang[i18n.getLang()])
	------------ 渠道 ------------
end
--[[
是否使用japan的本地化逻辑
@return _ bool 
--]]
function BattleConfigUtils:UseJapanLocalize()
	------------ 渠道 ------------
	return i18n.getLang() == 'ja-jp'
	------------ 渠道 ------------
end
--[[
是否屏蔽战斗的操作记录
@return _ bool 
--]]
function BattleConfigUtils.IsIgnoreRecordPLayerOperate(managerName, functionName)
	local ignoreRecordMap = {
		['G_BattleLogicMgr'] = {
			['RenderPauseBattleHandler']  = true, -- 暂停战斗
			['RenderResumeBattleHandler'] = true, -- 恢复战斗
		}
	}
	return ignoreRecordMap[managerName] ~= nil and ignoreRecordMap[managerName][functionName] == true
end
---------------------------------------------------
-- module end --
---------------------------------------------------