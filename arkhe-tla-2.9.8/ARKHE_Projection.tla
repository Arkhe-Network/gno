---------------------------- MODULE ARKHE_Projection ----------------------------
EXTENDS ARKHE_Types

ProjectionType == [
    A : [ArtifactIDs -> MaybeArtifact],
    E : [EventIDs    -> MaybeEvent],
    D : [DecisionIDs -> MaybeDecision],
    C : [EventIDs    -> ConfidenceLevel],
    B : [EventIDs    -> BOOLEAN],
    Creds : [HumanAgents -> MaybeCredential],
    Consents : [ActionIDs -> MaybeConsent],
    Perms : [HumanAgents -> SUBSET ActionIDs],
    Deployments : Seq(Deployment),
    Audits : Seq(Audit)
]

EmptyProjection == [
    A |-> [id \in ArtifactIDs |-> DummyArtifact],
    E |-> [id \in EventIDs    |-> DummyEvent],
    D |-> [id \in DecisionIDs |-> DummyDecision],
    C |-> [id \in EventIDs    |-> 0],
    B |-> [id \in EventIDs    |-> FALSE],
    Creds |-> [a \in HumanAgents |-> DummyCredential],
    Consents |-> [a \in ActionIDs |-> DummyConsent],
    Perms |-> [a \in HumanAgents |-> {}],
    Deployments |-> <<>>,
    Audits |-> <<>>
]

ApplyEvent(proj, e) ==
    IF e.type = "ArtifactAdded" THEN
        IF e.artifact \in ArtifactIDs /\ proj.A[e.artifact].id = "None"
        THEN [proj EXCEPT !.A[e.artifact] = [id |-> e.artifact, payload |-> e.payload, hash |-> HashOf[e.artifact]],
                  !.E[e.id] = e]
        ELSE proj
    ELSE IF e.type = "ArtifactRemoved" THEN
        IF e.artifact \in ArtifactIDs /\ proj.A[e.artifact].id # "None"
        THEN [proj EXCEPT !.A[e.artifact] = DummyArtifact, !.E[e.id] = e]
        ELSE proj
    ELSE IF e.type = "DecisionMade" THEN
        IF e.id \in EventIDs /\ proj.E[e.id].id # "None"
           /\ e.artifact \in ArtifactIDs /\ proj.A[e.artifact].id # "None"
           /\ \E did \in DecisionIDs : proj.D[did].id = "None"
        THEN
            LET newDid == CHOOSE did \in DecisionIDs : proj.D[did].id = "None"
                newDec == [id |-> newDid, event |-> e.id, type |-> "Accept", confidence |-> 2]
                audit == [id |-> Len(proj.Audits)+1, event |-> e.id,
                          artifact |-> e.artifact, action |-> e.artifact,
                          agent |-> e.agent, result |-> "pass",
                          timestamp |-> e.timestamp]
            IN [proj EXCEPT !.D[newDid] = newDec,
                            !.Audits = Append(proj.Audits, audit),
                            !.E[e.id] = e]
        ELSE proj
    ELSE IF e.type = "BeliefUpdated" THEN
        IF proj.E[e.id].id # "None"
        THEN [proj EXCEPT !.B[e.id] = TRUE, !.E[e.id] = e]
        ELSE proj
    ELSE IF e.type = "ConsentGranted" THEN
        IF e.agent \in HumanAgents /\ e.action \in ActionIDs
        THEN
            LET cons == [agent |-> e.agent, action |-> e.action, granted |-> TRUE, timestamp |-> e.timestamp]
                newPerms == [proj.Perms EXCEPT ![e.agent] = proj.Perms[e.agent] \cup {e.action}]
            IN [proj EXCEPT !.Consents[e.action] = cons, !.Perms = newPerms, !.E[e.id] = e]
        ELSE proj
    ELSE IF e.type = "DeploymentVerified" THEN
        IF e.artifact \in ArtifactIDs
        THEN
            LET dep == [id |-> Len(proj.Deployments)+1, artifact |-> e.artifact,
                        status |-> "verified", timestamp |-> e.timestamp]
            IN [proj EXCEPT !.Deployments = Append(proj.Deployments, dep), !.E[e.id] = e]
        ELSE proj
    ELSE IF e.type = "CredentialIssued" THEN
        IF e.agent \in HumanAgents
        THEN
            LET cred == [agent |-> e.agent, expiry |-> e.timestamp + 3600, issuer |-> e.agent]
            IN [proj EXCEPT !.Creds[e.agent] = cred, !.E[e.id] = e]
        ELSE proj
    ELSE
        [proj EXCEPT !.E[e.id] = e]

ExistingArtifacts(proj) == { aid \in ArtifactIDs : proj.A[aid].id # "None" }
ExistingEvents(proj)    == { eid \in EventIDs  : proj.E[eid].id # "None" }
ExistingDecisions(proj) == { did \in DecisionIDs : proj.D[did].id # "None" }

=============================================================================
