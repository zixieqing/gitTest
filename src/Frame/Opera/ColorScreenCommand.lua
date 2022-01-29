local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local ColorScreenCommand = Command:New()

ColorScreenCommand.NAME = "ColorScreenCommand"


--[[--*
* @param color 对应的色彩值
* @param time 持续时间
--]]
function ColorScreenCommand:New(color, time)
    local this = {}
    setmetatable( this, {__index = ColorScreenCommand} )
    this.color = ccc4FromInt(color)
    this.time = (time or 0)
    this.inAction = true
    this.relationNode = nil
    return this
end
--[[
设置图象的反转
@param color 色彩值
--]]
function ColorScreenCommand:SetColor( color )
    this.color = ccc4FromInt(color)
end

function ColorScreenCommand:CanMoveNext()
    return false
end

--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function ColorScreenCommand:Execute( )
    --执行方法的虚方法
	local director = Director.GetInstance( )
	local stage = director:GetStage()
	if stage then
        -- director:ClearRoles()
        -- stage:removeChildByTag(Director.ZorderTAG.Z_ROLE_LAYER)
        -- stage:removeChildByTag(Director.ZorderTAG.Z_BG_LAYER)
	--首先移除消息层
		stage:removeChildByTag(Director.ZorderTAG.Z_COLOR_SCREEN_LAYER)
		--再添加消息层
        -- local action = false
        if self.time > 0 then
            self.inAction = true
        end
        local colorView = CColorView:create(self.color)
        colorView:setContentSize(display.size)
        -- colorView:setOnClickScriptHandler(function(sender)
        --     if action == false then
        --         sender:setTouchEnabled(false)
        --         colorView:setVisible(false)
        --         local director = Director.GetInstance( "Director" )
        --         director:MoveNext()
        --     end
        -- end)
        self.relationNode = colorView
		display.commonUIParams(colorView, {po = display.center})
		stage:addChild(colorView, Director.ZorderTAG.Z_COLOR_SCREEN_LAYER,Director.ZorderTAG.Z_COLOR_SCREEN_LAYER)
        if self.time > 0 then
            colorView:setOpacity(100)
            colorView:runAction(cc.Sequence:create(TreeFadeIn:create(self.time), cc.CallFunc:create(function()
                director:ClearRoles()
                if stage:getChildByTag(Director.ZorderTAG.Z_ROLE_LAYER) then
                    stage:removeChildByTag(Director.ZorderTAG.Z_ROLE_LAYER)
                end
                if stage:getChildByTag(Director.ZorderTAG.Z_BG_LAYER) then
                    stage:removeChildByTag(Director.ZorderTAG.Z_BG_LAYER)
                end
                self.inAction = false
                --不再自动向下切换命令
                self:Dispatch("DirectorStory","next") 
            end)))
        else
            self.inAction = false
        end
	end
end

return ColorScreenCommand
