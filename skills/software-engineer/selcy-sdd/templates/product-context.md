# Product Context

The why behind the product. Every other file answers to this one: architecture serves it, scope is cut against it, and a feature that serves no goal here is out of scope.

## Problem

<PROBLEM_PARAGRAPHS>

What is broken, slow, or expensive today, and for whom. Two to four sentences. Write the pain, not the solution. If the pain is not real enough to state here, the feature built to fix it is probably not needed.

## Users

<USERS_TABLE_OR_BULLETS>

Who they are and the job they are hiring this product to do. Name the job, not the role: "a cashier closing a shift without miscounting the drawer", not "cashier user". The job is what every later feature is judged against.

## Success Metrics

| Metric | Baseline | Target | How measured |
| --- | --- | --- | --- |
<SUCCESS_METRICS_TABLE_ROWS>

Business outcomes, not feature completion. "Spec generation time from 3 days to 20 minutes", not "user can generate a spec". A feature can ship and still fail here; that is the point of writing it down.

## Non Goals

<NON_GOAL_BULLETS>

What this product deliberately is not, so a builder does not build it. Repeated from `project-overview.md` Out Of Scope when they overlap, but stated here as a product judgment rather than a scope cut.
