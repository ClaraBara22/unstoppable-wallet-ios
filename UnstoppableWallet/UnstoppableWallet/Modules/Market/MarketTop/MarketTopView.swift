import SectionsTableView
import RxSwift
import RxCocoa

class MarketTopView {
    private let disposeBag = DisposeBag()

    private let viewModel: MarketTopViewModel
    var openController: ((UIViewController) -> ())?

    private let sectionUpdatedRelay = PublishRelay<()>()
    private var viewItems = [MarketTopViewModel.ViewItem]()

    private let headerView = MarketListHeaderView()

    init(viewModel: MarketTopViewModel) {
        self.viewModel = viewModel

        headerView.set(sortingField: viewModel.sortingField)
        headerView.set(period: viewModel.period)
        headerView.set(sortingFieldAction: { [weak self] in self?.onTapSortingField() })
        headerView.set(periodAction: { [weak self] in self?.onTapPeriod() })

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
    }

    private func onTapSortingField() {
        let alertController = AlertRouter.module(
                title: "market.sort_by".localized,
                viewItems: viewModel.sortingFields.map { item in
                    AlertViewItem(
                            text: item,
                            selected: item == viewModel.sortingField
                    )
                }
        ) { [weak self] index in
            self?.setSortingField(at: index)
        }

        openController?(alertController)
    }

    private func onTapPeriod() {
        let alertController = AlertRouter.module(
                title: "market.changes".localized,
                viewItems: viewModel.periods.map { item in
                    AlertViewItem(
                            text: item,
                            selected: item == viewModel.period
                    )
                }
        ) { [weak self] index in
            self?.setPeriod(at: index)
        }

        openController?(alertController)
    }

    private func setSortingField(at index: Int) {
        viewModel.setSortingField(at: index)

        headerView.set(sortingField: viewModel.sortingField)
    }

    private func setPeriod(at index: Int) {
        viewModel.setPeriod(at: index)

        headerView.set(period: viewModel.period)
    }

    private func sync(viewItems: [MarketTopViewModel.ViewItem]) {
        self.viewItems = viewItems

        sectionUpdatedRelay.accept(())
    }

    private func row(index: Int, viewItem: MarketTopViewModel.ViewItem) -> RowProtocol {
        let last = index == viewItems.count - 1

        return Row<RateTopListCell>(
                id: "coin_rate_\(index + 1)",
                hash: viewItem.coinName,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.bind(
                        rank: viewItem.rank,
                        coinCode: viewItem.coinCode,
                        coinName: viewItem.coinName,
                        rate: viewItem.rate,
                        diff: viewItem.diff,
                        last: last)
                },
                action: { _ in
                    //todo: show chart page
//                    self?.delegate.onSelect(index: index)
                }
        )

    }

}

extension MarketTopView {

    public var sectionUpdatedSignal: Signal<()> {
        sectionUpdatedRelay.asSignal()
    }

    public var registeringCellClasses: [UITableViewCell.Type] {
        [RateTopListCell.self]
    }

    public var section: SectionProtocol {
        Section(
            id: "market_top_section",
            headerState: .static(view: headerView, height: .heightSingleLineCell),
            rows: viewItems.enumerated().map { index, viewItem in
                row(index: index, viewItem: viewItem)
            }
        )
    }

    public func refresh() {
        viewModel.refresh()
    }

}
