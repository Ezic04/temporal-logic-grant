{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}

import Control.Monad ((>=>))
import Data.Aeson (FromJSON (..), GFromJSON, Key, Options (..), Value (Object), Zero, defaultOptions, genericParseJSON, withObject, withText, (.!=), (.:?))
import Data.Aeson.Types (Parser, parseEither)
import Data.Bifunctor (bimap, first)
import Data.Char (isDigit, toLower)
import Data.Foldable (traverse_)
import Data.Functor ((<&>))
import Data.List (find, intersperse, partition, sortOn)
import Data.Maybe (catMaybes)
import Data.Ord (Down (..))
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (Day, UTCTime (utctDay), defaultTimeLocale, formatTime, getCurrentTime)
import GHC.Generics (Generic, Rep)
import Hakyll
import System.FilePath (dropExtension, makeRelative, normalise, takeDirectory, (</>))
import Text.Blaze.Html.Renderer.String (renderHtml)
import Text.Blaze.Html5 (Html, (!))
import Text.Blaze.Html5 qualified as H
import Text.Blaze.Html5.Attributes qualified as A
import Text.Pandoc (Block (..), Format (..), HTMLMathMethod (MathML), Inline (..), Pandoc (..), WriterOptions (..), readMarkdown, runPure, writeHtml5String)
import Text.Pandoc.Shared (stringify)
import Text.Pandoc.Walk (walk)
import Text.RawString.QQ (r)

data Section = Home | Team | Tasks | Seminars | Materials | Conferences | Publications
  deriving (Eq, Show, Enum, Bounded)

enumerate :: (Bounded a, Enum a) => [a]
enumerate = [minBound .. maxBound]

sections :: [Section]
sections = enumerate

slug :: Section -> String
slug = map toLower . show

sourcePath :: Section -> FilePath
sourcePath Home = "content/index.md"
sourcePath s = "content" </> slug s <> ".md"

outputPath :: Section -> FilePath
outputPath Home = "index.html"
outputPath s = slug s </> "index.html"

sectionUrl :: Section -> String
sectionUrl Home = "/"
sectionUrl s = "/" <> slug s <> "/"

materialsPattern :: Pattern
materialsPattern = "content/materials/*.md"

macros :: String
macros =
  [r|
\newcommand{\sf}[1]{\mathsf{#1}}
\newcommand{\UB}{\sf{UB}}
\newcommand{\TLR}{\sf{TLR}}
\newcommand{\CTL}{\sf{CTL}}
\newcommand{\CTLs}{\CTL^*}
|]

main :: IO ()
main = do
  today <- utctDay <$> getCurrentTime
  hakyll $ do
    match "templates/*" $ compile templateBodyCompiler
    match ("style.css" .||. ("content/**" .&&. complement "content/**.md")) $ do
      route (customRoute (makeRelative "content" . toFilePath))
      compile copyFileCompiler
    match materialsPattern $ do
      route cleanRoute
      compile $ do
        _ <- getUnderlying >>= decodeWith (parseJSON @Material)
        markdown >>= layout Materials pageContext
    traverse_ (sectionRules today) sections
    match ("content/**.md" .&&. complement knownSources) $
      compile (getUnderlying >>= \i -> fail ("unknown content file " <> toFilePath i) :: Compiler (Item String))

knownSources :: Pattern
knownSources = fromList (sectionToIdent <$> sections) .||. materialsPattern
  where
    sectionToIdent = fromFilePath . sourcePath

sectionRules :: Day -> Section -> Rules ()
sectionRules today s = match (fromGlob (sourcePath s)) $ do
  route (constRoute (outputPath s))
  compile $ do
    extra <- sectionExtra today s
    markdown >>= layout s (sectionContext s) . fmap (<> renderHtml extra)

cleanRoute :: Routes
cleanRoute = customRoute $ \i -> dropExtension (makeRelative "content" (toFilePath i)) </> "index.html"

sectionContext :: Section -> Context String
sectionContext Home = bodyField "body" <> metadataField <> constField "title" (show Home)
sectionContext s = pageContext <> constField "title" (show s)

pageContext :: Context String
pageContext = bodyField "body" <> metadataField <> boolField "heading" (const True)

layout :: Section -> Context String -> Item String -> Compiler (Item String)
layout s ctx =
  loadAndApplyTemplate "templates/default.html" (ctx <> constField "nav" (renderHtml (navHtml s)))
    >=> relativizeUrls

navHtml :: Section -> Html
navHtml active = foldMap link sections
  where
    link s =
      H.a
        ! A.href (H.stringValue (sectionUrl s))
        ! A.class_ (if s == active then "nav-link nav-link-active" else "nav-link")
        $ H.toHtml (show s)

writerOptions :: WriterOptions
writerOptions = defaultHakyllWriterOptions {writerHTMLMathMethod = MathML}

markdown :: Compiler (Item String)
markdown = do
  i <- getUnderlying
  root <- maybe "." toSiteRoot <$> getRoute i
  let relink = resolve root (takeDirectory (toFilePath i))
      transform = walk (transformInline relink)
  source <- fmap (macros <>) <$> getResourceBody
  renderPandocWithTransform defaultHakyllReaderOptions writerOptions transform source

resolve :: FilePath -> FilePath -> Text -> Text
resolve root dir t
  | T.any (== ':') t || any (`T.isPrefixOf` t) ["/", "#"] = t
  | otherwise = T.pack (root </> normalise (makeRelative "content" dir </> T.unpack t))

transformInline :: (Text -> Text) -> Inline -> Inline
transformInline relink = \case
  Image _ alt (src, _) | ".pdf" `T.isSuffixOf` T.toLower src -> pdfEmbed (stringify alt) (relink src)
  Image attr alt (src, t) -> Image attr alt (relink src, t)
  Link attr xs (href, t) -> Link attr xs (relink href, t)
  x -> x

pdfEmbed :: Text -> Text -> Inline
pdfEmbed label src =
  RawInline (Format "html") . T.pack . renderHtml $
    H.object ! A.class_ "pdf" ! A.data_ (H.textValue src) ! A.type_ "application/pdf" $
      H.a ! A.href (H.textValue src) $
        H.toHtml (if T.null label then "Download PDF" else label)

inline :: Text -> Either String Html
inline t = bimap show H.preEscapedToHtml . runPure $ do
  Pandoc meta blocks <- readMarkdown defaultHakyllReaderOptions (T.pack macros <> t)
  writeHtml5String writerOptions (Pandoc meta (map unPara blocks))
  where
    unPara (Para xs) = Plain xs
    unPara b = b

orFail :: Either String a -> Compiler a
orFail = either fail pure

decodeWith :: (Value -> Parser a) -> Identifier -> Compiler a
decodeWith parser i = getMetadata i >>= orFail . first ((toFilePath i <> ": ") <>) . parseEither parser . Object

frontmatter :: (FromJSON a, Monoid a) => Key -> Compiler a
frontmatter k = getUnderlying >>= decodeWith (withObject "frontmatter" (\o -> o .:? k .!= mempty))

strict :: (Generic a, GFromJSON Zero (Rep a)) => Value -> Parser a
strict = genericParseJSON defaultOptions {rejectUnknownFields = True}

enumJSON :: (Bounded a, Enum a) => String -> (a -> Text) -> Value -> Parser a
enumJSON name key = withText name parse
  where
    parse t = maybe (unknown t) pure (find (hasKey t) enumerate)
    hasKey t x = key x == t
    unknown t = fail (name <> ": unknown value " <> show t)

showDate :: Day -> String
showDate = formatTime defaultTimeLocale "%B %-d, %Y"

dateHtml :: Day -> Html
dateHtml d = H.time ! A.class_ "entry-date" ! A.datetime (H.stringValue (show d)) $ H.toHtml (showDate d)

linkHtml :: Text -> Html -> Html
linkHtml u = H.a ! A.href (H.textValue u)

data Role = PrincipalInvestigator | Contractor | Student
  deriving (Eq, Enum, Bounded)

roleKey :: Role -> Text
roleKey = \case
  PrincipalInvestigator -> "pi"
  Contractor -> "researcher"
  Student -> "student"

roleTitle :: Role -> Html
roleTitle = \case
  PrincipalInvestigator -> "Principal Investigator"
  Contractor -> "Contractor"
  Student -> "Scholarship Holder"

instance FromJSON Role where
  parseJSON = enumJSON "role" roleKey

newtype Orcid = Orcid Text

instance FromJSON Orcid where
  parseJSON = withText "orcid" $ \t ->
    if validOrcid t then pure (Orcid t) else fail ("invalid ORCID " <> show t)

validOrcid :: Text -> Bool
validOrcid t = case T.splitOn "-" t of
  groups@[_, _, _, _] -> all ((== 4) . T.length) groups && T.all isDigit (T.init digits) && (isDigit (T.last digits) || T.last digits == 'X')
    where
      digits = T.concat groups
  _ -> False

data Member = Member
  { name :: Text,
    role :: Role,
    affiliation :: Maybe Text,
    email :: Maybe Text,
    orcid :: Maybe Orcid,
    url :: Maybe Text
  }
  deriving (Generic)

instance FromJSON Member where
  parseJSON = strict

data Seminar = Seminar
  { date :: Day,
    speaker :: Maybe Text,
    topic :: Text
  }
  deriving (Generic)

instance FromJSON Seminar where
  parseJSON = strict

data Entry = Entry
  { title :: Text,
    authors :: [Text],
    venue :: Text,
    date :: Day,
    url :: Maybe Text,
    doi :: Maybe Text,
    pdf :: Maybe Text
  }
  deriving (Generic)

instance FromJSON Entry where
  parseJSON = strict

data Material = Material
  { title :: Text,
    description :: Maybe Text
  }
  deriving (Generic)

instance FromJSON Material where
  parseJSON = strict

sectionExtra :: Day -> Section -> Compiler Html
sectionExtra today = \case
  Home -> pure mempty
  Tasks -> pure mempty
  Team -> teamHtml <$> frontmatter "members"
  Seminars -> frontmatter "seminars" >>= orFail . seminarsHtml today
  Materials -> materialsHtml
  Conferences -> frontmatter "items" >>= orFail . entriesHtml
  Publications -> frontmatter "items" >>= orFail . entriesHtml

placeholder :: Html
placeholder = H.p ! A.class_ "placeholder" $ "Nothing here yet."

listHtml :: [Html] -> Html
listHtml [] = placeholder
listHtml xs = H.ul ! A.class_ "entry-list" $ mconcat (map H.li xs)

teamHtml :: [Member] -> Html
teamHtml = (H.ul ! A.class_ "team-list") . foldMap (H.li . member)

member :: Member -> Html
member m =
  H.strong (maybe id linkHtml m.url (H.toHtml m.name))
    <> ", "
    <> roleTitle m.role
    <> foldMap (\a -> ", " <> H.toHtml a) m.affiliation
    <> foldMap (\e -> " · " <> linkHtml ("mailto:" <> e) (H.toHtml e)) m.email
    <> foldMap (\o -> " · " <> orcidHtml o) m.orcid

orcidHtml :: Orcid -> Html
orcidHtml (Orcid o) =
  H.a ! A.class_ "orcid" ! A.href (H.textValue ("https://orcid.org/" <> o)) $ H.toHtml ("ORCID " <> o)

seminarsHtml :: Day -> [Seminar] -> Either String Html
seminarsHtml _ [] = pure placeholder
seminarsHtml today seminars = (<>) <$> block "Upcoming" (sortOn (.date) upcoming) <*> block "Past" (sortOn (Down . (.date)) past)
  where
    (upcoming, past) = partition ((>= today) . (.date)) seminars
    block _ [] = pure mempty
    block heading xs = (H.h3 heading <>) . listHtml <$> traverse seminar xs
    seminar :: Seminar -> Either String Html
    seminar s =
      inline s.topic <&> \topic ->
        dateHtml s.date
          <> (H.div ! A.class_ "entry-title" $ topic)
          <> (H.div ! A.class_ "entry-meta" $ maybe mempty H.toHtml s.speaker)

entriesHtml :: [Entry] -> Either String Html
entriesHtml entries = listHtml <$> traverse entry (sortOn (Down . (.date)) entries)
  where
    entry :: Entry -> Either String Html
    entry e = do
      t <- inline e.title
      v <- inline e.venue
      let meta = [H.toHtml (T.intercalate ", " e.authors) | not (null e.authors)] <> [v]
          links = catMaybes [("Link",) <$> e.url, ("DOI",) . ("https://doi.org/" <>) <$> e.doi, ("PDF",) <$> e.pdf]
      pure $
        dateHtml e.date
          <> (H.div ! A.class_ "entry-title" $ t)
          <> (H.div ! A.class_ "entry-meta" $ mconcat (intersperse " · " meta))
          <> linksHtml links
    linksHtml [] = mempty
    linksHtml ls = H.div ! A.class_ "entry-links" $ foldMap (\(label, u) -> linkHtml u label) ls

materialsHtml :: Compiler Html
materialsHtml = do
  items <- sortOn itemIdentifier <$> (loadAll materialsPattern :: Compiler [Item String])
  entries <- traverse material items
  orFail (listHtml <$> sequence entries)
  where
    material it = do
      let i = itemIdentifier it
      u <- maybe "/" (("/" <>) . (<> "/") . takeDirectory) <$> getRoute i
      m <- decodeWith (parseJSON @Material) i
      pure $ do
        d <- traverse inline m.description
        pure $
          (H.a ! A.class_ "entry-title" ! A.href (H.stringValue u) $ H.toHtml m.title)
            <> foldMap (H.div ! A.class_ "entry-meta") d
