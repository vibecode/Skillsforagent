---
name: swiftui-design
display_name: Modern SwiftUI Design
description: "Idiomatic modern SwiftUI craft for iOS 26 - use when building any SwiftUI screen (card grids, settings forms, list-detail, dashboards) and you want it to look crafted and native, not flat and generic. Teaches modern @Observable/@State/@Bindable state, view extraction, breathing layout (Grid/LazyVGrid, spacing rhythm, padding), .safeAreaInset, polished ScrollView and NavigationStack, stable list identity, and the lazy SwiftUI mistakes LLMs make."
metadata: {"openclaw": {"emoji": "🎨"}}
---

# Modern SwiftUI craft

Generated SwiftUI looks generic for a handful of repeatable reasons: one giant
`ContentView`, magic numbers everywhere, legacy `ObservableObject`, and layouts
that fight the system instead of leaning on it. This skill is the antidote.
Compose small views, let SwiftUI do spacing, use modern state. The result reads
as native because it is native.

## 1. State: `@Observable`, never `ObservableObject`

On iOS 17+ (so always, here) use the `@Observable` macro. It tracks only the
properties a view actually reads, so fewer redraws and no `@Published` noise.

```swift
@Observable
final class CounterModel {
    var count = 0
    var name = ""
    func increment() { count += 1 }
}

struct CounterView: View {
    @State private var model = CounterModel()   // view OWNS it -> @State
    var body: some View {
        Button("Count: \(model.count)") { model.increment() }
    }
}

// A child that needs two-way bindings into an injected model uses @Bindable:
struct NameField: View {
    @Bindable var model: CounterModel           // PASSED in -> @Bindable
    var body: some View { TextField("Name", text: $model.name) }
}
```

Rules: `@State` is always `private` and is where a value is *owned*. Never mark a
*passed-in* value `@State`. It freezes at the initial value and ignores updates.
Don't reach for `ObservableObject` / `@StateObject` / `@Published`.

## 2. Extract views: kill the massive ContentView

A 200-line `body` is the #1 tell of generated UI. Keep each `body` short by
pulling rows, cards, and sections into their own small views. Smaller views also
mean SwiftUI re-renders less.

```swift
// LAZY: one giant body with inline rows, headers, and styling.
// CRAFTED: a thin parent that composes named pieces.
struct ProfileView: View {
    let user: User
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ProfileHeader(user: user)
                StatsRow(user: user)
                ActivityList(items: user.activity)
            }
            .padding()
        }
    }
}
```

Use a computed `private var someSection: some View` for medium chunks, and a
dedicated `struct` once a piece has its own data or could be reused.

## 3. Layout that breathes

Generated screens feel cramped because everything is jammed to default spacing or
padded with random numbers. Give the layout rhythm with a small, consistent scale
and let stacks own spacing instead of padding each child.

```swift
// LAZY: padding sprinkled per child, magic numbers everywhere.
VStack {
    Text(title).padding(.bottom, 7)
    Text(subtitle).padding(.bottom, 13)
}

// CRAFTED: the stack owns the rhythm; spacing comes from a small scale.
VStack(alignment: .leading, spacing: 8) {
    Text(title).font(.headline)
    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
}
.padding()
```

Pick spacing from a tight set (4 / 8 / 12 / 16 / 24). Use `.foregroundStyle`
(not deprecated `.foregroundColor`) and semantic colors (`.secondary`, `.tint`)
so light and dark mode both read well. Reach for `GeometryReader` last, since it
usually means you're fighting the layout system.

## 4. Card grids: `LazyVGrid` done right

```swift
struct CardGrid: View {
    let items: [Item]
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in            // Item: Identifiable
                    CardCell(item: item)
                }
            }
            .padding()
        }
    }
}

struct CardCell: View {
    let item: Item
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: item.symbol)
                .font(.title2).foregroundStyle(.tint)
            Text(item.title).font(.headline)
            Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }
}
```

`.adaptive(minimum:)` makes the grid reflow across device sizes for free. A
material background with a rounded `.rect` reads as a real card; a flat gray
rectangle does not.

## 5. Settings forms: use `Form`, not a hand-rolled VStack

`Form` / `Section` gives you grouped insets, dividers, and native row styling
automatically. Don't rebuild it with stacks and `Divider()`.

```swift
struct SettingsView: View {
    @State private var notifications = true
    @State private var name = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $name)
                    NavigationLink("Account") { AccountView() }
                }
                Section("Preferences") {
                    Toggle("Notifications", isOn: $notifications)
                } footer: {
                    Text("We'll only ping you about important updates.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

## 6. List-detail with `NavigationStack` and stable identity

```swift
struct ItemList: View {
    let items: [Item]
    var body: some View {
        NavigationStack {
            List(items) { item in                 // Identifiable -> stable id
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
            .navigationTitle("Items")
            .navigationDestination(for: Item.self) { item in
                ItemDetail(item: item)
            }
        }
    }
}
```

Identity rule: drive `ForEach` / `List` by a stable `Identifiable` id, never by
`.indices` or array offset. Index-based identity breaks animations and recycles
state onto the wrong row when the data mutates.

## 7. `.safeAreaInset` for floating bars

A persistent action bar belongs in `.safeAreaInset`, which insets the scroll
content so nothing hides behind it, better than overlaying and guessing padding.

```swift
ScrollView { content }
    .safeAreaInset(edge: .bottom) {
        Button("Continue") { /* ... */ }
            .buttonStyle(.borderedProminent)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.bar)
    }
```

## Quick checklist before you ship a screen

- `@Observable` model, `@State` to own, `@Bindable` to bind a passed-in model.
- No `body` over ~15 lines; extract rows, cards, sections.
- Spacing from a small scale (4/8/12/16/24); stacks own spacing, not per-child padding.
- `Form` for settings, `LazyVGrid(.adaptive)` for grids, `List` + `NavigationStack` for list-detail.
- Stable `Identifiable` ids; `.foregroundStyle` + semantic colors; verify light AND dark.
