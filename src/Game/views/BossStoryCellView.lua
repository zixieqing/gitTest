---@class BossStoryCellView
local BossStoryCellView = class('home.BossStoryCellView',function ()
    local pageviewcell = CTableViewCell:new()
    pageviewcell.name = 'home.BossStoryCellView'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function BossStoryCellView:ctor(param)
    local cellSize = cc.size(195,625)
    self:setContentSize(cellSize)
    local cellContentSzie = cc.size(182,605)
    local cellLayout = CLayout:create(cellContentSzie)
    cellLayout:setPosition(cc.p(cellSize.width/2 , cellSize.height/2))
    self:addChild(cellLayout)
    cellLayout:setName("cellLayout")
    -- 点击的layer
    local clickLayer = display.newLayer(cellSize.width/2 , cellSize.height/2,{ap = display.CENTER ,size =cellContentSzie , color = cc.c4b(0,0,0,0) , enable = true })
    cellLayout:addChild(clickLayer)
    local cellBgFrame = display.newImageView(_res('ui/home/handbook/pokedex_monster_frame_card.png'),cellContentSzie.width/2,cellContentSzie.height/2)
    -- 背景框
    local cellBgList = display.newImageView(_res('ui/home/handbook/pokedex_monster_bg_card.png'),cellContentSzie.width/2,cellContentSzie.height/2+2)
    cellLayout:addChild(cellBgFrame,2)
    cellLayout:addChild(cellBgList)

    -- 新的图标
    local newIcon = display.newImageView(_res('ui/card_preview_ico_new_2'),0,cellContentSzie.height,{ ap = display.LEFT_TOP})
    cellLayout:addChild(newIcon,2)
    newIcon:setVisible(false)
    -- boss 的外框
    local bossImage = display.newImageView(_res('ui/home/handbook/compose_ico_unkown.png'),cellContentSzie.width/2,cellContentSzie.height/2)
    cellLayout:addChild(bossImage,2)
    -- 怪物的名称 没有的不显示
    local bottonName = display.newImageView(_res('ui/home/handbook/pokedex_monster_bg_name_default.png'),cellContentSzie.width/2,5,{ap = display.CENTER_BOTTOM, scale9 = true , size =cc.size(170, 80 ) })
    cellLayout:addChild(bottonName,4)
    local buttonSize = bottonName:getContentSize()
    bottonName:setVisible(false)
    local bossName = display.newLabel(buttonSize.width/2,buttonSize.height/2,fontWithColor(14,{fontSize = 24 , color = "#ffffff" ,text = ''  ,w = 150 ,reqH = 80 ,font = TTF_GAME_FONT}) )
    bottonName:addChild(bossName)
    bossName:enableOutline(cc.c4b(31,17,17,255), 2)
    self.bgLayout  = cellLayout
    self.viewData = {
        newIcon = newIcon,
        bossImage = bossImage ,
        bottonName = bottonName ,
        bossName = bossName ,
        clickLayer = clickLayer,
        cellLayout = cellLayout
    }
end
--==============================--
--desc:更新cell 的状态
--time:2017-07-17 05:33:55
--@data:传输相关的boss 数据
--@return 
--==============================--
function BossStoryCellView:UpdateView(data)
    if not  data then
        return
    end
    local viewData_ = self.viewData
    local bossName = data.name or ""
    local status = data.status or 1
    local monsterData =  CommonUtils.GetConfigAllMess('monster' , 'monster')[tostring(data.id)] or  {}
    local bossId =   monsterData.drawId or 300005
    local str = _res(string.format( 'cards/storycard/pokedex_card_draw_%s.png', bossId) )
    local fileUtils = cc.FileUtils:getInstance()
    local isFileExist =  fileUtils:isFileExist(str)

    if not  isFileExist then
        str = _res(string.format( 'cards/storycard/pokedex_card_draw_%s.png', 300005) )
    end
    -- status分为 1,2,3 三种状态 1. 为已经获得 2.尚未获得堕神，3.尚未遇见该堕神
    local newobtain = data.newIcon-- 是否是第一次后看见
    -- 首先重置元素不可见
    viewData_.bottonName:setVisible(false)
    viewData_.bossImage:setVisible(false)
    viewData_.newIcon:setVisible(false)
    if newobtain then
        viewData_.newIcon:setVisible(true)
    else
        viewData_.newIcon:setVisible(false)
    end
    if status == 3 then
        local node = viewData_.cellLayout:getChildByTag(888)
        if  node then
            node:removeFromParent()

        end
        local bossIdImage = FilteredSpriteWithOne:create()
        local x, y = 92, 302.5
        --bossIdImage:setPosition(cc.p(x, y))
        --bossIdImage:setAnchorPoint(display.CENTER)
        bossIdImage:setAnchorPoint(display.CENTER_BOTTOM)
        bossIdImage:setPosition(cc.p(x, 12))
        viewData_.cellLayout:addChild(bossIdImage,3)
        bossIdImage:setTag(888)
        bossIdImage:setTexture(str)
        viewData_.bossName:setString(bossName)
        viewData_.bottonName:setVisible(true)
        --viewData_.bottonName:setTexture(_res('ui/home/handbook/pokedex_monster_bg_name_default.png'))
    elseif status == 2 then
        local node = viewData_.cellLayout:getChildByTag(888)
        if  node then
            node:removeFromParent()
        end
        local bossIdImage = FilteredSpriteWithOne:create()
        local x, y = 92, 302.5
        bossIdImage:setAnchorPoint(display.CENTER_BOTTOM)
        bossIdImage:setPosition(cc.p(x, 12))
        bossIdImage:setTexture(str)
        viewData_.cellLayout:addChild(bossIdImage,3)
        bossIdImage:setTag(888)
        bossIdImage:setFilter(filter.newFilter('GRAY'))
        viewData_.bossName:setString(bossName)
        viewData_.bottonName:setVisible(true)
        --viewData_.bottonName:setTexture(_res('ui/home/handbook/pokedex_monster_bg_name_default.png'))
        --viewData_.bottonName:setTexture(_res('ui/home/handbook/pokedex_monster_bg_name_lock.png'))
    elseif status == 1 then
        local node = viewData_.cellLayout:getChildByTag(888)
        if  node then
            node:removeFromParent()
        end
        viewData_.bossName:setString(bossName)
        viewData_.bossImage:setVisible(true)

        viewData_.bottonName:setVisible(false)
    end  
end

function BossStoryCellView:UpdateCommonCell(data)
    local bossId = data.id  or '300005'
    local viewData_ = self.viewData
    local bossName = data.name or ""
    local  bgSize = viewData_.bgSize
    viewData_.bossImage:setVisible(false)
    local status = nil
    local textureStr = ""
    local scale  = 1
    if checkint(data.type)  == 1 then
        status = (checkint(data.status)  ~=2 and   checkint( data.status) ~=3)  and  checkint(data.status ) or 3
        textureStr = _res(string.format('cards/bikouguai/pokedex_bikong_%d.png',data.id ) )
        scale = 0.6
    else
        status = data.status
        textureStr = AssetsUtils.GetCartoonPath(bossId)
    end
    print(textureStr)
    if not app.gameResMgr:isExistent(textureStr) then
        textureStr = _res(string.format( 'cards/storycard/pokedex_card_draw_%s.png', 300005) )

    end
    print(textureStr)
    if status == 3 then
        local node = viewData_.cellLayout:getChildByTag(888)
        if  node then
            node:removeFromParent()
        end
        local bossIdImage = AssetsUtils.GetCartoonNode(0, 0, 0, {forceSize = cc.size(160, 160), isMinRation = true})
        -- local bossIdImage = FilteredSpriteWithOne:create()
        local x, y = 92, 302.5
        bossIdImage:setPosition(cc.p(x, y))
        bossIdImage:setAnchorPoint(display.CENTER)
        bossIdImage:setName("bossIdImage")
        viewData_.cellLayout:addChild(bossIdImage,3)
        bossIdImage:setTag(888)
        bossIdImage:setTexture(textureStr)
        bossIdImage:setScale(scale)
        viewData_.bossName:setString(bossName)
        viewData_.bottonName:setVisible(true)
        --viewData_.bottonName:setTexture(_res('ui/home/handbook/pokedex_monster_bg_name_default.png'))
    elseif status == 2 then
        local node = viewData_.cellLayout:getChildByTag(888)
        if  node then
            node:removeFromParent()
        end
        local bossIdImage = AssetsUtils.GetCartoonNode(0, 0, 0, {forceSize = cc.size(160, 160), isMinRation = true})
        -- local bossIdImage = FilteredSpriteWithOne:create()
        local x, y = 92, 302.5
        bossIdImage:setPosition(cc.p(x, y))
        bossIdImage:setAnchorPoint(display.CENTER)
        bossIdImage:setTexture(textureStr)
        bossIdImage:setScale(scale)
        bossIdImage:setName("bossIdImage")
        viewData_.cellLayout:addChild(bossIdImage,3)
        bossIdImage:setTag(888)
        -- bossIdImage:setFilter(filter.newFilter('GRAY'))
        bossIdImage:setFilterName(filter.TYPES.GRAY)
        viewData_.bossName:setString(bossName)
        viewData_.bottonName:setVisible(true)
        --viewData_.bottonName:setTexture(_res('ui/home/handbook/pokedex_monster_bg_name_default.png'))
        --viewData_.bottonName:setTexture(_res('ui/home/handbook/pokedex_monster_bg_name_lock.png'))
    elseif status == 1 then
        local node = viewData_.cellLayout:getChildByTag(888)
        if  node then
            node:removeFromParent()
        end
        viewData_.bossName:setString(bossName)
        viewData_.bossImage:setVisible(true)
        viewData_.bottonName:setVisible(false)
    end

end
return BossStoryCellView
