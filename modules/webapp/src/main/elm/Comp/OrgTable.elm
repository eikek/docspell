module Comp.OrgTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api.Model.Organization exposing (Organization)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.OrgUse
import Html exposing (..)
import Html.Attributes exposing (..)
import Styles as S
import Util.Address
import Util.Contact


type alias Model =
    { orgs : List Organization
    , selected : Maybe Organization
    }


emptyModel : Model
emptyModel =
    { orgs = []
    , selected = Nothing
    }


type Msg
    = SetOrgs (List Organization)
    | Select Organization
    | Deselect


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetOrgs list ->
            ( { model | orgs = list, selected = Nothing }, Cmd.none )

        Select equip ->
            ( { model | selected = Just equip }, Cmd.none )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none )



--- View2


view2 : Model -> Html Msg
view2 model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left pr-1 md:px-2" ]
                    [ text "Use"
                    ]
                , th [ class "text-left" ] [ text "Name" ]
                , th [ class "text-left hidden md:table-cell" ] [ text "Address" ]
                , th [ class "text-left hidden sm:table-cell" ] [ text "Contact" ]
                ]
            ]
        , tbody []
            (List.map (renderOrgLine2 model) model.orgs)
        ]


renderOrgLine2 : Model -> Organization -> Html Msg
renderOrgLine2 model org =
    tr
        [ classList [ ( "active", model.selected == Just org ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell (Select org)
        , td [ class "text-left pr-1 md:px-2" ]
            [ div [ class "label inline-flex text-sm" ]
                [ Data.OrgUse.fromString org.use
                    |> Maybe.withDefault Data.OrgUse.Correspondent
                    |> Data.OrgUse.label
                    |> text
                ]
            ]
        , td [ class "py-4 sm:py-2 pr-2 md:pr-4" ]
            [ text org.name
            ]
        , td [ class "py-4 sm:py-2 pr-4 hidden md:table-cell" ]
            [ Util.Address.toString org.address |> text
            ]
        , td [ class "py-4 sm:py-2 sm:py-2 pr-2 md:pr-4 hidden sm:table-cell" ]
            [ Util.Contact.toString org.contacts |> text
            ]
        ]
