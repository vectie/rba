///|
pub struct WorkConfigs {
  members : Array[String]
} derive(Debug)

///|
pub fn read_work(source : String) -> WorkConfigs {
  let (ast, _) = @pkg_parser.parse_string(source)
  let members = match ast {
    Obj(map={ "members": Arr(content=arr, ..), .. }, ..) =>
      arr.filter_map(x => {
        match x {
          Str(str~, ..) => Some(str)
          _ => None
        }
      })
    _ => []
  }
  { members, }
}

///|
async test "read_moon_work" {
  let source =
    #|members = [
    #|  "path/to/mod1",
    #|  "path/to/some/subdir/mod2",
    #|  "path/mod3",
    #|]
    #|
    #|supported_targets = "native+js"
    #|
  debug_inspect(
    read_work(source),
    content=(
      #|{ members: ["path/to/mod1", "path/to/some/subdir/mod2", "path/mod3"] }
    ),
  )
}
