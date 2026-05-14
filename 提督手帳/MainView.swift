import SwiftUI

struct LedgerShip: Identifiable, Codable {
    var id: String { name }
    let name: String
    let level: Int
    let shipType: String
}

struct LedgerItem: Identifiable, Codable {
    var id: String { name }
    let name: String
    let category: String
    let improvement: Int
}

struct MainView: View {
    let items: [LedgerItem] = [
        LedgerItem(
            name: "烈風改二",
            category: "艦上戦闘機",
            improvement: 10
        ),
        LedgerItem(
            name: "61cm五連装酸素魚雷",
            category: "魚雷",
            improvement: 6
        )
    ]
    
    @State private var ships: [LedgerShip] = [
        LedgerShip(name: "赤城改二", level: 99, shipType: "正規空母"),
        LedgerShip(name: "時雨改三", level: 88, shipType: "駆逐艦"),
        LedgerShip(name: "北上改二", level: 95, shipType: "軽巡洋艦")
    ]

    func loadShips() {

        guard let url = Bundle.main.url(
            forResource: "ships",
            withExtension: "json"
        ) else {
            print("ships.json not found")
            ships = [
                LedgerShip(name: "JSONが見つかりません", level: 0, shipType: "エラー")
            ]
            return
        }

        do {
            let data = try Data(contentsOf: url)

            let decoded = try JSONDecoder().decode(
                [LedgerShip].self,
                from: data
            )

            ships = decoded

        } catch {
            print(error)
            ships = [
                LedgerShip(name: "JSON読込エラー", level: 0, shipType: "\(error)")
            ]
        }
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                List(ships) { ship in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ship.name)
                            .font(.headline)

                        Text("\(ship.shipType) / Lv.\(ship.level)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("艦娘")
            }
            .tabItem {
                Label("艦娘", systemImage: "person.3")
            }

            NavigationStack {
                List(items) { item in
                    VStack(alignment: .leading, spacing: 4) {

                        Text(item.name)
                            .font(.headline)

                        Text("\(item.category) / ★\(item.improvement)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("装備")
            }
            .tabItem {
                Label("装備", systemImage: "shippingbox")
            }

            NavigationStack {
                List {
                    Text("燃料 250000")
                    Text("弾薬 240000")
                    Text("鋼材 300000")
                    Text("ボーキサイト 180000")
                }
                .navigationTitle("資材")
            }
            .tabItem {
                Label("資材", systemImage: "tray.full")
            }
        }
        .onAppear {
            loadShips()
        }
    }
}

#Preview {
    MainView()
}
