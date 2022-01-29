
--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息视图
]]
---@class WaterBarRewardFormulaView
local WaterBarRewardFormulaView = class('WaterBarRewardFormulaView', function()
	return CLayout:create(display.size)
end)
function WaterBarRewardFormulaView:ctor(param)
	local param = param or {}
	self.drinkId = param.drinkId or 420001
	self.isClose = false
	self:InitUI()
end
function WaterBarRewardFormulaView:InitUI()
	local closeLayer = display.newLayer(display.cx , display.cy , { ap =display.CENTER ,
		color = cc.c4b(0,0,0,175), enable = true , cb = function()
			if self.isClose then
				self:stopAllActions()
				self:runAction(cc.RemoveSelf:create())
				self.isClose = false
			end
		end
	})
	self:addChild(closeLayer)
	local centerSize = cc.size(600, 600)
	local centerLayout = display.newLayer(display.cx, display.cy + 20  , { size =centerSize ,  ap = display.CENTER})
	self:addChild(centerLayout)
	local lightImage = display.newImageView(_res('ui/common/common_reward_light.png'), centerSize.width/2 ,centerSize.height/2)
	centerLayout:addChild(lightImage)
	--lightImage:setOpacity(0)
	local drinkConf = CONF.BAR.DRINK:GetValue(self.drinkId)
	local formulaImage = display.newImageView(CommonUtils.GetGoodsIconPathById(drinkConf.formulaId   , true) ,centerSize.width/2 , centerSize.height/2  )
	centerLayout:addChild(formulaImage)

	local wordImage = display.newImageView(_res('ui/common/common_words_congratulations.png') , centerSize.width/2 , centerSize.height /2 + 150)
	self:addChild(wordImage)
	wordImage:setVisible(false)

	local formulaName = display.newLabel(centerSize.width/2 , centerSize.height /2  - 150, {fontSize = 60, text = drinkConf.name })
	centerLayout:addChild(formulaName)
	formulaName:setOpacity(0)
	local star = drinkConf.star
	local starWidth = 80
	local starLayout = display.newLayer(centerSize.width/2 , centerSize.height /2 - 220 , { ap = display.CENTER , size = cc.size(starWidth * star ,starWidth  )})
	centerLayout:addChild(starLayout)
	centerLayout:setVisible(false)
	starLayout:setOpacity(0)
	for i =1 , star do
		local starImage = display.newImageView(_res('ui/common/common_star_l_ico.png'), starWidth * (i - 0.5 ) , starWidth/2 )
		starLayout:addChild(starImage)
		starImage:setScale(1.2)
	end
	local ligthAction = cc.Sequence:create(    -- 光的动画展示
		cc.DelayTime:create(0.1) ,
		cc.CallFunc:create( function ()
			lightImage:setVisible(true)
			lightImage:setScale(0.519)
			lightImage:setRotation(-0.8)
		end) ,
		cc.Spawn:create(cc.ScaleTo:create(0.1, 1.5) ,cc.RotateTo:create(0.1, 10)) ,
		cc.Spawn:create(cc.ScaleTo:create(1.8, 1.5) ,cc.RotateTo:create(1.8, 78)) ,
		cc.RotateTo:create(4.9 *1000, 180*1000)
	)
	lightImage:runAction(ligthAction)
	local formulaImageAction = cc.Sequence:create(
		cc.CallFunc:create(function ()
			centerLayout:setVisible(true)
			formulaImage:setScale(0.14)
		end ) ,
		cc.ScaleTo:create(0.2 , 1.4*0.6) , cc.ScaleTo:create(0.1,0.6),
		cc.CallFunc:create(function()
			self.isClose = true
		end)
 	)
	formulaImage:runAction(formulaImageAction) --菜谱UI动画展示

	local heightoff = 200
	local rewardPoint_Srtart =  cc.p(display.cx ,  display.height+94.6)
	local rewardPoint_one = cc.p(display.cx ,  display.cy+heightoff-35.5)
	local rewardPoint_Two = cc.p(display.cx ,  display.cy+heightoff+24)
	local rewardPoint_Three = cc.p(display.cx ,  display.cy+heightoff-15)
	local rewardPoint_Four = cc.p(display.cx ,  display.cy+heightoff-15)
	local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
		cc.DelayTime:create(0.2) ,cc.CallFunc:create(function ( )
			wordImage:setVisible(true)
			wordImage:setOpacity(0)
			wordImage:setPosition(rewardPoint_Srtart)
		end),
		cc.Spawn:create(cc.FadeIn:create(0.2),cc.MoveTo:create(0.2,rewardPoint_one)),
		cc.Spawn:create(
			cc.Sequence:create(
				cc.MoveTo:create(0.1,rewardPoint_Two) ,
				cc.MoveTo:create(0.1,rewardPoint_Three) ,
				cc.MoveTo:create(0.1,rewardPoint_Four)
			),
			cc.TargetedAction:create(formulaName, cc.FadeIn:create(0.3)),
			cc.TargetedAction:create(starLayout ,  cc.FadeIn:create(0.3))
		)
	)
	wordImage:runAction(rewardSequnece)
end

return WaterBarRewardFormulaView
