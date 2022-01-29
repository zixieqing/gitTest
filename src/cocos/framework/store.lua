--[[--
lua store ipa code
--]]
--[[
/**
* ios app store ipa
**/
--]]
CCStoreReceiptVerifyModeNone = 0
CCStoreReceiptVerifyModeDevice = 1
CCStoreReceiptVerifyModeServer = 2
CCStoreReceiptVerifyStatusUnknownError = -5
CCStoreReceiptVerifyStatusInvalidReceipt = -4
CCStoreReceiptVerifyStatusRequestFailed = -3
CCStoreReceiptVerifyStatusInvalidResult = -2
CCStoreReceiptVerifyStatusNone = -1
CCStoreReceiptVerifyStatusOK = 0

local appstore = {}

local function checkCCStore()
    if not CCStore then
        print("CCStore not exists")
        return false
	end
	return true
end

function appstore.init(listener)
	if not checkCCStore() then return false end
	if appstore.provider then
		print("store already init")
		return false
	end
	if type(listener) ~= 'function' then
	   print('listener is not a function')
		return false
	end
	appstore.provider = CCStore:getInstance()
	return appstore.provider:postInitWithTransactionListenerLua(listener)
end

function appstore.getReceiptVerifyMode()
    if not checkCCStore() then return false end
    return appstore.provider:getReceiptVerifyMode()
end

function appstore.setReceiptVerifyMode(mode, isSandbox)
    if not checkCCStore() then return false end

    if type(mode) ~= "number"
        or (mode ~= CCStoreReceiptVerifyModeNone
        and mode ~= CCStoreReceiptVerifyModeDevice
        and mode ~= CCStoreReceiptVerifyModeServer) then
        print("Store.setReceiptVerifyMode() - invalid mode")
        return false
    end

    if type(isSandbox) ~= "boolean" then isSandbox = true end
    appstore.provider:setReceiptVerifyMode(mode, isSandbox)
end

function appstore.getReceiptVerifyServerUrl()
    if not checkCCStore() then return false end
    return appstore.provider:getReceiptVerifyServerUrl()
end

function appstore.setReceiptVerifyServerUrl(url)
    if not checkCCStore() then return false end

    if type(url) ~= "string" then
        print("Store.setReceiptVerifyServerUrl() - invalid url")
        return false
    end
    appstore.provider:setReceiptVerifyServerUrl(url)
end

function appstore.canMakePurchases()
    if not checkCCStore() then return false end
    return appstore.provider:canMakePurchases()
end

function appstore.loadProducts(productsId, listener)
    if not checkCCStore() then return false end

    if type(listener) ~= "function" then
        print("Store.loadProducts() - invalid listener")
        return false
    end

    if type(productsId) ~= "table" then
        print("Store.loadProducts() - invalid productsId")
        return false
    end

    for i = 1, #productsId do
        cclog(tostring(productsId[i]))
        if type(productsId[i]) ~= "string" then
            print("Store.loadProducts() - invalid id[#%d] in productsId", i)
            return false
        end
    end

    appstore.provider:loadProductsLua(productsId, listener)
    return true
end

function appstore.cancelLoadProducts()
    if not checkCCStore() then return false end
    appstore.provider:cancelLoadProducts()
end

function appstore.isProductLoaded(productId)
    if not checkCCStore() then return false end
    return appstore.provider:isProductLoaded(productId)
end

function appstore.purchase(productId)
    if not checkCCStore() then return false end

    if not appstore.provider then
        print("Store.purchase() - store not init")
        return false
    end

    if type(productId) ~= "string" then
        print("Store.purchase() - invalid productId")
        return false
    end

    return appstore.provider:purchase(productId)
end

function appstore.restore()
   if not checkCCStore() then return false end
   appstore.provider:restore()
end

function appstore.finishTransaction(transaction)
    if not checkCCStore() then return false end

    if not appstore.provider then
        print("Store.finishTransaction() - store not init")
        return false
    end

    if type(transaction) ~= "table" or type(transaction.transactionIdentifier) ~= "string" then
        print("Store.finishTransaction() - invalid transaction")
        return false
    end

    return appstore.provider:finishTransactionLua(transaction.transactionIdentifier)
end

return appstore
