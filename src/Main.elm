port module Main exposing (main)

import CloudWorker.AWS exposing (Event, EventResult(..), decodeEvent, encodeEventResult)
import Dict
import Json.Decode as Decode exposing (Decoder, Error)
import Json.Encode as Encode


port inputPort : (Decode.Value -> msg) -> Sub msg


port outputPort : Encode.Value -> Cmd msg


type alias Model =
    { event : Maybe Event }


type Msg
    = Incoming (Result Error Event)


main : Program () Model Msg
main =
    Platform.worker
        { init = \_ -> ( { event = Nothing }, Cmd.none )
        , update =
            \msg model ->
                case msg of
                    Incoming result ->
                        case result of
                            Ok event ->
                                ( { model | event = Just event }
                                , outputPort
                                    (encodeEventResult
                                        (ResultRequest
                                            (event.records
                                                |> List.foldr
                                                    (\{ cf } modRequest ->
                                                        let
                                                            request =
                                                                cf.request
                                                        in
                                                        { request | headers = Dict.union modRequest.headers request.headers }
                                                    )
                                                    { clientIp = ""
                                                    , headers = Dict.insert "my-head" [ { key = "what", value = "hey" } ] Dict.empty
                                                    , method = ""
                                                    , querystring = Nothing
                                                    , uri = ""
                                                    }
                                            )
                                        )
                                    )
                                )

                            Err _ ->
                                ( model, Cmd.none )
        , subscriptions = \_ -> inputPort (Decode.decodeValue decodeEvent >> Incoming)
        }
