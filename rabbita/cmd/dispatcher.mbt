///|
pub(all) struct Dispatch[Msg]((Msg) -> Cmd)

///|
pub fn[A, B] Dispatch::map(self : Self[A], f : (B) -> A) -> Self[B] {
  b => self(f(b))
}

///|
/// internal use only
#doc(hidden)
pub fn[Msg] make_dispatcher(
  _ : @key.Key,
  id : @common.Id,
  inbox : @queue.Queue[Msg],
) -> Dispatch[Msg] {
  // carry the drain (which own model and update) in message will cause memory leak in RC
  msg => Message(id, () => inbox.push(msg))
}
