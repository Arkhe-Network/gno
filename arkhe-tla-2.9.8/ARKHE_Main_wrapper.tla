---- MODULE ARKHE_Main_wrapper ----
EXTENDS ARKHE_Main
MaxReplayConstraint == Len(Ledger) =< MaxReplay
====
