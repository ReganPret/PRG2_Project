-- USE farmForm;
-- This would tell SQL Server to use the farmForm database.
-- It is commented out because you may already have selected the database in SSMS.
-- If your query runs against the wrong database, remove the -- at the start.


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
   PROCEDURE: DeactivateProduct

   PURPOSE:
   Marks a product as inactive instead of deleting it.

   WHY:
   Keeps history safe.

   Java use:
   - Delete button
   ============================================================ */

CREATE OR ALTER PROCEDURE DeactivateAnimal
    @TagID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Animal
    SET Status = 'Sold'  -- or 'Retired' if you want to add it everywhere
    WHERE TagID = @TagID;
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


