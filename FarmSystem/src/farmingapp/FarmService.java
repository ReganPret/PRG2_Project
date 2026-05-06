package farmingapp;

import java.sql.*;

public class FarmService {

    Connection con = DBConnection.getConnection();

    // Example: Add Animal
    public int addAnimal(String type, String breed, String gender,
                         String useType, String status,
                         String date, String notes) {

        try {
            String sql = "{CALL sp_AddAnimal(?,?,?,?,?,?,?)}";
            CallableStatement cs = con.prepareCall(sql);

            cs.setString(1, type);
            cs.setString(2, breed);
            cs.setString(3, gender);
            cs.setString(4, useType);
            cs.setString(5, status);
            cs.setDate(6, Date.valueOf(date));
            cs.setString(7, notes);

            ResultSet rs = cs.executeQuery();

            if (rs.next()) {
                return rs.getInt("NewTagID");
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return -1;
    }
}