import Foundation
import CoreMIDI

public typealias ReadProcType = ([UInt8]) -> Void

public class MidiSocket {
    var client: MIDIClientRef = 0
    var outPort: MIDIPortRef = 0
    var inPort: MIDIPortRef = 0
    var status : OSStatus = 0
    var activeDestinationNumber: Int = -1
    var activeDestination:MIDIEndpointRef = 0
    var activeSourceNumber: Int = -1
    var activeSource:MIDIEndpointRef = 0
    var readProc: ReadProcType?
    
    
    public init(midiDeviceName: String) {
        let midiDeviceOutPortName: String = midiDeviceName + ".out"
        let midiDeviceInPortName: String = midiDeviceName + ".in"
        status = MIDIClientCreate(midiDeviceName as CFString, nil, nil, &client)
        MIDIOutputPortCreate(client, midiDeviceOutPortName as CFString, &outPort)
        if #available(OSX 10.11, *) {
            MIDIInputPortCreateWithBlock(client, midiDeviceInPortName as CFString, &inPort, MIDIReadBlockCallBack)
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    public func attachProc(_ proc: @escaping ReadProcType){
        readProc = proc
    }
    
    public func getDestinations() -> [String]{
        var names:[String] = [String]()
        let count: Int = MIDIGetNumberOfDestinations()
        for i in 0 ..< count
        {
            let endpoint:MIDIEndpointRef = MIDIGetDestination(i)
            if (endpoint != 0)
            {
                names.append(getDisplayName(endpoint))
            }
        }
        return names
    }
    
    public func setActiveDestination(destinationNumber : Int) {
        activeDestinationNumber = destinationNumber
        activeDestination = MIDIGetDestination(activeDestinationNumber)
    }
    
    public func getActiveDestinationNumber() -> Int {
        return activeDestinationNumber
    }
    
    public func getSources() -> [String]{
        var names:[String] = [String]()
        let count: Int = MIDIGetNumberOfSources()
        for i in 0 ..< count
        {
            let endpoint:MIDIEndpointRef = MIDIGetSource(i)
            if (endpoint != 0)
            {
                names.append(getDisplayName(endpoint))
            }
        }
        return names
    }
    
    public func setActiveSource(sourceNumber : Int) {
        activeSourceNumber = sourceNumber
        activeSource = MIDIGetSource(activeSourceNumber)
        MIDIPortConnectSource(inPort, activeSource, &activeSource)
    }
    
    public func getActiveSourceNumber() -> Int {
        return activeSourceNumber
    }
    
    public func sendBlockOf256Bytes(_ bytesToSend: [UInt8]){
        var packet:MIDIPacket = MIDIPacket()
        packet.length = UInt16(bytesToSend.count)
        packet.timeStamp = 0
        memcpy(&packet.data, bytesToSend, bytesToSend.count)
        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet);
        MIDISend(outPort, activeDestination, &packetList);
    }
    
    public func sendBytes(_ bytesToSend: [UInt8]){
        
        let DATA_PAKET_SIZE = 256
        
        let numberOfBytesToSend = bytesToSend.count
        let numberOfBlocksToSend = numberOfBytesToSend/DATA_PAKET_SIZE
        let oddBytesToSend = numberOfBytesToSend % DATA_PAKET_SIZE
        
        var startBlockIndex = 0;
        var endBlockIndex = DATA_PAKET_SIZE;
        
        for _ in 0..<numberOfBlocksToSend {
            let bytesBlock = Array(bytesToSend[startBlockIndex...endBlockIndex])
            sendBlockOf256Bytes(bytesBlock)
            startBlockIndex +=  DATA_PAKET_SIZE
            endBlockIndex += DATA_PAKET_SIZE
        }
        endBlockIndex = startBlockIndex + oddBytesToSend - 1
        let bytesBlock:[UInt8] = Array(bytesToSend[startBlockIndex...endBlockIndex])
        sendBlockOf256Bytes(bytesBlock)
    }
    
    private func getDisplayName(_ obj: MIDIObjectRef) -> String {
        var param: Unmanaged<CFString>?
        var name: String = "Error";
        
        let err: OSStatus = MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &param)
        if err == OSStatus(noErr)
        {
            name =  param!.takeRetainedValue() as String
        }
        
        return name;
    }
    
    
        
    private func MIDIReadBlockCallBack(packetList: UnsafePointer<MIDIPacketList>, readProcRefCon: UnsafeMutableRawPointer?) -> Void {
        let packets:MIDIPacketList = packetList.pointee
        var packet:MIDIPacket = packets.packet
        var message = [uint8]()
        
        for _ in 1...packets.numPackets
        {
            let bytes = Mirror(reflecting: packet.data).children
            var dumpStr = ""
            
            
            // bytes mirror contains all the zero values in the ridiulous packet data tuple
            // so use the packet length to iterate.
            var i = packet.length
            for (_, attr) in bytes.enumerated()
            {
                let midiByte = attr.value as! UInt8
                message.append(midiByte)
                dumpStr += String(format:"0x%02X ", midiByte)
                i -= 1
                if (i <= 0)
                {
                    break
                }
            }
           // print(dumpStr)
            
            packet = MIDIPacketNext(&packet).pointee
        }
        if let procToRun: ReadProcType = readProc
        {
            procToRun(message)
        }
    }
}


