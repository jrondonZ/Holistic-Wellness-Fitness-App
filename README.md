# Holistic Chart

A state-of-the-art **holistic health record** for [Holistic Wellness Fitness LLC](https://www.instagram.com/holisticwellnessfitnessllc) — think Epic / MyChart, reimagined for whole-self wellness, gut healing and sustainable strength.

Members get one living "chart" that brings their habits together the way a great clinician keeps everything in one record: a patient-style banner, vitals flowsheets, trend charts, and a curated library to learn and move.

> Built on the same Rails 8 foundation as `Final_Project_COM214`, styled in the Holistic Wellness Fitness brand palette.

## The four pillars

| Module | What it does |
| --- | --- |
| 🧘 **Wellness** | Daily check-ins (mood, energy, stress, sleep, water, weight, blood pressure, resting HR) rendered as a vitals **flowsheet** with a composite wellness score. |
| 🥗 **Diet** | A nutrition log with per-meal macros, automatic daily calorie/macro totals, a personalized calorie target (Mifflin–St Jeor) and a 7-day calorie sparkline. |
| 🏋️ **Fitness** | A logged activity history plus a **video library** of real follow-along workouts and multi-week **routines** that string sessions together. |
| 📚 **Education** | Grounded articles on gut health, movement, mindfulness, sleep, nutrition and sea moss. |

The **Chart Summary** dashboard ties it all together: a patient banner (member ID, age, goals, BMI, BP, streak), snapshot stat cards, Chart.js trend graphs, a recent-vitals flowsheet, activity timeline, and personalized recommendations.

## Tech stack

- **Ruby** 3.3.6, **Rails** 8.1
- **Propshaft** asset pipeline + **import maps** (no Node build step)
- **Hotwire** (Turbo + Stimulus); **Chart.js** for trends (loaded via import map)
- **Bootstrap 5.3** + **Font Awesome 6** (CDN) layered with a custom brand design system
- `has_secure_password` (**bcrypt**) authentication
- **SQLite** in development/test, **PostgreSQL** in production
- Quality gates: **RuboCop** (omakase), **Brakeman**, Minitest

## Getting started

```bash
bin/setup            # installs gems, prepares the DB, seeds, and starts the server
# or manually:
bundle install
bin/rails db:prepare # create + migrate + seed
bin/rails server     # http://localhost:3000
```

### Demo account

The seeds create a fully-populated member so the chart is alive on first run:

```
username: demo
password: wellness
```

…with ~30 days of check-ins, two weeks of meals and a month of workouts, so every chart and flowsheet has real data.

## Tests & checks

```bash
bin/rails test   # model unit tests
bin/rubocop      # style
bin/brakeman     # security static analysis
```

## Deployment

- **Render** — `render.yaml` is a ready Blueprint (web service + Postgres). It builds assets, migrates and seeds automatically.
- **Docker / Kamal** — a production `Dockerfile` is included (`bin/kamal` for Kamal deploys).

Set `SECRET_KEY_BASE` and `DATABASE_URL` in the production environment (Render's blueprint wires these up for you).

## Design

The palette mirrors the Holistic Wellness Fitness brand site:

| Token | Value |
| --- | --- |
| Brand green | `#4a7c59` |
| Brand green (dark) | `#2d4a30` |
| Cream | `#fdfbf7` |
| Gold | `#c9a96e` |
| Sage | `#a3b18a` |

Typeface: **Inter**. The original brand photography lives in `app/assets/images/brand/`.

---

© Holistic Wellness Fitness LLC · 177 State Street, Meriden, CT 06450
