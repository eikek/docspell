module Comp.SpaceDetail exposing
    ( Model
    , Msg
    , init
    , initEmpty
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.IdName exposing (IdName)
import Api.Model.IdResult exposing (IdResult)
import Api.Model.NewSpace exposing (NewSpace)
import Api.Model.SpaceDetail exposing (SpaceDetail)
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
    , space : SpaceDetail
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
    | NewSpaceResp (Result Http.Error IdResult)
    | ChangeSpaceResp (Result Http.Error BasicResult)
    | ChangeNameResp (Result Http.Error BasicResult)
    | SpaceDetailResp (Result Http.Error SpaceDetail)
    | AddMember
    | RemoveMember IdName
    | RequestDelete
    | DeleteMsg Comp.YesNoDimmer.Msg
    | DeleteResp (Result Http.Error BasicResult)
    | GoBack


init : List User -> SpaceDetail -> Model
init users space =
    { result = Nothing
    , space = space
    , name = Util.Maybe.fromString space.name
    , members = space.members
    , users = users
    , memberDropdown =
        Comp.FixedDropdown.initMap .name
            (makeOptions users space)
    , selectedMember = Nothing
    , loading = False
    , deleteDimmer = Comp.YesNoDimmer.emptyModel
    }


initEmpty : List User -> Model
initEmpty users =
    init users Api.Model.SpaceDetail.empty


makeOptions : List User -> SpaceDetail -> List IdName
makeOptions users space =
    let
        toIdName u =
            IdName u.id u.login

        notMember idn =
            List.member idn (space.owner :: space.members) |> not
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
                            if model.space.id == "" then
                                Api.createNewSpace flags (NewSpace name) NewSpaceResp

                            else
                                Api.changeSpaceName flags
                                    model.space.id
                                    (NewSpace name)
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

        NewSpaceResp (Ok ir) ->
            if ir.success then
                ( model, Api.getSpaceDetail flags ir.id SpaceDetailResp, False )

            else
                ( { model
                    | loading = False
                    , result = Just (BasicResult ir.success ir.message)
                  }
                , Cmd.none
                , False
                )

        NewSpaceResp (Err err) ->
            ( { model
                | loading = False
                , result = Just (BasicResult False (Util.Http.errorToString err))
              }
            , Cmd.none
            , False
            )

        ChangeSpaceResp (Ok r) ->
            if r.success then
                ( model
                , Api.getSpaceDetail flags model.space.id SpaceDetailResp
                , False
                )

            else
                ( { model | loading = False, result = Just r }
                , Cmd.none
                , False
                )

        ChangeSpaceResp (Err err) ->
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

        SpaceDetailResp (Ok sd) ->
            ( init model.users sd, Cmd.none, False )

        SpaceDetailResp (Err err) ->
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
                    , Api.addMember flags model.space.id mem.id ChangeSpaceResp
                    , False
                    )

                Nothing ->
                    ( model, Cmd.none, False )

        RemoveMember idname ->
            ( { model | loading = True }
            , Api.removeMember flags model.space.id idname.id ChangeSpaceResp
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
                        Api.deleteSpace flags model.space.id DeleteResp

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
                |> Maybe.map ((==) model.space.owner.name)
                |> Maybe.withDefault False
    in
    div []
        ([ Html.map DeleteMsg (Comp.YesNoDimmer.view model.deleteDimmer)
         , if model.space.id == "" then
            div []
                [ text "Create a new space. You are automatically set as owner of this new space."
                ]

           else
            div []
                [ text "Modify this space by changing the name or add/remove members."
                ]
         , if model.space.id /= "" && not isOwner then
            div [ class "ui info message" ]
                [ text "You are not the owner of this space and therefore are not allowed to edit it."
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
            [ text model.space.owner.name
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
viewButtons _ =
    [ div [ class "ui divider" ] []
    , button
        [ class "ui button"
        , onClick GoBack
        ]
        [ text "Back"
        ]
    , button
        [ class "ui red button"
        , onClick RequestDelete
        ]
        [ text "Delete"
        ]
    ]


viewMembers : Model -> List (Html Msg)
viewMembers model =
    if model.space.id == "" then
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
