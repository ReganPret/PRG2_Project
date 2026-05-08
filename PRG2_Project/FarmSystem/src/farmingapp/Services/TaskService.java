package farmingapp.Services;

import farmingapp.DBConnection;
import java.sql.*;

public class TaskService {

    /* ============================================================
       METHOD: assignTask

       PURPOSE:
       Calls the SQL procedure AssignTask.

       This creates a task for a worker.

       TagID is optional:
       - if the task is linked to an animal, send the animal TagID
       - if not linked to an animal, send NULL to SQL

       RETURNS:
       NewTaskID if successful
       -1 if failed
       ============================================================ */

    public int assignTask(int empID,
                          Integer tagID,
                          String taskDescription,
                          String taskType,
                          String dateAssigned,
                          String notes) {

        try (Connection con = DBConnection.getConnection()) {

            String sql = "{CALL AssignTask(?,?,?,?,?,?)}";

            try (CallableStatement cs = con.prepareCall(sql)) {

                cs.setInt(1, empID);

                if (tagID == null) {
                    cs.setNull(2, java.sql.Types.INTEGER);
                } else {
                    cs.setInt(2, tagID);
                }

                cs.setString(3, taskDescription);
                cs.setString(4, taskType);

                if (dateAssigned == null || dateAssigned.trim().isEmpty()) {
                    cs.setNull(5, java.sql.Types.DATE);
                } else {
                    cs.setDate(5, Date.valueOf(dateAssigned.trim()));
                }

                cs.setString(6, notes);

                try (ResultSet rs = cs.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt("NewTaskID");
                    }
                }
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }

        return -1;
    }


    /* ============================================================
       METHOD: getAllTasks

       PURPOSE:
       Calls the SQL procedure GetAllTasks.

       Used to display all tasks in a JTable.
       ============================================================ */

    public ResultSet getAllTasks(Connection con) throws SQLException {

        String sql = "{CALL GetAllTasks}";

        CallableStatement cs = con.prepareCall(sql);

        return cs.executeQuery();
    }


    /* ============================================================
       METHOD: completeTask

       PURPOSE:
       Calls the SQL procedure CompleteTask.

       This marks a task as completed.

       RETURNS:
       true if successful
       false if failed
       ============================================================ */

    public boolean completeTask(int taskID,
                                String dateCompleted,
                                String notes) {

        try (Connection con = DBConnection.getConnection()) {

            String sql = "{CALL CompleteTask(?,?,?)}";

            try (CallableStatement cs = con.prepareCall(sql)) {

                cs.setInt(1, taskID);

                if (dateCompleted == null || dateCompleted.trim().isEmpty()) {
                    cs.setNull(2, java.sql.Types.DATE);
                } else {
                    cs.setDate(2, Date.valueOf(dateCompleted.trim()));
                }

                cs.setString(3, notes);

                cs.execute();

                return true;
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            return false;
        }
    }
}