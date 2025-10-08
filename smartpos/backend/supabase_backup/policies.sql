-- Enable RLS
alter table profiles enable row level security;

-- Clear existing policies
drop policy if exists "Users can read own profile" on profiles;
drop policy if exists "Users can update own profile" on profiles;
drop policy if exists "Enable insert for authenticated users only" on profiles;

-- Create new policies
create policy "Enable insert for registration"
on profiles for insert
with check (auth.uid() = id);

create policy "Enable read access for users"
on profiles for select
using (auth.uid() = id);

create policy "Enable update for users based on id"
on profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);
