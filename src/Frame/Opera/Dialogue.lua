--[[
--剧情中对白的显示层
--]]
local Dialogue = class('Dialogue', function()
    local tips = CLayout:create(display.size)
    tips.name = 'Dialogue'
    tips:enableNodeEvents()
    return tips
end)

local TAG_BG = 433

local CreateMsgView = function (  )
	local view = CLayout:create(display.size)
	-- local transparentBg = display.newImageView('ui/common/story_tranparent_bg.png',display.cx,display.cy,{
    --     scale9 = true,size = display.size,enable = true,tag = TAG_BG
    -- })
    -- view:addChild(transparentBg)
    --创建对白角色名称
    local nameLabel = display.newLabel(100,500,{fontSize = 26,color = 'ffffff',text = ''})
    view:addChild(nameLabel,2)

    local contentLabel = display.newLabel(100,200,{fontSize = 22,color = '6c6c6c',text = ''})
    contentLabel:setAnchorPoint(display.LEFT_CENTER)
    view:addChild(contentLabel,3)
    contentLabel:setAlignment(cc.TEXT_ALIGNMENT_LEFT)
    --对白内容
	return {
		view = view,
		-- transparentBg = transparentBg,
		nameLabel = nameLabel,
		contentLabel = contentLabel,
	}
end

function Dialogue:ctor( ... )
	local arg = unpack( {...})
	self.isTyping = false --是否正在打字机的过程中
	self.isDisable = false --是否背景点击时按钮处于禁用状态
	self.storyCmd = arg.command
	-- self.callback = arg.cb --当前一句对白执行完成后再行下一句对白的回调
	self.viewData = CreateMsgView()
	display.commonUIParams(self.viewData.view,{po = display.center})
	self:addChild(self.viewData.view)

	-- --添加事件
	-- self.viewData.transparentBg:setOnClickScriptHandler(handler(self,self.ShowFullStory))
end

--[[
--显示全部的文字内容
--]]
function Dialogue:ShowFullStory( )
	if not self.isDisable then
		self.isDisable = true --禁用
		if self.isTyping then
			self:SetTypeAction(false)
			--每句对白后是否延时时间
			if self.storyCmd.delay > 0 then
				self:performWithDelay(function ( delta )
					--延时delay才可点击切换到下一个对白状态
					self.isDisable = false
				end, self.storyCmd.delay)
			end
		else
			--延时后的再次点击处理
			self.isDisable = true
			--切换到下一个状态
			self.storyCmd:Dispatch("DirectorStory","next")
		end
	end
end


function Dialogue:SetTypeAction( isTyping )
	self.isTyping = isTyping --设置是否正在typing
	if self.isTyping == false then
		--显示所有的文字内容
		--打字机正在跑
		self.viewData.contentLabel:stopAllActions()
		self.viewData.contentLabel:setString(self.storyCmd.content)
	else
		--执行打字机的动作
		if self.viewData.contentLabel then
			self.viewData.contentLabel:setString(self.storyCmd.content)
			self.viewData.contentLabel:setVisible(false)
			local duration = string.utf8len(self.storyCmd.content) * 0.06
	        local writer = TypewriterAction:create(duration)
	        self.viewData.contentLabel:runAction(cc.Sequence:create(writer,cc.CallFunc:create(function ( )
		        --每句对白后是否延时时间
				if self.storyCmd.delay > 0 then
					self:performWithDelay(function ( delta )
						--延时delay才可点击切换到下一个对白状态
						self.isTyping  = false
						self.isDisable = false
					end, self.storyCmd.delay)
				end
	        end)))
	    end
	end
end

function Dialogue:onEnter(  )
	--页面创建时显示
	self:SetTypeAction(true) --启动打字机动作
end


return Dialogue