import UIKit
import PlaygroundSupport
import SwiftUI
import Combine

// Architecture definition
protocol Action {}
typealias Update<State> = (State, Action) -> State

// View binding
typealias Call = () -> Void
typealias Dispatch = (Action) -> Call

// View component

protocol Component: View {
    associatedtype State
    associatedtype Calls

    var state: State { get }
    var calls: Calls { get }
}

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

struct CounterScene: Component {

    struct State {
        let text: String
        let disabled: Bool

        init(state: AppState) {
            text = "Count: \(state)"
            disabled = state < 1
        }
    }

    struct Calls {
        let increment, decrement, reset: Call

        init(dispatch: Dispatch) {
            increment = dispatch(AppAction.increment)
            decrement = dispatch(AppAction.decrement)
            reset = dispatch(AppAction.reset)
        }
    }

    let state: State
    let calls: Calls

    var body: some View {
        VStack {
            Text(state.text)
            Button(
                action: calls.increment,
                label: { Text("+") }
            )
            Button(
                action: calls.decrement,
                label: { Text("-") }
            ).disabled(state.disabled)
            Button(
                action: calls.reset,
                label: { Text("Reset") }
            ).disabled(state.disabled)
        }
    }
}

struct App: View {
    @ObservedObject var store: BindableStore<AppState>

    var body: some View {
        CounterScene(state: CounterScene.State(state: store.state), calls: CounterScene.Calls(dispatch: store.dispatch))
    }
}

let app = App(store: BindableStore(state: AppState(), update: update))

PlaygroundPage.current.liveView = UIHostingController(rootView: app)
