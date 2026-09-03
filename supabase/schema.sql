-- Schéma Supabase pour le classement de Poor'íŋ Belé.
-- À exécuter une fois dans le SQL Editor du projet Supabase.
--
-- Étape complémentaire à faire dans le dashboard (pas possible en SQL) :
-- Authentication > Sign In / Providers > Email > désactiver "Confirm email",
-- pour que la création de compte soit immédiate (adapté aux enfants).

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null,
  last_name text not null,
  avatar_url text,
  points integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are readable by everyone"
  on public.profiles for select using (true);

create policy "users insert their own profile"
  on public.profiles for insert with check (auth.uid() = id);

create policy "users update their own profile"
  on public.profiles for update using (auth.uid() = id);

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "avatar images are publicly readable"
  on storage.objects for select using (bucket_id = 'avatars');

create policy "users upload their own avatar"
  on storage.objects for insert with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "users update their own avatar"
  on storage.objects for update using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
