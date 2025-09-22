-- Supabase Database Migrations for iOS App Template
-- Run these SQL commands in your Supabase SQL Editor

-- =====================================================
-- TABLE CREATION
-- =====================================================

-- User segment table for personalized onboarding
CREATE TABLE IF NOT EXISTS user_segment (
  id SERIAL PRIMARY KEY,
  user_property TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT,
  button_text TEXT NOT NULL,
  next_id INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Survey questions table
CREATE TABLE IF NOT EXISTS survey_questions (
  id SERIAL PRIMARY KEY,
  survey_id INTEGER NOT NULL,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL DEFAULT 'text',
  options JSONB,
  required BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Survey responses table
CREATE TABLE IF NOT EXISTS survey_responses (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  survey_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  response_value TEXT,
  response_metadata JSONB,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT,
  user_property TEXT DEFAULT 'beginner',
  subscription_status TEXT DEFAULT 'free',
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable Row Level Security
ALTER TABLE user_segment ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Allow read access to onboarding screens for authenticated users
DROP POLICY IF EXISTS "Users can read onboarding screens" ON user_segment;
CREATE POLICY "Users can read onboarding screens" ON user_segment
  FOR SELECT
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

-- Users can only see their own survey responses
DROP POLICY IF EXISTS "Users can manage their own responses" ON survey_responses;
CREATE POLICY "Users can manage their own responses" ON survey_responses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own responses" ON survey_responses
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own responses" ON survey_responses
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own responses" ON survey_responses
  FOR DELETE
  USING (auth.uid() = user_id);

-- Users can only manage their own profiles
DROP POLICY IF EXISTS "Users can manage their own profiles" ON user_profiles;
CREATE POLICY "Users can manage their own profiles" ON user_profiles
  FOR ALL
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can select own profile" ON user_profiles;
CREATE POLICY "Users can select own profile" ON user_profiles
  FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow read access to survey questions
DROP POLICY IF EXISTS "Users can read survey questions" ON survey_questions;
CREATE POLICY "Users can read survey questions" ON survey_questions
  FOR SELECT
  USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert sample onboarding screens for beginners
INSERT INTO user_segment (user_property, title, description, image_url, button_text, next_id) VALUES
('beginner', 'Welcome to the App', 'Get started with your personalized experience. We''ll guide you through the key features.', NULL, 'Get Started', 2),
('beginner', 'Explore Features', 'Discover powerful tools designed to help you achieve your goals efficiently.', NULL, 'Continue', 3),
('beginner', 'Ready to Begin', 'You''re all set! Start using the app and enjoy your experience.', NULL, 'Let''s Go', NULL)
ON CONFLICT (id) DO NOTHING;

-- Insert sample survey questions (survey_id = 1)
INSERT INTO survey_questions (survey_id, question_text, question_type, options, required) VALUES
(1, 'What is your primary goal with this app?', 'single_choice',
 '["Learn new skills", "Track progress", "Connect with others", "Other"]'::jsonb, true),
(1, 'How often do you plan to use this app?', 'single_choice',
 '["Daily", "Weekly", "Monthly", "Occasionally"]'::jsonb, true),
(1, 'What features are most important to you?', 'multiple_choice',
 '["Personalized content", "Progress tracking", "Community features", "Offline access"]'::jsonb, false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_user_segment_user_property ON user_segment(user_property);
CREATE INDEX IF NOT EXISTS idx_survey_questions_survey_id ON survey_questions(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_responses_user_id ON survey_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_survey_responses_survey_id ON survey_responses(survey_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_property ON user_profiles(user_property);

-- ADD: Ensure is_premium column exists on user_profiles (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'is_premium'
  ) THEN
    ALTER TABLE public.user_profiles
    ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;
  END IF;
END$$;

-- ADD: index for is_premium lookups (safe if already exists)
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_premium ON public.user_profiles(is_premium);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update user profile timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for user onboarding progress
CREATE OR REPLACE VIEW user_onboarding_progress AS
SELECT
    up.id as user_id,
    up.user_property,
    up.subscription_status,
    COUNT(sr.id) as survey_responses_count,
    MAX(sr.submitted_at) as last_survey_response
FROM user_profiles up
LEFT JOIN survey_responses sr ON up.id = sr.user_id
GROUP BY up.id, up.user_property, up.subscription_status;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify table creation
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE tablename IN ('user_segment', 'survey_questions', 'survey_responses', 'user_profiles')
    AND schemaname = 'public';

-- Verify RLS is enabled
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename IN ('user_segment', 'survey_questions', 'survey_responses', 'user_profiles')
    AND schemaname = 'public';

-- Verify sample data
SELECT
    user_property,
    COUNT(*) as screen_count
FROM user_segment
GROUP BY user_property;

-- Verify policies
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename IN ('user_segment', 'survey_questions', 'survey_responses', 'user_profiles')
ORDER BY tablename, policyname;