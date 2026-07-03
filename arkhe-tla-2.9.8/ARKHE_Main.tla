---------------------------- MODULE ARKHE_Main ----------------------------
EXTENDS ARKHE_Proofs

Invariants ==
    /\ I1_TypeOK
    /\ I4_ValidRefs
    /\ AASM_Invariants
    /\ NoInterference

Properties ==
    /\ Progress
    /\ CompositionSafety
    /\ AgentLiveness
    /\ AllLoopsLiveness
    /\ I6_Immutability
    /\ I7_AppendOnly

THEOREM Spec => []TypeOK

=============================================================================
