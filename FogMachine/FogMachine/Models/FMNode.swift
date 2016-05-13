import PeerKit
import MultipeerConnectivity

public class FMNode : CustomStringConvertible, Hashable, Equatable {
    
    // MARK: Properties
    public var name: String
    public var uniqueId: String
    public private(set) var mcPeerID: MCPeerID
    
    public var description: String{
        return name + " " + uniqueId
    }
    public var hashValue: Int
    
    public init(uniqueId:String, name:String, mcPeerID:MCPeerID) {
        self.name = name
        self.uniqueId = uniqueId
        self.mcPeerID = mcPeerID;
        self.hashValue = uniqueId.hash
    }
}

public func ==(lhs: FMNode, rhs: FMNode) -> Bool {
    return lhs.uniqueId == rhs.uniqueId
}