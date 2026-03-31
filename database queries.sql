-- Create database
CREATE DATABASE IF NOT EXISTS exam_system;
USE exam_system;

-- Table for storing users/students
CREATE TABLE IF NOT EXISTS users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    full_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for storing exam attempts/results
CREATE TABLE IF NOT EXISTS exam_results (
    result_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    exam_name VARCHAR(100) DEFAULT 'Java Programming Exam',
    score INT NOT NULL,
    total_questions INT NOT NULL,
    percentage DECIMAL(5,2) NOT NULL,
    grade VARCHAR(10),
    time_taken INT, -- in seconds
    attempt_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Table for storing detailed answers
CREATE TABLE IF NOT EXISTS user_answers (
    answer_id INT PRIMARY KEY AUTO_INCREMENT,
    result_id INT NOT NULL,
    question_number INT NOT NULL,
    question_text TEXT,
    selected_answer INT,
    correct_answer INT,
    is_correct BOOLEAN,
    FOREIGN KEY (result_id) REFERENCES exam_results(result_id) ON DELETE CASCADE
);

-- Table for questions (dynamic questions management)
CREATE TABLE IF NOT EXISTS questions_bank (
    question_id INT PRIMARY KEY AUTO_INCREMENT,
    question_text TEXT NOT NULL,
    option1 VARCHAR(255) NOT NULL,
    option2 VARCHAR(255) NOT NULL,
    option3 VARCHAR(255) NOT NULL,
    option4 VARCHAR(255) NOT NULL,
    correct_option INT NOT NULL, -- 0-based index
    difficulty VARCHAR(20) DEFAULT 'Medium',
    category VARCHAR(50) DEFAULT 'Java',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample questions into questions_bank
INSERT INTO questions_bank (question_text, option1, option2, option3, option4, correct_option, difficulty, category) VALUES
('Java is developed by?', 'Microsoft', 'Sun Microsystems', 'Google', 'Apple', 1, 'Easy', 'Java'),
('Which keyword is used for inheritance?', 'this', 'super', 'extends', 'implements', 2, 'Easy', 'Java'),
('Which is not a data type in Java?', 'int', 'float', 'boolean', 'real', 3, 'Easy', 'Java'),
('Which method is the entry point of a Java program?', 'start()', 'main()', 'run()', 'init()', 1, 'Easy', 'Java'),
('Which is an OOP concept?', 'Loop', 'Array', 'Encapsulation', 'Pointer', 2, 'Medium', 'OOP'),
('What does JVM stand for?', 'Java Visual Machine', 'Java Virtual Machine', 'Java Variable Method', 'Java Verified Machine', 1, 'Easy', 'Java'),
('Which keyword is used to create an object?', 'new', 'create', 'object', 'instance', 0, 'Easy', 'Java'),
('What is the size of int in Java?', '2 bytes', '4 bytes', '8 bytes', '1 byte', 1, 'Medium', 'Java'),
('Which access modifier provides the highest level of visibility?', 'private', 'protected', 'public', 'default', 2, 'Medium', 'Java'),
('What is the default value of a boolean variable?', 'true', 'false', '0', 'null', 1, 'Easy', 'Java');

-- Insert a test user (password: password123)
INSERT INTO users (username, password, email, full_name) VALUES 
('student1', 'password123', 'student1@example.com', 'John Doe');

-- Create index for better performance
CREATE INDEX idx_user_attempts ON exam_results(user_id, attempt_date);
CREATE INDEX idx_question_category ON questions_bank(category);