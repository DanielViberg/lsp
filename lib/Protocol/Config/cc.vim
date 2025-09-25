vim9script

export const CC = {
  workspace: {
    applyEdit: false,
    workspaceEdit: {
      documentChanges: false,
      resourceOperations: ['rename', 'create', 'delete'],
      failureHandling: '',
      normalizesLineEndings: false,
      changeAnnotationSupport: { groupsOnLabel: false }
    },
    didChangeConfiguration: { 
      dynamicRegistration: false
    },
    didChangeWatchedFiles: {
      dynamicRegistration: false,
      relativePatternSupport: false
    },
    symbol: {
      dynamicRegistration: false,
      symbolKind: { valueSet: [] },
      tagSupport: { valueSet: [] },
      resolveSupport: { properties: [] }
    },
    executeCommand: { dynamicRegistration: false },
    configuration: true,
    workspaceFolders: false,
    semanticTokens: {
      dynamicRegistration: false,
      requests: {
        range: false,
        full: { delta: false }
      },
      tokenTypes: [],
      tokenModifiers: [],
      formats: [],
      multilineTokenSupport: false,
      overlappingTokenSupport: false,
      serverCancelSupport: false,
      augmentsSyntaxTokens: false
    },
    fileOperations: {
      dynamicRegistration: false,
      didCreate: false,
      didRename: false,
      didDelete: false,
      willCreate: false,
      willRename: false,
      willDelete: false
    },
    inlineValue: { dynamicRegistration: false },
    inlayHint: {
      dynamicRegistration: false,
      resolveSupport: { properties: [] }
    },
    diagnostics: { 
      dynamicRegistration: false 
    }
  },
  textDocument: {
    synchronization: {
      dynamicRegistration: false,
      willSave: true,
      willSaveWaitUntil: false,
      didSave: true
    },
    completion: {
      dynamicRegistration: false,
      completionItem: {
        snippetSupport: false,
        commitCharactersSupport: false,
        documentationFormat: ['plaintext'],
        deprecatedSupport: false,
        preselectSupport: false,
        tagSupport: { valueSet: [] },
        insertReplaceSupport: false,
        resolveSupport: { properties: ['documentation', 'detail'] },
        insertTextModeSupport: { valueSet: [] },
        labelDetailsSupport: false
      },
      completionItemKind: { valueSet: range(1, 25) },
      contextSupport: false,
      insertTextMode: 0,
      completionList: { itemDefaults: [] }
    },
    hover: {
      dynamicRegistration: false,
      contentFormat: []
    },
    signatureHelp: {
      dynamicRegistration: false,
      signatureInformation: {
        documentationFormat: [],
        parameterInformation: { labelOffsetSupport: false },
        activeParameterSupport: false
      },
      contextSupport: false
    },
    references: { dynamicRegistration: false },
    documentHighlight: { dynamicRegistration: false },
    documentSymbol: {
      dynamicRegistration: false,
      symbolKind: { valueSet: range(1, 25) },
      hierarchicalDocumentSymbolSupport: false,
      tagSupport: { valueSet: [] },
      labelSupport: false
    },
    formatting: { 
      dynamicRegistration: false 
    },
    rangeFormatting: {
      dynamicRegistration: false,
      rangesSupport: false
    },
    onTypeFormatting: { dynamicRegistration: false },
    definition: {
      dynamicRegistration: false,
      linkSupport: false
    },
    typeDefinition: {
      dynamicRegistration: false,
      linkSupport: false
    },
    implementation: {
      dynamicRegistration: false,
      linkSupport: false
    },
    declaration: {
      dynamicRegistration: false,
      linkSupport: false
    },
    codeAction: {
      dynamicRegistration: false,
      codeActionLiteralSupport: { codeActionKind: { valueSet: [] } },
      isPreferredSupport: false,
      disabledSupport: false,
      dataSupport: false,
      resolveSupport: { properties: [] },
      honorsChangeAnnotations: false
    },
    codeLens: { dynamicRegistration: false },
    documentLink: {
      dynamicRegistration: false,
      tooltipSupport: false
    },
    colorProvider: { dynamicRegistration: false },
    rename: {
      dynamicRegistration: false,
      prepareSupport: false,
      prepareSupportDefaultBehavior: 0,
      honorsChangeAnnotations: false
    },
    publishDiagnostics: {
      relatedInformation: false,
      tagSupport: { valueSet: [] },
      versionSupport: false,
      codeDescriptionSupport: false,
      dataSupport: false
    },
    foldingRange: {
      dynamicRegistration: false,
      rangeLimit: 0,
      lineFoldingOnly: false,
      foldingRangeKind: { valueSet: [] },
      foldingRange: { collapsedText: false }
    },
    selectionRange: { dynamicRegistration: false },
    linkedEditingRange: { dynamicRegistration: false },
    callHierarchy: { dynamicRegistration: false },
    semanticTokens: {
      dynamicRegistration: false,
      requests: {
        range: false,
        full: { delta: false }
      },
      tokenTypes: [],
      tokenModifiers: [],
      formats: [],
      multilineTokenSupport: false,
      overlappingTokenSupport: false,
      serverCancelSupport: false,
      augmentsSyntaxTokens: false
    },
    moniker: { dynamicRegistration: false },
    typeHierarchy: { dynamicRegistration: false },
    inlineValue: { dynamicRegistration: false },
    inlayHint: {
      dynamicRegistration: false,
      resolveSupport: { properties: [] }
    },
    diagnostic: {
      dynamicRegistration: false,
      relatedDocumentSupport: false
    }
  },
  window: {
    workDoneProgress: false,
    showMessage: { messageActionItem: { additionalPropertiesSupport: false } },
    showDocument: { support: false }
  },
  general: {
    staleRequestSupport: {
      cancel: false,
      retryOnContentModified: []
    },
    regularExpressions: { engine: '', version: '' },
    markdown: { parser: '', version: '', allowedTags: [] },
    positionEncodings: ['utf-16', 'utf-32']
  },
  notebookDocument: {
    synchronization: {
      dynamicRegistration: false,
      executionSummarySupport: false
    }
  },
  offsetEncoding: ['utf-32', 'utf-16'],
}
