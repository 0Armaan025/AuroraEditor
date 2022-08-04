//
//  SearchResultModel.swift
//  AuroraEditorModules/Search
//
//  Created by Ziyuan Zhao on 2022/3/22.
//

import Foundation

public struct SearchResultModel: Hashable {
    public var file: WorkspaceClient.FileItem
    public var lineNumber: Int?
    public var lineContent: String?
    public var keywordRange: Range<String.Index>?

    public init(
        file: WorkspaceClient.FileItem,
        lineNumber: Int?,
        lineContent: String?,
        keywordRange: Range<String.Index>?
    ) {
        self.file = file
        self.lineNumber = lineNumber
        self.lineContent = lineContent
        self.keywordRange = keywordRange
    }

    public var hasKeywordInfo: Bool {
        lineNumber != nil && lineContent != nil && keywordRange != nil
    }
}