---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by zxr.
--- DateTime: 2020/3/9 7:17 下午
---
--- @params table {
---     @field presetTeamType PRESET_TEAM_TYPE   预设类型
---     @field clickCallback  function           点击回调
---     @field isClickAnimate boolean            是否使用点击动画
--- }



------------ define ------------
local RES_DICT = {
    -- 按钮底图
    COMMON_BTN_WHITE_DEFAULT =  _res('ui/common/common_btn_white_default.png')
}
------------ define ------------

local PresetTeamEntranceButton = class('CommonBattleButton', function ()
    local node = display.newButton(0, 0, {n = RES_DICT.COMMON_BTN_WHITE_DEFAULT})
    node.name = 'common.CommonBattleButton'
    node:enableNodeEvents()
    return node
end)

------------ import ------------
------------ import ------------


--[[
contrustor
--]]
function PresetTeamEntranceButton:ctor( ... )
    local args = unpack({...}) or {}

    self.presetTeamType = args.presetTeamType or PRESET_TEAM_TYPE.FIVE_DEFAULT
    self.isEditMode = args.isEditMode
    self.isSelectMode = args.isSelectMode
    self.clickCallback = args.clickCallback

    self:Init()
end
---------------------------------------------------
-- logic init begin --
---------------------------------------------------
--[[
初始化
--]]
function PresetTeamEntranceButton:Init()
    self:InitClickCallback()
end

---InitClickCallback
---初始化按钮回调
function PresetTeamEntranceButton:InitClickCallback()
    display.commonUIParams(self, {cb = handler(self, self.ClickHandler), animate = self.isClickAnimate})
end

---SetClickCallback
---设置按钮回调
---@param clickCallback function  回调
---@param isAnimate boolean       是否使用动画
function PresetTeamEntranceButton:SetClickCallback(clickCallback, isAnimate)
    if nil ~= clickCallback then
        self.ClickHandler   = clickCallback
        self.isClickAnimate = isAnimate
        self:InitClickCallback()
    end
end
---------------------------------------------------
-- logic init end --
---------------------------------------------------

---------------------------------------------------
-- click callback begin --
---------------------------------------------------

---ClickHandler
---点击回调
---@param sender userdata
function PresetTeamEntranceButton:ClickHandler(sender)
    PlayAudioByClickNormal()
    if nil ~= self.clickCallback then
        xTry(function ()
            self.clickCallback(sender)
        end, __G__TRACKBACK__)
    else
        local PresetTeamMediator = require( 'Game.mediator.presetTeam.PresetTeamMediator')
        local mediator = PresetTeamMediator.new({
            presetTeamTypes = {self.presetTeamType}, 
            isEditMode      = self.isEditMode,
            isSelectMode    = self.isSelectMode,
        })
        app:RegistMediator(mediator)
    end
end


---------------------------------------------------
-- click callback end --
---------------------------------------------------


return PresetTeamEntranceButton
