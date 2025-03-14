import RxSwift
import RxRelay

class TransactionAdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterManager: AdapterManager
    private let adapterFactory: AdapterFactory

    private let adaptersReadyRelay = PublishRelay<Void>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.transactions_adapter_manager", qos: .userInitiated)
    private var _adapterMap = [TransactionSource: ITransactionsAdapter]()

    init(adapterManager: AdapterManager, adapterFactory: AdapterFactory) {
        self.adapterManager = adapterManager
        self.adapterFactory = adapterFactory

        adapterManager.adaptersReadyObservable
                .observeOn(SerialDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] adaptersMap in
                    self?.initAdapters(adapterMap: adaptersMap)
                })
                .disposed(by: disposeBag)
    }

    private func initAdapters(adapterMap: [Wallet: IAdapter]) {
        var newAdapterMap = [TransactionSource: ITransactionsAdapter]()

        for (wallet, adapter) in adapterMap {
            let source = wallet.transactionSource

            guard newAdapterMap[source] == nil else {
                continue
            }

            let transactionsAdapter: ITransactionsAdapter?

            switch source.blockchain {
            case .evm(let blockchain):
                transactionsAdapter = adapterFactory.evmTransactionsAdapter(transactionSource: wallet.transactionSource, blockchain: blockchain)
            default:
                transactionsAdapter = adapter as? ITransactionsAdapter
            }


            if let transactionsAdapter = transactionsAdapter {
                newAdapterMap[source] = transactionsAdapter
            }
        }

        queue.async {
            self._adapterMap = newAdapterMap
            self.adaptersReadyRelay.accept(())
        }
    }

}

extension TransactionAdapterManager {

    var adapterMap: [TransactionSource: ITransactionsAdapter] {
        queue.sync { _adapterMap }
    }

    var adaptersReadyObservable: Observable<Void> {
        adaptersReadyRelay.asObservable()
    }

    func adapter(for source: TransactionSource) -> ITransactionsAdapter? {
        queue.sync { _adapterMap[source] }
    }

}
