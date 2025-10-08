-- Quick Database Migration Script
-- Run this in Supabase SQL Editor to fix the schema issues

-- First, check what tables currently exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check current profiles table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles';

-- Now run the full setup from supabase_setup.sql
-- This will drop and recreate all tables with the correct schema

-- After running the main setup, verify the new structure
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'shops', 'user_sessions');

-- Check new profiles table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles';