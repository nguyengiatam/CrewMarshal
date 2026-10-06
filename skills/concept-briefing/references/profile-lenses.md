# Profile Lenses — What to Ask for the Kind of Thing Being Built

The profile's core (who uses it, where it's heading, what wins a conflict, what
must never be traded) applies to everything. Past the core, what is worth asking
depends on what is being built: a CLI tool has no "expected concurrent users", and
a backend service has no "design source". Pick the lenses that match — often more
than one (a web app is usually *frontend* + *service*) — and ask only those.

**The test for every question, here or one you add:** would a different answer
change a design choice? If every answer leads to the same design, don't ask it.
The lists below are starting points, not forms to fill: drop a line that can't
matter for this project, add one the kind of work demands that isn't listed.

**Bold** = only the user can answer; ask it directly. The rest: draft from the repo
with `~` and have it confirmed in the batch. Anything about the future is never
drafted — the repo contains no future.

A lens adds one section to the profile, headed with the lens name.

---

## Service / backend system

APIs, workers, anything that runs and serves load.

- **Users today:** how many, internal or public.
- **Expected scale and its horizon:** users and load at a named point in time — or
  `CHƯA CHỐT`.
- **Which horizon the design targets:** today's numbers or the expected ones, and
  why. Left implicit, each session picks differently.
- Current scale: one instance enough | scaled horizontally. *(replicas in
  k8s/compose, HPA)*
- Load and data volume; **the heaviest realistic case** — the one number that
  decides whether a design is adequate. *(migrations, seeds, rate limits)*
- Operations: where it deploys, allowed downtime, who runs it, monitoring.
  *(CI/CD, manifests, probes)*
- Data and compliance: sensitive data, audit, backup, retention. *(PII-like
  fields, audit tables, retention jobs)*
- Boundaries that must not break: public API, schemas, jobs, outside consumers.
  *(route files, published schemas, topics, cron entry points)*

## Frontend / UI

Web UI, dashboard, landing page, anything whose quality is partly judged by eye.

- **Design source:** a finished design (Figma or similar link) | a design system
  or component library to follow | references or a mood only | nothing — design
  as we go. This decides whether the work is *implementing* a design or *making*
  one, which changes everything downstream.
- **Visual direction** when there is no finished design: theme, brand colors and
  fonts, references liked or disliked, light/dark.
- **Who signs off on the look,** and how — screenshots, a live preview, nobody.
- **Who uses it and on what:** desktop, mobile, both; which browsers must work.
- Accessibility and languages: a required level, or "reasonable"; i18n now or
  later.
- Existing UI stack: framework, component library, CSS approach, design tokens.
  *(package manifest, theme files, `components/`)*
- Where data comes from: an existing API, a mock to be replaced, static content.

## App (mobile / desktop)

- **Who uses it, in what situation:** on the move, at a desk, offline in a
  warehouse — situation decides offline, battery and input-method choices.
- **Platforms:** iOS, Android, macOS, Windows, Linux — which are required now.
- **Distribution:** app store, internal/enterprise, sideload, direct download.
- **Offline needs:** must work fully offline | degrade gracefully | always online.
- Design source and visual direction — as in *Frontend / UI*.
- Device capabilities used: camera, location, notifications, files, background
  work. *(manifests, entitlements)*
- Updates: how fast a fix must reach users; whether old versions must keep working
  against the backend.

## Tool (CLI, script, internal tool, plugin, automation)

- **Who runs it:** only you | the team | the public. This sets how much polish,
  documentation and error handling is worth it.
- **How often and how it's triggered:** once, by hand daily, from CI, on a
  schedule, called by another program.
- **What a failure costs:** rerun it | lose data | break someone's pipeline. Sets
  the guarding, idempotency and dry-run needs.
- Where it runs: OS, shell, runtime available there; installed or run in place.
  *(shebangs, package manifest, CI config)*
- Its contract: inputs, outputs, exit codes, and whether something else parses
  its output — then that output is an interface that must not break.
- For a plugin or extension: the host and its version range, and what the host
  already does that the plugin must not duplicate.

## Library / SDK

- **Who consumes it:** your own code only | other teams | the public.
- **Compatibility promise:** semver and how strict; supported language/runtime
  versions.
- Public surface: what is API, what is internal. *(exports, `index` files, docs)*
- Dependency appetite: how many and how heavy the consumers will tolerate.

## Data / pipeline / ML

- **Who consumes the output and how late it may arrive:** a dashboard next
  morning, a live feature, a one-off report.
- **What a wrong number costs:** whether figures, once published, are settled and
  must never shift.
- Volume and growth; batch or streaming. *(schemas, job configs)*
- Where it runs and what it may cost per run.
- Reproducibility: must a past run be re-creatable exactly.

---

## When no lens fits

Use the test above directly: list the choices this work will face, and ask the
user only the facts that would swing one of them. Then add that as a new section,
named for what it is.
