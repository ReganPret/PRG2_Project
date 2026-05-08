package farmingapp.Services;

import farmingapp.DBConnection;
import java.sql.*;

public class AnimalService {

    /*
     * This method calls the SQL procedure sp_AddAnimal.
     *
     * It does not run INSERT SQL directly.
     * It sends values to the procedure.
     *
     * Returns:
     * - NewTagID if successful
     * - -1 if something failed
     */
    public int addAnimal(String animalType,
                         String breed,
                         String gender,
                         String useType,
                         String status,
                         String dateRegistered,
                         String notes) {

        try (Connection con = DBConnection.getConnection()) {

            String sql = "{CALL sp_AddAnimal(?,?,?,?,?,?,?)}";

            try (CallableStatement cs = con.prepareCall(sql)) {

                cs.setString(1, animalType);
                cs.setString(2, breed);
                cs.setString(3, gender);
                cs.setString(4, useType);
                cs.setString(5, status);

                // Date.valueOf requires yyyy-mm-dd format.
                cs.setDate(6, Date.valueOf(dateRegistered));

                cs.setString(7, notes);

                try (ResultSet rs = cs.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt("NewTagID");
                    }
                }
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }

        return -1;
    }
        /* ============================================================
       METHOD: getAllAnimals

       PURPOSE:
       This method calls the SQL procedure GetAllAnimals.

       WHY:
       Java does not run SELECT * FROM Animal directly.
       Java asks the database procedure to return the animals.

       USED BY:
       AnimalPanel.java
       Specifically the "View All Animals" button.

       RETURNS:
       A ResultSet containing all animal records.
       ============================================================ */

    public ResultSet getAllAnimals(Connection con) throws SQLException {

        // This is the stored procedure call.
        // It calls the SQL procedure named GetAllAnimals.
        String sql = "{CALL GetAllAnimals}";

        // CallableStatement is used when Java calls a stored procedure.
        CallableStatement cs = con.prepareCall(sql);

        // executeQuery() is used because this procedure returns rows.
        return cs.executeQuery();
    }
    
    
        /* ============================================================
       METHOD: searchAnimals

       PURPOSE:
       This method calls the SQL procedure SearchAnimals.

       WHY:
       It allows Java to filter animals without writing raw SELECT SQL.

       USED BY:
       AnimalPanel.java
       Specifically the "Search Animals" button.

       PARAMETERS:
       animalType = optional animal type filter
       status     = optional status filter
       gender     = optional gender filter

       IMPORTANT:
       Empty values are converted to NULL.
       In SQL, NULL means "ignore this filter".
       ============================================================ */

    public ResultSet searchAnimals(Connection con,
                                   String animalType,
                                   String status,
                                   String gender) throws SQLException {

        // This calls the stored procedure SearchAnimals.
        String sql = "{CALL SearchAnimals(?,?,?)}";

        // CallableStatement is used for stored procedures.
        CallableStatement cs = con.prepareCall(sql);

        // If animalType is empty, send NULL to SQL.
        // SQL then ignores this filter.
        if (animalType == null || animalType.trim().isEmpty()) {
            cs.setNull(1, java.sql.Types.VARCHAR);
        } else {
            cs.setString(1, animalType.trim());
        }

        // If status is empty, send NULL to SQL.
        if (status == null || status.trim().isEmpty()) {
            cs.setNull(2, java.sql.Types.VARCHAR);
        } else {
            cs.setString(2, status.trim());
        }

        // If gender is empty or "Any", send NULL to SQL.
        if (gender == null || gender.trim().isEmpty() || gender.equals("Any")) {
            cs.setNull(3, java.sql.Types.CHAR);
        } else {
            cs.setString(3, gender.trim());
        }

        // executeQuery is used because SearchAnimals returns rows.
        return cs.executeQuery();
    }
    
        /* ============================================================
       METHOD: updateAnimalStatus

       PURPOSE:
       This method calls the SQL procedure UpdateAnimalStatus.

       WHY:
       Java does not update the Animal table directly.
       Java sends values to the stored procedure, and SQL handles:
       - checking the animal exists
       - updating the animal status
       - adding an AnimalEvent history record

       USED BY:
       AnimalPanel.java
       Specifically the "Update Status" button.

       RETURNS:
       true  = status update succeeded
       false = something failed
       ============================================================ */

    public boolean updateAnimalStatus(int tagID,
                                      Integer empID,
                                      String newStatus,
                                      String eventDate,
                                      String notes) {

        try (Connection con = DBConnection.getConnection()) {

            // This calls the stored procedure UpdateAnimalStatus.
            String sql = "{CALL UpdateAnimalStatus(?,?,?,?,?)}";

            try (CallableStatement cs = con.prepareCall(sql)) {

                // First ? = @TagID
                cs.setInt(1, tagID);

                // Second ? = @EmpID
                // EmpID is optional in the SQL procedure.
                // If empID is null, send SQL NULL.
                if (empID == null) {
                    cs.setNull(2, java.sql.Types.INTEGER);
                } else {
                    cs.setInt(2, empID);
                }

                // Third ? = @NewStatus
                cs.setString(3, newStatus);

                // Fourth ? = @EventDate
                // SQL expects a DATE.
                // Date.valueOf requires yyyy-mm-dd format.
                cs.setDate(4, Date.valueOf(eventDate));

                // Fifth ? = @Notes
                cs.setString(5, notes);

                // execute() is used because this procedure updates data
                // and does not need to return a ResultSet.
                cs.execute();

                return true;
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            return false;
        }
    }
}