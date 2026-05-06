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