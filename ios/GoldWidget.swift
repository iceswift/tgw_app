import WidgetKit
import SwiftUI
import Intents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), priceBuy: "43,000", priceSell: "43,100", change: "+50", updateTime: "10:00")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), priceBuy: "43,000", priceSell: "43,100", change: "+50", updateTime: "10:00")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.gold_app_group")
        let priceBuy = userDefaults?.string(forKey: "price_buy") ?? "--"
        let priceSell = userDefaults?.string(forKey: "price_sell") ?? "--"
        let change = userDefaults?.string(forKey: "change") ?? "--"
        let updateTime = userDefaults?.string(forKey: "date") ?? "--:--"

        let entry = SimpleEntry(date: Date(), priceBuy: priceBuy, priceSell: priceSell, change: change, updateTime: updateTime)

        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let priceBuy: String
    let priceSell: String
    let change: String
    let updateTime: String
}

struct GoldWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Gold Price")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0)) // Gold color
                Spacer()
                Text(entry.updateTime)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            HStack {
                Text("Buy")
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text(entry.priceBuy)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            }
            
            HStack {
                Text("Sell")
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text(entry.priceSell)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            }
            
            HStack {
                Text("Change")
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text(entry.change)
                    .font(.footnote)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color(red: 0.12, green: 0.12, blue: 0.12)) // Dark background
    }
}

@main
struct GoldWidget: Widget {
    let kind: String = "GoldWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GoldWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Gold Price Widget")
        .description("Shows the latest gold prices.")
        .supportedFamilies([.systemSmall])
    }
}
