#!/usr/bin/env bash
# cron example every 2h (except night): 0 8-22/2 * * * /root/firebase/aviasales.sh
set -euo pipefail

iphone=doNlx3yunEdpkWca-e3Q7a:APA91bE1ATqZDTuRbl9PMSSgv4tscV_aOZ0K6gBTCItPhBwj2vYznS8dPxxgjWuh4AXKnCTfeXWJS7WLwVxdrAFXrQVtpn7P-6aBpmC2EuZK2mUmT8sWuhc

resp=`curl 'https://ariadne.aviasales.ru/api/gql' \
--header 'Content-Type: application/json' \
--data '{
   "operation_name" : "price_chart",
   "query" : "query GetPriceChartV3($brand: Brand!,$input: PriceChartV3Input!,) {price_chart_v3(input: $input\nbrand: $brand) {prices {price {value\ndepart_date\nreturn_date}\nstats {\ndepart_value\nreturn_value}}}}",
   "variables" : {
      "brand" : "AS",
      "input" : {
         "origin_city_iata" : "LED",
         "destination_city_iata" : "HKT",
         "one_way" : true,
         "dates" : {
            "depart_date_from" : "2025-12-27",
            "depart_date_to" : "2026-01-05",
            "return_date_from" : "2026-01-08",
            "return_date_to" : "2026-01-08"
         },
         "filters" : {
            "direct" : true,
            "convenient" : true,
            "with_baggage" : false
         },
         "market" : "ru",
         "currency" : "rub",
         "trip_class" : "Y"
      }
   }
}
'`

# -c = compact
json=`echo $resp | jq -c '.data.price_chart_v3.prices.[].price | {date: .depart_date, rub: .value}'`

java -jar /root/firebase/tommypush.jar /root/firebase/firebase.json "Tommy Phuket Script" "$json" "$iphone"
