-- ============================================================================
-- Jarvis MVP — Table schema + security (dedicated role + RLS)
-- Taro's Garage
-- Generated: 2026-10-21
-- Convention: table and column names, and all comments, in English.
--
-- Run this whole script in the Supabase SQL Editor, in the order it appears.
-- It's split into 3 parts:
--   1) Tables (customers, cars, repairs, price_list)
--   2) Audit log (table + triggers) — optional layer from the spec, section 6
--   3) jarvis_agent role + RLS policies — layers 1 and 2 from the spec, section 6
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) TABLES
-- ----------------------------------------------------------------------------

create extension if not exists pgcrypto;

create table if not exists customers (
    id          uuid primary key default gen_random_uuid(),
    name        text not null,
    phone       text not null unique,
    email       text,
    created_at  timestamptz not null default now()
);

create table if not exists cars (
    id              uuid primary key default gen_random_uuid(),
    customer_id     uuid not null references customers(id) on delete restrict,
    make            text not null,
    model           text not null,
    year            int,
    license_plate   text not null unique,
    created_at      timestamptz not null default now()
);

create index if not exists idx_cars_customer_id on cars(customer_id);

create table if not exists repairs (
    id              uuid primary key default gen_random_uuid(),
    car_id          uuid not null references cars(id) on delete restrict,
    repair_date     date not null default current_date,
    work_performed  text not null,
    cost            numeric(12,2) not null check (cost >= 0),
    mileage         int check (mileage >= 0),
    notes           text,
    created_at      timestamptz not null default now()
);

create index if not exists idx_repairs_car_id on repairs(car_id);
create index if not exists idx_repairs_repair_date on repairs(repair_date);

create table if not exists price_list (
    id              uuid primary key default gen_random_uuid(),
    job_name        text not null,
    price           numeric(12,2) not null check (price >= 0),
    category        text check (category in ('recurring', 'new')),
    notes           text,
    updated_at      timestamptz not null default now()
);

-- Keeps updated_at current on every UPDATE (only relevant if a more
-- privileged role gets UPDATE in the future; jarvis_agent won't have it).
create or replace function set_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists trg_price_list_updated_at on price_list;
create trigger trg_price_list_updated_at
    before update on price_list
    for each row
    execute function set_updated_at();

-- ----------------------------------------------------------------------------
-- 2) AUDIT LOG (optional layer, spec section 6)
-- ----------------------------------------------------------------------------

create table if not exists jarvis_audit_log (
    id              uuid primary key default gen_random_uuid(),
    table_name      text not null,
    inserted_data   jsonb not null,
    created_at      timestamptz not null default now()
);

create or replace function log_jarvis_audit()
returns trigger as $$
begin
    insert into jarvis_audit_log (table_name, inserted_data)
    values (TG_TABLE_NAME, to_jsonb(new));
    return new;
end;
$$ language plpgsql;

drop trigger if exists trg_audit_customers on customers;
create trigger trg_audit_customers
    after insert on customers
    for each row execute function log_jarvis_audit();

drop trigger if exists trg_audit_cars on cars;
create trigger trg_audit_cars
    after insert on cars
    for each row execute function log_jarvis_audit();

drop trigger if exists trg_audit_repairs on repairs;
create trigger trg_audit_repairs
    after insert on repairs
    for each row execute function log_jarvis_audit();

drop trigger if exists trg_audit_price_list on price_list;
create trigger trg_audit_price_list
    after insert on price_list
    for each row execute function log_jarvis_audit();

-- ----------------------------------------------------------------------------
-- 3) DEDICATED ROLE + ROW LEVEL SECURITY (layers 1 and 2, spec section 6)
-- ----------------------------------------------------------------------------

-- Layer 1: a dedicated login role for the Supabase plugin.
-- Replace 'CHANGE_THIS_PASSWORD' with a strong password before running this,
-- or drop the LOGIN/PASSWORD clause and set up access however the plugin's
-- setup requires (e.g. a connector API key).
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'jarvis_agent') then
        create role jarvis_agent login password 'CHANGE_THIS_PASSWORD';
    end if;
end
$$;

grant select, insert on customers, cars, repairs, price_list to jarvis_agent;
-- Note: jarvis_agent gets NO permissions on jarvis_audit_log — that table is
-- for internal traceability only, not for the agent to read or write.

-- Layer 2: RLS enabled on the 4 operational tables.
alter table customers enable row level security;
alter table cars enable row level security;
alter table repairs enable row level security;
alter table price_list enable row level security;

-- Open SELECT for jarvis_agent on all 4 tables.
drop policy if exists jarvis_select_customers on customers;
create policy jarvis_select_customers on customers
    for select to jarvis_agent using (true);

drop policy if exists jarvis_select_cars on cars;
create policy jarvis_select_cars on cars
    for select to jarvis_agent using (true);

drop policy if exists jarvis_select_repairs on repairs;
create policy jarvis_select_repairs on repairs
    for select to jarvis_agent using (true);

drop policy if exists jarvis_select_price_list on price_list;
create policy jarvis_select_price_list on price_list
    for select to jarvis_agent using (true);

-- Open INSERT for jarvis_agent on all 4 tables.
drop policy if exists jarvis_insert_customers on customers;
create policy jarvis_insert_customers on customers
    for insert to jarvis_agent with check (true);

drop policy if exists jarvis_insert_cars on cars;
create policy jarvis_insert_cars on cars
    for insert to jarvis_agent with check (true);

drop policy if exists jarvis_insert_repairs on repairs;
create policy jarvis_insert_repairs on repairs
    for insert to jarvis_agent with check (true);

drop policy if exists jarvis_insert_price_list on price_list;
create policy jarvis_insert_price_list on price_list
    for insert to jarvis_agent with check (true);

-- No UPDATE/DELETE policies are created for jarvis_agent: since none exist,
-- those operations stay blocked both by RLS and by the Layer 1 GRANTs
-- (a hard floor at the database level).

-- ============================================================================
-- End of script.
-- Before running this against the real tables: change jarvis_agent's
-- password and confirm the Supabase plugin in ChatGPT can authenticate
-- with that role (or whatever API key it ends up using).
-- ============================================================================
