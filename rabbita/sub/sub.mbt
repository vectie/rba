///|
using @common {type Keyboard, type Mouse, type Scroll, type Viewport}

///|
using @cmd {type Cmd, trait Scheduler}

///|
/// A long-lived subscription managed by the Rabbita runtime.
///
/// Use subscriptions to listen to external signals such as timers, window
/// resize, scrolling, keyboard input, or visibility changes.
enum Sub {
  Custom(String, Scope, Initializer)
  Batch(Array[Sub])
}

///|
priv enum Scope {
  Local
  Global
}

///|
pub type Initializer = (&Scheduler) -> Disposer

///|
pub type Disposer = (&Scheduler) -> Unit

///|
#doc(hidden)
pub fn Sub::to_map(
  self : Self,
  _ : @key.Key,
  filter_global~ : Bool,
) -> Map[String, Initializer] {
  let map = {}
  fn go(s) {
    match s {
      Custom(_, Global, _) if filter_global => ()
      Custom(k, _, v) => map[k] = v
      Batch(xs) => xs.each(go)
    }
  }
  go(self)
  map
}

///|
fn custom_subscription(
  key : String,
  scope : Scope,
  load : (&Scheduler) -> (&Scheduler) -> Unit,
) -> Sub {
  Custom(key, scope, load)
}

///|
fn event_subscription(
  key : String,
  scope : Scope,
  target : @dom.EventTarget,
  event_name : String,
  handler : (@dom.Event) -> Cmd,
) -> Sub {
  custom_subscription(key, scope, scheduler => {
    let listener : @dom.Listener = event => scheduler.add(handler(event))
    target.add_event_listener(event_name, listener)
    _ => target.remove_event_listener(event_name, listener)
  })
}

///|
fn keyboard_from_dom(event : @dom.KeyboardEvent) -> Keyboard {
  Keyboard::new(
    key=event.key(),
    code=event.code(),
    alt_key=event.alt_key(),
    ctrl_key=event.ctrl_key(),
    shift_key=event.shift_key(),
    meta_key=event.meta_key(),
    is_composing=event.is_composing(),
    repeat=event.repeat(),
    location=event.location(),
  )
}

///|
fn mouse_from_dom(event : @dom.MouseEvent) -> Mouse {
  Mouse::new(
    screen={ x: event.get_screen_x(), y: event.get_screen_y() },
    offset={ x: event.get_offset_x(), y: event.get_offset_y() },
    client={ x: event.get_client_x(), y: event.get_client_y() },
  )
}

///|
fn window_scroll() -> Scroll {
  let root = @dom.document().query_selector("html").unwrap()
  Scroll::new(
    offset={ x: @dom.window().scroll_x(), y: @dom.window().scroll_y() },
    width=root.get_scroll_width().to_int(),
    height=root.get_scroll_height().to_int(),
  )
}

///|
/// Repeatedly enqueue `cmd` every `ms` milliseconds.
pub fn every(ms : Int, cmd : @cmd.Cmd) -> Sub {
  custom_subscription("every(\{ms})", Local, scheduler => {
    let id : Int = @dom.window().set_interval(() => scheduler.add(cmd), ms)
    fn(_) { @dom.window().clear_interval(id) }
  })
}

///|
/// Subscribe to window resize events.
///
/// The handler receives the latest viewport width and height.
pub fn on_resize(msg : @cmd.Dispatch[Viewport]) -> Sub {
  event_subscription(
    "on_resize",
    Local,
    @dom.window().as_event_target(),
    "resize",
    event => {
      ignore(event)
      msg({
        width: @dom.window().inner_width(),
        height: @dom.window().inner_height(),
      })
    },
  )
}

///|
/// Subscribe to `requestAnimationFrame` ticks.
///
/// The handler receives the browser timestamp for each frame while the
/// subscription is active.
pub fn on_animation_frame(msg : @cmd.Dispatch[Double]) -> Sub {
  custom_subscription("on_animation_frame", Local, scheduler => {
    let mut active = true
    let mut request_id : Double? = None

    fn queue_next() {
      request_id = Some(
        @dom.window().request_animation_frame(timestamp => {
          guard active else { return }
          scheduler.add(msg(timestamp))
          queue_next()
        }),
      )
    }

    queue_next()
    fn(_) {
      active = false
      guard request_id is Some(id) else { return }
      @dom.window().cancel_animation_frame(id)
    }
  })
}

///|
/// Subscribe to document `keydown` events.
///
/// The handler receives a normalized `Keyboard` value from `@common`.
pub fn on_key_down(msg : @cmd.Dispatch[Keyboard]) -> Sub {
  event_subscription(
    "on_key_down",
    Local,
    @dom.document().as_event_target(),
    "keydown",
    event => msg(keyboard_from_dom(event.to_keyboard_event().unwrap())),
  )
}

///|
/// Subscribe to document `keyup` events.
///
/// The handler receives a normalized `Keyboard` value from `@common`.
pub fn on_key_up(msg : @cmd.Dispatch[Keyboard]) -> Sub {
  event_subscription(
    "on_key_up",
    Local,
    @dom.document().as_event_target(),
    "keyup",
    event => msg(keyboard_from_dom(event.to_keyboard_event().unwrap())),
  )
}

///|
/// Subscribe to document visibility changes.
///
/// The handler receives `true` when the document is hidden, and `false`
/// when it becomes visible again.
pub fn on_visibility_change(msg : @cmd.Dispatch[Bool]) -> Sub {
  event_subscription(
    "on_visibility_change",
    Local,
    @dom.document().as_event_target(),
    "visibilitychange",
    _ => msg(@dom.document().hidden()),
  )
}

///|
/// Subscribe to document `mousemove` events.
///
/// The handler receives a normalized `Mouse` value from `@common`.
pub fn on_mouse_move(msg : @cmd.Dispatch[Mouse]) -> Sub {
  event_subscription(
    "on_mouse_move",
    Local,
    @dom.document().as_event_target(),
    "mousemove",
    event => msg(mouse_from_dom(event.to_mouse_event().unwrap())),
  )
}

///|
/// Subscribe to window scroll events.
///
/// This reports page-level scrolling on `window`, not scrolling of an inner
/// element. The handler receives the current scroll offset and document scroll
/// size as a `Scroll` value.
pub fn on_scroll(msg : @cmd.Dispatch[Scroll]) -> Sub {
  event_subscription(
    "on_scroll",
    Local,
    @dom.window().as_event_target(),
    "scroll",
    event => {
      ignore(event)
      msg(window_scroll())
    },
  )
}

///|
/// Subscribe to browser location changes.
///
/// This is an app-scoped subscription. It is only active when returned from
/// the root cell's `subscriptions` callback; if a non-root cell returns it,
/// the subscription is ignored.
pub fn on_url_changed(msg : @cmd.Dispatch[@url.Url]) -> Sub {
  custom_subscription("on_url_changed", Global, scheduler => {
    scheduler.hooks().url_changed = Some((scheduler, url) => {
      try @url.parse(url) catch {
        e => println("failed to parse \{url}: \{e}")
      } noraise {
        url => scheduler.add(msg(url))
      }
    })

    let listener = fn(_) {
      if scheduler.hooks().url_changed is Some(hook) {
        hook(scheduler, @dom.window().current_url())
      }
    }
    @dom.window().to_event_target().add_event_listener("popstate", listener)

    fn(_) {
      scheduler.hooks().url_changed = None
      @dom.window()
      .to_event_target()
      .remove_event_listener("popstate", listener)
    }
  })
}

///|
/// Subscribe to captured navigation requests from `@html.a(...)`.
///
/// This is an app-scoped subscription. It is only active when returned from
/// the root cell's `subscriptions` callback; if a non-root cell returns it,
/// the subscription is ignored.
pub fn on_url_request(msg : @cmd.Dispatch[@url.UrlRequest]) -> Sub {
  custom_subscription("on_url_request", Global, scheduler => {
    scheduler.hooks().url_request = Some((scheduler, href) => {
      let curr = try! @url.parse(@dom.window().current_url())
      let next = try! @url.parse(href)
      let request = if curr.protocol == next.protocol &&
        curr.host == next.host &&
        curr.port == next.port {
        @url.Internal(next)
      } else {
        External(href)
      }
      scheduler.add(msg(request))
    })

    fn(_) { scheduler.hooks().url_request = None }
  })
}

///|
/// A subscription that does nothing.
pub let none : Sub = Batch([])

///|
/// Combine multiple subscriptions into one.
///
/// If multiple subscriptions use the same internal key, the later one wins.
pub fn batch(xs : Array[Sub]) -> Sub {
  Batch(xs)
}
