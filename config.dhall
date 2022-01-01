let Project
    : Type
    = { name : Text, description : Text }

let AWS
    : Type
    = { bucketPrefix : Text, region : Text, accessKey : Text, secretKey : Text }

let projectConfig
    : Project
    = { name = "simple-static", description = "Simple Static AWS" }

let awsConfig
    : AWS
    = { bucketPrefix = "${projectConfig.name}-"
      , region = env:AWS_DEFAULT_REGION as Text
      , accessKey = env:AWS_ACCESS_KEY_ID as Text
      , secretKey = env:AWS_SECRET_ACCESS_KEY as Text
      }

in  { project = projectConfig, aws = awsConfig }
