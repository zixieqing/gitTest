--[[
	宝石抽取奖励UI
--]]
local GameScene = require( "Frame.GameScene" )

local JewelCatcherTenRewardsView = class('JewelCatcherTenRewardsView', GameScene)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local artiMgr = AppFacade.GetInstance():GetManager("ArtifactManager")

local function GetFullPath( imgName )
	return _res('ui/artifact/' .. imgName)
end

function JewelCatcherTenRewardsView:ctor( ... )
    local args = unpack({ ... })
    self.args = args
    self.aniEnd = 0
    self.totalAni = 0
    self.blingLimit = args.blingLimit -- 抽宝石保底显示闪光
	--创建页面
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 175))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function (  )
        uiMgr:AddDialog('common.RewardPopup', self.args)
        self:runAction(cc.RemoveSelf:create())
    end)
	local function CreateView( ... )
		local view = display.newLayer(display.cx, display.height, {size = display.size, ap = display.CENTER_TOP})
        self:addChild(view)
        
		return {
            view 			= view,
		}
	end
	xTry(function()
		self.viewData = CreateView()
    end, __G__TRACKBACK__)
end

local jumpConf = {
    {start = cc.p(display.cx + (20),    display.cy - 100 + (-660)),  stop = cc.p(display.cx + (980),  display.cy + (-320)), height = 100 + 800},
    {start = cc.p(display.cx + (50),    display.cy - 100 + (-680)),  stop = cc.p(display.cx + (-980), display.cy + (-530)), height = 100 + 1000},
    {start = cc.p(display.cx + (700),   display.cy - 100 + (-650)),  stop = cc.p(display.cx + (-350), display.cy + (-660)), height = 100 + 700},
    {start = cc.p(display.cx + (-480),  display.cy - 100 + (-600)),  stop = cc.p(display.cx + (450),  display.cy + (-600)), height = 100 + 500},
    {start = cc.p(display.cx + (-900),  display.cy - 100 + (-310)),  stop = cc.p(display.cx + (-170), display.cy + (-580)), height = 100 + 500},
    {start = cc.p(display.cx + (-580),  display.cy - 100 + (-620)),  stop = cc.p(display.cx + (30),   display.cy + (-600)), height = 100 + 750},
    {start = cc.p(display.cx + (-320),  display.cy - 100 + (-620)),  stop = cc.p(display.cx + (-880), display.cy + (-150)), height = 100 + 950},
    {start = cc.p(display.cx + (-200),  display.cy - 100 + (-600)),  stop = cc.p(display.cx + (860),  display.cy + (-610)), height = 100 + 580},
    {start = cc.p(display.cx + (-460),  display.cy - 100 + (-600)),  stop = cc.p(display.cx + (880),  display.cy + (150)),  height = 100 + 1200},
    {start = cc.p(display.cx + (200),   display.cy - 100 + (-580)),  stop = cc.p(display.cx + (210),  display.cy + (-580)), height = 100 + 840},
}

function JewelCatcherTenRewardsView:updateData(param)
    if checktable(param) then
        local cnt = 0
        local gemstone = artiMgr:GetConfigDataByName(artiMgr:GetConfigParse().TYPE.GEM_STONE)
        for k,v in pairs(param) do
            for i=1,v.num do
                local iconpath = CommonUtils.GetGoodsIconPathById(v.goodsId, true)
                local newIcon = display.newImageView( iconpath, jumpConf[cnt + 1].start.x, jumpConf[cnt + 1].start.y)
                self.viewData.view:addChild(newIcon, 2)
                newIcon:setScale(0.7)

            -- 抽到保底
                if self.blingLimit then
                    local grade = gemstone[tostring(v.goodsId)].grade
                    for k,v in pairs(self.blingLimit) do
                        if checkint(v) == checkint(grade) then
                            -- local luckySpine = sp.SkeletonAnimation:create(
                            --     'effects/artifact/biaoqian.json',
                            --     'effects/artifact/biaoqian.atlas',
                            -- 1)
                            -- luckySpine:setPosition(cc.p(newIcon:getContentSize().width / 2, newIcon:getContentSize().height / 2))
                            -- newIcon:addChild(luckySpine)
                            -- luckySpine:setAnimation(0, 'idle2', true)
                            -- luckySpine:update(0)
                            -- luckySpine:setToSetupPose()

                            local particle = cc.ParticleSystemQuad:create('effects/artifact/xingxing.plist')
                            particle:setAutoRemoveOnFinish(true)
                            particle:setPosition(cc.p(newIcon:getContentSize().width / 2, newIcon:getContentSize().height / 2))
                            newIcon:addChild(particle,10)

                            local streakView = cc.MotionStreak:create(0.3, 20, 200, cc.c3b(250,250,250), _res('effects/artifact/rainbow'))
                            streakView:setPosition(cc.p(jumpConf[cnt + 1].start.x, jumpConf[cnt + 1].start.y))
                            self.viewData.view:addChild(streakView)

                            streakView:runAction(cc.Sequence:create(
                                cc.DelayTime:create(cnt * 0.2),
                                cc.JumpTo:create(1, cc.p(jumpConf[cnt + 1].stop.x, jumpConf[cnt + 1].stop.y), jumpConf[cnt + 1].height, 1),
                                cc.RemoveSelf:create())
                            )

                            break
                        end
                    end
                end

                newIcon:runAction(cc.Sequence:create(
                    cc.DelayTime:create(cnt * 0.2),
                    cc.JumpTo:create(1, cc.p(jumpConf[cnt + 1].stop.x, jumpConf[cnt + 1].stop.y), jumpConf[cnt + 1].height, 1),
                    cc.RemoveSelf:create(),
                    cc.CallFunc:create(function (  )
                        self:JumpAniEnd()
                    end)
                ))
                cnt = cnt + 1
            end
        end
        self.totalAni = cnt
    end
end

function JewelCatcherTenRewardsView:JumpAniEnd(  )
    self.aniEnd = self.aniEnd + 1
    if self.aniEnd >= self.totalAni then
        self.aniEnd = 0
        self.totalAni = 0
        uiMgr:AddDialog('common.RewardPopup', self.args)
        self:removeFromParent()
    end
end

return JewelCatcherTenRewardsView