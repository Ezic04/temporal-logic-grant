module Language exposing
    ( I18n
    , Language(..)
    , defaultLanguage
    , formatDate
    , fromString
    , supportedLanguages
    , t
    , toString
    )

{-| Minimal internationalization (i18n) module supporting Polish (Pl) and English (En).

To drop a language in the future:

1.  Set `defaultLanguage` to your preferred single language (e.g. `En` or `Pl`).
2.  Set `supportedLanguages` to contain only that language (e.g. `[ En ]` or `[ Pl ]`).
    This automatically hides the language switcher in the header.
3.  Update `t` to always return that language.

-}


type Language
    = Pl
    | En


defaultLanguage : Language
defaultLanguage =
    Pl


supportedLanguages : List Language
supportedLanguages =
    [ Pl, En ]


type alias I18n a =
    { pl : a
    , en : a
    }


t : Language -> I18n a -> a
t lang translations =
    case lang of
        Pl ->
            translations.pl

        En ->
            translations.en


toString : Language -> String
toString lang =
    case lang of
        Pl ->
            "pl"

        En ->
            "en"


fromString : String -> Language
fromString str =
    case String.toLower str of
        "en" ->
            En

        _ ->
            Pl


{-| Formats an ISO-8601 date string (YYYY-MM-DD) into a localized, human-friendly format.
Example:

  - PL: "9 października 2026"
  - EN: "October 9, 2026"

-}
formatDate : Language -> String -> String
formatDate lang isoDate =
    case String.split "-" isoDate of
        [ year, monthStr, dayStr ] ->
            let
                dayInt =
                    String.toInt dayStr |> Maybe.withDefault 0

                dayClean =
                    String.fromInt dayInt

                monthName =
                    case monthStr of
                        "01" ->
                            { pl = "stycznia", en = "January" }

                        "02" ->
                            { pl = "lutego", en = "February" }

                        "03" ->
                            { pl = "marca", en = "March" }

                        "04" ->
                            { pl = "kwietnia", en = "April" }

                        "05" ->
                            { pl = "maja", en = "May" }

                        "06" ->
                            { pl = "czerwca", en = "June" }

                        "07" ->
                            { pl = "lipca", en = "July" }

                        "08" ->
                            { pl = "sierpnia", en = "August" }

                        "09" ->
                            { pl = "września", en = "September" }

                        "10" ->
                            { pl = "października", en = "October" }

                        "11" ->
                            { pl = "listopada", en = "November" }

                        "12" ->
                            { pl = "grudnia", en = "December" }

                        _ ->
                            { pl = monthStr, en = monthStr }
            in
            case lang of
                Pl ->
                    dayClean ++ " " ++ monthName.pl ++ " " ++ year

                En ->
                    monthName.en ++ " " ++ dayClean ++ ", " ++ year

        _ ->
            isoDate
