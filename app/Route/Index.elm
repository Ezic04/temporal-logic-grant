module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Html.Attributes
import Language
import PagesMsg exposing (PagesMsg)
import Route
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
        , description = "Home page of the research project"
        , locale = Nothing
        , title = "Home"
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
    in
    { title =
        Language.t lang
            { pl = "Strona Główna"
            , en = "Home"
            }
    , body =
        [ Html.section []
            [ Html.h2 []
                [ Html.text <|
                    Language.t lang
                        { pl = "O Projekcie"
                        , en = "About the Project"
                        }
                ]
            , Html.p []
                [ Html.text <|
                    Language.t lang
                        { pl = "TODO: opis"
                        , en = "TODO: description"
                        }
                ]
            , Html.h3 []
                [ Html.text <|
                    Language.t lang
                        { pl = "Przykładowa formuła"
                        , en = "Formula Example"
                        }
                ]
            , Html.node "katex-math"
                [ Html.Attributes.attribute "content" "\\varphi \\;\\equiv\\; \\Box (p \\implies \\Diamond q)"
                , Html.Attributes.attribute "display" "true"
                ]
                []
            ]
        , Html.section []
            [ Html.h3 []
                [ Html.text <|
                    Language.t lang
                        { pl = "Szybkie odnośniki"
                        , en = "Quick Navigation"
                        }
                ]
            , Html.ul []
                [ Html.li []
                    [ Route.link []
                        [ Html.text <|
                            Language.t lang
                                { pl = "Zespół badawczy"
                                , en = "Research Team"
                                }
                        ]
                        Route.Team
                    ]
                , Html.li []
                    [ Route.link []
                        [ Html.text <|
                            Language.t lang
                                { pl = "Aktualności i komunikaty"
                                , en = "News & Announcements"
                                }
                        ]
                        Route.News
                    ]
                , Html.li []
                    [ Route.link []
                        [ Html.text <|
                            Language.t lang
                                { pl = "Wyniki i publikacje"
                                , en = "Results & Publications"
                                }
                        ]
                        Route.Results
                    ]
                ]
            ]
        ]
    }
