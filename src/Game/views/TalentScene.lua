--[[
天赋View
--]]
local GameScene = require( "Frame.GameScene" )

local TalentScene = class('TalentScene', GameScene)

function TalentScene:ctor( ... )
    GameScene.ctor(self,'views.TalentScene')
    self.viewData = nil
    local function CreateTaskView( ... )
        local bgSize = display.size
        local bg = display.newImageView(_res('ui/home/talent/talent_bg.jpg'), display.cx, display.cy, {isFull = true})
        local view = CLayout:create(bgSize)
        view:setName("bgLayout")
        view:addChild(bg, -1)

        local tabNameLabel = display.newButton(130 + display.SAFE_L, display.height, {n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('料理天赋'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)

        local explainBg = display.newImageView(_res('ui/home/talent/talent_bg_explain.png'), display.cx - 667-145, display.cy, {ap = cc.p(0, 0.5)})
        view:addChild(explainBg, 5)
        local talentTreeBg = display.newImageView(_res('ui/home/talent/talent_bg_tree_1_cover.png'), display.cx, display.cy)
        view:addChild(talentTreeBg, 2)
        local skillPointBg = display.newImageView(_res('ui/home/talent/talent_bg_skill_points.png'), display.cx - 667, display.cy - 9, {ap = cc.p(0, 0)})
        view:addChild(skillPointBg, 5)
        local pointLabel = display.newLabel(skillPointBg:getContentSize().width/2, 200, {ap = cc.p(0.5, 0), text = __('当前厨力'), fontSize = 22, color = '#ffffff'})
        skillPointBg:addChild(pointLabel)
        local pointNum = cc.Label:createWithBMFont('font/battle_font_orange.fnt', '')
        pointNum:setAnchorPoint(cc.p(0, 0))
        pointNum:setHorizontalAlignment(display.TAR)
        pointNum:setPosition(122, 153)
        skillPointBg:addChild(pointNum)
        pointNum:setScale(0.6)
        local skillPointBg_fire = display.newImageView(_res('ui/home/talent/talent_bg_fire.png'), 0, 0, {ap = cc.p(0, 0)})
        skillPointBg_fire:setOpacity(0)
        skillPointBg:addChild(skillPointBg_fire, 5)
        local skillPointBg_effect = sp.SkeletonAnimation:create(
            'effects/talent/tf2.json',
            'effects/talent/tf2.atlas',
            1)
        skillPointBg:addChild(skillPointBg_effect, 10)
        skillPointBg_effect:setPosition(cc.p(skillPointBg:getContentSize().width/2, skillPointBg:getContentSize().width/2 - 15))

        local skillName = display.newLabel(display.cx - 649, display.cy + 100, {text = '', fontSize = 24, color = '#ffffff', w = 220, maxL = 2, ap = cc.p(0, 1)})
        view:addChild(skillName, 10)
        local effectLabel = display.newLabel(display.cx - 649, display.cy - 5, {ap = cc.p(0, 0), text = '', fontSize = 26, color = '#ff9140'})
        view:addChild(effectLabel, 10)

        local descrViewSize  = cc.size(244, 200)
        local descrContainer = cc.ScrollView:create()
        descrContainer:setPosition(cc.p(display.cx - 649, display.cy - 210))
        descrContainer:setDirection(eScrollViewDirectionVertical)
        descrContainer:setViewSize(descrViewSize)
        view:addChild(descrContainer, 10)

        local descrLabel = display.newLabel(0, 0, {hAlign = display.TAL, w = descrViewSize.width,text = '', fontSize = 20, color = '#ffdcbd'})
        descrLabel:setVisible(false)
        descrContainer:setContainer(descrLabel)

        local upgradeBtn = display.newButton(display.cx - 579, display.cy - 282, {ap = cc.p(0, 0), scale9 = true, size = cc.size(134, 62), n = _res('ui/common/common_btn_orange.png'), d = _res('ui/common/common_btn_orange_disable.png')})
        upgradeBtn:setName("UPGRADE_BTN")
        view:addChild(upgradeBtn, 10)
        upgradeBtn:setVisible(false)
        display.commonLabelParams(upgradeBtn, fontWithColor(14,{text = __('升级')}))

        local cookImg = nil
        if isJapanSdk() then
            cookImg = display.newImageView(CommonUtils.GetGoodsIconPathById(COOK_ID), display.cx - 550, display.cy - 306, {scale = 0.2})
            view:addChild(cookImg, 10)
            cookImg:setVisible(false)
        end

        local btnDescrLabel = display.newLabel(isJapanSdk() and (display.cx - 500) or (display.cx - 524), display.cy - 295, {text = '', fontSize = 22, color = '#ffffff' ,ap = display.CENTER_TOP})
        btnDescrLabel:setVisible(false)
        view:addChild(btnDescrLabel, 10)
        local btnDatas = {
            {name = __('伤害系'), n = 'ui/home/talent/talent_btn_1_default.png', s = 'ui/home/talent/talent_btn_1_select.png', tag = 1001, pos = cc.p(display.cx + 667, display.cy + 232)},
            {name = __('辅助系'), n = 'ui/home/talent/talent_btn_2_default.png', s = 'ui/home/talent/talent_btn_2_select.png', tag = 1002, pos = cc.p(display.cx + 667, display.cy + 118)},
            {name = __('控制系'), n = 'ui/home/talent/talent_btn_3_default.png', s = 'ui/home/talent/talent_btn_3_select.png', tag = 1003, pos = cc.p(display.cx + 667, display.cy + 4)},
            {name = '', n = 'ui/home/talent/talent_btn_4_lock.png', s = 'ui/home/talent/talent_btn_4_select.png', d = 'ui/home/talent/talent/btn_1_lock.png', tag = 1004, pos = cc.p(display.cx + 667, display.cy- 110)},
        }
        local buttons = {}
        for i,v in ipairs(btnDatas) do

            -------------------经营模式锁定--------------------------
            if i == 4 then
                local tabButton = display.newCheckBox(0, 0,
                    {n = _res(v.n), s = _res(v.s), ap = cc.p(0.5, 0.5)}
                )
                tabButton:setEnabled(false)
                tabButton:setTag(v.tag)
                local btnSize = tabButton:getContentSize()
                local layout = CLayout:create(btnSize)
                layout:setAnchorPoint(1, 1)
                layout:setPosition(v.pos)
                layout:setTag(7000 + i)
                view:addChild(layout, -1)
                tabButton:setPosition(btnSize.width/2, btnSize.height/2)
                layout:addChild(tabButton)
                table.insert(buttons, tabButton)
                local nameLabel = display.newLabel(tabButton:getContentSize().width - 80, 10,
                    {ap = cc.p(0.5, 0), text = v.name, fontSize = 26, color = '#ffffff'})
                layout:addChild(nameLabel)
                local numBg = display.newImageView(_res('ui/home/talent/talent_bg_skill_number.png'), tabButton:getContentSize().width - 80, 15, {ap = cc.p(0.5, 0 ), scale9 = true })
                layout:addChild(numBg)

                local levelLabel = display.newLabel(tabButton:getContentSize().width - 80, 15,
                    {ap = cc.p(0.5, 0), text = '', fontSize = 22, w = 130 , hAlign = display.TAC ,  color = '#fffefe'})
                layout:addChild(levelLabel)
                levelLabel:setTag(7100)
                numBg:setTag(7101)
                numBg:setVisible(false)
                levelLabel:setVisible(false)
                -- local lockIcon = display.newImageView(_res('ui/common/common_ico_lock.png'), tabButton:getContentSize().width - 80, 70)
                -- layout:addChild(lockIcon)
            else
            -------------------经营模式锁定--------------------------
                local tabButton = display.newCheckBox(0, 0,
                    {n = _res(v.n), s = _res(v.s), ap = cc.p(0.5, 0.5)}
                )
                tabButton:setTag(v.tag)
                local btnSize = tabButton:getContentSize()
                local layout = CLayout:create(btnSize)
                layout:setAnchorPoint(1, 1)
                layout:setPosition(v.pos)
                layout:setTag(7000 + i)
                view:addChild(layout, -1)
                tabButton:setPosition(btnSize.width/2, btnSize.height/2)
                layout:addChild(tabButton)
                table.insert(buttons, tabButton)
                if v.isFlip then
                    tabButton:setScaleY(-1)
                end
                local nameLabel = display.newLabel(tabButton:getContentSize().width - 80, 45,
                    {ap = cc.p(0.5, 0), text = v.name, fontSize = 30, color = '#532914'})
                layout:addChild(nameLabel)
                local numBg = display.newImageView(_res('ui/home/talent/talent_bg_skill_number.png'), tabButton:getContentSize().width - 80, 15, {ap = cc.p(0.5, 0) , scale9 = true })
                layout:addChild(numBg)
                numBg:setTag(7101)

                local levelLabel = display.newLabel(tabButton:getContentSize().width - 80, 15,
                    {ap = cc.p(0.5, 0), text = '', fontSize = 22, color = '#fffefe'})
                layout:addChild(levelLabel)
                levelLabel:setTag(7100)
            end
            local bgRight = display.newImageView(_res('ui/home/talent/talent_bg_cover_iX.png'), display.cx + 624, display.cy, {ap = cc.p(0, 0.5)})
            view:addChild(bgRight, 10)
        end
        local resetTalentBtn = display.newButton(display.cx + 463, display.cy + 249, {n = _res('ui/home/talent/talent_btn_reset.png'), ap = cc.p(0, 0)})
        view:addChild(resetTalentBtn, 10)
        display.commonLabelParams(resetTalentBtn, {text = '', fontSize = 22, color = '#473227'})
        resetTalentBtn:setName("resetTalentBtn")
        resetTalentBtn:setTag(8010)
        local cloud = sp.SkeletonAnimation:create(
            'effects/talent/cloud.json',
            'effects/talent/cloud.atlas',
            1)
        cloud:setAnimation(0, 'idle', true)
        view:addChild(cloud, 10)
        cloud:setPosition(cc.p((display.width - 1334)/2, (display.height - 1002)/2))

        return {
            bg                  = bg,
            bgSize              = bgSize,
            view                = view,
            tabNameLabel        = tabNameLabel,
            tabNameLabelPos     = cc.p(tabNameLabel:getPosition()),
            buttons             = buttons,
            talentTreeBg        = talentTreeBg,
            descrContainer      = descrContainer,
            effectLabel         = effectLabel,
            skillName           = skillName,
            descrLabel          = descrLabel,
            pointNum            = pointNum,
            upgradeBtn          = upgradeBtn,
            cookImg             = cookImg,
            btnDescrLabel       = btnDescrLabel,
            resetTalentBtn      = resetTalentBtn,
            skillPointBg_fire   = skillPointBg_fire,
            skillPointBg_effect = skillPointBg_effect
        }
    end
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 0.5))
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)

    self.viewData = CreateTaskView()
    display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = display.center})
    self:addChild(self.viewData.view)

    self.viewData.tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
    self.viewData.tabNameLabel:runAction( action )
end
function TalentScene:onCleanup(  )
    AppFacade.GetInstance():UnRegsitMediator("TalentMediator")
end

return TalentScene
