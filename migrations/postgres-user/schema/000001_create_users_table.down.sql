-- Drop indexes
DROP INDEX IF EXISTS idx_user_profiles_user_id;
DROP INDEX IF EXISTS idx_users_is_active;
DROP INDEX IF EXISTS idx_users_email;
DROP INDEX IF EXISTS idx_users_username;

-- Drop tables
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS users;
