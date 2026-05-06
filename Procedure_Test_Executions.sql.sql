/* ============================================================
   PROCEDURE TEST EXECUTIONS

   This file is NOT for creating tables.
   This file is NOT for creating procedures.

   This file is only used to TEST the procedures that already exist.

   Later, Java will do the same thing as this file:
   Java will call these stored procedures and pass values into them.

   For example:
   - Java form: Add Animal
   - User types animal details
   - Java sends those details to sp_AddAnimal
   - SQL Server inserts the animal into the database

   IMPORTANT:
   The ID numbers used below, like EmpID = 1 or TagID = 1,
   must exist in your database.
   If they do not exist, the procedure will show an error.
   ============================================================ */


/* ============================================================
   1. ADD A WORKER

   This creates a staff member / farm worker.

   The worker can later:
   - be assigned tasks
   - treat animals
   - use stock
   - restock products

   Java screen example:
   "Add Worker" form
   ============================================================ */

EXEC AddWorker
    @FirstName = 'Petrus',
    @LastName = 'Nambahu',
    @Position = 'Farm Worker',
    @PhoneNumber = '0811234567';
GO


/* ============================================================
   2. CREATE A USER ACCOUNT

   This creates a login account for an existing worker.

   @EmpID = 1 means:
   "Create this login for the worker whose EmpID is 1."

   The password should NOT be stored as plain text.
   For now we are using a fake value:
   'temporary_hash_from_java_later'

   Later, Java should hash the password before sending it
   to the database.

   Java screen example:
   "Create Login Account" form
   ============================================================ */

EXEC CreateUserAccount
    @EmpID = 1,
    @Username = 'petrus',
    @PasswordHash = 'temporary_hash_from_java_later',
    @Role = 'Worker';
GO


/* ============================================================
   3. ADD AN ANIMAL

   This registers a new animal on the farm.

   The database will:
   - add the animal to the Animal table
   - automatically create an AnimalEvent saying it was registered
   - return the new TagID

   Java screen example:
   "Register Animal" form
   ============================================================ */

EXEC sp_AddAnimal
    @AnimalType = 'Cattle',
    @Breed = 'Brahman',
    @Gender = 'F',
    @UseType = 'Milk',
    @Status = 'Healthy',
    @DateRegistered = '2026-04-30',
    @Notes = 'First test animal added';
GO


/* ============================================================
   4. ADD A PRODUCT

   This adds stock items to the store room.

   Examples:
   - feed
   - vaccine
   - medicine
   - tools

   If QuantityOnHand is more than 0, the procedure also logs
   the opening stock in InventoryTransaction.

   Java screen example:
   "Add Product" form
   ============================================================ */

EXEC AddProduct
    @ProductName = 'Cattle Feed',
    @ProductType = 'Feed',
    @QuantityOnHand = 50,
    @UnitOfMeasure = 'Bags',
    @ReorderLevel = 10,
    @StorageLocation = 'Main Store',
    @Status = 'Active';
GO


/* ============================================================
   5. RESTOCK A PRODUCT

   This is used when the farmer buys more stock.

   @ItemID = 1 means:
   "Restock the product whose ItemID is 1."

   The database will:
   - increase QuantityOnHand in Product
   - insert a StockIn record in InventoryTransaction

   Java screen example:
   "Restock Product" form
   ============================================================ */

EXEC RestockProduct
    @ItemID = 1,
    @EmpID = 1,
    @QuantityAdded = 20,
    @TransactionDate = '2026-04-30',
    @Notes = 'Bought more cattle feed';
GO


/* ============================================================
   6. ASSIGN A TASK

   This gives work to a farm worker.

   @EmpID = 1 means:
   "Give this task to worker number 1."

   @TagID = 1 means:
   "This task is linked to animal number 1."

   If the task is not linked to an animal, @TagID can be NULL.

   Java screen example:
   "Assign Task" form
   ============================================================ */

EXEC AssignTask
    @EmpID = 1,
    @TagID = 1,
    @TaskDescription = 'Check animal health and feeding',
    @TaskType = 'Animal Check',
    @Notes = 'Morning inspection';
GO


/* ============================================================
   7. COMPLETE A TASK

   This marks a task as completed.

   @TaskID = 1 means:
   "Complete the task whose TaskID is 1."

   The database will:
   - change the task status to Completed
   - set the completed date
   - save the notes

   Java screen example:
   "Complete Task" button
   ============================================================ */

EXEC CompleteTask
    @TaskID = 1,
    @Notes = 'Animal checked. No issues found.';
GO


/* ============================================================
   8. USE A PRODUCT

   This is for normal stock usage that is NOT a medical treatment.

   Example:
   - feeding animals
   - using cleaning supplies
   - using tools or other farm stock

   The database will:
   - reduce QuantityOnHand in Product
   - add a StockOut record in InventoryTransaction

   Java screen example:
   "Use Stock" form
   ============================================================ */

EXEC UseProduct
    @ItemID = 1,
    @EmpID = 1,
    @QuantityUsed = 2,
    @ReferenceType = 'Feeding',
    @Notes = 'Used feed for morning feeding';
GO


/* ============================================================
   9. RECORD A TREATMENT

   This records medical treatment for an animal.

   Example:
   - vaccination
   - medicine
   - deworming

   The database will:
   - insert a record into Treatment
   - reduce the product quantity
   - insert a StockOut record
   - insert an AnimalEvent record

   This means one procedure handles many database actions.
   Java does not need to do all these steps separately.

   Java screen example:
   "Record Treatment" form
   ============================================================ */

EXEC RecordTreatment
    @TagID = 1,
    @EmpID = 1,
    @ItemID = 1,
    @TreatmentType = 'Vaccination',
    @TreatmentDate = '2026-04-30',
    @QuantityUsed = 1,
    @Notes = 'Routine vaccination',
    @NextDueDate = '2026-10-30';
GO


/* ============================================================
   10. UPDATE ANIMAL STATUS

   This changes an animal's status.

   Examples of statuses:
   - Healthy
   - Sick
   - Sold
   - Died
   - Lost
   - Stolen

   The database will:
   - update the Animal table
   - add an AnimalEvent showing the status change

   Java screen example:
   "Update Animal Status" form
   ============================================================ */

EXEC UpdateAnimalStatus
    @TagID = 1,
    @EmpID = 1,
    @NewStatus = 'Healthy',
    @EventDate = '2026-04-30',
    @Notes = 'Status confirmed after inspection';
GO

--EXEC ShowLatest10FromAllTables;

/*EXEC DeleteAllTestData
    @Confirm = 'YES_DELETE_ALL';
    */