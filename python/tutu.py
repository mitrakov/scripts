#!/usr/bin/env python3
import json
import sys

"""
# Helps to find tickets from https://tutu.ru

curl 'https://offers-api.tutu.ru/railway/offers' --compressed --data-raw '{
  "routes": [{"departureStationCode": "2000000", "arrivalStationCode": "2004000", "departureDate": "2026-07-24"}],
  "source": "trainOffers"
}' | tutu.py
"""

def format_duration(minutes):
    """Transforms raw minutes into a human-readable Xh Ym format."""
    if not minutes:
        return "N/A"
    hours = minutes // 60
    mins = minutes % 60
    return f"{hours}h {mins:02d}m"

def parse_tutu_payload(root_node):
    """
    Dynamic tree search that traverses all extracted dictionaries 
    and resolves relational identifiers down to vehicle names and durations.
    """
    fare_apps = {}
    segments = {}
    voyages = {}
    conditions = {}
    vehicles = {}
    actual_offers = {}

    payload_list = root_node if isinstance(root_node, list) else [root_node]

    for block in payload_list:
        if not isinstance(block, dict):
            continue

        dictionary = block.get("dictionary", {})
        common = dictionary.get("common", {})

        fare_apps.update(common.get("fareApplications", {}))
        segments.update(common.get("segments", {}))

        train_node = dictionary.get("train", {})
        voyages.update(train_node.get("voyages", {}))
        conditions.update(train_node.get("conditions", {}))
        vehicles.update(train_node.get("vehicles", {}))

        offers = block.get("offers", {})
        actual_offers.update(offers.get("actual", {}))

    compressed_tickets = {}

    for offer_id, offer_info in actual_offers.items():
        variants = offer_info.get("offerVariants", [])
        for variant in variants:
            price_node = variant.get("price", {}).get("value", {})
            if not price_node:
                continue

            amount = price_node.get("amount", 0)
            fraction = price_node.get("fraction", 100)
            currency = price_node.get("currencyCode", "RUB")
            real_price = amount / fraction

            train_num = "Unknown"
            departure_time = "N/A"
            car_type = "Standard"
            brand_name = ""
            raw_duration = 0

            variant_fare_apps = variant.get("fareApplications", {})

            for app_key in variant_fare_apps.keys():
                lookup_keys = [app_key]
                if isinstance(variant_fare_apps[app_key], list):
                    lookup_keys.extend(variant_fare_apps[app_key])

                for key in lookup_keys:
                    if key in fare_apps:
                        app_meta = fare_apps[key]
                        seg_hash = app_meta.get("segmentHash")
                        cond_hash = app_meta.get("segmentConditions")

                        if seg_hash in segments:
                            segment_node = segments[seg_hash]
                            raw_dep = segment_node.get("departureDateTime", "")
                            if "T" in raw_dep:
                                departure_time = raw_dep.split("T")[-1][:5]

                            raw_duration = segment_node.get("duration", 0)

                            voyage_num = segment_node.get("voyageNumber")
                            if voyage_num in voyages:
                                train_num = voyages[voyage_num].get("numberForPassengers", "Unknown")

                            veh_id = segment_node.get("vehicleId")
                            if veh_id in vehicles:
                                brand_name = vehicles[veh_id].get("name", "")

                        if cond_hash in conditions:
                            car_type = conditions[cond_hash].get("carType", "Standard")

            group_key = (departure_time, train_num, car_type)

            if group_key not in compressed_tickets or real_price < compressed_tickets[group_key]["price"]:
                compressed_tickets[group_key] = {
                    "departure": departure_time,
                    "train": train_num,
                    "type": car_type,
                    "brand": brand_name if brand_name else "Regular Train",
                    "duration": format_duration(raw_duration),
                    "price": real_price,
                    "currency": currency
                }

    return list(compressed_tickets.values())

def main():
    input_data = sys.stdin.read()
    if not input_data.strip():
        sys.stderr.write("❌ Error: Standard input stream was empty.\n")
        sys.exit(1)

    try:
        raw_json = json.loads(input_data)
    except json.JSONDecodeError as e:
        sys.stderr.write(f"❌ Error: Input stream was not valid JSON: {e}\n")
        sys.exit(1)

    tickets = parse_tutu_payload(raw_json)

    if not tickets:
        print("❌ No matching ticket outputs recovered from parsed arrays.")
        return

    # 1. Fixed Sorting Hierarchy: Time ASC -> Train ID ASC -> Price ASC
    tickets.sort(key=lambda x: (x["departure"], x["train"], x["price"]))

    # Grid Separator Template
    grid_delimiter = "--------------------------------------------------------------------------------------------------"

    # Print Clean Dashboard Header
    print("\n" + "=" * 105)
    print(f"MOSCOW ➔ ST. PETERSBURG")
    print("=" * 105)
    print(f"{'DEPARTURE':<12} | {'TRAIN':<10} | {'TRAIN NAME':<22} | {'DURATION':<10} | {'SEAT CAR TYPE':<16} | {'MIN PRICE'}")
    print("-" * 105)

    # 2. Tracking Variables for Group Delimiters
    last_train_key = None

    for item in tickets:
        # Create a unique key combo for evaluating the train departure boundary
        current_train_key = (item["departure"], item["train"])

        # Inject the custom grid delimiter if we switch to a completely new train run
        if last_train_key is not None and current_train_key != last_train_key:
            print(grid_delimiter)

        last_train_key = current_train_key

        price_display = f"{item['price']:,.2f} {item['currency']}"
        print(f"{item['departure']:<12} | {item['train']:<10} | {item['brand']:<22} | {item['duration']:<10} | {item['type']:<16} | {price_display}")

    print("=" * 105)

if __name__ == "__main__":
    main()
