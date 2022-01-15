module Main exposing (main)

import CloudWorker.AWS exposing (Event, EventResult(..))
import CloudWorker.CloudWorker exposing (cloudWorker)
import Dict


main : Program () CloudWorker.CloudWorker.Model CloudWorker.CloudWorker.Msg
main =
    cloudWorker
        (\event ->
            ResultRequest
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
