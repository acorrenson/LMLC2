Require Export Coq.Classes.Init.
Require Import Coq.Program.Basics.
Require Import Coq.Program.Tactics.
Require Import Coq.Relations.Relation_Definitions.
Require Import Relation_Definitions.
From Coq Require Import Lists.List.
Import ListNotations.
Require Import PeanoNat.

From LMLCProof Require Import Utils Source Object Transpiler.

(** Beta-Reduction properties *)

Lemma beta_red_is_reflexive : reflexive lambda_term (beta_star).
Proof. unfold reflexive. intro x. unfold beta_star. apply refl.
Qed.

Lemma S_predn : forall (n : nat), n = 0 \/ S (pred n) = n.
Proof. 
  intros [|n].
  - simpl. left. reflexivity.
  - simpl. right. reflexivity.
Qed.

Lemma S_predn' : forall (n : nat), 0 < n -> S (pred n) = n.
Proof. 
  intros *. intro H.  Abort.


Lemma pred_minus : forall (n : nat), pred n = n - 1.
Proof.
  destruct n.
  - reflexivity.
  - simpl. rewrite minus_n_0. reflexivity.
Qed.

Lemma succ_church : forall n : nat,
  church_succ2 (church_int n) = church_int (S n).
Proof.
  intros n. unfold church_int. unfold church_int_free. unfold church_succ2.
  destruct n as [|n'].
  - reflexivity.
  - reflexivity.
Qed.

Example H3Modif : forall (n0 : nat) (h0 : lambda_term) (ht0 : lambda_term) (tlt0 : list lambda_term),
     (forall n : nat,
     match find_opt (h0 :: ht0 :: tlt0) n with
     | Some a =>
         match find_opt (h0 :: ht0 :: tlt0) (S n) with
         | Some b => a ->b b
         | None => True
         end
     | None => True
     end) -> match find_opt (h0 :: ht0 :: tlt0) (S n0) with
     | Some a =>
         match find_opt (h0 :: ht0 :: tlt0) (S (S n0)) with
         | Some b => a ->b b
         | None => True
         end
     | None => True
     end.
Proof. intros *. intro H3. apply H3. Qed.

Lemma beta_red_is_transitive : transitive lambda_term (beta_star).
Proof. unfold transitive. intros *. unfold beta_star. apply trans. Qed.

Lemma bredstar_contextual_abs :
  forall (x : var) (M M': lambda_term), M ->b* M' -> Labs x M ->b* Labs x M'.
Proof. intros. induction H as [M'|M1 M2 M3 Red1 IHred1 Red2 IHred2|M N Honestep].
  - apply refl.
  - apply trans with (y := Labs x M2).
    + apply IHred1.
    + apply IHred2.
  - apply onestep. apply contextual_lambda with (x := x) in Honestep. apply Honestep.
Qed.

Lemma bredstar_contextual_appl_function :
  forall (M M' N : lambda_term), M ->b* M' -> Lappl M N ->b* Lappl M' N.
Proof. intros *. intros red. induction red as [M'|M1 M2 M3 Red1 IHred1 Red2 IHred2|M M' Honestep].
  - apply refl.
  - apply trans with (y := Lappl M2 N).
    + apply IHred1.
    + apply IHred2.
  - apply onestep. apply contextual_function. apply Honestep.
Qed.

Lemma bredstar_contextual_appl_argument :
  forall (M N N': lambda_term), N ->b* N' -> Lappl M N ->b* Lappl M N'.
Proof. intros *. intros red.  induction red as [N'|N1 N2 N3 Red1 IHred1 Red2 IHred2|N N' Honestep].
  - apply refl.
  - apply trans with (y := Lappl M N2).
    + apply IHred1.
    + apply IHred2.
  - apply onestep. apply contextual_argument. apply Honestep.
Qed.

Lemma bredstar_contextual_appl :
  forall (M M' N N': lambda_term), M ->b* M' -> N ->b* N' -> Lappl M N ->b* Lappl M' N'.
Proof. intros *. intros redlhs redrhs. apply trans with (y := Lappl M' N).
  - apply bredstar_contextual_appl_function. apply redlhs.
  - apply bredstar_contextual_appl_argument. apply redrhs.
Qed.

Lemma substitution_fresh_l : forall (M N : lambda_term) (x : var), in_list (fvL M) x = false -> substitution M N x = M.
Proof. intros M P x H. induction M as [y | M IHM N IHN | y M IHM].
  - simpl. simpl in H. destruct (x =? y).
    + inversion H.
    + reflexivity.
  - simpl. simpl in H. apply in_list_app1 in H. destruct H as [H1 H2].
    rewrite IHM. rewrite IHN. reflexivity. apply H2. apply H1.
  - simpl. destruct (x =? y) eqn:eqxy.
    + reflexivity.
    + simpl in H. assert (cont : substitution M P x = M).
      * apply IHM. apply in_list_remove with (y := y). apply H. apply Nat.eqb_neq. apply eqxy.
      * rewrite cont. reflexivity.
Qed.


Lemma beta_alpha : forall (M M' N N' : lambda_term), M ->b* N -> M ~a M' -> N ~a N' -> M' ->b* N'.
Proof. intros. apply alpha_quot in H0. apply alpha_quot in H1. rewrite <- H0. rewrite <- H1.
  apply H. Qed.

Lemma beta_alpha_toplvl : forall (M N : lambda_term) (x y z : var), ~(In z (fvL M)) -> ~(In z (fvL N)) ->
        Labs z (substitution M (Lvar z) x) ->b* Labs z (substitution N (Lvar z) y) -> Labs x M ->b* Labs y N.
Proof. intros M N x y z H G H0. apply beta_alpha with (M := Labs z (substitution M (Lvar z) x)) (N := Labs z (substitution N (Lvar z) y)).
  - apply H0.
  - apply alpha_sym. apply alpha_rename with (N := M).
    + apply H.
    + apply alpha_refl.
    + reflexivity.
  - apply alpha_sym. apply alpha_rename with (N := N).
    + apply G.
    + apply alpha_refl.
    + reflexivity.
Qed.

Lemma subst_lambda_cont : forall (M N : lambda_term) (x y : var), x <> y ->
                                    substitution (Labs x M) N y = Labs x (substitution M N y).
Proof. intros. simpl. apply Nat.eqb_neq in H. rewrite Nat.eqb_sym. rewrite H. reflexivity. Qed.

Lemma subst_appl_cont : forall (M N P : lambda_term) (x : var),
                                    substitution (Lappl M N) P x = Lappl (substitution M P x) (substitution N P x).
Proof. reflexivity. Qed.

(* MAIN PROOF *)
Lemma lmlc_substitution : forall (M N : ml_term) (x : var),
                          lmlc (ml_substitution M N x) = substitution (lmlc M) (lmlc N) x.
Proof. induction M as [ x | M1 IHappl1 M2 IHappl2 | x M' IHfunbody| f x M' IHfixfunbody
                      | M1 IHplus1 M2 IHplus2 | M1 IHminus1 M2 IHminus2 | M1 IHtimes1 M2 IHtimes2 | n
                      | M' IHgtz
                      | | C IHifc T IHift E IHife
                      | HD IHconshd TL IHconsnil| |LST IHfoldlst OP IHfoldop INIT IHfoldinit
                      | P1 IHpair1 P2 IHpair2 | P IHfst | P IHsnd ].
(* M = x *)
  - intros *. simpl. destruct (x0 =? x).
    + reflexivity.
    + reflexivity.
(* M = (M1)M2 *)
  - intros *. simpl. rewrite IHappl1. rewrite IHappl2. reflexivity.
(* M = fun x -> M' *)
  - intros *. simpl. destruct (x0 =? x).
    + reflexivity.
    + simpl. rewrite IHfunbody. reflexivity.
(* M = fixfun f x -> M' *)
  - admit.
(* M = M1 + M2 *)
  - admit.
(* M = M1 - M2 *)
  - admit.
(* M = M1 * M2 *)
  - admit.
(* M = n [in NN] *)
  - intros. simpl. destruct (x =? 1) eqn:eqx1.
    + reflexivity.
    + destruct (x =? 0) eqn:eqx0.
      * reflexivity.
      * { induction n as [|n' IHn'].
          - simpl. rewrite eqx0. reflexivity.
          - admit.
        }
(* M = 0 < M *)
  - simpl. symmetry. rewrite <- IHgtz. symmetry. unfold church_gtz. unfold church_true. unfold church_false. admit.
(* M = true *)
  - intros. simpl. destruct b.
    + unfold church_true. destruct (x =? 0) eqn:eqx0.
      * simpl. rewrite eqx0. reflexivity.
      * destruct (x =? 1) eqn:eqx1.
        -- simpl. rewrite eqx0. rewrite eqx1. reflexivity.
        -- simpl. rewrite eqx0. rewrite eqx1. reflexivity.
    + unfold church_false. destruct (x =? 0) eqn:eqx0.
      * simpl. rewrite eqx0. reflexivity.
      * destruct (x =? 1) eqn:eqx1.
        -- simpl. rewrite eqx0. rewrite eqx1. reflexivity.
        -- simpl. rewrite eqx0. rewrite eqx1. reflexivity.
(* M = If C then T else E *)
  - admit.
(* M = HD::TL *)
  - admit.
(* M = [] *)
  - intros. simpl. destruct (x =? 0) eqn:eqx0.
      * simpl. reflexivity.
      * destruct (x =? 1) eqn:eqx1.
        -- reflexivity.
        -- reflexivity.
(* M = Fold_right LST OP INIT *)
  - admit.
(* M = <P1,P2> *)
  - admit.
(* M = fst P *)
  - intros. simpl. rewrite IHfst. destruct (x =? 1) eqn:eqx1.
    + admit.
    + destruct (x =? 2) eqn:eqx2.
      * admit.
      * admit.
(* M = snd P *)
  - admit.
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

Theorem lmlc_correct : forall (M N : ml_term), M ->ml N -> (lmlc M) ->b* (lmlc N).
Proof. intros.
induction H as
[
    x M M' HM IHfun_contextual
  | f x M M' HM IHfixfun_contextual
  | M M' N HM IHappl_contextual
  | M N N' HN IHappl_contextual
  | M M' N HM IHplus_contextual
  | M N N' HN IHplus_contextual
  | M M' N HM IHminus_contextual
  | M N N' HN IHminus_contextual
  | M M' N HM IHtimes_contextual
  | M N N' HN IHtimes_contextual
  | M M' N IHgtz_contextual
  | C C' T E HC IHif_contextual
  | C T T' E HT IHif_contextual
  | C T E E' HE IHif_contextual
  | HD HD' TL HHD IHcons_contextual
  | HD TL TL' HTL IHcons_contextual
  | LST LST' FOO INIT HLST IHfold_contextual
  | LST FOO FOO' INIT HFOO IHfold_contextual
  | LST FOO INIT INIT' HINIT IHfold_contextual
  | P1 P1' P2 HP1 IHpair
  | P1 P2 P2' HP2 IHpair
  | P P' HP IHfst
  | P P' HP IHsnd
  | x M N
  | f x M IHfixfun
  | n m
  | n m
  | n m
  | n
  | FOO INIT
  | HD TL FOO INIT
  | P1 P2
  | P1 P2
].
(* contextual cases *)
  (* fun *)
  - simpl. apply bredstar_contextual_abs. apply IHfun_contextual.
  (* fixfun *)
  - simpl. unfold turing_fixpoint_applied. apply bredstar_contextual_appl.
    + apply bredstar_contextual_abs. apply bredstar_contextual_abs. apply IHfixfun_contextual.
    + apply bredstar_contextual_appl.
      * apply refl.
      * apply bredstar_contextual_abs. apply bredstar_contextual_abs. apply IHfixfun_contextual.
  (* application - function *)
  - simpl. apply bredstar_contextual_appl.
    + apply IHappl_contextual.
    + apply refl.
  (* application - argument *)
  - simpl. apply bredstar_contextual_appl.
    + apply refl.
    + apply IHappl_contextual.
  (* plus - lhs *)
  - simpl. unfold church_plus. remember (fresh (fvL (lmlc M) ++ fvL (lmlc M') ++ fvL (lmlc N))) as new_x.
    remember (fresh (fvL (lmlc M) ++ fvL (lmlc N))) as x. remember (fresh (fvL (lmlc M') ++ fvL (lmlc N))) as x'.
    apply beta_alpha_toplvl with (z := new_x).
    + admit.
    + admit.
    + apply bredstar_contextual_abs.
      remember (fresh [x]) as y.
      remember (fresh [x']) as y'. simpl.
      assert (x =? y = false). { admit. } assert (x' =? y' = false). { admit. }
      rewrite H. rewrite H0. remember (fresh [new_x]) as new_y.
      apply beta_alpha_toplvl with (z := new_y).
      * admit.
      * admit.
      * apply bredstar_contextual_abs. rewrite Nat.eqb_refl. rewrite Nat.eqb_refl.
        simpl. rewrite Nat.eqb_refl. rewrite Nat.eqb_refl.
        assert (y =? new_x = false). { admit. } assert (y' =? new_x = false). { admit. }
        rewrite H1. rewrite H2. { apply bredstar_contextual_appl.
          - apply bredstar_contextual_appl.
            + admit.
            + apply refl.
          - apply bredstar_contextual_appl.
            + apply bredstar_contextual_appl.
              * {   rewrite substitution_fresh_l.
                  - rewrite substitution_fresh_l.
                    + {   rewrite substitution_fresh_l.
                        - rewrite substitution_fresh_l.
                          + apply IHplus_contextual.
                          + admit.
                        - admit.
                      }
                    + admit.
                  - admit.
                }
              * apply refl.
            + apply refl.
        }
  (* plus - rhs *)
  - admit.
  (* minus - lhs *)
  - admit.
  (* minus - rhs *)
  - admit.
  (* times - lhs *)
  - admit.
  (* times - rhs *)
  - admit.
  (* gtz *)
  - simpl. unfold church_gtz. apply bredstar_contextual_appl.
    + apply bredstar_contextual_appl.
      * apply IHgtz_contextual.
      * apply refl.
    + apply refl.
  (* if then else - condition*)
  - simpl. unfold church_if. apply bredstar_contextual_appl.
    + apply bredstar_contextual_appl.
      * apply IHif_contextual.
      * apply refl.
    + apply refl.
  (* if then else - then branch *)
  - simpl. apply bredstar_contextual_appl.
    + apply bredstar_contextual_appl.
      * apply refl.
      * apply IHif_contextual.
    + apply refl.
  (* if then else - else branch *)
  - simpl. apply bredstar_contextual_appl.
    + apply refl.
    + apply IHif_contextual.
  (* cons - head *)
  - simpl. remember (fresh [fresh (fvML HD ++ fvML TL)]). remember (fresh (fvML HD ++ fvML TL)).
      remember (fresh (fvML HD' ++ fvML TL)) as v0'. remember (fresh [v0']) as v'.
      remember (fresh (fvML HD ++ fvML HD' ++ fvML TL)) as new_v0.
      apply beta_alpha_toplvl with (z := new_v0).
    + admit.
    + admit.
    + remember (fresh [new_v0]) as new_v. apply bredstar_contextual_abs.
      rewrite subst_lambda_cont. rewrite subst_lambda_cont.
      simpl. assert (v =? v0 = false). { admit. } assert (v' =? v0' = false). { admit. } rewrite Nat.eqb_refl.
      rewrite Nat.eqb_sym. rewrite H. rewrite Nat.eqb_refl. rewrite Nat.eqb_sym. rewrite H0.
      apply beta_alpha_toplvl with (z := fresh [new_v0]).
      * admit.
      * admit.
      * apply bredstar_contextual_abs. simpl. rewrite Nat.eqb_refl. rewrite Nat.eqb_refl.
        assert (v =? new_v0 = false). { admit. } assert (v' =? new_v0 = false). { admit. }
        rewrite H1. rewrite H2. apply bredstar_contextual_appl.
        -- apply bredstar_contextual_appl.
          ++ apply refl.
          ++ rewrite substitution_fresh_l. rewrite substitution_fresh_l. rewrite substitution_fresh_l.
              rewrite substitution_fresh_l. apply IHcons_contextual. admit. admit. admit. admit.
        -- admit.
      * admit.
      * admit.
  (* cons - tail *)
  - admit. (* basically the same as previous case, let's focus on this one first. *)
  (* fold - list *)
  - simpl. apply bredstar_contextual_appl.
    + apply bredstar_contextual_appl.
      * apply IHfold_contextual.
      * apply refl.
    + apply refl.
  (* fold - operator *)
  - simpl. apply bredstar_contextual_appl.
    + apply bredstar_contextual_appl.
      * apply refl.
      * apply IHfold_contextual.
    + apply refl.
  (* fold - initial value *)
  - simpl. apply bredstar_contextual_appl.
    + apply bredstar_contextual_appl.
      * apply refl.
      * apply refl.
    + apply IHfold_contextual.
  (* pair - first element *)
  - admit.
  (* pair - second element *)
  - admit.
  - simpl. apply bredstar_contextual_appl.
    + apply IHfst.
    + remember (fresh (fvML P ++ fvML P')) as new_x. apply beta_alpha_toplvl with (z := new_x).
      * admit.
      * admit.
      * apply bredstar_contextual_abs. simpl.
        assert (fresh (fvML P) =? fresh [fresh (fvML P)] = false).
        { admit. } rewrite H. rewrite Nat.eqb_refl.
        assert (fresh (fvML P') =? fresh [fresh (fvML P')] = false).
        { admit. } rewrite H0. rewrite Nat.eqb_refl.
        apply beta_alpha_toplvl with (z := fresh [new_x]).
        -- admit.
        -- admit.
        -- apply bredstar_contextual_abs. simpl.
           assert (fresh [fresh (fvML P)] =? new_x = false). { admit. }
           assert (fresh [fresh (fvML P')] =? new_x = false). { admit. }
           rewrite H1. rewrite H2. apply refl.
  - simpl. apply bredstar_contextual_appl.
    + apply IHsnd.
    + remember (fresh (fvML P ++ fvML P')) as new_x. apply beta_alpha_toplvl with (z := new_x).
      * admit.
      * admit.
      * apply bredstar_contextual_abs. simpl.
        assert (fresh (fvML P) =? fresh [fresh (fvML P)] = false).
        { admit. } rewrite H.
        assert (fresh (fvML P') =? fresh [fresh (fvML P')] = false).
        { admit. } rewrite H0.
        apply beta_alpha_toplvl with (z := fresh [new_x]).
        -- admit.
        -- admit.
        -- apply bredstar_contextual_abs. simpl. rewrite Nat.eqb_refl. rewrite Nat.eqb_refl.
           apply refl.
(* redex case *)
  - simpl. rewrite lmlc_substitution. apply onestep. apply redex_contraction.
(* fixfun case *)
  - simpl. unfold turing_fixpoint_applied. apply bredstar_contextual_appl.
    + apply refl.
    + apply trans with (y := Lappl (Labs 0 (Lappl (Lvar 0) (Lappl turing_fixpoint (Lvar 0)))) (Labs f (Labs x (lmlc M)))).
      * unfold turing_fixpoint. apply bredstar_contextual_appl.
        -- apply onestep. apply redex_contraction.
        -- apply refl.
      * apply onestep. apply redex_contraction.
(* plus case *)
  - admit.
(* minus case *)
  - admit.
(* times case *)
  - admit.
(* greather than zero case *)
  - destruct (0 <? n) eqn:ineqn.
    + simpl. apply Nat.ltb_lt in ineqn. admit.
    + apply Nat.ltb_nlt in ineqn. apply Nat.nlt_ge in ineqn. inversion ineqn. simpl. unfold church_gtz.
      unfold church_int. unfold church_int_free. apply trans with (y := Lappl (Labs 0 (Lvar 0)) (church_false)).
      * assert ((Labs 0 (Lvar 0)) = substitution (Labs 0 (Lvar 0)) (Labs 0 church_true) 1). { reflexivity. }
        rewrite H0. assert (Lappl (Lappl (Labs 1 (substitution (Labs 0 (Lvar 0)) (Labs 0 church_true) 1)) (Labs 0 church_true)) = Lappl (Lappl (Labs 1 (Labs 0 (Lvar 0))) (Labs 0 church_true))).
        { reflexivity. } rewrite H1. apply bredstar_contextual_appl.
        -- apply onestep. apply redex_contraction.
        -- apply refl.
      * apply onestep. assert (church_false = substitution (Lvar 0) church_false 0). { reflexivity. }
        rewrite H0. assert (Lappl (Labs 0 (Lvar 0)) (substitution (Lvar 0) church_false 0) = Lappl (Labs 0 (Lvar 0)) (church_false)).
        { rewrite <- H0. reflexivity. } rewrite H1. apply redex_contraction.
(* fold base case *)
  - simpl. apply trans with (y := (Lappl (Labs 1 (Lvar 1)) (lmlc INIT))).
    + apply bredstar_contextual_appl.
      * assert (Labs 1 (Lvar 1) = substitution (Labs 1 (Lvar 1)) (lmlc FOO) 0). { reflexivity. } rewrite H.
        assert (Lappl (Labs 0 (substitution (Labs 1 (Lvar 1)) (lmlc FOO) 0)) (lmlc FOO) = Lappl (Labs 0 (Labs 1 (Lvar 1))) (lmlc FOO) ).
        { reflexivity. } rewrite H0. apply onestep. apply redex_contraction.
      * apply refl.
    + apply onestep. apply redex_contraction.
(* fold induction step case *)
  - admit.
(* fst case *)
  - admit.
(* snd case *)
  - admit.











