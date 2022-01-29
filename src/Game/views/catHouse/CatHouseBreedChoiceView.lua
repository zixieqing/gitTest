--[[
 * author : liuzhipeng
 * descpt : 猫屋 繁殖选择View
--]]
---@class CatHouseBreedChoiceView
local CatHouseBreedChoiceView = class('CatHouseBreedChoiceView', function ()
    return ui.layer({name = 'Game.views.catHouse.CatHouseBreedChoiceView', enableEvent = true, ap = display.CENTER})
end)
-------------------------------------------------
-------------------- define ---------------------
local RES_DICT = {
    BG            = _res('ui/catHouse/breed/grow_birth_choose_bg.png'),
    BTN_FRAME     = _res('ui/catHouse/breed/grow_birth_list_bg_cat_front_light.png'),
    BTN_BG_F      = _res('ui/catHouse/breed/grow_birth_list_bg_cat_front_f.png'),
    BTN_BG_M      = _res('ui/catHouse/breed/grow_birth_list_bg_cat_front_m.png'),
    CAT_BG        = _res('ui/catHouse/breed/grow_birth_list_bg_cat_back_small.png'),
    COMMON_BTN_N  = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_W  = _res('ui/common/common_btn_white_default.png'),
    COMMON_BTN_D  = _res('ui/common/common_btn_orange_disable.png'),
    BREEDING_ICON = _res('ui/catHouse/breed/grow_birth_list_bg_born.png'),
    COUNTDOWN_BG  = _res('ui/catHouse/breed/grow_birth_mian_bg_time.png'),
    ADD_ICON      = _res('ui/common/maps_fight_btn_pet_add.png'),
    HEART_ICON    = _res('ui/catHouse/breed/grow_birth_choose_ico_love.png'),
    MALE_SYMBOL   = _res('ui/catHouse/breed/grow_main_list_ico_m.png'),
    FEMALE_SYMBOL = _res('ui/catHouse/breed/grow_main_list_ico_f.png'),
    INVITE_BG_G   = _res('ui/catHouse/breed/grow_birth_choose_bg_love_grey.png'),
    INVITE_BG_L   = _res('ui/catHouse/breed/grow_birth_choose_bg_love_light.png'),
    CANCEL_BTN    = _res('ui/home/activity/activity_open_btn_quit.png'),
}
-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
-------------------- import ---------------------
local CatSpineNode = require('Game.views.catModule.cat.CatSpineNode')
-------------------- import ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedChoiceView:ctor( ... )
    self:InitUI()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
init ui
--]]
function CatHouseBreedChoiceView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- title 
        local title = display.newLabel(size.width / 2, size.height - 63, {text = __('请选择成为母亲或父亲'), color = '#602014', fontSize = 24})
        view:addChild(title, 5)
        -- 提示
        local tipsStrs = string.split(__('邀请方将消耗|_num_|, 孕育成功后获得幼猫。'), '|')
        local tipsRichLabel1 = display.newRichLabel(size.width / 2, size.height - 120, {r = true, c = {
            {text = tipsStrs[1], color = '#8D785D', fontSize = 20},
            {text = '1', color = '#c02b13', fontSize = 22},
            {img = CommonUtils.GetGoodsIconPathById(CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].goodsId), scale = 0.15},
            {text = tipsStrs[3], color = '#8D785D', fontSize = 20},
        }})
        view:addChild(tipsRichLabel1, 5)

        local tipsRichLabel2 = display.newRichLabel(size.width / 2, size.height - 150)
        view:addChild(tipsRichLabel2, 5)
        -- 雌性按钮
        local femaleBtnFrame = display.newImageView(RES_DICT.BTN_FRAME, size.width / 2 - 165, size.height / 2 - 29)
        view:addChild(femaleBtnFrame, 1)

        local femaleBtn = display.newButton(size.width / 2 - 165, size.height / 2 - 35, {n = RES_DICT.BTN_BG_F, useS = false, tag = CatHouseUtils.CAT_SEX_TYPE.GIRL})
        view:addChild(femaleBtn, 5)

        local femaleCatBg = display.newImageView(RES_DICT.CAT_BG, size.width / 2 - 165, size.height / 2 - 20)
        femaleCatBg:setScale(1.4)
        view:addChild(femaleCatBg, 1)

        local femaleCatSpineNode = CatSpineNode.new()
        femaleCatSpineNode:setPosition(cc.p(size.width / 2 - 165, size.height / 2 - 100))
        femaleCatSpineNode:setScale(0.7)
        view:addChild(femaleCatSpineNode, 1)

        local femaleNameLabel = display.newLabel(femaleBtn:getContentSize().width / 2, 60, {text = '', color = '#602014', fontSize = 22})
        femaleBtn:addChild(femaleNameLabel, 1)

        local femaleAddIcon = display.newImageView(RES_DICT.ADD_ICON, femaleBtn:getContentSize().width / 2, femaleBtn:getContentSize().height / 2 + 25)
        femaleAddIcon:setScale(1.8)
        femaleBtn:addChild(femaleAddIcon, 1)

        local femaleHeartIcon = display.newImageView(RES_DICT.HEART_ICON, femaleBtn:getContentSize().width / 2, femaleBtn:getContentSize().height / 2 + 25)
        femaleBtn:addChild(femaleHeartIcon, 1)

        local femaleSymbol = display.newImageView(RES_DICT.FEMALE_SYMBOL, femaleBtn:getContentSize().width - 57, femaleBtn:getContentSize().height / 2 - 43)
        femaleBtn:addChild(femaleSymbol, -1)

        local femaleInviteBg = display.newImageView(RES_DICT.INVITE_BG_G, femaleBtn:getContentSize().width / 2, femaleBtn:getContentSize().height - 40)
        femaleBtn:addChild(femaleInviteBg, 5)

        local femaleInviteLabel = display.newLabel(femaleInviteBg:getContentSize().width / 2, femaleInviteBg:getContentSize().height / 2, {text = '', fontSize = 22, color = '#FFFFFF'})
        femaleInviteBg:addChild(femaleInviteLabel, 1)

        local femaleCancelBtn = display.newButton(size.width / 2 - 63, size.height / 2 + 85, {n = RES_DICT.CANCEL_BTN, tag = CatHouseUtils.CAT_SEX_TYPE.GIRL})
        femaleCancelBtn:setScale(0.6)
        view:addChild(femaleCancelBtn, 5)
        
        local femaleAcceptBtn = display.newButton(size.width / 2 - 165, size.height / 2 - 215, {n = RES_DICT.COMMON_BTN_N, tag = CatHouseUtils.CAT_SEX_TYPE.GIRL})
        view:addChild(femaleAcceptBtn, 5)
        femaleAcceptBtn:setVisible(false)
        display.commonLabelParams(femaleAcceptBtn, fontWithColor(14, {text = __('确定')}))

        -- 雄性按钮
        local maleBtnFrame = display.newImageView(RES_DICT.BTN_FRAME, size.width / 2 + 165, size.height / 2 - 29)
        view:addChild(maleBtnFrame, 1)

        local maleBtn = display.newButton(size.width / 2 + 165, size.height / 2 - 35, {n = RES_DICT.BTN_BG_M, useS = false, tag = CatHouseUtils.CAT_SEX_TYPE.BOY})
        view:addChild(maleBtn, 5)

        local maleCatBg = display.newImageView(RES_DICT.CAT_BG, size.width / 2 + 165, size.height / 2 - 20)
        maleCatBg:setScale(1.4)
        view:addChild(maleCatBg, 1)

        local maleCatSpineNode = CatSpineNode.new()
        maleCatSpineNode:setPosition(cc.p(size.width / 2 + 165, size.height / 2 - 100))
        maleCatSpineNode:setScale(0.7)
        view:addChild(maleCatSpineNode, 1)

        local maleNameLabel = display.newLabel(maleBtn:getContentSize().width / 2, 60, {text = '', color = '#602014', fontSize = 22})
        maleBtn:addChild(maleNameLabel, 1)

        local maleAddIcon = display.newImageView(RES_DICT.ADD_ICON, maleBtn:getContentSize().width / 2, maleBtn:getContentSize().height / 2 + 25)
        maleAddIcon:setScale(1.8)
        maleBtn:addChild(maleAddIcon, 1)

        local maleHeartIcon = display.newImageView(RES_DICT.HEART_ICON, maleBtn:getContentSize().width / 2, maleBtn:getContentSize().height / 2 + 25)
        maleBtn:addChild(maleHeartIcon, 1)

        local maleSymbol = display.newImageView(RES_DICT.MALE_SYMBOL, maleBtn:getContentSize().width - 57, maleBtn:getContentSize().height / 2 - 43)
        maleBtn:addChild(maleSymbol, -1)

        local maleInviteBg = display.newImageView(RES_DICT.INVITE_BG_G, femaleBtn:getContentSize().width / 2, femaleBtn:getContentSize().height - 40)
        maleBtn:addChild(maleInviteBg, 5)

        local maleInviteLabel = display.newLabel(maleInviteBg:getContentSize().width / 2, maleInviteBg:getContentSize().height / 2, {text = '', fontSize = 22, color = '#FFFFFF'})
        maleInviteBg:addChild(maleInviteLabel, 1)

        local maleCancelBtn = display.newButton(size.width / 2 + 266, size.height / 2 + 85, {n = RES_DICT.CANCEL_BTN, tag = CatHouseUtils.CAT_SEX_TYPE.BOY})
        maleCancelBtn:setScale(0.6)
        view:addChild(maleCancelBtn, 5)

        local maleAcceptBtn = display.newButton(size.width / 2 + 165, size.height / 2 - 215, {n = RES_DICT.COMMON_BTN_N, tag = CatHouseUtils.CAT_SEX_TYPE.BOY})
        view:addChild(maleAcceptBtn, 5)
        maleAcceptBtn:setVisible(false)
        display.commonLabelParams(maleAcceptBtn, fontWithColor(14, {text = __('确定')}))

        -- 生育中 
        local breedingIcon = display.newImageView(RES_DICT.BREEDING_ICON, size.width / 2, 50)
        view:addChild(breedingIcon, 5)

        local breedingTitle = display.newLabel(breedingIcon:getContentSize().width / 2, breedingIcon:getContentSize().width / 2 - 27, {text = __('生育中'), color = '#9F4440', fontSize = 24, ttf = true, font = TTF_GAME_FONT})
        breedingIcon:addChild(breedingTitle, 1)

        local countdownBg = display.newImageView(RES_DICT.COUNTDOWN_BG, breedingIcon:getContentSize().width / 2, breedingIcon:getContentSize().width / 2 - 60)
        breedingIcon:addChild(countdownBg, 1)

        local countdownLabel = display.newLabel(countdownBg:getContentSize().width / 2, countdownBg:getContentSize().height / 2, {text = '', color = '#B7A892', fontSize = 22})
        countdownBg:addChild(countdownLabel, 1)
        return {
            view                = view,
            femaleBtn           = femaleBtn,
            femaleBtnFrame      = femaleBtnFrame,
            femaleCatBg         = femaleCatBg,
            femaleNameLabel     = femaleNameLabel,
            femaleAddIcon       = femaleAddIcon,
            femaleHeartIcon     = femaleHeartIcon,
            femaleInviteBg      = femaleInviteBg,
            femaleInviteLabel   = femaleInviteLabel,
            femaleCancelBtn     = femaleCancelBtn,
            femaleCatSpineNode  = femaleCatSpineNode,
            femaleAcceptBtn     = femaleAcceptBtn,
            maleBtn             = maleBtn,
            maleBtnFrame        = maleBtnFrame,
            maleCatBg           = maleCatBg,
            maleNameLabel       = maleNameLabel,
            maleAddIcon         = maleAddIcon,
            maleHeartIcon       = maleHeartIcon,
            maleInviteBg        = maleInviteBg,
            maleInviteLabel     = maleInviteLabel,
            maleCancelBtn       = maleCancelBtn,
            maleCatSpineNode    = maleCatSpineNode,
            maleAcceptBtn       = maleAcceptBtn,
            tipsRichLabel2      = tipsRichLabel2,
            breedingIcon        = breedingIcon,
            countdownLabel      = countdownLabel,
            
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function CatHouseBreedChoiceView:EnterAction()
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
更新收到的猫屋数量
--]]
function CatHouseBreedChoiceView:UpdateAcquireCatteryAmount( amount )
    local viewData = self:GetViewData()
    local tipsRichLabel2 = viewData.tipsRichLabel2
    local tipsStrs = string.split(__('受邀方当日最多获得|_num1_|/|_num2_|'), '|')
    display.reloadRichLabel(tipsRichLabel2, {c = {
        {text = tipsStrs[1], color = '#8D785D', fontSize = 20},
        {text = math.max(CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_REWARD_NUM() - checkint(amount), 0), color = '#c02b13', fontSize = 22},
        {text = tipsStrs[3], color = '#c02b13', fontSize = 20},
        {text = CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_REWARD_NUM(), color = '#c02b13', fontSize = 22},
        {img = CommonUtils.GetGoodsIconPathById(CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].goodsId), scale = 0.15}
    }})
end
--[[
刷新底部ui
--]]
function CatHouseBreedChoiceView:RefreshBottomUi( catData )
    local viewData = self:GetViewData()
    if catData.catModel and catData.catModel:hasMatingData() then
        viewData.breedingIcon:setVisible(true)
        self:UpdateBreedCountdown(catData.catModel:getMatingLeftSeconds())
    else
        viewData.breedingIcon:setVisible(false)
    end
end
---[[
---猫咪按钮创建状态
---]]
function CatHouseBreedChoiceView:CatBtnCreateState()
    local viewData = self:GetViewData()
    -- 雄性
    viewData.maleBtnFrame:setVisible(false)
    viewData.maleNameLabel:setVisible(false)
    viewData.maleAddIcon:setVisible(true)
    viewData.maleHeartIcon:setVisible(false)
    viewData.maleInviteBg:setVisible(false)
    viewData.maleCancelBtn:setVisible(false)
    viewData.maleCatSpineNode:setVisible(false)
    -- 雌性
    viewData.femaleBtnFrame:setVisible(false)
    viewData.femaleNameLabel:setVisible(false)
    viewData.femaleAddIcon:setVisible(true)
    viewData.femaleHeartIcon:setVisible(false)
    viewData.femaleInviteBg:setVisible(false)
    viewData.femaleCancelBtn:setVisible(false)
    viewData.femaleCatSpineNode:setVisible(false)
end
---[[
---猫咪按钮邀请者状态
---@param sex     number 猫咪性别
---@param catData table  猫咪数据
---]]
function CatHouseBreedChoiceView:CatBtnInviterState( sex, catData )
    local viewData = self:GetViewData()
    if sex == CatHouseUtils.CAT_SEX_TYPE.BOY then
        viewData.maleBtnFrame:setVisible(true)
        viewData.maleNameLabel:setVisible(true)
        viewData.maleNameLabel:setString(catData.catModel:getName())
        viewData.maleAddIcon:setVisible(false)
        viewData.maleHeartIcon:setVisible(false)
        viewData.maleInviteBg:setVisible(false)
        viewData.maleCatSpineNode:setVisible(true)
        viewData.maleCancelBtn:setVisible(not catData.catModel:hasMatingData())
        viewData.maleCatSpineNode:refreshNode(
            {catUuid = catData.catModel:getUuid()}
        )
    elseif sex == CatHouseUtils.CAT_SEX_TYPE.GIRL then
        viewData.femaleBtnFrame:setVisible(true)
        viewData.femaleNameLabel:setVisible(true)
        viewData.femaleNameLabel:setString(catData.catModel:getName())
        viewData.femaleAddIcon:setVisible(false)
        viewData.femaleHeartIcon:setVisible(false)
        viewData.femaleInviteBg:setVisible(false)
        viewData.femaleCatSpineNode:setVisible(true)
        viewData.femaleCancelBtn:setVisible(not catData.catModel:hasMatingData())
        viewData.femaleCatSpineNode:refreshNode(
            {catUuid = catData.catModel:getUuid()}
        )
    end
end
---[[
---猫咪按钮邀请状态
---@param sex     number 猫咪性别
---@param catData table  猫咪数据
---]]
function CatHouseBreedChoiceView:CatBtnInviteState( sex, catData )
    local viewData = self:GetViewData()
    if sex == CatHouseUtils.CAT_SEX_TYPE.BOY then
        viewData.maleInviteBg:setVisible(true)
        viewData.maleBtnFrame:setVisible(false)
        viewData.maleNameLabel:setVisible(false)
        viewData.maleAddIcon:setVisible(false)
        viewData.maleHeartIcon:setVisible(true)
        viewData.maleCancelBtn:setVisible(false)
        viewData.maleCatSpineNode:setVisible(false)
        if catData.catModel:isMatingInviteEmpty() then
            viewData.maleInviteBg:setTexture(RES_DICT.INVITE_BG_G)
            viewData.maleInviteLabel:setString('可邀请好友')
        else
            viewData.maleInviteBg:setTexture(RES_DICT.INVITE_BG_L)
            viewData.maleInviteLabel:setString('好友邀请中')
        end
    elseif sex == CatHouseUtils.CAT_SEX_TYPE.GIRL then
        viewData.femaleInviteBg:setVisible(true)
        viewData.femaleBtnFrame:setVisible(false)
        viewData.femaleNameLabel:setVisible(false)
        viewData.femaleAddIcon:setVisible(false)
        viewData.femaleHeartIcon:setVisible(true)
        viewData.femaleCancelBtn:setVisible(false)
        viewData.femaleCatSpineNode:setVisible(false)
        if catData.catModel:isMatingInviteEmpty() then
            viewData.femaleInviteBg:setTexture(RES_DICT.INVITE_BG_G)
            viewData.femaleInviteLabel:setString('可邀请好友')
        else
            viewData.femaleInviteBg:setTexture(RES_DICT.INVITE_BG_L)
            viewData.femaleInviteLabel:setString('好友邀请中')
        end
    end
end
---[[
---猫咪选择受邀猫咪状态
---@param sex     number 猫咪性别
---@param catData table  猫咪数据
---]]
function CatHouseBreedChoiceView:CatBtnSelectedInviteeState( sex, catData )
    local viewData = self:GetViewData()
    if sex == CatHouseUtils.CAT_SEX_TYPE.BOY then
        viewData.maleInviteBg:setVisible(true)
        viewData.maleBtnFrame:setVisible(false)
        viewData.maleNameLabel:setVisible(false)
        viewData.maleAddIcon:setVisible(true)
        viewData.maleHeartIcon:setVisible(false)
        viewData.maleCancelBtn:setVisible(false)
        viewData.maleCatSpineNode:setVisible(false)
        viewData.maleInviteBg:setTexture(RES_DICT.INVITE_BG_G)
        viewData.maleInviteLabel:setString(CommonUtils.getTimeFormatByType(catData.inviterData.timestamp - os.time()))
    elseif sex == CatHouseUtils.CAT_SEX_TYPE.GIRL then
        viewData.femaleInviteBg:setVisible(true)
        viewData.femaleBtnFrame:setVisible(false)
        viewData.femaleNameLabel:setVisible(false)
        viewData.femaleAddIcon:setVisible(true)
        viewData.femaleHeartIcon:setVisible(false)
        viewData.femaleCancelBtn:setVisible(false)
        viewData.femaleCatSpineNode:setVisible(false)
        viewData.femaleInviteBg:setTexture(RES_DICT.INVITE_BG_G)
        viewData.femaleInviteLabel:setString(CommonUtils.getTimeFormatByType(catData.inviterData.timestamp - os.time()))
    end
end
---[[
---猫咪受邀状态
---@param sex     number 猫咪性别
---@param catData table  猫咪数据
---]]
function CatHouseBreedChoiceView:CatBtnInviteeState( sex, catData )
    local viewData = self:GetViewData()
    ---@type HouseCatModel
    local catModel = catData.catModel
    if sex == CatHouseUtils.CAT_SEX_TYPE.BOY then
        viewData.maleBtnFrame:setVisible(false)
        viewData.maleNameLabel:setVisible(true)
        viewData.maleAddIcon:setVisible(false)
        viewData.maleHeartIcon:setVisible(false)
        viewData.maleInviteBg:setVisible(false)
        viewData.maleCancelBtn:setVisible(false)
        viewData.maleCatSpineNode:setVisible(true)
        viewData.maleCatSpineNode:setCatUuid(catModel:getUuid())
        viewData.maleNameLabel:setString(catModel:getName())
        viewData.maleInviteBg:setTexture(RES_DICT.INVITE_BG_G)
        viewData.maleInviteLabel:setString(CommonUtils.getTimeFormatByType(catData.inviterData.timestamp - os.time()))
    elseif sex == CatHouseUtils.CAT_SEX_TYPE.GIRL then
        viewData.femaleBtnFrame:setVisible(false)
        viewData.femaleNameLabel:setVisible(true)
        viewData.femaleAddIcon:setVisible(false)
        viewData.femaleHeartIcon:setVisible(false)
        viewData.femaleInviteBg:setVisible(false)
        viewData.femaleCancelBtn:setVisible(false)
        viewData.femaleCatSpineNode:setVisible(true)
        viewData.femaleCatSpineNode:setCatUuid(catModel:getUuid())
        viewData.femaleNameLabel:setString(catModel:getName())
        viewData.femaleInviteBg:setTexture(RES_DICT.INVITE_BG_G)
        viewData.femaleInviteLabel:setString(CommonUtils.getTimeFormatByType(catData.inviterData.timestamp - os.time()))
    end
end
---[[
---猫咪按钮生育状态
---@param sex     number 猫咪性别
---@param catData table  猫咪数据
---]]
function CatHouseBreedChoiceView:CatBtnBreedState( sex, catData )
    local viewData = self:GetViewData()
    if sex == CatHouseUtils.CAT_SEX_TYPE.BOY then
        viewData.maleBtnFrame:setVisible(false)
        viewData.maleNameLabel:setVisible(true)
        viewData.maleAddIcon:setVisible(false)
        viewData.maleHeartIcon:setVisible(false)
        viewData.maleInviteBg:setVisible(false)
        viewData.maleCancelBtn:setVisible(false)
        viewData.maleCatSpineNode:setVisible(true)
        if catData.state == CatHouseUtils.CAT_BREED_STATE.INVITED then
            viewData.maleCatSpineNode:refreshNode({catData = catData.inviterData})
            viewData.maleNameLabel:setString(catData.inviterData.name)
        else
            local matingData = catData.catModel:getMatingData()
            viewData.maleCatSpineNode:refreshNode({
                catData = {
                    age = matingData.age,
                    catId = matingData.catId,
                    gene = matingData.gene,
                }
            })
            viewData.maleNameLabel:setString(catData.catModel:getMatingData().name)
        end
    elseif sex == CatHouseUtils.CAT_SEX_TYPE.GIRL then
        viewData.femaleBtnFrame:setVisible(false)
        viewData.femaleNameLabel:setVisible(true)
        viewData.femaleAddIcon:setVisible(false)
        viewData.femaleHeartIcon:setVisible(false)
        viewData.femaleInviteBg:setVisible(false)
        viewData.femaleCancelBtn:setVisible(false)
        viewData.femaleCatSpineNode:setVisible(true)
        if catData.state == CatHouseUtils.CAT_BREED_STATE.INVITED then
            viewData.femaleCatSpineNode:refreshNode({catData = catData.inviterData})
            viewData.femaleNameLabel:setString(catData.inviterData.name)
        else
            local matingData = catData.catModel:getMatingData()
            viewData.femaleCatSpineNode:refreshNode({
                catData = {
                    age = matingData.age,
                    catId = matingData.catId,
                    gene = matingData.gene,
                }
            })
            viewData.femaleNameLabel:setString(catData.catModel:getMatingData().name)
        end
    end
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
--[[
刷新页面
--]]
function CatHouseBreedChoiceView:RefreshView( catData )
    self:UpdateAcquireCatteryAmount(app.catHouseMgr:getMatingRewardTimes())
    self:RefreshBottomUi(catData)
    if catData.state == CatHouseUtils.CAT_BREED_STATE.CREATE then
        self:CatBtnCreateState()
    elseif catData.state == CatHouseUtils.CAT_BREED_STATE.PAIRING then
        local sex = catData.catModel:getSex()
        self:CatBtnInviterState(sex, catData)
        self:CatBtnInviteState(CatHouseUtils.GetMateSex(sex), catData)
    elseif catData.state == CatHouseUtils.CAT_BREED_STATE.BREEDING then
        local sex = catData.catModel:getSex()
        if catData.catModel:IsMatingInviter() then
            self:CatBtnInviterState(sex, catData)
            self:CatBtnBreedState(CatHouseUtils.GetMateSex(sex), catData)
        else
            self:CatBtnInviterState(sex, catData)
            self:CatBtnBreedState(CatHouseUtils.GetMateSex(sex), catData)
        end
    elseif catData.state == CatHouseUtils.CAT_BREED_STATE.INVITED then
        local sex = checkint(catData.inviterData.sex)
        self:CatBtnBreedState(sex, catData)
        self:CatBtnSelectedInviteeState(CatHouseUtils.GetMateSex(sex), catData)
    end
end
--[[
更新生育倒计时
--]]
function CatHouseBreedChoiceView:UpdateBreedCountdown( seconds )
    local viewData = self:GetViewData()
    viewData.countdownLabel:setString(CommonUtils.getTimeFormatByType(seconds))
end
--[[
更新邀请倒计时
--]]
function CatHouseBreedChoiceView:UpdateInviteCountdown( sex, seconds )
    local viewData = self:GetViewData()
    if checkint(sex) == CatHouseUtils.CAT_SEX_TYPE.BOY then
        viewData.femaleInviteLabel:setString(CommonUtils.getTimeFormatByType(seconds))
    elseif checkint(sex) == CatHouseUtils.CAT_SEX_TYPE.GIRL then
        viewData.maleInviteLabel:setString(CommonUtils.getTimeFormatByType(seconds))
    end
end
--[[
刷新受邀者
--]]
function CatHouseBreedChoiceView:RefreshInvitee( catData )
    local viewData = self:GetViewData()
    self:CatBtnInviteeState(catData.catModel:getSex(), catData)
    if catData.catModel:getSex() == CatHouseUtils.CAT_SEX_TYPE.BOY then
        viewData.maleAcceptBtn:setVisible(true)
    else
        viewData.femaleAcceptBtn:setVisible(true)
    end
end
-------------------- public ---------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取viewData
--]]
function CatHouseBreedChoiceView:GetViewData()
    return self.viewData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedChoiceView