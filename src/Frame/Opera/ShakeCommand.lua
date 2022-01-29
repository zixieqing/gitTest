local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local ShakeCommand = Command:New()

ShakeCommand.NAME = "ShakeCommand"

local shareSceneManager = cc.CSceneManager:getInstance()

function ShakeCommand:New( duration, maxRadius, minRadius, roleId)
	local this = {}
	setmetatable( this, {__index = ShakeCommand} )
	this.duration = (duration or 1)
	this.maxRadius = (maxRadius or 5)
	this.minRadius = (minRadius or 2)
	this.roleId    = roleId
	return this
end

function ShakeCommand:CanMoveNext()
    return false
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--]]
function ShakeCommand:Execute( )
	--执行方法的虚方法
	if self.roleId then
		--抖动某一个角色
		local roleInfo = Director.GetInstance( "Director" ):GetRole(self.roleId)
	    if roleInfo and roleInfo.role then
	    	roleInfo.role:runAction(cc.Sequence:create(ShakeAction:create(self.duration, self.maxRadius, self.minRadius),cc.CallFunc:create(function()
				self:Dispatch("DirectorStory","next")
            end)))
    	end
	else
		--抖动窗口
		local scene = shareSceneManager:getRunningScene()
		--不阻碍命行下行，所以要先dipatch出去
		self:Dispatch("DirectorStory","next")
		scene:runAction(ShakeAction:create(self.duration, self.maxRadius, self.minRadius))
		-- scene:runAction(cc.Sequence:create(ShakeAction:create(self.duration, self.maxRadius, self.minRadius),cc.CallFunc:create(function()
		-- 	self:Dispatch("DirectorStory","next")
        -- end)))
	end
end

return ShakeCommand 
