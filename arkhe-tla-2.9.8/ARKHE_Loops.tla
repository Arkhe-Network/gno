---------------------------- MODULE ARKHE_Loops ----------------------------
EXTENDS ARKHE_State, ARKHE_Replay

Loops == {
    "ontologic", "contextual", "prompt", "semantic", "causal",
    "reflective", "epistemic", "blindspot", "learning",
    "secops", "devops", "devsecops", "cve",
    "memory", "dialogue", "scheduling",
    "reasoning", "planning", "creative", "empathic",
    "ethical", "executive"
}

LoopEventTypes[loop \in Loops] ==
    CASE loop = "ontologic"   -> {"OntologyInferred", "IntentClassified"}
      [] loop = "contextual"  -> {"ContextRetrieved", "ContextUpdated"}
      [] loop = "prompt"      -> {"PromptGenerated", "LLMResponse"}
      [] loop = "semantic"    -> {"SemanticGrounded", "AmbiguityResolved"}
      [] loop = "causal"      -> {"CausalGraphUpdated", "InterventionPlanned"}
      [] loop = "reflective"  -> {"SelfAssessment", "StrategyAdjusted"}
      [] loop = "epistemic"   -> {"UncertaintyQuantified", "KnowledgeGap"}
      [] loop = "blindspot"   -> {"BiasDetected", "MitigationSuggested"}
      [] loop = "learning"    -> {"ModelUpdate", "GradientComputed"}
      [] loop = "secops"      -> {"SecurityAlert", "ThreatMitigated"}
      [] loop = "devops"      -> {"DeployInitiated", "RollbackExecuted"}
      [] loop = "devsecops"   -> {"AuditPassed", "ComplianceChecked"}
      [] loop = "cve"         -> {"CVEPrioritized", "PatchDeployed"}
      [] loop = "memory"      -> {"MemoryConsolidated", "MemoryPruned"}
      [] loop = "dialogue"    -> {"MessageSent", "CollaborationEstablished"}
      [] loop = "scheduling"  -> {"TaskScheduled", "ResourceAllocated"}
      [] loop = "reasoning"   -> {"DecisionAccepted", "DecisionRejected"}
      [] loop = "planning"    -> {"CausalLinkAdded", "CausalLinkRemoved"}
      [] loop = "creative"    -> {"NovelIdeaGenerated", "IdeaEvaluated"}
      [] loop = "empathic"    -> {"EmotionDetected", "EmpathicResponse"}
      [] loop = "ethical"     -> {"EthicalCheckPassed", "EthicalViolation"}
      [] loop = "executive"   -> {"TaskDelegated", "TaskCompleted"}
      [] OTHER -> {}

LoopAction(loop, artifact, payload, agent, etype) ==
    \E eid \in EventIDs :
        /\ \A i \in 1..Len(Ledger) : Ledger[i].id # eid
        /\ etype \in LoopEventTypes[loop]
        /\ payload \in MaybePayload
        /\ agent \in LoopAgents
        /\ Ledger' = Append(Ledger,
            [id |-> eid, type |-> etype,
             artifact |-> artifact, payload |-> payload,
             timestamp |-> Len(Ledger) + 1, agent |-> agent,
             action |-> "None"])
        /\ activeLoop' = loop
        /\ UNCHANGED activeAgent

StopLoop ==
    \E loop \in Loops :
        /\ activeLoop = loop
        /\ activeLoop' = "none"
        /\ UNCHANGED <<Ledger, activeAgent>>

OntologicAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["ontologic"]:
        LoopAction("ontologic", artifact, payload, agent, etype)

ContextualAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["contextual"]:
        LoopAction("contextual", artifact, payload, agent, etype)

PromptAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["prompt"]:
        LoopAction("prompt", artifact, payload, agent, etype)

SemanticAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["semantic"]:
        LoopAction("semantic", artifact, payload, agent, etype)

CausalAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["causal"]:
        LoopAction("causal", artifact, payload, agent, etype)

ReflectiveAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["reflective"]:
        LoopAction("reflective", artifact, payload, agent, etype)

EpistemicAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["epistemic"]:
        LoopAction("epistemic", artifact, payload, agent, etype)

BlindspotAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["blindspot"]:
        LoopAction("blindspot", artifact, payload, agent, etype)

LearningAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["learning"]:
        LoopAction("learning", artifact, payload, agent, etype)

SecOpsActionL ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["secops"]:
        LoopAction("secops", artifact, payload, agent, etype)

DevOpsActionL ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["devops"]:
        LoopAction("devops", artifact, payload, agent, etype)

DevSecOpsActionL ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["devsecops"]:
        LoopAction("devsecops", artifact, payload, agent, etype)

CVEAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["cve"]:
        LoopAction("cve", artifact, payload, agent, etype)

MemoryAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["memory"]:
        LoopAction("memory", artifact, payload, agent, etype)

DialogueAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["dialogue"]:
        LoopAction("dialogue", artifact, payload, agent, etype)

SchedulingAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["scheduling"]:
        LoopAction("scheduling", artifact, payload, agent, etype)

ReasoningAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["reasoning"]:
        LoopAction("reasoning", artifact, payload, agent, etype)

PlanningAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["planning"]:
        LoopAction("planning", artifact, payload, agent, etype)

CreativeAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["creative"]:
        LoopAction("creative", artifact, payload, agent, etype)

EmpathicAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["empathic"]:
        LoopAction("empathic", artifact, payload, agent, etype)

EthicalAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["ethical"]:
        LoopAction("ethical", artifact, payload, agent, etype)

ExecutiveAction ==
    \E artifact \in ArtifactIDs, payload \in MaybePayload, agent \in LoopAgents, etype \in LoopEventTypes["executive"]:
        LoopAction("executive", artifact, payload, agent, etype)

NextLoops ==
    \/ OntologicAction \/ ContextualAction \/ PromptAction \/ SemanticAction \/ CausalAction \/ ReflectiveAction \/ EpistemicAction \/ BlindspotAction \/ LearningAction \/ SecOpsActionL \/ DevOpsActionL \/ DevSecOpsActionL \/ CVEAction \/ MemoryAction \/ DialogueAction \/ SchedulingAction \/ ReasoningAction \/ PlanningAction \/ CreativeAction \/ EmpathicAction \/ EthicalAction \/ ExecutiveAction \/ StopLoop

SpecLoops ==
    Init
    /\ [][NextLoops]_vars
    /\ WF_vars(OntologicAction)
    /\ WF_vars(ContextualAction)
    /\ WF_vars(PromptAction)
    /\ WF_vars(SemanticAction)
    /\ WF_vars(CausalAction)
    /\ WF_vars(ReflectiveAction)
    /\ WF_vars(EpistemicAction)
    /\ WF_vars(BlindspotAction)
    /\ WF_vars(LearningAction)
    /\ WF_vars(SecOpsActionL)
    /\ WF_vars(DevOpsActionL)
    /\ WF_vars(DevSecOpsActionL)
    /\ WF_vars(CVEAction)
    /\ WF_vars(MemoryAction)
    /\ WF_vars(DialogueAction)
    /\ WF_vars(SchedulingAction)
    /\ WF_vars(ReasoningAction)
    /\ WF_vars(PlanningAction)
    /\ WF_vars(CreativeAction)
    /\ WF_vars(EmpathicAction)
    /\ WF_vars(EthicalAction)
    /\ WF_vars(ExecutiveAction)
    /\ WF_vars(StopLoop)

AllLoopsLiveness ==
    \A loop \in Loops : <>(activeLoop = loop)

=============================================================================
