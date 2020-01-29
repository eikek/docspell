module Comp.SourceForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getSource
    , isValid
    , update
    , view
    )

import Api.Model.Source exposing (Source)
import Comp.Dropdown
import Data.Flags exposing (Flags)
import Data.Priority exposing (Priority)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput)


type alias Model =
    { source : Source
    , abbrev : String
    , description : Maybe String
    , priority : Comp.Dropdown.Model Priority
    , enabled : Bool
    }


emptyModel : Model
emptyModel =
    { source = Api.Model.Source.empty
    , abbrev = ""
    , description = Nothing
    , priority =
        Comp.Dropdown.makeSingleList
            { makeOption = \p -> { text = Data.Priority.toName p, value = Data.Priority.toName p }
            , placeholder = ""
            , options = Data.Priority.all
            , selected = Nothing
            }
    , enabled = False
    }


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
        , priority =
            Comp.Dropdown.getSelected model.priority
                |> List.head
                |> Maybe.map Data.Priority.toName
                |> Maybe.withDefault s.priority
    }


type Msg
    = SetAbbrev String
    | SetSource Source
    | SetDescr String
    | ToggleEnabled
    | PrioDropdownMsg (Comp.Dropdown.Msg Priority)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
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
                    }
            in
            ( { model
                | source = np
                , abbrev = t.abbrev
                , description = t.description
                , priority =
                    Comp.Dropdown.makeSingleList
                        { makeOption = \p -> { text = Data.Priority.toName p, value = Data.Priority.toName p }
                        , placeholder = ""
                        , options = Data.Priority.all
                        , selected = Data.Priority.fromString t.priority
                        }
                , enabled = t.enabled
              }
            , Cmd.none
            )

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
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.priority
            in
            ( { model | priority = m2 }, Cmd.map PrioDropdownMsg c2 )


view : Flags -> Model -> Html Msg
view flags model =
    div [ class "ui form" ]
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
            , Html.map PrioDropdownMsg (Comp.Dropdown.view model.priority)
            ]
        , urlInfoMessage flags model
        ]


urlInfoMessage : Flags -> Model -> Html Msg
urlInfoMessage flags model =
    div
        [ classList
            [ ( "ui info icon message", True )
            , ( "hidden", not model.enabled || model.source.id == "" )
            ]
        ]
        [ i [ class "info icon" ] []
        , div [ class "content" ]
            [ div [ class "header" ]
                [ text "Public Uploads"
                ]
            , p []
                [ text "This source defines URLs that can be used by anyone to send files to "
                , text "you. There is a web page that you can share or the API url can be used "
                , text "with other clients."
                ]
            , dl [ class "ui list" ]
                [ dt [] [ text "Public Upload Page" ]
                , dd []
                    [ let
                        url =
                            flags.config.baseUrl ++ "/app/upload/" ++ model.source.id
                      in
                      a [ href url, target "_blank" ] [ code [] [ text url ] ]
                    ]
                , dt [] [ text "Public API Upload URL" ]
                , dd []
                    [ code [] [ text (flags.config.baseUrl ++ "/api/v1/open/upload/item/" ++ model.source.id) ]
                    ]
                ]
            ]
        ]
