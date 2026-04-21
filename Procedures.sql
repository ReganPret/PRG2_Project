--USE farmForm;

CREATE OR ALTER PROCEDURE sp_AddAnimal
    @AnimalType      VARCHAR(50),
    @Breed           VARCHAR(50),
    @Gender          CHAR(1),
    @UseType         VARCHAR(50) = NULL,
    @Status          VARCHAR(20) = 'Healthy',
    @DateRegistered  DATE,
    @Notes           VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @AnimalType IS NULL OR LTRIM(RTRIM(@AnimalType)) = ''
    BEGIN
        RAISERROR('AnimalType is required.', 16, 1);
        RETURN;
    END

    IF @Breed IS NULL OR LTRIM(RTRIM(@Breed)) = ''
    BEGIN
        RAISERROR('Breed is required.', 16, 1);
        RETURN;
    END

    IF @Gender NOT IN ('M', 'F')
    BEGIN
        RAISERROR('Gender must be M or F.', 16, 1);
        RETURN;
    END

    INSERT INTO Animal (
        AnimalType,
        Breed,
        Gender,
        UseType,
        Status,
        DateRegistered,
        Notes
    )
    VALUES (
        @AnimalType,
        @Breed,
        @Gender,
        @UseType,
        @Status,
        @DateRegistered,
        @Notes
    );

    DECLARE @NewTagID INT = SCOPE_IDENTITY();

    INSERT INTO AnimalEvent (
        TagID,
        EmpID,
        EventType,
        EventDate,
        Notes
    )
    VALUES (
        @NewTagID,
        NULL,
        'Registered',
        @DateRegistered,
        'Animal added to system'
    );

    SELECT @NewTagID AS NewTagID;
END;
GO

exec sp_AddAnimal



CREATE OR ALTER PROCEDURE sp_AddProduct
    @ProductName       VARCHAR(100),
    @ProductType       VARCHAR(50),
    @QuantityOnHand    INT = 0,
    @UnitOfMeasure     VARCHAR(20) = NULL,
    @ReorderLevel      INT = 0,
    @StorageLocation   VARCHAR(100) = NULL,
    @Status            VARCHAR(20) = 'Active'
AS
BEGIN
    SET NOCOUNT ON;

    IF @ProductName IS NULL OR LTRIM(RTRIM(@ProductName)) = ''
    BEGIN
        RAISERROR('ProductName is required.', 16, 1);
        RETURN;
    END

    IF @ProductType IS NULL OR LTRIM(RTRIM(@ProductType)) = ''
    BEGIN
        RAISERROR('ProductType is required.', 16, 1);
        RETURN;
    END

    IF @QuantityOnHand < 0
    BEGIN
        RAISERROR('QuantityOnHand cannot be negative.', 16, 1);
        RETURN;
    END

    IF @ReorderLevel < 0
    BEGIN
        RAISERROR('ReorderLevel cannot be negative.', 16, 1);
        RETURN;
    END

    INSERT INTO Product (
        ProductName,
        ProductType,
        QuantityOnHand,
        UnitOfMeasure,
        ReorderLevel,
        StorageLocation,
        Status
    )
    VALUES (
        @ProductName,
        @ProductType,
        @QuantityOnHand,
        @UnitOfMeasure,
        @ReorderLevel,
        @StorageLocation,
        @Status
    );

    DECLARE @NewItemID INT = SCOPE_IDENTITY();

    IF @QuantityOnHand > 0
    BEGIN
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
            @NewItemID,
            NULL,
            'StockIn',
            @QuantityOnHand,
            CAST(GETDATE() AS DATE),
            'Initial',
            NULL,
            'Initial stock added during product creation'
        );
    END

    SELECT @NewItemID AS NewItemID;
END;
GO


CREATE OR ALTER PROCEDURE sp_RestockProduct
    @ItemID             INT,
    @EmpID              INT = NULL,
    @QuantityAdded      INT,
    @TransactionDate    DATE = NULL,
    @Notes              VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Product WHERE ItemID = @ItemID)
    BEGIN
        RAISERROR('Product does not exist.', 16, 1);
        RETURN;
    END

    IF @EmpID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    IF @QuantityAdded <= 0
    BEGIN
        RAISERROR('QuantityAdded must be greater than zero.', 16, 1);
        RETURN;
    END

    IF @TransactionDate IS NULL
        SET @TransactionDate = CAST(GETDATE() AS DATE);

    BEGIN TRANSACTION;

    BEGIN TRY
        UPDATE Product
        SET QuantityOnHand = QuantityOnHand + @QuantityAdded
        WHERE ItemID = @ItemID;

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
            'StockIn',
            @QuantityAdded,
            @TransactionDate,
            'Restock',
            NULL,
            @Notes
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE sp_RecordTreatment
    @TagID             INT,
    @EmpID             INT,
    @ItemID            INT,
    @TreatmentType     VARCHAR(50),
    @TreatmentDate     DATE,
    @QuantityUsed      INT,
    @Notes             VARCHAR(255) = NULL,
    @NextDueDate       DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentQty INT;
    DECLARE @NewTreatmentID INT;

    IF NOT EXISTS (SELECT 1 FROM Animal WHERE TagID = @TagID)
    BEGIN
        RAISERROR('Animal does not exist.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Product WHERE ItemID = @ItemID)
    BEGIN
        RAISERROR('Product does not exist.', 16, 1);
        RETURN;
    END

    IF @TreatmentType IS NULL OR LTRIM(RTRIM(@TreatmentType)) = ''
    BEGIN
        RAISERROR('TreatmentType is required.', 16, 1);
        RETURN;
    END

    IF @QuantityUsed <= 0
    BEGIN
        RAISERROR('QuantityUsed must be greater than zero.', 16, 1);
        RETURN;
    END

    SELECT @CurrentQty = QuantityOnHand
    FROM Product
    WHERE ItemID = @ItemID;

    IF @CurrentQty < @QuantityUsed
    BEGIN
        RAISERROR('Insufficient stock available for this treatment.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    BEGIN TRY
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

        SET @NewTreatmentID = SCOPE_IDENTITY();

        UPDATE Product
        SET QuantityOnHand = QuantityOnHand - @QuantityUsed
        WHERE ItemID = @ItemID;

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

        COMMIT TRANSACTION;

        SELECT @NewTreatmentID AS NewTreatmentID;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO



CREATE OR ALTER PROCEDURE sp_UpdateAnimalStatus
    @TagID         INT,
    @EmpID         INT = NULL,
    @NewStatus     VARCHAR(20),
    @EventDate     DATE = NULL,
    @Notes         VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldStatus VARCHAR(20);

    IF NOT EXISTS (SELECT 1 FROM Animal WHERE TagID = @TagID)
    BEGIN
        RAISERROR('Animal does not exist.', 16, 1);
        RETURN;
    END

    IF @EmpID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Worker WHERE EmpID = @EmpID)
    BEGIN
        RAISERROR('Worker does not exist.', 16, 1);
        RETURN;
    END

    IF @NewStatus IS NULL OR LTRIM(RTRIM(@NewStatus)) = ''
    BEGIN
        RAISERROR('NewStatus is required.', 16, 1);
        RETURN;
    END

    IF @EventDate IS NULL
        SET @EventDate = CAST(GETDATE() AS DATE);

    SELECT @OldStatus = Status
    FROM Animal
    WHERE TagID = @TagID;

    BEGIN TRANSACTION;

    BEGIN TRY
        UPDATE Animal
        SET Status = @NewStatus
        WHERE TagID = @TagID;

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
            CONCAT('Status changed from ', @OldStatus, ' to ', @NewStatus,
                   CASE WHEN @Notes IS NOT NULL THEN CONCAT(' - ', @Notes) ELSE '' END)
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO



