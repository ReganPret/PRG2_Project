-- USE farmForm;
-- This would tell SQL Server to use the farmForm database.
-- It is commented out because you may already have selected the database in SSMS.
-- If your query runs against the wrong database, remove the -- at the start.


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
            @NewItemID,                                      -- Product just created.
            NULL,                                            -- No worker linked to opening stock.
            'StockIn',                                       -- Opening stock is stock coming in.
            @QuantityOnHand,                                 -- Quantity added.
            CAST(GETDATE() AS DATE),                         -- Today's date.
            'Initial',                                       -- Initial stock entry.
            NULL,                                            -- No reference record.
            'Initial stock added during product creation'     -- Notes.
        );
    END

    -- Return the new product ID to Java.
    SELECT @NewItemID AS NewItemID;
END;
GO



/* ============================================================
   PROCEDURE: RestockProduct

   PURPOSE:
   This procedure adds more quantity to an existing product.

   EXAMPLE:
   The farm buys 20 more bags of feed.

   TABLES USED:
   - Product
   - InventoryTransaction

   MAIN IDEA:
   1. Check the product exists.
   2. Check the worker exists if EmpID is supplied.
   3. Check the quantity is valid.
   4. Increase Product.QuantityOnHand.
   5. Add a StockIn transaction.
   ============================================================ */

----------------------------------------------------------------------------------------------------------
-- Restock Product
----------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE RestockProduct
    -- Product ID that must be restocked.
    @ItemID             INT,

    -- Worker who performed the restock.
    -- NULL means no worker is linked.
    @EmpID              INT = NULL,

    -- Quantity being added to stock.
    @QuantityAdded      INT,

    -- Date of the stock transaction.
    -- NULL means use today's date.
    @TransactionDate    DATE = NULL,

    -- Optional notes.
    @Notes              VARCHAR(255) = NULL
AS
BEGIN
    -- Removes extra row-count messages.
    SET NOCOUNT ON;

    -- Make sure the product exists.
    -- SELECT 1 is used because we only care whether a row exists.
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ItemID = @ItemID)
    BEGIN
        -- Stop if product does not exist.
        RAISERROR('Product does not exist.', 16, 1);
        RETURN;
    END

    -- If EmpID is supplied, make sure the worker exists.
    -- If EmpID is NULL, this check is skipped.
    IF @EmpID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        -- Stop if worker does not exist.
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    -- Quantity added must be greater than zero.
    IF @QuantityAdded <= 0
    BEGIN
        -- Stop if the quantity is invalid.
        RAISERROR('QuantityAdded must be greater than zero.', 16, 1);
        RETURN;
    END

    -- If Java did not send a transaction date, use today.
    IF @TransactionDate IS NULL
        SET @TransactionDate = CAST(GETDATE() AS DATE);

    -- Start a database transaction.
    -- A transaction means all changes must succeed together.
    -- If one change fails, everything is rolled back.
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Increase the product quantity.
        UPDATE Product
        SET QuantityOnHand = QuantityOnHand + @QuantityAdded
        WHERE ItemID = @ItemID;

        -- Record the stock movement in InventoryTransaction.
        INSERT INTO InventoryTransaction (
            ItemID,             -- Product being changed.
            EmpID,              -- Worker responsible, if supplied.
            TransactionType,    -- StockIn because stock is added.
            QuantityChanged,    -- Quantity added.
            TransactionDate,    -- Date of transaction.
            ReferenceType,      -- Reason/category of transaction.
            ReferenceID,        -- No linked record here.
            Notes               -- Optional notes.
        )
        VALUES (
            @ItemID,            -- Product being restocked.
            @EmpID,             -- Worker ID or NULL.
            'StockIn',          -- Restocking is stock coming in.
            @QuantityAdded,     -- Amount added.
            @TransactionDate,   -- Date used.
            'Restock',          -- Reference type.
            NULL,               -- No reference ID.
            @Notes              -- Notes from Java or NULL.
        );

        -- Save both the product update and transaction insert.
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- If anything failed, undo all changes made in this transaction.
        ROLLBACK TRANSACTION;

        -- Throw the original SQL error back to Java/SSMS.
        THROW;
    END CATCH
END;
GO

/* ============================================================
   PROCEDURE: RecordTreatment

   PURPOSE:
   This procedure records medical treatment for an animal.

   EXAMPLE:
   - vaccination
   - deworming
   - medicine
   - routine vet treatment

   TABLES USED:
   - Animal
   - Worker
   - Product
   - Treatment
   - InventoryTransaction
   - AnimalEvent

   MAIN IDEA:
   1. Check that the animal exists.
   2. Check that the worker exists.
   3. Check that the product/medicine exists.
   4. Check that the treatment type is filled in.
   5. Check that enough stock is available.
   6. Insert the treatment record.
   7. Reduce product stock.
   8. Log the stock movement.
   9. Add an animal history event.
   ============================================================ */

----------------------------------------------------------------------------------------------------------
-- Record Treatment
----------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE RecordTreatment
    -- Animal being treated.
    @TagID             INT,

    -- Worker who performed the treatment.
    @EmpID             INT,

    -- Product or medicine used during treatment.
    @ItemID            INT,

    -- Type of treatment.
    -- Example: Vaccination, Deworming, Antibiotic.
    @TreatmentType     VARCHAR(50),

    -- Date the treatment happened.
    @TreatmentDate     DATE,

    -- Quantity of product/medicine used.
    @QuantityUsed      INT,

    -- Optional notes about the treatment.
    @Notes             VARCHAR(255) = NULL,

    -- Optional next date when treatment is due again.
    @NextDueDate       DATE = NULL
AS
BEGIN
    -- Removes extra SQL Server messages.
    SET NOCOUNT ON;

    -- This variable stores the current stock quantity.
    DECLARE @CurrentQty INT;

    -- This variable stores the new TreatmentID after insert.
    DECLARE @NewTreatmentID INT;

    -- Check that the animal exists before treatment is recorded.
    IF NOT EXISTS (SELECT 1 FROM Animal WHERE TagID = @TagID)
    BEGIN
        RAISERROR('Animal does not exist.', 16, 1);
        RETURN;
    END

    -- Check that the worker exists.
    IF NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    -- Check that the product/medicine exists.
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ItemID = @ItemID)
    BEGIN
        RAISERROR('Product does not exist.', 16, 1);
        RETURN;
    END

    -- Treatment type must not be empty.
    IF @TreatmentType IS NULL OR LTRIM(RTRIM(@TreatmentType)) = ''
    BEGIN
        RAISERROR('TreatmentType is required.', 16, 1);
        RETURN;
    END

    -- Quantity used must be greater than zero.
    IF @QuantityUsed <= 0
    BEGIN
        RAISERROR('QuantityUsed must be greater than zero.', 16, 1);
        RETURN;
    END

    -- Get current stock level for the selected product.
    SELECT @CurrentQty = QuantityOnHand
    FROM Product
    WHERE ItemID = @ItemID;

    -- Stop if there is not enough stock.
    IF @CurrentQty < @QuantityUsed
    BEGIN
        RAISERROR('Insufficient stock available for this treatment.', 16, 1);
        RETURN;
    END

    -- Start a transaction because multiple tables must be updated together.
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Insert the treatment into the Treatment table.
        INSERT INTO Treatment (
            TagID,
            EmpID,
            ItemID,
            TreatmentType,
            TreatmentDate,
            QuantityUsed,
            Notes,
            NextDueDate
        )
        VALUES (
            @TagID,
            @EmpID,
            @ItemID,
            @TreatmentType,
            @TreatmentDate,
            @QuantityUsed,
            @Notes,
            @NextDueDate
        );

        -- Get the TreatmentID that SQL Server just created.
        SET @NewTreatmentID = SCOPE_IDENTITY();

        -- Reduce the product quantity because medicine/product was used.
        UPDATE Product
        SET QuantityOnHand = QuantityOnHand - @QuantityUsed
        WHERE ItemID = @ItemID;

        -- Log the stock movement.
        -- QuantityChanged is negative because stock is going out.
        INSERT INTO InventoryTransaction (
            ItemID,
            EmpID,
            TransactionType,
            QuantityChanged,
            TransactionDate,
            ReferenceType,
            ReferenceID,
            Notes
        )
        VALUES (
            @ItemID,
            @EmpID,
            'StockOut',
            -@QuantityUsed,
            @TreatmentDate,
            'Treatment',
            @NewTreatmentID,
            @Notes
        );

        -- Add the treatment to the animal's event/history table.
        INSERT INTO AnimalEvent (
            TagID,
            EmpID,
            EventType,
            EventDate,
            Notes
        )
        VALUES (
            @TagID,
            @EmpID,
            @TreatmentType,
            @TreatmentDate,
            @Notes
        );

        -- Save all changes permanently.
        COMMIT TRANSACTION;

        -- Return the new treatment ID to Java.
        SELECT @NewTreatmentID AS NewTreatmentID;
    END TRY
    BEGIN CATCH
        -- Undo all changes if anything failed.
        ROLLBACK TRANSACTION;

        -- Send the original error back.
        THROW;
    END CATCH
END;
GO



/* ============================================================
   PROCEDURE: UpdateAnimalStatus

   PURPOSE:
   This procedure changes an animal's status.

   EXAMPLES:
   - Healthy
   - Sick
   - Sold
   - Died
   - Lost
   - Stolen

   TABLES USED:
   - Animal
   - AnimalEvent

   MAIN IDEA:
   1. Check that the animal exists.
   2. Check that the worker exists if one is supplied.
   3. Save the old status.
   4. Update the animal to the new status.
   5. Add an event showing the status change.
   ============================================================ */

----------------------------------------------------------------------------------------------------------
-- Update Animal Status
----------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE UpdateAnimalStatus
    -- Animal whose status must be changed.
    @TagID         INT,

    -- Worker who changed the status.
    -- Optional because some system actions may not have a worker.
    @EmpID         INT = NULL,

    -- New animal status.
    @NewStatus     VARCHAR(20),

    -- Date when the status changed.
    -- If NULL, SQL Server uses today's date.
    @EventDate     DATE = NULL,

    -- Optional notes about why the status changed.
    @Notes         VARCHAR(255) = NULL
AS
BEGIN
    -- Removes extra SQL Server messages.
    SET NOCOUNT ON;

    -- This stores the old status before it gets changed.
    DECLARE @OldStatus VARCHAR(20);

    -- Make sure the animal exists.
    IF NOT EXISTS (SELECT 1 FROM Animal WHERE TagID = @TagID)
    BEGIN
        RAISERROR('Animal does not exist.', 16, 1);
        RETURN;
    END

    -- If a worker was supplied, make sure that worker exists.
    IF @EmpID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    -- NewStatus must not be blank.
    IF @NewStatus IS NULL OR LTRIM(RTRIM(@NewStatus)) = ''
    BEGIN
        RAISERROR('NewStatus is required.', 16, 1);
        RETURN;
    END

    -- If Java does not send an event date, use today's date.
    IF @EventDate IS NULL
        SET @EventDate = CAST(GETDATE() AS DATE);

    -- Get the old status before updating.
    SELECT @OldStatus = Status
    FROM Animal
    WHERE TagID = @TagID;

    -- Start transaction because we update Animal and insert AnimalEvent together.
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Update the animal's current status.
        UPDATE Animal
        SET Status = @NewStatus
        WHERE TagID = @TagID;

        -- Insert a history event showing the status change.
        INSERT INTO AnimalEvent (
            TagID,
            EmpID,
            EventType,
            EventDate,
            Notes
        )
        VALUES (
            @TagID,
            @EmpID,
            'StatusChange',
            @EventDate,
            CONCAT(
                'Status changed from ',
                @OldStatus,
                ' to ',
                @NewStatus,
                CASE
                    WHEN @Notes IS NOT NULL THEN CONCAT(' - ', @Notes)
                    ELSE ''
                END
            )
        );

        -- Save both changes.
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Undo both changes if anything failed.
        ROLLBACK TRANSACTION;

        -- Send original error back.
        THROW;
    END CATCH
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



/* ============================================================
   PROCEDURE: AssignTask

   PURPOSE:
   This procedure assigns work to a worker.

   EXAMPLES:
   - Feed cattle
   - Check sick animal
   - Clean poultry area
   - Inspect water supply

   TABLES USED:
   - Worker
   - Animal
   - Task

   MAIN IDEA:
   1. Check that the worker exists.
   2. If an animal is linked, check that the animal exists.
   3. Check required task details.
   4. Insert the task as Pending.
   5. Return the new TaskID to Java.
   ============================================================ */

CREATE OR ALTER PROCEDURE AssignTask
    -- Worker receiving the task.
    @EmpID INT,

    -- Optional animal linked to the task.
    -- NULL means this task is not for one specific animal.
    @TagID INT = NULL,

    -- Description of what must be done.
    @TaskDescription VARCHAR(255),

    -- Category/type of task.
    -- Example: Feeding, Cleaning, Inspection, Health Check.
    @TaskType VARCHAR(50),

    -- Date the task was assigned.
    -- If NULL, SQL Server uses today's date.
    @DateAssigned DATE = NULL,

    -- Optional notes.
    @Notes VARCHAR(255) = NULL
AS
BEGIN
    -- Removes extra SQL Server row-count messages.
    SET NOCOUNT ON;

    -- Check that the worker exists.
    IF NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    -- If a TagID was supplied, check that the animal exists.
    IF @TagID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Animal WHERE TagID = @TagID)
    BEGIN
        RAISERROR('Animal does not exist.', 16, 1);
        RETURN;
    END

    -- TaskDescription must not be NULL, empty, or only spaces.
    IF @TaskDescription IS NULL OR LTRIM(RTRIM(@TaskDescription)) = ''
    BEGIN
        RAISERROR('TaskDescription is required.', 16, 1);
        RETURN;
    END

    -- TaskType must not be NULL, empty, or only spaces.
    IF @TaskType IS NULL OR LTRIM(RTRIM(@TaskType)) = ''
    BEGIN
        RAISERROR('TaskType is required.', 16, 1);
        RETURN;
    END

    -- If Java does not send a date, use today's date.
    IF @DateAssigned IS NULL
        SET @DateAssigned = CAST(GETDATE() AS DATE);

    -- Insert the task into the Task table.
    -- Status is set to Pending because the task is not done yet.
    INSERT INTO Task (
        EmpID,
        TagID,
        TaskDescription,
        TaskType,
        Status,
        DateAssigned,
        Notes
    )
    VALUES (
        @EmpID,
        @TagID,
        @TaskDescription,
        @TaskType,
        'Pending',
        @DateAssigned,
        @Notes
    );

    -- Return the new TaskID to Java.
    SELECT SCOPE_IDENTITY() AS NewTaskID;
END;
GO



/* ============================================================
   PROCEDURE: CompleteTask

   PURPOSE:
   This procedure marks an existing task as completed.

   TABLE USED:
   - Task

   MAIN IDEA:
   1. Check that the task exists.
   2. Use today's date if DateCompleted is not supplied.
   3. Change Status to Completed.
   4. Save completion notes if supplied.
   ============================================================ */

CREATE OR ALTER PROCEDURE CompleteTask
    -- Task that must be completed.
    @TaskID INT,

    -- Date the task was completed.
    -- If NULL, SQL Server uses today's date.
    @DateCompleted DATE = NULL,

    -- Optional notes about the completed task.
    @Notes VARCHAR(255) = NULL
AS
BEGIN
    -- Removes extra SQL Server row-count messages.
    SET NOCOUNT ON;

    -- Check that the task exists.
    IF NOT EXISTS (SELECT 1 FROM Task WHERE TaskID = @TaskID)
    BEGIN
        RAISERROR('Task does not exist.', 16, 1);
        RETURN;
    END

    -- If Java does not send a completion date, use today's date.
    IF @DateCompleted IS NULL
        SET @DateCompleted = CAST(GETDATE() AS DATE);

    -- Update the task.
    -- Status becomes Completed.
    -- DateCompleted is saved.
    -- COALESCE(@Notes, Notes) means:
    -- If @Notes is not NULL, use the new notes.
    -- If @Notes is NULL, keep the old notes already in the table.
    UPDATE Task
    SET Status = 'Completed',
        DateCompleted = @DateCompleted,
        Notes = COALESCE(@Notes, Notes)
    WHERE TaskID = @TaskID;
END;
GO



/* ============================================================
   PROCEDURE: UseProduct

   PURPOSE:
   This procedure records normal stock usage.

   This is used when stock is consumed outside medical treatment.

   EXAMPLES:
   - Feed used for animals
   - Cleaning supplies used
   - General supplies used

   TABLES USED:
   - Product
   - Worker
   - InventoryTransaction

   MAIN IDEA:
   1. Check that the product exists.
   2. Check that the worker exists if supplied.
   3. Check that quantity is valid.
   4. Check that enough stock exists.
   5. Reduce Product.QuantityOnHand.
   6. Insert a StockOut transaction.
   ============================================================ */

CREATE OR ALTER PROCEDURE UseProduct
    -- Product being used.
    @ItemID INT,

    -- Worker who used the product.
    -- NULL means no worker is linked.
    @EmpID INT = NULL,

    -- Quantity used.
    @QuantityUsed INT,

    -- Date of usage.
    -- If NULL, SQL Server uses today's date.
    @TransactionDate DATE = NULL,

    -- Reason/category for the stock usage.
    -- Example: Feeding, Cleaning, GeneralUse.
    @ReferenceType VARCHAR(20) = 'GeneralUse',

    -- Optional ID linking this usage to another table.
    @ReferenceID INT = NULL,

    -- Optional notes.
    @Notes VARCHAR(255) = NULL
AS
BEGIN
    -- Removes extra SQL Server row-count messages.
    SET NOCOUNT ON;

    -- Stores the product's current quantity before reducing it.
    DECLARE @CurrentQty INT;

    -- Check that the product exists.
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ItemID = @ItemID)
    BEGIN
        RAISERROR('Product does not exist.', 16, 1);
        RETURN;
    END

    -- If EmpID was supplied, check that the worker exists.
    IF @EmpID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    -- Quantity used must be greater than zero.
    IF @QuantityUsed <= 0
    BEGIN
        RAISERROR('QuantityUsed must be greater than zero.', 16, 1);
        RETURN;
    END

    -- If Java does not send a date, use today's date.
    IF @TransactionDate IS NULL
        SET @TransactionDate = CAST(GETDATE() AS DATE);

    -- Get current quantity from the Product table.
    SELECT @CurrentQty = QuantityOnHand
    FROM Product
    WHERE ItemID = @ItemID;

    -- Stop if there is not enough stock.
    IF @CurrentQty < @QuantityUsed
    BEGIN
        RAISERROR('Insufficient stock available.', 16, 1);
        RETURN;
    END

    -- Start transaction because stock update and stock history must match.
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Reduce stock.
        UPDATE Product
        SET QuantityOnHand = QuantityOnHand - @QuantityUsed
        WHERE ItemID = @ItemID;

        -- Insert stock history record.
        -- QuantityChanged is negative because stock is going out.
        INSERT INTO InventoryTransaction (
            ItemID,
            EmpID,
            TransactionType,
            QuantityChanged,
            TransactionDate,
            ReferenceType,
            ReferenceID,
            Notes
        )
        VALUES (
            @ItemID,
            @EmpID,
            'StockOut',
            -@QuantityUsed,
            @TransactionDate,
            @ReferenceType,
            @ReferenceID,
            @Notes
        );

        -- Save both changes.
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Undo both changes if anything failed.
        ROLLBACK TRANSACTION;

        -- Send the error back to Java/SSMS.
        THROW;
    END CATCH
END;
GO


/* ============================================================
   PROCEDURE: GetAllAnimals

   PURPOSE:
   Returns all animals in the system.

   Java use:
   - Populate main animal table
   - Default screen load

   NOTE:
   Ordered by newest first (highest TagID first)
   ============================================================ */

CREATE OR ALTER PROCEDURE GetAllAnimals
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Animal
    ORDER BY TagID DESC;
END;
GO

/* ============================================================
   PROCEDURE: GetAllProducts

   PURPOSE:
   Returns all products in the system.

   Java use:
   - Populate inventory table
   ============================================================ */

CREATE OR ALTER PROCEDURE GetAllProducts
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Product
    ORDER BY ItemID DESC;
END;
GO

/* ============================================================
   PROCEDURE: GetAllWorkers

   PURPOSE:
   Returns all workers.

   Java use:
   - Dropdowns
   - Worker management screen
   ============================================================ */

CREATE OR ALTER PROCEDURE GetAllWorkers
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Worker
    ORDER BY EmpID DESC;
END;
GO

/* ============================================================
   PROCEDURE: GetAllTasks

   PURPOSE:
   Returns all tasks.

   Java use:
   - Task screen
   ============================================================ */

CREATE OR ALTER PROCEDURE GetAllTasks
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Task
    ORDER BY TaskID DESC;
END;
GO

/* ============================================================
   PROCEDURE: GetAllTreatments

   PURPOSE:
   Returns all treatments.

   Java use:
   - Treatment history screen
   ============================================================ */

CREATE OR ALTER PROCEDURE GetAllTreatments
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Treatment
    ORDER BY TreatmentID DESC;
END;
GO


/* ============================================================
   PROCEDURE: SearchAnimals

   PURPOSE:
   Flexible animal filtering.

   Java use:
   - Dropdown filters
   - Search screen

   HOW IT WORKS:
   If a parameter is NULL, it is ignored.
   ============================================================ */

CREATE OR ALTER PROCEDURE SearchAnimals
    @AnimalType VARCHAR(50) = NULL,
    @Status     VARCHAR(20) = NULL,
    @Gender     CHAR(1)     = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Animal
    WHERE (@AnimalType IS NULL OR AnimalType = @AnimalType)
      AND (@Status IS NULL OR Status = @Status)
      AND (@Gender IS NULL OR Gender = @Gender)
    ORDER BY TagID DESC;
END;
GO


/* ============================================================
   PROCEDURE: SearchProducts

   PURPOSE:
   Flexible product filtering.

   Java use:
   - Inventory search
   ============================================================ */

CREATE OR ALTER PROCEDURE SearchProducts
    @ProductType VARCHAR(50) = NULL,
    @Status      VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Product
    WHERE (@ProductType IS NULL OR ProductType = @ProductType)
      AND (@Status IS NULL OR Status = @Status)
    ORDER BY ItemID DESC;
END;
GO


/* ============================================================
   PROCEDURE: UpdateAnimalDetails

   PURPOSE:
   Allows editing animal information (not status).

   Java use:
   - Edit animal screen
   ============================================================ */

CREATE OR ALTER PROCEDURE UpdateAnimalDetails
    @TagID INT,
    @AnimalType VARCHAR(50),
    @Breed VARCHAR(50),
    @Gender CHAR(1),
    @UseType VARCHAR(50),
    @Notes VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Check that the animal exists
    IF NOT EXISTS (SELECT 1 FROM Animal WHERE TagID = @TagID)
    BEGIN
        RAISERROR('Animal does not exist.', 16, 1);
        RETURN;
    END

    -- Validate AnimalType
    IF @AnimalType IS NULL OR LTRIM(RTRIM(@AnimalType)) = ''
    BEGIN
        RAISERROR('AnimalType is required.', 16, 1);
        RETURN;
    END

    -- Validate Breed
    IF @Breed IS NULL OR LTRIM(RTRIM(@Breed)) = ''
    BEGIN
        RAISERROR('Breed is required.', 16, 1);
        RETURN;
    END

    -- Validate Gender
    IF @Gender NOT IN ('M','F')
    BEGIN
        RAISERROR('Gender must be M or F.', 16, 1);
        RETURN;
    END

    -- Perform update
    UPDATE Animal
    SET AnimalType = @AnimalType,
        Breed = @Breed,
        Gender = @Gender,
        UseType = @UseType,
        Notes = @Notes
    WHERE TagID = @TagID;
END;
GO

/* ============================================================
   PROCEDURE: UpdateProductDetails

   PURPOSE:
   Allows editing product details (not stock).

   Java use:
   - Edit product screen
   ============================================================ */

CREATE OR ALTER PROCEDURE UpdateProductDetails
    @ItemID INT,
    @ProductName VARCHAR(100),
    @ProductType VARCHAR(50),
    @UnitOfMeasure VARCHAR(20),
    @ReorderLevel INT,
    @StorageLocation VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Product WHERE ItemID = @ItemID)
    BEGIN
        RAISERROR('Product does not exist.', 16, 1);
        RETURN;
    END

    UPDATE Product
    SET ProductName = @ProductName,
        ProductType = @ProductType,
        UnitOfMeasure = @UnitOfMeasure,
        ReorderLevel = @ReorderLevel,
        StorageLocation = @StorageLocation
    WHERE ItemID = @ItemID;
END;
GO


/* ============================================================
   PROCEDURE: UpdateWorkerDetails

   PURPOSE:
   Allows editing worker information.

   Java use:
   - Edit worker screen
   ============================================================ */

CREATE OR ALTER PROCEDURE UpdateWorkerDetails
    @EmpID INT,
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @Position VARCHAR(50),
    @PhoneNumber VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    UPDATE Worker
    SET FirstName = @FirstName,
        LastName = @LastName,
        Position = @Position,
        PhoneNumber = @PhoneNumber
    WHERE EmpID = @EmpID;
END;
GO


/* ============================================================
   PROCEDURE: DeactivateProduct

   PURPOSE:
   Marks a product as inactive instead of deleting it.

   WHY:
   Keeps history safe.

   Java use:
   - Delete button
   ============================================================ */

CREATE OR ALTER PROCEDURE DeactivateProduct
    @ItemID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Product
    SET Status = 'Inactive'
    WHERE ItemID = @ItemID;
END;
GO


/* ============================================================
   PROCEDURE: DeactivateWorker

   PURPOSE:
   Marks a worker as inactive.

   Java use:
   - Disable worker
   ============================================================ */

CREATE OR ALTER PROCEDURE DeactivateWorker
    @EmpID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Worker
    SET Status = 'Inactive'
    WHERE EmpID = @EmpID;
END;
GO


/* ============================================================
   PROCEDURE: DeactivateAnimal

   PURPOSE:
   Marks an animal as inactive (or retired).

   NOTE:
   You could also use UpdateAnimalStatus instead.

   Java use:
   - Archive animal
   ============================================================ */

CREATE OR ALTER PROCEDURE DeactivateAnimal
    @TagID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Animal
    SET Status = 'Sold'
    WHERE TagID = @TagID;
END;
GO



