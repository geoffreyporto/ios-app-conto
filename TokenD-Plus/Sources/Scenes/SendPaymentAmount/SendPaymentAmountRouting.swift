import Foundation

extension SendPaymentAmount {
    struct Routing {
        let onShowProgress: () -> Void
        let onHideProgress: () -> Void
        let onShowError: (_ erroMessage: String) -> Void
        let onPresentPicker: (
        _ options: [String],
        _ onSelect: @escaping (_ balanceId: String) -> Void
        ) -> Void
        let onSendAction: ((_ sendModel: Model.SendPaymentModel) -> Void)?
        let onAtomicSwapBuyAction: ((_ ask: Model.AtomicSwapPaymentUrl) -> Void)?
        let onShowWithdrawDestination: ((_ sendModel: Model.SendWithdrawModel) -> Void)?
        let onShowRedeem: ((_ redeemModel: Model.ShowRedeemViewModel, _ reference: String) -> Void)?
        let showFeesOverview: (_ asset: String, _ feeType: Int32) -> Void
    }
}
