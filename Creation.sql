--CREATE DATABASE farmForm;
USE farmForm;

CREATE TABLE Worker (
    EmpID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Position VARCHAR(50) NOT NULL,
    PhoneNumber VARCHAR(20),
    Status VARCHAR(20) NOT NULL DEFAULT 'Active',
    HireDate DATE
);
GO

CREATE TABLE UserAccount (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    EmpID INT NOT NULL UNIQUE,
    Username VARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    Role VARCHAR(20) NOT NULL,
    AccountStatus VARCHAR(20) NOT NULL DEFAULT 'Active',
    LastLogin DATETIME NULL,
    CONSTRAINT FK_UserAccount_Worker
        FOREIGN KEY (EmpID) REFERENCES Worker(EmpID)
);
GO

CREATE TABLE Animal (
    TagID INT PRIMARY KEY IDENTITY(1,1),
    AnimalType VARCHAR(50) NOT NULL,
    Breed VARCHAR(50) NOT NULL,
    Gender CHAR(1) NOT NULL,
    UseType VARCHAR(50),
    Status VARCHAR(20) NOT NULL DEFAULT 'Healthy',
    DateRegistered DATE NOT NULL,
    Notes VARCHAR(255),
    CONSTRAINT CHK_Animal_Gender CHECK (Gender IN ('M', 'F'))
);
GO

CREATE TABLE Product (
    ItemID INT PRIMARY KEY IDENTITY(1,1),
    ProductName VARCHAR(100) NOT NULL,
    ProductType VARCHAR(50) NOT NULL,
    QuantityOnHand INT NOT NULL DEFAULT 0,
    UnitOfMeasure VARCHAR(20),
    ReorderLevel INT NOT NULL DEFAULT 0,
    StorageLocation VARCHAR(100),
    Status VARCHAR(20) NOT NULL DEFAULT 'Active',
    CONSTRAINT CHK_Product_Quantity CHECK (QuantityOnHand >= 0),
    CONSTRAINT CHK_Product_Reorder CHECK (ReorderLevel >= 0)
);
GO

CREATE TABLE Treatment (
    TreatmentID INT PRIMARY KEY IDENTITY(1,1),
    TagID INT NOT NULL,
    EmpID INT NOT NULL,
    ItemID INT NOT NULL,
    TreatmentType VARCHAR(50) NOT NULL,
    TreatmentDate DATE NOT NULL,
    QuantityUsed INT NOT NULL DEFAULT 1,
    Notes VARCHAR(255),
    NextDueDate DATE,
    CONSTRAINT FK_Treatment_Animal
        FOREIGN KEY (TagID) REFERENCES Animal(TagID),
    CONSTRAINT FK_Treatment_Worker
        FOREIGN KEY (EmpID) REFERENCES Worker(EmpID),
    CONSTRAINT FK_Treatment_Product
        FOREIGN KEY (ItemID) REFERENCES Product(ItemID),
    CONSTRAINT CHK_Treatment_Quantity CHECK (QuantityUsed > 0)
);
GO

CREATE TABLE Task (
    TaskID INT PRIMARY KEY IDENTITY(1,1),
    EmpID INT NOT NULL,
    TagID INT NULL,
    TaskDescription VARCHAR(255) NOT NULL,
    TaskType VARCHAR(50) NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    DateAssigned DATE NOT NULL,
    DateCompleted DATE NULL,
    Notes VARCHAR(255),
    CONSTRAINT FK_Task_Worker
        FOREIGN KEY (EmpID) REFERENCES Worker(EmpID),
    CONSTRAINT FK_Task_Animal
        FOREIGN KEY (TagID) REFERENCES Animal(TagID)
);
GO

CREATE TABLE AnimalEvent (
    EventID INT PRIMARY KEY IDENTITY(1,1),
    TagID INT NOT NULL,
    EmpID INT NULL,
    EventType VARCHAR(30) NOT NULL,
    EventDate DATE NOT NULL,
    Notes VARCHAR(255),
    CONSTRAINT FK_AnimalEvent_Animal
        FOREIGN KEY (TagID) REFERENCES Animal(TagID),
    CONSTRAINT FK_AnimalEvent_Worker
        FOREIGN KEY (EmpID) REFERENCES Worker(EmpID)
);
GO

CREATE TABLE InventoryTransaction (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    ItemID INT NOT NULL,
    EmpID INT NULL,
    TransactionType VARCHAR(20) NOT NULL,
    QuantityChanged INT NOT NULL,
    TransactionDate DATE NOT NULL,
    ReferenceType VARCHAR(20),
    ReferenceID INT,
    Notes VARCHAR(255),
    CONSTRAINT FK_InventoryTransaction_Product
        FOREIGN KEY (ItemID) REFERENCES Product(ItemID),
    CONSTRAINT FK_InventoryTransaction_Worker
        FOREIGN KEY (EmpID) REFERENCES Worker(EmpID),
    CONSTRAINT CHK_InventoryTransaction_Quantity CHECK (QuantityChanged <> 0)
);