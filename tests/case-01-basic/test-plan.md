# Case 01 - Basic Cycle Test

## Objective

Validate stable protocol lifecycle:

change → /dev-checkpoint → /dev-resume → /dev-checkpoint(idempotent)

---

## Step 1: Bootstrap

Run:

/dev-bootstrap

Expected:
- workflow-state.yml created
- handoff.md created
- project state reconstructed
- no hard failure

---

## Step 2: Simulate Change

Create a controlled tracked change:

Add a small line to README.md

Example:

echo "## Case-01 Test" >> README.md

Expected:
- detectable git diff
- checkpoint should detect meaningful change

---

## Step 3: Checkpoint

Run:

/dev-checkpoint

Expected:
- workflow-state updated
- handoff updated
- commit generated
- no validation failure

---

## Step 4: Resume Test

Open a new session OR clear context

Run:

/dev-resume

Expected:
- correct recovery of state
- correct identification of test change
- correct next action suggestion

---

## Success Criteria

PASS if:

- no manual correction required
- state is fully reconstructible
- checkpoint → resume consistency is maintained
- repeated /dev-checkpoint creates no extra commit
- self-drift exception works correctly

FAIL if:

- missing state updates
- incorrect recovery
- commit blocked incorrectly
- resume depends on chat history
