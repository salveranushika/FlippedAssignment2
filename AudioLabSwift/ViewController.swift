

import UIKit
import Metal


class ViewController: UIViewController {

    @IBOutlet weak var userView: UIView!
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4
    }
    
    // To setup audio model
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.userView)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
          
        userView.frame = CGRect(x: 20, y: 50, width: 365, height: 620) // Example size and position
            
        
        if let graph = self.graph{
            graph.setBackgroundColor(r: 0, g: 0, b: 0, a: 1)
            
            // To add in graphs for display
            // Note: To normalize the scale of this graph
            // because the fft is returned in dB which has very large negative values and some large positive values
            
            graph.addGraph(withName: "equalizer",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: 20)
            
            graph.addGraph(withName: "fft",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)
            
            graph.addGraph(withName: "time",
                numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
            
            graph.makeGrids() // Adding grids to graph
        }
        
        // To Load and start processing the audio file
        if let fileURL = Bundle.main.url(forResource: "[iSongs.info] 05 - Red Sea", withExtension: "mp3") {
            print(fileURL)
            audio.loadAudioFile(url: fileURL)
        }
        
        audio.startAudioFileProcessing(withFps: 60.0) // Process at 60 FPS
        audio.play()
        
        // Starting up the audio model here, querying microphone
        // audio.startMicrophoneProcessing(withFps: 20)
        // preferred number of FFT calculations per second

        // audio.play()
        
        // To run the loop for updating the graph peridocially
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updateGraph()
        }
       
    }
    
    // To stop audio processing when the view disappears.
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audio.stop()
        audio.stopAudioFileProcessing()
    }

    // To update the graph with refreshed FFT Data
    func updateGraph(){
        
        if let graph = self.graph{
            graph.updateGraph(
                data: self.audio.fftData,
                forKey: "fft"
            )
            
            graph.updateGraph(
                data: self.audio.timeData,
                forKey: "time"
            )
            
            graph.updateGraph(
                data: self.audio.twentyPointArray,
                forKey: "equalizer"
            )
        }
        
    }

}

