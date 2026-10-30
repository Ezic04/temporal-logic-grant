module Route.News exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes
import Json.Decode as Decode
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
    {}


type alias Post =
    { slug : String
    , metadata : NewsPost.Metadata
    }


type alias Data =
    List Post


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
    Glob.succeed (\filePath slug -> { filePath = filePath, slug = slug })
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/news/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask
        |> BackendTask.map
            (\files ->
                files
                    |> List.map
                        (\{ filePath, slug } ->
                            File.onlyFrontmatter (Decode.map (Post slug) NewsPost.metadataDecoder) filePath
                                |> BackendTask.allowFatal
                        )
            )
        |> BackendTask.andThen BackendTask.combine
        |> BackendTask.map (List.sortBy (.metadata >> .date) >> List.reverse)


head : App Data ActionData RouteParams -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Shared.siteName
        , image = Shared.siteImage
        , description = "Project News and Announcements"
        , locale = Nothing
        , title = "News"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = "News"
    , body =
        [ Html.section []
            [ Html.h2 [] [ Html.text "News & Announcements" ]
            , if List.isEmpty app.data then
                Html.p [] [ Html.text "No news posts yet." ]

              else
                Html.div [ Html.Attributes.class "news-list" ]
                    (List.map renderPostPreview app.data)
            ]
        ]
    }


renderPostPreview : Post -> Html (PagesMsg Msg)
renderPostPreview { slug, metadata } =
    Html.article [ Html.Attributes.class "post-preview" ]
        [ Html.header []
            [ Html.time [ Html.Attributes.class "post-date" ]
                [ Html.text (NewsPost.formatDate metadata.date) ]
            , Html.h3 [ Html.Attributes.class "post-title" ]
                [ Route.link [] [ Html.text metadata.title ] (Route.News__Slug_ { slug = slug })
                ]
            ]
        , if String.isEmpty metadata.description then
            Html.text ""

          else
            Html.p [ Html.Attributes.class "post-description" ]
                [ Html.text metadata.description ]
        , Html.div [ Html.Attributes.class "post-actions" ]
            [ Route.link [ Html.Attributes.class "read-more" ]
                [ Html.text "Read more →" ]
                (Route.News__Slug_ { slug = slug })
            ]
        ]
