module Comp.ItemMail exposing
    ( FormAction(..)
    , Model
    , Msg
    , clear
    , emptyModel
    , init
    , update
    , view
    )

import Api
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.SimpleMail exposing (SimpleMail)
import Comp.Dropdown
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Util.Http


type alias Model =
    { connectionModel : Comp.Dropdown.Model String
    , subject : String
    , receiver : String
    , body : String
    , attachAll : Bool
    , formError : Maybe String
    }


type Msg
    = SetSubject String
    | SetReceiver String
    | SetBody String
    | ConnMsg (Comp.Dropdown.Msg String)
    | ConnResp (Result Http.Error EmailSettingsList)
    | ToggleAttachAll
    | Cancel
    | Send


type alias MailInfo =
    { conn : String
    , mail : SimpleMail
    }


type FormAction
    = FormSend MailInfo
    | FormCancel
    | FormNone


emptyModel : Model
emptyModel =
    { connectionModel =
        Comp.Dropdown.makeSingle
            { makeOption = \a -> { value = a, text = a }
            , placeholder = "Select connection..."
            }
    , subject = ""
    , receiver = ""
    , body = ""
    , attachAll = True
    , formError = Nothing
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel, Api.getMailSettings flags "" ConnResp )


clear : Model -> Model
clear model =
    { model
        | subject = ""
        , receiver = ""
        , body = ""
    }


update : Msg -> Model -> ( Model, FormAction )
update msg model =
    case msg of
        SetSubject str ->
            ( { model | subject = str }, FormNone )

        SetReceiver str ->
            ( { model | receiver = str }, FormNone )

        SetBody str ->
            ( { model | body = str }, FormNone )

        ConnMsg m ->
            let
                ( cm, _ ) =
                    --TODO dropdown doesn't use cmd!!
                    Comp.Dropdown.update m model.connectionModel
            in
            ( { model | connectionModel = cm }, FormNone )

        ToggleAttachAll ->
            ( { model | attachAll = not model.attachAll }, FormNone )

        ConnResp (Ok list) ->
            let
                names =
                    List.map .name list.items

                cm =
                    Comp.Dropdown.makeSingleList
                        { makeOption = \a -> { value = a, text = a }
                        , placeholder = "Select Connection..."
                        , options = names
                        , selected = List.head names
                        }
            in
            ( { model
                | connectionModel = cm
                , formError =
                    if names == [] then
                        Just "No E-Mail connections configured. Goto user settings to add one."

                    else
                        Nothing
              }
            , FormNone
            )

        ConnResp (Err err) ->
            ( { model | formError = Just (Util.Http.errorToString err) }, FormNone )

        Cancel ->
            ( model, FormCancel )

        Send ->
            case ( model.formError, Comp.Dropdown.getSelected model.connectionModel ) of
                ( Nothing, conn :: [] ) ->
                    let
                        rec =
                            String.split "," model.receiver

                        sm =
                            SimpleMail rec model.subject model.body model.attachAll []
                    in
                    ( model, FormSend { conn = conn, mail = sm } )

                _ ->
                    ( model, FormNone )


isValid : Model -> Bool
isValid model =
    model.receiver
        /= ""
        && model.subject
        /= ""
        && model.body
        /= ""
        && model.formError
        == Nothing


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "ui form", True )
            , ( "error", model.formError /= Nothing )
            ]
        ]
        [ div [ class "field" ]
            [ label [] [ text "Send via" ]
            , Html.map ConnMsg (Comp.Dropdown.view model.connectionModel)
            ]
        , div [ class "ui error message" ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , div [ class "field" ]
            [ label []
                [ text "Receiver(s)"
                , span [ class "muted" ]
                    [ text "Separate multiple recipients by comma" ]
                ]
            , input
                [ type_ "text"
                , onInput SetReceiver
                , value model.receiver
                ]
                []
            ]
        , div [ class "field" ]
            [ label [] [ text "Subject" ]
            , input
                [ type_ "text"
                , onInput SetSubject
                , value model.subject
                ]
                []
            ]
        , div [ class "field" ]
            [ label [] [ text "Body" ]
            , textarea [ onInput SetBody ]
                [ text model.body ]
            ]
        , div [ class "inline field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , checked model.attachAll
                    , onCheck (\_ -> ToggleAttachAll)
                    ]
                    []
                , label [] [ text "Include all item attachments" ]
                ]
            ]
        , button
            [ classList
                [ ( "ui primary button", True )
                , ( "disabled", not (isValid model) )
                ]
            , onClick Send
            ]
            [ text "Send"
            ]
        , button
            [ class "ui secondary button"
            , onClick Cancel
            ]
            [ text "Cancel"
            ]
        ]
