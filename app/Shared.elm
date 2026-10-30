module Shared exposing
    ( Data
    , Model
    , Msg
    , siteImage
    , siteName
    , template
    )

import BackendTask exposing (BackendTask)
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import UrlPath exposing (UrlPath)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Nothing
    }


type Msg
    = NoOp


type alias Data =
    ()


type alias Model =
    {}


init :
    Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : UrlPath
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Effect Msg )
init _ _ =
    ( {}, Effect.none )


update : Msg -> Model -> ( Model, Effect Msg )
update NoOp model =
    ( model, Effect.none )


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : BackendTask FatalError Data
data =
    BackendTask.succeed ()


siteName : String
siteName =
    "Temporal Logic Project"


siteImage : Seo.Image
siteImage =
    { url = [] |> UrlPath.join |> Pages.Url.fromPath
    , alt = "Logo"
    , dimensions = Nothing
    , mimeType = Nothing
    }


view :
    Data
    ->
        { path : UrlPath
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : List (Html msg), title : String }
view _ page _ _ pageView =
    { body =
        [ Html.header [ Html.Attributes.class "site-header" ]
            [ Html.h1 [ Html.Attributes.class "site-title" ]
                [ Html.text "Logical foundations of branching time theories using infinite inference rules" ]
            , Html.p [ Html.Attributes.class "site-subtitle" ]
                [ Html.text "National Science Center OPUS grant" ]
            , Html.nav [ Html.Attributes.class "site-nav" ]
                [ navLink Route.Index "Home" (page.route == Just Route.Index)
                , navLink Route.Team "Team" (page.route == Just Route.Team)
                , navLink Route.News "News" (isNewsRoute page.route)
                , navLink Route.Results "Results" (page.route == Just Route.Results)
                ]
            ]
        , Html.main_ [ Html.Attributes.class "site-content" ] pageView.body
        , Html.footer [ Html.Attributes.class "site-footer" ]
            [ Html.p [] [ Html.text "© 2026 TODO: footer" ] ]
        ]
    , title = pageView.title
    }


isNewsRoute : Maybe Route -> Bool
isNewsRoute maybeRoute =
    case maybeRoute of
        Just Route.News ->
            True

        Just (Route.News__Slug_ _) ->
            True

        _ ->
            False


navLink : Route -> String -> Bool -> Html msg
navLink targetRoute label isActive =
    Route.link
        [ Html.Attributes.class
            (if isActive then
                "nav-link nav-link-active"

             else
                "nav-link"
            )
        ]
        [ Html.text label ]
        targetRoute
