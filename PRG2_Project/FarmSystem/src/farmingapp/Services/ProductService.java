package farmingapp.Services;

import farmingapp.DBConnection;
import java.sql.*;

public class ProductService {

    /* ============================================================
       METHOD: addProduct

       PURPOSE:
       Calls the SQL procedure AddProduct.

       WHY:
       Java does not insert directly into Product.
       Java sends values to SQL Server, and the procedure:
       - adds the product
       - records initial stock in InventoryTransaction
       - links the transaction to the logged-in EmpID

       RETURNS:
       NewItemID if successful
       -1 if failed
       ============================================================ */

    public int addProduct(String productName,
                          String productType,
                          int quantityOnHand,
                          String unitOfMeasure,
                          int reorderLevel,
                          String storageLocation,
                          int empID,
                          String status) {

        try (Connection con = DBConnection.getConnection()) {

            String sql = "{CALL AddProduct(?,?,?,?,?,?,?,?)}";

            try (CallableStatement cs = con.prepareCall(sql)) {

                cs.setString(1, productName);
                cs.setString(2, productType);
                cs.setInt(3, quantityOnHand);
                cs.setString(4, unitOfMeasure);
                cs.setInt(5, reorderLevel);
                cs.setString(6, storageLocation);
                cs.setInt(7, empID);
                cs.setString(8, status);

                try (ResultSet rs = cs.executeQuery()) {
                    if (rs.next()) {
                        return rs.getInt("NewItemID");
                    }
                }
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }

        return -1;
    }
    
        /* ============================================================
       METHOD: getAllProducts

       PURPOSE:
       Calls the SQL procedure GetAllProducts.

       WHY:
       Java should not run:
       SELECT * FROM Product

       Instead, Java calls this method, and this method calls
       the stored procedure in SQL Server.

       USED BY:
       ProductPanel.java
       Specifically the "View All Products" button.

       IMPORTANT:
       This method receives a Connection from the panel.
       The panel opens and closes the connection.
       This keeps connection handling clean.
       ============================================================ */

    public ResultSet getAllProducts(Connection con) throws SQLException {

        // This is the stored procedure call.
        // GetAllProducts is a procedure in SQL Server.
        String sql = "{CALL GetAllProducts}";

        // CallableStatement is used for calling stored procedures.
        CallableStatement cs = con.prepareCall(sql);

        // executeQuery() is used because GetAllProducts returns rows.
        return cs.executeQuery();
    }
    
        /* ============================================================
       METHOD: searchProducts

       PURPOSE:
       Calls the SQL procedure SearchProducts.

       WHY:
       Java should not write its own SELECT query.

       Java sends the filter values to SQL Server.
       SQL Server decides which products match.

       USED BY:
       ProductPanel.java
       Specifically the "Search Products" button.

       PARAMETERS:
       productType = optional product type filter
       status      = optional product status filter

       IMPORTANT:
       If a value is blank, Java sends NULL to SQL Server.
       In your SearchProducts procedure, NULL means:
       "ignore this filter".
       ============================================================ */

    public ResultSet searchProducts(Connection con,
                                    String productType,
                                    String status) throws SQLException {

        // This calls your SQL stored procedure SearchProducts.
        // The two ? marks are placeholders for:
        // 1. @ProductType
        // 2. @Status
        String sql = "{CALL SearchProducts(?,?)}";

        // CallableStatement is used for calling stored procedures.
        CallableStatement cs = con.prepareCall(sql);

        // First parameter: @ProductType.
        // If the user leaves it blank, send SQL NULL.
        if (productType == null || productType.trim().isEmpty()) {
            cs.setNull(1, java.sql.Types.VARCHAR);
        } else {
            cs.setString(1, productType.trim());
        }

        // Second parameter: @Status.
        // If the user selects blank/Any, send SQL NULL.
        if (status == null || status.trim().isEmpty() || status.equals("Any")) {
            cs.setNull(2, java.sql.Types.VARCHAR);
        } else {
            cs.setString(2, status.trim());
        }

        // executeQuery() is used because SearchProducts returns rows.
        return cs.executeQuery();
    }
}