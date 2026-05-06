package farmingapp;

import javax.swing.*;
import java.awt.*;

public class LoginUI extends JFrame {

    JTextField txtUser;
    JPasswordField txtPass;
    JButton btnLogin;

    public LoginUI() {

        setTitle("Farm Login");
        setSize(400, 300);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLayout(null);

        JLabel userLabel = new JLabel("Username:");
        userLabel.setBounds(50, 50, 100, 25);

        txtUser = new JTextField();
        txtUser.setBounds(150, 50, 150, 25);

        JLabel passLabel = new JLabel("Password:");
        passLabel.setBounds(50, 100, 100, 25);

        txtPass = new JPasswordField();
        txtPass.setBounds(150, 100, 150, 25);

        btnLogin = new JButton("Login");
        btnLogin.setBounds(150, 150, 100, 30);

        add(userLabel);
        add(txtUser);
        add(passLabel);
        add(txtPass);
        add(btnLogin);

        btnLogin.addActionListener(e -> login());
    }

    private void login() {
        try {
            var con = DBConnection.getConnection();

            String sql = "SELECT * FROM UserAccount WHERE Username=? AND PasswordHash=?";
            var pst = con.prepareStatement(sql);

            pst.setString(1, txtUser.getText());
            pst.setString(2, new String(txtPass.getPassword()));

            var rs = pst.executeQuery();

            if (rs.next()) {
                JOptionPane.showMessageDialog(this, "Login Success");

                new FarmDashboard().setVisible(true);
                this.dispose();
            } else {
                JOptionPane.showMessageDialog(this, "Invalid Login");
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    public static void main(String[] args) {
        new LoginUI().setVisible(true);
    }
}