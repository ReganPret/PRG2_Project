package farmingapp.UI_Elements;

import farmingapp.Services.AnimalService;
import farmingapp.DBConnection;
import javax.swing.*;
import java.awt.*;
import java.sql.*;

public class AnimalPanel extends JPanel {

    // This service class talks to SQL Server animal procedures.
    private AnimalService animalService = new AnimalService();

    // This panel will hold either:
    // - animal menu buttons
    // - add animal form
    private JPanel contentPanel;

    public AnimalPanel() {

        // BorderLayout keeps this module clean:
        // NORTH = heading
        // CENTER = changing content
        setLayout(new BorderLayout());

        JLabel heading = new JLabel("🐄 Animal Module", JLabel.CENTER);
        heading.setFont(new Font("Arial", Font.BOLD, 22));
        add(heading, BorderLayout.NORTH);

        contentPanel = new JPanel();
        contentPanel.setLayout(null);
        add(contentPanel, BorderLayout.CENTER);

        showAnimalMenu();
    }

    private void showAnimalMenu() {

        // Clears whatever was showing before.
        contentPanel.removeAll();

        JButton btnAddAnimal = new JButton("Add Animal");
        btnAddAnimal.setBounds(40, 40, 180, 35);
        contentPanel.add(btnAddAnimal);

        JButton btnViewAnimals = new JButton("View All Animals");
        btnViewAnimals.setBounds(40, 90, 180, 35);
        contentPanel.add(btnViewAnimals);

        JButton btnSearchAnimals = new JButton("Search Animals");
        btnSearchAnimals.setBounds(40, 140, 180, 35);
        contentPanel.add(btnSearchAnimals);

        JButton btnUpdateStatus = new JButton("Update Status");
        btnUpdateStatus.setBounds(40, 190, 180, 35);
        contentPanel.add(btnUpdateStatus);

        JButton btnAnimalHistory = new JButton("Animal History");
        btnAnimalHistory.setBounds(40, 240, 180, 35);
        contentPanel.add(btnAnimalHistory);

        // When Add Animal is clicked, replace the menu with the add form.
        btnAddAnimal.addActionListener(e -> showAddAnimalForm());

        // These buttons are placeholders for now.
        // We will wire them one by one later.
        /* ============================================================
           BUTTON ACTION: View All Animals

           When clicked:
           - hide the animal menu
           - show a table
           - load all animals from the database
           ============================================================ */

        btnViewAnimals.addActionListener(e -> showAllAnimalsTable());

                /* ============================================================
           BUTTON ACTION: Search Animals

           When clicked:
           - show search fields
           - allow filtering by type, status, and gender
           ============================================================ */

        btnSearchAnimals.addActionListener(e -> showSearchAnimalsForm());

        /* ============================================================
           BUTTON ACTION: Update Status

           When clicked:
           - show the Update Animal Status form
           - user enters TagID and status
           - OK calls UpdateAnimalStatus procedure
           ============================================================ */

        btnUpdateStatus.addActionListener(e -> showUpdateAnimalStatusForm());

        btnAnimalHistory.addActionListener(e ->
            JOptionPane.showMessageDialog(this, "This is a paid feature, please add account details.")
        );

        contentPanel.revalidate();
        contentPanel.repaint();
    }
    
        /* ============================================================
       METHOD: showAllAnimalsTable

       PURPOSE:
       This method displays all animals in a JTable.

       FLOW:
       1. Clear the current AnimalPanel content.
       2. Create a table with animal columns.
       3. Call AnimalService.getAllAnimals().
       4. Add each database row into the table.
       5. Show the table on screen.
       6. Add a Back button to return to the Animal menu.

       IMPORTANT:
       The database still does the SELECT through GetAllAnimals.
       Java only displays the returned data.
       ============================================================ */

    private void showAllAnimalsTable() {

        // Remove whatever is currently showing in the animal content area.
        contentPanel.removeAll();

        // These are the column headings shown at the top of the table.
        String[] columns = {
            "TagID",
            "Animal Type",
            "Breed",
            "Gender",
            "Use Type",
            "Status",
            "Date Registered",
            "Notes"
        };

        // This table model holds the rows that will be displayed in the JTable.
        // We use DefaultTableModel because it is simple for adding rows manually.
        javax.swing.table.DefaultTableModel model =
                new javax.swing.table.DefaultTableModel(columns, 0);

        // JTable is the Swing component that displays rows and columns.
        JTable table = new JTable(model);

        // JScrollPane gives the table scrollbars if there are many records.
        JScrollPane scrollPane = new JScrollPane(table);
        scrollPane.setBounds(30, 30, 800, 350);
        contentPanel.add(scrollPane);

        // Back button returns to the Animal menu.
        JButton btnBack = new JButton("Back");
        btnBack.setBounds(30, 400, 120, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showAnimalMenu());

        // Database call section.
        // This opens the connection, calls the procedure, reads the rows,
        // and then closes the connection automatically.
        try (Connection con = DBConnection.getConnection()) {

            // Call the AnimalService method.
            // AnimalService then calls the GetAllAnimals stored procedure.
            ResultSet rs = animalService.getAllAnimals(con);

            // Loop through every row returned by SQL Server.
            while (rs.next()) {

                // Add one animal row into the table model.
                model.addRow(new Object[]{
                    rs.getInt("TagID"),
                    rs.getString("AnimalType"),
                    rs.getString("Breed"),
                    rs.getString("Gender"),
                    rs.getString("UseType"),
                    rs.getString("Status"),
                    rs.getDate("DateRegistered"),
                    rs.getString("Notes")
                });
            }

        } catch (Exception ex) {

            // Print full technical error in NetBeans output.
            ex.printStackTrace();

            // Show a friendly popup to the user.
            JOptionPane.showMessageDialog(this,
                    "Could not load animals: " + ex.getMessage());
        }

        // Refresh the panel after changing what is displayed.
        contentPanel.revalidate();
        contentPanel.repaint();
    }
    
        /* ============================================================
       METHOD: showSearchAnimalsForm

       PURPOSE:
       Shows a small search/filter form for animals.

       FLOW:
       1. User selects or types filter values.
       2. User clicks Search.
       3. Java calls AnimalService.searchAnimals().
       4. AnimalService calls SQL procedure SearchAnimals.
       5. Results are displayed in a JTable.

       IMPORTANT:
       Blank filters mean "show all for that field".
       Example:
       - Animal Type blank
       - Status Healthy
       - Gender Any
       This means: find all Healthy animals.
       ============================================================ */

    private void showSearchAnimalsForm() {

        // Clear current animal panel content.
        contentPanel.removeAll();

        JLabel lblType = new JLabel("Animal Type:");
        lblType.setBounds(30, 20, 120, 25);
        contentPanel.add(lblType);

        JTextField txtType = new JTextField();
        txtType.setBounds(160, 20, 180, 25);
        contentPanel.add(txtType);

        JLabel lblStatus = new JLabel("Status:");
        lblStatus.setBounds(30, 60, 120, 25);
        contentPanel.add(lblStatus);

        JComboBox<String> cmbStatus = new JComboBox<>(
            new String[]{"", "Healthy", "Sick", "Sold", "Died", "Lost", "Stolen"}
        );
        cmbStatus.setBounds(160, 60, 180, 25);
        contentPanel.add(cmbStatus);

        JLabel lblGender = new JLabel("Gender:");
        lblGender.setBounds(30, 100, 120, 25);
        contentPanel.add(lblGender);

        JComboBox<String> cmbGender = new JComboBox<>(new String[]{"Any", "M", "F"});
        cmbGender.setBounds(160, 100, 180, 25);
        contentPanel.add(cmbGender);

        JButton btnSearch = new JButton("Search");
        btnSearch.setBounds(160, 140, 90, 30);
        contentPanel.add(btnSearch);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(260, 140, 90, 30);
        contentPanel.add(btnBack);

        String[] columns = {
            "TagID",
            "Animal Type",
            "Breed",
            "Gender",
            "Use Type",
            "Status",
            "Date Registered",
            "Notes"
        };

        javax.swing.table.DefaultTableModel model =
                new javax.swing.table.DefaultTableModel(columns, 0);

        JTable table = new JTable(model);

        JScrollPane scrollPane = new JScrollPane(table);
        scrollPane.setBounds(30, 190, 800, 280);
        contentPanel.add(scrollPane);

        btnBack.addActionListener(e -> showAnimalMenu());

        btnSearch.addActionListener(e -> {

            // Clear old search results before loading new results.
            model.setRowCount(0);

            try (Connection con = DBConnection.getConnection()) {

                ResultSet rs = animalService.searchAnimals(
                    con,
                    txtType.getText(),
                    cmbStatus.getSelectedItem().toString(),
                    cmbGender.getSelectedItem().toString()
                );

                while (rs.next()) {
                    model.addRow(new Object[]{
                        rs.getInt("TagID"),
                        rs.getString("AnimalType"),
                        rs.getString("Breed"),
                        rs.getString("Gender"),
                        rs.getString("UseType"),
                        rs.getString("Status"),
                        rs.getDate("DateRegistered"),
                        rs.getString("Notes")
                    });
                }

            } catch (Exception ex) {
                ex.printStackTrace();

                JOptionPane.showMessageDialog(this,
                        "Could not search animals: " + ex.getMessage());
            }
        });

        contentPanel.revalidate();
        contentPanel.repaint();
    }
    
        /* ============================================================
       METHOD: showUpdateAnimalStatusForm

       PURPOSE:
       Shows a form that lets the user change an animal's status.

       FLOW:
       1. User enters the animal TagID.
       2. User selects the new status.
       3. User enters event date and notes.
       4. User clicks OK.
       5. Java calls AnimalService.updateAnimalStatus().
       6. SQL procedure UpdateAnimalStatus updates Animal.Status
          and writes a history record to AnimalEvent.

       IMPORTANT:
       This is better than Java running UPDATE Animal directly,
       because the procedure also creates the event/history record.
       ============================================================ */

    private void showUpdateAnimalStatusForm() {

        // Clear the current animal panel content.
        contentPanel.removeAll();

        JLabel lblTagID = new JLabel("Animal TagID:");
        lblTagID.setBounds(40, 30, 140, 25);
        contentPanel.add(lblTagID);

        JTextField txtTagID = new JTextField();
        txtTagID.setBounds(190, 30, 180, 25);
        contentPanel.add(txtTagID);

        JLabel lblStatus = new JLabel("New Status:");
        lblStatus.setBounds(40, 70, 140, 25);
        contentPanel.add(lblStatus);

        JComboBox<String> cmbStatus = new JComboBox<>(
            new String[]{"Healthy", "Sick", "Sold", "Died", "Lost", "Stolen"}
        );
        cmbStatus.setBounds(190, 70, 180, 25);
        contentPanel.add(cmbStatus);

        JLabel lblEmpID = new JLabel("Worker EmpID:");
        lblEmpID.setBounds(40, 110, 140, 25);
        contentPanel.add(lblEmpID);

        JTextField txtEmpID = new JTextField();
        txtEmpID.setBounds(190, 110, 180, 25);
        contentPanel.add(txtEmpID);

        JLabel lblDate = new JLabel("Event Date:");
        lblDate.setBounds(40, 150, 140, 25);
        contentPanel.add(lblDate);

        JTextField txtDate = new JTextField("2026-05-07");
        txtDate.setBounds(190, 150, 180, 25);
        contentPanel.add(txtDate);

        JLabel lblNotes = new JLabel("Notes:");
        lblNotes.setBounds(40, 190, 140, 25);
        contentPanel.add(lblNotes);

        JTextField txtNotes = new JTextField();
        txtNotes.setBounds(190, 190, 300, 25);
        contentPanel.add(txtNotes);

        JButton btnOk = new JButton("OK");
        btnOk.setBounds(190, 250, 90, 30);
        contentPanel.add(btnOk);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(300, 250, 90, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showAnimalMenu());

        btnOk.addActionListener(e -> {

            // Validate TagID.
            // The procedure needs a real animal ID.
            if (txtTagID.getText().trim().isEmpty()) {
                JOptionPane.showMessageDialog(this, "Animal TagID is required.");
                return;
            }

            // Validate date.
            // Date.valueOf() needs yyyy-mm-dd.
            if (txtDate.getText().trim().isEmpty()) {
                JOptionPane.showMessageDialog(this, "Event Date is required.");
                return;
            }

            try {
                // Convert TagID from text to int.
                int tagID = Integer.parseInt(txtTagID.getText().trim());

                // EmpID is optional in your SQL procedure.
                // If the field is blank, we send null.
                Integer empID = null;

                if (!txtEmpID.getText().trim().isEmpty()) {
                    empID = Integer.parseInt(txtEmpID.getText().trim());
                }

                boolean success = animalService.updateAnimalStatus(
                    tagID,
                    empID,
                    cmbStatus.getSelectedItem().toString(),
                    txtDate.getText().trim(),
                    txtNotes.getText().trim()
                );

                if (success) {
                    JOptionPane.showMessageDialog(this, "Animal status updated successfully.");
                    showAnimalMenu();
                } else {
                    JOptionPane.showMessageDialog(this, "Animal status was not updated. Check NetBeans output.");
                }

            } catch (NumberFormatException ex) {

                // This catches cases where the user typed letters instead of numbers.
                JOptionPane.showMessageDialog(this, "TagID and EmpID must be numbers.");
            }
        });

        contentPanel.revalidate();
        contentPanel.repaint();
    }

    private void showAddAnimalForm() {

        contentPanel.removeAll();

        JLabel lblType = new JLabel("Animal Type:");
        lblType.setBounds(40, 30, 130, 25);
        contentPanel.add(lblType);

        JTextField txtType = new JTextField();
        txtType.setBounds(180, 30, 200, 25);
        contentPanel.add(txtType);

        JLabel lblBreed = new JLabel("Breed:");
        lblBreed.setBounds(40, 70, 130, 25);
        contentPanel.add(lblBreed);

        JTextField txtBreed = new JTextField();
        txtBreed.setBounds(180, 70, 200, 25);
        contentPanel.add(txtBreed);

        JLabel lblGender = new JLabel("Gender:");
        lblGender.setBounds(40, 110, 130, 25);
        contentPanel.add(lblGender);

        JComboBox<String> cmbGender = new JComboBox<>(new String[]{"M", "F"});
        cmbGender.setBounds(180, 110, 200, 25);
        contentPanel.add(cmbGender);

        JLabel lblUseType = new JLabel("Use Type:");
        lblUseType.setBounds(40, 150, 130, 25);
        contentPanel.add(lblUseType);

        JTextField txtUseType = new JTextField();
        txtUseType.setBounds(180, 150, 200, 25);
        contentPanel.add(txtUseType);

        JLabel lblStatus = new JLabel("Status:");
        lblStatus.setBounds(40, 190, 130, 25);
        contentPanel.add(lblStatus);

        JComboBox<String> cmbStatus = new JComboBox<>(
            new String[]{"Healthy", "Sick", "Sold", "Died", "Lost", "Stolen"}
        );
        cmbStatus.setBounds(180, 190, 200, 25);
        contentPanel.add(cmbStatus);

        JLabel lblDate = new JLabel("Date Registered:");
        lblDate.setBounds(40, 230, 130, 25);
        contentPanel.add(lblDate);

        // Date must be yyyy-mm-dd because AnimalService uses Date.valueOf().
        JTextField txtDate = new JTextField("2026-05-07");
        txtDate.setBounds(180, 230, 200, 25);
        contentPanel.add(txtDate);

        JLabel lblNotes = new JLabel("Notes:");
        lblNotes.setBounds(40, 270, 130, 25);
        contentPanel.add(lblNotes);

        JTextField txtNotes = new JTextField();
        txtNotes.setBounds(180, 270, 300, 25);
        contentPanel.add(txtNotes);

        JButton btnOk = new JButton("OK");
        btnOk.setBounds(180, 330, 90, 30);
        contentPanel.add(btnOk);

        JButton btnCancel = new JButton("Cancel");
        btnCancel.setBounds(290, 330, 90, 30);
        contentPanel.add(btnCancel);

        btnOk.addActionListener(e -> {

            // Basic Java-side validation.
            // SQL also validates, but this gives a nicer message before calling SQL.
            if (txtType.getText().trim().isEmpty()
                    || txtBreed.getText().trim().isEmpty()
                    || txtDate.getText().trim().isEmpty()) {

                JOptionPane.showMessageDialog(this,
                    "Animal Type, Breed, and Date Registered are required.");
                return;
            }

            int newTagID = animalService.addAnimal(
                txtType.getText().trim(),
                txtBreed.getText().trim(),
                cmbGender.getSelectedItem().toString(),
                txtUseType.getText().trim(),
                cmbStatus.getSelectedItem().toString(),
                txtDate.getText().trim(),
                txtNotes.getText().trim()
            );

            if (newTagID > 0) {
                JOptionPane.showMessageDialog(this,
                    "Animal added successfully. TagID: " + newTagID);

                // Return to animal menu after success.
                showAnimalMenu();
            } else {
                JOptionPane.showMessageDialog(this,
                    "Animal was not added. Check NetBeans output.");
            }
        });

        btnCancel.addActionListener(e -> showAnimalMenu());

        contentPanel.revalidate();
        contentPanel.repaint();
    }
}