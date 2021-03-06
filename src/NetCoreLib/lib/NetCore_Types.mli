(** Library for building the underlying infrastructure of Frenetic controllers.
*)

open Packet

type switchId = OpenFlow0x01_Core.switchId

type 'a wildcard =
  | WildcardExact of 'a
  | WildcardAll
  | WildcardNone

type port =
  | Physical of OpenFlow0x01_Core.portId
  | All
  | Here

type lp = switchId * port * packet

type ptrn = {
  ptrnDlSrc : dlAddr wildcard;
  ptrnDlDst : dlAddr wildcard;
  ptrnDlTyp : dlTyp wildcard;
  ptrnDlVlan : dlVlan wildcard;
  ptrnDlVlanPcp : dlVlanPcp wildcard;
  ptrnNwSrc : nwAddr wildcard;
  ptrnNwDst : nwAddr wildcard;
  ptrnNwProto : nwProto wildcard;
  ptrnNwTos : nwTos wildcard;
  ptrnTpSrc : tpPort wildcard;
  ptrnTpDst : tpPort wildcard;
  ptrnInPort : port wildcard
}

type 'a match_modify = ('a * 'a) option

  (** Note that OpenFlow does not allow the [dlTyp] and [nwProto]
      fields to be modified. *)
type output = {
  outDlSrc : dlAddr match_modify;
  outDlDst : dlAddr match_modify;
  outDlVlan : dlVlan match_modify;
  outDlVlanPcp : dlVlanPcp match_modify;
  outNwSrc : nwAddr match_modify;
  outNwDst : nwAddr match_modify;
  outNwTos : nwTos match_modify;
  outTpSrc : tpPort match_modify;
  outTpDst : tpPort match_modify;
  outPort : port 
}

val id : output

type get_packet_handler = switchId -> port -> packet -> action

  (* Packet count -> Byte count -> unit. *)
and get_count_handler = Int64.t -> Int64.t -> unit

and action_atom =
  | SwitchAction of output
  | ControllerAction of get_packet_handler
  | ControllerQuery of float * get_count_handler

and action = action_atom list

type pred =
  | Hdr of ptrn
  | OnSwitch of switchId
  | Or of pred * pred
  | And of pred * pred
  | Not of pred
  | Everything
  | Nothing

type switchEvent =
  | SwitchUp of switchId * OpenFlow0x01.SwitchFeatures.t
  | SwitchDown of switchId

type pol =
  | HandleSwitchEvent of (switchEvent -> unit)
  | Action of action
  | Filter of pred
  | Union of pol * pol
  | Seq of pol * pol
  | ITE of pred * pol * pol


type value =
  | Pkt of switchId * port * packet * OpenFlow0x01.Payload.t


val all : ptrn

val empty : ptrn

val dlSrc : dlAddr -> ptrn

val dlDst : dlAddr -> ptrn
  
val dlTyp : dlTyp -> ptrn
  
val dlVlan : dlVlan -> ptrn
  
val dlVlanPcp : dlVlanPcp -> ptrn
  
val ipSrc : nwAddr -> ptrn
  
val ipDst : nwAddr -> ptrn
  
val ipProto : nwProto -> ptrn

val ipTos : nwTos -> ptrn
  
val inPort : port -> ptrn
  
val tcpSrcPort : tpPort -> ptrn
  
val tcpDstPort : tpPort -> ptrn
  
val udpSrcPort : tpPort -> ptrn
  
val udpDstPort : tpPort -> ptrn
