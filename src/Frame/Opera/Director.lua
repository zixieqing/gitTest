---@class Director
local Director = class("Director", mvc.Dispatch)

local shareFacade = AppFacade.GetInstance()

Director.instances = {}

local CommandType = Enum ({
	Automatic = 1, --自动执行
	Manually = 2 --手动执行
})

local RoleType = Enum (
{
	RoleMapRole = "role",
	RoleMapImage = "image"
})

Director.ZorderTAG = Enum(
{
	Z_COLOR_BOTTOM       = 20,
	Z_BG_COLOR_LAYER     = 788,
	Z_BG_LAYER           = 1000,
	Z_LIVE2D_LAYER       = 1003,
	Z_ROLE_LAYER         = 1004,
	Z_SPINE_ANIME        = 1005,
	Z_MESSAGE_LAYER      = 1024,
	Z_OPENING_LAYER      = 1025,
	Z_WHEN_LAYER         = 1026,
	Z_EFFECT_LAYER       = 1028,
	Z_QUESTION_LAYER     = 1029,
	Z_APPEND_DESCR_LAYER = 1030,
	Z_ROLE_DESC_LAYER    = 1031,
	Z_COLOR_SCREEN_LAYER = 1132,
	Z_VIDEO_LAYER        = 1133,
	Z_CREATE_ROLE_LAYER  = 1134,
})

Director.Align = {
	LEFT          = 1,
	LEFT_CENTER   = 2,
	RIGHT_CENTER  = 3,
	RIGHT         = 4,
	CENTER        = 5,
}

Director.Type = {
	STORY        = 0,  -- 剧情
	CG_BEGEN     = 2,  -- 开始CG
	CG_RETAIN    = 1,  -- 维持CG
	CG_ENDED     = 3,  -- 结束CG
	LOCATION     = 4,  -- 时间地点
	BLACK        = 5,  -- 黑屏白字
	OPTION       = 6,  -- 选项
	SPINE_BEGEN  = 7,  -- 开始spine
	SPINE_RETAIN = 8,  -- 维持spine
	SPINE_ENDED  = 9,  -- 结束spine
	APPEND_DESCR = 10,  -- 附加描述
}

local scheduler = require('cocos.framework.scheduler')

function Director:ctor( )
	self.super.ctor(self)
	self.commands = {}
	self.roles = {} --记录所有的角色的位置列表{["2"] = {role = roleNode,pos="left",type="role"}}
	self.isDone = false --记录当前对白是否已完成
	self.isStart = false --记录当前对白是否已开始执行
	self.curIndex = 1; --当前的命令位置
	self.canGo = true --当前这条命令是否可以向下继续执行
	self.cmdType = CommandType.Manually --当前的命令类型，初始为自动执行类型
	self.stage =  nil --当前的舞台
end
---@return  Director
function Director.GetInstance( key )
	if not key then key = "Director" end
	local director = nil
	if not Director.instances[key] then
		director = Director.new()
		Director.instances[key] = director
	else
		director = Director.instances[key]
	end
	return director
end

function Director.Destroy(key)
	if Director.instances[key] then
		--清除配表数据
	    local instance = Director.instances[key]
	    if instance.updateHandler then
	        scheduler.unscheduleGlobal(instance.updateHandler)
	    end
	    instance.isStart = false
	    instance = nil
		Director.instances[key] = nil
	end
end
--[[
开始执行剧情逻辑功能
--]]
function Director:Start( )
	if (not self.updateHandler) and (not self.isStart) then
		self.isStart = true --记录当前对白是否已开始执行
		self.updateHandler = scheduler.scheduleGlobal(handler(self, self.Update),0.1)
	end
end
--[[
是否存在指定的角色信息
@param roleId 角色id
--]]
function Director:HasRole( roleId )
	return (self.roles[tostring(roleId)] ~= nil)
end
--[[
获取指定的缓存角色
--]]
function Director:GetRole( roleId )
	return self.roles[tostring(roleId)]
end

function Director:PushImage( imageId, node )
	self:PopImage(imageId)
	self.roles[tostring(imageId)] = {role = node,pos = "center", type="image"}
end
--[[
* 添加一个角色类型,要判断是role类型的位置然后进行相应的高亮与灰色处理
* @param roleId 角色id
* @param node 对象节点
--]]
function Director:PushRole( roleId, node, align)
	--判断同位置是否有角色要进行更换操作
	node:setPosition(Director.GetAlignPoint(align))
	for id,v in pairs(self.roles) do
		if v.type == 'role' and v.role and align == checkint(v.pos) then
			self:PopRole(id) --先移出再进行添加人物的操作
		else
            if v.type == 'role' and v.role then
                local roleImageNode = v.role:getChildByTag(888)
                local nameLabelNode = v.role:getChildByTag(7654)
				if roleImageNode and not v.role.mysteryMode then
					roleImageNode:setColor(cc.c3b(80,80,80))
				end
				if nameLabelNode then
                    nameLabelNode:setVisible(false)
                end
            end
		end
	end
	self.roles[tostring(roleId)] = {role = node,pos = align, type="role"}
end

function Director:PushSpine( node, fileName, animeName, isReplay)
	self:PopImage(fileName)
	self.roles[tostring(fileName)] = {spine = node, file = fileName, anime = animeName, type="spine"}
end

--[[
* 移出一个类型,要判断是role类型的位置然后进行相应的高亮与灰色处理
* @param roleId 角色id
--]]
function Director:PopImage( imageId )
	local v = self.roles[tostring(imageId)]
	if v then
		if v.type == 'image' then
			if v.role and not tolua.isnull(v.role) then
				v.role:removeFromParent()
			end
			self.roles[tostring(imageId)] = nil
		elseif v.type == 'spine' then
			if v.spine and not tolua.isnull(v.spine) then
				v.spine:removeFromParent()
			end
			self.roles[tostring(imageId)] = nil
		elseif v.type == 'role' then
			self:PopRole(imageId)
		end
	end
end


function Director:PopAllImageAndRole( imageId )
	for imageId, _ in pairs(self.roles) do
		self:PopImage(imageId)
	end
end

function Director:RemoveImageCache(imageId)
	local v = self.roles[tostring(imageId)]
    if v then
        self.roles[tostring(imageId)] = nil
    end
end

--[[
* 移出一个角色类型,要判断是role类型的位置然后进行相应的高亮与灰色处理
* @param roleId 角色id
--]]
function Director:PopRole( roleId )
	--判断同位置是否有角色要进行更换操作
	local roleInfo = self.roles[tostring(roleId)]
	if roleInfo then
		if roleInfo.type == 'role' then
			if roleInfo.role then
				roleInfo.role:removeFromParent()
			end
			self.roles[tostring(roleId)] = nil
		end
	end
end
--[[
* 移出一个角色类型,要判断是role类型的位置然后进行相应的高亮与灰色处理
--]]
function Director:ClearRoles( )
	--判断同位置是否有角色要进行更换操作
    for id,v in pairs(self.roles) do
        if v.type == 'role' and v.role then
            self:PopRole(id) --先移出再进行添加人物的操作
        end
    end
end

function Director:OpacityRoles()
    for id,v in pairs(self.roles) do
        if v.type == 'role' and v.role then
            local roleImageNode = v.role:getChildByTag(888)
            local nameLabelNode = v.role:getChildByTag(7654)
            if roleImageNode and not v.role.mysteryMode then
				roleImageNode:setColor(cc.c3b(80,80,80))
			end
			if nameLabelNode then
                nameLabelNode:setVisible(false)
            end
        end
    end
end
--[[
设置剧情舞台
@param stage 舞台
--]]
function Director:SetStage( stage)
	self.stage = stage
end

function Director:GetStage(  )
	return self.stage
end

--[[
添加一条命令
@param command 命令 Command的子类
--]]
function Director:AddCommand( command )
	table.insert( self.commands, command )
	-- table.insert( self.commands, 1, command )
end

--[[
调整对白类型
@param type 是否是自动还是手动执行
--]]
function Director:SetCommandType( type )
	self.cmdType = type
end

--[[
调整是否可以向下进行
@param can 设置是否可以向下执行
--]]
function Director:SetCanGo( can )
	self.canGo = can
end
--[[
--重一个文件中读取命令配表
@param filepath 要读取的文件路径
@param datahanel 是否自己去处理命令配表数据
--]]
function Director:LoadFromFile( filepath, datahandle )
	local pathList = string.split2(filepath, '/')
	local content  = CommonUtils.GetConfigAllMess(pathList[#pathList], pathList[#pathList - 1])
    -- filepath = getRealConfigPath(filepath)
    -- local name = stripextension(basename(filepath))
	-- local content = getRealConfigData(filepath, name)
	if datahandle then
		datahandle(filepath, content)
	else
		--初始的数据处理逻辑
		local function handleData(content)
			local t = json.decode(content) --转为table
			if t and next(t) ~= nil then
				for k, v in pairs( t ) do
					if checkint(v.type) == 0 then
						--对白
						local cmd = require( "Frame.Opera.DialogueCommand" ):New()
						cmd:CommandDialogue(v.name,v.descr)
						self:AddCommand(cmd)
					end
				end
			end
		end
		handleData(content)
	end
end

function Director:SkipToCreateRole( )
	local t = {}

	if GAME_MODULE_OPEN.NEW_PLOT then
		self.commands = {}

		local storyPath = string.format('conf/%s/plot/story0.json', i18n.getLang())
		self.stage:LoadStory(storyPath, 7)
		t = self.commands
		
		local CreateRoleCommand = require("Frame.Opera.CreateRoleCommand")
		table.insert(t, 1, CreateRoleCommand:New() )

		self.stage:removeChildByTag(Director.ZorderTAG.Z_MESSAGE_LAYER)

	else
		local len = table.nums(self.commands)
		local pos = 1
		for k,val in pairs(self.commands) do
			if val.NAME == 'CreateRoleCommand' then
				pos = checkint(k)
				break
			end
		end
		for k,val in pairs(self.commands) do
			if checkint(k) >= pos then
				-- print(k, pos, val.NAME)
				table.insert(t,val)
			end
		end
	
		local imagecmd = require('Frame.Opera.ImageCommand'):New("main_bg_06")
		table.insert(t, 2, imagecmd)
	end

	-- 清全部角色
	-- 清全部spine
	self:PopAllImageAndRole()
	
	self.commands = t
	self.curIndex = 0
    self.stage:removeChildByTag(Director.ZorderTAG.Z_OPENING_LAYER)
	self.stage:removeChildByTag(Director.ZorderTAG.Z_WHEN_LAYER)
	self.stage:removeChildByTag(Director.ZorderTAG.Z_SPINE_ANIME)
	self.stage:removeChildByTag(Director.ZorderTAG.Z_VIDEO_LAYER)
    self.stage:removeChildByTag(Director.ZorderTAG.Z_COLOR_SCREEN_LAYER)
    self:MoveNext()
end
--相关的方法操作
--[[
--移动到下一个命令
--]]
function Director:MoveNext( )
	if next(self.commands) == nil then
		--当前没有命令集
		return
	end
	local index = self.curIndex
	self.curIndex = index + 1
	local len = table.nums(self.commands)
	if (self.curIndex > len) then
		self.curIndex = 0
		self.commands = {} --清除所有命令
		--发送执行完成的逻辑操作
		funLog(Logger.INFO, "Execute success")
        shareFacade:DispatchObservers("DirectorStory", "success")
	else
        local cmd = self.commands[self.curIndex]
        if cmd.NAME == "CreateRoleCommand" then
            --隐藏跳过按钮
            self.stage:HiddenSkip()
        end
		self.canGo = true --可以执行下一步操作
	end
end
--[[
--移动到前一个命令
--]]
function Director:MovePre( )
	if next(self.commands) == nil then
		--当前没有命令集
		return
	end
	local index = self.curIndex
	self.curIndex = index - 1
	if (self.curIndex <= 0) then
		self.curIndex = 1
	end
end

--[[
--得到第一句对白类型的位置
--]]
function Director:GetFirstDialogIndex( )
	local index = -1
	for k, v in pairs( self.commands ) do
		if v.NAME == "DialogueCommand" then --得到第一句对白类型的位置
			index = k
			break
		end
	end
	return index
end

--[[
--获取当前正在执行的命令对象
--]]
function Director:GetCurrentCommand()
    return self.commands[self.curIndex]
end

--[[
* 自动执行当前命令
--]]
function Director:ExecuteAutomatic( )
	if next(self.commands) == nil then return end
	if self.canGo then
		self.canGo = false --做一个锁定操作
		if self.curIndex < 1 or self.curIndex > table.nums(self.commands) then
			--位置超过范围了
		end
		local command = self.commands[self.curIndex]
		command:Execute() --执行命令
		self:MoveNext() --命令下移一条
	end
end

--[[
* 手动执行当前命令
--]]
function Director:ExecuteManually( )
	if next(self.commands) == nil then return end
	if self.canGo then
		self.canGo = false
		if self.curIndex < 1 or self.curIndex > table.nums(self.commands) then
			--位置超过范围了
		end
		local index = self:GetFirstDialogIndex()
		if self.curIndex == index then
			--第一句对白功能进行执行
			local command = self.commands[self.curIndex]
			command:Execute()
			if command:CanMoveNext() then
				self:MoveNext() --执行下一步
			end
		else
			--需要后动触发对话框的显示
			local command = self.commands[self.curIndex]
			command:Execute()
			if command:CanMoveNext() then
				self:MoveNext() --执行下一步
			end
			funLog(Logger.INFO, string.format("当前执到位置[%d],总的命令数[%d]",self.curIndex,#self.commands))
		end
	end
end

function Director:Update( dt )
	if self.cmdType == CommandType.Automatic then
		self:ExecuteAutomatic()
	elseif self.cmdType == CommandType.Manually then
		self:ExecuteManually()
	end
end



--[[
	获取角色名字
]]
function Director.GetRoleName(roleId)
	local roleName = ""
	local roleId = checkstr(roleId)
	local isCard = false
	
	--数字表示是卡牌
	if string.match(roleId, '^%d+') then
		isCard = true

        -- 突破后的立绘不存在 使用默认立绘
		local cardId = checkint(roleId)
        if 250000 < cardId and 259000 >= cardId then
            -- cardId = skinId
            cardId = checkint(checktable(CardUtils.GetCardSkinConfig(cardId)).cardId)
            -- cardId = cardId
        elseif 259000 < cardId then
            cardId = cardId
            -- cardId = bossCardId
        end
		roleName = tostring(checktable(CardUtils.GetCardConfig(cardId)).name)
		
	--角色人物
	else
        local rInfo = app.gameMgr:GetRoleInfo(roleId)
        if rInfo then
			roleName = tostring(rInfo.roleName)
		else
			roleName = '???'
		end

		if roleName == '_name_' then
			if string.len(checkstr(app.gameMgr:GetUserInfo().playerName)) > 0 then
				roleName = tostring(app.gameMgr:GetUserInfo().playerName)
			else
				roleName = __('我')
			end
		end
	end
	
	return roleName, isCard
end


function Director.GetRoleHead(roleId)
	local HEAD_SIZE = cc.size(170, 170)
	local headNode = display.newLayer(0, 0, {color = cc.r4b(150), size = HEAD_SIZE})
	local roleId = checkstr(roleId)
	local isCard = false

	--数字表示是卡牌
	if string.match(roleId, '^%d+') then
		isCard = true

		local cardId   = checkint(roleId)
		local headPath = CardUtils.GetCardHeadPathByCardId(cardId)
		headNode = display.newImageView(headPath)

	--角色人物
	else
		-- check is self
		if roleId == 'role_0000' then
			headNode = require('root.CCHeaderNode').new({isSelf = true, tsize = HEAD_SIZE})
		else
			local headPath  = CommonUtils.GetNpcIconPathById(roleId, NpcImagType.TYPE_HALF_BODY)
			local headImage = display.newImageView(headPath, HEAD_SIZE.width/2, HEAD_SIZE.height/2)
			headImage:setScale(1.8)
			headNode = display.newLayer(0, 0, {size = HEAD_SIZE})
			headNode:addChild(headImage)
		end
	end

	return headNode, isCard
end


function Director.GetAlignPoint(align)
	if align == Director.Align.LEFT then
		return cc.p(224 + display.SAFE_L, display.cy)
	elseif align == Director.Align.LEFT_CENTER then
		return cc.p(476 + display.SAFE_L, display.cy)
	elseif align == Director.Align.RIGHT_CENTER then
		return cc.p(852 - display.SAFE_L, display.cy)
	elseif align == Director.Align.RIGHT then
		return cc.p(display.width - 228 - display.SAFE_L, display.cy)
	elseif align == Director.Align.CENTER then
		return cc.p(display.cx, display.cy)
	end
	return cc.p(0,0)
end


return Director
