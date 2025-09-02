-- jr_banking Database Tables
-- Make sure to run this SQL script on your database before using the resource

CREATE TABLE IF NOT EXISTS `jr_banking_accounts` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `name` varchar(100) NOT NULL,
    `balance` int(11) NOT NULL DEFAULT 5000,
    `pin_code` varchar(255) DEFAULT NULL,
    `pin_attempts` int(11) NOT NULL DEFAULT 0,
    `locked_until` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jr_banking_transactions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `from_identifier` varchar(50) DEFAULT NULL,
    `to_identifier` varchar(50) DEFAULT NULL,
    `amount` int(11) NOT NULL,
    `type` enum('deposit','withdraw','transfer_in','transfer_out','fee') NOT NULL,
    `description` varchar(255) NOT NULL,
    `reference_id` varchar(100) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `from_identifier` (`from_identifier`),
    KEY `to_identifier` (`to_identifier`),
    KEY `created_at` (`created_at`),
    KEY `reference_id` (`reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jr_banking_settings` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `setting_key` varchar(100) NOT NULL,
    `setting_value` text NOT NULL,
    `description` varchar(255) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `setting_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default settings
INSERT INTO `jr_banking_settings` (`setting_key`, `setting_value`, `description`) VALUES
('bank_name', 'Jr Banking', 'Bank name displayed in UI'),
('interest_rate', '0.05', 'Monthly interest rate (5%)'),
('maintenance_mode', '0', 'Enable maintenance mode (1) or disable (0)'),
('max_accounts_per_player', '1', 'Maximum accounts per player'),
('daily_transaction_limit', '1000000', 'Daily transaction limit per account');

-- Add indexes for performance
ALTER TABLE `jr_banking_transactions` ADD INDEX `idx_from_created` (`from_identifier`, `created_at`);
ALTER TABLE `jr_banking_transactions` ADD INDEX `idx_to_created` (`to_identifier`, `created_at`);
ALTER TABLE `jr_banking_transactions` ADD INDEX `idx_type_created` (`type`, `created_at`);