# Jr Banking - Modern FiveM Banking System

A complete, modern banking system for FiveM servers with a sleek NUI interface, comprehensive security features, and full ESX/QBCore compatibility.

![Banking Interface](https://github.com/user-attachments/assets/784f12ba-9a1d-42ec-a083-6fc1b15f7ed5)

## Features

### 🏦 Core Banking Operations
- **Account Management** - Automatic account creation for new players
- **Deposit/Withdraw** - Cash transactions with configurable limits
- **Player Transfers** - Send money between players with fee calculation
- **Transaction History** - Complete transaction logs with filtering
- **Real-time Updates** - Live balance and transaction updates

### 🔒 Security Features
- **PIN Protection** - 4-digit PIN security for transactions
- **Account Lockout** - Automatic lockout after failed PIN attempts
- **Rate Limiting** - Anti-spam protection for transactions
- **Transaction Limits** - Configurable maximum amounts
- **Anti-Cheat** - Server-side validation for all operations

### 🎨 Modern Interface
- **Responsive Design** - Works on all screen sizes
- **Dark Theme** - Modern, eye-friendly dark interface
- **Smooth Animations** - CSS transitions and effects
- **Intuitive Navigation** - User-friendly button layout
- **Real-time Feedback** - Instant notifications and updates

### 🔧 Technical Features
- **Framework Support** - ESX and QBCore compatibility
- **Database Integration** - MySQL with optimized queries
- **Performance Optimized** - Efficient memory and CPU usage
- **Configurable** - Extensive configuration options
- **Multi-language Ready** - Localization support foundation

## Installation

### Prerequisites
- FiveM Server
- ESX or QBCore Framework
- MySQL Database
- mysql-async resource

### Quick Setup

1. **Download and Extract**
   ```bash
   cd resources
   git clone https://github.com/HeisenbergJr49/jr_banking.git
   ```

2. **Database Setup**
   - Import `sql/banking_tables.sql` into your database
   - The script will create 3 tables: accounts, transactions, and settings

3. **Configuration**
   - Edit `config.lua` to match your server settings
   - Configure framework (ESX/QBCore)
   - Set transaction limits and fees
   - Customize ATM/Bank locations

4. **Resource Start**
   ```bash
   # Add to server.cfg
   ensure jr_banking
   ```

## Configuration

### Basic Settings (config.lua)

```lua
-- Framework Selection
Config.Framework = 'esx' -- 'esx' or 'qb'

-- Starting Balance
Config.StartCash = 5000

-- Transaction Limits
Config.MaxWithdrawAmount = 50000
Config.MaxDepositAmount = 100000
Config.MaxTransferAmount = 75000

-- Security Settings
Config.RequirePIN = true
Config.PINLength = 4
Config.MaxPINAttempts = 3
Config.LockoutTime = 300 -- 5 minutes

-- Transfer Fees
Config.TransferFee = 0.02 -- 2%
Config.MinTransferFee = 10
Config.MaxTransferFee = 1000
```

### ATM/Bank Locations

The system includes pre-configured ATM and bank locations throughout the map. You can customize these in `config.lua`:

```lua
Config.ATMLocations = {
    {x = 147.4, y = -1035.8, z = 29.3},
    -- Add more locations...
}

Config.BankLocations = {
    {x = 150.266, y = -1040.203, z = 29.374, heading = 160.0},
    -- Add more locations...
}
```

## Usage

### For Players

1. **Accessing Banking**
   - Approach any ATM or Bank location
   - Press `E` to open the banking interface

2. **Basic Operations**
   - **Deposit**: Convert cash to bank balance
   - **Withdraw**: Convert bank balance to cash (requires PIN if enabled)
   - **Transfer**: Send money to other players (requires PIN if enabled)
   - **History**: View transaction history with filters

3. **PIN Setup**
   - First-time users will be prompted to set a 4-digit PIN
   - PIN is required for withdrawals and transfers
   - Account locks after 3 failed PIN attempts

### For Administrators

- **Command**: `/bankadmin` (requires admin permissions)
- Access to account management and system statistics
- Transaction monitoring and reporting

## Screenshots

### Main Interface
![Main Banking Interface](https://github.com/user-attachments/assets/784f12ba-9a1d-42ec-a083-6fc1b15f7ed5)

### Deposit Form
![Deposit Interface](https://github.com/user-attachments/assets/3932d752-74c3-4065-8ae2-adc551498f67)

### Transfer with Fee Calculation
![Transfer Interface](https://github.com/user-attachments/assets/13d1172d-5410-483d-b1c2-0c6abcf49934)

## Database Schema

### Tables Created

1. **jr_banking_accounts**
   - Player account information
   - Balance, PIN, and security data

2. **jr_banking_transactions**
   - Complete transaction history
   - Supports deposits, withdrawals, transfers, and fees

3. **jr_banking_settings**
   - System configuration
   - Dynamic settings management

## API Events

### Client Events
```lua
-- Open banking interface
TriggerEvent('jr_banking:openBanking')

-- Account info updates
RegisterNetEvent('jr_banking:receiveAccountInfo')

-- Transaction notifications
RegisterNetEvent('jr_banking:notify')
```

### Server Events
```lua
-- Banking operations
TriggerServerEvent('jr_banking:deposit', amount)
TriggerServerEvent('jr_banking:withdraw', amount, pin)
TriggerServerEvent('jr_banking:transfer', targetId, amount, pin)

-- Account management
TriggerServerEvent('jr_banking:getAccountInfo')
TriggerServerEvent('jr_banking:setPIN', newPIN)
```

## Performance

- **Optimized Queries** - Indexed database operations
- **Memory Efficient** - Minimal resource usage
- **Rate Limited** - Prevents server overload
- **Caching** - Smart data caching for performance

## Support

For support, feature requests, or bug reports:
- GitHub Issues: [Create an Issue](https://github.com/HeisenbergJr49/jr_banking/issues)
- Discord: Contact repository owner

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- **Developer**: HeisenbergJr49
- **Framework**: FiveM
- **UI Library**: Custom HTML/CSS/JavaScript
- **Database**: MySQL

---

**Made with ❤️ for the FiveM community**