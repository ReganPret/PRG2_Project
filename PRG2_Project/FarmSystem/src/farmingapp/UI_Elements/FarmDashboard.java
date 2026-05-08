package farmingapp.UI_Elements;

import farmingapp.LoginUI;
import farmingapp.UI_Elements.WorkerPanel;
import farmingapp.UI_Elements.ProductPanel;
import farmingapp.UI_Elements.TreatmentPanel;
import farmingapp.UI_Elements.TaskPanel;
import javax.swing.*;
import java.awt.*;

public class FarmDashboard extends JFrame {

    // CardLayout lets us switch the centre area between panels.
    // Example: animal panel, product panel, worker panel, etc.
    private CardLayout cardLayout;

    // This is the middle area of the dashboard.
    // Different module panels are added here.
    private JPanel mainPanel;

    public FarmDashboard() {

        setTitle("Farm System Dashboard 🌾");
        setSize(1000, 600);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(EXIT_ON_CLOSE);

        // BorderLayout gives us:
        // NORTH = title bar
        // WEST = menu
        // CENTER = changing content area
        setLayout(new BorderLayout());

        // ================= TOP BAR =================
        JLabel title = new JLabel("🌾 FARM MANAGEMENT SYSTEM", JLabel.CENTER);
        title.setFont(new Font("Arial", Font.BOLD, 20));
        title.setOpaque(true);
        title.setBackground(new Color(34, 139, 34));
        title.setForeground(Color.WHITE);

        add(title, BorderLayout.NORTH);

        // ================= LEFT MENU =================
        JPanel menu = new JPanel(new GridLayout(6, 1));

        JButton btnAnimal = new JButton("Animals");
        JButton btnProduct = new JButton("Products");
        JButton btnWorker = new JButton("Workers");
        JButton btnTask = new JButton("Tasks");
        JButton btnTreatment = new JButton("Treatment");
        JButton btnLogout = new JButton("Logout");

        menu.add(btnAnimal);
        menu.add(btnProduct);
        menu.add(btnWorker);
        menu.add(btnTask);
        menu.add(btnTreatment);
        menu.add(btnLogout);

        add(menu, BorderLayout.WEST);

        // ================= CENTER AREA =================
        cardLayout = new CardLayout();
        mainPanel = new JPanel(cardLayout);

        // Each module gets its own panel class.
        // This keeps FarmDashboard small and clean.
        mainPanel.add(new AnimalPanel(), "animal");

        // Temporary placeholder panels.
        // Later we replace these with ProductPanel, WorkerPanel, etc.
        mainPanel.add(new ProductPanel(), "product");
        mainPanel.add(new WorkerPanel(), "worker");
        mainPanel.add(new TaskPanel(), "task");
        mainPanel.add(new TreatmentPanel(), "treatment");

        add(mainPanel, BorderLayout.CENTER);

        // ================= BUTTON ACTIONS =================
        btnAnimal.addActionListener(e -> cardLayout.show(mainPanel, "animal"));
        btnProduct.addActionListener(e -> cardLayout.show(mainPanel, "product"));
        btnWorker.addActionListener(e -> cardLayout.show(mainPanel, "worker"));
        btnTask.addActionListener(e -> cardLayout.show(mainPanel, "task"));
        btnTreatment.addActionListener(e -> cardLayout.show(mainPanel, "treatment"));

        btnLogout.addActionListener(e -> {
            new LoginUI().setVisible(true);
            this.dispose();
        });
    }

    // Simple temporary panel for modules we have not built yet.
    private JPanel simplePanel(String text) {
        JPanel panel = new JPanel();
        panel.add(new JLabel(text));
        return panel;
    }
}