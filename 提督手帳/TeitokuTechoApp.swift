//
//  TeitokuTechoApp.swift
//  提督手帳
//
//  Created by 小西克尚 on 2026/05/14.
//


// TeitokuTechoApp.swift

import SwiftUI

@main
struct TeitokuTechoApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

// ContentView.swift

import SwiftUI
import Combine
import UniformTypeIdentifiers

struct KanColleLedger: Codable {
    var ships: [Ship]
    var slotItems: [SlotItem]
    var materials: [Material]

    static let empty = KanColleLedger(
        ships: [],
        slotItems: [],
        materials: []
    )
}

struct Ship: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let level: Int
    let shipType: String?
    let locked: Bool?
}

struct SlotItem: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let type: String?
    let level: Int?
    let locked: Bool?
}

struct Material: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let value: Int
}

final class LedgerStore: ObservableObject {
    @Published var ledger: KanColleLedger = .empty
    @Published var errorMessage: String?

    func loadSampleData() {
        ledger = KanColleLedger(
            ships: [
                Ship(id: 1, name: "赤城改二", level: 99, shipType: "正規空母", locked: true),
                Ship(id: 2, name: "時雨改三", level: 88, shipType: "駆逐艦", locked: true),
                Ship(id: 3, name: "北上改二", level: 95, shipType: "軽巡洋艦", locked: true)
            ],
            slotItems: [
                SlotItem(id: 1, name: "烈風改二", type: "艦上戦闘機", level: 10, locked: true),
                SlotItem(id: 2, name: "61cm五連装酸素魚雷", type: "魚雷", level: 6, locked: true)
            ],
            materials: [
                Material(name: "燃料", value: 250000),
                Material(name: "弾薬", value: 240000),
                Material(name: "鋼材", value: 300000),
                Material(name: "ボーキサイト", value: 180000),
                Material(name: "高速修復材", value: 1200),
                Material(name: "改修資材", value: 300)
            ]
        )
    }
}

struct ContentView: View {
    @StateObject private var store = LedgerStore()

    var body: some View {
        TabView {
            ShipListView(store: store)
                .tabItem {
                    Label("艦娘", systemImage: "person.3")
                }

            ItemListView(store: store)
                .tabItem {
                    Label("装備", systemImage: "shippingbox")
                }

            MaterialListView(store: store)
                .tabItem {
                    Label("資材", systemImage: "tray.full")
                }
        }
        .onAppear {
            if store.ledger.ships.isEmpty {
                store.loadSampleData()
            }
        }
    }
}

struct ShipListView: View {
    @ObservedObject var store: LedgerStore

    var body: some View {
        NavigationStack {
            List(store.ledger.ships.sorted { $0.level > $1.level }) { ship in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ship.name)
                            .font(.headline)
                        if ship.locked == true {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                        }
                    }
                    HStack {
                        Text("Lv. \(ship.level)")
                        if let shipType = ship.shipType {
                            Text(shipType)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("艦娘")
        }
    }
}

struct ItemListView: View {
    @ObservedObject var store: LedgerStore

    var body: some View {
        NavigationStack {
            List(store.ledger.slotItems) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                        if item.locked == true {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                        }
                    }
                    HStack {
                        if let type = item.type {
                            Text(type)
                        }
                        if let level = item.level, level > 0 {
                            Text("★\(level)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("装備")
        }
    }
}

struct MaterialListView: View {
    @ObservedObject var store: LedgerStore

    var body: some View {
        NavigationStack {
            List(store.ledger.materials) { material in
                HStack {
                    Text(material.name)
                    Spacer()
                    Text(material.value.formatted())
                        .font(.headline)
                }
            }
            .navigationTitle("資材")
        }
    }
}

#Preview {
    ContentView()
}
