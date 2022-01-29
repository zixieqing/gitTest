-- 此处一定是重写commom utils如果不是会造成巨大的问题
if nil == CommonUtils then
	return
end

------------ import ------------
------------ import ------------

------------ define ------------
__CommonUtils__ = {}

-- 全局保存配表信息的map
CommonUtils.ConfigMap = {}
------------ define ------------

-------------------------------------------------
-- config begin --
-------------------------------------------------
--[[
根据模块名 配表名获取
@params mname string 模块名
@params tname string 配表名
@params id string 键
@return _ table
--]]
function CommonUtils.GetConfig(mname, tname, id)
	-- 特殊处理
	mname, tname = __CommonUtils__.GetFixedConfigMAndTName(mname, tname, id)

	local alldata = CommonUtils.GetConfigAllMess(tname, mname)
	if nil ~= alldata then
		return alldata[tostring(id)]
	end

	return nil
end
function CommonUtils.GetConfigNoParser(module, tname, id)
    return CommonUtils.GetConfig(module, tname, id)
end
--[[
获取整张表的数据
@params tname string 配表名
@params mname string 模块名
--]]
function CommonUtils.GetConfigAllMess(tname, mname)
	------------ warning ------------
	-- 分表逻辑和获取整表的行为冲突
	------------ warning ------------
	mname, tname = __CommonUtils__.GetFixedConfigMAndTName(mname, tname)

	if nil == CommonUtils.ConfigMap[tostring(mname)] or nil == CommonUtils.ConfigMap[tostring(mname)][tostring(tname)] then
		-- 内存里没有这张表 加载一次这张表
		CommonUtils.LoadConfigJson(tostring(mname), tostring(tname))
	end
	return CommonUtils.ConfigMap[tostring(mname)] and CommonUtils.ConfigMap[tostring(mname)][tostring(tname)] or nil
end
--[[
根据模块名 配表名加载配表
@params mname string 模块名
@params tname string 配表名
--]]
function CommonUtils.LoadConfigJson(mname, tname)
	local path = CommonUtils.GetConfigPathByMN(mname, tname)
	if CommonUtils.FileExistByPath(path) then
		local file = io.open(path)
		local fileContent = file:read('*a')
		local configtable = json.decode(fileContent)
		file:close()
		if nil == CommonUtils.ConfigMap[mname] then
			CommonUtils.ConfigMap[mname] = {}
		end
		CommonUtils.ConfigMap[mname][tname] = configtable
	else
		print('cannot find file when loading config json ->', path)
	end
end
--[[
根据模块名 配表名移除配表
@params mname string 模块名
@params tname string 配表名
--]]
function CommonUtils.RemoveConfigJson(mname, tname)

end
--[[
根据模块名 配表名获取配表文件路径
@params mname string 模块名
@params tname string 配表名
--]]
function CommonUtils.GetConfigPathByMN(mname, tname)
	return 'conf/' .. CommonUtils.GetLangCode() .. '/' .. mname .. '/' .. tname .. '.json'
end
-------------------------------------------------
-- config end --
-------------------------------------------------

-------------------------------------------------
-- file begin --
-------------------------------------------------
--[[
根据文件路径判断文件是否存在
@params path string 文件路径
@return _ bool 是否存在
--]]
function CommonUtils.FileExistByPath(path)
	local file = io.open(path)
	if nil ~= file then
		file:close()
	end
	return nil ~= file
end
-------------------------------------------------
-- file end --
-------------------------------------------------

-------------------------------------------------
-- language begin --
-------------------------------------------------
--[[
获取语言代码
@return _ LangCodesMap
--]]
function CommonUtils.GetLangCode()
	return SERVER_SCRIPT_LANG_CODE or 'zh-cn'
end
-------------------------------------------------
-- language end --
-------------------------------------------------

-------------------------------------------------
-- private begin --
-------------------------------------------------
--[[
修正一次模块名 表名
@params mname string 模块名
@params tname string 配表名
@params id string 键
@return newmname, newtname, newid string, string, string 新模块名, 新表名, 新键
--]]
function __CommonUtils__.GetFixedConfigMAndTName(mname, tname, id)
	local newmname = mname
	local newtname = tname
	local newid = id

	if 'cards' == mname then
		newmname = 'card'
	end

	if nil ~= id then
		local needRedirect, newmname_, newtname_, newid_ = __CommonUtils__.RedirectConfig(
			newmname, newtname, newid
		)
		if true == needRedirect then
			return newmname_, newtname_, newid_
		end
	end

	return newmname, newtname, newid
end


--[[
通用的配表重定向 -> 根据id段分表
@params mname string 模块名
@params tname string 配表名
@params id string 键
@params section int 分段的系数
--]]
local function CommonRedirectConfigHandler(mname, tname, id, section)
	local newtname = tname .. math.ceil(checkint(id) / section)
	return mname, newtname, id
end
local ConfigRedirectMap = {
	['card'] = {
		['skill'] 			= {need = true, handleFunc = function (mname, tname, id)
			return CommonRedirectConfigHandler(mname, tname, id, 50)
		end},
	},
	['artifact'] = {
		['gemstoneSkill'] 	= {need = true, handleFunc = function (mname, tname, id)
			-- !!! 此处递归 谨慎使用 !!! --
			local indexConfig = CommonUtils.GetConfig('artifact', 'cardArtifactGemstoneSkill', id)
			if nil ~= indexConfig then
				return mname, tname .. indexConfig, id
			end
		end},
	}
}
--[[
获取重定向的配表 如果必要的话
@params mname string 模块名
@params tname string 配表名
@params id string 键
@return need, newmname, newtname, newid, newid bool, string, string, string 是否需要重定向, 新模块名, 新表名, 新键
--]]
function __CommonUtils__.RedirectConfig(mname, tname, id)
	if nil ~= ConfigRedirectMap[mname] and nil ~= ConfigRedirectMap[mname][tname] then
		local redirectInfo = ConfigRedirectMap[mname][tname]
		if true == redirectInfo.need then
			return true, redirectInfo.handleFunc(mname, tname, id)
		end
	end
	return false
end
-------------------------------------------------
-- private end --
-------------------------------------------------