ESX = nil
local playerLoaded = false
local bankingUI = false
local currentATM = nil
local inBankZone = false

-- Initialize ESX
if Config.Framework == 'esx' then
    Citizen.CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
        
        while ESX.GetPlayerData().job == nil do
            Citizen.Wait(10)
        end
        
        playerLoaded = true
    end)
end

-- Utility functions
local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function formatMoney(amount)
    local formatted = tostring(amount)
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return '$' .. formatted
end

-- Draw text function
local function DrawText3D(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov * (scale or 0.35)
    
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropShadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Open banking UI
local function openBankingUI()
    if not playerLoaded then return end
    
    bankingUI = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openBanking',
        config = {
            maxWithdraw = Config.MaxWithdrawAmount,
            maxDeposit = Config.MaxDepositAmount,
            maxTransfer = Config.MaxTransferAmount,
            requirePIN = Config.RequirePIN,
            pinLength = Config.PINLength,
            transferFee = Config.TransferFee * 100, -- Convert to percentage
            minTransferFee = Config.MinTransferFee,
            maxTransferFee = Config.MaxTransferFee,
            ui = Config.UISettings
        }
    })
    
    -- Request account info
    TriggerServerEvent('jr_banking:getAccountInfo')
end

-- Close banking UI
local function closeBankingUI()
    bankingUI = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeBanking'
    })
end

-- ATM/Bank interaction
local function createATMBlips()
    for _, atm in pairs(Config.ATMLocations) do
        local blip = AddBlipForCoord(atm.x, atm.y, atm.z)
        SetBlipSprite(blip, 277)
        SetBlipColour(blip, 2)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("ATM")
        EndTextCommandSetBlipName(blip)
    end
end

local function createBankBlips()
    for _, bank in pairs(Config.BankLocations) do
        local blip = AddBlipForCoord(bank.x, bank.y, bank.z)
        SetBlipSprite(blip, 108)
        SetBlipColour(blip, 2)
        SetBlipScale(blip, 0.9)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Bank")
        EndTextCommandSetBlipName(blip)
    end
end

-- Main thread for ATM/Bank detection
Citizen.CreateThread(function()
    createATMBlips()
    createBankBlips()
    
    while true do
        Citizen.Wait(0)
        
        if playerLoaded then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local nearATM = false
            local nearBank = false
            
            -- Check ATM proximity
            for _, atm in pairs(Config.ATMLocations) do
                local distance = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, atm.x, atm.y, atm.z, true)
                
                if distance < 2.5 then
                    nearATM = true
                    DrawText3D(atm.x, atm.y, atm.z + 1.0, "~g~[E]~w~ Use ATM", 0.35)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        currentATM = atm
                        openBankingUI()
                    end
                    break
                end
            end
            
            -- Check Bank proximity
            for _, bank in pairs(Config.BankLocations) do
                local distance = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, bank.x, bank.y, bank.z, true)
                
                if distance < 3.0 then
                    nearBank = true
                    inBankZone = true
                    DrawText3D(bank.x, bank.y, bank.z + 1.0, "~g~[E]~w~ Access Bank", 0.35)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        openBankingUI()
                    end
                    break
                else
                    inBankZone = false
                end
            end
            
            -- Close UI if moved away
            if bankingUI and not nearATM and not nearBank then
                closeBankingUI()
            end
        end
    end
end)

-- Key controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if bankingUI then
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 18, true) -- Enter
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            
            if IsDisabledControlJustPressed(0, 322) then -- ESC
                closeBankingUI()
            end
        end
    end
end)

-- Event handlers
RegisterNetEvent('jr_banking:receiveAccountInfo')
AddEventHandler('jr_banking:receiveAccountInfo', function(accountInfo)
    SendNUIMessage({
        type = 'updateAccountInfo',
        data = accountInfo
    })
end)

RegisterNetEvent('jr_banking:receiveTransactionHistory')
AddEventHandler('jr_banking:receiveTransactionHistory', function(transactions)
    SendNUIMessage({
        type = 'updateTransactionHistory',
        data = transactions
    })
end)

RegisterNetEvent('jr_banking:notify')
AddEventHandler('jr_banking:notify', function(message, type)
    SendNUIMessage({
        type = 'notification',
        message = message,
        notificationType = type or 'info'
    })
end)

-- NUI Callbacks
RegisterNUICallback('closeBanking', function(data, cb)
    closeBankingUI()
    cb('ok')
end)

RegisterNUICallback('deposit', function(data, cb)
    local amount = tonumber(data.amount)
    if amount and amount > 0 then
        TriggerServerEvent('jr_banking:deposit', amount)
        cb('ok')
    else
        cb('error')
    end
end)

RegisterNUICallback('withdraw', function(data, cb)
    local amount = tonumber(data.amount)
    local pin = data.pin
    
    if amount and amount > 0 then
        TriggerServerEvent('jr_banking:withdraw', amount, pin)
        cb('ok')
    else
        cb('error')
    end
end)

RegisterNUICallback('transfer', function(data, cb)
    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)
    local pin = data.pin
    
    if targetId and amount and amount > 0 then
        TriggerServerEvent('jr_banking:transfer', targetId, amount, pin)
        cb('ok')
    else
        cb('error')
    end
end)

RegisterNUICallback('setPIN', function(data, cb)
    local newPIN = data.pin
    if newPIN and string.len(newPIN) == Config.PINLength then
        TriggerServerEvent('jr_banking:setPIN', newPIN)
        cb('ok')
    else
        cb('error')
    end
end)

RegisterNUICallback('getTransactionHistory', function(data, cb)
    local limit = data.limit or 50
    TriggerServerEvent('jr_banking:getTransactionHistory', limit)
    cb('ok')
end)

RegisterNUICallback('getAccountInfo', function(data, cb)
    TriggerServerEvent('jr_banking:getAccountInfo')
    cb('ok')
end)

-- Admin commands (if player has admin rights)
RegisterCommand('bankadmin', function(source, args)
    if Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerData()
        if xPlayer.group == 'admin' or xPlayer.group == 'superadmin' then
            -- Open admin banking interface
            SendNUIMessage({
                type = 'openAdmin'
            })
        end
    end
end)

print('^2[jr_banking]^7 Client initialized successfully!')