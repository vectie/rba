///|
using @path {
  type Path,
  type MooncakesPath,
  type SourcePath,
  type ArtifactPath,
  type Target,
  type Build,
  type Mode,
}

///|
pub struct MoonWork {
  root : @path.SourcePath
  members : Array[MoonMod]
} derive(Debug)

///|
pub struct MoonPkg {
  name : @path.MooncakesPath
  root : @path.SourcePath
  kind : @configs.PkgKind
  artifact_root : ArtifactPath
  artifacts : Artifacts
} derive(Debug)

///|
pub type Artifacts = Map[(Target, Build, Mode), Map[String, SourcePath]]

// js, native, wasm, wasm-gc
// debug, release
// check, build

///|
pub struct MoonMod {
  name : @path.MooncakesPath
  root : @path.SourcePath
  packages : Array[MoonPkg]
  artifact_root : ArtifactPath
} derive(Debug)

///|
async fn lookup_contains(cwd : Path, file~ : String) -> SourcePath? {
  let mut path = cwd
  while path != Path::resolve("/") {
    let next = path.join(file).to_string()
    if @fs.exists(next) {
      return Some(SourcePath::new(path.to_string()))
    } else {
      path = path.join("..").normalize()
    }
  }
  None
}

///|
async fn find_ext_in_dir(cwd : Path, ext~ : String) -> Array[SourcePath] {
  let arr = []
  for file in @fs.readdir(cwd.0) {
    if file.has_suffix(ext) {
      arr.push(SourcePath::new(Path::resolve(file).to_string()))
    }
  }
  arr
}

///|
pub struct Discover {
  build_root : ArtifactPath
  deps_root : ArtifactPath
  kind : DiscoverKind
} derive(Debug)

///|
pub enum DiscoverKind {
  MoonWork(MoonWork)
  MoonMod(MoonMod)
  MoonMbtX(Array[SourcePath])
  MoonMbtMd(Array[SourcePath])
} derive(Debug)

///|
let mbtx_extension = ".mbtx"

///|
let mbtmd_extension = ".mbt.md"

///|
pub async fn discover(cwd : String) -> Discover? {
  let cwd = Path::resolve(cwd).0
  let mod_root = lookup_contains(cwd, file=moon_mod_name)
  let work_root = lookup_contains(cwd, file=moon_work_name)
  match (work_root, mod_root) {
    (Some(root), None) => {
      let build_root = ArtifactPath::new(root.join(build_dir))
      Some({
        kind: MoonWork(discover_work(root, build_root~)),
        build_root,
        deps_root: ArtifactPath::new(root.join(mooncakes_dir)),
      })
    }
    (None, Some(root)) => {
      let build_root = ArtifactPath::new(root.join(build_dir))
      Some({
        kind: MoonMod(discover_mod(root, build_root~, is_member_of_work=false)),
        build_root,
        deps_root: ArtifactPath::new(root.join(mooncakes_dir)),
      })
    }
    (Some(work_root), Some(mod_root)) => {
      let work_configs : @configs.WorkConfigs = @fs.read_file(
          work_root.join(moon_work_name).to_string(),
        ).text()
        |> @configs.read_work
      if work_configs.members.any(pkg => work_root.join(pkg) == mod_root) {
        let build_root = ArtifactPath::new(work_root.join(build_dir))
        Some({
          kind: MoonWork(discover_work(work_root, build_root~)),
          build_root,
          deps_root: ArtifactPath::new(work_root.join(mooncakes_dir)),
        })
      } else {
        let build_root = ArtifactPath::new(mod_root.join(build_dir))
        Some({
          kind: MoonMod(
            discover_mod(mod_root, build_root~, is_member_of_work=false),
          ),
          build_root: ArtifactPath::new(mod_root.join(build_dir)),
          deps_root: ArtifactPath::new(mod_root.join(mooncakes_dir)),
        })
      }
    }
    (None, None) if find_ext_in_dir(cwd, ext=mbtx_extension) is xs &&
      !xs.is_empty() => {
      let root = SourcePath::new(cwd)
      Some({
        kind: MoonMbtX(xs),
        build_root: ArtifactPath::new(root.join(build_dir)),
        deps_root: ArtifactPath::new(root.join(mooncakes_dir)),
      })
    }
    (None, None) if find_ext_in_dir(cwd, ext=mbtmd_extension) is xs &&
      !xs.is_empty() => {
      let root = SourcePath::new(cwd)
      Some({
        kind: MoonMbtMd(xs),
        build_root: ArtifactPath::new(root.join(build_dir)),
        deps_root: ArtifactPath::new(root.join(mooncakes_dir)),
      })
    }
    (None, None) => None
  }
}

///|
async fn discover_work(
  work_root : SourcePath,
  build_root~ : ArtifactPath,
) -> MoonWork {
  let moon_work_path = work_root.join(moon_work_name)
  guard @fs.exists(moon_work_path.to_string())
  let work_configs = @fs.read_file(moon_work_path.to_string()).text()
    |> @configs.read_work
  let members = []
  for member_relative in work_configs.members {
    let mod_root = work_root.join(member_relative)
    members.push(discover_mod(mod_root, build_root~, is_member_of_work=true))
  }
  { root: work_root, members }
}

///|
async fn discover_mod(
  mod_root : SourcePath,
  build_root~ : ArtifactPath, // path to _build
  is_member_of_work~ : Bool,
) -> MoonMod {
  let moon_mod_path = mod_root.join(moon_mod_name)
  guard @fs.exists(moon_mod_path.to_string())
  let mod_configs = @fs.read_file(moon_mod_path.to_string()).text()
    |> @configs.read_mod
  let mod_name = MooncakesPath::new(mod_configs.name)
  let mod_artifact_root = if is_member_of_work {
    build_root.join_module_path(mod_name)
  } else {
    build_root
  }
  let queue = @queue.Queue::from_array([mod_root])
  let packages = []
  while queue.pop() is Some(dir) {
    let files = @fs.readdir(dir.to_string())
    for file in files {
      let path = dir.join(file)
      let path_str = path.to_string()
      match file {
        "moon.pkg" =>
          packages.push(
            discover_pkg(dir, mod_root~, mod_name~, mod_artifact_root~),
          )
        "_build" | ".mooncakes" | "node_modules" => ()
        _ if @fs.exists(path_str) && @fs.kind(path_str) is Directory =>
          queue.push(path)
        _ => ()
      }
    }
  }
  { packages, root: mod_root, name: mod_name, artifact_root: mod_artifact_root }
}

///|
async fn discover_artifact(
  artifact_root : ArtifactPath,
  target : @path.Target,
  build : @path.Build,
  mod : @path.Mode,
) -> Map[String, SourcePath] {
  let path = artifact_root.to_string(target, build, mod)
  let res = {}
  if !@fs.exists(path.to_string()) {
    return {}
  }
  for file in @fs.readdir(path.to_string()) {
    res[file] = path.join(file)
  }
  res
}

///|
async fn discover_pkg(
  pkg_root : SourcePath,
  mod_root~ : SourcePath,
  mod_name~ : MooncakesPath,
  mod_artifact_root~ : ArtifactPath,
) -> MoonPkg {
  let pkg_configs = @fs.read_file(pkg_root.join(moon_pkg_name).to_string()).text()
    |> @configs.read_pkg()
  let pkg_relative = pkg_root.relative(mod_root)
  let is_root_pkg = pkg_relative == "." || pkg_relative == ""
  let name = if is_root_pkg { mod_name } else { mod_name.join(pkg_relative) }
  let artifact_root = if is_root_pkg {
    mod_artifact_root
  } else {
    mod_artifact_root.join_relative(pkg_relative)
  }
  let artifacts : Artifacts = {}
  for x in [Target::Js, Wasm, WasmGC, Native] {
    for y in [Build::Debug, Release] {
      for z in [Mode::Check, Mode::Build] {
        let r = discover_artifact(artifact_root, x, y, z)
        if !r.is_empty() {
          artifacts[(x, y, z)] = r
        }
      }
    }
  }
  { kind: pkg_configs.kind, root: pkg_root, name, artifacts, artifact_root }
}
