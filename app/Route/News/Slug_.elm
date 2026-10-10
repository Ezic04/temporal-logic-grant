module Route.News.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes
import Json.Decode as Decode
import Language
import Markdown.Parser
import Markdown.Renderer
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
    { slug : String }


type alias Data =
    { titlePl : String
    , titleEn : String
    , date : String
    , body : String
    }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    Glob.succeed RouteParams
        |> Glob.match (Glob.literal "content/news/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    File.bodyWithFrontmatter
        (\markdownBody ->
            Decode.map3
                (\date ( titlePl, titleEn ) () ->
                    { date = date
                    , titlePl = titlePl
                    , titleEn = titleEn
                    , body = markdownBody
                    }
                )
                (Decode.field "date" Decode.string)
                (Decode.oneOf
                    [ Decode.map2 Tuple.pair
                        (Decode.field "title_pl" Decode.string)
                        (Decode.field "title_en" Decode.string)
                    , Decode.map (\t -> ( t, t ))
                        (Decode.field "title" Decode.string)
                    , Decode.map (\t -> ( t, t ))
                        (Decode.field "title_pl" Decode.string)
                    , Decode.succeed ( "Untitled", "Untitled" )
                    ]
                )
                (Decode.succeed ())
        )
        ("content/news/" ++ routeParams.slug ++ ".md")
        |> BackendTask.allowFatal


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Shared.siteName
        , image = Shared.siteImage
        , description = app.data.titleEn
        , locale = Nothing
        , title = app.data.titleEn ++ " | News"
        }
        |> Seo.website


renderMarkdown : String -> List (Html msg)
renderMarkdown markdown =
    Markdown.Parser.parse markdown
        |> Result.mapError (\_ -> "Markdown parsing error")
        |> Result.andThen (Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer)
        |> Result.withDefault [ Html.text markdown ]


extractBody : Language.Language -> String -> String
extractBody lang raw =
    if String.contains "<!-- en -->" raw then
        case String.split "<!-- en -->" raw of
            [ plPart, enPart ] ->
                case lang of
                    Language.Pl ->
                        plPart
                            |> String.replace "<!-- pl -->" ""
                            |> String.trim

                    Language.En ->
                        String.trim enPart

            _ ->
                raw

    else
        raw


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app shared =
    let
        lang =
            shared.language

        title =
            Language.t lang
                { pl = app.data.titlePl
                , en = app.data.titleEn
                }

        bodyMarkdown =
            extractBody lang app.data.body
    in
    { title = title
    , body =
        [ Html.div [ Html.Attributes.class "post-full" ]
            [ Html.div [ Html.Attributes.class "post-back" ]
                [ Route.link []
                    [ Html.text <|
                        Language.t lang
                            { pl = "← Wróć do aktualności"
                            , en = "← Back to news"
                            }
                    ]
                    Route.News
                ]
            , Html.article []
                [ Html.header []
                    [ Html.h1 [] [ Html.text title ]
                    , Html.p [ Html.Attributes.class "post-meta" ]
                        [ Html.time []
                            [ Html.text <|
                                Language.t lang
                                    { pl = "Opublikowano: " ++ Language.formatDate lang app.data.date
                                    , en = "Published: " ++ Language.formatDate lang app.data.date
                                    }
                            ]
                        ]
                    ]
                , Html.div [ Html.Attributes.class "post-content" ]
                    (renderMarkdown bodyMarkdown)
                ]
            ]
        ]
    }
