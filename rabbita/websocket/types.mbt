///|
#cfg(target="js")
using @debug {trait Debug, type Repr}

///|
/// Close event information surfaced by `@websocket.connect(...)`.
#cfg(target="js")
pub struct CloseInfo {
  code : Int
  reason : String
  clean : Bool
} derive(Show, Debug)

///|
/// Inbound events emitted by a managed WebSocket connection.
#cfg(target="js")
pub(all) enum Event {
  Opened
  Message(String)
  Closed(CloseInfo)
  Errored
} derive(Show, Debug)

///|
/// Outbound payload for `send(...)`.
#cfg(target="js")
pub(all) enum Payload {
  Text(String)
  Json(Json)
} derive(Show)

///|
#cfg(target="js")
pub impl Debug for Payload with to_repr(self) {
  Repr::literal(self.to_string())
}

///|
/// Browser `WebSocket.readyState` mapped to a MoonBit enum.
#cfg(target="js")
pub(all) enum ReadyState {
  Connecting
  Open
  Closing
  Closed
} derive(Show, Debug)

///|
/// Snapshot of the current connection state for a named socket.
#cfg(target="js")
pub struct Snapshot {
  id : String
  url : String
  protocol : String
  buffered_amount : Int
  ready_state : ReadyState
} derive(Show, Debug)
