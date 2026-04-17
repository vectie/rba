///|
pub struct PkgConfigs {
  kind : PkgKind
  imports : Array[(String, String?)]
  test_imports : Array[(String, String?)]
  wbtest_imports : Array[(String, String?)]
  supported_targets : String?
} derive(Debug)

///|
pub enum PkgKind {
  Cmd
  Lib
} derive(Debug)

///|
fn read_import_item(ast : @pkg_parser.Ast) -> (String, String?)? {
  match ast {
    Str(str~, ..) => Some((str, None))
    Obj(map~, ..) => {
      let path = match map.get("path") {
        Some(Str(str~, ..)) => Some(str)
        _ => None
      }
      let import_alias = match map.get("alias") {
        Some(Str(str~, ..)) => Some(str)
        _ => None
      }
      path.map(path => (path, import_alias))
    }
    _ => None
  }
}

///|
fn read_imports(
  map : Map[String, @pkg_parser.Ast],
  key : String,
) -> Array[(String, String?)] {
  match map.get(key) {
    Some(Arr(content=arr, ..)) => arr.filter_map(read_import_item)
    _ => []
  }
}

///|
pub fn read_pkg(source : String) -> PkgConfigs {
  let (ast, _) = @pkg_parser.parse_string(source)
  match ast {
    Obj(map~, ..) => {
      let kind = match map.get("options") {
        Some(Obj(map=options, ..)) =>
          match options.get("is-main") {
            Some(True(_)) => Cmd
            _ => Lib
          }
        _ => Lib
      }
      let imports = read_imports(map, "import")
      let test_imports = read_imports(map, "test-import")
      let wbtest_imports = read_imports(map, "wbtest-import")
      let supported_targets = match map.get("supported_targets") {
        Some(Str(str~, ..)) => Some(str)
        _ => None
      }
      { kind, imports, test_imports, wbtest_imports, supported_targets }
    }
    _ =>
      {
        kind: Lib,
        imports: [],
        test_imports: [],
        wbtest_imports: [],
        supported_targets: None,
      }
  }
}

///|
async test "read_pkg for main package" {
  let source =
    #|import {
    #|  "moonbit-community/rabbita",
    #|  "moonbit-community/rabbita/html" @html,
    #|}
    #|
    #|import {
    #|  "moonbitlang/core/test",
    #|  "moonbitlang/core/json" @json,
    #|} for "test"
    #|
    #|import {
    #|  "moonbitlang/core/hashmap",
    #|} for "wbtest"
    #|
    #|supported_targets = "js+native"
    #|
    #|options(
    #|  "is-main": true,
    #|)
  let configs = read_pkg(source)
  debug_inspect(
    configs,
    content=(
      #|{
      #|  kind: Cmd,
      #|  imports: [
      #|    ("moonbit-community/rabbita", None),
      #|    ("moonbit-community/rabbita/html", Some("html")),
      #|  ],
      #|  test_imports: [
      #|    ("moonbitlang/core/test", None),
      #|    ("moonbitlang/core/json", Some("json")),
      #|  ],
      #|  wbtest_imports: [("moonbitlang/core/hashmap", None)],
      #|  supported_targets: Some("js+native"),
      #|}
    ),
  )
}

///|
async test "read_pkg defaults to lib" {
  let source =
    #|import {
    #|  "moonbitlang/async",
    #|}
  let configs = read_pkg(source)
  debug_inspect(
    configs,
    content=(
      #|{
      #|  kind: Lib,
      #|  imports: [("moonbitlang/async", None)],
      #|  test_imports: [],
      #|  wbtest_imports: [],
      #|  supported_targets: None,
      #|}
    ),
  )
}
