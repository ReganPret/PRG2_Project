package farmingapp.UI_Elements;

import farmingapp.DBConnection;
import farmingapp.Services.TreatmentService;
import javax.swing.*;
import java.awt.*;
import java.sql.*;

public class TreatmentPanel extends JPanel {

    private TreatmentService treatmentService = new TreatmentService();
    private JPanel contentPanel;

    public TreatmentPanel() {

        setLayout(new BorderLayout());

        JLabel heading = new JLabel("💉 Treatment Module", JLabel.CENTER);
        heading.setFont(new Font("Arial", Font.BOLD, 22));
        add(heading, BorderLayout.NORTH);

        contentPanel = new JPanel();
        contentPanel.setLayout(null);
        add(contentPanel, BorderLayout.CENTER);

        showTreatmentMenu();
    }


    /* ============================================================
       METHOD: showTreatmentMenu
       ============================================================ */

    private void showTreatmentMenu() {

        contentPanel.removeAll();

        JButton btnRecord = new JButton("Record Treatment");
        btnRecord.setBounds(40, 40, 200, 35);
        contentPanel.add(btnRecord);

        JButton btnView = new JButton("View All Treatments");
        btnView.setBounds(40, 90, 200, 35);
        contentPanel.add(btnView);

        btnRecord.addActionListener(e -> showRecordTreatmentForm());
        btnView.addActionListener(e -> showAllTreatmentsTable());

        contentPanel.revalidate();
        contentPanel.repaint();
    }


    /* ============================================================
       METHOD: showRecordTreatmentForm
       ============================================================ */

    private void showRecordTreatmentForm() {

        contentPanel.removeAll();

        JLabel lblTagID = new JLabel("Animal TagID:");
        lblTagID.setBounds(40, 30, 150, 25);
        contentPanel.add(lblTagID);

        JTextField txtTagID = new JTextField();
        txtTagID.setBounds(200, 30, 200, 25);
        contentPanel.add(txtTagID);

        JLabel lblEmpID = new JLabel("Worker EmpID:");
        lblEmpID.setBounds(40, 70, 150, 25);
        contentPanel.add(lblEmpID);

        JTextField txtEmpID = new JTextField();
        txtEmpID.setBounds(200, 70, 200, 25);
        contentPanel.add(txtEmpID);

        JLabel lblItemID = new JLabel("Product ItemID:");
        lblItemID.setBounds(40, 110, 150, 25);
        contentPanel.add(lblItemID);

        JTextField txtItemID = new JTextField();
        txtItemID.setBounds(200, 110, 200, 25);
        contentPanel.add(txtItemID);

        JLabel lblType = new JLabel("Treatment Type:");
        lblType.setBounds(40, 150, 150, 25);
        contentPanel.add(lblType);

        JTextField txtType = new JTextField();
        txtType.setBounds(200, 150, 250, 25);
        contentPanel.add(txtType);

        JLabel lblDate = new JLabel("Date:");
        lblDate.setBounds(40, 190, 150, 25);
        contentPanel.add(lblDate);

        JTextField txtDate = new JTextField("2026-05-07");
        txtDate.setBounds(200, 190, 200, 25);
        contentPanel.add(txtDate);

        JLabel lblNotes = new JLabel("Notes:");
        lblNotes.setBounds(40, 230, 150, 25);
        contentPanel.add(lblNotes);

        JTextField txtNotes = new JTextField();
        txtNotes.setBounds(200, 230, 300, 25);
        contentPanel.add(txtNotes);

        JButton btnOk = new JButton("OK");
        btnOk.setBounds(200, 290, 90, 30);
        contentPanel.add(btnOk);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(310, 290, 90, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showTreatmentMenu());

        btnOk.addActionListener(e -> {

            if (txtTagID.getText().trim().isEmpty()
                    || txtEmpID.getText().trim().isEmpty()
                    || txtItemID.getText().trim().isEmpty()
                    || txtType.getText().trim().isEmpty()) {

                JOptionPane.showMessageDialog(this,
                        "TagID, EmpID, ItemID, and Type are required.");
                return;
            }

            try {
                int tagID = Integer.parseInt(txtTagID.getText().trim());
                int empID = Integer.parseInt(txtEmpID.getText().trim());
                int itemID = Integer.parseInt(txtItemID.getText().trim());

                int newID = treatmentService.recordTreatment(
                        tagID,
                        empID,
                        itemID,
                        txtType.getText().trim(),
                        txtDate.getText().trim(),
                        txtNotes.getText().trim()
                );

                if (newID > 0) {
                    JOptionPane.showMessageDialog(this,
                            "Treatment recorded. ID: " + newID);
                    showTreatmentMenu();
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Failed. Check output.");
                }

            } catch (NumberFormatException ex) {
                JOptionPane.showMessageDialog(this,
                        "IDs must be numbers.");
            }
        });

        contentPanel.revalidate();
        contentPanel.repaint();
    }


    /* ============================================================
       METHOD: showAllTreatmentsTable
       ============================================================ */

    private void showAllTreatmentsTable() {

        contentPanel.removeAll();

        String[] cols = {
            "TreatmentID", "TagID", "EmpID",
            "ItemID", "Type", "Date", "Notes"
        };

        javax.swing.table.DefaultTableModel model =
                new javax.swing.table.DefaultTableModel(cols, 0);

        JTable table = new JTable(model);
        JScrollPane scroll = new JScrollPane(table);
        scroll.setBounds(30, 30, 850, 350);
        contentPanel.add(scroll);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(30, 400, 120, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showTreatmentMenu());

        try (Connection con = DBConnection.getConnection()) {

            ResultSet rs = treatmentService.getAllTreatments(con);

            while (rs.next()) {
                model.addRow(new Object[]{
                    rs.getInt("TreatmentID"),
                    rs.getInt("TagID"),
                    rs.getInt("EmpID"),
                    rs.getInt("ItemID"),
                    rs.getString("TreatmentType"),
                    rs.getDate("TreatmentDate"),
                    rs.getString("Notes")
                });
            }

        } catch (Exception ex) {
            ex.printStackTrace();
        }

        contentPanel.revalidate();
        contentPanel.repaint();
    }
}