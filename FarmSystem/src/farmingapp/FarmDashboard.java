package farmingapp;

import javax.swing.*;
import java.awt.*;

public class FarmDashboard extends JFrame {

    CardLayout cardLayout;
    JPanel mainPanel;

    FarmService service = new FarmService();

    public FarmDashboard() {

        setTitle("Farm System Dashboard 🌾");
        setSize(1000, 600);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(EXIT_ON_CLOSE);

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

        mainPanel.add(animalPanel(), "animal");
        mainPanel.add(productPanel(), "product");
        mainPanel.add(workerPanel(), "worker");
        mainPanel.add(taskPanel(), "task");
        mainPanel.add(treatmentPanel(), "treatment");

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

    // ================= MODULE PANELS =================

    private JPanel animalPanel() {
        BackgroundPanel p = new BackgroundPanel("images/animal.jpg");
        p.add(new JLabel("🐄 Animal Module"));
        return p;
    }

    private JPanel productPanel() {
        BackgroundPanel p = new BackgroundPanel("images/product.jpg");
        p.add(new JLabel("🌿 Product Module"));
        return p;
    }

    private JPanel workerPanel() {
        BackgroundPanel p = new BackgroundPanel("images/worker.jpg");
        p.add(new JLabel("👨‍🌾 Worker Module"));
        return p;
    }

    private JPanel taskPanel() {
        BackgroundPanel p = new BackgroundPanel("images/task.jpg");
        p.add(new JLabel("📋 Task Module"));
        return p;
    }

    private JPanel treatmentPanel() {
        BackgroundPanel p = new BackgroundPanel("images/treatment.jpg");
        p.add(new JLabel("💉 Treatment Module"));
        return p;
    }
}