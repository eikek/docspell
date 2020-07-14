module Comp.FolderDetail exposing
    ( Model
    , Msg
    , init
    , initEmpty
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.FolderDetail exposing (FolderDetail)
import Api.Model.IdName exposing (IdName)
import Api.Model.IdResult exposing (IdResult)
import Api.Model.NewFolder exposing (NewFolder)
import Api.Model.User exposing (User)
import Api.Model.UserList exposing (UserList)
import Comp.FixedDropdown
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
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
