---------------------------- MODULE ARKHE_Proofs ----------------------------
EXTENDS ARKHE_Transition, ARKHE_Replay, ARKHE_AASM, ARKHE_Composition

I1_TypeOK == TypeOK

I4_ValidRefs ==
    \A did \in DecisionIDs :
        LET proj == CurrentProjection
        IN proj.D[did].id # "None" => proj.D[did].event \in ExistingEvents(proj)

I6_Immutability ==
    [][\A aid \in ArtifactIDs :
         LET proj == CurrentProjection
             nextProj == Replay(Ledger')
         IN proj.A[aid].id # "None" =>
                (nextProj.A[aid] = proj.A[aid] \/ nextProj.A[aid].id = "None")]_vars

I7_AppendOnly ==
    [][\A i \in 1..Len(Ledger) : Ledger[i] = Ledger'[i] /\ Len(Ledger') >= Len(Ledger)]_vars

Progress ==
    <>\E d \in DecisionIDs : CurrentProjection.D[d].id # "None"

=============================================================================
