///|
using @cmd {type Cmd, trait Scheduler, type Dispatch}

///|
using @json {trait FromJson}

///|
pub struct Request {
  url : String
  http_method : String
  body : Body
}

///|
/// Expect a message with a `Result[T, Error]` payload.
/// 
/// On success, the result contains `T`; on failure, it contains an `Error`.
/// The response body is parsed as JSON and decoded into `T`.
/// 
/// ```mbt nocheck
/// @http.get("api/user").expect(x => dispatch(UserLoaded(x)))
/// ```
/// 
/// It is recommended to process the decoded value when handling the
/// `UserLoaded` message in `update`, rather than in the callback.
/// **Keep the callback passed to `expect` short and clean.**
/// 
/// ### Anti-pattern:
/// - embedding logic in the callback
///     ```mbt nocheck
///     @http.get("api/user").expect(result => {
///       let processed = process(result)
///       dispatch(UserLoaded(processed))
///     })
///     ```
/// - ignoring the returned `Cmd`
///     ```
///     @http.get("api/user").expect(x => dispatch(UserLoaded(x))) |> ignore
///     ```
pub fn[T : FromJson] Request::expect(
  self : Request,
  msg : Dispatch[Result[T, Error]],
) -> Cmd {
  self.send(
    on_success=body => {
      let result : Result[T, Error] = try? @json.from_json(@json.parse(body))
      msg(result)
    },
    on_failure=error => msg(Err(error)),
  )
}

///|
/// Expect a message with a `Result[Json, Error]` payload.
/// 
/// On success, the result contains `Json`; on failure, it contains an `Error`.
/// The response body is parsed as JSON.
/// 
/// ```mbt nocheck
/// @http.get("api/user").expect_json(x => dispatch(JsonLoaded(x)))
/// ```
/// 
/// It is recommended to process the parsed JSON when handling the
/// `JsonLoaded` message in `update`, rather than in the callback.
/// **Keep the callback passed to `expect_json` short and clean.**
/// 
/// ### Anti-pattern:
/// - embedding logic in the callback
///     ```mbt nocheck
///     @http.get("api/user").expect_json(result => {
///       let normalized = normalize(result)
///       dispatch(JsonLoaded(normalized))
///     })
///     ```
/// - ignoring the returned `Cmd`
///     ```
///     @http.get("api/user").expect_json(x => dispatch(JsonLoaded(x))) |> ignore
///     ```
pub fn Request::expect_json(
  self : Request,
  msg : Dispatch[Result[Json, Error]],
) -> Cmd {
  self.send(
    on_success=body => {
      let result : Result[Json, Error] = try? @json.parse(body)
      msg(result)
    },
    on_failure=error => msg(Err(error)),
  )
}

///|
/// Expect a message with a `Result[String, Error]` payload.
/// 
/// On success, the result contains `String`; on failure, it contains an `Error`.
/// The response body is returned as plain text.
/// 
/// ```mbt nocheck
/// @http.get("api/text").expect_text(x => dispatch(CustomMsg(x)))
/// ```
/// 
/// It is recommended to process the text when handling the
/// `CustomMsg` message in `update`, rather than in the callback.
/// **Keep the callback passed to `expect_text` short and clean.**
/// 
/// ### Anti-pattern:
/// - embedding logic in the callback
///     ```mbt nocheck
///     @http.get("api/text").expect_text(result => {
///       let processed = process(result)
///       dispatch(CustomMsg(processed))
///     })
///     ```
/// - ignoring the returned `Cmd`
///     ```
///     @http.get("api/text").expect_text(x => dispatch(CustomMsg(x))) |> ignore
///     ```
pub fn Request::expect_text(
  self : Request,
  msg : Dispatch[Result[String, Error]],
) -> Cmd {
  self.send(on_success=body => msg(Ok(body)), on_failure=error => {
    msg(Err(error))
  })
}

///|
/// Expect a message with an `Error?` payload.
/// 
/// On success, the result is `None`; on failure, it is `Some(error)`.
/// The response body is ignored.
/// 
/// ```mbt nocheck
/// @http.delete("api/user/1").expect_empty(x => dispatch(UserDeleted(x)))
/// ```
/// 
/// It is recommended to handle the success or failure state when handling the
/// `UserDeleted` message in `update`, rather than in the callback.
/// **Keep the callback passed to `expect_empty` short and clean.**
/// 
/// ### Anti-pattern:
/// - embedding logic in the callback
///     ```mbt nocheck
///     @http.delete("api/user/1").expect_empty(result => {
///       let status = result.is_none()
///       dispatch(UserDeletedStatus(status))
///     })
///     ```
/// - ignoring the returned `Cmd`
///     ```
///     @http.delete("api/user/1").expect_empty(x => dispatch(UserDeleted(x))) |> ignore
///     ```
pub fn Request::expect_empty(self : Request, msg : Dispatch[Error?]) -> Cmd {
  self.send(on_success=_ => msg(None), on_failure=error => msg(Some(error)))
}

///|
/// Create a `GET` request.
/// 
/// The request body is empty.
/// Finish the request with `expect`, `expect_json`, `expect_text`, or
/// `expect_empty` to turn it into a `Cmd`.
/// 
/// ```mbt nocheck
/// @http.get("api/user").expect(x => dispatch(UserLoaded(x)))
/// ```
/// 
/// It is recommended to build and finish the request in one expression.
/// **Keep request construction local and straightforward.**
/// 
/// ### Anti-pattern:
/// - ignoring the returned `Request`
///     ```mbt nocheck
///     @http.get("api/user") |> ignore
///     ```
/// - storing the `Request` or `Cmd` in a variable
///     ```
///     let user_api_request = @http.get("api/user")
///     let user_api_cmd = @http.get("api/user").expect(x => dispatch(x))
///     ```
/// - wrapping the request construction in a helper function
///     ```mbt nocheck
///     fn fetch_user(dispatch : Dispatch[Msg]) -> Cmd {
///       @http.get("api/user").expect(x => dispatch(UserLoaded(x)))
///     }
///     ```
pub fn get(url : String) -> Request {
  { url, http_method: "GET", body: Empty }
}

///|
/// Create a `DELETE` request.
/// 
/// The request body is empty.
/// Finish the request with `expect`, `expect_json`, `expect_text`, or
/// `expect_empty` to turn it into a `Cmd`.
/// 
/// ```mbt nocheck
/// @http.delete("api/user/1").expect_empty(x => dispatch(UserDeleted(x)))
/// ```
/// 
/// It is recommended to build and finish the request in one expression.
/// **Keep request construction local and straightforward.**
/// 
/// ### Anti-pattern:
/// - ignoring the returned `Request`
///     ```mbt nocheck
///     @http.delete("api/user/1") |> ignore
///     ```
/// - storing the `Request` or `Cmd` in a variable
///     ```
///     let delete_user_request = @http.delete("api/user/1")
///     let delete_user_cmd = @http.delete("api/user/1").expect_empty(x => dispatch(x))
///     ```
/// - wrapping the request construction in a helper function
///     ```mbt nocheck
///     fn delete_user(dispatch : Dispatch[Msg]) -> Cmd {
///       @http.delete("api/user/1").expect_empty(x => dispatch(UserDeleted(x)))
///     }
///     ```
pub fn delete(url : String) -> Request {
  { url, http_method: "DELETE", body: Empty }
}

///|
/// Create a `POST` request.
/// 
/// The request body is set to `body`.
/// Finish the request with `expect`, `expect_json`, `expect_text`, or
/// `expect_empty` to turn it into a `Cmd`.
/// 
/// ```mbt nocheck
/// @http.post("api/user", Json(payload)).expect_empty(x => dispatch(UserCreated(x)))
/// ```
/// 
/// It is recommended to build and finish the request in one expression.
/// **Keep request construction local and straightforward.**
/// 
/// ### Anti-pattern:
/// - ignoring the returned `Request`
///     ```mbt nocheck
///     @http.post("api/user", Json(payload)) |> ignore
///     ```
/// - storing the `Request` or `Cmd` in a variable
///     ```
///     let create_user_request = @http.post("api/user", Json(payload))
///     let create_user_cmd = @http.post("api/user", Json(payload)).expect_empty(x => dispatch(x))
///     ```
/// - wrapping the request construction in a helper function
///     ```mbt nocheck
///     fn create_user(dispatch : Dispatch[Msg]) -> Cmd {
///       @http.post("api/user", Json(payload)).expect_empty(x => {
///         dispatch(UserCreated(x))
///       })
///     }
///     ```
pub fn post(url : String, body : Body) -> Request {
  { url, http_method: "POST", body }
}

///|
/// Create a `PATCH` request.
/// 
/// The request body is set to `body`.
/// Finish the request with `expect`, `expect_json`, `expect_text`, or
/// `expect_empty` to turn it into a `Cmd`.
/// 
/// ```mbt nocheck
/// @http
///   .patch("api/user/1", Json(payload))
///   .expect_empty(x => dispatch(UserPatched(x)))
/// ```
/// 
/// It is recommended to build and finish the request in one expression.
/// **Keep request construction local and straightforward.**
/// 
/// ### Anti-pattern:
/// - ignoring the returned `Request`
///     ```mbt nocheck
///     @http.patch("api/user/1", Json(payload)) |> ignore
///     ```
/// - storing the `Request` or `Cmd` in a variable
///     ```
///     let patch_user_request = @http.patch("api/user/1", Json(payload))
///     let patch_user_cmd = @http.patch("api/user/1", Json(payload)).expect_empty(x => dispatch(x))
///     ```
/// - wrapping the request construction in a helper function
///     ```mbt nocheck
///     fn patch_user(dispatch : Dispatch[Msg]) -> Cmd {
///       @http.patch("api/user/1", Json(payload)).expect_empty(x => {
///         dispatch(UserPatched(x))
///       })
///     }
///     ```
pub fn patch(url : String, body : Body) -> Request {
  { url, http_method: "PATCH", body }
}

///|
/// Create a `PUT` request.
/// 
/// The request body is set to `body`.
/// Finish the request with `expect`, `expect_json`, `expect_text`, or
/// `expect_empty` to turn it into a `Cmd`.
/// 
/// ```mbt nocheck
/// @http
///   .put("api/user/1", Json(payload))
///   .expect_empty(x => dispatch(UserReplaced(x)))
/// ```
/// 
/// It is recommended to build and finish the request in one expression.
/// **Keep request construction local and straightforward.**
/// 
/// ### Anti-pattern:
/// - ignoring the returned `Request`
///     ```mbt nocheck
///     @http.put("api/user/1", Json(payload)) |> ignore
///     ```
/// - storing the `Request` or `Cmd` in a variable
///     ```mbt nocheck
///     let replace_user_request = @http.put("api/user/1", Json(payload))
///
///     let replace_user_cmd = @http.put("api/user/1", Json(payload)).expect_empty(x => {
///       dispatch(x)
///     })
///     ```
/// - wrapping the request construction in a helper function
///     ```mbt nocheck
///     fn replace_user(dispatch : Dispatch[Msg]) -> Cmd {
///       @http.put("api/user/1", Json(payload)).expect_empty(x => {
///         dispatch(UserReplaced(x))
///       })
///     }
///     ```
pub fn put(url : String, body : Body) -> Request {
  { url, http_method: "PUT", body }
}

///|
pub(all) enum Body {
  Json(Json)
  Text(String)
  Empty
}

///|
pub(all) suberror RequestError {
  RequestError(String)
}

///|
fn Request::send(
  self : Request,
  on_success~ : (String) -> Cmd,
  on_failure~ : (Error) -> Cmd,
) -> Cmd {
  @cmd.custom_cmd(fn(scheduler : &Scheduler) {
    let (content_type, body, has_body) = match self.body {
      Json(json) => ("application/json", json.stringify(), true)
      Text(text) => ("text/plain", text, true)
      Empty => ("text/plain", "", false)
    }
    js_request(
      self.url,
      self.http_method,
      content_type~,
      body~,
      has_body~,
      succeed=body => scheduler.add(on_success(body)),
      failed=detail => {
        scheduler.add(on_failure(RequestError("Http request failed:\{detail}")))
      },
    )
  })
}

///|
extern "js" fn js_request(
  url : String,
  http_method : String,
  content_type~ : String,
  body~ : String,
  has_body~ : Bool,
  succeed~ : (String) -> Unit,
  failed~ : (String) -> Unit,
) =
  #| (url, method, contentType, body, hasBody, succeed, failed) => {
  #|   const config = {
  #|     method,
  #|     headers: { "Content-Type": contentType },
  #|   };
  #|   if (hasBody) {
  #|     config.body = body;
  #|   }
  #|   fetch(url, config)
  #|     .then((response) => response.text())
  #|     .then((text) => succeed(text))
  #|     .catch((error) => failed(error.toString()));
  #| }
