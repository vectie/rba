///|
pub type Key = String

///|
pub(open) trait Subscription {
  to_map(Self) -> Map[Key, CustomSubscription]
}

///|
pub(all) struct CustomSubscription {
  on_load : (&Scheduler) -> Unit
  on_unload : (&Scheduler) -> Unit
}
