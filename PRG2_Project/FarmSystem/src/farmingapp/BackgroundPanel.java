package farmingapp;

import javax.swing.*;
import java.awt.*;

public class BackgroundPanel extends JPanel {

    private Image img;

    public BackgroundPanel(String path) {
        img = new ImageIcon(path).getImage();
    }

    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        g.drawImage(img, 0, 0, getWidth(), getHeight(), this);
    }
}