# Case-55: Cross-Project Telemetry Bootstrap

## Scenario

When /dev-init runs on an external target project, it must bootstrap the runtime-telemetry directory so that subsequent /dev-status, /dev-scope, /dev-save, and continue loop commands can record telemetry events.

## Preconditions

- Telemetry source files exist in dev-protocol: `.agents/dev-protocol/runtime-telemetry/telemetry.ps1`, `config.json`, `README.md`
- /dev-init skill is available

## Steps

1. Verify /dev-init SKILL.md and PROMPT.md contain instructions to create `runtime-telemetry/` directory
2. Verify /dev-init instructions include copying `telemetry.ps1`, `README.md`, and creating `config.json`
3. Verify all 6 core skills (dev-status, dev-save, dev-scope, dev-init, continue-loop, generate-plan) have YAML frontmatter with `name` and `description`

## Expected Result

- /dev-init instructions explicitly require `runtime-telemetry/` bootstrap
- Skills have discoverable descriptions in command palette

## Failure Signal

- /dev-init missing runtime-telemetry bootstrap instructions
- Skills missing YAML frontmatter
