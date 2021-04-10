module Comp.FolderDetail exposing
    ( Model
    , Msg
    , init
    , initEmpty
    , update
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
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Messages.Comp.FolderDetail exposing (Texts)
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
        Comp.FixedDropdown.init (makeOptions users folder)
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



--- View2


view2 : Texts -> Flags -> Model -> Html Msg
view2 texts flags model =
    let
        isOwner =
            Maybe.map .user flags.account
                |> Maybe.map ((==) model.folder.owner.name)
                |> Maybe.withDefault False

        dimmerSettings : Comp.YesNoDimmer.Settings
        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeleteThisFolder
                texts.basics.yes
                texts.basics.no
    in
    div [ class "flex flex-col md:relative" ]
        (viewButtons2 texts model
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
                    [ text texts.autoOwnerInfo
                    ]
               , div
                    [ class "py-2 text-lg opacity-75"
                    , classList [ ( "hidden", model.folder.id == "" ) ]
                    ]
                    [ text texts.modifyInfo
                    ]
               , div
                    [ class S.message
                    , classList [ ( "hidden", model.folder.id == "" || isOwner ) ]
                    ]
                    [ text texts.notOwnerInfo
                    ]
               , div [ class "mb-4 flex flex-col" ]
                    [ label
                        [ class S.inputLabel
                        , for "folder-name"
                        ]
                        [ text texts.basics.name
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
                                [ text texts.basics.submit
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
            ++ viewMembers2 texts model
        )


viewMembers2 : Texts -> Model -> List (Html Msg)
viewMembers2 texts model =
    let
        folderCfg =
            { display = .name
            , icon = \_ -> Nothing
            , style = DS.mainStyle
            }
    in
    if model.folder.id == "" then
        []

    else
        [ div
            [ class S.header3
            , class "mt-4"
            ]
            [ text texts.members
            ]
        , div [ class "flex flex-col space-y-2" ]
            [ div [ class "flex flex-row space-x-2" ]
                [ div [ class "flex-grow" ]
                    [ Html.map MemberDropdownMsg
                        (Comp.FixedDropdown.viewStyled2
                            folderCfg
                            False
                            model.selectedMember
                            model.memberDropdown
                        )
                    ]
                , a
                    [ title texts.addMember
                    , onClick AddMember
                    , class S.primaryButton
                    , href "#"
                    , class "flex-none"
                    ]
                    [ i [ class "fa fa-plus" ] []
                    , span [ class "ml-2 hidden sm:inline" ]
                        [ text texts.add
                        ]
                    ]
                ]
            ]
        , div
            [ class "flex flex-col space-y-4 md:space-y-2 mt-2"
            , class "px-2 border-0 border-l dark:border-bluegray-600"
            ]
            (List.map (viewMember2 texts) model.members)
        ]


viewMember2 : Texts -> IdName -> Html Msg
viewMember2 texts member =
    div
        [ class "flex flex-row space-x-2 items-center"
        ]
        [ a
            [ class S.deleteLabel
            , href "#"
            , title texts.removeMember
            , onClick (RemoveMember member)
            ]
            [ i [ class "fa fa-trash " ] []
            ]
        , span [ class "ml-2" ]
            [ text member.name
            ]
        ]


viewButtons2 : Texts -> Model -> Html Msg
viewButtons2 texts model =
    MB.view
        { start =
            [ MB.SecondaryButton
                { tagger = GoBack
                , label = texts.basics.cancel
                , icon = Just "fa fa-arrow-left"
                , title = texts.basics.backToList
                }
            ]
        , end =
            [ MB.CustomButton
                { tagger = RequestDelete
                , label = texts.basics.delete
                , icon = Just "fa fa-trash"
                , title = texts.deleteThisFolder
                , inputClass =
                    [ ( S.deleteButton, True )
                    , ( "hidden", model.folder.id == "" )
                    ]
                }
            ]
        , rootClasses = "mb-4"
        }
