{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.AddonRunConfigForm exposing (Model, Msg, get, init, initWith, update, view)

import Api
import Api.Model.Addon exposing (Addon)
import Api.Model.AddonList exposing (AddonList)
import Api.Model.AddonRef exposing (AddonRef)
import Api.Model.AddonRunConfig exposing (AddonRunConfig)
import Api.Model.User exposing (User)
import Api.Model.UserList exposing (UserList)
import Comp.Basic as B
import Comp.CalEventInput
import Comp.Dropdown
import Comp.MenuBar as MB
import Data.AddonTrigger exposing (AddonTrigger)
import Data.CalEvent exposing (CalEvent)
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.TimeZone exposing (TimeZone)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Markdown
import Messages.Comp.AddonRunConfigForm exposing (Texts)
import Process
import Styles as S
import Task
import Util.List
import Util.String


type alias Model =
    { runConfig : AddonRunConfig
    , name : String
    , enabled : Bool
    , userDropdown : Comp.Dropdown.Model User
    , userId : Maybe String
    , userList : List User
    , scheduleModel : Maybe Comp.CalEventInput.Model
    , schedule : Maybe CalEvent
    , triggerDropdown : Comp.Dropdown.Model AddonTrigger
    , addons : List AddonRef
    , selectedAddon : Maybe AddonConfigModel
    , existingAddonDropdown : Comp.Dropdown.Model Addon
    , existingAddons : List Addon
    , configApplied : Bool
    }


type alias AddonConfigModel =
    { ref : AddonRef
    , position : Int
    , args : String
    , readMore : Bool
    }


getRef : AddonConfigModel -> AddonRef
getRef cfg =
    let
        a =
            cfg.ref
    in
    { a | args = cfg.args }


emptyModel : Model
emptyModel =
    { runConfig = Api.Model.AddonRunConfig.empty
    , name = ""
    , enabled = True
    , userDropdown = Comp.Dropdown.makeSingle
    , userId = Nothing
    , userList = []
    , scheduleModel = Nothing
    , schedule = Nothing
    , triggerDropdown =
        Comp.Dropdown.makeMultipleList
            { options = Data.AddonTrigger.all, selected = [] }
    , addons = []
    , selectedAddon = Nothing
    , existingAddonDropdown = Comp.Dropdown.makeSingle
    , existingAddons = []
    , configApplied = False
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel
    , Cmd.batch
        [ Api.getUsers flags UserListResp
        , Api.addonsGetAll flags AddonListResp
        ]
    )


initWith : Flags -> AddonRunConfig -> ( Model, Cmd Msg )
initWith flags a =
    let
        ce =
            Maybe.andThen Data.CalEvent.fromEvent a.schedule

        ceInit =
            Maybe.map (Comp.CalEventInput.init flags) ce

        triggerModel =
            Comp.Dropdown.makeMultipleList
                { options = Data.AddonTrigger.all
                , selected = Data.AddonTrigger.fromList a.trigger
                }
    in
    ( { emptyModel
        | runConfig = a
        , name = a.name
        , enabled = a.enabled
        , scheduleModel = Maybe.map Tuple.first ceInit
        , schedule = ce
        , triggerDropdown = triggerModel
        , userId = a.userId
        , addons = a.addons
      }
    , Cmd.batch
        [ Api.getUsers flags UserListResp
        , Api.addonsGetAll flags AddonListResp
        , Maybe.map Tuple.second ceInit
            |> Maybe.map (Cmd.map ScheduleMsg)
            |> Maybe.withDefault Cmd.none
        ]
    )


isValid : Model -> Bool
isValid model =
    model.name
        /= ""
        && (Comp.Dropdown.getSelected model.triggerDropdown
                |> List.isEmpty
                |> not
           )
        && (List.isEmpty model.addons
                |> not
           )


get : Model -> Maybe AddonRunConfig
get model =
    let
        a =
            model.runConfig
    in
    if isValid model then
        Just
            { a
                | name = model.name
                , enabled = model.enabled
                , schedule = Maybe.map Data.CalEvent.makeEvent model.schedule
                , trigger =
                    Comp.Dropdown.getSelected model.triggerDropdown
                        |> List.map Data.AddonTrigger.asString
                , userId = model.userId
                , addons = model.addons
            }

    else
        Nothing


type Msg
    = SetName String
    | UserListResp (Result Http.Error UserList)
    | AddonListResp (Result Http.Error AddonList)
    | ScheduleMsg Comp.CalEventInput.Msg
    | UserDropdownMsg (Comp.Dropdown.Msg User)
    | TriggerDropdownMsg (Comp.Dropdown.Msg AddonTrigger)
    | AddonDropdownMsg (Comp.Dropdown.Msg Addon)
    | Configure Int AddonRef
    | Up Int
    | Down Int
    | Remove Int
    | ToggleEnabled
    | ConfigSetArgs String
    | ConfigApply
    | ConfigCancel
    | AddSelectedAddon
    | ConfigToggleReadMore
    | ConfigArgsUpdated Bool



--- Update


update : Flags -> TimeZone -> Msg -> Model -> ( Model, Cmd Msg )
update flags tz msg model =
    case msg of
        UserListResp (Ok list) ->
            let
                um =
                    Comp.Dropdown.makeSingleList
                        { options = list.items
                        , selected = Nothing
                        }
            in
            ( { model | userDropdown = um, userList = list.items }, Cmd.none )

        UserListResp (Err err) ->
            ( model, Cmd.none )

        AddonListResp (Ok list) ->
            let
                am =
                    Comp.Dropdown.makeSingleList
                        { options = list.items
                        , selected = Nothing
                        }
            in
            ( { model | existingAddonDropdown = am, existingAddons = list.items }, Cmd.none )

        AddonListResp (Err err) ->
            ( model, Cmd.none )

        UserDropdownMsg lm ->
            let
                ( um, cmd ) =
                    Comp.Dropdown.update lm model.userDropdown

                sel =
                    Comp.Dropdown.getSelected um |> List.head
            in
            ( { model | userDropdown = um, userId = Maybe.map .id sel }, Cmd.map UserDropdownMsg cmd )

        TriggerDropdownMsg lm ->
            let
                ( tm, tc ) =
                    Comp.Dropdown.update lm model.triggerDropdown

                ( nm, nc ) =
                    initScheduleIfNeeded flags { model | triggerDropdown = tm } tz
            in
            ( nm, Cmd.batch [ Cmd.map TriggerDropdownMsg tc, nc ] )

        ScheduleMsg lm ->
            case model.scheduleModel of
                Just m ->
                    let
                        ( cm, cc, ce ) =
                            Comp.CalEventInput.update flags tz model.schedule lm m
                    in
                    ( { model | scheduleModel = Just cm, schedule = ce }, Cmd.map ScheduleMsg cc )

                Nothing ->
                    ( model, Cmd.none )

        ToggleEnabled ->
            ( { model | enabled = not model.enabled }, Cmd.none )

        AddonDropdownMsg lm ->
            let
                ( am, ac ) =
                    Comp.Dropdown.update lm model.existingAddonDropdown
            in
            ( { model | existingAddonDropdown = am }, Cmd.map AddonDropdownMsg ac )

        Configure index ref ->
            let
                cfg =
                    { ref = ref
                    , position = index + 1
                    , args = ref.args
                    , readMore = False
                    }
            in
            ( { model | selectedAddon = Just cfg }, Cmd.none )

        ConfigCancel ->
            ( { model | selectedAddon = Nothing }, Cmd.none )

        ConfigToggleReadMore ->
            case model.selectedAddon of
                Just cfg ->
                    ( { model | selectedAddon = Just { cfg | readMore = not cfg.readMore } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ConfigArgsUpdated flag ->
            ( { model | configApplied = flag }, Cmd.none )

        ConfigSetArgs str ->
            case model.selectedAddon of
                Just cfg ->
                    ( { model | selectedAddon = Just { cfg | args = str } }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        ConfigApply ->
            case model.selectedAddon of
                Just cfg ->
                    let
                        na =
                            getRef cfg

                        addons =
                            Util.List.replaceByIndex (cfg.position - 1) na model.addons
                    in
                    ( { model | addons = addons, configApplied = True }
                    , Process.sleep 1200 |> Task.perform (\_ -> ConfigArgsUpdated False)
                    )

                Nothing ->
                    ( model, Cmd.none )

        AddSelectedAddon ->
            let
                sel =
                    Comp.Dropdown.getSelected model.existingAddonDropdown |> List.head

                ( dm, _ ) =
                    Comp.Dropdown.update (Comp.Dropdown.SetSelection []) model.existingAddonDropdown

                addon =
                    Maybe.map
                        (\a ->
                            { addonId = a.id
                            , name = a.name
                            , version = a.version
                            , description = a.description
                            , args = ""
                            }
                        )
                        sel

                newAddons =
                    Maybe.map (\e -> e :: model.addons) addon
                        |> Maybe.withDefault model.addons
            in
            ( { model | addons = newAddons, existingAddonDropdown = dm, selectedAddon = Nothing }, Cmd.none )

        Up curIndex ->
            let
                newAddons =
                    Util.List.changePosition curIndex (curIndex - 1) model.addons
            in
            ( { model | addons = newAddons, selectedAddon = Nothing }, Cmd.none )

        Down curIndex ->
            let
                newAddons =
                    Util.List.changePosition (curIndex + 1) curIndex model.addons
            in
            ( { model | addons = newAddons, selectedAddon = Nothing }, Cmd.none )

        SetName str ->
            ( { model | name = str }, Cmd.none )

        Remove index ->
            ( { model | addons = Util.List.removeByIndex index model.addons, selectedAddon = Nothing }, Cmd.none )


initScheduleIfNeeded : Flags -> Model -> TimeZone -> ( Model, Cmd Msg )
initScheduleIfNeeded flags model tz =
    let
        hasTrigger =
            Comp.Dropdown.getSelected model.triggerDropdown
                |> List.any ((==) Data.AddonTrigger.Scheduled)

        noModel =
            model.scheduleModel == Nothing

        hasModel =
            not noModel

        ce =
            Data.CalEvent.everyMonthTz tz

        ( cm, cc ) =
            Comp.CalEventInput.init flags ce
    in
    if hasTrigger && noModel then
        ( { model | scheduleModel = Just cm, schedule = Just ce }, Cmd.map ScheduleMsg cc )

    else if not hasTrigger && hasModel then
        ( { model | scheduleModel = Nothing, schedule = Nothing }, Cmd.none )

    else
        ( model, Cmd.none )



--- View


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        userDs =
            { makeOption = \user -> { text = user.login, additional = "" }
            , placeholder = texts.basics.selectPlaceholder
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }

        triggerDs =
            { makeOption = \trigger -> { text = Data.AddonTrigger.asString trigger, additional = "" }
            , placeholder = texts.basics.selectPlaceholder
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }
    in
    div
        [ class "flex flex-col" ]
        [ div [ class "mb-4" ]
            [ div [ class "mb-4" ]
                [ label
                    [ class S.inputLabel
                    ]
                    [ text texts.basics.name
                    , B.inputRequired
                    ]
                , input
                    [ type_ "text"
                    , placeholder texts.chooseName
                    , value model.name
                    , onInput SetName
                    , class S.textInput
                    , classList [ ( S.inputErrorBorder, model.name == "" ) ]
                    ]
                    []
                ]
            , div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { tagger = \_ -> ToggleEnabled
                        , label = texts.enableDisable
                        , value = model.enabled
                        , id = "addon-run-config-enabled"
                        }
                ]
            , div [ class "mb-4" ]
                [ label
                    [ class S.inputLabel
                    ]
                    [ text texts.impersonateUser
                    ]
                , Html.map UserDropdownMsg
                    (Comp.Dropdown.view2 userDs settings model.userDropdown)
                ]
            , div [ class "mb-4" ]
                [ label
                    [ class S.inputLabel
                    ]
                    [ text texts.triggerRun
                    , B.inputRequired
                    ]
                , Html.map TriggerDropdownMsg
                    (Comp.Dropdown.view2 triggerDs settings model.triggerDropdown)
                ]
            , case model.scheduleModel of
                Nothing ->
                    span [ class "hidden" ] []

                Just m ->
                    div [ class "mb-4" ]
                        [ label
                            [ class S.inputLabel ]
                            [ text texts.schedule
                            ]
                        , Html.map ScheduleMsg (Comp.CalEventInput.view2 texts.calEventInput "" model.schedule m)
                        ]
            ]
        , div [ class "mb-4" ]
            [ h2 [ class S.header2 ]
                [ text texts.addons ]
            , addonRef texts model
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.includedAddons
                    , B.inputRequired
                    ]
                , newAddon texts settings model
                , div [ class "mb-4" ]
                    [ div [ class "flex flex-col mb-4" ]
                        (List.indexedMap (addonLine texts model) model.addons)
                    ]
                ]
            ]
        ]


newAddon : Texts -> UiSettings -> Model -> Html Msg
newAddon texts uiSettings model =
    let
        addonDs =
            { makeOption = \addon -> { text = addon.name ++ " / " ++ addon.version, additional = "" }
            , placeholder = texts.basics.selectPlaceholder
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }
    in
    div [ class "mb-4" ]
        [ div [ class "flex flex-row" ]
            [ div [ class "flex-grow mr-2" ]
                [ Html.map AddonDropdownMsg
                    (Comp.Dropdown.view2 addonDs uiSettings model.existingAddonDropdown)
                ]
            , B.primaryBasicButton
                { label = texts.add
                , icon = "fa fa-plus"
                , disabled = List.isEmpty (Comp.Dropdown.getSelected model.existingAddonDropdown)
                , handler = onClick AddSelectedAddon
                , attrs = [ href "#" ]
                }
            ]
        ]


addonRef : Texts -> Model -> Html Msg
addonRef texts model =
    let
        maybeRef =
            Maybe.map .ref model.selectedAddon

        refInfo =
            case model.selectedAddon of
                Nothing ->
                    div [ class "mb-4" ]
                        [ text "[ -- ]"
                        ]

                Just cfg ->
                    let
                        ( descr, requireFolding ) =
                            case cfg.ref.description of
                                Just d ->
                                    let
                                        part =
                                            Util.String.firstSentenceOrMax 120 d

                                        text =
                                            if cfg.readMore then
                                                d

                                            else
                                                Maybe.withDefault d part
                                    in
                                    ( Markdown.toHtml [ class "markdown-preview" ] text, part /= Nothing )

                                Nothing ->
                                    ( span [ class "italic" ] [ text "No description." ], False )
                    in
                    div [ class "flex flex-col mb-4" ]
                        [ div [ class "mt-2" ]
                            [ label [ class " font-semibold py-0.5 " ]
                                [ text cfg.ref.name
                                , text " "
                                , text cfg.ref.version
                                , text " (pos. "
                                , text <| String.fromInt cfg.position
                                , text ")"
                                , span
                                    [ classList [ ( "hidden", not requireFolding ) ]
                                    , class "ml-2"
                                    ]
                                    [ a
                                        [ class "px-4"
                                        , class S.link
                                        , href "#"
                                        , onClick ConfigToggleReadMore
                                        ]
                                        [ if cfg.readMore then
                                            text texts.readLess

                                          else
                                            text texts.readMore
                                        ]
                                    ]
                                ]
                            , div [ class "px-3 py-1 border-l dark:border-slate-600" ]
                                [ descr
                                ]
                            ]
                        ]
    in
    div
        [ class "flex flex-col mb-3"
        , classList [ ( "disabled", maybeRef == Nothing ) ]
        ]
        [ refInfo
        , div [ class "mb-2" ]
            [ label [ class S.inputLabel ] [ text texts.arguments ]
            , textarea
                [ Maybe.map .args model.selectedAddon |> Maybe.withDefault "" |> value
                , class S.textAreaInput
                , class "font-mono"
                , rows 8
                , onInput ConfigSetArgs
                ]
                []
            ]
        , MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = ConfigApply
                    , title = ""
                    , icon = Just "fa fa-save"
                    , label = texts.update
                    }
                , MB.SecondaryButton
                    { tagger = ConfigCancel
                    , title = texts.basics.cancel
                    , icon = Just "fa fa-times"
                    , label = texts.basics.cancel
                    }
                , MB.CustomElement <|
                    div
                        [ classList [ ( "hidden", not model.configApplied ) ]
                        , class S.successText
                        , class "inline-block min-w-fit font-semibold text-normal min-w-fit"
                        ]
                        [ text texts.argumentsUpdated
                        , i [ class "fa fa-thumbs-up ml-2" ] []
                        ]
                ]
            , end = []
            , rootClasses = "mb-4 text-sm"
            , sticky = False
            }
        ]


addonLine : Texts -> Model -> Int -> AddonRef -> Html Msg
addonLine texts model index ref =
    let
        isSelected =
            case model.selectedAddon of
                Just cfg ->
                    cfg.position - 1 == index

                Nothing ->
                    False
    in
    div
        [ class "flex flex-row items-center px-4 py-4 rounded shadow dark:border dark:border-slate-600 mb-2"
        , classList [ ( "ring-2", isSelected ) ]
        ]
        [ div [ class "px-2 hidden sm:block" ]
            [ span [ class "label rounded-full opacity-75" ]
                [ text <| String.fromInt (index + 1)
                ]
            ]
        , div [ class "px-4 font-semibold" ]
            [ text ref.name
            , text " v"
            , text ref.version
            ]
        , div [ class "flex-grow" ]
            []
        , div [ class "px-2" ]
            [ MB.view
                { start = []
                , end =
                    [ MB.PrimaryButton
                        { tagger = Configure index ref
                        , title = texts.configureTitle
                        , icon = Just "fa fa-cog"
                        , label = texts.configureLabel
                        }
                    , MB.CustomElement <|
                        B.secondaryButton
                            { handler = onClick (Up index)
                            , attrs = [ title "Move up", href "#" ]
                            , icon = "fa fa-arrow-up"
                            , label = ""
                            , disabled = index == 0
                            }
                    , MB.CustomElement <|
                        B.secondaryButton
                            { handler = onClick (Down index)
                            , attrs = [ title "Move down", href "#" ]
                            , icon = "fa fa-arrow-down"
                            , label = ""
                            , disabled = index + 1 == List.length model.addons
                            }
                    , MB.CustomElement <|
                        B.deleteButton
                            { label = ""
                            , icon = "fa fa-trash"
                            , disabled = False
                            , handler = onClick (Remove index)
                            , attrs = [ href "#" ]
                            }
                    ]
                , rootClasses = "text-sm"
                , sticky = False
                }
            ]
        ]
