module Comp.FolderDetail exposing
    ( Model
    , Msg
    , init
    , initEmpty
    , update
    , view
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.FolderDetail exposing (FolderDetail)
import Api.Model.IdName exposing (IdName)
import Api.Model.IdResult exposing (IdResult)
import Api.Model.NewFolder exposing (NewFolder)
import Api.Model.User exposing (User)
import Comp.Basic as B
import Comp.FixedDropdown
import Comp.MenuBar as MB
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Styles as S
import Util.Http
import Util.Maybe


type alias Model =
    { result : Maybe BasicResult
    , folder : FolderDetail
    , name : Maybe String
    , members : List IdName
    , users : List User
    , memberDropdown : Comp.FixedDropdown.Model IdName
    , selectedMember : Maybe IdName
    , loading : Bool
    , deleteDimmer : Comp.YesNoDimmer.Model
    }


type Msg
    = SetName String
    | MemberDropdownMsg (Comp.FixedDropdown.Msg IdName)
    | SaveName
    | NewFolderResp (Result Http.Error IdResult)
    | ChangeFolderResp (Result Http.Error BasicResult)
    | ChangeNameResp (Result Http.Error BasicResult)
    | FolderDetailResp (Result Http.Error FolderDetail)
    | AddMember
    | RemoveMember IdName
    | RequestDelete
    | DeleteMsg Comp.YesNoDimmer.Msg
    | DeleteResp (Result Http.Error BasicResult)
    | GoBack


init : List User -> FolderDetail -> Model
init users folder =
    { result = Nothing
    , folder = folder
    , name = Util.Maybe.fromString folder.name
    , members = folder.members
    , users = users
    , memberDropdown =
        Comp.FixedDropdown.initMap .name
            (makeOptions users folder)
    , selectedMember = Nothing
    , loading = False
    , deleteDimmer = Comp.YesNoDimmer.emptyModel
    }


initEmpty : List User -> Model
initEmpty users =
    init users Api.Model.FolderDetail.empty


makeOptions : List User -> FolderDetail -> List IdName
makeOptions users folder =
    let
        toIdName u =
            IdName u.id u.login

        notMember idn =
            List.member idn (folder.owner :: folder.members) |> not
    in
    List.map toIdName users
        |> List.filter notMember



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Bool )
update flags msg model =
    case msg of
        GoBack ->
            ( model, Cmd.none, True )

        SetName str ->
            ( { model | name = Util.Maybe.fromString str }
            , Cmd.none
            , False
            )

        MemberDropdownMsg lmsg ->
            let
                ( mm, sel ) =
                    Comp.FixedDropdown.update lmsg model.memberDropdown
            in
            ( { model
                | memberDropdown = mm
                , selectedMember =
                    case sel of
                        Just _ ->
                            sel

                        Nothing ->
                            model.selectedMember
              }
            , Cmd.none
            , False
            )

        SaveName ->
            case model.name of
                Just name ->
                    let
                        cmd =
                            if model.folder.id == "" then
                                Api.createNewFolder flags (NewFolder name) NewFolderResp

                            else
                                Api.changeFolderName flags
                                    model.folder.id
                                    (NewFolder name)
                                    ChangeNameResp
                    in
                    ( { model
                        | loading = True
                        , result = Nothing
                      }
                    , cmd
                    , False
                    )

                Nothing ->
                    ( model, Cmd.none, False )

        NewFolderResp (Ok ir) ->
            if ir.success then
                ( model, Api.getFolderDetail flags ir.id FolderDetailResp, False )

            else
                ( { model
                    | loading = False
                    , result = Just (BasicResult ir.success ir.message)
                  }
                , Cmd.none
                , False
                )

        NewFolderResp (Err err) ->
            ( { model
                | loading = False
                , result = Just (BasicResult False (Util.Http.errorToString err))
              }
            , Cmd.none
            , False
            )

        ChangeFolderResp (Ok r) ->
            if r.success then
                ( model
                , Api.getFolderDetail flags model.folder.id FolderDetailResp
                , False
                )

            else
                ( { model | loading = False, result = Just r }
                , Cmd.none
                , False
                )

        ChangeFolderResp (Err err) ->
            ( { model
                | loading = False
                , result = Just (BasicResult False (Util.Http.errorToString err))
              }
            , Cmd.none
            , False
            )

        ChangeNameResp (Ok r) ->
            let
                model_ =
                    { model | result = Just r, loading = False }
            in
            ( model_, Cmd.none, False )

        ChangeNameResp (Err err) ->
            ( { model
                | result = Just (BasicResult False (Util.Http.errorToString err))
                , loading = False
              }
            , Cmd.none
            , False
            )

        FolderDetailResp (Ok sd) ->
            ( init model.users sd, Cmd.none, False )

        FolderDetailResp (Err err) ->
            ( { model
                | loading = False
                , result = Just (BasicResult False (Util.Http.errorToString err))
              }
            , Cmd.none
            , False
            )

        AddMember ->
            case model.selectedMember of
                Just mem ->
                    ( { model | loading = True }
                    , Api.addMember flags model.folder.id mem.id ChangeFolderResp
                    , False
                    )

                Nothing ->
                    ( model, Cmd.none, False )

        RemoveMember idname ->
            ( { model | loading = True }
            , Api.removeMember flags model.folder.id idname.id ChangeFolderResp
            , False
            )

        RequestDelete ->
            let
                ( dm, _ ) =
                    Comp.YesNoDimmer.update Comp.YesNoDimmer.activate model.deleteDimmer
            in
            ( { model | deleteDimmer = dm }, Cmd.none, False )

        DeleteMsg lm ->
            let
                ( dm, flag ) =
                    Comp.YesNoDimmer.update lm model.deleteDimmer

                cmd =
                    if flag then
                        Api.deleteFolder flags model.folder.id DeleteResp

                    else
                        Cmd.none
            in
            ( { model | deleteDimmer = dm }, cmd, False )

        DeleteResp (Ok r) ->
            ( { model | result = Just r }, Cmd.none, r.success )

        DeleteResp (Err err) ->
            ( { model | result = Just (BasicResult False (Util.Http.errorToString err)) }
            , Cmd.none
            , False
            )



--- View


view : Flags -> Model -> Html Msg
view flags model =
    let
        isOwner =
            Maybe.map .user flags.account
                |> Maybe.map ((==) model.folder.owner.name)
                |> Maybe.withDefault False
    in
    div []
        ([ Html.map DeleteMsg (Comp.YesNoDimmer.view model.deleteDimmer)
         , if model.folder.id == "" then
            div []
                [ text "Create a new folder. You are automatically set as owner of this new folder."
                ]

           else
            div []
                [ text "Modify this folder by changing the name or add/remove members."
                ]
         , if model.folder.id /= "" && not isOwner then
            div [ class "ui info message" ]
                [ text "You are not the owner of this folder and therefore are not allowed to edit it."
                ]

           else
            div [] []
         , div
            [ classList
                [ ( "ui message", True )
                , ( "invisible hidden", model.result == Nothing )
                , ( "error", Maybe.map .success model.result == Just False )
                , ( "success", Maybe.map .success model.result == Just True )
                ]
            ]
            [ Maybe.map .message model.result
                |> Maybe.withDefault ""
                |> text
            ]
         , div [ class "ui header" ]
            [ text "Owner"
            ]
         , div [ class "" ]
            [ text model.folder.owner.name
            ]
         , div [ class "ui header" ]
            [ text "Name"
            ]
         , div [ class "ui action input" ]
            [ input
                [ type_ "text"
                , onInput SetName
                , Maybe.withDefault "" model.name
                    |> value
                ]
                []
            , button
                [ class "ui icon button"
                , onClick SaveName
                ]
                [ i [ class "save icon" ] []
                ]
            ]
         ]
            ++ viewMembers model
            ++ viewButtons model
        )


viewButtons : Model -> List (Html Msg)
viewButtons model =
    [ div [ class "ui divider" ] []
    , button
        [ class "ui button"
        , onClick GoBack
        ]
        [ text "Back"
        ]
    , button
        [ classList
            [ ( "ui red button", True )
            , ( "invisible hidden", model.folder.id == "" )
            ]
        , onClick RequestDelete
        ]
        [ text "Delete"
        ]
    ]


viewMembers : Model -> List (Html Msg)
viewMembers model =
    if model.folder.id == "" then
        []

    else
        [ div [ class "ui header" ]
            [ text "Members"
            ]
        , div [ class "ui form" ]
            [ div [ class "inline field" ]
                [ Html.map MemberDropdownMsg
                    (Comp.FixedDropdown.view
                        (Maybe.map makeItem model.selectedMember)
                        model.memberDropdown
                    )
                , button
                    [ class "ui primary button"
                    , title "Add a new member"
                    , onClick AddMember
                    ]
                    [ text "Add"
                    ]
                ]
            ]
        , div
            [ class "ui list"
            ]
            (List.map viewMember model.members)
        ]


makeItem : IdName -> Comp.FixedDropdown.Item IdName
makeItem idn =
    Comp.FixedDropdown.Item idn idn.name


viewMember : IdName -> Html Msg
viewMember member =
    div
        [ class "item"
        ]
        [ a
            [ class "link icon"
            , href "#"
            , title "Remove this member"
            , onClick (RemoveMember member)
            ]
            [ i [ class "red trash icon" ] []
            ]
        , span []
            [ text member.name
            ]
        ]



--- View2


view2 : Flags -> Model -> Html Msg
view2 flags model =
    let
        isOwner =
            Maybe.map .user flags.account
                |> Maybe.map ((==) model.folder.owner.name)
                |> Maybe.withDefault False

        dimmerSettings : Comp.YesNoDimmer.Settings
        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings2 "Really delete this folder?"
    in
    div [ class "flex flex-col md:relative" ]
        (viewButtons2 model
            :: [ Html.map DeleteMsg
                    (Comp.YesNoDimmer.viewN
                        True
                        dimmerSettings
                        model.deleteDimmer
                    )
               , div
                    [ class "py-2 text-lg opacity-75"
                    , classList [ ( "hidden", model.folder.id /= "" ) ]
                    ]
                    [ text "You are automatically set as owner of this new folder."
                    ]
               , div
                    [ class "py-2 text-lg opacity-75"
                    , classList [ ( "hidden", model.folder.id == "" ) ]
                    ]
                    [ text "Modify this folder by changing the name or add/remove members."
                    ]
               , div
                    [ class S.message
                    , classList [ ( "hidden", model.folder.id == "" || isOwner ) ]
                    ]
                    [ text "You are not the owner of this folder and therefore are not allowed to edit it."
                    ]
               , div [ class "mb-4 flex flex-col" ]
                    [ label
                        [ class S.inputLabel
                        , for "folder-name"
                        ]
                        [ text "Name"
                        , B.inputRequired
                        ]
                    , div [ class "flex flex-row space-x-2" ]
                        [ input
                            [ type_ "text"
                            , onInput SetName
                            , Maybe.withDefault "" model.name
                                |> value
                            , classList [ ( S.inputErrorBorder, model.name == Nothing ) ]
                            , class S.textInput
                            , id "folder-name"
                            ]
                            []
                        , a
                            [ class S.primaryButton
                            , class "rounded-r -ml-1"
                            , onClick SaveName
                            , href "#"
                            ]
                            [ i [ class "fa fa-save" ] []
                            , span [ class "ml-2 hidden sm:inline" ]
                                [ text "Save"
                                ]
                            ]
                        ]
                    ]
               , div
                    [ classList
                        [ ( "hidden", model.result == Nothing )
                        , ( S.errorMessage, Maybe.map .success model.result == Just False )
                        , ( S.successMessage, Maybe.map .success model.result == Just True )
                        ]
                    , class "my-4"
                    ]
                    [ Maybe.map .message model.result
                        |> Maybe.withDefault ""
                        |> text
                    ]
               ]
            ++ viewMembers2 model
        )


viewMembers2 : Model -> List (Html Msg)
viewMembers2 model =
    if model.folder.id == "" then
        []

    else
        [ div
            [ class S.header3
            , class "mt-4"
            ]
            [ text "Members"
            ]
        , div [ class "flex flex-col space-y-2" ]
            [ div [ class "flex flex-row space-x-2" ]
                [ div [ class "flex-grow" ]
                    [ Html.map MemberDropdownMsg
                        (Comp.FixedDropdown.view2
                            (Maybe.map makeItem model.selectedMember)
                            model.memberDropdown
                        )
                    ]
                , a
                    [ title "Add a new member"
                    , onClick AddMember
                    , class S.primaryButton
                    , href "#"
                    , class "flex-none"
                    ]
                    [ i [ class "fa fa-plus" ] []
                    , span [ class "ml-2 hidden sm:inline" ]
                        [ text "Add"
                        ]
                    ]
                ]
            ]
        , div
            [ class "flex flex-col space-y-4 md:space-y-2 mt-2"
            , class "px-2 border-0 border-l dark:border-bluegray-600"
            ]
            (List.map viewMember2 model.members)
        ]


viewMember2 : IdName -> Html Msg
viewMember2 member =
    div
        [ class "flex flex-row space-x-2 items-center"
        ]
        [ a
            [ class S.deleteLabel
            , href "#"
            , title "Remove this member"
            , onClick (RemoveMember member)
            ]
            [ i [ class "fa fa-trash " ] []
            ]
        , span [ class "ml-2" ]
            [ text member.name
            ]
        ]


viewButtons2 : Model -> Html Msg
viewButtons2 model =
    MB.view
        { start =
            [ MB.SecondaryButton
                { tagger = GoBack
                , label = "Back"
                , icon = Just "fa fa-arrow-left"
                , title = "Back to list"
                }
            ]
        , end =
            [ MB.CustomButton
                { tagger = RequestDelete
                , label = "Delete"
                , icon = Just "fa fa-trash"
                , title = "Delete this folder"
                , inputClass =
                    [ ( S.deleteButton, True )
                    , ( "hidden", model.folder.id == "" )
                    ]
                }
            ]
        , rootClasses = "mb-4"
        }
