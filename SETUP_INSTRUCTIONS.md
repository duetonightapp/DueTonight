# Supabase Setup Instructions

## 1. Create Supabase Project
1. Go to https://supabase.com and create a new project
2. Note your **Project URL** and **anon/public key** from Settings > API

## 2. Configure Google OAuth Provider
1. In Supabase Dashboard, go to **Authentication > Providers > Google**
2. Enable Google provider
3. Enter your Google Cloud Console credentials:
   - **Client ID**
   - **Client Secret**

## 3. Update App Constants
Replace the placeholder values in `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
}
```

## 4. Create Database Tables

Run the following SQL in Supabase SQL Editor to create required tables:

```sql
-- Create profiles table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  batch_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for users to read their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Create policy for users to update their own profile
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Create policy to insert profile on user creation
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Trigger to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## 5. Configure Google Cloud Console
1. Go to https://console.cloud.google.com
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials (Web application)
5. Add authorized redirect URI: `https://<your-project>.supabase.co/auth/v1/callback`
6. Add Android authorized origins if needed

## 6. Android Setup
1. Download `google-services.json` from Google Cloud Console
2. Place it in `android/app/` directory
3. Configure package name: `com.college.due_tonight`
4. Add SHA-1 fingerprint of your signing key

For debug keystore:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```