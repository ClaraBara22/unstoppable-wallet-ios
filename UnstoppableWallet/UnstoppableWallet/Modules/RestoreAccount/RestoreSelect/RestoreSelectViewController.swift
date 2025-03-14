import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class RestoreSelectViewController: CoinToggleViewController {
    private let viewModel: RestoreSelectViewModel
    private let enableCoinView: EnableCoinView

    init(viewModel: RestoreSelectViewModel, enableCoinView: EnableCoinView) {
        self.viewModel = viewModel
        self.enableCoinView = enableCoinView

        super.init(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.searchController = nil

        title = "restore_select.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(onTapRightBarButton))

        enableCoinView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }

        subscribe(disposeBag, viewModel.restoreEnabledDriver) { [weak self] in self?.navigationItem.rightBarButtonItem?.isEnabled = $0 }
        subscribe(disposeBag, viewModel.successSignal) { [weak self] in self?.dismiss(animated: true) }
        subscribe(disposeBag, viewModel.disableBlockchainSignal) { [weak self] in self?.setToggle(on: false, uid: $0) }
    }

    private func open(controller: UIViewController) {
        navigationItem.searchController?.dismiss(animated: true)
        present(controller, animated: true)
    }

    @objc private func onTapRightBarButton() {
        viewModel.onRestore()
    }

}
