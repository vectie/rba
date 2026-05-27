using @vector {type Vector}
using @rabbita {simple_cell, new, type Emit, type Html}
using @html {button, div, h1, input, li, p, span, ul, nothing, fragment}
using @svg {circle, line, polyline, svg}

///|
struct Todo {
  id : Int
  title : String
  done : Bool
}

///|
struct Model {
  draft : String
  items : Vector[Todo]
  next_id : Int
}

///|
enum Msg {
  DraftChanged(String)
  Add
  Toggle(Int)
  Delete(Int)
  ClearDone
}

///|
fn update(msg : Msg, model : Model) -> Model {
  let { draft, items, next_id } = model
  match msg {
    Add if draft == "" => model
    Add => {
      let title = model.draft.trim().to_owned()
      let todo = { id: next_id, title, done: false }
      { draft: "", items: items.push(todo), next_id: next_id + 1 }
    }
    DraftChanged(draft) => { ..model, draft, }
    Delete(id) => { ..model, items: items.filter(todo => todo.id != id) }
    ClearDone => { ..model, items: items.filter(todo => !todo.done) }
    Toggle(id) => {
      let items = items.map(todo => {
        if todo.id == id {
          { ..todo, done: !todo.done }
        } else {
          todo
        }
      })
      { ..model, items, }
    }
  }
}

///|
fn completed_count(items : Vector[Todo]) -> Int {
  items.fold(init=0, (count, todo) => if todo.done { count + 1 } else { count })
}

///|
fn view(emit : Emit[Msg], model : Model) -> Html {
  fn todo(item) {
    li(class=item_class(item)) <| [
      button(class="icon-button toggle", on_click=emit(Toggle(item.id))) <| [
        if item.done {
          done_icon
        } else {
          circle_icon
        },
      ],
      span(class="todo-title", item.title),
      button(
        class="icon-button delete",
        title="Delete todo",
        on_click=emit(Delete(item.id)),
        delete_icon,
      ),
    ]
  }

  fn todo_list(items : Vector[Todo]) {
    if items.is_empty() {
      p(class="empty", "Nothing yet.")
    } else {
      ul(class="todo-list", [ for x in items => todo(x) ])
    }
  }

  fn header(draft) {
    fragment <| [
      h1(class="title", "Todos"),
      div(class="composer") <| [
        input(
          class="new-todo",
          value=draft,
          placeholder="What needs doing?",
          on_input=emit.map(s => DraftChanged(s)),
          nothing,
        ),
        button(
          class="add",
          disabled=draft.trim().to_owned() == "",
          on_click=emit(Add),
          "add",
        ),
      ],
    ]
  }

  fn footer(active, completed) {
    div(class="footer") <| [
      span("\{active} active / \{completed} done"),
      button(
        class="clear",
        disabled=completed == 0,
        on_click=emit(ClearDone),
        "clear done",
      ),
    ]
  }

  let total = model.items.length()
  let completed = completed_count(model.items)

  div(class="app") <| [
    div(class="panel") <| [
      header(model.draft),
      todo_list(model.items),
      footer(total - completed, completed),
    ],
  ]
}

///|
fn item_class(todo : Todo) -> String {
  if todo.done {
    "todo-item done"
  } else {
    "todo-item"
  }
}

///|
let circle_icon : Html = svg(
  class="icon",
  width=18,
  height=18,
  view_box="0 0 24 24",
) <| [
  circle(cx=12, cy=12, r=9, fill="none", stroke="currentColor", stroke_width=2),
]

///|
let done_icon : Html = svg(
  class="icon",
  width=18,
  height=18,
  view_box="0 0 24 24",
) <| [
  circle(cx=12, cy=12, r=9, fill="none", stroke="currentColor", stroke_width=2),
  polyline(
    points=[(8, 12), (11, 15), (16, 9)],
    fill="none",
    stroke="currentColor",
    stroke_width=2,
    stroke_linecap="round",
  ),
]

///|
let delete_icon : Html = svg(
  class="icon",
  width=18,
  height=18,
  view_box="0 0 24 24",
) <| [
  line(
    x1=7,
    y1=7,
    x2=17,
    y2=17,
    stroke="currentColor",
    stroke_width=2,
    stroke_linecap="round",
  ),
  line(
    x1=17,
    y1=7,
    x2=7,
    y2=17,
    stroke="currentColor",
    stroke_width=2,
    stroke_linecap="round",
  ),
]

///|
fn main {
  let app = simple_cell(
    model={ draft: "", items: Vector::new(), next_id: 0 },
    update~,
    view~,
  )
  new(app).mount("app")
}
