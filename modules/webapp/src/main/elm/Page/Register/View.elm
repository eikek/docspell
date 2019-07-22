module Page.Register.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Data.Flags exposing (Flags)
import Page.Register.Data exposing (..)
import Page exposing (Page(..))

view: Flags -> Model -> Html Msg
view flags model =
    div [class "register-page"]
        [div [class "ui centered grid"]
             [div [class "row"]
                  [div [class "six wide column ui segment register-view"]
                       [h1 [class "ui cener aligned icon header"]
                           [i [class "umbrella icon"][]
                           ,text "Sign up @ Docspell"
                           ]
                       ,Html.form [class "ui large error form raised segment", onSubmit RegisterSubmit]
                           [div [class "required field"]
                                [label [][text "Collective ID"]
                                ,div [class "ui left icon input"]
                                     [input [type_ "text"
                                            ,onInput SetCollId
                                            ,value model.collId
                                            ,autofocus True
                                            ][]
                                     ,i [class "users icon"][]
                                     ]
                                ]
                           ,div [class "required field"]
                                [label [][text "User Login"]
                                ,div [class "ui left icon input"]
                                     [input [type_ "text"
                                            ,onInput SetLogin
                                            ,value model.login
                                            ][]
                                     ,i [class "user icon"][]
                                     ]
                                ]
                           ,div [class "required field"
                                ]
                                [label [][text "Password"]
                                ,div [class "ui left icon action input"]
                                    [input [type_ <| if model.showPass1 then "text" else "password"
                                           ,onInput SetPass1
                                           ,value model.pass1
                                           ][]
                                    ,i [class "lock icon"][]
                                    ,button [class "ui icon button", onClick ToggleShowPass1]
                                        [i [class "eye icon"][]
                                        ]
                                    ]
                                ]
                           ,div [class "required field"
                                ]
                                [label [][text "Password (repeat)"]
                                ,div [class "ui left icon action input"]
                                    [input [type_ <| if model.showPass2 then "text" else "password"
                                           ,onInput SetPass2
                                           ,value model.pass2
                                           ][]
                                    ,i [class "lock icon"][]
                                    ,button [class "ui icon button", onClick ToggleShowPass2]
                                        [i [class "eye icon"][]
                                        ]
                                    ]
                                ]
                           ,div [classList [("field", True)
                                           ,("invisible", flags.config.signupMode /= "invite")
                                           ]]
                               [label [][text "Invitation Key"]
                               ,div [class "ui left icon input"]
                                    [input [type_ "text"
                                           ,onInput SetInvite
                                           ,model.invite |> Maybe.withDefault "" |> value
                                           ][]
                                    ,i [class "key icon"][]
                                    ]
                               ]
                           ,button [class "ui primary button"
                                   ,type_ "submit"
                                   ]
                                [text "Submit"
                                ]
                           ]
                       ,(resultMessage model)
                       ,div [class "ui very basic right aligned segment"]
                            [text "Already signed up? "
                            ,a [class "ui link", Page.href (LoginPage Nothing)]
                               [i [class "sign-in icon"][]
                               ,text "Sign in"
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
                    [text "Registration successful."
                    ]
            else
                div [class "ui error message"]
                    [text r.message
                    ]

        Nothing ->
            if List.isEmpty model.errorMsg then
                span [class "invisible"][]
            else
                div [class "ui error message"]
                    (List.map (\s -> div[][text s]) model.errorMsg)
