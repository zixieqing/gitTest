--[[
	宝石抽取奖励UI
--]]
local GameScene = require( "Frame.GameScene" )

local JewelCatcherRewardsView = class('JewelCatcherRewardsView', GameScene)

local artiMgr = AppFacade.GetInstance():GetManager("ArtifactManager")

local function GetFullPath( imgName )
	return _res('ui/artifact/' .. imgName)
end

function JewelCatcherRewardsView:ctor( ... )
    local args = unpack({ ... })
    self.blingLimit = args.blingLimit -- 抽宝石保底显示闪光
	--创建页面
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 175))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
	local function CreateView( ... )
		local view = display.newLayer(display.cx, display.height, {size = display.size, ap = display.CENTER_TOP})
        self:addChild(view)
        
        local rewardImage = display.newImageView(_res('ui/common/common_words_congratulations.png'),display.cx, display.height+60)
        view:addChild(rewardImage,2)
        rewardImage:setVisible(false)

        local light = display.newImageView(_res('ui/common/common_reward_light.png'), display.cx , display.cy)
        view:addChild(light)

        local newIcon = display.newImageView( _res('ui/home/capsule/draw_card_ico_new.png'), display.cx , display.cy)
        view:addChild(newIcon)

        local jewelNameBg = display.newImageView(_res('ui/home/kitchen/kitchen_foods_name_delicate.png'), display.cx, display.cy - 180)
        view:addChild(jewelNameBg)

        local jewelName = display.newLabel(display.cx, display.cy - 180, fontWithColor('1' ,{fontSize = 26 ,text =  '',color = "ffdf89" }))
        view:addChild(jewelName)

        local makeSureBtn = display.newButton(display.cx,display.cy - 345 , { n = _res("ui/common/common_btn_orange.png") ,enable = true} )
        display.commonLabelParams(makeSureBtn ,fontWithColor('14', { text = __('确定')}))
        view:addChild(makeSureBtn,2)
        makeSureBtn:setVisible(false)

		return {
            view 			= view,
            light           = light,
            newIcon         = newIcon,
            makeSureBtn     = makeSureBtn,
            rewardImage     = rewardImage,
            jewelName       = jewelName,
		}
	end
	xTry(function()
		self.viewData = CreateView()
    end, __G__TRACKBACK__)
end

function JewelCatcherRewardsView:updateData(param)
    self:updataView(param)
    self:runActionType()
end

function JewelCatcherRewardsView:updataView( param )
    if checktable(param) then
        if checktable(param[1]) then
            local iconpath = CommonUtils.GetGoodsIconPathById(param[1].goodsId, true)
            self.viewData.newIcon:setTexture(iconpath)

            -- 抽到保底
            if self.blingLimit then
                local gemstone = artiMgr:GetConfigDataByName(artiMgr:GetConfigParse().TYPE.GEM_STONE)
                local grade = gemstone[tostring(param[1].goodsId)].grade
                for k,v in pairs(self.blingLimit) do
                    if checkint(v) == checkint(grade) then
                        if not self.viewData.particle then
                            local particle = cc.ParticleSystemQuad:create('effects/artifact/xingxing.plist')
                            particle:setAutoRemoveOnFinish(true)
                            particle:setPosition(cc.p(display.cx, display.cy + 20))
                            self.viewData.view:addChild(particle,10)
                            self.viewData.particle = particle
                            particle:setVisible(false)
                    
                            -- local luckySpine = sp.SkeletonAnimation:create(
                            --     'effects/artifact/biaoqian.json',
                            --     'effects/artifact/biaoqian.atlas',
                            -- 1)
                            -- luckySpine:setPosition(cc.p(display.cx, display.cy - 20))
                            -- self.viewData.view:addChild(luckySpine)
                            -- luckySpine:setAnimation(0, 'idle2', true)
                            -- luckySpine:update(0)
                            -- luckySpine:setToSetupPose()
                            -- luckySpine:setVisible(false)
                            -- self.viewData.luckySpine = luckySpine
                        end
                        break
                    end
                end
            end

            local gemstone = artiMgr:GetConfigDataByName(artiMgr:GetConfigParse().TYPE.GEM_STONE)
            self.viewData.jewelName:setString(gemstone[tostring(param[1].goodsId)].name)
        end
    end
end

function JewelCatcherRewardsView:runActionType(  )
    self.viewData.newIcon:runAction(cc.Sequence:create(
        cc.CallFunc:create(function ()
            self.viewData.newIcon:setScale(0.14)
        end ) ,
        cc.ScaleTo:create(0.2 , 1.12) , cc.ScaleTo:create(0.1,0.7 * 0.85)
    )) 

    if self.viewData.particle then
        self:CreateCot(display.center, 'chouka_qian')
        -- self:CreateCot(display.center, 'chouka_hou')
        
        self.viewData.particle:setOpacity(0)
        self.viewData.particle:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.3) ,
            cc.Show:create(),
            cc.FadeIn:create(0.3)
        ))
    end
 
    local ligthAction = cc.Sequence:create(    -- 光的动画展示
        cc.DelayTime:create(0.1) ,
        cc.CallFunc:create( function ()
            self.viewData.light:setVisible(true)
            self.viewData.light:setScale(0.519)
            self.viewData.light:setRotation(-0.8)
        end) ,
        cc.Spawn:create(cc.ScaleTo:create(0.1, 0.96) ,cc.RotateTo:create(0.1, 10)) ,
        cc.Spawn:create(cc.ScaleTo:create(1.8, 1.3) ,cc.RotateTo:create(1.8, 78)) ,
        cc.CallFunc:create( function ()
            self.viewData.light:runAction(cc.RepeatForever:create(cc.RotateBy:create(4.9, 180)))
        end)
    )
    self.viewData.light:runAction(ligthAction)

    -- 恭喜获得
    local rewardPoint_Srtart =  cc.p(display.cx ,  display.cy+330)
    local rewardPoint_one = cc.p(display.cx ,   display.cy+210-35.5)
    local rewardPoint_Two = cc.p(display.cx ,   display.cy+210+24)
    local rewardPoint_Three = cc.p(display.cx , display.cy+210-15)
    local rewardPoint_Four = cc.p(display.cx ,  display.cy+210)
    local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
        cc.DelayTime:create(0.2) ,cc.CallFunc:create(function ( )
            self.viewData.rewardImage:setVisible(true)
            self.viewData.rewardImage:setOpacity(0)
            self.viewData.rewardImage:setPosition(rewardPoint_Srtart)
        end),
         cc.Spawn:create(cc.FadeIn:create(0.2),cc.MoveTo:create(0.2,rewardPoint_one)),
         cc.MoveTo:create(0.1,rewardPoint_Two) ,
         cc.MoveTo:create(0.1,rewardPoint_Three) ,
         cc.MoveTo:create(0.1,rewardPoint_Four)
         )
    self.viewData.rewardImage:runAction(rewardSequnece)

    local btnAction = cc.Sequence:create(
        cc.Hide:create(),
        cc.DelayTime:create(10/30),
        cc.CallFunc:create(function ()
            self.viewData.makeSureBtn:setVisible(true)
            self.viewData.makeSureBtn:setOpacity(0)
        end),
        cc.Spawn:create(cc.MoveBy:create(7/30, cc.p(0 ,60)) ,cc.FadeIn:create(7/30) ) ,
        cc.CallFunc:create(function (  )
            self.viewData.makeSureBtn:setOnClickScriptHandler(function (sender)
                PlayAudioByClickNormal()
                self:stopAllActions()
                self:runAction(cc.RemoveSelf:create())
            end)
        end)
    )
    self.viewData.makeSureBtn:runAction(btnAction)
end

-- 添加点击的响应动画
function JewelCatcherRewardsView:CreateCot( position, type )

	local cotAnimation = sp.SkeletonAnimation:create(
   		'effects/capsule/capsule.json',
   		'effects/capsule/capsule.atlas',
   		1)
   	-- cotAnimation:update(0)
   	-- cotAnimation:setToSetupPose()
   	cotAnimation:setAnimation(0, type, false)
   	cotAnimation:setPosition(position)
   	self.viewData.view:addChild(cotAnimation, 10)
   	-- 结束后移除
   	cotAnimation:registerSpineEventHandler(function (event)
   		cotAnimation:runAction(cc.RemoveSelf:create())
   	end, sp.EventType.ANIMATION_END)
end

return JewelCatcherRewardsView