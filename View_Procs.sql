/* ============================================================
   PROCEDURE: ViewAllUserAccounts

   Shows user accounts together with the worker details.

   This is better than only showing UserAccount,
   because it tells you who the account belongs to.
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewAllUserAccounts
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        UA.UserID,
        UA.EmpID,
        W.FirstName,
        W.LastName,
        W.Position,
        UA.Username,
        UA.Role,
        UA.AccountStatus,
        UA.LastLogin
    FROM UserAccount UA
    INNER JOIN Worker W ON UA.EmpID = W.EmpID
    ORDER BY UA.UserID DESC;
END;
GO

/* ============================================================
   PROCEDURE: ViewAllWorkers

   PURPOSE:
   Returns all workers.

   Java use:
   - Dropdowns
   - Worker management screen
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewAllWorkers
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM Worker
    ORDER BY EmpID DESC;
END;
GO

/* ============================================================
   PROCEDURE: ViewAllAnimals
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewAllAnimals
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TagID,
        AnimalType,
        Breed,
        Gender,
        UseType,
        Status,
        DateRegistered,
        Notes
    FROM Animal
    ORDER BY TagID DESC;
END;
GO


/* ============================================================
   PROCEDURE: ViewAllProducts
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewAllProducts
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ItemID,
        ProductName,
        ProductType,
        QuantityOnHand,
        UnitOfMeasure,
        ReorderLevel,
        StorageLocation,
        Status
    FROM Product
    ORDER BY ItemID DESC;
END;
GO


/* ============================================================
   PROCEDURE: ViewAllTreatments

   Shows treatments with animal, worker, and product details.
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewAllTreatments
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        T.TreatmentID,
        T.TagID,
        A.AnimalType,
        A.Breed,
        T.EmpID,
        W.FirstName + ' ' + W.LastName AS WorkerName,
        T.ItemID,
        P.ProductName,
        T.TreatmentType,
        T.TreatmentDate,
        T.QuantityUsed,
        T.NextDueDate,
        T.Notes
    FROM Treatment T
    INNER JOIN Animal A ON T.TagID = A.TagID
    INNER JOIN Worker W ON T.EmpID = W.EmpID
    INNER JOIN Product P ON T.ItemID = P.ItemID
    ORDER BY T.TreatmentID DESC;
END;
GO


/* ============================================================
   PROCEDURE: ViewAllTasks

   Shows tasks with worker and optional animal details.
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewAllTasks
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        T.TaskID,
        T.EmpID,
        W.FirstName + ' ' + W.LastName AS WorkerName,
        T.TagID,
        A.AnimalType,
        A.Breed,
        T.TaskDescription,
        T.TaskType,
        T.Status,
        T.DateAssigned,
        T.DateCompleted,
        T.Notes
    FROM Task T
    INNER JOIN Worker W ON T.EmpID = W.EmpID
    LEFT JOIN Animal A ON T.TagID = A.TagID
    ORDER BY T.TaskID DESC;
END;
GO


/* ============================================================
   PROCEDURE: ViewAllAnimalEvents

   Shows animal event/history records with animal and worker info.
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewAllAnimalEvents
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        AE.EventID,
        AE.TagID,
        A.AnimalType,
        A.Breed,
        AE.EmpID,
        W.FirstName + ' ' + W.LastName AS WorkerName,
        AE.EventType,
        AE.EventDate,
        AE.Notes
    FROM AnimalEvent AE
    INNER JOIN Animal A ON AE.TagID = A.TagID
    LEFT JOIN Worker W ON AE.EmpID = W.EmpID
    ORDER BY AE.EventID DESC;
END;
GO


/* ============================================================
   PROCEDURE: ViewAllInventoryTransactions

   Shows stock movement with product and worker info.
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewAllInventoryTransactions
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        IT.TransactionID,
        IT.ItemID,
        P.ProductName,
        P.ProductType,
        IT.EmpID,
        W.FirstName + ' ' + W.LastName AS WorkerName,
        IT.TransactionType,
        IT.QuantityChanged,
        IT.TransactionDate,
        IT.ReferenceType,
        IT.ReferenceID,
        IT.Notes
    FROM InventoryTransaction IT
    INNER JOIN Product P ON IT.ItemID = P.ItemID
    LEFT JOIN Worker W ON IT.EmpID = W.EmpID
    ORDER BY IT.TransactionID DESC;
END;
GO


/* ============================================================
   PROCEDURE: ViewEverythingRaw

   PURPOSE:
   Shows raw data from every table.

   Each SELECT returns a separate result set.

   This is useful in SSMS for testing.
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewEverythingRaw
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 'Worker' AS TableName;
    SELECT EmpID, FirstName, LastName, Position, PhoneNumber, Status, HireDate
    FROM Worker
    ORDER BY EmpID DESC;

    SELECT 'UserAccount' AS TableName;
    SELECT UserID, EmpID, Username, Role, AccountStatus, LastLogin
    FROM UserAccount
    ORDER BY UserID DESC;

    SELECT 'Animal' AS TableName;
    SELECT TagID, AnimalType, Breed, Gender, UseType, Status, DateRegistered, Notes
    FROM Animal
    ORDER BY TagID DESC;

    SELECT 'Product' AS TableName;
    SELECT ItemID, ProductName, ProductType, QuantityOnHand, UnitOfMeasure, ReorderLevel, StorageLocation, Status
    FROM Product
    ORDER BY ItemID DESC;

    SELECT 'Treatment' AS TableName;
    SELECT TreatmentID, TagID, EmpID, ItemID, TreatmentType, TreatmentDate, QuantityUsed, Notes, NextDueDate
    FROM Treatment
    ORDER BY TreatmentID DESC;

    SELECT 'Task' AS TableName;
    SELECT TaskID, EmpID, TagID, TaskDescription, TaskType, Status, DateAssigned, DateCompleted, Notes
    FROM Task
    ORDER BY TaskID DESC;

    SELECT 'AnimalEvent' AS TableName;
    SELECT EventID, TagID, EmpID, EventType, EventDate, Notes
    FROM AnimalEvent
    ORDER BY EventID DESC;

    SELECT 'InventoryTransaction' AS TableName;
    SELECT TransactionID, ItemID, EmpID, TransactionType, QuantityChanged, TransactionDate, ReferenceType, ReferenceID, Notes
    FROM InventoryTransaction
    ORDER BY TransactionID DESC;
END;
GO


/* ============================================================
   PROCEDURE: ViewEverythingJoined

   PURPOSE:
   Shows the most useful joined views.

   This helps you understand what the procedures created.
   ============================================================ */

CREATE OR ALTER PROCEDURE ViewEverythingJoined
AS
BEGIN
    SET NOCOUNT ON;

    EXEC ViewAllUserAccounts;
    EXEC ViewAllTreatments;
    EXEC ViewAllTasks;
    EXEC ViewAllAnimalEvents;
    EXEC ViewAllInventoryTransactions;
END;
GO