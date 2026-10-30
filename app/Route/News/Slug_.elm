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
import Markdown.Parser
import Markdown.Renderer
import NewsPost
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
    { body : String
    , metadata : NewsPost.Metadata
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
        (\markdownBody -> Decode.map (Data markdownBody) NewsPost.metadataDecoder)
        ("content/news/" ++ routeParams.slug ++ ".md")
        |> BackendTask.allowFatal


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Shared.siteName
        , image = Shared.siteImage
        , description = app.data.metadata.title
        , locale = Nothing
        , title = app.data.metadata.title ++ " | News"
        }
        |> Seo.website


renderMarkdown : String -> List (Html msg)
renderMarkdown markdown =
    Markdown.Parser.parse markdown
        |> Result.mapError (\_ -> "Markdown parsing error")
        |> Result.andThen (Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer)
        |> Result.withDefault [ Html.text markdown ]


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    { title = app.data.metadata.title
    , body =
        [ Html.div [ Html.Attributes.class "post-full" ]
            [ Html.div [ Html.Attributes.class "post-back" ]
                [ Route.link [] [ Html.text "← Back to news" ] Route.News ]
            , Html.article []
                [ Html.header []
                    [ Html.h1 [] [ Html.text app.data.metadata.title ]
                    , Html.p [ Html.Attributes.class "post-meta" ]
                        [ Html.time []
                            [ Html.text ("Published: " ++ NewsPost.formatDate app.data.metadata.date) ]
                        ]
                    ]
                , Html.div [ Html.Attributes.class "post-content" ]
                    (renderMarkdown app.data.body)
                ]
            ]
        ]
    }
