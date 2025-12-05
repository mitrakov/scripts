#!/bin/bash
# cron example every 3h (except night): 0 10-23/3 * * * /Users/director/workspace/scripts/bash/aviasales.sh

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
            "depart_date_from" : "2025-12-31",
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

java -jar /Users/director/software/tommypush.jar /Users/director/software/firebase.json "Tommy Phuket Script" "$json" fp_SZm2UPEZzj1yBihN5KN:APA91bF16zMlXvnwGvrch-tVOVqz8-EgLAqv33eBxeHJCLiTB6PjY4rj4W9lGZvBYRSEU-1Ea2ew4lB14lVmgRUGQw5SVY7iFlrRf1zCfoNPLym__eR71EE
