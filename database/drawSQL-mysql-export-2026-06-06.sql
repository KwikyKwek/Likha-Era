CREATE TABLE `Orders`(
    `orderId` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `orderLabel` VARCHAR(255) NOT NULL,
    `orderDescription` VARCHAR(255) NULL,
    `orderCreatedAt` TIMESTAMP NOT NULL,
    `statusId` INT NOT NULL,
    `userId` BIGINT NULL,
    `orderReference` VARCHAR(255) NULL,
    `paymentMethodId` BIGINT NOT NULL,
    `platformId` BIGINT NOT NULL,
    `cost` DECIMAL(8, 2) NOT NULL,
    `currency` VARCHAR(255) NOT NULL DEFAULT 'PHP',
    `notes` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Orders` ADD UNIQUE `orders_orderlabel_unique`(`orderLabel`);
ALTER TABLE
    `Orders` ADD UNIQUE `orders_userid_unique`(`userId`);
CREATE TABLE `orderline`(
    `orderlineId` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `orderId` BIGINT NOT NULL,
    `itemId` VARCHAR(255) NOT NULL,
    `orderlineDescription` BIGINT NOT NULL
);
CREATE TABLE `Status`(
    `statusId` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `statusLabel` VARCHAR(255) NOT NULL,
    `statusDescription` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Status` ADD UNIQUE `status_statuslabel_unique`(`statusLabel`);
ALTER TABLE
    `Status` ADD INDEX `status_statusdescription_index`(`statusDescription`);
CREATE TABLE `Users`(
    `userId` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `userName` BIGINT NOT NULL,
    `userPassword` VARCHAR(255) NOT NULL,
    `createdAt` TIMESTAMP NOT NULL,
    `userEmail` BIGINT NOT NULL
);
ALTER TABLE
    `Users` ADD UNIQUE `users_username_unique`(`userName`);
ALTER TABLE
    `Users` ADD UNIQUE `users_useremail_unique`(`userEmail`);
CREATE TABLE `CustomerInfo`(
    `customerId` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `firstName` VARCHAR(255) NOT NULL,
    `lastName` VARCHAR(255) NOT NULL,
    `userId` BIGINT NOT NULL
);
ALTER TABLE
    `CustomerInfo` ADD UNIQUE `customerinfo_userid_unique`(`userId`);
CREATE TABLE `LoyaltyRewards`(
    `loyaltyId` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `userId` BIGINT NOT NULL,
    `points` BIGINT NOT NULL,
    `tier` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `LoyaltyRewards` ADD INDEX `loyaltyrewards_userid_index`(`userId`);
CREATE TABLE `PaymentMethod`(
    `paymentMethodId` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `paymentLabel` VARCHAR(255) NOT NULL,
    `paymentDescription` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `PaymentMethod` ADD UNIQUE `paymentmethod_paymentlabel_unique`(`paymentLabel`);
CREATE TABLE `Platform`(
    `platformId` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `platformLabel` VARCHAR(255) NOT NULL,
    `platformDescription` VARCHAR(255) NOT NULL
);
ALTER TABLE
    `Platform` ADD UNIQUE `platform_platformlabel_unique`(`platformLabel`);
CREATE TABLE `Items`(
    `itemId` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `itemLabel` VARCHAR(255) NOT NULL,
    `itemDescription` VARCHAR(255) NOT NULL,
    `itemImageUrl` VARCHAR(255) NOT NULL,
    `stockQty` BIGINT NOT NULL,
    `active` BOOLEAN NOT NULL
);
ALTER TABLE
    `Items` ADD UNIQUE `items_itemlabel_unique`(`itemLabel`);
CREATE TABLE `orderStatusHistory`(
    `orderStatusId` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `orderId` BIGINT NOT NULL,
    `statusId` BIGINT NOT NULL,
    `changedAt` TIMESTAMP NOT NULL,
    `changedBy` VARCHAR(255) NOT NULL,
    `note` VARCHAR(255) NULL
);
ALTER TABLE
    `orderStatusHistory` ADD UNIQUE `orderstatushistory_orderid_unique`(`orderId`);
CREATE TABLE `OrderAttachments`(
    `attachmentId` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `orderId` BIGINT NOT NULL,
    `fileUrl` VARCHAR(255) NOT NULL,
    `fileType` VARCHAR(255) NOT NULL,
    `uploadedAt` TIMESTAMP NOT NULL,
    `uploadedBy` BIGINT NOT NULL
);
ALTER TABLE
    `OrderAttachments` ADD UNIQUE `orderattachments_orderid_unique`(`orderId`);
ALTER TABLE
    `OrderAttachments` ADD UNIQUE `orderattachments_uploadedby_unique`(`uploadedBy`);
CREATE TABLE `Addresses`(
    `addressId` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `customerId` BIGINT NOT NULL,
    `houseNumber` VARCHAR(255) NOT NULL,
    `street` VARCHAR(255) NOT NULL,
    `city` VARCHAR(255) NOT NULL,
    `province` VARCHAR(255) NOT NULL,
    `postalCode` BIGINT NOT NULL
);
ALTER TABLE
    `Addresses` ADD UNIQUE `addresses_customerid_unique`(`customerId`);
CREATE TABLE `Reviews`(
    `reviewId` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `orderId` BIGINT NOT NULL,
    `rating` INT NOT NULL,
    `comment` VARCHAR(255) NULL,
    `reviewedAt` TIMESTAMP NOT NULL
);
ALTER TABLE
    `Reviews` ADD UNIQUE `reviews_orderid_unique`(`orderId`);
CREATE TABLE `Contacts`(
    `contactId` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `contactEmail` VARCHAR(255) NOT NULL,
    `message` VARCHAR(255) NOT NULL,
    `createdAt` TIMESTAMP NOT NULL
);
ALTER TABLE
    `Orders` ADD CONSTRAINT `orders_email_foreign` FOREIGN KEY(`email`) REFERENCES `Users`(`userEmail`);
ALTER TABLE
    `CustomerInfo` ADD CONSTRAINT `customerinfo_customerid_foreign` FOREIGN KEY(`customerId`) REFERENCES `Addresses`(`customerId`);
ALTER TABLE
    `orderline` ADD CONSTRAINT `orderline_orderid_foreign` FOREIGN KEY(`orderId`) REFERENCES `Orders`(`orderId`);
ALTER TABLE
    `Orders` ADD CONSTRAINT `orders_platformid_foreign` FOREIGN KEY(`platformId`) REFERENCES `Platform`(`platformId`);
ALTER TABLE
    `orderStatusHistory` ADD CONSTRAINT `orderstatushistory_changedby_foreign` FOREIGN KEY(`changedBy`) REFERENCES `Users`(`userId`);
ALTER TABLE
    `Orders` ADD CONSTRAINT `orders_email_foreign` FOREIGN KEY(`email`) REFERENCES `Contacts`(`contactEmail`);
ALTER TABLE
    `Users` ADD CONSTRAINT `users_userid_foreign` FOREIGN KEY(`userId`) REFERENCES `LoyaltyRewards`(`userId`);
ALTER TABLE
    `Orders` ADD CONSTRAINT `orders_statusid_foreign` FOREIGN KEY(`statusId`) REFERENCES `Status`(`statusId`);
ALTER TABLE
    `CustomerInfo` ADD CONSTRAINT `customerinfo_userid_foreign` FOREIGN KEY(`userId`) REFERENCES `Users`(`userId`);
ALTER TABLE
    `Orders` ADD CONSTRAINT `orders_orderid_foreign` FOREIGN KEY(`orderId`) REFERENCES `Reviews`(`orderId`);
ALTER TABLE
    `orderline` ADD CONSTRAINT `orderline_itemid_foreign` FOREIGN KEY(`itemId`) REFERENCES `Items`(`itemId`);
ALTER TABLE
    `Orders` ADD CONSTRAINT `orders_paymentmethodid_foreign` FOREIGN KEY(`paymentMethodId`) REFERENCES `PaymentMethod`(`paymentMethodId`);
ALTER TABLE
    `orderStatusHistory` ADD CONSTRAINT `orderstatushistory_orderid_foreign` FOREIGN KEY(`orderId`) REFERENCES `Orders`(`orderId`);
ALTER TABLE
    `OrderAttachments` ADD CONSTRAINT `orderattachments_orderid_foreign` FOREIGN KEY(`orderId`) REFERENCES `Orders`(`orderId`);
ALTER TABLE
    `Orders` ADD CONSTRAINT `orders_userid_foreign` FOREIGN KEY(`userId`) REFERENCES `Users`(`userId`);
ALTER TABLE
    `OrderAttachments` ADD CONSTRAINT `orderattachments_uploadedby_foreign` FOREIGN KEY(`uploadedBy`) REFERENCES `Users`(`userId`);
ALTER TABLE
    `orderStatusHistory` ADD CONSTRAINT `orderstatushistory_statusid_foreign` FOREIGN KEY(`statusId`) REFERENCES `Status`(`statusId`);