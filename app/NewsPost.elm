module NewsPost exposing (Metadata, formatDate, metadataDecoder)

import Json.Decode as Decode exposing (Decoder)


type alias Metadata =
    { date : String
    , title : String
    , description : String
    }


metadataDecoder : Decoder Metadata
metadataDecoder =
    Decode.map3 Metadata
        (Decode.field "date" Decode.string)
        (fieldWithDefault "title" "Untitled")
        (fieldWithDefault "description" "")


fieldWithDefault : String -> String -> Decoder String
fieldWithDefault name default =
    Decode.oneOf
        [ Decode.field name Decode.string
        , Decode.succeed default
        ]


formatDate : String -> String
formatDate isoDate =
    case String.split "-" isoDate of
        [ year, month, day ] ->
            monthName month
                ++ " "
                ++ (String.toInt day |> Maybe.withDefault 0 |> String.fromInt)
                ++ ", "
                ++ year

        _ ->
            isoDate


monthName : String -> String
monthName month =
    case month of
        "01" ->
            "January"

        "02" ->
            "February"

        "03" ->
            "March"

        "04" ->
            "April"

        "05" ->
            "May"

        "06" ->
            "June"

        "07" ->
            "July"

        "08" ->
            "August"

        "09" ->
            "September"

        "10" ->
            "October"

        "11" ->
            "November"

        "12" ->
            "December"

        _ ->
            month
