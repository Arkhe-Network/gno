---------------------------- MODULE ARKHE_TraceFix ----------------------------
EXTENDS ARKHE_Transition

Agents == {"secops", "devops", "devsecops"}

SecOpsAction ==
    \E eid \in EventIDs, artifact \in ArtifactIDs :
        LET e == [id |-> eid, type |-> "SecOpsCheck",
                  artifact |-> artifact, payload |-> "None",
                  timestamp |-> Len(Ledger) + 1, agent |-> "secops",
                  action |-> "None"]
        IN AppendEvent(e) /\ activeAgent' = "secops"

DevOpsAction ==
    \E eid \in EventIDs, eid2 \in EventIDs, artifact \in ArtifactIDs :
        eid # eid2
        /\ LET e1 == [id |-> eid, type |-> "DevOpsDeploy",
                      artifact |-> artifact, payload |-> "None",
                      timestamp |-> Len(Ledger) + 1, agent |-> "devops",
                      action |-> "None"]
                e2 == [id |-> eid2, type |-> "DeploymentVerified",
                      artifact |-> artifact, payload |-> "None",
                      timestamp |-> Len(Ledger) + 2, agent |-> "devops",
                      action |-> "None"]
                newLedger1 == Append(Ledger, e1)
                newLedger2 == Append(newLedger1, e2)
        IN Ledger' = newLedger2 /\ activeAgent' = "devops"

DevSecOpsAction ==
    \E eid \in EventIDs, artifact \in ArtifactIDs :
        LET e == [id |-> eid, type |-> "DevSecOpsAudit",
                  artifact |-> artifact, payload |-> "None",
                  timestamp |-> Len(Ledger) + 1, agent |-> "devsecops",
                  action |-> "None"]
        IN AppendEvent(e) /\ activeAgent' = "devsecops"

StopAgent ==
    \E a \in Agents :
        /\ activeAgent = a
        /\ activeAgent' = "none"
        /\ UNCHANGED <<Ledger, activeLoop>>

NextTraceFix ==
    SecOpsAction \/ DevOpsAction \/ DevSecOpsAction \/ StopAgent

SpecTraceFix ==
    Init
    /\ [][NextTraceFix]_vars
    /\ WF_vars(SecOpsAction)
    /\ WF_vars(DevOpsAction)
    /\ WF_vars(DevSecOpsAction)
    /\ WF_vars(StopAgent)

AgentLiveness ==
    \A a \in Agents : <>(activeAgent = a)

=============================================================================
