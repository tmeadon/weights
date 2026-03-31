# Progress

## Current Status

Milestones 1 through 5 are now functionally in place, and Milestone 6 has started with initial difficulty calculations.

## Completed So Far

### Project Skeleton

- Rails 8 app scaffolded in the existing repository
- SQLite configured as the development database
- Base Rails structure, routes, test setup, and default tooling generated
- Local bundler workflow set up using `vendor/bundle`

### Authentication

- Rails authentication generator added session and password reset flows
- Sign-up flow added with `RegistrationsController`
- Sign-in and sign-out wired through session handling
- Added a simple account page with email display and sign-out action
- Password reset views restyled to match the app shell
- Root layout updated to show auth actions based on session state

### Base Layout and Design System

- Global app shell added with top navigation and flash messaging
- Notebook-inspired landing page added at the root route
- Shared design tokens added for color, spacing, typography, borders, and elevation
- Reusable button, card, form, status, and responsive layout styles added
- Authentication pages updated to use the shared visual system
- Navigation was later simplified into a flatter pill-based bar with a compact `Me` entry point

### Exercise Library

- Added canonical `Exercise` model with globally unique public identifiers
- Built authenticated exercise CRUD flows with search and metadata filtering
- Added text-based bulk import with duplicate detection
- Added archive and restore behavior so the active library stays clean without losing records
- Seeded 10 starter exercises for local development

### Workout CRUD

- Added user-owned `Workout` model with title, date, notes, status, total difficulty, and soft-delete fields
- Built workout CRUD flows with list, detail, create, edit, and archive behavior
- Added draft / in-progress / completed lifecycle validation rules
- Added cancelled workouts for plans that never ran
- Added cancelled workouts for plans that never ran, with optional reopen to draft
- Enforced a single in-progress workout per user
- Added active workout surfacing on the workout index
- Added inline status transition actions on the workout page so common lifecycle changes do not require opening edit

### Planned Sets

- Added `WorkoutSet` records to attach exercises to workouts
- Added planned target reps, target weight, ordering, and coach notes
- Built nested planned-set create, edit, and remove flows from the workout detail page
- Surfaced workout structure on the workout detail view
- Added a grouped exercise planner on the workout page so common patterns like `3 x 8 @ weight`, `3x8`, or `9,9,8` can be entered quickly without leaving the session view
- Reworked the planned-set UI around Turbo so adding and removing sets updates in place without a full-page refresh
- Shifted the workout detail presentation from large pills to a compact mini-table that already reserves space for future actuals
- Continued tightening small-screen spacing, inline controls, and remove actions so the page reads more like a training log than a CRUD screen

### Execution Logging

- Added `actual_reps` and `actual_weight` fields to `WorkoutSet`
- Added inline actual-result logging controls directly inside the workout set table for in-progress workouts
- Added a quick "Log extra set" flow so new sets and new exercises can be recorded without leaving the workout page
- Added autosave on change for actuals to keep logging lightweight
- Tightened mobile row spacing and compacted planned text for readability
- Preserved the existing planned-vs-actual split so draft planning data stays intact while performed results are captured separately

### Difficulty Engine (In Progress)

- Added per-set difficulty derived from weight and reps with actuals taking priority
- Added planned vs actual difficulty totals on the workout page
- Added tests for difficulty fallback behavior when data is missing
- Planned difficulty now snapshots when a workout moves from draft to in-progress

### Configuration and Developer Experience

- Added `.gitignore` entries for local bundle output, temp files, SQLite files, and secrets
- Dev server default port changed to `3001` in `config/puma.rb`
- Verified database setup and tests with `bin/rails db:prepare test`
- Verified linting with `bin/rubocop`
- Added a lightweight system test harness for CI
- Added `bin/importmap` to support JS audit checks in CI
- Added mobile CSS fixes for native date inputs and iOS input zoom behavior

## Key Files Added or Updated

- `Gemfile`
- `config/routes.rb`
- `config/puma.rb`
- `app/views/layouts/application.html.erb`
- `app/assets/stylesheets/application.css`
- `app/controllers/concerns/authentication.rb`
- `app/controllers/home_controller.rb`
- `app/controllers/exercises_controller.rb`
- `app/controllers/registrations_controller.rb`
- `app/controllers/workouts_controller.rb`
- `app/models/exercise.rb`
- `app/models/workout.rb`
- `app/views/home/index.html.erb`
- `app/views/exercises/index.html.erb`
- `app/views/workouts/index.html.erb`
- `app/views/workouts/show.html.erb`
- `app/views/registrations/new.html.erb`
- `app/views/sessions/new.html.erb`
- `app/views/passwords/new.html.erb`
- `app/views/passwords/edit.html.erb`
- `db/seeds.rb`
- `.gitignore`

## Notes

- `vendor/.keep` is still untracked; `vendor/bundle` is ignored correctly
- `bin/dev` now starts Puma on port `3001` by default
- The repository started nearly empty, so most current project files were created as part of Milestone 1 setup

## Milestone 2 Progress

- Exercise library implementation has started
- Planned scope for the first slice:
  - canonical `Exercise` model with unique identifier and metadata fields
  - authenticated CRUD flows
  - search and metadata filtering on the library index
  - text-based bulk import with duplicate detection
- Current slice now also supports archiving and restoring exercises so the active library stays clean without losing canonical records

## Milestone 3 Progress

- Workout CRUD has started with the core model, validations, routes, and authenticated pages in place
- Current slice includes:
  - workout list and detail pages
  - create and edit flows for title, date, notes, and status
  - soft-delete style archiving
  - active workout detection
  - lifecycle guards for `draft`, `in_progress`, and `completed`

## Milestone 4 Progress

- Planned sets are now attached to workouts with exercise selection, ordering, target reps, target weight, and coach notes
- Current slice includes:
  - nested planned-set CRUD routes under workouts
  - workout detail rendering for the planned structure
  - automatic ordering for newly added sets
  - position reordering after set removal
  - grouped set planning with flexible reps patterns and grouped workout display
  - inline Hotwire updates for add/remove actions
  - iterative UI refinement toward the future execution logging flow

## Recommended Next Step

Continue Milestone 6 by refining the scoring model:

- monitor the new intensity-weighted difficulty formula in real use and tune it if needed
- add any required rounding or units for display
- decide how completed workouts should lock or recalculate difficulty

## UI Direction Notes

- Planned-set entry now favors a compact inline workout-page form instead of separate edit/create screens for every small change
- Planned-set display now favors rows and columns over decorative pills so the later transition to planned-vs-actual logging is straightforward
- Execution logging now uses the same compact row layout, and future refinements should keep prioritizing one-page workflow and mobile readability
- Input font sizes were raised to prevent iOS zoom on focus
- Workout lists now use inline relative dates for near-term sessions to improve scanability
