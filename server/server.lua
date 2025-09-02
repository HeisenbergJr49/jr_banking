ESX = nil
local playerAccounts = {}
local rateLimitData = {}

-- Initialize ESX
if Config.Framework == 'esx' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

-- Rate limiting function
local function checkRateLimit(source)
    if not Config.AntiCheat.enabled then return true end
    
    local playerId = tostring(source)
    local currentTime = os.time()
    
    if not rateLimitData[playerId] then
        rateLimitData[playerId] = {requests = {}, transactions = {}}
    end
    
    local playerData = rateLimitData[playerId]
    
    -- Clean old requests
    for i = #playerData.requests, 1, -1 do
        if currentTime - playerData.requests[i] > 1 then
            table.remove(playerData.requests, i)
        end
    end
    
    -- Check requests per second
    if #playerData.requests >= Config.AntiCheat.maxRequestsPerSecond then
        return false
    end
    
    table.insert(playerData.requests, currentTime)
    return true
end

-- Initialize player account
local function initializeAccount(identifier, name)
    MySQL.Async.fetchScalar('SELECT id FROM jr_banking_accounts WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(accountId)
        if not accountId then
            -- Create new account
            MySQL.Async.execute('INSERT INTO jr_banking_accounts (identifier, name, balance) VALUES (@identifier, @name, @balance)', {
                ['@identifier'] = identifier,
                ['@name'] = name,
                ['@balance'] = Config.StartCash
            }, function(insertId)
                playerAccounts[identifier] = {
                    id = insertId,
                    identifier = identifier,
                    name = name,
                    balance = Config.StartCash,
                    pin_code = nil,
                    pin_attempts = 0,
                    locked_until = nil
                }
            end)
        else
            -- Load existing account
            MySQL.Async.fetchAll('SELECT * FROM jr_banking_accounts WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(result)
                if result[1] then
                    local account = result[1]
                    playerAccounts[identifier] = {
                        id = account.id,
                        identifier = account.identifier,
                        name = account.name,
                        balance = account.balance,
                        pin_code = account.pin_code,
                        pin_attempts = account.pin_attempts,
                        locked_until = account.locked_until
                    }
                end
            end)
        end
    end)
end

-- Log transaction
local function logTransaction(fromIdentifier, toIdentifier, amount, transactionType, description, referenceId)
    if not Config.EnableLogging then return end
    
    MySQL.Async.execute('INSERT INTO jr_banking_transactions (from_identifier, to_identifier, amount, type, description, reference_id) VALUES (@from_identifier, @to_identifier, @amount, @type, @description, @reference_id)', {
        ['@from_identifier'] = fromIdentifier,
        ['@to_identifier'] = toIdentifier,
        ['@amount'] = amount,
        ['@type'] = transactionType,
        ['@description'] = description,
        ['@reference_id'] = referenceId
    })
end

-- Update account balance
local function updateAccountBalance(identifier, newBalance)
    MySQL.Async.execute('UPDATE jr_banking_accounts SET balance = @balance, updated_at = NOW() WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@balance'] = newBalance
    })
    
    if playerAccounts[identifier] then
        playerAccounts[identifier].balance = newBalance
    end
end

-- Generate unique reference ID
local function generateReferenceId()
    return string.upper(string.format('%08x', math.random(0, 0xFFFFFFFF)))
end

-- Player connected
AddEventHandler('playerConnecting', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            initializeAccount(identifier, xPlayer.getName())
        end
    end
end)

-- Player dropped
AddEventHandler('playerDropped', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if playerAccounts[identifier] then
        playerAccounts[identifier] = nil
    end
    
    if rateLimitData[tostring(source)] then
        rateLimitData[tostring(source)] = nil
    end
end)

-- Get account info
RegisterServerEvent('jr_banking:getAccountInfo')
AddEventHandler('jr_banking:getAccountInfo', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if not checkRateLimit(source) then
        TriggerClientEvent('jr_banking:notify', source, 'Too many requests. Please wait.', 'error')
        return
    end
    
    if playerAccounts[identifier] then
        local account = playerAccounts[identifier]
        TriggerClientEvent('jr_banking:receiveAccountInfo', source, {
            balance = account.balance,
            name = account.name,
            hasPIN = account.pin_code ~= nil,
            isLocked = account.locked_until and os.time() < account.locked_until
        })
    else
        -- Account not loaded yet, try to load from database
        MySQL.Async.fetchAll('SELECT * FROM jr_banking_accounts WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(result)
            if result[1] then
                local account = result[1]
                playerAccounts[identifier] = account
                TriggerClientEvent('jr_banking:receiveAccountInfo', source, {
                    balance = account.balance,
                    name = account.name,
                    hasPIN = account.pin_code ~= nil,
                    isLocked = account.locked_until and os.time() < account.locked_until
                })
            end
        end)
    end
end)

-- Deposit money
RegisterServerEvent('jr_banking:deposit')
AddEventHandler('jr_banking:deposit', function(amount)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if not checkRateLimit(source) then
        TriggerClientEvent('jr_banking:notify', source, 'Too many requests. Please wait.', 'error')
        return
    end
    
    if not amount or amount <= 0 or amount > Config.MaxDepositAmount then
        TriggerClientEvent('jr_banking:notify', source, 'Invalid amount', 'error')
        return
    end
    
    if Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.getMoney() >= amount then
            xPlayer.removeMoney(amount)
            
            local account = playerAccounts[identifier]
            if account then
                local newBalance = account.balance + amount
                updateAccountBalance(identifier, newBalance)
                
                logTransaction(identifier, nil, amount, 'deposit', 'Cash deposit', generateReferenceId())
                
                TriggerClientEvent('jr_banking:notify', source, string.format('Deposited $%s successfully', amount), 'success')
                TriggerClientEvent('jr_banking:receiveAccountInfo', source, {
                    balance = newBalance,
                    name = account.name,
                    hasPIN = account.pin_code ~= nil,
                    isLocked = account.locked_until and os.time() < account.locked_until
                })
            end
        else
            TriggerClientEvent('jr_banking:notify', source, 'Insufficient cash', 'error')
        end
    end
end)

-- Withdraw money
RegisterServerEvent('jr_banking:withdraw')
AddEventHandler('jr_banking:withdraw', function(amount, pin)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if not checkRateLimit(source) then
        TriggerClientEvent('jr_banking:notify', source, 'Too many requests. Please wait.', 'error')
        return
    end
    
    if not amount or amount <= 0 or amount > Config.MaxWithdrawAmount then
        TriggerClientEvent('jr_banking:notify', source, 'Invalid amount', 'error')
        return
    end
    
    local account = playerAccounts[identifier]
    if not account then
        TriggerClientEvent('jr_banking:notify', source, 'Account not found', 'error')
        return
    end
    
    -- Check if account is locked
    if account.locked_until and os.time() < account.locked_until then
        TriggerClientEvent('jr_banking:notify', source, 'Account is temporarily locked', 'error')
        return
    end
    
    -- Verify PIN if required
    if Config.RequirePIN and account.pin_code then
        if not pin or account.pin_code ~= pin then
            account.pin_attempts = account.pin_attempts + 1
            
            MySQL.Async.execute('UPDATE jr_banking_accounts SET pin_attempts = @attempts WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
                ['@attempts'] = account.pin_attempts
            })
            
            if account.pin_attempts >= Config.MaxPINAttempts then
                local lockTime = os.time() + Config.LockoutTime
                account.locked_until = lockTime
                
                MySQL.Async.execute('UPDATE jr_banking_accounts SET locked_until = FROM_UNIXTIME(@lockTime) WHERE identifier = @identifier', {
                    ['@identifier'] = identifier,
                    ['@lockTime'] = lockTime
                })
                
                TriggerClientEvent('jr_banking:notify', source, string.format('Account locked for %d minutes due to failed PIN attempts', Config.LockoutTime / 60), 'error')
            else
                TriggerClientEvent('jr_banking:notify', source, string.format('Invalid PIN. %d attempts remaining', Config.MaxPINAttempts - account.pin_attempts), 'error')
            end
            return
        end
        
        -- Reset PIN attempts on successful verification
        if account.pin_attempts > 0 then
            account.pin_attempts = 0
            MySQL.Async.execute('UPDATE jr_banking_accounts SET pin_attempts = 0 WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            })
        end
    end
    
    if account.balance >= amount then
        if Config.Framework == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.addMoney(amount)
                
                local newBalance = account.balance - amount
                updateAccountBalance(identifier, newBalance)
                
                logTransaction(identifier, nil, amount, 'withdraw', 'Cash withdrawal', generateReferenceId())
                
                TriggerClientEvent('jr_banking:notify', source, string.format('Withdrawn $%s successfully', amount), 'success')
                TriggerClientEvent('jr_banking:receiveAccountInfo', source, {
                    balance = newBalance,
                    name = account.name,
                    hasPIN = account.pin_code ~= nil,
                    isLocked = account.locked_until and os.time() < account.locked_until
                })
            end
        end
    else
        TriggerClientEvent('jr_banking:notify', source, 'Insufficient funds', 'error')
    end
end)

-- Transfer money
RegisterServerEvent('jr_banking:transfer')
AddEventHandler('jr_banking:transfer', function(targetId, amount, pin)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    local targetIdentifier = GetPlayerIdentifier(targetId, 0)
    
    if not checkRateLimit(source) then
        TriggerClientEvent('jr_banking:notify', source, 'Too many requests. Please wait.', 'error')
        return
    end
    
    if not amount or amount <= 0 or amount > Config.MaxTransferAmount then
        TriggerClientEvent('jr_banking:notify', source, 'Invalid amount', 'error')
        return
    end
    
    if identifier == targetIdentifier then
        TriggerClientEvent('jr_banking:notify', source, 'Cannot transfer to yourself', 'error')
        return
    end
    
    local fromAccount = playerAccounts[identifier]
    if not fromAccount then
        TriggerClientEvent('jr_banking:notify', source, 'Account not found', 'error')
        return
    end
    
    -- Check if account is locked
    if fromAccount.locked_until and os.time() < fromAccount.locked_until then
        TriggerClientEvent('jr_banking:notify', source, 'Account is temporarily locked', 'error')
        return
    end
    
    -- Verify PIN if required
    if Config.RequirePIN and fromAccount.pin_code and fromAccount.pin_code ~= pin then
        TriggerClientEvent('jr_banking:notify', source, 'Invalid PIN', 'error')
        return
    end
    
    -- Calculate fee
    local fee = math.max(Config.MinTransferFee, math.min(Config.MaxTransferFee, math.floor(amount * Config.TransferFee)))
    local totalDeduction = amount + fee
    
    if fromAccount.balance >= totalDeduction then
        -- Check if target account exists
        MySQL.Async.fetchAll('SELECT * FROM jr_banking_accounts WHERE identifier = @identifier', {
            ['@identifier'] = targetIdentifier
        }, function(result)
            if result[1] then
                local referenceId = generateReferenceId()
                
                -- Deduct from sender
                local newFromBalance = fromAccount.balance - totalDeduction
                updateAccountBalance(identifier, newFromBalance)
                
                -- Add to recipient
                local toAccount = result[1]
                local newToBalance = toAccount.balance + amount
                updateAccountBalance(targetIdentifier, newToBalance)
                
                -- Log transactions
                logTransaction(identifier, targetIdentifier, amount, 'transfer_out', string.format('Transfer to %s', toAccount.name), referenceId)
                logTransaction(targetIdentifier, identifier, amount, 'transfer_in', string.format('Transfer from %s', fromAccount.name), referenceId)
                
                if fee > 0 then
                    logTransaction(identifier, nil, fee, 'fee', 'Transfer fee', referenceId)
                end
                
                TriggerClientEvent('jr_banking:notify', source, string.format('Transferred $%s to %s (Fee: $%s)', amount, toAccount.name, fee), 'success')
                TriggerClientEvent('jr_banking:notify', targetId, string.format('Received $%s from %s', amount, fromAccount.name), 'success')
                
                -- Update sender's account info
                TriggerClientEvent('jr_banking:receiveAccountInfo', source, {
                    balance = newFromBalance,
                    name = fromAccount.name,
                    hasPIN = fromAccount.pin_code ~= nil,
                    isLocked = fromAccount.locked_until and os.time() < fromAccount.locked_until
                })
                
                -- Update recipient's account info if online
                if playerAccounts[targetIdentifier] then
                    playerAccounts[targetIdentifier].balance = newToBalance
                    TriggerClientEvent('jr_banking:receiveAccountInfo', targetId, {
                        balance = newToBalance,
                        name = toAccount.name,
                        hasPIN = toAccount.pin_code ~= nil,
                        isLocked = toAccount.locked_until and os.time() < toAccount.locked_until
                    })
                end
            else
                TriggerClientEvent('jr_banking:notify', source, 'Target player does not have a bank account', 'error')
            end
        end)
    else
        TriggerClientEvent('jr_banking:notify', source, 'Insufficient funds (including transfer fee)', 'error')
    end
end)

-- Set PIN
RegisterServerEvent('jr_banking:setPIN')
AddEventHandler('jr_banking:setPIN', function(newPIN)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if not checkRateLimit(source) then
        TriggerClientEvent('jr_banking:notify', source, 'Too many requests. Please wait.', 'error')
        return
    end
    
    if not newPIN or string.len(newPIN) ~= Config.PINLength then
        TriggerClientEvent('jr_banking:notify', source, string.format('PIN must be %d digits', Config.PINLength), 'error')
        return
    end
    
    local account = playerAccounts[identifier]
    if account then
        MySQL.Async.execute('UPDATE jr_banking_accounts SET pin_code = @pin WHERE identifier = @identifier', {
            ['@identifier'] = identifier,
            ['@pin'] = newPIN
        }, function(affectedRows)
            if affectedRows > 0 then
                account.pin_code = newPIN
                TriggerClientEvent('jr_banking:notify', source, 'PIN set successfully', 'success')
            else
                TriggerClientEvent('jr_banking:notify', source, 'Failed to set PIN', 'error')
            end
        end)
    end
end)

-- Get transaction history
RegisterServerEvent('jr_banking:getTransactionHistory')
AddEventHandler('jr_banking:getTransactionHistory', function(limit)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if not checkRateLimit(source) then
        TriggerClientEvent('jr_banking:notify', source, 'Too many requests. Please wait.', 'error')
        return
    end
    
    limit = limit or 50
    
    MySQL.Async.fetchAll('SELECT * FROM jr_banking_transactions WHERE from_identifier = @identifier OR to_identifier = @identifier ORDER BY created_at DESC LIMIT @limit', {
        ['@identifier'] = identifier,
        ['@limit'] = limit
    }, function(result)
        TriggerClientEvent('jr_banking:receiveTransactionHistory', source, result)
    end)
end)

print('^2[jr_banking]^7 Server initialized successfully!')