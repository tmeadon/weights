# Weights --- Product Requirements Document

## Product Definition

**Weights** is a minimal personal strength-training tracker that allows
a user to plan workouts, log actual performance during a session,
preserve structured training history, and quantify workout difficulty in
a format that also supports external coaching or AI-generated plans.

The product prioritises:

-   fast logging during workouts
-   clear historical records
-   structured training data

over dashboards, social features, or complex analytics.

The overall feel should resemble a **personal training notebook** rather
than a fitness platform.

------------------------------------------------------------------------

# 1. Product Principles

These principles guide both product and implementation decisions.

## 1.1 Fast During Training

The interface must allow workouts to be logged quickly while exercising.

Common actions must require minimal friction:

-   logging reps
-   adjusting weight
-   adding sets
-   adding exercises

Interaction speed is more important than visual density or analytics.

------------------------------------------------------------------------

## 1.2 Structured Training Data

Workout data must remain predictable and structured so that external
systems (coaches, scripts, AI models) can interpret it reliably.

The domain model must avoid ambiguous or loosely typed data.

------------------------------------------------------------------------

## 1.3 Clear Plan vs Execution Separation

The system must always distinguish between:

-   **planned training targets**
-   **actual performance results**

Both must be preserved historically.

Planned data must never be overwritten by execution data.

------------------------------------------------------------------------

## 1.4 Durable Training History

Completed workouts must remain readable even if:

-   exercise metadata changes
-   exercises are renamed
-   library details evolve

Historical records represent the **truth of what happened at the time**.

------------------------------------------------------------------------

## 1.5 Calm Utility

The application should feel like a personal notebook:

-   simple
-   focused
-   calm
-   dependable

The interface should avoid:

-   dashboard complexity
-   overly dense layouts
-   feature sprawl

------------------------------------------------------------------------

# 2. Core Domain Model

The system revolves around five core entities:

-   Exercises
-   Workouts
-   Sets
-   Notes
-   Difficulty calculations

------------------------------------------------------------------------

# 3. Exercises

Exercises represent the canonical movement library.

Examples:

-   Dumbbell Bench Press
-   Lat Pulldown
-   Seated Cable Row
-   Barbell Curl

Exercises are reused across workouts.

------------------------------------------------------------------------

## Exercise Requirements

The system must allow:

-   creation of exercises
-   editing of exercise metadata
-   deletion or archiving of exercises
-   bulk import of exercises
-   duplicate detection during import

------------------------------------------------------------------------

## Exercise Data Fields

Typical fields include:

-   name
-   movement category (optional)
-   primary muscle group (optional)
-   equipment type (optional)
-   notes (optional)

------------------------------------------------------------------------

## Exercise Library Capabilities

The exercise library must support:

-   text search
-   metadata filtering

Exercise identifiers must remain **globally unique**.

------------------------------------------------------------------------

# 4. Workouts

A workout represents a single training session.

Workouts act as containers for:

-   exercises
-   sets
-   notes
-   difficulty calculations

------------------------------------------------------------------------

## Workout Fields

Typical fields include:

-   title
-   workout date
-   workout notes
-   workout status
-   total difficulty (derived)

Workout dates are stored at **day precision** even if the user enters a
date-time value.

------------------------------------------------------------------------

## Workout Operations

The system must support:

-   creating workouts
-   retrieving a workout with all related sets and notes
-   listing workouts
-   editing workout metadata
-   soft deletion
-   retrieving the currently active workout

Soft-deleted workouts must be excluded from standard queries.

------------------------------------------------------------------------

# 5. Workout Lifecycle

Workouts follow a defined lifecycle.

## States

draft\
in_progress\
completed

------------------------------------------------------------------------

## Lifecycle Rules

-   New workouts default to **draft**
-   Draft workouts may transition to **in_progress**
-   In-progress workouts may transition to **completed**
-   Draft workouts may **not skip directly** to completed
-   Completed workouts may **not transition backward**

------------------------------------------------------------------------

## Active Workout

Only **one workout may be in progress** at a time.

The system must expose the current active workout.

------------------------------------------------------------------------

## Planned Future State

Product planning documents mention an additional lifecycle state:

loaded

This state would represent workouts generated externally (for example by
AI).

The rebuild should ensure the model can support this state even if it is
not implemented initially.

------------------------------------------------------------------------

# 6. Sets

Sets represent the fundamental training record.

A set represents one attempt of an exercise.

Each set must belong to:

-   a workout
-   an exercise

------------------------------------------------------------------------

# 7. Planned Sets

Planned sets represent the intended structure of the workout.

These exist before the workout begins.

------------------------------------------------------------------------

## Planned Set Fields

Planned sets may include:

-   target weight
-   target reps
-   ordering
-   coach notes

Planned values must remain distinct from actual performance results.

------------------------------------------------------------------------

# 8. Actual Execution Logging

During workout execution, the user records real results.

------------------------------------------------------------------------

## Execution Fields

Actual execution fields include:

-   actual weight
-   actual reps

Effort can be inferred by comparing planned targets to actual results.

------------------------------------------------------------------------

## Execution Requirements

While a workout is **in_progress**, the user must be able to:

-   update logged results
-   modify previously entered values
-   add extra sets
-   add entirely new exercises via quick logging

The logging experience must remain extremely fast.

The workout detail interface should therefore be able to evolve from
planning into logging without forcing the user through separate,
repetitive edit screens.

Planned-set UI should prefer:

-   compact inline controls
-   grouped exercise blocks
-   row-based layouts that can later show both planned and actual values

over large decorative cards or one-form-per-set flows.

------------------------------------------------------------------------

# 9. Difficulty Calculation

Difficulty represents the workload of a training session.

Difficulty is **always derived** and never user-entered.

------------------------------------------------------------------------

## Set Difficulty

Each set must expose an individual difficulty value.

Difficulty calculations use:

-   weight
-   reps

Effort can optionally be inferred from planned-vs-actual deltas.

If actual results are missing, planned values may be used.

------------------------------------------------------------------------

## Workout Difficulty

Workout difficulty equals the sum of all set difficulties.

total_difficulty = sum(set_difficulty)

Difficulty must recalculate whenever:

-   set results change
-   sets are added
-   sets are removed
-   effort values change

------------------------------------------------------------------------

# 10. Notes Model

The system supports notes at multiple scopes.

------------------------------------------------------------------------

## Workout-Level Notes

Attached to the workout itself.

Example:

> Felt strong today but grip was weak.

------------------------------------------------------------------------

## Exercise-Level Notes (Workout Context)

Notes tied to a specific exercise **within a specific workout**.

Examples:

-   coach notes
-   user notes

These must remain separate from canonical exercise definitions.

------------------------------------------------------------------------

## Set-Level Notes

Optional notes attached to individual sets.

Example:

> Last rep was shaky.

------------------------------------------------------------------------

# 11. History and Progress Data

Completed workouts become historical records.

Historical workouts must expose:

-   exercises performed
-   sets and results
-   notes
-   difficulty scores

Historical records must remain queryable.

------------------------------------------------------------------------

# 12. External Coach and AI Compatibility

The domain model must support externally generated training plans.

This includes:

-   importing structured workouts
-   editing imported plans
-   attaching coach notes
-   logging execution against planned sets

External systems must be able to clearly distinguish between:

-   planned targets
-   actual results

------------------------------------------------------------------------

# 13. Non-Functional Requirements

## Performance

The product must feel responsive during a workout session.

## Reliability

Workout data must not be lost mid-session.

Autosave or low-friction persistence is required.

## Offline Tolerance

The product should tolerate intermittent connectivity.

## Simplicity

The product must remain usable by a single person without training.

## Portability

The domain model must remain portable and independent of a specific
framework.

------------------------------------------------------------------------

# 14. Business Rules

-   Exercise identifiers must be unique.
-   Workouts store dates at day precision.
-   Soft-deleted workouts are excluded from normal queries.
-   Difficulty is always derived.
-   Sets must belong to both a workout and an exercise.
-   Plan data and execution data must remain distinct.
-   Workout difficulty must equal the sum of set difficulties.

------------------------------------------------------------------------

# 15. Rebuild Scope

The rebuild should progress through three phases.

## Phase 1 --- Core Training Capture

Includes:

-   exercise library
-   workout CRUD
-   workout lifecycle
-   planned sets
-   execution logging
-   notes model
-   difficulty calculation

## Phase 2 --- Execution Ergonomics

Includes:

-   resume active workout
-   quick-add exercise
-   grouped set editing
-   autosave behaviour

The intended UX direction for this phase is that the workout detail page
becomes the primary surface for both planning and execution, with minimal
page navigation and inline updates where possible.

## Phase 3 --- Intelligence and Analysis

Includes:

-   historical progress views
-   time-based difficulty summaries
-   AI-generated workout loading
-   richer coaching workflows

------------------------------------------------------------------------

# 16. Acceptance Criteria

A user can:

-   create a workout with title, date, and notes
-   add planned sets for exercises
-   start a workout and mark it **in progress**
-   log weight and reps during the session
-   log weight and reps during the session
-   add extra sets and new exercises mid-workout
-   finish a workout and store it as history

The system must:

-   calculate set difficulty automatically
-   roll difficulty up to workout level
-   preserve historical workouts
-   maintain separation between planned and actual data
-   support management of the exercise library

------------------------------------------------------------------------

# 17. Out of Scope

The following are intentionally excluded from the initial rebuild:

-   social features
-   sharing workouts
-   public exercise libraries
-   community programs
-   complex analytics dashboards
-   wearable integrations

------------------------------------------------------------------------

# 18. Development Milestones

## Milestone 1 --- Project Skeleton

-   Rails app scaffold
-   authentication
-   base layout and design system
-   global stylesheet and design tokens

## Milestone 2 --- Exercise Library

-   exercise model
-   exercise CRUD
-   search
-   filtering
-   bulk import

## Milestone 3 --- Workout CRUD

-   workout model
-   workout CRUD
-   workout list view
-   workout detail page

## Milestone 4 --- Planned Sets

-   planned set model
-   attach exercises to workouts
-   target reps and weight

## Milestone 5 --- Execution Logging

-   actual reps
-   actual weight
-   add sets during workout
-   add new exercises during workout

## Milestone 6 --- Difficulty Engine

-   set difficulty calculation
-   workout difficulty rollup

## Milestone 7 --- History and Querying

-   workout history pages
-   queries by date
-   queries by exercise

## Milestone 8 --- Execution Ergonomics

-   resume active workout
-   grouped editing by exercise
-   autosave behaviour

## Milestone 9 --- AI Workflows (Optional)

-   load externally generated workouts
-   AI planning integration
