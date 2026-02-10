-- Sprint 21 Phase 5: Account Deletion RPC
-- Run this in Supabase SQL Editor before deploying
--
-- This function allows authenticated users to delete their own account.
-- Uses SECURITY DEFINER to access auth.users (which requires elevated privileges).
-- CASCADE constraints on families/family_members/babies/activities handle data cleanup.

create or replace function delete_own_account()
returns void as $$
begin
  -- Delete the authenticated user's auth record
  -- CASCADE will handle: families, family_members, babies, activities, family_invites
  delete from auth.users where id = auth.uid();
end;
$$ language plpgsql security definer;
