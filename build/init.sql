SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

CREATE TABLE `company` (
  `name` varchar(60) NOT NULL UNIQUE,
  `codeManager` varchar(14) NOT NULL UNIQUE,
  `codeEmployee` varchar(14) NOT NULL UNIQUE,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `user` (
  `Name` varchar(40) NOT NULL,
  `Surname` varchar(40) NOT NULL,
  `email` varchar(255) NOT NULL UNIQUE,
  `username` varchar(30) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL,
  `profilePhotoFile` varchar(255) DEFAULT NULL,
  `emailVerified` BOOLEAN NOT NULL DEFAULT FALSE,
  `companyID` int(11) NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_company` FOREIGN KEY (`companyID`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `email_verification_tokens` (
  `token` varchar(64) NOT NULL,
  `userID` int(11) NOT NULL,
  `newEmail` varchar(255) DEFAULT NULL,
  `expiresAt` timestamp NOT NULL,
  PRIMARY KEY (`token`),
  CONSTRAINT `fk_email_token_user` FOREIGN KEY (`userID`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `company_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `companyName` varchar(60) NOT NULL,
  `requesterEmail` varchar(255) NOT NULL,
  `token` varchar(64) NOT NULL UNIQUE,
  `status` enum('pending','approved') NOT NULL DEFAULT 'pending',
  `createdAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `account_recovery_tokens` (
  `token` varchar(64) NOT NULL,
  `userID` int(11) NOT NULL,
  `type` enum('password','username') NOT NULL,
  `expiresAt` timestamp NOT NULL,
  PRIMARY KEY (`token`),
  CONSTRAINT `fk_recovery_token_user` FOREIGN KEY (`userID`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `employee` (
  `id` int(11) NOT NULL,
  `role` varchar(50) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_employee_user` FOREIGN KEY (`id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `manager` (
  `id` int(11) NOT NULL,
  `role` varchar(50) NOT NULL,
  `description` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_manager_user` FOREIGN KEY (`id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `shifts` (
  `userID` int(11) NOT NULL,
  `Day` varchar(20) DEFAULT NULL,
  `startTime` time NOT NULL,
  `endTime` time NOT NULL,
  `Date` DATE DEFAULT NULL,
  CONSTRAINT `fk_shifts_user` FOREIGN KEY (`userID`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `expenses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(300) NOT NULL,
  `expense` DECIMAL(10,2) NOT NULL,
  `DateOfExpense` date NOT NULL,
  `Notes` text DEFAULT NULL,
  `companyID` int(11) NOT NULL,
  `deletedAt` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_expenses_deletedAt` (`deletedAt`),
  CONSTRAINT `fk_company_expense` FOREIGN KEY (`companyID`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `income` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Source` varchar(300) NOT NULL,
  `Income` DECIMAL(10,2) NOT NULL,
  `DateOfIncome` date NOT NULL,
  `Notes` text DEFAULT NULL,
  `companyID` int(11) NOT NULL,
  `deletedAt` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_income_deletedAt` (`deletedAt`),
  CONSTRAINT `fk_company_income` FOREIGN KEY (`companyID`) REFERENCES `company` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `attachments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `companyID` int(11) NOT NULL,
  `fileName` varchar(255) NOT NULL UNIQUE,
  `incomeID` int(11) DEFAULT NULL,
  `expenseID` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_attachments_company` FOREIGN KEY (`companyID`) REFERENCES `company` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_attachments_income` FOREIGN KEY (`incomeID`) REFERENCES `income` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_attachments_expense` FOREIGN KEY (`expenseID`) REFERENCES `expenses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `privileges` (
  `employeeID` int(11) NOT NULL,
  `income` BOOLEAN NOT NULL DEFAULT FALSE,
  `expenses` BOOLEAN NOT NULL DEFAULT FALSE,
  `money-tracker` BOOLEAN NOT NULL DEFAULT FALSE,
  `shift` BOOLEAN NOT NULL DEFAULT FALSE,
  `manage-employees` BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (`employeeID`),
  CONSTRAINT `fk_employee_privileges` FOREIGN KEY (`employeeID`) REFERENCES `employee` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- test data 

INSERT INTO `company` (`name`, `codeManager`, `codeEmployee`) VALUES
('CompanyX', '09ir13AhOekoII', '10ir1oL9Oe2oII');

INSERT INTO `user` (`Name`, `Surname`, `username`, `password`, `companyID`, `email`, `emailVerified`, `profilePhotoFile`) VALUES
('Christos', 'Vlassis', 'chrisvlas1', '$2y$10$KQH7tqpa857BbkG3ogIkZuiaSU5d2Xknf9dxI0RGKDdDKesoPqXcS', 1, 'ex1@email.com', TRUE, NULL),
('Miltos', 'Karabasilis', 'miltos90', '$2y$10$KQH7tqpa857BbkG3ogIkZuiaSU5d2Xknf9dxI0RGKDdDKesoPqXcS', 1, 'ex2@email.com', TRUE, '1_seed_miltos.png'),
('Anna', 'Dimitriou', 'anna6', '$2y$10$KQH7tqpa857BbkG3ogIkZuiaSU5d2Xknf9dxI0RGKDdDKesoPqXcS', 1, 'ex3@email.com', TRUE, '2_seed_anna.png'),
('Nikos', 'Andreou', 'nikos21', '$2y$10$KQH7tqpa857BbkG3ogIkZuiaSU5d2Xknf9dxI0RGKDdDKesoPqXcS', 1, 'ex4@email.com', TRUE, NULL),
('Sofia', 'Markou', 'sofia111', '$2y$10$KQH7tqpa857BbkG3ogIkZuiaSU5d2Xknf9dxI0RGKDdDKesoPqXcS', 1, 'ex5@email.com', TRUE, NULL),
('Petros', 'Ioannou', 'petros89', '$2y$10$KQH7tqpa857BbkG3ogIkZuiaSU5d2Xknf9dxI0RGKDdDKesoPqXcS', 1, 'ex6@email.com', TRUE, NULL);

INSERT INTO `manager` (`id`, `role`, `description`) VALUES
(1, 'General Manager', 'Overseeing all core business operations and system workflows. Here to ensure everything runs smoothly and our team has the support needed to grow.');

INSERT INTO `employee` (`id`, `role`, `description`) VALUES
(2, 'Data entry Employee', 'Responsible for daily data entry and record keeping. Here to help keep our system accurate and up to date.'),
(3, 'Storage helper', 'Assists with warehouse operations.'),
(4, 'Front-end Developer', 'Crafting intuitive and responsive user interfaces. Focused on enhancing the overall user experience and ensuring seamless interaction with our information system.'),
(5, 'Back-end Developer', 'Building robust server-side logic and database architecture. Dedicated to maintaining system security, performance, and reliable data processing.'),
(6, 'Financial analyst', 'Managing warehouse inventory and logistics. Ensures efficient organization of stock to support smooth daily operations and timely order fulfillment.');

INSERT INTO `privileges` (`employeeID`, `income`, `expenses`, `money-tracker`, `shift`, `manage-employees`) VALUES
(2, TRUE, TRUE, FALSE, FALSE, FALSE),
(3, FALSE, FALSE, FALSE, FALSE, FALSE),
(4, FALSE, FALSE, FALSE, FALSE, FALSE),
(5, FALSE, FALSE, FALSE, FALSE, FALSE),
(6, TRUE, TRUE, TRUE, FALSE, FALSE);

-- Every shift slot is shared by at least 2 employees
INSERT INTO `shifts` (`userID`, `Day`, `startTime`, `endTime`) VALUES
(2, 'Monday', '09:00:00', '17:00:00'),
(4, 'Monday', '09:00:00', '17:00:00'),
(5, 'Monday', '09:00:00', '17:00:00'),
(3, 'Tuesday', '10:00:00', '18:00:00'),
(6, 'Tuesday', '10:00:00', '18:00:00'),
(2, 'Wednesday', '08:00:00', '16:00:00'),
(3, 'Wednesday', '08:00:00', '16:00:00'),
(4, 'Thursday', '12:00:00', '20:00:00'),
(5, 'Thursday', '12:00:00', '20:00:00'),
(5, 'Friday', '09:00:00', '17:00:00'),
(6, 'Friday', '09:00:00', '17:00:00'),
(3, 'Saturday', '15:00:00', '19:00:00'),
(6, 'Saturday', '15:00:00', '19:00:00');

-- Expenses 2023-2026 (e-shop warehouse & website operations)
INSERT INTO `expenses` (`source`, `expense`, `DateOfExpense`, `Notes`, `companyID`) VALUES
('Warehouse & office rent', 858.00, '2023-01-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-01-01 12:00:00
', 1),
('Electricity - warehouse', 117.00, '2023-01-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 117.00.
Created by Miltos Karabasilis (id: 2) at 2023-01-05 12:00:00
', 1),
('Packaging & bubble wrap', 158.00, '2023-01-10', 'Packaging supplies order for fragile items and standard parcel sizes.
Created by Miltos Karabasilis (id: 2) at 2023-01-10 12:00:00
', 1),
('Warehouse & office rent', 866.00, '2023-02-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-02-01 12:00:00
', 1),
('Electricity - warehouse', 119.00, '2023-02-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 119.00.
Created by Miltos Karabasilis (id: 2) at 2023-02-05 12:00:00
', 1),
('Courier last-mile delivery', 161.00, '2023-02-10', 'Delivery partner invoice covering tracked parcels shipped from the warehouse.
Created by Miltos Karabasilis (id: 2) at 2023-02-10 12:00:00
', 1),
('Warehouse & office rent', 874.00, '2023-03-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-03-01 12:00:00
', 1),
('Electricity - warehouse', 121.00, '2023-03-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 121.00.
Created by Miltos Karabasilis (id: 2) at 2023-03-05 12:00:00
', 1),
('Thermal shipping labels', 164.00, '2023-03-10', 'Printer media restock for shipping labels and return-address stickers.
Created by Miltos Karabasilis (id: 2) at 2023-03-10 12:00:00
', 1),
('Warehouse & office rent', 882.00, '2023-04-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-04-01 12:00:00
', 1),
('Electricity - warehouse', 123.00, '2023-04-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 123.00.
Created by Miltos Karabasilis (id: 2) at 2023-04-05 12:00:00
', 1),
('Warehouse rack maintenance', 167.00, '2023-04-10', 'Repair service for shelving in picking zones to keep stock accessible.
Created by Miltos Karabasilis (id: 2) at 2023-04-10 12:00:00
', 1),
('Warehouse & office rent', 890.00, '2023-05-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-05-01 12:00:00
', 1),
('Electricity - warehouse', 125.00, '2023-05-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 125.00.
Created by Miltos Karabasilis (id: 2) at 2023-05-05 12:00:00
', 1),
('Shopify platform fee', 170.00, '2023-05-10', 'E-commerce platform charge covering hosting, checkout, and app integrations.
Created by Miltos Karabasilis (id: 2) at 2023-05-10 12:00:00
', 1),
('Warehouse & office rent', 898.00, '2023-06-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-06-01 12:00:00
', 1),
('Electricity - warehouse', 127.00, '2023-06-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 127.00.
Created by Miltos Karabasilis (id: 2) at 2023-06-05 12:00:00
', 1),
('Packaging & bubble wrap', 173.00, '2023-06-10', 'Packaging supplies order for fragile items and standard parcel sizes.
Created by Miltos Karabasilis (id: 2) at 2023-06-10 12:00:00
', 1),
('Warehouse & office rent', 906.00, '2023-07-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-07-01 12:00:00
', 1),
('Electricity - warehouse', 129.00, '2023-07-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 129.00.
Created by Miltos Karabasilis (id: 2) at 2023-07-05 12:00:00
', 1),
('Courier last-mile delivery', 176.00, '2023-07-10', 'Delivery partner invoice covering tracked parcels shipped from the warehouse.
Created by Miltos Karabasilis (id: 2) at 2023-07-10 12:00:00
', 1),
('Warehouse & office rent', 914.00, '2023-08-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-08-01 12:00:00
', 1),
('Electricity - warehouse', 131.00, '2023-08-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 131.00.
Created by Miltos Karabasilis (id: 2) at 2023-08-05 12:00:00
', 1),
('Thermal shipping labels', 179.00, '2023-08-10', 'Printer media restock for shipping labels and return-address stickers.
Created by Miltos Karabasilis (id: 2) at 2023-08-10 12:00:00
', 1),
('Warehouse & office rent', 922.00, '2023-09-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-09-01 12:00:00
', 1),
('Electricity - warehouse', 133.00, '2023-09-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 133.00.
Created by Miltos Karabasilis (id: 2) at 2023-09-05 12:00:00
', 1),
('Warehouse rack maintenance', 182.00, '2023-09-10', 'Repair service for shelving in picking zones to keep stock accessible.
Created by Miltos Karabasilis (id: 2) at 2023-09-10 12:00:00
', 1),
('Warehouse & office rent', 930.00, '2023-10-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-10-01 12:00:00
', 1),
('Electricity - warehouse', 135.00, '2023-10-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 135.00.
Created by Miltos Karabasilis (id: 2) at 2023-10-05 12:00:00
', 1),
('Shopify platform fee', 185.00, '2023-10-10', 'E-commerce platform charge covering hosting, checkout, and app integrations.
Created by Miltos Karabasilis (id: 2) at 2023-10-10 12:00:00
', 1),
('Warehouse & office rent', 938.00, '2023-11-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-11-01 12:00:00
', 1),
('Electricity - warehouse', 137.00, '2023-11-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 137.00.
Created by Miltos Karabasilis (id: 2) at 2023-11-05 12:00:00
', 1),
('Packaging & bubble wrap', 188.00, '2023-11-10', 'Packaging supplies order for fragile items and standard parcel sizes.
Created by Miltos Karabasilis (id: 2) at 2023-11-10 12:00:00
', 1),
('Warehouse & office rent', 946.00, '2023-12-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2023-12-01 12:00:00
', 1),
('Electricity - warehouse', 139.00, '2023-12-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 139.00.
Created by Miltos Karabasilis (id: 2) at 2023-12-05 12:00:00
', 1),
('Courier last-mile delivery', 191.00, '2023-12-10', 'Delivery partner invoice covering tracked parcels shipped from the warehouse.
Created by Miltos Karabasilis (id: 2) at 2023-12-10 12:00:00
', 1),
('Warehouse & office rent', 892.00, '2024-01-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-01-01 12:00:00
', 1),
('Electricity - warehouse', 121.60, '2024-01-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 121.60.
Created by Miltos Karabasilis (id: 2) at 2024-01-05 12:00:00
', 1),
('Packaging & bubble wrap', 164.20, '2024-01-10', 'Bulk purchase of mailer boxes and protective wrap for daily dispatch volume.
Created by Miltos Karabasilis (id: 2) at 2024-01-10 12:00:00
', 1),
('Warehouse & office rent', 900.00, '2024-02-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-02-01 12:00:00
', 1),
('Electricity - warehouse', 123.60, '2024-02-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 123.60.
Created by Miltos Karabasilis (id: 2) at 2024-02-05 12:00:00
', 1),
('Courier last-mile delivery', 167.20, '2024-02-10', 'Outbound logistics fee for home deliveries generated by online checkout.
Created by Miltos Karabasilis (id: 2) at 2024-02-10 12:00:00
', 1),
('Warehouse & office rent', 908.00, '2024-03-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-03-01 12:00:00
', 1),
('Electricity - warehouse', 125.60, '2024-03-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 125.60.
Created by Miltos Karabasilis (id: 2) at 2024-03-05 12:00:00
', 1),
('Thermal shipping labels', 170.20, '2024-03-10', 'Label supply order matched to current warehouse printer specifications.
Created by Miltos Karabasilis (id: 2) at 2024-03-10 12:00:00
', 1),
('Warehouse & office rent', 916.00, '2024-04-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-04-01 12:00:00
', 1),
('Electricity - warehouse', 127.60, '2024-04-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 127.60.
Created by Miltos Karabasilis (id: 2) at 2024-04-05 12:00:00
', 1),
('Warehouse rack maintenance', 173.20, '2024-04-10', 'Scheduled inspection and fixes on storage racks after peak picking weeks.
Created by Miltos Karabasilis (id: 2) at 2024-04-10 12:00:00
', 1),
('Warehouse & office rent', 924.00, '2024-05-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-05-01 12:00:00
', 1),
('Electricity - warehouse', 129.60, '2024-05-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 129.60.
Created by Miltos Karabasilis (id: 2) at 2024-05-05 12:00:00
', 1),
('Shopify platform fee', 176.20, '2024-05-10', 'Website platform invoice for storefront uptime and order-management tools.
Created by Miltos Karabasilis (id: 2) at 2024-05-10 12:00:00
', 1),
('Warehouse & office rent', 932.00, '2024-06-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-06-01 12:00:00
', 1),
('Electricity - warehouse', 131.60, '2024-06-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 131.60.
Created by Miltos Karabasilis (id: 2) at 2024-06-05 12:00:00
', 1),
('Packaging & bubble wrap', 179.20, '2024-06-10', 'Bulk purchase of mailer boxes and protective wrap for daily dispatch volume.
Created by Miltos Karabasilis (id: 2) at 2024-06-10 12:00:00
', 1),
('Warehouse & office rent', 940.00, '2024-07-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-07-01 12:00:00
', 1),
('Electricity - warehouse', 133.60, '2024-07-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 133.60.
Created by Miltos Karabasilis (id: 2) at 2024-07-05 12:00:00
', 1),
('Courier last-mile delivery', 182.20, '2024-07-10', 'Outbound logistics fee for home deliveries generated by online checkout.
Created by Miltos Karabasilis (id: 2) at 2024-07-10 12:00:00
', 1),
('Warehouse & office rent', 948.00, '2024-08-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-08-01 12:00:00
', 1),
('Electricity - warehouse', 135.60, '2024-08-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 135.60.
Created by Miltos Karabasilis (id: 2) at 2024-08-05 12:00:00
', 1),
('Thermal shipping labels', 185.20, '2024-08-10', 'Label supply order matched to current warehouse printer specifications.
Created by Miltos Karabasilis (id: 2) at 2024-08-10 12:00:00
', 1),
('Warehouse & office rent', 956.00, '2024-09-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-09-01 12:00:00
', 1),
('Electricity - warehouse', 137.60, '2024-09-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 137.60.
Created by Miltos Karabasilis (id: 2) at 2024-09-05 12:00:00
', 1),
('Warehouse rack maintenance', 188.20, '2024-09-10', 'Scheduled inspection and fixes on storage racks after peak picking weeks.
Created by Miltos Karabasilis (id: 2) at 2024-09-10 12:00:00
', 1),
('Warehouse & office rent', 964.00, '2024-10-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-10-01 12:00:00
', 1),
('Electricity - warehouse', 139.60, '2024-10-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 139.60.
Created by Miltos Karabasilis (id: 2) at 2024-10-05 12:00:00
', 1),
('Shopify platform fee', 191.20, '2024-10-10', 'Website platform invoice for storefront uptime and order-management tools.
Created by Miltos Karabasilis (id: 2) at 2024-10-10 12:00:00
', 1),
('Warehouse & office rent', 972.00, '2024-11-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-11-01 12:00:00
', 1),
('Electricity - warehouse', 141.60, '2024-11-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 141.60.
Created by Miltos Karabasilis (id: 2) at 2024-11-05 12:00:00
', 1),
('Packaging & bubble wrap', 194.20, '2024-11-10', 'Bulk purchase of mailer boxes and protective wrap for daily dispatch volume.
Created by Miltos Karabasilis (id: 2) at 2024-11-10 12:00:00
', 1),
('Warehouse & office rent', 980.00, '2024-12-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2024-12-01 12:00:00
', 1),
('Electricity - warehouse', 143.60, '2024-12-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 143.60.
Created by Miltos Karabasilis (id: 2) at 2024-12-05 12:00:00
', 1),
('Courier last-mile delivery', 197.20, '2024-12-10', 'Outbound logistics fee for home deliveries generated by online checkout.
Created by Miltos Karabasilis (id: 2) at 2024-12-10 12:00:00
', 1),
('Warehouse & office rent', 926.00, '2025-01-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-01-01 12:00:00
', 1),
('Electricity - warehouse', 126.20, '2025-01-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 126.20.
Created by Miltos Karabasilis (id: 2) at 2025-01-05 12:00:00
', 1),
('Packaging & bubble wrap', 170.40, '2025-01-10', 'Bulk purchase of mailer boxes and protective wrap for daily dispatch volume.
Created by Miltos Karabasilis (id: 2) at 2025-01-10 12:00:00
', 1),
('Warehouse & office rent', 934.00, '2025-02-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-02-01 12:00:00
', 1),
('Electricity - warehouse', 128.20, '2025-02-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 128.20.
Created by Miltos Karabasilis (id: 2) at 2025-02-05 12:00:00
', 1),
('Courier last-mile delivery', 173.40, '2025-02-10', 'Outbound logistics fee for home deliveries generated by online checkout.
Created by Miltos Karabasilis (id: 2) at 2025-02-10 12:00:00
', 1),
('Warehouse & office rent', 942.00, '2025-03-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-03-01 12:00:00
', 1),
('Electricity - warehouse', 130.20, '2025-03-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 130.20.
Created by Miltos Karabasilis (id: 2) at 2025-03-05 12:00:00
', 1),
('Thermal shipping labels', 176.40, '2025-03-10', 'Supplier delivered on time. Cartons were sturdy; one pallet had torn corners but stock was usable.
Created by Miltos Karabasilis (id: 2) at 2025-03-10 12:00:00
', 1),
('Warehouse & office rent', 950.00, '2025-04-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-04-01 12:00:00
', 1),
('Electricity - warehouse', 132.20, '2025-04-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 132.20.
Created by Miltos Karabasilis (id: 2) at 2025-04-05 12:00:00
', 1),
('Warehouse rack maintenance', 179.40, '2025-04-10', 'Scheduled inspection and fixes on storage racks after peak picking weeks.
Created by Miltos Karabasilis (id: 2) at 2025-04-10 12:00:00
', 1),
('Warehouse & office rent', 958.00, '2025-05-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-05-01 12:00:00
', 1),
('Electricity - warehouse', 134.20, '2025-05-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 134.20.
Created by Miltos Karabasilis (id: 2) at 2025-05-05 12:00:00
', 1),
('Shopify platform fee', 182.40, '2025-05-10', 'Website platform invoice for storefront uptime and order-management tools.
Created by Miltos Karabasilis (id: 2) at 2025-05-10 12:00:00
', 1),
('Warehouse & office rent', 966.00, '2025-06-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-06-01 12:00:00
', 1),
('Electricity - warehouse', 136.20, '2025-06-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 136.20.
Created by Miltos Karabasilis (id: 2) at 2025-06-05 12:00:00
', 1),
('Packaging & bubble wrap', 185.40, '2025-06-10', 'Bulk purchase of mailer boxes and protective wrap for daily dispatch volume.
Created by Miltos Karabasilis (id: 2) at 2025-06-10 12:00:00
', 1),
('Warehouse & office rent', 974.00, '2025-07-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-07-01 12:00:00
', 1),
('Electricity - warehouse', 138.20, '2025-07-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 138.20.
Created by Miltos Karabasilis (id: 2) at 2025-07-05 12:00:00
', 1),
('Courier last-mile delivery', 188.40, '2025-07-10', 'Outbound logistics fee for home deliveries generated by online checkout.
Created by Miltos Karabasilis (id: 2) at 2025-07-10 12:00:00
', 1),
('Warehouse & office rent', 982.00, '2025-08-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-08-01 12:00:00
', 1),
('Electricity - warehouse', 140.20, '2025-08-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 140.20.
Created by Miltos Karabasilis (id: 2) at 2025-08-05 12:00:00
', 1),
('Thermal shipping labels', 191.40, '2025-08-10', 'Label supply order matched to current warehouse printer specifications.
Created by Miltos Karabasilis (id: 2) at 2025-08-10 12:00:00
', 1),
('Warehouse & office rent', 990.00, '2025-09-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-09-01 12:00:00
', 1),
('Electricity - warehouse', 142.20, '2025-09-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 142.20.
Created by Miltos Karabasilis (id: 2) at 2025-09-05 12:00:00
', 1),
('Warehouse rack maintenance', 194.40, '2025-09-10', 'Scheduled inspection and fixes on storage racks after peak picking weeks.
Created by Miltos Karabasilis (id: 2) at 2025-09-10 12:00:00
', 1),
('Warehouse & office rent', 998.00, '2025-10-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2025-10-01 12:00:00
', 1),
('Electricity - warehouse', 144.20, '2025-10-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 144.20.
Created by Miltos Karabasilis (id: 2) at 2025-10-05 12:00:00
', 1),
('Shopify platform fee', 197.40, '2025-10-10', 'Website platform invoice for storefront uptime and order-management tools.
Created by Miltos Karabasilis (id: 2) at 2025-10-10 12:00:00
', 1),
('Warehouse & office rent', 1006.00, '2025-11-01', 'Monthly lease for warehouse unit B and adjoining office space, including loading bay access.
Created by Miltos Karabasilis (id: 2) at 2025-11-01 12:00:00
', 1),
('Electricity - warehouse', 146.20, '2025-11-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 146.20.
Created by Miltos Karabasilis (id: 2) at 2025-11-05 12:00:00
', 1),
('Packaging & bubble wrap', 200.40, '2025-11-10', 'Bulk purchase of mailer boxes and protective wrap for daily dispatch volume.
Created by Miltos Karabasilis (id: 2) at 2025-11-10 12:00:00
', 1),
('Warehouse & office rent', 1014.00, '2025-12-01', 'Monthly lease for warehouse unit B and adjoining office space, including loading bay access.
Created by Miltos Karabasilis (id: 2) at 2025-12-01 12:00:00
', 1),
('Electricity - warehouse', 148.20, '2025-12-05', 'Utility payment for charging stations, scanners, and overnight security lighting. Amount billed: EUR 148.20.
Created by Miltos Karabasilis (id: 2) at 2025-12-05 12:00:00
', 1),
('Courier last-mile delivery', 203.40, '2025-12-10', 'Outbound logistics fee for home deliveries generated by online checkout.
Created by Miltos Karabasilis (id: 2) at 2025-12-10 12:00:00
', 1),
('Warehouse & office rent', 988.00, '2026-01-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2026-01-01 12:00:00
', 1),
('Packaging & bubble wrap', 178.00, '2026-01-10', 'Packaging supplies order for fragile items and standard parcel sizes.
Created by Miltos Karabasilis (id: 2) at 2026-01-10 12:00:00
', 1),
('Warehouse & office rent', 996.00, '2026-02-01', 'Rent payment covering storage floors, staff offices, and shared logistics yard.
Created by Miltos Karabasilis (id: 2) at 2026-02-01 12:00:00
', 1),
('Electricity - warehouse', 139.00, '2026-02-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 139.00.
Created by Miltos Karabasilis (id: 2) at 2026-02-05 12:00:00
', 1),
('Warehouse & office rent', 1004.00, '2026-03-01', 'Monthly lease for warehouse unit B and adjoining office space, including loading bay access.
Created by Miltos Karabasilis (id: 2) at 2026-03-01 12:00:00
', 1),
('Thermal shipping labels', 184.00, '2026-03-10', 'Printer media restock for shipping labels and return-address stickers.
Created by Miltos Karabasilis (id: 2) at 2026-03-10 12:00:00
', 1),
('Warehouse & office rent', 1012.00, '2026-04-01', 'Monthly lease for warehouse unit B and adjoining office space, including loading bay access.
Created by Miltos Karabasilis (id: 2) at 2026-04-01 12:00:00
', 1),
('Electricity - warehouse', 143.00, '2026-04-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 143.00.
Created by Miltos Karabasilis (id: 2) at 2026-04-05 12:00:00
', 1),
('Warehouse & office rent', 1020.00, '2026-05-01', 'Monthly lease for warehouse unit B and adjoining office space, including loading bay access.
Created by Miltos Karabasilis (id: 2) at 2026-05-01 12:00:00
', 1),
('Shopify platform fee', 190.00, '2026-05-10', 'Platform uptime was stable during the May sale. Checkout and warehouse sync worked without issues.
Created by Miltos Karabasilis (id: 2) at 2026-05-10 12:00:00
', 1),
('Warehouse & office rent', 1028.00, '2026-06-01', 'Monthly lease for warehouse unit B and adjoining office space, including loading bay access.
Created by Miltos Karabasilis (id: 2) at 2026-06-01 12:00:00
', 1),
('Electricity - warehouse', 147.00, '2026-06-05', 'Power consumption charge for cold-storage units and conveyor systems. Amount billed: EUR 147.00.
Created by Miltos Karabasilis (id: 2) at 2026-06-05 12:00:00
', 1),
('Packaging & bubble wrap', 191.60, '2026-06-10', 'Bulk purchase of mailer boxes and protective wrap for daily dispatch volume.
Created by Miltos Karabasilis (id: 2) at 2026-06-10 12:00:00
', 1),
('Courier last-mile delivery', 198.40, '2026-06-15', 'Outbound logistics fee for home deliveries generated by online checkout.
Created by Miltos Karabasilis (id: 2) at 2026-06-15 12:00:00
', 1),
('Thermal shipping labels', 188.20, '2026-06-20', 'Printer media restock for shipping labels and return-address stickers.
Created by Miltos Karabasilis (id: 2) at 2026-06-20 12:00:00
', 1),
('Shopify platform fee', 194.00, '2026-06-25', 'Website platform invoice for storefront uptime and order-management tools.
Created by Miltos Karabasilis (id: 2) at 2026-06-25 12:00:00
', 1);

-- Income 2023-2026 (e-shop and physical store revenue)
INSERT INTO `income` (`Source`, `Income`, `DateOfIncome`, `Notes`, `companyID`) VALUES
('E-shop revenue', 132.25, '2023-01-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230101-225.
Created by Miltos Karabasilis (id: 2) at 2023-01-01 12:00:00
', 1),
('Physical store revenue', 81.05, '2023-01-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230101-105.
Created by Miltos Karabasilis (id: 2) at 2023-01-01 12:00:00
', 1),
('E-shop revenue', 120.22, '2023-01-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230102-022.
Created by Miltos Karabasilis (id: 2) at 2023-01-02 12:00:00
', 1),
('Physical store revenue', 73.68, '2023-01-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230102-368.
Created by Miltos Karabasilis (id: 2) at 2023-01-02 12:00:00
', 1),
('E-shop revenue', 111.29, '2023-01-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230103-129.
Created by Miltos Karabasilis (id: 2) at 2023-01-03 12:00:00
', 1),
('Physical store revenue', 68.21, '2023-01-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230103-821.
Created by Miltos Karabasilis (id: 2) at 2023-01-03 12:00:00
', 1),
('E-shop revenue', 114.76, '2023-01-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230104-476.
Created by Miltos Karabasilis (id: 2) at 2023-01-04 12:00:00
', 1),
('Physical store revenue', 70.34, '2023-01-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230104-034.
Created by Miltos Karabasilis (id: 2) at 2023-01-04 12:00:00
', 1),
('E-shop revenue', 118.23, '2023-01-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230105-823.
Created by Miltos Karabasilis (id: 2) at 2023-01-05 12:00:00
', 1),
('Physical store revenue', 72.47, '2023-01-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230105-247.
Created by Miltos Karabasilis (id: 2) at 2023-01-05 12:00:00
', 1),
('E-shop revenue', 121.71, '2023-01-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230106-171.
Created by Miltos Karabasilis (id: 2) at 2023-01-06 12:00:00
', 1),
('Physical store revenue', 74.59, '2023-01-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230106-459.
Created by Miltos Karabasilis (id: 2) at 2023-01-06 12:00:00
', 1),
('E-shop revenue', 143.96, '2023-01-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230107-396.
Created by Miltos Karabasilis (id: 2) at 2023-01-07 12:00:00
', 1),
('Physical store revenue', 88.24, '2023-01-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230107-824.
Created by Miltos Karabasilis (id: 2) at 2023-01-07 12:00:00
', 1),
('E-shop revenue', 147.44, '2023-01-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230108-744.
Created by Miltos Karabasilis (id: 2) at 2023-01-08 12:00:00
', 1),
('Physical store revenue', 90.36, '2023-01-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230108-036.
Created by Miltos Karabasilis (id: 2) at 2023-01-08 12:00:00
', 1),
('E-shop revenue', 135.41, '2023-01-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230109-541.
Created by Miltos Karabasilis (id: 2) at 2023-01-09 12:00:00
', 1),
('Physical store revenue', 82.99, '2023-01-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230109-299.
Created by Miltos Karabasilis (id: 2) at 2023-01-09 12:00:00
', 1),
('E-shop revenue', 126.48, '2023-01-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230110-648.
Created by Miltos Karabasilis (id: 2) at 2023-01-10 12:00:00
', 1),
('Physical store revenue', 77.52, '2023-01-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230110-752.
Created by Miltos Karabasilis (id: 2) at 2023-01-10 12:00:00
', 1),
('E-shop revenue', 129.95, '2023-01-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230111-995.
Created by Miltos Karabasilis (id: 2) at 2023-01-11 12:00:00
', 1),
('Physical store revenue', 79.65, '2023-01-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230111-965.
Created by Miltos Karabasilis (id: 2) at 2023-01-11 12:00:00
', 1),
('E-shop revenue', 133.42, '2023-01-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230112-342.
Created by Miltos Karabasilis (id: 2) at 2023-01-12 12:00:00
', 1),
('Physical store revenue', 81.78, '2023-01-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230112-178.
Created by Miltos Karabasilis (id: 2) at 2023-01-12 12:00:00
', 1),
('E-shop revenue', 136.90, '2023-01-13', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230113-690.
Created by Miltos Karabasilis (id: 2) at 2023-01-13 12:00:00
', 1),
('Physical store revenue', 83.90, '2023-01-13', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230113-390.
Created by Miltos Karabasilis (id: 2) at 2023-01-13 12:00:00
', 1),
('E-shop revenue', 159.15, '2023-01-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230114-915.
Created by Miltos Karabasilis (id: 2) at 2023-01-14 12:00:00
', 1),
('Physical store revenue', 97.55, '2023-01-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230114-755.
Created by Miltos Karabasilis (id: 2) at 2023-01-14 12:00:00
', 1),
('E-shop revenue', 162.63, '2023-01-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230115-263.
Created by Miltos Karabasilis (id: 2) at 2023-01-15 12:00:00
', 1),
('Physical store revenue', 99.67, '2023-01-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230115-967.
Created by Miltos Karabasilis (id: 2) at 2023-01-15 12:00:00
', 1),
('E-shop revenue', 150.60, '2023-01-16', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230116-060.
Created by Miltos Karabasilis (id: 2) at 2023-01-16 12:00:00
', 1),
('Physical store revenue', 92.30, '2023-01-16', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230116-230.
Created by Miltos Karabasilis (id: 2) at 2023-01-16 12:00:00
', 1),
('E-shop revenue', 141.67, '2023-01-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230117-167.
Created by Miltos Karabasilis (id: 2) at 2023-01-17 12:00:00
', 1),
('Physical store revenue', 86.83, '2023-01-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230117-683.
Created by Miltos Karabasilis (id: 2) at 2023-01-17 12:00:00
', 1),
('E-shop revenue', 108.25, '2023-01-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230118-825.
Created by Miltos Karabasilis (id: 2) at 2023-01-18 12:00:00
', 1),
('Physical store revenue', 66.35, '2023-01-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230118-635.
Created by Miltos Karabasilis (id: 2) at 2023-01-18 12:00:00
', 1),
('E-shop revenue', 111.72, '2023-01-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230119-172.
Created by Miltos Karabasilis (id: 2) at 2023-01-19 12:00:00
', 1),
('Physical store revenue', 68.48, '2023-01-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230119-848.
Created by Miltos Karabasilis (id: 2) at 2023-01-19 12:00:00
', 1),
('E-shop revenue', 115.20, '2023-01-20', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230120-520.
Created by Miltos Karabasilis (id: 2) at 2023-01-20 12:00:00
', 1),
('Physical store revenue', 70.60, '2023-01-20', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230120-060.
Created by Miltos Karabasilis (id: 2) at 2023-01-20 12:00:00
', 1),
('E-shop revenue', 137.45, '2023-01-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230121-745.
Created by Miltos Karabasilis (id: 2) at 2023-01-21 12:00:00
', 1),
('Physical store revenue', 84.25, '2023-01-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230121-425.
Created by Miltos Karabasilis (id: 2) at 2023-01-21 12:00:00
', 1),
('E-shop revenue', 140.93, '2023-01-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230122-093.
Created by Miltos Karabasilis (id: 2) at 2023-01-22 12:00:00
', 1),
('Physical store revenue', 86.37, '2023-01-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230122-637.
Created by Miltos Karabasilis (id: 2) at 2023-01-22 12:00:00
', 1),
('E-shop revenue', 128.90, '2023-01-23', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230123-890.
Created by Miltos Karabasilis (id: 2) at 2023-01-23 12:00:00
', 1),
('Physical store revenue', 79.00, '2023-01-23', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230123-900.
Created by Miltos Karabasilis (id: 2) at 2023-01-23 12:00:00
', 1),
('E-shop revenue', 119.97, '2023-01-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230124-997.
Created by Miltos Karabasilis (id: 2) at 2023-01-24 12:00:00
', 1),
('Physical store revenue', 73.53, '2023-01-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230124-353.
Created by Miltos Karabasilis (id: 2) at 2023-01-24 12:00:00
', 1),
('E-shop revenue', 123.44, '2023-01-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230125-344.
Created by Miltos Karabasilis (id: 2) at 2023-01-25 12:00:00
', 1),
('Physical store revenue', 75.66, '2023-01-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230125-566.
Created by Miltos Karabasilis (id: 2) at 2023-01-25 12:00:00
', 1),
('E-shop revenue', 126.91, '2023-01-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230126-691.
Created by Miltos Karabasilis (id: 2) at 2023-01-26 12:00:00
', 1),
('Physical store revenue', 77.79, '2023-01-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230126-779.
Created by Miltos Karabasilis (id: 2) at 2023-01-26 12:00:00
', 1),
('E-shop revenue', 130.39, '2023-01-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230127-039.
Created by Miltos Karabasilis (id: 2) at 2023-01-27 12:00:00
', 1),
('Physical store revenue', 79.91, '2023-01-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230127-991.
Created by Miltos Karabasilis (id: 2) at 2023-01-27 12:00:00
', 1),
('E-shop revenue', 152.64, '2023-01-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230128-264.
Created by Miltos Karabasilis (id: 2) at 2023-01-28 12:00:00
', 1),
('Physical store revenue', 93.56, '2023-01-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230128-356.
Created by Miltos Karabasilis (id: 2) at 2023-01-28 12:00:00
', 1),
('E-shop revenue', 156.12, '2023-01-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230129-612.
Created by Miltos Karabasilis (id: 2) at 2023-01-29 12:00:00
', 1),
('Physical store revenue', 95.68, '2023-01-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230129-568.
Created by Miltos Karabasilis (id: 2) at 2023-01-29 12:00:00
', 1),
('E-shop revenue', 144.09, '2023-01-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230130-409.
Created by Miltos Karabasilis (id: 2) at 2023-01-30 12:00:00
', 1),
('Physical store revenue', 88.31, '2023-01-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230130-831.
Created by Miltos Karabasilis (id: 2) at 2023-01-30 12:00:00
', 1),
('E-shop revenue', 135.16, '2023-01-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230131-516.
Created by Miltos Karabasilis (id: 2) at 2023-01-31 12:00:00
', 1),
('Physical store revenue', 82.84, '2023-01-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230131-284.
Created by Miltos Karabasilis (id: 2) at 2023-01-31 12:00:00
', 1),
('E-shop revenue', 135.47, '2023-02-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230201-547.
Created by Miltos Karabasilis (id: 2) at 2023-02-01 12:00:00
', 1),
('Physical store revenue', 83.03, '2023-02-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230201-303.
Created by Miltos Karabasilis (id: 2) at 2023-02-01 12:00:00
', 1),
('E-shop revenue', 138.94, '2023-02-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230202-894.
Created by Miltos Karabasilis (id: 2) at 2023-02-02 12:00:00
', 1),
('Physical store revenue', 85.16, '2023-02-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230202-516.
Created by Miltos Karabasilis (id: 2) at 2023-02-02 12:00:00
', 1),
('E-shop revenue', 142.41, '2023-02-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230203-241.
Created by Miltos Karabasilis (id: 2) at 2023-02-03 12:00:00
', 1),
('Physical store revenue', 87.29, '2023-02-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230203-729.
Created by Miltos Karabasilis (id: 2) at 2023-02-03 12:00:00
', 1),
('E-shop revenue', 136.90, '2023-02-04', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20230204-690.
Created by Miltos Karabasilis (id: 2) at 2023-02-04 12:00:00
', 1),
('Physical store revenue', 83.90, '2023-02-04', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230204-390.
Created by Miltos Karabasilis (id: 2) at 2023-02-04 12:00:00
', 1),
('E-shop revenue', 140.37, '2023-02-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230205-037.
Created by Miltos Karabasilis (id: 2) at 2023-02-05 12:00:00
', 1),
('Physical store revenue', 86.03, '2023-02-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230205-603.
Created by Miltos Karabasilis (id: 2) at 2023-02-05 12:00:00
', 1),
('E-shop revenue', 128.34, '2023-02-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230206-834.
Created by Miltos Karabasilis (id: 2) at 2023-02-06 12:00:00
', 1),
('Physical store revenue', 78.66, '2023-02-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230206-866.
Created by Miltos Karabasilis (id: 2) at 2023-02-06 12:00:00
', 1),
('E-shop revenue', 110.30, '2023-02-07', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230207-030.
Created by Miltos Karabasilis (id: 2) at 2023-02-07 12:00:00
', 1),
('Physical store revenue', 67.60, '2023-02-07', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230207-760.
Created by Miltos Karabasilis (id: 2) at 2023-02-07 12:00:00
', 1),
('E-shop revenue', 113.77, '2023-02-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230208-377.
Created by Miltos Karabasilis (id: 2) at 2023-02-08 12:00:00
', 1),
('Physical store revenue', 69.73, '2023-02-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230208-973.
Created by Miltos Karabasilis (id: 2) at 2023-02-08 12:00:00
', 1),
('E-shop revenue', 117.24, '2023-02-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230209-724.
Created by Miltos Karabasilis (id: 2) at 2023-02-09 12:00:00
', 1),
('Physical store revenue', 71.86, '2023-02-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230209-186.
Created by Miltos Karabasilis (id: 2) at 2023-02-09 12:00:00
', 1),
('E-shop revenue', 120.71, '2023-02-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230210-071.
Created by Miltos Karabasilis (id: 2) at 2023-02-10 12:00:00
', 1),
('Physical store revenue', 73.99, '2023-02-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230210-399.
Created by Miltos Karabasilis (id: 2) at 2023-02-10 12:00:00
', 1),
('E-shop revenue', 152.09, '2023-02-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230211-209.
Created by Miltos Karabasilis (id: 2) at 2023-02-11 12:00:00
', 1),
('Physical store revenue', 93.21, '2023-02-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230211-321.
Created by Miltos Karabasilis (id: 2) at 2023-02-11 12:00:00
', 1),
('E-shop revenue', 155.56, '2023-02-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230212-556.
Created by Miltos Karabasilis (id: 2) at 2023-02-12 12:00:00
', 1),
('Physical store revenue', 95.34, '2023-02-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230212-534.
Created by Miltos Karabasilis (id: 2) at 2023-02-12 12:00:00
', 1),
('E-shop revenue', 143.53, '2023-02-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230213-353.
Created by Miltos Karabasilis (id: 2) at 2023-02-13 12:00:00
', 1),
('Physical store revenue', 87.97, '2023-02-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230213-797.
Created by Miltos Karabasilis (id: 2) at 2023-02-13 12:00:00
', 1),
('E-shop revenue', 125.49, '2023-02-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230214-549.
Created by Miltos Karabasilis (id: 2) at 2023-02-14 12:00:00
', 1),
('Physical store revenue', 76.91, '2023-02-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230214-691.
Created by Miltos Karabasilis (id: 2) at 2023-02-14 12:00:00
', 1),
('E-shop revenue', 128.96, '2023-02-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230215-896.
Created by Miltos Karabasilis (id: 2) at 2023-02-15 12:00:00
', 1),
('Physical store revenue', 79.04, '2023-02-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230215-904.
Created by Miltos Karabasilis (id: 2) at 2023-02-15 12:00:00
', 1),
('E-shop revenue', 132.43, '2023-02-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230216-243.
Created by Miltos Karabasilis (id: 2) at 2023-02-16 12:00:00
', 1),
('Physical store revenue', 81.17, '2023-02-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230216-117.
Created by Miltos Karabasilis (id: 2) at 2023-02-16 12:00:00
', 1),
('E-shop revenue', 135.90, '2023-02-17', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230217-590.
Created by Miltos Karabasilis (id: 2) at 2023-02-17 12:00:00
', 1),
('Physical store revenue', 83.30, '2023-02-17', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230217-330.
Created by Miltos Karabasilis (id: 2) at 2023-02-17 12:00:00
', 1),
('E-shop revenue', 167.28, '2023-02-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230218-728.
Created by Miltos Karabasilis (id: 2) at 2023-02-18 12:00:00
', 1),
('Physical store revenue', 102.52, '2023-02-18', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230218-252.
Created by Miltos Karabasilis (id: 2) at 2023-02-18 12:00:00
', 1),
('E-shop revenue', 170.75, '2023-02-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230219-075.
Created by Miltos Karabasilis (id: 2) at 2023-02-19 12:00:00
', 1),
('Physical store revenue', 104.65, '2023-02-19', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230219-465.
Created by Miltos Karabasilis (id: 2) at 2023-02-19 12:00:00
', 1),
('E-shop revenue', 158.72, '2023-02-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230220-872.
Created by Miltos Karabasilis (id: 2) at 2023-02-20 12:00:00
', 1),
('Physical store revenue', 97.28, '2023-02-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230220-728.
Created by Miltos Karabasilis (id: 2) at 2023-02-20 12:00:00
', 1),
('E-shop revenue', 103.79, '2023-02-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230221-379.
Created by Miltos Karabasilis (id: 2) at 2023-02-21 12:00:00
', 1),
('Physical store revenue', 63.61, '2023-02-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230221-361.
Created by Miltos Karabasilis (id: 2) at 2023-02-21 12:00:00
', 1),
('E-shop revenue', 107.26, '2023-02-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230222-726.
Created by Miltos Karabasilis (id: 2) at 2023-02-22 12:00:00
', 1),
('Physical store revenue', 65.74, '2023-02-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230222-574.
Created by Miltos Karabasilis (id: 2) at 2023-02-22 12:00:00
', 1),
('E-shop revenue', 110.73, '2023-02-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230223-073.
Created by Miltos Karabasilis (id: 2) at 2023-02-23 12:00:00
', 1),
('Physical store revenue', 67.87, '2023-02-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230223-787.
Created by Miltos Karabasilis (id: 2) at 2023-02-23 12:00:00
', 1),
('E-shop revenue', 114.20, '2023-02-24', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230224-420.
Created by Miltos Karabasilis (id: 2) at 2023-02-24 12:00:00
', 1),
('Physical store revenue', 70.00, '2023-02-24', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230224-000.
Created by Miltos Karabasilis (id: 2) at 2023-02-24 12:00:00
', 1),
('E-shop revenue', 145.58, '2023-02-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230225-558.
Created by Miltos Karabasilis (id: 2) at 2023-02-25 12:00:00
', 1),
('Physical store revenue', 89.22, '2023-02-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230225-922.
Created by Miltos Karabasilis (id: 2) at 2023-02-25 12:00:00
', 1),
('E-shop revenue', 149.05, '2023-02-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230226-905.
Created by Miltos Karabasilis (id: 2) at 2023-02-26 12:00:00
', 1),
('Physical store revenue', 91.35, '2023-02-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230226-135.
Created by Miltos Karabasilis (id: 2) at 2023-02-26 12:00:00
', 1),
('E-shop revenue', 137.02, '2023-02-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230227-702.
Created by Miltos Karabasilis (id: 2) at 2023-02-27 12:00:00
', 1),
('Physical store revenue', 83.98, '2023-02-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230227-398.
Created by Miltos Karabasilis (id: 2) at 2023-02-27 12:00:00
', 1),
('E-shop revenue', 118.98, '2023-02-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230228-898.
Created by Miltos Karabasilis (id: 2) at 2023-02-28 12:00:00
', 1),
('Physical store revenue', 72.92, '2023-02-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230228-292.
Created by Miltos Karabasilis (id: 2) at 2023-02-28 12:00:00
', 1),
('E-shop revenue', 123.19, '2023-03-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230301-319.
Created by Miltos Karabasilis (id: 2) at 2023-03-01 12:00:00
', 1),
('Physical store revenue', 75.51, '2023-03-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230301-551.
Created by Miltos Karabasilis (id: 2) at 2023-03-01 12:00:00
', 1),
('E-shop revenue', 126.67, '2023-03-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230302-667.
Created by Miltos Karabasilis (id: 2) at 2023-03-02 12:00:00
', 1),
('Physical store revenue', 77.63, '2023-03-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230302-763.
Created by Miltos Karabasilis (id: 2) at 2023-03-02 12:00:00
', 1),
('E-shop revenue', 130.14, '2023-03-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230303-014.
Created by Miltos Karabasilis (id: 2) at 2023-03-03 12:00:00
', 1),
('Physical store revenue', 79.76, '2023-03-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230303-976.
Created by Miltos Karabasilis (id: 2) at 2023-03-03 12:00:00
', 1),
('E-shop revenue', 161.51, '2023-03-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230304-151.
Created by Miltos Karabasilis (id: 2) at 2023-03-04 12:00:00
', 1),
('Physical store revenue', 98.99, '2023-03-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230304-899.
Created by Miltos Karabasilis (id: 2) at 2023-03-04 12:00:00
', 1),
('E-shop revenue', 164.98, '2023-03-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230305-498.
Created by Miltos Karabasilis (id: 2) at 2023-03-05 12:00:00
', 1),
('Physical store revenue', 101.12, '2023-03-05', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230305-112.
Created by Miltos Karabasilis (id: 2) at 2023-03-05 12:00:00
', 1),
('E-shop revenue', 152.95, '2023-03-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230306-295.
Created by Miltos Karabasilis (id: 2) at 2023-03-06 12:00:00
', 1),
('Physical store revenue', 93.75, '2023-03-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230306-375.
Created by Miltos Karabasilis (id: 2) at 2023-03-06 12:00:00
', 1),
('E-shop revenue', 134.91, '2023-03-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230307-491.
Created by Miltos Karabasilis (id: 2) at 2023-03-07 12:00:00
', 1),
('Physical store revenue', 82.69, '2023-03-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230307-269.
Created by Miltos Karabasilis (id: 2) at 2023-03-07 12:00:00
', 1),
('E-shop revenue', 138.38, '2023-03-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230308-838.
Created by Miltos Karabasilis (id: 2) at 2023-03-08 12:00:00
', 1),
('Physical store revenue', 84.82, '2023-03-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230308-482.
Created by Miltos Karabasilis (id: 2) at 2023-03-08 12:00:00
', 1),
('E-shop revenue', 141.86, '2023-03-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230309-186.
Created by Miltos Karabasilis (id: 2) at 2023-03-09 12:00:00
', 1),
('Physical store revenue', 86.94, '2023-03-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230309-694.
Created by Miltos Karabasilis (id: 2) at 2023-03-09 12:00:00
', 1),
('E-shop revenue', 108.44, '2023-03-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230310-844.
Created by Miltos Karabasilis (id: 2) at 2023-03-10 12:00:00
', 1),
('Physical store revenue', 66.46, '2023-03-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230310-646.
Created by Miltos Karabasilis (id: 2) at 2023-03-10 12:00:00
', 1),
('E-shop revenue', 139.81, '2023-03-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230311-981.
Created by Miltos Karabasilis (id: 2) at 2023-03-11 12:00:00
', 1),
('Physical store revenue', 85.69, '2023-03-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230311-569.
Created by Miltos Karabasilis (id: 2) at 2023-03-11 12:00:00
', 1),
('E-shop revenue', 143.28, '2023-03-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230312-328.
Created by Miltos Karabasilis (id: 2) at 2023-03-12 12:00:00
', 1),
('Physical store revenue', 87.82, '2023-03-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230312-782.
Created by Miltos Karabasilis (id: 2) at 2023-03-12 12:00:00
', 1),
('E-shop revenue', 131.25, '2023-03-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230313-125.
Created by Miltos Karabasilis (id: 2) at 2023-03-13 12:00:00
', 1),
('Physical store revenue', 80.45, '2023-03-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230313-045.
Created by Miltos Karabasilis (id: 2) at 2023-03-13 12:00:00
', 1),
('E-shop revenue', 113.21, '2023-03-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230314-321.
Created by Miltos Karabasilis (id: 2) at 2023-03-14 12:00:00
', 1),
('Physical store revenue', 69.39, '2023-03-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230314-939.
Created by Miltos Karabasilis (id: 2) at 2023-03-14 12:00:00
', 1),
('E-shop revenue', 116.68, '2023-03-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230315-668.
Created by Miltos Karabasilis (id: 2) at 2023-03-15 12:00:00
', 1),
('Physical store revenue', 71.52, '2023-03-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230315-152.
Created by Miltos Karabasilis (id: 2) at 2023-03-15 12:00:00
', 1),
('E-shop revenue', 120.16, '2023-03-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230316-016.
Created by Miltos Karabasilis (id: 2) at 2023-03-16 12:00:00
', 1),
('Physical store revenue', 73.64, '2023-03-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230316-364.
Created by Miltos Karabasilis (id: 2) at 2023-03-16 12:00:00
', 1),
('E-shop revenue', 123.63, '2023-03-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230317-363.
Created by Miltos Karabasilis (id: 2) at 2023-03-17 12:00:00
', 1),
('Physical store revenue', 75.77, '2023-03-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230317-577.
Created by Miltos Karabasilis (id: 2) at 2023-03-17 12:00:00
', 1),
('E-shop revenue', 155.00, '2023-03-18', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Weekend order batch reference WEB-20230318-500.
Created by Miltos Karabasilis (id: 2) at 2023-03-18 12:00:00
', 1),
('Physical store revenue', 95.00, '2023-03-18', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230318-500.
Created by Miltos Karabasilis (id: 2) at 2023-03-18 12:00:00
', 1),
('E-shop revenue', 158.47, '2023-03-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230319-847.
Created by Miltos Karabasilis (id: 2) at 2023-03-19 12:00:00
', 1),
('Physical store revenue', 97.13, '2023-03-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230319-713.
Created by Miltos Karabasilis (id: 2) at 2023-03-19 12:00:00
', 1),
('E-shop revenue', 146.44, '2023-03-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230320-644.
Created by Miltos Karabasilis (id: 2) at 2023-03-20 12:00:00
', 1),
('Physical store revenue', 89.76, '2023-03-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230320-976.
Created by Miltos Karabasilis (id: 2) at 2023-03-20 12:00:00
', 1),
('E-shop revenue', 128.40, '2023-03-21', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230321-840.
Created by Miltos Karabasilis (id: 2) at 2023-03-21 12:00:00
', 1),
('Physical store revenue', 78.70, '2023-03-21', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230321-870.
Created by Miltos Karabasilis (id: 2) at 2023-03-21 12:00:00
', 1),
('E-shop revenue', 131.87, '2023-03-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230322-187.
Created by Miltos Karabasilis (id: 2) at 2023-03-22 12:00:00
', 1),
('Physical store revenue', 80.83, '2023-03-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230322-083.
Created by Miltos Karabasilis (id: 2) at 2023-03-22 12:00:00
', 1),
('E-shop revenue', 135.35, '2023-03-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230323-535.
Created by Miltos Karabasilis (id: 2) at 2023-03-23 12:00:00
', 1),
('Physical store revenue', 82.95, '2023-03-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230323-295.
Created by Miltos Karabasilis (id: 2) at 2023-03-23 12:00:00
', 1),
('E-shop revenue', 138.82, '2023-03-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230324-882.
Created by Miltos Karabasilis (id: 2) at 2023-03-24 12:00:00
', 1),
('Physical store revenue', 85.08, '2023-03-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230324-508.
Created by Miltos Karabasilis (id: 2) at 2023-03-24 12:00:00
', 1),
('E-shop revenue', 170.19, '2023-03-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230325-019.
Created by Miltos Karabasilis (id: 2) at 2023-03-25 12:00:00
', 1),
('Physical store revenue', 104.31, '2023-03-25', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230325-431.
Created by Miltos Karabasilis (id: 2) at 2023-03-25 12:00:00
', 1),
('E-shop revenue', 173.66, '2023-03-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230326-366.
Created by Miltos Karabasilis (id: 2) at 2023-03-26 12:00:00
', 1),
('Physical store revenue', 106.44, '2023-03-26', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230326-644.
Created by Miltos Karabasilis (id: 2) at 2023-03-26 12:00:00
', 1),
('E-shop revenue', 124.74, '2023-03-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230327-474.
Created by Miltos Karabasilis (id: 2) at 2023-03-27 12:00:00
', 1),
('Physical store revenue', 76.46, '2023-03-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230327-646.
Created by Miltos Karabasilis (id: 2) at 2023-03-27 12:00:00
', 1),
('E-shop revenue', 106.70, '2023-03-28', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230328-670.
Created by Miltos Karabasilis (id: 2) at 2023-03-28 12:00:00
', 1),
('Physical store revenue', 65.40, '2023-03-28', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230328-540.
Created by Miltos Karabasilis (id: 2) at 2023-03-28 12:00:00
', 1),
('E-shop revenue', 110.17, '2023-03-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230329-017.
Created by Miltos Karabasilis (id: 2) at 2023-03-29 12:00:00
', 1),
('Physical store revenue', 67.53, '2023-03-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230329-753.
Created by Miltos Karabasilis (id: 2) at 2023-03-29 12:00:00
', 1),
('E-shop revenue', 113.65, '2023-03-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230330-365.
Created by Miltos Karabasilis (id: 2) at 2023-03-30 12:00:00
', 1),
('Physical store revenue', 69.65, '2023-03-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230330-965.
Created by Miltos Karabasilis (id: 2) at 2023-03-30 12:00:00
', 1),
('E-shop revenue', 117.12, '2023-03-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230331-712.
Created by Miltos Karabasilis (id: 2) at 2023-03-31 12:00:00
', 1),
('Physical store revenue', 71.78, '2023-03-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230331-178.
Created by Miltos Karabasilis (id: 2) at 2023-03-31 12:00:00
', 1),
('E-shop revenue', 145.33, '2023-04-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230401-533.
Created by Miltos Karabasilis (id: 2) at 2023-04-01 12:00:00
', 1),
('Physical store revenue', 89.07, '2023-04-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230401-907.
Created by Miltos Karabasilis (id: 2) at 2023-04-01 12:00:00
', 1),
('E-shop revenue', 148.80, '2023-04-02', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20230402-880.
Created by Miltos Karabasilis (id: 2) at 2023-04-02 12:00:00
', 1),
('Physical store revenue', 91.20, '2023-04-02', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230402-120.
Created by Miltos Karabasilis (id: 2) at 2023-04-02 12:00:00
', 1),
('E-shop revenue', 136.77, '2023-04-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230403-677.
Created by Miltos Karabasilis (id: 2) at 2023-04-03 12:00:00
', 1),
('Physical store revenue', 83.83, '2023-04-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230403-383.
Created by Miltos Karabasilis (id: 2) at 2023-04-03 12:00:00
', 1),
('E-shop revenue', 127.84, '2023-04-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230404-784.
Created by Miltos Karabasilis (id: 2) at 2023-04-04 12:00:00
', 1),
('Physical store revenue', 78.36, '2023-04-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230404-836.
Created by Miltos Karabasilis (id: 2) at 2023-04-04 12:00:00
', 1),
('E-shop revenue', 131.32, '2023-04-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230405-132.
Created by Miltos Karabasilis (id: 2) at 2023-04-05 12:00:00
', 1),
('Physical store revenue', 80.48, '2023-04-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230405-048.
Created by Miltos Karabasilis (id: 2) at 2023-04-05 12:00:00
', 1),
('E-shop revenue', 134.79, '2023-04-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230406-479.
Created by Miltos Karabasilis (id: 2) at 2023-04-06 12:00:00
', 1),
('Physical store revenue', 82.61, '2023-04-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230406-261.
Created by Miltos Karabasilis (id: 2) at 2023-04-06 12:00:00
', 1),
('E-shop revenue', 129.15, '2023-04-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230407-915.
Created by Miltos Karabasilis (id: 2) at 2023-04-07 12:00:00
', 1),
('Physical store revenue', 79.15, '2023-04-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230407-915.
Created by Miltos Karabasilis (id: 2) at 2023-04-07 12:00:00
', 1),
('E-shop revenue', 160.52, '2023-04-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230408-052.
Created by Miltos Karabasilis (id: 2) at 2023-04-08 12:00:00
', 1),
('Physical store revenue', 98.38, '2023-04-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230408-838.
Created by Miltos Karabasilis (id: 2) at 2023-04-08 12:00:00
', 1),
('E-shop revenue', 163.99, '2023-04-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230409-399.
Created by Miltos Karabasilis (id: 2) at 2023-04-09 12:00:00
', 1),
('Physical store revenue', 100.51, '2023-04-09', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230409-051.
Created by Miltos Karabasilis (id: 2) at 2023-04-09 12:00:00
', 1),
('E-shop revenue', 151.96, '2023-04-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230410-196.
Created by Miltos Karabasilis (id: 2) at 2023-04-10 12:00:00
', 1),
('Physical store revenue', 93.14, '2023-04-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230410-314.
Created by Miltos Karabasilis (id: 2) at 2023-04-10 12:00:00
', 1),
('E-shop revenue', 143.03, '2023-04-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230411-303.
Created by Miltos Karabasilis (id: 2) at 2023-04-11 12:00:00
', 1),
('Physical store revenue', 87.67, '2023-04-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230411-767.
Created by Miltos Karabasilis (id: 2) at 2023-04-11 12:00:00
', 1),
('E-shop revenue', 146.51, '2023-04-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230412-651.
Created by Miltos Karabasilis (id: 2) at 2023-04-12 12:00:00
', 1),
('Physical store revenue', 89.79, '2023-04-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230412-979.
Created by Miltos Karabasilis (id: 2) at 2023-04-12 12:00:00
', 1),
('E-shop revenue', 113.09, '2023-04-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230413-309.
Created by Miltos Karabasilis (id: 2) at 2023-04-13 12:00:00
', 1),
('Physical store revenue', 69.31, '2023-04-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230413-931.
Created by Miltos Karabasilis (id: 2) at 2023-04-13 12:00:00
', 1),
('E-shop revenue', 107.45, '2023-04-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230414-745.
Created by Miltos Karabasilis (id: 2) at 2023-04-14 12:00:00
', 1),
('Physical store revenue', 65.85, '2023-04-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230414-585.
Created by Miltos Karabasilis (id: 2) at 2023-04-14 12:00:00
', 1),
('E-shop revenue', 138.82, '2023-04-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230415-882.
Created by Miltos Karabasilis (id: 2) at 2023-04-15 12:00:00
', 1),
('Physical store revenue', 85.08, '2023-04-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230415-508.
Created by Miltos Karabasilis (id: 2) at 2023-04-15 12:00:00
', 1),
('E-shop revenue', 142.29, '2023-04-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230416-229.
Created by Miltos Karabasilis (id: 2) at 2023-04-16 12:00:00
', 1),
('Physical store revenue', 87.21, '2023-04-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230416-721.
Created by Miltos Karabasilis (id: 2) at 2023-04-16 12:00:00
', 1),
('E-shop revenue', 130.26, '2023-04-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230417-026.
Created by Miltos Karabasilis (id: 2) at 2023-04-17 12:00:00
', 1),
('Physical store revenue', 79.84, '2023-04-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230417-984.
Created by Miltos Karabasilis (id: 2) at 2023-04-17 12:00:00
', 1),
('E-shop revenue', 121.33, '2023-04-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230418-133.
Created by Miltos Karabasilis (id: 2) at 2023-04-18 12:00:00
', 1),
('Physical store revenue', 74.37, '2023-04-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230418-437.
Created by Miltos Karabasilis (id: 2) at 2023-04-18 12:00:00
', 1),
('E-shop revenue', 124.81, '2023-04-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230419-481.
Created by Miltos Karabasilis (id: 2) at 2023-04-19 12:00:00
', 1),
('Physical store revenue', 76.49, '2023-04-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230419-649.
Created by Miltos Karabasilis (id: 2) at 2023-04-19 12:00:00
', 1),
('E-shop revenue', 128.28, '2023-04-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230420-828.
Created by Miltos Karabasilis (id: 2) at 2023-04-20 12:00:00
', 1),
('Physical store revenue', 78.62, '2023-04-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230420-862.
Created by Miltos Karabasilis (id: 2) at 2023-04-20 12:00:00
', 1),
('E-shop revenue', 122.64, '2023-04-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230421-264.
Created by Miltos Karabasilis (id: 2) at 2023-04-21 12:00:00
', 1),
('Physical store revenue', 75.16, '2023-04-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230421-516.
Created by Miltos Karabasilis (id: 2) at 2023-04-21 12:00:00
', 1),
('E-shop revenue', 154.01, '2023-04-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230422-401.
Created by Miltos Karabasilis (id: 2) at 2023-04-22 12:00:00
', 1),
('Physical store revenue', 94.39, '2023-04-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230422-439.
Created by Miltos Karabasilis (id: 2) at 2023-04-22 12:00:00
', 1),
('E-shop revenue', 157.48, '2023-04-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230423-748.
Created by Miltos Karabasilis (id: 2) at 2023-04-23 12:00:00
', 1),
('Physical store revenue', 96.52, '2023-04-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230423-652.
Created by Miltos Karabasilis (id: 2) at 2023-04-23 12:00:00
', 1),
('E-shop revenue', 145.45, '2023-04-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230424-545.
Created by Miltos Karabasilis (id: 2) at 2023-04-24 12:00:00
', 1),
('Physical store revenue', 89.15, '2023-04-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230424-915.
Created by Miltos Karabasilis (id: 2) at 2023-04-24 12:00:00
', 1),
('E-shop revenue', 136.52, '2023-04-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230425-652.
Created by Miltos Karabasilis (id: 2) at 2023-04-25 12:00:00
', 1),
('Physical store revenue', 83.68, '2023-04-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230425-368.
Created by Miltos Karabasilis (id: 2) at 2023-04-25 12:00:00
', 1),
('E-shop revenue', 140.00, '2023-04-26', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20230426-000.
Created by Miltos Karabasilis (id: 2) at 2023-04-26 12:00:00
', 1),
('Physical store revenue', 85.80, '2023-04-26', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230426-580.
Created by Miltos Karabasilis (id: 2) at 2023-04-26 12:00:00
', 1),
('E-shop revenue', 143.47, '2023-04-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230427-347.
Created by Miltos Karabasilis (id: 2) at 2023-04-27 12:00:00
', 1),
('Physical store revenue', 87.93, '2023-04-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230427-793.
Created by Miltos Karabasilis (id: 2) at 2023-04-27 12:00:00
', 1),
('E-shop revenue', 137.83, '2023-04-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230428-783.
Created by Miltos Karabasilis (id: 2) at 2023-04-28 12:00:00
', 1),
('Physical store revenue', 84.47, '2023-04-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230428-447.
Created by Miltos Karabasilis (id: 2) at 2023-04-28 12:00:00
', 1),
('E-shop revenue', 169.20, '2023-04-29', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20230429-920.
Created by Miltos Karabasilis (id: 2) at 2023-04-29 12:00:00
', 1),
('Physical store revenue', 103.70, '2023-04-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230429-370.
Created by Miltos Karabasilis (id: 2) at 2023-04-29 12:00:00
', 1),
('E-shop revenue', 135.78, '2023-04-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230430-578.
Created by Miltos Karabasilis (id: 2) at 2023-04-30 12:00:00
', 1),
('Physical store revenue', 83.22, '2023-04-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230430-322.
Created by Miltos Karabasilis (id: 2) at 2023-04-30 12:00:00
', 1),
('E-shop revenue', 121.89, '2023-05-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230501-189.
Created by Miltos Karabasilis (id: 2) at 2023-05-01 12:00:00
', 1),
('Physical store revenue', 74.71, '2023-05-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230501-471.
Created by Miltos Karabasilis (id: 2) at 2023-05-01 12:00:00
', 1),
('E-shop revenue', 112.96, '2023-05-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230502-296.
Created by Miltos Karabasilis (id: 2) at 2023-05-02 12:00:00
', 1),
('Physical store revenue', 69.24, '2023-05-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230502-924.
Created by Miltos Karabasilis (id: 2) at 2023-05-02 12:00:00
', 1),
('E-shop revenue', 116.44, '2023-05-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230503-644.
Created by Miltos Karabasilis (id: 2) at 2023-05-03 12:00:00
', 1),
('Physical store revenue', 71.36, '2023-05-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230503-136.
Created by Miltos Karabasilis (id: 2) at 2023-05-03 12:00:00
', 1),
('E-shop revenue', 119.91, '2023-05-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230504-991.
Created by Miltos Karabasilis (id: 2) at 2023-05-04 12:00:00
', 1),
('Physical store revenue', 73.49, '2023-05-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230504-349.
Created by Miltos Karabasilis (id: 2) at 2023-05-04 12:00:00
', 1),
('E-shop revenue', 123.38, '2023-05-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230505-338.
Created by Miltos Karabasilis (id: 2) at 2023-05-05 12:00:00
', 1),
('Physical store revenue', 75.62, '2023-05-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230505-562.
Created by Miltos Karabasilis (id: 2) at 2023-05-05 12:00:00
', 1),
('E-shop revenue', 154.75, '2023-05-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230506-475.
Created by Miltos Karabasilis (id: 2) at 2023-05-06 12:00:00
', 1),
('Physical store revenue', 94.85, '2023-05-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230506-485.
Created by Miltos Karabasilis (id: 2) at 2023-05-06 12:00:00
', 1),
('E-shop revenue', 149.11, '2023-05-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230507-911.
Created by Miltos Karabasilis (id: 2) at 2023-05-07 12:00:00
', 1),
('Physical store revenue', 91.39, '2023-05-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230507-139.
Created by Miltos Karabasilis (id: 2) at 2023-05-07 12:00:00
', 1),
('E-shop revenue', 137.08, '2023-05-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230508-708.
Created by Miltos Karabasilis (id: 2) at 2023-05-08 12:00:00
', 1),
('Physical store revenue', 84.02, '2023-05-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230508-402.
Created by Miltos Karabasilis (id: 2) at 2023-05-08 12:00:00
', 1),
('E-shop revenue', 128.15, '2023-05-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230509-815.
Created by Miltos Karabasilis (id: 2) at 2023-05-09 12:00:00
', 1),
('Physical store revenue', 78.55, '2023-05-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230509-855.
Created by Miltos Karabasilis (id: 2) at 2023-05-09 12:00:00
', 1),
('E-shop revenue', 131.63, '2023-05-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230510-163.
Created by Miltos Karabasilis (id: 2) at 2023-05-10 12:00:00
', 1),
('Physical store revenue', 80.67, '2023-05-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230510-067.
Created by Miltos Karabasilis (id: 2) at 2023-05-10 12:00:00
', 1),
('E-shop revenue', 135.10, '2023-05-11', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230511-510.
Created by Miltos Karabasilis (id: 2) at 2023-05-11 12:00:00
', 1),
('Physical store revenue', 82.80, '2023-05-11', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230511-280.
Created by Miltos Karabasilis (id: 2) at 2023-05-11 12:00:00
', 1),
('E-shop revenue', 138.57, '2023-05-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230512-857.
Created by Miltos Karabasilis (id: 2) at 2023-05-12 12:00:00
', 1),
('Physical store revenue', 84.93, '2023-05-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230512-493.
Created by Miltos Karabasilis (id: 2) at 2023-05-12 12:00:00
', 1),
('E-shop revenue', 169.94, '2023-05-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230513-994.
Created by Miltos Karabasilis (id: 2) at 2023-05-13 12:00:00
', 1),
('Physical store revenue', 104.16, '2023-05-13', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230513-416.
Created by Miltos Karabasilis (id: 2) at 2023-05-13 12:00:00
', 1),
('E-shop revenue', 164.30, '2023-05-14', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20230514-430.
Created by Miltos Karabasilis (id: 2) at 2023-05-14 12:00:00
', 1),
('Physical store revenue', 100.70, '2023-05-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230514-070.
Created by Miltos Karabasilis (id: 2) at 2023-05-14 12:00:00
', 1),
('E-shop revenue', 152.27, '2023-05-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230515-227.
Created by Miltos Karabasilis (id: 2) at 2023-05-15 12:00:00
', 1),
('Physical store revenue', 93.33, '2023-05-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230515-333.
Created by Miltos Karabasilis (id: 2) at 2023-05-15 12:00:00
', 1),
('E-shop revenue', 143.34, '2023-05-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230516-334.
Created by Miltos Karabasilis (id: 2) at 2023-05-16 12:00:00
', 1),
('Physical store revenue', 87.86, '2023-05-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230516-786.
Created by Miltos Karabasilis (id: 2) at 2023-05-16 12:00:00
', 1),
('E-shop revenue', 109.93, '2023-05-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230517-993.
Created by Miltos Karabasilis (id: 2) at 2023-05-17 12:00:00
', 1),
('Physical store revenue', 67.37, '2023-05-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230517-737.
Created by Miltos Karabasilis (id: 2) at 2023-05-17 12:00:00
', 1),
('E-shop revenue', 113.40, '2023-05-18', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230518-340.
Created by Miltos Karabasilis (id: 2) at 2023-05-18 12:00:00
', 1),
('Physical store revenue', 69.50, '2023-05-18', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230518-950.
Created by Miltos Karabasilis (id: 2) at 2023-05-18 12:00:00
', 1),
('E-shop revenue', 116.87, '2023-05-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230519-687.
Created by Miltos Karabasilis (id: 2) at 2023-05-19 12:00:00
', 1),
('Physical store revenue', 71.63, '2023-05-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230519-163.
Created by Miltos Karabasilis (id: 2) at 2023-05-19 12:00:00
', 1),
('E-shop revenue', 148.24, '2023-05-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230520-824.
Created by Miltos Karabasilis (id: 2) at 2023-05-20 12:00:00
', 1),
('Physical store revenue', 90.86, '2023-05-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230520-086.
Created by Miltos Karabasilis (id: 2) at 2023-05-20 12:00:00
', 1),
('E-shop revenue', 142.60, '2023-05-21', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20230521-260.
Created by Miltos Karabasilis (id: 2) at 2023-05-21 12:00:00
', 1),
('Physical store revenue', 87.40, '2023-05-21', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230521-740.
Created by Miltos Karabasilis (id: 2) at 2023-05-21 12:00:00
', 1),
('E-shop revenue', 130.57, '2023-05-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230522-057.
Created by Miltos Karabasilis (id: 2) at 2023-05-22 12:00:00
', 1),
('Physical store revenue', 80.03, '2023-05-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230522-003.
Created by Miltos Karabasilis (id: 2) at 2023-05-22 12:00:00
', 1),
('E-shop revenue', 121.64, '2023-05-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230523-164.
Created by Miltos Karabasilis (id: 2) at 2023-05-23 12:00:00
', 1),
('Physical store revenue', 74.56, '2023-05-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230523-456.
Created by Miltos Karabasilis (id: 2) at 2023-05-23 12:00:00
', 1),
('E-shop revenue', 125.12, '2023-05-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230524-512.
Created by Miltos Karabasilis (id: 2) at 2023-05-24 12:00:00
', 1),
('Physical store revenue', 76.68, '2023-05-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230524-668.
Created by Miltos Karabasilis (id: 2) at 2023-05-24 12:00:00
', 1),
('E-shop revenue', 128.59, '2023-05-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230525-859.
Created by Miltos Karabasilis (id: 2) at 2023-05-25 12:00:00
', 1),
('Physical store revenue', 78.81, '2023-05-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230525-881.
Created by Miltos Karabasilis (id: 2) at 2023-05-25 12:00:00
', 1),
('E-shop revenue', 132.06, '2023-05-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230526-206.
Created by Miltos Karabasilis (id: 2) at 2023-05-26 12:00:00
', 1),
('Physical store revenue', 80.94, '2023-05-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230526-094.
Created by Miltos Karabasilis (id: 2) at 2023-05-26 12:00:00
', 1),
('E-shop revenue', 163.43, '2023-05-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230527-343.
Created by Miltos Karabasilis (id: 2) at 2023-05-27 12:00:00
', 1),
('Physical store revenue', 100.17, '2023-05-27', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230527-017.
Created by Miltos Karabasilis (id: 2) at 2023-05-27 12:00:00
', 1),
('E-shop revenue', 157.79, '2023-05-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230528-779.
Created by Miltos Karabasilis (id: 2) at 2023-05-28 12:00:00
', 1),
('Physical store revenue', 96.71, '2023-05-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230528-671.
Created by Miltos Karabasilis (id: 2) at 2023-05-28 12:00:00
', 1),
('E-shop revenue', 145.76, '2023-05-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230529-576.
Created by Miltos Karabasilis (id: 2) at 2023-05-29 12:00:00
', 1),
('Physical store revenue', 89.34, '2023-05-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230529-934.
Created by Miltos Karabasilis (id: 2) at 2023-05-29 12:00:00
', 1),
('E-shop revenue', 136.83, '2023-05-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230530-683.
Created by Miltos Karabasilis (id: 2) at 2023-05-30 12:00:00
', 1),
('Physical store revenue', 83.87, '2023-05-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230530-387.
Created by Miltos Karabasilis (id: 2) at 2023-05-30 12:00:00
', 1),
('E-shop revenue', 140.31, '2023-05-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230531-031.
Created by Miltos Karabasilis (id: 2) at 2023-05-31 12:00:00
', 1),
('Physical store revenue', 85.99, '2023-05-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230531-599.
Created by Miltos Karabasilis (id: 2) at 2023-05-31 12:00:00
', 1),
('E-shop revenue', 140.62, '2023-06-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230601-062.
Created by Miltos Karabasilis (id: 2) at 2023-06-01 12:00:00
', 1),
('Physical store revenue', 86.18, '2023-06-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230601-618.
Created by Miltos Karabasilis (id: 2) at 2023-06-01 12:00:00
', 1),
('E-shop revenue', 144.09, '2023-06-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230602-409.
Created by Miltos Karabasilis (id: 2) at 2023-06-02 12:00:00
', 1),
('Physical store revenue', 88.31, '2023-06-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230602-831.
Created by Miltos Karabasilis (id: 2) at 2023-06-02 12:00:00
', 1),
('E-shop revenue', 138.57, '2023-06-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230603-857.
Created by Miltos Karabasilis (id: 2) at 2023-06-03 12:00:00
', 1),
('Physical store revenue', 84.93, '2023-06-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230603-493.
Created by Miltos Karabasilis (id: 2) at 2023-06-03 12:00:00
', 1),
('E-shop revenue', 142.04, '2023-06-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230604-204.
Created by Miltos Karabasilis (id: 2) at 2023-06-04 12:00:00
', 1),
('Physical store revenue', 87.06, '2023-06-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230604-706.
Created by Miltos Karabasilis (id: 2) at 2023-06-04 12:00:00
', 1),
('E-shop revenue', 130.01, '2023-06-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230605-001.
Created by Miltos Karabasilis (id: 2) at 2023-06-05 12:00:00
', 1),
('Physical store revenue', 79.69, '2023-06-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230605-969.
Created by Miltos Karabasilis (id: 2) at 2023-06-05 12:00:00
', 1),
('E-shop revenue', 121.09, '2023-06-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230606-109.
Created by Miltos Karabasilis (id: 2) at 2023-06-06 12:00:00
', 1),
('Physical store revenue', 74.21, '2023-06-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230606-421.
Created by Miltos Karabasilis (id: 2) at 2023-06-06 12:00:00
', 1),
('E-shop revenue', 115.44, '2023-06-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230607-544.
Created by Miltos Karabasilis (id: 2) at 2023-06-07 12:00:00
', 1),
('Physical store revenue', 70.76, '2023-06-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230607-076.
Created by Miltos Karabasilis (id: 2) at 2023-06-07 12:00:00
', 1),
('E-shop revenue', 118.92, '2023-06-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230608-892.
Created by Miltos Karabasilis (id: 2) at 2023-06-08 12:00:00
', 1),
('Physical store revenue', 72.88, '2023-06-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230608-288.
Created by Miltos Karabasilis (id: 2) at 2023-06-08 12:00:00
', 1),
('E-shop revenue', 122.39, '2023-06-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230609-239.
Created by Miltos Karabasilis (id: 2) at 2023-06-09 12:00:00
', 1),
('Physical store revenue', 75.01, '2023-06-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230609-501.
Created by Miltos Karabasilis (id: 2) at 2023-06-09 12:00:00
', 1),
('E-shop revenue', 153.76, '2023-06-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230610-376.
Created by Miltos Karabasilis (id: 2) at 2023-06-10 12:00:00
', 1),
('Physical store revenue', 94.24, '2023-06-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230610-424.
Created by Miltos Karabasilis (id: 2) at 2023-06-10 12:00:00
', 1),
('E-shop revenue', 157.23, '2023-06-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230611-723.
Created by Miltos Karabasilis (id: 2) at 2023-06-11 12:00:00
', 1),
('Physical store revenue', 96.37, '2023-06-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230611-637.
Created by Miltos Karabasilis (id: 2) at 2023-06-11 12:00:00
', 1),
('E-shop revenue', 145.20, '2023-06-12', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230612-520.
Created by Miltos Karabasilis (id: 2) at 2023-06-12 12:00:00
', 1),
('Physical store revenue', 89.00, '2023-06-12', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230612-900.
Created by Miltos Karabasilis (id: 2) at 2023-06-12 12:00:00
', 1),
('E-shop revenue', 136.28, '2023-06-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230613-628.
Created by Miltos Karabasilis (id: 2) at 2023-06-13 12:00:00
', 1),
('Physical store revenue', 83.52, '2023-06-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230613-352.
Created by Miltos Karabasilis (id: 2) at 2023-06-13 12:00:00
', 1),
('E-shop revenue', 130.63, '2023-06-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230614-063.
Created by Miltos Karabasilis (id: 2) at 2023-06-14 12:00:00
', 1),
('Physical store revenue', 80.07, '2023-06-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230614-007.
Created by Miltos Karabasilis (id: 2) at 2023-06-14 12:00:00
', 1),
('E-shop revenue', 134.11, '2023-06-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230615-411.
Created by Miltos Karabasilis (id: 2) at 2023-06-15 12:00:00
', 1),
('Physical store revenue', 82.19, '2023-06-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230615-219.
Created by Miltos Karabasilis (id: 2) at 2023-06-15 12:00:00
', 1),
('E-shop revenue', 137.58, '2023-06-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230616-758.
Created by Miltos Karabasilis (id: 2) at 2023-06-16 12:00:00
', 1),
('Physical store revenue', 84.32, '2023-06-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230616-432.
Created by Miltos Karabasilis (id: 2) at 2023-06-16 12:00:00
', 1),
('E-shop revenue', 168.95, '2023-06-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230617-895.
Created by Miltos Karabasilis (id: 2) at 2023-06-17 12:00:00
', 1),
('Physical store revenue', 103.55, '2023-06-17', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230617-355.
Created by Miltos Karabasilis (id: 2) at 2023-06-17 12:00:00
', 1),
('E-shop revenue', 172.42, '2023-06-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230618-242.
Created by Miltos Karabasilis (id: 2) at 2023-06-18 12:00:00
', 1),
('Physical store revenue', 105.68, '2023-06-18', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230618-568.
Created by Miltos Karabasilis (id: 2) at 2023-06-18 12:00:00
', 1),
('E-shop revenue', 160.39, '2023-06-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230619-039.
Created by Miltos Karabasilis (id: 2) at 2023-06-19 12:00:00
', 1),
('Physical store revenue', 98.31, '2023-06-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230619-831.
Created by Miltos Karabasilis (id: 2) at 2023-06-19 12:00:00
', 1),
('E-shop revenue', 114.58, '2023-06-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230620-458.
Created by Miltos Karabasilis (id: 2) at 2023-06-20 12:00:00
', 1),
('Physical store revenue', 70.22, '2023-06-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230620-022.
Created by Miltos Karabasilis (id: 2) at 2023-06-20 12:00:00
', 1),
('E-shop revenue', 108.93, '2023-06-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230621-893.
Created by Miltos Karabasilis (id: 2) at 2023-06-21 12:00:00
', 1),
('Physical store revenue', 66.77, '2023-06-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230621-677.
Created by Miltos Karabasilis (id: 2) at 2023-06-21 12:00:00
', 1),
('E-shop revenue', 112.41, '2023-06-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230622-241.
Created by Miltos Karabasilis (id: 2) at 2023-06-22 12:00:00
', 1),
('Physical store revenue', 68.89, '2023-06-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230622-889.
Created by Miltos Karabasilis (id: 2) at 2023-06-22 12:00:00
', 1),
('E-shop revenue', 115.88, '2023-06-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230623-588.
Created by Miltos Karabasilis (id: 2) at 2023-06-23 12:00:00
', 1),
('Physical store revenue', 71.02, '2023-06-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230623-102.
Created by Miltos Karabasilis (id: 2) at 2023-06-23 12:00:00
', 1),
('E-shop revenue', 147.25, '2023-06-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230624-725.
Created by Miltos Karabasilis (id: 2) at 2023-06-24 12:00:00
', 1),
('Physical store revenue', 90.25, '2023-06-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230624-025.
Created by Miltos Karabasilis (id: 2) at 2023-06-24 12:00:00
', 1),
('E-shop revenue', 150.72, '2023-06-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230625-072.
Created by Miltos Karabasilis (id: 2) at 2023-06-25 12:00:00
', 1),
('Physical store revenue', 92.38, '2023-06-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230625-238.
Created by Miltos Karabasilis (id: 2) at 2023-06-25 12:00:00
', 1),
('E-shop revenue', 138.69, '2023-06-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230626-869.
Created by Miltos Karabasilis (id: 2) at 2023-06-26 12:00:00
', 1),
('Physical store revenue', 85.01, '2023-06-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230626-501.
Created by Miltos Karabasilis (id: 2) at 2023-06-26 12:00:00
', 1),
('E-shop revenue', 129.77, '2023-06-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230627-977.
Created by Miltos Karabasilis (id: 2) at 2023-06-27 12:00:00
', 1),
('Physical store revenue', 79.53, '2023-06-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230627-953.
Created by Miltos Karabasilis (id: 2) at 2023-06-27 12:00:00
', 1),
('E-shop revenue', 124.12, '2023-06-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230628-412.
Created by Miltos Karabasilis (id: 2) at 2023-06-28 12:00:00
', 1),
('Physical store revenue', 76.08, '2023-06-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230628-608.
Created by Miltos Karabasilis (id: 2) at 2023-06-28 12:00:00
', 1),
('E-shop revenue', 127.60, '2023-06-29', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230629-760.
Created by Miltos Karabasilis (id: 2) at 2023-06-29 12:00:00
', 1),
('Physical store revenue', 78.20, '2023-06-29', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230629-820.
Created by Miltos Karabasilis (id: 2) at 2023-06-29 12:00:00
', 1),
('E-shop revenue', 131.07, '2023-06-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230630-107.
Created by Miltos Karabasilis (id: 2) at 2023-06-30 12:00:00
', 1),
('Physical store revenue', 80.33, '2023-06-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230630-033.
Created by Miltos Karabasilis (id: 2) at 2023-06-30 12:00:00
', 1),
('E-shop revenue', 160.58, '2023-07-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230701-058.
Created by Miltos Karabasilis (id: 2) at 2023-07-01 12:00:00
', 1),
('Physical store revenue', 98.42, '2023-07-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230701-842.
Created by Miltos Karabasilis (id: 2) at 2023-07-01 12:00:00
', 1),
('E-shop revenue', 164.05, '2023-07-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230702-405.
Created by Miltos Karabasilis (id: 2) at 2023-07-02 12:00:00
', 1),
('Physical store revenue', 100.55, '2023-07-02', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230702-055.
Created by Miltos Karabasilis (id: 2) at 2023-07-02 12:00:00
', 1),
('E-shop revenue', 152.02, '2023-07-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230703-202.
Created by Miltos Karabasilis (id: 2) at 2023-07-03 12:00:00
', 1),
('Physical store revenue', 93.18, '2023-07-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230703-318.
Created by Miltos Karabasilis (id: 2) at 2023-07-03 12:00:00
', 1),
('E-shop revenue', 143.10, '2023-07-04', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230704-310.
Created by Miltos Karabasilis (id: 2) at 2023-07-04 12:00:00
', 1),
('Physical store revenue', 87.70, '2023-07-04', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230704-770.
Created by Miltos Karabasilis (id: 2) at 2023-07-04 12:00:00
', 1),
('E-shop revenue', 146.57, '2023-07-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230705-657.
Created by Miltos Karabasilis (id: 2) at 2023-07-05 12:00:00
', 1),
('Physical store revenue', 89.83, '2023-07-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230705-983.
Created by Miltos Karabasilis (id: 2) at 2023-07-05 12:00:00
', 1),
('E-shop revenue', 150.04, '2023-07-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230706-004.
Created by Miltos Karabasilis (id: 2) at 2023-07-06 12:00:00
', 1),
('Physical store revenue', 91.96, '2023-07-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230706-196.
Created by Miltos Karabasilis (id: 2) at 2023-07-06 12:00:00
', 1),
('E-shop revenue', 107.51, '2023-07-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230707-751.
Created by Miltos Karabasilis (id: 2) at 2023-07-07 12:00:00
', 1),
('Physical store revenue', 65.89, '2023-07-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230707-589.
Created by Miltos Karabasilis (id: 2) at 2023-07-07 12:00:00
', 1),
('E-shop revenue', 138.88, '2023-07-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230708-888.
Created by Miltos Karabasilis (id: 2) at 2023-07-08 12:00:00
', 1),
('Physical store revenue', 85.12, '2023-07-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230708-512.
Created by Miltos Karabasilis (id: 2) at 2023-07-08 12:00:00
', 1),
('E-shop revenue', 142.35, '2023-07-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230709-235.
Created by Miltos Karabasilis (id: 2) at 2023-07-09 12:00:00
', 1),
('Physical store revenue', 87.25, '2023-07-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230709-725.
Created by Miltos Karabasilis (id: 2) at 2023-07-09 12:00:00
', 1),
('E-shop revenue', 130.32, '2023-07-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230710-032.
Created by Miltos Karabasilis (id: 2) at 2023-07-10 12:00:00
', 1),
('Physical store revenue', 79.88, '2023-07-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230710-988.
Created by Miltos Karabasilis (id: 2) at 2023-07-10 12:00:00
', 1),
('E-shop revenue', 121.40, '2023-07-11', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230711-140.
Created by Miltos Karabasilis (id: 2) at 2023-07-11 12:00:00
', 1),
('Physical store revenue', 74.40, '2023-07-11', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230711-440.
Created by Miltos Karabasilis (id: 2) at 2023-07-11 12:00:00
', 1),
('E-shop revenue', 124.87, '2023-07-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230712-487.
Created by Miltos Karabasilis (id: 2) at 2023-07-12 12:00:00
', 1),
('Physical store revenue', 76.53, '2023-07-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230712-653.
Created by Miltos Karabasilis (id: 2) at 2023-07-12 12:00:00
', 1),
('E-shop revenue', 128.34, '2023-07-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230713-834.
Created by Miltos Karabasilis (id: 2) at 2023-07-13 12:00:00
', 1),
('Physical store revenue', 78.66, '2023-07-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230713-866.
Created by Miltos Karabasilis (id: 2) at 2023-07-13 12:00:00
', 1),
('E-shop revenue', 122.70, '2023-07-14', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230714-270.
Created by Miltos Karabasilis (id: 2) at 2023-07-14 12:00:00
', 1),
('Physical store revenue', 75.20, '2023-07-14', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230714-520.
Created by Miltos Karabasilis (id: 2) at 2023-07-14 12:00:00
', 1),
('E-shop revenue', 154.07, '2023-07-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230715-407.
Created by Miltos Karabasilis (id: 2) at 2023-07-15 12:00:00
', 1),
('Physical store revenue', 94.43, '2023-07-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230715-443.
Created by Miltos Karabasilis (id: 2) at 2023-07-15 12:00:00
', 1),
('E-shop revenue', 157.54, '2023-07-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230716-754.
Created by Miltos Karabasilis (id: 2) at 2023-07-16 12:00:00
', 1),
('Physical store revenue', 96.56, '2023-07-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230716-656.
Created by Miltos Karabasilis (id: 2) at 2023-07-16 12:00:00
', 1),
('E-shop revenue', 145.51, '2023-07-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230717-551.
Created by Miltos Karabasilis (id: 2) at 2023-07-17 12:00:00
', 1),
('Physical store revenue', 89.19, '2023-07-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230717-919.
Created by Miltos Karabasilis (id: 2) at 2023-07-17 12:00:00
', 1),
('E-shop revenue', 136.59, '2023-07-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230718-659.
Created by Miltos Karabasilis (id: 2) at 2023-07-18 12:00:00
', 1),
('Physical store revenue', 83.71, '2023-07-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230718-371.
Created by Miltos Karabasilis (id: 2) at 2023-07-18 12:00:00
', 1),
('E-shop revenue', 140.06, '2023-07-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230719-006.
Created by Miltos Karabasilis (id: 2) at 2023-07-19 12:00:00
', 1),
('Physical store revenue', 85.84, '2023-07-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230719-584.
Created by Miltos Karabasilis (id: 2) at 2023-07-19 12:00:00
', 1),
('E-shop revenue', 143.53, '2023-07-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230720-353.
Created by Miltos Karabasilis (id: 2) at 2023-07-20 12:00:00
', 1),
('Physical store revenue', 87.97, '2023-07-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230720-797.
Created by Miltos Karabasilis (id: 2) at 2023-07-20 12:00:00
', 1),
('E-shop revenue', 137.89, '2023-07-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230721-789.
Created by Miltos Karabasilis (id: 2) at 2023-07-21 12:00:00
', 1),
('Physical store revenue', 84.51, '2023-07-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230721-451.
Created by Miltos Karabasilis (id: 2) at 2023-07-21 12:00:00
', 1),
('E-shop revenue', 169.26, '2023-07-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230722-926.
Created by Miltos Karabasilis (id: 2) at 2023-07-22 12:00:00
', 1),
('Physical store revenue', 103.74, '2023-07-22', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230722-374.
Created by Miltos Karabasilis (id: 2) at 2023-07-22 12:00:00
', 1),
('E-shop revenue', 172.73, '2023-07-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230723-273.
Created by Miltos Karabasilis (id: 2) at 2023-07-23 12:00:00
', 1),
('Physical store revenue', 105.87, '2023-07-23', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230723-587.
Created by Miltos Karabasilis (id: 2) at 2023-07-23 12:00:00
', 1),
('E-shop revenue', 123.81, '2023-07-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230724-381.
Created by Miltos Karabasilis (id: 2) at 2023-07-24 12:00:00
', 1),
('Physical store revenue', 75.89, '2023-07-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230724-589.
Created by Miltos Karabasilis (id: 2) at 2023-07-24 12:00:00
', 1),
('E-shop revenue', 114.89, '2023-07-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230725-489.
Created by Miltos Karabasilis (id: 2) at 2023-07-25 12:00:00
', 1),
('Physical store revenue', 70.41, '2023-07-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230725-041.
Created by Miltos Karabasilis (id: 2) at 2023-07-25 12:00:00
', 1),
('E-shop revenue', 118.36, '2023-07-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230726-836.
Created by Miltos Karabasilis (id: 2) at 2023-07-26 12:00:00
', 1),
('Physical store revenue', 72.54, '2023-07-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230726-254.
Created by Miltos Karabasilis (id: 2) at 2023-07-26 12:00:00
', 1),
('E-shop revenue', 121.83, '2023-07-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230727-183.
Created by Miltos Karabasilis (id: 2) at 2023-07-27 12:00:00
', 1),
('Physical store revenue', 74.67, '2023-07-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230727-467.
Created by Miltos Karabasilis (id: 2) at 2023-07-27 12:00:00
', 1),
('E-shop revenue', 116.19, '2023-07-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230728-619.
Created by Miltos Karabasilis (id: 2) at 2023-07-28 12:00:00
', 1),
('Physical store revenue', 71.21, '2023-07-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230728-121.
Created by Miltos Karabasilis (id: 2) at 2023-07-28 12:00:00
', 1),
('E-shop revenue', 147.56, '2023-07-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230729-756.
Created by Miltos Karabasilis (id: 2) at 2023-07-29 12:00:00
', 1),
('Physical store revenue', 90.44, '2023-07-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230729-044.
Created by Miltos Karabasilis (id: 2) at 2023-07-29 12:00:00
', 1),
('E-shop revenue', 151.03, '2023-07-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230730-103.
Created by Miltos Karabasilis (id: 2) at 2023-07-30 12:00:00
', 1),
('Physical store revenue', 92.57, '2023-07-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230730-257.
Created by Miltos Karabasilis (id: 2) at 2023-07-30 12:00:00
', 1),
('E-shop revenue', 139.00, '2023-07-31', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20230731-900.
Created by Miltos Karabasilis (id: 2) at 2023-07-31 12:00:00
', 1),
('Physical store revenue', 85.20, '2023-07-31', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230731-520.
Created by Miltos Karabasilis (id: 2) at 2023-07-31 12:00:00
', 1),
('E-shop revenue', 126.91, '2023-08-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230801-691.
Created by Miltos Karabasilis (id: 2) at 2023-08-01 12:00:00
', 1),
('Physical store revenue', 77.79, '2023-08-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230801-779.
Created by Miltos Karabasilis (id: 2) at 2023-08-01 12:00:00
', 1),
('E-shop revenue', 130.39, '2023-08-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230802-039.
Created by Miltos Karabasilis (id: 2) at 2023-08-02 12:00:00
', 1),
('Physical store revenue', 79.91, '2023-08-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230802-991.
Created by Miltos Karabasilis (id: 2) at 2023-08-02 12:00:00
', 1),
('E-shop revenue', 133.86, '2023-08-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230803-386.
Created by Miltos Karabasilis (id: 2) at 2023-08-03 12:00:00
', 1),
('Physical store revenue', 82.04, '2023-08-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230803-204.
Created by Miltos Karabasilis (id: 2) at 2023-08-03 12:00:00
', 1),
('E-shop revenue', 137.33, '2023-08-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230804-733.
Created by Miltos Karabasilis (id: 2) at 2023-08-04 12:00:00
', 1),
('Physical store revenue', 84.17, '2023-08-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230804-417.
Created by Miltos Karabasilis (id: 2) at 2023-08-04 12:00:00
', 1),
('E-shop revenue', 168.70, '2023-08-05', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20230805-870.
Created by Miltos Karabasilis (id: 2) at 2023-08-05 12:00:00
', 1),
('Physical store revenue', 103.40, '2023-08-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230805-340.
Created by Miltos Karabasilis (id: 2) at 2023-08-05 12:00:00
', 1),
('E-shop revenue', 172.17, '2023-08-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230806-217.
Created by Miltos Karabasilis (id: 2) at 2023-08-06 12:00:00
', 1),
('Physical store revenue', 105.53, '2023-08-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230806-553.
Created by Miltos Karabasilis (id: 2) at 2023-08-06 12:00:00
', 1),
('E-shop revenue', 151.03, '2023-08-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230807-103.
Created by Miltos Karabasilis (id: 2) at 2023-08-07 12:00:00
', 1),
('Physical store revenue', 92.57, '2023-08-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230807-257.
Created by Miltos Karabasilis (id: 2) at 2023-08-07 12:00:00
', 1),
('E-shop revenue', 142.10, '2023-08-08', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230808-210.
Created by Miltos Karabasilis (id: 2) at 2023-08-08 12:00:00
', 1),
('Physical store revenue', 87.10, '2023-08-08', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230808-710.
Created by Miltos Karabasilis (id: 2) at 2023-08-08 12:00:00
', 1),
('E-shop revenue', 145.58, '2023-08-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230809-558.
Created by Miltos Karabasilis (id: 2) at 2023-08-09 12:00:00
', 1),
('Physical store revenue', 89.22, '2023-08-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230809-922.
Created by Miltos Karabasilis (id: 2) at 2023-08-09 12:00:00
', 1),
('E-shop revenue', 112.16, '2023-08-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230810-216.
Created by Miltos Karabasilis (id: 2) at 2023-08-10 12:00:00
', 1),
('Physical store revenue', 68.74, '2023-08-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230810-874.
Created by Miltos Karabasilis (id: 2) at 2023-08-10 12:00:00
', 1),
('E-shop revenue', 115.63, '2023-08-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230811-563.
Created by Miltos Karabasilis (id: 2) at 2023-08-11 12:00:00
', 1),
('Physical store revenue', 70.87, '2023-08-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230811-087.
Created by Miltos Karabasilis (id: 2) at 2023-08-11 12:00:00
', 1),
('E-shop revenue', 147.00, '2023-08-12', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Weekend order batch reference WEB-20230812-700.
Created by Miltos Karabasilis (id: 2) at 2023-08-12 12:00:00
', 1),
('Physical store revenue', 90.10, '2023-08-12', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230812-010.
Created by Miltos Karabasilis (id: 2) at 2023-08-12 12:00:00
', 1),
('E-shop revenue', 150.47, '2023-08-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230813-047.
Created by Miltos Karabasilis (id: 2) at 2023-08-13 12:00:00
', 1),
('Physical store revenue', 92.23, '2023-08-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230813-223.
Created by Miltos Karabasilis (id: 2) at 2023-08-13 12:00:00
', 1),
('E-shop revenue', 129.33, '2023-08-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230814-933.
Created by Miltos Karabasilis (id: 2) at 2023-08-14 12:00:00
', 1),
('Physical store revenue', 79.27, '2023-08-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230814-927.
Created by Miltos Karabasilis (id: 2) at 2023-08-14 12:00:00
', 1),
('E-shop revenue', 120.40, '2023-08-15', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20230815-040.
Created by Miltos Karabasilis (id: 2) at 2023-08-15 12:00:00
', 1),
('Physical store revenue', 73.80, '2023-08-15', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230815-380.
Created by Miltos Karabasilis (id: 2) at 2023-08-15 12:00:00
', 1),
('E-shop revenue', 123.88, '2023-08-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230816-388.
Created by Miltos Karabasilis (id: 2) at 2023-08-16 12:00:00
', 1),
('Physical store revenue', 75.92, '2023-08-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230816-592.
Created by Miltos Karabasilis (id: 2) at 2023-08-16 12:00:00
', 1),
('E-shop revenue', 127.35, '2023-08-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230817-735.
Created by Miltos Karabasilis (id: 2) at 2023-08-17 12:00:00
', 1),
('Physical store revenue', 78.05, '2023-08-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230817-805.
Created by Miltos Karabasilis (id: 2) at 2023-08-17 12:00:00
', 1),
('E-shop revenue', 130.82, '2023-08-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230818-082.
Created by Miltos Karabasilis (id: 2) at 2023-08-18 12:00:00
', 1),
('Physical store revenue', 80.18, '2023-08-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230818-018.
Created by Miltos Karabasilis (id: 2) at 2023-08-18 12:00:00
', 1),
('E-shop revenue', 162.19, '2023-08-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230819-219.
Created by Miltos Karabasilis (id: 2) at 2023-08-19 12:00:00
', 1),
('Physical store revenue', 99.41, '2023-08-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230819-941.
Created by Miltos Karabasilis (id: 2) at 2023-08-19 12:00:00
', 1),
('E-shop revenue', 165.66, '2023-08-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230820-566.
Created by Miltos Karabasilis (id: 2) at 2023-08-20 12:00:00
', 1),
('Physical store revenue', 101.54, '2023-08-20', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230820-154.
Created by Miltos Karabasilis (id: 2) at 2023-08-20 12:00:00
', 1),
('E-shop revenue', 144.52, '2023-08-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230821-452.
Created by Miltos Karabasilis (id: 2) at 2023-08-21 12:00:00
', 1),
('Physical store revenue', 88.58, '2023-08-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230821-858.
Created by Miltos Karabasilis (id: 2) at 2023-08-21 12:00:00
', 1),
('E-shop revenue', 135.59, '2023-08-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230822-559.
Created by Miltos Karabasilis (id: 2) at 2023-08-22 12:00:00
', 1),
('Physical store revenue', 83.11, '2023-08-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230822-311.
Created by Miltos Karabasilis (id: 2) at 2023-08-22 12:00:00
', 1),
('E-shop revenue', 139.07, '2023-08-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230823-907.
Created by Miltos Karabasilis (id: 2) at 2023-08-23 12:00:00
', 1),
('Physical store revenue', 85.23, '2023-08-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230823-523.
Created by Miltos Karabasilis (id: 2) at 2023-08-23 12:00:00
', 1),
('E-shop revenue', 142.54, '2023-08-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230824-254.
Created by Miltos Karabasilis (id: 2) at 2023-08-24 12:00:00
', 1),
('Physical store revenue', 87.36, '2023-08-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230824-736.
Created by Miltos Karabasilis (id: 2) at 2023-08-24 12:00:00
', 1),
('E-shop revenue', 146.01, '2023-08-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230825-601.
Created by Miltos Karabasilis (id: 2) at 2023-08-25 12:00:00
', 1),
('Physical store revenue', 89.49, '2023-08-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230825-949.
Created by Miltos Karabasilis (id: 2) at 2023-08-25 12:00:00
', 1),
('E-shop revenue', 177.38, '2023-08-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230826-738.
Created by Miltos Karabasilis (id: 2) at 2023-08-26 12:00:00
', 1),
('Physical store revenue', 108.72, '2023-08-26', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230826-872.
Created by Miltos Karabasilis (id: 2) at 2023-08-26 12:00:00
', 1),
('E-shop revenue', 143.96, '2023-08-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230827-396.
Created by Miltos Karabasilis (id: 2) at 2023-08-27 12:00:00
', 1),
('Physical store revenue', 88.24, '2023-08-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230827-824.
Created by Miltos Karabasilis (id: 2) at 2023-08-27 12:00:00
', 1),
('E-shop revenue', 122.82, '2023-08-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230828-282.
Created by Miltos Karabasilis (id: 2) at 2023-08-28 12:00:00
', 1),
('Physical store revenue', 75.28, '2023-08-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230828-528.
Created by Miltos Karabasilis (id: 2) at 2023-08-28 12:00:00
', 1),
('E-shop revenue', 113.89, '2023-08-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230829-389.
Created by Miltos Karabasilis (id: 2) at 2023-08-29 12:00:00
', 1),
('Physical store revenue', 69.81, '2023-08-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230829-981.
Created by Miltos Karabasilis (id: 2) at 2023-08-29 12:00:00
', 1),
('E-shop revenue', 117.37, '2023-08-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230830-737.
Created by Miltos Karabasilis (id: 2) at 2023-08-30 12:00:00
', 1),
('Physical store revenue', 71.93, '2023-08-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230830-193.
Created by Miltos Karabasilis (id: 2) at 2023-08-30 12:00:00
', 1),
('E-shop revenue', 120.84, '2023-08-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230831-084.
Created by Miltos Karabasilis (id: 2) at 2023-08-31 12:00:00
', 1),
('Physical store revenue', 74.06, '2023-08-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230831-406.
Created by Miltos Karabasilis (id: 2) at 2023-08-31 12:00:00
', 1),
('E-shop revenue', 121.15, '2023-09-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230901-115.
Created by Miltos Karabasilis (id: 2) at 2023-09-01 12:00:00
', 1),
('Physical store revenue', 74.25, '2023-09-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230901-425.
Created by Miltos Karabasilis (id: 2) at 2023-09-01 12:00:00
', 1),
('E-shop revenue', 152.52, '2023-09-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230902-252.
Created by Miltos Karabasilis (id: 2) at 2023-09-02 12:00:00
', 1),
('Physical store revenue', 93.48, '2023-09-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230902-348.
Created by Miltos Karabasilis (id: 2) at 2023-09-02 12:00:00
', 1),
('E-shop revenue', 155.99, '2023-09-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230903-599.
Created by Miltos Karabasilis (id: 2) at 2023-09-03 12:00:00
', 1),
('Physical store revenue', 95.61, '2023-09-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230903-561.
Created by Miltos Karabasilis (id: 2) at 2023-09-03 12:00:00
', 1),
('E-shop revenue', 143.96, '2023-09-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230904-396.
Created by Miltos Karabasilis (id: 2) at 2023-09-04 12:00:00
', 1),
('Physical store revenue', 88.24, '2023-09-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230904-824.
Created by Miltos Karabasilis (id: 2) at 2023-09-04 12:00:00
', 1),
('E-shop revenue', 135.04, '2023-09-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230905-504.
Created by Miltos Karabasilis (id: 2) at 2023-09-05 12:00:00
', 1),
('Physical store revenue', 82.76, '2023-09-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230905-276.
Created by Miltos Karabasilis (id: 2) at 2023-09-05 12:00:00
', 1),
('E-shop revenue', 138.51, '2023-09-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230906-851.
Created by Miltos Karabasilis (id: 2) at 2023-09-06 12:00:00
', 1),
('Physical store revenue', 84.89, '2023-09-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230906-489.
Created by Miltos Karabasilis (id: 2) at 2023-09-06 12:00:00
', 1),
('E-shop revenue', 132.87, '2023-09-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230907-287.
Created by Miltos Karabasilis (id: 2) at 2023-09-07 12:00:00
', 1),
('Physical store revenue', 81.43, '2023-09-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230907-143.
Created by Miltos Karabasilis (id: 2) at 2023-09-07 12:00:00
', 1),
('E-shop revenue', 136.34, '2023-09-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230908-634.
Created by Miltos Karabasilis (id: 2) at 2023-09-08 12:00:00
', 1),
('Physical store revenue', 83.56, '2023-09-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230908-356.
Created by Miltos Karabasilis (id: 2) at 2023-09-08 12:00:00
', 1),
('E-shop revenue', 167.71, '2023-09-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230909-771.
Created by Miltos Karabasilis (id: 2) at 2023-09-09 12:00:00
', 1),
('Physical store revenue', 102.79, '2023-09-09', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230909-279.
Created by Miltos Karabasilis (id: 2) at 2023-09-09 12:00:00
', 1),
('E-shop revenue', 171.18, '2023-09-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230910-118.
Created by Miltos Karabasilis (id: 2) at 2023-09-10 12:00:00
', 1),
('Physical store revenue', 104.92, '2023-09-10', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230910-492.
Created by Miltos Karabasilis (id: 2) at 2023-09-10 12:00:00
', 1),
('E-shop revenue', 159.15, '2023-09-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230911-915.
Created by Miltos Karabasilis (id: 2) at 2023-09-11 12:00:00
', 1),
('Physical store revenue', 97.55, '2023-09-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230911-755.
Created by Miltos Karabasilis (id: 2) at 2023-09-11 12:00:00
', 1),
('E-shop revenue', 150.23, '2023-09-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230912-023.
Created by Miltos Karabasilis (id: 2) at 2023-09-12 12:00:00
', 1),
('Physical store revenue', 92.07, '2023-09-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230912-207.
Created by Miltos Karabasilis (id: 2) at 2023-09-12 12:00:00
', 1),
('E-shop revenue', 116.81, '2023-09-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230913-681.
Created by Miltos Karabasilis (id: 2) at 2023-09-13 12:00:00
', 1),
('Physical store revenue', 71.59, '2023-09-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230913-159.
Created by Miltos Karabasilis (id: 2) at 2023-09-13 12:00:00
', 1),
('E-shop revenue', 111.17, '2023-09-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230914-117.
Created by Miltos Karabasilis (id: 2) at 2023-09-14 12:00:00
', 1),
('Physical store revenue', 68.13, '2023-09-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230914-813.
Created by Miltos Karabasilis (id: 2) at 2023-09-14 12:00:00
', 1),
('E-shop revenue', 114.64, '2023-09-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230915-464.
Created by Miltos Karabasilis (id: 2) at 2023-09-15 12:00:00
', 1),
('Physical store revenue', 70.26, '2023-09-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230915-026.
Created by Miltos Karabasilis (id: 2) at 2023-09-15 12:00:00
', 1),
('E-shop revenue', 146.01, '2023-09-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230916-601.
Created by Miltos Karabasilis (id: 2) at 2023-09-16 12:00:00
', 1),
('Physical store revenue', 89.49, '2023-09-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230916-949.
Created by Miltos Karabasilis (id: 2) at 2023-09-16 12:00:00
', 1),
('E-shop revenue', 149.48, '2023-09-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230917-948.
Created by Miltos Karabasilis (id: 2) at 2023-09-17 12:00:00
', 1),
('Physical store revenue', 91.62, '2023-09-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230917-162.
Created by Miltos Karabasilis (id: 2) at 2023-09-17 12:00:00
', 1),
('E-shop revenue', 137.45, '2023-09-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230918-745.
Created by Miltos Karabasilis (id: 2) at 2023-09-18 12:00:00
', 1),
('Physical store revenue', 84.25, '2023-09-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230918-425.
Created by Miltos Karabasilis (id: 2) at 2023-09-18 12:00:00
', 1),
('E-shop revenue', 128.53, '2023-09-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230919-853.
Created by Miltos Karabasilis (id: 2) at 2023-09-19 12:00:00
', 1),
('Physical store revenue', 78.77, '2023-09-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230919-877.
Created by Miltos Karabasilis (id: 2) at 2023-09-19 12:00:00
', 1),
('E-shop revenue', 132.00, '2023-09-20', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20230920-200.
Created by Miltos Karabasilis (id: 2) at 2023-09-20 12:00:00
', 1),
('Physical store revenue', 80.90, '2023-09-20', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230920-090.
Created by Miltos Karabasilis (id: 2) at 2023-09-20 12:00:00
', 1),
('E-shop revenue', 126.36, '2023-09-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230921-636.
Created by Miltos Karabasilis (id: 2) at 2023-09-21 12:00:00
', 1),
('Physical store revenue', 77.44, '2023-09-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230921-744.
Created by Miltos Karabasilis (id: 2) at 2023-09-21 12:00:00
', 1),
('E-shop revenue', 129.83, '2023-09-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230922-983.
Created by Miltos Karabasilis (id: 2) at 2023-09-22 12:00:00
', 1),
('Physical store revenue', 79.57, '2023-09-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230922-957.
Created by Miltos Karabasilis (id: 2) at 2023-09-22 12:00:00
', 1),
('E-shop revenue', 161.20, '2023-09-23', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20230923-120.
Created by Miltos Karabasilis (id: 2) at 2023-09-23 12:00:00
', 1),
('Physical store revenue', 98.80, '2023-09-23', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230923-880.
Created by Miltos Karabasilis (id: 2) at 2023-09-23 12:00:00
', 1),
('E-shop revenue', 164.67, '2023-09-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20230924-467.
Created by Miltos Karabasilis (id: 2) at 2023-09-24 12:00:00
', 1),
('Physical store revenue', 100.93, '2023-09-24', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20230924-093.
Created by Miltos Karabasilis (id: 2) at 2023-09-24 12:00:00
', 1),
('E-shop revenue', 152.64, '2023-09-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230925-264.
Created by Miltos Karabasilis (id: 2) at 2023-09-25 12:00:00
', 1),
('Physical store revenue', 93.56, '2023-09-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230925-356.
Created by Miltos Karabasilis (id: 2) at 2023-09-25 12:00:00
', 1),
('E-shop revenue', 143.72, '2023-09-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230926-372.
Created by Miltos Karabasilis (id: 2) at 2023-09-26 12:00:00
', 1),
('Physical store revenue', 88.08, '2023-09-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230926-808.
Created by Miltos Karabasilis (id: 2) at 2023-09-26 12:00:00
', 1),
('E-shop revenue', 147.19, '2023-09-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230927-719.
Created by Miltos Karabasilis (id: 2) at 2023-09-27 12:00:00
', 1),
('Physical store revenue', 90.21, '2023-09-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230927-021.
Created by Miltos Karabasilis (id: 2) at 2023-09-27 12:00:00
', 1),
('E-shop revenue', 141.55, '2023-09-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230928-155.
Created by Miltos Karabasilis (id: 2) at 2023-09-28 12:00:00
', 1),
('Physical store revenue', 86.75, '2023-09-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230928-675.
Created by Miltos Karabasilis (id: 2) at 2023-09-28 12:00:00
', 1),
('E-shop revenue', 145.02, '2023-09-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20230929-502.
Created by Miltos Karabasilis (id: 2) at 2023-09-29 12:00:00
', 1),
('Physical store revenue', 88.88, '2023-09-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20230929-888.
Created by Miltos Karabasilis (id: 2) at 2023-09-29 12:00:00
', 1),
('E-shop revenue', 139.50, '2023-09-30', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20230930-950.
Created by Miltos Karabasilis (id: 2) at 2023-09-30 12:00:00
', 1),
('Physical store revenue', 85.50, '2023-09-30', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20230930-550.
Created by Miltos Karabasilis (id: 2) at 2023-09-30 12:00:00
', 1),
('E-shop revenue', 141.11, '2023-10-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231001-111.
Created by Miltos Karabasilis (id: 2) at 2023-10-01 12:00:00
', 1),
('Physical store revenue', 86.49, '2023-10-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231001-649.
Created by Miltos Karabasilis (id: 2) at 2023-10-01 12:00:00
', 1),
('E-shop revenue', 129.08, '2023-10-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231002-908.
Created by Miltos Karabasilis (id: 2) at 2023-10-02 12:00:00
', 1),
('Physical store revenue', 79.12, '2023-10-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231002-912.
Created by Miltos Karabasilis (id: 2) at 2023-10-02 12:00:00
', 1),
('E-shop revenue', 120.16, '2023-10-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231003-016.
Created by Miltos Karabasilis (id: 2) at 2023-10-03 12:00:00
', 1),
('Physical store revenue', 73.64, '2023-10-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231003-364.
Created by Miltos Karabasilis (id: 2) at 2023-10-03 12:00:00
', 1),
('E-shop revenue', 123.63, '2023-10-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231004-363.
Created by Miltos Karabasilis (id: 2) at 2023-10-04 12:00:00
', 1),
('Physical store revenue', 75.77, '2023-10-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231004-577.
Created by Miltos Karabasilis (id: 2) at 2023-10-04 12:00:00
', 1),
('E-shop revenue', 127.10, '2023-10-05', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20231005-710.
Created by Miltos Karabasilis (id: 2) at 2023-10-05 12:00:00
', 1),
('Physical store revenue', 77.90, '2023-10-05', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20231005-790.
Created by Miltos Karabasilis (id: 2) at 2023-10-05 12:00:00
', 1),
('E-shop revenue', 130.57, '2023-10-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231006-057.
Created by Miltos Karabasilis (id: 2) at 2023-10-06 12:00:00
', 1),
('Physical store revenue', 80.03, '2023-10-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231006-003.
Created by Miltos Karabasilis (id: 2) at 2023-10-06 12:00:00
', 1),
('E-shop revenue', 152.83, '2023-10-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231007-283.
Created by Miltos Karabasilis (id: 2) at 2023-10-07 12:00:00
', 1),
('Physical store revenue', 93.67, '2023-10-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231007-367.
Created by Miltos Karabasilis (id: 2) at 2023-10-07 12:00:00
', 1),
('E-shop revenue', 156.30, '2023-10-08', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20231008-630.
Created by Miltos Karabasilis (id: 2) at 2023-10-08 12:00:00
', 1),
('Physical store revenue', 95.80, '2023-10-08', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20231008-580.
Created by Miltos Karabasilis (id: 2) at 2023-10-08 12:00:00
', 1),
('E-shop revenue', 144.27, '2023-10-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231009-427.
Created by Miltos Karabasilis (id: 2) at 2023-10-09 12:00:00
', 1),
('Physical store revenue', 88.43, '2023-10-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231009-843.
Created by Miltos Karabasilis (id: 2) at 2023-10-09 12:00:00
', 1),
('E-shop revenue', 135.35, '2023-10-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231010-535.
Created by Miltos Karabasilis (id: 2) at 2023-10-10 12:00:00
', 1),
('Physical store revenue', 82.95, '2023-10-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231010-295.
Created by Miltos Karabasilis (id: 2) at 2023-10-10 12:00:00
', 1),
('E-shop revenue', 138.82, '2023-10-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231011-882.
Created by Miltos Karabasilis (id: 2) at 2023-10-11 12:00:00
', 1),
('Physical store revenue', 85.08, '2023-10-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231011-508.
Created by Miltos Karabasilis (id: 2) at 2023-10-11 12:00:00
', 1),
('E-shop revenue', 142.29, '2023-10-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231012-229.
Created by Miltos Karabasilis (id: 2) at 2023-10-12 12:00:00
', 1),
('Physical store revenue', 87.21, '2023-10-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231012-721.
Created by Miltos Karabasilis (id: 2) at 2023-10-12 12:00:00
', 1),
('E-shop revenue', 145.76, '2023-10-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231013-576.
Created by Miltos Karabasilis (id: 2) at 2023-10-13 12:00:00
', 1),
('Physical store revenue', 89.34, '2023-10-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231013-934.
Created by Miltos Karabasilis (id: 2) at 2023-10-13 12:00:00
', 1),
('E-shop revenue', 168.02, '2023-10-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231014-802.
Created by Miltos Karabasilis (id: 2) at 2023-10-14 12:00:00
', 1),
('Physical store revenue', 102.98, '2023-10-14', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231014-298.
Created by Miltos Karabasilis (id: 2) at 2023-10-14 12:00:00
', 1),
('E-shop revenue', 171.49, '2023-10-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231015-149.
Created by Miltos Karabasilis (id: 2) at 2023-10-15 12:00:00
', 1),
('Physical store revenue', 105.11, '2023-10-15', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231015-511.
Created by Miltos Karabasilis (id: 2) at 2023-10-15 12:00:00
', 1),
('E-shop revenue', 159.46, '2023-10-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231016-946.
Created by Miltos Karabasilis (id: 2) at 2023-10-16 12:00:00
', 1),
('Physical store revenue', 97.74, '2023-10-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231016-774.
Created by Miltos Karabasilis (id: 2) at 2023-10-16 12:00:00
', 1),
('E-shop revenue', 113.65, '2023-10-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231017-365.
Created by Miltos Karabasilis (id: 2) at 2023-10-17 12:00:00
', 1),
('Physical store revenue', 69.65, '2023-10-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231017-965.
Created by Miltos Karabasilis (id: 2) at 2023-10-17 12:00:00
', 1),
('E-shop revenue', 117.12, '2023-10-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231018-712.
Created by Miltos Karabasilis (id: 2) at 2023-10-18 12:00:00
', 1),
('Physical store revenue', 71.78, '2023-10-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231018-178.
Created by Miltos Karabasilis (id: 2) at 2023-10-18 12:00:00
', 1),
('E-shop revenue', 120.59, '2023-10-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231019-059.
Created by Miltos Karabasilis (id: 2) at 2023-10-19 12:00:00
', 1),
('Physical store revenue', 73.91, '2023-10-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231019-391.
Created by Miltos Karabasilis (id: 2) at 2023-10-19 12:00:00
', 1),
('E-shop revenue', 124.06, '2023-10-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231020-406.
Created by Miltos Karabasilis (id: 2) at 2023-10-20 12:00:00
', 1),
('Physical store revenue', 76.04, '2023-10-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231020-604.
Created by Miltos Karabasilis (id: 2) at 2023-10-20 12:00:00
', 1),
('E-shop revenue', 146.32, '2023-10-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231021-632.
Created by Miltos Karabasilis (id: 2) at 2023-10-21 12:00:00
', 1),
('Physical store revenue', 89.68, '2023-10-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231021-968.
Created by Miltos Karabasilis (id: 2) at 2023-10-21 12:00:00
', 1),
('E-shop revenue', 149.79, '2023-10-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231022-979.
Created by Miltos Karabasilis (id: 2) at 2023-10-22 12:00:00
', 1),
('Physical store revenue', 91.81, '2023-10-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231022-181.
Created by Miltos Karabasilis (id: 2) at 2023-10-22 12:00:00
', 1),
('E-shop revenue', 137.76, '2023-10-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231023-776.
Created by Miltos Karabasilis (id: 2) at 2023-10-23 12:00:00
', 1),
('Physical store revenue', 84.44, '2023-10-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231023-444.
Created by Miltos Karabasilis (id: 2) at 2023-10-23 12:00:00
', 1),
('E-shop revenue', 128.84, '2023-10-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231024-884.
Created by Miltos Karabasilis (id: 2) at 2023-10-24 12:00:00
', 1),
('Physical store revenue', 78.96, '2023-10-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231024-896.
Created by Miltos Karabasilis (id: 2) at 2023-10-24 12:00:00
', 1),
('E-shop revenue', 132.31, '2023-10-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231025-231.
Created by Miltos Karabasilis (id: 2) at 2023-10-25 12:00:00
', 1),
('Physical store revenue', 81.09, '2023-10-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231025-109.
Created by Miltos Karabasilis (id: 2) at 2023-10-25 12:00:00
', 1),
('E-shop revenue', 135.78, '2023-10-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231026-578.
Created by Miltos Karabasilis (id: 2) at 2023-10-26 12:00:00
', 1),
('Physical store revenue', 83.22, '2023-10-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231026-322.
Created by Miltos Karabasilis (id: 2) at 2023-10-26 12:00:00
', 1),
('E-shop revenue', 139.25, '2023-10-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231027-925.
Created by Miltos Karabasilis (id: 2) at 2023-10-27 12:00:00
', 1),
('Physical store revenue', 85.35, '2023-10-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231027-535.
Created by Miltos Karabasilis (id: 2) at 2023-10-27 12:00:00
', 1),
('E-shop revenue', 161.51, '2023-10-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231028-151.
Created by Miltos Karabasilis (id: 2) at 2023-10-28 12:00:00
', 1),
('Physical store revenue', 98.99, '2023-10-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231028-899.
Created by Miltos Karabasilis (id: 2) at 2023-10-28 12:00:00
', 1),
('E-shop revenue', 164.98, '2023-10-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231029-498.
Created by Miltos Karabasilis (id: 2) at 2023-10-29 12:00:00
', 1),
('Physical store revenue', 101.12, '2023-10-29', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231029-112.
Created by Miltos Karabasilis (id: 2) at 2023-10-29 12:00:00
', 1),
('E-shop revenue', 152.95, '2023-10-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231030-295.
Created by Miltos Karabasilis (id: 2) at 2023-10-30 12:00:00
', 1),
('Physical store revenue', 93.75, '2023-10-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231030-375.
Created by Miltos Karabasilis (id: 2) at 2023-10-30 12:00:00
', 1),
('E-shop revenue', 144.03, '2023-10-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231031-403.
Created by Miltos Karabasilis (id: 2) at 2023-10-31 12:00:00
', 1),
('Physical store revenue', 88.27, '2023-10-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231031-827.
Created by Miltos Karabasilis (id: 2) at 2023-10-31 12:00:00
', 1),
('E-shop revenue', 144.34, '2023-11-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231101-434.
Created by Miltos Karabasilis (id: 2) at 2023-11-01 12:00:00
', 1),
('Physical store revenue', 88.46, '2023-11-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231101-846.
Created by Miltos Karabasilis (id: 2) at 2023-11-01 12:00:00
', 1),
('E-shop revenue', 147.81, '2023-11-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231102-781.
Created by Miltos Karabasilis (id: 2) at 2023-11-02 12:00:00
', 1),
('Physical store revenue', 90.59, '2023-11-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231102-059.
Created by Miltos Karabasilis (id: 2) at 2023-11-02 12:00:00
', 1),
('E-shop revenue', 114.39, '2023-11-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231103-439.
Created by Miltos Karabasilis (id: 2) at 2023-11-03 12:00:00
', 1),
('Physical store revenue', 70.11, '2023-11-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231103-011.
Created by Miltos Karabasilis (id: 2) at 2023-11-03 12:00:00
', 1),
('E-shop revenue', 145.76, '2023-11-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231104-576.
Created by Miltos Karabasilis (id: 2) at 2023-11-04 12:00:00
', 1),
('Physical store revenue', 89.34, '2023-11-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231104-934.
Created by Miltos Karabasilis (id: 2) at 2023-11-04 12:00:00
', 1),
('E-shop revenue', 149.23, '2023-11-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231105-923.
Created by Miltos Karabasilis (id: 2) at 2023-11-05 12:00:00
', 1),
('Physical store revenue', 91.47, '2023-11-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231105-147.
Created by Miltos Karabasilis (id: 2) at 2023-11-05 12:00:00
', 1),
('E-shop revenue', 137.21, '2023-11-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231106-721.
Created by Miltos Karabasilis (id: 2) at 2023-11-06 12:00:00
', 1),
('Physical store revenue', 84.09, '2023-11-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231106-409.
Created by Miltos Karabasilis (id: 2) at 2023-11-06 12:00:00
', 1),
('E-shop revenue', 119.16, '2023-11-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231107-916.
Created by Miltos Karabasilis (id: 2) at 2023-11-07 12:00:00
', 1),
('Physical store revenue', 73.04, '2023-11-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231107-304.
Created by Miltos Karabasilis (id: 2) at 2023-11-07 12:00:00
', 1),
('E-shop revenue', 122.64, '2023-11-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231108-264.
Created by Miltos Karabasilis (id: 2) at 2023-11-08 12:00:00
', 1),
('Physical store revenue', 75.16, '2023-11-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231108-516.
Created by Miltos Karabasilis (id: 2) at 2023-11-08 12:00:00
', 1),
('E-shop revenue', 126.11, '2023-11-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231109-611.
Created by Miltos Karabasilis (id: 2) at 2023-11-09 12:00:00
', 1),
('Physical store revenue', 77.29, '2023-11-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231109-729.
Created by Miltos Karabasilis (id: 2) at 2023-11-09 12:00:00
', 1),
('E-shop revenue', 129.58, '2023-11-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231110-958.
Created by Miltos Karabasilis (id: 2) at 2023-11-10 12:00:00
', 1),
('Physical store revenue', 79.42, '2023-11-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231110-942.
Created by Miltos Karabasilis (id: 2) at 2023-11-10 12:00:00
', 1),
('E-shop revenue', 160.95, '2023-11-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231111-095.
Created by Miltos Karabasilis (id: 2) at 2023-11-11 12:00:00
', 1),
('Physical store revenue', 98.65, '2023-11-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231111-865.
Created by Miltos Karabasilis (id: 2) at 2023-11-11 12:00:00
', 1),
('E-shop revenue', 164.42, '2023-11-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231112-442.
Created by Miltos Karabasilis (id: 2) at 2023-11-12 12:00:00
', 1),
('Physical store revenue', 100.78, '2023-11-12', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231112-078.
Created by Miltos Karabasilis (id: 2) at 2023-11-12 12:00:00
', 1),
('E-shop revenue', 152.40, '2023-11-13', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20231113-240.
Created by Miltos Karabasilis (id: 2) at 2023-11-13 12:00:00
', 1),
('Physical store revenue', 93.40, '2023-11-13', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20231113-340.
Created by Miltos Karabasilis (id: 2) at 2023-11-13 12:00:00
', 1),
('E-shop revenue', 134.35, '2023-11-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231114-435.
Created by Miltos Karabasilis (id: 2) at 2023-11-14 12:00:00
', 1),
('Physical store revenue', 82.35, '2023-11-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231114-235.
Created by Miltos Karabasilis (id: 2) at 2023-11-14 12:00:00
', 1),
('E-shop revenue', 137.83, '2023-11-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231115-783.
Created by Miltos Karabasilis (id: 2) at 2023-11-15 12:00:00
', 1),
('Physical store revenue', 84.47, '2023-11-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231115-447.
Created by Miltos Karabasilis (id: 2) at 2023-11-15 12:00:00
', 1),
('E-shop revenue', 141.30, '2023-11-16', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20231116-130.
Created by Miltos Karabasilis (id: 2) at 2023-11-16 12:00:00
', 1),
('Physical store revenue', 86.60, '2023-11-16', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20231116-660.
Created by Miltos Karabasilis (id: 2) at 2023-11-16 12:00:00
', 1),
('E-shop revenue', 144.77, '2023-11-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231117-477.
Created by Miltos Karabasilis (id: 2) at 2023-11-17 12:00:00
', 1),
('Physical store revenue', 88.73, '2023-11-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231117-873.
Created by Miltos Karabasilis (id: 2) at 2023-11-17 12:00:00
', 1),
('E-shop revenue', 176.14, '2023-11-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231118-614.
Created by Miltos Karabasilis (id: 2) at 2023-11-18 12:00:00
', 1),
('Physical store revenue', 107.96, '2023-11-18', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231118-796.
Created by Miltos Karabasilis (id: 2) at 2023-11-18 12:00:00
', 1),
('E-shop revenue', 179.61, '2023-11-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231119-961.
Created by Miltos Karabasilis (id: 2) at 2023-11-19 12:00:00
', 1),
('Physical store revenue', 110.09, '2023-11-19', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231119-009.
Created by Miltos Karabasilis (id: 2) at 2023-11-19 12:00:00
', 1),
('E-shop revenue', 130.70, '2023-11-20', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20231120-070.
Created by Miltos Karabasilis (id: 2) at 2023-11-20 12:00:00
', 1),
('Physical store revenue', 80.10, '2023-11-20', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20231120-010.
Created by Miltos Karabasilis (id: 2) at 2023-11-20 12:00:00
', 1),
('E-shop revenue', 112.65, '2023-11-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231121-265.
Created by Miltos Karabasilis (id: 2) at 2023-11-21 12:00:00
', 1),
('Physical store revenue', 69.05, '2023-11-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231121-905.
Created by Miltos Karabasilis (id: 2) at 2023-11-21 12:00:00
', 1),
('E-shop revenue', 116.13, '2023-11-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231122-613.
Created by Miltos Karabasilis (id: 2) at 2023-11-22 12:00:00
', 1),
('Physical store revenue', 71.17, '2023-11-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231122-117.
Created by Miltos Karabasilis (id: 2) at 2023-11-22 12:00:00
', 1),
('E-shop revenue', 119.60, '2023-11-23', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20231123-960.
Created by Miltos Karabasilis (id: 2) at 2023-11-23 12:00:00
', 1),
('Physical store revenue', 73.30, '2023-11-23', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20231123-330.
Created by Miltos Karabasilis (id: 2) at 2023-11-23 12:00:00
', 1),
('E-shop revenue', 123.07, '2023-11-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231124-307.
Created by Miltos Karabasilis (id: 2) at 2023-11-24 12:00:00
', 1),
('Physical store revenue', 75.43, '2023-11-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231124-543.
Created by Miltos Karabasilis (id: 2) at 2023-11-24 12:00:00
', 1),
('E-shop revenue', 154.44, '2023-11-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231125-444.
Created by Miltos Karabasilis (id: 2) at 2023-11-25 12:00:00
', 1),
('Physical store revenue', 94.66, '2023-11-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231125-466.
Created by Miltos Karabasilis (id: 2) at 2023-11-25 12:00:00
', 1),
('E-shop revenue', 157.91, '2023-11-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231126-791.
Created by Miltos Karabasilis (id: 2) at 2023-11-26 12:00:00
', 1),
('Physical store revenue', 96.79, '2023-11-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231126-679.
Created by Miltos Karabasilis (id: 2) at 2023-11-26 12:00:00
', 1),
('E-shop revenue', 145.89, '2023-11-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231127-589.
Created by Miltos Karabasilis (id: 2) at 2023-11-27 12:00:00
', 1),
('Physical store revenue', 89.41, '2023-11-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231127-941.
Created by Miltos Karabasilis (id: 2) at 2023-11-27 12:00:00
', 1),
('E-shop revenue', 127.84, '2023-11-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231128-784.
Created by Miltos Karabasilis (id: 2) at 2023-11-28 12:00:00
', 1),
('Physical store revenue', 78.36, '2023-11-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231128-836.
Created by Miltos Karabasilis (id: 2) at 2023-11-28 12:00:00
', 1),
('E-shop revenue', 131.32, '2023-11-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231129-132.
Created by Miltos Karabasilis (id: 2) at 2023-11-29 12:00:00
', 1),
('Physical store revenue', 80.48, '2023-11-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231129-048.
Created by Miltos Karabasilis (id: 2) at 2023-11-29 12:00:00
', 1),
('E-shop revenue', 134.79, '2023-11-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231130-479.
Created by Miltos Karabasilis (id: 2) at 2023-11-30 12:00:00
', 1),
('Physical store revenue', 82.61, '2023-11-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231130-261.
Created by Miltos Karabasilis (id: 2) at 2023-11-30 12:00:00
', 1),
('E-shop revenue', 136.40, '2023-12-01', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20231201-640.
Created by Miltos Karabasilis (id: 2) at 2023-12-01 12:00:00
', 1),
('Physical store revenue', 83.60, '2023-12-01', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20231201-360.
Created by Miltos Karabasilis (id: 2) at 2023-12-01 12:00:00
', 1),
('E-shop revenue', 167.77, '2023-12-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231202-777.
Created by Miltos Karabasilis (id: 2) at 2023-12-02 12:00:00
', 1),
('Physical store revenue', 102.83, '2023-12-02', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231202-283.
Created by Miltos Karabasilis (id: 2) at 2023-12-02 12:00:00
', 1),
('E-shop revenue', 171.24, '2023-12-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231203-124.
Created by Miltos Karabasilis (id: 2) at 2023-12-03 12:00:00
', 1),
('Physical store revenue', 104.96, '2023-12-03', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231203-496.
Created by Miltos Karabasilis (id: 2) at 2023-12-03 12:00:00
', 1),
('E-shop revenue', 159.22, '2023-12-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231204-922.
Created by Miltos Karabasilis (id: 2) at 2023-12-04 12:00:00
', 1),
('Physical store revenue', 97.58, '2023-12-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231204-758.
Created by Miltos Karabasilis (id: 2) at 2023-12-04 12:00:00
', 1),
('E-shop revenue', 150.29, '2023-12-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231205-029.
Created by Miltos Karabasilis (id: 2) at 2023-12-05 12:00:00
', 1),
('Physical store revenue', 92.11, '2023-12-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231205-211.
Created by Miltos Karabasilis (id: 2) at 2023-12-05 12:00:00
', 1),
('E-shop revenue', 153.76, '2023-12-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231206-376.
Created by Miltos Karabasilis (id: 2) at 2023-12-06 12:00:00
', 1),
('Physical store revenue', 94.24, '2023-12-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231206-424.
Created by Miltos Karabasilis (id: 2) at 2023-12-06 12:00:00
', 1),
('E-shop revenue', 111.23, '2023-12-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231207-123.
Created by Miltos Karabasilis (id: 2) at 2023-12-07 12:00:00
', 1),
('Physical store revenue', 68.17, '2023-12-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231207-817.
Created by Miltos Karabasilis (id: 2) at 2023-12-07 12:00:00
', 1),
('E-shop revenue', 114.70, '2023-12-08', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20231208-470.
Created by Miltos Karabasilis (id: 2) at 2023-12-08 12:00:00
', 1),
('Physical store revenue', 70.30, '2023-12-08', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20231208-030.
Created by Miltos Karabasilis (id: 2) at 2023-12-08 12:00:00
', 1),
('E-shop revenue', 146.07, '2023-12-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231209-607.
Created by Miltos Karabasilis (id: 2) at 2023-12-09 12:00:00
', 1),
('Physical store revenue', 89.53, '2023-12-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231209-953.
Created by Miltos Karabasilis (id: 2) at 2023-12-09 12:00:00
', 1),
('E-shop revenue', 149.54, '2023-12-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231210-954.
Created by Miltos Karabasilis (id: 2) at 2023-12-10 12:00:00
', 1),
('Physical store revenue', 91.66, '2023-12-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231210-166.
Created by Miltos Karabasilis (id: 2) at 2023-12-10 12:00:00
', 1),
('E-shop revenue', 137.52, '2023-12-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231211-752.
Created by Miltos Karabasilis (id: 2) at 2023-12-11 12:00:00
', 1),
('Physical store revenue', 84.28, '2023-12-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231211-428.
Created by Miltos Karabasilis (id: 2) at 2023-12-11 12:00:00
', 1),
('E-shop revenue', 128.59, '2023-12-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231212-859.
Created by Miltos Karabasilis (id: 2) at 2023-12-12 12:00:00
', 1),
('Physical store revenue', 78.81, '2023-12-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231212-881.
Created by Miltos Karabasilis (id: 2) at 2023-12-12 12:00:00
', 1),
('E-shop revenue', 132.06, '2023-12-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231213-206.
Created by Miltos Karabasilis (id: 2) at 2023-12-13 12:00:00
', 1),
('Physical store revenue', 80.94, '2023-12-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231213-094.
Created by Miltos Karabasilis (id: 2) at 2023-12-13 12:00:00
', 1),
('E-shop revenue', 126.42, '2023-12-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231214-642.
Created by Miltos Karabasilis (id: 2) at 2023-12-14 12:00:00
', 1),
('Physical store revenue', 77.48, '2023-12-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231214-748.
Created by Miltos Karabasilis (id: 2) at 2023-12-14 12:00:00
', 1),
('E-shop revenue', 129.89, '2023-12-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231215-989.
Created by Miltos Karabasilis (id: 2) at 2023-12-15 12:00:00
', 1),
('Physical store revenue', 79.61, '2023-12-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231215-961.
Created by Miltos Karabasilis (id: 2) at 2023-12-15 12:00:00
', 1),
('E-shop revenue', 161.26, '2023-12-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231216-126.
Created by Miltos Karabasilis (id: 2) at 2023-12-16 12:00:00
', 1),
('Physical store revenue', 98.84, '2023-12-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231216-884.
Created by Miltos Karabasilis (id: 2) at 2023-12-16 12:00:00
', 1),
('E-shop revenue', 164.73, '2023-12-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231217-473.
Created by Miltos Karabasilis (id: 2) at 2023-12-17 12:00:00
', 1),
('Physical store revenue', 100.97, '2023-12-17', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231217-097.
Created by Miltos Karabasilis (id: 2) at 2023-12-17 12:00:00
', 1),
('E-shop revenue', 152.71, '2023-12-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231218-271.
Created by Miltos Karabasilis (id: 2) at 2023-12-18 12:00:00
', 1),
('Physical store revenue', 93.59, '2023-12-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231218-359.
Created by Miltos Karabasilis (id: 2) at 2023-12-18 12:00:00
', 1),
('E-shop revenue', 143.78, '2023-12-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231219-378.
Created by Miltos Karabasilis (id: 2) at 2023-12-19 12:00:00
', 1),
('Physical store revenue', 88.12, '2023-12-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231219-812.
Created by Miltos Karabasilis (id: 2) at 2023-12-19 12:00:00
', 1),
('E-shop revenue', 147.25, '2023-12-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231220-725.
Created by Miltos Karabasilis (id: 2) at 2023-12-20 12:00:00
', 1),
('Physical store revenue', 90.25, '2023-12-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231220-025.
Created by Miltos Karabasilis (id: 2) at 2023-12-20 12:00:00
', 1),
('E-shop revenue', 141.61, '2023-12-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231221-161.
Created by Miltos Karabasilis (id: 2) at 2023-12-21 12:00:00
', 1),
('Physical store revenue', 86.79, '2023-12-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231221-679.
Created by Miltos Karabasilis (id: 2) at 2023-12-21 12:00:00
', 1),
('E-shop revenue', 145.08, '2023-12-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231222-508.
Created by Miltos Karabasilis (id: 2) at 2023-12-22 12:00:00
', 1),
('Physical store revenue', 88.92, '2023-12-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231222-892.
Created by Miltos Karabasilis (id: 2) at 2023-12-22 12:00:00
', 1),
('E-shop revenue', 176.45, '2023-12-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231223-645.
Created by Miltos Karabasilis (id: 2) at 2023-12-23 12:00:00
', 1),
('Physical store revenue', 108.15, '2023-12-23', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20231223-815.
Created by Miltos Karabasilis (id: 2) at 2023-12-23 12:00:00
', 1),
('E-shop revenue', 143.03, '2023-12-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231224-303.
Created by Miltos Karabasilis (id: 2) at 2023-12-24 12:00:00
', 1),
('Physical store revenue', 87.67, '2023-12-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231224-767.
Created by Miltos Karabasilis (id: 2) at 2023-12-24 12:00:00
', 1),
('E-shop revenue', 131.01, '2023-12-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231225-101.
Created by Miltos Karabasilis (id: 2) at 2023-12-25 12:00:00
', 1),
('Physical store revenue', 80.29, '2023-12-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231225-029.
Created by Miltos Karabasilis (id: 2) at 2023-12-25 12:00:00
', 1),
('E-shop revenue', 122.08, '2023-12-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231226-208.
Created by Miltos Karabasilis (id: 2) at 2023-12-26 12:00:00
', 1),
('Physical store revenue', 74.82, '2023-12-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231226-482.
Created by Miltos Karabasilis (id: 2) at 2023-12-26 12:00:00
', 1),
('E-shop revenue', 125.55, '2023-12-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231227-555.
Created by Miltos Karabasilis (id: 2) at 2023-12-27 12:00:00
', 1),
('Physical store revenue', 76.95, '2023-12-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231227-695.
Created by Miltos Karabasilis (id: 2) at 2023-12-27 12:00:00
', 1),
('E-shop revenue', 119.91, '2023-12-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231228-991.
Created by Miltos Karabasilis (id: 2) at 2023-12-28 12:00:00
', 1),
('Physical store revenue', 73.49, '2023-12-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231228-349.
Created by Miltos Karabasilis (id: 2) at 2023-12-28 12:00:00
', 1),
('E-shop revenue', 123.38, '2023-12-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20231229-338.
Created by Miltos Karabasilis (id: 2) at 2023-12-29 12:00:00
', 1),
('Physical store revenue', 75.62, '2023-12-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231229-562.
Created by Miltos Karabasilis (id: 2) at 2023-12-29 12:00:00
', 1),
('E-shop revenue', 154.75, '2023-12-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231230-475.
Created by Miltos Karabasilis (id: 2) at 2023-12-30 12:00:00
', 1),
('Physical store revenue', 94.85, '2023-12-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231230-485.
Created by Miltos Karabasilis (id: 2) at 2023-12-30 12:00:00
', 1),
('E-shop revenue', 158.22, '2023-12-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20231231-822.
Created by Miltos Karabasilis (id: 2) at 2023-12-31 12:00:00
', 1),
('Physical store revenue', 96.98, '2023-12-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20231231-698.
Created by Miltos Karabasilis (id: 2) at 2023-12-31 12:00:00
', 1),
('E-shop revenue', 139.07, '2024-01-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240101-907.
Created by Miltos Karabasilis (id: 2) at 2024-01-01 12:00:00
', 1),
('Physical store revenue', 85.23, '2024-01-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240101-523.
Created by Miltos Karabasilis (id: 2) at 2024-01-01 12:00:00
', 1),
('E-shop revenue', 130.14, '2024-01-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240102-014.
Created by Miltos Karabasilis (id: 2) at 2024-01-02 12:00:00
', 1),
('Physical store revenue', 79.76, '2024-01-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240102-976.
Created by Miltos Karabasilis (id: 2) at 2024-01-02 12:00:00
', 1),
('E-shop revenue', 133.61, '2024-01-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240103-361.
Created by Miltos Karabasilis (id: 2) at 2024-01-03 12:00:00
', 1),
('Physical store revenue', 81.89, '2024-01-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240103-189.
Created by Miltos Karabasilis (id: 2) at 2024-01-03 12:00:00
', 1),
('E-shop revenue', 137.08, '2024-01-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240104-708.
Created by Miltos Karabasilis (id: 2) at 2024-01-04 12:00:00
', 1),
('Physical store revenue', 84.02, '2024-01-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240104-402.
Created by Miltos Karabasilis (id: 2) at 2024-01-04 12:00:00
', 1),
('E-shop revenue', 140.55, '2024-01-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240105-055.
Created by Miltos Karabasilis (id: 2) at 2024-01-05 12:00:00
', 1),
('Physical store revenue', 86.15, '2024-01-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240105-615.
Created by Miltos Karabasilis (id: 2) at 2024-01-05 12:00:00
', 1),
('E-shop revenue', 171.93, '2024-01-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240106-193.
Created by Miltos Karabasilis (id: 2) at 2024-01-06 12:00:00
', 1),
('Physical store revenue', 105.37, '2024-01-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240106-537.
Created by Miltos Karabasilis (id: 2) at 2024-01-06 12:00:00
', 1),
('E-shop revenue', 166.28, '2024-01-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240107-628.
Created by Miltos Karabasilis (id: 2) at 2024-01-07 12:00:00
', 1),
('Physical store revenue', 101.92, '2024-01-07', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240107-192.
Created by Miltos Karabasilis (id: 2) at 2024-01-07 12:00:00
', 1),
('E-shop revenue', 154.26, '2024-01-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240108-426.
Created by Miltos Karabasilis (id: 2) at 2024-01-08 12:00:00
', 1),
('Physical store revenue', 94.54, '2024-01-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240108-454.
Created by Miltos Karabasilis (id: 2) at 2024-01-08 12:00:00
', 1),
('E-shop revenue', 145.33, '2024-01-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240109-533.
Created by Miltos Karabasilis (id: 2) at 2024-01-09 12:00:00
', 1),
('Physical store revenue', 89.07, '2024-01-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240109-907.
Created by Miltos Karabasilis (id: 2) at 2024-01-09 12:00:00
', 1),
('E-shop revenue', 111.91, '2024-01-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240110-191.
Created by Miltos Karabasilis (id: 2) at 2024-01-10 12:00:00
', 1),
('Physical store revenue', 68.59, '2024-01-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240110-859.
Created by Miltos Karabasilis (id: 2) at 2024-01-10 12:00:00
', 1),
('E-shop revenue', 115.38, '2024-01-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240111-538.
Created by Miltos Karabasilis (id: 2) at 2024-01-11 12:00:00
', 1),
('Physical store revenue', 70.72, '2024-01-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240111-072.
Created by Miltos Karabasilis (id: 2) at 2024-01-11 12:00:00
', 1),
('E-shop revenue', 118.85, '2024-01-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240112-885.
Created by Miltos Karabasilis (id: 2) at 2024-01-12 12:00:00
', 1),
('Physical store revenue', 72.85, '2024-01-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240112-285.
Created by Miltos Karabasilis (id: 2) at 2024-01-12 12:00:00
', 1),
('E-shop revenue', 150.23, '2024-01-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240113-023.
Created by Miltos Karabasilis (id: 2) at 2024-01-13 12:00:00
', 1),
('Physical store revenue', 92.07, '2024-01-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240113-207.
Created by Miltos Karabasilis (id: 2) at 2024-01-13 12:00:00
', 1),
('E-shop revenue', 144.58, '2024-01-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240114-458.
Created by Miltos Karabasilis (id: 2) at 2024-01-14 12:00:00
', 1),
('Physical store revenue', 88.62, '2024-01-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240114-862.
Created by Miltos Karabasilis (id: 2) at 2024-01-14 12:00:00
', 1),
('E-shop revenue', 132.56, '2024-01-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240115-256.
Created by Miltos Karabasilis (id: 2) at 2024-01-15 12:00:00
', 1),
('Physical store revenue', 81.24, '2024-01-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240115-124.
Created by Miltos Karabasilis (id: 2) at 2024-01-15 12:00:00
', 1),
('E-shop revenue', 123.63, '2024-01-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240116-363.
Created by Miltos Karabasilis (id: 2) at 2024-01-16 12:00:00
', 1),
('Physical store revenue', 75.77, '2024-01-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240116-577.
Created by Miltos Karabasilis (id: 2) at 2024-01-16 12:00:00
', 1),
('E-shop revenue', 127.10, '2024-01-17', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240117-710.
Created by Miltos Karabasilis (id: 2) at 2024-01-17 12:00:00
', 1),
('Physical store revenue', 77.90, '2024-01-17', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240117-790.
Created by Miltos Karabasilis (id: 2) at 2024-01-17 12:00:00
', 1),
('E-shop revenue', 130.57, '2024-01-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240118-057.
Created by Miltos Karabasilis (id: 2) at 2024-01-18 12:00:00
', 1),
('Physical store revenue', 80.03, '2024-01-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240118-003.
Created by Miltos Karabasilis (id: 2) at 2024-01-18 12:00:00
', 1),
('E-shop revenue', 134.04, '2024-01-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240119-404.
Created by Miltos Karabasilis (id: 2) at 2024-01-19 12:00:00
', 1),
('Physical store revenue', 82.16, '2024-01-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240119-216.
Created by Miltos Karabasilis (id: 2) at 2024-01-19 12:00:00
', 1),
('E-shop revenue', 165.42, '2024-01-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240120-542.
Created by Miltos Karabasilis (id: 2) at 2024-01-20 12:00:00
', 1),
('Physical store revenue', 101.38, '2024-01-20', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240120-138.
Created by Miltos Karabasilis (id: 2) at 2024-01-20 12:00:00
', 1),
('E-shop revenue', 159.77, '2024-01-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240121-977.
Created by Miltos Karabasilis (id: 2) at 2024-01-21 12:00:00
', 1),
('Physical store revenue', 97.93, '2024-01-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240121-793.
Created by Miltos Karabasilis (id: 2) at 2024-01-21 12:00:00
', 1),
('E-shop revenue', 147.75, '2024-01-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240122-775.
Created by Miltos Karabasilis (id: 2) at 2024-01-22 12:00:00
', 1),
('Physical store revenue', 90.55, '2024-01-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240122-055.
Created by Miltos Karabasilis (id: 2) at 2024-01-22 12:00:00
', 1),
('E-shop revenue', 138.82, '2024-01-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240123-882.
Created by Miltos Karabasilis (id: 2) at 2024-01-23 12:00:00
', 1),
('Physical store revenue', 85.08, '2024-01-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240123-508.
Created by Miltos Karabasilis (id: 2) at 2024-01-23 12:00:00
', 1),
('E-shop revenue', 142.29, '2024-01-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240124-229.
Created by Miltos Karabasilis (id: 2) at 2024-01-24 12:00:00
', 1),
('Physical store revenue', 87.21, '2024-01-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240124-721.
Created by Miltos Karabasilis (id: 2) at 2024-01-24 12:00:00
', 1),
('E-shop revenue', 145.76, '2024-01-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240125-576.
Created by Miltos Karabasilis (id: 2) at 2024-01-25 12:00:00
', 1),
('Physical store revenue', 89.34, '2024-01-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240125-934.
Created by Miltos Karabasilis (id: 2) at 2024-01-25 12:00:00
', 1),
('E-shop revenue', 149.23, '2024-01-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240126-923.
Created by Miltos Karabasilis (id: 2) at 2024-01-26 12:00:00
', 1),
('Physical store revenue', 91.47, '2024-01-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240126-147.
Created by Miltos Karabasilis (id: 2) at 2024-01-26 12:00:00
', 1),
('E-shop revenue', 143.72, '2024-01-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240127-372.
Created by Miltos Karabasilis (id: 2) at 2024-01-27 12:00:00
', 1),
('Physical store revenue', 88.08, '2024-01-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240127-808.
Created by Miltos Karabasilis (id: 2) at 2024-01-27 12:00:00
', 1),
('E-shop revenue', 138.07, '2024-01-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240128-807.
Created by Miltos Karabasilis (id: 2) at 2024-01-28 12:00:00
', 1),
('Physical store revenue', 84.63, '2024-01-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240128-463.
Created by Miltos Karabasilis (id: 2) at 2024-01-28 12:00:00
', 1),
('E-shop revenue', 126.05, '2024-01-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240129-605.
Created by Miltos Karabasilis (id: 2) at 2024-01-29 12:00:00
', 1),
('Physical store revenue', 77.25, '2024-01-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240129-725.
Created by Miltos Karabasilis (id: 2) at 2024-01-29 12:00:00
', 1),
('E-shop revenue', 117.12, '2024-01-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240130-712.
Created by Miltos Karabasilis (id: 2) at 2024-01-30 12:00:00
', 1),
('Physical store revenue', 71.78, '2024-01-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240130-178.
Created by Miltos Karabasilis (id: 2) at 2024-01-30 12:00:00
', 1),
('E-shop revenue', 120.59, '2024-01-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240131-059.
Created by Miltos Karabasilis (id: 2) at 2024-01-31 12:00:00
', 1),
('Physical store revenue', 73.91, '2024-01-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240131-391.
Created by Miltos Karabasilis (id: 2) at 2024-01-31 12:00:00
', 1),
('E-shop revenue', 120.90, '2024-02-01', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240201-090.
Created by Miltos Karabasilis (id: 2) at 2024-02-01 12:00:00
', 1),
('Physical store revenue', 74.10, '2024-02-01', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240201-410.
Created by Miltos Karabasilis (id: 2) at 2024-02-01 12:00:00
', 1),
('E-shop revenue', 124.37, '2024-02-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240202-437.
Created by Miltos Karabasilis (id: 2) at 2024-02-02 12:00:00
', 1),
('Physical store revenue', 76.23, '2024-02-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240202-623.
Created by Miltos Karabasilis (id: 2) at 2024-02-02 12:00:00
', 1),
('E-shop revenue', 155.74, '2024-02-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240203-574.
Created by Miltos Karabasilis (id: 2) at 2024-02-03 12:00:00
', 1),
('Physical store revenue', 95.46, '2024-02-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240203-546.
Created by Miltos Karabasilis (id: 2) at 2024-02-03 12:00:00
', 1),
('E-shop revenue', 159.22, '2024-02-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240204-922.
Created by Miltos Karabasilis (id: 2) at 2024-02-04 12:00:00
', 1),
('Physical store revenue', 97.58, '2024-02-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240204-758.
Created by Miltos Karabasilis (id: 2) at 2024-02-04 12:00:00
', 1),
('E-shop revenue', 147.19, '2024-02-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240205-719.
Created by Miltos Karabasilis (id: 2) at 2024-02-05 12:00:00
', 1),
('Physical store revenue', 90.21, '2024-02-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240205-021.
Created by Miltos Karabasilis (id: 2) at 2024-02-05 12:00:00
', 1),
('E-shop revenue', 138.26, '2024-02-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240206-826.
Created by Miltos Karabasilis (id: 2) at 2024-02-06 12:00:00
', 1),
('Physical store revenue', 84.74, '2024-02-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240206-474.
Created by Miltos Karabasilis (id: 2) at 2024-02-06 12:00:00
', 1),
('E-shop revenue', 132.62, '2024-02-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240207-262.
Created by Miltos Karabasilis (id: 2) at 2024-02-07 12:00:00
', 1),
('Physical store revenue', 81.28, '2024-02-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240207-128.
Created by Miltos Karabasilis (id: 2) at 2024-02-07 12:00:00
', 1),
('E-shop revenue', 136.09, '2024-02-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240208-609.
Created by Miltos Karabasilis (id: 2) at 2024-02-08 12:00:00
', 1),
('Physical store revenue', 83.41, '2024-02-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240208-341.
Created by Miltos Karabasilis (id: 2) at 2024-02-08 12:00:00
', 1),
('E-shop revenue', 139.56, '2024-02-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240209-956.
Created by Miltos Karabasilis (id: 2) at 2024-02-09 12:00:00
', 1),
('Physical store revenue', 85.54, '2024-02-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240209-554.
Created by Miltos Karabasilis (id: 2) at 2024-02-09 12:00:00
', 1),
('E-shop revenue', 170.93, '2024-02-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240210-093.
Created by Miltos Karabasilis (id: 2) at 2024-02-10 12:00:00
', 1),
('Physical store revenue', 104.77, '2024-02-10', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240210-477.
Created by Miltos Karabasilis (id: 2) at 2024-02-10 12:00:00
', 1),
('E-shop revenue', 174.41, '2024-02-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240211-441.
Created by Miltos Karabasilis (id: 2) at 2024-02-11 12:00:00
', 1),
('Physical store revenue', 106.89, '2024-02-11', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240211-689.
Created by Miltos Karabasilis (id: 2) at 2024-02-11 12:00:00
', 1),
('E-shop revenue', 162.38, '2024-02-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240212-238.
Created by Miltos Karabasilis (id: 2) at 2024-02-12 12:00:00
', 1),
('Physical store revenue', 99.52, '2024-02-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240212-952.
Created by Miltos Karabasilis (id: 2) at 2024-02-12 12:00:00
', 1),
('E-shop revenue', 116.56, '2024-02-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240213-656.
Created by Miltos Karabasilis (id: 2) at 2024-02-13 12:00:00
', 1),
('Physical store revenue', 71.44, '2024-02-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240213-144.
Created by Miltos Karabasilis (id: 2) at 2024-02-13 12:00:00
', 1),
('E-shop revenue', 110.92, '2024-02-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240214-092.
Created by Miltos Karabasilis (id: 2) at 2024-02-14 12:00:00
', 1),
('Physical store revenue', 67.98, '2024-02-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240214-798.
Created by Miltos Karabasilis (id: 2) at 2024-02-14 12:00:00
', 1),
('E-shop revenue', 114.39, '2024-02-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240215-439.
Created by Miltos Karabasilis (id: 2) at 2024-02-15 12:00:00
', 1),
('Physical store revenue', 70.11, '2024-02-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240215-011.
Created by Miltos Karabasilis (id: 2) at 2024-02-15 12:00:00
', 1),
('E-shop revenue', 117.86, '2024-02-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240216-786.
Created by Miltos Karabasilis (id: 2) at 2024-02-16 12:00:00
', 1),
('Physical store revenue', 72.24, '2024-02-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240216-224.
Created by Miltos Karabasilis (id: 2) at 2024-02-16 12:00:00
', 1),
('E-shop revenue', 149.23, '2024-02-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240217-923.
Created by Miltos Karabasilis (id: 2) at 2024-02-17 12:00:00
', 1),
('Physical store revenue', 91.47, '2024-02-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240217-147.
Created by Miltos Karabasilis (id: 2) at 2024-02-17 12:00:00
', 1),
('E-shop revenue', 152.71, '2024-02-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240218-271.
Created by Miltos Karabasilis (id: 2) at 2024-02-18 12:00:00
', 1),
('Physical store revenue', 93.59, '2024-02-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240218-359.
Created by Miltos Karabasilis (id: 2) at 2024-02-18 12:00:00
', 1),
('E-shop revenue', 140.68, '2024-02-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240219-068.
Created by Miltos Karabasilis (id: 2) at 2024-02-19 12:00:00
', 1),
('Physical store revenue', 86.22, '2024-02-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240219-622.
Created by Miltos Karabasilis (id: 2) at 2024-02-19 12:00:00
', 1),
('E-shop revenue', 131.75, '2024-02-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240220-175.
Created by Miltos Karabasilis (id: 2) at 2024-02-20 12:00:00
', 1),
('Physical store revenue', 80.75, '2024-02-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240220-075.
Created by Miltos Karabasilis (id: 2) at 2024-02-20 12:00:00
', 1),
('E-shop revenue', 126.11, '2024-02-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240221-611.
Created by Miltos Karabasilis (id: 2) at 2024-02-21 12:00:00
', 1),
('Physical store revenue', 77.29, '2024-02-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240221-729.
Created by Miltos Karabasilis (id: 2) at 2024-02-21 12:00:00
', 1),
('E-shop revenue', 129.58, '2024-02-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240222-958.
Created by Miltos Karabasilis (id: 2) at 2024-02-22 12:00:00
', 1),
('Physical store revenue', 79.42, '2024-02-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240222-942.
Created by Miltos Karabasilis (id: 2) at 2024-02-22 12:00:00
', 1),
('E-shop revenue', 133.05, '2024-02-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240223-305.
Created by Miltos Karabasilis (id: 2) at 2024-02-23 12:00:00
', 1),
('Physical store revenue', 81.55, '2024-02-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240223-155.
Created by Miltos Karabasilis (id: 2) at 2024-02-23 12:00:00
', 1),
('E-shop revenue', 164.42, '2024-02-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240224-442.
Created by Miltos Karabasilis (id: 2) at 2024-02-24 12:00:00
', 1),
('Physical store revenue', 100.78, '2024-02-24', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240224-078.
Created by Miltos Karabasilis (id: 2) at 2024-02-24 12:00:00
', 1),
('E-shop revenue', 167.90, '2024-02-25', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20240225-790.
Created by Miltos Karabasilis (id: 2) at 2024-02-25 12:00:00
', 1),
('Physical store revenue', 102.90, '2024-02-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240225-290.
Created by Miltos Karabasilis (id: 2) at 2024-02-25 12:00:00
', 1),
('E-shop revenue', 155.87, '2024-02-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240226-587.
Created by Miltos Karabasilis (id: 2) at 2024-02-26 12:00:00
', 1),
('Physical store revenue', 95.53, '2024-02-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240226-553.
Created by Miltos Karabasilis (id: 2) at 2024-02-26 12:00:00
', 1),
('E-shop revenue', 146.94, '2024-02-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240227-694.
Created by Miltos Karabasilis (id: 2) at 2024-02-27 12:00:00
', 1),
('Physical store revenue', 90.06, '2024-02-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240227-006.
Created by Miltos Karabasilis (id: 2) at 2024-02-27 12:00:00
', 1),
('E-shop revenue', 141.30, '2024-02-28', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240228-130.
Created by Miltos Karabasilis (id: 2) at 2024-02-28 12:00:00
', 1),
('Physical store revenue', 86.60, '2024-02-28', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240228-660.
Created by Miltos Karabasilis (id: 2) at 2024-02-28 12:00:00
', 1),
('E-shop revenue', 144.77, '2024-02-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240229-477.
Created by Miltos Karabasilis (id: 2) at 2024-02-29 12:00:00
', 1),
('Physical store revenue', 88.73, '2024-02-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240229-873.
Created by Miltos Karabasilis (id: 2) at 2024-02-29 12:00:00
', 1),
('E-shop revenue', 110.79, '2024-03-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240301-079.
Created by Miltos Karabasilis (id: 2) at 2024-03-01 12:00:00
', 1),
('Physical store revenue', 67.91, '2024-03-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240301-791.
Created by Miltos Karabasilis (id: 2) at 2024-03-01 12:00:00
', 1),
('E-shop revenue', 142.17, '2024-03-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240302-217.
Created by Miltos Karabasilis (id: 2) at 2024-03-02 12:00:00
', 1),
('Physical store revenue', 87.13, '2024-03-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240302-713.
Created by Miltos Karabasilis (id: 2) at 2024-03-02 12:00:00
', 1),
('E-shop revenue', 145.64, '2024-03-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240303-564.
Created by Miltos Karabasilis (id: 2) at 2024-03-03 12:00:00
', 1),
('Physical store revenue', 89.26, '2024-03-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240303-926.
Created by Miltos Karabasilis (id: 2) at 2024-03-03 12:00:00
', 1),
('E-shop revenue', 133.61, '2024-03-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240304-361.
Created by Miltos Karabasilis (id: 2) at 2024-03-04 12:00:00
', 1),
('Physical store revenue', 81.89, '2024-03-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240304-189.
Created by Miltos Karabasilis (id: 2) at 2024-03-04 12:00:00
', 1),
('E-shop revenue', 124.68, '2024-03-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240305-468.
Created by Miltos Karabasilis (id: 2) at 2024-03-05 12:00:00
', 1),
('Physical store revenue', 76.42, '2024-03-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240305-642.
Created by Miltos Karabasilis (id: 2) at 2024-03-05 12:00:00
', 1),
('E-shop revenue', 128.15, '2024-03-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240306-815.
Created by Miltos Karabasilis (id: 2) at 2024-03-06 12:00:00
', 1),
('Physical store revenue', 78.55, '2024-03-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240306-855.
Created by Miltos Karabasilis (id: 2) at 2024-03-06 12:00:00
', 1),
('E-shop revenue', 122.51, '2024-03-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240307-251.
Created by Miltos Karabasilis (id: 2) at 2024-03-07 12:00:00
', 1),
('Physical store revenue', 75.09, '2024-03-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240307-509.
Created by Miltos Karabasilis (id: 2) at 2024-03-07 12:00:00
', 1),
('E-shop revenue', 125.98, '2024-03-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240308-598.
Created by Miltos Karabasilis (id: 2) at 2024-03-08 12:00:00
', 1),
('Physical store revenue', 77.22, '2024-03-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240308-722.
Created by Miltos Karabasilis (id: 2) at 2024-03-08 12:00:00
', 1),
('E-shop revenue', 157.36, '2024-03-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240309-736.
Created by Miltos Karabasilis (id: 2) at 2024-03-09 12:00:00
', 1),
('Physical store revenue', 96.44, '2024-03-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240309-644.
Created by Miltos Karabasilis (id: 2) at 2024-03-09 12:00:00
', 1),
('E-shop revenue', 160.83, '2024-03-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240310-083.
Created by Miltos Karabasilis (id: 2) at 2024-03-10 12:00:00
', 1),
('Physical store revenue', 98.57, '2024-03-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240310-857.
Created by Miltos Karabasilis (id: 2) at 2024-03-10 12:00:00
', 1),
('E-shop revenue', 148.80, '2024-03-11', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240311-880.
Created by Miltos Karabasilis (id: 2) at 2024-03-11 12:00:00
', 1),
('Physical store revenue', 91.20, '2024-03-11', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240311-120.
Created by Miltos Karabasilis (id: 2) at 2024-03-11 12:00:00
', 1),
('E-shop revenue', 139.87, '2024-03-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240312-987.
Created by Miltos Karabasilis (id: 2) at 2024-03-12 12:00:00
', 1),
('Physical store revenue', 85.73, '2024-03-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240312-573.
Created by Miltos Karabasilis (id: 2) at 2024-03-12 12:00:00
', 1),
('E-shop revenue', 143.34, '2024-03-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240313-334.
Created by Miltos Karabasilis (id: 2) at 2024-03-13 12:00:00
', 1),
('Physical store revenue', 87.86, '2024-03-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240313-786.
Created by Miltos Karabasilis (id: 2) at 2024-03-13 12:00:00
', 1),
('E-shop revenue', 137.70, '2024-03-14', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240314-770.
Created by Miltos Karabasilis (id: 2) at 2024-03-14 12:00:00
', 1),
('Physical store revenue', 84.40, '2024-03-14', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240314-440.
Created by Miltos Karabasilis (id: 2) at 2024-03-14 12:00:00
', 1),
('E-shop revenue', 141.17, '2024-03-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240315-117.
Created by Miltos Karabasilis (id: 2) at 2024-03-15 12:00:00
', 1),
('Physical store revenue', 86.53, '2024-03-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240315-653.
Created by Miltos Karabasilis (id: 2) at 2024-03-15 12:00:00
', 1),
('E-shop revenue', 172.55, '2024-03-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240316-255.
Created by Miltos Karabasilis (id: 2) at 2024-03-16 12:00:00
', 1),
('Physical store revenue', 105.75, '2024-03-16', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240316-575.
Created by Miltos Karabasilis (id: 2) at 2024-03-16 12:00:00
', 1),
('E-shop revenue', 176.02, '2024-03-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240317-602.
Created by Miltos Karabasilis (id: 2) at 2024-03-17 12:00:00
', 1),
('Physical store revenue', 107.88, '2024-03-17', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240317-788.
Created by Miltos Karabasilis (id: 2) at 2024-03-17 12:00:00
', 1),
('E-shop revenue', 127.10, '2024-03-18', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240318-710.
Created by Miltos Karabasilis (id: 2) at 2024-03-18 12:00:00
', 1),
('Physical store revenue', 77.90, '2024-03-18', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240318-790.
Created by Miltos Karabasilis (id: 2) at 2024-03-18 12:00:00
', 1),
('E-shop revenue', 118.17, '2024-03-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240319-817.
Created by Miltos Karabasilis (id: 2) at 2024-03-19 12:00:00
', 1),
('Physical store revenue', 72.43, '2024-03-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240319-243.
Created by Miltos Karabasilis (id: 2) at 2024-03-19 12:00:00
', 1),
('E-shop revenue', 121.64, '2024-03-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240320-164.
Created by Miltos Karabasilis (id: 2) at 2024-03-20 12:00:00
', 1),
('Physical store revenue', 74.56, '2024-03-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240320-456.
Created by Miltos Karabasilis (id: 2) at 2024-03-20 12:00:00
', 1),
('E-shop revenue', 116.00, '2024-03-21', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20240321-600.
Created by Miltos Karabasilis (id: 2) at 2024-03-21 12:00:00
', 1),
('Physical store revenue', 71.10, '2024-03-21', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240321-110.
Created by Miltos Karabasilis (id: 2) at 2024-03-21 12:00:00
', 1),
('E-shop revenue', 119.47, '2024-03-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240322-947.
Created by Miltos Karabasilis (id: 2) at 2024-03-22 12:00:00
', 1),
('Physical store revenue', 73.23, '2024-03-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240322-323.
Created by Miltos Karabasilis (id: 2) at 2024-03-22 12:00:00
', 1),
('E-shop revenue', 150.85, '2024-03-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240323-085.
Created by Miltos Karabasilis (id: 2) at 2024-03-23 12:00:00
', 1),
('Physical store revenue', 92.45, '2024-03-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240323-245.
Created by Miltos Karabasilis (id: 2) at 2024-03-23 12:00:00
', 1),
('E-shop revenue', 154.32, '2024-03-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240324-432.
Created by Miltos Karabasilis (id: 2) at 2024-03-24 12:00:00
', 1),
('Physical store revenue', 94.58, '2024-03-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240324-458.
Created by Miltos Karabasilis (id: 2) at 2024-03-24 12:00:00
', 1),
('E-shop revenue', 142.29, '2024-03-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240325-229.
Created by Miltos Karabasilis (id: 2) at 2024-03-25 12:00:00
', 1),
('Physical store revenue', 87.21, '2024-03-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240325-721.
Created by Miltos Karabasilis (id: 2) at 2024-03-25 12:00:00
', 1),
('E-shop revenue', 133.36, '2024-03-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240326-336.
Created by Miltos Karabasilis (id: 2) at 2024-03-26 12:00:00
', 1),
('Physical store revenue', 81.74, '2024-03-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240326-174.
Created by Miltos Karabasilis (id: 2) at 2024-03-26 12:00:00
', 1),
('E-shop revenue', 136.83, '2024-03-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240327-683.
Created by Miltos Karabasilis (id: 2) at 2024-03-27 12:00:00
', 1),
('Physical store revenue', 83.87, '2024-03-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240327-387.
Created by Miltos Karabasilis (id: 2) at 2024-03-27 12:00:00
', 1),
('E-shop revenue', 131.19, '2024-03-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240328-119.
Created by Miltos Karabasilis (id: 2) at 2024-03-28 12:00:00
', 1),
('Physical store revenue', 80.41, '2024-03-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240328-041.
Created by Miltos Karabasilis (id: 2) at 2024-03-28 12:00:00
', 1),
('E-shop revenue', 134.66, '2024-03-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240329-466.
Created by Miltos Karabasilis (id: 2) at 2024-03-29 12:00:00
', 1),
('Physical store revenue', 82.54, '2024-03-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240329-254.
Created by Miltos Karabasilis (id: 2) at 2024-03-29 12:00:00
', 1),
('E-shop revenue', 166.04, '2024-03-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240330-604.
Created by Miltos Karabasilis (id: 2) at 2024-03-30 12:00:00
', 1),
('Physical store revenue', 101.76, '2024-03-30', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240330-176.
Created by Miltos Karabasilis (id: 2) at 2024-03-30 12:00:00
', 1),
('E-shop revenue', 169.51, '2024-03-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240331-951.
Created by Miltos Karabasilis (id: 2) at 2024-03-31 12:00:00
', 1),
('Physical store revenue', 103.89, '2024-03-31', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240331-389.
Created by Miltos Karabasilis (id: 2) at 2024-03-31 12:00:00
', 1),
('E-shop revenue', 154.32, '2024-04-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240401-432.
Created by Miltos Karabasilis (id: 2) at 2024-04-01 12:00:00
', 1),
('Physical store revenue', 94.58, '2024-04-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240401-458.
Created by Miltos Karabasilis (id: 2) at 2024-04-01 12:00:00
', 1),
('E-shop revenue', 145.39, '2024-04-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240402-539.
Created by Miltos Karabasilis (id: 2) at 2024-04-02 12:00:00
', 1),
('Physical store revenue', 89.11, '2024-04-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240402-911.
Created by Miltos Karabasilis (id: 2) at 2024-04-02 12:00:00
', 1),
('E-shop revenue', 148.86, '2024-04-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240403-886.
Created by Miltos Karabasilis (id: 2) at 2024-04-03 12:00:00
', 1),
('Physical store revenue', 91.24, '2024-04-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240403-124.
Created by Miltos Karabasilis (id: 2) at 2024-04-03 12:00:00
', 1),
('E-shop revenue', 115.44, '2024-04-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240404-544.
Created by Miltos Karabasilis (id: 2) at 2024-04-04 12:00:00
', 1),
('Physical store revenue', 70.76, '2024-04-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240404-076.
Created by Miltos Karabasilis (id: 2) at 2024-04-04 12:00:00
', 1),
('E-shop revenue', 118.92, '2024-04-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240405-892.
Created by Miltos Karabasilis (id: 2) at 2024-04-05 12:00:00
', 1),
('Physical store revenue', 72.88, '2024-04-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240405-288.
Created by Miltos Karabasilis (id: 2) at 2024-04-05 12:00:00
', 1),
('E-shop revenue', 150.29, '2024-04-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240406-029.
Created by Miltos Karabasilis (id: 2) at 2024-04-06 12:00:00
', 1),
('Physical store revenue', 92.11, '2024-04-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240406-211.
Created by Miltos Karabasilis (id: 2) at 2024-04-06 12:00:00
', 1),
('E-shop revenue', 144.65, '2024-04-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240407-465.
Created by Miltos Karabasilis (id: 2) at 2024-04-07 12:00:00
', 1),
('Physical store revenue', 88.65, '2024-04-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240407-865.
Created by Miltos Karabasilis (id: 2) at 2024-04-07 12:00:00
', 1),
('E-shop revenue', 132.62, '2024-04-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240408-262.
Created by Miltos Karabasilis (id: 2) at 2024-04-08 12:00:00
', 1),
('Physical store revenue', 81.28, '2024-04-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240408-128.
Created by Miltos Karabasilis (id: 2) at 2024-04-08 12:00:00
', 1),
('E-shop revenue', 123.69, '2024-04-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240409-369.
Created by Miltos Karabasilis (id: 2) at 2024-04-09 12:00:00
', 1),
('Physical store revenue', 75.81, '2024-04-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240409-581.
Created by Miltos Karabasilis (id: 2) at 2024-04-09 12:00:00
', 1),
('E-shop revenue', 127.16, '2024-04-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240410-716.
Created by Miltos Karabasilis (id: 2) at 2024-04-10 12:00:00
', 1),
('Physical store revenue', 77.94, '2024-04-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240410-794.
Created by Miltos Karabasilis (id: 2) at 2024-04-10 12:00:00
', 1),
('E-shop revenue', 130.63, '2024-04-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240411-063.
Created by Miltos Karabasilis (id: 2) at 2024-04-11 12:00:00
', 1),
('Physical store revenue', 80.07, '2024-04-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240411-007.
Created by Miltos Karabasilis (id: 2) at 2024-04-11 12:00:00
', 1),
('E-shop revenue', 134.11, '2024-04-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240412-411.
Created by Miltos Karabasilis (id: 2) at 2024-04-12 12:00:00
', 1),
('Physical store revenue', 82.19, '2024-04-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240412-219.
Created by Miltos Karabasilis (id: 2) at 2024-04-12 12:00:00
', 1),
('E-shop revenue', 165.48, '2024-04-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240413-548.
Created by Miltos Karabasilis (id: 2) at 2024-04-13 12:00:00
', 1),
('Physical store revenue', 101.42, '2024-04-13', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240413-142.
Created by Miltos Karabasilis (id: 2) at 2024-04-13 12:00:00
', 1),
('E-shop revenue', 159.84, '2024-04-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240414-984.
Created by Miltos Karabasilis (id: 2) at 2024-04-14 12:00:00
', 1),
('Physical store revenue', 97.96, '2024-04-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240414-796.
Created by Miltos Karabasilis (id: 2) at 2024-04-14 12:00:00
', 1),
('E-shop revenue', 147.81, '2024-04-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240415-781.
Created by Miltos Karabasilis (id: 2) at 2024-04-15 12:00:00
', 1),
('Physical store revenue', 90.59, '2024-04-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240415-059.
Created by Miltos Karabasilis (id: 2) at 2024-04-15 12:00:00
', 1),
('E-shop revenue', 138.88, '2024-04-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240416-888.
Created by Miltos Karabasilis (id: 2) at 2024-04-16 12:00:00
', 1),
('Physical store revenue', 85.12, '2024-04-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240416-512.
Created by Miltos Karabasilis (id: 2) at 2024-04-16 12:00:00
', 1),
('E-shop revenue', 142.35, '2024-04-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240417-235.
Created by Miltos Karabasilis (id: 2) at 2024-04-17 12:00:00
', 1),
('Physical store revenue', 87.25, '2024-04-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240417-725.
Created by Miltos Karabasilis (id: 2) at 2024-04-17 12:00:00
', 1),
('E-shop revenue', 145.82, '2024-04-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240418-582.
Created by Miltos Karabasilis (id: 2) at 2024-04-18 12:00:00
', 1),
('Physical store revenue', 89.38, '2024-04-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240418-938.
Created by Miltos Karabasilis (id: 2) at 2024-04-18 12:00:00
', 1),
('E-shop revenue', 149.30, '2024-04-19', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240419-930.
Created by Miltos Karabasilis (id: 2) at 2024-04-19 12:00:00
', 1),
('Physical store revenue', 91.50, '2024-04-19', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240419-150.
Created by Miltos Karabasilis (id: 2) at 2024-04-19 12:00:00
', 1),
('E-shop revenue', 180.67, '2024-04-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240420-067.
Created by Miltos Karabasilis (id: 2) at 2024-04-20 12:00:00
', 1),
('Physical store revenue', 110.73, '2024-04-20', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240420-073.
Created by Miltos Karabasilis (id: 2) at 2024-04-20 12:00:00
', 1),
('E-shop revenue', 138.14, '2024-04-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240421-814.
Created by Miltos Karabasilis (id: 2) at 2024-04-21 12:00:00
', 1),
('Physical store revenue', 84.66, '2024-04-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240421-466.
Created by Miltos Karabasilis (id: 2) at 2024-04-21 12:00:00
', 1),
('E-shop revenue', 126.11, '2024-04-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240422-611.
Created by Miltos Karabasilis (id: 2) at 2024-04-22 12:00:00
', 1),
('Physical store revenue', 77.29, '2024-04-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240422-729.
Created by Miltos Karabasilis (id: 2) at 2024-04-22 12:00:00
', 1),
('E-shop revenue', 117.18, '2024-04-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240423-718.
Created by Miltos Karabasilis (id: 2) at 2024-04-23 12:00:00
', 1),
('Physical store revenue', 71.82, '2024-04-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240423-182.
Created by Miltos Karabasilis (id: 2) at 2024-04-23 12:00:00
', 1),
('E-shop revenue', 120.65, '2024-04-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240424-065.
Created by Miltos Karabasilis (id: 2) at 2024-04-24 12:00:00
', 1),
('Physical store revenue', 73.95, '2024-04-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240424-395.
Created by Miltos Karabasilis (id: 2) at 2024-04-24 12:00:00
', 1),
('E-shop revenue', 124.12, '2024-04-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240425-412.
Created by Miltos Karabasilis (id: 2) at 2024-04-25 12:00:00
', 1),
('Physical store revenue', 76.08, '2024-04-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240425-608.
Created by Miltos Karabasilis (id: 2) at 2024-04-25 12:00:00
', 1),
('E-shop revenue', 127.60, '2024-04-26', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240426-760.
Created by Miltos Karabasilis (id: 2) at 2024-04-26 12:00:00
', 1),
('Physical store revenue', 78.20, '2024-04-26', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240426-820.
Created by Miltos Karabasilis (id: 2) at 2024-04-26 12:00:00
', 1),
('E-shop revenue', 158.97, '2024-04-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240427-897.
Created by Miltos Karabasilis (id: 2) at 2024-04-27 12:00:00
', 1),
('Physical store revenue', 97.43, '2024-04-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240427-743.
Created by Miltos Karabasilis (id: 2) at 2024-04-27 12:00:00
', 1),
('E-shop revenue', 153.33, '2024-04-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240428-333.
Created by Miltos Karabasilis (id: 2) at 2024-04-28 12:00:00
', 1),
('Physical store revenue', 93.97, '2024-04-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240428-397.
Created by Miltos Karabasilis (id: 2) at 2024-04-28 12:00:00
', 1),
('E-shop revenue', 141.30, '2024-04-29', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240429-130.
Created by Miltos Karabasilis (id: 2) at 2024-04-29 12:00:00
', 1),
('Physical store revenue', 86.60, '2024-04-29', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240429-660.
Created by Miltos Karabasilis (id: 2) at 2024-04-29 12:00:00
', 1),
('E-shop revenue', 132.37, '2024-04-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240430-237.
Created by Miltos Karabasilis (id: 2) at 2024-04-30 12:00:00
', 1),
('Physical store revenue', 81.13, '2024-04-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240430-113.
Created by Miltos Karabasilis (id: 2) at 2024-04-30 12:00:00
', 1),
('E-shop revenue', 133.98, '2024-05-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240501-398.
Created by Miltos Karabasilis (id: 2) at 2024-05-01 12:00:00
', 1),
('Physical store revenue', 82.12, '2024-05-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240501-212.
Created by Miltos Karabasilis (id: 2) at 2024-05-01 12:00:00
', 1),
('E-shop revenue', 137.45, '2024-05-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240502-745.
Created by Miltos Karabasilis (id: 2) at 2024-05-02 12:00:00
', 1),
('Physical store revenue', 84.25, '2024-05-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240502-425.
Created by Miltos Karabasilis (id: 2) at 2024-05-02 12:00:00
', 1),
('E-shop revenue', 140.93, '2024-05-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240503-093.
Created by Miltos Karabasilis (id: 2) at 2024-05-03 12:00:00
', 1),
('Physical store revenue', 86.37, '2024-05-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240503-637.
Created by Miltos Karabasilis (id: 2) at 2024-05-03 12:00:00
', 1),
('E-shop revenue', 172.30, '2024-05-04', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20240504-230.
Created by Miltos Karabasilis (id: 2) at 2024-05-04 12:00:00
', 1),
('Physical store revenue', 105.60, '2024-05-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240504-560.
Created by Miltos Karabasilis (id: 2) at 2024-05-04 12:00:00
', 1),
('E-shop revenue', 175.77, '2024-05-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240505-577.
Created by Miltos Karabasilis (id: 2) at 2024-05-05 12:00:00
', 1),
('Physical store revenue', 107.73, '2024-05-05', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240505-773.
Created by Miltos Karabasilis (id: 2) at 2024-05-05 12:00:00
', 1),
('E-shop revenue', 163.74, '2024-05-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240506-374.
Created by Miltos Karabasilis (id: 2) at 2024-05-06 12:00:00
', 1),
('Physical store revenue', 100.36, '2024-05-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240506-036.
Created by Miltos Karabasilis (id: 2) at 2024-05-06 12:00:00
', 1),
('E-shop revenue', 145.70, '2024-05-07', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240507-570.
Created by Miltos Karabasilis (id: 2) at 2024-05-07 12:00:00
', 1),
('Physical store revenue', 89.30, '2024-05-07', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240507-930.
Created by Miltos Karabasilis (id: 2) at 2024-05-07 12:00:00
', 1),
('E-shop revenue', 112.28, '2024-05-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240508-228.
Created by Miltos Karabasilis (id: 2) at 2024-05-08 12:00:00
', 1),
('Physical store revenue', 68.82, '2024-05-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240508-882.
Created by Miltos Karabasilis (id: 2) at 2024-05-08 12:00:00
', 1),
('E-shop revenue', 115.75, '2024-05-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240509-575.
Created by Miltos Karabasilis (id: 2) at 2024-05-09 12:00:00
', 1),
('Physical store revenue', 70.95, '2024-05-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240509-095.
Created by Miltos Karabasilis (id: 2) at 2024-05-09 12:00:00
', 1),
('E-shop revenue', 119.23, '2024-05-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240510-923.
Created by Miltos Karabasilis (id: 2) at 2024-05-10 12:00:00
', 1),
('Physical store revenue', 73.07, '2024-05-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240510-307.
Created by Miltos Karabasilis (id: 2) at 2024-05-10 12:00:00
', 1),
('E-shop revenue', 150.60, '2024-05-11', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20240511-060.
Created by Miltos Karabasilis (id: 2) at 2024-05-11 12:00:00
', 1),
('Physical store revenue', 92.30, '2024-05-11', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240511-230.
Created by Miltos Karabasilis (id: 2) at 2024-05-11 12:00:00
', 1),
('E-shop revenue', 154.07, '2024-05-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240512-407.
Created by Miltos Karabasilis (id: 2) at 2024-05-12 12:00:00
', 1),
('Physical store revenue', 94.43, '2024-05-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240512-443.
Created by Miltos Karabasilis (id: 2) at 2024-05-12 12:00:00
', 1),
('E-shop revenue', 142.04, '2024-05-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240513-204.
Created by Miltos Karabasilis (id: 2) at 2024-05-13 12:00:00
', 1),
('Physical store revenue', 87.06, '2024-05-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240513-706.
Created by Miltos Karabasilis (id: 2) at 2024-05-13 12:00:00
', 1),
('E-shop revenue', 124.00, '2024-05-14', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20240514-400.
Created by Miltos Karabasilis (id: 2) at 2024-05-14 12:00:00
', 1),
('Physical store revenue', 76.00, '2024-05-14', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240514-600.
Created by Miltos Karabasilis (id: 2) at 2024-05-14 12:00:00
', 1),
('E-shop revenue', 127.47, '2024-05-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240515-747.
Created by Miltos Karabasilis (id: 2) at 2024-05-15 12:00:00
', 1),
('Physical store revenue', 78.13, '2024-05-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240515-813.
Created by Miltos Karabasilis (id: 2) at 2024-05-15 12:00:00
', 1),
('E-shop revenue', 130.94, '2024-05-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240516-094.
Created by Miltos Karabasilis (id: 2) at 2024-05-16 12:00:00
', 1),
('Physical store revenue', 80.26, '2024-05-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240516-026.
Created by Miltos Karabasilis (id: 2) at 2024-05-16 12:00:00
', 1),
('E-shop revenue', 134.42, '2024-05-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240517-442.
Created by Miltos Karabasilis (id: 2) at 2024-05-17 12:00:00
', 1),
('Physical store revenue', 82.38, '2024-05-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240517-238.
Created by Miltos Karabasilis (id: 2) at 2024-05-17 12:00:00
', 1),
('E-shop revenue', 165.79, '2024-05-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240518-579.
Created by Miltos Karabasilis (id: 2) at 2024-05-18 12:00:00
', 1),
('Physical store revenue', 101.61, '2024-05-18', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240518-161.
Created by Miltos Karabasilis (id: 2) at 2024-05-18 12:00:00
', 1),
('E-shop revenue', 169.26, '2024-05-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240519-926.
Created by Miltos Karabasilis (id: 2) at 2024-05-19 12:00:00
', 1),
('Physical store revenue', 103.74, '2024-05-19', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240519-374.
Created by Miltos Karabasilis (id: 2) at 2024-05-19 12:00:00
', 1),
('E-shop revenue', 157.23, '2024-05-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240520-723.
Created by Miltos Karabasilis (id: 2) at 2024-05-20 12:00:00
', 1),
('Physical store revenue', 96.37, '2024-05-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240520-637.
Created by Miltos Karabasilis (id: 2) at 2024-05-20 12:00:00
', 1),
('E-shop revenue', 139.19, '2024-05-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240521-919.
Created by Miltos Karabasilis (id: 2) at 2024-05-21 12:00:00
', 1),
('Physical store revenue', 85.31, '2024-05-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240521-531.
Created by Miltos Karabasilis (id: 2) at 2024-05-21 12:00:00
', 1),
('E-shop revenue', 142.66, '2024-05-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240522-266.
Created by Miltos Karabasilis (id: 2) at 2024-05-22 12:00:00
', 1),
('Physical store revenue', 87.44, '2024-05-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240522-744.
Created by Miltos Karabasilis (id: 2) at 2024-05-22 12:00:00
', 1),
('E-shop revenue', 146.13, '2024-05-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240523-613.
Created by Miltos Karabasilis (id: 2) at 2024-05-23 12:00:00
', 1),
('Physical store revenue', 89.57, '2024-05-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240523-957.
Created by Miltos Karabasilis (id: 2) at 2024-05-23 12:00:00
', 1),
('E-shop revenue', 149.61, '2024-05-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240524-961.
Created by Miltos Karabasilis (id: 2) at 2024-05-24 12:00:00
', 1),
('Physical store revenue', 91.69, '2024-05-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240524-169.
Created by Miltos Karabasilis (id: 2) at 2024-05-24 12:00:00
', 1),
('E-shop revenue', 144.09, '2024-05-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240525-409.
Created by Miltos Karabasilis (id: 2) at 2024-05-25 12:00:00
', 1),
('Physical store revenue', 88.31, '2024-05-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240525-831.
Created by Miltos Karabasilis (id: 2) at 2024-05-25 12:00:00
', 1),
('E-shop revenue', 147.56, '2024-05-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240526-756.
Created by Miltos Karabasilis (id: 2) at 2024-05-26 12:00:00
', 1),
('Physical store revenue', 90.44, '2024-05-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240526-044.
Created by Miltos Karabasilis (id: 2) at 2024-05-26 12:00:00
', 1),
('E-shop revenue', 135.53, '2024-05-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240527-553.
Created by Miltos Karabasilis (id: 2) at 2024-05-27 12:00:00
', 1),
('Physical store revenue', 83.07, '2024-05-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240527-307.
Created by Miltos Karabasilis (id: 2) at 2024-05-27 12:00:00
', 1),
('E-shop revenue', 117.49, '2024-05-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240528-749.
Created by Miltos Karabasilis (id: 2) at 2024-05-28 12:00:00
', 1),
('Physical store revenue', 72.01, '2024-05-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240528-201.
Created by Miltos Karabasilis (id: 2) at 2024-05-28 12:00:00
', 1),
('E-shop revenue', 120.96, '2024-05-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240529-096.
Created by Miltos Karabasilis (id: 2) at 2024-05-29 12:00:00
', 1),
('Physical store revenue', 74.14, '2024-05-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240529-414.
Created by Miltos Karabasilis (id: 2) at 2024-05-29 12:00:00
', 1),
('E-shop revenue', 124.43, '2024-05-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240530-443.
Created by Miltos Karabasilis (id: 2) at 2024-05-30 12:00:00
', 1),
('Physical store revenue', 76.27, '2024-05-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240530-627.
Created by Miltos Karabasilis (id: 2) at 2024-05-30 12:00:00
', 1),
('E-shop revenue', 127.91, '2024-05-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240531-791.
Created by Miltos Karabasilis (id: 2) at 2024-05-31 12:00:00
', 1),
('Physical store revenue', 78.39, '2024-05-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240531-839.
Created by Miltos Karabasilis (id: 2) at 2024-05-31 12:00:00
', 1),
('E-shop revenue', 156.12, '2024-06-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240601-612.
Created by Miltos Karabasilis (id: 2) at 2024-06-01 12:00:00
', 1),
('Physical store revenue', 95.68, '2024-06-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240601-568.
Created by Miltos Karabasilis (id: 2) at 2024-06-01 12:00:00
', 1),
('E-shop revenue', 159.59, '2024-06-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240602-959.
Created by Miltos Karabasilis (id: 2) at 2024-06-02 12:00:00
', 1),
('Physical store revenue', 97.81, '2024-06-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240602-781.
Created by Miltos Karabasilis (id: 2) at 2024-06-02 12:00:00
', 1),
('E-shop revenue', 147.56, '2024-06-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240603-756.
Created by Miltos Karabasilis (id: 2) at 2024-06-03 12:00:00
', 1),
('Physical store revenue', 90.44, '2024-06-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240603-044.
Created by Miltos Karabasilis (id: 2) at 2024-06-03 12:00:00
', 1),
('E-shop revenue', 138.63, '2024-06-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240604-863.
Created by Miltos Karabasilis (id: 2) at 2024-06-04 12:00:00
', 1),
('Physical store revenue', 84.97, '2024-06-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240604-497.
Created by Miltos Karabasilis (id: 2) at 2024-06-04 12:00:00
', 1),
('E-shop revenue', 142.10, '2024-06-05', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240605-210.
Created by Miltos Karabasilis (id: 2) at 2024-06-05 12:00:00
', 1),
('Physical store revenue', 87.10, '2024-06-05', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240605-710.
Created by Miltos Karabasilis (id: 2) at 2024-06-05 12:00:00
', 1),
('E-shop revenue', 145.58, '2024-06-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240606-558.
Created by Miltos Karabasilis (id: 2) at 2024-06-06 12:00:00
', 1),
('Physical store revenue', 89.22, '2024-06-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240606-922.
Created by Miltos Karabasilis (id: 2) at 2024-06-06 12:00:00
', 1),
('E-shop revenue', 139.93, '2024-06-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240607-993.
Created by Miltos Karabasilis (id: 2) at 2024-06-07 12:00:00
', 1),
('Physical store revenue', 85.77, '2024-06-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240607-577.
Created by Miltos Karabasilis (id: 2) at 2024-06-07 12:00:00
', 1),
('E-shop revenue', 171.31, '2024-06-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240608-131.
Created by Miltos Karabasilis (id: 2) at 2024-06-08 12:00:00
', 1),
('Physical store revenue', 104.99, '2024-06-08', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240608-499.
Created by Miltos Karabasilis (id: 2) at 2024-06-08 12:00:00
', 1),
('E-shop revenue', 174.78, '2024-06-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240609-478.
Created by Miltos Karabasilis (id: 2) at 2024-06-09 12:00:00
', 1),
('Physical store revenue', 107.12, '2024-06-09', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240609-712.
Created by Miltos Karabasilis (id: 2) at 2024-06-09 12:00:00
', 1),
('E-shop revenue', 162.75, '2024-06-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240610-275.
Created by Miltos Karabasilis (id: 2) at 2024-06-10 12:00:00
', 1),
('Physical store revenue', 99.75, '2024-06-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240610-975.
Created by Miltos Karabasilis (id: 2) at 2024-06-10 12:00:00
', 1),
('E-shop revenue', 116.93, '2024-06-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240611-693.
Created by Miltos Karabasilis (id: 2) at 2024-06-11 12:00:00
', 1),
('Physical store revenue', 71.67, '2024-06-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240611-167.
Created by Miltos Karabasilis (id: 2) at 2024-06-11 12:00:00
', 1),
('E-shop revenue', 120.40, '2024-06-12', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240612-040.
Created by Miltos Karabasilis (id: 2) at 2024-06-12 12:00:00
', 1),
('Physical store revenue', 73.80, '2024-06-12', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240612-380.
Created by Miltos Karabasilis (id: 2) at 2024-06-12 12:00:00
', 1),
('E-shop revenue', 123.88, '2024-06-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240613-388.
Created by Miltos Karabasilis (id: 2) at 2024-06-13 12:00:00
', 1),
('Physical store revenue', 75.92, '2024-06-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240613-592.
Created by Miltos Karabasilis (id: 2) at 2024-06-13 12:00:00
', 1),
('E-shop revenue', 118.23, '2024-06-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240614-823.
Created by Miltos Karabasilis (id: 2) at 2024-06-14 12:00:00
', 1),
('Physical store revenue', 72.47, '2024-06-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240614-247.
Created by Miltos Karabasilis (id: 2) at 2024-06-14 12:00:00
', 1),
('E-shop revenue', 149.61, '2024-06-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240615-961.
Created by Miltos Karabasilis (id: 2) at 2024-06-15 12:00:00
', 1),
('Physical store revenue', 91.69, '2024-06-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240615-169.
Created by Miltos Karabasilis (id: 2) at 2024-06-15 12:00:00
', 1),
('E-shop revenue', 153.08, '2024-06-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240616-308.
Created by Miltos Karabasilis (id: 2) at 2024-06-16 12:00:00
', 1),
('Physical store revenue', 93.82, '2024-06-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240616-382.
Created by Miltos Karabasilis (id: 2) at 2024-06-16 12:00:00
', 1),
('E-shop revenue', 141.05, '2024-06-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240617-105.
Created by Miltos Karabasilis (id: 2) at 2024-06-17 12:00:00
', 1),
('Physical store revenue', 86.45, '2024-06-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240617-645.
Created by Miltos Karabasilis (id: 2) at 2024-06-17 12:00:00
', 1),
('E-shop revenue', 132.12, '2024-06-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240618-212.
Created by Miltos Karabasilis (id: 2) at 2024-06-18 12:00:00
', 1),
('Physical store revenue', 80.98, '2024-06-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240618-098.
Created by Miltos Karabasilis (id: 2) at 2024-06-18 12:00:00
', 1),
('E-shop revenue', 135.59, '2024-06-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240619-559.
Created by Miltos Karabasilis (id: 2) at 2024-06-19 12:00:00
', 1),
('Physical store revenue', 83.11, '2024-06-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240619-311.
Created by Miltos Karabasilis (id: 2) at 2024-06-19 12:00:00
', 1),
('E-shop revenue', 139.07, '2024-06-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240620-907.
Created by Miltos Karabasilis (id: 2) at 2024-06-20 12:00:00
', 1),
('Physical store revenue', 85.23, '2024-06-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240620-523.
Created by Miltos Karabasilis (id: 2) at 2024-06-20 12:00:00
', 1),
('E-shop revenue', 133.42, '2024-06-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240621-342.
Created by Miltos Karabasilis (id: 2) at 2024-06-21 12:00:00
', 1),
('Physical store revenue', 81.78, '2024-06-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240621-178.
Created by Miltos Karabasilis (id: 2) at 2024-06-21 12:00:00
', 1),
('E-shop revenue', 164.80, '2024-06-22', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20240622-480.
Created by Miltos Karabasilis (id: 2) at 2024-06-22 12:00:00
', 1),
('Physical store revenue', 101.00, '2024-06-22', 'Physical shop revenue from cash and card transactions handled on site. Receipt batch POS-20240622-100.
Created by Miltos Karabasilis (id: 2) at 2024-06-22 12:00:00
', 1),
('E-shop revenue', 168.27, '2024-06-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240623-827.
Created by Miltos Karabasilis (id: 2) at 2024-06-23 12:00:00
', 1),
('Physical store revenue', 103.13, '2024-06-23', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240623-313.
Created by Miltos Karabasilis (id: 2) at 2024-06-23 12:00:00
', 1),
('E-shop revenue', 156.24, '2024-06-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240624-624.
Created by Miltos Karabasilis (id: 2) at 2024-06-24 12:00:00
', 1),
('Physical store revenue', 95.76, '2024-06-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240624-576.
Created by Miltos Karabasilis (id: 2) at 2024-06-24 12:00:00
', 1),
('E-shop revenue', 147.31, '2024-06-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240625-731.
Created by Miltos Karabasilis (id: 2) at 2024-06-25 12:00:00
', 1),
('Physical store revenue', 90.29, '2024-06-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240625-029.
Created by Miltos Karabasilis (id: 2) at 2024-06-25 12:00:00
', 1),
('E-shop revenue', 150.78, '2024-06-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240626-078.
Created by Miltos Karabasilis (id: 2) at 2024-06-26 12:00:00
', 1),
('Physical store revenue', 92.42, '2024-06-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240626-242.
Created by Miltos Karabasilis (id: 2) at 2024-06-26 12:00:00
', 1),
('E-shop revenue', 154.26, '2024-06-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240627-426.
Created by Miltos Karabasilis (id: 2) at 2024-06-27 12:00:00
', 1),
('Physical store revenue', 94.54, '2024-06-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240627-454.
Created by Miltos Karabasilis (id: 2) at 2024-06-27 12:00:00
', 1),
('E-shop revenue', 111.72, '2024-06-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240628-172.
Created by Miltos Karabasilis (id: 2) at 2024-06-28 12:00:00
', 1),
('Physical store revenue', 68.48, '2024-06-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240628-848.
Created by Miltos Karabasilis (id: 2) at 2024-06-28 12:00:00
', 1),
('E-shop revenue', 143.10, '2024-06-29', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20240629-310.
Created by Miltos Karabasilis (id: 2) at 2024-06-29 12:00:00
', 1),
('Physical store revenue', 87.70, '2024-06-29', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240629-770.
Created by Miltos Karabasilis (id: 2) at 2024-06-29 12:00:00
', 1),
('E-shop revenue', 146.57, '2024-06-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240630-657.
Created by Miltos Karabasilis (id: 2) at 2024-06-30 12:00:00
', 1),
('Physical store revenue', 89.83, '2024-06-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240630-983.
Created by Miltos Karabasilis (id: 2) at 2024-06-30 12:00:00
', 1),
('E-shop revenue', 132.68, '2024-07-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240701-268.
Created by Miltos Karabasilis (id: 2) at 2024-07-01 12:00:00
', 1),
('Physical store revenue', 81.32, '2024-07-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240701-132.
Created by Miltos Karabasilis (id: 2) at 2024-07-01 12:00:00
', 1),
('E-shop revenue', 123.75, '2024-07-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240702-375.
Created by Miltos Karabasilis (id: 2) at 2024-07-02 12:00:00
', 1),
('Physical store revenue', 75.85, '2024-07-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240702-585.
Created by Miltos Karabasilis (id: 2) at 2024-07-02 12:00:00
', 1),
('E-shop revenue', 127.22, '2024-07-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240703-722.
Created by Miltos Karabasilis (id: 2) at 2024-07-03 12:00:00
', 1),
('Physical store revenue', 77.98, '2024-07-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240703-798.
Created by Miltos Karabasilis (id: 2) at 2024-07-03 12:00:00
', 1),
('E-shop revenue', 130.70, '2024-07-04', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240704-070.
Created by Miltos Karabasilis (id: 2) at 2024-07-04 12:00:00
', 1),
('Physical store revenue', 80.10, '2024-07-04', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240704-010.
Created by Miltos Karabasilis (id: 2) at 2024-07-04 12:00:00
', 1),
('E-shop revenue', 134.17, '2024-07-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240705-417.
Created by Miltos Karabasilis (id: 2) at 2024-07-05 12:00:00
', 1),
('Physical store revenue', 82.23, '2024-07-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240705-223.
Created by Miltos Karabasilis (id: 2) at 2024-07-05 12:00:00
', 1),
('E-shop revenue', 165.54, '2024-07-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240706-554.
Created by Miltos Karabasilis (id: 2) at 2024-07-06 12:00:00
', 1),
('Physical store revenue', 101.46, '2024-07-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240706-146.
Created by Miltos Karabasilis (id: 2) at 2024-07-06 12:00:00
', 1),
('E-shop revenue', 159.90, '2024-07-07', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20240707-990.
Created by Miltos Karabasilis (id: 2) at 2024-07-07 12:00:00
', 1),
('Physical store revenue', 98.00, '2024-07-07', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240707-800.
Created by Miltos Karabasilis (id: 2) at 2024-07-07 12:00:00
', 1),
('E-shop revenue', 147.87, '2024-07-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240708-787.
Created by Miltos Karabasilis (id: 2) at 2024-07-08 12:00:00
', 1),
('Physical store revenue', 90.63, '2024-07-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240708-063.
Created by Miltos Karabasilis (id: 2) at 2024-07-08 12:00:00
', 1),
('E-shop revenue', 138.94, '2024-07-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240709-894.
Created by Miltos Karabasilis (id: 2) at 2024-07-09 12:00:00
', 1),
('Physical store revenue', 85.16, '2024-07-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240709-516.
Created by Miltos Karabasilis (id: 2) at 2024-07-09 12:00:00
', 1),
('E-shop revenue', 142.41, '2024-07-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240710-241.
Created by Miltos Karabasilis (id: 2) at 2024-07-10 12:00:00
', 1),
('Physical store revenue', 87.29, '2024-07-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240710-729.
Created by Miltos Karabasilis (id: 2) at 2024-07-10 12:00:00
', 1),
('E-shop revenue', 145.89, '2024-07-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240711-589.
Created by Miltos Karabasilis (id: 2) at 2024-07-11 12:00:00
', 1),
('Physical store revenue', 89.41, '2024-07-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240711-941.
Created by Miltos Karabasilis (id: 2) at 2024-07-11 12:00:00
', 1),
('E-shop revenue', 149.36, '2024-07-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240712-936.
Created by Miltos Karabasilis (id: 2) at 2024-07-12 12:00:00
', 1),
('Physical store revenue', 91.54, '2024-07-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240712-154.
Created by Miltos Karabasilis (id: 2) at 2024-07-12 12:00:00
', 1),
('E-shop revenue', 180.73, '2024-07-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240713-073.
Created by Miltos Karabasilis (id: 2) at 2024-07-13 12:00:00
', 1),
('Physical store revenue', 110.77, '2024-07-13', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240713-077.
Created by Miltos Karabasilis (id: 2) at 2024-07-13 12:00:00
', 1),
('E-shop revenue', 175.09, '2024-07-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240714-509.
Created by Miltos Karabasilis (id: 2) at 2024-07-14 12:00:00
', 1),
('Physical store revenue', 107.31, '2024-07-14', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240714-731.
Created by Miltos Karabasilis (id: 2) at 2024-07-14 12:00:00
', 1),
('E-shop revenue', 126.17, '2024-07-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240715-617.
Created by Miltos Karabasilis (id: 2) at 2024-07-15 12:00:00
', 1),
('Physical store revenue', 77.33, '2024-07-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240715-733.
Created by Miltos Karabasilis (id: 2) at 2024-07-15 12:00:00
', 1),
('E-shop revenue', 117.24, '2024-07-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240716-724.
Created by Miltos Karabasilis (id: 2) at 2024-07-16 12:00:00
', 1),
('Physical store revenue', 71.86, '2024-07-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240716-186.
Created by Miltos Karabasilis (id: 2) at 2024-07-16 12:00:00
', 1),
('E-shop revenue', 120.71, '2024-07-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240717-071.
Created by Miltos Karabasilis (id: 2) at 2024-07-17 12:00:00
', 1),
('Physical store revenue', 73.99, '2024-07-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240717-399.
Created by Miltos Karabasilis (id: 2) at 2024-07-17 12:00:00
', 1),
('E-shop revenue', 124.19, '2024-07-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240718-419.
Created by Miltos Karabasilis (id: 2) at 2024-07-18 12:00:00
', 1),
('Physical store revenue', 76.11, '2024-07-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240718-611.
Created by Miltos Karabasilis (id: 2) at 2024-07-18 12:00:00
', 1),
('E-shop revenue', 127.66, '2024-07-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240719-766.
Created by Miltos Karabasilis (id: 2) at 2024-07-19 12:00:00
', 1),
('Physical store revenue', 78.24, '2024-07-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240719-824.
Created by Miltos Karabasilis (id: 2) at 2024-07-19 12:00:00
', 1),
('E-shop revenue', 159.03, '2024-07-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240720-903.
Created by Miltos Karabasilis (id: 2) at 2024-07-20 12:00:00
', 1),
('Physical store revenue', 97.47, '2024-07-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240720-747.
Created by Miltos Karabasilis (id: 2) at 2024-07-20 12:00:00
', 1),
('E-shop revenue', 153.39, '2024-07-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240721-339.
Created by Miltos Karabasilis (id: 2) at 2024-07-21 12:00:00
', 1),
('Physical store revenue', 94.01, '2024-07-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240721-401.
Created by Miltos Karabasilis (id: 2) at 2024-07-21 12:00:00
', 1),
('E-shop revenue', 141.36, '2024-07-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240722-136.
Created by Miltos Karabasilis (id: 2) at 2024-07-22 12:00:00
', 1),
('Physical store revenue', 86.64, '2024-07-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240722-664.
Created by Miltos Karabasilis (id: 2) at 2024-07-22 12:00:00
', 1),
('E-shop revenue', 132.43, '2024-07-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240723-243.
Created by Miltos Karabasilis (id: 2) at 2024-07-23 12:00:00
', 1),
('Physical store revenue', 81.17, '2024-07-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240723-117.
Created by Miltos Karabasilis (id: 2) at 2024-07-23 12:00:00
', 1),
('E-shop revenue', 135.90, '2024-07-24', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240724-590.
Created by Miltos Karabasilis (id: 2) at 2024-07-24 12:00:00
', 1),
('Physical store revenue', 83.30, '2024-07-24', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240724-330.
Created by Miltos Karabasilis (id: 2) at 2024-07-24 12:00:00
', 1),
('E-shop revenue', 139.38, '2024-07-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240725-938.
Created by Miltos Karabasilis (id: 2) at 2024-07-25 12:00:00
', 1),
('Physical store revenue', 85.42, '2024-07-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240725-542.
Created by Miltos Karabasilis (id: 2) at 2024-07-25 12:00:00
', 1),
('E-shop revenue', 142.85, '2024-07-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240726-285.
Created by Miltos Karabasilis (id: 2) at 2024-07-26 12:00:00
', 1),
('Physical store revenue', 87.55, '2024-07-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240726-755.
Created by Miltos Karabasilis (id: 2) at 2024-07-26 12:00:00
', 1),
('E-shop revenue', 174.22, '2024-07-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240727-422.
Created by Miltos Karabasilis (id: 2) at 2024-07-27 12:00:00
', 1),
('Physical store revenue', 106.78, '2024-07-27', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240727-678.
Created by Miltos Karabasilis (id: 2) at 2024-07-27 12:00:00
', 1),
('E-shop revenue', 168.58, '2024-07-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240728-858.
Created by Miltos Karabasilis (id: 2) at 2024-07-28 12:00:00
', 1),
('Physical store revenue', 103.32, '2024-07-28', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240728-332.
Created by Miltos Karabasilis (id: 2) at 2024-07-28 12:00:00
', 1),
('E-shop revenue', 156.55, '2024-07-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240729-655.
Created by Miltos Karabasilis (id: 2) at 2024-07-29 12:00:00
', 1),
('Physical store revenue', 95.95, '2024-07-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240729-595.
Created by Miltos Karabasilis (id: 2) at 2024-07-29 12:00:00
', 1),
('E-shop revenue', 147.62, '2024-07-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240730-762.
Created by Miltos Karabasilis (id: 2) at 2024-07-30 12:00:00
', 1),
('Physical store revenue', 90.48, '2024-07-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240730-048.
Created by Miltos Karabasilis (id: 2) at 2024-07-30 12:00:00
', 1),
('E-shop revenue', 151.09, '2024-07-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240731-109.
Created by Miltos Karabasilis (id: 2) at 2024-07-31 12:00:00
', 1),
('Physical store revenue', 92.61, '2024-07-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240731-261.
Created by Miltos Karabasilis (id: 2) at 2024-07-31 12:00:00
', 1),
('E-shop revenue', 114.51, '2024-08-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240801-451.
Created by Miltos Karabasilis (id: 2) at 2024-08-01 12:00:00
', 1),
('Physical store revenue', 70.19, '2024-08-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240801-019.
Created by Miltos Karabasilis (id: 2) at 2024-08-01 12:00:00
', 1),
('E-shop revenue', 117.99, '2024-08-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240802-799.
Created by Miltos Karabasilis (id: 2) at 2024-08-02 12:00:00
', 1),
('Physical store revenue', 72.31, '2024-08-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240802-231.
Created by Miltos Karabasilis (id: 2) at 2024-08-02 12:00:00
', 1),
('E-shop revenue', 149.36, '2024-08-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240803-936.
Created by Miltos Karabasilis (id: 2) at 2024-08-03 12:00:00
', 1),
('Physical store revenue', 91.54, '2024-08-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240803-154.
Created by Miltos Karabasilis (id: 2) at 2024-08-03 12:00:00
', 1),
('E-shop revenue', 152.83, '2024-08-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240804-283.
Created by Miltos Karabasilis (id: 2) at 2024-08-04 12:00:00
', 1),
('Physical store revenue', 93.67, '2024-08-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240804-367.
Created by Miltos Karabasilis (id: 2) at 2024-08-04 12:00:00
', 1),
('E-shop revenue', 140.80, '2024-08-05', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240805-080.
Created by Miltos Karabasilis (id: 2) at 2024-08-05 12:00:00
', 1),
('Physical store revenue', 86.30, '2024-08-05', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240805-630.
Created by Miltos Karabasilis (id: 2) at 2024-08-05 12:00:00
', 1),
('E-shop revenue', 131.87, '2024-08-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240806-187.
Created by Miltos Karabasilis (id: 2) at 2024-08-06 12:00:00
', 1),
('Physical store revenue', 80.83, '2024-08-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240806-083.
Created by Miltos Karabasilis (id: 2) at 2024-08-06 12:00:00
', 1),
('E-shop revenue', 126.23, '2024-08-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240807-623.
Created by Miltos Karabasilis (id: 2) at 2024-08-07 12:00:00
', 1),
('Physical store revenue', 77.37, '2024-08-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240807-737.
Created by Miltos Karabasilis (id: 2) at 2024-08-07 12:00:00
', 1),
('E-shop revenue', 129.70, '2024-08-08', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240808-970.
Created by Miltos Karabasilis (id: 2) at 2024-08-08 12:00:00
', 1),
('Physical store revenue', 79.50, '2024-08-08', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240808-950.
Created by Miltos Karabasilis (id: 2) at 2024-08-08 12:00:00
', 1),
('E-shop revenue', 133.18, '2024-08-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240809-318.
Created by Miltos Karabasilis (id: 2) at 2024-08-09 12:00:00
', 1),
('Physical store revenue', 81.62, '2024-08-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240809-162.
Created by Miltos Karabasilis (id: 2) at 2024-08-09 12:00:00
', 1),
('E-shop revenue', 164.55, '2024-08-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240810-455.
Created by Miltos Karabasilis (id: 2) at 2024-08-10 12:00:00
', 1),
('Physical store revenue', 100.85, '2024-08-10', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240810-085.
Created by Miltos Karabasilis (id: 2) at 2024-08-10 12:00:00
', 1),
('E-shop revenue', 168.02, '2024-08-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240811-802.
Created by Miltos Karabasilis (id: 2) at 2024-08-11 12:00:00
', 1),
('Physical store revenue', 102.98, '2024-08-11', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240811-298.
Created by Miltos Karabasilis (id: 2) at 2024-08-11 12:00:00
', 1),
('E-shop revenue', 155.99, '2024-08-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240812-599.
Created by Miltos Karabasilis (id: 2) at 2024-08-12 12:00:00
', 1),
('Physical store revenue', 95.61, '2024-08-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240812-561.
Created by Miltos Karabasilis (id: 2) at 2024-08-12 12:00:00
', 1),
('E-shop revenue', 147.06, '2024-08-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240813-706.
Created by Miltos Karabasilis (id: 2) at 2024-08-13 12:00:00
', 1),
('Physical store revenue', 90.14, '2024-08-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240813-014.
Created by Miltos Karabasilis (id: 2) at 2024-08-13 12:00:00
', 1),
('E-shop revenue', 141.42, '2024-08-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240814-142.
Created by Miltos Karabasilis (id: 2) at 2024-08-14 12:00:00
', 1),
('Physical store revenue', 86.68, '2024-08-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240814-668.
Created by Miltos Karabasilis (id: 2) at 2024-08-14 12:00:00
', 1),
('E-shop revenue', 144.89, '2024-08-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240815-489.
Created by Miltos Karabasilis (id: 2) at 2024-08-15 12:00:00
', 1),
('Physical store revenue', 88.81, '2024-08-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240815-881.
Created by Miltos Karabasilis (id: 2) at 2024-08-15 12:00:00
', 1),
('E-shop revenue', 148.37, '2024-08-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240816-837.
Created by Miltos Karabasilis (id: 2) at 2024-08-16 12:00:00
', 1),
('Physical store revenue', 90.93, '2024-08-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240816-093.
Created by Miltos Karabasilis (id: 2) at 2024-08-16 12:00:00
', 1),
('E-shop revenue', 179.74, '2024-08-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240817-974.
Created by Miltos Karabasilis (id: 2) at 2024-08-17 12:00:00
', 1),
('Physical store revenue', 110.16, '2024-08-17', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240817-016.
Created by Miltos Karabasilis (id: 2) at 2024-08-17 12:00:00
', 1),
('E-shop revenue', 146.32, '2024-08-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240818-632.
Created by Miltos Karabasilis (id: 2) at 2024-08-18 12:00:00
', 1),
('Physical store revenue', 89.68, '2024-08-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240818-968.
Created by Miltos Karabasilis (id: 2) at 2024-08-18 12:00:00
', 1),
('E-shop revenue', 134.29, '2024-08-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240819-429.
Created by Miltos Karabasilis (id: 2) at 2024-08-19 12:00:00
', 1),
('Physical store revenue', 82.31, '2024-08-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240819-231.
Created by Miltos Karabasilis (id: 2) at 2024-08-19 12:00:00
', 1),
('E-shop revenue', 125.36, '2024-08-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240820-536.
Created by Miltos Karabasilis (id: 2) at 2024-08-20 12:00:00
', 1),
('Physical store revenue', 76.84, '2024-08-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240820-684.
Created by Miltos Karabasilis (id: 2) at 2024-08-20 12:00:00
', 1),
('E-shop revenue', 119.72, '2024-08-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240821-972.
Created by Miltos Karabasilis (id: 2) at 2024-08-21 12:00:00
', 1),
('Physical store revenue', 73.38, '2024-08-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240821-338.
Created by Miltos Karabasilis (id: 2) at 2024-08-21 12:00:00
', 1),
('E-shop revenue', 123.19, '2024-08-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240822-319.
Created by Miltos Karabasilis (id: 2) at 2024-08-22 12:00:00
', 1),
('Physical store revenue', 75.51, '2024-08-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240822-551.
Created by Miltos Karabasilis (id: 2) at 2024-08-22 12:00:00
', 1),
('E-shop revenue', 126.67, '2024-08-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240823-667.
Created by Miltos Karabasilis (id: 2) at 2024-08-23 12:00:00
', 1),
('Physical store revenue', 77.63, '2024-08-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240823-763.
Created by Miltos Karabasilis (id: 2) at 2024-08-23 12:00:00
', 1),
('E-shop revenue', 158.04, '2024-08-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240824-804.
Created by Miltos Karabasilis (id: 2) at 2024-08-24 12:00:00
', 1),
('Physical store revenue', 96.86, '2024-08-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240824-686.
Created by Miltos Karabasilis (id: 2) at 2024-08-24 12:00:00
', 1),
('E-shop revenue', 161.51, '2024-08-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240825-151.
Created by Miltos Karabasilis (id: 2) at 2024-08-25 12:00:00
', 1),
('Physical store revenue', 98.99, '2024-08-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240825-899.
Created by Miltos Karabasilis (id: 2) at 2024-08-25 12:00:00
', 1),
('E-shop revenue', 149.48, '2024-08-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240826-948.
Created by Miltos Karabasilis (id: 2) at 2024-08-26 12:00:00
', 1),
('Physical store revenue', 91.62, '2024-08-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240826-162.
Created by Miltos Karabasilis (id: 2) at 2024-08-26 12:00:00
', 1),
('E-shop revenue', 140.55, '2024-08-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240827-055.
Created by Miltos Karabasilis (id: 2) at 2024-08-27 12:00:00
', 1),
('Physical store revenue', 86.15, '2024-08-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240827-615.
Created by Miltos Karabasilis (id: 2) at 2024-08-27 12:00:00
', 1),
('E-shop revenue', 134.91, '2024-08-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240828-491.
Created by Miltos Karabasilis (id: 2) at 2024-08-28 12:00:00
', 1),
('Physical store revenue', 82.69, '2024-08-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240828-269.
Created by Miltos Karabasilis (id: 2) at 2024-08-28 12:00:00
', 1),
('E-shop revenue', 138.38, '2024-08-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240829-838.
Created by Miltos Karabasilis (id: 2) at 2024-08-29 12:00:00
', 1),
('Physical store revenue', 84.82, '2024-08-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240829-482.
Created by Miltos Karabasilis (id: 2) at 2024-08-29 12:00:00
', 1),
('E-shop revenue', 141.86, '2024-08-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240830-186.
Created by Miltos Karabasilis (id: 2) at 2024-08-30 12:00:00
', 1),
('Physical store revenue', 86.94, '2024-08-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240830-694.
Created by Miltos Karabasilis (id: 2) at 2024-08-30 12:00:00
', 1),
('E-shop revenue', 173.23, '2024-08-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240831-323.
Created by Miltos Karabasilis (id: 2) at 2024-08-31 12:00:00
', 1),
('Physical store revenue', 106.17, '2024-08-31', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240831-617.
Created by Miltos Karabasilis (id: 2) at 2024-08-31 12:00:00
', 1),
('E-shop revenue', 173.54, '2024-09-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240901-354.
Created by Miltos Karabasilis (id: 2) at 2024-09-01 12:00:00
', 1),
('Physical store revenue', 106.36, '2024-09-01', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240901-636.
Created by Miltos Karabasilis (id: 2) at 2024-09-01 12:00:00
', 1),
('E-shop revenue', 161.51, '2024-09-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240902-151.
Created by Miltos Karabasilis (id: 2) at 2024-09-02 12:00:00
', 1),
('Physical store revenue', 98.99, '2024-09-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240902-899.
Created by Miltos Karabasilis (id: 2) at 2024-09-02 12:00:00
', 1),
('E-shop revenue', 152.58, '2024-09-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240903-258.
Created by Miltos Karabasilis (id: 2) at 2024-09-03 12:00:00
', 1),
('Physical store revenue', 93.52, '2024-09-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240903-352.
Created by Miltos Karabasilis (id: 2) at 2024-09-03 12:00:00
', 1),
('E-shop revenue', 119.16, '2024-09-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240904-916.
Created by Miltos Karabasilis (id: 2) at 2024-09-04 12:00:00
', 1),
('Physical store revenue', 73.04, '2024-09-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240904-304.
Created by Miltos Karabasilis (id: 2) at 2024-09-04 12:00:00
', 1),
('E-shop revenue', 122.64, '2024-09-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240905-264.
Created by Miltos Karabasilis (id: 2) at 2024-09-05 12:00:00
', 1),
('Physical store revenue', 75.16, '2024-09-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240905-516.
Created by Miltos Karabasilis (id: 2) at 2024-09-05 12:00:00
', 1),
('E-shop revenue', 126.11, '2024-09-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240906-611.
Created by Miltos Karabasilis (id: 2) at 2024-09-06 12:00:00
', 1),
('Physical store revenue', 77.29, '2024-09-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240906-729.
Created by Miltos Karabasilis (id: 2) at 2024-09-06 12:00:00
', 1),
('E-shop revenue', 148.37, '2024-09-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240907-837.
Created by Miltos Karabasilis (id: 2) at 2024-09-07 12:00:00
', 1),
('Physical store revenue', 90.93, '2024-09-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240907-093.
Created by Miltos Karabasilis (id: 2) at 2024-09-07 12:00:00
', 1),
('E-shop revenue', 151.84, '2024-09-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240908-184.
Created by Miltos Karabasilis (id: 2) at 2024-09-08 12:00:00
', 1),
('Physical store revenue', 93.06, '2024-09-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240908-306.
Created by Miltos Karabasilis (id: 2) at 2024-09-08 12:00:00
', 1),
('E-shop revenue', 139.81, '2024-09-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240909-981.
Created by Miltos Karabasilis (id: 2) at 2024-09-09 12:00:00
', 1),
('Physical store revenue', 85.69, '2024-09-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240909-569.
Created by Miltos Karabasilis (id: 2) at 2024-09-09 12:00:00
', 1),
('E-shop revenue', 130.88, '2024-09-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240910-088.
Created by Miltos Karabasilis (id: 2) at 2024-09-10 12:00:00
', 1),
('Physical store revenue', 80.22, '2024-09-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240910-022.
Created by Miltos Karabasilis (id: 2) at 2024-09-10 12:00:00
', 1),
('E-shop revenue', 134.35, '2024-09-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240911-435.
Created by Miltos Karabasilis (id: 2) at 2024-09-11 12:00:00
', 1),
('Physical store revenue', 82.35, '2024-09-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240911-235.
Created by Miltos Karabasilis (id: 2) at 2024-09-11 12:00:00
', 1),
('E-shop revenue', 137.83, '2024-09-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240912-783.
Created by Miltos Karabasilis (id: 2) at 2024-09-12 12:00:00
', 1),
('Physical store revenue', 84.47, '2024-09-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240912-447.
Created by Miltos Karabasilis (id: 2) at 2024-09-12 12:00:00
', 1),
('E-shop revenue', 141.30, '2024-09-13', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240913-130.
Created by Miltos Karabasilis (id: 2) at 2024-09-13 12:00:00
', 1),
('Physical store revenue', 86.60, '2024-09-13', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240913-660.
Created by Miltos Karabasilis (id: 2) at 2024-09-13 12:00:00
', 1),
('E-shop revenue', 163.56, '2024-09-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240914-356.
Created by Miltos Karabasilis (id: 2) at 2024-09-14 12:00:00
', 1),
('Physical store revenue', 100.24, '2024-09-14', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240914-024.
Created by Miltos Karabasilis (id: 2) at 2024-09-14 12:00:00
', 1),
('E-shop revenue', 167.03, '2024-09-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240915-703.
Created by Miltos Karabasilis (id: 2) at 2024-09-15 12:00:00
', 1),
('Physical store revenue', 102.37, '2024-09-15', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240915-237.
Created by Miltos Karabasilis (id: 2) at 2024-09-15 12:00:00
', 1),
('E-shop revenue', 155.00, '2024-09-16', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20240916-500.
Created by Miltos Karabasilis (id: 2) at 2024-09-16 12:00:00
', 1),
('Physical store revenue', 95.00, '2024-09-16', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20240916-500.
Created by Miltos Karabasilis (id: 2) at 2024-09-16 12:00:00
', 1),
('E-shop revenue', 146.07, '2024-09-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240917-607.
Created by Miltos Karabasilis (id: 2) at 2024-09-17 12:00:00
', 1),
('Physical store revenue', 89.53, '2024-09-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240917-953.
Created by Miltos Karabasilis (id: 2) at 2024-09-17 12:00:00
', 1),
('E-shop revenue', 149.54, '2024-09-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240918-954.
Created by Miltos Karabasilis (id: 2) at 2024-09-18 12:00:00
', 1),
('Physical store revenue', 91.66, '2024-09-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240918-166.
Created by Miltos Karabasilis (id: 2) at 2024-09-18 12:00:00
', 1),
('E-shop revenue', 153.02, '2024-09-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240919-302.
Created by Miltos Karabasilis (id: 2) at 2024-09-19 12:00:00
', 1),
('Physical store revenue', 93.78, '2024-09-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240919-378.
Created by Miltos Karabasilis (id: 2) at 2024-09-19 12:00:00
', 1),
('E-shop revenue', 156.49, '2024-09-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240920-649.
Created by Miltos Karabasilis (id: 2) at 2024-09-20 12:00:00
', 1),
('Physical store revenue', 95.91, '2024-09-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240920-591.
Created by Miltos Karabasilis (id: 2) at 2024-09-20 12:00:00
', 1),
('E-shop revenue', 141.86, '2024-09-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240921-186.
Created by Miltos Karabasilis (id: 2) at 2024-09-21 12:00:00
', 1),
('Physical store revenue', 86.94, '2024-09-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240921-694.
Created by Miltos Karabasilis (id: 2) at 2024-09-21 12:00:00
', 1),
('E-shop revenue', 145.33, '2024-09-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240922-533.
Created by Miltos Karabasilis (id: 2) at 2024-09-22 12:00:00
', 1),
('Physical store revenue', 89.07, '2024-09-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240922-907.
Created by Miltos Karabasilis (id: 2) at 2024-09-22 12:00:00
', 1),
('E-shop revenue', 133.30, '2024-09-23', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20240923-330.
Created by Miltos Karabasilis (id: 2) at 2024-09-23 12:00:00
', 1),
('Physical store revenue', 81.70, '2024-09-23', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20240923-170.
Created by Miltos Karabasilis (id: 2) at 2024-09-23 12:00:00
', 1),
('E-shop revenue', 124.37, '2024-09-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240924-437.
Created by Miltos Karabasilis (id: 2) at 2024-09-24 12:00:00
', 1),
('Physical store revenue', 76.23, '2024-09-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240924-623.
Created by Miltos Karabasilis (id: 2) at 2024-09-24 12:00:00
', 1),
('E-shop revenue', 127.84, '2024-09-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240925-784.
Created by Miltos Karabasilis (id: 2) at 2024-09-25 12:00:00
', 1),
('Physical store revenue', 78.36, '2024-09-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240925-836.
Created by Miltos Karabasilis (id: 2) at 2024-09-25 12:00:00
', 1),
('E-shop revenue', 131.32, '2024-09-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240926-132.
Created by Miltos Karabasilis (id: 2) at 2024-09-26 12:00:00
', 1),
('Physical store revenue', 80.48, '2024-09-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240926-048.
Created by Miltos Karabasilis (id: 2) at 2024-09-26 12:00:00
', 1),
('E-shop revenue', 134.79, '2024-09-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240927-479.
Created by Miltos Karabasilis (id: 2) at 2024-09-27 12:00:00
', 1),
('Physical store revenue', 82.61, '2024-09-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240927-261.
Created by Miltos Karabasilis (id: 2) at 2024-09-27 12:00:00
', 1),
('E-shop revenue', 157.05, '2024-09-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240928-705.
Created by Miltos Karabasilis (id: 2) at 2024-09-28 12:00:00
', 1),
('Physical store revenue', 96.25, '2024-09-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240928-625.
Created by Miltos Karabasilis (id: 2) at 2024-09-28 12:00:00
', 1),
('E-shop revenue', 160.52, '2024-09-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20240929-052.
Created by Miltos Karabasilis (id: 2) at 2024-09-29 12:00:00
', 1),
('Physical store revenue', 98.38, '2024-09-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240929-838.
Created by Miltos Karabasilis (id: 2) at 2024-09-29 12:00:00
', 1),
('E-shop revenue', 148.49, '2024-09-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20240930-849.
Created by Miltos Karabasilis (id: 2) at 2024-09-30 12:00:00
', 1),
('Physical store revenue', 91.01, '2024-09-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20240930-101.
Created by Miltos Karabasilis (id: 2) at 2024-09-30 12:00:00
', 1),
('E-shop revenue', 137.70, '2024-10-01', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20241001-770.
Created by Miltos Karabasilis (id: 2) at 2024-10-01 12:00:00
', 1),
('Physical store revenue', 84.40, '2024-10-01', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20241001-440.
Created by Miltos Karabasilis (id: 2) at 2024-10-01 12:00:00
', 1),
('E-shop revenue', 141.17, '2024-10-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241002-117.
Created by Miltos Karabasilis (id: 2) at 2024-10-02 12:00:00
', 1),
('Physical store revenue', 86.53, '2024-10-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241002-653.
Created by Miltos Karabasilis (id: 2) at 2024-10-02 12:00:00
', 1),
('E-shop revenue', 144.65, '2024-10-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241003-465.
Created by Miltos Karabasilis (id: 2) at 2024-10-03 12:00:00
', 1),
('Physical store revenue', 88.65, '2024-10-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241003-865.
Created by Miltos Karabasilis (id: 2) at 2024-10-03 12:00:00
', 1),
('E-shop revenue', 148.12, '2024-10-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241004-812.
Created by Miltos Karabasilis (id: 2) at 2024-10-04 12:00:00
', 1),
('Physical store revenue', 90.78, '2024-10-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241004-078.
Created by Miltos Karabasilis (id: 2) at 2024-10-04 12:00:00
', 1),
('E-shop revenue', 179.49, '2024-10-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241005-949.
Created by Miltos Karabasilis (id: 2) at 2024-10-05 12:00:00
', 1),
('Physical store revenue', 110.01, '2024-10-05', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241005-001.
Created by Miltos Karabasilis (id: 2) at 2024-10-05 12:00:00
', 1),
('E-shop revenue', 182.96, '2024-10-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241006-296.
Created by Miltos Karabasilis (id: 2) at 2024-10-06 12:00:00
', 1),
('Physical store revenue', 112.14, '2024-10-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241006-214.
Created by Miltos Karabasilis (id: 2) at 2024-10-06 12:00:00
', 1),
('E-shop revenue', 161.82, '2024-10-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241007-182.
Created by Miltos Karabasilis (id: 2) at 2024-10-07 12:00:00
', 1),
('Physical store revenue', 99.18, '2024-10-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241007-918.
Created by Miltos Karabasilis (id: 2) at 2024-10-07 12:00:00
', 1),
('E-shop revenue', 116.00, '2024-10-08', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20241008-600.
Created by Miltos Karabasilis (id: 2) at 2024-10-08 12:00:00
', 1),
('Physical store revenue', 71.10, '2024-10-08', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20241008-110.
Created by Miltos Karabasilis (id: 2) at 2024-10-08 12:00:00
', 1),
('E-shop revenue', 119.47, '2024-10-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241009-947.
Created by Miltos Karabasilis (id: 2) at 2024-10-09 12:00:00
', 1),
('Physical store revenue', 73.23, '2024-10-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241009-323.
Created by Miltos Karabasilis (id: 2) at 2024-10-09 12:00:00
', 1),
('E-shop revenue', 122.95, '2024-10-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241010-295.
Created by Miltos Karabasilis (id: 2) at 2024-10-10 12:00:00
', 1),
('Physical store revenue', 75.35, '2024-10-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241010-535.
Created by Miltos Karabasilis (id: 2) at 2024-10-10 12:00:00
', 1),
('E-shop revenue', 126.42, '2024-10-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241011-642.
Created by Miltos Karabasilis (id: 2) at 2024-10-11 12:00:00
', 1),
('Physical store revenue', 77.48, '2024-10-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241011-748.
Created by Miltos Karabasilis (id: 2) at 2024-10-11 12:00:00
', 1),
('E-shop revenue', 157.79, '2024-10-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241012-779.
Created by Miltos Karabasilis (id: 2) at 2024-10-12 12:00:00
', 1),
('Physical store revenue', 96.71, '2024-10-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241012-671.
Created by Miltos Karabasilis (id: 2) at 2024-10-12 12:00:00
', 1),
('E-shop revenue', 161.26, '2024-10-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241013-126.
Created by Miltos Karabasilis (id: 2) at 2024-10-13 12:00:00
', 1),
('Physical store revenue', 98.84, '2024-10-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241013-884.
Created by Miltos Karabasilis (id: 2) at 2024-10-13 12:00:00
', 1),
('E-shop revenue', 140.12, '2024-10-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241014-012.
Created by Miltos Karabasilis (id: 2) at 2024-10-14 12:00:00
', 1),
('Physical store revenue', 85.88, '2024-10-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241014-588.
Created by Miltos Karabasilis (id: 2) at 2024-10-14 12:00:00
', 1),
('E-shop revenue', 131.19, '2024-10-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241015-119.
Created by Miltos Karabasilis (id: 2) at 2024-10-15 12:00:00
', 1),
('Physical store revenue', 80.41, '2024-10-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241015-041.
Created by Miltos Karabasilis (id: 2) at 2024-10-15 12:00:00
', 1),
('E-shop revenue', 134.66, '2024-10-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241016-466.
Created by Miltos Karabasilis (id: 2) at 2024-10-16 12:00:00
', 1),
('Physical store revenue', 82.54, '2024-10-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241016-254.
Created by Miltos Karabasilis (id: 2) at 2024-10-16 12:00:00
', 1),
('E-shop revenue', 138.14, '2024-10-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241017-814.
Created by Miltos Karabasilis (id: 2) at 2024-10-17 12:00:00
', 1),
('Physical store revenue', 84.66, '2024-10-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241017-466.
Created by Miltos Karabasilis (id: 2) at 2024-10-17 12:00:00
', 1),
('E-shop revenue', 141.61, '2024-10-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241018-161.
Created by Miltos Karabasilis (id: 2) at 2024-10-18 12:00:00
', 1),
('Physical store revenue', 86.79, '2024-10-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241018-679.
Created by Miltos Karabasilis (id: 2) at 2024-10-18 12:00:00
', 1),
('E-shop revenue', 172.98, '2024-10-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241019-298.
Created by Miltos Karabasilis (id: 2) at 2024-10-19 12:00:00
', 1),
('Physical store revenue', 106.02, '2024-10-19', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241019-602.
Created by Miltos Karabasilis (id: 2) at 2024-10-19 12:00:00
', 1),
('E-shop revenue', 176.45, '2024-10-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241020-645.
Created by Miltos Karabasilis (id: 2) at 2024-10-20 12:00:00
', 1),
('Physical store revenue', 108.15, '2024-10-20', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241020-815.
Created by Miltos Karabasilis (id: 2) at 2024-10-20 12:00:00
', 1),
('E-shop revenue', 155.31, '2024-10-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241021-531.
Created by Miltos Karabasilis (id: 2) at 2024-10-21 12:00:00
', 1),
('Physical store revenue', 95.19, '2024-10-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241021-519.
Created by Miltos Karabasilis (id: 2) at 2024-10-21 12:00:00
', 1),
('E-shop revenue', 146.38, '2024-10-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241022-638.
Created by Miltos Karabasilis (id: 2) at 2024-10-22 12:00:00
', 1),
('Physical store revenue', 89.72, '2024-10-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241022-972.
Created by Miltos Karabasilis (id: 2) at 2024-10-22 12:00:00
', 1),
('E-shop revenue', 149.85, '2024-10-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241023-985.
Created by Miltos Karabasilis (id: 2) at 2024-10-23 12:00:00
', 1),
('Physical store revenue', 91.85, '2024-10-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241023-185.
Created by Miltos Karabasilis (id: 2) at 2024-10-23 12:00:00
', 1),
('E-shop revenue', 153.33, '2024-10-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241024-333.
Created by Miltos Karabasilis (id: 2) at 2024-10-24 12:00:00
', 1),
('Physical store revenue', 93.97, '2024-10-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241024-397.
Created by Miltos Karabasilis (id: 2) at 2024-10-24 12:00:00
', 1),
('E-shop revenue', 119.91, '2024-10-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241025-991.
Created by Miltos Karabasilis (id: 2) at 2024-10-25 12:00:00
', 1),
('Physical store revenue', 73.49, '2024-10-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241025-349.
Created by Miltos Karabasilis (id: 2) at 2024-10-25 12:00:00
', 1),
('E-shop revenue', 151.28, '2024-10-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241026-128.
Created by Miltos Karabasilis (id: 2) at 2024-10-26 12:00:00
', 1),
('Physical store revenue', 92.72, '2024-10-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241026-272.
Created by Miltos Karabasilis (id: 2) at 2024-10-26 12:00:00
', 1),
('E-shop revenue', 154.75, '2024-10-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241027-475.
Created by Miltos Karabasilis (id: 2) at 2024-10-27 12:00:00
', 1),
('Physical store revenue', 94.85, '2024-10-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241027-485.
Created by Miltos Karabasilis (id: 2) at 2024-10-27 12:00:00
', 1),
('E-shop revenue', 133.61, '2024-10-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241028-361.
Created by Miltos Karabasilis (id: 2) at 2024-10-28 12:00:00
', 1),
('Physical store revenue', 81.89, '2024-10-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241028-189.
Created by Miltos Karabasilis (id: 2) at 2024-10-28 12:00:00
', 1),
('E-shop revenue', 124.68, '2024-10-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241029-468.
Created by Miltos Karabasilis (id: 2) at 2024-10-29 12:00:00
', 1),
('Physical store revenue', 76.42, '2024-10-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241029-642.
Created by Miltos Karabasilis (id: 2) at 2024-10-29 12:00:00
', 1),
('E-shop revenue', 128.15, '2024-10-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241030-815.
Created by Miltos Karabasilis (id: 2) at 2024-10-30 12:00:00
', 1),
('Physical store revenue', 78.55, '2024-10-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241030-855.
Created by Miltos Karabasilis (id: 2) at 2024-10-30 12:00:00
', 1),
('E-shop revenue', 131.63, '2024-10-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241031-163.
Created by Miltos Karabasilis (id: 2) at 2024-10-31 12:00:00
', 1),
('Physical store revenue', 80.67, '2024-10-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241031-067.
Created by Miltos Karabasilis (id: 2) at 2024-10-31 12:00:00
', 1),
('E-shop revenue', 131.94, '2024-11-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241101-194.
Created by Miltos Karabasilis (id: 2) at 2024-11-01 12:00:00
', 1),
('Physical store revenue', 80.86, '2024-11-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241101-086.
Created by Miltos Karabasilis (id: 2) at 2024-11-01 12:00:00
', 1),
('E-shop revenue', 163.31, '2024-11-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241102-331.
Created by Miltos Karabasilis (id: 2) at 2024-11-02 12:00:00
', 1),
('Physical store revenue', 100.09, '2024-11-02', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241102-009.
Created by Miltos Karabasilis (id: 2) at 2024-11-02 12:00:00
', 1),
('E-shop revenue', 166.78, '2024-11-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241103-678.
Created by Miltos Karabasilis (id: 2) at 2024-11-03 12:00:00
', 1),
('Physical store revenue', 102.22, '2024-11-03', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241103-222.
Created by Miltos Karabasilis (id: 2) at 2024-11-03 12:00:00
', 1),
('E-shop revenue', 154.75, '2024-11-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241104-475.
Created by Miltos Karabasilis (id: 2) at 2024-11-04 12:00:00
', 1),
('Physical store revenue', 94.85, '2024-11-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241104-485.
Created by Miltos Karabasilis (id: 2) at 2024-11-04 12:00:00
', 1),
('E-shop revenue', 145.82, '2024-11-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241105-582.
Created by Miltos Karabasilis (id: 2) at 2024-11-05 12:00:00
', 1),
('Physical store revenue', 89.38, '2024-11-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241105-938.
Created by Miltos Karabasilis (id: 2) at 2024-11-05 12:00:00
', 1),
('E-shop revenue', 149.30, '2024-11-06', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20241106-930.
Created by Miltos Karabasilis (id: 2) at 2024-11-06 12:00:00
', 1),
('Physical store revenue', 91.50, '2024-11-06', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20241106-150.
Created by Miltos Karabasilis (id: 2) at 2024-11-06 12:00:00
', 1),
('E-shop revenue', 143.65, '2024-11-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241107-365.
Created by Miltos Karabasilis (id: 2) at 2024-11-07 12:00:00
', 1),
('Physical store revenue', 88.05, '2024-11-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241107-805.
Created by Miltos Karabasilis (id: 2) at 2024-11-07 12:00:00
', 1),
('E-shop revenue', 147.13, '2024-11-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241108-713.
Created by Miltos Karabasilis (id: 2) at 2024-11-08 12:00:00
', 1),
('Physical store revenue', 90.17, '2024-11-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241108-017.
Created by Miltos Karabasilis (id: 2) at 2024-11-08 12:00:00
', 1),
('E-shop revenue', 178.50, '2024-11-09', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20241109-850.
Created by Miltos Karabasilis (id: 2) at 2024-11-09 12:00:00
', 1),
('Physical store revenue', 109.40, '2024-11-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241109-940.
Created by Miltos Karabasilis (id: 2) at 2024-11-09 12:00:00
', 1),
('E-shop revenue', 181.97, '2024-11-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241110-197.
Created by Miltos Karabasilis (id: 2) at 2024-11-10 12:00:00
', 1),
('Physical store revenue', 111.53, '2024-11-10', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241110-153.
Created by Miltos Karabasilis (id: 2) at 2024-11-10 12:00:00
', 1),
('E-shop revenue', 133.05, '2024-11-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241111-305.
Created by Miltos Karabasilis (id: 2) at 2024-11-11 12:00:00
', 1),
('Physical store revenue', 81.55, '2024-11-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241111-155.
Created by Miltos Karabasilis (id: 2) at 2024-11-11 12:00:00
', 1),
('E-shop revenue', 124.12, '2024-11-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241112-412.
Created by Miltos Karabasilis (id: 2) at 2024-11-12 12:00:00
', 1),
('Physical store revenue', 76.08, '2024-11-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241112-608.
Created by Miltos Karabasilis (id: 2) at 2024-11-12 12:00:00
', 1),
('E-shop revenue', 127.60, '2024-11-13', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20241113-760.
Created by Miltos Karabasilis (id: 2) at 2024-11-13 12:00:00
', 1),
('Physical store revenue', 78.20, '2024-11-13', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20241113-820.
Created by Miltos Karabasilis (id: 2) at 2024-11-13 12:00:00
', 1),
('E-shop revenue', 121.95, '2024-11-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241114-195.
Created by Miltos Karabasilis (id: 2) at 2024-11-14 12:00:00
', 1),
('Physical store revenue', 74.75, '2024-11-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241114-475.
Created by Miltos Karabasilis (id: 2) at 2024-11-14 12:00:00
', 1),
('E-shop revenue', 125.43, '2024-11-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241115-543.
Created by Miltos Karabasilis (id: 2) at 2024-11-15 12:00:00
', 1),
('Physical store revenue', 76.87, '2024-11-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241115-687.
Created by Miltos Karabasilis (id: 2) at 2024-11-15 12:00:00
', 1),
('E-shop revenue', 156.80, '2024-11-16', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20241116-680.
Created by Miltos Karabasilis (id: 2) at 2024-11-16 12:00:00
', 1),
('Physical store revenue', 96.10, '2024-11-16', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20241116-610.
Created by Miltos Karabasilis (id: 2) at 2024-11-16 12:00:00
', 1),
('E-shop revenue', 160.27, '2024-11-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241117-027.
Created by Miltos Karabasilis (id: 2) at 2024-11-17 12:00:00
', 1),
('Physical store revenue', 98.23, '2024-11-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241117-823.
Created by Miltos Karabasilis (id: 2) at 2024-11-17 12:00:00
', 1),
('E-shop revenue', 148.24, '2024-11-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241118-824.
Created by Miltos Karabasilis (id: 2) at 2024-11-18 12:00:00
', 1),
('Physical store revenue', 90.86, '2024-11-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241118-086.
Created by Miltos Karabasilis (id: 2) at 2024-11-18 12:00:00
', 1),
('E-shop revenue', 139.31, '2024-11-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241119-931.
Created by Miltos Karabasilis (id: 2) at 2024-11-19 12:00:00
', 1),
('Physical store revenue', 85.39, '2024-11-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241119-539.
Created by Miltos Karabasilis (id: 2) at 2024-11-19 12:00:00
', 1),
('E-shop revenue', 142.79, '2024-11-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241120-279.
Created by Miltos Karabasilis (id: 2) at 2024-11-20 12:00:00
', 1),
('Physical store revenue', 87.51, '2024-11-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241120-751.
Created by Miltos Karabasilis (id: 2) at 2024-11-20 12:00:00
', 1),
('E-shop revenue', 137.14, '2024-11-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241121-714.
Created by Miltos Karabasilis (id: 2) at 2024-11-21 12:00:00
', 1),
('Physical store revenue', 84.06, '2024-11-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241121-406.
Created by Miltos Karabasilis (id: 2) at 2024-11-21 12:00:00
', 1),
('E-shop revenue', 140.62, '2024-11-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241122-062.
Created by Miltos Karabasilis (id: 2) at 2024-11-22 12:00:00
', 1),
('Physical store revenue', 86.18, '2024-11-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241122-618.
Created by Miltos Karabasilis (id: 2) at 2024-11-22 12:00:00
', 1),
('E-shop revenue', 171.99, '2024-11-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241123-199.
Created by Miltos Karabasilis (id: 2) at 2024-11-23 12:00:00
', 1),
('Physical store revenue', 105.41, '2024-11-23', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241123-541.
Created by Miltos Karabasilis (id: 2) at 2024-11-23 12:00:00
', 1),
('E-shop revenue', 175.46, '2024-11-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241124-546.
Created by Miltos Karabasilis (id: 2) at 2024-11-24 12:00:00
', 1),
('Physical store revenue', 107.54, '2024-11-24', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241124-754.
Created by Miltos Karabasilis (id: 2) at 2024-11-24 12:00:00
', 1),
('E-shop revenue', 163.43, '2024-11-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241125-343.
Created by Miltos Karabasilis (id: 2) at 2024-11-25 12:00:00
', 1),
('Physical store revenue', 100.17, '2024-11-25', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241125-017.
Created by Miltos Karabasilis (id: 2) at 2024-11-25 12:00:00
', 1),
('E-shop revenue', 154.50, '2024-11-26', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20241126-450.
Created by Miltos Karabasilis (id: 2) at 2024-11-26 12:00:00
', 1),
('Physical store revenue', 94.70, '2024-11-26', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20241126-470.
Created by Miltos Karabasilis (id: 2) at 2024-11-26 12:00:00
', 1),
('E-shop revenue', 157.98, '2024-11-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241127-798.
Created by Miltos Karabasilis (id: 2) at 2024-11-27 12:00:00
', 1),
('Physical store revenue', 96.82, '2024-11-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241127-682.
Created by Miltos Karabasilis (id: 2) at 2024-11-27 12:00:00
', 1),
('E-shop revenue', 115.44, '2024-11-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241128-544.
Created by Miltos Karabasilis (id: 2) at 2024-11-28 12:00:00
', 1),
('Physical store revenue', 70.76, '2024-11-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241128-076.
Created by Miltos Karabasilis (id: 2) at 2024-11-28 12:00:00
', 1),
('E-shop revenue', 118.92, '2024-11-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241129-892.
Created by Miltos Karabasilis (id: 2) at 2024-11-29 12:00:00
', 1),
('Physical store revenue', 72.88, '2024-11-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241129-288.
Created by Miltos Karabasilis (id: 2) at 2024-11-29 12:00:00
', 1),
('E-shop revenue', 150.29, '2024-11-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241130-029.
Created by Miltos Karabasilis (id: 2) at 2024-11-30 12:00:00
', 1),
('Physical store revenue', 92.11, '2024-11-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241130-211.
Created by Miltos Karabasilis (id: 2) at 2024-11-30 12:00:00
', 1),
('E-shop revenue', 151.90, '2024-12-01', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20241201-190.
Created by Miltos Karabasilis (id: 2) at 2024-12-01 12:00:00
', 1),
('Physical store revenue', 93.10, '2024-12-01', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20241201-310.
Created by Miltos Karabasilis (id: 2) at 2024-12-01 12:00:00
', 1),
('E-shop revenue', 139.87, '2024-12-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241202-987.
Created by Miltos Karabasilis (id: 2) at 2024-12-02 12:00:00
', 1),
('Physical store revenue', 85.73, '2024-12-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241202-573.
Created by Miltos Karabasilis (id: 2) at 2024-12-02 12:00:00
', 1),
('E-shop revenue', 130.94, '2024-12-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241203-094.
Created by Miltos Karabasilis (id: 2) at 2024-12-03 12:00:00
', 1),
('Physical store revenue', 80.26, '2024-12-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241203-026.
Created by Miltos Karabasilis (id: 2) at 2024-12-03 12:00:00
', 1),
('E-shop revenue', 134.42, '2024-12-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241204-442.
Created by Miltos Karabasilis (id: 2) at 2024-12-04 12:00:00
', 1),
('Physical store revenue', 82.38, '2024-12-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241204-238.
Created by Miltos Karabasilis (id: 2) at 2024-12-04 12:00:00
', 1),
('E-shop revenue', 137.89, '2024-12-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241205-789.
Created by Miltos Karabasilis (id: 2) at 2024-12-05 12:00:00
', 1),
('Physical store revenue', 84.51, '2024-12-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241205-451.
Created by Miltos Karabasilis (id: 2) at 2024-12-05 12:00:00
', 1),
('E-shop revenue', 141.36, '2024-12-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241206-136.
Created by Miltos Karabasilis (id: 2) at 2024-12-06 12:00:00
', 1),
('Physical store revenue', 86.64, '2024-12-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241206-664.
Created by Miltos Karabasilis (id: 2) at 2024-12-06 12:00:00
', 1),
('E-shop revenue', 163.62, '2024-12-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241207-362.
Created by Miltos Karabasilis (id: 2) at 2024-12-07 12:00:00
', 1),
('Physical store revenue', 100.28, '2024-12-07', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241207-028.
Created by Miltos Karabasilis (id: 2) at 2024-12-07 12:00:00
', 1),
('E-shop revenue', 167.09, '2024-12-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241208-709.
Created by Miltos Karabasilis (id: 2) at 2024-12-08 12:00:00
', 1),
('Physical store revenue', 102.41, '2024-12-08', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241208-241.
Created by Miltos Karabasilis (id: 2) at 2024-12-08 12:00:00
', 1),
('E-shop revenue', 155.06, '2024-12-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241209-506.
Created by Miltos Karabasilis (id: 2) at 2024-12-09 12:00:00
', 1),
('Physical store revenue', 95.04, '2024-12-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241209-504.
Created by Miltos Karabasilis (id: 2) at 2024-12-09 12:00:00
', 1),
('E-shop revenue', 146.13, '2024-12-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241210-613.
Created by Miltos Karabasilis (id: 2) at 2024-12-10 12:00:00
', 1),
('Physical store revenue', 89.57, '2024-12-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241210-957.
Created by Miltos Karabasilis (id: 2) at 2024-12-10 12:00:00
', 1),
('E-shop revenue', 149.61, '2024-12-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241211-961.
Created by Miltos Karabasilis (id: 2) at 2024-12-11 12:00:00
', 1),
('Physical store revenue', 91.69, '2024-12-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241211-169.
Created by Miltos Karabasilis (id: 2) at 2024-12-11 12:00:00
', 1),
('E-shop revenue', 153.08, '2024-12-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241212-308.
Created by Miltos Karabasilis (id: 2) at 2024-12-12 12:00:00
', 1),
('Physical store revenue', 93.82, '2024-12-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241212-382.
Created by Miltos Karabasilis (id: 2) at 2024-12-12 12:00:00
', 1),
('E-shop revenue', 156.55, '2024-12-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241213-655.
Created by Miltos Karabasilis (id: 2) at 2024-12-13 12:00:00
', 1),
('Physical store revenue', 95.95, '2024-12-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241213-595.
Created by Miltos Karabasilis (id: 2) at 2024-12-13 12:00:00
', 1),
('E-shop revenue', 178.81, '2024-12-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241214-881.
Created by Miltos Karabasilis (id: 2) at 2024-12-14 12:00:00
', 1),
('Physical store revenue', 109.59, '2024-12-14', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241214-959.
Created by Miltos Karabasilis (id: 2) at 2024-12-14 12:00:00
', 1),
('E-shop revenue', 145.39, '2024-12-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241215-539.
Created by Miltos Karabasilis (id: 2) at 2024-12-15 12:00:00
', 1),
('Physical store revenue', 89.11, '2024-12-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241215-911.
Created by Miltos Karabasilis (id: 2) at 2024-12-15 12:00:00
', 1),
('E-shop revenue', 133.36, '2024-12-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241216-336.
Created by Miltos Karabasilis (id: 2) at 2024-12-16 12:00:00
', 1),
('Physical store revenue', 81.74, '2024-12-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241216-174.
Created by Miltos Karabasilis (id: 2) at 2024-12-16 12:00:00
', 1),
('E-shop revenue', 124.43, '2024-12-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241217-443.
Created by Miltos Karabasilis (id: 2) at 2024-12-17 12:00:00
', 1),
('Physical store revenue', 76.27, '2024-12-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241217-627.
Created by Miltos Karabasilis (id: 2) at 2024-12-17 12:00:00
', 1),
('E-shop revenue', 127.91, '2024-12-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241218-791.
Created by Miltos Karabasilis (id: 2) at 2024-12-18 12:00:00
', 1),
('Physical store revenue', 78.39, '2024-12-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241218-839.
Created by Miltos Karabasilis (id: 2) at 2024-12-18 12:00:00
', 1),
('E-shop revenue', 131.38, '2024-12-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241219-138.
Created by Miltos Karabasilis (id: 2) at 2024-12-19 12:00:00
', 1),
('Physical store revenue', 80.52, '2024-12-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241219-052.
Created by Miltos Karabasilis (id: 2) at 2024-12-19 12:00:00
', 1),
('E-shop revenue', 134.85, '2024-12-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241220-485.
Created by Miltos Karabasilis (id: 2) at 2024-12-20 12:00:00
', 1),
('Physical store revenue', 82.65, '2024-12-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241220-265.
Created by Miltos Karabasilis (id: 2) at 2024-12-20 12:00:00
', 1),
('E-shop revenue', 157.11, '2024-12-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241221-711.
Created by Miltos Karabasilis (id: 2) at 2024-12-21 12:00:00
', 1),
('Physical store revenue', 96.29, '2024-12-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241221-629.
Created by Miltos Karabasilis (id: 2) at 2024-12-21 12:00:00
', 1),
('E-shop revenue', 160.58, '2024-12-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241222-058.
Created by Miltos Karabasilis (id: 2) at 2024-12-22 12:00:00
', 1),
('Physical store revenue', 98.42, '2024-12-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241222-842.
Created by Miltos Karabasilis (id: 2) at 2024-12-22 12:00:00
', 1),
('E-shop revenue', 148.55, '2024-12-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241223-855.
Created by Miltos Karabasilis (id: 2) at 2024-12-23 12:00:00
', 1),
('Physical store revenue', 91.05, '2024-12-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241223-105.
Created by Miltos Karabasilis (id: 2) at 2024-12-23 12:00:00
', 1),
('E-shop revenue', 139.62, '2024-12-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241224-962.
Created by Miltos Karabasilis (id: 2) at 2024-12-24 12:00:00
', 1),
('Physical store revenue', 85.58, '2024-12-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241224-558.
Created by Miltos Karabasilis (id: 2) at 2024-12-24 12:00:00
', 1),
('E-shop revenue', 143.10, '2024-12-25', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20241225-310.
Created by Miltos Karabasilis (id: 2) at 2024-12-25 12:00:00
', 1),
('Physical store revenue', 87.70, '2024-12-25', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20241225-770.
Created by Miltos Karabasilis (id: 2) at 2024-12-25 12:00:00
', 1),
('E-shop revenue', 146.57, '2024-12-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241226-657.
Created by Miltos Karabasilis (id: 2) at 2024-12-26 12:00:00
', 1),
('Physical store revenue', 89.83, '2024-12-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241226-983.
Created by Miltos Karabasilis (id: 2) at 2024-12-26 12:00:00
', 1),
('E-shop revenue', 150.04, '2024-12-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241227-004.
Created by Miltos Karabasilis (id: 2) at 2024-12-27 12:00:00
', 1),
('Physical store revenue', 91.96, '2024-12-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241227-196.
Created by Miltos Karabasilis (id: 2) at 2024-12-27 12:00:00
', 1),
('E-shop revenue', 172.30, '2024-12-28', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20241228-230.
Created by Miltos Karabasilis (id: 2) at 2024-12-28 12:00:00
', 1),
('Physical store revenue', 105.60, '2024-12-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241228-560.
Created by Miltos Karabasilis (id: 2) at 2024-12-28 12:00:00
', 1),
('E-shop revenue', 175.77, '2024-12-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20241229-577.
Created by Miltos Karabasilis (id: 2) at 2024-12-29 12:00:00
', 1),
('Physical store revenue', 107.73, '2024-12-29', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241229-773.
Created by Miltos Karabasilis (id: 2) at 2024-12-29 12:00:00
', 1),
('E-shop revenue', 163.74, '2024-12-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241230-374.
Created by Miltos Karabasilis (id: 2) at 2024-12-30 12:00:00
', 1),
('Physical store revenue', 100.36, '2024-12-30', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20241230-036.
Created by Miltos Karabasilis (id: 2) at 2024-12-30 12:00:00
', 1),
('E-shop revenue', 154.81, '2024-12-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20241231-481.
Created by Miltos Karabasilis (id: 2) at 2024-12-31 12:00:00
', 1),
('Physical store revenue', 94.89, '2024-12-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20241231-489.
Created by Miltos Karabasilis (id: 2) at 2024-12-31 12:00:00
', 1),
('E-shop revenue', 114.27, '2025-01-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250101-427.
Created by Miltos Karabasilis (id: 2) at 2025-01-01 12:00:00
', 1),
('Physical store revenue', 70.03, '2025-01-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250101-003.
Created by Miltos Karabasilis (id: 2) at 2025-01-01 12:00:00
', 1),
('E-shop revenue', 117.74, '2025-01-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250102-774.
Created by Miltos Karabasilis (id: 2) at 2025-01-02 12:00:00
', 1),
('Physical store revenue', 72.16, '2025-01-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250102-216.
Created by Miltos Karabasilis (id: 2) at 2025-01-02 12:00:00
', 1),
('E-shop revenue', 121.21, '2025-01-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250103-121.
Created by Miltos Karabasilis (id: 2) at 2025-01-03 12:00:00
', 1),
('Physical store revenue', 74.29, '2025-01-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250103-429.
Created by Miltos Karabasilis (id: 2) at 2025-01-03 12:00:00
', 1),
('E-shop revenue', 152.58, '2025-01-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250104-258.
Created by Miltos Karabasilis (id: 2) at 2025-01-04 12:00:00
', 1),
('Physical store revenue', 93.52, '2025-01-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250104-352.
Created by Miltos Karabasilis (id: 2) at 2025-01-04 12:00:00
', 1),
('E-shop revenue', 156.05, '2025-01-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250105-605.
Created by Miltos Karabasilis (id: 2) at 2025-01-05 12:00:00
', 1),
('Physical store revenue', 95.65, '2025-01-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250105-565.
Created by Miltos Karabasilis (id: 2) at 2025-01-05 12:00:00
', 1),
('E-shop revenue', 144.03, '2025-01-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250106-403.
Created by Miltos Karabasilis (id: 2) at 2025-01-06 12:00:00
', 1),
('Physical store revenue', 88.27, '2025-01-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250106-827.
Created by Miltos Karabasilis (id: 2) at 2025-01-06 12:00:00
', 1),
('E-shop revenue', 125.98, '2025-01-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250107-598.
Created by Miltos Karabasilis (id: 2) at 2025-01-07 12:00:00
', 1),
('Physical store revenue', 77.22, '2025-01-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250107-722.
Created by Miltos Karabasilis (id: 2) at 2025-01-07 12:00:00
', 1),
('E-shop revenue', 129.46, '2025-01-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250108-946.
Created by Miltos Karabasilis (id: 2) at 2025-01-08 12:00:00
', 1),
('Physical store revenue', 79.34, '2025-01-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250108-934.
Created by Miltos Karabasilis (id: 2) at 2025-01-08 12:00:00
', 1),
('E-shop revenue', 132.93, '2025-01-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250109-293.
Created by Miltos Karabasilis (id: 2) at 2025-01-09 12:00:00
', 1),
('Physical store revenue', 81.47, '2025-01-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250109-147.
Created by Miltos Karabasilis (id: 2) at 2025-01-09 12:00:00
', 1),
('E-shop revenue', 136.40, '2025-01-10', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250110-640.
Created by Miltos Karabasilis (id: 2) at 2025-01-10 12:00:00
', 1),
('Physical store revenue', 83.60, '2025-01-10', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250110-360.
Created by Miltos Karabasilis (id: 2) at 2025-01-10 12:00:00
', 1),
('E-shop revenue', 167.77, '2025-01-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250111-777.
Created by Miltos Karabasilis (id: 2) at 2025-01-11 12:00:00
', 1),
('Physical store revenue', 102.83, '2025-01-11', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250111-283.
Created by Miltos Karabasilis (id: 2) at 2025-01-11 12:00:00
', 1),
('E-shop revenue', 171.24, '2025-01-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250112-124.
Created by Miltos Karabasilis (id: 2) at 2025-01-12 12:00:00
', 1),
('Physical store revenue', 104.96, '2025-01-12', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250112-496.
Created by Miltos Karabasilis (id: 2) at 2025-01-12 12:00:00
', 1),
('E-shop revenue', 159.22, '2025-01-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250113-922.
Created by Miltos Karabasilis (id: 2) at 2025-01-13 12:00:00
', 1),
('Physical store revenue', 97.58, '2025-01-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250113-758.
Created by Miltos Karabasilis (id: 2) at 2025-01-13 12:00:00
', 1),
('E-shop revenue', 141.17, '2025-01-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250114-117.
Created by Miltos Karabasilis (id: 2) at 2025-01-14 12:00:00
', 1),
('Physical store revenue', 86.53, '2025-01-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250114-653.
Created by Miltos Karabasilis (id: 2) at 2025-01-14 12:00:00
', 1),
('E-shop revenue', 144.65, '2025-01-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250115-465.
Created by Miltos Karabasilis (id: 2) at 2025-01-15 12:00:00
', 1),
('Physical store revenue', 88.65, '2025-01-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250115-865.
Created by Miltos Karabasilis (id: 2) at 2025-01-15 12:00:00
', 1),
('E-shop revenue', 148.12, '2025-01-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250116-812.
Created by Miltos Karabasilis (id: 2) at 2025-01-16 12:00:00
', 1),
('Physical store revenue', 90.78, '2025-01-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250116-078.
Created by Miltos Karabasilis (id: 2) at 2025-01-16 12:00:00
', 1),
('E-shop revenue', 151.59, '2025-01-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250117-159.
Created by Miltos Karabasilis (id: 2) at 2025-01-17 12:00:00
', 1),
('Physical store revenue', 92.91, '2025-01-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250117-291.
Created by Miltos Karabasilis (id: 2) at 2025-01-17 12:00:00
', 1),
('E-shop revenue', 146.07, '2025-01-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250118-607.
Created by Miltos Karabasilis (id: 2) at 2025-01-18 12:00:00
', 1),
('Physical store revenue', 89.53, '2025-01-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250118-953.
Created by Miltos Karabasilis (id: 2) at 2025-01-18 12:00:00
', 1),
('E-shop revenue', 149.54, '2025-01-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250119-954.
Created by Miltos Karabasilis (id: 2) at 2025-01-19 12:00:00
', 1),
('Physical store revenue', 91.66, '2025-01-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250119-166.
Created by Miltos Karabasilis (id: 2) at 2025-01-19 12:00:00
', 1),
('E-shop revenue', 137.52, '2025-01-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250120-752.
Created by Miltos Karabasilis (id: 2) at 2025-01-20 12:00:00
', 1),
('Physical store revenue', 84.28, '2025-01-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250120-428.
Created by Miltos Karabasilis (id: 2) at 2025-01-20 12:00:00
', 1),
('E-shop revenue', 119.47, '2025-01-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250121-947.
Created by Miltos Karabasilis (id: 2) at 2025-01-21 12:00:00
', 1),
('Physical store revenue', 73.23, '2025-01-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250121-323.
Created by Miltos Karabasilis (id: 2) at 2025-01-21 12:00:00
', 1),
('E-shop revenue', 122.95, '2025-01-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250122-295.
Created by Miltos Karabasilis (id: 2) at 2025-01-22 12:00:00
', 1),
('Physical store revenue', 75.35, '2025-01-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250122-535.
Created by Miltos Karabasilis (id: 2) at 2025-01-22 12:00:00
', 1),
('E-shop revenue', 126.42, '2025-01-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250123-642.
Created by Miltos Karabasilis (id: 2) at 2025-01-23 12:00:00
', 1),
('Physical store revenue', 77.48, '2025-01-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250123-748.
Created by Miltos Karabasilis (id: 2) at 2025-01-23 12:00:00
', 1),
('E-shop revenue', 129.89, '2025-01-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250124-989.
Created by Miltos Karabasilis (id: 2) at 2025-01-24 12:00:00
', 1),
('Physical store revenue', 79.61, '2025-01-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250124-961.
Created by Miltos Karabasilis (id: 2) at 2025-01-24 12:00:00
', 1),
('E-shop revenue', 161.26, '2025-01-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250125-126.
Created by Miltos Karabasilis (id: 2) at 2025-01-25 12:00:00
', 1),
('Physical store revenue', 98.84, '2025-01-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250125-884.
Created by Miltos Karabasilis (id: 2) at 2025-01-25 12:00:00
', 1),
('E-shop revenue', 164.73, '2025-01-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250126-473.
Created by Miltos Karabasilis (id: 2) at 2025-01-26 12:00:00
', 1),
('Physical store revenue', 100.97, '2025-01-26', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250126-097.
Created by Miltos Karabasilis (id: 2) at 2025-01-26 12:00:00
', 1),
('E-shop revenue', 152.71, '2025-01-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250127-271.
Created by Miltos Karabasilis (id: 2) at 2025-01-27 12:00:00
', 1),
('Physical store revenue', 93.59, '2025-01-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250127-359.
Created by Miltos Karabasilis (id: 2) at 2025-01-27 12:00:00
', 1),
('E-shop revenue', 134.66, '2025-01-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250128-466.
Created by Miltos Karabasilis (id: 2) at 2025-01-28 12:00:00
', 1),
('Physical store revenue', 82.54, '2025-01-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250128-254.
Created by Miltos Karabasilis (id: 2) at 2025-01-28 12:00:00
', 1),
('E-shop revenue', 138.14, '2025-01-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250129-814.
Created by Miltos Karabasilis (id: 2) at 2025-01-29 12:00:00
', 1),
('Physical store revenue', 84.66, '2025-01-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250129-466.
Created by Miltos Karabasilis (id: 2) at 2025-01-29 12:00:00
', 1),
('E-shop revenue', 141.61, '2025-01-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250130-161.
Created by Miltos Karabasilis (id: 2) at 2025-01-30 12:00:00
', 1),
('Physical store revenue', 86.79, '2025-01-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250130-679.
Created by Miltos Karabasilis (id: 2) at 2025-01-30 12:00:00
', 1),
('E-shop revenue', 145.08, '2025-01-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250131-508.
Created by Miltos Karabasilis (id: 2) at 2025-01-31 12:00:00
', 1),
('Physical store revenue', 88.92, '2025-01-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250131-892.
Created by Miltos Karabasilis (id: 2) at 2025-01-31 12:00:00
', 1),
('E-shop revenue', 173.29, '2025-02-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250201-329.
Created by Miltos Karabasilis (id: 2) at 2025-02-01 12:00:00
', 1),
('Physical store revenue', 106.21, '2025-02-01', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250201-621.
Created by Miltos Karabasilis (id: 2) at 2025-02-01 12:00:00
', 1),
('E-shop revenue', 176.76, '2025-02-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250202-676.
Created by Miltos Karabasilis (id: 2) at 2025-02-02 12:00:00
', 1),
('Physical store revenue', 108.34, '2025-02-02', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250202-834.
Created by Miltos Karabasilis (id: 2) at 2025-02-02 12:00:00
', 1),
('E-shop revenue', 164.73, '2025-02-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250203-473.
Created by Miltos Karabasilis (id: 2) at 2025-02-03 12:00:00
', 1),
('Physical store revenue', 100.97, '2025-02-03', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250203-097.
Created by Miltos Karabasilis (id: 2) at 2025-02-03 12:00:00
', 1),
('E-shop revenue', 118.92, '2025-02-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250204-892.
Created by Miltos Karabasilis (id: 2) at 2025-02-04 12:00:00
', 1),
('Physical store revenue', 72.88, '2025-02-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250204-288.
Created by Miltos Karabasilis (id: 2) at 2025-02-04 12:00:00
', 1),
('E-shop revenue', 122.39, '2025-02-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250205-239.
Created by Miltos Karabasilis (id: 2) at 2025-02-05 12:00:00
', 1),
('Physical store revenue', 75.01, '2025-02-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250205-501.
Created by Miltos Karabasilis (id: 2) at 2025-02-05 12:00:00
', 1),
('E-shop revenue', 125.86, '2025-02-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250206-586.
Created by Miltos Karabasilis (id: 2) at 2025-02-06 12:00:00
', 1),
('Physical store revenue', 77.14, '2025-02-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250206-714.
Created by Miltos Karabasilis (id: 2) at 2025-02-06 12:00:00
', 1),
('E-shop revenue', 120.22, '2025-02-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250207-022.
Created by Miltos Karabasilis (id: 2) at 2025-02-07 12:00:00
', 1),
('Physical store revenue', 73.68, '2025-02-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250207-368.
Created by Miltos Karabasilis (id: 2) at 2025-02-07 12:00:00
', 1),
('E-shop revenue', 151.59, '2025-02-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250208-159.
Created by Miltos Karabasilis (id: 2) at 2025-02-08 12:00:00
', 1),
('Physical store revenue', 92.91, '2025-02-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250208-291.
Created by Miltos Karabasilis (id: 2) at 2025-02-08 12:00:00
', 1),
('E-shop revenue', 155.06, '2025-02-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250209-506.
Created by Miltos Karabasilis (id: 2) at 2025-02-09 12:00:00
', 1),
('Physical store revenue', 95.04, '2025-02-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250209-504.
Created by Miltos Karabasilis (id: 2) at 2025-02-09 12:00:00
', 1),
('E-shop revenue', 143.03, '2025-02-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250210-303.
Created by Miltos Karabasilis (id: 2) at 2025-02-10 12:00:00
', 1),
('Physical store revenue', 87.67, '2025-02-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250210-767.
Created by Miltos Karabasilis (id: 2) at 2025-02-10 12:00:00
', 1),
('E-shop revenue', 134.11, '2025-02-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250211-411.
Created by Miltos Karabasilis (id: 2) at 2025-02-11 12:00:00
', 1),
('Physical store revenue', 82.19, '2025-02-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250211-219.
Created by Miltos Karabasilis (id: 2) at 2025-02-11 12:00:00
', 1),
('E-shop revenue', 137.58, '2025-02-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250212-758.
Created by Miltos Karabasilis (id: 2) at 2025-02-12 12:00:00
', 1),
('Physical store revenue', 84.32, '2025-02-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250212-432.
Created by Miltos Karabasilis (id: 2) at 2025-02-12 12:00:00
', 1),
('E-shop revenue', 141.05, '2025-02-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250213-105.
Created by Miltos Karabasilis (id: 2) at 2025-02-13 12:00:00
', 1),
('Physical store revenue', 86.45, '2025-02-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250213-645.
Created by Miltos Karabasilis (id: 2) at 2025-02-13 12:00:00
', 1),
('E-shop revenue', 135.41, '2025-02-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250214-541.
Created by Miltos Karabasilis (id: 2) at 2025-02-14 12:00:00
', 1),
('Physical store revenue', 82.99, '2025-02-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250214-299.
Created by Miltos Karabasilis (id: 2) at 2025-02-14 12:00:00
', 1),
('E-shop revenue', 166.78, '2025-02-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250215-678.
Created by Miltos Karabasilis (id: 2) at 2025-02-15 12:00:00
', 1),
('Physical store revenue', 102.22, '2025-02-15', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250215-222.
Created by Miltos Karabasilis (id: 2) at 2025-02-15 12:00:00
', 1),
('E-shop revenue', 170.25, '2025-02-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250216-025.
Created by Miltos Karabasilis (id: 2) at 2025-02-16 12:00:00
', 1),
('Physical store revenue', 104.35, '2025-02-16', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250216-435.
Created by Miltos Karabasilis (id: 2) at 2025-02-16 12:00:00
', 1),
('E-shop revenue', 158.22, '2025-02-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250217-822.
Created by Miltos Karabasilis (id: 2) at 2025-02-17 12:00:00
', 1),
('Physical store revenue', 96.98, '2025-02-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250217-698.
Created by Miltos Karabasilis (id: 2) at 2025-02-17 12:00:00
', 1),
('E-shop revenue', 149.30, '2025-02-18', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250218-930.
Created by Miltos Karabasilis (id: 2) at 2025-02-18 12:00:00
', 1),
('Physical store revenue', 91.50, '2025-02-18', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250218-150.
Created by Miltos Karabasilis (id: 2) at 2025-02-18 12:00:00
', 1),
('E-shop revenue', 152.77, '2025-02-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250219-277.
Created by Miltos Karabasilis (id: 2) at 2025-02-19 12:00:00
', 1),
('Physical store revenue', 93.63, '2025-02-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250219-363.
Created by Miltos Karabasilis (id: 2) at 2025-02-19 12:00:00
', 1),
('E-shop revenue', 156.24, '2025-02-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250220-624.
Created by Miltos Karabasilis (id: 2) at 2025-02-20 12:00:00
', 1),
('Physical store revenue', 95.76, '2025-02-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250220-576.
Created by Miltos Karabasilis (id: 2) at 2025-02-20 12:00:00
', 1),
('E-shop revenue', 113.71, '2025-02-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250221-371.
Created by Miltos Karabasilis (id: 2) at 2025-02-21 12:00:00
', 1),
('Physical store revenue', 69.69, '2025-02-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250221-969.
Created by Miltos Karabasilis (id: 2) at 2025-02-21 12:00:00
', 1),
('E-shop revenue', 145.08, '2025-02-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250222-508.
Created by Miltos Karabasilis (id: 2) at 2025-02-22 12:00:00
', 1),
('Physical store revenue', 88.92, '2025-02-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250222-892.
Created by Miltos Karabasilis (id: 2) at 2025-02-22 12:00:00
', 1),
('E-shop revenue', 148.55, '2025-02-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250223-855.
Created by Miltos Karabasilis (id: 2) at 2025-02-23 12:00:00
', 1),
('Physical store revenue', 91.05, '2025-02-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250223-105.
Created by Miltos Karabasilis (id: 2) at 2025-02-23 12:00:00
', 1),
('E-shop revenue', 136.52, '2025-02-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250224-652.
Created by Miltos Karabasilis (id: 2) at 2025-02-24 12:00:00
', 1),
('Physical store revenue', 83.68, '2025-02-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250224-368.
Created by Miltos Karabasilis (id: 2) at 2025-02-24 12:00:00
', 1),
('E-shop revenue', 127.60, '2025-02-25', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250225-760.
Created by Miltos Karabasilis (id: 2) at 2025-02-25 12:00:00
', 1),
('Physical store revenue', 78.20, '2025-02-25', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250225-820.
Created by Miltos Karabasilis (id: 2) at 2025-02-25 12:00:00
', 1),
('E-shop revenue', 131.07, '2025-02-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250226-107.
Created by Miltos Karabasilis (id: 2) at 2025-02-26 12:00:00
', 1),
('Physical store revenue', 80.33, '2025-02-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250226-033.
Created by Miltos Karabasilis (id: 2) at 2025-02-26 12:00:00
', 1),
('E-shop revenue', 134.54, '2025-02-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250227-454.
Created by Miltos Karabasilis (id: 2) at 2025-02-27 12:00:00
', 1),
('Physical store revenue', 82.46, '2025-02-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250227-246.
Created by Miltos Karabasilis (id: 2) at 2025-02-27 12:00:00
', 1),
('E-shop revenue', 128.90, '2025-02-28', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250228-890.
Created by Miltos Karabasilis (id: 2) at 2025-02-28 12:00:00
', 1),
('Physical store revenue', 79.00, '2025-02-28', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250228-900.
Created by Miltos Karabasilis (id: 2) at 2025-02-28 12:00:00
', 1),
('E-shop revenue', 161.01, '2025-03-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250301-101.
Created by Miltos Karabasilis (id: 2) at 2025-03-01 12:00:00
', 1),
('Physical store revenue', 98.69, '2025-03-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250301-869.
Created by Miltos Karabasilis (id: 2) at 2025-03-01 12:00:00
', 1),
('E-shop revenue', 164.49, '2025-03-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250302-449.
Created by Miltos Karabasilis (id: 2) at 2025-03-02 12:00:00
', 1),
('Physical store revenue', 100.81, '2025-03-02', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250302-081.
Created by Miltos Karabasilis (id: 2) at 2025-03-02 12:00:00
', 1),
('E-shop revenue', 152.46, '2025-03-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250303-246.
Created by Miltos Karabasilis (id: 2) at 2025-03-03 12:00:00
', 1),
('Physical store revenue', 93.44, '2025-03-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250303-344.
Created by Miltos Karabasilis (id: 2) at 2025-03-03 12:00:00
', 1),
('E-shop revenue', 143.53, '2025-03-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250304-353.
Created by Miltos Karabasilis (id: 2) at 2025-03-04 12:00:00
', 1),
('Physical store revenue', 87.97, '2025-03-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250304-797.
Created by Miltos Karabasilis (id: 2) at 2025-03-04 12:00:00
', 1),
('E-shop revenue', 147.00, '2025-03-05', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20250305-700.
Created by Miltos Karabasilis (id: 2) at 2025-03-05 12:00:00
', 1),
('Physical store revenue', 90.10, '2025-03-05', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250305-010.
Created by Miltos Karabasilis (id: 2) at 2025-03-05 12:00:00
', 1),
('E-shop revenue', 150.47, '2025-03-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250306-047.
Created by Miltos Karabasilis (id: 2) at 2025-03-06 12:00:00
', 1),
('Physical store revenue', 92.23, '2025-03-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250306-223.
Created by Miltos Karabasilis (id: 2) at 2025-03-06 12:00:00
', 1),
('E-shop revenue', 144.83, '2025-03-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250307-483.
Created by Miltos Karabasilis (id: 2) at 2025-03-07 12:00:00
', 1),
('Physical store revenue', 88.77, '2025-03-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250307-877.
Created by Miltos Karabasilis (id: 2) at 2025-03-07 12:00:00
', 1),
('E-shop revenue', 176.20, '2025-03-08', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20250308-620.
Created by Miltos Karabasilis (id: 2) at 2025-03-08 12:00:00
', 1),
('Physical store revenue', 108.00, '2025-03-08', 'Physical shop revenue from cash and card transactions handled on site. Receipt batch POS-20250308-800.
Created by Miltos Karabasilis (id: 2) at 2025-03-08 12:00:00
', 1),
('E-shop revenue', 179.68, '2025-03-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250309-968.
Created by Miltos Karabasilis (id: 2) at 2025-03-09 12:00:00
', 1),
('Physical store revenue', 110.12, '2025-03-09', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250309-012.
Created by Miltos Karabasilis (id: 2) at 2025-03-09 12:00:00
', 1),
('E-shop revenue', 130.76, '2025-03-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250310-076.
Created by Miltos Karabasilis (id: 2) at 2025-03-10 12:00:00
', 1),
('Physical store revenue', 80.14, '2025-03-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250310-014.
Created by Miltos Karabasilis (id: 2) at 2025-03-10 12:00:00
', 1),
('E-shop revenue', 121.83, '2025-03-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250311-183.
Created by Miltos Karabasilis (id: 2) at 2025-03-11 12:00:00
', 1),
('Physical store revenue', 74.67, '2025-03-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250311-467.
Created by Miltos Karabasilis (id: 2) at 2025-03-11 12:00:00
', 1),
('E-shop revenue', 125.30, '2025-03-12', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250312-530.
Created by Miltos Karabasilis (id: 2) at 2025-03-12 12:00:00
', 1),
('Physical store revenue', 76.80, '2025-03-12', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250312-680.
Created by Miltos Karabasilis (id: 2) at 2025-03-12 12:00:00
', 1),
('E-shop revenue', 128.77, '2025-03-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250313-877.
Created by Miltos Karabasilis (id: 2) at 2025-03-13 12:00:00
', 1),
('Physical store revenue', 78.93, '2025-03-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250313-893.
Created by Miltos Karabasilis (id: 2) at 2025-03-13 12:00:00
', 1),
('E-shop revenue', 123.13, '2025-03-14', 'Repeat customer: Elena Kostaki, 45 Ermou St, Athens 105 63. Order #WEB-4821 picked from warehouse aisle A2.
Created by Miltos Karabasilis (id: 2) at 2025-03-14 12:00:00
', 1),
('Physical store revenue', 75.47, '2025-03-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250314-547.
Created by Miltos Karabasilis (id: 2) at 2025-03-14 12:00:00
', 1),
('E-shop revenue', 154.50, '2025-03-15', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20250315-450.
Created by Miltos Karabasilis (id: 2) at 2025-03-15 12:00:00
', 1),
('Physical store revenue', 94.70, '2025-03-15', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250315-470.
Created by Miltos Karabasilis (id: 2) at 2025-03-15 12:00:00
', 1),
('E-shop revenue', 157.98, '2025-03-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250316-798.
Created by Miltos Karabasilis (id: 2) at 2025-03-16 12:00:00
', 1),
('Physical store revenue', 96.82, '2025-03-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250316-682.
Created by Miltos Karabasilis (id: 2) at 2025-03-16 12:00:00
', 1),
('E-shop revenue', 145.95, '2025-03-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250317-595.
Created by Miltos Karabasilis (id: 2) at 2025-03-17 12:00:00
', 1),
('Physical store revenue', 89.45, '2025-03-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250317-945.
Created by Miltos Karabasilis (id: 2) at 2025-03-17 12:00:00
', 1),
('E-shop revenue', 137.02, '2025-03-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250318-702.
Created by Miltos Karabasilis (id: 2) at 2025-03-18 12:00:00
', 1),
('Physical store revenue', 83.98, '2025-03-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250318-398.
Created by Miltos Karabasilis (id: 2) at 2025-03-18 12:00:00
', 1),
('E-shop revenue', 140.49, '2025-03-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250319-049.
Created by Miltos Karabasilis (id: 2) at 2025-03-19 12:00:00
', 1),
('Physical store revenue', 86.11, '2025-03-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250319-611.
Created by Miltos Karabasilis (id: 2) at 2025-03-19 12:00:00
', 1),
('E-shop revenue', 143.96, '2025-03-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250320-396.
Created by Miltos Karabasilis (id: 2) at 2025-03-20 12:00:00
', 1),
('Physical store revenue', 88.24, '2025-03-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250320-824.
Created by Miltos Karabasilis (id: 2) at 2025-03-20 12:00:00
', 1),
('E-shop revenue', 138.32, '2025-03-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250321-832.
Created by Miltos Karabasilis (id: 2) at 2025-03-21 12:00:00
', 1),
('Physical store revenue', 84.78, '2025-03-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250321-478.
Created by Miltos Karabasilis (id: 2) at 2025-03-21 12:00:00
', 1),
('E-shop revenue', 169.69, '2025-03-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250322-969.
Created by Miltos Karabasilis (id: 2) at 2025-03-22 12:00:00
', 1),
('Physical store revenue', 104.01, '2025-03-22', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250322-401.
Created by Miltos Karabasilis (id: 2) at 2025-03-22 12:00:00
', 1),
('E-shop revenue', 173.17, '2025-03-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250323-317.
Created by Miltos Karabasilis (id: 2) at 2025-03-23 12:00:00
', 1),
('Physical store revenue', 106.13, '2025-03-23', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250323-613.
Created by Miltos Karabasilis (id: 2) at 2025-03-23 12:00:00
', 1),
('E-shop revenue', 161.14, '2025-03-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250324-114.
Created by Miltos Karabasilis (id: 2) at 2025-03-24 12:00:00
', 1),
('Physical store revenue', 98.76, '2025-03-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250324-876.
Created by Miltos Karabasilis (id: 2) at 2025-03-24 12:00:00
', 1),
('E-shop revenue', 152.21, '2025-03-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250325-221.
Created by Miltos Karabasilis (id: 2) at 2025-03-25 12:00:00
', 1),
('Physical store revenue', 93.29, '2025-03-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250325-329.
Created by Miltos Karabasilis (id: 2) at 2025-03-25 12:00:00
', 1),
('E-shop revenue', 155.68, '2025-03-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250326-568.
Created by Miltos Karabasilis (id: 2) at 2025-03-26 12:00:00
', 1),
('Physical store revenue', 95.42, '2025-03-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250326-542.
Created by Miltos Karabasilis (id: 2) at 2025-03-26 12:00:00
', 1),
('E-shop revenue', 122.26, '2025-03-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250327-226.
Created by Miltos Karabasilis (id: 2) at 2025-03-27 12:00:00
', 1),
('Physical store revenue', 74.94, '2025-03-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250327-494.
Created by Miltos Karabasilis (id: 2) at 2025-03-27 12:00:00
', 1),
('E-shop revenue', 116.62, '2025-03-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250328-662.
Created by Miltos Karabasilis (id: 2) at 2025-03-28 12:00:00
', 1),
('Physical store revenue', 71.48, '2025-03-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250328-148.
Created by Miltos Karabasilis (id: 2) at 2025-03-28 12:00:00
', 1),
('E-shop revenue', 147.99, '2025-03-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250329-799.
Created by Miltos Karabasilis (id: 2) at 2025-03-29 12:00:00
', 1),
('Physical store revenue', 90.71, '2025-03-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250329-071.
Created by Miltos Karabasilis (id: 2) at 2025-03-29 12:00:00
', 1),
('E-shop revenue', 151.47, '2025-03-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250330-147.
Created by Miltos Karabasilis (id: 2) at 2025-03-30 12:00:00
', 1),
('Physical store revenue', 92.83, '2025-03-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250330-283.
Created by Miltos Karabasilis (id: 2) at 2025-03-30 12:00:00
', 1),
('E-shop revenue', 139.44, '2025-03-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250331-944.
Created by Miltos Karabasilis (id: 2) at 2025-03-31 12:00:00
', 1),
('Physical store revenue', 85.46, '2025-03-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250331-546.
Created by Miltos Karabasilis (id: 2) at 2025-03-31 12:00:00
', 1),
('E-shop revenue', 127.35, '2025-04-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250401-735.
Created by Miltos Karabasilis (id: 2) at 2025-04-01 12:00:00
', 1),
('Physical store revenue', 78.05, '2025-04-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250401-805.
Created by Miltos Karabasilis (id: 2) at 2025-04-01 12:00:00
', 1),
('E-shop revenue', 130.82, '2025-04-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250402-082.
Created by Miltos Karabasilis (id: 2) at 2025-04-02 12:00:00
', 1),
('Physical store revenue', 80.18, '2025-04-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250402-018.
Created by Miltos Karabasilis (id: 2) at 2025-04-02 12:00:00
', 1),
('E-shop revenue', 134.29, '2025-04-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250403-429.
Created by Miltos Karabasilis (id: 2) at 2025-04-03 12:00:00
', 1),
('Physical store revenue', 82.31, '2025-04-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250403-231.
Created by Miltos Karabasilis (id: 2) at 2025-04-03 12:00:00
', 1),
('E-shop revenue', 137.76, '2025-04-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250404-776.
Created by Miltos Karabasilis (id: 2) at 2025-04-04 12:00:00
', 1),
('Physical store revenue', 84.44, '2025-04-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250404-444.
Created by Miltos Karabasilis (id: 2) at 2025-04-04 12:00:00
', 1),
('E-shop revenue', 169.14, '2025-04-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250405-914.
Created by Miltos Karabasilis (id: 2) at 2025-04-05 12:00:00
', 1),
('Physical store revenue', 103.66, '2025-04-05', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250405-366.
Created by Miltos Karabasilis (id: 2) at 2025-04-05 12:00:00
', 1),
('E-shop revenue', 172.61, '2025-04-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250406-261.
Created by Miltos Karabasilis (id: 2) at 2025-04-06 12:00:00
', 1),
('Physical store revenue', 105.79, '2025-04-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250406-579.
Created by Miltos Karabasilis (id: 2) at 2025-04-06 12:00:00
', 1),
('E-shop revenue', 151.47, '2025-04-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250407-147.
Created by Miltos Karabasilis (id: 2) at 2025-04-07 12:00:00
', 1),
('Physical store revenue', 92.83, '2025-04-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250407-283.
Created by Miltos Karabasilis (id: 2) at 2025-04-07 12:00:00
', 1),
('E-shop revenue', 142.54, '2025-04-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250408-254.
Created by Miltos Karabasilis (id: 2) at 2025-04-08 12:00:00
', 1),
('Physical store revenue', 87.36, '2025-04-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250408-736.
Created by Miltos Karabasilis (id: 2) at 2025-04-08 12:00:00
', 1),
('E-shop revenue', 146.01, '2025-04-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250409-601.
Created by Miltos Karabasilis (id: 2) at 2025-04-09 12:00:00
', 1),
('Physical store revenue', 89.49, '2025-04-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250409-949.
Created by Miltos Karabasilis (id: 2) at 2025-04-09 12:00:00
', 1),
('E-shop revenue', 149.48, '2025-04-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250410-948.
Created by Miltos Karabasilis (id: 2) at 2025-04-10 12:00:00
', 1),
('Physical store revenue', 91.62, '2025-04-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250410-162.
Created by Miltos Karabasilis (id: 2) at 2025-04-10 12:00:00
', 1),
('E-shop revenue', 152.95, '2025-04-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250411-295.
Created by Miltos Karabasilis (id: 2) at 2025-04-11 12:00:00
', 1),
('Physical store revenue', 93.75, '2025-04-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250411-375.
Created by Miltos Karabasilis (id: 2) at 2025-04-11 12:00:00
', 1),
('E-shop revenue', 184.33, '2025-04-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250412-433.
Created by Miltos Karabasilis (id: 2) at 2025-04-12 12:00:00
', 1),
('Physical store revenue', 112.97, '2025-04-12', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250412-297.
Created by Miltos Karabasilis (id: 2) at 2025-04-12 12:00:00
', 1),
('E-shop revenue', 150.91, '2025-04-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250413-091.
Created by Miltos Karabasilis (id: 2) at 2025-04-13 12:00:00
', 1),
('Physical store revenue', 92.49, '2025-04-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250413-249.
Created by Miltos Karabasilis (id: 2) at 2025-04-13 12:00:00
', 1),
('E-shop revenue', 129.77, '2025-04-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250414-977.
Created by Miltos Karabasilis (id: 2) at 2025-04-14 12:00:00
', 1),
('Physical store revenue', 79.53, '2025-04-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250414-953.
Created by Miltos Karabasilis (id: 2) at 2025-04-14 12:00:00
', 1),
('E-shop revenue', 120.84, '2025-04-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250415-084.
Created by Miltos Karabasilis (id: 2) at 2025-04-15 12:00:00
', 1),
('Physical store revenue', 74.06, '2025-04-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250415-406.
Created by Miltos Karabasilis (id: 2) at 2025-04-15 12:00:00
', 1),
('E-shop revenue', 124.31, '2025-04-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250416-431.
Created by Miltos Karabasilis (id: 2) at 2025-04-16 12:00:00
', 1),
('Physical store revenue', 76.19, '2025-04-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250416-619.
Created by Miltos Karabasilis (id: 2) at 2025-04-16 12:00:00
', 1),
('E-shop revenue', 127.78, '2025-04-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250417-778.
Created by Miltos Karabasilis (id: 2) at 2025-04-17 12:00:00
', 1),
('Physical store revenue', 78.32, '2025-04-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250417-832.
Created by Miltos Karabasilis (id: 2) at 2025-04-17 12:00:00
', 1),
('E-shop revenue', 131.25, '2025-04-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250418-125.
Created by Miltos Karabasilis (id: 2) at 2025-04-18 12:00:00
', 1),
('Physical store revenue', 80.45, '2025-04-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250418-045.
Created by Miltos Karabasilis (id: 2) at 2025-04-18 12:00:00
', 1),
('E-shop revenue', 162.63, '2025-04-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250419-263.
Created by Miltos Karabasilis (id: 2) at 2025-04-19 12:00:00
', 1),
('Physical store revenue', 99.67, '2025-04-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250419-967.
Created by Miltos Karabasilis (id: 2) at 2025-04-19 12:00:00
', 1),
('E-shop revenue', 166.10, '2025-04-20', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20250420-610.
Created by Miltos Karabasilis (id: 2) at 2025-04-20 12:00:00
', 1),
('Physical store revenue', 101.80, '2025-04-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250420-180.
Created by Miltos Karabasilis (id: 2) at 2025-04-20 12:00:00
', 1),
('E-shop revenue', 144.96, '2025-04-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250421-496.
Created by Miltos Karabasilis (id: 2) at 2025-04-21 12:00:00
', 1),
('Physical store revenue', 88.84, '2025-04-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250421-884.
Created by Miltos Karabasilis (id: 2) at 2025-04-21 12:00:00
', 1),
('E-shop revenue', 136.03, '2025-04-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250422-603.
Created by Miltos Karabasilis (id: 2) at 2025-04-22 12:00:00
', 1),
('Physical store revenue', 83.37, '2025-04-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250422-337.
Created by Miltos Karabasilis (id: 2) at 2025-04-22 12:00:00
', 1),
('E-shop revenue', 139.50, '2025-04-23', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250423-950.
Created by Miltos Karabasilis (id: 2) at 2025-04-23 12:00:00
', 1),
('Physical store revenue', 85.50, '2025-04-23', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250423-550.
Created by Miltos Karabasilis (id: 2) at 2025-04-23 12:00:00
', 1),
('E-shop revenue', 142.97, '2025-04-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250424-297.
Created by Miltos Karabasilis (id: 2) at 2025-04-24 12:00:00
', 1),
('Physical store revenue', 87.63, '2025-04-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250424-763.
Created by Miltos Karabasilis (id: 2) at 2025-04-24 12:00:00
', 1),
('E-shop revenue', 146.44, '2025-04-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250425-644.
Created by Miltos Karabasilis (id: 2) at 2025-04-25 12:00:00
', 1),
('Physical store revenue', 89.76, '2025-04-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250425-976.
Created by Miltos Karabasilis (id: 2) at 2025-04-25 12:00:00
', 1),
('E-shop revenue', 177.82, '2025-04-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250426-782.
Created by Miltos Karabasilis (id: 2) at 2025-04-26 12:00:00
', 1),
('Physical store revenue', 108.98, '2025-04-26', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250426-898.
Created by Miltos Karabasilis (id: 2) at 2025-04-26 12:00:00
', 1),
('E-shop revenue', 181.29, '2025-04-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250427-129.
Created by Miltos Karabasilis (id: 2) at 2025-04-27 12:00:00
', 1),
('Physical store revenue', 111.11, '2025-04-27', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250427-111.
Created by Miltos Karabasilis (id: 2) at 2025-04-27 12:00:00
', 1),
('E-shop revenue', 160.15, '2025-04-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250428-015.
Created by Miltos Karabasilis (id: 2) at 2025-04-28 12:00:00
', 1),
('Physical store revenue', 98.15, '2025-04-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250428-815.
Created by Miltos Karabasilis (id: 2) at 2025-04-28 12:00:00
', 1),
('E-shop revenue', 151.22, '2025-04-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250429-122.
Created by Miltos Karabasilis (id: 2) at 2025-04-29 12:00:00
', 1),
('Physical store revenue', 92.68, '2025-04-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250429-268.
Created by Miltos Karabasilis (id: 2) at 2025-04-29 12:00:00
', 1),
('E-shop revenue', 117.80, '2025-04-30', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250430-780.
Created by Miltos Karabasilis (id: 2) at 2025-04-30 12:00:00
', 1),
('Physical store revenue', 72.20, '2025-04-30', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250430-220.
Created by Miltos Karabasilis (id: 2) at 2025-04-30 12:00:00
', 1),
('E-shop revenue', 119.41, '2025-05-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250501-941.
Created by Miltos Karabasilis (id: 2) at 2025-05-01 12:00:00
', 1),
('Physical store revenue', 73.19, '2025-05-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250501-319.
Created by Miltos Karabasilis (id: 2) at 2025-05-01 12:00:00
', 1),
('E-shop revenue', 122.88, '2025-05-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250502-288.
Created by Miltos Karabasilis (id: 2) at 2025-05-02 12:00:00
', 1),
('Physical store revenue', 75.32, '2025-05-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250502-532.
Created by Miltos Karabasilis (id: 2) at 2025-05-02 12:00:00
', 1),
('E-shop revenue', 154.26, '2025-05-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250503-426.
Created by Miltos Karabasilis (id: 2) at 2025-05-03 12:00:00
', 1),
('Physical store revenue', 94.54, '2025-05-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250503-454.
Created by Miltos Karabasilis (id: 2) at 2025-05-03 12:00:00
', 1),
('E-shop revenue', 157.73, '2025-05-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250504-773.
Created by Miltos Karabasilis (id: 2) at 2025-05-04 12:00:00
', 1),
('Physical store revenue', 96.67, '2025-05-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250504-667.
Created by Miltos Karabasilis (id: 2) at 2025-05-04 12:00:00
', 1),
('E-shop revenue', 145.70, '2025-05-05', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250505-570.
Created by Miltos Karabasilis (id: 2) at 2025-05-05 12:00:00
', 1),
('Physical store revenue', 89.30, '2025-05-05', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250505-930.
Created by Miltos Karabasilis (id: 2) at 2025-05-05 12:00:00
', 1),
('E-shop revenue', 136.77, '2025-05-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250506-677.
Created by Miltos Karabasilis (id: 2) at 2025-05-06 12:00:00
', 1),
('Physical store revenue', 83.83, '2025-05-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250506-383.
Created by Miltos Karabasilis (id: 2) at 2025-05-06 12:00:00
', 1),
('E-shop revenue', 131.13, '2025-05-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250507-113.
Created by Miltos Karabasilis (id: 2) at 2025-05-07 12:00:00
', 1),
('Physical store revenue', 80.37, '2025-05-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250507-037.
Created by Miltos Karabasilis (id: 2) at 2025-05-07 12:00:00
', 1),
('E-shop revenue', 134.60, '2025-05-08', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250508-460.
Created by Miltos Karabasilis (id: 2) at 2025-05-08 12:00:00
', 1),
('Physical store revenue', 82.50, '2025-05-08', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250508-250.
Created by Miltos Karabasilis (id: 2) at 2025-05-08 12:00:00
', 1),
('E-shop revenue', 138.07, '2025-05-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250509-807.
Created by Miltos Karabasilis (id: 2) at 2025-05-09 12:00:00
', 1),
('Physical store revenue', 84.63, '2025-05-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250509-463.
Created by Miltos Karabasilis (id: 2) at 2025-05-09 12:00:00
', 1),
('E-shop revenue', 169.45, '2025-05-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250510-945.
Created by Miltos Karabasilis (id: 2) at 2025-05-10 12:00:00
', 1),
('Physical store revenue', 103.85, '2025-05-10', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250510-385.
Created by Miltos Karabasilis (id: 2) at 2025-05-10 12:00:00
', 1),
('E-shop revenue', 172.92, '2025-05-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250511-292.
Created by Miltos Karabasilis (id: 2) at 2025-05-11 12:00:00
', 1),
('Physical store revenue', 105.98, '2025-05-11', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250511-598.
Created by Miltos Karabasilis (id: 2) at 2025-05-11 12:00:00
', 1),
('E-shop revenue', 160.89, '2025-05-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250512-089.
Created by Miltos Karabasilis (id: 2) at 2025-05-12 12:00:00
', 1),
('Physical store revenue', 98.61, '2025-05-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250512-861.
Created by Miltos Karabasilis (id: 2) at 2025-05-12 12:00:00
', 1),
('E-shop revenue', 151.96, '2025-05-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250513-196.
Created by Miltos Karabasilis (id: 2) at 2025-05-13 12:00:00
', 1),
('Physical store revenue', 93.14, '2025-05-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250513-314.
Created by Miltos Karabasilis (id: 2) at 2025-05-13 12:00:00
', 1),
('E-shop revenue', 146.32, '2025-05-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250514-632.
Created by Miltos Karabasilis (id: 2) at 2025-05-14 12:00:00
', 1),
('Physical store revenue', 89.68, '2025-05-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250514-968.
Created by Miltos Karabasilis (id: 2) at 2025-05-14 12:00:00
', 1),
('E-shop revenue', 149.79, '2025-05-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250515-979.
Created by Miltos Karabasilis (id: 2) at 2025-05-15 12:00:00
', 1),
('Physical store revenue', 91.81, '2025-05-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250515-181.
Created by Miltos Karabasilis (id: 2) at 2025-05-15 12:00:00
', 1),
('E-shop revenue', 153.26, '2025-05-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250516-326.
Created by Miltos Karabasilis (id: 2) at 2025-05-16 12:00:00
', 1),
('Physical store revenue', 93.94, '2025-05-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250516-394.
Created by Miltos Karabasilis (id: 2) at 2025-05-16 12:00:00
', 1),
('E-shop revenue', 147.75, '2025-05-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250517-775.
Created by Miltos Karabasilis (id: 2) at 2025-05-17 12:00:00
', 1),
('Physical store revenue', 90.55, '2025-05-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250517-055.
Created by Miltos Karabasilis (id: 2) at 2025-05-17 12:00:00
', 1),
('E-shop revenue', 151.22, '2025-05-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250518-122.
Created by Miltos Karabasilis (id: 2) at 2025-05-18 12:00:00
', 1),
('Physical store revenue', 92.68, '2025-05-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250518-268.
Created by Miltos Karabasilis (id: 2) at 2025-05-18 12:00:00
', 1),
('E-shop revenue', 139.19, '2025-05-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250519-919.
Created by Miltos Karabasilis (id: 2) at 2025-05-19 12:00:00
', 1),
('Physical store revenue', 85.31, '2025-05-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250519-531.
Created by Miltos Karabasilis (id: 2) at 2025-05-19 12:00:00
', 1),
('E-shop revenue', 130.26, '2025-05-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250520-026.
Created by Miltos Karabasilis (id: 2) at 2025-05-20 12:00:00
', 1),
('Physical store revenue', 79.84, '2025-05-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250520-984.
Created by Miltos Karabasilis (id: 2) at 2025-05-20 12:00:00
', 1),
('E-shop revenue', 124.62, '2025-05-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250521-462.
Created by Miltos Karabasilis (id: 2) at 2025-05-21 12:00:00
', 1),
('Physical store revenue', 76.38, '2025-05-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250521-638.
Created by Miltos Karabasilis (id: 2) at 2025-05-21 12:00:00
', 1),
('E-shop revenue', 128.09, '2025-05-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250522-809.
Created by Miltos Karabasilis (id: 2) at 2025-05-22 12:00:00
', 1),
('Physical store revenue', 78.51, '2025-05-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250522-851.
Created by Miltos Karabasilis (id: 2) at 2025-05-22 12:00:00
', 1),
('E-shop revenue', 131.56, '2025-05-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250523-156.
Created by Miltos Karabasilis (id: 2) at 2025-05-23 12:00:00
', 1),
('Physical store revenue', 80.64, '2025-05-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250523-064.
Created by Miltos Karabasilis (id: 2) at 2025-05-23 12:00:00
', 1),
('E-shop revenue', 162.94, '2025-05-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250524-294.
Created by Miltos Karabasilis (id: 2) at 2025-05-24 12:00:00
', 1),
('Physical store revenue', 99.86, '2025-05-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250524-986.
Created by Miltos Karabasilis (id: 2) at 2025-05-24 12:00:00
', 1),
('E-shop revenue', 166.41, '2025-05-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250525-641.
Created by Miltos Karabasilis (id: 2) at 2025-05-25 12:00:00
', 1),
('Physical store revenue', 101.99, '2025-05-25', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250525-199.
Created by Miltos Karabasilis (id: 2) at 2025-05-25 12:00:00
', 1),
('E-shop revenue', 154.38, '2025-05-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250526-438.
Created by Miltos Karabasilis (id: 2) at 2025-05-26 12:00:00
', 1),
('Physical store revenue', 94.62, '2025-05-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250526-462.
Created by Miltos Karabasilis (id: 2) at 2025-05-26 12:00:00
', 1),
('E-shop revenue', 145.45, '2025-05-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250527-545.
Created by Miltos Karabasilis (id: 2) at 2025-05-27 12:00:00
', 1),
('Physical store revenue', 89.15, '2025-05-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250527-915.
Created by Miltos Karabasilis (id: 2) at 2025-05-27 12:00:00
', 1),
('E-shop revenue', 139.81, '2025-05-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250528-981.
Created by Miltos Karabasilis (id: 2) at 2025-05-28 12:00:00
', 1),
('Physical store revenue', 85.69, '2025-05-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250528-569.
Created by Miltos Karabasilis (id: 2) at 2025-05-28 12:00:00
', 1),
('E-shop revenue', 143.28, '2025-05-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250529-328.
Created by Miltos Karabasilis (id: 2) at 2025-05-29 12:00:00
', 1),
('Physical store revenue', 87.82, '2025-05-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250529-782.
Created by Miltos Karabasilis (id: 2) at 2025-05-29 12:00:00
', 1),
('E-shop revenue', 146.75, '2025-05-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250530-675.
Created by Miltos Karabasilis (id: 2) at 2025-05-30 12:00:00
', 1),
('Physical store revenue', 89.95, '2025-05-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250530-995.
Created by Miltos Karabasilis (id: 2) at 2025-05-30 12:00:00
', 1),
('E-shop revenue', 178.13, '2025-05-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250531-813.
Created by Miltos Karabasilis (id: 2) at 2025-05-31 12:00:00
', 1),
('Physical store revenue', 109.17, '2025-05-31', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250531-917.
Created by Miltos Karabasilis (id: 2) at 2025-05-31 12:00:00
', 1),
('E-shop revenue', 178.44, '2025-06-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250601-844.
Created by Miltos Karabasilis (id: 2) at 2025-06-01 12:00:00
', 1),
('Physical store revenue', 109.36, '2025-06-01', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250601-936.
Created by Miltos Karabasilis (id: 2) at 2025-06-01 12:00:00
', 1),
('E-shop revenue', 166.41, '2025-06-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250602-641.
Created by Miltos Karabasilis (id: 2) at 2025-06-02 12:00:00
', 1),
('Physical store revenue', 101.99, '2025-06-02', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250602-199.
Created by Miltos Karabasilis (id: 2) at 2025-06-02 12:00:00
', 1),
('E-shop revenue', 120.59, '2025-06-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250603-059.
Created by Miltos Karabasilis (id: 2) at 2025-06-03 12:00:00
', 1),
('Physical store revenue', 73.91, '2025-06-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250603-391.
Created by Miltos Karabasilis (id: 2) at 2025-06-03 12:00:00
', 1),
('E-shop revenue', 124.06, '2025-06-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250604-406.
Created by Miltos Karabasilis (id: 2) at 2025-06-04 12:00:00
', 1),
('Physical store revenue', 76.04, '2025-06-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250604-604.
Created by Miltos Karabasilis (id: 2) at 2025-06-04 12:00:00
', 1),
('E-shop revenue', 127.53, '2025-06-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250605-753.
Created by Miltos Karabasilis (id: 2) at 2025-06-05 12:00:00
', 1),
('Physical store revenue', 78.17, '2025-06-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250605-817.
Created by Miltos Karabasilis (id: 2) at 2025-06-05 12:00:00
', 1),
('E-shop revenue', 131.01, '2025-06-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250606-101.
Created by Miltos Karabasilis (id: 2) at 2025-06-06 12:00:00
', 1),
('Physical store revenue', 80.29, '2025-06-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250606-029.
Created by Miltos Karabasilis (id: 2) at 2025-06-06 12:00:00
', 1),
('E-shop revenue', 153.26, '2025-06-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250607-326.
Created by Miltos Karabasilis (id: 2) at 2025-06-07 12:00:00
', 1),
('Physical store revenue', 93.94, '2025-06-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250607-394.
Created by Miltos Karabasilis (id: 2) at 2025-06-07 12:00:00
', 1),
('E-shop revenue', 156.74, '2025-06-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250608-674.
Created by Miltos Karabasilis (id: 2) at 2025-06-08 12:00:00
', 1),
('Physical store revenue', 96.06, '2025-06-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250608-606.
Created by Miltos Karabasilis (id: 2) at 2025-06-08 12:00:00
', 1),
('E-shop revenue', 144.71, '2025-06-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250609-471.
Created by Miltos Karabasilis (id: 2) at 2025-06-09 12:00:00
', 1),
('Physical store revenue', 88.69, '2025-06-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250609-869.
Created by Miltos Karabasilis (id: 2) at 2025-06-09 12:00:00
', 1),
('E-shop revenue', 135.78, '2025-06-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250610-578.
Created by Miltos Karabasilis (id: 2) at 2025-06-10 12:00:00
', 1),
('Physical store revenue', 83.22, '2025-06-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250610-322.
Created by Miltos Karabasilis (id: 2) at 2025-06-10 12:00:00
', 1),
('E-shop revenue', 139.25, '2025-06-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250611-925.
Created by Miltos Karabasilis (id: 2) at 2025-06-11 12:00:00
', 1),
('Physical store revenue', 85.35, '2025-06-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250611-535.
Created by Miltos Karabasilis (id: 2) at 2025-06-11 12:00:00
', 1),
('E-shop revenue', 142.72, '2025-06-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250612-272.
Created by Miltos Karabasilis (id: 2) at 2025-06-12 12:00:00
', 1),
('Physical store revenue', 87.48, '2025-06-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250612-748.
Created by Miltos Karabasilis (id: 2) at 2025-06-12 12:00:00
', 1),
('E-shop revenue', 146.20, '2025-06-13', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250613-620.
Created by Miltos Karabasilis (id: 2) at 2025-06-13 12:00:00
', 1),
('Physical store revenue', 89.60, '2025-06-13', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250613-960.
Created by Miltos Karabasilis (id: 2) at 2025-06-13 12:00:00
', 1),
('E-shop revenue', 168.45, '2025-06-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250614-845.
Created by Miltos Karabasilis (id: 2) at 2025-06-14 12:00:00
', 1),
('Physical store revenue', 103.25, '2025-06-14', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250614-325.
Created by Miltos Karabasilis (id: 2) at 2025-06-14 12:00:00
', 1),
('E-shop revenue', 171.93, '2025-06-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250615-193.
Created by Miltos Karabasilis (id: 2) at 2025-06-15 12:00:00
', 1),
('Physical store revenue', 105.37, '2025-06-15', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250615-537.
Created by Miltos Karabasilis (id: 2) at 2025-06-15 12:00:00
', 1),
('E-shop revenue', 159.90, '2025-06-16', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250616-990.
Created by Miltos Karabasilis (id: 2) at 2025-06-16 12:00:00
', 1),
('Physical store revenue', 98.00, '2025-06-16', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250616-800.
Created by Miltos Karabasilis (id: 2) at 2025-06-16 12:00:00
', 1),
('E-shop revenue', 150.97, '2025-06-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250617-097.
Created by Miltos Karabasilis (id: 2) at 2025-06-17 12:00:00
', 1),
('Physical store revenue', 92.53, '2025-06-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250617-253.
Created by Miltos Karabasilis (id: 2) at 2025-06-17 12:00:00
', 1),
('E-shop revenue', 154.44, '2025-06-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250618-444.
Created by Miltos Karabasilis (id: 2) at 2025-06-18 12:00:00
', 1),
('Physical store revenue', 94.66, '2025-06-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250618-466.
Created by Miltos Karabasilis (id: 2) at 2025-06-18 12:00:00
', 1),
('E-shop revenue', 157.91, '2025-06-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250619-791.
Created by Miltos Karabasilis (id: 2) at 2025-06-19 12:00:00
', 1),
('Physical store revenue', 96.79, '2025-06-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250619-679.
Created by Miltos Karabasilis (id: 2) at 2025-06-19 12:00:00
', 1),
('E-shop revenue', 124.50, '2025-06-20', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250620-450.
Created by Miltos Karabasilis (id: 2) at 2025-06-20 12:00:00
', 1),
('Physical store revenue', 76.30, '2025-06-20', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250620-630.
Created by Miltos Karabasilis (id: 2) at 2025-06-20 12:00:00
', 1),
('E-shop revenue', 146.75, '2025-06-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250621-675.
Created by Miltos Karabasilis (id: 2) at 2025-06-21 12:00:00
', 1),
('Physical store revenue', 89.95, '2025-06-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250621-995.
Created by Miltos Karabasilis (id: 2) at 2025-06-21 12:00:00
', 1),
('E-shop revenue', 150.23, '2025-06-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250622-023.
Created by Miltos Karabasilis (id: 2) at 2025-06-22 12:00:00
', 1),
('Physical store revenue', 92.07, '2025-06-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250622-207.
Created by Miltos Karabasilis (id: 2) at 2025-06-22 12:00:00
', 1),
('E-shop revenue', 138.20, '2025-06-23', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250623-820.
Created by Miltos Karabasilis (id: 2) at 2025-06-23 12:00:00
', 1),
('Physical store revenue', 84.70, '2025-06-23', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250623-470.
Created by Miltos Karabasilis (id: 2) at 2025-06-23 12:00:00
', 1),
('E-shop revenue', 129.27, '2025-06-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250624-927.
Created by Miltos Karabasilis (id: 2) at 2025-06-24 12:00:00
', 1),
('Physical store revenue', 79.23, '2025-06-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250624-923.
Created by Miltos Karabasilis (id: 2) at 2025-06-24 12:00:00
', 1),
('E-shop revenue', 132.74, '2025-06-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250625-274.
Created by Miltos Karabasilis (id: 2) at 2025-06-25 12:00:00
', 1),
('Physical store revenue', 81.36, '2025-06-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250625-136.
Created by Miltos Karabasilis (id: 2) at 2025-06-25 12:00:00
', 1),
('E-shop revenue', 136.21, '2025-06-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250626-621.
Created by Miltos Karabasilis (id: 2) at 2025-06-26 12:00:00
', 1),
('Physical store revenue', 83.49, '2025-06-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250626-349.
Created by Miltos Karabasilis (id: 2) at 2025-06-26 12:00:00
', 1),
('E-shop revenue', 139.69, '2025-06-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250627-969.
Created by Miltos Karabasilis (id: 2) at 2025-06-27 12:00:00
', 1),
('Physical store revenue', 85.61, '2025-06-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250627-561.
Created by Miltos Karabasilis (id: 2) at 2025-06-27 12:00:00
', 1),
('E-shop revenue', 161.94, '2025-06-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250628-194.
Created by Miltos Karabasilis (id: 2) at 2025-06-28 12:00:00
', 1),
('Physical store revenue', 99.26, '2025-06-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250628-926.
Created by Miltos Karabasilis (id: 2) at 2025-06-28 12:00:00
', 1),
('E-shop revenue', 165.42, '2025-06-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250629-542.
Created by Miltos Karabasilis (id: 2) at 2025-06-29 12:00:00
', 1),
('Physical store revenue', 101.38, '2025-06-29', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250629-138.
Created by Miltos Karabasilis (id: 2) at 2025-06-29 12:00:00
', 1),
('E-shop revenue', 153.39, '2025-06-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250630-339.
Created by Miltos Karabasilis (id: 2) at 2025-06-30 12:00:00
', 1),
('Physical store revenue', 94.01, '2025-06-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250630-401.
Created by Miltos Karabasilis (id: 2) at 2025-06-30 12:00:00
', 1),
('E-shop revenue', 142.60, '2025-07-01', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250701-260.
Created by Miltos Karabasilis (id: 2) at 2025-07-01 12:00:00
', 1),
('Physical store revenue', 87.40, '2025-07-01', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250701-740.
Created by Miltos Karabasilis (id: 2) at 2025-07-01 12:00:00
', 1),
('E-shop revenue', 146.07, '2025-07-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250702-607.
Created by Miltos Karabasilis (id: 2) at 2025-07-02 12:00:00
', 1),
('Physical store revenue', 89.53, '2025-07-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250702-953.
Created by Miltos Karabasilis (id: 2) at 2025-07-02 12:00:00
', 1),
('E-shop revenue', 149.54, '2025-07-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250703-954.
Created by Miltos Karabasilis (id: 2) at 2025-07-03 12:00:00
', 1),
('Physical store revenue', 91.66, '2025-07-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250703-166.
Created by Miltos Karabasilis (id: 2) at 2025-07-03 12:00:00
', 1),
('E-shop revenue', 153.02, '2025-07-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250704-302.
Created by Miltos Karabasilis (id: 2) at 2025-07-04 12:00:00
', 1),
('Physical store revenue', 93.78, '2025-07-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250704-378.
Created by Miltos Karabasilis (id: 2) at 2025-07-04 12:00:00
', 1),
('E-shop revenue', 184.39, '2025-07-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250705-439.
Created by Miltos Karabasilis (id: 2) at 2025-07-05 12:00:00
', 1),
('Physical store revenue', 113.01, '2025-07-05', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250705-301.
Created by Miltos Karabasilis (id: 2) at 2025-07-05 12:00:00
', 1),
('E-shop revenue', 187.86, '2025-07-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250706-786.
Created by Miltos Karabasilis (id: 2) at 2025-07-06 12:00:00
', 1),
('Physical store revenue', 115.14, '2025-07-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250706-514.
Created by Miltos Karabasilis (id: 2) at 2025-07-06 12:00:00
', 1),
('E-shop revenue', 129.83, '2025-07-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250707-983.
Created by Miltos Karabasilis (id: 2) at 2025-07-07 12:00:00
', 1),
('Physical store revenue', 79.57, '2025-07-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250707-957.
Created by Miltos Karabasilis (id: 2) at 2025-07-07 12:00:00
', 1),
('E-shop revenue', 120.90, '2025-07-08', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250708-090.
Created by Miltos Karabasilis (id: 2) at 2025-07-08 12:00:00
', 1),
('Physical store revenue', 74.10, '2025-07-08', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250708-410.
Created by Miltos Karabasilis (id: 2) at 2025-07-08 12:00:00
', 1),
('E-shop revenue', 124.37, '2025-07-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250709-437.
Created by Miltos Karabasilis (id: 2) at 2025-07-09 12:00:00
', 1),
('Physical store revenue', 76.23, '2025-07-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250709-623.
Created by Miltos Karabasilis (id: 2) at 2025-07-09 12:00:00
', 1),
('E-shop revenue', 127.84, '2025-07-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250710-784.
Created by Miltos Karabasilis (id: 2) at 2025-07-10 12:00:00
', 1),
('Physical store revenue', 78.36, '2025-07-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250710-836.
Created by Miltos Karabasilis (id: 2) at 2025-07-10 12:00:00
', 1),
('E-shop revenue', 131.32, '2025-07-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250711-132.
Created by Miltos Karabasilis (id: 2) at 2025-07-11 12:00:00
', 1),
('Physical store revenue', 80.48, '2025-07-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250711-048.
Created by Miltos Karabasilis (id: 2) at 2025-07-11 12:00:00
', 1),
('E-shop revenue', 162.69, '2025-07-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250712-269.
Created by Miltos Karabasilis (id: 2) at 2025-07-12 12:00:00
', 1),
('Physical store revenue', 99.71, '2025-07-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250712-971.
Created by Miltos Karabasilis (id: 2) at 2025-07-12 12:00:00
', 1),
('E-shop revenue', 166.16, '2025-07-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250713-616.
Created by Miltos Karabasilis (id: 2) at 2025-07-13 12:00:00
', 1),
('Physical store revenue', 101.84, '2025-07-13', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250713-184.
Created by Miltos Karabasilis (id: 2) at 2025-07-13 12:00:00
', 1),
('E-shop revenue', 145.02, '2025-07-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250714-502.
Created by Miltos Karabasilis (id: 2) at 2025-07-14 12:00:00
', 1),
('Physical store revenue', 88.88, '2025-07-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250714-888.
Created by Miltos Karabasilis (id: 2) at 2025-07-14 12:00:00
', 1),
('E-shop revenue', 136.09, '2025-07-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250715-609.
Created by Miltos Karabasilis (id: 2) at 2025-07-15 12:00:00
', 1),
('Physical store revenue', 83.41, '2025-07-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250715-341.
Created by Miltos Karabasilis (id: 2) at 2025-07-15 12:00:00
', 1),
('E-shop revenue', 139.56, '2025-07-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250716-956.
Created by Miltos Karabasilis (id: 2) at 2025-07-16 12:00:00
', 1),
('Physical store revenue', 85.54, '2025-07-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250716-554.
Created by Miltos Karabasilis (id: 2) at 2025-07-16 12:00:00
', 1),
('E-shop revenue', 143.03, '2025-07-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250717-303.
Created by Miltos Karabasilis (id: 2) at 2025-07-17 12:00:00
', 1),
('Physical store revenue', 87.67, '2025-07-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250717-767.
Created by Miltos Karabasilis (id: 2) at 2025-07-17 12:00:00
', 1),
('E-shop revenue', 146.51, '2025-07-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250718-651.
Created by Miltos Karabasilis (id: 2) at 2025-07-18 12:00:00
', 1),
('Physical store revenue', 89.79, '2025-07-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250718-979.
Created by Miltos Karabasilis (id: 2) at 2025-07-18 12:00:00
', 1),
('E-shop revenue', 177.88, '2025-07-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250719-788.
Created by Miltos Karabasilis (id: 2) at 2025-07-19 12:00:00
', 1),
('Physical store revenue', 109.02, '2025-07-19', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250719-902.
Created by Miltos Karabasilis (id: 2) at 2025-07-19 12:00:00
', 1),
('E-shop revenue', 181.35, '2025-07-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250720-135.
Created by Miltos Karabasilis (id: 2) at 2025-07-20 12:00:00
', 1),
('Physical store revenue', 111.15, '2025-07-20', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250720-115.
Created by Miltos Karabasilis (id: 2) at 2025-07-20 12:00:00
', 1),
('E-shop revenue', 160.21, '2025-07-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250721-021.
Created by Miltos Karabasilis (id: 2) at 2025-07-21 12:00:00
', 1),
('Physical store revenue', 98.19, '2025-07-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250721-819.
Created by Miltos Karabasilis (id: 2) at 2025-07-21 12:00:00
', 1),
('E-shop revenue', 151.28, '2025-07-22', 'Corporate buyer: BrightDesk Ltd, 18 Industrial Zone Rd, Patras 265 04. 26 office chairs shipped from warehouse bay C1.
Created by Miltos Karabasilis (id: 2) at 2025-07-22 12:00:00
', 1),
('Physical store revenue', 92.72, '2025-07-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250722-272.
Created by Miltos Karabasilis (id: 2) at 2025-07-22 12:00:00
', 1),
('E-shop revenue', 154.75, '2025-07-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250723-475.
Created by Miltos Karabasilis (id: 2) at 2025-07-23 12:00:00
', 1),
('Physical store revenue', 94.85, '2025-07-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250723-485.
Created by Miltos Karabasilis (id: 2) at 2025-07-23 12:00:00
', 1),
('E-shop revenue', 121.33, '2025-07-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250724-133.
Created by Miltos Karabasilis (id: 2) at 2025-07-24 12:00:00
', 1),
('Physical store revenue', 74.37, '2025-07-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250724-437.
Created by Miltos Karabasilis (id: 2) at 2025-07-24 12:00:00
', 1),
('E-shop revenue', 124.81, '2025-07-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250725-481.
Created by Miltos Karabasilis (id: 2) at 2025-07-25 12:00:00
', 1),
('Physical store revenue', 76.49, '2025-07-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250725-649.
Created by Miltos Karabasilis (id: 2) at 2025-07-25 12:00:00
', 1),
('E-shop revenue', 156.18, '2025-07-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250726-618.
Created by Miltos Karabasilis (id: 2) at 2025-07-26 12:00:00
', 1),
('Physical store revenue', 95.72, '2025-07-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250726-572.
Created by Miltos Karabasilis (id: 2) at 2025-07-26 12:00:00
', 1),
('E-shop revenue', 159.65, '2025-07-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250727-965.
Created by Miltos Karabasilis (id: 2) at 2025-07-27 12:00:00
', 1),
('Physical store revenue', 97.85, '2025-07-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250727-785.
Created by Miltos Karabasilis (id: 2) at 2025-07-27 12:00:00
', 1),
('E-shop revenue', 138.51, '2025-07-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250728-851.
Created by Miltos Karabasilis (id: 2) at 2025-07-28 12:00:00
', 1),
('Physical store revenue', 84.89, '2025-07-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250728-489.
Created by Miltos Karabasilis (id: 2) at 2025-07-28 12:00:00
', 1),
('E-shop revenue', 129.58, '2025-07-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250729-958.
Created by Miltos Karabasilis (id: 2) at 2025-07-29 12:00:00
', 1),
('Physical store revenue', 79.42, '2025-07-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250729-942.
Created by Miltos Karabasilis (id: 2) at 2025-07-29 12:00:00
', 1),
('E-shop revenue', 133.05, '2025-07-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250730-305.
Created by Miltos Karabasilis (id: 2) at 2025-07-30 12:00:00
', 1),
('Physical store revenue', 81.55, '2025-07-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250730-155.
Created by Miltos Karabasilis (id: 2) at 2025-07-30 12:00:00
', 1),
('E-shop revenue', 136.52, '2025-07-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250731-652.
Created by Miltos Karabasilis (id: 2) at 2025-07-31 12:00:00
', 1),
('Physical store revenue', 83.68, '2025-07-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250731-368.
Created by Miltos Karabasilis (id: 2) at 2025-07-31 12:00:00
', 1),
('E-shop revenue', 136.83, '2025-08-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250801-683.
Created by Miltos Karabasilis (id: 2) at 2025-08-01 12:00:00
', 1),
('Physical store revenue', 83.87, '2025-08-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250801-387.
Created by Miltos Karabasilis (id: 2) at 2025-08-01 12:00:00
', 1),
('E-shop revenue', 168.21, '2025-08-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250802-821.
Created by Miltos Karabasilis (id: 2) at 2025-08-02 12:00:00
', 1),
('Physical store revenue', 103.09, '2025-08-02', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250802-309.
Created by Miltos Karabasilis (id: 2) at 2025-08-02 12:00:00
', 1),
('E-shop revenue', 171.68, '2025-08-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250803-168.
Created by Miltos Karabasilis (id: 2) at 2025-08-03 12:00:00
', 1),
('Physical store revenue', 105.22, '2025-08-03', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250803-522.
Created by Miltos Karabasilis (id: 2) at 2025-08-03 12:00:00
', 1),
('E-shop revenue', 159.65, '2025-08-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250804-965.
Created by Miltos Karabasilis (id: 2) at 2025-08-04 12:00:00
', 1),
('Physical store revenue', 97.85, '2025-08-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250804-785.
Created by Miltos Karabasilis (id: 2) at 2025-08-04 12:00:00
', 1),
('E-shop revenue', 150.72, '2025-08-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250805-072.
Created by Miltos Karabasilis (id: 2) at 2025-08-05 12:00:00
', 1),
('Physical store revenue', 92.38, '2025-08-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250805-238.
Created by Miltos Karabasilis (id: 2) at 2025-08-05 12:00:00
', 1),
('E-shop revenue', 154.19, '2025-08-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250806-419.
Created by Miltos Karabasilis (id: 2) at 2025-08-06 12:00:00
', 1),
('Physical store revenue', 94.51, '2025-08-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250806-451.
Created by Miltos Karabasilis (id: 2) at 2025-08-06 12:00:00
', 1),
('E-shop revenue', 148.55, '2025-08-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250807-855.
Created by Miltos Karabasilis (id: 2) at 2025-08-07 12:00:00
', 1),
('Physical store revenue', 91.05, '2025-08-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250807-105.
Created by Miltos Karabasilis (id: 2) at 2025-08-07 12:00:00
', 1),
('E-shop revenue', 152.02, '2025-08-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250808-202.
Created by Miltos Karabasilis (id: 2) at 2025-08-08 12:00:00
', 1),
('Physical store revenue', 93.18, '2025-08-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250808-318.
Created by Miltos Karabasilis (id: 2) at 2025-08-08 12:00:00
', 1),
('E-shop revenue', 183.40, '2025-08-09', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20250809-340.
Created by Miltos Karabasilis (id: 2) at 2025-08-09 12:00:00
', 1),
('Physical store revenue', 112.40, '2025-08-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250809-240.
Created by Miltos Karabasilis (id: 2) at 2025-08-09 12:00:00
', 1),
('E-shop revenue', 149.98, '2025-08-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250810-998.
Created by Miltos Karabasilis (id: 2) at 2025-08-10 12:00:00
', 1),
('Physical store revenue', 91.92, '2025-08-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250810-192.
Created by Miltos Karabasilis (id: 2) at 2025-08-10 12:00:00
', 1),
('E-shop revenue', 137.95, '2025-08-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250811-795.
Created by Miltos Karabasilis (id: 2) at 2025-08-11 12:00:00
', 1),
('Physical store revenue', 84.55, '2025-08-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250811-455.
Created by Miltos Karabasilis (id: 2) at 2025-08-11 12:00:00
', 1),
('E-shop revenue', 129.02, '2025-08-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250812-902.
Created by Miltos Karabasilis (id: 2) at 2025-08-12 12:00:00
', 1),
('Physical store revenue', 79.08, '2025-08-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250812-908.
Created by Miltos Karabasilis (id: 2) at 2025-08-12 12:00:00
', 1),
('E-shop revenue', 132.49, '2025-08-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250813-249.
Created by Miltos Karabasilis (id: 2) at 2025-08-13 12:00:00
', 1),
('Physical store revenue', 81.21, '2025-08-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250813-121.
Created by Miltos Karabasilis (id: 2) at 2025-08-13 12:00:00
', 1),
('E-shop revenue', 126.85, '2025-08-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250814-685.
Created by Miltos Karabasilis (id: 2) at 2025-08-14 12:00:00
', 1),
('Physical store revenue', 77.75, '2025-08-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250814-775.
Created by Miltos Karabasilis (id: 2) at 2025-08-14 12:00:00
', 1),
('E-shop revenue', 130.32, '2025-08-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250815-032.
Created by Miltos Karabasilis (id: 2) at 2025-08-15 12:00:00
', 1),
('Physical store revenue', 79.88, '2025-08-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250815-988.
Created by Miltos Karabasilis (id: 2) at 2025-08-15 12:00:00
', 1),
('E-shop revenue', 161.70, '2025-08-16', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20250816-170.
Created by Miltos Karabasilis (id: 2) at 2025-08-16 12:00:00
', 1),
('Physical store revenue', 99.10, '2025-08-16', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250816-910.
Created by Miltos Karabasilis (id: 2) at 2025-08-16 12:00:00
', 1),
('E-shop revenue', 165.17, '2025-08-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250817-517.
Created by Miltos Karabasilis (id: 2) at 2025-08-17 12:00:00
', 1),
('Physical store revenue', 101.23, '2025-08-17', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250817-123.
Created by Miltos Karabasilis (id: 2) at 2025-08-17 12:00:00
', 1),
('E-shop revenue', 153.14, '2025-08-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250818-314.
Created by Miltos Karabasilis (id: 2) at 2025-08-18 12:00:00
', 1),
('Physical store revenue', 93.86, '2025-08-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250818-386.
Created by Miltos Karabasilis (id: 2) at 2025-08-18 12:00:00
', 1),
('E-shop revenue', 144.21, '2025-08-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250819-421.
Created by Miltos Karabasilis (id: 2) at 2025-08-19 12:00:00
', 1),
('Physical store revenue', 88.39, '2025-08-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250819-839.
Created by Miltos Karabasilis (id: 2) at 2025-08-19 12:00:00
', 1),
('E-shop revenue', 147.68, '2025-08-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250820-768.
Created by Miltos Karabasilis (id: 2) at 2025-08-20 12:00:00
', 1),
('Physical store revenue', 90.52, '2025-08-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250820-052.
Created by Miltos Karabasilis (id: 2) at 2025-08-20 12:00:00
', 1),
('E-shop revenue', 142.04, '2025-08-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250821-204.
Created by Miltos Karabasilis (id: 2) at 2025-08-21 12:00:00
', 1),
('Physical store revenue', 87.06, '2025-08-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250821-706.
Created by Miltos Karabasilis (id: 2) at 2025-08-21 12:00:00
', 1),
('E-shop revenue', 145.51, '2025-08-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250822-551.
Created by Miltos Karabasilis (id: 2) at 2025-08-22 12:00:00
', 1),
('Physical store revenue', 89.19, '2025-08-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250822-919.
Created by Miltos Karabasilis (id: 2) at 2025-08-22 12:00:00
', 1),
('E-shop revenue', 176.89, '2025-08-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250823-689.
Created by Miltos Karabasilis (id: 2) at 2025-08-23 12:00:00
', 1),
('Physical store revenue', 108.41, '2025-08-23', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250823-841.
Created by Miltos Karabasilis (id: 2) at 2025-08-23 12:00:00
', 1),
('E-shop revenue', 180.36, '2025-08-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250824-036.
Created by Miltos Karabasilis (id: 2) at 2025-08-24 12:00:00
', 1),
('Physical store revenue', 110.54, '2025-08-24', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250824-054.
Created by Miltos Karabasilis (id: 2) at 2025-08-24 12:00:00
', 1),
('E-shop revenue', 168.33, '2025-08-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250825-833.
Created by Miltos Karabasilis (id: 2) at 2025-08-25 12:00:00
', 1),
('Physical store revenue', 103.17, '2025-08-25', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250825-317.
Created by Miltos Karabasilis (id: 2) at 2025-08-25 12:00:00
', 1),
('E-shop revenue', 159.40, '2025-08-26', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250826-940.
Created by Miltos Karabasilis (id: 2) at 2025-08-26 12:00:00
', 1),
('Physical store revenue', 97.70, '2025-08-26', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250826-770.
Created by Miltos Karabasilis (id: 2) at 2025-08-26 12:00:00
', 1),
('E-shop revenue', 125.98, '2025-08-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250827-598.
Created by Miltos Karabasilis (id: 2) at 2025-08-27 12:00:00
', 1),
('Physical store revenue', 77.22, '2025-08-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250827-722.
Created by Miltos Karabasilis (id: 2) at 2025-08-27 12:00:00
', 1),
('E-shop revenue', 120.34, '2025-08-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250828-034.
Created by Miltos Karabasilis (id: 2) at 2025-08-28 12:00:00
', 1),
('Physical store revenue', 73.76, '2025-08-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250828-376.
Created by Miltos Karabasilis (id: 2) at 2025-08-28 12:00:00
', 1),
('E-shop revenue', 123.81, '2025-08-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250829-381.
Created by Miltos Karabasilis (id: 2) at 2025-08-29 12:00:00
', 1),
('Physical store revenue', 75.89, '2025-08-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250829-589.
Created by Miltos Karabasilis (id: 2) at 2025-08-29 12:00:00
', 1),
('E-shop revenue', 155.19, '2025-08-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250830-519.
Created by Miltos Karabasilis (id: 2) at 2025-08-30 12:00:00
', 1),
('Physical store revenue', 95.11, '2025-08-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250830-511.
Created by Miltos Karabasilis (id: 2) at 2025-08-30 12:00:00
', 1),
('E-shop revenue', 158.66, '2025-08-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250831-866.
Created by Miltos Karabasilis (id: 2) at 2025-08-31 12:00:00
', 1),
('Physical store revenue', 97.24, '2025-08-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250831-724.
Created by Miltos Karabasilis (id: 2) at 2025-08-31 12:00:00
', 1),
('E-shop revenue', 143.47, '2025-09-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250901-347.
Created by Miltos Karabasilis (id: 2) at 2025-09-01 12:00:00
', 1),
('Physical store revenue', 87.93, '2025-09-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250901-793.
Created by Miltos Karabasilis (id: 2) at 2025-09-01 12:00:00
', 1),
('E-shop revenue', 134.54, '2025-09-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250902-454.
Created by Miltos Karabasilis (id: 2) at 2025-09-02 12:00:00
', 1),
('Physical store revenue', 82.46, '2025-09-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250902-246.
Created by Miltos Karabasilis (id: 2) at 2025-09-02 12:00:00
', 1),
('E-shop revenue', 138.01, '2025-09-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250903-801.
Created by Miltos Karabasilis (id: 2) at 2025-09-03 12:00:00
', 1),
('Physical store revenue', 84.59, '2025-09-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250903-459.
Created by Miltos Karabasilis (id: 2) at 2025-09-03 12:00:00
', 1),
('E-shop revenue', 141.48, '2025-09-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250904-148.
Created by Miltos Karabasilis (id: 2) at 2025-09-04 12:00:00
', 1),
('Physical store revenue', 86.72, '2025-09-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250904-672.
Created by Miltos Karabasilis (id: 2) at 2025-09-04 12:00:00
', 1),
('E-shop revenue', 144.96, '2025-09-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250905-496.
Created by Miltos Karabasilis (id: 2) at 2025-09-05 12:00:00
', 1),
('Physical store revenue', 88.84, '2025-09-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250905-884.
Created by Miltos Karabasilis (id: 2) at 2025-09-05 12:00:00
', 1),
('E-shop revenue', 176.33, '2025-09-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250906-633.
Created by Miltos Karabasilis (id: 2) at 2025-09-06 12:00:00
', 1),
('Physical store revenue', 108.07, '2025-09-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250906-807.
Created by Miltos Karabasilis (id: 2) at 2025-09-06 12:00:00
', 1),
('E-shop revenue', 170.69, '2025-09-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250907-069.
Created by Miltos Karabasilis (id: 2) at 2025-09-07 12:00:00
', 1),
('Physical store revenue', 104.61, '2025-09-07', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250907-461.
Created by Miltos Karabasilis (id: 2) at 2025-09-07 12:00:00
', 1),
('E-shop revenue', 158.66, '2025-09-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250908-866.
Created by Miltos Karabasilis (id: 2) at 2025-09-08 12:00:00
', 1),
('Physical store revenue', 97.24, '2025-09-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250908-724.
Created by Miltos Karabasilis (id: 2) at 2025-09-08 12:00:00
', 1),
('E-shop revenue', 149.73, '2025-09-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250909-973.
Created by Miltos Karabasilis (id: 2) at 2025-09-09 12:00:00
', 1),
('Physical store revenue', 91.77, '2025-09-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250909-177.
Created by Miltos Karabasilis (id: 2) at 2025-09-09 12:00:00
', 1),
('E-shop revenue', 153.20, '2025-09-10', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250910-320.
Created by Miltos Karabasilis (id: 2) at 2025-09-10 12:00:00
', 1),
('Physical store revenue', 93.90, '2025-09-10', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250910-390.
Created by Miltos Karabasilis (id: 2) at 2025-09-10 12:00:00
', 1),
('E-shop revenue', 156.67, '2025-09-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250911-667.
Created by Miltos Karabasilis (id: 2) at 2025-09-11 12:00:00
', 1),
('Physical store revenue', 96.03, '2025-09-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250911-603.
Created by Miltos Karabasilis (id: 2) at 2025-09-11 12:00:00
', 1),
('E-shop revenue', 160.15, '2025-09-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250912-015.
Created by Miltos Karabasilis (id: 2) at 2025-09-12 12:00:00
', 1),
('Physical store revenue', 98.15, '2025-09-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250912-815.
Created by Miltos Karabasilis (id: 2) at 2025-09-12 12:00:00
', 1),
('E-shop revenue', 154.63, '2025-09-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250913-463.
Created by Miltos Karabasilis (id: 2) at 2025-09-13 12:00:00
', 1),
('Physical store revenue', 94.77, '2025-09-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250913-477.
Created by Miltos Karabasilis (id: 2) at 2025-09-13 12:00:00
', 1),
('E-shop revenue', 148.99, '2025-09-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250914-899.
Created by Miltos Karabasilis (id: 2) at 2025-09-14 12:00:00
', 1),
('Physical store revenue', 91.31, '2025-09-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250914-131.
Created by Miltos Karabasilis (id: 2) at 2025-09-14 12:00:00
', 1),
('E-shop revenue', 136.96, '2025-09-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250915-696.
Created by Miltos Karabasilis (id: 2) at 2025-09-15 12:00:00
', 1),
('Physical store revenue', 83.94, '2025-09-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250915-394.
Created by Miltos Karabasilis (id: 2) at 2025-09-15 12:00:00
', 1),
('E-shop revenue', 128.03, '2025-09-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250916-803.
Created by Miltos Karabasilis (id: 2) at 2025-09-16 12:00:00
', 1),
('Physical store revenue', 78.47, '2025-09-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250916-847.
Created by Miltos Karabasilis (id: 2) at 2025-09-16 12:00:00
', 1),
('E-shop revenue', 131.50, '2025-09-17', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20250917-150.
Created by Miltos Karabasilis (id: 2) at 2025-09-17 12:00:00
', 1),
('Physical store revenue', 80.60, '2025-09-17', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20250917-060.
Created by Miltos Karabasilis (id: 2) at 2025-09-17 12:00:00
', 1),
('E-shop revenue', 134.97, '2025-09-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250918-497.
Created by Miltos Karabasilis (id: 2) at 2025-09-18 12:00:00
', 1),
('Physical store revenue', 82.73, '2025-09-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250918-273.
Created by Miltos Karabasilis (id: 2) at 2025-09-18 12:00:00
', 1),
('E-shop revenue', 138.45, '2025-09-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250919-845.
Created by Miltos Karabasilis (id: 2) at 2025-09-19 12:00:00
', 1),
('Physical store revenue', 84.85, '2025-09-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250919-485.
Created by Miltos Karabasilis (id: 2) at 2025-09-19 12:00:00
', 1),
('E-shop revenue', 169.82, '2025-09-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250920-982.
Created by Miltos Karabasilis (id: 2) at 2025-09-20 12:00:00
', 1),
('Physical store revenue', 104.08, '2025-09-20', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250920-408.
Created by Miltos Karabasilis (id: 2) at 2025-09-20 12:00:00
', 1),
('E-shop revenue', 164.18, '2025-09-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250921-418.
Created by Miltos Karabasilis (id: 2) at 2025-09-21 12:00:00
', 1),
('Physical store revenue', 100.62, '2025-09-21', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250921-062.
Created by Miltos Karabasilis (id: 2) at 2025-09-21 12:00:00
', 1),
('E-shop revenue', 152.15, '2025-09-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250922-215.
Created by Miltos Karabasilis (id: 2) at 2025-09-22 12:00:00
', 1),
('Physical store revenue', 93.25, '2025-09-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250922-325.
Created by Miltos Karabasilis (id: 2) at 2025-09-22 12:00:00
', 1),
('E-shop revenue', 143.22, '2025-09-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250923-322.
Created by Miltos Karabasilis (id: 2) at 2025-09-23 12:00:00
', 1),
('Physical store revenue', 87.78, '2025-09-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250923-778.
Created by Miltos Karabasilis (id: 2) at 2025-09-23 12:00:00
', 1),
('E-shop revenue', 146.69, '2025-09-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250924-669.
Created by Miltos Karabasilis (id: 2) at 2025-09-24 12:00:00
', 1),
('Physical store revenue', 89.91, '2025-09-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250924-991.
Created by Miltos Karabasilis (id: 2) at 2025-09-24 12:00:00
', 1),
('E-shop revenue', 150.16, '2025-09-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250925-016.
Created by Miltos Karabasilis (id: 2) at 2025-09-25 12:00:00
', 1),
('Physical store revenue', 92.04, '2025-09-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250925-204.
Created by Miltos Karabasilis (id: 2) at 2025-09-25 12:00:00
', 1),
('E-shop revenue', 153.64, '2025-09-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250926-364.
Created by Miltos Karabasilis (id: 2) at 2025-09-26 12:00:00
', 1),
('Physical store revenue', 94.16, '2025-09-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250926-416.
Created by Miltos Karabasilis (id: 2) at 2025-09-26 12:00:00
', 1),
('E-shop revenue', 185.01, '2025-09-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250927-501.
Created by Miltos Karabasilis (id: 2) at 2025-09-27 12:00:00
', 1),
('Physical store revenue', 113.39, '2025-09-27', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250927-339.
Created by Miltos Karabasilis (id: 2) at 2025-09-27 12:00:00
', 1),
('E-shop revenue', 179.37, '2025-09-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20250928-937.
Created by Miltos Karabasilis (id: 2) at 2025-09-28 12:00:00
', 1),
('Physical store revenue', 109.93, '2025-09-28', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250928-993.
Created by Miltos Karabasilis (id: 2) at 2025-09-28 12:00:00
', 1),
('E-shop revenue', 167.34, '2025-09-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250929-734.
Created by Miltos Karabasilis (id: 2) at 2025-09-29 12:00:00
', 1),
('Physical store revenue', 102.56, '2025-09-29', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20250929-256.
Created by Miltos Karabasilis (id: 2) at 2025-09-29 12:00:00
', 1),
('E-shop revenue', 121.52, '2025-09-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20250930-152.
Created by Miltos Karabasilis (id: 2) at 2025-09-30 12:00:00
', 1),
('Physical store revenue', 74.48, '2025-09-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20250930-448.
Created by Miltos Karabasilis (id: 2) at 2025-09-30 12:00:00
', 1),
('E-shop revenue', 123.13, '2025-10-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251001-313.
Created by Miltos Karabasilis (id: 2) at 2025-10-01 12:00:00
', 1),
('Physical store revenue', 75.47, '2025-10-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251001-547.
Created by Miltos Karabasilis (id: 2) at 2025-10-01 12:00:00
', 1),
('E-shop revenue', 126.60, '2025-10-02', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20251002-660.
Created by Miltos Karabasilis (id: 2) at 2025-10-02 12:00:00
', 1),
('Physical store revenue', 77.60, '2025-10-02', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20251002-760.
Created by Miltos Karabasilis (id: 2) at 2025-10-02 12:00:00
', 1),
('E-shop revenue', 130.08, '2025-10-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251003-008.
Created by Miltos Karabasilis (id: 2) at 2025-10-03 12:00:00
', 1),
('Physical store revenue', 79.72, '2025-10-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251003-972.
Created by Miltos Karabasilis (id: 2) at 2025-10-03 12:00:00
', 1),
('E-shop revenue', 161.45, '2025-10-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251004-145.
Created by Miltos Karabasilis (id: 2) at 2025-10-04 12:00:00
', 1),
('Physical store revenue', 98.95, '2025-10-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251004-895.
Created by Miltos Karabasilis (id: 2) at 2025-10-04 12:00:00
', 1),
('E-shop revenue', 164.92, '2025-10-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251005-492.
Created by Miltos Karabasilis (id: 2) at 2025-10-05 12:00:00
', 1),
('Physical store revenue', 101.08, '2025-10-05', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251005-108.
Created by Miltos Karabasilis (id: 2) at 2025-10-05 12:00:00
', 1),
('E-shop revenue', 152.89, '2025-10-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251006-289.
Created by Miltos Karabasilis (id: 2) at 2025-10-06 12:00:00
', 1),
('Physical store revenue', 93.71, '2025-10-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251006-371.
Created by Miltos Karabasilis (id: 2) at 2025-10-06 12:00:00
', 1),
('E-shop revenue', 134.85, '2025-10-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251007-485.
Created by Miltos Karabasilis (id: 2) at 2025-10-07 12:00:00
', 1),
('Physical store revenue', 82.65, '2025-10-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251007-265.
Created by Miltos Karabasilis (id: 2) at 2025-10-07 12:00:00
', 1),
('E-shop revenue', 138.32, '2025-10-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251008-832.
Created by Miltos Karabasilis (id: 2) at 2025-10-08 12:00:00
', 1),
('Physical store revenue', 84.78, '2025-10-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251008-478.
Created by Miltos Karabasilis (id: 2) at 2025-10-08 12:00:00
', 1),
('E-shop revenue', 141.79, '2025-10-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251009-179.
Created by Miltos Karabasilis (id: 2) at 2025-10-09 12:00:00
', 1),
('Physical store revenue', 86.91, '2025-10-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251009-691.
Created by Miltos Karabasilis (id: 2) at 2025-10-09 12:00:00
', 1),
('E-shop revenue', 145.27, '2025-10-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251010-527.
Created by Miltos Karabasilis (id: 2) at 2025-10-10 12:00:00
', 1),
('Physical store revenue', 89.03, '2025-10-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251010-903.
Created by Miltos Karabasilis (id: 2) at 2025-10-10 12:00:00
', 1),
('E-shop revenue', 176.64, '2025-10-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251011-664.
Created by Miltos Karabasilis (id: 2) at 2025-10-11 12:00:00
', 1),
('Physical store revenue', 108.26, '2025-10-11', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251011-826.
Created by Miltos Karabasilis (id: 2) at 2025-10-11 12:00:00
', 1),
('E-shop revenue', 180.11, '2025-10-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251012-011.
Created by Miltos Karabasilis (id: 2) at 2025-10-12 12:00:00
', 1),
('Physical store revenue', 110.39, '2025-10-12', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251012-039.
Created by Miltos Karabasilis (id: 2) at 2025-10-12 12:00:00
', 1),
('E-shop revenue', 168.08, '2025-10-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251013-808.
Created by Miltos Karabasilis (id: 2) at 2025-10-13 12:00:00
', 1),
('Physical store revenue', 103.02, '2025-10-13', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251013-302.
Created by Miltos Karabasilis (id: 2) at 2025-10-13 12:00:00
', 1),
('E-shop revenue', 150.04, '2025-10-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251014-004.
Created by Miltos Karabasilis (id: 2) at 2025-10-14 12:00:00
', 1),
('Physical store revenue', 91.96, '2025-10-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251014-196.
Created by Miltos Karabasilis (id: 2) at 2025-10-14 12:00:00
', 1),
('E-shop revenue', 153.51, '2025-10-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251015-351.
Created by Miltos Karabasilis (id: 2) at 2025-10-15 12:00:00
', 1),
('Physical store revenue', 94.09, '2025-10-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251015-409.
Created by Miltos Karabasilis (id: 2) at 2025-10-15 12:00:00
', 1),
('E-shop revenue', 156.98, '2025-10-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251016-698.
Created by Miltos Karabasilis (id: 2) at 2025-10-16 12:00:00
', 1),
('Physical store revenue', 96.22, '2025-10-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251016-622.
Created by Miltos Karabasilis (id: 2) at 2025-10-16 12:00:00
', 1),
('E-shop revenue', 123.57, '2025-10-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251017-357.
Created by Miltos Karabasilis (id: 2) at 2025-10-17 12:00:00
', 1),
('Physical store revenue', 75.73, '2025-10-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251017-573.
Created by Miltos Karabasilis (id: 2) at 2025-10-17 12:00:00
', 1),
('E-shop revenue', 154.94, '2025-10-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251018-494.
Created by Miltos Karabasilis (id: 2) at 2025-10-18 12:00:00
', 1),
('Physical store revenue', 94.96, '2025-10-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251018-496.
Created by Miltos Karabasilis (id: 2) at 2025-10-18 12:00:00
', 1),
('E-shop revenue', 158.41, '2025-10-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251019-841.
Created by Miltos Karabasilis (id: 2) at 2025-10-19 12:00:00
', 1),
('Physical store revenue', 97.09, '2025-10-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251019-709.
Created by Miltos Karabasilis (id: 2) at 2025-10-19 12:00:00
', 1),
('E-shop revenue', 146.38, '2025-10-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251020-638.
Created by Miltos Karabasilis (id: 2) at 2025-10-20 12:00:00
', 1),
('Physical store revenue', 89.72, '2025-10-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251020-972.
Created by Miltos Karabasilis (id: 2) at 2025-10-20 12:00:00
', 1),
('E-shop revenue', 128.34, '2025-10-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251021-834.
Created by Miltos Karabasilis (id: 2) at 2025-10-21 12:00:00
', 1),
('Physical store revenue', 78.66, '2025-10-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251021-866.
Created by Miltos Karabasilis (id: 2) at 2025-10-21 12:00:00
', 1),
('E-shop revenue', 131.81, '2025-10-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251022-181.
Created by Miltos Karabasilis (id: 2) at 2025-10-22 12:00:00
', 1),
('Physical store revenue', 80.79, '2025-10-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251022-079.
Created by Miltos Karabasilis (id: 2) at 2025-10-22 12:00:00
', 1),
('E-shop revenue', 135.28, '2025-10-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251023-528.
Created by Miltos Karabasilis (id: 2) at 2025-10-23 12:00:00
', 1),
('Physical store revenue', 82.92, '2025-10-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251023-292.
Created by Miltos Karabasilis (id: 2) at 2025-10-23 12:00:00
', 1),
('E-shop revenue', 138.76, '2025-10-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251024-876.
Created by Miltos Karabasilis (id: 2) at 2025-10-24 12:00:00
', 1),
('Physical store revenue', 85.04, '2025-10-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251024-504.
Created by Miltos Karabasilis (id: 2) at 2025-10-24 12:00:00
', 1),
('E-shop revenue', 170.13, '2025-10-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251025-013.
Created by Miltos Karabasilis (id: 2) at 2025-10-25 12:00:00
', 1),
('Physical store revenue', 104.27, '2025-10-25', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251025-427.
Created by Miltos Karabasilis (id: 2) at 2025-10-25 12:00:00
', 1),
('E-shop revenue', 173.60, '2025-10-26', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20251026-360.
Created by Miltos Karabasilis (id: 2) at 2025-10-26 12:00:00
', 1),
('Physical store revenue', 106.40, '2025-10-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251026-640.
Created by Miltos Karabasilis (id: 2) at 2025-10-26 12:00:00
', 1),
('E-shop revenue', 161.57, '2025-10-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251027-157.
Created by Miltos Karabasilis (id: 2) at 2025-10-27 12:00:00
', 1),
('Physical store revenue', 99.03, '2025-10-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251027-903.
Created by Miltos Karabasilis (id: 2) at 2025-10-27 12:00:00
', 1),
('E-shop revenue', 143.53, '2025-10-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251028-353.
Created by Miltos Karabasilis (id: 2) at 2025-10-28 12:00:00
', 1),
('Physical store revenue', 87.97, '2025-10-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251028-797.
Created by Miltos Karabasilis (id: 2) at 2025-10-28 12:00:00
', 1),
('E-shop revenue', 147.00, '2025-10-29', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20251029-700.
Created by Miltos Karabasilis (id: 2) at 2025-10-29 12:00:00
', 1),
('Physical store revenue', 90.10, '2025-10-29', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20251029-010.
Created by Miltos Karabasilis (id: 2) at 2025-10-29 12:00:00
', 1),
('E-shop revenue', 150.47, '2025-10-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251030-047.
Created by Miltos Karabasilis (id: 2) at 2025-10-30 12:00:00
', 1),
('Physical store revenue', 92.23, '2025-10-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251030-223.
Created by Miltos Karabasilis (id: 2) at 2025-10-30 12:00:00
', 1),
('E-shop revenue', 153.95, '2025-10-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251031-395.
Created by Miltos Karabasilis (id: 2) at 2025-10-31 12:00:00
', 1),
('Physical store revenue', 94.35, '2025-10-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251031-435.
Created by Miltos Karabasilis (id: 2) at 2025-10-31 12:00:00
', 1),
('E-shop revenue', 182.16, '2025-11-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251101-216.
Created by Miltos Karabasilis (id: 2) at 2025-11-01 12:00:00
', 1),
('Physical store revenue', 111.64, '2025-11-01', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251101-164.
Created by Miltos Karabasilis (id: 2) at 2025-11-01 12:00:00
', 1),
('E-shop revenue', 185.63, '2025-11-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251102-563.
Created by Miltos Karabasilis (id: 2) at 2025-11-02 12:00:00
', 1),
('Physical store revenue', 113.77, '2025-11-02', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251102-377.
Created by Miltos Karabasilis (id: 2) at 2025-11-02 12:00:00
', 1),
('E-shop revenue', 136.71, '2025-11-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251103-671.
Created by Miltos Karabasilis (id: 2) at 2025-11-03 12:00:00
', 1),
('Physical store revenue', 83.79, '2025-11-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251103-379.
Created by Miltos Karabasilis (id: 2) at 2025-11-03 12:00:00
', 1),
('E-shop revenue', 127.78, '2025-11-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251104-778.
Created by Miltos Karabasilis (id: 2) at 2025-11-04 12:00:00
', 1),
('Physical store revenue', 78.32, '2025-11-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251104-832.
Created by Miltos Karabasilis (id: 2) at 2025-11-04 12:00:00
', 1),
('E-shop revenue', 131.25, '2025-11-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251105-125.
Created by Miltos Karabasilis (id: 2) at 2025-11-05 12:00:00
', 1),
('Physical store revenue', 80.45, '2025-11-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251105-045.
Created by Miltos Karabasilis (id: 2) at 2025-11-05 12:00:00
', 1),
('E-shop revenue', 134.73, '2025-11-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251106-473.
Created by Miltos Karabasilis (id: 2) at 2025-11-06 12:00:00
', 1),
('Physical store revenue', 82.57, '2025-11-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251106-257.
Created by Miltos Karabasilis (id: 2) at 2025-11-06 12:00:00
', 1),
('E-shop revenue', 129.08, '2025-11-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251107-908.
Created by Miltos Karabasilis (id: 2) at 2025-11-07 12:00:00
', 1),
('Physical store revenue', 79.12, '2025-11-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251107-912.
Created by Miltos Karabasilis (id: 2) at 2025-11-07 12:00:00
', 1),
('E-shop revenue', 160.46, '2025-11-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251108-046.
Created by Miltos Karabasilis (id: 2) at 2025-11-08 12:00:00
', 1),
('Physical store revenue', 98.34, '2025-11-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251108-834.
Created by Miltos Karabasilis (id: 2) at 2025-11-08 12:00:00
', 1),
('E-shop revenue', 163.93, '2025-11-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251109-393.
Created by Miltos Karabasilis (id: 2) at 2025-11-09 12:00:00
', 1),
('Physical store revenue', 100.47, '2025-11-09', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251109-047.
Created by Miltos Karabasilis (id: 2) at 2025-11-09 12:00:00
', 1),
('E-shop revenue', 151.90, '2025-11-10', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20251110-190.
Created by Miltos Karabasilis (id: 2) at 2025-11-10 12:00:00
', 1),
('Physical store revenue', 93.10, '2025-11-10', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20251110-310.
Created by Miltos Karabasilis (id: 2) at 2025-11-10 12:00:00
', 1),
('E-shop revenue', 142.97, '2025-11-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251111-297.
Created by Miltos Karabasilis (id: 2) at 2025-11-11 12:00:00
', 1),
('Physical store revenue', 87.63, '2025-11-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251111-763.
Created by Miltos Karabasilis (id: 2) at 2025-11-11 12:00:00
', 1),
('E-shop revenue', 146.44, '2025-11-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251112-644.
Created by Miltos Karabasilis (id: 2) at 2025-11-12 12:00:00
', 1),
('Physical store revenue', 89.76, '2025-11-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251112-976.
Created by Miltos Karabasilis (id: 2) at 2025-11-12 12:00:00
', 1),
('E-shop revenue', 149.92, '2025-11-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251113-992.
Created by Miltos Karabasilis (id: 2) at 2025-11-13 12:00:00
', 1),
('Physical store revenue', 91.88, '2025-11-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251113-188.
Created by Miltos Karabasilis (id: 2) at 2025-11-13 12:00:00
', 1),
('E-shop revenue', 144.27, '2025-11-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251114-427.
Created by Miltos Karabasilis (id: 2) at 2025-11-14 12:00:00
', 1),
('Physical store revenue', 88.43, '2025-11-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251114-843.
Created by Miltos Karabasilis (id: 2) at 2025-11-14 12:00:00
', 1),
('E-shop revenue', 175.65, '2025-11-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251115-565.
Created by Miltos Karabasilis (id: 2) at 2025-11-15 12:00:00
', 1),
('Physical store revenue', 107.65, '2025-11-15', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251115-765.
Created by Miltos Karabasilis (id: 2) at 2025-11-15 12:00:00
', 1),
('E-shop revenue', 179.12, '2025-11-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251116-912.
Created by Miltos Karabasilis (id: 2) at 2025-11-16 12:00:00
', 1),
('Physical store revenue', 109.78, '2025-11-16', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251116-978.
Created by Miltos Karabasilis (id: 2) at 2025-11-16 12:00:00
', 1),
('E-shop revenue', 167.09, '2025-11-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251117-709.
Created by Miltos Karabasilis (id: 2) at 2025-11-17 12:00:00
', 1),
('Physical store revenue', 102.41, '2025-11-17', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251117-241.
Created by Miltos Karabasilis (id: 2) at 2025-11-17 12:00:00
', 1),
('E-shop revenue', 158.16, '2025-11-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251118-816.
Created by Miltos Karabasilis (id: 2) at 2025-11-18 12:00:00
', 1),
('Physical store revenue', 96.94, '2025-11-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251118-694.
Created by Miltos Karabasilis (id: 2) at 2025-11-18 12:00:00
', 1),
('E-shop revenue', 161.63, '2025-11-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251119-163.
Created by Miltos Karabasilis (id: 2) at 2025-11-19 12:00:00
', 1),
('Physical store revenue', 99.07, '2025-11-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251119-907.
Created by Miltos Karabasilis (id: 2) at 2025-11-19 12:00:00
', 1),
('E-shop revenue', 128.22, '2025-11-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251120-822.
Created by Miltos Karabasilis (id: 2) at 2025-11-20 12:00:00
', 1),
('Physical store revenue', 78.58, '2025-11-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251120-858.
Created by Miltos Karabasilis (id: 2) at 2025-11-20 12:00:00
', 1),
('E-shop revenue', 122.57, '2025-11-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251121-257.
Created by Miltos Karabasilis (id: 2) at 2025-11-21 12:00:00
', 1),
('Physical store revenue', 75.13, '2025-11-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251121-513.
Created by Miltos Karabasilis (id: 2) at 2025-11-21 12:00:00
', 1),
('E-shop revenue', 153.95, '2025-11-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251122-395.
Created by Miltos Karabasilis (id: 2) at 2025-11-22 12:00:00
', 1),
('Physical store revenue', 94.35, '2025-11-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251122-435.
Created by Miltos Karabasilis (id: 2) at 2025-11-22 12:00:00
', 1),
('E-shop revenue', 157.42, '2025-11-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251123-742.
Created by Miltos Karabasilis (id: 2) at 2025-11-23 12:00:00
', 1),
('Physical store revenue', 96.48, '2025-11-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251123-648.
Created by Miltos Karabasilis (id: 2) at 2025-11-23 12:00:00
', 1),
('E-shop revenue', 145.39, '2025-11-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251124-539.
Created by Miltos Karabasilis (id: 2) at 2025-11-24 12:00:00
', 1),
('Physical store revenue', 89.11, '2025-11-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251124-911.
Created by Miltos Karabasilis (id: 2) at 2025-11-24 12:00:00
', 1),
('E-shop revenue', 136.46, '2025-11-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251125-646.
Created by Miltos Karabasilis (id: 2) at 2025-11-25 12:00:00
', 1),
('Physical store revenue', 83.64, '2025-11-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251125-364.
Created by Miltos Karabasilis (id: 2) at 2025-11-25 12:00:00
', 1),
('E-shop revenue', 139.93, '2025-11-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251126-993.
Created by Miltos Karabasilis (id: 2) at 2025-11-26 12:00:00
', 1),
('Physical store revenue', 85.77, '2025-11-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251126-577.
Created by Miltos Karabasilis (id: 2) at 2025-11-26 12:00:00
', 1),
('E-shop revenue', 143.41, '2025-11-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251127-341.
Created by Miltos Karabasilis (id: 2) at 2025-11-27 12:00:00
', 1),
('Physical store revenue', 87.89, '2025-11-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251127-789.
Created by Miltos Karabasilis (id: 2) at 2025-11-27 12:00:00
', 1),
('E-shop revenue', 137.76, '2025-11-28', 'Black Friday checkout: Maria Papadopoulou, 12 Nikis St, Thessaloniki 546 24. Website payment confirmed; same-day warehouse dispatch.
Created by Miltos Karabasilis (id: 2) at 2025-11-28 12:00:00
', 1),
('Physical store revenue', 84.44, '2025-11-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251128-444.
Created by Miltos Karabasilis (id: 2) at 2025-11-28 12:00:00
', 1),
('E-shop revenue', 169.14, '2025-11-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251129-914.
Created by Miltos Karabasilis (id: 2) at 2025-11-29 12:00:00
', 1),
('Physical store revenue', 103.66, '2025-11-29', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251129-366.
Created by Miltos Karabasilis (id: 2) at 2025-11-29 12:00:00
', 1),
('E-shop revenue', 172.61, '2025-11-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251130-261.
Created by Miltos Karabasilis (id: 2) at 2025-11-30 12:00:00
', 1),
('Physical store revenue', 105.79, '2025-11-30', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251130-579.
Created by Miltos Karabasilis (id: 2) at 2025-11-30 12:00:00
', 1),
('E-shop revenue', 158.72, '2025-12-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251201-872.
Created by Miltos Karabasilis (id: 2) at 2025-12-01 12:00:00
', 1),
('Physical store revenue', 97.28, '2025-12-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251201-728.
Created by Miltos Karabasilis (id: 2) at 2025-12-01 12:00:00
', 1),
('E-shop revenue', 149.79, '2025-12-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251202-979.
Created by Miltos Karabasilis (id: 2) at 2025-12-02 12:00:00
', 1),
('Physical store revenue', 91.81, '2025-12-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251202-181.
Created by Miltos Karabasilis (id: 2) at 2025-12-02 12:00:00
', 1),
('E-shop revenue', 153.26, '2025-12-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251203-326.
Created by Miltos Karabasilis (id: 2) at 2025-12-03 12:00:00
', 1),
('Physical store revenue', 93.94, '2025-12-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251203-394.
Created by Miltos Karabasilis (id: 2) at 2025-12-03 12:00:00
', 1),
('E-shop revenue', 156.74, '2025-12-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251204-674.
Created by Miltos Karabasilis (id: 2) at 2025-12-04 12:00:00
', 1),
('Physical store revenue', 96.06, '2025-12-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251204-606.
Created by Miltos Karabasilis (id: 2) at 2025-12-04 12:00:00
', 1),
('E-shop revenue', 160.21, '2025-12-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251205-021.
Created by Miltos Karabasilis (id: 2) at 2025-12-05 12:00:00
', 1),
('Physical store revenue', 98.19, '2025-12-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251205-819.
Created by Miltos Karabasilis (id: 2) at 2025-12-05 12:00:00
', 1),
('E-shop revenue', 191.58, '2025-12-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251206-158.
Created by Miltos Karabasilis (id: 2) at 2025-12-06 12:00:00
', 1),
('Physical store revenue', 117.42, '2025-12-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251206-742.
Created by Miltos Karabasilis (id: 2) at 2025-12-06 12:00:00
', 1),
('E-shop revenue', 149.05, '2025-12-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251207-905.
Created by Miltos Karabasilis (id: 2) at 2025-12-07 12:00:00
', 1),
('Physical store revenue', 91.35, '2025-12-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251207-135.
Created by Miltos Karabasilis (id: 2) at 2025-12-07 12:00:00
', 1),
('E-shop revenue', 137.02, '2025-12-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251208-702.
Created by Miltos Karabasilis (id: 2) at 2025-12-08 12:00:00
', 1),
('Physical store revenue', 83.98, '2025-12-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251208-398.
Created by Miltos Karabasilis (id: 2) at 2025-12-08 12:00:00
', 1),
('E-shop revenue', 128.09, '2025-12-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251209-809.
Created by Miltos Karabasilis (id: 2) at 2025-12-09 12:00:00
', 1),
('Physical store revenue', 78.51, '2025-12-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251209-851.
Created by Miltos Karabasilis (id: 2) at 2025-12-09 12:00:00
', 1),
('E-shop revenue', 131.56, '2025-12-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251210-156.
Created by Miltos Karabasilis (id: 2) at 2025-12-10 12:00:00
', 1),
('Physical store revenue', 80.64, '2025-12-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251210-064.
Created by Miltos Karabasilis (id: 2) at 2025-12-10 12:00:00
', 1),
('E-shop revenue', 135.04, '2025-12-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251211-504.
Created by Miltos Karabasilis (id: 2) at 2025-12-11 12:00:00
', 1),
('Physical store revenue', 82.76, '2025-12-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251211-276.
Created by Miltos Karabasilis (id: 2) at 2025-12-11 12:00:00
', 1),
('E-shop revenue', 138.51, '2025-12-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251212-851.
Created by Miltos Karabasilis (id: 2) at 2025-12-12 12:00:00
', 1),
('Physical store revenue', 84.89, '2025-12-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251212-489.
Created by Miltos Karabasilis (id: 2) at 2025-12-12 12:00:00
', 1),
('E-shop revenue', 169.88, '2025-12-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251213-988.
Created by Miltos Karabasilis (id: 2) at 2025-12-13 12:00:00
', 1),
('Physical store revenue', 104.12, '2025-12-13', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251213-412.
Created by Miltos Karabasilis (id: 2) at 2025-12-13 12:00:00
', 1),
('E-shop revenue', 164.24, '2025-12-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251214-424.
Created by Miltos Karabasilis (id: 2) at 2025-12-14 12:00:00
', 1),
('Physical store revenue', 100.66, '2025-12-14', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251214-066.
Created by Miltos Karabasilis (id: 2) at 2025-12-14 12:00:00
', 1),
('E-shop revenue', 152.21, '2025-12-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251215-221.
Created by Miltos Karabasilis (id: 2) at 2025-12-15 12:00:00
', 1),
('Physical store revenue', 93.29, '2025-12-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251215-329.
Created by Miltos Karabasilis (id: 2) at 2025-12-15 12:00:00
', 1),
('E-shop revenue', 143.28, '2025-12-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251216-328.
Created by Miltos Karabasilis (id: 2) at 2025-12-16 12:00:00
', 1),
('Physical store revenue', 87.82, '2025-12-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251216-782.
Created by Miltos Karabasilis (id: 2) at 2025-12-16 12:00:00
', 1),
('E-shop revenue', 146.75, '2025-12-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251217-675.
Created by Miltos Karabasilis (id: 2) at 2025-12-17 12:00:00
', 1),
('Physical store revenue', 89.95, '2025-12-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251217-995.
Created by Miltos Karabasilis (id: 2) at 2025-12-17 12:00:00
', 1),
('E-shop revenue', 150.23, '2025-12-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251218-023.
Created by Miltos Karabasilis (id: 2) at 2025-12-18 12:00:00
', 1),
('Physical store revenue', 92.07, '2025-12-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251218-207.
Created by Miltos Karabasilis (id: 2) at 2025-12-18 12:00:00
', 1),
('E-shop revenue', 153.70, '2025-12-19', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20251219-370.
Created by Miltos Karabasilis (id: 2) at 2025-12-19 12:00:00
', 1),
('Physical store revenue', 94.20, '2025-12-19', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20251219-420.
Created by Miltos Karabasilis (id: 2) at 2025-12-19 12:00:00
', 1),
('E-shop revenue', 185.07, '2025-12-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251220-507.
Created by Miltos Karabasilis (id: 2) at 2025-12-20 12:00:00
', 1),
('Physical store revenue', 113.43, '2025-12-20', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251220-343.
Created by Miltos Karabasilis (id: 2) at 2025-12-20 12:00:00
', 1),
('E-shop revenue', 179.43, '2025-12-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251221-943.
Created by Miltos Karabasilis (id: 2) at 2025-12-21 12:00:00
', 1),
('Physical store revenue', 109.97, '2025-12-21', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251221-997.
Created by Miltos Karabasilis (id: 2) at 2025-12-21 12:00:00
', 1),
('E-shop revenue', 167.40, '2025-12-22', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20251222-740.
Created by Miltos Karabasilis (id: 2) at 2025-12-22 12:00:00
', 1),
('Physical store revenue', 102.60, '2025-12-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251222-260.
Created by Miltos Karabasilis (id: 2) at 2025-12-22 12:00:00
', 1),
('E-shop revenue', 158.47, '2025-12-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251223-847.
Created by Miltos Karabasilis (id: 2) at 2025-12-23 12:00:00
', 1),
('Physical store revenue', 97.13, '2025-12-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251223-713.
Created by Miltos Karabasilis (id: 2) at 2025-12-23 12:00:00
', 1),
('E-shop revenue', 125.05, '2025-12-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251224-505.
Created by Miltos Karabasilis (id: 2) at 2025-12-24 12:00:00
', 1),
('Physical store revenue', 76.65, '2025-12-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251224-665.
Created by Miltos Karabasilis (id: 2) at 2025-12-24 12:00:00
', 1),
('E-shop revenue', 128.53, '2025-12-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251225-853.
Created by Miltos Karabasilis (id: 2) at 2025-12-25 12:00:00
', 1),
('Physical store revenue', 78.77, '2025-12-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251225-877.
Created by Miltos Karabasilis (id: 2) at 2025-12-25 12:00:00
', 1),
('E-shop revenue', 132.00, '2025-12-26', 'Online sales recorded through the storefront; parcels prepared for courier pickup. Order batch reference WEB-20251226-200.
Created by Miltos Karabasilis (id: 2) at 2025-12-26 12:00:00
', 1),
('Physical store revenue', 80.90, '2025-12-26', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20251226-090.
Created by Miltos Karabasilis (id: 2) at 2025-12-26 12:00:00
', 1),
('E-shop revenue', 163.37, '2025-12-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251227-337.
Created by Miltos Karabasilis (id: 2) at 2025-12-27 12:00:00
', 1),
('Physical store revenue', 100.13, '2025-12-27', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20251227-013.
Created by Miltos Karabasilis (id: 2) at 2025-12-27 12:00:00
', 1),
('E-shop revenue', 157.73, '2025-12-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20251228-773.
Created by Miltos Karabasilis (id: 2) at 2025-12-28 12:00:00
', 1),
('Physical store revenue', 96.67, '2025-12-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251228-667.
Created by Miltos Karabasilis (id: 2) at 2025-12-28 12:00:00
', 1),
('E-shop revenue', 145.70, '2025-12-29', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20251229-570.
Created by Miltos Karabasilis (id: 2) at 2025-12-29 12:00:00
', 1),
('Physical store revenue', 89.30, '2025-12-29', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20251229-930.
Created by Miltos Karabasilis (id: 2) at 2025-12-29 12:00:00
', 1),
('E-shop revenue', 136.77, '2025-12-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251230-677.
Created by Miltos Karabasilis (id: 2) at 2025-12-30 12:00:00
', 1),
('Physical store revenue', 83.83, '2025-12-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251230-383.
Created by Miltos Karabasilis (id: 2) at 2025-12-30 12:00:00
', 1),
('E-shop revenue', 140.24, '2025-12-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20251231-024.
Created by Miltos Karabasilis (id: 2) at 2025-12-31 12:00:00
', 1),
('Physical store revenue', 85.96, '2025-12-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20251231-596.
Created by Miltos Karabasilis (id: 2) at 2025-12-31 12:00:00
', 1),
('E-shop revenue', 136.59, '2026-01-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260101-659.
Created by Miltos Karabasilis (id: 2) at 2026-01-01 12:00:00
', 1),
('Physical store revenue', 83.71, '2026-01-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260101-371.
Created by Miltos Karabasilis (id: 2) at 2026-01-01 12:00:00
', 1),
('E-shop revenue', 140.06, '2026-01-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260102-006.
Created by Miltos Karabasilis (id: 2) at 2026-01-02 12:00:00
', 1),
('Physical store revenue', 85.84, '2026-01-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260102-584.
Created by Miltos Karabasilis (id: 2) at 2026-01-02 12:00:00
', 1),
('E-shop revenue', 171.43, '2026-01-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260103-143.
Created by Miltos Karabasilis (id: 2) at 2026-01-03 12:00:00
', 1),
('Physical store revenue', 105.07, '2026-01-03', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260103-507.
Created by Miltos Karabasilis (id: 2) at 2026-01-03 12:00:00
', 1),
('E-shop revenue', 174.90, '2026-01-04', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20260104-490.
Created by Miltos Karabasilis (id: 2) at 2026-01-04 12:00:00
', 1),
('Physical store revenue', 107.20, '2026-01-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260104-720.
Created by Miltos Karabasilis (id: 2) at 2026-01-04 12:00:00
', 1),
('E-shop revenue', 162.87, '2026-01-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260105-287.
Created by Miltos Karabasilis (id: 2) at 2026-01-05 12:00:00
', 1),
('Physical store revenue', 99.83, '2026-01-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260105-983.
Created by Miltos Karabasilis (id: 2) at 2026-01-05 12:00:00
', 1),
('E-shop revenue', 153.95, '2026-01-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260106-395.
Created by Miltos Karabasilis (id: 2) at 2026-01-06 12:00:00
', 1),
('Physical store revenue', 94.35, '2026-01-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260106-435.
Created by Miltos Karabasilis (id: 2) at 2026-01-06 12:00:00
', 1),
('E-shop revenue', 148.30, '2026-01-07', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260107-830.
Created by Miltos Karabasilis (id: 2) at 2026-01-07 12:00:00
', 1),
('Physical store revenue', 90.90, '2026-01-07', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260107-090.
Created by Miltos Karabasilis (id: 2) at 2026-01-07 12:00:00
', 1),
('E-shop revenue', 151.78, '2026-01-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260108-178.
Created by Miltos Karabasilis (id: 2) at 2026-01-08 12:00:00
', 1),
('Physical store revenue', 93.02, '2026-01-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260108-302.
Created by Miltos Karabasilis (id: 2) at 2026-01-08 12:00:00
', 1),
('E-shop revenue', 155.25, '2026-01-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260109-525.
Created by Miltos Karabasilis (id: 2) at 2026-01-09 12:00:00
', 1),
('Physical store revenue', 95.15, '2026-01-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260109-515.
Created by Miltos Karabasilis (id: 2) at 2026-01-09 12:00:00
', 1),
('E-shop revenue', 149.73, '2026-01-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260110-973.
Created by Miltos Karabasilis (id: 2) at 2026-01-10 12:00:00
', 1),
('Physical store revenue', 91.77, '2026-01-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260110-177.
Created by Miltos Karabasilis (id: 2) at 2026-01-10 12:00:00
', 1),
('E-shop revenue', 153.20, '2026-01-11', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20260111-320.
Created by Miltos Karabasilis (id: 2) at 2026-01-11 12:00:00
', 1),
('Physical store revenue', 93.90, '2026-01-11', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260111-390.
Created by Miltos Karabasilis (id: 2) at 2026-01-11 12:00:00
', 1),
('E-shop revenue', 141.17, '2026-01-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260112-117.
Created by Miltos Karabasilis (id: 2) at 2026-01-12 12:00:00
', 1),
('Physical store revenue', 86.53, '2026-01-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260112-653.
Created by Miltos Karabasilis (id: 2) at 2026-01-12 12:00:00
', 1),
('E-shop revenue', 132.25, '2026-01-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260113-225.
Created by Miltos Karabasilis (id: 2) at 2026-01-13 12:00:00
', 1),
('Physical store revenue', 81.05, '2026-01-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260113-105.
Created by Miltos Karabasilis (id: 2) at 2026-01-13 12:00:00
', 1),
('E-shop revenue', 126.60, '2026-01-14', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260114-660.
Created by Miltos Karabasilis (id: 2) at 2026-01-14 12:00:00
', 1),
('Physical store revenue', 77.60, '2026-01-14', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260114-760.
Created by Miltos Karabasilis (id: 2) at 2026-01-14 12:00:00
', 1),
('E-shop revenue', 130.08, '2026-01-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260115-008.
Created by Miltos Karabasilis (id: 2) at 2026-01-15 12:00:00
', 1),
('Physical store revenue', 79.72, '2026-01-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260115-972.
Created by Miltos Karabasilis (id: 2) at 2026-01-15 12:00:00
', 1),
('E-shop revenue', 133.55, '2026-01-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260116-355.
Created by Miltos Karabasilis (id: 2) at 2026-01-16 12:00:00
', 1),
('Physical store revenue', 81.85, '2026-01-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260116-185.
Created by Miltos Karabasilis (id: 2) at 2026-01-16 12:00:00
', 1),
('E-shop revenue', 164.92, '2026-01-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260117-492.
Created by Miltos Karabasilis (id: 2) at 2026-01-17 12:00:00
', 1),
('Physical store revenue', 101.08, '2026-01-17', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260117-108.
Created by Miltos Karabasilis (id: 2) at 2026-01-17 12:00:00
', 1),
('E-shop revenue', 168.39, '2026-01-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260118-839.
Created by Miltos Karabasilis (id: 2) at 2026-01-18 12:00:00
', 1),
('Physical store revenue', 103.21, '2026-01-18', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260118-321.
Created by Miltos Karabasilis (id: 2) at 2026-01-18 12:00:00
', 1),
('E-shop revenue', 156.36, '2026-01-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260119-636.
Created by Miltos Karabasilis (id: 2) at 2026-01-19 12:00:00
', 1),
('Physical store revenue', 95.84, '2026-01-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260119-584.
Created by Miltos Karabasilis (id: 2) at 2026-01-19 12:00:00
', 1),
('E-shop revenue', 147.44, '2026-01-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260120-744.
Created by Miltos Karabasilis (id: 2) at 2026-01-20 12:00:00
', 1),
('Physical store revenue', 90.36, '2026-01-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260120-036.
Created by Miltos Karabasilis (id: 2) at 2026-01-20 12:00:00
', 1),
('E-shop revenue', 141.79, '2026-01-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260121-179.
Created by Miltos Karabasilis (id: 2) at 2026-01-21 12:00:00
', 1),
('Physical store revenue', 86.91, '2026-01-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260121-691.
Created by Miltos Karabasilis (id: 2) at 2026-01-21 12:00:00
', 1),
('E-shop revenue', 145.27, '2026-01-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260122-527.
Created by Miltos Karabasilis (id: 2) at 2026-01-22 12:00:00
', 1),
('Physical store revenue', 89.03, '2026-01-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260122-903.
Created by Miltos Karabasilis (id: 2) at 2026-01-22 12:00:00
', 1),
('E-shop revenue', 148.74, '2026-01-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260123-874.
Created by Miltos Karabasilis (id: 2) at 2026-01-23 12:00:00
', 1),
('Physical store revenue', 91.16, '2026-01-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260123-116.
Created by Miltos Karabasilis (id: 2) at 2026-01-23 12:00:00
', 1),
('E-shop revenue', 180.11, '2026-01-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260124-011.
Created by Miltos Karabasilis (id: 2) at 2026-01-24 12:00:00
', 1),
('Physical store revenue', 110.39, '2026-01-24', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260124-039.
Created by Miltos Karabasilis (id: 2) at 2026-01-24 12:00:00
', 1),
('E-shop revenue', 183.58, '2026-01-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260125-358.
Created by Miltos Karabasilis (id: 2) at 2026-01-25 12:00:00
', 1),
('Physical store revenue', 112.52, '2026-01-25', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260125-252.
Created by Miltos Karabasilis (id: 2) at 2026-01-25 12:00:00
', 1),
('E-shop revenue', 171.55, '2026-01-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260126-155.
Created by Miltos Karabasilis (id: 2) at 2026-01-26 12:00:00
', 1),
('Physical store revenue', 105.15, '2026-01-26', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260126-515.
Created by Miltos Karabasilis (id: 2) at 2026-01-26 12:00:00
', 1),
('E-shop revenue', 125.74, '2026-01-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260127-574.
Created by Miltos Karabasilis (id: 2) at 2026-01-27 12:00:00
', 1),
('Physical store revenue', 77.06, '2026-01-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260127-706.
Created by Miltos Karabasilis (id: 2) at 2026-01-27 12:00:00
', 1),
('E-shop revenue', 120.09, '2026-01-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260128-009.
Created by Miltos Karabasilis (id: 2) at 2026-01-28 12:00:00
', 1),
('Physical store revenue', 73.61, '2026-01-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260128-361.
Created by Miltos Karabasilis (id: 2) at 2026-01-28 12:00:00
', 1),
('E-shop revenue', 123.57, '2026-01-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260129-357.
Created by Miltos Karabasilis (id: 2) at 2026-01-29 12:00:00
', 1),
('Physical store revenue', 75.73, '2026-01-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260129-573.
Created by Miltos Karabasilis (id: 2) at 2026-01-29 12:00:00
', 1),
('E-shop revenue', 127.04, '2026-01-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260130-704.
Created by Miltos Karabasilis (id: 2) at 2026-01-30 12:00:00
', 1),
('Physical store revenue', 77.86, '2026-01-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260130-786.
Created by Miltos Karabasilis (id: 2) at 2026-01-30 12:00:00
', 1),
('E-shop revenue', 158.41, '2026-01-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260131-841.
Created by Miltos Karabasilis (id: 2) at 2026-01-31 12:00:00
', 1),
('Physical store revenue', 97.09, '2026-01-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260131-709.
Created by Miltos Karabasilis (id: 2) at 2026-01-31 12:00:00
', 1),
('E-shop revenue', 158.72, '2026-02-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260201-872.
Created by Miltos Karabasilis (id: 2) at 2026-02-01 12:00:00
', 1),
('Physical store revenue', 97.28, '2026-02-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260201-728.
Created by Miltos Karabasilis (id: 2) at 2026-02-01 12:00:00
', 1),
('E-shop revenue', 146.69, '2026-02-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260202-669.
Created by Miltos Karabasilis (id: 2) at 2026-02-02 12:00:00
', 1),
('Physical store revenue', 89.91, '2026-02-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260202-991.
Created by Miltos Karabasilis (id: 2) at 2026-02-02 12:00:00
', 1),
('E-shop revenue', 137.76, '2026-02-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260203-776.
Created by Miltos Karabasilis (id: 2) at 2026-02-03 12:00:00
', 1),
('Physical store revenue', 84.44, '2026-02-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260203-444.
Created by Miltos Karabasilis (id: 2) at 2026-02-03 12:00:00
', 1),
('E-shop revenue', 141.24, '2026-02-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260204-124.
Created by Miltos Karabasilis (id: 2) at 2026-02-04 12:00:00
', 1),
('Physical store revenue', 86.56, '2026-02-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260204-656.
Created by Miltos Karabasilis (id: 2) at 2026-02-04 12:00:00
', 1),
('E-shop revenue', 144.71, '2026-02-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260205-471.
Created by Miltos Karabasilis (id: 2) at 2026-02-05 12:00:00
', 1),
('Physical store revenue', 88.69, '2026-02-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260205-869.
Created by Miltos Karabasilis (id: 2) at 2026-02-05 12:00:00
', 1),
('E-shop revenue', 148.18, '2026-02-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260206-818.
Created by Miltos Karabasilis (id: 2) at 2026-02-06 12:00:00
', 1),
('Physical store revenue', 90.82, '2026-02-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260206-082.
Created by Miltos Karabasilis (id: 2) at 2026-02-06 12:00:00
', 1),
('E-shop revenue', 170.44, '2026-02-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260207-044.
Created by Miltos Karabasilis (id: 2) at 2026-02-07 12:00:00
', 1),
('Physical store revenue', 104.46, '2026-02-07', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260207-446.
Created by Miltos Karabasilis (id: 2) at 2026-02-07 12:00:00
', 1),
('E-shop revenue', 173.91, '2026-02-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260208-391.
Created by Miltos Karabasilis (id: 2) at 2026-02-08 12:00:00
', 1),
('Physical store revenue', 106.59, '2026-02-08', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260208-659.
Created by Miltos Karabasilis (id: 2) at 2026-02-08 12:00:00
', 1),
('E-shop revenue', 161.88, '2026-02-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260209-188.
Created by Miltos Karabasilis (id: 2) at 2026-02-09 12:00:00
', 1),
('Physical store revenue', 99.22, '2026-02-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260209-922.
Created by Miltos Karabasilis (id: 2) at 2026-02-09 12:00:00
', 1),
('E-shop revenue', 152.95, '2026-02-10', 'New customer: James Cole, 88 Oak Avenue, Manchester M1 4BT, UK. International order fulfilled from main warehouse.
Created by Miltos Karabasilis (id: 2) at 2026-02-10 12:00:00
', 1),
('Physical store revenue', 93.75, '2026-02-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260210-375.
Created by Miltos Karabasilis (id: 2) at 2026-02-10 12:00:00
', 1),
('E-shop revenue', 156.43, '2026-02-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260211-643.
Created by Miltos Karabasilis (id: 2) at 2026-02-11 12:00:00
', 1),
('Physical store revenue', 95.87, '2026-02-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260211-587.
Created by Miltos Karabasilis (id: 2) at 2026-02-11 12:00:00
', 1),
('E-shop revenue', 159.90, '2026-02-12', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260212-990.
Created by Miltos Karabasilis (id: 2) at 2026-02-12 12:00:00
', 1),
('Physical store revenue', 98.00, '2026-02-12', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260212-800.
Created by Miltos Karabasilis (id: 2) at 2026-02-12 12:00:00
', 1),
('E-shop revenue', 126.48, '2026-02-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260213-648.
Created by Miltos Karabasilis (id: 2) at 2026-02-13 12:00:00
', 1),
('Physical store revenue', 77.52, '2026-02-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260213-752.
Created by Miltos Karabasilis (id: 2) at 2026-02-13 12:00:00
', 1),
('E-shop revenue', 148.74, '2026-02-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260214-874.
Created by Miltos Karabasilis (id: 2) at 2026-02-14 12:00:00
', 1),
('Physical store revenue', 91.16, '2026-02-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260214-116.
Created by Miltos Karabasilis (id: 2) at 2026-02-14 12:00:00
', 1),
('E-shop revenue', 152.21, '2026-02-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260215-221.
Created by Miltos Karabasilis (id: 2) at 2026-02-15 12:00:00
', 1),
('Physical store revenue', 93.29, '2026-02-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260215-329.
Created by Miltos Karabasilis (id: 2) at 2026-02-15 12:00:00
', 1),
('E-shop revenue', 140.18, '2026-02-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260216-018.
Created by Miltos Karabasilis (id: 2) at 2026-02-16 12:00:00
', 1),
('Physical store revenue', 85.92, '2026-02-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260216-592.
Created by Miltos Karabasilis (id: 2) at 2026-02-16 12:00:00
', 1),
('E-shop revenue', 131.25, '2026-02-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260217-125.
Created by Miltos Karabasilis (id: 2) at 2026-02-17 12:00:00
', 1),
('Physical store revenue', 80.45, '2026-02-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260217-045.
Created by Miltos Karabasilis (id: 2) at 2026-02-17 12:00:00
', 1),
('E-shop revenue', 134.73, '2026-02-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260218-473.
Created by Miltos Karabasilis (id: 2) at 2026-02-18 12:00:00
', 1),
('Physical store revenue', 82.57, '2026-02-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260218-257.
Created by Miltos Karabasilis (id: 2) at 2026-02-18 12:00:00
', 1),
('E-shop revenue', 138.20, '2026-02-19', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260219-820.
Created by Miltos Karabasilis (id: 2) at 2026-02-19 12:00:00
', 1),
('Physical store revenue', 84.70, '2026-02-19', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260219-470.
Created by Miltos Karabasilis (id: 2) at 2026-02-19 12:00:00
', 1),
('E-shop revenue', 141.67, '2026-02-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260220-167.
Created by Miltos Karabasilis (id: 2) at 2026-02-20 12:00:00
', 1),
('Physical store revenue', 86.83, '2026-02-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260220-683.
Created by Miltos Karabasilis (id: 2) at 2026-02-20 12:00:00
', 1),
('E-shop revenue', 163.93, '2026-02-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260221-393.
Created by Miltos Karabasilis (id: 2) at 2026-02-21 12:00:00
', 1),
('Physical store revenue', 100.47, '2026-02-21', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260221-047.
Created by Miltos Karabasilis (id: 2) at 2026-02-21 12:00:00
', 1),
('E-shop revenue', 167.40, '2026-02-22', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20260222-740.
Created by Miltos Karabasilis (id: 2) at 2026-02-22 12:00:00
', 1),
('Physical store revenue', 102.60, '2026-02-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260222-260.
Created by Miltos Karabasilis (id: 2) at 2026-02-22 12:00:00
', 1),
('E-shop revenue', 155.37, '2026-02-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260223-537.
Created by Miltos Karabasilis (id: 2) at 2026-02-23 12:00:00
', 1),
('Physical store revenue', 95.23, '2026-02-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260223-523.
Created by Miltos Karabasilis (id: 2) at 2026-02-23 12:00:00
', 1),
('E-shop revenue', 146.44, '2026-02-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260224-644.
Created by Miltos Karabasilis (id: 2) at 2026-02-24 12:00:00
', 1),
('Physical store revenue', 89.76, '2026-02-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260224-976.
Created by Miltos Karabasilis (id: 2) at 2026-02-24 12:00:00
', 1),
('E-shop revenue', 149.92, '2026-02-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260225-992.
Created by Miltos Karabasilis (id: 2) at 2026-02-25 12:00:00
', 1),
('Physical store revenue', 91.88, '2026-02-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260225-188.
Created by Miltos Karabasilis (id: 2) at 2026-02-25 12:00:00
', 1),
('E-shop revenue', 153.39, '2026-02-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260226-339.
Created by Miltos Karabasilis (id: 2) at 2026-02-26 12:00:00
', 1),
('Physical store revenue', 94.01, '2026-02-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260226-401.
Created by Miltos Karabasilis (id: 2) at 2026-02-26 12:00:00
', 1),
('E-shop revenue', 156.86, '2026-02-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260227-686.
Created by Miltos Karabasilis (id: 2) at 2026-02-27 12:00:00
', 1),
('Physical store revenue', 96.14, '2026-02-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260227-614.
Created by Miltos Karabasilis (id: 2) at 2026-02-27 12:00:00
', 1),
('E-shop revenue', 179.12, '2026-02-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260228-912.
Created by Miltos Karabasilis (id: 2) at 2026-02-28 12:00:00
', 1),
('Physical store revenue', 109.78, '2026-02-28', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260228-978.
Created by Miltos Karabasilis (id: 2) at 2026-02-28 12:00:00
', 1),
('E-shop revenue', 183.33, '2026-03-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260301-333.
Created by Miltos Karabasilis (id: 2) at 2026-03-01 12:00:00
', 1),
('Physical store revenue', 112.37, '2026-03-01', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260301-237.
Created by Miltos Karabasilis (id: 2) at 2026-03-01 12:00:00
', 1),
('E-shop revenue', 134.42, '2026-03-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260302-442.
Created by Miltos Karabasilis (id: 2) at 2026-03-02 12:00:00
', 1),
('Physical store revenue', 82.38, '2026-03-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260302-238.
Created by Miltos Karabasilis (id: 2) at 2026-03-02 12:00:00
', 1),
('E-shop revenue', 125.49, '2026-03-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260303-549.
Created by Miltos Karabasilis (id: 2) at 2026-03-03 12:00:00
', 1),
('Physical store revenue', 76.91, '2026-03-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260303-691.
Created by Miltos Karabasilis (id: 2) at 2026-03-03 12:00:00
', 1),
('E-shop revenue', 128.96, '2026-03-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260304-896.
Created by Miltos Karabasilis (id: 2) at 2026-03-04 12:00:00
', 1),
('Physical store revenue', 79.04, '2026-03-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260304-904.
Created by Miltos Karabasilis (id: 2) at 2026-03-04 12:00:00
', 1),
('E-shop revenue', 132.43, '2026-03-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260305-243.
Created by Miltos Karabasilis (id: 2) at 2026-03-05 12:00:00
', 1),
('Physical store revenue', 81.17, '2026-03-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260305-117.
Created by Miltos Karabasilis (id: 2) at 2026-03-05 12:00:00
', 1),
('E-shop revenue', 135.90, '2026-03-06', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260306-590.
Created by Miltos Karabasilis (id: 2) at 2026-03-06 12:00:00
', 1),
('Physical store revenue', 83.30, '2026-03-06', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260306-330.
Created by Miltos Karabasilis (id: 2) at 2026-03-06 12:00:00
', 1),
('E-shop revenue', 158.16, '2026-03-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260307-816.
Created by Miltos Karabasilis (id: 2) at 2026-03-07 12:00:00
', 1),
('Physical store revenue', 96.94, '2026-03-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260307-694.
Created by Miltos Karabasilis (id: 2) at 2026-03-07 12:00:00
', 1),
('E-shop revenue', 161.63, '2026-03-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260308-163.
Created by Miltos Karabasilis (id: 2) at 2026-03-08 12:00:00
', 1),
('Physical store revenue', 99.07, '2026-03-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260308-907.
Created by Miltos Karabasilis (id: 2) at 2026-03-08 12:00:00
', 1),
('E-shop revenue', 149.61, '2026-03-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260309-961.
Created by Miltos Karabasilis (id: 2) at 2026-03-09 12:00:00
', 1),
('Physical store revenue', 91.69, '2026-03-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260309-169.
Created by Miltos Karabasilis (id: 2) at 2026-03-09 12:00:00
', 1),
('E-shop revenue', 140.68, '2026-03-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260310-068.
Created by Miltos Karabasilis (id: 2) at 2026-03-10 12:00:00
', 1),
('Physical store revenue', 86.22, '2026-03-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260310-622.
Created by Miltos Karabasilis (id: 2) at 2026-03-10 12:00:00
', 1),
('E-shop revenue', 144.15, '2026-03-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260311-415.
Created by Miltos Karabasilis (id: 2) at 2026-03-11 12:00:00
', 1),
('Physical store revenue', 88.35, '2026-03-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260311-835.
Created by Miltos Karabasilis (id: 2) at 2026-03-11 12:00:00
', 1),
('E-shop revenue', 147.62, '2026-03-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260312-762.
Created by Miltos Karabasilis (id: 2) at 2026-03-12 12:00:00
', 1),
('Physical store revenue', 90.48, '2026-03-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260312-048.
Created by Miltos Karabasilis (id: 2) at 2026-03-12 12:00:00
', 1),
('E-shop revenue', 151.09, '2026-03-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260313-109.
Created by Miltos Karabasilis (id: 2) at 2026-03-13 12:00:00
', 1),
('Physical store revenue', 92.61, '2026-03-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260313-261.
Created by Miltos Karabasilis (id: 2) at 2026-03-13 12:00:00
', 1),
('E-shop revenue', 173.35, '2026-03-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260314-335.
Created by Miltos Karabasilis (id: 2) at 2026-03-14 12:00:00
', 1),
('Physical store revenue', 106.25, '2026-03-14', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260314-625.
Created by Miltos Karabasilis (id: 2) at 2026-03-14 12:00:00
', 1),
('E-shop revenue', 176.82, '2026-03-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260315-682.
Created by Miltos Karabasilis (id: 2) at 2026-03-15 12:00:00
', 1),
('Physical store revenue', 108.38, '2026-03-15', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260315-838.
Created by Miltos Karabasilis (id: 2) at 2026-03-15 12:00:00
', 1),
('E-shop revenue', 164.80, '2026-03-16', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260316-480.
Created by Miltos Karabasilis (id: 2) at 2026-03-16 12:00:00
', 1),
('Physical store revenue', 101.00, '2026-03-16', 'Physical shop revenue from cash and card transactions handled on site. Receipt batch POS-20260316-100.
Created by Miltos Karabasilis (id: 2) at 2026-03-16 12:00:00
', 1),
('E-shop revenue', 155.87, '2026-03-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260317-587.
Created by Miltos Karabasilis (id: 2) at 2026-03-17 12:00:00
', 1),
('Physical store revenue', 95.53, '2026-03-17', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260317-553.
Created by Miltos Karabasilis (id: 2) at 2026-03-17 12:00:00
', 1),
('E-shop revenue', 159.34, '2026-03-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260318-934.
Created by Miltos Karabasilis (id: 2) at 2026-03-18 12:00:00
', 1),
('Physical store revenue', 97.66, '2026-03-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260318-766.
Created by Miltos Karabasilis (id: 2) at 2026-03-18 12:00:00
', 1),
('E-shop revenue', 125.92, '2026-03-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260319-592.
Created by Miltos Karabasilis (id: 2) at 2026-03-19 12:00:00
', 1),
('Physical store revenue', 77.18, '2026-03-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260319-718.
Created by Miltos Karabasilis (id: 2) at 2026-03-19 12:00:00
', 1),
('E-shop revenue', 129.39, '2026-03-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260320-939.
Created by Miltos Karabasilis (id: 2) at 2026-03-20 12:00:00
', 1),
('Physical store revenue', 79.31, '2026-03-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260320-931.
Created by Miltos Karabasilis (id: 2) at 2026-03-20 12:00:00
', 1),
('E-shop revenue', 151.65, '2026-03-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260321-165.
Created by Miltos Karabasilis (id: 2) at 2026-03-21 12:00:00
', 1),
('Physical store revenue', 92.95, '2026-03-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260321-295.
Created by Miltos Karabasilis (id: 2) at 2026-03-21 12:00:00
', 1),
('E-shop revenue', 155.12, '2026-03-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260322-512.
Created by Miltos Karabasilis (id: 2) at 2026-03-22 12:00:00
', 1),
('Physical store revenue', 95.08, '2026-03-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260322-508.
Created by Miltos Karabasilis (id: 2) at 2026-03-22 12:00:00
', 1),
('E-shop revenue', 143.10, '2026-03-23', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260323-310.
Created by Miltos Karabasilis (id: 2) at 2026-03-23 12:00:00
', 1),
('Physical store revenue', 87.70, '2026-03-23', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260323-770.
Created by Miltos Karabasilis (id: 2) at 2026-03-23 12:00:00
', 1),
('E-shop revenue', 134.17, '2026-03-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260324-417.
Created by Miltos Karabasilis (id: 2) at 2026-03-24 12:00:00
', 1),
('Physical store revenue', 82.23, '2026-03-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260324-223.
Created by Miltos Karabasilis (id: 2) at 2026-03-24 12:00:00
', 1),
('E-shop revenue', 137.64, '2026-03-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260325-764.
Created by Miltos Karabasilis (id: 2) at 2026-03-25 12:00:00
', 1),
('Physical store revenue', 84.36, '2026-03-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260325-436.
Created by Miltos Karabasilis (id: 2) at 2026-03-25 12:00:00
', 1),
('E-shop revenue', 141.11, '2026-03-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260326-111.
Created by Miltos Karabasilis (id: 2) at 2026-03-26 12:00:00
', 1),
('Physical store revenue', 86.49, '2026-03-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260326-649.
Created by Miltos Karabasilis (id: 2) at 2026-03-26 12:00:00
', 1),
('E-shop revenue', 144.58, '2026-03-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260327-458.
Created by Miltos Karabasilis (id: 2) at 2026-03-27 12:00:00
', 1),
('Physical store revenue', 88.62, '2026-03-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260327-862.
Created by Miltos Karabasilis (id: 2) at 2026-03-27 12:00:00
', 1),
('E-shop revenue', 166.84, '2026-03-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260328-684.
Created by Miltos Karabasilis (id: 2) at 2026-03-28 12:00:00
', 1),
('Physical store revenue', 102.26, '2026-03-28', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260328-226.
Created by Miltos Karabasilis (id: 2) at 2026-03-28 12:00:00
', 1),
('E-shop revenue', 170.31, '2026-03-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260329-031.
Created by Miltos Karabasilis (id: 2) at 2026-03-29 12:00:00
', 1),
('Physical store revenue', 104.39, '2026-03-29', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260329-439.
Created by Miltos Karabasilis (id: 2) at 2026-03-29 12:00:00
', 1),
('E-shop revenue', 158.29, '2026-03-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260330-829.
Created by Miltos Karabasilis (id: 2) at 2026-03-30 12:00:00
', 1),
('Physical store revenue', 97.01, '2026-03-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260330-701.
Created by Miltos Karabasilis (id: 2) at 2026-03-30 12:00:00
', 1),
('E-shop revenue', 149.36, '2026-03-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260331-936.
Created by Miltos Karabasilis (id: 2) at 2026-03-31 12:00:00
', 1),
('Physical store revenue', 91.54, '2026-03-31', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260331-154.
Created by Miltos Karabasilis (id: 2) at 2026-03-31 12:00:00
', 1),
('E-shop revenue', 149.67, '2026-04-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260401-967.
Created by Miltos Karabasilis (id: 2) at 2026-04-01 12:00:00
', 1),
('Physical store revenue', 91.73, '2026-04-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260401-173.
Created by Miltos Karabasilis (id: 2) at 2026-04-01 12:00:00
', 1),
('E-shop revenue', 153.14, '2026-04-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260402-314.
Created by Miltos Karabasilis (id: 2) at 2026-04-02 12:00:00
', 1),
('Physical store revenue', 93.86, '2026-04-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260402-386.
Created by Miltos Karabasilis (id: 2) at 2026-04-02 12:00:00
', 1),
('E-shop revenue', 156.61, '2026-04-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260403-661.
Created by Miltos Karabasilis (id: 2) at 2026-04-03 12:00:00
', 1),
('Physical store revenue', 95.99, '2026-04-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260403-599.
Created by Miltos Karabasilis (id: 2) at 2026-04-03 12:00:00
', 1),
('E-shop revenue', 187.98, '2026-04-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260404-798.
Created by Miltos Karabasilis (id: 2) at 2026-04-04 12:00:00
', 1),
('Physical store revenue', 115.22, '2026-04-04', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260404-522.
Created by Miltos Karabasilis (id: 2) at 2026-04-04 12:00:00
', 1),
('E-shop revenue', 154.57, '2026-04-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260405-457.
Created by Miltos Karabasilis (id: 2) at 2026-04-05 12:00:00
', 1),
('Physical store revenue', 94.73, '2026-04-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260405-473.
Created by Miltos Karabasilis (id: 2) at 2026-04-05 12:00:00
', 1),
('E-shop revenue', 142.54, '2026-04-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260406-254.
Created by Miltos Karabasilis (id: 2) at 2026-04-06 12:00:00
', 1),
('Physical store revenue', 87.36, '2026-04-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260406-736.
Created by Miltos Karabasilis (id: 2) at 2026-04-06 12:00:00
', 1),
('E-shop revenue', 124.50, '2026-04-07', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260407-450.
Created by Miltos Karabasilis (id: 2) at 2026-04-07 12:00:00
', 1),
('Physical store revenue', 76.30, '2026-04-07', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260407-630.
Created by Miltos Karabasilis (id: 2) at 2026-04-07 12:00:00
', 1),
('E-shop revenue', 127.97, '2026-04-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260408-797.
Created by Miltos Karabasilis (id: 2) at 2026-04-08 12:00:00
', 1),
('Physical store revenue', 78.43, '2026-04-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260408-843.
Created by Miltos Karabasilis (id: 2) at 2026-04-08 12:00:00
', 1),
('E-shop revenue', 131.44, '2026-04-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260409-144.
Created by Miltos Karabasilis (id: 2) at 2026-04-09 12:00:00
', 1),
('Physical store revenue', 80.56, '2026-04-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260409-056.
Created by Miltos Karabasilis (id: 2) at 2026-04-09 12:00:00
', 1),
('E-shop revenue', 134.91, '2026-04-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260410-491.
Created by Miltos Karabasilis (id: 2) at 2026-04-10 12:00:00
', 1),
('Physical store revenue', 82.69, '2026-04-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260410-269.
Created by Miltos Karabasilis (id: 2) at 2026-04-10 12:00:00
', 1),
('E-shop revenue', 166.28, '2026-04-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260411-628.
Created by Miltos Karabasilis (id: 2) at 2026-04-11 12:00:00
', 1),
('Physical store revenue', 101.92, '2026-04-11', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260411-192.
Created by Miltos Karabasilis (id: 2) at 2026-04-11 12:00:00
', 1),
('E-shop revenue', 169.76, '2026-04-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260412-976.
Created by Miltos Karabasilis (id: 2) at 2026-04-12 12:00:00
', 1),
('Physical store revenue', 104.04, '2026-04-12', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260412-404.
Created by Miltos Karabasilis (id: 2) at 2026-04-12 12:00:00
', 1),
('E-shop revenue', 157.73, '2026-04-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260413-773.
Created by Miltos Karabasilis (id: 2) at 2026-04-13 12:00:00
', 1),
('Physical store revenue', 96.67, '2026-04-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260413-667.
Created by Miltos Karabasilis (id: 2) at 2026-04-13 12:00:00
', 1),
('E-shop revenue', 139.69, '2026-04-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260414-969.
Created by Miltos Karabasilis (id: 2) at 2026-04-14 12:00:00
', 1),
('Physical store revenue', 85.61, '2026-04-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260414-561.
Created by Miltos Karabasilis (id: 2) at 2026-04-14 12:00:00
', 1),
('E-shop revenue', 143.16, '2026-04-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260415-316.
Created by Miltos Karabasilis (id: 2) at 2026-04-15 12:00:00
', 1),
('Physical store revenue', 87.74, '2026-04-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260415-774.
Created by Miltos Karabasilis (id: 2) at 2026-04-15 12:00:00
', 1),
('E-shop revenue', 146.63, '2026-04-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260416-663.
Created by Miltos Karabasilis (id: 2) at 2026-04-16 12:00:00
', 1),
('Physical store revenue', 89.87, '2026-04-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260416-987.
Created by Miltos Karabasilis (id: 2) at 2026-04-16 12:00:00
', 1),
('E-shop revenue', 150.10, '2026-04-17', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260417-010.
Created by Miltos Karabasilis (id: 2) at 2026-04-17 12:00:00
', 1),
('Physical store revenue', 92.00, '2026-04-17', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260417-200.
Created by Miltos Karabasilis (id: 2) at 2026-04-17 12:00:00
', 1),
('E-shop revenue', 181.47, '2026-04-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260418-147.
Created by Miltos Karabasilis (id: 2) at 2026-04-18 12:00:00
', 1),
('Physical store revenue', 111.23, '2026-04-18', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260418-123.
Created by Miltos Karabasilis (id: 2) at 2026-04-18 12:00:00
', 1),
('E-shop revenue', 184.95, '2026-04-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260419-495.
Created by Miltos Karabasilis (id: 2) at 2026-04-19 12:00:00
', 1),
('Physical store revenue', 113.35, '2026-04-19', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260419-335.
Created by Miltos Karabasilis (id: 2) at 2026-04-19 12:00:00
', 1),
('E-shop revenue', 172.92, '2026-04-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260420-292.
Created by Miltos Karabasilis (id: 2) at 2026-04-20 12:00:00
', 1),
('Physical store revenue', 105.98, '2026-04-20', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260420-598.
Created by Miltos Karabasilis (id: 2) at 2026-04-20 12:00:00
', 1),
('E-shop revenue', 154.88, '2026-04-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260421-488.
Created by Miltos Karabasilis (id: 2) at 2026-04-21 12:00:00
', 1),
('Physical store revenue', 94.92, '2026-04-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260421-492.
Created by Miltos Karabasilis (id: 2) at 2026-04-21 12:00:00
', 1),
('E-shop revenue', 121.46, '2026-04-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260422-146.
Created by Miltos Karabasilis (id: 2) at 2026-04-22 12:00:00
', 1),
('Physical store revenue', 74.44, '2026-04-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260422-444.
Created by Miltos Karabasilis (id: 2) at 2026-04-22 12:00:00
', 1),
('E-shop revenue', 124.93, '2026-04-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260423-493.
Created by Miltos Karabasilis (id: 2) at 2026-04-23 12:00:00
', 1),
('Physical store revenue', 76.57, '2026-04-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260423-657.
Created by Miltos Karabasilis (id: 2) at 2026-04-23 12:00:00
', 1),
('E-shop revenue', 128.40, '2026-04-24', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260424-840.
Created by Miltos Karabasilis (id: 2) at 2026-04-24 12:00:00
', 1),
('Physical store revenue', 78.70, '2026-04-24', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260424-870.
Created by Miltos Karabasilis (id: 2) at 2026-04-24 12:00:00
', 1),
('E-shop revenue', 159.77, '2026-04-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260425-977.
Created by Miltos Karabasilis (id: 2) at 2026-04-25 12:00:00
', 1),
('Physical store revenue', 97.93, '2026-04-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260425-793.
Created by Miltos Karabasilis (id: 2) at 2026-04-25 12:00:00
', 1),
('E-shop revenue', 163.25, '2026-04-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260426-325.
Created by Miltos Karabasilis (id: 2) at 2026-04-26 12:00:00
', 1),
('Physical store revenue', 100.05, '2026-04-26', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260426-005.
Created by Miltos Karabasilis (id: 2) at 2026-04-26 12:00:00
', 1),
('E-shop revenue', 151.22, '2026-04-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260427-122.
Created by Miltos Karabasilis (id: 2) at 2026-04-27 12:00:00
', 1),
('Physical store revenue', 92.68, '2026-04-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260427-268.
Created by Miltos Karabasilis (id: 2) at 2026-04-27 12:00:00
', 1),
('E-shop revenue', 133.18, '2026-04-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260428-318.
Created by Miltos Karabasilis (id: 2) at 2026-04-28 12:00:00
', 1),
('Physical store revenue', 81.62, '2026-04-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260428-162.
Created by Miltos Karabasilis (id: 2) at 2026-04-28 12:00:00
', 1),
('E-shop revenue', 136.65, '2026-04-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260429-665.
Created by Miltos Karabasilis (id: 2) at 2026-04-29 12:00:00
', 1),
('Physical store revenue', 83.75, '2026-04-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260429-375.
Created by Miltos Karabasilis (id: 2) at 2026-04-29 12:00:00
', 1),
('E-shop revenue', 140.12, '2026-04-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260430-012.
Created by Miltos Karabasilis (id: 2) at 2026-04-30 12:00:00
', 1),
('Physical store revenue', 85.88, '2026-04-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260430-588.
Created by Miltos Karabasilis (id: 2) at 2026-04-30 12:00:00
', 1),
('E-shop revenue', 141.73, '2026-05-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260501-173.
Created by Miltos Karabasilis (id: 2) at 2026-05-01 12:00:00
', 1),
('Physical store revenue', 86.87, '2026-05-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260501-687.
Created by Miltos Karabasilis (id: 2) at 2026-05-01 12:00:00
', 1),
('E-shop revenue', 173.10, '2026-05-02', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20260502-310.
Created by Miltos Karabasilis (id: 2) at 2026-05-02 12:00:00
', 1),
('Physical store revenue', 106.10, '2026-05-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260502-610.
Created by Miltos Karabasilis (id: 2) at 2026-05-02 12:00:00
', 1),
('E-shop revenue', 176.58, '2026-05-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260503-658.
Created by Miltos Karabasilis (id: 2) at 2026-05-03 12:00:00
', 1),
('Physical store revenue', 108.22, '2026-05-03', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260503-822.
Created by Miltos Karabasilis (id: 2) at 2026-05-03 12:00:00
', 1),
('E-shop revenue', 164.55, '2026-05-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260504-455.
Created by Miltos Karabasilis (id: 2) at 2026-05-04 12:00:00
', 1),
('Physical store revenue', 100.85, '2026-05-04', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260504-085.
Created by Miltos Karabasilis (id: 2) at 2026-05-04 12:00:00
', 1),
('E-shop revenue', 155.62, '2026-05-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260505-562.
Created by Miltos Karabasilis (id: 2) at 2026-05-05 12:00:00
', 1),
('Physical store revenue', 95.38, '2026-05-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260505-538.
Created by Miltos Karabasilis (id: 2) at 2026-05-05 12:00:00
', 1),
('E-shop revenue', 159.09, '2026-05-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260506-909.
Created by Miltos Karabasilis (id: 2) at 2026-05-06 12:00:00
', 1),
('Physical store revenue', 97.51, '2026-05-06', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260506-751.
Created by Miltos Karabasilis (id: 2) at 2026-05-06 12:00:00
', 1),
('E-shop revenue', 153.45, '2026-05-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260507-345.
Created by Miltos Karabasilis (id: 2) at 2026-05-07 12:00:00
', 1),
('Physical store revenue', 94.05, '2026-05-07', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260507-405.
Created by Miltos Karabasilis (id: 2) at 2026-05-07 12:00:00
', 1),
('E-shop revenue', 156.92, '2026-05-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260508-692.
Created by Miltos Karabasilis (id: 2) at 2026-05-08 12:00:00
', 1),
('Physical store revenue', 96.18, '2026-05-08', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260508-618.
Created by Miltos Karabasilis (id: 2) at 2026-05-08 12:00:00
', 1),
('E-shop revenue', 151.40, '2026-05-09', 'E-shop orders fulfilled from inventory bins after payment authorization. Weekend order batch reference WEB-20260509-140.
Created by Miltos Karabasilis (id: 2) at 2026-05-09 12:00:00
', 1),
('Physical store revenue', 92.80, '2026-05-09', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260509-280.
Created by Miltos Karabasilis (id: 2) at 2026-05-09 12:00:00
', 1),
('E-shop revenue', 154.88, '2026-05-10', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260510-488.
Created by Miltos Karabasilis (id: 2) at 2026-05-10 12:00:00
', 1),
('Physical store revenue', 94.92, '2026-05-10', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260510-492.
Created by Miltos Karabasilis (id: 2) at 2026-05-10 12:00:00
', 1),
('E-shop revenue', 142.85, '2026-05-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260511-285.
Created by Miltos Karabasilis (id: 2) at 2026-05-11 12:00:00
', 1),
('Physical store revenue', 87.55, '2026-05-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260511-755.
Created by Miltos Karabasilis (id: 2) at 2026-05-11 12:00:00
', 1),
('E-shop revenue', 133.92, '2026-05-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260512-392.
Created by Miltos Karabasilis (id: 2) at 2026-05-12 12:00:00
', 1),
('Physical store revenue', 82.08, '2026-05-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260512-208.
Created by Miltos Karabasilis (id: 2) at 2026-05-12 12:00:00
', 1),
('E-shop revenue', 137.39, '2026-05-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260513-739.
Created by Miltos Karabasilis (id: 2) at 2026-05-13 12:00:00
', 1),
('Physical store revenue', 84.21, '2026-05-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260513-421.
Created by Miltos Karabasilis (id: 2) at 2026-05-13 12:00:00
', 1),
('E-shop revenue', 131.75, '2026-05-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260514-175.
Created by Miltos Karabasilis (id: 2) at 2026-05-14 12:00:00
', 1),
('Physical store revenue', 80.75, '2026-05-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260514-075.
Created by Miltos Karabasilis (id: 2) at 2026-05-14 12:00:00
', 1),
('E-shop revenue', 135.22, '2026-05-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260515-522.
Created by Miltos Karabasilis (id: 2) at 2026-05-15 12:00:00
', 1),
('Physical store revenue', 82.88, '2026-05-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260515-288.
Created by Miltos Karabasilis (id: 2) at 2026-05-15 12:00:00
', 1),
('E-shop revenue', 166.59, '2026-05-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260516-659.
Created by Miltos Karabasilis (id: 2) at 2026-05-16 12:00:00
', 1),
('Physical store revenue', 102.11, '2026-05-16', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260516-211.
Created by Miltos Karabasilis (id: 2) at 2026-05-16 12:00:00
', 1),
('E-shop revenue', 170.07, '2026-05-17', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260517-007.
Created by Miltos Karabasilis (id: 2) at 2026-05-17 12:00:00
', 1),
('Physical store revenue', 104.23, '2026-05-17', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260517-423.
Created by Miltos Karabasilis (id: 2) at 2026-05-17 12:00:00
', 1),
('E-shop revenue', 158.04, '2026-05-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260518-804.
Created by Miltos Karabasilis (id: 2) at 2026-05-18 12:00:00
', 1),
('Physical store revenue', 96.86, '2026-05-18', 'Local pickup: Sofia Andreou, 3 Plateia Syntagmatos, Larissa 412 22. Customer collected 4 parcels at warehouse desk.
Created by Miltos Karabasilis (id: 2) at 2026-05-18 12:00:00
', 1),
('E-shop revenue', 149.11, '2026-05-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260519-911.
Created by Miltos Karabasilis (id: 2) at 2026-05-19 12:00:00
', 1),
('Physical store revenue', 91.39, '2026-05-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260519-139.
Created by Miltos Karabasilis (id: 2) at 2026-05-19 12:00:00
', 1),
('E-shop revenue', 152.58, '2026-05-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260520-258.
Created by Miltos Karabasilis (id: 2) at 2026-05-20 12:00:00
', 1),
('Physical store revenue', 93.52, '2026-05-20', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260520-352.
Created by Miltos Karabasilis (id: 2) at 2026-05-20 12:00:00
', 1),
('E-shop revenue', 146.94, '2026-05-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260521-694.
Created by Miltos Karabasilis (id: 2) at 2026-05-21 12:00:00
', 1),
('Physical store revenue', 90.06, '2026-05-21', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260521-006.
Created by Miltos Karabasilis (id: 2) at 2026-05-21 12:00:00
', 1),
('E-shop revenue', 150.41, '2026-05-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260522-041.
Created by Miltos Karabasilis (id: 2) at 2026-05-22 12:00:00
', 1),
('Physical store revenue', 92.19, '2026-05-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260522-219.
Created by Miltos Karabasilis (id: 2) at 2026-05-22 12:00:00
', 1),
('E-shop revenue', 181.78, '2026-05-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260523-178.
Created by Miltos Karabasilis (id: 2) at 2026-05-23 12:00:00
', 1),
('Physical store revenue', 111.42, '2026-05-23', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260523-142.
Created by Miltos Karabasilis (id: 2) at 2026-05-23 12:00:00
', 1),
('E-shop revenue', 185.26, '2026-05-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260524-526.
Created by Miltos Karabasilis (id: 2) at 2026-05-24 12:00:00
', 1),
('Physical store revenue', 113.54, '2026-05-24', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260524-354.
Created by Miltos Karabasilis (id: 2) at 2026-05-24 12:00:00
', 1),
('E-shop revenue', 173.23, '2026-05-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260525-323.
Created by Miltos Karabasilis (id: 2) at 2026-05-25 12:00:00
', 1),
('Physical store revenue', 106.17, '2026-05-25', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260525-617.
Created by Miltos Karabasilis (id: 2) at 2026-05-25 12:00:00
', 1),
('E-shop revenue', 127.41, '2026-05-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260526-741.
Created by Miltos Karabasilis (id: 2) at 2026-05-26 12:00:00
', 1),
('Physical store revenue', 78.09, '2026-05-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260526-809.
Created by Miltos Karabasilis (id: 2) at 2026-05-26 12:00:00
', 1),
('E-shop revenue', 130.88, '2026-05-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260527-088.
Created by Miltos Karabasilis (id: 2) at 2026-05-27 12:00:00
', 1),
('Physical store revenue', 80.22, '2026-05-27', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260527-022.
Created by Miltos Karabasilis (id: 2) at 2026-05-27 12:00:00
', 1),
('E-shop revenue', 125.24, '2026-05-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260528-524.
Created by Miltos Karabasilis (id: 2) at 2026-05-28 12:00:00
', 1),
('Physical store revenue', 76.76, '2026-05-28', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260528-676.
Created by Miltos Karabasilis (id: 2) at 2026-05-28 12:00:00
', 1),
('E-shop revenue', 128.71, '2026-05-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260529-871.
Created by Miltos Karabasilis (id: 2) at 2026-05-29 12:00:00
', 1),
('Physical store revenue', 78.89, '2026-05-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260529-889.
Created by Miltos Karabasilis (id: 2) at 2026-05-29 12:00:00
', 1),
('E-shop revenue', 160.08, '2026-05-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260530-008.
Created by Miltos Karabasilis (id: 2) at 2026-05-30 12:00:00
', 1),
('Physical store revenue', 98.12, '2026-05-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260530-812.
Created by Miltos Karabasilis (id: 2) at 2026-05-30 12:00:00
', 1),
('E-shop revenue', 163.56, '2026-05-31', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260531-356.
Created by Miltos Karabasilis (id: 2) at 2026-05-31 12:00:00
', 1),
('Physical store revenue', 100.24, '2026-05-31', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260531-024.
Created by Miltos Karabasilis (id: 2) at 2026-05-31 12:00:00
', 1),
('E-shop revenue', 148.37, '2026-06-01', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260601-837.
Created by Miltos Karabasilis (id: 2) at 2026-06-01 12:00:00
', 1),
('Physical store revenue', 90.93, '2026-06-01', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260601-093.
Created by Miltos Karabasilis (id: 2) at 2026-06-01 12:00:00
', 1),
('E-shop revenue', 139.44, '2026-06-02', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260602-944.
Created by Miltos Karabasilis (id: 2) at 2026-06-02 12:00:00
', 1),
('Physical store revenue', 85.46, '2026-06-02', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260602-546.
Created by Miltos Karabasilis (id: 2) at 2026-06-02 12:00:00
', 1),
('E-shop revenue', 142.91, '2026-06-03', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260603-291.
Created by Miltos Karabasilis (id: 2) at 2026-06-03 12:00:00
', 1),
('Physical store revenue', 87.59, '2026-06-03', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260603-759.
Created by Miltos Karabasilis (id: 2) at 2026-06-03 12:00:00
', 1),
('E-shop revenue', 146.38, '2026-06-04', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260604-638.
Created by Miltos Karabasilis (id: 2) at 2026-06-04 12:00:00
', 1),
('Physical store revenue', 89.72, '2026-06-04', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260604-972.
Created by Miltos Karabasilis (id: 2) at 2026-06-04 12:00:00
', 1),
('E-shop revenue', 149.85, '2026-06-05', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260605-985.
Created by Miltos Karabasilis (id: 2) at 2026-06-05 12:00:00
', 1),
('Physical store revenue', 91.85, '2026-06-05', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260605-185.
Created by Miltos Karabasilis (id: 2) at 2026-06-05 12:00:00
', 1),
('E-shop revenue', 181.23, '2026-06-06', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260606-123.
Created by Miltos Karabasilis (id: 2) at 2026-06-06 12:00:00
', 1),
('Physical store revenue', 111.07, '2026-06-06', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260606-107.
Created by Miltos Karabasilis (id: 2) at 2026-06-06 12:00:00
', 1),
('E-shop revenue', 175.58, '2026-06-07', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260607-558.
Created by Miltos Karabasilis (id: 2) at 2026-06-07 12:00:00
', 1),
('Physical store revenue', 107.62, '2026-06-07', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260607-762.
Created by Miltos Karabasilis (id: 2) at 2026-06-07 12:00:00
', 1),
('E-shop revenue', 163.56, '2026-06-08', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260608-356.
Created by Miltos Karabasilis (id: 2) at 2026-06-08 12:00:00
', 1),
('Physical store revenue', 100.24, '2026-06-08', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260608-024.
Created by Miltos Karabasilis (id: 2) at 2026-06-08 12:00:00
', 1),
('E-shop revenue', 154.63, '2026-06-09', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260609-463.
Created by Miltos Karabasilis (id: 2) at 2026-06-09 12:00:00
', 1),
('Physical store revenue', 94.77, '2026-06-09', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260609-477.
Created by Miltos Karabasilis (id: 2) at 2026-06-09 12:00:00
', 1),
('E-shop revenue', 158.10, '2026-06-10', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260610-810.
Created by Miltos Karabasilis (id: 2) at 2026-06-10 12:00:00
', 1),
('Physical store revenue', 96.90, '2026-06-10', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260610-690.
Created by Miltos Karabasilis (id: 2) at 2026-06-10 12:00:00
', 1),
('E-shop revenue', 161.57, '2026-06-11', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260611-157.
Created by Miltos Karabasilis (id: 2) at 2026-06-11 12:00:00
', 1),
('Physical store revenue', 99.03, '2026-06-11', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260611-903.
Created by Miltos Karabasilis (id: 2) at 2026-06-11 12:00:00
', 1),
('E-shop revenue', 128.15, '2026-06-12', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260612-815.
Created by Miltos Karabasilis (id: 2) at 2026-06-12 12:00:00
', 1),
('Physical store revenue', 78.55, '2026-06-12', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260612-855.
Created by Miltos Karabasilis (id: 2) at 2026-06-12 12:00:00
', 1),
('E-shop revenue', 159.53, '2026-06-13', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260613-953.
Created by Miltos Karabasilis (id: 2) at 2026-06-13 12:00:00
', 1),
('Physical store revenue', 97.77, '2026-06-13', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260613-777.
Created by Miltos Karabasilis (id: 2) at 2026-06-13 12:00:00
', 1),
('E-shop revenue', 153.88, '2026-06-14', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260614-388.
Created by Miltos Karabasilis (id: 2) at 2026-06-14 12:00:00
', 1),
('Physical store revenue', 94.32, '2026-06-14', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260614-432.
Created by Miltos Karabasilis (id: 2) at 2026-06-14 12:00:00
', 1),
('E-shop revenue', 141.86, '2026-06-15', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260615-186.
Created by Miltos Karabasilis (id: 2) at 2026-06-15 12:00:00
', 1),
('Physical store revenue', 86.94, '2026-06-15', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260615-694.
Created by Miltos Karabasilis (id: 2) at 2026-06-15 12:00:00
', 1),
('E-shop revenue', 132.93, '2026-06-16', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260616-293.
Created by Miltos Karabasilis (id: 2) at 2026-06-16 12:00:00
', 1),
('Physical store revenue', 81.47, '2026-06-16', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260616-147.
Created by Miltos Karabasilis (id: 2) at 2026-06-16 12:00:00
', 1),
('E-shop revenue', 136.40, '2026-06-17', 'E-shop orders fulfilled from inventory bins after payment authorization. Order batch reference WEB-20260617-640.
Created by Miltos Karabasilis (id: 2) at 2026-06-17 12:00:00
', 1),
('Physical store revenue', 83.60, '2026-06-17', 'Counter sales total for customers buying directly from the store location. Receipt batch POS-20260617-360.
Created by Miltos Karabasilis (id: 2) at 2026-06-17 12:00:00
', 1),
('E-shop revenue', 139.87, '2026-06-18', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260618-987.
Created by Miltos Karabasilis (id: 2) at 2026-06-18 12:00:00
', 1),
('Physical store revenue', 85.73, '2026-06-18', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260618-573.
Created by Miltos Karabasilis (id: 2) at 2026-06-18 12:00:00
', 1),
('E-shop revenue', 143.34, '2026-06-19', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260619-334.
Created by Miltos Karabasilis (id: 2) at 2026-06-19 12:00:00
', 1),
('Physical store revenue', 87.86, '2026-06-19', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260619-786.
Created by Miltos Karabasilis (id: 2) at 2026-06-19 12:00:00
', 1),
('E-shop revenue', 174.72, '2026-06-20', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260620-472.
Created by Miltos Karabasilis (id: 2) at 2026-06-20 12:00:00
', 1),
('Physical store revenue', 107.08, '2026-06-20', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260620-708.
Created by Miltos Karabasilis (id: 2) at 2026-06-20 12:00:00
', 1),
('E-shop revenue', 169.07, '2026-06-21', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260621-907.
Created by Miltos Karabasilis (id: 2) at 2026-06-21 12:00:00
', 1),
('Physical store revenue', 103.63, '2026-06-21', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260621-363.
Created by Miltos Karabasilis (id: 2) at 2026-06-21 12:00:00
', 1),
('E-shop revenue', 157.05, '2026-06-22', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260622-705.
Created by Miltos Karabasilis (id: 2) at 2026-06-22 12:00:00
', 1),
('Physical store revenue', 96.25, '2026-06-22', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260622-625.
Created by Miltos Karabasilis (id: 2) at 2026-06-22 12:00:00
', 1),
('E-shop revenue', 148.12, '2026-06-23', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260623-812.
Created by Miltos Karabasilis (id: 2) at 2026-06-23 12:00:00
', 1),
('Physical store revenue', 90.78, '2026-06-23', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260623-078.
Created by Miltos Karabasilis (id: 2) at 2026-06-23 12:00:00
', 1),
('E-shop revenue', 151.59, '2026-06-24', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260624-159.
Created by Miltos Karabasilis (id: 2) at 2026-06-24 12:00:00
', 1),
('Physical store revenue', 92.91, '2026-06-24', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260624-291.
Created by Miltos Karabasilis (id: 2) at 2026-06-24 12:00:00
', 1),
('E-shop revenue', 155.06, '2026-06-25', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260625-506.
Created by Miltos Karabasilis (id: 2) at 2026-06-25 12:00:00
', 1),
('Physical store revenue', 95.04, '2026-06-25', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260625-504.
Created by Miltos Karabasilis (id: 2) at 2026-06-25 12:00:00
', 1),
('E-shop revenue', 158.53, '2026-06-26', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260626-853.
Created by Miltos Karabasilis (id: 2) at 2026-06-26 12:00:00
', 1),
('Physical store revenue', 97.17, '2026-06-26', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260626-717.
Created by Miltos Karabasilis (id: 2) at 2026-06-26 12:00:00
', 1),
('E-shop revenue', 189.91, '2026-06-27', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260627-991.
Created by Miltos Karabasilis (id: 2) at 2026-06-27 12:00:00
', 1),
('Physical store revenue', 116.39, '2026-06-27', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260627-639.
Created by Miltos Karabasilis (id: 2) at 2026-06-27 12:00:00
', 1),
('E-shop revenue', 184.26, '2026-06-28', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Weekend order batch reference WEB-20260628-426.
Created by Miltos Karabasilis (id: 2) at 2026-06-28 12:00:00
', 1),
('Physical store revenue', 112.94, '2026-06-28', 'In-store POS sales and walk-in purchases at the retail counter. Receipt batch POS-20260628-294.
Created by Miltos Karabasilis (id: 2) at 2026-06-28 12:00:00
', 1),
('E-shop revenue', 135.35, '2026-06-29', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260629-535.
Created by Miltos Karabasilis (id: 2) at 2026-06-29 12:00:00
', 1),
('Physical store revenue', 82.95, '2026-06-29', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260629-295.
Created by Miltos Karabasilis (id: 2) at 2026-06-29 12:00:00
', 1),
('E-shop revenue', 126.42, '2026-06-30', 'Daily website checkout total. Orders picked, packed, and shipped from warehouse stock. Order batch reference WEB-20260630-642.
Created by Miltos Karabasilis (id: 2) at 2026-06-30 12:00:00
', 1),
('Physical store revenue', 77.48, '2026-06-30', 'Retail floor transactions recorded at the point-of-sale terminal. Receipt batch POS-20260630-748.
Created by Miltos Karabasilis (id: 2) at 2026-06-30 12:00:00
', 1);

-- Seed attachments for the two most recent income and expense rows (simple .txt files under uploads/{income|expense}/CompanyX/)
INSERT INTO `attachments` (`companyID`, `fileName`, `incomeID`, `expenseID`) VALUES
(1, '2553_seed_eshop.txt', 2553, NULL),
(1, '2554_seed_store.txt', 2554, NULL),
(1, '123_seed_labels.txt', NULL, 123),
(1, '124_seed_shopify.txt', NULL, 124);
