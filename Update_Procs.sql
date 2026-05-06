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