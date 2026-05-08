package farmingapp;

import java.sql.Connection; // Connection is the Java object that represents an open connection to the database.
import java.sql.DriverManager; // DriverManager is used to open a JDBC connection using the URL, username, and password.
import java.sql.SQLException; // SQLException is the type of error Java throws when something DB related Dies.

public class DBConnection {
    private static final String URL =
        "jdbc:sqlserver://localhost:1433;databaseName=farmForm;encrypt=true;trustServerCertificate=true;";  // - use encryption - trust the local SQL Server certificate
    
    private static final String USER = "farmapp_user"; // DB user loging in. NOT APP LOGIN, this only CONNECTS TO SERVER
    private static final String PASSWORD = "Admin55";  // Password for the SQL Server database login above.

    
    // This method opens and returns a database connection.
    // Other classes call DBConnection.getConnection() when they need to talk to the database.
    // "throws SQLException": connection fails, error not handled here. Class that called method will handle with try/catch. MAIN CLASS
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}