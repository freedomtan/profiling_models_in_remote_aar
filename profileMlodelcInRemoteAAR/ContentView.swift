//
//  ContentView.swift
//  profileMlodelcInRemoteAAR
//
//  Created by Koan-Sin Tan on 8/24/24.
//

import AppleArchive
import CoreML
import SwiftUI
import System

struct ContentView: View {
    @State private var aarExtracted = false
    @State private var modelPathPrefix = ""
    @State private var modelPath = ""
    @State private var analyticsDict = Dictionary<AnyHashable, Any>()
    @State private var dictLoaded = false
    @State private var showMIL = false
    @State private var showSimple = false
    @State private var models = ["image-classification", "image-segmentation", "pose-estimation", "object-detection", "face-detection",
                                 "depth-estimation", "style-transfer", "image-super-resolution", "text-classification", "machine-translation"]
    @State private var precisions = ["f32", "f16", "i8"]
 
    @State private var modelSelected = "image-classification"
    @State private var precisionSelected = "f32"
    
    let modelNames = [
        "image-classification": "mobilenet_v1",
        "image-segmentation": "deeplabv3_mobilenetv2",
        "pose-estimation": "openposev2_vgg19",
        "object-detection": "mobilenetv1_ssd",
        "face-detection": "retinaface",
        "depth-estimation": "de_efficientnetlitev3",
        "style-transfer": "imagetransformnet",
        "image-super-resolution": "rfdn",
        "text-classification": "bert_tiny",
        "machine-translation":"Transformer_complex"
    ]
    
     var body: some View {
        VStack {
            Button("Download the .aar", action: downloadAar)
            HStack {
                Picker("model", selection: $modelSelected) {
                    ForEach(models, id: \.self) {
                        Text($0)
                    }
                }
                Picker("precision", selection: $precisionSelected) {
                    ForEach(precisions, id: \.self) {
                        Text($0)
                    }
                }
            }
            Button("profiling", action: {
                if (aarExtracted) {
                    modelPath = modelPathPrefix + "/\(modelSelected)/\(modelNames[modelSelected]!)_\(precisionSelected).mlmodelc/"
                    analyticsDict = getProfilingDict()
                    if (!dictLoaded) {
                        dictLoaded.toggle()
                    }
                }
            })
            HStack {
                Button("Show MIL") {
                    if (!showMIL) && (showSimple) {
                        showSimple.toggle()
                    }
                    showMIL.toggle()
                }
                Button("Show Simple") {
                    if (!showSimple) && (showMIL) {
                        showMIL.toggle()
                    }
                    showSimple.toggle()
                }
            }

            if (showMIL) {
                if (dictLoaded) {
                    // "at program:line:col" -> program
                    let fileName = ((analyticsDict.first!.key as! String).components(separatedBy: " ")[1]).components(separatedBy: ":")[0]
                    let toSaveUrl = URL.temporaryDirectory.appending(component: "\(modelSelected)_\(modelNames[modelSelected]!)_\(precisionSelected)_analytics.mil")
                    let milString = try! String.init(contentsOfFile: fileName, encoding: String.Encoding.utf8)
                    let _: () = try! milString.data(using: .utf8)!.write(to: toSaveUrl)
                    
                    ShareLink(item: toSaveUrl)
                    ScrollView(.vertical) {
                        ScrollView(.horizontal) {
                            Text(milString).font(.system(size:12))
                        }
                    }.textSelection(.enabled)
                } else {
                    Text("MIL")
                }
            }
            if (showSimple) {
                if (dictLoaded) {
                    let csvContent = getSimple(d: analyticsDict)
                    let toSaveUrl = URL.temporaryDirectory.appending(component: "\(modelSelected)_\(modelNames[modelSelected]!)_\(precisionSelected).csv")
                    let _: () = try! csvContent.data(using: .utf8)!.write(to: toSaveUrl)
                    
                    ShareLink(item: toSaveUrl)
                    ScrollView(.vertical) {
                        ScrollView(.horizontal) {
                            Text(getSimple(d: analyticsDict)).font(.system(size:12))
                        }
                    }.textSelection(.enabled)
                } else {
                    Text("Simple")
                }
            }
        }
        .padding()
    }
    
    func downloadAar() {
        if let url = URL(string: "http://freedom-imac-2.local/~freedom/banff_1_0.aar") {
            // print("here")
            let task = URLSession.shared.downloadTask(with: url) {
                localURL, response, error in
                if let localURL = localURL {
                    // Move the downloaded file to a desired location
                    let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("banff_1_0.aar")
                    try? FileManager.default.moveItem(at: localURL, to: destinationURL)
                    print("models downloaded \(destinationURL)")
                    
                    guard let readFileStream = ArchiveByteStream.fileStream(
                            path: FilePath(destinationURL.path()),
                            mode: .readOnly,
                            options: [ ],
                            permissions: FilePermissions(rawValue: 0o644)) else {
                        return
                    }
                    defer {
                        try? readFileStream.close()
                    }
                    guard let decompressStream = ArchiveByteStream.decompressionStream(readingFrom: readFileStream) else {
                        return
                    }
                    defer {
                        try? decompressStream.close()
                    }
                    let decompressPath = NSTemporaryDirectory() + "dest/"

                    guard let decodeStream = ArchiveStream.decodeStream(readingFrom: decompressStream) else {
                        print("unable to create decode stream")
                        return
                    }
                    defer {
                        try? decodeStream.close()
                    }

                    if !FileManager.default.fileExists(atPath: decompressPath) {
                        do {
                            try FileManager.default.createDirectory(atPath: decompressPath,
                                                                    withIntermediateDirectories: false)
                        } catch {
                            fatalError("Unable to create destination directory.")
                        }
                    }
                    let decompressDestination = FilePath(decompressPath)
                    
                    guard let extractStream = ArchiveStream.extractStream(extractingTo: decompressDestination,
                                                                          flags: [ .ignoreOperationNotPermitted ]) else {
                        return
                    }
                    defer {
                        try? extractStream.close()
                    }
                    do {
                        _ = try ArchiveStream.process(readingFrom: decodeStream,
                                                      writingTo: extractStream)
                        print("models extracted to \(decompressPath)")
                        modelPathPrefix = decompressPath
                        // modelPath = decompressPath + "/image-classification/mobilenet_v1_f16.mlmodelc"
                    } catch {
                        print("process failed")
                    }
                    
                    aarExtracted = true;
                    /*
                    if (!dictLoaded) {
                        analyticsDict = getProfilingDict()
                        dictLoaded.toggle()
                    }
                    */
                }
            }
            // print("here to download")
            task.resume()
        }
    }
    
    func getProfilingDict() -> [AnyHashable: Any] {
        let url = URL.init(fileURLWithPath: modelPath)
        
        let configuration = MLModelConfiguration()
        configuration.setProfilingOptions(1)
        
        let mlmodel = try! MLModel(contentsOf: url, configuration: configuration)
        let e5engine = mlmodel.program() as! MLE5Engine
        
        // hack:
        //   cannot get class of e5engine.program (OBJC_$_MLE5ProgramLibary), so hack with dynamic binding
        //   downcast to NSObject to invoke segmentationAnalyticsAndReturnError:
        //    e5engine.programLibrary() as! NSObject
        let d = (e5engine.programLibrary() as! NSObject).segmentationAnalyticsAndReturnError(nil)
        // print(String.init(format: "%@", d!))
        print("profiling done")
        
        return d!
    }
    
    func getSimple(d: Dictionary<AnyHashable, Any>) -> String {
        let allKeys = d.keys
        let sortedKeys = allKeys.sorted(by: {
            (obj1, obj2) in
           
            let loc_1 = ((obj1 as! String).components(separatedBy: ":")[1] as NSString).integerValue
            let loc_2 = ((obj2 as! String).components(separatedBy: ":")[1] as NSString).integerValue;
            return (loc_1 < loc_2)
        })
        // print(sortedKeys)
        
        var max_backends = 0;
        var all_backends: Array<String> = Array.init()
        
        for e in sortedKeys {
            let backends = (d[e] as! Dictionary<AnyHashable, Any>)["BackendSupport"] as! Dictionary<AnyHashable, Any>
            if (backends.count > max_backends) {
                max_backends = backends.count
                all_backends = backends.map { $0.key } as! [String]
            }
        }
        // print(all_backends)
        
        var toReturn: String = String()
        
        for e in sortedKeys {
            let d_casted = d[e] as! Dictionary<AnyHashable, Any>
            
            let debugName = d_casted["DebugName"] as! String
            let opType = d_casted["OpType"] as! String
            let selectedBackend = d_casted["SelectedBackend"] as! String
            
            var backends = Array<String>();
            var estimateds = Array<String>();
            var errorMessages = Array<String>();
            
            let supportedBackends = (d_casted["BackendSupport"] as! Dictionary<String, Any>).map{$0.key} as! [String]
            let estimated = (d_casted["EstimatedRunTime"] as! Dictionary<AnyHashable, Any>).map{$0.key} as! [String]
            let validationMessages = (d_casted["ValidationMessages"] as! Dictionary<AnyHashable, Any>).map{$0.key} as! [String]
            // print(supportedBackends)
            // print(debugName)
            
            for i in 0...max_backends-1 {
                // supportedBackends.contains
                if (supportedBackends.contains(all_backends[i])) {
                    backends.append(all_backends[i])
                } else {
                    backends.append("")
                }
                
                if (estimated.contains(all_backends[i])) {
                    let r = (d_casted["EstimatedRunTime"] as! Dictionary<String, NSNumber>)[all_backends[i]]
                    estimateds.append(r!.stringValue)
                } else {
                    estimateds.append("")
                }
                
                if (validationMessages.contains(all_backends[i])) {
                    let r = (d_casted["ValidationMessages"] as! Dictionary<String, String>)[all_backends[i]]
                    errorMessages.append(r!)
                } else {
                    errorMessages.append("")
                }
            }
            // print(backends)
            // print(estimateds)
            
            var entry : String = String()
            entry = entry.appendingFormat("%@\t%@\t%@\t",  debugName, opType, selectedBackend)
            
            for i in 0...max_backends-1 {
                entry = entry.appendingFormat("%@\t", backends[i])
            }
            for i in 0...max_backends-1 {
                entry = entry.appendingFormat("%@\t", estimateds[i])
            }
            for i in 0...max_backends-2 {
                entry = entry.appendingFormat("%@\t", errorMessages[i])
            }
            entry = entry.appendingFormat("%@\n", errorMessages[max_backends - 1])
            // print(entry)
            toReturn = toReturn.appending(entry)
        }
        return toReturn
    }
}

#Preview {
    ContentView()
}
