module Route.Team exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Language
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


type alias Data =
    {}


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


data : BackendTask FatalError Data
data =
    BackendTask.succeed {}


head : App Data ActionData RouteParams -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Shared.siteName
        , image = Shared.siteImage
        , description = "Research Team"
        , locale = Nothing
        , title = "Team"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view _ shared =
    let
        lang =
            shared.language

        uksw =
            Language.t lang
                { pl = "Uniwersytet Kardynała Stefana Wyszyńskiego w Warszawie"
                , en = "Cardinal Stefan Wyszyński University in Warsaw"
                }

        piEmail =
            "contact@example.com"
    in
    { title =
        Language.t lang
            { pl = "Zespół"
            , en = "Team"
            }
    , body =
        [ Html.section []
            [ Html.h2 []
                [ Html.text <|
                    Language.t lang
                        { pl = "Skład Zespołu"
                        , en = "Research Team"
                        }
                ]
            , Html.p []
                [ Html.text <|
                    Language.t lang
                        { pl = "Poniżej znajduje się lista członków zespołu realizującego projekt."
                        , en = "Below is the list of researchers and contributors participating in the project."
                        }
                ]
            , Html.div []
                [ Html.h3 []
                    [ Html.text <|
                        Language.t lang
                            { pl = "Kierownik Projektu"
                            , en = "Principal Investigator"
                            }
                    ]
                , Html.ul []
                    [ Html.li []
                        [ Html.text <|
                            Language.t lang
                                { pl = "dr. hab. Kordula Świętorzecka"
                                , en = "PhD Kordula Świętorzecka"
                                }
                        , Html.text (" — " ++ uksw ++ Language.t lang { pl = ", e-mail: ", en = ", email: " } ++ piEmail)
                        ]
                    ]
                , Html.h3 []
                    [ Html.text <|
                        Language.t lang
                            { pl = "Wykonawcy"
                            , en = "Researchers & Collaborators"
                            }
                    ]
                , Html.ul []
                    [ Html.li []
                        [ Html.strong [] [ Html.text "Konrad Zdanowski" ]
                        , Html.text <|
                            Language.t lang
                                { pl = " — rola w projekcie / obszar badawczy"
                                , en = " — project role / research area"
                                }
                        ]
                    ]
                , Html.h3 []
                    [ Html.text <|
                        Language.t lang
                            { pl = "Stypendyści"
                            , en = "Scholarship Holders"
                            }
                    ]
                , Html.ul []
                    [ Html.li []
                        [ Html.strong [] [ Html.text "[Stypendysta 1 / Scholarship Holder 1]" ]
                        , Html.text <|
                            Language.t lang
                                { pl = " — rola w projekcie / obszar badawczy"
                                , en = " — project role / research area"
                                }
                        ]
                    , Html.li []
                        [ Html.strong [] [ Html.text "[Stypendysta 2 / Scholarship Holder 2]" ]
                        , Html.text <|
                            Language.t lang
                                { pl = " — rola w projekcie / obszar badawczy"
                                , en = " — project role / research area"
                                }
                        ]
                    ]
                ]
            ]
        ]
    }
