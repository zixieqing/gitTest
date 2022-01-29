local GuideNode = class('GuideNode', function ()
	local node = CLayout:create(display.size)
	node.name = 'common.GuideNode'
	node:enableNodeEvents()
	return node
end)

local STUDIES_TEXT_EXPLAIN_CONFS = CommonUtils.GetConfigAllMess('studiesTextExplain', 'common') or {}

local pageSize = cc.size(1100, 622)
local configs = {
    ['card'] = {
        pageCount  = 3,
        moduleId   = MODULE_DATA[tostring(RemindTag.CARDS)]
    },
    ['explore'] = {
        pageCount  = 3,
        moduleId   = MODULE_DATA[tostring(RemindTag.EXPLORE_SYSTEM)]
    },
    ['pvp'] = {
        pageCount  = 3,
        moduleId   = MODULE_DATA[tostring(RemindTag.PVC)],
    },
    ['takeout'] = {
        pageCount  = 3,
        moduleId   = MODULE_DATA[tostring(RemindTag.ORDER)],
    },
    ['tower'] = {
        pageCount  = 5,
        moduleId   = MODULE_DATA[tostring(RemindTag.TOWER)],
    },
    ['recipe'] = {
        pageCount  = 3,
        moduleId   = MODULE_DATA[tostring(RemindTag.RESEARCH)],
    },
    ['ttGame'] = {
        pageCount  = 3,
        moduleId   = MODULE_DATA[tostring(RemindTag.TTGAME)],
    },
    ['catModule'] = {
        pageCount = 17,
        moduleId = MODULE_DATA[tostring(RemindTag.CAT_HOUSE)],
    },
}

-- local CONFIGS = {
--     [tostring(MODULE_DATA(tostring(RemindTag.RESEARCH)))] = {
--         {id = 1, img1 = _res('guide/guide_cook_image_p1_1.png'), img2 = _res('guide/guide_cook_image_p1_2.png')},
--         {id = 2, img1 = _res('guide/guide_cood_image_p2.png')},
--         {id = 3, img1 = _res('guide/guide_cood_image_p3.png')},
--     }
-- }

local shareUserDefault = cc.UserDefault:getInstance()
local deltaTime = 0.35
local offsetX = pageSize.width * 0.5

--[[
--引导节点的显示的逻辑
--tmodule --必需传一个所出引导的某个模块的逻辑
--]]
function GuideNode:ctor(...)
    local args = unpack({...})
    self.isInAction = false--正在操作中的逻辑
    self.index = 1 --初始看第一个页面图
    self:setName("common.GuideNode")
    local targetModule = args.tmodule or 'tower'
    local isFirstGuide = isGuideOpened(targetModule)
    self.moudleId = configs[tostring(targetModule)].moduleId
    self.curModuleConf = STUDIES_TEXT_EXPLAIN_CONFS[tostring(self.moudleId)] or {}
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 120))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 0.5))
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self:setPosition(args.po or display.center)

    local confCount = #configs[tostring(targetModule)]
    self.isNewGuide = confCount == 0
    local len = 0 --table.nums(configs[tostring(targetModule)])
    if self.isNewGuide then
        len = configs[tostring(targetModule)].pageCount
    else
        len = confCount
    end

    local function CreateGuideView()
        -- 地图page view
        local view = CLayout:create(pageSize)
        -- view:setBackgroundColor(cc.c4b(100,100,100,100))
        local bg = display.newImageView(_res("ui/home/story/task_bg.png"), offsetX, pageSize.height* 0.5 - 22)
        view:addChild(bg,2)
        local closeBtn = display.newButton(pageSize.width, pageSize.height, {n = _res('ui/home/story/task_btn_quit.png')})
        display.commonUIParams(closeBtn, {ap = display.RIGHT_TOP,po = cc.p(display.cx + pageSize.width * 0.5 + 36, display.cy + pageSize.height * 0.5 - 32)})
        self:addChild(closeBtn, 1)
        
        local preImageView = nil
        local nextImageView = nil
        local preView = nil
        local nextView = nil
        if self.isNewGuide then
            preView = require('Game.views.guide.GuideView').new({moudleId = self.moudleId})
            display.commonUIParams(preView, {po = cc.p(pageSize.width * 0.5, pageSize.height * 0.5)})
            view:addChild(preView, 5)
            preView:setCascadeOpacityEnabled(true)

            nextView = require('Game.views.guide.GuideView').new({moudleId = self.moudleId})
            display.commonUIParams(nextView, {po = cc.p(pageSize.width * 0.5, pageSize.height * 0.5)})
            nextView:setOpacity(0)
            view:addChild(nextView, 5)
            nextView:setCascadeOpacityEnabled(true)
        else
        
            preImageView = display.newImageView(_res('guide/guide_tower_p5'), 0,0)
            display.commonUIParams(preImageView, {po = cc.p(pageSize.width * 0.5, pageSize.height * 0.5)})
            view:addChild(preImageView, 5)
    
            nextImageView = display.newImageView(_res('guide/guide_tower_p5'), 0,0)
            display.commonUIParams(nextImageView, {po = cc.p(display.width, pageSize.height * 0.5)})
            nextImageView:setOpacity(0)
            view:addChild(nextImageView, 5)
        end

        -- 翻页按钮
        local prevBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png')})
        prevBtn:setScaleX(-1)
        display.commonUIParams(prevBtn, {po = cc.p(display.cx - 500 - prevBtn:getContentSize().width * 0.5, display.height * 0.5)})
        self:addChild(prevBtn, 20)
        prevBtn:setTag(2001)

        local nextBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png')})
        display.commonUIParams(nextBtn, {po = cc.p(display.cx + 500 + nextBtn:getContentSize().width * 0.5, display.height * 0.5)})
        self:addChild(nextBtn, 20)
        nextBtn:setTag(2002)

        return {
            view        = view,
            closeBtn    = closeBtn,
            preImageView = preImageView,
            nextImageView = nextImageView,
            preView     = preView,
            nextView    = nextView,
            prevBtn     = prevBtn,
            nextBtn     = nextBtn,
        }
    end
    self.viewData = CreateGuideView()
    display.commonUIParams(self.viewData.view, {po = display.center})
    self:addChild(self.viewData.view, 10)

    if self.isNewGuide then
        if len > 0 then
            self.viewData.preView:refreshUI({confData = self.curModuleConf[self.index], pageIndex = self.index})
        end
    else
        self.viewData.preImageView:setTexture(configs[tostring(targetModule)][self.index].image)
    end
    
    if isFirstGuide then
        self.viewData.prevBtn:setVisible(false)
        self.viewData.nextBtn:setVisible(false)
        self.viewData.closeBtn:setVisible(false)
        eaterLayer:setOnClickScriptHandler(function(sender)
            if self.index < len then
                if self.isInAction then return end
                self.isInAction = true
                local preView = self.isNewGuide and self.viewData.preView or self.viewData.preImageView
                local nextView =  self.isNewGuide and self.viewData.nextView or self.viewData.nextImageView
                if self.index % 2 == 0 then
                    preView = self.isNewGuide and self.viewData.nextView or self.viewData.nextImageView
                    nextView = self.isNewGuide and self.viewData.preView or self.viewData.preImageView
                end
                self.index = self.index + 1
                nextView:setPosition(cc.p(display.width, pageSize.height * 0.5))
                preView:setVisible(true)
                nextView:setVisible(true)

                if self.isNewGuide then
                    nextView:refreshUI({confData = self.curModuleConf[self.index], pageIndex = self.index})
                else
                    nextView:setTexture(configs[tostring(targetModule)][self.index].image)
                end
                self:runAction(cc.Sequence:create(
                        cc.Sequence:create(
                            cc.Spawn:create(
                                cc.Spawn:create(
                                    cc.TargetedAction:create(preView, cc.EaseOut:create(cc.MoveTo:create(deltaTime,cc.p(-offsetX,pageSize.height * 0.5)),deltaTime)),
                                    cc.TargetedAction:create(preView,cc.FadeOut:create(deltaTime))
                                    ),
                                cc.Spawn:create(
                                    cc.TargetedAction:create(nextView, cc.EaseIn:create(cc.MoveTo:create(deltaTime, cc.p(offsetX,pageSize.height * 0.5)), deltaTime)),
                                    cc.TargetedAction:create(nextView,cc.FadeIn:create(deltaTime))
                                    )
                                ),
                            cc.CallFunc:create(function()
                                preView:setPosition(display.width, pageSize.height * 0.5)
                                if self.isNewGuide then
                                    preView:setVisible(false)
                                end
                            end)
                            ),
                        cc.DelayTime:create(0.1),cc.CallFunc:create(function()
                            self.isInAction = false
                        end)
                    ))
            else
                --最后一张要结束的逻辑
                self.isInAction = true
                eaterLayer:setTouchEnabled(false)
                local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
                local playerId = gameMgr:GetUserInfo().playerId
                local moduleKey = string.format('%s_%d', targetModule, checkint(playerId))
                shareUserDefault:setBoolForKey(moduleKey, false)
                shareUserDefault:flush()
                self:runAction(cc.Sequence:create(cc.Hide:create(),cc.RemoveSelf:create()))
                --[[
                self:runAction(cc.Sequence:create(cc.Spawn:create(
                            cc.TargetedAction:create(self.viewData.view,cc.ScaleTo:create(0, 0.2)),
                            cc.TargetedAction:create(self.viewData.view,cc.MoveTo:create(0.2, cc.p(display.cx, 0)))
                    ),
                cc.RemoveSelf:create()
                ))
                --]]
            end
        end)
    else
        self.viewData.closeBtn:setOnClickScriptHandler(function(sender)
            eaterLayer:setTouchEnabled(false)
            self:runAction(cc.Sequence:create(cc.Hide:create(),cc.RemoveSelf:create()))
        end)
        if self.index == 1 then
            self.viewData.prevBtn:setVisible(false)
        end
        -- 注册左右切换的按钮事件
        self.viewData.prevBtn:setOnClickScriptHandler(function(sender)
            if self.index > 1 then
                if self.isInAction then return end
                self.isInAction = true
                self.viewData.nextBtn:setVisible(true)
                -- local preView = self.viewData.preView
                -- local nextView = self.viewData.nextView
                -- if self.index % 2 == 0 then
                --     preView = self.viewData.nextView
                --     nextView = self.viewData.preView
                -- end
                local preView = self.isNewGuide and self.viewData.preView or self.viewData.preImageView
                local nextView =  self.isNewGuide and self.viewData.nextView or self.viewData.nextImageView
                if self.index % 2 == 0 then
                    preView = self.isNewGuide and self.viewData.nextView or self.viewData.nextImageView
                    nextView = self.isNewGuide and self.viewData.preView or self.viewData.preImageView
                end
                self.index = self.index - 1
                if self.index <= 1 then
                    self.viewData.prevBtn:setVisible(false)
                end
                nextView:setPosition(cc.p(-offsetX, pageSize.height * 0.5))
                preView:setVisible(true)
                nextView:setVisible(true)

                if self.isNewGuide then
                    nextView:refreshUI({confData = self.curModuleConf[self.index], pageIndex = self.index})
                else
                    nextView:setTexture(configs[tostring(targetModule)][self.index].image)
                end
                self:runAction(cc.Sequence:create(
                        cc.Sequence:create(
                            cc.Spawn:create(
                                cc.Spawn:create(
                                    cc.TargetedAction:create(preView, cc.EaseOut:create(cc.MoveTo:create(deltaTime,cc.p(display.width,pageSize.height * 0.5)),deltaTime)),
                                    cc.TargetedAction:create(preView, cc.FadeOut:create(deltaTime))
                                    ),
                                cc.Spawn:create(
                                    cc.TargetedAction:create(nextView, cc.EaseIn:create(cc.MoveTo:create(deltaTime, cc.p(offsetX,pageSize.height * 0.5)), deltaTime)),
                                    cc.TargetedAction:create(nextView, cc.FadeIn:create(deltaTime))
                                    )
                                ),
                            cc.CallFunc:create(function()
                                preView:setPosition(- offsetX, pageSize.height * 0.5)
                                if self.isNewGuide then
                                    preView:setVisible(false)
                                end
                            end)
                            ),
                        cc.DelayTime:create(0.1),cc.CallFunc:create(function()
                            self.isInAction = false
                        end)

                    ))
            end

        end)

        self.viewData.nextBtn:setOnClickScriptHandler(function(sender)
            if self.index < len then
                if self.isInAction then return end
                self.isInAction = true
                self.viewData.prevBtn:setVisible(true)
                -- local preView = self.viewData.preView
                -- local nextView = self.viewData.nextView
                -- if self.index % 2 == 0 then
                --     preView = self.viewData.nextView
                --     nextView = self.viewData.preView
                -- end
                local preView = self.isNewGuide and self.viewData.preView or self.viewData.preImageView
                local nextView =  self.isNewGuide and self.viewData.nextView or self.viewData.nextImageView
                if self.index % 2 == 0 then
                    preView = self.isNewGuide and self.viewData.nextView or self.viewData.nextImageView
                    nextView = self.isNewGuide and self.viewData.preView or self.viewData.preImageView
                end
                self.index = self.index + 1
                if self.index >= len then
                    self.viewData.nextBtn:setVisible(false)
                end
                preView:setVisible(true)
                nextView:setVisible(true)
                nextView:setPosition(cc.p(display.width, pageSize.height * 0.5))

                if self.isNewGuide then
                    nextView:refreshUI({confData = self.curModuleConf[self.index], pageIndex = self.index})
                else
                    nextView:setTexture(configs[tostring(targetModule)][self.index].image)
                end
                self:runAction(cc.Sequence:create(
                        cc.Sequence:create(
                            cc.Spawn:create(
                                cc.Spawn:create(
                                    cc.TargetedAction:create(preView, cc.EaseOut:create(cc.MoveTo:create(deltaTime,cc.p(-offsetX,pageSize.height * 0.5)),deltaTime)),
                                    cc.TargetedAction:create(preView,cc.FadeOut:create(deltaTime))
                                    ),
                                cc.Spawn:create(
                                    cc.TargetedAction:create(nextView, cc.EaseIn:create(cc.MoveTo:create(deltaTime, cc.p(offsetX,pageSize.height * 0.5)), deltaTime)),
                                    cc.TargetedAction:create(nextView,cc.FadeIn:create(deltaTime))
                                    )
                                ),
                            cc.CallFunc:create(function()
                                preView:setPosition(display.width, pageSize.height * 0.5)
                                if self.isNewGuide then
                                    preView:setVisible(false)
                                end
                            end)
                            ),
                        cc.DelayTime:create(0.1),cc.CallFunc:create(function()
                            self.isInAction = false
                        end)
                    ))
            end

        end)

    end
end

function GuideNode:onExit()
    -- display.removeUnusedSpriteFrames()
end

return GuideNode

