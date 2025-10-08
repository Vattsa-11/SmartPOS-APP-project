-- Enable RLS on the profiles table
alter table public.profiles enable row level security;

-- Allow users to read their own profile
create policy "Users can read own profile"
  on public.profiles for select
  using ( auth.uid() = id );

-- Allow the create_user_profile function to create profiles
create policy "create_user_profile function can create profiles"
  on public.profiles for insert
  using ( true )
  with check ( true );

-- Allow users to update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  using ( auth.uid() = id )
  with check ( auth.uid() = id );
