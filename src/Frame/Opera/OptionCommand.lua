local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local OptionCommand = Command:New()

OptionCommand.NAME = "OptionCommand"


--[[--*
* @param params
--]]
function OptionCommand:New(params)
    local this = {}
    setmetatable( this, {__index = OptionCommand} )
    this.params = params
    return this
end

--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function OptionCommand:CanMoveNext( )
	return false
end

--[[
--执行方法的虚方法
--真实调用的方法逻辑
--]]
function OptionCommand:Execute( )
    --执行方法的虚方法
    local director = Director.GetInstance( "Director" )
    local stage = director:GetStage()
    if stage then
        director:ClearRoles()
        local messageLayer = stage:getChildByTag(Director.ZorderTAG.Z_QUESTION_LAYER)
        if messageLayer then
            stage:removeChildByTag(Director.ZorderTAG.Z_QUESTION_LAYER)
        end
        local OptionView = require('Game.views.counterpart.OptionView')
        local optionView = OptionView.new(self.params)
        display.commonUIParams(optionView, {po = display.center})
        stage:addChild(optionView, Director.ZorderTAG.Z_QUESTION_LAYER, Director.ZorderTAG.Z_QUESTION_LAYER)
    end
end

return OptionCommand
