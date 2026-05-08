package farmingapp;

// Imports the Java SQL library.
// This gives us Connection, CallableStatement, ResultSet, Date, SQLException, etc.
import java.sql.*;

public class FarmService {

    // This method is used by the Java GUI when the user wants to add/register an animal.
    //
    // It returns an int:
    // - if successful, it returns the new animal TagID from SQL Server
    // - if something fails, it returns -1
    public int addAnimal(String type, String breed, String gender,
                         String useType, String status,
                         String date, String notes) {

        // This opens a connection to the database.
        // DBConnection.getConnection() is the method from your DBConnection class.
        //
        // try-with-resources means:
        // Java will automatically close the database connection when done.
        try (Connection con = DBConnection.getConnection()) {

            // This is the stored procedure call.
            // CALL sp_AddAnimal means Java is calling your SQL procedure.
            //
            // The question marks (?) are placeholders.
            // Each ? will be filled below using cs.setString(), cs.setDate(), etc.
            String sql = "{CALL sp_AddAnimal(?,?,?,?,?,?,?)}";

            // CallableStatement is a Java SQL object used for calling stored procedures.
            //
            // con.prepareCall(sql) prepares the procedure call before executing it.
            try (CallableStatement cs = con.prepareCall(sql)) {

                // These lines fill in the ? placeholders in order.

                // First ? = @AnimalType
                cs.setString(1, type);

                // Second ? = @Breed
                cs.setString(2, breed);

                // Third ? = @Gender
                cs.setString(3, gender);

                // Fourth ? = @UseType
                cs.setString(4, useType);

                // Fifth ? = @Status
                cs.setString(5, status);

                // Sixth ? = @DateRegistered
                //
                // Date.valueOf(date) converts a String into a SQL Date.
                // The string must be in this format:
                // yyyy-mm-dd
                //
                // Example:
                // "2026-05-07"
                cs.setDate(6, Date.valueOf(date));

                // Seventh ? = @Notes
                cs.setString(7, notes);

                // executeQuery() is used because sp_AddAnimal returns a SELECT:
                // SELECT @NewTagID AS NewTagID;
                //
                // ResultSet stores the returned row from the procedure.
                try (ResultSet rs = cs.executeQuery()) {

                    // rs.next() moves to the first row of the result.
                    // If it returns true, SQL returned something.
                    if (rs.next()) {

                        // Get the returned NewTagID column from SQL Server.
                        // This is the new animal ID.
                        return rs.getInt("NewTagID");
                    }
                }
            }

        } catch (Exception e) {
            // Prints full technical error in NetBeans output.
            // Useful for debugging database/procedure errors.
            e.printStackTrace();
        }

        // If anything failed, or no NewTagID was returned, return -1.
        // The GUI can check for -1 and show "animal not added".
        return -1;
    }
}