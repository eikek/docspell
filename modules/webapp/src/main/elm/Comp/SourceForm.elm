module Comp.SourceForm exposing
    ( Model
    , Msg(..)
    , getSource
    , init
    , isValid
    , update
    , view
    )

import Api
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.IdName exposing (IdName)
import Api.Model.Source exposing (Source)
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.FixedDropdown
import Data.Flags exposing (Flags)
import Data.Priority exposing (Priority)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput)
import Http
import Markdown
import QRCode
import Util.Folder exposing (mkFolderOption)


type alias Model =
    { source : Source
    , abbrev : String
    , description : Maybe String
    , priorityModel : Comp.FixedDropdown.Model Priority
    , priority : Priority
    , enabled : Bool
    , folderModel : Comp.Dropdown.Model IdName
    , allFolders : List FolderItem
    , folderId : Maybe String
    }


emptyModel : Model
emptyModel =
    { source = Api.Model.Source.empty
    , abbrev = ""
    , description = Nothing
    , priorityModel =
        Comp.FixedDropdown.initMap
            Data.Priority.toName
            Data.Priority.all
    , priority = Data.Priority.Low
    , enabled = False
    , folderModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , allFolders = []
    , folderId = Nothing
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel
    , Api.getFolders flags "" False GetFolderResp
    )


isValid : Model -> Bool
isValid model =
    model.abbrev /= ""


getSource : Model -> Source
getSource model =
    let
        s =
            model.source
    in
    { s
        | abbrev = model.abbrev
        , description = model.description
        , enabled = model.enabled
        , priority = Data.Priority.toName model.priority
        , folder = model.folderId
    }


type Msg
    = SetAbbrev String
    | SetSource Source
    | SetDescr String
    | ToggleEnabled
    | PrioDropdownMsg (Comp.FixedDropdown.Msg Priority)
    | GetFolderResp (Result Http.Error FolderList)
    | FolderDropdownMsg (Comp.Dropdown.Msg IdName)



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetSource t ->
            let
                post =
                    model.source

                np =
                    { post
                        | id = t.id
                        , abbrev = t.abbrev
                        , description = t.description
                        , priority = t.priority
                        , enabled = t.enabled
                        , folder = t.folder
                    }

                newModel =
                    { model
                        | source = np
                        , abbrev = t.abbrev
                        , description = t.description
                        , priority =
                            Data.Priority.fromString t.priority
                                |> Maybe.withDefault Data.Priority.Low
                        , enabled = t.enabled
                        , folderId = t.folder
                    }

                mkIdName id =
                    List.filterMap
                        (\f ->
                            if f.id == id then
                                Just (IdName id f.name)

                            else
                                Nothing
                        )
                        model.allFolders

                sel =
                    case Maybe.map mkIdName t.folder of
                        Just idref ->
                            idref

                        Nothing ->
                            []
            in
            update flags (FolderDropdownMsg (Comp.Dropdown.SetSelection sel)) newModel

        ToggleEnabled ->
            ( { model | enabled = not model.enabled }, Cmd.none )

        SetAbbrev n ->
            ( { model | abbrev = n }, Cmd.none )

        SetDescr d ->
            ( { model
                | description =
                    if d /= "" then
                        Just d

                    else
                        Nothing
              }
            , Cmd.none
            )

        PrioDropdownMsg m ->
            let
                ( m2, p2 ) =
                    Comp.FixedDropdown.update m model.priorityModel
            in
            ( { model
                | priorityModel = m2
                , priority = Maybe.withDefault model.priority p2
              }
            , Cmd.none
            )

        GetFolderResp (Ok fs) ->
            let
                model_ =
                    { model
                        | allFolders = fs.items
                        , folderModel =
                            Comp.Dropdown.setMkOption
                                (mkFolderOption flags fs.items)
                                model.folderModel
                    }

                mkIdName fitem =
                    IdName fitem.id fitem.name

                opts =
                    fs.items
                        |> List.map mkIdName
                        |> Comp.Dropdown.SetOptions
            in
            update flags (FolderDropdownMsg opts) model_

        GetFolderResp (Err _) ->
            ( model, Cmd.none )

        FolderDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.folderModel

                newModel =
                    { model | folderModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                model_ =
                    if isDropdownChangeMsg m then
                        { newModel | folderId = Maybe.map .id idref }

                    else
                        newModel
            in
            ( model_, Cmd.map FolderDropdownMsg c2 )



--- View


qrCodeView : String -> Html msg
qrCodeView message =
    QRCode.encode message
        |> Result.map QRCode.toSvg
        |> Result.withDefault
            (Html.text "Error generating QR-Code")


view : Flags -> UiSettings -> Model -> Html Msg
view flags settings model =
    let
        priorityItem =
            Comp.FixedDropdown.Item
                model.priority
                (Data.Priority.toName model.priority)
    in
    div [ class "ui warning form" ]
        [ div
            [ classList
                [ ( "field", True )
                , ( "error", not (isValid model) )
                ]
            ]
            [ label [] [ text "Abbrev*" ]
            , input
                [ type_ "text"
                , onInput SetAbbrev
                , placeholder "Abbrev"
                , value model.abbrev
                ]
                []
            ]
        , div [ class "field" ]
            [ label [] [ text "Description" ]
            , textarea
                [ onInput SetDescr
                , model.description |> Maybe.withDefault "" |> value
                ]
                []
            ]
        , div [ class "inline field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleEnabled)
                    , checked model.enabled
                    ]
                    []
                , label [] [ text "Enabled" ]
                ]
            ]
        , div [ class "field" ]
            [ label [] [ text "Priority" ]
            , Html.map PrioDropdownMsg
                (Comp.FixedDropdown.view
                    (Just priorityItem)
                    model.priorityModel
                )
            ]
        , div [ class "field" ]
            [ label []
                [ text "Folder"
                ]
            , Html.map FolderDropdownMsg (Comp.Dropdown.view settings model.folderModel)
            , div
                [ classList
                    [ ( "ui warning message", True )
                    , ( "hidden", isFolderMember model )
                    ]
                ]
                [ Markdown.toHtml [] """
You are **not a member** of this folder. Items created through this
link will be **hidden** from any search results. Use a folder where
you are a member of to make items visible. This message will
disappear then.
                      """
                ]
            ]
        , urlInfoMessage flags model
        ]


urlInfoMessage : Flags -> Model -> Html Msg
urlInfoMessage flags model =
    let
        appUrl =
            flags.config.baseUrl ++ "/app/upload/" ++ model.source.id

        apiUrl =
            flags.config.baseUrl ++ "/api/v1/open/upload/item/" ++ model.source.id
    in
    div
        [ classList
            [ ( "ui info icon message", True )
            , ( "hidden", not model.enabled || model.source.id == "" )
            ]
        ]
        [ div [ class "content" ]
            [ h3 [ class "ui dividingheader" ]
                [ i [ class "info icon" ] []
                , text "Public Uploads"
                ]
            , p []
                [ text "This source defines URLs that can be used by anyone to send files to "
                , text "you. There is a web page that you can share or the API url can be used "
                , text "with other clients."
                ]
            , dl [ class "ui list" ]
                [ dt [] [ text "Public Upload Page" ]
                , dd []
                    [ a [ href appUrl, target "_blank" ] [ code [] [ text appUrl ] ]
                    ]
                ]
            , dl [ class "ui list" ]
                [ dt [] [ text "Public API Upload URL" ]
                , dd []
                    [ p []
                        [ code []
                            [ text apiUrl
                            ]
                        ]
                    , p [ class "qr-code" ]
                        [ qrCodeView apiUrl
                        ]
                    ]
                ]
            ]
        ]


isFolderMember : Model -> Bool
isFolderMember model =
    let
        selected =
            Comp.Dropdown.getSelected model.folderModel
                |> List.head
                |> Maybe.map .id
    in
    Util.Folder.isFolderMember model.allFolders selected
