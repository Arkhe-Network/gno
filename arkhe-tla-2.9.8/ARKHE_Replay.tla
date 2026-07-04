---------------------------- MODULE ARKHE_Replay ----------------------------
EXTENDS ARKHE_Projection, ARKHE_State

RECURSIVE FoldApply(_, _, _)

FoldApply(seq, idx, proj) ==
    IF idx > Len(seq) THEN proj
    ELSE
        LET e == seq[idx]
            newProj == ApplyEvent(proj, e)
        IN IF newProj = proj
           THEN FoldApply(seq, idx + 1, proj)
           ELSE FoldApply(seq, idx + 1, newProj)

Replay(ledger) == FoldApply(ledger, 1, EmptyProjection)

CurrentProjection == Replay(Ledger)

=============================================================================
