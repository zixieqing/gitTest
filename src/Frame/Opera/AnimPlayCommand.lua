local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local AnimPlayCommand = Command:New()

AnimPlayCommand.NAME = "AnimPlayCommand" --移除动作执行功能


--[[--*
* 等待多少秒再继续执行剧情
* @param animateId 执行的动画id
* @param wait 是否需要点击才执行接下来的动作
--]]
function AnimPlayCommand:New(animateId, wait)
    local this = {}
    setmetatable( this, {__index = AnimPlayCommand} )
    this.animateId = animateId
    this.inAction = true
    this.wait = (wait or false) --是否需在单击才会执行接下来的动作
    return this
end


--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function AnimPlayCommand:Execute( )
    --执行方法的虚方法
    local director = Director.GetInstance( )
	local stage = director:GetStage()
	if stage then
		--首先移除特效层
		stage:removeChildByTag(Director.ZorderTAG.Z_EFFECT_LAYER)
        local colorView = CColorView:create(cc.c4b(100,100,100,0))
        colorView:setContentSize(display.size)
		display.commonUIParams(colorView, {po = display.center})
		stage:addChild(colorView, Director.ZorderTAG.Z_EFFECT_LAYER,Director.ZorderTAG.Z_EFFECT_LAYER)
        --添加特效的id添加相关的ui功能
        if self.animateId == 8 then
            --攻击
            local bgImage = display.newSprite(_res("arts/stage/ui/stage_attack_bg.png"))
            display.commonUIParams(bgImage, {po = display.center})
            colorView:addChild(bgImage,1)
            fullScreenFixScale(bgImage)
            local scale = bgImage:getScale()
            bgImage:setScale((scale + 0.1))
            local catImage1 = display.newSprite(_res("arts/stage/ui/stage_attack_cat_1.png"))
            display.commonUIParams(catImage1, {po = display.center})
            catImage1:setLocalZOrder(100)
            catImage1:setOpacity(0)
            colorView:addChild(catImage1, 100)

            local catImage2 = display.newSprite(_res("arts/stage/ui/stage_attack_cat_2.png"))
            display.commonUIParams(catImage2, {po = display.center})
            catImage2:setLocalZOrder(100)
            catImage2:setOpacity(0)
            colorView:addChild(catImage2, 100)
            --开始播动动画
            colorView:runAction(cc.Sequence:create(cc.TargetedAction:create(bgImage, cc.ScaleTo:create(0.3,scale)),
                        cc.TargetedAction:create(catImage1,cc.Sequence:create(cc.Spawn:create(cc.FadeIn:create(0.1), cc.CallFunc:create(function()
                            local zorder = catImage1:getLocalZOrder()
                            zorder =  zorder - 2
                            if zorder < 3 then zorder = 3 end
                            catImage1:setLocalZOrder(zorder)
                        end)),cc.CallFunc:create(function()
                            catImage1:setVisible(false)
                        end))),cc.TargetedAction:create(catImage2,cc.Spawn:create(cc.FadeIn:create(0.1), cc.CallFunc:create(function()
                            local zorder = catImage2:getLocalZOrder()
                            zorder =  zorder - 2
                            if zorder < 3 then zorder = 3 end
                            catImage2:setLocalZOrder(zorder)
                        end))),cc.CallFunc:create(function()
                            catImage1:setLocalZOrder(3)
                            catImage2:setLocalZOrder(3)
                            catImage2:setVisible(false)
                            self.inAction = false
                            --自动下移命令
                            self:Dispatch("DirectorStory","next")
                        end),cc.RemoveSelf:create()))
            self.relationNode = colorView
        elseif self.animateId == 6 or self.animateId == 7 then
            --白色雾气6 黑色雾气是7
            local cloudName = "stage_woo"
            if self.animateId == 6 then
                --白色
                cloudName = ""
            end
            local catImage1 = display.newSprite(_res(string.format("arts/stage/ui/%s_1.png",cloudName )))
            display.commonUIParams(catImage1, {po = cc.p(display.width - 500,display.height * 0.42)})
            catImage1:setOpacity(0)
            colorView:addChild(catImage1, 10)

            local catImage2 = display.newSprite(_res(string.format("arts/stage/ui/%s_2.png",cloudName )))
            display.commonUIParams(catImage2, {po = cc.p(200, display.height *0.618)})
            catImage2:setOpacity(0)
            colorView:addChild(catImage2, 10)

            local catImage3 = display.newSprite(_res(string.format("arts/stage/ui/%s_3.png",cloudName )))
            display.commonUIParams(catImage3, {po = cc.p(display.width - 360,  display.height - catImage1:getContentSize().height * 0.7)})
            catImage3:setOpacity(0)
            colorView:addChild(catImage3, 10)
            colorView:runAction(cc.Sequence:create(cc.Spawn:create(
                        cc.TargetedAction:create(catImage1,cc.Sequence:create(cc.FadeIn:create(0.5), cc.MoveBy:create(2, cc.p(-30, 0)))),
                        cc.TargetedAction:create(catImage2,cc.Sequence:create(cc.FadeIn:create(0.5), cc.MoveBy:create(2, cc.p(50, 0)))),
                        cc.TargetedAction:create(catImage3,cc.Sequence:create(cc.FadeIn:create(0.5), cc.MoveBy:create(2, cc.p(-30, 0))))
                        ),
                        cc.CallFunc:create(function()
                            self.inAction = false
                            --自动下移命令
                            self:Dispatch("DirectorStory","next")
                        end), cc.RemoveSelf:create()))
            self.relationNode = colorView
        else
            self.inAction = false
        end
    end
end

--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function AnimPlayCommand:CanMoveNext( )
    return false
end

return AnimPlayCommand
