-- Cole isto no Supabase: SQL Editor > New query > Run
create table if not exists public.docs (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind text not null,
  data jsonb not null default '{}',
  updated_at timestamptz not null default now(),
  deleted boolean not null default false,
  synced_at timestamptz not null default now()
);
create index if not exists docs_user_synced on public.docs (user_id, synced_at);

create or replace function public.docs_touch() returns trigger
language plpgsql as $$ begin new.synced_at = now(); return new; end $$;
drop trigger if exists docs_touch on public.docs;
create trigger docs_touch before insert or update on public.docs
for each row execute function public.docs_touch();

alter table public.docs enable row level security;
drop policy if exists docs_own on public.docs;
create policy docs_own on public.docs for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
revoke all on public.docs from anon;
