---------------------------- MODULE ARKHE_AASM ----------------------------
EXTENDS ARKHE_Projection, ARKHE_Replay, ARKHE_State

AASM_CredentialLifecycle ==
    \A a \in HumanAgents :
        LET proj == CurrentProjection
        IN proj.Creds[a].expiry > 0 \/ proj.Creds[a].agent = "None"

AASM_ConsentEnforcement ==
    \A agent \in HumanAgents :
        LET proj == CurrentProjection
        IN \A action \in proj.Perms[agent] :
            \E consent \in ActionIDs :
                proj.Consents[consent].agent = agent
                /\ proj.Consents[consent].granted = TRUE

AASM_AuditCompleteness ==
    \A eid \in EventIDs :
        LET proj == CurrentProjection
        IN (proj.E[eid].id # "None" /\ proj.E[eid].type = "DecisionMade") =>
            \E audit \in 1..Len(proj.Audits) : proj.Audits[audit].event = eid

AASM_DataMinimization ==
    \A a \in ArtifactIDs :
        LET proj == CurrentProjection
        IN proj.A[a].id # "None" => Len(proj.A[a].payload) <= 100

AASM_Resilience ==
    LET proj == CurrentProjection
    IN (Len(proj.Deployments) > 0) => \E deployment \in 1..Len(proj.Deployments) : proj.Deployments[deployment].status = "verified"

AASM_Invariants ==
    /\ AASM_CredentialLifecycle
    /\ AASM_ConsentEnforcement
    /\ AASM_AuditCompleteness
    /\ AASM_DataMinimization
    /\ AASM_Resilience

=============================================================================
