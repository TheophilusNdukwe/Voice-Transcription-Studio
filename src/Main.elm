
-- src/Main.elm
port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Encode as Encode
import Dict exposing (Dict)
import Time
import Task
import Set exposing (Set)

-- MAIN
main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }

-- MODEL
type alias Model =
    { transcription : String
    , isRecording : Bool
    , wordCount : Int
    , duration : Int
    , wordFrequency : Dict String Int
    , status : Status
    , fillerCount : Int
    , fillerWords : List String
    , fillerPercentage : Float
    }

type Status
    = Ready
    | Recording | Error String

init : () -> (Model, Cmd Msg)
init _ =
    ( { transcription = ""
      , isRecording = False
      , wordCount = 0
      , duration = 0
      , wordFrequency = Dict.empty
      , status = Ready
      , fillerCount = 0
      , fillerWords = []
      , fillerPercentage = 0.0
      }
    , Cmd.none
    )

-- UPDATE
type Msg
    = StartRecording
    | StopRecording
    | TranscriptionReceived String
    | ClearTranscription
    | Tick Time.Posix
    | RecordingError String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        StartRecording ->
            ( { model | isRecording = True, status = Recording }
            , startRecording ()
            )

        StopRecording ->
            ( { model | isRecording = False, status = Ready }
            , stopRecording ()
            )

        TranscriptionReceived text ->
            let
                newTranscription = 
                    if model.transcription == "" then
                        text
                    else
                        model.transcription ++ " " ++ text
                        
                words = String.words newTranscription
                wordFreq = calculateWordFrequency words
                
                -- filler detection
                (fillerCount, fillerWordsList) = detectFillers newTranscription
                fillerPercentage = 
                    if List.length words > 0 then 
                        toFloat fillerCount / toFloat (List.length words) * 100
                    else
                        0.0
            in
            ( { model 
                | transcription = newTranscription
                , wordCount = List.length words
                , wordFrequency = wordFreq
                , fillerCount = fillerCount
                , fillerWords = fillerWordsList
                , fillerPercentage = fillerPercentage
              }
            , Cmd.none
            )

        ClearTranscription ->
            ( { model 
                | transcription = ""
                , wordCount = 0
                , duration = 0
                , wordFrequency = Dict.empty
                , fillerCount = 0
                , fillerWords = []
                , fillerPercentage = 0.0
              }
            , Cmd.none
            )

        Tick _ ->
            if model.isRecording then
                ( { model | duration = model.duration + 1 }, Cmd.none )
            else
                ( model, Cmd.none )

        RecordingError error ->
            ( { model | status = Error error, isRecording = False }
            , stopRecording ()
            )

calculateWordFrequency : List String -> Dict String Int
calculateWordFrequency words =
    let
        addWord word dict =
            Dict.update 
                (String.toLower word) 
                (\maybeCount -> 
                    case maybeCount of
                        Just count -> Just (count + 1)
                        Nothing -> Just 1
                ) 
                dict
    in
    List.foldl addWord Dict.empty words

removeDuplicates : List String -> List String
removeDuplicates list =
    let
        helper item acc =
            if List.member item acc then
                acc
            else
                item :: acc
    in
    List.foldl helper [] list
        |> List.reverse

-- VIEW
view : Model -> Html Msg
view model =
    div []
        [ statusIndicator model
        , div [ class "controls" ]
            [ recordButton model
            , button [ class "clear-btn", onClick ClearTranscription ] 
                [ text "Clear" ]
            ]
        , div [ class "transcription-area" ] 
            [ text model.transcription ]
        , statsView model
        , wordCloudView model
        , fillerWordsView model
        ]

statusIndicator : Model -> Html msg
statusIndicator model =
    div [ class "status-indicator" ]
        [ div [ class ("status-dot" ++ if model.isRecording then " active" else "") ] []
        , text (statusText model.status)
        ]

statusText : Status -> String
statusText status =
    case status of
        Ready -> "Ready to record"
        Recording -> "Recording..."
        Error err -> "Error: " ++ err

recordButton : Model -> Html Msg
recordButton model =
    button 
        [ class ("record-btn" ++ if model.isRecording then " recording" else "")
        , onClick (if model.isRecording then StopRecording else StartRecording)
        ] 
        [ text (if model.isRecording then "Stop Recording" else "Start Recording") ]

statsView : Model -> Html msg
statsView model =
    div [ class "stats-grid" ]
        [ statCard "Words" (String.fromInt model.wordCount)
        , statCard "Duration" (formatDuration model.duration)
        , statCard "Words/Min" (calculateWPM model)
        , statCard "Filler Words" (String.fromInt model.fillerCount)
        , statCard "Filler %" (formatPercentage model.fillerPercentage)
        ]

statCard : String -> String -> Html msg
statCard label value =
    div [ class "stat-card" ]
        [ div [ class "stat-value" ] [ text value ]
        , div [ class "stat-label" ] [ text label ]
        ]

formatDuration : Int -> String
formatDuration seconds =
    let
        mins = seconds // 60
        secs = remainderBy 60 seconds
    in
    String.fromInt mins ++ ":" ++ String.padLeft 2 '0' (String.fromInt secs)

calculateWPM : Model -> String
calculateWPM model =
    if model.duration > 0 then
        String.fromInt (model.wordCount * 60 // model.duration)
    else
        "0"
formatPercentage : Float -> String
formatPercentage pct = 
    String.fromFloat (toFloat(round (pct * 10)) / 10) ++ "%"

wordCloudView : Model -> Html msg
wordCloudView model =
    let
        topWords = 
            model.wordFrequency
                |> Dict.toList
                |> List.sortBy (\(_, count) -> -count)
                |> List.take 10
    in
    if List.isEmpty topWords then
        text ""
    else
        div [ class "word-cloud" ]
            [ h3 [] [ text "Most Frequent Words" ]
            , div [] (List.map wordItem topWords)
            ]

wordItem : (String, Int) -> Html msg
wordItem (word, count) =
    span [ class "word-item" ] 
        [ text (word ++ " (" ++ String.fromInt count ++ ")") ]
fillerWordsView : Model -> Html msg
fillerWordsView model = 
    if List.isEmpty model.fillerWords then
        text ""
    else
        div [ class "filler-words-section"]
        [h3 [] [text "Filler Words Detected"]
        , div [class "filler-pills"]
            (model.fillerWords
            |> List.sort
            |> removeDuplicates -- Remove duplicates
            |> List.map (\word ->
                span [ class "filler-pill" ] [text word ]
                )
            )
        ]

fillerWords : Set String
fillerWords = Set.fromList
    [ "um", "uh", "umm", "uhh", "er", "err", "ah", "ahh"
    , "like", "basically", "actually", "literally"
    , "anyway", "anyways", "whatever", "totally"
    , "obviously", "seriously", "honestly" ]

fillerPhrases : List String
fillerPhrases = 
    [ "you know", "sort of", "kind of", "i mean"
    , "you see", "so yeah", "you know what"
    , "at the end of the day", "to be honest"
    , "to be fair", "i guess", "or something"
    , "and stuff", "and things", "or whatever"
    , "you know what i mean", "if that makes sense"
    , "does that make sense" ]

-- Helper function to count non-overlapping occurrences of a phrase
countPhraseOccurrences : String -> String -> Int
countPhraseOccurrences phrase text =
    let
        phraseLength = String.length phrase
        
        countHelper : Int -> Int -> Int
        countHelper index count =
            case String.indexes phrase (String.dropLeft index text) of
                [] -> 
                    count
                firstIndex :: _ ->
                    countHelper (index + firstIndex + phraseLength) (count + 1)
    in
    countHelper 0 0

-- Helper to check if a character is a word boundary
isWordBoundary : Maybe Char -> Bool
isWordBoundary maybeChar =
    case maybeChar of
        Nothing -> True
        Just char -> not (Char.isAlphaNum char)

-- Simplified and more reliable filler detection
detectFillers : String -> (Int, List String)
detectFillers text = 
    let 
        lowerText = String.toLower text
        
        -- Extract single words with proper tokenization
        words = 
            lowerText
                |> String.words
                |> List.map (String.filter Char.isAlpha) -- Remove punctuation
                |> List.filter (not << String.isEmpty)
        
        -- Count single-word fillers (most common case)
        singleWordFillers = 
            words
                |> List.filter (\w -> Set.member w fillerWords)
        
        -- Simple phrase detection for common phrases
        detectSimplePhrase : String -> List String
        detectSimplePhrase phrase =
            let
                phraseWords = String.words phrase
                phraseLength = List.length phraseWords
                
                -- Check if phrase appears at position i in word list
                checkAt : Int -> Bool
                checkAt i =
                    if i + phraseLength > List.length words then
                        False
                    else
                        let
                            slice = List.drop i words |> List.take phraseLength
                        in
                        slice == phraseWords
                
                -- Find all positions where phrase occurs
                positions = 
                    List.range 0 (List.length words - phraseLength)
                        |> List.filter checkAt
            in
            List.repeat (List.length positions) phrase
        
        -- Detect common phrase fillers
        phraseFillers = 
            [ "you know", "i mean", "kind of", "sort of" ]
                |> List.concatMap detectSimplePhrase
        
        -- Combine all detected fillers
        allFillers = singleWordFillers ++ phraseFillers
        totalCount = List.length allFillers
    in 
    (totalCount, allFillers)

-- Additional helper: Get filler density (fillers per 100 words)
getFillerDensity : Model -> Float
getFillerDensity model =
    if model.wordCount > 0 then
        (toFloat model.fillerCount / toFloat model.wordCount) * 100
    else
        0.0

-- Additional helper: Get most common fillers
getMostCommonFillers : List String -> List (String, Int)
getMostCommonFillers fillers =
    fillers
        |> List.foldl (\filler acc ->
            Dict.update filler
                (\maybeCount ->
                    case maybeCount of
                        Just count -> Just (count + 1)
                        Nothing -> Just 1
                )
                acc
        ) Dict.empty
        |> Dict.toList
        |> List.sortBy (\(_, count) -> -count)
        |> List.take 5

-- Additional feature: Detect filler patterns
type FillerPattern
    = StartingFiller  -- Filler at the beginning of speech
    | RepetitiveFiller -- Same filler used multiple times in succession
    | TransitionFiller -- Filler between topic changes

detectFillerPatterns : String -> List String -> List FillerPattern
detectFillerPatterns transcription fillers =
    let
        sentences = String.split "." transcription
        patterns = []
        
        -- Check if transcription starts with a filler
        startsWithFiller =
            case List.head sentences of
                Just firstSentence ->
                    List.any (\filler -> 
                        String.startsWith filler (String.toLower (String.trim firstSentence))
                    ) (fillerWords |> Set.toList)
                Nothing ->
                    False
                    
        startPattern = 
            if startsWithFiller then [StartingFiller] else []
    in
    startPattern ++ patterns
-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ transcriptionReceived TranscriptionReceived
        , recordingError RecordingError
        , if model.isRecording then
            Time.every 1000 Tick
          else
            Sub.none
        ]

-- PORTS
port startRecording : () -> Cmd msg
port stopRecording : () -> Cmd msg
port transcriptionReceived : (String -> msg) -> Sub msg
port recordingError : (String -> msg) -> Sub msg