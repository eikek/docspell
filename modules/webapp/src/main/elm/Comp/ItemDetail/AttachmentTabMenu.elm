module Comp.ItemDetail.AttachmentTabMenu exposing (view)

import Api.Model.Attachment exposing (Attachment)
import Comp.ItemDetail.Model exposing (Model, Msg(..))
import Comp.SentMails
import Html exposing (Html, a, div, i, text)
import Html.Attributes exposing (class, classList, href, title)
import Html.Events exposing (onClick)
import Html5.DragDrop as DD
import Util.List
import Util.Maybe
import Util.String


view : Model -> Html Msg
view model =
    div [ class "ui top attached tabular menu" ]
        (activeAttach model
            :: selectMenu model
            ++ sentMailsTab model
        )


activeAttach : Model -> Html Msg
activeAttach model =
    let
        attachM =
            Util.Maybe.or
                [ Util.List.get model.item.attachments model.visibleAttach
                    |> Maybe.map (Tuple.pair model.visibleAttach)
                , List.head model.item.attachments
                    |> Maybe.map (Tuple.pair 0)
                ]

        visible =
            not model.sentMailsOpen
    in
    case attachM of
        Just ( pos, attach ) ->
            a
                ([ classList
                    [ ( "active", visible )
                    , ( "item", True )
                    ]
                 , title (Maybe.withDefault "No Name" attach.name)
                 , href "#"
                 ]
                    ++ (if visible then
                            []

                        else
                            [ onClick (SetActiveAttachment pos) ]
                       )
                )
                [ Maybe.map (Util.String.ellipsis 30) attach.name
                    |> Maybe.withDefault "No Name"
                    |> text
                , a
                    [ classList
                        [ ( "right-tab-icon-link", True )
                        , ( "invisible hidden", not visible )
                        ]
                    , href "#"
                    , onClick (EditAttachNameStart attach.id)
                    ]
                    [ i [ class "grey edit link icon" ] []
                    ]
                ]

        Nothing ->
            div [] []


selectMenu : Model -> List (Html Msg)
selectMenu model =
    case model.item.attachments of
        [] ->
            []

        [ _ ] ->
            []

        _ ->
            [ a
                [ class "ui dropdown item"
                , href "#"
                , onClick ToggleAttachMenu
                ]
                [ i
                    [ classList
                        [ ( "large ellipsis icon", True )
                        , ( "horizontal", not model.attachMenuOpen )
                        , ( "vertical", model.attachMenuOpen )
                        ]
                    ]
                    []
                , div
                    [ classList
                        [ ( "menu transition", True )
                        , ( "visible", model.attachMenuOpen )
                        , ( "hidden", not model.attachMenuOpen )
                        ]
                    ]
                    (List.indexedMap (menuItem model) model.item.attachments)
                ]
            ]


menuItem : Model -> Int -> Attachment -> Html Msg
menuItem model pos attach =
    let
        highlight el =
            let
                dropId =
                    DD.getDropId model.attachDD

                dragId =
                    DD.getDragId model.attachDD

                enable =
                    Just el.id == dropId && dropId /= dragId
            in
            [ ( "current-drop-target", enable )
            ]
    in
    a
        ([ classList <|
            [ ( "item", True )
            ]
                ++ highlight attach
         , href "#"
         , onClick (SetActiveAttachment pos)
         ]
            ++ DD.draggable AttachDDMsg attach.id
            ++ DD.droppable AttachDDMsg attach.id
        )
        [ Maybe.map (Util.String.ellipsis 60) attach.name
            |> Maybe.withDefault "No Name"
            |> text
        ]


sentMailsTab : Model -> List (Html Msg)
sentMailsTab model =
    if Comp.SentMails.isEmpty model.sentMails then
        []

    else
        [ div
            [ classList
                [ ( "right item", True )
                , ( "active", model.sentMailsOpen )
                ]
            , onClick ToggleSentMails
            ]
            [ text "E-Mails"
            ]
        ]
