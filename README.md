# BI Project

## Dataset

This project uses **NYC TLC Yellow Taxi Trip Record Data** for the period **January 2022 through December 2023**, inclusive (24 monthly files). Use this same date range consistently for the Phase 1 data profiling and dimensional-modeling work, and for later project phases unless the team formally revises the scope.

The data is published by the NYC Taxi & Limousine Commission (TLC):

- [TLC Trip Record Data: download page](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)

Download the **Yellow Taxi** monthly Parquet files for `2022-01` through `2023-12`. Do not substitute Green Taxi, FHV, or High Volume FHV files. The TLC page also provides the taxi-zone lookup and zone shapefile used to interpret pickup and drop-off location IDs.

### Local folder layout

Keep downloaded data under `dataset/` (this directory is excluded from Git):

```text
dataset/
├── trip_data/
│   ├── yellow_tripdata_2022-01.parquet
│   ├── ...
│   └── yellow_tripdata_2023-12.parquet
└── taxi_zones/
    └── ...
```

The monthly trip files are intentionally not committed because the raw dataset is large and can be downloaded again from the TLC source. PDF documents, including the project brief, are also excluded from Git.
