--[[
成就任务系统UI
--]]
local VIEW_SIZE = cc.size(1230, 641)
local AchievementTaskView = class('AchievementTaskView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.task.AchievementTaskView'
	node:enableNodeEvents()
	return node
end)

local CreateView      = nil

local RES_DIR = {
    TASK_LIST_BG       = _res('ui/home/task/main/achievement_bg_task_big'),
    CARTON_IMG         = _res('ui/home/task/main/achievement_img_bjl.png'),
    BG_LEVEL           = _res('ui/home/task/main/achievement_bg_level.png'),
    BAR_BG             = _res('ui/home/task/task_bar_bg.png'),
    BAR                = _res('ui/home/task/task_bar.png'),
    TAB_LIST_BG        = _res('ui/home/task/main/achievement_bg_liebiao.png'),
    DIALOGUE_TIPS      = _res('ui/common/common_bg_dialogue_tips.png'),
    RED_IMG            = _res('ui/common/common_ico_red_point.png'),
    TAB_SELECT         = _res('ui/home/rank/rank_btn_tab_select.png'),
    TAB_DEFAULT        = _res('ui/home/rank/rank_btn_tab_default.png'),
    TAB_SECOND_SELECT  = _res('ui/home/rank/rank_btn_2_select.png'),
    TAB_SECOND_DEFAULT = _res('ui/home/rank/rank_btn_2_default.png'),

    SPINE_BOX          = _spn('effects/xiaobaoxiang/box_2'),
    
}

local STYLE_COOKING_CONFS = CommonUtils.GetConfigAllMess('style', 'cooking')
local OTHER_GOODS_CONFS   = CommonUtils.GetConfigAllMess('other', 'goods')

local TASK_TYPE = {
	FOOD_COLLECT      = '61',                -- 菜品收集
	CARD_COLLECT_1    = '64',                -- 卡牌收集
	CARD_COLLECT_2    = '65',                -- 卡牌收集
	TEAM_COLLECT      = '89',                -- 组队收集
}

function AchievementTaskView:ctor( ... )
    self.args = unpack({...})
    self:initialUI()
end

function AchievementTaskView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)
end

--==============================--
--desc: 更新成就tab列表
--@params taskClassTabData table  成就tab数据
--@params selectedTab int  成就tab数据
--@return
--==============================--
function AchievementTaskView:refreshExpandableListView(taskClassTabData, selectedTab)
	local viewData = self:GetViewComponent().viewData
    local expandableListView = viewData.expandableListView
    for i,v in ipairs(taskClassTabData) do
        local expandableNode = expandableListView:getExpandableNodeAtIndex(i - 1)
        if expandableNode then
		    -- 判断是否被选中
		    if selectedTab == v.rankTypes then
		    	expandableNode.button:setNormalImage(RES_DIR.TAB_SELECT)
                expandableNode.button:setSelectedImage(RES_DIR.TAB_SELECT)
            else
		    	expandableNode.button:setNormalImage(RES_DIR.TAB_DEFAULT)
                expandableNode.button:setSelectedImage(RES_DIR.TAB_DEFAULT)
		    end
		    -- 判断是否有子页签
            if v.smallClass and next(v.smallClass) ~= nil then
                local isSelected = false
		    	-- 判断子页签是否被选中
                for index, child in ipairs(v.smallClass) do
                    local node = expandableNode:getItemNodeAtIndex(index - 1)
                    if child.rankTypes == selectedTab then
                        node.bgBtn:setNormalImage(RES_DIR.TAB_SECOND_SELECT)
                        node.bgBtn:setSelectedImage(RES_DIR.TAB_SECOND_SELECT)
                        isSelected = true
                    else
                        node.bgBtn:setNormalImage(RES_DIR.TAB_SECOND_DEFAULT)
                        node.bgBtn:setSelectedImage(RES_DIR.TAB_SECOND_DEFAULT)
		    		end
                end
                if isSelected then
                    expandableNode:setExpanded(true)
                    expandableNode.button:setNormalImage(RES_DIR.TAB_SELECT)
                    expandableNode.button:setSelectedImage(RES_DIR.TAB_SELECT)
                    expandableNode.arrowIcon:setRotation(0)
                else
                    expandableNode:setExpanded(false)
                    expandableNode.arrowIcon:setRotation(270)
                end
		    end
        end
    end
    expandableListView:reloadData()
end

--==============================--
--desc: 更新成就任务列表
--@params listData table  成就任务列表数据
--@return
--==============================--
function AchievementTaskView:updateTaskList(listData)
    local viewData       = self:getViewData()
    local taskList       = viewData.taskList
    local emptyTaksLayer = viewData.emptyTaksLayer
    local isShowList = next(listData) ~= nil
    taskList:setVisible(isShowList)
    emptyTaksLayer:setVisible(not isShowList)
    if isShowList ~= 0 then
        local count = table.nums(listData)
        taskList:setCountOfCell(count)
        taskList:reloadData()
    end
end

--==============================--
--desc: 更新成就进度
--@params newLvExp   新等级进度
--@params needLvExp  需要等级进度
--@return
--==============================--
function AchievementTaskView:updateAchieveProgress(newLvExp, needLvExp)
    local viewData = self:getViewData()
    local achieveNowExpLabel  = viewData.achieveNowExpLabel
    local achieveNeedExpLabel = viewData.achieveNeedExpLabel

    achieveNowExpLabel:setString(string.format(('%d'), newLvExp))
    achieveNeedExpLabel:setString(string.format(('/%d'), needLvExp))

    local achieveProgressBar = viewData.achieveProgressBar
    achieveProgressBar:setMaxValue(needLvExp)
    achieveProgressBar:setValue(newLvExp)
    
    local achieveLvLabel = viewData.achieveLvLabel
    display.commonLabelParams(achieveLvLabel, {text =  string.fmt(__('_num_级'), {['_num_'] = app.gameMgr:GetUserInfo().achieveLevel})})
end

--==============================--
--desc: 更新成就TAB显示状态
--@params sender    userdata tab
--@params isSelect  bool     是否选中
--@return
--==============================--
function AchievementTaskView:updateTabShowState(sender, isSelect)
    local img = isSelect and RES_DIR.TAB_SELECT or RES_DIR.TAB_DEFAULT
    sender:setNormalImage(img)
    sender:setSelectedImage(img)
end

--==============================--
--desc: 更新成就二级TAB显示状态
--@params sender    userdata tab
--@params isSelect  bool     是否选中
--@return
--==============================--
function AchievementTaskView:updateSencondTabShowState(sender, isSelect)
    local img = isSelect and RES_DIR.TAB_SECOND_SELECT or RES_DIR.TAB_SECOND_DEFAULT
    sender:setNormalImage(img)
    sender:setSelectedImage(img)
end


--==============================--
--desc: 创建红点图片
--@return img userdata
--==============================--
function AchievementTaskView:CreateRedPointImg()
    local redPointImg = display.newImageView(RES_DIR.RED_IMG, 0, 0)
    redPointImg:setVisible(false)
    return redPointImg
end

--==============================--
--desc: 创建成就cell
--@return img userdata
--==============================--
function AchievementTaskView:CreateAchievementCell(size)
    local cell = CGridViewCell:new()
	cell:setContentSize(size)

	local pExpLayoutSize = cc.size(116,167)
	local pExpLayout = display.newLayer(10, size.height / 2, { ap = display.LEFT_CENTER, size = pExpLayoutSize})
	cell:addChild(pExpLayout)

	local expBgImg = display.newImageView(_res('ui/home/task/main/achievement_bg_achievement_number'), pExpLayout:getContentSize().width*0.5,  pExpLayout:getContentSize().height*0.5,{scale9 = true ,size =pExpLayoutSize } )
	pExpLayout:addChild(expBgImg)
    --expBgImg:setVisible(false)

	local expNum = display.newButton(0, 0,{n = _res('ui/home/task/main/achievement_ico_achievement_number.png'), animate = false, enable = false})
	pExpLayout:addChild(expNum,1)
	display.commonLabelParams(expNum, fontWithColor('14', {text = 'ddd',offset= cc.p(0,-12)}))
	expNum:setPosition(cc.p(pExpLayout:getContentSize().width*0.5,  pExpLayout:getContentSize().height*0.5))
	expNum:setName('expNum')

	local achievementBg = display.newImageView(_res('ui/home/task/main/achievement_bg_task_default.png'), 0, 0, {ap = display.CENTER , size = cc.size(660,167) ,scale9 = true })

	local achievementBg_S = display.newImageView(_res('ui/home/task/main/achievement_bg_task_select.png'), 0, 0, {ap = display.CENTER, size = cc.size(660,167) ,scale9 = true})
	local achievementBgSize = achievementBg:getContentSize()
	local descLayer = display.newLayer(size.width - 8, size.height / 2, {ap = display.RIGHT_CENTER, size = achievementBgSize})
	display.commonUIParams(achievementBg, {po = utils.getLocalCenter(descLayer)})
	display.commonUIParams(achievementBg_S, {po = utils.getLocalCenter(descLayer)})
	achievementBg_S:setVisible(false)
	descLayer:addChild(achievementBg)
	descLayer:addChild(achievementBg_S)
	cell:addChild(descLayer)

	local titleBg = display.newImageView(_res('ui/home/task/task_bg_title.png'), 0, 0, {ap = display.LEFT_TOP})
	local titleBgSize = titleBg:getContentSize()
	display.commonUIParams(titleBg, {po = cc.p(0, achievementBgSize.height - 5)})
	descLayer:addChild(titleBg)
	local titleLabel = display.newLabel(10, titleBgSize.height / 2, fontWithColor(4,{text = '成就', ap = display.LEFT_CENTER}))
	titleBg:addChild(titleLabel)

	local descrLabel = display.newLabel(10, achievementBgSize.height * 0.45, fontWithColor(6, {fontSize = 20 ,  text = '在主线战斗子类中获得400个sssss',  w = 285, ap = display.LEFT_CENTER}))
	descLayer:addChild(descrLabel)

	local progressBar = CProgressBar:create(_res('ui/home/task/main/achievement_bar_2.png'))
    progressBar:setPosition(cc.p(descrLabel:getPositionX(), achievementBgSize.height * 0.17))
    progressBar:setBackgroundImage(_res('ui/home/task/main/achievement_bar_1.png'))
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
	progressBar:setAnchorPoint(display.LEFT_TOP)
	progressBar:setShowValueLabel(true)
	progressBar:setVisible(false)
	display.commonLabelParams(progressBar:getLabel(),fontWithColor('9'))
	descLayer:addChild(progressBar)

	local rewardLayer = display.newLayer(achievementBgSize.width * 0.55, achievementBgSize.height / 2, {ap = display.LEFT_CENTER, size = cc.size(achievementBgSize.width * 0.45, achievementBgSize.height)})
	descLayer:addChild(rewardLayer)

	local btn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
	display.commonUIParams(btn, {po = cc.p(achievementBgSize.width - 10, achievementBgSize.height * 0.5), ap = display.RIGHT_CENTER})
	display.commonLabelParams(btn, fontWithColor(14))
	btn:setVisible(false)
	descLayer:addChild(btn)

	local achievementReachBtn = display.newButton(achievementBgSize.width - 10, achievementBgSize.height * 0.5, {n = _res('ui/common/activity_mifan_by_ico.png'), animate = false, enable = false , ap = display.RIGHT_CENTER})
	display.commonLabelParams(achievementReachBtn, fontWithColor(14, {text = __('达成成就')}))
	achievementReachBtn:setVisible(false)
	descLayer:addChild(achievementReachBtn)

	cell.viewData = {
		expNum = expNum,
		descLayer = descLayer,
		achievementBg = achievementBg,
		achievementBg_S = achievementBg_S,
		titleLabel = titleLabel,
		descrLabel = descrLabel,
		progressBar = progressBar,
		rewardLayer = rewardLayer,
		btn = btn,
		achievementReachBtn = achievementReachBtn,
    }
    return cell
end

--==============================--
--desc: 更新成就cell
--@params data     table  成就数据
--@params viewData table  视图数据
--@return
--==============================--
function AchievementTaskView:updateAchievementCell(data, viewData)
    if data == nil or viewData == nil then return end

	local serverData    = data.serverData
	local taskConf      = checktable(data.conf)
	local showComplete  = data.showComplete
	local progress      = checkint(serverData.progress)
	local targetNum     = checkint(taskConf.targetNum) == 0 and 1 or checkint(taskConf.targetNum)
	local showProgress  = checkint(taskConf.showProgress)
	local rewards 	    = checktable(taskConf.rewards)
	local descr         = tostring(taskConf.descr)
	local taskType      = tostring(taskConf.taskType)
	local targetId      = taskConf.targetId

	local isComplete     = showComplete == 1
	local isReceive      = progress >= targetNum
	local isShowProgress = showProgress == 1

	local expNum              = viewData.expNum
	local achievementBg       = viewData.achievementBg
	local achievementBg_S     = viewData.achievementBg_S
	local titleLabel          = viewData.titleLabel
	local descrLabel          = viewData.descrLabel
	local progressBar         = viewData.progressBar
	local rewardLayer         = viewData.rewardLayer
	local btn                 = viewData.btn
	local achievementReachBtn = viewData.achievementReachBtn

	if targetId ~= '' then
		if TASK_TYPE.CARD_COLLECT_1 == taskType or TASK_TYPE.CARD_COLLECT_2 == taskType then
			local cardDatas = CommonUtils.GetConfig('cards', 'card', checkint(targetId))
			if cardDatas then
				descr = string.gsub(descr, targetId, tostring(cardDatas.name))
			end
		elseif TASK_TYPE.FOOD_COLLECT == taskType then
			local foodData = STYLE_COOKING_CONFS[tostring(targetId)]
			if foodData then
				local foodName = foodData.name or ''
				descr = string.fmt(descr, {['_food_id_'] = foodName})
			end
		elseif TASK_TYPE.TEAM_COLLECT == taskType then
			local goodData = OTHER_GOODS_CONFS[tostring(targetId)]
			if goodData then
				descr = string.gsub(descr, targetId, tostring(goodData.name))
			end
		end
	end

	display.commonLabelParams(expNum,     {text = tostring(taskConf.achieveExp)})
	display.commonLabelParams(titleLabel, {text = tostring(taskConf.name)})
	display.commonLabelParams(descrLabel, {text = descr})
	-- display.commonLabelParams(btn, {text = isReceive and __('领取') or __('前往')})
	achievementBg:setVisible(not (isReceive or isComplete))
	achievementBg_S:setVisible(isReceive or isComplete)

	if isReceive then
		btn:setNormalImage(_res('ui/common/common_btn_orange.png'))
		btn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
		btn:setText(__('领取'))
	else
		btn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		btn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		btn:setText(__('未完成'))
	end

	if rewardLayer:getChildrenCount() > 0 then
		rewardLayer:removeAllChildren()
	end

	for i,v in ipairs(taskConf.rewards) do
		local function callBack(sender)
			app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
		end
		local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, callBack = callBack})
		goodsNode:setPosition(cc.p(0 + (i - 1) * 90, rewardLayer:getContentSize().height/2))
		goodsNode:setScale(0.75)
		rewardLayer:addChild(goodsNode, 5)
	end

	progressBar:setVisible(isShowProgress)
	if isShowProgress then
		progressBar:setMaxValue(targetNum)
		progressBar:setValue(progress)
	end

	btn:setVisible(not isComplete)
	achievementReachBtn:setVisible(isComplete)
end

CreateView = function (size)
    local view = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})
    
    local contentSize = cc.size(1082, 641)
    local contentLayout = display.newLayer(543, VIEW_SIZE.height / 2, {ap = display.CENTER, size = contentSize})
    view:addChild(contentLayout)

    local bgSize = cc.size(994,570)
    local bgLayer = display.newLayer(contentSize.width / 2, contentSize.height / 2, 
        {ap = display.CENTER, size = bgSize})
    contentLayout:addChild(bgLayer)

    --------------------------
    -- top
    local topLayerSize = cc.size(bgSize.width, 120)
    local topLayer = display.newLayer(bgSize.width / 2, bgSize.height, 
        {ap = display.CENTER_TOP, size = topLayerSize})
    bgLayer:addChild(topLayer)

    -- achieve lv
    local cartonImg = display.newImageView(RES_DIR.CARTON_IMG, 20, topLayerSize.height / 2 + 13,
        {ap = cc.p(0.5, 0.5)})
    topLayer:addChild(cartonImg,1)

    local achieveLvBtn = display.newButton(0, 0,{n = RES_DIR.BG_LEVEL, animate = false,enable = false})
    topLayer:addChild(achieveLvBtn)
    display.commonLabelParams(achieveLvBtn, fontWithColor(14, {outline = '#7c7c7c', color = '#ffffff'}))
    achieveLvBtn:setPosition(cc.p(130, topLayerSize.height/2))
    local achieveLvLabel = achieveLvBtn:getLabel()

    achieveLvBtn:addChild(display.newLabel(achieveLvBtn:getContentSize().width * 0.5, achieveLvBtn:getContentSize().height * 0.5 - 50, fontWithColor(8,{text = __('成就等级'),fontSize = 18, ap = cc.p(0.5, 0.5)})))

    -- progress bar
    local barBgSize = cc.size(645,18)
    local achieveProgressBarBg = display.newNSprite(
        RES_DIR.BAR_BG,
        topLayerSize.width / 2 + 30,
        topLayerSize.height * 0.5 - 20,{scale9 = true, size = barBgSize})
    topLayer:addChild(achieveProgressBarBg, 10)

    local achieveProgressBar = CProgressBar:create(RES_DIR.BAR)
    achieveProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    achieveProgressBar:setAnchorPoint(cc.p(1, 0.5))
    achieveProgressBar:setMaxValue(100)
    achieveProgressBar:setValue(0)
    achieveProgressBar:setPosition(cc.p(barBgSize.width - 1, barBgSize.height / 2 ))
    achieveProgressBarBg:addChild(achieveProgressBar)
    achieveProgressBar:setScaleX(0.89)

    -- achievement completion progress
    local achieveNowExpLabel = cc.Label:createWithBMFont('font/common_num_unused.fnt', '')
    display.commonUIParams(achieveNowExpLabel, 
        {ap = display.RIGHT_CENTER, po = cc.p(achieveProgressBarBg:getPositionX(), topLayerSize.height / 2 + 12)})
    topLayer:addChild(achieveNowExpLabel, 1)

    local achieveNeedExpLabel = cc.Label:createWithBMFont('font/common_text_num.fnt', '')
    display.commonUIParams(achieveNeedExpLabel, 
        {ap = display.LEFT_CENTER, po = cc.p(achieveProgressBarBg:getPositionX(), topLayerSize.height / 2 + 8)})
    topLayer:addChild(achieveNeedExpLabel, 1)

    -- achieve reward
    local achieveRewardLayerSize = cc.size(95, 80)
    local achieveRewardLayer = display.newLayer(topLayerSize.width - 70, topLayerSize.height / 2, 
        {ap = display.CENTER, enable = true, color = cc.c4b(0,0,0,0), size = achieveRewardLayerSize})
    topLayer:addChild(achieveRewardLayer)

    local rewardBox = sp.SkeletonAnimation:create(RES_DIR.SPINE_BOX.json, RES_DIR.SPINE_BOX.atlas, 0.8)
    -- rewardBox:setToSetupPose()
    rewardBox:setAnimation(0, 'stop', true)
    rewardBox:setPosition(cc.p(achieveRewardLayerSize.width /2, achieveRewardLayerSize.height / 2))
    achieveRewardLayer:addChild(rewardBox,1)

    --------------------------
    -- centent
    local contentSize = cc.size(bgSize.width, 439)
    local contentLayer = display.newLayer(bgSize.width / 2, bgSize.height - 125, 
        {size = contentSize, ap = display.CENTER_TOP})
    bgLayer:addChild(contentLayer)

    -- tab list
    local tabListBgSize = cc.size(198, 440)
    local tabListBg = display.newImageView(RES_DIR.TAB_LIST_BG, 5, contentSize.height, {scale9 = true, size = tabListBgSize, ap = display.LEFT_TOP})
    contentLayer:addChild(tabListBg)

    local expandableListView = CExpandableListView:create(cc.size(tabListBgSize.width, 420))
    display.commonUIParams(expandableListView, {ap = display.CENTER, po = cc.p(tabListBg:getPositionX() + tabListBgSize.width / 2, tabListBgSize.height / 2)})
    expandableListView:setDirection(eScrollViewDirectionVertical)
    expandableListView:setName('expandableListView')
    contentLayer:addChild(expandableListView)

    -- task list
    local taskListBgSize = cc.size(782, 440)
    local listBg = display.newImageView(RES_DIR.TASK_LIST_BG, 208, contentSize.height,
        {scale9 = true, size = taskListBgSize, ap = display.LEFT_TOP})
    contentLayer:addChild(listBg)

    local taskListSize = cc.size(taskListBgSize.width - 2, taskListBgSize.height - 2)
	local taskListCellSize = cc.size(taskListSize.width, 180)
    local taskList = CGridView:create(taskListBgSize)
    display.commonUIParams(taskList, {ap = display.CENTER, po = cc.p(listBg:getPositionX() + taskListBgSize.width / 2, contentSize.height / 2)})
    taskList:setSizeOfCell(taskListCellSize)
    taskList:setColumns(1)
    taskList:setAutoRelocate(true)
    contentLayer:addChild(taskList)

    -- empty task layer
    local emptyTaksLayer = display.newLayer(contentSize.width / 2, contentSize.height / 2, {ap = display.CENTER, size = contentSize})
    contentLayer:addChild(emptyTaksLayer)

    local dialogueTips = display.newButton(0, 0, {ap = display.LEFT_CENTER, n = RES_DIR.DIALOGUE_TIPS})
    display.commonUIParams(dialogueTips, {po = cc.p(230, contentSize.height * 0.5)})
    display.commonLabelParams(dialogueTips,{text = __('未选择成就任务'), fontSize = 24, color = '#4c4c4c'})
    emptyTaksLayer:addChild(dialogueTips, 6)

    -- 中间小人
    local loadingCardQ = AssetsUtils.GetCartoonNode(3, dialogueTips:getPositionX() + dialogueTips:getContentSize().width + 160, contentSize.height * 0.5)
    loadingCardQ:setScale(0.6)
    emptyTaksLayer:addChild(loadingCardQ, 6)

    return {
        view                = view,
        achieveLvLabel      = achieveLvLabel,
        achieveProgressBar  = achieveProgressBar,
        achieveNowExpLabel  = achieveNowExpLabel,
        achieveNeedExpLabel = achieveNeedExpLabel,
        achieveRewardLayer  = achieveRewardLayer,
        rewardBox           = rewardBox,
        expandableListView  = expandableListView,
        taskList            = taskList,
        emptyTaksLayer      = emptyTaksLayer,
    }
end


function AchievementTaskView:getViewData()
	return self.viewData_
end

return AchievementTaskView