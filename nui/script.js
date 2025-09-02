// Jr Banking - NUI Script
class BankingApp {
    constructor() {
        this.config = {};
        this.accountInfo = {};
        this.transactionHistory = [];
        this.currentForm = null;
        this.isVisible = false;
        
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.setupNotificationSystem();
        console.log('[Jr Banking] UI initialized');
    }
    
    bindEvents() {
        // Main navigation
        document.getElementById('close-banking').addEventListener('click', () => this.closeBanking());
        
        // Quick actions
        document.getElementById('deposit-btn').addEventListener('click', () => this.showTransactionForm('deposit'));
        document.getElementById('withdraw-btn').addEventListener('click', () => this.showTransactionForm('withdraw'));
        document.getElementById('transfer-btn').addEventListener('click', () => this.showTransactionForm('transfer'));
        document.getElementById('history-btn').addEventListener('click', () => this.showTransactionHistory());
        
        // Form controls
        document.getElementById('form-close').addEventListener('click', () => this.hideTransactionForm());
        document.getElementById('cancel-transaction').addEventListener('click', () => this.hideTransactionForm());
        document.getElementById('confirm-transaction').addEventListener('click', () => this.confirmTransaction());
        
        // History controls
        document.getElementById('history-close').addEventListener('click', () => this.hideTransactionHistory());
        document.getElementById('history-filter').addEventListener('change', (e) => this.filterTransactionHistory(e.target.value));
        
        // Amount input for fee calculation
        document.getElementById('amount-input').addEventListener('input', (e) => this.calculateFees(e.target.value));
        
        // PIN setup modal
        document.getElementById('set-pin').addEventListener('click', () => this.setPIN());
        document.getElementById('skip-pin').addEventListener('click', () => this.closePINModal());
        
        // Settings
        document.getElementById('settings-btn').addEventListener('click', () => this.showSettings());
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => this.handleKeyboard(e));
        
        // NUI focus handling
        window.addEventListener('message', (event) => this.handleNUIMessage(event));
        
        // Click outside to close
        document.addEventListener('click', (e) => {
            if (e.target.id === 'app' && this.isVisible) {
                this.closeBanking();
            }
        });
    }
    
    setupNotificationSystem() {
        this.notificationContainer = document.getElementById('notification-container');
    }
    
    handleNUIMessage(event) {
        const data = event.data;
        
        switch (data.type) {
            case 'openBanking':
                this.openBanking(data.config);
                break;
            case 'closeBanking':
                this.closeBanking();
                break;
            case 'updateAccountInfo':
                this.updateAccountInfo(data.data);
                break;
            case 'updateTransactionHistory':
                this.updateTransactionHistory(data.data);
                break;
            case 'notification':
                this.showNotification(data.message, data.notificationType);
                break;
            case 'openAdmin':
                this.openAdminPanel();
                break;
        }
    }
    
    openBanking(config = {}) {
        this.config = config;
        this.isVisible = true;
        
        document.getElementById('banking-container').classList.remove('hidden');
        document.body.style.display = 'block';
        
        // Request account info
        this.postNUI('getAccountInfo');
        
        // Show PIN setup if needed
        if (config.requirePIN && !this.accountInfo.hasPIN) {
            setTimeout(() => this.showPINSetup(), 1000);
        }
    }
    
    closeBanking() {
        this.isVisible = false;
        document.getElementById('banking-container').classList.add('hidden');
        document.body.style.display = 'none';
        
        // Hide all modals and forms
        this.hideTransactionForm();
        this.hideTransactionHistory();
        this.closePINModal();
        
        this.postNUI('closeBanking');
    }
    
    updateAccountInfo(data) {
        this.accountInfo = data;
        
        document.getElementById('account-name').textContent = data.name || 'Unknown';
        document.getElementById('account-balance').textContent = this.formatMoney(data.balance || 0);
        
        // Update UI based on account status
        if (data.isLocked) {
            this.showNotification('Your account is temporarily locked due to failed PIN attempts', 'warning');
        }
    }
    
    showTransactionForm(type) {
        this.currentForm = type;
        this.hideTransactionHistory();
        
        const form = document.getElementById('transaction-form');
        const title = document.getElementById('form-title');
        const amountInput = document.getElementById('amount-input');
        const targetGroup = document.getElementById('target-group');
        const pinGroup = document.getElementById('pin-group');
        const feeInfo = document.getElementById('fee-info');
        
        // Reset form
        form.querySelectorAll('input').forEach(input => input.value = '');
        targetGroup.style.display = 'none';
        pinGroup.style.display = 'none';
        feeInfo.style.display = 'none';
        
        // Configure form based on type
        switch (type) {
            case 'deposit':
                title.textContent = 'Deposit Money';
                amountInput.placeholder = `Max: ${this.formatMoney(this.config.maxDeposit)}`;
                amountInput.max = this.config.maxDeposit;
                break;
                
            case 'withdraw':
                title.textContent = 'Withdraw Money';
                amountInput.placeholder = `Max: ${this.formatMoney(this.config.maxWithdraw)}`;
                amountInput.max = this.config.maxWithdraw;
                
                if (this.config.requirePIN && this.accountInfo.hasPIN) {
                    pinGroup.style.display = 'block';
                }
                break;
                
            case 'transfer':
                title.textContent = 'Transfer Money';
                amountInput.placeholder = `Max: ${this.formatMoney(this.config.maxTransfer)}`;
                amountInput.max = this.config.maxTransfer;
                targetGroup.style.display = 'block';
                feeInfo.style.display = 'block';
                
                if (this.config.requirePIN && this.accountInfo.hasPIN) {
                    pinGroup.style.display = 'block';
                }
                break;
        }
        
        form.classList.remove('hidden');
        amountInput.focus();
    }
    
    hideTransactionForm() {
        document.getElementById('transaction-form').classList.add('hidden');
        this.currentForm = null;
    }
    
    calculateFees(amount) {
        if (this.currentForm !== 'transfer' || !amount) return;
        
        const transferAmount = parseFloat(amount) || 0;
        const feeRate = this.config.transferFee / 100;
        let fee = Math.floor(transferAmount * feeRate);
        
        // Apply min/max fee limits
        fee = Math.max(this.config.minTransferFee, Math.min(this.config.maxTransferFee, fee));
        
        const total = transferAmount + fee;
        
        document.getElementById('transfer-amount').textContent = this.formatMoney(transferAmount);
        document.getElementById('transfer-fee').textContent = this.formatMoney(fee);
        document.getElementById('total-deduction').textContent = this.formatMoney(total);
    }
    
    confirmTransaction() {
        const amountInput = document.getElementById('amount-input');
        const targetInput = document.getElementById('target-input');
        const pinInput = document.getElementById('pin-input');
        
        const amount = parseFloat(amountInput.value);
        const targetId = parseInt(targetInput.value);
        const pin = pinInput.value;
        
        // Validation
        if (!amount || amount <= 0) {
            this.showNotification('Please enter a valid amount', 'error');
            return;
        }
        
        // Type-specific validation
        switch (this.currentForm) {
            case 'deposit':
                if (amount > this.config.maxDeposit) {
                    this.showNotification(`Maximum deposit amount is ${this.formatMoney(this.config.maxDeposit)}`, 'error');
                    return;
                }
                break;
                
            case 'withdraw':
                if (amount > this.config.maxWithdraw) {
                    this.showNotification(`Maximum withdraw amount is ${this.formatMoney(this.config.maxWithdraw)}`, 'error');
                    return;
                }
                if (amount > this.accountInfo.balance) {
                    this.showNotification('Insufficient funds', 'error');
                    return;
                }
                if (this.config.requirePIN && this.accountInfo.hasPIN && !pin) {
                    this.showNotification('Please enter your PIN', 'error');
                    return;
                }
                break;
                
            case 'transfer':
                if (amount > this.config.maxTransfer) {
                    this.showNotification(`Maximum transfer amount is ${this.formatMoney(this.config.maxTransfer)}`, 'error');
                    return;
                }
                if (!targetId || targetId < 1) {
                    this.showNotification('Please enter a valid player ID', 'error');
                    return;
                }
                if (this.config.requirePIN && this.accountInfo.hasPIN && !pin) {
                    this.showNotification('Please enter your PIN', 'error');
                    return;
                }
                
                const feeRate = this.config.transferFee / 100;
                let fee = Math.floor(amount * feeRate);
                fee = Math.max(this.config.minTransferFee, Math.min(this.config.maxTransferFee, fee));
                
                if (amount + fee > this.accountInfo.balance) {
                    this.showNotification('Insufficient funds (including transfer fee)', 'error');
                    return;
                }
                break;
        }
        
        // Show loading
        this.showLoading();
        
        // Send transaction to server
        const transactionData = { amount };
        if (this.currentForm === 'transfer') {
            transactionData.targetId = targetId;
        }
        if (pin) {
            transactionData.pin = pin;
        }
        
        this.postNUI(this.currentForm, transactionData).then(() => {
            this.hideLoading();
            this.hideTransactionForm();
        }).catch(() => {
            this.hideLoading();
        });
    }
    
    showTransactionHistory() {
        this.hideTransactionForm();
        
        const history = document.getElementById('transaction-history');
        history.classList.remove('hidden');
        
        // Request transaction history
        this.postNUI('getTransactionHistory', { limit: 50 });
    }
    
    hideTransactionHistory() {
        document.getElementById('transaction-history').classList.add('hidden');
    }
    
    updateTransactionHistory(transactions) {
        this.transactionHistory = transactions;
        this.renderTransactionHistory();
    }
    
    renderTransactionHistory(filter = 'all') {
        const historyList = document.getElementById('history-list');
        let filteredTransactions = this.transactionHistory;
        
        if (filter !== 'all') {
            filteredTransactions = this.transactionHistory.filter(t => t.type === filter);
        }
        
        if (filteredTransactions.length === 0) {
            historyList.innerHTML = `
                <div class="no-transactions">
                    <i class="fas fa-receipt"></i>
                    <p>No transactions found</p>
                </div>
            `;
            return;
        }
        
        historyList.innerHTML = filteredTransactions.map(transaction => {
            const isIncoming = transaction.type === 'transfer_in' || transaction.type === 'deposit';
            const icon = this.getTransactionIcon(transaction.type);
            const amount = isIncoming ? `+${this.formatMoney(transaction.amount)}` : `-${this.formatMoney(transaction.amount)}`;
            const date = new Date(transaction.created_at).toLocaleString();
            
            return `
                <div class="transaction-item">
                    <div class="transaction-info">
                        <div class="transaction-icon ${transaction.type}">
                            <i class="fas ${icon}"></i>
                        </div>
                        <div class="transaction-details">
                            <h4>${this.getTransactionTitle(transaction.type)}</h4>
                            <p>${transaction.description}</p>
                        </div>
                    </div>
                    <div class="transaction-amount">
                        <div class="amount" style="color: ${isIncoming ? 'var(--success-color)' : 'var(--danger-color)'}">${amount}</div>
                        <div class="date">${date}</div>
                    </div>
                </div>
            `;
        }).join('');
    }
    
    filterTransactionHistory(filter) {
        this.renderTransactionHistory(filter);
    }
    
    getTransactionIcon(type) {
        const icons = {
            'deposit': 'fa-plus-circle',
            'withdraw': 'fa-minus-circle',
            'transfer_in': 'fa-arrow-down',
            'transfer_out': 'fa-arrow-up',
            'fee': 'fa-receipt'
        };
        return icons[type] || 'fa-exchange-alt';
    }
    
    getTransactionTitle(type) {
        const titles = {
            'deposit': 'Cash Deposit',
            'withdraw': 'Cash Withdrawal',
            'transfer_in': 'Incoming Transfer',
            'transfer_out': 'Outgoing Transfer',
            'fee': 'Transaction Fee'
        };
        return titles[type] || 'Transaction';
    }
    
    showPINSetup() {
        document.getElementById('pin-setup-modal').classList.remove('hidden');
        document.getElementById('new-pin').focus();
    }
    
    closePINModal() {
        document.getElementById('pin-setup-modal').classList.add('hidden');
        document.getElementById('new-pin').value = '';
        document.getElementById('confirm-pin').value = '';
    }
    
    setPIN() {
        const newPIN = document.getElementById('new-pin').value;
        const confirmPIN = document.getElementById('confirm-pin').value;
        
        if (!newPIN || newPIN.length !== this.config.pinLength) {
            this.showNotification(`PIN must be ${this.config.pinLength} digits`, 'error');
            return;
        }
        
        if (newPIN !== confirmPIN) {
            this.showNotification('PIN codes do not match', 'error');
            return;
        }
        
        if (!/^\d+$/.test(newPIN)) {
            this.showNotification('PIN must contain only numbers', 'error');
            return;
        }
        
        this.postNUI('setPIN', { pin: newPIN }).then(() => {
            this.closePINModal();
            this.accountInfo.hasPIN = true;
        });
    }
    
    showSettings() {
        // Placeholder for settings functionality
        this.showNotification('Settings panel coming soon!', 'info');
    }
    
    openAdminPanel() {
        // Placeholder for admin functionality
        this.showNotification('Admin panel coming soon!', 'info');
    }
    
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        notification.addEventListener('click', () => {
            notification.remove();
        });
        
        this.notificationContainer.appendChild(notification);
        
        // Auto-remove after 3 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.style.animation = 'notificationSlideOut 0.3s ease forwards';
                setTimeout(() => notification.remove(), 300);
            }
        }, 3000);
    }
    
    showLoading() {
        document.getElementById('loading-overlay').classList.remove('hidden');
    }
    
    hideLoading() {
        document.getElementById('loading-overlay').classList.add('hidden');
    }
    
    handleKeyboard(e) {
        if (!this.isVisible) return;
        
        switch (e.key) {
            case 'Escape':
                if (document.getElementById('transaction-form').classList.contains('hidden') && 
                    document.getElementById('transaction-history').classList.contains('hidden') &&
                    document.getElementById('pin-setup-modal').classList.contains('hidden')) {
                    this.closeBanking();
                } else {
                    this.hideTransactionForm();
                    this.hideTransactionHistory();
                    this.closePINModal();
                }
                break;
            case 'Enter':
                if (!document.getElementById('transaction-form').classList.contains('hidden')) {
                    this.confirmTransaction();
                }
                break;
        }
    }
    
    formatMoney(amount) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount || 0);
    }
    
    postNUI(action, data = {}) {
        return fetch(`https://jr_banking/${action}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        }).then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        }).catch(error => {
            console.error('[Jr Banking] NUI Callback Error:', error);
            throw error;
        });
    }
}

// Add notification slide out animation
const style = document.createElement('style');
style.textContent = `
    @keyframes notificationSlideOut {
        from {
            opacity: 1;
            transform: translateX(0);
        }
        to {
            opacity: 0;
            transform: translateX(100%);
        }
    }
`;
document.head.appendChild(style);

// Initialize the banking app
const bankingApp = new BankingApp();

// Debug helpers for development
if (window.location.protocol === 'file:') {
    console.log('[Jr Banking] Development mode detected');
    
    // Mock data for testing
    window.testBanking = () => {
        bankingApp.openBanking({
            maxWithdraw: 50000,
            maxDeposit: 100000,
            maxTransfer: 75000,
            requirePIN: true,
            pinLength: 4,
            transferFee: 2,
            minTransferFee: 10,
            maxTransferFee: 1000,
            ui: {
                theme: 'dark',
                primaryColor: '#1a73e8',
                secondaryColor: '#34a853',
                dangerColor: '#ea4335',
                warningColor: '#fbbc05'
            }
        });
        
        setTimeout(() => {
            bankingApp.updateAccountInfo({
                balance: 25000,
                name: 'John Doe',
                hasPIN: false,
                isLocked: false
            });
        }, 500);
    };
    
    window.testNotifications = () => {
        bankingApp.showNotification('Test success message', 'success');
        setTimeout(() => bankingApp.showNotification('Test error message', 'error'), 1000);
        setTimeout(() => bankingApp.showNotification('Test warning message', 'warning'), 2000);
        setTimeout(() => bankingApp.showNotification('Test info message', 'info'), 3000);
    };
    
    window.testTransactions = () => {
        const mockTransactions = [
            {
                id: 1,
                type: 'deposit',
                amount: 5000,
                description: 'Cash deposit',
                created_at: new Date(Date.now() - 86400000).toISOString()
            },
            {
                id: 2,
                type: 'withdraw',
                amount: 2000,
                description: 'Cash withdrawal',
                created_at: new Date(Date.now() - 43200000).toISOString()
            },
            {
                id: 3,
                type: 'transfer_in',
                amount: 3000,
                description: 'Transfer from Jane Smith',
                created_at: new Date(Date.now() - 21600000).toISOString()
            }
        ];
        bankingApp.updateTransactionHistory(mockTransactions);
    };
}