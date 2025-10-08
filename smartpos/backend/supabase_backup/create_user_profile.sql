-- Create a function to handle profile creation
create or replace function public.create_user_profile(
  user_id uuid,
  user_username text,
  user_phone text,
  user_shop_name text,
  user_language text
) returns json
language plpgsql
security definer -- This makes the function run with the privileges of the creator
set search_path = public -- This prevents search_path attacks
as $$
begin
  -- First, check if a profile already exists for this user
  if exists (select 1 from public.profiles where id = user_id) then
    return json_build_object(
      'success', false,
      'message', 'Profile already exists'
    );
  end if;

  -- Insert the new profile
  insert into public.profiles (
    id,
    username,
    phone,
    shop_name,
    language_preference,
    created_at,
    updated_at
  ) values (
    user_id,
    user_username,
    user_phone,
    user_shop_name,
    user_language,
    now(),
    now()
  );

  return json_build_object(
    'success', true,
    'message', 'Profile created successfully'
  );
exception
  when others then
    return json_build_object(
      'success', false,
      'message', SQLERRM
    );
end;
$$;
