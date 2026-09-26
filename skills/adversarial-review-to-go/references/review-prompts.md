# Review Prompt Templates — One Per Altitude

Three artifacts, three prompts. They are not variations of one prompt: each names
a different question and, more importantly, a different **prohibition**. The
prohibitions are the working part — a reviewer will answer whatever you attach,
so attaching a source-file list to a spec review *is* an instruction to find
implementation defects.

Write the prompt in the project's working language. Keep it self-contained: a
fresh reviewer thread must be able to work from it alone.

Every template includes `system-profile.md` (or its key lines). That axis sets
**severity**. The template sets **altitude**. Both are needed.

---

## The Finding Format — Required by All Three

Paste this block at the end of every prompt below. A finding without fix options
hands the owner a blank page at the moment the reviewer's context is richest.

> **Output format. Every finding has these fields, in this order:**
>
> - **Finding** — what is wrong, at the cited place.
> - **Failure** — the concrete consequence. Not "risky": say what breaks.
> - **Fix options** — 1 or 2 **directions**, not patches. Each names the approach
>   and where it applies, *at the altitude of this review*, in at most two
>   sentences, followed by its cost: what it breaks, what it slows, what it
>   postpones. No code, no diff, no rewritten paragraph, no line numbers — the
>   owner writes the change after confirming the finding. Give a second option
>   only when it takes a **different approach**; the same fix at two sizes is one
>   option.
> - **Recommended** — which option you would take, and why. When the two are a
>   real trade-off for the owner to settle, write "owner decides" and say what the
>   decision turns on.
>
> **Coverage.** End the report with a list of the sections (or tasks) you
> examined deeply and those you only skimmed. Do not claim depth you did not
> spend — the next round is aimed at what you skimmed.
>
> These fixes are read as suggestions: the owner re-verifies every finding on the
> real source before applying anything. Write the option you would defend, not the
> one that is easiest to accept. Spending your budget drafting an implementation
> is attention taken from finding the next defect.

## Round N+1 on a Large Spec or Plan — Add to Template 1 or 2

> Round <N+1>. The previous round patched these sites: <list>, and only skimmed
> these sections: <list from its coverage report>. Review the patched sites
> **first**, then the skimmed sections. Do not re-sweep sections already
> examined deeply unless a patch changed what they depend on.
>
> Report **blocking** findings only: a wrong decision, a missing constraint with
> a stated consequence, a done-line that goes green for the wrong reason, a task
> that cannot run, a false parallel, an undecided "or" with data or security
> consequences. Anything else — clarity, wording, "could also mention" — goes in
> one short separate list marked non-blocking, or is left out.
>
> Every patch you propose adds text to a document that will be reviewed again.
> Prefer the fix that adds least, and keep listing what should be cut.

---

## 1 — Reviewing a SPEC

**Attach:** the spec · `system-profile.md` · the original request.
**Never attach:** a source-file list, a repo tree, "the code is at …".

> You are reviewing a specification, not an implementation. Nothing below asks
> you to look at source code, and you should not ask for it.
>
> System profile: <paste or point>. A finding is only real relative to these
> priorities and these hard boundaries.
>
> Answer four questions:
> 1. **Wrong decisions.** Which decision here is wrong given the profile, and
>    what is the consequence? Not "risky" — say what breaks.
> 2. **Missing constraints.** What must hold that the spec never states? Name
>    the result that must be achieved, not the way to achieve it.
> 3. **Definition of done.** Which DoD line can go green while the goal is still
>    unmet? For each, say how it goes green for the wrong reason.
> 4. **Reverse altitude check.** Which sections describe *mechanism* — how to
>    build it — and should be cut and left to the plan? List them to be deleted.
>
> Out of scope, do not report: choice of data structure, file layout, function
> or type names, library choice, line-level wording.
>
> <paste the finding format block>. At this altitude a fix option names which
> decision to take instead, or what constraint the spec is missing — named in the
> spec's own terms, not drafted for it. For a reverse-altitude finding, it says
> what to cut and which layer it belongs to.

**Why the prohibition.** Attaching files and saying "verify against the code"
produced a review where the majority of findings were implementation-layer; the
same model on the same document, with the prompt above, produced zero of those
and 3/10 findings that were cuts.

---

## 2 — Reviewing a PLAN

**Attach:** the plan · the spec it derives from · `system-profile.md` · who
executes each task (the plan's assignment table) · the executor's known capability.
**Never attach:** an invitation to redesign. The design was settled in the spec.

> You are reviewing an implementation plan that will be handed to a coding agent
> with no memory of this conversation. Judge it as that agent would read it.
>
> Do **not** re-litigate the design — decisions belong to the spec, which is
> attached for context only. Do not propose a different mechanism because you
> prefer it.
>
> Answer six questions:
> 1. **Runnable tasks.** Which task cannot actually be started by someone who
>    reads only this plan and the context file it points at? What is missing?
> 2. **Dependency graph.** Which tasks are listed as parallel but are not —
>    same files, same generated artifacts (including committed build output),
>    same migration, same service? Which task consumes the output of a gate that
>    the plan places *after* it?
> 3. **Acceptance.** For each task, does "done when" measure the **hardest**
>    requirement of that task, or the easiest observable one? Port/migration
>    tasks whose acceptance is "it starts up" are the classic failure.
> 4. **Missing acceptance.** Which tasks have no "done when" at all?
> 5. **Undecided decisions in disguise.** Find every "or", "alternatively",
>    "depending on". Each is a decision the executor will make silently and not
>    report. Say which ones have security or data consequences.
> 6. **Unverified numbers.** Every count in this plan is a claim ("rebuild 9
>    services", "3 call sites"). Which are unchecked?
>
> Out of scope, do not report: naming, code style, wording, anything that would
> only be visible after the code exists.
>
> <paste the finding format block>. At this altitude a fix option names which task
> to split, which dependency to reorder, which "or" to pin down, or what the
> acceptance should measure — the direction only. Do not rewrite the task, the
> acceptance line, or the sequence for me.

---

## 3 — Reviewing a DIFF

**Attach:** the diff or branch scope · the plan section it implements ·
`system-profile.md` · the constraints the task claims to satisfy · on round N+1,
**the sites patched in round N**.
**Attach the file list here** — this is the altitude where it belongs.

> You are reviewing an implemented change against the constraints it claims to
> satisfy. Source is at <path/branch>; the diff is <scope>.
>
> System profile: <paste or point>.
>
> <Round N+1 only:> These sites were patched in the previous round: <list>.
> Review them **first** — patches are where the newest, least-reviewed code is.
>
> 1. **Correctness at the cited site.** For each finding, quote the code and
>    give a concrete failure: inputs or interleaving → wrong result or crash.
>    No finding without a failure path.
> 2. **Seeded mutations — required.** Copy the repo to a scratch directory. For
>    **each constraint the task claims to satisfy**, introduce a deliberate
>    defect that would violate it — prefer the failure modes the handoff calls
>    classic. Run the test suite. Report which mutations were **not** caught.
>    A constraint whose mutation survives is unguarded, whatever the suite says.
> 3. **Gaps the tests cannot see.** Crash between two writes, TOCTOU, ordering
>    across replicas, migration-on-deploy, partial failure of a batch.
> 4. **Profile check.** Which findings are you raising only because of generic
>    best practice, and would not matter at this system's stated scale? List
>    them separately — do not mix them with the rest.
>
> <paste the finding format block>. At this altitude a fix option names the site
> and what kind of guard belongs there — smallest one that holds first; a guard or
> CAS at the contention point ranks above a rewrite, and the cost line says so
> when you propose the larger one. Where a fix needs a test to hold it, name what
> the test must catch. Do not write the patch; I write it after confirming the
> finding at the site.

**Why mutations are mandatory here.** At a real gate, a reviewer did this
unasked: 4 of 4 seeded mutations were caught, including the exact trap the
handoff had described. Without that step the evidence was "hundreds of tests
pass", which demonstrates that the code runs and nothing about whether the tests
watch the constraint.
