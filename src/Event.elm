module Event exposing (..)

{-| Types based on:
<https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html#request-event-fields>
-}


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
    --, headers : List ( String, List Header )
    --, method : String -- TODO: Type
    --, querystring : Maybe String
    , uri : String
    }


type alias CFConfigResponse =
    { -- config : Config,
      request : Request
    }


type alias CloudFront =
    { cf : CFConfigResponse }


type alias Event =
    { records : List CloudFront }
