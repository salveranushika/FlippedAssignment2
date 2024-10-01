
import Foundation
import Accelerate
import AVFoundation

class AudioModel {
    
    // MARK: Properties
    private var BUFFER_SIZE:Int
   
    var timeData:[Float]
    var fftData:[Float]
    lazy var samplingRate:Int = {
        return Int(self.audioManager!.samplingRate)
    }()
    
    
    var twentyPointArray: [Float] {
        guard !fftData.isEmpty else { return Array(repeating: 0, count: 20) }
        let binSize = fftData.count / 20
        
        return (0..<20).map { binIndex in
            let startIndex = binIndex * binSize
            let endIndex = startIndex + binSize
            let binMax = fftData[startIndex..<endIndex].max() ?? 0
            return binMax
        }
    }

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var fileBuffer: AVAudioPCMBuffer?
    private var processingTimer: Timer?
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
    }
    
   
    func startMicrophoneProcessing(withFps:Double){
       
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            
         
            Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
                self.updateData()
            }
            
        }
    }
    
    
   
    func stop() {
        audioManager?.pause()

       
        audioManager?.inputBlock = nil
    }
    
    func loadAudioFile(url: URL) {
        do {
            if audioEngine == nil {
                audioEngine = AVAudioEngine()
                audioPlayerNode = AVAudioPlayerNode()
                audioEngine?.attach(audioPlayerNode!)
            }
            
          
            audioFile = try AVAudioFile(forReading: url)
            print("Audio file successfully loaded: \(url)")

            
            
            if let audioFile = audioFile {
                fileBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
                try audioFile.read(into: fileBuffer!)
                print("PCM buffer successfully created with frame capacity: \(fileBuffer!.frameCapacity)")
            }
            
           
            audioEngine?.connect(audioPlayerNode!, to: audioEngine!.mainMixerNode, format: audioFile!.processingFormat)
            print("Player node connected to main mixer.")
            
           
            if !audioEngine!.isRunning {
                try audioEngine?.start()
                print("Audio engine started successfully.")
                
            }
        } catch {
            print("Error loading audio file: \(error)")
        }
    }
    
    
    func startAudioFileProcessing(withFps: Double) {
        guard let audioEngine = audioEngine, let audioPlayerNode = audioPlayerNode, let fileBuffer = fileBuffer else {
            return
        }
        
        do {
            
            audioPlayerNode.scheduleBuffer(fileBuffer, at: nil, options: .loops, completionHandler: nil)
            
            
            try audioEngine.start()
            audioPlayerNode.play()
            
            
            processingTimer?.invalidate() // Stop any existing timer
            processingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / withFps, repeats: true) { _ in
                self.updateData()
            }
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    private var currentFrameIndex: Int = 0
    
    private func updateData() {
        guard let fileBuffer = fileBuffer else { return }

            
        let frameLength = min(fileBuffer.frameLength, AVAudioFrameCount(BUFFER_SIZE), fileBuffer.frameLength - AVAudioFrameCount(currentFrameIndex))
            
        if frameLength == 0 {
            
            currentFrameIndex = 0
            return
        }
        
        // Get a pointer to the audio samples
        let channelData = fileBuffer.floatChannelData![0]

        
        timeData = Array(UnsafeBufferPointer(start: channelData.advanced(by: Int(currentFrameIndex)), count: Int(frameLength)))
            
            
        fftHelper?.performForwardFFT(withData: &timeData, andCopydBMagnitudeToBuffer: &fftData)
            
        
        currentFrameIndex += Int(frameLength)
    }

    func stopAudioFileProcessing() {
        audioPlayerNode?.stop()
        audioEngine?.stop()
        processingTimer?.invalidate()
        
    }

       
   
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    
    
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    
    
    private func runEveryInterval(){
        if inputBuffer != nil {
           
            self.inputBuffer!.fetchFreshData(&timeData, // copied into this array
                                             withNumSamples: Int64(BUFFER_SIZE))
                
            
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)
            
        }
    }
    
    
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
       
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
    
}
