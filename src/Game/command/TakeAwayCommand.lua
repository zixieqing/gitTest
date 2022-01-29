local SimpleCommand = mvc.SimpleCommand


local TakeAwayCommand = class("TakeAwayCommand", SimpleCommand)


function TakeAwayCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function TakeAwayCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local body = signal:GetBody()
    local action = body.action
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMANDS_TAKEAWAY then
        if action == 'Takeaway/home' then
            httpManager:Post("Takeaway/home",SIGNALNAMES.SIGNALNAMES_TAKEAWAY_HOME)
        elseif action == 'Takeaway/unlockDiningCar' then
            --解锁
            httpManager:Post("Takeaway/unlockDiningCar",SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UNLOCK_CAR,body)
        elseif action == 'Takeaway/upgradeDiningCar' then
            --升级外卖车
            httpManager:Post("Takeaway/upgradeDiningCar",SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UPGRADE_CAR,body)
        elseif action == 'Takeaway/draw' then
            --领取奖励
        elseif action == 'Takeaway/delivery' then
            --发车
        elseif action == 'Takeaway/deliveryList' then
            --外卖列表
        elseif action == 'Takeaway/robbery' then
            --打劫外卖
        end
    end
end

return TakeAwayCommand