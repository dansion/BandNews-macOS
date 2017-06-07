//
//  DataCache.swift
//  BandRadios
//
//  Created by Daniel Bonates on 27/03/17.
//  Copyright © 2017 Daniel Bonates. All rights reserved.
//

import Foundation

final class DataCache {
    
    private static let dataFolder = "\(Bundle.main.bundleIdentifier!)"
    
    private static var basePath: String {
        return NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
            .first!.appending("/\(DataCache.dataFolder)/")
    }
    
    func cachePathFor(_ url: URL, id: Int? = nil) -> String {
        
        try? FileManager.default.createDirectory(
            atPath: DataCache.basePath,
            withIntermediateDirectories: true,
            attributes: [:])
        
        if let id = id {
            return DataCache.basePath.appending(url.lastPathComponent + "-\(id)")
        }
        return DataCache.basePath.appending(url.lastPathComponent)
    }
    
    func getRadioList(from url: URL, completion: @escaping ([Station]?) -> ()) {
        
        let destinationPath = cachePathFor(url)
        
        if FileManager.default.fileExists(atPath: destinationPath) {
            guard let localURL = URL(string: destinationPath) else { return }
            DataService().loadLocal(resource: stationsResource(from: localURL), completion: { stations in
                completion(stations)
                return
            })
        }
        
        let sr = stationsResource(from: url)
        
        DataService().load(resource: sr, completion: { stations in
            completion(stations)
        })
        
    }
    
    func stationsResource(from url: URL) -> Resource<[Station]> {
    
        let stationsResource = Resource<[Station]>(id: nil, url: url, parse: { data in
            
            do {
                
                if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                    
                    return (self.stations(from: json))
                    
                }
            } catch let error {
                print(error.localizedDescription)
            }
            
            return nil
        })
        
        return stationsResource
    }
    
    func getStreamInfo(for url: URL, id: Int, completion: @escaping (Stream?) -> ()) {
        
        let localURL = cachePathFor(url, id: id)
        
        let shouldLoadLocal = FileManager.default.fileExists(atPath: localURL)
                
        let sr = streamInfoResource(from: url, id: id)
        
        if shouldLoadLocal {
            DataService().loadLocal(resource: sr, completion: { stationInfo in
                completion(stationInfo)
            })
        } else {
            DataService().load(resource: sr, completion: { stationInfo in
                completion(stationInfo)
            })
        }
        
    }
    
    func streamInfoResource(from url: URL, id: Int) -> Resource<Stream> {
        
        let stationInfoResource = Resource<Stream>(id: id, url: url, parse: { data in
            
            do {
                
                if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                    
                    guard
                        let resultDataJson = json["resultData"] as? [String: Any]
                        else { return nil }
                    
                    return (Stream(from: resultDataJson))
                    
                }
            } catch let error {
                print(error.localizedDescription)
            }
            
            return nil
        })
        
        return stationInfoResource
    }
    
    
    func stations(from json: [String: Any]) -> [Station]? {
        guard
            let resultDataJson = json["resultData"] as? [String: Any],
            let dataJson = resultDataJson["data"] as? [[String: Any]]
        else { return nil }
        
        return dataJson.flatMap(Station.init)
    }
    
    
}

