module Comp.BoxSearchQueryInput exposing
    ( Model
    , Msg
    , UpdateResult
    , init
    , switchToBookmark
    , switchToQuery
    , toSearchQuery
    , update
    , view
    )

import Api
import Comp.BookmarkDropdown
import Comp.PowerSearchInput
import Data.Bookmarks exposing (AllBookmarks)
import Data.BoxContent exposing (SearchQuery(..))
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html, div, input, label, span, text)
import Html.Attributes exposing (checked, class, type_)
import Html.Events exposing (onCheck)
import Http
import Messages.Comp.BoxSearchQueryInput exposing (Texts)
import Styles as S


type alias Model =
    { queryModel : QueryModel
    , allBookmarks : AllBookmarks
    }


type QueryModel
    = Search Comp.PowerSearchInput.Model
    | Bookmark Comp.BookmarkDropdown.Model


toSearchQuery : Model -> Maybe SearchQuery
toSearchQuery model =
    case model.queryModel of
        Search pm ->
            let
                qstr =
                    Maybe.withDefault "" pm.input
            in
            if qstr == "" || Comp.PowerSearchInput.isValid pm then
                Just (SearchQueryString qstr)

            else
                Nothing

        Bookmark bm ->
            Comp.BookmarkDropdown.getSelectedId bm
                |> Maybe.map SearchQueryBookmark


type Msg
    = GetBookmarksResp (Result Http.Error AllBookmarks)
    | BookmarkMsg Comp.BookmarkDropdown.Msg
    | PowerSearchMsg Comp.PowerSearchInput.Msg
    | SwitchQueryBookmark
    | SwitchQuerySearch


switchToBookmark : Msg
switchToBookmark =
    SwitchQueryBookmark


switchToQuery : Msg
switchToQuery =
    SwitchQuerySearch


init : Flags -> SearchQuery -> AllBookmarks -> ( Model, Cmd Msg, Sub Msg )
init flags query bookmarks =
    let
        emptyModel =
            { queryModel = Search Comp.PowerSearchInput.init
            , allBookmarks = bookmarks
            }
    in
    case query of
        SearchQueryBookmark id ->
            initQueryBookmark flags emptyModel (Just id)

        SearchQueryString qstr ->
            initQuerySearch emptyModel qstr


initQueryBookmark : Flags -> Model -> Maybe String -> ( Model, Cmd Msg, Sub Msg )
initQueryBookmark flags model bookmarkId =
    ( { model
        | queryModel =
            Bookmark
                (Comp.BookmarkDropdown.initWith model.allBookmarks bookmarkId)
      }
    , if model.allBookmarks == Data.Bookmarks.empty then
        Api.getBookmarks flags GetBookmarksResp

      else
        Cmd.none
    , Sub.none
    )


initQuerySearch : Model -> String -> ( Model, Cmd Msg, Sub Msg )
initQuerySearch model qstr =
    let
        ( qm, qc, qs ) =
            Comp.PowerSearchInput.initWith qstr
    in
    ( { model | queryModel = Search qm }
    , Cmd.map PowerSearchMsg qc
    , Sub.map PowerSearchMsg qs
    )



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , query : Maybe SearchQuery
    }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        GetBookmarksResp (Ok list) ->
            let
                bmId =
                    case model.queryModel of
                        Bookmark bm ->
                            Comp.BookmarkDropdown.getSelectedId bm

                        Search _ ->
                            Nothing

                nm =
                    { model | allBookmarks = list }
            in
            case model.queryModel of
                Bookmark _ ->
                    update flags
                        SwitchQueryBookmark
                        { nm
                            | queryModel =
                                Bookmark (Comp.BookmarkDropdown.initWith model.allBookmarks bmId)
                        }

                Search _ ->
                    unit nm

        GetBookmarksResp (Err _) ->
            unit model

        BookmarkMsg lm ->
            case model.queryModel of
                Bookmark m ->
                    let
                        ( bm, bc ) =
                            Comp.BookmarkDropdown.update lm m

                        nextModel =
                            { model | queryModel = Bookmark bm }
                    in
                    { model = nextModel
                    , cmd = Cmd.map BookmarkMsg bc
                    , sub = Sub.none
                    , query = toSearchQuery nextModel
                    }

                _ ->
                    unit model

        PowerSearchMsg lm ->
            case model.queryModel of
                Search m ->
                    let
                        result =
                            Comp.PowerSearchInput.update lm m

                        nextModel =
                            { model | queryModel = Search result.model }
                    in
                    { model = nextModel
                    , cmd = Cmd.map PowerSearchMsg result.cmd
                    , sub = Sub.map PowerSearchMsg result.subs
                    , query = toSearchQuery nextModel
                    }

                _ ->
                    unit model

        SwitchQueryBookmark ->
            let
                selected =
                    case toSearchQuery model of
                        Just (SearchQueryBookmark id) ->
                            Just id

                        _ ->
                            Nothing

                ( m, c, s ) =
                    initQueryBookmark flags model selected
            in
            UpdateResult m c s (toSearchQuery m)

        SwitchQuerySearch ->
            let
                qstr =
                    case toSearchQuery model of
                        Just (SearchQueryString q) ->
                            q

                        _ ->
                            ""

                ( m, c, s ) =
                    initQuerySearch model qstr
            in
            UpdateResult m c s (toSearchQuery m)


unit : Model -> UpdateResult
unit model =
    UpdateResult model Cmd.none Sub.none Nothing



--- View


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        ( isBookmark, isQuery ) =
            case model.queryModel of
                Bookmark _ ->
                    ( True, False )

                Search _ ->
                    ( False, True )

        searchSettings =
            { placeholder = texts.searchPlaceholder
            , extraAttrs = []
            }
    in
    div [ class "flex flex-col" ]
        [ div [ class "flex flex-row space-x-4" ]
            [ label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , checked isBookmark
                    , onCheck (\_ -> SwitchQueryBookmark)
                    , class S.radioInput
                    ]
                    []
                , span [ class "ml-2" ] [ text texts.switchToBookmark ]
                ]
            , label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , checked isQuery
                    , onCheck (\_ -> SwitchQuerySearch)
                    , class S.radioInput
                    ]
                    []
                , span [ class "ml-2" ] [ text texts.switchToQuery ]
                ]
            ]
        , case model.queryModel of
            Bookmark m ->
                Html.map BookmarkMsg
                    (Comp.BookmarkDropdown.view texts.bookmarkDropdown settings m)

            Search m ->
                div [ class "relative" ]
                    [ Html.map PowerSearchMsg
                        (Comp.PowerSearchInput.viewInput searchSettings m)
                    , Html.map PowerSearchMsg
                        (Comp.PowerSearchInput.viewResult [] m)
                    ]
        ]
