local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local CreateRoleCommand = Command:New()

CreateRoleCommand.NAME = "CreateRoleCommand"


--[[--*
* @param color 对应的色彩值
* @param time 持续时间
--]]
function CreateRoleCommand:New(color, time)
    local this = {}
    setmetatable( this, {__index = CreateRoleCommand} )
    this.inAction = true
    return this
end
--[[
设置图象的反转
@param color 色彩值
--]]
function CreateRoleCommand:SetColor( color )
    this.color = ccc4FromInt(color)
end

function CreateRoleCommand:CanMoveNext()
    return false
end

--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function CreateRoleCommand:Execute( )
    --执行方法的虚方法
    --去创角页面的逻辑
    --添加显示创角页面
    local director = Director.GetInstance( )
    local stage = director:GetStage()
    if stage then
        --首先移除消息层
        stage:removeChildByTag(Director.ZorderTAG.Z_CREATE_ROLE_LAYER)
        --再添加消息层
        local colorView
        if GAME_MODULE_OPEN.NEW_CREATE_ROLE then
            colorView = require('Game.views.createPlayer.CreatePlayerEnterLayer').new() 
        else
            colorView = require('Game.views.CreateRoleLayer').new()
        end
        display.commonUIParams(colorView, {po = display.center})
        stage:addChild(colorView, Director.ZorderTAG.Z_CREATE_ROLE_LAYER,Director.ZorderTAG.Z_CREATE_ROLE_LAYER)
    end
end

return CreateRoleCommand
