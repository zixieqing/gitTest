local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
---@type PetManager
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
local ChoosePetCell = class('home.ChoosePetCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.ChoosePetCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function ChoosePetCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    -- local datas = arg[2]/
    -- local index = arg[2]

    self:setContentSize(size)
    
    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    
    -- local num = math.random(4)
    local rankBg = display.newImageView(_res('ui/cards/petNew/card_pet_bg_card.png'), size.width * 0.5, size.height * 0.5)
    eventNode:addChild(rankBg,-1)
    rankBg:setTouchEnabled(true)
    self.rankBg = rankBg

     --common_frame_pet_bg_variationl_1.png 异化堕神背景
    local bg = display.newImageView(_res('ui/common/common_frame_goods_5.png'), 60, size.height * 0.65)
    eventNode:addChild(bg)
    self.bg = bg
    bg:setScale(0.8)

    local lvlabel = display.newLabel(55,bg:getPositionY() - bg:getContentSize().height*0.5*0.8 - 4,
        {text = (' '), fontSize = 20, color = '#4c4c4c', ap = cc.p(0.5, 1)})
    eventNode:addChild(lvlabel)
    self.levelLabel = lvlabel
    -- self.levelBtn = levelBtn
    -- local starlayout = CLayout:create()
    -- starlayout:setAnchorPoint(cc.p(0.5,0.5))
    -- starlayout:setPosition(cc.p(bg:getContentSize().width * 0.5,14))
    -- bg:addChild(starlayout,4)
    -- starlayout:setVisible(true)
    -- self.starlayout = starlayout

    local exclusivePetStarImage = display.newImageView(
        _res('ui/cards/petNew/pet_ico_sp.png'),
        10,
        bg:getContentSize().height - 8 )
    bg:addChild(exclusivePetStarImage,10)
    exclusivePetStarImage:setVisible(false)
    self.exclusivePetStarImage = exclusivePetStarImage
    
    local petImage = display.newImageView(
        _res('ui/home/teamformation/choosehero/team_bg_avater.png'),
        bg:getContentSize().width * 0.5,
        bg:getContentSize().height * 0.5 )
    bg:addChild(petImage)
    self.petImage = petImage
    petImage:setScale(0.55)
    self.petImage:setVisible(false)


    local isEqulabel = display.newLabel(20,20,fontWithColor(16,{ap = cc.p(0,0),text = (' ')}))
    eventNode:addChild(isEqulabel)
    self.isEqulabel = isEqulabel


    self.TDataLayout = {}
    for i=1,4 do
        local propLayout = CLayout:create()
        -- propLayout:setBackgroundColor((cc.c4b(0, 255, 128, 128)))
        propLayout:setAnchorPoint(cc.p(0.5, 1))
        propLayout:setPosition(cc.p( size.width * 0.5 + 35, size.height - 20 - 30*(i-1) ))
        eventNode:addChild(propLayout)

        
        propLayout:setContentSize(cc.size(size.width* 0.6,30))

        local size = propLayout:getContentSize()
        local label = display.newLabel(10,size.height* 0.5,fontWithColor(5,{ap = cc.p(0,0.5),text = (' ')}))
        propLayout:addChild(label)
        label:setTag(6)

        local label1 = display.newLabel(size.width - 10,size.height* 0.5,
            {text = ('+50'), fontSize = 20, color = '#39a712', ap = cc.p(1, 0.5)})
        propLayout:addChild(label1)
        label1:setTag(7)

        local lineImg = display.newImageView(_res(_res('ui/cards/propertyNew/card_ico_attribute_line.png')),size.width * 0.5,4,
            {scale9 = true,size = cc.size(size.width,2)})
        lineImg:setAnchorPoint(cc.p(0.5,1))
        propLayout:addChild(lineImg,2)
        lineImg:setTag(8)

        table.insert(self.TDataLayout,propLayout)
    end

end

function ChoosePetCell:updataUi(datas,playerPetId)
    local Tdata = {}
    Tdata = datas

    -- dump(Tdata)
    self.levelLabel:setString(string.fmt(__('等级：_lv_'),{_lv_ = tostring(datas.level) }))

    -- local petData = gameMgr:GetPetDataById(Tdata.id)
    if CommonUtils.GetConfig('pet', 'pet',Tdata.petId) then
        local headIconPath = CommonUtils.GetGoodsIconPathById(Tdata.petId)
        self.petImage:setVisible(true)
        self.petImage:setTexture(_res(headIconPath))
    else
        -- dump(Tdata.id)
        self.petImage:setVisible(false)
    end

    self.bg:setTexture( _res(string.format('ui/common/common_frame_goods_%d.png', checkint(petMgr.GetPetQualityById(datas.id)))))
    -- self.starlayout:setContentSize(cc.size(20*checkint(datas.breakLevel),20))
    -- self.starlayout:removeAllChildren()
    -- for i=1,checkint(datas.breakLevel) do
    --     local lightStar = display.newImageView(_res('ui/common/common_star_l_ico.png'), 0, 0,{ap = cc.p(0.5, 0.5)})
    --     self.starlayout:addChild(lightStar)
    --     lightStar:setScale(0.5)
    --     lightStar:setPosition(cc.p(8+20*(i-1),10))
    -- end

    if Tdata.playerCardId then
        local name = CommonUtils.GetConfig('cards','card',gameMgr:GetCardDataById(Tdata.playerCardId).cardId).name or ''
        self.isEqulabel:setVisible(true)
        self.isEqulabel:setString(string.fmt(__('跟随于_name_'),{_name_ = name}))
    else
        self.isEqulabel:setVisible(false)
    end


    for i,v in ipairs(self.TDataLayout ) do
        local label = v:getChildByTag(6)
        local label1 = v:getChildByTag(7)
        local lineImg = v:getChildByTag(8)

        label:setVisible(false)
        lineImg:setVisible(false)
        if label1 then
            v:removeChild(label1)
        end

        if Tdata then
            label:setVisible(true)
            lineImg:setVisible(true)
            -- if checkint(Tdata.level) >= checkint(configData[i].unlockLevel) then
            local petMess = petMgr.GetPetAFixedProp(Tdata.id, i)
            if petMess.unlock then
                local quailty = petMess.pquality or 1 
                local extraAttrNum = petMess.pvalue  or 1 
                local extraAttrType = petMess.ptype  or 1 

                local size = v:getContentSize()
                label1 = cc.Label:createWithBMFont(petMgr.GetPetPropFontPath(quailty), '')--
                label1:setAnchorPoint(cc.p(1, 0.5))
                label1:setHorizontalAlignment(display.TAR)
                label1:setPosition(cc.p(size.width - 10,size.height* 0.5))
                label1:setString('+'..extraAttrNum)
                v:addChild(label1)
                label1:setTag(7)

                label:setString(PetPConfig[extraAttrType].name)
                label:setVisible(true)
            else
                label:setVisible(false)
                lineImg:setVisible(false)
            end
        end
    end
end

return ChoosePetCell