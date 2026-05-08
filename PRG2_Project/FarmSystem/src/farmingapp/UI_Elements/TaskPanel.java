package farmingapp.UI_Elements;

import farmingapp.DBConnection;
import farmingapp.Services.TaskService;
import javax.swing.*;
import java.awt.*;
import java.sql.*;

public class TaskPanel extends JPanel {

    private TaskService taskService = new TaskService();
    private JPanel contentPanel;

    public TaskPanel() {

        setLayout(new BorderLayout());

        JLabel heading = new JLabel("📋 Task Module", JLabel.CENTER);
        heading.setFont(new Font("Arial", Font.BOLD, 22));
        add(heading, BorderLayout.NORTH);

        contentPanel = new JPanel();
        contentPanel.setLayout(null);
        add(contentPanel, BorderLayout.CENTER);

        showTaskMenu();
    }


    /* ============================================================
       METHOD: showTaskMenu

       PURPOSE:
       Shows task-related buttons.

       These are the main task actions for this version:
       - Assign Task
       - View All Tasks
       - Complete Task
       ============================================================ */

    private void showTaskMenu() {

        contentPanel.removeAll();

        JButton btnAssignTask = new JButton("Assign Task");
        btnAssignTask.setBounds(40, 40, 180, 35);
        contentPanel.add(btnAssignTask);

        JButton btnViewTasks = new JButton("View All Tasks");
        btnViewTasks.setBounds(40, 90, 180, 35);
        contentPanel.add(btnViewTasks);

        JButton btnCompleteTask = new JButton("Complete Task");
        btnCompleteTask.setBounds(40, 140, 180, 35);
        contentPanel.add(btnCompleteTask);

        btnAssignTask.addActionListener(e -> showAssignTaskForm());
        btnViewTasks.addActionListener(e -> showAllTasksTable());
        btnCompleteTask.addActionListener(e -> showCompleteTaskForm());

        contentPanel.revalidate();
        contentPanel.repaint();
    }


    /* ============================================================
       METHOD: showAssignTaskForm

       PURPOSE:
       Shows the form used to assign a task to a worker.

       FLOW:
       1. User enters EmpID of worker.
       2. User optionally enters TagID of animal.
       3. User enters task details.
       4. OK calls TaskService.assignTask().
       5. TaskService calls SQL procedure AssignTask.
       ============================================================ */

    private void showAssignTaskForm() {

        contentPanel.removeAll();

        JLabel lblEmpID = new JLabel("Worker EmpID:");
        lblEmpID.setBounds(40, 30, 150, 25);
        contentPanel.add(lblEmpID);

        JTextField txtEmpID = new JTextField();
        txtEmpID.setBounds(200, 30, 220, 25);
        contentPanel.add(txtEmpID);

        JLabel lblTagID = new JLabel("Animal TagID:");
        lblTagID.setBounds(40, 70, 150, 25);
        contentPanel.add(lblTagID);

        JTextField txtTagID = new JTextField();
        txtTagID.setBounds(200, 70, 220, 25);
        contentPanel.add(txtTagID);

        JLabel lblDescription = new JLabel("Task Description:");
        lblDescription.setBounds(40, 110, 150, 25);
        contentPanel.add(lblDescription);

        JTextField txtDescription = new JTextField();
        txtDescription.setBounds(200, 110, 320, 25);
        contentPanel.add(txtDescription);

        JLabel lblType = new JLabel("Task Type:");
        lblType.setBounds(40, 150, 150, 25);
        contentPanel.add(lblType);

        JTextField txtType = new JTextField();
        txtType.setBounds(200, 150, 220, 25);
        contentPanel.add(txtType);

        JLabel lblDate = new JLabel("Date Assigned:");
        lblDate.setBounds(40, 190, 150, 25);
        contentPanel.add(lblDate);

        JTextField txtDate = new JTextField("2026-05-07");
        txtDate.setBounds(200, 190, 220, 25);
        contentPanel.add(txtDate);

        JLabel lblNotes = new JLabel("Notes:");
        lblNotes.setBounds(40, 230, 150, 25);
        contentPanel.add(lblNotes);

        JTextField txtNotes = new JTextField();
        txtNotes.setBounds(200, 230, 320, 25);
        contentPanel.add(txtNotes);

        JButton btnOk = new JButton("OK");
        btnOk.setBounds(200, 290, 90, 30);
        contentPanel.add(btnOk);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(310, 290, 90, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showTaskMenu());

        btnOk.addActionListener(e -> {

            if (txtEmpID.getText().trim().isEmpty()
                    || txtDescription.getText().trim().isEmpty()
                    || txtType.getText().trim().isEmpty()) {

                JOptionPane.showMessageDialog(this,
                        "Worker EmpID, Task Description, and Task Type are required.");
                return;
            }

            try {
                int empID = Integer.parseInt(txtEmpID.getText().trim());

                Integer tagID = null;
                if (!txtTagID.getText().trim().isEmpty()) {
                    tagID = Integer.parseInt(txtTagID.getText().trim());
                }

                int newTaskID = taskService.assignTask(
                        empID,
                        tagID,
                        txtDescription.getText().trim(),
                        txtType.getText().trim(),
                        txtDate.getText().trim(),
                        txtNotes.getText().trim()
                );

                if (newTaskID > 0) {
                    JOptionPane.showMessageDialog(this,
                            "Task assigned successfully. TaskID: " + newTaskID);
                    showTaskMenu();
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Task was not assigned. Check NetBeans output.");
                }

            } catch (NumberFormatException ex) {
                JOptionPane.showMessageDialog(this,
                        "EmpID and TagID must be numbers.");
            }
        });

        contentPanel.revalidate();
        contentPanel.repaint();
    }


    /* ============================================================
       METHOD: showAllTasksTable

       PURPOSE:
       Displays all tasks in a JTable.

       Java calls TaskService.getAllTasks().
       TaskService calls SQL procedure GetAllTasks.
       ============================================================ */

    private void showAllTasksTable() {

        contentPanel.removeAll();

        String[] columns = {
            "TaskID",
            "EmpID",
            "TagID",
            "Description",
            "Type",
            "Status",
            "Date Assigned",
            "Date Completed",
            "Notes"
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

        btnBack.addActionListener(e -> showTaskMenu());

        try (Connection con = DBConnection.getConnection()) {

            ResultSet rs = taskService.getAllTasks(con);

            while (rs.next()) {
                model.addRow(new Object[]{
                    rs.getInt("TaskID"),
                    rs.getInt("EmpID"),
                    rs.getObject("TagID"),
                    rs.getString("TaskDescription"),
                    rs.getString("TaskType"),
                    rs.getString("Status"),
                    rs.getDate("DateAssigned"),
                    rs.getDate("DateCompleted"),
                    rs.getString("Notes")
                });
            }

        } catch (Exception ex) {
            ex.printStackTrace();

            JOptionPane.showMessageDialog(this,
                    "Could not load tasks: " + ex.getMessage());
        }

        contentPanel.revalidate();
        contentPanel.repaint();
    }


    /* ============================================================
       METHOD: showCompleteTaskForm

       PURPOSE:
       Shows a form used to mark a task as completed.

       FLOW:
       1. User enters TaskID.
       2. User enters completion date and notes.
       3. OK calls TaskService.completeTask().
       4. TaskService calls SQL procedure CompleteTask.
       ============================================================ */

    private void showCompleteTaskForm() {

        contentPanel.removeAll();

        JLabel lblTaskID = new JLabel("TaskID:");
        lblTaskID.setBounds(40, 30, 150, 25);
        contentPanel.add(lblTaskID);

        JTextField txtTaskID = new JTextField();
        txtTaskID.setBounds(200, 30, 220, 25);
        contentPanel.add(txtTaskID);

        JLabel lblDate = new JLabel("Date Completed:");
        lblDate.setBounds(40, 70, 150, 25);
        contentPanel.add(lblDate);

        JTextField txtDate = new JTextField("2026-05-07");
        txtDate.setBounds(200, 70, 220, 25);
        contentPanel.add(txtDate);

        JLabel lblNotes = new JLabel("Notes:");
        lblNotes.setBounds(40, 110, 150, 25);
        contentPanel.add(lblNotes);

        JTextField txtNotes = new JTextField();
        txtNotes.setBounds(200, 110, 320, 25);
        contentPanel.add(txtNotes);

        JButton btnOk = new JButton("Complete");
        btnOk.setBounds(200, 170, 110, 30);
        contentPanel.add(btnOk);

        JButton btnBack = new JButton("Back");
        btnBack.setBounds(330, 170, 90, 30);
        contentPanel.add(btnBack);

        btnBack.addActionListener(e -> showTaskMenu());

        btnOk.addActionListener(e -> {

            if (txtTaskID.getText().trim().isEmpty()) {
                JOptionPane.showMessageDialog(this, "TaskID is required.");
                return;
            }

            try {
                int taskID = Integer.parseInt(txtTaskID.getText().trim());

                boolean success = taskService.completeTask(
                        taskID,
                        txtDate.getText().trim(),
                        txtNotes.getText().trim()
                );

                if (success) {
                    JOptionPane.showMessageDialog(this,
                            "Task completed successfully.");
                    showTaskMenu();
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Task was not completed. Check NetBeans output.");
                }

            } catch (NumberFormatException ex) {
                JOptionPane.showMessageDialog(this,
                        "TaskID must be a number.");
            }
        });

        contentPanel.revalidate();
        contentPanel.repaint();
    }
}