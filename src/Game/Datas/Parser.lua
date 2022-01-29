---@class  Parser
local Parser = class('Parser')
---@param name table dict 下的文件名
function Parser:ctor(name)
	self.name = name
	local dictName = string.match(self.NAME , "(%w+)ConfigParser")
	self.dictName = string.dcfirst(dictName)
	self.datas = {} --解析出来的数据集合
end


--[[
配表解析逻辑
@param dataManager 数据集合
--]]
function Parser:Load(dataManager )
	--local files = self:GetConfigFiles()
	--for tableName, path in pairs( files ) do
	--	self:ParserSpecifyConfigFile(tableName, path)
	--end
end

--[[
抽象的提供路径的方法
--]]
function Parser:GetConfigFiles( )
	-- 判断配表是否生成
	local t = {}
	local commonStr = 'conf/' .. i18n.getLang() .. '/'.. self.dictName .. '/'
	for k, v in pairs( self.name ) do
		local path = getRealConfigPath(commonStr .. v .. '.json')
		t[tostring( v )] = path
	end
	return t
end

--[[
得到具体的某一个对象
@params id 对象id
--]]
function Parser:GetVoById( id )
	if not self.datas[tostring(id)] then
		local path = getRealConfigPath('conf/' .. i18n.getLang() .. '/'.. self.dictName ..'/' .. tostring(id) .. '.json')
		self:ParserSpecifyConfigFile(tostring(id), path)
	end
	return self.datas[tostring( id )]
end

--[[
获取vo路径
@params name 配表名字
--]]
function Parser:GetVoPath(name)
  local path = 'Game/Datas/vo/' .. string.ucfirst(name) .. 'Vo.lua'
  if not utils.isExistent(path) then
    path = 'Game.Datas.Vo'
  else
    path = 'Game.Datas.vo.' .. string.ucfirst(name) .. 'Vo'
  end
  return path
end

--[[
--解析指定的json文件
--@tname  table表名称
--@jsonFilePath  string  json配表的具体路径
--]]
function Parser:ParserSpecifyConfigFile(tname, jsonFilePath)
    local t = getRealConfigData(jsonFilePath, tname)
    if t and next(t) ~= nil then
        -- local voClass = require(self:GetVoPath(tname))
        -- for k,v in pairs(t) do
        --     local vo = voClass:New(v, k)
        --     if nil == self.datas[tname] then
        --         self.datas[tname] = {}
        --     end
        --     if not vo:GetId() then
        --         print('--IMPORT-------NOT ID START-', tname,jsonFilePath)
        --         table.insert(self.datas[tname],vo:GetData())
        --     else
        --         self.datas[tname][tostring(vo:GetId())] = vo:GetData()
        --     end
        -- end
        self.datas[tname] = t
    else
        self.datas[tname] = {}
    end
end
--[[
获取数据
@params name string 配表名字
@params id int vo id
--]]
function Parser:GetVo(tname, id)
	if not self.datas[tname] then
		local path = getRealConfigPath('conf/' .. i18n.getLang() .. '/' .. self.dictName ..'/' .. tname .. '.json')
		self:ParserSpecifyConfigFile(tname, path)
	end
	return self.datas[tname][tostring(id)]
end

--[[
获取分表的表名
@params tname string 源表名
@params id int id
@return fixedtname string 修正后的表名
--]]
function Parser:GetFixedJsonName(tname, id)
	local indextname = self:GetIndexByJsonName(tname)
	
	if nil ~= indextname and self.datas[indextname] then
		local fixedtname = self:FixJsonName(tname, id, self.datas[indextname][tostring(id)])
		return fixedtname
	end

	return tname
end

--[[
修正分表的表名 拼接表名的逻辑
@params tname string 源表名
@params id int id
@params indexvalue value 索引表中对应的值
@return fixedtname string 修正后的表名
--]]
function Parser:FixJsonName(tname, id, indexvalue)
	return tname
end

--[[
根据表名获取分表索引信息
@params tname string 源表名
@return indextname string 索引表名
--]]
function Parser:GetIndexByJsonName(tname)
	return nil
end

return Parser
