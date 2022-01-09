module CloudWorker.AWS exposing (..)

{-| Types based on:
<https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html#request-event-fields>
-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, Error)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode


type alias Config =
    { distributionDomainName : String
    , distributionId : String
    , eventType : String
    , requestId : String
    }


type alias Header =
    { key : String, value : String }


type alias Request =
    { clientIp : String
    , headers : Dict.Dict String (List Header)
    , method : String
    , querystring : Maybe String
    , uri : String
    }


type alias Response =
    { status : String
    , statusDescription : String
    , body : String
    }


type alias CFConfigResponse =
    { -- config : Config,
      request : Request
    }


type alias CloudFront =
    { cf : CFConfigResponse }


type alias Event =
    { records : List CloudFront }


decodeHeader : Decoder Header
decodeHeader =
    Decode.succeed Header
        |> Decode.required "key" Decode.string
        |> Decode.required "value" Decode.string


decodeRequest : Decoder Request
decodeRequest =
    Decode.succeed Request
        |> Decode.required "clientIp" Decode.string
        |> Decode.required "headers" (Decode.dict (Decode.list decodeHeader))
        |> Decode.required "method" Decode.string
        |> Decode.required "querystring" (Decode.maybe Decode.string)
        |> Decode.required "uri" Decode.string


decodeCloudFront : Decoder CloudFront
decodeCloudFront =
    Decode.succeed CloudFront
        |> Decode.required "cf"
            (Decode.succeed CFConfigResponse
                |> Decode.required "request" decodeRequest
            )


decodeEvent : Decoder Event
decodeEvent =
    Decode.succeed Event
        |> Decode.required "Records"
            (Decode.list decodeCloudFront)



-- TODO:  not the best name


type Output
    = Res Response
    | Req Request


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
