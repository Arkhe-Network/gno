---------------------------- MODULE ARKHE_State ----------------------------
EXTENDS ARKHE_Projection

VARIABLES
    Ledger,
    activeAgent,
    activeLoop

vars == <<Ledger, activeAgent, activeLoop>>

TypeOK ==
    /\ Ledger \in StateType
    /\ Len(Ledger) =< MaxReplay
    /\ activeAgent \in HumanAgents \cup LoopAgents \cup {"none"} \cup {"secops", "devops", "devsecops"}
    /\ activeLoop \in LoopAgents \cup {
        "ontologic", "contextual", "prompt", "semantic", "causal",
        "reflective", "epistemic", "blindspot", "learning",
        "secops", "devops", "devsecops", "cve",
        "memory", "dialogue", "scheduling",
        "reasoning", "planning", "creative", "empathic",
        "ethical", "executive", "none"
       }

Init ==
    /\ Ledger = <<>>
    /\ activeAgent = "none"
    /\ activeLoop = "none"
    /\ TypeOK

=============================================================================
