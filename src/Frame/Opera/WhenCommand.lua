local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local WhenCommand = Command:New()

WhenCommand.NAME = "WhenCommand"


--[[
* content
--]]
function WhenCommand:New(params)
	local this = {}
	setmetatable( this, {__index = WhenCommand} )
	this.when = (params.when or '') --初始显示的内容
	this.address = (params.address or '') --初始显示的内容
	this.inAction = true
	return this
end

--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function WhenCommand:CanMoveNext( )
	return false
end

--[[
--执行方法的虚方法
--]]
function WhenCommand:Execute( )
	--执行方法的虚方法
	local director = Director.GetInstance( "Director" )
	local stage = director:GetStage()
	if stage then
		--首先移除消息层
		if stage:getChildByTag(Director.ZorderTAG.Z_WHEN_LAYER) then
			stage:removeChildByTag(Director.ZorderTAG.Z_WHEN_LAYER)
		end
		local CreateMsgView = function (  )
			local view = CLayout:create(display.size)
			view:setBackgroundColor(cc.c4b(100,100,100,0))
			--bg
			local background = display.newSprite(_res("arts/stage/ui/story_bg_kaichang.png"),display.cx, display.cy, {scale9 = true , size =cc.size(1000, 225)})
			view:addChild(background,1)
			local lsize = background:getContentSize()
			view:setContentSize(cc.size(display.width, lsize.height))
			display.commonUIParams(background, {po = cc.p( display.cx,lsize.height * 0.5)})
			background:setCascadeOpacityEnabled(true)
			local bg2 = display.newSprite(_res("arts/stage/ui/story_bg_mengban_kaichang_font.png"),display.cx, lsize.height * 0.5)
			view:addChild(bg2)

            local lfont = TTF_GAME_FONT
            -- if i18n.getLang() ~= 'zh-tw' then
                -- lfont = TTF_GAME_FONT
            -- end
			local whenLabel = display.newLabel(lsize.width * 0.5, 124,{
				ttf = true, font = lfont, fontSize = 32,color = 'ffffff',text = self.when,
				w = lsize.width - 20, h = 100})
			display.commonUIParams(whenLabel, {ap = cc.p(0.5, 0.5)})
			background:addChild(whenLabel,3)
			whenLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
			whenLabel:setDimensions(lsize.width - 20, 100)

			local addressLabel = display.newLabel(lsize.width * 0.5, 54,{
				ttf = true, font = lfont, fontSize = 24,color = 'ffffff',text = self.address,
				w = lsize.width - 20, h = 100})
			display.commonUIParams(addressLabel, {ap = cc.p(0.5, 0.5)})
			background:addChild(addressLabel,3)
			addressLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
			addressLabel:setDimensions(lsize.width - 20, 100)

			return {
				view = view,
				background = background,
			}
		end
		--再添加消息层
		self.viewData = CreateMsgView()
		display.commonUIParams(self.viewData.view, {po = display.center})
		stage:addChild(self.viewData.view, Director.ZorderTAG.Z_WHEN_LAYER,Director.ZorderTAG.Z_WHEN_LAYER)
		self.viewData.background:setOpacity(0)
		self.viewData.background:runAction(cc.Sequence:create(TreeFadeIn:create(0.6),cc.DelayTime:create(0.1),cc.CallFunc:create(function ( )
			--每句对白后是否延时时间
			self.inAction = false
		end)))
	end
end

function WhenCommand:ExecuteAfter( )
	--移除自身
	local director = Director.GetInstance( "Director" )
	local stage = director:GetStage()
	if stage then
		local node = stage:getChildByTag(Director.ZorderTAG.Z_WHEN_LAYER)
		if node then
			node:runAction(cc.Sequence:create(cc.FadeOut:create(0.1),cc.CallFunc:create(function()
				director:MoveNext()
			end),cc.RemoveSelf:create()))
		end
	end
end
return WhenCommand
