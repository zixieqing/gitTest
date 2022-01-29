---@class BlackGoldUpgradeSuccessPopUp
local BlackGoldUpgradeSuccessPopUp = class('BlackGoldUpgradeSuccessPopUp', function()
	local layout = CLayout:create(display.size)
	return layout
end)
local newNSprite = display.newNSprite
local newLayer = display.newLayer
local RES_DICT = {
	COMMON_WORDS_LEVELUP                 = _res('ui/common/common_words_levelup.png'),
	COMMON_REWARD_LIGHT                  = _res('ui/common/common_reward_light.png')
}
function BlackGoldUpgradeSuccessPopUp:ctor(params )
	params  = params or {}
	self.callback = params.callback 
	self:InitUI()
end

function BlackGoldUpgradeSuccessPopUp:InitUI()
	local view = display.newLayer(display.cx , display.cy , {ap = display.CENTER , size = display.size })
	self:addChild(view)
	local closeLayer = display.newLayer(display.cx , display.cy , {ap = display.CENTER , enable = true  , cb = function()
		if self.callback then
			self.callback()
		end
		self:stopAllActions()
		self:removeFromParent()
	end, color = cc.c4b(0,0,0,175)})
	view:addChild(closeLayer)

	local rightLayout = newLayer(display.cx , display.cy ,
			{ ap = display.CENTER, size = cc.size(500, 650)  })
	view:addChild(rightLayout)


	local swallowLayer = newLayer(500/2, 650/2 ,
			{ ap = display.CENTER , size = cc.size(500, 400), enable = true })
	rightLayout:addChild(swallowLayer)

	local lightImage = newNSprite(RES_DICT.COMMON_REWARD_LIGHT, 237, 411,
			{ ap = display.CENTER, tag = 243 })
	lightImage:setScale(1, 1)
	rightLayout:addChild(lightImage)

	local levelUpImage = newNSprite(RES_DICT.COMMON_WORDS_LEVELUP, 237, 572,
			{ ap = display.CENTER, tag = 244 })
	levelUpImage:setScale(1, 1)
	rightLayout:addChild(levelUpImage)
	rightLayout:setOpacity(0)

	local ligthAction = cc.Sequence:create(    -- 光的动画展示
		cc.DelayTime:create(0.1) ,
		cc.CallFunc:create( function ()
			lightImage:setVisible(true)
			lightImage:setScale(0.519)
			lightImage:setRotation(-0.8)
		end) ,
		cc.Spawn:create(cc.ScaleTo:create(0.1, 0.96) ,cc.RotateTo:create(0.1, 10)) ,
		cc.Spawn:create(cc.ScaleTo:create(1.8, 1) ,cc.RotateTo:create(1.8, 78)) ,
		cc.RotateTo:create(4.9 *1000, 180*1000)
	)
	lightImage:runAction(ligthAction)
	local height = 200
	local rewardPoint_Srtart =  cc.p(237 ,  display.height+94.6 - height)
	local rewardPoint_one = cc.p(237 ,  display.cy+300-35.5-50- height)
	local rewardPoint_Two = cc.p(237 ,  display.cy+300+24-50- height)
	local rewardPoint_Three = cc.p(237 ,  display.cy+300-15-50- height)
	local rewardPoint_Four = cc.p(237,  display.cy+300-15 -50- height )
	local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
			cc.DelayTime:create(0.4) ,cc.CallFunc:create(function ( )
				levelUpImage:setVisible(true)
				levelUpImage:setOpacity(0)
				levelUpImage:setPosition(rewardPoint_Srtart)
			end),
			cc.Spawn:create(cc.FadeIn:create(0.2),cc.MoveTo:create(0.2,rewardPoint_one)),
			cc.MoveTo:create(0.1,rewardPoint_Two) ,
			cc.MoveTo:create(0.1,rewardPoint_Three) ,
			cc.MoveTo:create(0.1,rewardPoint_Four)
	)
	levelUpImage:runAction(rewardSequnece)
	rightLayout:runAction(
		cc.Spawn:create(
			cc.Sequence:create(cc.DelayTime:create(0.5) ,cc.FadeIn:create(0.5))
		)
	)
end


return BlackGoldUpgradeSuccessPopUp
