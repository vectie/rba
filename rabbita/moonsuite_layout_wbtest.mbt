///|
test "root package exposes moonsuite product home contract" {
  let home = moonsuite_product_home()
  assert_eq(home.product_id, "rabbita")
  assert_eq(home.state_path, ".moonsuite/products/rabbita")
  assert_eq(home.service_path, ".moonsuite/products/rabbita/service.json")
  assert_eq(home.runtime_path, ".moonsuite/products/rabbita/runtime")
  assert_eq(home.cache_path, ".moonsuite/products/rabbita/cache")
  assert_eq(home.tmp_path, ".tmp/products/rabbita")
}
