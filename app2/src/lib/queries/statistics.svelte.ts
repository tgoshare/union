import { dailyPackets, dailyTransfers, statistics } from "$lib/stores/statistics.svelte"
import { createQueryGraphql } from "$lib/utils/queries"
import { DailyTransfers, Statistics } from "@unionlabs/sdk/schema"
import { Option, Schema, Struct } from "effect"
import { graphql } from "gql.tada"

export const statisticsQuery = createQueryGraphql({
  schema: Schema.Struct({ v2_stats_count: Statistics }),
  document: graphql(`
      query StatsQuery @cached(ttl: 1) {
        v2_stats_count {
          name
          value
        }
      }
    `),
  variables: {},
  refetchInterval: "1 second",
  writeData: data => {
    statistics.data = data.pipe(Option.map(d => d.v2_stats_count))
  },
  writeError: error => {
    statistics.error = error
  },
})

export const dailyTransfersQuery = (limit = 60) =>
  createQueryGraphql({
    schema: Schema.Struct({ v2_stats_transfers_daily_count: DailyTransfers }),
    document: graphql(`
      query TransfersPerDay($limit: Int!) @cached(ttl: 60) {
        v2_stats_transfers_daily_count(args: { p_days_back: $limit }) {
          count
          day_date
        }
      }
    `),
    variables: { limit },
    refetchInterval: "60 seconds",
    writeData: data => {
      // Only show testnet 10 transfers
      dailyTransfers.data = data.pipe(
        Option.map(Struct.get("v2_stats_transfers_daily_count")),
      )
    },
    writeError: error => {
      dailyTransfers.error = error
    },
  })

export const dailyPacketsQuery = (limit = 60) =>
  createQueryGraphql({
    schema: Schema.Struct({ v2_stats_packets_daily_count: DailyTransfers }),
    document: graphql(`
      query PacketsPerDay($limit: Int!) @cached(ttl: 60) {
        v2_stats_packets_daily_count(args: { p_days_back: $limit }) {
          count
          day_date
        }
      }
    `),
    variables: { limit },
    refetchInterval: "60 seconds",
    writeData: data => {
      dailyPackets.data = data.pipe(
        Option.map(Struct.get("v2_stats_packets_daily_count")),
      )
    },
    writeError: error => {
      dailyPackets.error = error
    },
  })
