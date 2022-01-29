local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local OpenBlackCommand = Command:New()

OpenBlackCommand.NAME = "OpenBlackCommand"


--[[
* content
--]]
function OpenBlackCommand:New(params)
	local this = {}
	setmetatable( this, {__index = OpenBlackCommand} )
	this.renationNode = nil
	this.content = (params.content or '') --初始显示的内容
	this.inAction = true
	local faceData = string.split2(checkstr(params.face), ',')
	this.fontColor = faceData[1] or '#FFFFFF'
	this.fontSize  = faceData[2] or 34
	this.bgColor   = faceData[3] or '#000000'
	this.bgAlpha   = faceData[4] or 100
	return this
end

--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function OpenBlackCommand:CanMoveNext( )
	return false 
end

--[[
--执行方法的虚方法
--]]
function OpenBlackCommand:Execute( )
	--执行方法的虚方法
	local director = Director.GetInstance( "Director" )
	local stage = director:GetStage()
	if stage then
		--首先移除消息层
		stage:removeChildByTag(Director.ZorderTAG.Z_OPENING_LAYER)
		local CreateMsgView = function (  )
			local view = CLayout:create(display.size)
			view:setBackgroundColor(ccc3FromInt(self.bgColor))
			view:setBackgroundOpacity(255/100*checkint(self.bgAlpha))

			local contentLabel = display.newLabel(display.cx, display.cy + 40,{
				ttf = true, font = TTF_GAME_FONT, fontSize = 34,color = 'ffffff',text = "",
				w = display.width - 500})
			display.commonUIParams(contentLabel, {ap = cc.p(0.5, 1.0)})
			view:addChild(contentLabel,3)
			contentLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
			
			return {
				view = view,
				contentLabel = contentLabel,
			}
		end
		--再添加消息层
		self.viewData = CreateMsgView()
		display.commonUIParams(self.viewData.view, {po = display.center})
		stage:addChild(self.viewData.view, Director.ZorderTAG.Z_OPENING_LAYER,Director.ZorderTAG.Z_OPENING_LAYER)

		if string.find(tostring(self.content), '_name_') then
			self.content = string.fmt(self.content, {_name_ = tostring(app.gameMgr:GetUserInfo().playerName)})
		end
		self.viewData.contentLabel:setString(self.content)
		self.viewData.contentLabel:setOpacity(0)
		-- local duration = string.utf8len(self.content) * 0.06
		-- local writer = TypewriterAction:create(duration)
		self.viewData.contentLabel:runAction(cc.Sequence:create(cc.FadeIn:create(2),cc.DelayTime:create(0.2),cc.CallFunc:create(function ( )
			--每句对白后是否延时时间
			self.inAction = false
		end)))
	end
end

function OpenBlackCommand:ExecuteAfter( )
	--移除自身
	local director = Director.GetInstance( "Director" )
	local stage = director:GetStage()
	if stage then
		local node = stage:getChildByTag(Director.ZorderTAG.Z_OPENING_LAYER)
		if node then
			node:runAction(cc.Sequence:create(cc.FadeIn:create(0.1),cc.CallFunc:create(function()
				director:MoveNext()
			end),cc.RemoveSelf:create()))
		end
	end
end
return OpenBlackCommand 
