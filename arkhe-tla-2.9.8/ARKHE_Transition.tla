---------------------------- MODULE ARKHE_Transition ----------------------------
EXTENDS ARKHE_State, ARKHE_Replay

AppendEvent(e) ==
    /\ Ledger' = Append(Ledger, e)
    /\ UNCHANGED <<activeAgent, activeLoop>>

AddArtifact ==
    \E eid \in EventIDs, artifact \in ArtifactIDs, payload \in Payloads :
        LET e == [id |-> eid, type |-> "ArtifactAdded",
                  artifact |-> artifact, payload |-> payload,
                  timestamp |-> Len(Ledger) + 1, agent |-> "None",
                  action |-> "None"]
        IN AppendEvent(e)

RemoveArtifact ==
    \E eid \in EventIDs, artifact \in ArtifactIDs :
        LET e == [id |-> eid, type |-> "ArtifactRemoved",
                  artifact |-> artifact, payload |-> "None",
                  timestamp |-> Len(Ledger) + 1, agent |-> "None",
                  action |-> "None"]
        IN AppendEvent(e)

MakeDecision ==
    \E eid \in EventIDs, artifact \in ArtifactIDs, agent \in HumanAgents :
        LET e == [id |-> eid, type |-> "DecisionMade",
                  artifact |-> artifact, payload |-> "None",
                  timestamp |-> Len(Ledger) + 1, agent |-> agent,
                  action |-> "None"]
        IN AppendEvent(e)

UpdateBelief ==
    \E eid \in EventIDs, artifact \in ArtifactIDs :
        LET e == [id |-> eid, type |-> "BeliefUpdated",
                  artifact |-> artifact, payload |-> "None",
                  timestamp |-> Len(Ledger) + 1, agent |-> "None",
                  action |-> "None"]
        IN AppendEvent(e)

ConsentGranted ==
    \E eid \in EventIDs, agent \in HumanAgents, action \in ActionIDs :
        LET e == [id |-> eid, type |-> "ConsentGranted",
                  artifact |-> action,   (* reuso documentado *)
                  payload |-> "None",
                  timestamp |-> Len(Ledger) + 1, agent |-> agent,
                  action |-> action]   (* campo real *)
        IN AppendEvent(e)

DeploymentVerified ==
    \E eid \in EventIDs, artifact \in ArtifactIDs :
        LET e == [id |-> eid, type |-> "DeploymentVerified",
                  artifact |-> artifact, payload |-> "None",
                  timestamp |-> Len(Ledger) + 1, agent |-> "None",
                  action |-> "None"]
        IN AppendEvent(e)

Next ==
    AddArtifact \/ RemoveArtifact \/ MakeDecision \/ UpdateBelief \/ ConsentGranted \/ DeploymentVerified

Spec ==
    Init
    /\ [][Next]_vars
    /\ WF_vars(AddArtifact) /\ WF_vars(RemoveArtifact)
    /\ WF_vars(MakeDecision) /\ WF_vars(UpdateBelief)
    /\ WF_vars(ConsentGranted) /\ WF_vars(DeploymentVerified)

=============================================================================
