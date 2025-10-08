-- Enable RLS
alter table profiles enable row level security;

-- Remove existing policies
drop policy if exists "Users can read own profile" on profiles;
drop policy if exists "Users can update own profile" on profiles;
drop policy if exists "Enable insert for authenticated users only" on profiles;

-- Create a policy that allows anyone to insert a new profile
create policy "Enable insert for authenticated users"
on profiles for insert
with check (auth.uid() = id);

-- Create a policy that allows users to read their own profiles
create policy "Enable read for users"
on profiles for select
using (auth.uid() = id);

-- Create a policy that allows users to update their own profiles
create policy "Enable update for users"
on profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);
