//
//  Format.swift
//  CropAgent
//
//  Created by bertrand DUPUY on 10/05/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit

enum ExportFormat: Int{
    case a4 = 4, a5, a6, a7, a8, a9, a10
}

struct FormatStruct {
    
    let type : ExportFormat
    let size : CGSize
    let typeLabel : String
    let sizeLabel : String
    let imageName : String
    
    init(type : ExportFormat){
    
        self.type = type
        
        switch(type){
            
        case .a4 :
            size = CGSize(width: 297, height: 210)
            typeLabel = "A4"
            sizeLabel = "210 x 297 mm"
        case .a5 :
            size = CGSize(width: 210, height: 148)
            typeLabel = "A5"
            sizeLabel = "148 x 210 mm"
        case .a6 :
            size = CGSize(width: 148, height: 105)
            typeLabel = "A6"
            sizeLabel = "105 x 148 mm"
        case .a7 :
            size = CGSize(width: 105, height: 74)
            typeLabel = "A7"
            sizeLabel = "74 x 105 mm"
        case .a8 :
            size = CGSize(width: 74, height: 52)
            typeLabel = "A8"
            sizeLabel = "52 x 74 mm"
        case .a9 :
            size = CGSize(width: 52, height: 37)
            typeLabel = "A9"
            sizeLabel = "37 x 52 mm"
        case .a10:
            size = CGSize(width: 37, height: 26)
            typeLabel = "A10"
            sizeLabel = "26 x 37 mm"
        }
                
        imageName = "a"+String(type.rawValue)
    }
}

class Format {

    static private let availableFormats :[ExportFormat] = [ExportFormat.a4, .a5, .a6, .a7, .a8, .a9, .a10]
    let currentFormat : FormatStruct
    
    init(currentFormat : ExportFormat){
        self.currentFormat = FormatStruct(type: currentFormat)
    }
    
    static func getAllFormats()->[FormatStruct]{
    
        var allFormats = [FormatStruct]()
        
        for tmpElt in availableFormats{
            allFormats.append(FormatStruct(type: tmpElt))
        }
        return allFormats
    }
}
