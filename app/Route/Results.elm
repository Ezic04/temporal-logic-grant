module Route.Results exposing (ActionData, Data, Model, Msg, route)

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
        , description = "Research Results and Publications"
        , locale = Nothing
        , title = "Results"
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
            { pl = "Wyniki"
            , en = "Results"
            }
    , body =
        [ Html.section []
            [ Html.h2 []
                [ Html.text <|
                    Language.t lang
                        { pl = "Wyniki Badań"
                        , en = "Research Results"
                        }
                ]
            , Html.p []
                [ Html.text <|
                    Language.t lang
                        { pl = "TODO: tu są wyniki"
                        , en = "TODO: results here"
                        }
                ]
            , Html.h3 []
                [ Html.text <|
                    Language.t lang
                        { pl = "Publikacje"
                        , en = "Publications"
                        }
                ]
            , Html.ul []
                [ Html.li []
                    [ Html.text "TODO: [Paper 1 / Publikacja 1]"
                    ]
                , Html.li []
                    [ Html.text "TODO: [Paper 2 / Publikacja 2]"
                    ]
                ]
            , Html.h3 []
                [ Html.text <|
                    Language.t lang
                        { pl = "Konferencje"
                        , en = "Conferences"
                        }
                ]
            , Html.p []
                [ Html.text <|
                    Language.t lang
                        { pl = "TODO: [konferencja]"
                        , en = "TODO: [conference]"
                        }
                ]
            ]
        ]
    }
