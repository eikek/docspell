module Comp.BookmarkChooser exposing
    ( Model
    , Msg
    , Selection
    , emptySelection
    , getQueries
    , init
    , isEmpty
    , isEmptySelection
    , update
    , view
    )

import Api.Model.ShareDetail exposing (ShareDetail)
import Data.BookmarkedQuery exposing (AllBookmarks, BookmarkedQuery)
import Data.Icons as Icons
import Html exposing (Html, a, div, i, span, text)
import Html.Attributes exposing (class, classList, href)
import Html.Events exposing (onClick)
import Messages.Comp.BookmarkChooser exposing (Texts)
import Set exposing (Set)


type alias Model =
    { all : AllBookmarks
    }


init : AllBookmarks -> Model
init all =
    { all = all
    }


isEmpty : Model -> Bool
isEmpty model =
    model.all == Data.BookmarkedQuery.allBookmarksEmpty


type alias Selection =
    { user : Set String
    , collective : Set String
    , shares : Set String
    }


emptySelection : Selection
emptySelection =
    { user = Set.empty, collective = Set.empty, shares = Set.empty }


isEmptySelection : Selection -> Bool
isEmptySelection sel =
    sel == emptySelection


type Kind
    = User
    | Collective
    | Share


type Msg
    = Toggle Kind String


getQueries : Model -> Selection -> List BookmarkedQuery
getQueries model sel =
    let
        member set bm =
            Set.member bm.name set

        filterBookmarks f bms =
            Data.BookmarkedQuery.filter f bms |> Data.BookmarkedQuery.map identity
    in
    List.concat
        [ filterBookmarks (member sel.user) model.all.user
        , filterBookmarks (member sel.collective) model.all.collective
        , List.map shareToBookmark model.all.shares
            |> List.filter (member sel.shares)
        ]



--- Update


update : Msg -> Model -> Selection -> ( Model, Selection )
update msg model current =
    let
        toggle name set =
            if Set.member name set then
                Set.remove name set

            else
                Set.insert name set
    in
    case msg of
        Toggle kind name ->
            case kind of
                User ->
                    ( model, { current | user = toggle name current.user } )

                Collective ->
                    ( model, { current | collective = toggle name current.collective } )

                Share ->
                    ( model, { current | shares = toggle name current.shares } )



--- View


view : Texts -> Model -> Selection -> Html Msg
view texts model selection =
    div [ class "flex flex-col" ]
        [ userBookmarks texts model selection
        , collBookmarks texts model selection
        , shares texts model selection
        ]


userBookmarks : Texts -> Model -> Selection -> Html Msg
userBookmarks texts model sel =
    div
        [ class "mb-2"
        , classList [ ( "hidden", Data.BookmarkedQuery.emptyBookmarks == model.all.user ) ]
        ]
        [ div [ class " text-sm font-semibold py-0.5 " ]
            [ text texts.userLabel
            ]
        , div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (Data.BookmarkedQuery.map (mkItem "fa fa-bookmark" sel User) model.all.user)
        ]


collBookmarks : Texts -> Model -> Selection -> Html Msg
collBookmarks texts model sel =
    div
        [ class "mb-2"
        , classList [ ( "hidden", Data.BookmarkedQuery.emptyBookmarks == model.all.collective ) ]
        ]
        [ div [ class " text-sm font-semibold py-0.5 " ]
            [ text texts.collectiveLabel
            ]
        , div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (Data.BookmarkedQuery.map (mkItem "fa fa-bookmark font-light" sel Collective) model.all.collective)
        ]


shares : Texts -> Model -> Selection -> Html Msg
shares texts model sel =
    let
        bms =
            List.map shareToBookmark model.all.shares
    in
    div
        [ class ""
        , classList [ ( "hidden", List.isEmpty bms ) ]
        ]
        [ div [ class " text-sm font-semibold py-0.5 " ]
            [ text texts.shareLabel
            ]
        , div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (List.map (mkItem Icons.share sel Share) bms)
        ]


mkItem : String -> Selection -> Kind -> BookmarkedQuery -> Html Msg
mkItem icon sel kind bm =
    a
        [ class "flex flex-row items-center rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-slate-600"
        , href "#"
        , onClick (Toggle kind bm.name)
        ]
        [ if isSelected sel kind bm.name then
            i [ class "fa fa-check" ] []

          else
            i [ class icon ] []
        , span [ class "ml-2" ] [ text bm.name ]
        ]


isSelected : Selection -> Kind -> String -> Bool
isSelected sel kind name =
    Set.member name <|
        case kind of
            User ->
                sel.user

            Collective ->
                sel.collective

            Share ->
                sel.shares


shareToBookmark : ShareDetail -> BookmarkedQuery
shareToBookmark share =
    BookmarkedQuery (Maybe.withDefault "-" share.name) share.query
