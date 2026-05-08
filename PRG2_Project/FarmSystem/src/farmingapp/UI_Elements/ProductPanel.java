package farmingapp.UI_Elements;

import farmingapp.DBConnection;
import farmingapp.Services.ProductService;
import javax.swing.*;
import java.awt.*;
import java.sql.*;

public class ProductPanel extends JPanel {

    private ProductService productService = new ProductService();
    private JPanel contentPanel;

    public ProductPanel() {

        setLayout(new BorderLayout());

        JLabel heading = new JLabel("🌿 Product Module", JLabel.CENTER);
        heading.setFont(new Font("Arial", Font.BOLD, 22));
        add(heading, BorderLayout.NORTH);

        contentPanel = new JPanel();
        contentPanel.setLayout(null);
        add(contentPanel, BorderLayout.CENTER);

        showProductMenu();
    }

    /* ============================================================
       METHOD: showProductMenu

       PURPOSE:
       Shows product-related buttons.

       These buttons are the product module actions.
       We wire them one by one.
       ============================================================ */

    private void showProductMenu() {

        contentPanel.removeAll();

        JButton btnAddProduct = new JButton("Add Product");
        btnAddProduct.setBounds(40, 40, 180, 35);
        contentPanel.add(btnAddProduct);

        JButton btnViewProducts = new JButton("View All Products");
        btnViewProducts.setBounds(40, 90, 180, 35);
        contentPanel.add(btnViewProducts);

        JButton btnSearchProducts = new JButton("Search Products");
        btnSearchProducts.setBounds(40, 140, 180, 35);
        contentPanel.add(btnSearchProducts);

        JButton btnRestockProduct = new JButton("Restock Product");
        btnRestockProduct.setBounds(40, 190, 180, 35);
        contentPanel.add(btnRestockProduct);

        JButton btnUseProduct = new JButton("Use Product");
        btnUseProduct.setBounds(40, 240, 180, 35);
        contentPanel.add(btnUseProduct);

        btnAddProduct.addActionListener(e -> showAddProductForm());

                /* ============================================================
           BUTTON ACTION: View All Products

           When clicked:
           - clears the current product menu
           - shows a JTable
           - loads all product records using GetAllProducts
           ============================================================ */

        btnViewProducts.addActionListener(e -> showAllProductsTable());

                /* ============================================================
           BUTTON ACTION: Search Products

           When clicked:
           - shows a product search form
           - allows filtering by Product Type and Status
           - displays matching products in a JTable
           ============================================================ */

        btnSearchProducts.addActionListener(e -> showSearchProductsForm());

        btnRestockProduct.addActionListener(e ->
            JOptionPane.showMessageDialog(this, "This is a paid feature, please add account details.")
        );

        btnUseProduct.addActionListener(e ->
            JOptionPane.showMessageDialog(this, "This is a paid feature, please add account details.")
        );

        contentPanel.revalidate();
        contentPanel.repaint();
    }
    
    
        /* ============================================================
       METHOD: showAllProductsTable

       PURPOSE:
       Displays all products in a table on the Product screen.

       FLOW:
       1. Clear the current product panel.
       2. Create a JTable.
       3. Open a database connection.
       4. Call ProductService.getAllProducts().
       5. ProductService calls SQL procedure GetAllProducts.
       6. Read each row from the ResultSet.
       7. Add each row to the JTable.
       8. Show a Back button.

       IMPORTANT:
       This method does NOT write raw SQL.
       The database reading is still done through a stored procedure.
       ============================================================ */

    private void showAllProductsTable() {

        // Clear the content panel so only this table view is shown.
        contentPanel.removeAll();

        // These are the column names displayed at the top of the JTable.
        // They do not have to exactly match SQL column names,
        // but keeping them similar makes the table easier to understand.
        String[] columns = {
            "ItemID",
            "Product Name",
            "Product Type",
            "Quantity",
            "Unit",
            "Reorder Level",
            "Storage Location",
            "Status"
        };

        // DefaultTableModel stores the data that the JTable displays.
        // The second argument 0 means start with zero rows.
        javax.swing.table.DefaultTableModel model =
                new javax.swing.table.DefaultTableModel(columns, 0);

        // JTable is the visible table component.
        JTable table = new JTable(model);

        // JScrollPane adds scrollbars around the table.
        // This is useful when there are many products.
        JScrollPane scrollPane = new JScrollPane(table);
        scrollPane.setBounds(30, 30, 850, 350);
        contentPanel.add(scrollPane);

        // Back button returns to the Product menu.
        JButton btnBack = new JButton("Back");
        btnBack.setBounds(30, 400, 120, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showProductMenu());

        // This is the database section.
        // try-with-resources automatically closes the connection.
        try (Connection con = DBConnection.getConnection()) {

            // Calls the service method.
            // The service method calls the SQL stored procedure.
            ResultSet rs = productService.getAllProducts(con);

            // Loop through every product returned from SQL Server.
            while (rs.next()) {

                // Add one database row into the JTable model.
                model.addRow(new Object[]{
                    rs.getInt("ItemID"),
                    rs.getString("ProductName"),
                    rs.getString("ProductType"),
                    rs.getInt("QuantityOnHand"),
                    rs.getString("UnitOfMeasure"),
                    rs.getInt("ReorderLevel"),
                    rs.getString("StorageLocation"),
                    rs.getString("Status")
                });
            }

        } catch (Exception ex) {

            // Print full error in NetBeans output.
            // Useful for developers while testing.
            ex.printStackTrace();

            // Show a friendly popup to the user.
            JOptionPane.showMessageDialog(this,
                    "Could not load products: " + ex.getMessage());
        }

        // Refresh the panel so Swing redraws the updated screen.
        contentPanel.revalidate();
        contentPanel.repaint();
    }
    
        /* ============================================================
       METHOD: showSearchProductsForm

       PURPOSE:
       Shows a search/filter form for products.

       FLOW:
       1. User enters Product Type, or leaves it blank.
       2. User chooses Status, or chooses Any.
       3. User clicks Search.
       4. Java calls ProductService.searchProducts().
       5. ProductService calls the SQL procedure SearchProducts.
       6. Returned products are displayed in a JTable.

       IMPORTANT:
       Blank values are treated as "ignore this filter".

       EXAMPLES:
       Product Type = Feed, Status = Any
       Means:
       show all feed products.

       Product Type = blank, Status = Active
       Means:
       show all active products.
       ============================================================ */

    private void showSearchProductsForm() {

        // Clear the product panel so only the search screen is shown.
        contentPanel.removeAll();

        JLabel lblType = new JLabel("Product Type:");
        lblType.setBounds(30, 20, 120, 25);
        contentPanel.add(lblType);

        JTextField txtType = new JTextField();
        txtType.setBounds(160, 20, 180, 25);
        contentPanel.add(txtType);

        JLabel lblStatus = new JLabel("Status:");
        lblStatus.setBounds(30, 60, 120, 25);
        contentPanel.add(lblStatus);

        JComboBox<String> cmbStatus = new JComboBox<>(
            new String[]{"Any", "Active", "Inactive"}
        );
        cmbStatus.setBounds(160, 60, 180, 25);
        contentPanel.add(cmbStatus);

        JButton btnSearch = new JButton("Search");
        btnSearch.setBounds(160, 110, 90, 30);
        contentPanel.add(btnSearch);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(260, 110, 90, 30);
        contentPanel.add(btnBack);

        // These are the headings for the product results table.
        String[] columns = {
            "ItemID",
            "Product Name",
            "Product Type",
            "Quantity",
            "Unit",
            "Reorder Level",
            "Storage Location",
            "Status"
        };

        // This model stores the table rows.
        javax.swing.table.DefaultTableModel model =
                new javax.swing.table.DefaultTableModel(columns, 0);

        // JTable displays the model rows on screen.
        JTable table = new JTable(model);

        // JScrollPane makes the table scrollable.
        JScrollPane scrollPane = new JScrollPane(table);
        scrollPane.setBounds(30, 170, 850, 300);
        contentPanel.add(scrollPane);

        // Back returns to the Product menu.
        btnBack.addActionListener(e -> showProductMenu());

        // Search button action.
        btnSearch.addActionListener(e -> {

            // Clear old results before showing new results.
            model.setRowCount(0);

            try (Connection con = DBConnection.getConnection()) {

                // Call the service method.
                // The service method calls the SQL stored procedure.
                ResultSet rs = productService.searchProducts(
                    con,
                    txtType.getText(),
                    cmbStatus.getSelectedItem().toString()
                );

                // Loop through all rows returned by SQL Server.
                while (rs.next()) {

                    // Add one product row into the JTable.
                    model.addRow(new Object[]{
                        rs.getInt("ItemID"),
                        rs.getString("ProductName"),
                        rs.getString("ProductType"),
                        rs.getInt("QuantityOnHand"),
                        rs.getString("UnitOfMeasure"),
                        rs.getInt("ReorderLevel"),
                        rs.getString("StorageLocation"),
                        rs.getString("Status")
                    });
                }

            } catch (Exception ex) {

                // Prints technical details in NetBeans output.
                ex.printStackTrace();

                // Shows a simpler popup message.
                JOptionPane.showMessageDialog(this,
                        "Could not search products: " + ex.getMessage());
            }
        });

        // Refresh the screen after changing the panel.
        contentPanel.revalidate();
        contentPanel.repaint();
    }
    
    
    

    /* ============================================================
       METHOD: showAddProductForm

       PURPOSE:
       Shows the form used to add a product.

       FLOW:
       1. User fills in product details.
       2. User clicks OK.
       3. Java validates required fields.
       4. Java calls ProductService.addProduct().
       5. ProductService calls SQL procedure AddProduct.
       6. SQL adds product and logs initial stock.
       ============================================================ */

    private void showAddProductForm() {

        contentPanel.removeAll();

        JLabel lblName = new JLabel("Product Name:");
        lblName.setBounds(40, 30, 140, 25);
        contentPanel.add(lblName);

        JTextField txtName = new JTextField();
        txtName.setBounds(190, 30, 220, 25);
        contentPanel.add(txtName);

        JLabel lblType = new JLabel("Product Type:");
        lblType.setBounds(40, 70, 140, 25);
        contentPanel.add(lblType);

        JTextField txtType = new JTextField();
        txtType.setBounds(190, 70, 220, 25);
        contentPanel.add(txtType);

        JLabel lblQty = new JLabel("Quantity:");
        lblQty.setBounds(40, 110, 140, 25);
        contentPanel.add(lblQty);

        JTextField txtQty = new JTextField("0");
        txtQty.setBounds(190, 110, 220, 25);
        contentPanel.add(txtQty);

        JLabel lblUnit = new JLabel("Unit of Measure:");
        lblUnit.setBounds(40, 150, 140, 25);
        contentPanel.add(lblUnit);

        JTextField txtUnit = new JTextField();
        txtUnit.setBounds(190, 150, 220, 25);
        contentPanel.add(txtUnit);

        JLabel lblReorder = new JLabel("Reorder Level:");
        lblReorder.setBounds(40, 190, 140, 25);
        contentPanel.add(lblReorder);

        JTextField txtReorder = new JTextField("0");
        txtReorder.setBounds(190, 190, 220, 25);
        contentPanel.add(txtReorder);

        JLabel lblLocation = new JLabel("Storage Location:");
        lblLocation.setBounds(40, 230, 140, 25);
        contentPanel.add(lblLocation);

        JTextField txtLocation = new JTextField();
        txtLocation.setBounds(190, 230, 220, 25);
        contentPanel.add(txtLocation);

        JLabel lblEmpID = new JLabel("Logged-in EmpID:");
        lblEmpID.setBounds(40, 270, 140, 25);
        contentPanel.add(lblEmpID);

        JTextField txtEmpID = new JTextField("1");
        txtEmpID.setBounds(190, 270, 220, 25);
        contentPanel.add(txtEmpID);

        JLabel lblStatus = new JLabel("Status:");
        lblStatus.setBounds(40, 310, 140, 25);
        contentPanel.add(lblStatus);

        JComboBox<String> cmbStatus = new JComboBox<>(new String[]{"Active", "Inactive"});
        cmbStatus.setBounds(190, 310, 220, 25);
        contentPanel.add(cmbStatus);

        JButton btnOk = new JButton("OK");
        btnOk.setBounds(190, 360, 90, 30);
        contentPanel.add(btnOk);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(300, 360, 90, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showProductMenu());

        btnOk.addActionListener(e -> {

            if (txtName.getText().trim().isEmpty()
                    || txtType.getText().trim().isEmpty()) {

                JOptionPane.showMessageDialog(this,
                        "Product Name and Product Type are required.");
                return;
            }

            try {
                int quantity = Integer.parseInt(txtQty.getText().trim());
                int reorder = Integer.parseInt(txtReorder.getText().trim());
                int empID = Integer.parseInt(txtEmpID.getText().trim());

                int newItemID = productService.addProduct(
                    txtName.getText().trim(),
                    txtType.getText().trim(),
                    quantity,
                    txtUnit.getText().trim(),
                    reorder,
                    txtLocation.getText().trim(),
                    empID,
                    cmbStatus.getSelectedItem().toString()
                );

                if (newItemID > 0) {
                    JOptionPane.showMessageDialog(this,
                            "Product added successfully. ItemID: " + newItemID);

                    showProductMenu();
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Product was not added. Check NetBeans output.");
                }

            } catch (NumberFormatException ex) {
                JOptionPane.showMessageDialog(this,
                        "Quantity, Reorder Level, and EmpID must be numbers.");
            }
        });

        contentPanel.revalidate();
        contentPanel.repaint();
    }
}