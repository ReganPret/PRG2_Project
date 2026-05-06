/* ============================================================
   PROCEDURE: sp_AddAnimal

   PURPOSE:
   This procedure adds/registers a new animal into the farm system.

   WHY WE USE A PROCEDURE:
   Java only needs to call sp_AddAnimal.
   The database then handles the insert and the first history record.

   TABLES USED:
   - Animal
   - AnimalEvent

   MAIN IDEA:
   1. Validate the animal details.
   2. Insert the animal.
   3. Get the new TagID.
   4. Add an AnimalEvent saying the animal was registered.
   5. Return the new TagID to Java.
   ============================================================ */

----------------------------------------------------------------------------------------------------------
-- Add Animal
----------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_AddAnimal
    -- This receives the animal type from Java.
    -- Example values: Cattle, Sheep, Poultry.
    @AnimalType      VARCHAR(50),

    -- This receives the breed from Java.
    -- Example values: Brahman, Dorper, Layer.
    @Breed           VARCHAR(50),

    -- This receives the animal gender.
    -- Only M or F is accepted by the validation below.
    @Gender          CHAR(1),

    -- This is optional.
    -- Example values: Milk, Meat, Eggs.
    -- NULL means Java does not have to send a value.
    @UseType         VARCHAR(50) = NULL,

    -- This is the animal status.
    -- If Java does not send a status, SQL Server uses Healthy.
    @Status          VARCHAR(20) = 'Healthy',

    -- This is the date the animal is registered.
    -- Java should send this value.
    @DateRegistered  DATE,

    -- Optional notes about the animal.
    -- NULL means this can be left blank.
    @Notes           VARCHAR(255) = NULL
AS
BEGIN
    -- Stops SQL Server from sending extra "rows affected" messages.
    -- This makes it cleaner when Java receives results.
    SET NOCOUNT ON;

    -- Check if AnimalType is missing, NULL, empty, or only spaces.
    -- LTRIM removes spaces from the left.
    -- RTRIM removes spaces from the right.
    IF @AnimalType IS NULL OR LTRIM(RTRIM(@AnimalType)) = ''
    BEGIN
        -- Show a clear error message.
        RAISERROR('AnimalType is required.', 16, 1);

        -- Stop the procedure here.
        RETURN;
    END

    -- Check if Breed is missing, NULL, empty, or only spaces.
    IF @Breed IS NULL OR LTRIM(RTRIM(@Breed)) = ''
    BEGIN
        -- Show a clear error message.
        RAISERROR('Breed is required.', 16, 1);

        -- Stop the procedure here.
        RETURN;
    END

    -- Check that Gender is only M or F.
    -- This prevents invalid values from being saved.
    IF @Gender NOT IN ('M', 'F')
    BEGIN
        -- Show a clear error message.
        RAISERROR('Gender must be M or F.', 16, 1);

        -- Stop the procedure here.
        RETURN;
    END

    -- Insert the new animal into the Animal table.
    INSERT INTO Animal (
        AnimalType,       -- Animal type column.
        Breed,            -- Breed column.
        Gender,           -- Gender column.
        UseType,          -- Use type column.
        Status,           -- Status column.
        DateRegistered,   -- Date registered column.
        Notes             -- Notes column.
    )
    VALUES (
        @AnimalType,      -- Value received by the procedure.
        @Breed,           -- Value received by the procedure.
        @Gender,          -- Value received by the procedure.
        @UseType,         -- Optional value received by the procedure.
        @Status,          -- Status received or default Healthy.
        @DateRegistered,  -- Date received by the procedure.
        @Notes            -- Optional notes.
    );

    -- Store the new animal ID created by SQL Server.
    -- SCOPE_IDENTITY() returns the identity ID from the last insert.
    DECLARE @NewTagID INT = SCOPE_IDENTITY();

    -- Insert the first history/event record for the animal.
    -- This means every animal has a record showing when it was registered.
    INSERT INTO AnimalEvent (
        TagID,       -- Links the event to the animal.
        EmpID,       -- Links the event to a worker, but NULL here.
        EventType,   -- Type of event.
        EventDate,   -- Date of event.
        Notes        -- Notes about the event.
    )
    VALUES (
        @NewTagID,              -- The animal that was just created.
        NULL,                   -- No worker linked during basic registration.
        'Registered',           -- Event type.
        @DateRegistered,        -- Same date as animal registration.
        'Animal added to system' -- Simple automatic note.
    );

    -- Return the new TagID.
    -- Java can use this ID after the insert.
    SELECT @NewTagID AS NewTagID;
END;
GO



/* ============================================================
   PROCEDURE: AddProduct

   PURPOSE:
   This procedure adds a new inventory item/product.

   EXAMPLES:
   - Cattle Feed
   - Vaccine
   - Deworming medicine
   - Cleaning supplies
   - Farm tools

   TABLES USED:
   - Product
   - InventoryTransaction

   MAIN IDEA:
   1. Validate the product details.
   2. Insert the product.
   3. Get the new ItemID.
   4. If opening stock is more than 0, log it as StockIn.
   5. Return the new ItemID to Java.
   ============================================================ */

----------------------------------------------------------------------------------------------------------
-- Add Product
----------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE AddProduct
    -- Product name received from Java.
    @ProductName       VARCHAR(100),

    -- Product type received from Java.
    -- Example: Feed, Medicine, Tool.
    @ProductType       VARCHAR(50),

    -- Current quantity in stock.
    -- Default is 0 if Java does not send a value.
    @QuantityOnHand    INT = 0,

    -- Unit of measure.
    -- Example: Bags, Bottles, Kg.
    @UnitOfMeasure     VARCHAR(20) = NULL,

    -- Level where the system should show low-stock warning.
    -- Example: if ReorderLevel is 10 and stock is 10 or below, it is low.
    @ReorderLevel      INT = 0,

    -- Where the product is stored.
    -- Example: Main Store, Medicine Cabinet.
    @StorageLocation   VARCHAR(100) = NULL,

    -- Worker/admin who added the product.
    @EmpID INT = NULL,

    -- Product status.
    -- Active means the product is currently used.
    @Status            VARCHAR(20) = 'Active'
AS
BEGIN
    -- Removes extra SQL Server messages.
    SET NOCOUNT ON;

    -- ProductName must not be missing or blank.
    IF @ProductName IS NULL OR LTRIM(RTRIM(@ProductName)) = ''
    BEGIN
        -- Stop and show error.
        RAISERROR('ProductName is required.', 16, 1);
        RETURN;
    END

    -- ProductType must not be missing or blank.
    IF @ProductType IS NULL OR LTRIM(RTRIM(@ProductType)) = ''
    BEGIN
        -- Stop and show error.
        RAISERROR('ProductType is required.', 16, 1);
        RETURN;
    END

    -- QuantityOnHand cannot be below zero.
    -- Negative stock does not make sense here.
    IF @QuantityOnHand < 0
    BEGIN
        -- Stop and show error.
        RAISERROR('QuantityOnHand cannot be negative.', 16, 1);
        RETURN;
    END

    -- ReorderLevel cannot be below zero.
    IF @ReorderLevel < 0
    BEGIN
        -- Stop and show error.
        RAISERROR('ReorderLevel cannot be negative.', 16, 1);
        RETURN;
    END

    -- Insert the product into the Product table.
    INSERT INTO Product (
        ProductName,      -- Product name column.
        ProductType,      -- Product type column.
        QuantityOnHand,   -- Current stock column.
        UnitOfMeasure,    -- Unit column.
        ReorderLevel,     -- Low-stock warning level column.
        StorageLocation,  -- Storage location column.
        Status            -- Status column.
    )
    VALUES (
        @ProductName,      -- Product name sent to procedure.
        @ProductType,      -- Product type sent to procedure.
        @QuantityOnHand,   -- Quantity sent or default 0.
        @UnitOfMeasure,    -- Unit sent or NULL.
        @ReorderLevel,     -- Reorder level sent or default 0.
        @StorageLocation,  -- Storage location sent or NULL.
        @Status            -- Status sent or default Active.
    );

    -- Store the new product ID.
    DECLARE @NewItemID INT = SCOPE_IDENTITY();

    -- If the product starts with stock available,
    -- record that starting stock in InventoryTransaction.
    IF @QuantityOnHand > 0
    BEGIN
        -- Add a stock history record.
        INSERT INTO InventoryTransaction (
            ItemID,             -- Product linked to this transaction.
            EmpID,              -- Worker linked to transaction.
            TransactionType,    -- StockIn, StockOut, or Adjustment.
            QuantityChanged,    -- How much stock changed.
            TransactionDate,    -- Date of stock movement.
            ReferenceType,      -- Why the transaction happened.
            ReferenceID,        -- Optional link to another record.
            Notes               -- Extra notes.
        )
        VALUES (
            @NewItemID,
            @EmpID,
            'StockIn',
            @QuantityOnHand,
            CAST(GETDATE() AS DATE),
            'Initial',
            @NewItemID,
            'Initial stock added during product creation'
        );
    END

    -- Return the new product ID to Java.
    SELECT @NewItemID AS NewItemID;
END;
GO

/* ============================================================
   PROCEDURE: AddWorker

   PURPOSE:
   This procedure adds a farm worker/staff member.

   EXAMPLES:
   - Farm Worker
   - Manager
   - Vet Assistant

   TABLE USED:
   - Worker

   MAIN IDEA:
   1. Check required worker details.
   2. Use today's date if HireDate is not supplied.
   3. Insert the worker.
   4. Return the new EmpID to Java.
   ============================================================ */

CREATE OR ALTER PROCEDURE AddWorker
    -- Worker first name.
    @FirstName VARCHAR(50),

    -- Worker surname / last name.
    @LastName VARCHAR(50),

    -- Work position or job title.
    @Position VARCHAR(50),

    -- Optional phone number.
    @PhoneNumber VARCHAR(20) = NULL,

    -- Worker status.
    -- Active means the worker can currently use the system.
    @Status VARCHAR(20) = 'Active',

    -- Date the worker was hired.
    -- If Java sends NULL, SQL Server uses today's date.
    @HireDate DATE = NULL
AS
BEGIN
    -- Removes extra SQL Server row-count messages.
    SET NOCOUNT ON;

    -- FirstName must not be NULL, empty, or only spaces.
    IF @FirstName IS NULL OR LTRIM(RTRIM(@FirstName)) = ''
    BEGIN
        RAISERROR('FirstName is required.', 16, 1);
        RETURN;
    END

    -- LastName must not be NULL, empty, or only spaces.
    IF @LastName IS NULL OR LTRIM(RTRIM(@LastName)) = ''
    BEGIN
        RAISERROR('LastName is required.', 16, 1);
        RETURN;
    END

    -- Position must not be NULL, empty, or only spaces.
    IF @Position IS NULL OR LTRIM(RTRIM(@Position)) = ''
    BEGIN
        RAISERROR('Position is required.', 16, 1);
        RETURN;
    END

    -- If no hire date was supplied, use today's date.
    IF @HireDate IS NULL
        SET @HireDate = CAST(GETDATE() AS DATE);

    -- Insert the worker into the Worker table.
    INSERT INTO Worker (
        FirstName,
        LastName,
        Position,
        PhoneNumber,
        Status,
        HireDate
    )
    VALUES (
        @FirstName,
        @LastName,
        @Position,
        @PhoneNumber,
        @Status,
        @HireDate
    );

    -- Return the new worker ID to Java.
    SELECT SCOPE_IDENTITY() AS NewEmpID;
END;
GO



/* ============================================================
   PROCEDURE: CreateUserAccount

   PURPOSE:
   This procedure creates a login account for a worker.

   IMPORTANT:
   This procedure does not create a plain text password.
   Java should hash the password first.
   The database stores only the PasswordHash.

   TABLES USED:
   - Worker
   - UserAccount

   MAIN IDEA:
   1. Check that the worker exists.
   2. Check that the worker does not already have a login.
   3. Check that the username is not already used.
   4. Insert the login account.
   5. Return the new UserID to Java.
   ============================================================ */

CREATE OR ALTER PROCEDURE CreateUserAccount
    -- Worker who owns this login account.
    @EmpID INT,

    -- Username used to log into the Java system.
    @Username VARCHAR(50),

    -- Hashed password.
    -- This should be created in Java before saving.
    @PasswordHash VARCHAR(255),

    -- User role.
    -- Example: Admin, Manager, Worker.
    @Role VARCHAR(20),

    -- Account status.
    -- Active means the account can log in.
    @AccountStatus VARCHAR(20) = 'Active'
AS
BEGIN
    -- Removes extra SQL Server row-count messages.
    SET NOCOUNT ON;

    -- Check that the worker exists before creating a login.
    IF NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    -- Prevent one worker from having more than one login account.
    IF EXISTS (SELECT 1 FROM UserAccount WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('This worker already has a user account.', 16, 1);
        RETURN;
    END

    -- Prevent duplicate usernames.
    -- Two people should not be able to log in with the same username.
    IF EXISTS (SELECT 1 FROM UserAccount WHERE Username = @Username)
    BEGIN
        RAISERROR('Username already exists.', 16, 1);
        RETURN;
    END

    -- Username must not be NULL, empty, or only spaces.
    IF @Username IS NULL OR LTRIM(RTRIM(@Username)) = ''
    BEGIN
        RAISERROR('Username is required.', 16, 1);
        RETURN;
    END

    -- PasswordHash must not be NULL, empty, or only spaces.
    IF @PasswordHash IS NULL OR LTRIM(RTRIM(@PasswordHash)) = ''
    BEGIN
        RAISERROR('PasswordHash is required.', 16, 1);
        RETURN;
    END

    -- Role must not be NULL, empty, or only spaces.
    IF @Role IS NULL OR LTRIM(RTRIM(@Role)) = ''
    BEGIN
        RAISERROR('Role is required.', 16, 1);
        RETURN;
    END

    -- Insert the login account into UserAccount.
    INSERT INTO UserAccount (
        EmpID,
        Username,
        PasswordHash,
        Role,
        AccountStatus
    )
    VALUES (
        @EmpID,
        @Username,
        @PasswordHash,
        @Role,
        @AccountStatus
    );

    -- Return the new UserID to Java.
    SELECT SCOPE_IDENTITY() AS NewUserID;
END;
GO