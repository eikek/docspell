module Comp.OrgForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getOrg
    , isValid
    , update
    , view2
    )

import Api.Model.Organization exposing (Organization)
import Comp.AddressForm
import Comp.Basic as B
import Comp.ContactField
import Comp.FixedDropdown
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.OrgUse exposing (OrgUse)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Styles as S
import Util.Maybe


type alias Model =
    { org : Organization
    , name : String
    , addressModel : Comp.AddressForm.Model
    , contactModel : Comp.ContactField.Model
    , notes : Maybe String
    , shortName : Maybe String
    , use : OrgUse
    , useModel : Comp.FixedDropdown.Model OrgUse
    }


emptyModel : Model
emptyModel =
    { org = Api.Model.Organization.empty
    , name = ""
    , addressModel = Comp.AddressForm.emptyModel
    , contactModel = Comp.ContactField.emptyModel
    , notes = Nothing
    , shortName = Nothing
    , use = Data.OrgUse.Correspondent
    , useModel =
        Comp.FixedDropdown.init Data.OrgUse.all
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
        , shortName = model.shortName
        , use = Data.OrgUse.asString model.use
    }


type Msg
    = SetName String
    | SetOrg Organization
    | AddressMsg Comp.AddressForm.Msg
    | ContactMsg Comp.ContactField.Msg
    | SetNotes String
    | SetShortName String
    | UseDropdownMsg (Comp.FixedDropdown.Msg OrgUse)


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
            ( { m2
                | org = t
                , name = t.name
                , notes = t.notes
                , shortName = t.shortName
                , use =
                    Data.OrgUse.fromString t.use
                        |> Maybe.withDefault Data.OrgUse.Correspondent
              }
            , Cmd.batch [ c1, c2 ]
            )

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
            ( { model | notes = Util.Maybe.fromString str }
            , Cmd.none
            )

        SetShortName str ->
            ( { model | shortName = Util.Maybe.fromString str }
            , Cmd.none
            )

        UseDropdownMsg lm ->
            let
                ( nm, mu ) =
                    Comp.FixedDropdown.update lm model.useModel

                newUse =
                    Maybe.withDefault model.use mu
            in
            ( { model | useModel = nm, use = newUse }, Cmd.none )



--- View2


view2 : Bool -> UiSettings -> Model -> Html Msg
view2 mobile settings model =
    let
        orgUseCfg =
            { display = Data.OrgUse.label
            , icon = \_ -> Nothing
            , style = DS.mainStyle
            }
    in
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
        , div
            [ class "mb-4" ]
            [ label
                [ for "org-short-name"
                , class S.inputLabel
                ]
                [ text "Short Name"
                ]
            , input
                [ type_ "text"
                , onInput SetShortName
                , placeholder "Abbreviation"
                , Maybe.withDefault "" model.shortName
                    |> value
                , name "org-short-name"
                , class S.textInput
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text "Use" ]
            , Html.map UseDropdownMsg
                (Comp.FixedDropdown.viewStyled2 orgUseCfg
                    False
                    (Just model.use)
                    model.useModel
                )
            , span [ class "opacity-50 text-sm" ]
                [ case model.use of
                    Data.OrgUse.Correspondent ->
                        text "Use as correspondent"

                    Data.OrgUse.Disabled ->
                        text "Do not use for suggestions."
                ]
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
