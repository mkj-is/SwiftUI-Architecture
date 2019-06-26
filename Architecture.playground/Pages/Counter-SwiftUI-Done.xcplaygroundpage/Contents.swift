import UIKit
import PlaygroundSupport
import SwiftUI
import Combine

// Architecture definition
protocol Action {}
typealias Reducer<State> =  (State, Action) -> State

// View binding
typealias Call = () -> Void
typealias Dispatch = (Action) -> Call

// Store

final class BindableStore<State>: BindableObject {
    private let reducer: Reducer<State>
    private(set) var state: State

    let didChange = PassthroughSubject<State, Never>()

    init(state: State, reducer: @escaping Reducer<State>) {
        self.state = state
        self.reducer = reducer
    }

    func dispatch(_ action: Action) -> Call {
    { self.dispatch(action: action) }
    }

    private func dispatch(action: Action) {
        state = reducer(state, action)
        didChange.send(state)
    }
}

// Example

typealias AppState = Int

enum AppAction: Action {
    case increment
    case decrement
    case reset
}

func appReducer(state: AppState, action: Action) -> AppState {
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
    @ObjectBinding var store: BindableStore<AppState>

    var body: some View {
        CounterScene(count: store.state, dispatch: store.dispatch)
            .relativeSize(width: 1, height: 1)
    }
}

struct CounterScene: View {
    let count: Int
    let dispatch: Dispatch

    var body: some View {
        VStack {
            Text( "Count: \(count)")
            Button(
                action: dispatch(AppAction.increment),
                label: { Text("+") }
            )
            Button(
                action: dispatch(AppAction.decrement),
                label: { Text("-") }
            )
            Button(
                action: dispatch(AppAction.reset),
                label: { Text("Reset") }
            )
        }
    }
}

let app = App(store: BindableStore(state: AppState(), reducer: appReducer))

PlaygroundPage.current.liveView = UIHostingController(rootView: app)
