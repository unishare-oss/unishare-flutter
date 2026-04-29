# /debug

Scientific debugging workflow — hypothesis, reproduce, fix, regression test. Never skip steps.

## Usage

```
/debug <description of the bug>
```

Example: `/debug Login screen crashes on back navigation after biometric prompt`

## Steps

### 1. Understand before touching code

- Restate the bug in your own words: what the user sees vs. what should happen
- Identify the affected feature module and layer (data / domain / presentation)
- Check `docs/agent-log.md` and recent commits for related changes
- Check if a previous session scratchpad in `docs/sessions/` covers this area

### 2. Reproduce

- Write the exact steps to reproduce (device, OS version, Flutter version if relevant)
- Confirm the bug is reproducible before proceeding — if not, say so and stop
- Check Crashlytics / logs for stack traces if the bug is a crash

### 3. Hypotheses (list at least 2)

For each hypothesis:
- State what you think is wrong
- Cite the specific file and line range
- Describe the test that would confirm or refute it

Work through hypotheses cheapest-first (read code before running code).

### 4. Fix

- Make the minimal change that fixes the root cause — no opportunistic cleanup
- Do not change more than one logical thing per fix
- If the fix touches auth, crypto, or PII: flag for security-reviewer before merging

### 5. Regression test

- Write a test that fails on the unfixed code and passes on the fixed code
- Unit test if the bug is in domain/data layer; widget test if it's in presentation
- Add the test before marking the bug fixed

### 6. Handoff

- Update the session scratchpad in `docs/sessions/` with what was found and fixed
- If the root cause reveals a systemic issue, flag it — do not silently fix it and move on

## Rules

- Never delete a failing test to make CI green
- Never suppress an exception to make a crash go away
- If you cannot reproduce the bug, say so — do not guess-fix
