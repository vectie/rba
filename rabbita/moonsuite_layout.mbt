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
pub fn moonsuite_product_state_path() -> String {
  ".moonsuite/products/rabbita"
}

///|
pub fn moonsuite_product_service_path() -> String {
  "\{moonsuite_product_state_path()}/service.json"
}

///|
pub fn moonsuite_product_runtime_path() -> String {
  "\{moonsuite_product_state_path()}/runtime"
}

///|
pub fn moonsuite_product_cache_path() -> String {
  "\{moonsuite_product_state_path()}/cache"
}

///|
pub fn moonsuite_product_tmp_path() -> String {
  ".tmp/products/rabbita"
}

///|
pub fn moonsuite_product_home() -> RabbitaMoonSuiteProductHome {
  {
    product_id: moonsuite_product_id(),
    state_path: moonsuite_product_state_path(),
    service_path: moonsuite_product_service_path(),
    runtime_path: moonsuite_product_runtime_path(),
    cache_path: moonsuite_product_cache_path(),
    tmp_path: moonsuite_product_tmp_path(),
  }
}
