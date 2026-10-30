module Route.Results exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
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
view _ _ =
    { title = "Results"
    , body =
        [ Html.section []
            [ Html.h2 [] [ Html.text "Research Results" ]
            , Html.p [] [ Html.text "TODO: results here" ]
            , Html.h3 [] [ Html.text "Publications" ]
            , Html.ul []
                [ Html.li [] [ Html.text "TODO: [Paper 1]" ]
                , Html.li [] [ Html.text "TODO: [Paper 2]" ]
                ]
            , Html.h3 [] [ Html.text "Conferences" ]
            , Html.p [] [ Html.text "TODO: [conference]" ]
            ]
        ]
    }
