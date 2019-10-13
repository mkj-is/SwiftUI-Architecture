import UIKit
import PlaygroundSupport

// Architecture definition
protocol Action {}
typealias Update<State> =  (State, Action) -> State
typealias Subscriber<State> = (State) -> Void

// View binding
typealias Call = () -> Void
typealias Dispatch = (Action) -> Call

// Store

final class Store<State> {
    private let update: Update<State>
    private var state: State
    private var subscribers: [Subscriber<State>]

    init(state: State, update: @escaping Update<State>) {
        self.state = state
        self.update = update
        self.subscribers = []
    }

    func dispatch(action: Action) {
        state = update(state, action)
        notify()
    }

    func subscribe(_ subscriber: @escaping Subscriber<State>) {
        subscriber(state)
        subscribers.append(subscriber)
    }

    private func notify() {
        subscribers.forEach { subscriber in
            subscriber(state)
        }
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
        return state - 1
    case AppAction.reset:
        return 0
    default:
        return state
    }
}

// View

final class ViewController: UIViewController {

    let store: Store<AppState>

    init(store: Store<AppState>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Unimplemented")
    }

    @objc func increment() {
        store.dispatch(action: AppAction.increment)
    }

    @objc func decrement() {
        store.dispatch(action: AppAction.decrement)
    }

    @objc func reset() {
        store.dispatch(action: AppAction.reset)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let label = UILabel()
        label.textAlignment = .center

        let incrementButton = UIButton(type: .system)
        incrementButton.setTitle("Přidat", for: .normal)
        incrementButton.addTarget(self, action: #selector(increment), for: .touchUpInside)

        let decrementButton = UIButton(type: .system)
        decrementButton.setTitle("Odebrat", for: .normal)
        decrementButton.addTarget(self, action: #selector(decrement), for: .touchUpInside)

        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Restartovat", for: .normal)
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [label, incrementButton, decrementButton, resetButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        view.addSubview(stackView)

        store.subscribe { [weak label] state in
            label?.text = String(state)
        }
    }
}

// App start

let store = Store(state: 0, update: update)

PlaygroundPage.current.liveView = ViewController(store: store)
