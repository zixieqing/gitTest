-- LobbyFriendView
---@type FishConfigParser
local fishConfigParser = require('Game.Datas.Parser.FishConfigParser')
---@class LobbyFriendView
local LobbyFriendView = class('LobbyFriendView',
	function ()
		local node = CLayout:create(display.size)
		node.name = 'Game.views.LobbyFriendView'
		node:enableNodeEvents()
		return node
	end
)
local RES_DIR = {
    --------------------------------  好友界面  --------------------------------------
    title = _res('ui/common/common_title_5.png'),
    card_bar_bg = _res('avatar/ui/card_bar_bg.png'),
    message_book = _res('avatar/ui/friends_btn_messagebook.png'),
    bg = _res('ui/common/common_bg_botton-m.png'),
    frame = _res('avatar/ui/restaurant_avatar_frame_default.png'),
    line = _res('ui/cards/propertyNew/card_ico_attribute_line.png'),

    --------------------------------  好友界面Cell  --------------------------------------
    cell_robet_bg = _res('avatar/ui/restaurant_bg_robet_list.png'),
    cell_bg = _res('avatar/ui/restaurant_bg_friends_list.png'),
    cell_bg_s = _res('avatar/ui/restaurant_bg_friends_list_selected.png'),
    rob_help = _res('avatar/ui/restaurant_friends_ico_rob_help.png'),
    insect = _res('avatar/ui/restaurant_friends_ico_kill_insect.png'),
    clean_number = _res('avatar/ui/restaurant_friend_bg_clean_number.png'),
    kill_insect = _res('avatar/ui/restaurant_friends_ico_help_kill_insect.png'),
    friend_default_header = _res('ui/home/friend/friend_frame_touxiang.png'),
    msg_cell_bg = _res('ui/common/common_bg_list.png'),
    cell_selected_frame =  _res('ui/mail/common_bg_list_selected.png'),

    --------------------------------  留言簿  --------------------------------------
    desc_bg = _res('avatar/ui/profile_bg.png'),
    friends_tips_bg_name = _res('avatar/ui/friends_tips_bg_name.png'),
    btn_n = _res('ui/common/common_btn_orange.png'),
    btn_d = _res('ui/common/common_btn_white_default.png'),
    
    --------------------------------  头像  --------------------------------------
    head_bg = _res('ui/author/create_roles_head_down_default.png'),
	head = _res('ui/home/nmain/common_role_female.png'),
	frame_default = _res('ui/author/create_roles_head_up_default.png'),
    fishing_friend = _res('ui/home/fishing/fishing_friend_ico_available.png'),
    BG_HEAD_2 = _res("ui/home/kitchen/cooking_cook_bg_head_2.png"),
    BG_HEAD = _res("ui/home/kitchen/cooking_cook_bg_head.png"),
}

local FLAG = {'rob_help', 'insect', 'kill_insect'}

local CreateView        = nil
local CreateHeader      = nil
local CreateCell_       = nil
local CreateCellLayer_  = nil
local CreateFriendDesc_ = nil
local CreateTipImg_     = nil
local CreateFishIcon    = nil
function LobbyFriendView:ctor( ... )
    self:initValue()
    self:initUi()
end

function LobbyFriendView:initValue( ... )
    -- body
end

function LobbyFriendView:initUi( ... )
    self.viewData = CreateView()
    self:addChild(self.viewData.touchLayer)
    self:addChild(self.viewData.layer)
    self:addChild(self.viewData.bgLayer)
end

CreateView = function ()
    local touchLayer = display.newLayer(0, 0, {size = display.size, color = cc.c4b(0,0,0,0), enable = true, ap = display.LEFT_BOTTOM})

    -- bg and frame
    local size = cc.size(412, display.height)
    local layer = display.newLayer(display.SAFE_R - size.width, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true, ap = display.LEFT_BOTTOM})
    local bgLayer = display.newLayer(display.SAFE_R - size.width, 0, {size = size, ap = display.LEFT_BOTTOM})
    local bg = display.newImageView(RES_DIR.bg, 0, 0, {size = size, scale9 = true, ap = display.LEFT_BOTTOM})
    local frame = display.newImageView(RES_DIR.frame, 0, 0, {size = size, scale9 = true, ap = display.LEFT_BOTTOM})
    
    bgLayer:addChild(bg)
    bgLayer:addChild(frame)
    
    -- title
    local titleBg = display.newImageView(RES_DIR.title, size.width / 2, size.height * 0.98, {ap = display.CENTER_TOP ,scale9 = true })
    local titleLabel = display.newLabel(0, 0, fontWithColor(4, {text = __("我的好友")   ,reqW = 170 }))

    local titleLabelSize  = display.getLabelContentSize(titleLabel)
    local titleBgSize = titleBg:getContentSize()
    local maxWith = 220
    if titleLabelSize.width + 40  > titleBgSize.width  then
        maxWith = titleLabelSize.width + 40 >  maxWith and maxWith or ( titleLabelSize.width + 40 )
        titleBg:setContentSize(cc.size( maxWith,titleBgSize.height ))

    end
    display.commonUIParams(titleLabel, {po = cc.p(utils.getLocalCenter(titleBg))})
    titleBg:addChild(titleLabel)
    bgLayer:addChild(titleBg)

    -- TODO temp
    local officialConfs = CommonUtils.GetConfigAllMess('show', 'restaurant') or {}
    -- local officialBtn   = display.newButton(15, size.height - 15, {n = RES_DIR.btn_n, ap = display.LEFT_TOP})
    -- display.commonLabelParams(officialBtn, fontWithColor(1, {text = tostring(officialConfs.name)}))
    -- officialBtn:setScale(0.6)
    -- bgLayer:addChild(officialBtn)

    -- 好友人数
    local friendCountLb = display.newLabel(size.width * 0.02, size.height * 0.88, fontWithColor(4, {ap = display.LEFT_BOTTOM}))
    bgLayer:addChild(friendCountLb)

    -- 留言板
    local messageBook = display.newButton(size.width * 0.9, size.height * 0.88, {n = RES_DIR.message_book, ap = display.RIGHT_BOTTOM})
    local messageBookSize = messageBook:getContentSize()
    local messageBg = display.newImageView(RES_DIR.card_bar_bg, messageBookSize.width / 2, 0, { size = cc.size(170, 30) , scale9 = true ,ap = display.CENTER_BOTTOM})
    local messageLabel = display.newLabel(0, 0, fontWithColor(12, {text = __("访客记录") , reqW =110}))
    display.commonUIParams(messageLabel, {po = cc.p(utils.getLocalCenter(messageBg))})
    messageBg:addChild(messageLabel)
    messageLabel:setName("messageLabel")
    messageBook:addChild(messageBg)
    bgLayer:addChild(messageBook)

    -- 分割线
    local line = display.newImageView(RES_DIR.line, size.width / 2, size.height * 0.875)
    bgLayer:addChild(line)

    -- 机器人
    local robetViewData = CreateCellLayer_()
    local robetView      = robetViewData.view
    display.commonUIParams(robetView, {po = cc.p(size.width / 2 - 2, size.height * 0.871), ap = display.CENTER_TOP})
    bgLayer:addChild(robetView, 1)

    -- 好友列表
    local gridViewSize = cc.size(size.width * 0.96, size.height * 0.86 - 93)
    local gridViewCellSize = cc.size(gridViewSize.width, 93)
    local gridView = CGridView:create(gridViewSize)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    -- gridView:setAutoRelocate(true)
    -- gridView:setBounceable(false)
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    bgLayer:addChild(gridView)
    gridView:setAnchorPoint(display.CENTER_BOTTOM)
    gridView:setPosition(cc.p(size.width / 2 + 2, 10))

    -- 添加好友
    local addFriendLayerSize = cc.size(size.width, 200)
    local addFriendLayer = display.newLayer(size.width / 2, size.height * 0.4, {ap = display.CENTER, size = addFriendLayerSize})
    addFriendLayer:setVisible(false)
    local chooseCookerBtn = display.newButton(0, 0, {n = _res('ui/home/lobby/peopleManage/restaurant_manage_bg_people_state.png')})
    display.commonUIParams(chooseCookerBtn, {ap = cc.p(0.5,0.5),po = cc.p(addFriendLayerSize.width * 0.5,addFriendLayerSize.height * 0.6)})
    addFriendLayer:addChild(chooseCookerBtn)
    bgLayer:addChild(addFriendLayer)

    local chooseCookerBtnSize = chooseCookerBtn:getContentSize()
    local addImg = display.newImageView(_res('ui/common/maps_fight_btn_pet_add.png'), 0, 0)
    display.commonUIParams(addImg, {ap = cc.p(0.5, 0.5), po = cc.p(chooseCookerBtnSize.width * 0.5, chooseCookerBtnSize.height * 0.5)})
    chooseCookerBtn:addChild(addImg)

    local addFriendLabel = display.newLabel(chooseCookerBtn:getPositionX(), chooseCookerBtn:getPositionY() - chooseCookerBtnSize.height / 2 - 5, fontWithColor(4, {text = __('添加好友'), ap = display.CENTER_TOP}))
    addFriendLayer:addChild(addFriendLabel)
    return {
        layer             = layer,
        bgLayer           = bgLayer,
        -- officialBtn       = officialBtn,
        gridView          = gridView,
        touchLayer        = touchLayer,
        friendCountLb     = friendCountLb,
        messageBook       = messageBook,
        messageLabel      = messageLabel,

        addFriendLayer    = addFriendLayer,
        chooseCookerBtn   = chooseCookerBtn,

        robetViewData     = robetViewData,
    }
end

CreateHeader = function (parent, scale, pos, friendLvScale)
    scale = scale or 1
    friendLvScale = friendLvScale or 1

    -- local headerButton = display.newButton(0, 0, {animate = false, n = RES_DIR.head_bg, ap = display.LEFT_BOTTOM})	
    -- local oldSize = headerButton:getContentSize()
	-- local headerSize = cc.size(oldSize.width * scale, oldSize.height * scale)
    -- local layer = display.newLayer(pos.x, pos.y, {size = headerSize, ap = display.LEFT_CENTER})
    -- headerButton:setScale(scale)
    -- layer:addChild(headerButton)
    -- parent:addChild(layer)

    -- local noticeImage = WebSprite.new({url = '', ad = true, hpath = RES_DIR.head, tsize = headerSize})
    -- local noticeImageSize = noticeImage:getContentSize()
    -- noticeImage:setPosition(utils.getLocalCenter(headerButton))
    -- noticeImage:setScale(0.8)
    -- headerButton:addChild(noticeImage)

    local noticeImage = display.newLayer()

    -- local frame = display.newImageView(RES_DIR.frame_default, 0, 0, {ap = display.LEFT_BOTTOM})
    -- headerButton:addChild(frame)
    -- local headIcon = require('root.CCHeaderNode').new({tsize = bgSize, pre = self.avatarFrame or 500077, url = self.avatar})
    
    local headerButton = require('root.CCHeaderNode').new({bg = RES_DIR.head_bg, pre = 500077})
    local oldSize = headerButton:getContentSize()
    local headerSize = cc.size(oldSize.width * scale, oldSize.height * scale)
    display.commonUIParams(headerButton,{ap = display.LEFT_BOTTOM})
    headerButton:setScale(scale)
    headerButton.headerSprite:setScale(0.8)
    local layer = display.newLayer(pos.x, pos.y, {size = headerSize, ap = display.LEFT_CENTER})
    layer:addChild(headerButton)
    parent:addChild(layer)
    -- parent:addChild(headerButton)

    -- local frame = display.newImageView(RES_DIR.frame_default, 0, 0, {ap = display.LEFT_BOTTOM})
    -- headerButton:addChild(frame, 1)

    -- display.commonUIParams(headerButton,{pos})
    -- local layer = display.newLayer(pos.x, pos.y, {size = headerSize, ap = display.LEFT_CENTER})
    -- layer:addChild(headerButton)
    -- local friendLvLabel = display.newLabel(headerSize.width - 10, 10, fontWithColor(14, {fontSize = 28, text = 120, ap = display.RIGHT_BOTTOM}))
    -- headerButton:addChild(friendLvLabel)
    -- print(scale)
    local friendLvLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '000')
    friendLvLabel:setAnchorPoint(display.RIGHT_BOTTOM)
    friendLvLabel:setHorizontalAlignment(display.TAR)
    friendLvLabel:setPosition(headerSize.width * 0.97, headerSize.height * 0.02)
    friendLvLabel:setScale(friendLvScale)
    layer:addChild(friendLvLabel,1)

    -- headerButton:setVisible(false)
    return headerButton, noticeImage, friendLvLabel
end

-- state = 1 表示好友cell
-- state = 2 表示留言簿cell
CreateCell_ = function (state)
    local viewData = CreateCellLayer_(state)

    local cell = CGridViewCell:new()
    cell:setContentSize(viewData.cellBgSize)
    cell:addChild(viewData.view)
    
    cell.viewData = viewData
    return cell
end

-- state = 1 表示好友cell
-- state = 2 表示留言簿cell
CreateCellLayer_ = function (state)
    local cellBgImg = nil
    local headerScale = nil
    local friendLvScale = nil
    if state == 1 then
        cellBgImg = RES_DIR.cell_bg
        headerScale = 0.5
        friendLvScale = 0.85
    elseif state == 2 then
        cellBgImg = RES_DIR.msg_cell_bg
        headerScale = 0.6  
        friendLvScale = 0.9
    else
        cellBgImg = RES_DIR.cell_robet_bg
        headerScale = 0.5
        friendLvScale = 0.85
    end
     -- bg
     local cellBg = display.newButton(2, 0, {n = cellBgImg, enable = isFriend, ap = display.LEFT_BOTTOM})
     local cellBg_s = display.newImageView(RES_DIR.cell_bg_s, 0, 0, {ap = display.LEFT_BOTTOM})
     local cellBgSize = cellBg:getContentSize()
     local cellSelectedFrame = display.newImageView(RES_DIR.cell_selected_frame, 0, 0, {scale9 = true, size = cellBgSize, ap = display.LEFT_BOTTOM})
     local view = display.newLayer(0, 0, {size = cellBgSize, ap = display.LEFT_BOTTOM})
     cellBg_s:setVisible(false)
     cellSelectedFrame:setVisible(false)
     view:addChild(cellBg)
     view:addChild(cellBg_s)
     view:addChild(cellSelectedFrame)
 
     local headerButton, noticeImage, friendLvLabel = CreateHeader(view, headerScale, cc.p(cellBgSize.width * 0.03, cellBgSize.height / 2), friendLvScale)
 
     local nameLabel = display.newLabel(cellBgSize.width * 0.24, cellBgSize.height * 0.75,
         fontWithColor(11, { ap = display.LEFT_CENTER}))
     view:addChild(nameLabel)
    
     local descLabel = display.newLabel(cellBgSize.width * 0.24, cellBgSize.height * 0.49,
         fontWithColor(6, {ap = display.LEFT_TOP, w = cellBgSize.width * 0.75}))
     descLabel:setVisible(state ~= nil)
     view:addChild(descLabel)
 
     local tipImgs = {}
     local tipLayer = nil
     local timeLabel = nil
     if state == 1 then
         tipLayer = display.newLayer(cellBgSize.width * 0.985, cellBgSize.height / 2, {size = cellBgSize, ap = display.RIGHT_CENTER})
         view:addChild(tipLayer)
     elseif state == 2 then
         timeLabel = display.newLabel(cellBgSize.width * 0.24, cellBgSize.height * 0.67,
             fontWithColor(11, {color = '#d76363', fontSize = 20, ap = display.LEFT_TOP}))
         view:addChild(timeLabel)
     end

     return {
        view               = view,
        cellBg             = cellBg,
        cellBg_s           = cellBg_s,
        cellSelectedFrame  = cellSelectedFrame,
        descLabel          = descLabel,
        tipImgs            = tipImgs,
        tipLayer           = tipLayer,
        nameLabel          = nameLabel,
        timeLabel          = timeLabel,
        noticeImage        = noticeImage,
        headerButton       = headerButton,
        friendLvLabel      = friendLvLabel,

        cellBgSize         = cellBgSize,
    }
end

-- 好友详情界面 
CreateFriendDesc_ = function ( ... )
    local bg = display.newImageView(RES_DIR.desc_bg, 0, 0, {ap = display.LEFT_BOTTOM})
    local bgSize = bg:getContentSize()
    local view = display.newLayer(0, 0, {size = bgSize, ap = display.RIGHT_TOP})
    view:addChild(bg)
    -- 头像
    local headScale = 0.7
    local headerButton, noticeImage, friendLvLabel = CreateHeader(view, headScale, cc.p(bgSize.width * 0.06, bgSize.height * 0.82))
    local headSize = headerButton:getContentSize()
    -- display.commonUIParams(headerButton, {ap = display.LEFT_TOP, po = cc.p(bgSize.width * 0.06, bgSize.height * 0.95)})

    -- 昵称
    local nameBg = display.newImageView(RES_DIR.friends_tips_bg_name, headerButton:getPositionX() + headSize.width * headScale + 20, bgSize.height * 0.899, {ap = display.LEFT_CENTER})
    local nameBgSize = nameBg:getContentSize()
    local nameLabel = display.newLabel(10, nameBgSize.height / 2, fontWithColor(11, {text = '睡觉了',ap = display.LEFT_CENTER}))
    nameBg:addChild(nameLabel)
    view:addChild(nameBg)
    
    -- 在线 or 离线
    local onlineLabel = display.newLabel(bgSize.width * 0.96, nameBg:getPositionY(), fontWithColor(6, {text = '离线', ap = display.RIGHT_CENTER}))
    view:addChild(onlineLabel)

    -- 餐厅等级
    local avatarLv = display.newLabel(nameBg:getPositionX() + 8, bgSize.height * 0.79, fontWithColor(6, {text = string.format(__('餐厅等级%s'), 33), ap = display.LEFT_CENTER}))
    local avatarLvSize = display.getLabelContentSize(avatarLv)
    view:addChild(avatarLv)

    -- 亲密度
    local intimacy = display.newLabel(avatarLv:getPositionX(), avatarLv:getPositionY() - avatarLvSize.height / 2, 
        fontWithColor(6, {text = string.format(__('亲密度%s'), 33), ap = display.LEFT_TOP}))
    view:addChild(intimacy)

    local btnTexts = {
        [33331] = __('去餐厅'),
        [33332] = __('未开放'),
        [33333] = __('未开放'),
        [33334] = __('未开放'),
        [33335] = __('未开放'),
        [33336] = __('未开放'),
    }

    local actionBtns = {}
    local offsetY = 0
    local count = 0
    for i,v in pairs(btnTexts) do
        count = count + 1
        local offsetX = -15
        local ap = display.RIGHT_TOP
        if count % 2 == 0 then
            offsetX = 15
            ap = display.LEFT_TOP
        end
        local btn = display.newButton(bgSize.width / 2 + offsetX, bgSize.height * 0.6 - offsetY, {n = RES_DIR.btn_n, ap = ap})
        btn:setTag(i)
        display.commonLabelParams(btn, fontWithColor(14, {text = v}))
        view:addChild(btn)
        
        actionBtns[i] = btn
        offsetY = (math.floor(count / 2)) * 70
    end

    view.viewData = {
        nameLabel = nameLabel,
        onlineLabel = onlineLabel,
        avatarLv = avatarLv,
        intimacy = intimacy,
        noticeImage = noticeImage,
        friendLvLabel = friendLvLabel,
        actionBtns = actionBtns,
        headerButton = headerButton,
    }
    return view
end

CreateTipImg_ = function(parent, bugTips)
    if parent and parent:getChildrenCount() > 0 then
        parent:removeAllChildren()
    end
    
    local function getBugImgByBug(bug)
        if bug == 2 then
            return RES_DIR.insect
        elseif bug == 3 then
            return RES_DIR.kill_insect
        end
        return
    end

    local function getQuestEventByBug(bug)
        if bug == 2 then
            return RES_DIR.rob_help
        elseif bug == 3 then
            return RES_DIR.rob_help
        end

        return
    end

    local function createImg(parent, path, size, imgSize , bugType )
        local tipImg = display.newImageView(path, size.width * 0.985 - imgSize.width, size.height / 2, {ap = display.RIGHT_CENTER})
        bugType = checkint(bugType)
        if bugType == 1 then
            tipImg:setPosition(size.width * 0.985 - 50, size.height / 2)
        end
        parent:addChild(tipImg)
        return tipImg
    end

    local parentSize = parent:getContentSize()
    local childCount = 0
    local tipImgSize = cc.size(0, 0)
    for i,v in ipairs(bugTips) do
        local bug = bugTips[i]
        if i == 1 then
            local imgPath = getBugImgByBug(bug)
            if imgPath then
                createImg(parent, imgPath, parentSize, tipImgSize , i )
            end
        elseif i == 2 then
            local imgPath = getQuestEventByBug(bug)
            if imgPath then
                createImg(parent, imgPath, parentSize, tipImgSize , i )
            end
        end
    end
end
CreateFishIcon = function(parent, bugTips)
    bugTips = bugTips or {}
    if parent and parent:getChildrenCount() > 0 then
        parent:removeAllChildren()
    end
    local function createImg(parent, path, size, imgSize)
        local tipImg = display.newImageView(path, size.width * 0.985 - imgSize.width, size.height / 2, {ap = display.RIGHT_CENTER})
        parent:addChild(tipImg)
        return tipImg
    end
    local function createHead(parent,size,imgSize)
        local headerImageBtn = display.newImageView(RES_DIR.BG_HEAD_2)
        local headSize = headerImageBtn:getContentSize()
        local cardId = bugTips.friendFish.cardId
        headerImageBtn:setPosition(cc.p(headSize.width/2 , headSize.height/2))
        local headerLayout = display.newLayer(0,0,{ap = display.RIGHT_TOP , size = headSize })
        headerLayout:addChild(headerImageBtn,2)
        local headBg = display.newImageView(RES_DIR.BG_HEAD)
        headBg:setPosition(cc.p(headSize.width/2 , headSize.height/2))
        headerLayout:addChild(headBg)
        local effectImage = CardUtils.GetCardHeadPathByCardId(cardId)
        local clippingNode = cc.ClippingNode:create()
        local noticeImage = display.newImageView(effectImage)
        local stencilNode = display.newImageView(RES_DIR.BG_HEAD)
        local stencilNodeSzie = stencilNode:getContentSize()
        local scale = stencilNodeSzie.width/ noticeImage:getContentSize().width
        noticeImage:setScale(scale)
        clippingNode:setAnchorPoint(display.CENTER)
        clippingNode:setContentSize( cc.size(stencilNodeSzie.width,stencilNodeSzie.height))
        clippingNode:addChild(noticeImage)
        clippingNode:setPosition(cc.p(headSize.width-3, headSize.height-3))
        clippingNode:setStencil(stencilNode)
        clippingNode:setAlphaThreshold(0.05)
        clippingNode:setInverted(false)
        headerLayout:addChild(clippingNode)
        headerLayout:setPosition(size.width * 0.985 - imgSize.width, size.height / 2 + 40)
        parent:addChild(headerLayout)
    end
    local parentSize = parent:getContentSize()
    local tipImgSize = cc.size(0, 0)
    if checkint(bugTips.fishPlaceLevel) > 0   then -- 证明此位置钓场已经打开
        local  friendFish = bugTips.friendFish or {}
        -- friendFish 元素不为零 并且playerCardId 存在 此位置已经有人
        if table.nums(friendFish)  > 0  and checkint(friendFish.playerCardId) > 0  then
            if CommonUtils.JuageMySelfOperation(friendFish.friendId)  then
                -- 如果是自己创建icon
                createHead(parent ,parentSize,tipImgSize  )
            end
        else
        -- 该位置空缺可以添加飨灵
            createImg(parent ,RES_DIR.fishing_friend , parentSize , tipImgSize )
        end
    end
    local friendFishPlace = bugTips.friendFishPlace or {}
    local buff = friendFishPlace.buff
    if buff then
        local currentTime = getServerTime()
        if checkint(buff.startTime) < currentTime and currentTime < checkint(buff.endTime) then
            local prayConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRAY,'fish')
            local buffId =  buff.buffId
            if buffId  then
                local icon = prayConfig[tostring(buffId)].icon
                local image = display.newImageView(_res('ui/common/' .. icon) ,parentSize.width -55, parentSize.height/2, {ap = display.RIGHT_CENTER} )
                parent:addChild(image)
                image:setScale(0.5)
            end
        end
    end

end



----------------------------- 公有 -----------------------------
-- 创建cell 方法
function LobbyFriendView:CreateCell(state)
    return CreateCell_(state)
end

-- 创建好友详情 方法
function LobbyFriendView:CreateFriendDesc( ... )
    return CreateFriendDesc_( ... )
end

function LobbyFriendView:CreateTipImg(parent,bugTips)
    return CreateTipImg_(parent,bugTips)
    -- dump(bugTips)
end

function LobbyFriendView:CreateFishIcon(parent,bugTips)
    return CreateFishIcon(parent,bugTips)
    -- dump(bugTips)
end


return LobbyFriendView