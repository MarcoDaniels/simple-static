const {handler} = require('./lambda')

const payload = {
    'Records': [
        {
            'cf': {
                'config': {
                    'distributionDomainName': 'd111111abcdef8.cloudfront.net',
                    'distributionId': 'EDFDVBD6EXAMPLE',
                    'eventType': 'origin-request',
                    'requestId': '4TyzHTaYWb1GX1qTfsHhEqV6HUDd_BzoBZnwfnvQc_1oF26ClkoUSEQ=='
                },
                'request': {
                    'clientIp': '203.0.113.178',
                    'headers': {
                        'user-agent': [
                            {
                                'key': 'User-Agent',
                                'value': 'Amazon CloudFront'
                            }
                        ],
                        'cache-control': [
                            {
                                'key': 'Cache-Control',
                                'value': 'no-cache, cf-no-cache'
                            }
                        ]
                    },
                    'method': 'GET',
                    'querystring': '',
                    'uri': '/'
                }
            }
        }
    ]
}

logJSON = (_, content) =>
    console.log(JSON.stringify(content, null, 4))

handler(payload, '', logJSON)