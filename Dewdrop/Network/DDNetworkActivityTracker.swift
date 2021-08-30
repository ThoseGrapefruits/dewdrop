//
//  DDNetworkActivityTracker.swift
//  DDNetworkActivityTracker
//
//  Created by Logan Moore on 2021-08-29.
//

import Foundation
import GameKit

struct TimeSeriesEntry {
  internal init(bytes: Int) {
    self.datetime = Date()
    self.bytes = bytes
  }

  let datetime: Date
  let bytes: Int
}

struct TimeSeriesStats {
  var meanBytes: Float
  var medianBytes: Int
  var count: Int
  var largest: Int
}

typealias TimeSeries = [ TimeSeriesEntry ]
typealias TimeSeriesView = ArraySlice<TimeSeriesEntry>

extension TimeSeriesView {
  func getStats() -> TimeSeriesStats {
    let sortedByBytes = sorted { e1, e2 in e1.bytes < e2.bytes }
    return TimeSeriesStats(
      meanBytes: count == 0
        ? Float.zero
        : Float(reduce(0, { acc, entry in acc + entry.bytes })) / Float(count),
      medianBytes: count == 0
        ? Int.zero
        : sortedByBytes[sortedByBytes.count / 2].bytes,
      count: count,
      largest: sortedByBytes.last?.bytes ?? 0)
  }
}

class DDNetworkActivityTracker {

  private var received: TimeSeries = []
  private var sent:     TimeSeries = []

  // MARK: Recording

  func recordReceive(data: Data) {
    received.append(TimeSeriesEntry(bytes: data.count))
  }

  func recordSend(data: Data, to recipients: [GKPlayer]) {
    for _ in recipients {
      sent.append(TimeSeriesEntry(bytes: data.count))
    }
  }

  // MARK: Querying

  func getReceivedWithin(interval: DateInterval) -> TimeSeriesView {
    return getWithin(interval: interval, timeSeries: received)
  }

  func getReceivedWithinLast(seconds: TimeInterval) -> TimeSeriesView {
    return getWithinLast(seconds: seconds, timeSeries: received)
  }

  func getSentWithin(interval: DateInterval) -> TimeSeriesView {
    return getWithin(interval: interval, timeSeries: sent)
  }

  func getSentWithinLast(seconds: TimeInterval) -> TimeSeriesView {
    return getWithinLast(seconds: seconds, timeSeries: sent)
  }

  // MARK: Querying helpers

  private func getWithinLast(
    seconds: TimeInterval,
    timeSeries: TimeSeries
  ) -> TimeSeriesView {
    let now = Date()
    let target = now.addingTimeInterval(-seconds)
    let interval = DateInterval(start: target, end: now)

    return getWithin(interval: interval, timeSeries: timeSeries)
  }

  private func getWithin(
    interval: DateInterval,
    timeSeries: TimeSeries
  ) -> TimeSeriesView {
    let result: TimeSeriesView = timeSeries
      .reversed()
      .drop(while: { entry in !interval.contains(entry.datetime) })
      .reversed()
      .drop(while: { entry in !interval.contains(entry.datetime) })

    cleanup()

    return result
  }

  // MARK: Util

  private func cleanup() {
    let oneMinuteAgo = Date().addingTimeInterval(-60)

    for var timeSeries in [ received, sent ] {
      while let datetime = timeSeries.first?.datetime, datetime < oneMinuteAgo {
        timeSeries.removeFirst()
      }
    }
  }
}
