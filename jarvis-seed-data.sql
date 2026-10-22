-- ============================================================================
-- Jarvis MVP — Seed data
-- Taro's Garage
-- Generated: 2026-10-21
--
-- Sample data to test the schema from jarvis-schema-setup.sql: 5 customers,
-- 7 cars, 8 price_list entries, and 12 repair records.
-- Run this AFTER jarvis-schema-setup.sql has been run successfully.
--
-- Uses fixed UUIDs (instead of gen_random_uuid()) so the foreign keys below
-- are easy to follow and the script is idempotent via ON CONFLICT DO NOTHING
-- (safe to re-run without creating duplicates).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CUSTOMERS
-- ----------------------------------------------------------------------------

insert into customers (id, name, phone, email, created_at) values
    ('a0000000-0000-4000-8000-000000000001', 'María Fernández Rojas',  '8888-1234', 'maria.fernandez@gmail.com', now() - interval '120 days'),
    ('a0000000-0000-4000-8000-000000000002', 'Carlos Jiménez Solís',   '8777-5678', null,                        now() - interval '95 days'),
    ('a0000000-0000-4000-8000-000000000003', 'Ana Lucía Vargas',       '8666-9012', 'analu.vargas@hotmail.com',  now() - interval '70 days'),
    ('a0000000-0000-4000-8000-000000000004', 'Roberto Castro Mora',    '8555-3456', null,                        now() - interval '45 days'),
    ('a0000000-0000-4000-8000-000000000005', 'Gabriela Solano Pérez',  '8444-7890', 'gabriela.solano@outlook.com', now() - interval '20 days')
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- CARS
-- ----------------------------------------------------------------------------

insert into cars (id, customer_id, make, model, year, license_plate, created_at) values
    ('b0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Toyota',  'Corolla', 2018, '456789', now() - interval '120 days'),
    ('b0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'Honda',   'CR-V',    2020, '678901', now() - interval '100 days'),
    ('b0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000002', 'Hyundai', 'Tucson',  2019, '234567', now() - interval '95 days'),
    ('b0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000003', 'Nissan',  'Sentra',  2015, '890123', now() - interval '70 days'),
    ('b0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000004', 'Kia',     'Rio',     2021, '345678', now() - interval '45 days'),
    ('b0000000-0000-4000-8000-000000000006', 'a0000000-0000-4000-8000-000000000005', 'Toyota',  'Hilux',   2017, '567890', now() - interval '20 days'),
    ('b0000000-0000-4000-8000-000000000007', 'a0000000-0000-4000-8000-000000000005', 'Suzuki',  'Alto',    2016, '123456', now() - interval '18 days')
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- PRICE LIST
-- ----------------------------------------------------------------------------

insert into price_list (id, job_name, price, category, notes, updated_at) values
    ('c0000000-0000-4000-8000-000000000001', 'Cambio de aceite y filtro',     25000, 'recurring', 'Incluye aceite sintético 5W-30',        now() - interval '30 days'),
    ('c0000000-0000-4000-8000-000000000002', 'Pastillas de freno (par)',      45000, 'recurring', 'Precio por eje, mano de obra incluida', now() - interval '30 days'),
    ('c0000000-0000-4000-8000-000000000003', 'Afinamiento mayor',             85000, 'recurring', 'Bujías, filtros, revisión general',     now() - interval '30 days'),
    ('c0000000-0000-4000-8000-000000000004', 'Revisión de frenos',            15000, 'recurring', null,                                     now() - interval '30 days'),
    ('c0000000-0000-4000-8000-000000000005', 'Cambio de batería',             60000, 'new',       'Precio varía según tipo de batería',    now() - interval '30 days'),
    ('c0000000-0000-4000-8000-000000000006', 'Alineación y balanceo',         20000, 'recurring', null,                                     now() - interval '30 days'),
    ('c0000000-0000-4000-8000-000000000007', 'Cambio de filtro de aire',       8000, 'recurring', null,                                     now() - interval '30 days'),
    ('c0000000-0000-4000-8000-000000000008', 'Diagnóstico computarizado',     15000, 'new',       'Se abona al total si se hace la reparación', now() - interval '30 days')
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- REPAIRS
-- ----------------------------------------------------------------------------

insert into repairs (id, car_id, repair_date, work_performed, cost, mileage, notes, created_at) values
    ('d0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001', current_date - interval '110 days', 'Cambio de aceite y filtro',           25000, 68000,  null,                                  now() - interval '110 days'),
    ('d0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001', current_date - interval '45 days',  'Pastillas de freno delanteras',       45000, 72500,  'Cliente reportó chillido al frenar',  now() - interval '45 days'),
    ('d0000000-0000-4000-8000-000000000003', 'b0000000-0000-4000-8000-000000000002', current_date - interval '90 days',  'Afinamiento mayor',                   85000, 34000,  null,                                  now() - interval '90 days'),
    ('d0000000-0000-4000-8000-000000000004', 'b0000000-0000-4000-8000-000000000002', current_date - interval '15 days',  'Alineación y balanceo',               20000, 38200,  null,                                  now() - interval '15 days'),
    ('d0000000-0000-4000-8000-000000000005', 'b0000000-0000-4000-8000-000000000003', current_date - interval '80 days',  'Cambio de batería',                   62000, 95000,  'Batería no arrancaba en frío',        now() - interval '80 days'),
    ('d0000000-0000-4000-8000-000000000006', 'b0000000-0000-4000-8000-000000000003', current_date - interval '20 days',  'Cambio de aceite y filtro',           25000, 98500,  null,                                  now() - interval '20 days'),
    ('d0000000-0000-4000-8000-000000000007', 'b0000000-0000-4000-8000-000000000004', current_date - interval '65 days',  'Diagnóstico computarizado',           15000, 142000, 'Luz de check engine encendida',       now() - interval '65 days'),
    ('d0000000-0000-4000-8000-000000000008', 'b0000000-0000-4000-8000-000000000004', current_date - interval '60 days',  'Cambio de filtro de aire',             8000, 142300, null,                                  now() - interval '60 days'),
    ('d0000000-0000-4000-8000-000000000009', 'b0000000-0000-4000-8000-000000000005', current_date - interval '40 days',  'Revisión de frenos',                  15000, 21000,  'Todo en orden, sin cambios necesarios', now() - interval '40 days'),
    ('d0000000-0000-4000-8000-000000000010', 'b0000000-0000-4000-8000-000000000006', current_date - interval '18 days',  'Cambio de aceite y filtro',           25000, 58900,  null,                                  now() - interval '18 days'),
    ('d0000000-0000-4000-8000-000000000011', 'b0000000-0000-4000-8000-000000000006', current_date - interval '10 days',  'Pastillas de freno traseras',         45000, 59400,  null,                                  now() - interval '10 days'),
    ('d0000000-0000-4000-8000-000000000012', 'b0000000-0000-4000-8000-000000000007', current_date - interval '5 days',   'Afinamiento mayor',                   85000, 112000, 'Auto con mantenimiento atrasado',     now() - interval '5 days')
on conflict (id) do nothing;

-- ============================================================================
-- End of seed data.
-- Quick sanity checks after running:
--   select count(*) from customers;   -- expect 5
--   select count(*) from cars;        -- expect 7
--   select count(*) from price_list;  -- expect 8
--   select count(*) from repairs;     -- expect 12
-- ============================================================================
