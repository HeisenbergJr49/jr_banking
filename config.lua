Config = {}

-- Framework Settings
Config.Framework = 'esx' -- 'esx' or 'qb'

-- Banking Settings
Config.StartCash = 5000 -- Starting bank balance for new players
Config.MaxWithdrawAmount = 50000 -- Maximum withdraw amount per transaction
Config.MaxDepositAmount = 100000 -- Maximum deposit amount per transaction
Config.MaxTransferAmount = 75000 -- Maximum transfer amount per transaction

-- Security Settings
Config.RequirePIN = true -- Require PIN for transactions
Config.PINLength = 4 -- PIN code length
Config.MaxPINAttempts = 3 -- Maximum PIN attempts before lockout
Config.LockoutTime = 300 -- Lockout time in seconds (5 minutes)

-- Transaction Fees
Config.TransferFee = 0.02 -- 2% fee for transfers
Config.MinTransferFee = 10 -- Minimum transfer fee
Config.MaxTransferFee = 1000 -- Maximum transfer fee

-- ATM Locations
Config.ATMLocations = {
    {x = 147.4, y = -1035.8, z = 29.3},
    {x = 145.9, y = -1035.2, z = 29.3},
    {x = 112.4, y = -819.8, z = 31.3},
    {x = 112.9, y = -821.3, z = 31.3},
    {x = -1205.35, y = -325.579, z = 37.870},
    {x = -1205.2, y = -324.308, z = 37.862},
    {x = -2975.72, y = 379.197, z = 15.020},
    {x = -2962.60, y = 482.627, z = 15.703},
    {x = -3144.13, y = 1127.415, z = 20.868},
    {x = -3241.927, y = 996.756, z = 12.500},
    {x = -1091.464, y = 2708.923, z = 18.954}
}

-- Bank Locations (Interior Banking)
Config.BankLocations = {
    {x = 150.266, y = -1040.203, z = 29.374, heading = 160.0}, -- Pillbox Hill
    {x = -1212.980, y = -330.841, z = 37.787, heading = 26.5}, -- Burton
    {x = -2962.885, y = 482.627, z = 15.703, heading = 83.0}, -- Great Ocean Highway
    {x = -112.202, y = 6469.295, z = 31.626, heading = 134.5}, -- Paleto Bay
    {x = 314.187, y = -278.621, z = 54.170, heading = 340.5}, -- Alta Street
    {x = -351.534, y = -49.529, z = 49.042, heading = 160.0} -- Hawick Avenue
}

-- UI Settings
Config.UISettings = {
    theme = 'dark', -- 'light' or 'dark'
    primaryColor = '#1a73e8',
    secondaryColor = '#34a853',
    dangerColor = '#ea4335',
    warningColor = '#fbbc05',
    animationSpeed = 300
}

-- Language Settings
Config.Locale = 'en' -- Default language

-- Logging Settings
Config.EnableLogging = true
Config.LogLevel = 'info' -- 'debug', 'info', 'warn', 'error'

-- Anti-Cheat Settings
Config.AntiCheat = {
    enabled = true,
    maxRequestsPerSecond = 5,
    maxTransactionsPerMinute = 10
}