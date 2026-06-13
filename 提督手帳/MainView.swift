import SwiftUI
import UniformTypeIdentifiers

struct LedgerShip: Identifiable, Codable {
    var id: String { name }
    let name: String
    let level: Int
    let shipType: String
    let sortNumber: Int
}

struct LedgerItem: Identifiable, Codable {
    var id: String { "\(category)-\(name)-\(improvement)-\(typeOrder)" }
    let name: String
    let category: String
    let improvement: Int
    let typeOrder: Int
}

struct LedgerMaterial: Identifiable, Codable {
    var id: String { name }
    let name: String
    let amount: Int
}

struct LedgerUseItem: Identifiable, Codable {
    var id: String { name }
    let name: String
    let amount: Int
}

struct LedgerPayItem: Identifiable, Codable {
    var id: String { name }
    let name: String
    let amount: Int
}

enum ShipSortMode: String, CaseIterable, Identifiable {
    case level = "Lv順"
    case sortNumber = "艦番号順"
    case type = "艦種順"

    var id: String { rawValue }
}

enum ShowingImporterType {
    case ship
    case item
    case material
    case useitem
    case payitem
}

struct MainView: View {
    let shipTypeOrder: [String: Int] = [
        "戦艦": 10,
        "航空戦艦": 11,
        "正規空母": 20,
        "装甲空母": 21,
        "軽空母": 22,
        "重巡洋艦": 30,
        "航空巡洋艦": 31,
        "軽巡洋艦": 40,
        "重雷装巡洋艦": 41,
        "練習巡洋艦": 42,
        "駆逐艦": 50,
        "海防艦": 60,
        "潜水艦": 70,
        "潜水空母": 71,
        "水上機母艦": 80,
        "揚陸艦": 81,
        "補給艦": 82,
        "工作艦": 83
    ]

    @State private var ships: [LedgerShip] = []
    @State private var items: [LedgerItem] = []
    @State private var materials: [LedgerMaterial] = []
    @State private var useitems: [LedgerUseItem] = []
    @State private var payitems: [LedgerPayItem] = []

    @State private var shipSearchText = ""
    @State private var itemSearchText = ""
    @State private var shipSortMode: ShipSortMode = .level
    @State private var sectionByShipType = true
    @State private var isShowingImporter = false
    @State private var showingImporterType: ShowingImporterType?

    @State private var collapsedShipTypes: Set<String> = []
    @State private var collapsedItemCategories: Set<String> = []
    @State private var collapsedItemNames: Set<String> = []
    
    @State private var initializedCollapse = false

    var filteredShips: [LedgerShip] {
        let searched: [LedgerShip]

        if shipSearchText.isEmpty {
            searched = ships
        } else {
            searched = ships.filter {
                $0.name.localizedCaseInsensitiveContains(shipSearchText)
                || $0.shipType.localizedCaseInsensitiveContains(shipSearchText)
            }
        }

        switch shipSortMode {
        case .level:
            return searched.sorted { $0.level > $1.level }
        case .sortNumber:
            return searched.sorted { $0.sortNumber < $1.sortNumber }
        case .type:
            return searched.sorted {
                let left = shipTypeOrder[$0.shipType] ?? 999
                let right = shipTypeOrder[$1.shipType] ?? 999

                if left == right {
                    return $0.sortNumber < $1.sortNumber
                }
                return left < right
            }
        }
    }

    var groupedShips: [(type: String, ships: [LedgerShip])] {
        let groups = Dictionary(grouping: filteredShips) { ship in
            ship.shipType
        }

        return groups
            .map { (type: $0.key, ships: $0.value.sorted { $0.sortNumber < $1.sortNumber }) }
            .sorted {
                let left = shipTypeOrder[$0.type] ?? 999
                let right = shipTypeOrder[$1.type] ?? 999
                return left < right
            }
    }

    var filteredItems: [LedgerItem] {
        let searched: [LedgerItem]

        if itemSearchText.isEmpty {
            searched = items
        } else {
            searched = items.filter {
                $0.name.localizedCaseInsensitiveContains(itemSearchText)
                || $0.category.localizedCaseInsensitiveContains(itemSearchText)
            }
        }

        return searched.sorted {
            if $0.typeOrder == $1.typeOrder {
                return $0.name < $1.name
            }
            return $0.typeOrder < $1.typeOrder
        }
    }

    var groupedItems: [(category: String, items: [LedgerItem])] {
        let groups = Dictionary(grouping: filteredItems) { item in
            item.category
        }

        return groups
            .map { (category: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted {
                let left = $0.items.first?.typeOrder ?? 999
                let right = $1.items.first?.typeOrder ?? 999
                return left < right
            }
    }

    var body: some View {
        TabView {
            ShipListView(
                filteredShips: filteredShips,
                groupedShips: groupedShips,
                shipSortMode: $shipSortMode,
                sectionByShipType: $sectionByShipType,
                searchText: $shipSearchText,
                requestImport: {
                    showingImporterType = .ship
                    isShowingImporter = true
                },
                collapsedTypes: $collapsedShipTypes
            )
            .tabItem {
                Label("艦娘", systemImage: "person.3")
            }
            
            ItemListView(
                groupedItems: groupedItems,
                searchText: $itemSearchText,
                requestImport: {
                    showingImporterType = .item
                    isShowingImporter = true
                },
                collapsedCategories: $collapsedItemCategories,
                collapsedItemNames: $collapsedItemNames
            )
            .tabItem {
                Label("装備", systemImage: "shippingbox")
            }
            
            MaterialListView(
                materials: materials,
                useitems: useitems,
                payitems: payitems,
                requestMaterialImport: {
                    showingImporterType = .material
                    isShowingImporter = true
                },
                requestUseItemImport: {
                    showingImporterType = .useitem
                    isShowingImporter = true
                },
                requestPayItemImport: {
                    showingImporterType = .payitem
                    isShowingImporter = true
                }
            )
            .tabItem {
                Label("資材", systemImage: "tray.full")
            }
        }
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.json]
        ) { result in
            guard let importerType = showingImporterType else {
                return
            }
            
            defer {
                showingImporterType = nil
            }
            
            do {
                let url = try result.get()
                
                switch importerType {
                case .ship:
                    guard url.lastPathComponent == "ships.json" else {
                        print("ships.jsonを選択してください")
                        return
                    }
                    
                    ships = try loadJSON([LedgerShip].self, from: url)
                    collapsedShipTypes = Set(ships.map(\.shipType))
                    print("ships loaded: \(ships.count)")
                    
                case .item:
                    guard url.lastPathComponent == "items.json" else {
                        print("items.jsonを選択してください")
                        return
                    }
                    
                    items = try loadItems(from: url)
                    collapsedItemCategories = Set(items.map(\.category))
                    print("items loaded: \(items.count)")
                    
                case .material:
                    guard url.lastPathComponent == "materials.json" else {
                        print("materials.jsonを選択してください")
                        return
                    }
                    
                    materials = try loadMaterials(from: url)
                    print("materials loaded: \(materials.count)")
                    
                case .useitem:
                    guard url.lastPathComponent == "useitems.json" else {
                        print("useitems.jsonを選択してください")
                        return
                    }
                    
                    useitems = try loadUseItems(from: url)
                    print("useitems loaded: \(useitems.count)")
                    
                case .payitem:
                    guard url.lastPathComponent == "payitems.json" else {
                        print("payitems.jsonを選択してください")
                        return
                    }
                    
                    payitems = try loadPayItems(from: url)
                    print("payitems loaded: \(payitems.count)")
                }
            } catch {
                print(error)
            }
        }
    }

    func loadItems(from url: URL) throws -> [LedgerItem] {
        try loadJSON([LedgerItem].self, from: url)
    }

    func loadMaterials(from url: URL) throws -> [LedgerMaterial] {
        try loadJSON([LedgerMaterial].self, from: url)
    }

    func loadUseItems(from url: URL) throws -> [LedgerUseItem] {
        try loadJSON([LedgerUseItem].self, from: url)
    }

    func loadPayItems(from url: URL) throws -> [LedgerPayItem] {
        try loadJSON([LedgerPayItem].self, from: url)
    }

    func loadJSON<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}

struct ShipListView: View {
    let filteredShips: [LedgerShip]
    let groupedShips: [(type: String, ships: [LedgerShip])]

    @Binding var shipSortMode: ShipSortMode
    @Binding var sectionByShipType: Bool
    @Binding var searchText: String
    let requestImport: () -> Void
    @Binding var collapsedTypes: Set<String>

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        StatCard(title: "表示", value: "\(filteredShips.count)")
                        StatCard(title: "Lv99以上", value: "\(filteredShips.filter { $0.level >= 99 }.count)")
                    }
                }

                Section {
                    Picker("並び順", selection: $shipSortMode) {
                        ForEach(ShipSortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("艦種別に表示", isOn: $sectionByShipType)
                }

                if sectionByShipType {
                    ForEach(groupedShips, id: \.type) { group in
                        Section {
                            if !collapsedTypes.contains(group.type) {
                                ForEach(group.ships) { ship in
                                    ShipRowView(ship: ship)
                                }
                            }
                        } header: {
                            Button {
                                if collapsedTypes.contains(group.type) {
                                    collapsedTypes.remove(group.type)
                                } else {
                                    collapsedTypes.insert(group.type)
                                }
                            } label: {
                                HStack {
                                    Text("\(group.type)（\(group.ships.count)）")
                                    Spacer()
                                    Image(systemName: collapsedTypes.contains(group.type) ? "chevron.right" : "chevron.down")
                                }
                            }
                        }
                    }
                } else {
                    Section("艦娘一覧") {
                        ForEach(filteredShips) { ship in
                            ShipRowView(ship: ship)
                        }
                    }
                }
            }
            .navigationTitle("艦娘")
            .searchable(text: $searchText, prompt: "艦名・艦種で検索")
            .toolbar {
                Menu("読込") {
                    Button("ships.json") {
                        requestImport()
                    }
                }
            }
        }
    }
}

struct ShipRowView: View {
    let ship: LedgerShip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ship.name)
                .font(.headline)

            Text("\(ship.shipType) / Lv.\(ship.level) / No.\(ship.sortNumber)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct ItemListView: View {
    let groupedItems: [(category: String, items: [LedgerItem])]

    @Binding var searchText: String
    let requestImport: () -> Void
    @Binding var collapsedCategories: Set<String>
    @Binding var collapsedItemNames: Set<String>

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("表示中の装備カテゴリ: \(groupedItems.count)")
                        .foregroundStyle(.secondary)
                }

                ForEach(groupedItems, id: \.category) { group in
                    Section {
                        if !collapsedCategories.contains(group.category) {
                            ForEach(groupedItemNames(for: group), id: \.key) { itemGroup in
                                DisclosureItemNameRow(
                                    category: group.category,
                                    name: itemGroup.name,
                                    items: itemGroup.items,
                                    collapsedItemNames: $collapsedItemNames
                                )
                            }
                        }
                    } header: {
                        Button {
                            if collapsedCategories.contains(group.category) {
                                collapsedCategories.remove(group.category)
                            } else {
                                collapsedCategories.insert(group.category)
                            }
                        } label: {
                            HStack {
                                Text("\(group.category)（\(group.items.count)）")
                                Spacer()
                                Image(systemName: collapsedCategories.contains(group.category) ? "chevron.right" : "chevron.down")
                            }
                        }
                    }
                }
            }
            .navigationTitle("装備")
            .searchable(text: $searchText, prompt: "装備名・カテゴリで検索")
            .toolbar {
                Menu("読込") {
                    Button("items.json") {
                        requestImport()
                    }
                }
            }
        }
    }

    func groupedItemNames(for group: (category: String, items: [LedgerItem])) -> [(key: String, name: String, items: [LedgerItem])] {
        let groups = Dictionary(grouping: group.items) { item in
            item.name
        }

        return groups
            .map { (key: "\(group.category)|\($0.key)", name: $0.key, items: $0.value.sorted { $0.improvement > $1.improvement }) }
            .sorted { $0.name < $1.name }
    }
}

struct DisclosureItemNameRow: View {
    let category: String
    let name: String
    let items: [LedgerItem]
    @Binding var collapsedItemNames: Set<String>

    var key: String { "\(category)|\(name)" }
    var isCollapsed: Bool { collapsedItemNames.contains(key) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                if isCollapsed {
                    collapsedItemNames.remove(key)
                } else {
                    collapsedItemNames.insert(key)
                }
            } label: {
                HStack {
                    Text("\(name) ×\(items.count)")
                        .font(.headline)
                    Spacer()
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                }
            }

            if !isCollapsed {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    ItemRowView(item: item)
                        .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ItemRowView: View {
    let item: LedgerItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if item.improvement > 0 {
                Text("★\(item.improvement)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("★0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct MaterialListView: View {
    let materials: [LedgerMaterial]
    let useitems: [LedgerUseItem]
    let payitems: [LedgerPayItem]
    let requestMaterialImport: () -> Void
    let requestUseItemImport: () -> Void
    let requestPayItemImport: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("資材") {
                    ForEach(materials) { material in
                        HStack {
                            Text(material.name)
                            Spacer()
                            Text(material.amount.formatted())
                                .font(.headline)
                        }
                    }
                }

                Section("特殊アイテム") {
                    ForEach(useitems) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.amount.formatted())
                                .font(.headline)
                        }
                    }
                }

                Section("課金アイテム") {
                    ForEach(payitems) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.amount.formatted())
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("資材・道具")
            .toolbar {
                Menu("読込") {
                    Button("materials.json") {
                        requestMaterialImport()
                    }

                    Button("useitems.json") {
                        requestUseItemImport()
                    }

                    Button("payitems.json") {
                        requestPayItemImport()
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MainView()
}
