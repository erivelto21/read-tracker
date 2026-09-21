## Context

The Terraform-managed MongoDB VM already has a fixed private IP (`172.18.34.72`) and a public SSH path, but the public endpoint is currently treated as something operators and scripts discover through the `public_ip` Terraform output. The backup/restore helper scripts introduced for the MongoDB lifecycle currently resolve SSH through that dynamic output, even though operations now rely on a reserved Magalu Cloud public IP `169.150.1.49` that is intended to persist as a stable contract across destroy/apply cycles.

## Goals / Non-Goals

**Goals:**
- Make `169.150.1.49` the canonical SSH endpoint for the MongoDB VM
- Align Terraform, specs, and operational scripts around that fixed reserved public IP contract
- Preserve the existing fixed private IP and MongoDB networking behavior for in-cluster consumers
- Keep the public IP lifecycle explicit in Terraform rather than relying on ad hoc operator knowledge

**Non-Goals:**
- Changing the MongoDB private address, hostname, or Kubernetes-facing connectivity model
- Reworking database backup/restore semantics beyond the SSH endpoint assumption
- Introducing dynamic service discovery for SSH administration

## Decisions

### Decision 1: Treat the reserved public IP as an invariant, not a discovered value

**Chosen**: Define `169.150.1.49` as a required infrastructure contract for the MongoDB VM SSH endpoint.

**Alternatives considered**:
- *Keep discovering `public_ip` from Terraform output*: Works technically, but keeps the operational model dynamic even though the public IP is intentionally reserved.
- *Use only an environment override in scripts*: Useful as a temporary escape hatch, but too weak for a real infrastructure guarantee.

**Rationale**: If the public IP is reserved and expected to survive recreate flows, the codebase should describe it as a stable invariant. That gives operators and scripts a simpler, clearer contract than “discover whatever IP Terraform currently reports.”

### Decision 2: Keep Terraform as the source of lifecycle management, but simplify the configuration to a fixed reserved-IP reference

**Chosen**: Terraform will reference the known reserved public IP through a variable whose default value is the Magalu Cloud reserved public IP ID, and operational scripts will default to the fixed SSH host contract instead of resolving it dynamically on every run.

**Alternatives considered**:
- *Keep the reserved public IP ID as a variable plus validation checks*: Safer, but more configuration-heavy than needed for a stable single-operator setup.
- *Keep scripts fully coupled to `terraform output public_ip`*: Simpler from a Terraform-only perspective, but it defeats the simplification goal for scripts.

**Rationale**: The infrastructure contract is already fixed: this VM must use the same reserved public IP. Keeping the reserved public IP resource ID in a variable default preserves a simple operator experience while avoiding a magic value embedded directly in the Terraform resource block.

### Decision 3: Preserve backward visibility while tightening the spec

**Chosen**: Keep a `public_ip` output, but require its value to be the reserved public IP `169.150.1.49`.

**Alternatives considered**:
- *Rename the output to something new*: Adds churn without much benefit because `public_ip` already expresses the right concept.
- *Drop public IP output from the spec entirely*: Reduces observability for operators validating Terraform state.

**Rationale**: This keeps operator ergonomics while changing the semantics from “whatever was allocated” to “the reserved IP that must always be attached.”

## Risks / Trade-offs

- **[Risk] Reserved IP attachment drifts from the intended VM]** → Mitigation: Terraform must manage the attachment explicitly and outputs must reflect the reserved value.
- **[Risk] Scripts and specs diverge on the canonical SSH host]** → Mitigation: Define `169.150.1.49` consistently in the Terraform contract and helper-script defaults.
- **[Risk] Future operators assume any replacement VM can use a different public IP]** → Mitigation: State clearly in specs and documentation that the reserved IP is mandatory, not optional.

## Migration Plan

1. Update the Terraform capability spec to require the reserved public IP `169.150.1.49` as the SSH endpoint.
2. Update Terraform implementation so the reserved public IP is referenced through the defaulted reserved public IP ID variable and exposed as `public_ip`.
3. Update MongoDB operational scripts to default SSH access to `169.150.1.49` rather than resolving the host dynamically from Terraform output.
4. Validate that destroy/apply flows keep the reserved IP contract intact while backup/restore automation continues to work.

**Rollback**: Revert the spec and implementation to the previous dynamic public IP discovery model, with the understanding that scripts will again depend on Terraform output resolution.

## Open Questions

- _None. The reserved public IP and its exact value have been decided._
