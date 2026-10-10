module Route.News exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes
import Json.Decode as Decode exposing (Decoder)
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


type alias Post =
    { slug : String
    , date : String
    , titlePl : String
    , titleEn : String
    , descriptionPl : String
    , descriptionEn : String
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


postMetadataDecoder : String -> Decoder Post
postMetadataDecoder slug =
    Decode.map3
        (\date ( titlePl, titleEn ) ( descPl, descEn ) ->
            { slug = slug
            , date = date
            , titlePl = titlePl
            , titleEn = titleEn
            , descriptionPl = descPl
            , descriptionEn = descEn
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
        (Decode.oneOf
            [ Decode.map2 Tuple.pair
                (Decode.field "description_pl" Decode.string)
                (Decode.field "description_en" Decode.string)
            , Decode.map (\d -> ( d, d ))
                (Decode.field "description" Decode.string)
            , Decode.map (\d -> ( d, d ))
                (Decode.field "description_pl" Decode.string)
            , Decode.succeed ( "", "" )
            ]
        )


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
                            File.onlyFrontmatter (postMetadataDecoder slug) filePath
                                |> BackendTask.allowFatal
                        )
            )
        |> BackendTask.andThen BackendTask.combine
        |> BackendTask.map (List.sortBy .date >> List.reverse)


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
view app shared =
    let
        lang =
            shared.language
    in
    { title =
        Language.t lang
            { pl = "Aktualności"
            , en = "News"
            }
    , body =
        [ Html.section []
            [ Html.h2 []
                [ Html.text <|
                    Language.t lang
                        { pl = "Aktualności"
                        , en = "News & Announcements"
                        }
                ]
            , if List.isEmpty app.data then
                Html.p []
                    [ Html.text <|
                        Language.t lang
                            { pl = "Brak wpisów w aktualnościach."
                            , en = "No news posts yet."
                            }
                    ]

              else
                Html.div [ Html.Attributes.class "news-list" ]
                    (List.map (renderPostPreview lang) app.data)
            ]
        ]
    }


renderPostPreview : Language.Language -> Post -> Html (PagesMsg Msg)
renderPostPreview lang post =
    let
        title =
            Language.t lang
                { pl = post.titlePl
                , en = post.titleEn
                }

        description =
            Language.t lang
                { pl = post.descriptionPl
                , en = post.descriptionEn
                }
    in
    Html.article [ Html.Attributes.class "post-preview" ]
        [ Html.header []
            [ Html.time [ Html.Attributes.class "post-date" ]
                [ Html.text (Language.formatDate lang post.date) ]
            , Html.h3 [ Html.Attributes.class "post-title" ]
                [ Route.link [] [ Html.text title ] (Route.News__Slug_ { slug = post.slug })
                ]
            ]
        , if String.isEmpty description then
            Html.text ""

          else
            Html.p [ Html.Attributes.class "post-description" ]
                [ Html.text description ]
        , Html.div [ Html.Attributes.class "post-actions" ]
            [ Route.link [ Html.Attributes.class "read-more" ]
                [ Html.text <|
                    Language.t lang
                        { pl = "Czytaj dalej →"
                        , en = "Read more →"
                        }
                ]
                (Route.News__Slug_ { slug = post.slug })
            ]
        ]
