---------------------------- MODULE ARKHE_Types ----------------------------
EXTENDS Integers, FiniteSets, Sequences, TLC

CONSTANT
    None,
    ArtifactIDs,
    EventIDs,
    DecisionIDs,
    ActionIDs,
    HumanAgents,
    LoopAgents,
    Payloads,
    Hashes,
    MaxReplay

HashOf[a \in ArtifactIDs] == "hash1"

ASSUME
    /\ Payloads # {}
    /\ HumanAgents # {}
    /\ MaxReplay \in Int /\ MaxReplay >= 1

ConfidenceLevel == {0, 1, 2}

EventType == {
    "ArtifactAdded", "ArtifactRemoved", "DecisionMade", "BeliefUpdated",
    "ConsentGranted", "DeploymentVerified", "CredentialIssued",
    "SecOpsCheck", "DevOpsDeploy", "DevSecOpsAudit",
    "OntologyInferred", "IntentClassified",
    "ContextRetrieved", "ContextUpdated",
    "PromptGenerated", "LLMResponse",
    "SemanticGrounded", "AmbiguityResolved",
    "CausalGraphUpdated", "InterventionPlanned",
    "SelfAssessment", "StrategyAdjusted",
    "UncertaintyQuantified", "KnowledgeGap",
    "BiasDetected", "MitigationSuggested",
    "ModelUpdate", "GradientComputed",
    "SecurityAlert", "ThreatMitigated",
    "DeployInitiated", "RollbackExecuted",
    "AuditPassed", "ComplianceChecked",
    "CVEPrioritized", "PatchDeployed",
    "MemoryConsolidated", "MemoryPruned",
    "MessageSent", "CollaborationEstablished",
    "TaskScheduled", "ResourceAllocated",
    "DecisionAccepted", "DecisionRejected",
    "BeliefStrengthened", "BeliefWeakened",
    "CausalLinkAdded", "CausalLinkRemoved",
    "NovelIdeaGenerated", "IdeaEvaluated",
    "EmotionDetected", "EmpathicResponse",
    "EthicalCheckPassed", "EthicalViolation",
    "TaskDelegated", "TaskCompleted",
    "None"
}

DecisionType == {"Accept", "Reject", "Defer"}

Artifact == [id: ArtifactIDs \cup {"None"}, payload: Payloads \cup {"None"}, hash: Hashes \cup {"None"}]

MaybePayload    == Payloads   \cup {"None"}

Event == [
    id: EventIDs \cup {"None"},
    type: EventType,
    artifact: ArtifactIDs \cup ActionIDs \cup {"None"},
    payload: MaybePayload,
    timestamp: Int,
    agent: HumanAgents \cup LoopAgents \cup {"secops", "devops", "devsecops"} \cup {"None"},
    action: ActionIDs \cup {"None"}
]

Decision == [id: DecisionIDs \cup {"None"}, event: EventIDs \cup {"None"}, type: DecisionType, confidence: ConfidenceLevel]

Credential == [agent: HumanAgents \cup {"None"}, expiry: Int, issuer: HumanAgents \cup {"None"}]
Consent    == [agent: HumanAgents \cup {"None"}, action: ActionIDs \cup {"None"}, granted: BOOLEAN, timestamp: Int]
Deployment == [id: Int, artifact: ArtifactIDs \cup {"None"}, status: {"pending","verified","failed","None"}, timestamp: Int]
Audit      == [id: Int, event: EventIDs \cup {"None"}, artifact: ArtifactIDs \cup ActionIDs \cup {"None"}, action: ActionIDs \cup ArtifactIDs \cup {"None"},
               agent: HumanAgents \cup LoopAgents \cup {"secops", "devops", "devsecops"} \cup {"None"}, result: {"pass","fail","None"}, timestamp: Int]

DummyArtifact == [id |-> "None", payload |-> "None", hash |-> "None"]
DummyEvent == [id |-> "None", type |-> "None", artifact |-> "None", payload |-> "None", timestamp |-> 0, agent |-> "None", action |-> "None"]
DummyDecision == [id |-> "None", event |-> "None", type |-> "Accept", confidence |-> 0]
DummyCredential == [agent |-> "None", expiry |-> 0, issuer |-> "None"]
DummyConsent == [agent |-> "None", action |-> "None", granted |-> FALSE, timestamp |-> 0]

MaybeArtifact == Artifact
MaybeEvent    == Event
MaybeDecision == Decision
MaybeCredential == Credential
MaybeConsent    == Consent
MaybeDeployment == Deployment
MaybeAudit      == Audit

StateType == Seq(Event)

=============================================================================
