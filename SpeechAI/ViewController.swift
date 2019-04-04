//
//  ViewController.swift
//  SpeechAI
//
//  Created by Prasann Pandya on 2019-04-04.
//  Copyright © 2019 Prasann Pandya. All rights reserved.
//

import UIKit
import Speech
import AVFoundation
import NaturalLanguage

class ViewController: UIViewController {
    
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var startStopBtn: UIButton!
    
    @IBOutlet weak var missView: UITextView!
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US")) //1
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    var wordList = [String]()
    var saidList = [String]()
    var missList = [String]()
    
    var lang: String = "en-US"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let text = """
        In those days a decree went out from Caesar Augustus that all the world should be registered. This was the first registration when Quirinius was governor of Syria. And all went to be registered, each to his own town.
        """
        
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = text
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { _, tokenRange, _ in
            let word = (text as NSString).substring(with: tokenRange)
            self.wordList.append(word)
        }
        
        print(self.wordList)
        
        startStopBtn.isEnabled = false  //2
        
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.startStopBtn.isEnabled = isButtonEnabled
            }
        }
        
        self.speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate  //3
        
        
        

    }
    
    @IBAction func startStopAct(_ sender: Any) {
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            startStopBtn.isEnabled = false
            startStopBtn.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            startStopBtn.setTitle("Stop Recording", for: .normal)
        }
        
    }
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            //try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        var elapsedTime: Date = Date();
        //        var prevCount = 0
        
        var count: Int = 0
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            var finalText: String = ""
            
            
            
            
            //            print("Here again!")
            
            if let result = result {
                // Update the text view with the results.
                
                finalText += result.bestTranscription.formattedString
                self.textView.text = finalText
                
                isFinal = result.isFinal
                if(Date().timeIntervalSince(elapsedTime) > 1.5){
                    //                    finalText += ". "
                    var temp_text: String = ""
                    for i in count..<result.bestTranscription.segments.count{
                        temp_text += result.bestTranscription.segments[i].substring + " ";
                    }
                    count = result.bestTranscription.segments.count-1
                    //                    print(temp_text)
//                    self.finalList.append(temp_text)
//                    print(self.finalList)
//                    print("Full Stop")
                    
                    //                    result = SFSpeechRecognitionResult(coder: )
                }
                elapsedTime = Date();
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.startStopBtn.isEnabled = true
                self.textView.text.append(". ");
                
                let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
                tagger.string = self.textView.text
                
                
                let range = NSRange(location: 0, length: self.textView.text.utf16.count)
                let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
                tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { _, tokenRange, _ in
                    let word = (self.textView.text as NSString).substring(with: tokenRange)
                    self.saidList.append(word)
                }
                
                var missText: String = ""
                for i in 0..<self.saidList.count{
                    if(self.wordList.contains(self.saidList[i])==false){
                        self.missList.append(self.saidList[i])
                        missText+=self.saidList[i] + " "
                    }
                }
                print(self.missList)
                self.missView.text = missText
                
//                var highlightText: String = ""
//                for i in 0..<self.saidList.count{
//                    if(self.missList.contains(self.saidList[i])){
////                        highlightText+=
//                    }
//                }
//                print(self.finalList)
            }
        }
        
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = ""
        
    }
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            startStopBtn.isEnabled = true
        } else {
            startStopBtn.isEnabled = false
        }
    }
}

