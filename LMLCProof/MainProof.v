Require Export Coq.Classes.Init.
Require Import Coq.Program.Basics.
Require Import Coq.Program.Tactics.
Require Import Coq.Relations.Relation_Definitions.
Require Import Relation_Definitions.

From LMLCProof Require Import Utils Source Object Transpiler.

(** Beta-Eeduction properties *)

Lemma beta_red_is_reflexive : reflexive lambda_term (beta_star).
Proof. unfold reflexive. intro x. unfold beta_star.
       unfold refl_trans_closure. exists [x]. split.
  - simpl. reflexivity.
  - simpl. split.
    + reflexivity.
    + intro n. destruct n as [|n'].
      * reflexivity.
      * destruct (match n' with | 0 | _ => None end).
        ++ reflexivity.
        ++ reflexivity.
Qed.

Lemma beta_red_is_transitive : transitive lambda_term (beta_star).
Proof. unfold transitive. intros *. unfold beta_star. unfold refl_trans_closure.
       intros H G. destruct H as [l0 H]. destruct H as [H1 H2]. destruct H2 as [H2 H3].
                   destruct G as [l1 G]. destruct G as [G1 G2]. destruct G2 as [G2 G3].
       exists (l0 ++ l1). split.
  - 

Lemma beta_subset_beta_star : forall (M N : lambda_term), M ->b N -> M ->b* N.
Proof. intros M N H. unfold beta_star. unfold refl_trans_closure. exists [M;N].
       simpl. split.
  - reflexivity.
  - split.
    + reflexivity.
    + intro n. destruct n as [|n'].
      * apply H.
      * destruct n' as [|n''].
        -- reflexivity.
        -- destruct (match n'' with | 0 | _ => None end).
          ++ reflexivity.
          ++ reflexivity.
Qed.

Lemma beta_star_contextual_abs :
  forall (x : var) (M M': lambda_term), M ->b* M' -> Labs x M ->b* Labs x M'.
Admitted.

Lemma beta_star_contextual_appl :
  forall (M M' N N': lambda_term), M ->b* M' /\ N ->b* N' -> Lappl M N ->b* Lappl M' N'.
Admitted.

Lemma beta_star_contextual_appl'l :
  forall (M M' N: lambda_term), M ->b* M' -> Lappl M N ->b* Lappl M' N.
Admitted.

Lemma beta_star_contextual_appl'r :
  forall (M N N': lambda_term), N ->b* N' -> Lappl M N ->b* Lappl M N'.
Admitted.

(* MAIN PROOF *)

Lemma lmlc_substitution : forall (M N : ml_term) (x : var),
                          lmlc (ml_substitution M N x) = substitution (lmlc M) (lmlc N) x.
Proof. induction M as [ x | M1 IHappl1 M2 IHappl2 | x M' IHfunbody| f x M' IHfixfunbody
                      | M1 IHplus1 M2 IHplus2 | M1 IHminus1 M2 IHminus2 | M1 IHtimes1 M2 IHtimes2 | n
                      | M' IHgtz
                      | | | C IHifc T IHift E IHife
                      | HD IHconshd TL IHconsnil| |LST IHfoldlst OP IHfoldop INIT IHfoldinit
                      | P1 IHpair1 P2 IHpair2 | P IHfst | P IHsnd ].
  - intros *. simpl. destruct (eqb x0 x).
    + reflexivity.
    + reflexivity.
  -
Admitted.

(**
If you want to induct :
[ y | L1 IHappl1' L2 IHappl2' | y L IHfunbody'| g y L IHfixfunbody'
| L1 IHplus1' L2 IHplus2' | L1 IHminus1' L2 IHminus2' | L1 IHtimes1' L2 IHtimes2' | m
| L IHgtz'
| | | C' IHifc' T' IHift' E' IHife'
| HD' IHconshd' TL' IHconsnil' | | LST' IHfoldlst' OP' IHfoldop' INIT' IHfoldinit'
| P1' IHpair1' P2' IHpair2' | P' IHfst' | P' IHsnd' ]


If you want to destruct :
[ y | L1 L2 | y L | g y L
| L1 L2 | L1 L2 | L1 L2 | m
| L
| | | C' T' E'
| HD' TL' | | LST' OP' INIT'
| P1' P2' | P' | P' ]

*)

Theorem lmlc_is_correct : forall (M N : ml_term), M ->ml N -> (lmlc M) ->b* (lmlc N).
Proof. induction M as [ x | M1 IHappl1 M2 IHappl2 | x M' IHfunbody| f x M' IHfixfunbody
                      | M1 IHplus1 M2 IHplus2 | M1 IHminus1 M2 IHminus2 | M1 IHtimes1 M2 IHtimes2 | n
                      | M' IHgtz
                      | | | C IHifc T IHift E IHife
                      | HD IHconshd TL IHconsnil| |LST IHfoldlst OP IHfoldop INIT IHfoldinit
                      | P1 IHpair1 P2 IHpair2 | P IHfst | P IHsnd ].
(* M = x *)
  - intros N H. simpl in H. exfalso. apply H.
(* M = (M1)M2 *)
  - intros N H. simpl. simpl in H. destruct M1 as 
                                                  [ y | L1 L2 | y L | g y L
                                                  | L1 L2 | L1 L2 | L1 L2 | m
                                                  | L
                                                  | | | C' T' E'
                                                  | HD' TL' | | LST' OP' INIT'
                                                  | P1' P2' | P' | P' ].
    (* M1 = y *)
    + simpl. simpl in H. destruct N. all : try (exfalso; apply H).
      * simpl. destruct H.
        ++ exfalso. apply H.
        ++ destruct H as [H1 H2]. rewrite <- H1. simpl. apply IHappl2 in H2.
           apply beta_star_contextual_appl'r. apply H2.
    (* M1 = (L1)L2 *)
    + destruct N. all : try (exfalso ; apply H).
      * destruct H.
        ++ destruct H. apply IHappl1 in H. simpl. rewrite H0.
           apply beta_star_contextual_appl'l. simpl in H. apply H.
        ++ destruct H. rewrite H. simpl. apply beta_star_contextual_appl'r. apply IHappl2. apply H0.
    (* M1 = fun y -> L *)    
    + destruct N as 
                  [ z | T1 T2 | z T | h z T
                  | T1 T2 | T1 T2 | T1 T2 | m
                  | T
                  | | | C'' T'' E''
                  | HD'' TL'' | | LST'' OP'' INIT''
                  | P1'' P2'' | P'' | P'' ].
      * simpl. 
(* M = fun x -> M' *)
  -
(* M = fixfun f x -> M' *)
  -
(* M = M1 + M2 *)
  -
(* M = M1 - M2 *)
  -
(* M = M1 * M2 *)
  -
(* M = n [in NN] *)
  -
(* M = 0 < M *)
  -
(* M = true *)
  -
(* M = false *)
  -
(* M = If C then T else E *)
  -
(* M = HD::TL *)
  -
(* M = [] *)
  -
(* M = Fold_right LST OP INIT *)
  -
(* M = <P1,P2> *)
  -
(* M = fst P *)
(* M = snd P *)

