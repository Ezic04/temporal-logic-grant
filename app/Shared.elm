module Shared exposing
    ( Data
    , Model
    , Msg(..)
    , SharedMsg(..)
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
import Html.Events
import Json.Decode as Decode
import Language exposing (Language(..))
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
    = SharedMsg SharedMsg
    | SetLanguage Language


type alias Data =
    ()


type SharedMsg
    = NoOp


type alias Model =
    { language : Language
    }


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
init flags maybePagePath =
    let
        initialLanguage =
            case flags of
                Pages.Flags.BrowserFlags value ->
                    case Decode.decodeValue Decode.string value of
                        Ok "en" ->
                            En

                        _ ->
                            Language.defaultLanguage

                Pages.Flags.PreRenderFlags ->
                    Language.defaultLanguage
    in
    ( { language = initialLanguage }
    , Effect.none
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg NoOp ->
            ( model, Effect.none )

        SetLanguage lang ->
            ( { model | language = lang }, Effect.none )


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : BackendTask FatalError Data
data =
    BackendTask.succeed ()


siteTitle : Language -> String
siteTitle lang =
    Language.t lang
        { pl = "Logiczne podstawy teorii rozgałęzionego czasu z zastosowaniem nieskończonych reguł wnioskowania"
        , en = "Logical foundations of branching time theories using infinite inference rules"
        }


siteSubtitle : Language -> String
siteSubtitle lang =
    Language.t lang
        { pl = "grant OPUS Narodowego Centrum Nauki"
        , en = "National Science Center OPUS grant"
        }


siteName : String
siteName =
    "Temporal Logic Project"


siteImage : Seo.Image
siteImage =
    { url = [ "images", "icon-png.png" ] |> UrlPath.join |> Pages.Url.fromPath
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
view sharedData page model toMsg pageView =
    let
        lang =
            model.language
    in
    { body =
        [ Html.header [ Html.Attributes.class "site-header" ]
            [ Html.div [ Html.Attributes.class "header-top-row" ]
                [ Html.div [ Html.Attributes.class "site-title-box" ]
                    [ Html.h1 [ Html.Attributes.class "site-title" ]
                        [ Html.text (siteTitle lang) ]
                    , Html.p [ Html.Attributes.class "site-subtitle" ]
                        [ Html.text (siteSubtitle lang) ]
                    ]
                , if List.length Language.supportedLanguages > 1 then
                    Html.div [ Html.Attributes.class "lang-switcher" ]
                        [ Html.button
                            [ Html.Events.onClick (SetLanguage Pl)
                            , Html.Attributes.class
                                (if lang == Pl then
                                    "lang-btn lang-btn-active"

                                 else
                                    "lang-btn"
                                )
                            ]
                            [ Html.text "PL" ]
                        , Html.button
                            [ Html.Events.onClick (SetLanguage En)
                            , Html.Attributes.class
                                (if lang == En then
                                    "lang-btn lang-btn-active"

                                 else
                                    "lang-btn"
                                )
                            ]
                            [ Html.text "EN" ]
                        ]
                        |> Html.map toMsg

                  else
                    Html.text ""
                ]
            , Html.nav [ Html.Attributes.class "site-nav" ]
                [ navLink Route.Index (Language.t lang { pl = "Główna", en = "Home" }) (page.route == Just Route.Index)
                , navLink Route.Team (Language.t lang { pl = "Zespół", en = "Team" }) (page.route == Just Route.Team)
                , navLink Route.News (Language.t lang { pl = "Aktualności", en = "News" }) (isNewsRoute page.route)
                , navLink Route.Results (Language.t lang { pl = "Wyniki", en = "Results" }) (page.route == Just Route.Results)
                ]
            ]
        , Html.main_ [ Html.Attributes.class "site-content" ] pageView.body
        , Html.footer [ Html.Attributes.class "site-footer" ]
            [ Html.p []
                [ Html.text <|
                    Language.t lang
                        { pl = "© 2026 TODO: stopka"
                        , en = "© 2026 TODO: footer"
                        }
                ]
            ]
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
