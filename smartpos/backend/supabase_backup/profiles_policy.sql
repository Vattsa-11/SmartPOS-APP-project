-- First, enable RLS on the profiles table
alter table public.profiles enable row level security;

-- Drop any existing policies
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;

-- Create new policies

-- Allow users to insert their own profile only
create policy "Users can insert own profile"
on public.profiles
for insert
with check (
  auth.uid() = id
);

-- Allow users to view their own profile
create policy "Users can view own profile"
on public.profiles
for select
using (
  auth.uid() = id
);

-- Allow users to update their own profile
create policy "Users can update own profile"
on public.profiles
for update
using (
  auth.uid() = id
)
with check (
  auth.uid() = id
);

-- Allow checking for existing phone numbers during registration
create policy "Anyone can check phone numbers"
on public.profiles
for select
using (true);
