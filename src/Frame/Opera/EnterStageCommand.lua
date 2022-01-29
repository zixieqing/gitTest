local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local EnterStageCommand = Command:New()

EnterStageCommand.NAME = "EnterStageCommand"


--[[--*
* 对一个角色进行透明度的逻辑处理
* @param roleId 执行动作的角色id
* @param x x坐标
* @param y y坐标
* @param faceId 对应的表情id
--]]
function EnterStageCommand:New(roleId, x, y,faceId, flip)
    local this = {}
    setmetatable( this, {__index = EnterStageCommand} )
    this.roleId = roleId
    this.relationNode = nil
    x = (x or display.width * 0.75)
    y = (y or display.height * 2.2)
    this.pos = cc.p(x, y)
    this.inAction = true
    this.iscard = true
    this.faceId = (faceId or 1)
    this.flip = checkbool(flip)
    return this
end

--[[
--直到一个人物进入完成后才能够下
--一步的操作
--]]
function EnterStageCommand:CanMoveNext()
    return false
end
--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function EnterStageCommand:Execute( )
    --执行方法的虚方法
    --添加指定的角色图片资源
    local director = Director.GetInstance()
    local stage = director:GetStage()
    stage:removeChildByTag(Director.ZorderTAG.Z_ROLE_DESC_LAYER)
    local colorView = CColorView:create(cc.c4b(255,255,255,255))
    colorView:setContentSize(display.size)
    colorView:setPosition(display.center)
    stage:addChild(colorView, Director.ZorderTAG.Z_ROLE_DESC_LAYER,Director.ZorderTAG.Z_ROLE_DESC_LAYER)

    local cardId = self.roleId
    local roleName = ""

    if string.match(self.roleId, '^%d+') then
        --数字表示是卡牌
        self.iscard = true
        -- 突破后的立绘不存在 使用默认立绘
        cardId = checkint(self.roleId)
        roleName = tostring(CardUtils.GetCardConfig(cardId).name)
    else
        self.iscard = false
        --角色人物
        local rInfo = app.gameMgr:GetRoleInfo(self.roleId)
        if rInfo then
            roleName = rInfo.roleName
        end
    end

    local animateNode = CLayout:create(display.size)
    display.commonUIParams(animateNode, { po = display.center})
    colorView:addChild(animateNode)

    local bg = display.newImageView(_res("arts/stage/bg/main_dial_bg_introduce.jpg"), display.cx, display.cy, {isFull = true})
    animateNode:addChild(bg)

    local lwidth = 200
    local roleNode = CLayout:create()
    local cardView = CommonUtils.GetRoleNodeById(self.roleId, checkint(self.faceId), checkbool(self.flip))
    lwidth = cardView:getContentSize().width
    roleNode:setContentSize(cc.size(lwidth,display.height))
    display.commonUIParams(cardView, {ap = display.CENTER_TOP, po = cc.p(lwidth * 0.5, display.height - 80)})
    cardView:setTag(888)
    roleNode:addChild(cardView)
    if self.iscard then
        CommonUtils.FixAvatarLocation(cardView, cardId)
    else
        roleNode:setScale(1.6)
    end
    --开始执行动画逻辑
    -- roleNode:setBackgroundColor(cc.c4b(100,100,100))
    roleNode:setPosition(self.pos)
    animateNode:addChild(roleNode,2)
    animateNode:setOpacity(0)

    --相关的名称与描述的UI处理
    -- local actions = {}
    -- table.insert( actions, TreeFadeIn:create(1.5))
    -- table.insert( actions, cc.DelayTime:create(1.2))
    -- table.insert( actions, TreeFadeOut:create(1))
    -- table.insert( actions, cc.MoveTo:create(0.2, cc.p(400, display.height * 0.7)) )
    -- table.insert( actions, TreeFadeIn:create(1.5) )
    -- table.insert( actions, cc.DelayTime:create(1.2))
    -- table.insert( actions, TreeFadeOut:create(1) )
    -- table.insert( actions, cc.MoveTo:create(0.1,cc.p(display.cx,display.height)))
    -- table.insert( actions, TreeFadeIn:create(1))
    -- table.insert( actions, cc.EaseIn:create(cc.MoveTo:create(1, cc.p(display.cx, 200)), 0.3))
    -- -- table.insert( actions, cc.Spawn:create(TreeFadeIn:create(3.4), cc.MoveTo:create(3.4, cc.p(display.cx, 200))) )
    -- table.insert( actions, cc.CallFunc:create(function()
    --     self.inAction = false
    --     self:Dispatch("DirectorStory","next")
    -- end) )
    colorView:runAction(cc.Sequence:create(cc.TargetedAction:create(animateNode, cc.Sequence:create(
        TreeFadeIn:create(1),cc.DelayTime:create(1),TreeFadeOut:create(0.5),
        cc.TargetedAction:create(roleNode,cc.MoveTo:create(0.2, cc.p(400, display.height)))
    )), cc.TargetedAction:create(animateNode, cc.Sequence:create(
        TreeFadeIn:create(1), cc.DelayTime:create(1), TreeFadeOut:create(0.5),
        cc.MoveTo:create(0.1,cc.p(display.cx,display.height)),
        cc.TargetedAction:create(roleNode,cc.Sequence:create(cc.ScaleTo:create(0.1,1.0),cc.MoveTo:create(0.1,cc.p(display.cx,display.cy))))
    )),cc.TargetedAction:create(animateNode, cc.Sequence:create(
       cc.Spawn:create(TreeFadeIn:create(0.8),cc.EaseOut:create(cc.MoveTo:create(1.5, cc.p(display.cx, display.cy)), 1.5)),
       cc.DelayTime:create(0.5),
    cc.CallFunc:create(function()
            self:ExecuteAfter()
            -- self.inAction = false
            -- self:Dispatch("DirectorStory","next")
    end)))))
    -- animateNode:runAction(cc.Sequence:create(actions))
end

function EnterStageCommand:ExecuteAfter( )
	--移除自身
	local director = Director.GetInstance( "Director" )
	local stage = director:GetStage()
	if stage then
		local node = stage:getChildByTag(Director.ZorderTAG.Z_ROLE_DESC_LAYER)
		if node then
			node:runAction(cc.Sequence:create(cc.DelayTime:create(0.1),cc.CallFunc:create(function()
				director:MoveNext()
			end),cc.RemoveSelf:create()))
		end
	end
end

return EnterStageCommand
