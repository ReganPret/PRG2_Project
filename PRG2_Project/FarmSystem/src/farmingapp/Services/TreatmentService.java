package farmingapp.Services;

import farmingapp.DBConnection;
import java.sql.*;

public class TreatmentService {

    /* ============================================================
       METHOD: recordTreatment

       PURPOSE:
       Calls RecordTreatment procedure.

       A treatment links:
       - Animal (TagID)
       - Worker (EmpID)
       - Product (ItemID)

       RETURNS:
       NewTreatmentID if successful
       -1 if failed
       ============================================================ */

    public int recordTreatment(int tagID,
                               int empID,
                               int itemID,
                               String treatmentType,
                               String treatmentDate,
                               String notes) {

        try (Connection con = DBConnection.getConnection()) {

            String sql = "{CALL RecordTreatment(?,?,?,?,?,?)}";

            try (CallableStatement cs = con.prepareCall(sql)) {

                cs.setInt(1, tagID);
                cs.setInt(2, empID);
                cs.setInt(3, itemID);
                cs.setString(4, treatmentType);

                if (treatmentDate == null || treatmentDate.trim().isEmpty()) {
                    cs.setNull(5, java.sql.Types.DATE);
                } else {
                    cs.setDate(5, Date.valueOf(treatmentDate.trim()));
                }

                cs.setString(6, notes);

                try (ResultSet rs = cs.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt("NewTreatmentID");
                    }
                }
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }

        return -1;
    }


    /* ============================================================
       METHOD: getAllTreatments

       PURPOSE:
       Calls GetAllTreatments procedure.

       Used to display treatments in JTable.
       ============================================================ */

    public ResultSet getAllTreatments(Connection con) throws SQLException {

        String sql = "{CALL GetAllTreatments}";

        CallableStatement cs = con.prepareCall(sql);

        return cs.executeQuery();
    }
}