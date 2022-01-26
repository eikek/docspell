{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


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
    , viewWith
    )

import Api.Model.BookmarkedQuery exposing (BookmarkedQuery)
import Api.Model.ShareDetail exposing (ShareDetail)
import Data.Bookmarks exposing (AllBookmarks)
import Data.Icons as Icons
import Html exposing (Html, a, div, i, label, span, text)
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
    model.all == Data.Bookmarks.empty


type alias Selection =
    { bookmarks : Set String
    , shares : Set String
    }


emptySelection : Selection
emptySelection =
    { bookmarks = Set.empty, shares = Set.empty }


isEmptySelection : Selection -> Bool
isEmptySelection sel =
    sel == emptySelection


type Kind
    = Bookmark
    | Share


type Msg
    = Toggle Kind String


getQueries : Model -> Selection -> List BookmarkedQuery
getQueries model sel =
    let
        member set bm =
            Set.member bm.id set

        filterBookmarks f bms =
            List.filter f bms |> List.map identity
    in
    List.concat
        [ filterBookmarks (member sel.bookmarks) model.all.bookmarks
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
        Toggle kind id ->
            case kind of
                Bookmark ->
                    ( model, { current | bookmarks = toggle id current.bookmarks } )

                Share ->
                    ( model, { current | shares = toggle id current.shares } )



--- View


type alias ViewSettings =
    { showUser : Bool
    , showCollective : Bool
    , showShares : Bool
    }


viewWith : ViewSettings -> Texts -> Model -> Selection -> Html Msg
viewWith cfg texts model selection =
    let
        ( user, coll ) =
            List.partition .personal model.all.bookmarks
    in
    div [ class "flex flex-col" ]
        [ userBookmarks cfg.showUser texts user selection
        , collBookmarks cfg.showCollective texts coll selection
        , shares cfg.showShares texts model selection
        ]


view : Texts -> Model -> Selection -> Html Msg
view =
    viewWith { showUser = True, showCollective = True, showShares = True }


titleDiv : String -> Html msg
titleDiv label =
    div [ class "text-sm opacity-75 py-0.5 italic" ]
        [ text label

        --, text " ──"
        ]


userBookmarks : Bool -> Texts -> List BookmarkedQuery -> Selection -> Html Msg
userBookmarks visible texts model sel =
    div
        [ class "mb-2"
        , classList [ ( "hidden", model == [] || not visible ) ]
        ]
        [ titleDiv texts.userLabel
        , div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (List.map (mkItem "fa fa-bookmark" sel Bookmark) model)
        ]


collBookmarks : Bool -> Texts -> List BookmarkedQuery -> Selection -> Html Msg
collBookmarks visible texts model sel =
    div
        [ class "mb-2"
        , classList [ ( "hidden", [] == model || not visible ) ]
        ]
        [ titleDiv texts.collectiveLabel
        , div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (List.map (mkItem "fa fa-bookmark font-light" sel Bookmark) model)
        ]


shares : Bool -> Texts -> Model -> Selection -> Html Msg
shares visible texts model sel =
    let
        bms =
            List.map shareToBookmark model.all.shares
    in
    div
        [ class ""
        , classList [ ( "hidden", List.isEmpty bms || not visible ) ]
        ]
        [ titleDiv texts.shareLabel
        , div [ class "flex flex-col space-y-2 md:space-y-1" ]
            (List.map (mkItem Icons.share sel Share) bms)
        ]


mkItem : String -> Selection -> Kind -> BookmarkedQuery -> Html Msg
mkItem icon sel kind bm =
    a
        [ class "flex flex-row items-center rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-slate-600"
        , href "#"
        , onClick (Toggle kind bm.id)
        ]
        [ if isSelected sel kind bm.id then
            i [ class "fa fa-check" ] []

          else
            i [ class icon ] []
        , span [ class "ml-2" ] [ text bm.name ]
        ]


isSelected : Selection -> Kind -> String -> Bool
isSelected sel kind id =
    Set.member id <|
        case kind of
            Bookmark ->
                sel.bookmarks

            Share ->
                sel.shares


shareToBookmark : ShareDetail -> BookmarkedQuery
shareToBookmark share =
    BookmarkedQuery share.id (Maybe.withDefault "-" share.name) share.name share.query False 0
