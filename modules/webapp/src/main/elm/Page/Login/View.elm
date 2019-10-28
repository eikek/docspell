module Page.Login.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Page exposing (Page(..))
import Page.Login.Data exposing (..)
import Data.Flags exposing (Flags)

view: Flags -> Model -> Html Msg
view flags model =
    div [class "login-page"]
        [div [class "ui centered grid"]
             [div [class "row"]
                  [div [class "six wide column ui segment login-view"]
                       [h1 [class "ui center aligned icon header"]
                            [img [class "ui image"
                                 ,src (flags.config.docspellAssetPath ++ "/img/logo-96.png")
                                 ][]
                            ,div [class "content"]
                                 [text "Sign in to Docspell"
                                 ]
                            ]
                       ,Html.form [ class "ui large error raised form segment"
                                  , onSubmit Authenticate
                                  , autocomplete False
                                  ]
                           [div [class "field"]
                                [label [][text "Username"]
                                ,div [class "ui left icon input"]
                                     [input [type_ "text"
                                            ,autocomplete False
                                            ,onInput SetUsername
                                            ,value model.username
                                            ,placeholder "Collective / Login"
                                            ,autofocus True
                                            ][]
                                     ,i [class "user icon"][]
                                     ]
                                ]
                           ,div [class "field"]
                               [label [][text "Password"]
                               ,div [class "ui left icon input"]
                                    [input [type_ "password"
                                           ,autocomplete False
                                           ,onInput SetPassword
                                           ,value model.password
                                           ,placeholder "Password"
                                           ][]
                                    ,i [class "lock icon"][]
                                    ]
                               ]
                           ,button [class "ui primary fluid button"
                                   ,type_ "submit"
                                   ]
                                [text "Login"
                                ]
                           ]
                       ,(resultMessage model)
                       ,div[class "ui very basic right aligned segment"]
                           [text "No account? "
                           ,a [class "ui icon link", Page.href RegisterPage]
                              [i [class "edit icon"][]
                              ,text "Sign up!"
                              ]
                           ]
                       ]
                  ]
             ]
        ]

resultMessage: Model -> Html Msg
resultMessage model =
    case model.result of
        Just r ->
            if r.success
            then
                div [class "ui success message"]
                    [text "Login successful."
                    ]
            else
                div [class "ui error message"]
                    [text r.message
                    ]

        Nothing ->
            span [][]
