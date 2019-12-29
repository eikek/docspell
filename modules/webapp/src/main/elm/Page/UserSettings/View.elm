module Page.UserSettings.View exposing (view)

import Comp.ChangePasswordForm
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page.UserSettings.Data exposing (..)
import Util.Html exposing (classActive)


view : Model -> Html Msg
view model =
    div [ class "usersetting-page ui padded grid" ]
        [ div [ class "four wide column" ]
            [ h4 [ class "ui top attached ablue-comp header" ]
                [ text "User"
                ]
            , div [ class "ui attached fluid segment" ]
                [ div [ class "ui fluid vertical secondary menu" ]
                    [ div
                        [ classActive (model.currentTab == Just ChangePassTab) "link icon item"
                        , onClick (SetTab ChangePassTab)
                        ]
                        [ i [ class "user secret icon" ] []
                        , text "Change Password"
                        ]
                    ]
                ]
            ]
        , div [ class "twelve wide column" ]
            [ div [ class "" ]
                (case model.currentTab of
                    Just ChangePassTab ->
                        viewChangePassword model

                    Nothing ->
                        []
                )
            ]
        ]


viewChangePassword : Model -> List (Html Msg)
viewChangePassword model =
    [ h2 [ class "ui header" ]
        [ i [ class "ui user secret icon" ] []
        , div [ class "content" ]
            [ text "Change Password"
            ]
        ]
    , Html.map ChangePassMsg (Comp.ChangePasswordForm.view model.changePassModel)
    ]
