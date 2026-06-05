///|
async test "discover skips dangling symlinks" {
  let root_str = "/tmp/warren-discover-dangling-symlink-test"
  if @fs.exists(root_str) {
    @fs.rmdir(root_str, recursive=true)
  }
  @fs.mkdir(root_str, permission=0o755, recursive=true)
  let mod_config =
    #|{
    #|  "name": "local/discover-test",
    #|  "version": "0.1.0",
    #|  "deps": {}
    #|}
  @fs.write_file(
    "\{root_str}/moon.mod.json",
    mod_config,
    create=0o644,
    truncate=true,
  )
  let pkg_config =
    #|options(
    #|  "is-main": true,
    #|)
  @fs.write_file(
    "\{root_str}/moon.pkg",
    pkg_config,
    create=0o644,
    truncate=true,
  )
  @fs.symlink(target="\{root_str}/missing-target", "\{root_str}/dangling-link")
  match @discover.discover(root_str) {
    Some({ kind: MoonMod(mod), .. }) =>
      inspect(mod.packages.length(), content="1")
    None => inspect("None", content="Some(MoonMod(...))")
    Some({ kind: MoonWork(_), .. }) => inspect("MoonWork", content="MoonMod")
    Some({ kind: MoonMbtX(_), .. }) => inspect("MoonMbtX", content="MoonMod")
    Some({ kind: MoonMbtMd(_), .. }) => inspect("MoonMbtMd", content="MoonMod")
  }
  @fs.rmdir(root_str, recursive=true)
}
