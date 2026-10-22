-- ============================================================================
-- Jarvis MVP — Seed data
-- Taro's Garage
-- Generated: 2026-10-21
--
-- Sample data to test the schema from jarvis-schema-setup.sql: 1 customer,
-- 1 car, 15 price_list entries, and 0 repair records.
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
    ('a0000000-0000-4000-8000-000000000001', 'Kevin Martinez', '88937529', 'mkevin755@gmail.com', now())
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- CARS
-- ----------------------------------------------------------------------------

insert into cars (id, customer_id, make, model, year, license_plate, created_at) values
    ('b0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'MG', 'GS', 2017, 'FQM026', now())
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- PRICE LIST
-- ----------------------------------------------------------------------------
-- Transcribed from Taro's price notebook photo (2026-10-22). Only the items
-- with a legible price are included here. Items photographed without an
-- amount written in (cambio de links estabilizadora, cambio de faja de
-- accesorios, llevar/preparar para Dekra, diagnóstico electrónico y escaneo,
-- cambio de clutch sencillo/4x4, cambio de compensadores, cambio de rótula
-- de dirección) are left out — add them once Taro gives you their prices.
--
-- "Rectificación de tambores" price was partly obscured in the photo
-- (read as 12.000) — confirm with Taro before relying on it.
--
-- "Ajuste de cable de freno de mano" is a price RANGE (₡10.000–₡25.000):
-- price holds the minimum, price_max the maximum (see schema notes).
--
-- category is left null for all of these — Taro's notebook didn't distinguish
-- recurring vs. new/occasional jobs, so this needs a manual pass later.

insert into price_list (id, job_name, price, price_max, category, notes, updated_at) values
    ('c0000000-0000-4000-8000-000000000001', 'Cambio de coolant',                                         25000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000002', 'Cambio de aceite',                                           8000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000003', 'Revisión general',                                          25000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000004', 'Rectificación de tambores',                                 12000, null,  null, 'Monto parcialmente ilegible en la foto, confirmar con Taro', now()),
    ('c0000000-0000-4000-8000-000000000005', 'Rectificación de volante',                                  20000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000006', 'Reparación de caliper',                                     30000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000007', 'Cambio de discos',                                          15000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000008', 'Cambio de pastillas',                                       15000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000009', 'Cambio de zapatas',                                         30000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000010', 'Limpieza y ajuste de tambores',                             15000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000011', 'Cambio de aceite transmisión, transfer o diferencial',      12000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000012', 'Cambio de aceite transmisión automática',                   45000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000013', 'Escaneo avanzado',                                          25000, null,  null, null,                                   now()),
    ('c0000000-0000-4000-8000-000000000014', 'Ajuste de cable de freno de mano',                          10000, 25000, null, 'Precio en rango segun complejidad',   now()),
    ('c0000000-0000-4000-8000-000000000015', 'Cambio de bombas auxiliares',                               25000, null,  null, null,                                   now())
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- REPAIRS
-- ----------------------------------------------------------------------------
-- No sample repairs for now — the previous sample rows belonged to the
-- fictional customer/cars that were removed. Insert real repair records
-- for Kevin's MG GS (car_id 'b0000000-0000-4000-8000-000000000001') as they
-- happen, following the insert flow discussed earlier (repairs.cost = what
-- was charged, then a matching row in expenses if there was a real cost).

-- ============================================================================
-- End of seed data.
-- Quick sanity checks after running:
--   select count(*) from customers;   -- expect 1
--   select count(*) from cars;        -- expect 1
--   select count(*) from price_list;  -- expect 15
--   select count(*) from repairs;     -- expect 0
-- ============================================================================