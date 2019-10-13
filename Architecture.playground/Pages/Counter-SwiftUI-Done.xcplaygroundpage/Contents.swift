import UIKit
import PlaygroundSupport
import SwiftUI
import Combine

// Architecture definition
protocol Action {}
typealias Update<State> =  (State, Action) -> State

// View binding
typealias Call = () -> Void
typealias Dispatch = (Action) -> Call

// Store

final class BindableStore<State>: ObservableObject {
    private let update: Update<State>
    private(set) var state: State

    let objectWillChange = PassthroughSubject<State, Never>()

    init(state: State, update: @escaping Update<State>) {
        self.state = state
        self.update = update
    }

    func dispatch(_ action: Action) -> Call {
        { self.dispatch(action: action) }
    }

    private func dispatch(action: Action) {
        state = update(state, action)
        objectWillChange.send(state)
    }
}

// Example

typealias AppState = Int

enum AppAction: Action {
    case increment
    case decrement
    case reset
}

func update(state: AppState, action: Action) -> AppState {
    switch action {
    case AppAction.increment:
        return state + 1
    case AppAction.decrement:
        return max(state - 1, 0)
    case AppAction.reset:
        return 0
    default:
        return state
    }
}

// View

struct App: View {
    @ObservedObject var store: BindableStore<AppState>

    var body: some View {
        CounterScene(state: store.state, dispatch: store.dispatch)
    }
}

struct CounterScene: View {
    let text: String
    let disabled: Bool
    let increment, decrement, reset: Call

    init(state: AppState, dispatch: Dispatch) {
        self.text = "Count: \(state)"
        self.disabled = state < 1

        self.increment = dispatch(AppAction.increment)
        self.decrement = dispatch(AppAction.decrement)
        self.reset = dispatch(AppAction.reset)
    }

    var body: some View {
        VStack {
            Text(text)
            Button(
                action: increment,
                label: { Text("+") }
            )
            Button(
                action: decrement,
                label: { Text("-") }
            ).disabled(disabled)
            Button(
                action: reset,
                label: { Text("Reset") }
            ).disabled(disabled)
        }
    }
}

let app = App(store: BindableStore(state: AppState(), update: update))

PlaygroundPage.current.liveView = UIHostingController(rootView: app)
