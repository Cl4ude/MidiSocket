# MidiSocket

Simple implementation of CoreMIDI

 class MidiSocket 
 
 Init Socket :
- init(midiDeviceName: String) 

Manage midi Destinations :
- getDestinations() -> [String]
- setActiveDestination(destinationNumber : Int)
- getActiveDestinationNumber() -> Int 
 
 Manage Midi Sources :
- getSources() -> [String]
- setActiveSource(sourceNumber : Int) {
- getActiveSourceNumber() -> Int

Send data :
- sendBlockOf256Bytes(_ bytesToSend: [UInt8])
- sendBytes(_ bytesToSend: [UInt8])

Receive Data :
- attachProc(_ proc: @escaping ReadProcType)
 
