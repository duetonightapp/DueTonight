create table if not exists public.assignment_solutions (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null,
  assignment_id uuid not null,
  uploaded_by uuid not null,
  file_name text not null,
  file_url text not null,
  file_type text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.assignment_solutions enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'assignment_solutions'
      and policyname = 'Users can view assignment solutions in their room'
  ) then
    create policy "Users can view assignment solutions in their room"
      on public.assignment_solutions
      for select
      using (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'assignment_solutions'
      and policyname = 'Users can insert their own assignment solutions'
  ) then
    create policy "Users can insert their own assignment solutions"
      on public.assignment_solutions
      for insert
      with check (auth.uid() = uploaded_by);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'assignment_solutions'
      and policyname = 'Users can delete their own assignment solutions'
  ) then
    create policy "Users can delete their own assignment solutions"
      on public.assignment_solutions
      for delete
      using (auth.uid() = uploaded_by);
  end if;
end
$$;

create index if not exists assignment_solutions_assignment_id_idx
  on public.assignment_solutions (assignment_id);

create index if not exists assignment_solutions_room_id_idx
  on public.assignment_solutions (room_id);
