-- Insert test users (passwords are hashed 'password123')
INSERT INTO users (username, email, password_hash, full_name, phone, is_verified) VALUES
    ('admin', 'admin@example.com', '$2a$10$YourHashedPasswordHere', 'Admin User', '+1234567890', true),
    ('john_doe', 'john@example.com', '$2a$10$YourHashedPasswordHere', 'John Doe', '+1234567891', true),
    ('jane_smith', 'jane@example.com', '$2a$10$YourHashedPasswordHere', 'Jane Smith', '+1234567892', true),
    ('bob_wilson', 'bob@example.com', '$2a$10$YourHashedPasswordHere', 'Bob Wilson', '+1234567893', false)
ON CONFLICT (username) DO NOTHING;

-- Insert user profiles
INSERT INTO user_profiles (user_id, bio, city, country) 
SELECT id, 
       'Software developer and tech enthusiast', 
       'San Francisco', 
       'USA'
FROM users WHERE username = 'john_doe'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_profiles (user_id, bio, city, country) 
SELECT id, 
       'Product designer and creative thinker', 
       'New York', 
       'USA'
FROM users WHERE username = 'jane_smith'
ON CONFLICT (user_id) DO NOTHING;
