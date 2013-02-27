open MessagesDef
open OpenFlow0x04Parser
open OpenFlow0x04Types
open PatternImplDef
open NetCoreEval13
open NetCoreCompiler13
open List

module W = Wildcard

(* Egh. Assuming each action list only has a single port. Otherwise we
   need to use watch groups instead of a watch port and that's just more
   messy crap *)

let ofpp_any = Int32.of_int (-1)
(* Not even specified in OF 1.3. It's like they're not even trying... *)
let ofpg_any = Int32.of_int (-1)

let rec watchport acts = match acts with
  | NetCoreEval.Forward (modif, MessagesDef.PhysicalPort pid) :: acts -> (Int32.of_int pid)
  | _ :: acts -> watchport acts
  | _ -> ofpp_any

let rec mapi' idx f lst = match lst with
  | elm :: lst -> f idx elm :: mapi' (idx+1) f lst
  | [] -> []

let mapi f lst = mapi' 0 f lst

let insert_groups = mapi (fun idx (pat,(a,b)) -> (pat, (Int32.of_int idx, [(0, (watchport a), a); (0, (watchport b), b)])))

let remove_inport = map (fun (pat, acts) -> (  { pat with ptrnInPort = W.WildcardAll }, acts))

let compile_nc = compile_opt

open Classifier
let rec compile_pb pri bak sw =
    let pri_tbl = compile_nc pri sw in
    let bak_tbl = compile_nc bak sw in
    let merge = fun a b -> (a,b) in
    let overlap = insert_groups (inter merge pri_tbl (remove_inport bak_tbl)) in
    let ft_tbl = map (fun (pat, (a,b)) -> (pat, [Group a])) overlap in
    (ft_tbl @ pri_tbl @ bak_tbl, map snd overlap)
    
