## Repository Guide For Agents

This repository is a small Rails 8.1 application named `weights`.
It uses Ruby 3.4.7, SQLite, Minitest, Importmap, Turbo, Stimulus, RuboCop Omakase, Brakeman, and Bundler Audit.
There is no Node-based build pipeline in the repo today.

## Source Of Truth

- Prefer repository files over assumptions.
- Key config files:
  - `Gemfile`
  - `.github/workflows/ci.yml`
  - `config/ci.rb`
  - `.rubocop.yml`
  - `config/application.rb`
  - `test/test_helper.rb`
- There is currently no `.cursorrules` file.
- There is currently no `.cursor/rules/` directory.
- There is currently no `.github/copilot-instructions.md` file.
- If any of those agent-rule files are added later, treat them as high-priority instructions.

## Environment

- Ruby version: `ruby-3.4.7`
- Rails version: `8.1.x`
- Database: SQLite (`storage/development.sqlite3`, `storage/test.sqlite3`)
- Test framework: Minitest
- App server in development: `bin/dev` runs `bin/rails server`
- Authentication/session logic is custom and lives in app code, not Devise.

## Setup Commands

- Install gems and prepare the database:
  - `bin/setup --skip-server`
- Full setup plus start the dev server:
  - `bin/setup`
- Reset the database during setup:
  - `bin/setup --reset --skip-server`
- Prepare the current environment database manually:
  - `bin/rails db:prepare`

## Run Commands

- Start the app locally:
  - `bin/dev`
- Start Rails directly:
  - `bin/rails server`
- Open a console:
  - `bin/rails console`
- Run database migrations:
  - `bin/rails db:migrate`
- Reseed in test environment:
  - `RAILS_ENV=test bin/rails db:seed:replant`

## Build Commands

- There is no dedicated frontend build step.
- For local validation, treat these as the closest equivalents to a build/check pipeline:
  - `bin/setup --skip-server`
  - `bin/rubocop`
  - `bin/rails test`
  - `bin/ci`
- For production container builds:
  - `docker build -t weights .`
- Production assets are precompiled inside the Docker build with:
  - `SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile`

## Lint And Security Commands

- Ruby lint:
  - `bin/rubocop`
- Ruby lint with GitHub formatter:
  - `bin/rubocop -f github`
- Static security scan:
  - `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`
- Gem vulnerability audit:
  - `bin/bundler-audit`
- Importmap vulnerability audit:
  - `bin/importmap audit`
- Full local CI-style check:
  - `bin/ci`

## Test Commands

- Run all tests:
  - `bin/rails test`
- Prepare the test database and run all tests:
  - `bin/rails db:test:prepare test`
- Run system tests:
  - `bin/rails test:system`
- Prepare the test database and run system tests:
  - `bin/rails db:test:prepare test:system`

## Single-Test Commands

- Run one test file:
  - `bin/rails test test/models/user_test.rb`
- Run one test file at a specific line:
  - `bin/rails test test/models/user_test.rb:4`
- Example for a controller test at a line:
  - `bin/rails test test/controllers/sessions_controller_test.rb:18`
- If you need deterministic isolation while debugging, run the exact file or file:line instead of the full suite.

## CI Behavior

- GitHub Actions runs these categories:
  - security scans
  - RuboCop lint
  - regular test suite
  - system tests
- Local `bin/ci` runs:
  - setup
  - RuboCop
  - Bundler Audit
  - Importmap audit
  - Brakeman
  - `bin/rails test`
  - test seed replant
- Prefer `bin/ci` before handing off substantial changes.

## Architecture Notes

- Rails defaults are largely intact.
- Controllers are thin and rely on framework helpers and redirects.
- Authentication behavior is implemented in `app/controllers/concerns/authentication.rb`.
- Models are small and use Rails macros (`has_secure_password`, associations, normalization).
- Tests use Minitest with fixtures and helper modules.
- `db/schema.rb` is generated output; change migrations, not the schema file by hand.

## Code Style

- Follow RuboCop Omakase defaults from `.rubocop.yml`.
- Match the existing style in nearby files before introducing new patterns.
- Keep classes small and conventional.
- Prefer Rails conventions over custom abstractions.
- Avoid adding gems or framework layers unless the repository clearly needs them.

## Imports And Requires

- In app code, rely on Rails autoloading instead of adding unnecessary `require` calls.
- In tests, use `require "test_helper"`.
- In scripts/config files, keep `require` and `require_relative` statements grouped at the top.
- Do not add manual requires for application classes that Zeitwerk can autoload.

## Formatting

- Use 2-space indentation.
- Keep whitespace and hash/array literal spacing consistent with existing files.
- Preserve the current empty-line rhythm: short methods often have no extra padding; private sections do.
- Prefer concise methods when the Rails DSL already reads clearly.
- Avoid trailing whitespace.

## Types And Data Shapes

- This is a dynamic Ruby codebase; there is no Sorbet, RBS, or static typing setup.
- Express constraints with validations, associations, normalizers, strong parameters, and tests.
- Prefer framework-level guarantees over custom type wrappers.
- Keep params filtering explicit.

## Naming Conventions

- Use standard Rails naming:
  - classes/modules: `CamelCase`
  - files: `snake_case.rb`
  - methods/variables: `snake_case`
  - constants: `SCREAMING_SNAKE_CASE`
- Name controller actions with standard REST verbs where possible.
- Prefer descriptive domain names like `email_address`, `password_reset_token`, `current_user`.
- Keep route and path helper naming conventional.

## Controllers

- Use strong parameters or `params.expect`/`params.permit` explicitly.
- Prefer guardable `if` branches with clear redirect/render outcomes.
- Use redirects with `notice` or `alert` for user-visible outcomes when following existing patterns.
- Use `status: :unprocessable_entity` when re-rendering invalid forms.
- Keep controller logic thin; move reusable auth/session behavior into concerns or models when justified.

## Models

- Prefer declarative Rails macros first: associations, `dependent`, `normalizes`, `has_secure_password`.
- Add validations and callbacks only when they are needed by behavior or data integrity.
- Keep model APIs small and intention-revealing.
- Use bang methods when failure should surface immediately in trusted flows.

## Error Handling

- Prefer Rails-native handling over broad `rescue StandardError` blocks.
- Rescue only specific exceptions you expect, as in the password reset token flow.
- On user input errors, show a clear redirect/render path and a concise flash message.
- Let truly unexpected exceptions bubble unless the app already has a clear recovery path.

## Views And Frontend

- Follow the existing server-rendered ERB approach.
- Use Rails form builders (`form_with`) and path helpers.
- Keep markup semantic and class names descriptive.
- Do not introduce a JS toolchain unless the repo changes direction.
- Preserve the existing Hotwire/Importmap setup if touching frontend behavior.

## Testing Conventions

- Add or update tests for behavior changes.
- Prefer integration/controller tests for request flows and user-facing auth behavior.
- Use model tests for focused domain behavior.
- Reuse helpers from `test/test_helpers/` when appropriate.
- Keep test names descriptive, sentence-like, and behavior-focused.
- Use fixtures where that is already the project pattern.

## Database And Schema Changes

- Create migrations for schema changes.
- Do not hand-edit `db/schema.rb`.
- After migrations, ensure schema output is updated by Rails.
- Consider test data and fixtures when changing required columns or associations.

## Agent Working Rules

- Before editing, inspect neighboring files for local conventions.
- Make the smallest change that fits the current architecture.
- Do not rewrite style just for preference.
- Do not add headers, comments, or abstractions unless they clarify non-obvious logic.
- If a command is expensive, prefer the narrowest useful validation first, then broaden.
- When changing tests, start with a file or file:line run when practical.

## Practical Validation Order

- Small Ruby-only change:
  - `bin/rubocop path/to/file.rb`
  - `bin/rails test path/to/test_file.rb:LINE`
- Multi-file behavior change:
  - `bin/rubocop`
  - `bin/rails test`
- Pre-handoff confidence check:
  - `bin/ci`
