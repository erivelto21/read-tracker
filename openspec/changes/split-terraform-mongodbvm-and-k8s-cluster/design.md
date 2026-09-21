## Context

The repository already contains a working Terraform stack under `deploy/terraform/` that provisions a MongoDB VM on Magalu Cloud and is invoked through generic `tf-apply` and `tf-destroy` Make targets. The next infrastructure need is a second Terraform stack that can recreate the current managed Kubernetes cluster in MGC without sharing state, variables, or operational commands with the MongoDB VM stack.

The current cluster baseline is known from the live MGC cluster and kube context:
- region `br-se1`
- Kubernetes version `v1.35.2`
- CNI `calico`
- pod CIDR `192.168.0.0/16`
- service CIDR `10.96.0.0/12`
- three control-plane nodes distributed across zones `a`, `b`, and `c`
- one fixed-size worker pool named `my-pool` using flavor `BV2-2-40` with 1 replica in zone `c`

The change touches both repository structure and infrastructure workflow, so design guidance is useful before implementation.

## Goals / Non-Goals

**Goals:**
- Isolate the MongoDB VM Terraform stack into `deploy/terraform/mongodbvm/`
- Add a dedicated `deploy/terraform/k8s-cluster/` stack for recreating the current MGC Kubernetes cluster baseline
- Define stack-specific Make targets for apply and destroy operations
- Preserve the existing MongoDB VM behavior while changing only its location and command entrypoints

**Non-Goals:**
- Changing the MongoDB VM size, networking model, or bootstrap behavior
- Migrating Helm, raw Kubernetes manifests, or application deployment workflows into Terraform
- Expanding the Kubernetes cluster beyond the current baseline with extra node pools, autoscaling ranges, or add-ons
- Introducing shared Terraform modules across stacks in this change

## Decisions

### Split Terraform into two independent root stacks
The current flat `deploy/terraform/` layout will be replaced by two root stacks:

```text
deploy/terraform/
├── mongodbvm/
│   ├── provider.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── cloud-init.sh
│   └── .gitignore
└── k8s-cluster/
    ├── provider.tf
    ├── variables.tf
    ├── main.tf
    ├── outputs.tf
    └── .gitignore
```

This keeps each stack's state, variable files, and lifecycle separate.

**Alternatives considered:**
- Keep both infrastructures in one root stack — rejected because it would couple unrelated state and make partial apply/destroy flows risky.
- Introduce Terraform modules immediately — rejected because the project currently favors simple root stacks and there is not enough shared logic yet to justify module extraction.

### Keep MongoDB VM implementation intact, only relocate it
The MongoDB VM files should move as-is into `deploy/terraform/mongodbvm/`, with only path-sensitive references updated.

**Alternatives considered:**
- Rewrite the MongoDB VM stack while moving it — rejected because the current change is about structure and workflow isolation, not re-designing the VM stack.

### Model the Kubernetes cluster from the current live baseline
The new `k8s-cluster` stack should encode the current cluster characteristics as defaults so Terraform recreates the same baseline:
- region `br-se1`
- cluster name `my-cluster`
- version `v1.35.2`
- `calico` CNI
- pod CIDR `192.168.0.0/16`
- service CIDR `10.96.0.0/12`
- control plane distributed across `br-se1-a`, `br-se1-b`, and `br-se1-c`
- worker pool `my-pool` with flavor `BV2-2-40`, local disk `40 GB`, fixed-size scaling, and 1 replica

**Alternatives considered:**
- Use looser variables with no defaults — rejected because the user explicitly wants a cluster equal to the current one in MGC.
- Encode a larger or autoscaled node pool — rejected because the current cluster uses a fixed single-node worker pool.

### Replace shared Terraform commands with stack-specific Make targets
The generic targets `tf-apply` and `tf-destroy` will be replaced with explicit targets:
- `tf-mongodbvm-apply`
- `tf-mongodbvm-destroy`
- `tf-k8s-apply`
- `tf-k8s-destroy`

The MongoDB VM apply/destroy hooks remain attached only to the MongoDB VM targets.

**Alternatives considered:**
- Preserve generic targets and pass a stack variable — rejected because explicit commands are simpler for routine operations and reduce operator mistakes.

## Risks / Trade-offs

- **State migration from the existing flat stack** → The MongoDB VM files move to a new root path, so operators may need to reinitialize Terraform in the new directory and handle local state files carefully.
- **Current cluster parity may drift over time** → The new stack captures today's cluster baseline; if the live cluster changes later, Terraform defaults may need a follow-up update.
- **Kubernetes provider surface may differ from the current CLI view** → Some control-plane settings may map to provider-specific fields rather than one-to-one node descriptors; implementation should prefer provider-supported cluster inputs while preserving the observed baseline.
- **More Make targets increase surface area** → Explicit names improve safety, but maintainers must update documentation and habits to use the new commands.

## Migration Plan

1. Move the MongoDB VM Terraform files from `deploy/terraform/` to `deploy/terraform/mongodbvm/`.
2. Update path-sensitive references such as `.gitignore` expectations and any `terraform -chdir` usage.
3. Create the new `deploy/terraform/k8s-cluster/` stack with provider, variables, resources, and outputs for the current MGC cluster baseline.
4. Replace the shared Terraform Make targets with stack-specific targets.
5. Update Terraform usage documentation and examples to point to the new directories and commands.
6. Re-run `terraform init` independently in each stack before applying.

Rollback strategy: restore the previous flat `deploy/terraform/` layout and the original `tf-apply` / `tf-destroy` Make targets.

## Open Questions

- Which outputs from the Kubernetes stack are most useful for operators beyond the cluster ID and name?
- Whether the implementation should preserve backward-compatible alias targets for `tf-apply` and `tf-destroy`, or remove them entirely in favor of the explicit stack names
