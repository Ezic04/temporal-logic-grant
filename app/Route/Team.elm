module Route.Team exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html)
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


memberItem : String -> Html msg
memberItem name =
    Html.li []
        [ Html.strong [] [ Html.text name ]
        , Html.text " — project role / research area"
        ]


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view _ _ =
    { title = "Team"
    , body =
        [ Html.section []
            [ Html.h2 [] [ Html.text "Research Team" ]
            , Html.p [] [ Html.text "Below is the list of researchers and contributors participating in the project." ]
            , Html.div []
                [ Html.h3 [] [ Html.text "Principal Investigator" ]
                , Html.ul []
                    [ Html.li []
                        [ Html.text "Prof. Kordula Świętorzecka — Cardinal Stefan Wyszyński University in Warsaw, email: contact@example.com" ]
                    ]
                , Html.h3 [] [ Html.text "Researchers & Collaborators" ]
                , Html.ul [] [ memberItem "PhD Konrad Zdanowski" ]
                , Html.h3 [] [ Html.text "Scholarship Holders" ]
                , Html.ul []
                    [ memberItem "[Scholarship Holder 1]"
                    , memberItem "[Scholarship Holder 2]"
                    ]
                ]
            ]
        ]
    }
