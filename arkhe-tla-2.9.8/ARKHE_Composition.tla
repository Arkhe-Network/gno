---------------------------- MODULE ARKHE_Composition ----------------------------
EXTENDS ARKHE_AASM, ARKHE_TraceFix, ARKHE_Loops

SecOpsSafety ==
    [][ \A i \in 1..Len(Ledger) :
         Ledger[i].type = "SecOpsCheck" =>
            LET aid == Ledger[i].artifact
                proj == CurrentProjection
            IN (proj.A[aid].id # "None") =>
                proj.A[aid].hash = HashOf[aid] ]_vars

DevOpsSafety ==
    \A i \in 1..Len(Ledger) :
         Ledger[i].type = "DevOpsDeploy" =>
            LET aid == Ledger[i].artifact
            IN \E dep \in 1..Len(CurrentProjection.Deployments) :
                CurrentProjection.Deployments[dep].artifact = aid /\ CurrentProjection.Deployments[dep].status = "verified"

DevSecOpsSafety ==
    [][ \A i \in 1..Len(Ledger) :
         Ledger[i].type = "DevSecOpsAudit" =>
            LET aid == Ledger[i].artifact
                proj == CurrentProjection
            IN \E audit \in 1..Len(proj.Audits) :
                proj.Audits[audit].artifact = aid /\ proj.Audits[audit].result = "pass" ]_vars

GlobalSafety == SecOpsSafety /\ DevOpsSafety /\ DevSecOpsSafety

CompositionSafety == GlobalSafety

NoInterference ==
    \A i, j \in 1..Len(Ledger) :
         i # j /\ Ledger[i].type = "DecisionMade" /\ Ledger[j].type = "DecisionMade" /\ Ledger[i].id = Ledger[j].id =>
            Ledger[i].artifact = Ledger[j].artifact

=============================================================================
