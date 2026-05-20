# Case 01 - Basic Cycle Test

## Objective
Validate full lifecycle:

/dev-bootstrap → /dev-checkpoint → /dev-resume

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

Create a controlled change:

echo "// case-01 test change" >> tests\case-01-basic\marker.txt

Expected:
- detectable git diff
- state drift introduced

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

FAIL if:

- missing state updates
- incorrect recovery
- commit blocked incorrectly
- resume depends on chat history
