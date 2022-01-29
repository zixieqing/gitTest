--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 拼图游戏 中介者
]]
local Anniversary20PuzzleView     = require('Game.views.anniversary20.Anniversary20PuzzleView')
local Anniversary20PuzzleMediator = class('Anniversary20PuzzleMediator', mvc.Mediator)

function Anniversary20PuzzleMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'Anniversary20PuzzleMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


local DONATE_INPUT_MAX   = Anniversary20PuzzleView.DONATE_INPUT_MAX


-------------------------------------------------
-- inheritance

function Anniversary20PuzzleMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = Anniversary20PuzzleView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
    ui.bindClick(self:getViewData().puzzleCollectNode, handler(self, self.onClickCollectButtonHandler_))
    ui.bindClick(self:getViewData().puzzleBuffNode, handler(self, self.onClickBuffButtonHandler_))
    for _, cellNode in ipairs(self:getViewData().puzzleCells) do
        ui.bindClick(cellNode, handler(self, self.onClickPuzzleCellHandler_), false)
    end

    self.isControllable_ = false
end


function Anniversary20PuzzleMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function Anniversary20PuzzleMediator:OnRegist()
    regPost(POST.ANNIV2020_PUZZLE_HOME)
    regPost(POST.ANNIV2020_PUZZLE_COMMIT)

    self:getViewNode():showUI(function()
        self.isControllable_ = true
        self:SendSignal(POST.ANNIV2020_PUZZLE_HOME.cmdName)
    end) 
end


function Anniversary20PuzzleMediator:OnUnRegist()
    unregPost(POST.ANNIV2020_PUZZLE_HOME)
    unregPost(POST.ANNIV2020_PUZZLE_COMMIT)
end


function Anniversary20PuzzleMediator:InterestSignals()
    return {
        POST.ANNIV2020_PUZZLE_HOME.sglName,
        POST.ANNIV2020_PUZZLE_COMMIT.sglName,
    }
end
function Anniversary20PuzzleMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.ANNIV2020_PUZZLE_HOME.sglName then
        self:initHomeData_(data)
        
        -- 上次播放未开始，挂了，再次上线时重新播放
        if LOCAL.ANNIV2020.PUZZLE_UNLOCKED_ANIM_PROGRESS():Load() >= CONF.ANNIV2020.PUZZLE_GAME:GetLength() then
            app.anniv2020Mgr:checkPlayPuzzleCompletedStory()
        end


    elseif name == POST.ANNIV2020_PUZZLE_COMMIT.sglName then
        -- 消耗捐献道具
        CommonUtils.DrawRewards({
            {goodsId = app.anniv2020Mgr:getPuzzleGoodsId(), num = -self:getDonateGoodsNum()}
        })

        -- 获得奖励
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards, closeCallback = function()
            -- 刷新进度
            self:initHomeData_(data)
        end})
        
        -- 重置使用次数
        self:setDonateGoodsNum(math.min(self:getPuzzleGoodsNum(), DONATE_INPUT_MAX))
    end
end


-------------------------------------------------
-- get / set

function Anniversary20PuzzleMediator:getViewNode()
    return  self.viewNode_
end
function Anniversary20PuzzleMediator:getViewData()
    return self:getViewNode():getViewData()
end


function Anniversary20PuzzleMediator:getNewUnlockStoryIndex()
    return checkint(self.newUnlockStoryIndex_)
end
function Anniversary20PuzzleMediator:setNewUnlockStoryIndex(cellIndex)
    self.newUnlockStoryIndex_ = checkint(cellIndex)
    self:getViewNode():refreshUnlockStorySpinePos(self:getNewUnlockStoryIndex())
end


function Anniversary20PuzzleMediator:getDonateGoodsNum()
    return checkint(self.donateGoodsNum_)
end
function Anniversary20PuzzleMediator:setDonateGoodsNum(goodsNum)
    self.donateGoodsNum_ = checkint(goodsNum)
    self:getViewNode():refreshDonateLayerGoodNum(self:getDonateGoodsNum())
end


function Anniversary20PuzzleMediator:getPuzzleGoodsNum()
    return app.gameMgr:GetAmountByIdForce(app.anniv2020Mgr:getPuzzleGoodsId())
end


-------------------------------------------------
-- public

function Anniversary20PuzzleMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function Anniversary20PuzzleMediator:initHomeData_(homeData)
    -- update puzzleProgress
    app.anniv2020Mgr:setPuzzlesProgress(homeData.progress)

    self:refreshPuzzleState()
end


function Anniversary20PuzzleMediator:refreshCurStoryIndex()
    local puzzleUnlockedNum         = app.anniv2020Mgr:getPuzzlesUnlockNum()
    local puzzleUnlockedLocalDefine = LOCAL.ANNIV2020.PUZZLE_UNLOCKED_ANIM_PROGRESS()
    local lastUnlockedPuzzleIndex   = math.min(puzzleUnlockedLocalDefine:Load() + 1, puzzleUnlockedNum)

    local newUnlockStoryIndex = 0
    for puzzleId = 1, lastUnlockedPuzzleIndex do
        local puzzleConf = CONF.ANNIV2020.PUZZLE_GAME:GetValue(puzzleId)
        local isUnlock   = app.anniv2020Mgr:isStoryUnlocked(puzzleConf.story)
        if not isUnlock then
            newUnlockStoryIndex = puzzleId
            break
        end
    end
    self:setNewUnlockStoryIndex(newUnlockStoryIndex)
end


function Anniversary20PuzzleMediator:refreshPuzzleState()
    local puzzleUnlockedNum         = app.anniv2020Mgr:getPuzzlesUnlockNum()
    local puzzleUnlockedLocalDefine = LOCAL.ANNIV2020.PUZZLE_UNLOCKED_ANIM_PROGRESS()
    local lastUnlockedPuzzleIndex   = math.min(puzzleUnlockedLocalDefine:Load(), puzzleUnlockedNum)

    -- update prev unlock cells
    for puzzleId = 1, lastUnlockedPuzzleIndex do
        local puzzleCell = self:getViewData().puzzleCells[puzzleId]
        self:getViewNode():removePuzzleCellCardSpine(puzzleCell)
    end

    -- update unlocking 
    if lastUnlockedPuzzleIndex + 1 <= puzzleUnlockedNum then
        self.isControllable_ = false
        self:getViewNode():addPuzzleUnlockingAnimation(function()
            self.isControllable_ = true
        end)
        puzzleUnlockedLocalDefine:Save(puzzleUnlockedNum)
    end
    for puzzleId = lastUnlockedPuzzleIndex + 1, puzzleUnlockedNum do
        local puzzleCell = self:getViewData().puzzleCells[puzzleId]
        self:getViewNode():removePuzzleCellCardSpine(puzzleCell)
    end

    -- update unlock story cell
    self:refreshCurStoryIndex()

    -- update unlock progress cell
    local prevPuzzleConf = CONF.ANNIV2020.PUZZLE_GAME:GetValue(puzzleUnlockedNum) or {}
    local currPuzzleConf = CONF.ANNIV2020.PUZZLE_GAME:GetValue(puzzleUnlockedNum + 1) or {}
    local puzzleProgress = app.anniv2020Mgr:getPuzzlesProgress()
    self:getViewNode():updateProgressValue(puzzleProgress - checkint(prevPuzzleConf.num), checkint(currPuzzleConf.num) - checkint(prevPuzzleConf.num))
    self:getViewNode():updateProgressNodePosition()

    -- update skill value
    self:getViewNode():updateBuffButtonValue()
end


-----------------------------------------------------------------------------------------------
-- handler
-----------------------------------------------------------------------------------------------

------------------------------------------------------ top Handler
function Anniversary20PuzzleMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function Anniversary20PuzzleMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.ANNIV20_PUZZLE})
end


---------------------------------------------------------- center view handler
function Anniversary20PuzzleMediator:onClickPuzzleCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local puzzleIndex = checkint(sender:getTag())
    local puzzleConf  = CONF.ANNIV2020.PUZZLE_GAME:GetValue(puzzleIndex)
    local isUnlock    = app.anniv2020Mgr:isStoryUnlocked(checkint(puzzleConf.story))

    if isUnlock then
        app.anniv2020Mgr:playStory(puzzleConf.story)

    elseif self:getNewUnlockStoryIndex() == puzzleIndex then
        app.anniv2020Mgr:toUnlockStory(puzzleConf.story, function()
            local unlockStoryIndex = self:getNewUnlockStoryIndex() + 1
            local puzzleUnlockNum = app.anniv2020Mgr:getPuzzlesUnlockNum()
            local newUnlockStoryIndex = unlockStoryIndex > puzzleUnlockNum and 0 or unlockStoryIndex
            self:setNewUnlockStoryIndex(newUnlockStoryIndex)

            if checkint(puzzleConf.id) == CONF.ANNIV2020.PUZZLE_GAME:GetLength() then
                app.anniv2020Mgr:playStory(puzzleConf.story, function()
                    app.anniv2020Mgr:checkPlayPuzzleCompletedStory()
                end)
            else
                app.anniv2020Mgr:playStory(puzzleConf.story)
            end
        end)

    elseif app.anniv2020Mgr:getPuzzlesUnlockNum() >= puzzleIndex then
        app.uiMgr:ShowInformationTips(__("请先解锁前置剧情"))

    else
        app.uiMgr:ShowInformationTips(__('拼图被污染了，收集糖果，使拼图恢复原样吧！'))
    end
end


-- handler to open donate view, 
function Anniversary20PuzzleMediator:onClickCollectButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- show donateLayer
    self:getViewNode():updateDonateLayerVisible(true, function(viewData)
        local addBtn = viewData.addBtn
        addBtn:setTag(2)
        ui.bindClick(addBtn, handler(self, self.onClickSetNumBtnHandler_))
        
        local delBtn = viewData.delBtn
        delBtn:setTag(1)
        ui.bindClick(delBtn, handler(self, self.onClickSetNumBtnHandler_))
        
        ui.bindClick(viewData.inputBtn, handler(self, self.onClickDonateNumInputButtonHandler_))
        ui.bindClick(viewData.confirmBtn, handler(self, self.onClickDonateConfirmBtnHandler_))
        ui.bindClick(viewData.blockLayer, handler(self, self.onClickDonateBlockLayerHandler_))
    end)
    
    -- update donateNum
    self:setDonateGoodsNum(math.min(self:getPuzzleGoodsNum(), DONATE_INPUT_MAX))
end


-- handler to open buff view
function Anniversary20PuzzleMediator:onClickBuffButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():updateBuffDetailLayerVisible(true, function(viewData)
        ui.bindClick(viewData.buffClickView, handler(self, self.onClickBuffViewBlackHandler_), false)
    end)
end


---------------------------------------------------------------- donate view handler
function Anniversary20PuzzleMediator:onClickDonateBlockLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():updateDonateLayerVisible(false)
end


function Anniversary20PuzzleMediator:onClickDonateConfirmBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- 检测消耗 --
    if self:getDonateGoodsNum() <= 0 or self:getPuzzleGoodsNum() < self:getDonateGoodsNum() then
        app.uiMgr:ShowInformationTips(__('道具数量不足'))
        return
    end

    self:SendSignal(POST.ANNIV2020_PUZZLE_COMMIT.cmdName, {num = self:getDonateGoodsNum()})
end


--  加减数量回调
function Anniversary20PuzzleMediator:onClickSetNumBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local senderTag = checkint(sender:getTag())
	if senderTag == 1 then --减
        self:setDonateGoodsNum(math.max(self:getDonateGoodsNum() - 1, 0))

    elseif senderTag == 2 then--加
        local maxLimit = math.min(self:getPuzzleGoodsNum(), DONATE_INPUT_MAX)
		if self:getDonateGoodsNum() >= maxLimit then
			app.uiMgr:ShowInformationTips(__('已达拥有数量上限'))
		else
            self:setDonateGoodsNum(math.min(self:getDonateGoodsNum() + 1, maxLimit))
		end
    end
end


-- 打开数字键盘
function Anniversary20PuzzleMediator:onClickDonateNumInputButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

	local tempData = {
        callback  = handler(self, self.onClickDonateKeyBoardReturnBtnHandler_),
        titleText = __('请输入要使用的道具数量'),
        nums      = DONATE_INPUT_MAX,
        model     = NumboardModel.freeModel,
    }
	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' ) 
	local mediator = NumKeyboardMediator.new(tempData)
	app:RegistMediator(mediator)
end

 
-- 确认数字键盘回调
function Anniversary20PuzzleMediator:onClickDonateKeyBoardReturnBtnHandler_(data)
	if data then
        local inputNum = math.max(checkint(data), 0)
        self:setDonateGoodsNum(math.min(DONATE_INPUT_MAX, math.min(self:getPuzzleGoodsNum(), inputNum)))
	end
end


----------------------------------------------------------------  buff view handler
function Anniversary20PuzzleMediator:onClickBuffViewBlackHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():updateBuffDetailLayerVisible(false)
end


return Anniversary20PuzzleMediator
