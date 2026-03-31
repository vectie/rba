///|
using @interface {trait Scheduler}

///|
using @cmd {type Cmd}

///|
struct Sub(Map[String, @interface.CustomSubscription])

///|
pub impl @interface.Subscription for Sub with to_map(self) {
  self.0
}

///|
pub fn every(ms : Int, cmd : @cmd.Cmd) -> Sub {
  let mut id : Int? = None
  fn on_load(scheduler : &Scheduler) {
    id = Some(
      @dom.window().set_interval(() => scheduler.add_cmds(cmd.to_array()), ms),
    )
  }
  fn on_unload(_) {
    guard id is Some(interval_id) else { return }
    @dom.window().clear_interval(interval_id)
    id = None
  }

  Map::from_array([("every(\{ms})", { on_load, on_unload })])
}

///|
pub fn on_resize(cmd : Cmd) -> Sub {
  let mut listener : @dom.Listener? = None
  fn on_load(scheduler : &Scheduler) {
    @dom.window().add_event_listener("resize", _ => {
      scheduler.add_cmds(cmd.to_array())
    })
  }
  fn on_unload(_) {
    guard listener is Some(current) else { return }
    @dom.window().remove_event_listener("resize", current)
    listener = None
  }
  { "on_resize": { on_load, on_unload } }
}

///|
pub let none : Sub = {}

///|
pub fn batch(xs : Array[Sub]) -> Sub {
  let r = {}
  for x in xs {
    for k, v in x.0 {
      r[k] = v
    }
  }
  r
}
