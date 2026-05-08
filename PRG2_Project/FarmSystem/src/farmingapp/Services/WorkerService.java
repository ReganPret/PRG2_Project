package farmingapp.Services;

import farmingapp.DBConnection;
import java.sql.*;

public class WorkerService {

    /* ============================================================
       METHOD: addWorker

       PURPOSE:
       Calls the SQL procedure AddWorker.

       Java does not insert directly into Worker.
       The database procedure handles the insert.

       RETURNS:
       NewEmpID if successful
       -1 if failed
       ============================================================ */

    public int addWorker(String firstName,
                         String lastName,
                         String position,
                         String phoneNumber,
                         String status,
                         String hireDate) {

        try (Connection con = DBConnection.getConnection()) {

            String sql = "{CALL AddWorker(?,?,?,?,?,?)}";

            try (CallableStatement cs = con.prepareCall(sql)) {

                cs.setString(1, firstName);
                cs.setString(2, lastName);
                cs.setString(3, position);
                cs.setString(4, phoneNumber);
                cs.setString(5, status);

                // If hireDate is blank, send NULL to SQL.
                // The AddWorker procedure will then use today's date.
                if (hireDate == null || hireDate.trim().isEmpty()) {
                    cs.setNull(6, java.sql.Types.DATE);
                } else {
                    cs.setDate(6, Date.valueOf(hireDate.trim()));
                }

                try (ResultSet rs = cs.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt("NewEmpID");
                    }
                }
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }

        return -1;
    }


    /* ============================================================
       METHOD: getAllWorkers

       PURPOSE:
       Calls the SQL procedure GetAllWorkers.

       Used to display all workers in a JTable.
       ============================================================ */

    public ResultSet getAllWorkers(Connection con) throws SQLException {

        String sql = "{CALL GetAllWorkers}";

        CallableStatement cs = con.prepareCall(sql);

        return cs.executeQuery();
    }


    /* ============================================================
       METHOD: updateWorkerDetails

       PURPOSE:
       Calls the SQL procedure UpdateWorkerDetails.

       Used when editing worker information.
       ============================================================ */

    public boolean updateWorkerDetails(int empID,
                                       String firstName,
                                       String lastName,
                                       String position,
                                       String phoneNumber) {

        try (Connection con = DBConnection.getConnection()) {

            String sql = "{CALL UpdateWorkerDetails(?,?,?,?,?)}";

            try (CallableStatement cs = con.prepareCall(sql)) {

                cs.setInt(1, empID);
                cs.setString(2, firstName);
                cs.setString(3, lastName);
                cs.setString(4, position);
                cs.setString(5, phoneNumber);

                cs.execute();

                return true;
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            return false;
        }
    }


    /* ============================================================
       METHOD: deactivateWorker

       PURPOSE:
       Calls the SQL procedure DeactivateWorker.

       This does not delete the worker.
       It marks the worker as Inactive.
       ============================================================ */

    public boolean deactivateWorker(int empID) {

        try (Connection con = DBConnection.getConnection()) {

            String sql = "{CALL DeactivateWorker(?)}";

            try (CallableStatement cs = con.prepareCall(sql)) {

                cs.setInt(1, empID);

                cs.execute();

                return true;
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            return false;
        }
    }
}