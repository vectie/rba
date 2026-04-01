///|
pub(open) trait Scheduler {
  run_effect(Self, EffectKind, OnExecute) -> Unit
  queue_message(Self, @common.Id, MessageSender) -> Unit
  drain_message(Self) -> Unit
  add(Self, Cmd) -> Unit = _
  hooks(Self) -> Hooks
}

///|
pub(all) struct Hooks {
  mut url_request : Hook[String]?
  mut url_changed : Hook[String]?
}

///|
pub type Hook[Arg] = (&Scheduler, Arg) -> Unit

///|
pub type MessageSender = () -> Unit

///|
impl Scheduler with add(self, cmd) {
  fn go(cmd) {
    match cmd {
      Batch(xs) => xs.each(x => go(x))
      Effect(k, f) => self.run_effect(k, f)
      Message(id, send_message) => self.queue_message(id, send_message)
    }
  }
  go(cmd)
  self.drain_message()
}
