package farmingapp.UI_Elements;

import farmingapp.DBConnection;
import farmingapp.Services.WorkerService;
import javax.swing.*;
import java.awt.*;
import java.sql.*;

public class WorkerPanel extends JPanel {

    // WorkerService contains the Java methods that call worker procedures.
    private WorkerService workerService = new WorkerService();

    // This panel changes between worker menu, forms, and tables.
    private JPanel contentPanel;

    public WorkerPanel() {

        setLayout(new BorderLayout());

        JLabel heading = new JLabel("👨‍🌾 Worker Module", JLabel.CENTER);
        heading.setFont(new Font("Arial", Font.BOLD, 22));
        add(heading, BorderLayout.NORTH);

        contentPanel = new JPanel();
        contentPanel.setLayout(null);
        add(contentPanel, BorderLayout.CENTER);

        showWorkerMenu();
    }


    /* ============================================================
       METHOD: showWorkerMenu

       PURPOSE:
       Shows the worker module buttons.

       Each button opens a different worker action screen.
       ============================================================ */

    private void showWorkerMenu() {

        contentPanel.removeAll();

        JButton btnAddWorker = new JButton("Add Worker");
        btnAddWorker.setBounds(40, 40, 180, 35);
        contentPanel.add(btnAddWorker);

        JButton btnViewWorkers = new JButton("View All Workers");
        btnViewWorkers.setBounds(40, 90, 180, 35);
        contentPanel.add(btnViewWorkers);

        JButton btnUpdateWorker = new JButton("Update Worker");
        btnUpdateWorker.setBounds(40, 140, 180, 35);
        contentPanel.add(btnUpdateWorker);

        JButton btnDeactivateWorker = new JButton("Deactivate Worker");
        btnDeactivateWorker.setBounds(40, 190, 180, 35);
        contentPanel.add(btnDeactivateWorker);

        btnAddWorker.addActionListener(e -> showAddWorkerForm());
        btnViewWorkers.addActionListener(e -> showAllWorkersTable());
        btnUpdateWorker.addActionListener(e -> showUpdateWorkerForm());
        btnDeactivateWorker.addActionListener(e -> showDeactivateWorkerForm());

        contentPanel.revalidate();
        contentPanel.repaint();
    }


    /* ============================================================
       METHOD: showAddWorkerForm

       PURPOSE:
       Shows the form for adding a worker.

       FLOW:
       User enters worker details.
       OK button calls WorkerService.addWorker().
       WorkerService calls SQL procedure AddWorker.
       ============================================================ */

    private void showAddWorkerForm() {

        contentPanel.removeAll();

        JLabel lblFirstName = new JLabel("First Name:");
        lblFirstName.setBounds(40, 30, 140, 25);
        contentPanel.add(lblFirstName);

        JTextField txtFirstName = new JTextField();
        txtFirstName.setBounds(190, 30, 220, 25);
        contentPanel.add(txtFirstName);

        JLabel lblLastName = new JLabel("Last Name:");
        lblLastName.setBounds(40, 70, 140, 25);
        contentPanel.add(lblLastName);

        JTextField txtLastName = new JTextField();
        txtLastName.setBounds(190, 70, 220, 25);
        contentPanel.add(txtLastName);

        JLabel lblPosition = new JLabel("Position:");
        lblPosition.setBounds(40, 110, 140, 25);
        contentPanel.add(lblPosition);

        JTextField txtPosition = new JTextField();
        txtPosition.setBounds(190, 110, 220, 25);
        contentPanel.add(txtPosition);

        JLabel lblPhone = new JLabel("Phone Number:");
        lblPhone.setBounds(40, 150, 140, 25);
        contentPanel.add(lblPhone);

        JTextField txtPhone = new JTextField();
        txtPhone.setBounds(190, 150, 220, 25);
        contentPanel.add(txtPhone);

        JLabel lblStatus = new JLabel("Status:");
        lblStatus.setBounds(40, 190, 140, 25);
        contentPanel.add(lblStatus);

        JComboBox<String> cmbStatus = new JComboBox<>(new String[]{"Active", "Inactive"});
        cmbStatus.setBounds(190, 190, 220, 25);
        contentPanel.add(cmbStatus);

        JLabel lblHireDate = new JLabel("Hire Date:");
        lblHireDate.setBounds(40, 230, 140, 25);
        contentPanel.add(lblHireDate);

        // Date must be yyyy-mm-dd if supplied.
        // Blank is allowed because SQL will use today's date.
        JTextField txtHireDate = new JTextField("2026-05-07");
        txtHireDate.setBounds(190, 230, 220, 25);
        contentPanel.add(txtHireDate);

        JButton btnOk = new JButton("OK");
        btnOk.setBounds(190, 290, 90, 30);
        contentPanel.add(btnOk);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(300, 290, 90, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showWorkerMenu());

        btnOk.addActionListener(e -> {

            if (txtFirstName.getText().trim().isEmpty()
                    || txtLastName.getText().trim().isEmpty()
                    || txtPosition.getText().trim().isEmpty()) {

                JOptionPane.showMessageDialog(this,
                        "First Name, Last Name, and Position are required.");
                return;
            }

            int newEmpID = workerService.addWorker(
                    txtFirstName.getText().trim(),
                    txtLastName.getText().trim(),
                    txtPosition.getText().trim(),
                    txtPhone.getText().trim(),
                    cmbStatus.getSelectedItem().toString(),
                    txtHireDate.getText().trim()
            );

            if (newEmpID > 0) {
                JOptionPane.showMessageDialog(this,
                        "Worker added successfully. EmpID: " + newEmpID);
                showWorkerMenu();
            } else {
                JOptionPane.showMessageDialog(this,
                        "Worker was not added. Check NetBeans output.");
            }
        });

        contentPanel.revalidate();
        contentPanel.repaint();
    }


    /* ============================================================
       METHOD: showAllWorkersTable

       PURPOSE:
       Displays all workers in a JTable.

       Java calls WorkerService.getAllWorkers().
       WorkerService calls SQL procedure GetAllWorkers.
       ============================================================ */

    private void showAllWorkersTable() {

        contentPanel.removeAll();

        String[] columns = {
            "EmpID",
            "First Name",
            "Last Name",
            "Position",
            "Phone Number",
            "Status",
            "Hire Date"
        };

        javax.swing.table.DefaultTableModel model =
                new javax.swing.table.DefaultTableModel(columns, 0);

        JTable table = new JTable(model);

        JScrollPane scrollPane = new JScrollPane(table);
        scrollPane.setBounds(30, 30, 850, 350);
        contentPanel.add(scrollPane);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(30, 400, 120, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showWorkerMenu());

        try (Connection con = DBConnection.getConnection()) {

            ResultSet rs = workerService.getAllWorkers(con);

            while (rs.next()) {
                model.addRow(new Object[]{
                    rs.getInt("EmpID"),
                    rs.getString("FirstName"),
                    rs.getString("LastName"),
                    rs.getString("Position"),
                    rs.getString("PhoneNumber"),
                    rs.getString("Status"),
                    rs.getDate("HireDate")
                });
            }

        } catch (Exception ex) {
            ex.printStackTrace();

            JOptionPane.showMessageDialog(this,
                    "Could not load workers: " + ex.getMessage());
        }

        contentPanel.revalidate();
        contentPanel.repaint();
    }


    /* ============================================================
       METHOD: showUpdateWorkerForm

       PURPOSE:
       Shows a form for editing worker details.

       This calls UpdateWorkerDetails in SQL.
       ============================================================ */

    private void showUpdateWorkerForm() {

        contentPanel.removeAll();

        JLabel lblEmpID = new JLabel("EmpID:");
        lblEmpID.setBounds(40, 30, 140, 25);
        contentPanel.add(lblEmpID);

        JTextField txtEmpID = new JTextField();
        txtEmpID.setBounds(190, 30, 220, 25);
        contentPanel.add(txtEmpID);

        JLabel lblFirstName = new JLabel("First Name:");
        lblFirstName.setBounds(40, 70, 140, 25);
        contentPanel.add(lblFirstName);

        JTextField txtFirstName = new JTextField();
        txtFirstName.setBounds(190, 70, 220, 25);
        contentPanel.add(txtFirstName);

        JLabel lblLastName = new JLabel("Last Name:");
        lblLastName.setBounds(40, 110, 140, 25);
        contentPanel.add(lblLastName);

        JTextField txtLastName = new JTextField();
        txtLastName.setBounds(190, 110, 220, 25);
        contentPanel.add(txtLastName);

        JLabel lblPosition = new JLabel("Position:");
        lblPosition.setBounds(40, 150, 140, 25);
        contentPanel.add(lblPosition);

        JTextField txtPosition = new JTextField();
        txtPosition.setBounds(190, 150, 220, 25);
        contentPanel.add(txtPosition);

        JLabel lblPhone = new JLabel("Phone Number:");
        lblPhone.setBounds(40, 190, 140, 25);
        contentPanel.add(lblPhone);

        JTextField txtPhone = new JTextField();
        txtPhone.setBounds(190, 190, 220, 25);
        contentPanel.add(txtPhone);

        JButton btnOk = new JButton("OK");
        btnOk.setBounds(190, 250, 90, 30);
        contentPanel.add(btnOk);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(300, 250, 90, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showWorkerMenu());

        btnOk.addActionListener(e -> {

            if (txtEmpID.getText().trim().isEmpty()
                    || txtFirstName.getText().trim().isEmpty()
                    || txtLastName.getText().trim().isEmpty()
                    || txtPosition.getText().trim().isEmpty()) {

                JOptionPane.showMessageDialog(this,
                        "EmpID, First Name, Last Name, and Position are required.");
                return;
            }

            try {
                int empID = Integer.parseInt(txtEmpID.getText().trim());

                boolean success = workerService.updateWorkerDetails(
                        empID,
                        txtFirstName.getText().trim(),
                        txtLastName.getText().trim(),
                        txtPosition.getText().trim(),
                        txtPhone.getText().trim()
                );

                if (success) {
                    JOptionPane.showMessageDialog(this,
                            "Worker updated successfully.");
                    showWorkerMenu();
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Worker was not updated. Check NetBeans output.");
                }

            } catch (NumberFormatException ex) {
                JOptionPane.showMessageDialog(this,
                        "EmpID must be a number.");
            }
        });

        contentPanel.revalidate();
        contentPanel.repaint();
    }


    /* ============================================================
       METHOD: showDeactivateWorkerForm

       PURPOSE:
       Marks a worker as inactive.

       It does not delete the worker from the database.
       ============================================================ */

    private void showDeactivateWorkerForm() {

        contentPanel.removeAll();

        JLabel lblEmpID = new JLabel("EmpID:");
        lblEmpID.setBounds(40, 30, 140, 25);
        contentPanel.add(lblEmpID);

        JTextField txtEmpID = new JTextField();
        txtEmpID.setBounds(190, 30, 220, 25);
        contentPanel.add(txtEmpID);

        JButton btnOk = new JButton("Deactivate");
        btnOk.setBounds(190, 90, 120, 30);
        contentPanel.add(btnOk);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(330, 90, 90, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showWorkerMenu());

        btnOk.addActionListener(e -> {

            if (txtEmpID.getText().trim().isEmpty()) {
                JOptionPane.showMessageDialog(this, "EmpID is required.");
                return;
            }

            try {
                int empID = Integer.parseInt(txtEmpID.getText().trim());

                boolean success = workerService.deactivateWorker(empID);

                if (success) {
                    JOptionPane.showMessageDialog(this,
                            "Worker deactivated successfully.");
                    showWorkerMenu();
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Worker was not deactivated. Check NetBeans output.");
                }

            } catch (NumberFormatException ex) {
                JOptionPane.showMessageDialog(this,
                        "EmpID must be a number.");
            }
        });

        contentPanel.revalidate();
        contentPanel.repaint();
    }
}