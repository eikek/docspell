module Comp.ItemSearchInput exposing (Config, Model, Msg, defaultConfig, hasFocus, init, isSearching, update, view)

import Api
import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.SimpleTextInput
import Data.Flags exposing (Flags)
import Data.ItemQuery as IQ
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Html exposing (Attribute, Html, a, div, span, text)
import Html.Attributes exposing (class, classList, href, placeholder)
import Html.Events exposing (onBlur, onClick, onFocus)
import Http
import Messages.Comp.ItemSearchInput exposing (Texts)
import Process
import Styles as S
import Task
import Util.Html
import Util.List
import Util.String


type alias Model =
    { searchModel : Comp.SimpleTextInput.Model
    , config : Config
    , results : List ItemLight
    , searchProgress : Bool
    , menuState : MenuState
    , focus : Bool
    , errorState : ErrorState
    }


type alias MenuState =
    { open : Bool
    , active : Maybe String
    }


type ErrorState
    = NoError
    | HttpError Http.Error


type alias Config =
    { makeQuery : String -> IQ.ItemQuery
    , limit : Int
    }


defaultConfig : Config
defaultConfig =
    { limit = 15
    , makeQuery = defaultMakeQuery
    }


defaultMakeQuery : String -> IQ.ItemQuery
defaultMakeQuery str =
    let
        qstr =
            Util.String.appendIfAbsent "*" str
    in
    IQ.Or
        [ IQ.ItemIdMatch qstr
        , IQ.AllNames qstr
        ]


init : Config -> Model
init cfg =
    let
        textCfg =
            { delay = 200
            , setOnTyping = True
            , setOnEnter = True
            , setOnBlur = False
            }
    in
    { searchModel = Comp.SimpleTextInput.init textCfg Nothing
    , config = cfg
    , results = []
    , searchProgress = False
    , menuState =
        { open = False
        , active = Nothing
        }
    , errorState = NoError
    , focus = False
    }


type Msg
    = SetSearchMsg Comp.SimpleTextInput.Msg
    | SearchResultResp (Result Http.Error ItemLightList)
    | SelectItem ItemLight
    | FocusGained
    | FocusRemoved Bool


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , selected : Maybe ItemLight
    }


isSearching : Model -> Bool
isSearching model =
    model.searchProgress


hasFocus : Model -> Bool
hasFocus model =
    model.focus



--- Update


unit : Model -> UpdateResult
unit model =
    UpdateResult model Cmd.none Sub.none Nothing


update : Flags -> Maybe IQ.ItemQuery -> Msg -> Model -> UpdateResult
update flags addQuery msg model =
    case msg of
        SetSearchMsg lm ->
            let
                res =
                    Comp.SimpleTextInput.update lm model.searchModel

                findActiveItem results =
                    Maybe.andThen (\id -> List.filter (\e -> e.id == id) results |> List.head) model.menuState.active

                ( mm, selectAction ) =
                    case res.keyPressed of
                        Just Util.Html.ESC ->
                            ( setMenuOpen False model, False )

                        Just Util.Html.Enter ->
                            if model.menuState.open then
                                ( model, True )

                            else
                                ( setMenuOpen True model, False )

                        Just Util.Html.Up ->
                            ( setActivePrev model, False )

                        Just Util.Html.Down ->
                            ( setActiveNext model, False )

                        _ ->
                            ( model, False )

                ( model_, searchCmd ) =
                    case res.change of
                        Comp.SimpleTextInput.ValueUnchanged ->
                            ( mm, Cmd.none )

                        Comp.SimpleTextInput.ValueUpdated v ->
                            let
                                cmd =
                                    makeSearchCmd flags model addQuery v
                            in
                            ( { mm | searchProgress = cmd /= Cmd.none }, cmd )
            in
            if selectAction then
                findActiveItem model.results
                    |> Maybe.map SelectItem
                    |> Maybe.map (\m -> update flags addQuery m model)
                    |> Maybe.withDefault (unit model)

            else
                { model = { model_ | searchModel = res.model }
                , cmd = Cmd.batch [ Cmd.map SetSearchMsg res.cmd, searchCmd ]
                , sub = Sub.map SetSearchMsg res.sub
                , selected = Nothing
                }

        SearchResultResp (Ok list) ->
            unit
                { model
                    | results = Data.Items.flatten list
                    , errorState = NoError
                    , searchProgress = False
                }

        SearchResultResp (Err err) ->
            unit { model | errorState = HttpError err, searchProgress = False }

        SelectItem item ->
            let
                ms =
                    model.menuState

                ( searchModel, sub ) =
                    Comp.SimpleTextInput.setValue model.searchModel ""

                res =
                    unit
                        { model
                            | menuState = { ms | open = False }
                            , searchModel = searchModel
                        }
            in
            { res | selected = Just item, sub = Sub.map SetSearchMsg sub }

        FocusGained ->
            unit (setMenuOpen True model |> setFocus True)

        FocusRemoved flag ->
            if flag then
                unit (setMenuOpen False model |> setFocus False)

            else
                { model = model
                , cmd =
                    Process.sleep 100
                        |> Task.perform (\_ -> FocusRemoved True)
                , sub = Sub.none
                , selected = Nothing
                }


makeSearchCmd : Flags -> Model -> Maybe IQ.ItemQuery -> Maybe String -> Cmd Msg
makeSearchCmd flags model addQuery str =
    let
        itemQuery =
            IQ.and
                [ addQuery
                , Maybe.map model.config.makeQuery str
                ]

        qstr =
            IQ.renderMaybe itemQuery

        q =
            { offset = Nothing
            , limit = Just model.config.limit
            , withDetails = Just False
            , searchMode = Nothing
            , query = qstr
            }
    in
    if str == Nothing then
        Cmd.none

    else
        Api.itemSearch flags q SearchResultResp


setMenuOpen : Bool -> Model -> Model
setMenuOpen flag model =
    let
        ms =
            model.menuState
    in
    { model | menuState = { ms | open = flag } }


setFocus : Bool -> Model -> Model
setFocus flag model =
    { model | focus = flag }


setActiveNext : Model -> Model
setActiveNext model =
    let
        find ms =
            case ms.active of
                Just id ->
                    Util.List.findNext (\e -> e.id == id) model.results

                Nothing ->
                    List.head model.results

        set ms act =
            { ms | active = act }

        updateMs =
            find >> Maybe.map .id >> set model.menuState
    in
    if model.menuState.open then
        { model | menuState = updateMs model.menuState }

    else
        model


setActivePrev : Model -> Model
setActivePrev model =
    let
        find ms =
            case ms.active of
                Just id ->
                    Util.List.findPrev (\e -> e.id == id) model.results

                Nothing ->
                    List.reverse model.results |> List.head

        set ms act =
            { ms | active = act }

        updateMs =
            find >> Maybe.map .id >> set model.menuState
    in
    if model.menuState.open then
        { model | menuState = updateMs model.menuState }

    else
        model



--- View


view : Texts -> UiSettings -> Model -> List (Attribute Msg) -> Html Msg
view texts settings model attrs =
    let
        inputAttrs =
            [ class S.textInput
            , onFocus FocusGained
            , onBlur (FocusRemoved False)
            , placeholder texts.placeholder
            ]
    in
    div
        [ class "relative"
        ]
        [ Comp.SimpleTextInput.viewMap SetSearchMsg
            (inputAttrs ++ attrs)
            model.searchModel
        , renderResultMenu texts settings model
        ]


renderResultMenu : Texts -> UiSettings -> Model -> Html Msg
renderResultMenu texts _ model =
    div
        [ class "z-50 max-h-96 overflow-y-auto"
        , class dropdownMenu
        , classList [ ( "hidden", not model.menuState.open ) ]
        ]
        (case model.errorState of
            HttpError err ->
                [ div
                    [ class dropdownItem
                    , class S.errorText
                    ]
                    [ text <| texts.httpError err
                    ]
                ]

            NoError ->
                case model.results of
                    [] ->
                        [ div [ class dropdownItem ]
                            [ span [ class "italic" ]
                                [ text texts.noResults
                                ]
                            ]
                        ]

                    _ ->
                        List.map (renderResultItem model) model.results
        )


renderResultItem : Model -> ItemLight -> Html Msg
renderResultItem model item =
    let
        active =
            model.menuState.active == Just item.id
    in
    a
        [ classList
            [ ( dropdownItem, not active )
            , ( activeItem, active )
            ]
        , href "#"
        , onClick (SelectItem item)
        ]
        [ text item.name
        ]


dropdownMenu : String
dropdownMenu =
    " absolute left-0 bg-white dark:bg-slate-800 border dark:border-slate-700 dark:text-slate-300 shadow-lg opacity-1 transition duration-200 w-full "


dropdownItem : String
dropdownItem =
    "transition-colors duration-200 items-center block px-4 py-2 text-normal hover:bg-gray-200 dark:hover:bg-slate-700 dark:hover:text-slate-50"


activeItem : String
activeItem =
    "transition-colors duration-200 items-center block px-4 py-2 text-normal bg-gray-200 dark:bg-slate-700 dark:text-slate-50"
