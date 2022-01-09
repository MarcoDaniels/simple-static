port module Main exposing (main)

import Event exposing (CFConfigResponse, CloudFront, Event, Request)
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode


port inputPort : (Decode.Value -> msg) -> Sub msg


port outputPort : Encode.Value -> Cmd msg


type alias Model =
    { event : Maybe Event }


type Msg
    = Incoming (Result Error Event)


type alias Response =
    { status : String
    , statusDescription : String
    , body : String
    }


type Output
    = Res Response
    | Req Request


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
                                    (encodeOutput
                                        (Res
                                            { status = "200"
                                            , statusDescription = "OK"
                                            , body =
                                                event.records
                                                    |> List.map (\{ cf } -> cf.request.clientIp)
                                                    |> String.concat
                                            }
                                        )
                                    )
                                )

                            Err _ ->
                                ( model, Cmd.none )
        , subscriptions = \_ -> inputPort (decodeEvent >> Incoming)
        }


encodeOutput : Output -> Encode.Value
encodeOutput out =
    case out of
        Res res ->
            Encode.object
                [ ( "status", Encode.string res.status )
                , ( "statusDescription", Encode.string res.statusDescription )
                , ( "body", Encode.string res.body )
                ]

        Req req ->
            Encode.object
                [ ( "clientIp", Encode.string req.clientIp )
                , ( "uri", Encode.string req.uri )
                ]


decodeEvent : Decode.Value -> Result Error Event
decodeEvent =
    Decode.decodeValue
        (Decode.map Event
            (Decode.field "Records"
                (Decode.list
                    (Decode.map CloudFront
                        (Decode.field "cf"
                            (Decode.map CFConfigResponse
                                (Decode.field "request"
                                    (Decode.map2 Request
                                        (Decode.field "clientIp" Decode.string)
                                        (Decode.field "uri" Decode.string)
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
