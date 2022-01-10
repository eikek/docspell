{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BookmarkDropdown exposing (Item(..), Model, Msg, getSelected, getSelectedId, init, initWith, update, view)

import Api
import Api.Model.BookmarkedQuery exposing (BookmarkedQuery)
import Api.Model.ShareDetail exposing (ShareDetail)
import Comp.Dropdown exposing (Option)
import Data.Bookmarks exposing (AllBookmarks)
import Data.DropdownStyle
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html)
import Http
import Messages.Comp.BookmarkDropdown exposing (Texts)
import Util.List


type Model
    = Model (Comp.Dropdown.Model Item)


type Msg
    = DropdownMsg (Comp.Dropdown.Msg Item)
    | GetBookmarksResp (Maybe String) (Result Http.Error AllBookmarks)


initCmd : Flags -> Maybe String -> Cmd Msg
initCmd flags selected =
    Api.getBookmarks flags (GetBookmarksResp selected)


type Item
    = BM BookmarkedQuery
    | Share ShareDetail


toItems : AllBookmarks -> List Item
toItems all =
    List.map BM all.bookmarks
        ++ List.map Share all.shares


initWith : AllBookmarks -> Maybe String -> Model
initWith bms selected =
    let
        items =
            toItems bms

        findSel id =
            Util.List.find
                (\b ->
                    case b of
                        BM m ->
                            m.id == id

                        Share s ->
                            s.id == id
                )
                items
    in
    Model <|
        Comp.Dropdown.makeSingleList
            { options = items, selected = Maybe.andThen findSel selected }


init : Flags -> Maybe String -> ( Model, Cmd Msg )
init flags selected =
    ( Model Comp.Dropdown.makeSingle, initCmd flags selected )


getSelected : Model -> Maybe Item
getSelected model =
    case model of
        Model dm ->
            Comp.Dropdown.getSelected dm
                |> List.head


getSelectedId : Model -> Maybe String
getSelectedId model =
    let
        id item =
            case item of
                BM b ->
                    b.id

                Share s ->
                    s.id
    in
    getSelected model |> Maybe.map id



--- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        dmodel =
            case model of
                Model a ->
                    a
    in
    case msg of
        GetBookmarksResp sel (Ok all) ->
            ( initWith all sel, Cmd.none )

        GetBookmarksResp _ (Err err) ->
            ( model, Cmd.none )

        DropdownMsg lm ->
            let
                ( dm, dc ) =
                    Comp.Dropdown.update lm dmodel
            in
            ( Model dm, Cmd.map DropdownMsg dc )



--- View


itemOption : Texts -> Item -> Option
itemOption texts item =
    case item of
        BM b ->
            { text = b.name
            , additional =
                if b.personal then
                    texts.personal

                else
                    texts.collective
            }

        Share s ->
            { text = Maybe.withDefault "-" s.name, additional = texts.share }


itemColor : Item -> String
itemColor item =
    case item of
        BM b ->
            if b.personal then
                "text-cyan-600 dark:text-indigo-300"

            else
                "text-sky-600 dark:text-violet-300"

        Share _ ->
            "text-blue-600 dark:text-purple-300"


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        viewSettings =
            { makeOption = itemOption texts
            , placeholder = texts.placeholder
            , labelColor = \a -> \_ -> itemColor a
            , style = Data.DropdownStyle.mainStyle
            }

        dm =
            case model of
                Model a ->
                    a
    in
    Html.map DropdownMsg
        (Comp.Dropdown.viewSingle2 viewSettings settings dm)
