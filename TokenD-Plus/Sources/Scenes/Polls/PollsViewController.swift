import UIKit
import RxSwift

public protocol PollsDisplayLogic: class {
    typealias Event = Polls.Event
    
    func displaySceneUpdated(viewModel: Event.SceneUpdated.ViewModel)
    func displayPollsDidChange(viewModel: Event.PollsDidChange.ViewModel)
    func displayError(viewModel: Event.Error.ViewModel)
    func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel)
}

extension Polls {
    public typealias DisplayLogic = PollsDisplayLogic
    
    @objc(PollsViewController)
    public class ViewController: UIViewController {
        
        public typealias Event = Polls.Event
        public typealias Model = Polls.Model
        
        // MARK: - Private properties
        
        private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
        private let refreshControl: UIRefreshControl = UIRefreshControl()
        private let emptyView: EmptyView.View = EmptyView.View()
        
        private var polls: [PollCell.ViewModel] = [] {
            didSet {
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                UIView.animate(withDuration: 0.5, animations: {
                    self.tableView.reloadData()
                })
            }
        }
        
        private let disposeBag: DisposeBag = DisposeBag()
        
        // MARK: -
        
        deinit {
            self.onDeinit?(self)
        }
        
        // MARK: - Injections
        
        private var interactorDispatch: InteractorDispatch?
        private var routing: Routing?
        private var onDeinit: DeinitCompletion = nil
        
        public func inject(
            interactorDispatch: InteractorDispatch?,
            routing: Routing?,
            onDeinit: DeinitCompletion = nil
            ) {
            
            self.interactorDispatch = interactorDispatch
            self.routing = routing
            self.onDeinit = onDeinit
        }
        
        // MARK: - Overridden
        
        public override func viewDidLoad() {
            super.viewDidLoad()
            
            self.setupView()
            self.setupRefreshControl()
            self.setupEmptyView()
            self.setupTableView()
            self.setupLayout()
            
            self.observeLanguageChanges()
            
            let request = Event.ViewDidLoad.Request()
            self.interactorDispatch?.sendRequest { businessLogic in
                businessLogic.onViewDidLoad(request: request)
            }
        }
        
        // MARK: - Private
        
        private func observeLanguageChanges() {
            NotificationCenterUtil.instance.addObserver(
                forName: Notification.Name("LCLLanguageChangeNotification"),
                using: { [weak self] notification in
                    DispatchQueue.main.async {
                        self?.navigationItem.title = Localized(.polls)
                        let request = Event.RefreshInitiated.Request()
                        self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                            businessLogic.onRefreshInitiated(request: request)
                        })
                    }
                }
            )
        }
        
        private func updateContentOffset(offset: CGPoint) {
            if offset.y > 0 {
                self.routing?.showShadow()
            } else {
                self.routing?.hideShadow()
            }
        }
        
        // MARK: - Setup
        
        private func setupView() {
            self.view.backgroundColor = Theme.Colors.containerBackgroundColor
        }
        
        private func setupRefreshControl() {
            self.refreshControl
                .rx
                .controlEvent(.valueChanged)
                .subscribe(onNext: { [weak self] (_) in
                    let request = Event.RefreshInitiated.Request()
                    self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                        businessLogic.onRefreshInitiated(request: request)
                    })
                })
            .disposed(by: self.disposeBag)
        }
        
        private func setupEmptyView() {
            self.emptyView.isHidden = true
        }
        
        private func setupTableView() {
            self.tableView.backgroundColor = Theme.Colors.containerBackgroundColor
            self.tableView.register(classes: [
                PollCell.ViewModel.self
                ]
            )
            self.tableView.dataSource = self
            self.tableView.separatorStyle = .none
            self.tableView
                .rx
                .contentOffset
                .asDriver()
                .drive(onNext: { [weak self] (offset) in
                    self?.updateContentOffset(offset: offset)
                })
                .disposed(by: self.disposeBag)
        }
        
        private func setupLayout() {
            self.view.addSubview(self.tableView)
            self.view.addSubview(self.emptyView)
            
            self.tableView.addSubview(self.refreshControl)
            
            self.tableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.emptyView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension Polls.ViewController: Polls.DisplayLogic {
    
    public func displaySceneUpdated(viewModel: Event.SceneUpdated.ViewModel) {
        switch viewModel.content {
            
        case .empty(let message):
            self.emptyView.message = message
            self.emptyView.isHidden = false
            
        case .polls(let polls):
            self.emptyView.isHidden = true
            self.polls = polls
        }
    }
    
    public func displayPollsDidChange(viewModel: Event.PollsDidChange.ViewModel) {
        viewModel.polls.forEach { (pollViewModel) in
            if let index = self.polls.indexOf(pollViewModel) {
                let indexPath = IndexPath(row: 0, section: index)
                if let cell = self.tableView.cellForRow(at: indexPath),
                    let pollCell = cell as? Polls.PollCell.View {
                    
                    pollViewModel.setup(cell: pollCell)
                }
                self.polls[index] = pollViewModel
            }
        }
    }
    
    public func displayError(viewModel: Event.Error.ViewModel) {
        self.routing?.showError(viewModel.message)
    }
    
    public func displayLoadingStatusDidChange(viewModel: Event.LoadingStatusDidChange.ViewModel) {
        switch viewModel {
            
        case .loaded:
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            self.routing?.hideLoading()
            
        case .loading:
            self.routing?.showLoading()
        }
    }
}

extension Polls.ViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.polls.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.polls[indexPath.section]
        let cell = tableView.dequeueReusableCell(with: model, for: indexPath)
        
        if let pollCell = cell as? Polls.PollCell.View {
            pollCell.onActionButtonClicked = { [weak self] in
                guard let upToDateModel = self?.polls[indexPath.section] else { return }
                
                let request = Event.ActionButtonClicked.Request(
                    pollId: upToDateModel.pollId
                )
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onActionButtonClicked(request: request)
                })
            }
            pollCell.onChoiceSelected = { [weak self] (choice) in
                let request = Event.ChoiceChanged.Request(
                    pollId: model.pollId,
                    choice: choice
                )
                self?.interactorDispatch?.sendRequest(requestBlock: { (businessLogic) in
                    businessLogic.onChoiceChanged(request: request)
                })
            }
        }
        return cell
    }
}
