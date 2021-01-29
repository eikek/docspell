module Comp.OrgForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getOrg
    , isValid
    , update
    , view
    , view1
    , view2
    )

import Api.Model.Organization exposing (Organization)
import Comp.AddressForm
import Comp.Basic as B
import Comp.ContactField
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Styles as S


type alias Model =
    { org : Organization
    , name : String
    , addressModel : Comp.AddressForm.Model
    , contactModel : Comp.ContactField.Model
    , notes : Maybe String
    }


emptyModel : Model
emptyModel =
    { org = Api.Model.Organization.empty
    , name = ""
    , addressModel = Comp.AddressForm.emptyModel
    , contactModel = Comp.ContactField.emptyModel
    , notes = Nothing
    }


isValid : Model -> Bool
isValid model =
    model.name /= ""


getOrg : Model -> Organization
getOrg model =
    let
        o =
            model.org
    in
    { o
        | name = model.name
        , address = Comp.AddressForm.getAddress model.addressModel
        , contacts = Comp.ContactField.getContacts model.contactModel
        , notes = model.notes
    }


type Msg
    = SetName String
    | SetOrg Organization
    | AddressMsg Comp.AddressForm.Msg
    | ContactMsg Comp.ContactField.Msg
    | SetNotes String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetOrg t ->
            let
                ( m1, c1 ) =
                    update flags (AddressMsg (Comp.AddressForm.SetAddress t.address)) model

                ( m2, c2 ) =
                    update flags (ContactMsg (Comp.ContactField.SetItems t.contacts)) m1
            in
            ( { m2 | org = t, name = t.name, notes = t.notes }, Cmd.batch [ c1, c2 ] )

        AddressMsg am ->
            let
                ( m1, c1 ) =
                    Comp.AddressForm.update am model.addressModel
            in
            ( { model | addressModel = m1 }, Cmd.map AddressMsg c1 )

        ContactMsg m ->
            let
                ( m1, c1 ) =
                    Comp.ContactField.update m model.contactModel
            in
            ( { model | contactModel = m1 }, Cmd.map ContactMsg c1 )

        SetName n ->
            ( { model | name = n }, Cmd.none )

        SetNotes str ->
            ( { model
                | notes =
                    if str == "" then
                        Nothing

                    else
                        Just str
              }
            , Cmd.none
            )


view : UiSettings -> Model -> Html Msg
view settings model =
    view1 settings False model


view1 : UiSettings -> Bool -> Model -> Html Msg
view1 settings compact model =
    div [ class "ui form" ]
        [ div
            [ classList
                [ ( "field", True )
                , ( "error", not (isValid model) )
                ]
            ]
            [ label [] [ text "Name*" ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder "Name"
                , value model.name
                ]
                []
            ]
        , h3 [ class "ui dividing header" ]
            [ text "Address"
            ]
        , Html.map AddressMsg (Comp.AddressForm.view settings model.addressModel)
        , h3 [ class "ui dividing header" ]
            [ text "Contacts"
            ]
        , Html.map ContactMsg (Comp.ContactField.view1 settings compact model.contactModel)
        , h3 [ class "ui dividing header" ]
            [ text "Notes"
            ]
        , div [ class "field" ]
            [ textarea
                [ onInput SetNotes
                , Maybe.withDefault "" model.notes |> value
                ]
                []
            ]
        ]



--- View2


view2 : Bool -> UiSettings -> Model -> Html Msg
view2 mobile settings model =
    div [ class "flex flex-col" ]
        [ div
            [ class "mb-4" ]
            [ label
                [ for "orgname"
                , class S.inputLabel
                ]
                [ text "Name"
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder "Name"
                , value model.name
                , name "orgname"
                , class S.textInput
                , classList
                    [ ( S.inputErrorBorder, not (isValid model) )
                    ]
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ h3 [ class S.header3 ]
                [ text "Address"
                ]
            , Html.map AddressMsg
                (Comp.AddressForm.view2 settings model.addressModel)
            ]
        , div [ class "mb-4" ]
            [ h3 [ class S.header3 ]
                [ text "Contacts"
                ]
            , Html.map ContactMsg
                (Comp.ContactField.view2 mobile settings model.contactModel)
            ]
        , div [ class "mb-4" ]
            [ h3 [ class S.header3 ]
                [ text "Notes"
                ]
            , div [ class "" ]
                [ textarea
                    [ onInput SetNotes
                    , Maybe.withDefault "" model.notes |> value
                    , class S.textAreaInput
                    ]
                    []
                ]
            ]
        ]
