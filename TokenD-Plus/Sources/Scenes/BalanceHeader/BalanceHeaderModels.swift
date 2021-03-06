import UIKit

public enum BalanceHeader {
    
    // MARK: - Typealiases
    
    public typealias DeinitCompletion = ((_ vc: UIViewController) -> Void)?
    
    // MARK: -
    
    public enum Model {}
    public enum Event {}
}

// MARK: - Models

extension BalanceHeader.Model {
    
    public struct SceneModel {
        var balance: Balance?
        let balanceId: String
    }
    
    public struct Balance {
        let balance: Amount
        let iconUrl: URL?
    }
    
    public struct Amount {
        let value: Decimal
        let assetName: String
    }
    
    public enum ImageRepresentation {
        case abbreviation(text: String, color: UIColor)
        case image(URL)
    }
}

// MARK: - Events

extension BalanceHeader.Event {
    public typealias Model = BalanceHeader.Model
    
    // MARK: -
    
    public enum ViewDidLoad {
        public struct Request {}
    }
    
    public enum BalanceUpdated {
        
        public struct Response {
            let balanceAmount: Model.Amount
            let iconUrl: URL?
        }
        
        public struct ViewModel {
            let assetName: String
            let balance: String
            let title: String
            let imageRepresentation: Model.ImageRepresentation
        }
    }
}
