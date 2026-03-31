# database
import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.event.*;
import java.sql.*;
import java.util.Timer;
import java.util.TimerTask;
import java.util.ArrayList;
import java.util.List;

public class OnlineExamSystem extends JFrame implements ActionListener {
    
    // Database connection parameters
    private static final String DB_URL = "jdbc:mysql://localhost:3306/exam_system";
    private static final String DB_USER = "root"; // Change this to your MySQL username
    private static final String DB_PASSWORD = "Ilim@123"; // Change this to your MySQL password
    
    // Database objects
    private Connection connection;
    private int currentUserId;
    private String currentUsername;
    
    // Components
    private JLabel titleLabel;
    private JLabel questionLabel;
    private JLabel questionNumberLabel;
    private JLabel timerLabel;
    private JRadioButton opt1, opt2, opt3, opt4;
    private JButton nextButton, prevButton, resultButton, restartButton;
    private ButtonGroup bg;
    private JPanel questionPanel;
    private JPanel controlPanel;
    private JPanel topPanel;
    private JProgressBar progressBar;
    private JLabel scorePreviewLabel;
    private JLabel userInfoLabel;
    
    // Variables
    private int currentQuestion = 0;
    private int score = 0;
    private int[] userAnswers;
    private int timeLeft = 300; // 5 minutes in seconds
    private Timer timer;
    private boolean examCompleted = false;
    private long startTime;
    
    // Questions data (loaded from database)
    private List<Question> questionsList = new ArrayList<>();
    private int[] correctAnswersArray;
    
    // Dark theme colors
    private Color themeColor = new Color(156, 39, 176);
    private Color accentColor = new Color(103, 58, 183);
    private Color darkBg = new Color(18, 18, 18);
    private Color cardBg = new Color(30, 30, 30);
    private Color textColor = new Color(230, 230, 230);
    private Color secondaryText = new Color(160, 160, 160);
    
    // Question class to hold question data
    class Question {
        int id;
        String text;
        String[] options = new String[4];
        int correctOption;
        
        Question(int id, String text, String opt1, String opt2, String opt3, String opt4, int correctOption) {
            this.id = id;
            this.text = text;
            this.options[0] = opt1;
            this.options[1] = opt2;
            this.options[2] = opt3;
            this.options[3] = opt4;
            this.correctOption = correctOption;
        }
    }
    
    public OnlineExamSystem() {
        // Initialize database connection FIRST
        initializeDatabase();
        
        // Show login dialog
        if (!showLoginDialog()) {
            System.exit(0); // Exit if login fails or cancelled
        }
        
        // Load questions from database
        loadQuestionsFromDatabase();
        
        // Initialize user answers array
        userAnswers = new int[questionsList.size()];
        for (int i = 0; i < userAnswers.length; i++) {
            userAnswers[i] = -1;
        }
        
        // Setup JFrame
        setTitle("✨ Online Examination System ✨");
        setSize(950, 700);
        setLayout(new BorderLayout());
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        setResizable(false);
        
        // Set dark background for frame
        getContentPane().setBackground(darkBg);
        
        // Initialize components
        initializeComponents();
        
        // Load first question
        loadQuestion();
        
        // Start timer
        startTime = System.currentTimeMillis();
        startTimer();
        
        setVisible(true);
    }
    
    private boolean showLoginDialog() {
        JPanel loginPanel = new JPanel(new GridBagLayout());
        loginPanel.setBackground(new Color(30, 30, 30));
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(10, 10, 10, 10);
        
        // Title
        JLabel titleLabel = new JLabel("🔐 Exam Login");
        titleLabel.setFont(new Font("Segoe UI", Font.BOLD, 24));
        titleLabel.setForeground(new Color(156, 39, 176));
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.gridwidth = 2;
        loginPanel.add(titleLabel, gbc);
        
        // Username
        gbc.gridwidth = 1;
        gbc.gridy = 1;
        gbc.gridx = 0;
        JLabel userLabel = new JLabel("Username:");
        userLabel.setForeground(Color.WHITE);
        userLabel.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        loginPanel.add(userLabel, gbc);
        
        gbc.gridx = 1;
        JTextField usernameField = new JTextField(15);
        usernameField.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        loginPanel.add(usernameField, gbc);
        
        // Password
        gbc.gridy = 2;
        gbc.gridx = 0;
        JLabel passLabel = new JLabel("Password:");
        passLabel.setForeground(Color.WHITE);
        passLabel.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        loginPanel.add(passLabel, gbc);
        
        gbc.gridx = 1;
        JPasswordField passwordField = new JPasswordField(15);
        passwordField.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        loginPanel.add(passwordField, gbc);
        
        // Buttons
        gbc.gridy = 3;
        gbc.gridx = 0;
        JButton loginBtn = new JButton("Login");
        loginBtn.setBackground(new Color(156, 39, 176));
        loginBtn.setForeground(Color.WHITE);
        loginBtn.setFont(new Font("Segoe UI", Font.BOLD, 14));
        loginBtn.setCursor(new Cursor(Cursor.HAND_CURSOR));
        loginPanel.add(loginBtn, gbc);
        
        gbc.gridx = 1;
        JButton registerBtn = new JButton("Register");
        registerBtn.setBackground(new Color(40, 167, 69));
        registerBtn.setForeground(Color.WHITE);
        registerBtn.setFont(new Font("Segoe UI", Font.BOLD, 14));
        registerBtn.setCursor(new Cursor(Cursor.HAND_CURSOR));
        loginPanel.add(registerBtn, gbc);
        
        // Login action
        final boolean[] loginSuccess = {false};
        
        loginBtn.addActionListener(e -> {
            String username = usernameField.getText().trim();
            String password = new String(passwordField.getPassword()).trim();
            
            if (authenticateUser(username, password)) {
                currentUsername = username;
                loginSuccess[0] = true;
                Window win = SwingUtilities.getWindowAncestor(loginPanel);
                win.dispose();
            } else {
                JOptionPane.showMessageDialog(loginPanel, 
                    "Invalid username or password!", "Login Failed", 
                    JOptionPane.ERROR_MESSAGE);
            }
        });
        
        registerBtn.addActionListener(e -> {
            showRegistrationDialog();
        });
        
        // Create a modal dialog
        JDialog loginDialog = new JDialog();
        loginDialog.setModal(true);
        loginDialog.setContentPane(loginPanel);
        loginDialog.pack();
        loginDialog.setLocationRelativeTo(null);
        
        // Add window listener to handle dialog closing
        loginDialog.addWindowListener(new java.awt.event.WindowAdapter() {
            @Override
            public void windowClosing(java.awt.event.WindowEvent windowEvent) {
                if (!loginSuccess[0]) {
                    System.exit(0);
                }
            }
        });
        
        loginDialog.setVisible(true);
        
        return loginSuccess[0];
    }
    
    private void showRegistrationDialog() {
        JPanel regPanel = new JPanel(new GridBagLayout());
        regPanel.setBackground(new Color(30, 30, 30));
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(8, 8, 8, 8);
        
        JLabel titleLabel = new JLabel("📝 New User Registration");
        titleLabel.setFont(new Font("Segoe UI", Font.BOLD, 20));
        titleLabel.setForeground(new Color(156, 39, 176));
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.gridwidth = 2;
        regPanel.add(titleLabel, gbc);
        
        String[] labels = {"Full Name:", "Username:", "Email:", "Password:", "Confirm Password:"};
        JTextField[] fields = new JTextField[5];
        
        for (int i = 0; i < labels.length; i++) {
            gbc.gridwidth = 1;
            gbc.gridy = i + 1;
            gbc.gridx = 0;
            JLabel label = new JLabel(labels[i]);
            label.setForeground(Color.WHITE);
            regPanel.add(label, gbc);
            
            gbc.gridx = 1;
            if (i >= 3) {
                fields[i] = new JPasswordField(15);
            } else {
                fields[i] = new JTextField(15);
            }
            fields[i].setFont(new Font("Segoe UI", Font.PLAIN, 14));
            regPanel.add(fields[i], gbc);
        }
        
        gbc.gridy = 6;
        gbc.gridx = 0;
        gbc.gridwidth = 2;
        JButton registerBtn = new JButton("Register");
        registerBtn.setBackground(new Color(40, 167, 69));
        registerBtn.setForeground(Color.WHITE);
        registerBtn.setFont(new Font("Segoe UI", Font.BOLD, 14));
        regPanel.add(registerBtn, gbc);
        
        registerBtn.addActionListener(e -> {
            String fullName = fields[0].getText().trim();
            String username = fields[1].getText().trim();
            String email = fields[2].getText().trim();
            String password = fields[3].getText().trim();
            String confirmPass = fields[4].getText().trim();
            
            if (username.isEmpty() || password.isEmpty()) {
                JOptionPane.showMessageDialog(regPanel, "Username and password are required!");
                return;
            }
            
            if (!password.equals(confirmPass)) {
                JOptionPane.showMessageDialog(regPanel, "Passwords do not match!");
                return;
            }
            
            if (registerUser(fullName, username, email, password)) {
                JOptionPane.showMessageDialog(regPanel, "Registration successful! Please login.");
                Window win = SwingUtilities.getWindowAncestor(regPanel);
                win.dispose();
            } else {
                JOptionPane.showMessageDialog(regPanel, "Username already exists!");
            }
        });
        
        JOptionPane.showMessageDialog(null, regPanel, "Register", JOptionPane.PLAIN_MESSAGE);
    }
    
    private boolean authenticateUser(String username, String password) {
        if (connection == null) {
            JOptionPane.showMessageDialog(null, "Database connection not established!", "Error", JOptionPane.ERROR_MESSAGE);
            return false;
        }
        
        String query = "SELECT user_id FROM users WHERE username = ? AND password = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(query)) {
            pstmt.setString(1, username);
            pstmt.setString(2, password);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                currentUserId = rs.getInt("user_id");
                return true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            JOptionPane.showMessageDialog(null, "Database error: " + e.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
        }
        return false;
    }
    
    private boolean registerUser(String fullName, String username, String email, String password) {
        if (connection == null) return false;
        
        String query = "INSERT INTO users (full_name, username, email, password) VALUES (?, ?, ?, ?)";
        try (PreparedStatement pstmt = connection.prepareStatement(query)) {
            pstmt.setString(1, fullName);
            pstmt.setString(2, username);
            pstmt.setString(3, email);
            pstmt.setString(4, password);
            pstmt.executeUpdate();
            return true;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    private void initializeDatabase() {
        try {
            // Load MySQL JDBC Driver
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            // Establish connection
            connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            
            // Test connection
            if (connection != null) {
                System.out.println("Database connection established successfully!");
            }
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
            JOptionPane.showMessageDialog(null, 
                "MySQL JDBC Driver not found!\nPlease add mysql-connector-java.jar to classpath.", 
                "Driver Error", JOptionPane.ERROR_MESSAGE);
            System.exit(1);
        } catch (SQLException e) {
            e.printStackTrace();
            JOptionPane.showMessageDialog(null, 
                "Database connection failed!\nPlease check:\n1. MySQL is running\n2. Database 'exam_system' exists\n3. Username/password is correct\n\nError: " + e.getMessage(), 
                "Database Error", JOptionPane.ERROR_MESSAGE);
            System.exit(1);
        }
    }
    
    private void loadQuestionsFromDatabase() {
        if (connection == null) {
            loadDefaultQuestions();
            return;
        }
        
        String query = "SELECT * FROM questions_bank ORDER BY question_id";
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(query)) {
            
            while (rs.next()) {
                Question q = new Question(
                    rs.getInt("question_id"),
                    rs.getString("question_text"),
                    rs.getString("option1"),
                    rs.getString("option2"),
                    rs.getString("option3"),
                    rs.getString("option4"),
                    rs.getInt("correct_option")
                );
                questionsList.add(q);
            }
            
            // If no questions in database, load defaults
            if (questionsList.isEmpty()) {
                loadDefaultQuestions();
            }
            
            // Initialize correct answers array
            correctAnswersArray = new int[questionsList.size()];
            for (int i = 0; i < questionsList.size(); i++) {
                correctAnswersArray[i] = questionsList.get(i).correctOption;
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
            loadDefaultQuestions();
        }
    }
    
    private void loadDefaultQuestions() {
        String[][] defaultQuestions = {
            {"Java is developed by?", "Microsoft", "Sun Microsystems", "Google", "Apple"},
            {"Which keyword is used for inheritance?", "this", "super", "extends", "implements"},
            {"Which is not a data type in Java?", "int", "float", "boolean", "real"},
            {"Which method is the entry point of a Java program?", "start()", "main()", "run()", "init()"},
            {"Which is an OOP concept?", "Loop", "Array", "Encapsulation", "Pointer"},
            {"What does JVM stand for?", "Java Visual Machine", "Java Virtual Machine", "Java Variable Method", "Java Verified Machine"},
            {"Which keyword is used to create an object?", "new", "create", "object", "instance"},
            {"What is the size of int in Java?", "2 bytes", "4 bytes", "8 bytes", "1 byte"},
            {"Which access modifier provides the highest level of visibility?", "private", "protected", "public", "default"},
            {"What is the default value of a boolean variable?", "true", "false", "0", "null"}
        };
        int[] defaultCorrect = {1, 2, 3, 1, 2, 1, 0, 1, 2, 1};
        
        for (int i = 0; i < defaultQuestions.length; i++) {
            Question q = new Question(i+1, defaultQuestions[i][0], 
                defaultQuestions[i][1], defaultQuestions[i][2], 
                defaultQuestions[i][3], defaultQuestions[i][4], defaultCorrect[i]);
            questionsList.add(q);
        }
        correctAnswersArray = new int[questionsList.size()];
        for (int i = 0; i < questionsList.size(); i++) {
            correctAnswersArray[i] = questionsList.get(i).correctOption;
        }
    }
    
    private void initializeComponents() {
        // Top Panel with Gradient Effect
        topPanel = new JPanel(new BorderLayout()) {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                Graphics2D g2d = (Graphics2D) g;
                g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
                GradientPaint gp = new GradientPaint(0, 0, new Color(156, 39, 176), getWidth(), 0, new Color(103, 58, 183));
                g2d.setPaint(gp);
                g2d.fillRect(0, 0, getWidth(), getHeight());
            }
        };
        topPanel.setPreferredSize(new Dimension(950, 100));
        topPanel.setBorder(BorderFactory.createEmptyBorder(15, 20, 15, 20));
        topPanel.setOpaque(false);
        
        // Title with icon
        titleLabel = new JLabel("📚 Online Examination System");
        titleLabel.setFont(new Font("Segoe UI", Font.BOLD, 26));
        titleLabel.setForeground(Color.WHITE);
        
        // User Info Panel
        JPanel userInfoPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        userInfoPanel.setOpaque(false);
        userInfoLabel = new JLabel("👤 " + currentUsername);
        userInfoLabel.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        userInfoLabel.setForeground(Color.WHITE);
        userInfoPanel.add(userInfoLabel);
        
        // Timer Panel
        JPanel timerPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        timerPanel.setOpaque(false);
        
        timerLabel = new JLabel("⏱️ Time Left: 05:00");
        timerLabel.setFont(new Font("Segoe UI", Font.BOLD, 20));
        timerLabel.setForeground(Color.WHITE);
        timerPanel.add(timerLabel);
        
        JPanel rightPanel = new JPanel(new GridLayout(2, 1));
        rightPanel.setOpaque(false);
        rightPanel.add(userInfoPanel);
        rightPanel.add(timerPanel);
        
        topPanel.add(titleLabel, BorderLayout.WEST);
        topPanel.add(rightPanel, BorderLayout.EAST);
        add(topPanel, BorderLayout.NORTH);
        
        // Question Panel
        questionPanel = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                Graphics2D g2d = (Graphics2D) g;
                g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2d.setColor(cardBg);
                g2d.fillRoundRect(0, 0, getWidth(), getHeight(), 20, 20);
                g2d.setColor(new Color(50, 50, 50));
                g2d.drawRoundRect(0, 0, getWidth() - 1, getHeight() - 1, 20, 20);
            }
        };
        questionPanel.setLayout(null);
        questionPanel.setBackground(cardBg);
        questionPanel.setBorder(BorderFactory.createEmptyBorder(20, 30, 20, 30));
        questionPanel.setOpaque(false);
        
        // Progress Bar
        progressBar = new JProgressBar(0, questionsList.size());
        progressBar.setValue(0);
        progressBar.setStringPainted(true);
        progressBar.setForeground(themeColor);
        progressBar.setBackground(new Color(50, 50, 50));
        progressBar.setBorder(BorderFactory.createEmptyBorder());
        progressBar.setBounds(20, 10, 850, 25);
        progressBar.setFont(new Font("Segoe UI", Font.BOLD, 12));
        questionPanel.add(progressBar);
        
        // Score Preview
        scorePreviewLabel = new JLabel("📊 Score: 0/" + questionsList.size());
        scorePreviewLabel.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        scorePreviewLabel.setForeground(secondaryText);
        scorePreviewLabel.setBounds(20, 45, 200, 20);
        questionPanel.add(scorePreviewLabel);
        
        // Question Number Label
        questionNumberLabel = new JLabel();
        questionNumberLabel.setFont(new Font("Segoe UI", Font.BOLD, 16));
        questionNumberLabel.setForeground(themeColor);
        questionNumberLabel.setBounds(20, 75, 850, 30);
        questionPanel.add(questionNumberLabel);
        
        // Question Label
        questionLabel = new JLabel();
        questionLabel.setFont(new Font("Segoe UI", Font.PLAIN, 18));
        questionLabel.setForeground(textColor);
        questionLabel.setBounds(20, 115, 850, 50);
        questionPanel.add(questionLabel);
        
        // Radio Buttons
        opt1 = createStyledRadioButton();
        opt2 = createStyledRadioButton();
        opt3 = createStyledRadioButton();
        opt4 = createStyledRadioButton();
        
        JRadioButton[] options = {opt1, opt2, opt3, opt4};
        int yPosition = 180;
        for (JRadioButton opt : options) {
            opt.setBounds(40, yPosition, 800, 35);
            questionPanel.add(opt);
            yPosition += 55;
        }
        
        bg = new ButtonGroup();
        bg.add(opt1);
        bg.add(opt2);
        bg.add(opt3);
        bg.add(opt4);
        
        add(questionPanel, BorderLayout.CENTER);
        
        // Control Panel
        controlPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 20, 15));
        controlPanel.setBackground(new Color(25, 25, 25));
        controlPanel.setBorder(BorderFactory.createMatteBorder(1, 0, 0, 0, new Color(50, 50, 50)));
        
        prevButton = createStyledButton("← Previous", new Color(108, 117, 125));
        nextButton = createStyledButton("Next →", themeColor);
        resultButton = createStyledButton("📝 Submit Exam", new Color(40, 167, 69));
        restartButton = createStyledButton("🔄 Restart Exam", new Color(220, 53, 69));
        
        controlPanel.add(prevButton);
        controlPanel.add(nextButton);
        controlPanel.add(resultButton);
        controlPanel.add(restartButton);
        
        add(controlPanel, BorderLayout.SOUTH);
    }
    
    private JRadioButton createStyledRadioButton() {
        JRadioButton radio = new JRadioButton();
        radio.setFont(new Font("Segoe UI", Font.PLAIN, 15));
        radio.setForeground(textColor);
        radio.setFocusPainted(false);
        radio.setBackground(cardBg);
        radio.setOpaque(false);
        return radio;
    }
    
    private JButton createStyledButton(String text, Color bgColor) {
        JButton button = new JButton(text);
        button.setFont(new Font("Segoe UI", Font.BOLD, 13));
        button.setForeground(Color.WHITE);
        button.setBackground(bgColor);
        button.setBorder(BorderFactory.createEmptyBorder(10, 20, 10, 20));
        button.setFocusPainted(false);
        button.setCursor(new Cursor(Cursor.HAND_CURSOR));
        button.addActionListener(this);
        return button;
    }
    
    private void loadQuestion() {
        bg.clearSelection();
        
        // Update progress bar
        progressBar.setValue(currentQuestion);
        progressBar.setString(String.format("Question %d of %d", currentQuestion + 1, questionsList.size()));
        
        // Update question number and text
        questionNumberLabel.setText("📌 Question " + (currentQuestion + 1) + " of " + questionsList.size());
        Question q = questionsList.get(currentQuestion);
        questionLabel.setText(q.text);
        
        // Set option texts
        opt1.setText("🅰️  " + q.options[0]);
        opt2.setText("🅱️  " + q.options[1]);
        opt3.setText("🅲  " + q.options[2]);
        opt4.setText("🅳  " + q.options[3]);
        
        // Restore previously selected answer
        if (userAnswers[currentQuestion] != -1) {
            switch (userAnswers[currentQuestion]) {
                case 0: opt1.setSelected(true); break;
                case 1: opt2.setSelected(true); break;
                case 2: opt3.setSelected(true); break;
                case 3: opt4.setSelected(true); break;
            }
        }
        
        // Update button states
        prevButton.setEnabled(currentQuestion > 0);
        
        if (currentQuestion == questionsList.size() - 1) {
            nextButton.setText("✓ Finish");
        } else {
            nextButton.setText("Next →");
        }
        
        // Update score preview
        updateScorePreview();
    }
    
    private void updateScorePreview() {
        int tempScore = 0;
        for (int i = 0; i <= currentQuestion; i++) {
            if (userAnswers[i] == correctAnswersArray[i]) {
                tempScore++;
            }
        }
        scorePreviewLabel.setText("📊 Current Score: " + tempScore + "/" + questionsList.size());
    }
    
    private void saveCurrentAnswer() {
        if (opt1.isSelected()) userAnswers[currentQuestion] = 0;
        else if (opt2.isSelected()) userAnswers[currentQuestion] = 1;
        else if (opt3.isSelected()) userAnswers[currentQuestion] = 2;
        else if (opt4.isSelected()) userAnswers[currentQuestion] = 3;
    }
    
    private void calculateScore() {
        score = 0;
        for (int i = 0; i < questionsList.size(); i++) {
            if (userAnswers[i] == correctAnswersArray[i]) {
                score++;
            }
        }
    }
    
    private void saveExamResultToDatabase() {
        if (connection == null) {
            JOptionPane.showMessageDialog(this, 
                "Cannot save results: Database connection not available!", 
                "Warning", JOptionPane.WARNING_MESSAGE);
            return;
        }
        
        int timeTaken = (int)((System.currentTimeMillis() - startTime) / 1000);
        double percentage = (score * 100.0) / questionsList.size();
        String grade = calculateGrade(percentage);
        
        String resultQuery = "INSERT INTO exam_results (user_id, exam_name, score, total_questions, percentage, grade, time_taken) VALUES (?, ?, ?, ?, ?, ?, ?)";
        
        try (PreparedStatement pstmt = connection.prepareStatement(resultQuery, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setInt(1, currentUserId);
            pstmt.setString(2, "Java Programming Exam");
            pstmt.setInt(3, score);
            pstmt.setInt(4, questionsList.size());
            pstmt.setDouble(5, percentage);
            pstmt.setString(6, grade);
            pstmt.setInt(7, timeTaken);
            pstmt.executeUpdate();
            
            ResultSet generatedKeys = pstmt.getGeneratedKeys();
            if (generatedKeys.next()) {
                int resultId = generatedKeys.getInt(1);
                saveDetailedAnswers(resultId);
            }
            
            JOptionPane.showMessageDialog(this, 
                "✅ Your exam results have been saved to the database!", 
                "Results Saved", JOptionPane.INFORMATION_MESSAGE);
                
        } catch (SQLException e) {
            e.printStackTrace();
            JOptionPane.showMessageDialog(this, 
                "Failed to save results to database!\n" + e.getMessage(), 
                "Database Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void saveDetailedAnswers(int resultId) {
        if (connection == null) return;
        
        String answerQuery = "INSERT INTO user_answers (result_id, question_number, question_text, selected_answer, correct_answer, is_correct) VALUES (?, ?, ?, ?, ?, ?)";
        
        try (PreparedStatement pstmt = connection.prepareStatement(answerQuery)) {
            for (int i = 0; i < questionsList.size(); i++) {
                Question q = questionsList.get(i);
                boolean isCorrect = (userAnswers[i] == correctAnswersArray[i]);
                
                pstmt.setInt(1, resultId);
                pstmt.setInt(2, i + 1);
                pstmt.setString(3, q.text);
                pstmt.setInt(4, userAnswers[i]);
                pstmt.setInt(5, correctAnswersArray[i]);
                pstmt.setBoolean(6, isCorrect);
                pstmt.addBatch();
            }
            pstmt.executeBatch();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    private String calculateGrade(double percentage) {
        if (percentage >= 90) return "A+";
        else if (percentage >= 80) return "A";
        else if (percentage >= 70) return "B";
        else if (percentage >= 60) return "C";
        else if (percentage >= 50) return "D";
        else return "F";
    }
    
    private void showResult() {
        if (examCompleted) return;
        
        examCompleted = true;
        saveCurrentAnswer();
        calculateScore();
        
        if (timer != null) {
            timer.cancel();
        }
        
        // Save results to database
        saveExamResultToDatabase();
        
        prevButton.setEnabled(false);
        nextButton.setEnabled(false);
        resultButton.setEnabled(false);
        restartButton.setEnabled(true);
        
        double percentage = (score * 100.0) / questionsList.size();
        String grade;
        
        if (percentage >= 90) {
            grade = "A+ (Outstanding!) 🏆";
        } else if (percentage >= 80) {
            grade = "A (Excellent!) ⭐";
        } else if (percentage >= 70) {
            grade = "B (Very Good!) 👍";
        } else if (percentage >= 60) {
            grade = "C (Good) 📘";
        } else if (percentage >= 50) {
            grade = "D (Satisfactory) 📖";
        } else {
            grade = "F (Need Improvement) 📚";
        }
        
        // Create result panel
        JPanel resultPanel = new JPanel();
        resultPanel.setLayout(new BoxLayout(resultPanel, BoxLayout.Y_AXIS));
        resultPanel.setBackground(new Color(30, 30, 30));
        resultPanel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));
        
        JLabel headerLabel = new JLabel("📊 EXAMINATION RESULT");
        headerLabel.setFont(new Font("Segoe UI", Font.BOLD, 20));
        headerLabel.setForeground(themeColor);
        headerLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
        resultPanel.add(headerLabel);
        resultPanel.add(Box.createRigidArea(new Dimension(0, 20)));
        
        JPanel scoreCard = new JPanel(new GridLayout(5, 2, 10, 10));
        scoreCard.setBackground(new Color(40, 40, 40));
        scoreCard.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(new Color(60, 60, 60)),
            BorderFactory.createEmptyBorder(15, 15, 15, 15)
        ));
        
        addScoreRow(scoreCard, "👤 Student:", currentUsername);
        addScoreRow(scoreCard, "📝 Total Questions:", String.valueOf(questionsList.size()));
        addScoreRow(scoreCard, "✅ Correct Answers:", String.valueOf(score));
        addScoreRow(scoreCard, "❌ Wrong Answers:", String.valueOf(questionsList.size() - score));
        addScoreRow(scoreCard, "📈 Percentage:", String.format("%.2f%%", percentage));
        addScoreRow(scoreCard, "🎓 Grade:", grade);
        
        resultPanel.add(scoreCard);
        
        JOptionPane.showMessageDialog(this, resultPanel, "🎉 Exam Result 🎉", 
                                      JOptionPane.PLAIN_MESSAGE);
    }
    
    private void addScoreRow(JPanel panel, String label, String value) {
        JLabel labelComp = new JLabel(label);
        labelComp.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        labelComp.setForeground(textColor);
        JLabel valueComp = new JLabel(value);
        valueComp.setFont(new Font("Segoe UI", Font.BOLD, 13));
        valueComp.setForeground(themeColor);
        panel.add(labelComp);
        panel.add(valueComp);
    }
    
    private void startTimer() {
        timer = new Timer();
        timer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                if (timeLeft > 0 && !examCompleted) {
                    timeLeft--;
                    updateTimerDisplay();
                    
                    if (timeLeft == 0) {
                        SwingUtilities.invokeLater(() -> {
                            JOptionPane.showMessageDialog(OnlineExamSystem.this, 
                                "⏰ Time's up! Submitting your exam automatically.", 
                                "Time Out", JOptionPane.WARNING_MESSAGE);
                            showResult();
                        });
                    }
                }
            }
        }, 1000, 1000);
    }
    
    private void updateTimerDisplay() {
        int minutes = timeLeft / 60;
        int seconds = timeLeft % 60;
        String timeString = String.format("⏱️ Time Left: %02d:%02d", minutes, seconds);
        
        if (timeLeft <= 60) {
            timerLabel.setForeground(new Color(255, 100, 100));
            timerLabel.setFont(new Font("Segoe UI", Font.BOLD, 22));
        } else if (timeLeft <= 120) {
            timerLabel.setForeground(new Color(255, 200, 100));
        } else {
            timerLabel.setForeground(Color.WHITE);
        }
        
        timerLabel.setText(timeString);
    }
    
    private void restartExam() {
        int confirm = JOptionPane.showConfirmDialog(this, 
            "🔄 Are you sure you want to restart the exam? All progress will be lost.",
            "Restart Exam", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
        
        if (confirm == JOptionPane.YES_OPTION) {
            currentQuestion = 0;
            score = 0;
            timeLeft = 300;
            examCompleted = false;
            
            userAnswers = new int[questionsList.size()];
            for (int i = 0; i < userAnswers.length; i++) {
                userAnswers[i] = -1;
            }
            
            if (timer != null) {
                timer.cancel();
            }
            startTime = System.currentTimeMillis();
            startTimer();
            
            prevButton.setEnabled(false);
            nextButton.setEnabled(true);
            resultButton.setEnabled(true);
            restartButton.setEnabled(false);
            
            loadQuestion();
            timerLabel.setForeground(Color.WHITE);
            updateTimerDisplay();
            
            JOptionPane.showMessageDialog(this, "✨ Exam restarted! Good luck! ✨", 
                                        "Restarted", JOptionPane.INFORMATION_MESSAGE);
        }
    }
    
    @Override
    public void actionPerformed(ActionEvent e) {
        if (e.getSource() == nextButton) {
            saveCurrentAnswer();
            
            if (currentQuestion < questionsList.size() - 1) {
                currentQuestion++;
                loadQuestion();
            } else {
                int confirm = JOptionPane.showConfirmDialog(this, 
                    "📝 Are you ready to submit your exam?", 
                    "Submit", JOptionPane.YES_NO_OPTION);
                if (confirm == JOptionPane.YES_OPTION) {
                    showResult();
                }
            }
        } 
        else if (e.getSource() == prevButton) {
            saveCurrentAnswer();
            if (currentQuestion > 0) {
                currentQuestion--;
                loadQuestion();
            }
        }
        else if (e.getSource() == resultButton) {
            int confirm = JOptionPane.showConfirmDialog(this, 
                "📝 Are you sure you want to submit the exam?", 
                "Submit Exam", JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE);
            
            if (confirm == JOptionPane.YES_OPTION) {
                showResult();
            }
        }
        else if (e.getSource() == restartButton) {
            restartExam();
        }
    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            new OnlineExamSystem();
        });
    }
}




import java.sql.*;

public class TestDB {
    public static void main(String[] args) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/exam_system", "root", "Ilim@123");
            System.out.println("Connected successfully!");
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
