open Jwt

module RemoteData = {
  type t<'data> = option<result<'data, string>>

  let fmap = (m: t<'a>, f: 'a => 'b): t<'b> => {
    m->Belt.Option.flatMap(r => r->Belt.Result.flatMap(d => d->f->Ok)->Some)
  }
}

module UrlData = {
  let getParamOption = name => {
    let params = Prelude.URLSearchParams.current()
    params->Prelude.URLSearchParams.get(name)->Js.Nullable.toOption
  }
  let getParam = name => name->getParamOption->Belt.Option.getWithDefault("")
  let getOrder = () =>
    getParam("o")
    ->Prelude.orderFromQS
    ->Belt.Option.getWithDefault({field: "updated_at", direction: Desc})
    ->Some
  let getQuery = () =>
    switch getParam("q") {
    | "" => "from:now-3weeks"
    | q => q
    }
  let getFilter = () => getParam("f")
  let getLimit = () => {
    let params = Prelude.URLSearchParams.current()
    params
    ->Prelude.URLSearchParams.get("l")
    ->Js.Nullable.toOption
    ->Belt.Option.getWithDefault("0")
    ->int_of_string
  }
}

module Store = {
  type suggestionsR = RemoteData.t<SearchTypes.suggestions_response>
  type fieldsRespR = RemoteData.t<SearchTypes.fields_response>
  type projectsR = RemoteData.t<ConfigTypes.get_projects_response>
  type aboutR = RemoteData.t<ConfigTypes.get_about_response>

  type authorScopedTab =
    | ChangeActivity
    | ReviewActivity
    | OpenChanges
    | MergedChanges
    | AbandonedChanges
    | RepoSummary
    | GroupMembers

  type t = {
    index: string,
    query: string,
    filter: string,
    limit: int,
    username: option<string>,
    authenticated_user: option<Jwt.authenticatedUser>,
    order: option<SearchTypes.order>,
    author_scoped_tab: authorScopedTab,
    suggestions: suggestionsR,
    fields: RemoteData.t<list<SearchTypes.field>>,
    projects: projectsR,
    changes_pies_panel: bool,
    about: ConfigTypes.about,
    dexie: Dexie.Database.t,
    toasts: list<string>,
    errors: list<CrawlerTypes.crawler_error_list>,
  }
  type action =
    | ChangeIndex(string)
    | SetQuery(string)
    | SetFilter(string)
    | SetLimit(int)
    | SetOrder(option<SearchTypes.order>)
    | SetAuthorScopedTab(authorScopedTab)
    | SetErrors(list<CrawlerTypes.crawler_error_list>)
    | FetchFields(fieldsRespR)
    | FetchSuggestions(suggestionsR)
    | FetchProjects(projectsR)
    | ReverseChangesPiePanelState
    | RemoveToast(string)
    | AddToast(string)
    | NonAuthenticatedLogin(string)
    | NonAuthenticatedLogout
    | AuthenticatedLogout

  type dispatch = action => unit

  let getMonocleCookie = () =>
    Js.String.split(";", Prelude.getCookies())
    ->Belt.Array.keep(cookie => {
      Js.String.split("=", cookie)
      ->Belt.Array.get(0)
      ->Belt.Option.getWithDefault("")
      ->Js.String.trim == "Monocle"
    })
    ->Belt.Array.map(cookie =>
      Js.String.split("=", cookie)->Belt.Array.get(1)->Belt.Option.getWithDefault("")
    )
    ->Belt.Array.get(0)

  let getAuthenticatedUser = () =>
    getMonocleCookie()->Belt.Option.flatMap(jwt => jwt->jwtToAuthenticatedUser)

  let getAuthenticatedUserJWT = (state: t) =>
    state.authenticated_user->Belt.Option.flatMap(au => au.jwt->Some)

  let create = (index, about) => {
    index: index,
    query: UrlData.getQuery(),
    filter: UrlData.getFilter(),
    limit: UrlData.getLimit(),
    order: UrlData.getOrder(),
    author_scoped_tab: ChangeActivity,
    username: Dom.Storage.localStorage |> Dom.Storage.getItem("monocle_username"),
    authenticated_user: getAuthenticatedUser(),
    suggestions: None,
    fields: None,
    projects: None,
    about: about,
    changes_pies_panel: false,
    dexie: MonoIndexedDB.mkDexie(),
    toasts: list{},
    errors: list{},
  }

  let reducer = (state: t, action: action) =>
    switch action {
    | RemoveToast(toast) => {...state, toasts: state.toasts->Belt.List.keep(x => x != toast)}
    | AddToast(toast) => {
        ...state,
        toasts: state.toasts->Belt.List.keep(x => x != toast)->Belt.List.add(toast),
      }
    | ChangeIndex(index) => {
        RescriptReactRouter.push("/" ++ index)
        create(index, state.about)
      }
    | SetQuery(query) => {
        Prelude.setLocationSearch("q", query)->ignore
        {...state, query: query}
      }
    | SetFilter(query) => {
        Prelude.setLocationSearch("f", query)->ignore
        {...state, filter: query}
      }
    | SetOrder(order) => {
        Prelude.setLocationSearch("o", order->Prelude.orderToQS)->ignore
        {...state, order: order}
      }
    | SetAuthorScopedTab(name) => {...state, author_scoped_tab: name}
    | SetLimit(limit) => {
        Prelude.setLocationSearch("l", limit->string_of_int)->ignore
        {...state, limit: limit}
      }
    | SetErrors(errors) => {...state, errors: errors}
    | FetchFields(res) => {...state, fields: res->RemoteData.fmap(resp => resp.fields)}
    | FetchSuggestions(res) => {...state, suggestions: res}
    | FetchProjects(res) => {...state, projects: res}
    | ReverseChangesPiePanelState => {...state, changes_pies_panel: !state.changes_pies_panel}
    | NonAuthenticatedLogin(username) => {
        Dom.Storage.localStorage |> Dom.Storage.setItem("monocle_username", username)
        {...state, username: username->Some}
      }
    | NonAuthenticatedLogout => {
        Dom.Storage.localStorage |> Dom.Storage.removeItem("monocle_username")
        {...state, username: None}
      }
    | AuthenticatedLogout => {
        Prelude.delCookie("Monocle")
        {...state, authenticated_user: None}
      }
    }
}

module Fetch = {
  // Helper module to abstract the WebApi
  open WebApi
  let fetch = (
    value: RemoteData.t<'r>,
    get: unit => axios<'a>,
    mkAction: RemoteData.t<'a> => Store.action,
    dispatch: Store.dispatch,
  ) => {
    let set = v => v->Some->mkAction->dispatch->Js.Promise.resolve
    let handleErr = err => {
      Js.log(err)
      "Network error"->Error->set
    }
    let handleOk = resp => resp.data->Ok->set
    // Effect0 is performed when the component is monted
    React.useEffect0(() => {
      // We fetch the remote data only when needed
      switch value {
      | None => (get() |> Js.Promise.then_(handleOk) |> Js.Promise.catch(handleErr))->ignore
      | _ => ignore()
      }
      None
    })
    value
  }

  let suggestions = ((state: Store.t, dispatch)) =>
    fetch(
      state.suggestions,
      () => WebApi.Search.suggestions({SearchTypes.index: state.index}),
      res => Store.FetchSuggestions(res),
      dispatch,
    )

  let fields = ((state: Store.t, dispatch)) => {
    fetch(
      state.fields,
      () => WebApi.Search.fields({version: "1"}),
      res => Store.FetchFields(res),
      dispatch,
    )
  }

  let projects = ((state: Store.t, dispatch)) => {
    fetch(
      state.projects,
      () => WebApi.Config.getProjects({ConfigTypes.index: state.index}),
      res => Store.FetchProjects(res),
      dispatch,
    )
  }
}

let changeIndex = ((_, dispatch), name) => name->Store.ChangeIndex->dispatch

let mkSearchRequest = (state: Store.t, query_type: SearchTypes.query_request_query_type) => {
  SearchTypes.index: state.index,
  username: state.username->Belt.Option.getWithDefault(""),
  query: state.query,
  query_type: query_type,
  order: state.order,
  limit: state.limit->Int32.of_int,
  change_id: "",
}

// Hook API
type t = (Store.t, Store.action => unit)

let use = (index, about): t => React.useReducer(Store.reducer, Store.create(index, about))
