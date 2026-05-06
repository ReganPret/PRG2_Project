USE farmForm;

--1. Clear all existing data from previous tests
EXEC DeleteAllTestData @Confirm = 'YES_DELETE_ALL';
GO

--2. Need to add the workers as done below:

EXEC AddWorker
    @FirstName = 'System',
    @LastName = 'Admin',
    @Position = 'Administrator',
    @PhoneNumber = '0000000000',
    @Status = 'Active';
GO

EXEC AddWorker
    @FirstName = 'Petrus',
    @LastName = 'Nambahu',
    @Position = 'Farm Worker',
    @PhoneNumber = '0811234567';
GO

EXEC AddWorker
    @FirstName = 'Anna',
    @LastName = 'Kandjii',
    @Position = 'Farm Manager',
    @PhoneNumber = '0817654321';
GO

EXEC AddWorker
    @FirstName = 'Samuel',
    @LastName = 'Haufiku',
    @Position = 'Vet Assistant',
    @PhoneNumber = '0815551111';
GO

--3. Get all of the workers to confirm they were created:
EXEC ViewAllWorkers;



--4. Need to create accounts for the users so that they can use the system and also be monitored


EXEC CreateUserAccount
    @EmpID = 1,
    @Username = 'admin',
    @PasswordHash = 'temporary_admin_hash',
    @Role = 'Admin',
    @AccountStatus = 'Active';
GO

EXEC CreateUserAccount
    @EmpID = 2,
    @Username = 'petrus',
    @PasswordHash = 'hash_for_petrus',
    @Role = 'Worker';
GO

EXEC CreateUserAccount
    @EmpID = 3,
    @Username = 'anna',
    @PasswordHash = 'hash_for_anna',
    @Role = 'Manager';
GO

EXEC CreateUserAccount
    @EmpID = 4,
    @Username = 'samuel',
    @PasswordHash = 'hash_for_samuel',
    @Role = 'Vet';
GO

-- 5. Get all of the accounts so we can see if they were created

EXEC ViewAllUserAccounts;

EXEC GetUserForLogin
    @Username = 'admin';
GO


-- 6. NExt we add animals

EXEC sp_AddAnimal
    @AnimalType = 'Cattle',
    @Breed = 'Brahman',
    @Gender = 'F',
    @UseType = 'Milk',
    @Status = 'Healthy',
    @DateRegistered = '2026-05-01',
    @Notes = 'Milking cow';
GO

EXEC sp_AddAnimal
    @AnimalType = 'Cattle',
    @Breed = 'Bonsmara',
    @Gender = 'M',
    @UseType = 'Meat',
    @Status = 'Healthy',
    @DateRegistered = '2026-05-01',
    @Notes = 'Young bull';
GO

EXEC sp_AddAnimal
    @AnimalType = 'Sheep',
    @Breed = 'Dorper',
    @Gender = 'F',
    @UseType = 'Meat',
    @Status = 'Healthy',
    @DateRegistered = '2026-05-02',
    @Notes = 'Breeding ewe';
GO

EXEC sp_AddAnimal
    @AnimalType = 'Poultry',
    @Breed = 'Layer',
    @Gender = 'F',
    @UseType = 'Eggs',
    @Status = 'Healthy',
    @DateRegistered = '2026-05-02',
    @Notes = 'Layer hen';
GO

-- 7. Confirm the animals were created

EXEC ViewAllAnimals;

-- 8. Add Products

EXEC AddProduct
    @ProductName = 'Cattle Feed',
    @ProductType = 'Feed',
    @QuantityOnHand = 50,
    @UnitOfMeasure = 'Bags',
    @ReorderLevel = 10,
    @StorageLocation = 'Main Store',
    @EmpID = 1,
    @Status = 'Active';
GO

EXEC AddProduct
    @ProductName = 'Sheep Feed',
    @ProductType = 'Feed',
    @QuantityOnHand = 30,
    @UnitOfMeasure = 'Bags',
    @ReorderLevel = 8,
    @StorageLocation = 'Main Store';
GO

EXEC AddProduct
    @ProductName = 'Vaccine A',
    @ProductType = 'Medicine',
    @QuantityOnHand = 20,
    @UnitOfMeasure = 'Doses',
    @ReorderLevel = 5,
    @StorageLocation = 'Medicine Cabinet';
GO

EXEC AddProduct
    @ProductName = 'Dewormer',
    @ProductType = 'Medicine',
    @QuantityOnHand = 15,
    @UnitOfMeasure = 'Doses',
    @ReorderLevel = 5,
    @StorageLocation = 'Medicine Cabinet';
GO

-- 9. View all Products/Stock

EXEC ViewAllProducts;
EXEC ViewAllInventoryTransactions;
GO

-- 10. Lets see the latest 10 things added (This takes a second)

EXEC ShowLatest10FromAllTables;
GO
