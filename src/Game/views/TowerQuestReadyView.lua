--[[
 * author : kaishiqi
 * descpt : 爬塔 - 准备界面
]]
local TowerModelFactory   = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel     = TowerModelFactory.getModelType('TowerQuest')
local TowerQuestReadyView = class('TowerQuestReadyView', function()
    return display.newLayer(0, 0, {name = 'Game.views.TowerQuestReadyView'})
end)

local RES_DICT = {
    BG_IMG        = 'ui/tower/ready/tower_bg_1.jpg',
    BG_BAR        = 'ui/tower/ready/tower_bg_below.png',
    ENTER_FRAME   = 'ui/tower/ready/tower_bg_enter.png',
    TIMES_BAR     = 'ui/tower/ready/tower_label_title.png',
    BTN_ENTER_N   = 'ui/tower/ready/tower_btn_enter_active.png',
    BTN_ENTER_D   = 'ui/tower/ready/tower_btn_enter_locked.png',
    -------------------------------------------------
    EDIT_ADD_ICON = 'ui/common/maps_fight_btn_pet_add.png',
    EDIT_FRAME    = 'ui/tower/ready/tower_bg_add_preteam.png',
    -------------------------------------------------
    DIALOG_FRAME  = 'arts/stage/ui/dialogue_bg_2.png',
    DIALOG_HORN   = 'arts/stage/ui/dialogue_horn.png',
}

local CreateView = nil


function TowerQuestReadyView:ctor(args)
    xTry(function()
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self.viewData_.roleLayer:setSkewX(20)
        self.viewData_.roleLayer:setPositionX(display.width * 0.5)
        self.viewData_.dialogueFrame:setScale(0)
        self.viewData_.dialogueFrame:setOpacity(0)
        self.viewData_.dialogueFrame:setRotation(90)
        self.viewData_.bottomUILayer:setPositionY(-280)
    end, __G__TRACKBACK__)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    view:addChild(display.newImageView(_res(RES_DICT.BG_IMG), size.width/2, size.height/2, {isFull = true}))

    -------------------------------------------------
    -- role layer
    local roleLayer = display.newLayer()
    view:addChild(roleLayer)

    local roleImgPos  = cc.p(display.SAFE_R - 280, -80)
    local teamRoleImg = CommonUtils.GetRoleNodeById('role_14', 2)
    -- local noneRoleImg = CommonUtils.GetRoleNodeById('role_14', 8)
    teamRoleImg:setPosition(display.SAFE_R - 280, -80)
    teamRoleImg:setScaleX(-1)
    roleLayer:addChild(teamRoleImg)

    local roleClickArea = display.newLayer(roleImgPos.x, 0, {size = cc.size(size.width/2, display.height - 80), color = cc.c4b(0,0,0,0), ap = display.CENTER_BOTTOM, enable = true})
    roleLayer:addChild(roleClickArea)

    local dialogueFrame = display.newImageView(_res(RES_DICT.DIALOG_FRAME), display.cx + 220, display.cy + 60, {ap = display.RIGHT_BOTTOM})
    dialogueFrame:addChild(display.newImageView(_res(RES_DICT.DIALOG_HORN), 460, 5, {scaleX = -1, rotation = -8}))
    view:addChild(dialogueFrame)

    display.commonUIParams(roleClickArea, {cb = function(sender)
        teamRoleImg:runAction(cc.Sequence:create({
            cc.ScaleTo:create(0.1, -1.1, 0.8),
            cc.ScaleTo:create(0.1, -0.8, 1.1),
            cc.ScaleTo:create(0.1, -1.05, 0.95),
            cc.ScaleTo:create(0.1, -0.95, 1.05),
            cc.ScaleTo:create(0.1, -1, 1)
        }))
        dialogueFrame:runAction(cc.Sequence:create({
            cc.ScaleTo:create(0.1, 1.1, 0.8),
            cc.ScaleTo:create(0.1, 0.8, 1.1),
            cc.ScaleTo:create(0.1, 1.05, 0.95),
            cc.ScaleTo:create(0.1, 0.95, 1.05),
            cc.ScaleTo:create(0.1, 1, 1)
        }))
    end})

    local dialogueSize  = dialogueFrame:getContentSize()
    local dialogueLabel = display.newLabel(dialogueSize.width/2, dialogueSize.height/2, fontWithColor(1, {fontSize = 24, color = '#6c6c6c', w = 520, hAlign = display.TAC}))
    local textFormatArg = {_min_ = TowerQuestModel.LIBRARY_CARD_MIN, _max_ = TowerQuestModel.LIBRARY_CARD_MAX}
    display.commonLabelParams(dialogueLabel, {text = string.fmt(__('进入遗迹前，必须先拥有一支预备队伍！\n（选_min_-_max_张卡牌吧，点击下面修改）'), textFormatArg)})
    dialogueFrame:addChild(dialogueLabel)


    -------------------------------------------------
    -- bottom ui layer
    local bottomUILayer = display.newLayer()
    view:addChild(bottomUILayer)

    bottomUILayer:addChild(display.newImageView(_res(RES_DICT.BG_BAR), display.SAFE_L - 60, 0, {ap = display.LEFT_BOTTOM}))
    bottomUILayer:addChild(display.newImageView(_res(RES_DICT.ENTER_FRAME), display.SAFE_R + 60, 0, {ap = display.RIGHT_BOTTOM}))

    -- times bar
    local timesBar = display.newButton(display.SAFE_R + 35, -1, {n = _res(RES_DICT.TIMES_BAR), ap = display.RIGHT_BOTTOM, scale9 = true, size = cc.size(350,36), enable = false})
    display.commonLabelParams(timesBar, fontWithColor(4, {offset = cc.p(-5,0)}))
    bottomUILayer:addChild(timesBar)

    -- enter button
    local enterBtn = display.newButton(display.SAFE_R - 15, 50, {n = _res(RES_DICT.BTN_ENTER_N), d = _res(RES_DICT.BTN_ENTER_D), ap = display.RIGHT_BOTTOM})
    display.commonLabelParams(enterBtn, fontWithColor(20, {text = __('进 入')}))
    bottomUILayer:addChild(enterBtn)

    -------------------------------------------------
    -- edit layer
    local editLayer = display.newLayer()
    bottomUILayer:addChild(editLayer)

    -- edit bar
    local editSize = cc.size(560, 140)
    local editBar  = display.newLayer(display.SAFE_L + 400, 90, {size = editSize, color = cc.c4b(0,0,0,0), ap = display.CENTER, enable = true})
    editBar:addChild(display.newImageView(_res(RES_DICT.EDIT_FRAME), editSize.width/2, editSize.height/2 + 15))
    editBar:addChild(display.newImageView(_res(RES_DICT.EDIT_ADD_ICON), editSize.width/2, editSize.height/2 + 15))
    editBar:addChild(display.newLabel(editSize.width/2, editSize.height/2 - 50, fontWithColor(3, {text = __('编辑预备队伍')})))
    editLayer:addChild(editBar)


    if GAME_MODULE_OPEN.PRESET_TEAM and CommonUtils.UnLockModule(JUMP_MODULE_DATA.PRESET_TEAM_TOWER) then
        -- 预设队伍按钮
        local presetTeamBtn = require("Game.views.presetTeam.PresetTeamEntranceButton").new({
            presetTeamType = PRESET_TEAM_TYPE.TEN_DEFAULT,
            isSelectMode = true,
        })
        display.commonUIParams(presetTeamBtn, {po = cc.p(
            display.SAFE_L + 60,
            display.cy + 30
        )})
        display.commonLabelParams(presetTeamBtn, fontWithColor('14', {text = __('预设队伍')}))
        view:addChild(presetTeamBtn)
    end

    return {
        view          = view,
        roleLayer     = roleLayer,
        dialogueFrame = dialogueFrame,
        bottomUILayer = bottomUILayer,
        enterBtn      = enterBtn,
        timesBar      = timesBar,
        editLayer     = editLayer,
        editBar       = editBar,
    }
end


function TowerQuestReadyView:getViewData()
    return self.viewData_
end


function TowerQuestReadyView:showUI(endCB)
    local actTime  = 0.35
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.bottomUILayer, cc.MoveTo:create(actTime, cc.p(0, 0))),
            cc.TargetedAction:create(self.viewData_.roleLayer, cc.Sequence:create({
                cc.DelayTime:create(0.1),
                cc.MoveTo:create(0.25, cc.p(0, 0))
            }))
        }),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end),
        cc.TargetedAction:create(self.viewData_.roleLayer, cc.SkewTo:create(0.2, -15, 0)),
        cc.TargetedAction:create(self.viewData_.roleLayer, cc.SkewTo:create(0.1, 0, 0)),
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.dialogueFrame, cc.FadeTo:create(0.3, 255)),
            cc.TargetedAction:create(self.viewData_.dialogueFrame, cc.ScaleTo:create(0.3, 1)),
            cc.TargetedAction:create(self.viewData_.dialogueFrame, cc.RotateTo:create(0.3, 0))
        })
    }))
end


return TowerQuestReadyView
