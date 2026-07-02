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

///|
test "moonsuite product home resolves from suite hosted book root" {
  let suite_root = "/tmp/rabbita-suite"
  let book_root = suite_root + "/books/browser-lab"
  let home = moonsuite_product_home_for_workspace_root(book_root)
  assert_eq(home.product_id, "rabbita")
  assert_eq(home.state_path, suite_root + "/.moonsuite/products/rabbita")
  assert_eq(
    home.service_path,
    suite_root + "/.moonsuite/products/rabbita/service.json",
  )
  assert_eq(
    home.runtime_path,
    suite_root + "/.moonsuite/products/rabbita/runtime",
  )
  assert_eq(home.cache_path, suite_root + "/.moonsuite/products/rabbita/cache")
  assert_eq(home.tmp_path, suite_root + "/.tmp/products/rabbita")
  assert_true(!home.state_path.contains("/books/browser-lab/.moonsuite"))
  assert_true(!home.tmp_path.contains("/books/browser-lab/.tmp"))
}
