//
//  Job.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/09/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

struct Job: Codable {
    let total_count: Int
    let jobs: [Jobs]
}
