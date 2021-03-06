import Foundation
import TokenDWallet
import TokenDSDK
import RxCocoa
import RxSwift

public class TransactionSender {
    
    // MARK: - Private properties
    
    private let api: TransactionsApi
    private let keychainDataProvider: KeychainDataProviderProtocol
    private let transactionActionRelay: PublishRelay<Void> = PublishRelay()
    
    // MARK: -
    
    public init(
        api: TransactionsApi,
        keychainDataProvider: KeychainDataProviderProtocol
        ) {
        
        self.api = api
        self.keychainDataProvider = keychainDataProvider
    }
    
    // MARK: - Public
    
    public enum SendTransactionResult {
        
        case succeeded(TransactionResponse)
        case failed(Swift.Error)
    }
    public func sendTransaction(
        _ transaction: TransactionModel,
        shouldSign: Bool = true,
        completion: @escaping (SendTransactionResult) -> Void
        ) throws {
        
        if shouldSign {
            try transaction.addSignature(signer: self.keychainDataProvider.getKeyData())
        }
        self.api.sendTransaction(
            envelope: transaction.getEnvelope().toXdrBase64String()
        ) { (result) in
            switch result {
                
            case .success(let response):
                self.transactionActionRelay.accept(())
                completion(.succeeded(response))
                
            case .failure(let error):
                completion(.failed(error))
            }
        }
    }
    
    public func observeTransactionActions() -> Observable<Void> {
        return self.transactionActionRelay.asObservable()
    }
}
