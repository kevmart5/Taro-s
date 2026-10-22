# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Database layer for **Jarvis**, an AI assistant for Taro's Garage (a small auto shop in Costa Rica). There is no application code — this repo is entirely SQL (Postgres on Supabase) plus Spanish-language spec/setup docs. The "agent" itself is a ChatGPT Project with custom instructions, connected to this database via the official Supabase plugin (MCP-based); it is configured in ChatGPT, not in this repo.

No build, lint, or test commands exist. The only "run" step is pasting `.sql` files into the Supabase SQL Editor, in order.

## File map

- `jarvis-schema-setup.sql` — the entire schema: tables, audit log + triggers, `jarvis_agent` role + RLS policies, and views. Idempotent (`create table/view if not exists`/`or replace`, `drop policy if exists` before `create policy`) — safe to re-run.
- `jarvis-seed-data.sql` — fixed-UUID sample data (5 customers, 7 cars, 8 price_list entries, 12 repairs), `on conflict do nothing` so re-running is safe. Does not include sample `expenses` rows (added after the seed file was written).
- `jarvis-mvp-spec.md` — original MVP spec (Spanish), includes the agent's first-draft system instructions and the rationale for the security model. Partially superseded by the setup guide (e.g. `expenses` table and extra views postdate this doc).
- `jarvis-setup-guide.md` — step-by-step, idempotent-assumption-free setup walkthrough (Spanish), including the **current** agent system instructions to paste into the ChatGPT Project. Treat this as the source of truth over the spec when they disagree.
- `README.md` — short English summary of contents/setup/security notes.

## Schema architecture

5 operational tables, all in the public schema:

- `customers` → `cars` (FK `cars.customer_id`, `on delete restrict`) → `repairs` (FK `repairs.car_id`, `on delete restrict`)
- `price_list` — standalone, not FK'd to anything (it's a catalog, not a ledger)
- `expenses` — optionally FK'd to `repairs` via nullable `repair_id` (`on delete set null`); parts/labor expenses link to a repair, operational expenses (rent, utilities) leave it null

`on delete restrict` on the customer→car and car→repair FKs is deliberate: nothing in this schema ever deletes rows (see Security model below), so this is a backstop, not an active concern.

A separate `jarvis_audit_log` table (append-only, `table_name` + `inserted_data jsonb` + `created_at`) is populated by `AFTER INSERT` triggers on all 5 operational tables. `jarvis_agent` has zero grants on it — it's for human review only.

### Views exist to dodge ChatGPT's tool-call safety checks, not for normal SQL reasons

This is the one piece of non-obvious context in the repo. Jarvis writing its own multi-table JOIN (customers + cars + repairs) gets blocked by ChatGPT's safety checks with the error *"This tool call was blocked by OpenAI's safety checks"* — this is **not** an RLS or grants problem (those were confirmed working directly). The fix is giving Jarvis a single view to query instead of a JOIN it writes itself:

- `customer_cars` — one row per car, no repair fan-out (for "what cars does this customer have")
- `car_latest_repair` — one row per car, most recent repair only (`select distinct on (ca.id) ... order by ca.id, r.repair_date desc, r.created_at desc`); uses an inner join on purpose, so a car with no repairs doesn't appear
- `customer_car_history` — full fan-out, one row per repair, for date-range/history questions
- `monthly_profit` — revenue (`sum(repairs.cost)`) vs `sum(expenses.amount)` per month, combined with a `full outer join` on month so a month with only expenses or only revenue doesn't get dropped
- `monthly_expenses_by_category` — expenses grouped by month + category

**Every view must have `with (security_invoker = true)`.** Without it, the view runs with the privileges of whoever created it (the owner), silently bypassing `jarvis_agent`'s RLS policies instead of enforcing them. This is the single easiest thing to get wrong when adding a new view.

When adding a new cross-table query Jarvis needs, add a view rather than relying on the agent to write its own JOIN/aggregation — and update the agent instructions block in `jarvis-setup-guide.md` (Paso 5) to tell it which view to use for that question shape.

## Security model (two independent layers, both load-bearing)

1. **Postgres GRANTs** on `jarvis_agent`: `SELECT, INSERT` only, on the 5 operational tables — no `UPDATE`/`DELETE`, no access to `jarvis_audit_log` at all. This is a hard floor: even a broken RLS policy can't exceed it.
2. **RLS**, enabled on all 5 operational tables, with open `USING (true)` SELECT and `WITH CHECK (true)` INSERT policies scoped to `jarvis_agent`. No UPDATE/DELETE policies exist for that role, so those ops are blocked by RLS too, independent of the GRANTs.

Both layers only restrict the literal Postgres role `jarvis_agent`. Per `jarvis-setup-guide.md`'s closing notes, the ChatGPT Supabase plugin may actually connect using the owner-authenticated Supabase account from setup, **not** this dedicated role — in which case the real protection against destructive writes today is that the agent was simply never instructed to delete/update, not the database-level grants. Keep that distinction in mind: don't assume `jarvis_agent`'s restrictions are being enforced in production until that's verified against whatever the plugin actually authenticates as.

If you add a new table that Jarvis should read/write, replicate exactly this pattern: grant only `SELECT, INSERT` to `jarvis_agent`, enable RLS, add matching open SELECT/INSERT policies for that role, and add an `AFTER INSERT` audit trigger calling `log_jarvis_audit()`.

## Conventions

- All identifiers and SQL comments: English. All spec/setup prose: Spanish (this is a Costa Rican shop; money is always ₡/colones).
- Every table/view-creating statement uses `if not exists` / `or replace`, and every policy creation is preceded by `drop policy if exists` — scripts must stay safe to re-run wholesale.
- `jarvis-schema-setup.sql` is organized in 5 numbered parts (tables → audit → role/RLS → JOIN-avoidance views → monthly_profit views) with a header comment explaining why each part exists — keep new additions inside the matching part, or add a new numbered part, rather than scattering `create` statements.
