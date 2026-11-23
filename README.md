# Campus Connect — The campus that thinks

Goa Buildathon 2027 prototype. An intelligent campus ecosystem that turns needs, talent, resources and opportunities into action.

**Live site:** https://anup031006-sketch.github.io/campus-connect/

## What it does

| Engine | What works |
| --- | --- |
| AI Campus Brain | Assistant that answers from verified campus data, finds teammates and opportunities, drafts a project plan (you approve) and prepares issue reports |
| Talent Graph | Opt-in profiles; transparent matching: 55% skills, 20% interests, 15% availability, 10% diversity |
| Campus Digital Twin | Map of buildings, this week's events and open issues; report a problem where it happens |
| Opportunity Engine | Ranked, eligibility-filtered feed with a "why you" reason and saves |
| Campus Pulse | Duplicate reports grouped, rule-based priority, routing, staff workflow, live updates and notifications |
| Analytics | Reports by category and location, resolution time, plain-language insight |

## Try it

Open the live site → **Try the live demo** → **Try as Student** (or **Try as Campus Staff** in a second window).

| Account | Email | Password |
| --- | --- | --- |
| Student | student@demo.app | CampusDemo#2027 |
| Staff | staff@demo.app | CampusDemo#2027 |

All students, opportunities and campus facts are demo data.

## How it's built

- **Frontend:** one `index.html` (Tailwind CSS, Leaflet + OpenStreetMap), hosted on GitHub Pages
- **Backend:** Supabase: Postgres with Row Level Security, database functions for every write, Realtime, and an Edge Function (`ai-chat`) that calls Google Gemini
- **Database schema:** `supabase/schema.sql`

The Supabase key in `index.html` is the public *publishable* key. It is safe to share: Row Level Security and the database functions control what each logged-in user can read and change.
