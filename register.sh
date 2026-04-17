#!/bin/bash
# o código carrier 2151 corresponde aos correios do brasil 

curl -X POST \
    --header '17token:<token>' \
    --header 'Content-Type:application/json' \
    --data '[
              {
                "number": "<codigo-de-rastreio>",
                "carrier": 2151
              }
            ]' \
    https://api.17track.net/track/v2.4/register
