///|
pub(all) struct RabbitaMoonSuiteProductHome {
  product_id : String
  state_path : String
  service_path : String
  runtime_path : String
  cache_path : String
  tmp_path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn moonsuite_product_id() -> String {
  "rabbita"
}

///|
fn moonsuite_active_workspace_root() -> String {
  "."
}

///|
pub fn moonsuite_product_state_path_for_workspace_root(root : String) -> String {
  @moonsuite.product_dir(
    @moonsuite.suite_root_for_workspace_root(root),
    moonsuite_product_id(),
  )
}

///|
pub fn moonsuite_product_state_path() -> String {
  moonsuite_product_state_path_for_workspace_root(
    moonsuite_active_workspace_root(),
  )
}

///|
pub fn moonsuite_product_service_path_for_workspace_root(
  root : String,
) -> String {
  @moonsuite.product_service_path(
    @moonsuite.suite_root_for_workspace_root(root),
    moonsuite_product_id(),
  )
}

///|
pub fn moonsuite_product_service_path() -> String {
  moonsuite_product_service_path_for_workspace_root(
    moonsuite_active_workspace_root(),
  )
}

///|
pub fn moonsuite_product_runtime_path_for_workspace_root(
  root : String,
) -> String {
  @moonsuite.product_artifact_for_workspace_root(
    root,
    moonsuite_product_id(),
    "runtime",
  )
}

///|
pub fn moonsuite_product_runtime_path() -> String {
  moonsuite_product_runtime_path_for_workspace_root(
    moonsuite_active_workspace_root(),
  )
}

///|
pub fn moonsuite_product_cache_path_for_workspace_root(root : String) -> String {
  @moonsuite.product_artifact_for_workspace_root(
    root,
    moonsuite_product_id(),
    "cache",
  )
}

///|
pub fn moonsuite_product_cache_path() -> String {
  moonsuite_product_cache_path_for_workspace_root(
    moonsuite_active_workspace_root(),
  )
}

///|
pub fn moonsuite_product_tmp_path_for_workspace_root(root : String) -> String {
  @moonsuite.product_tmp_dir(
    @moonsuite.suite_root_for_workspace_root(root),
    moonsuite_product_id(),
  )
}

///|
pub fn moonsuite_product_tmp_path() -> String {
  moonsuite_product_tmp_path_for_workspace_root(
    moonsuite_active_workspace_root(),
  )
}

///|
pub fn moonsuite_product_home_for_workspace_root(
  root : String,
) -> RabbitaMoonSuiteProductHome {
  {
    product_id: moonsuite_product_id(),
    state_path: moonsuite_product_state_path_for_workspace_root(root),
    service_path: moonsuite_product_service_path_for_workspace_root(root),
    runtime_path: moonsuite_product_runtime_path_for_workspace_root(root),
    cache_path: moonsuite_product_cache_path_for_workspace_root(root),
    tmp_path: moonsuite_product_tmp_path_for_workspace_root(root),
  }
}

///|
pub fn moonsuite_product_home() -> RabbitaMoonSuiteProductHome {
  moonsuite_product_home_for_workspace_root(moonsuite_active_workspace_root())
}
