(***********************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team    *)
(* <O___,, *        INRIA-Rocquencourt  &  LRI-CNRS-Orsay              *)
(*   \VV/  *************************************************************)
(*    //   *      This file is distributed under the terms of the      *)
(*         *       GNU Lesser General Public License Version 2.1       *)
(***********************************************************************)

(* Certification of Imperative Programs / Jean-Christophe Filli�tre *)

(* $Id$ *)

open Pp
open Util
open Names
open Term
open Himsg

open Putil
open Ptype
open Past


let raise_with_loc = function
    None -> raise
  | Some loc -> Stdpp.raise_with_loc loc 

let unbound_variable id loc =
  raise_with_loc loc
    (UserError ("Prog_errors.unbound_variable",
    (hOV 0 [<'sTR"Unbound variable"; 'sPC; pr_id id; 'fNL >])))

let unbound_reference id loc =
  raise_with_loc loc
    (UserError ("Prog_errors.unbound_reference",
    (hOV 0 [<'sTR"Unbound reference"; 'sPC; pr_id id; 'fNL >])))

let clash id loc =
  raise_with_loc loc
    (UserError ("Prog_errors.clash",
    (hOV 0 [< 'sTR"Clash with previous constant"; 'sPC;
    'sTR(string_of_id id); 'fNL >])))

let not_defined id =
  raise
    (UserError ("Prog_errors.not_defined",
	       	(hOV 0 [< 'sTR"The object"; 'sPC; pr_id id; 'sPC;
			  'sTR"is not defined"; 'fNL >])))

let check_for_reference loc id = function
    Ref _ -> ()
  | _ -> Stdpp.raise_with_loc loc 
	(UserError ("Prog_errors.check_for_reference",
		    hOV 0 [< pr_id id; 'sPC; 
			     'sTR"is not a reference" >]))

let check_for_array loc id = function
    Array _ -> ()
  | _ -> Stdpp.raise_with_loc loc 
	(UserError ("Prog_errors.check_for_array",
		    hOV 0 [< pr_id id; 'sPC; 
			     'sTR"is not an array" >]))

let is_constant_type s = function
    TypePure c ->
      let id = id_of_string s in
      let c' = Declare.global_reference CCI id in
      Reduction.is_conv (Global.env()) Evd.empty c c'
  | _ -> false 

let check_for_index_type loc v =
  let is_index = is_constant_type "Z" v in
  if not is_index then
    Stdpp.raise_with_loc loc 
      (UserError ("Prog_errors.check_for_index",
		  hOV 0 [< 'sTR"This expression is an index"; 'sPC; 
			   'sTR"and should have type int (Z)" >]))

let check_no_effect loc ef =
  if not (Peffect.get_writes ef = []) then
    Stdpp.raise_with_loc loc 
      (UserError ("Prog_errors.check_no_effect",
		  hOV 0 [< 'sTR"A boolean should not have side effects"
		        >]))

let should_be_boolean loc =
  Stdpp.raise_with_loc loc 
    (UserError ("Prog_errors.should_be_boolean",
		hOV 0 [< 'sTR"This expression is a test:" ; 'sPC;
			 'sTR"it should have type bool" >]))

let test_should_be_annotated loc =
  Stdpp.raise_with_loc loc 
    (UserError ("Prog_errors.test_should_be_annotated",
		hOV 0 [< 'sTR"This test should be annotated" >]))

let if_branches loc =
  Stdpp.raise_with_loc loc 
    (UserError ("Prog_errors.if_branches",
		hOV 0 [< 'sTR"The two branches of an `if' expression" ; 'sPC;
			 'sTR"should have the same type" >]))

let check_for_not_mutable loc v =
  if is_mutable v then
    Stdpp.raise_with_loc loc 
      (UserError ("Prog_errors.check_for_not_mutable",
		  hOV 0 [< 'sTR"This expression cannot be a mutable" >]))

let check_for_pure_type loc v =
  if not (is_pure v) then
    Stdpp.raise_with_loc loc 
      (UserError ("Prog_errors.check_for_pure_type",
		  hOV 0 [< 'sTR"This expression must be pure"; 'sPC;
			   'sTR"(neither a mutable nor a function)" >]))

let check_for_let_ref loc v =
  if not (is_pure v) then
    Stdpp.raise_with_loc loc 
      (UserError ("Prog_errors.check_for_let_ref",
		  hOV 0 [< 'sTR"References can only be bound in pure terms">]))

let informative loc s =
  Stdpp.raise_with_loc loc 
  (UserError ("Prog_errors.variant_informative",
	      hOV 0 [< 'sTR s; 'sPC; 'sTR"must be informative" >]))

let variant_informative loc = informative loc "Variant"
let should_be_informative loc = informative loc "This term"

let app_of_non_function loc =
  Stdpp.raise_with_loc loc 
  (UserError ("Prog_errors.app_of_non_function",
	      hOV 0 [< 'sTR"This term cannot be applied"; 'sPC;
		       'sTR"(either it is not a function"; 'sPC;
		       'sTR"or it is applied to non pure arguments)" >]))
  
let partial_app loc =
  Stdpp.raise_with_loc loc 
  (UserError ("Prog_errors.partial_app",
	      hOV 0 [< 'sTR"This function does not have";
		       'sPC; 'sTR"the right number of arguments" >]))
  
let expected_type loc s =
  Stdpp.raise_with_loc loc 
  (UserError ("Prog_errors.expected_type",
	      hOV 0 [< 'sTR"Argument is expected to have type"; 'sPC; s >]))

let expects_a_type id loc =
  Stdpp.raise_with_loc loc 
  (UserError ("Prog_errors.expects_a_type",
	      hOV 0 [< 'sTR"The argument "; pr_id id; 'sPC;
		       'sTR"in this application is supposed to be a type" >]))

let expects_a_term id =
  raise
  (UserError ("Prog_errors.expects_a_type",
	      hOV 0 [< 'sTR"The argument "; pr_id id; 'sPC;
		       'sTR"in this application is supposed to be a term" >]))

let should_be_a_variable loc =
  Stdpp.raise_with_loc loc 
  (UserError ("Prog_errors.should_be_a_variable",
	      hOV 0 [< 'sTR"Argument should be a variable" >]))
   
let should_be_a_reference loc =
  Stdpp.raise_with_loc loc 
  (UserError ("Prog_errors.should_be_a_reference",
	      hOV 0 [< 'sTR"Argument of function should be a reference" >]))

   
