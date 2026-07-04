# 🗺️ Cathedral ARKHE Project Roadmap

## Phase 1: Stabilization and Cleanup (Current)
1. **Root Directory Cleanup:** Move stray Python scripts (`fix_*.py`, `patch_*.py`) and bash scripts (`fix_*.sh`) into the `scripts/` or `tools/` directory.
2. **Standardize Documentation:** Ensure `AGENTS.md`, `CLAUDE.md`, `README.md`, and `PLAN.md` are aligned with the new modular structure.
3. **CI/CD Alignment:** Fix any missing dependencies for Github actions, ensuring `cargo xtask` workflows properly cover `safe-core`, `cathedral-cse`, and all Substrato bridge targets.

## Phase 2: Core Substrates Hardening
1. **Plurality & Nostr Integration:** Polish the `cathedral-plurality-integration` workspace, ensuring NIP-44 stubs perform reliably in offline E2E tests.
2. **Qdrant Vector DB Integrity:** Finalize Merkle sealing tests (`safe-core-memory-system`) across all hybrid PostgreSQL/SQLite/RocksDB layers.

## Phase 3: Hardware & TEE Bridge Deployments
1. **TPM & YubiKey Mock Testing:** Validate `safe-core-hw-yubihsm` and `safe-core-tpm-bridge` without native C-bindings on CI pipelines.
2. **ZK Proofs Integration:** Test RISC Zero proofs in `cathedral-bridge`.

## Phase 4: Identify Missing Components (arkhe-cep, arkhe-ztm)
1. **Locate or Stub `arkhe-cep`:** It was mentioned in earlier specs but is missing from `crates/`. Identify if it was renamed or needs implementation.
2. **Locate or Stub `arkhe-ztm`:** Similarly, search out where Zero Trust Mesh logic lives (potentially in `arkhe-pqc` or a separate `cathedral-ztm` stub).

## Phase 5: Production and Auditing
1. **Formal Verification:** Link `arkhe-tla-2.9.8` proofs to Lean4 code inside `safe-core-verifier`.
2. **Mainnet Deployments:** Substrato 4004 (Base Chain B20) and Substrato 9510 (Taproot) transitions to live environments.
