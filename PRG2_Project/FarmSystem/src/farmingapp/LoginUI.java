package farmingapp;

// Swing components: JFrame, JTextField, JButton, JOptionPane, etc.
import farmingapp.UI_Elements.FarmDashboard;
import javax.swing.*;

// Basic GUI layout/positioning classes.
import java.awt.*;

// SQL classes used for database connection, procedure call, and result reading.
import java.sql.*;

public class LoginUI extends JFrame {

    JTextField txtUser; // Text box where the user types the username.
    JPasswordField txtPass; // Password field hides what the user types.
    JButton btnLogin; // Button the user clicks to log in.

    public LoginUI() {

        setTitle("Farm Login");     // Window title.
        setSize(400, 300);         // Window size: width 400, height 300.
        setLocationRelativeTo(null);  // Centers the window on the screen by having it as null.
        setDefaultCloseOperation(EXIT_ON_CLOSE);  // Closes the whole program when this window is closed.

        setLayout(null); // null layout means we manually place every component using setBounds().

        JLabel userLabel = new JLabel("Username:"); 
        userLabel.setBounds(50, 50, 100, 25); //// x-position from left, y-position from top, width, height

        txtUser = new JTextField(); // Creating new object (Like Scanner)
        txtUser.setBounds(150, 50, 150, 25);
      //txtUser.setBackground(Color.red);  //Can adjust color with this one

        JLabel passLabel = new JLabel("Password:");
        passLabel.setBounds(50, 100, 100, 25);

        txtPass = new JPasswordField();
        txtPass.setBounds(150, 100, 150, 25);
      //txtPass.setBackground(Color.red);  //Can adjust color with this one
        
        btnLogin = new JButton("Login");
        btnLogin.setBounds(150, 150, 100, 30);
      //btnLogin.setBackground(Color.red); //Can adjust color with this one
  
        //These 5 lines literally create the boxes and lables we defined above
        add(userLabel);
        add(txtUser);
        add(passLabel);
        add(txtPass);
        add(btnLogin);

        // When the login button is clicked, run the login() method.
        // e is the button-click event object.
        btnLogin.addActionListener(e -> login()); //Login is a method written right below
    }

    private void login() { //Private because it is only used in this class

        String username = txtUser.getText();         // Read username from the text field.

        // Read password from the password field.
        // getPassword() returns char[], so we convert it to String //Comes from the JpasswordField Creation
        String password = new String(txtPass.getPassword());

        // try-with-resources automatically closes the database connection after use.
        try (Connection con = DBConnection.getConnection()) {

            // This calls stored procedure instead of raw SELECT SQL.
            CallableStatement cs = con.prepareCall("{CALL GetUserForLogin(?)}");

            // Send username to the procedure.
            cs.setString(1, username);

            // Execute procedure and receive results.
            ResultSet rs = cs.executeQuery(); //Stores rows gotten by calling proc

            // If the procedure returned a row, the username exists and account is active.
            if (rs.next()) {

                // Get stored password from database.
                // For now we are storing plain text in PasswordHash for testing.
                String storedPassword = rs.getString("PasswordHash"); //PaswordHash is the column in which the password is stored

                // Compare typed password with stored password.
                if (password.equals(storedPassword)) {

                    // Login successful.
                    JOptionPane.showMessageDialog(this, "Login Success"); //"this" reffers to the current window we are in already

                    new FarmDashboard().setVisible(true);// Open dashboard. From Class of same name

                    // Close login window.
                    this.dispose(); //Dispose is an imported method

                } else {
                    // Username exists, but password was wrong.
                    JOptionPane.showMessageDialog(this, "Invalid Login: Incorrect Password");
                }

            } else {
                // Procedure returned no user.
                // Either username does not exist, account is inactive, or worker is inactive.
                JOptionPane.showMessageDialog(this, "Invalid Login: User does not exist");
            }

        } catch (Exception ex) {
            // Prints error details in NetBeans output.
            ex.printStackTrace();

            // Shows a simpler message to the user.
            JOptionPane.showMessageDialog(this, "Database error: " + ex.getMessage());
        }
    }

    public static void main(String[] args) {

        // Starts the login screen.
        new LoginUI().setVisible(true);
    }
}