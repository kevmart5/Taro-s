# Taro's Garage — Jarvis MVP

Database schema and seed data for Jarvis, the garage management assistant for Taro's Garage, built on Supabase (Postgres).

## Contents

- `jarvis-schema-setup.sql` — creates the core tables (`customers`, `cars`, `repairs`, `price_list`), an audit log with triggers, and the `jarvis_agent` role with Row Level Security policies.
- `jarvis-seed-data.sql` — sample data (5 customers, 7 cars, 8 price list entries, 12 repairs) for testing the schema.

## Setup

1. Open the **Supabase SQL Editor** for your project.
2. Before running the schema script, edit `jarvis-schema-setup.sql` and replace `CHANGE_THIS_PASSWORD` with a strong password for the `jarvis_agent` role (or adapt that section to however your Supabase plugin/connector authenticates).
3. Run `jarvis-schema-setup.sql` in full, in order. It creates, in sequence:
   - the 4 operational tables
   - the audit log table and triggers (optional traceability layer)
   - the `jarvis_agent` role, grants, and RLS policies
4. (Optional) Run `jarvis-seed-data.sql` to load sample data for testing. It's idempotent (`ON CONFLICT DO NOTHING`) and safe to re-run.
5. Confirm that whatever client/plugin connects as `jarvis_agent` can authenticate with the password set in step 2.

## Security notes

- `jarvis_agent` only has `SELECT`/`INSERT` on the 4 operational tables — no `UPDATE`/`DELETE`, and no access at all to `jarvis_audit_log`.
- RLS is enabled on all 4 operational tables, with open `SELECT`/`INSERT` policies scoped to the `jarvis_agent` role.
