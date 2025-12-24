-- Remove seeded user profiles
DELETE FROM user_profiles WHERE user_id IN (
    SELECT id FROM users WHERE username IN ('john_doe', 'jane_smith')
);

-- Remove seeded users
DELETE FROM users WHERE username IN ('admin', 'john_doe', 'jane_smith', 'bob_wilson');
