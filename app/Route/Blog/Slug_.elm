module Route.Blog.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Pages.Url
import PagesMsg exposing (PagesMsg)
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
    { content : String }


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



-- pages : BackendTask FatalError (List RouteParams)
-- pages =
--     BackendTask.succeed
--         [ { slug = "hello" }
--         ]


pages : BackendTask FatalError (List RouteParams)
pages =
    Glob.succeed RouteParams
        |> Glob.match (Glob.literal "content/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask



-- data : RouteParams -> BackendTask FatalError Data
-- data routeParams =
--     BackendTask.map Data
--         (BackendTask.succeed "Hi")


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    File.rawFile ("content/" ++ routeParams.slug ++ ".md")
        |> BackendTask.allowFatal
        |> BackendTask.map (\body -> { content = body })



-- head :
--     App Data ActionData RouteParams
--     -> List Head.Tag
-- head app =
--     Seo.summary
--         { canonicalUrlOverride = Nothing
--         , siteName = "elm-pages"
--         , image =
--             { url = Pages.Url.external "TODO"
--             , alt = "elm-pages logo"
--             , dimensions = Nothing
--             , mimeType = Nothing
--             }
--         , description = "TODO"
--         , locale = Nothing
--         , title = "TODO title" -- metadata.title -- TODO
--         }
--         |> Seo.website


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    []



-- view :
--     App Data ActionData RouteParams
--     -> Shared.Model
--     -> View (PagesMsg Msg)
-- view app sharedModel =
--     { title = "Placeholder - Blog.Slug_"
--     , body = [ Html.text "You're on the page Blog.Slug_" ]
--     }


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app shared =
    { title = app.routeParams.slug
    , body =
        [ Html.h1 [] [ Html.text app.routeParams.slug ]
        , Html.p [] [ Html.text app.data.content ]
        ]
    }
