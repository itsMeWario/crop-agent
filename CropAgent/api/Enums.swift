//
//  Enums.swift
//  CropAgent
//
//  Created by bertrand DUPUY on 11/06/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit

enum ImageAlignment : Int{
    case leftAlignment = 0, topAlignment,
    rightAlignment, bottomAlignment,
    horizontalCenterAlignment, verticalCenterAlignment, none
}

enum AlignmentAxis : Int{
    case horizontal = 0, vertical
}

enum ImageDefinition : Int{
    case lowRes = 0, highRes
}

enum AspectSizeChange : Int{
    case equalHeight = 0, equaWidth
}
