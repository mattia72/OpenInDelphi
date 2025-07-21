class DelphiCommander {
    static pipeData = null;
    static sendCommandToDelphi(pipeData, pipeName = '\\\\.\\pipe\\vscode_delphi_bridge') {
        const net = require('net');
        const fs = require('fs');
        const path = require('path');
        const os = require('os');
        const jsonData = JSON.stringify(pipeData, null, 2);
        const client = net.connect(pipeName, () => {
            client.write(jsonData);
            client.end();
        });
        client.on('error', (err) => {
            console.error('Pipe error:', err);
            // Try alternative approach - write to temp file
            const tempFile = path.join(os.tmpdir(), 'vscode_delphi_bridge.json');
            fs.writeFileSync(tempFile, jsonData);
            console.log('Written to temp file instead:', tempFile);
        });
        client.on('end', () => {
            console.log('Successfully written to pipe:', pipeName);
        });
    }

    static openCurrentFileInDelphi() {
        const vscode = require('vscode');
        const path = require('path');
        const activeEditor = vscode.window.activeTextEditor;
        if (activeEditor) {
            DelphiCommander.getActiveEditorData(activeEditor);
            try {
                DelphiCommander.sendCommandToDelphi(DelphiCommander.pipeData);
                vscode.window.showInformationMessage('Data sent to Delphi via named pipe (or temp file fallback)');
            } catch (error) {
                console.error('Error creating pipe data:', error);
                vscode.window.showErrorMessage('Failed to send data to pipe');
            }
            const pd = DelphiCommander.pipeData;
            const locationInfo = `File: ${pd.fileName}\nPath: ${pd.filePath}\nRelative: ${pd.relativePath}\nPosition: Line ${pd.line}, Column ${pd.column}\nLanguage: ${pd.languageId}`;
            vscode.window.showInformationMessage(locationInfo);
        } else {
            vscode.window.showWarningMessage('No file is currently open in the editor.');
        }
    }

    // createPipeData entfällt, Logik wandert nach getActiveEditorData

    static getActiveEditorData(activeEditor) {
        const path = require('path');
        const filePath = activeEditor.document.uri.fsPath;
        const fileName = activeEditor.document.fileName;
        const workspaceFolder = require('vscode').workspace.getWorkspaceFolder(activeEditor.document.uri);
        const position = activeEditor.selection.active;
        const line = position.line + 1;
        const column = position.character + 1;
        const relativePath = workspaceFolder ?
            require('vscode').workspace.asRelativePath(activeEditor.document.uri) :
            filePath;
        const languageId = activeEditor.document.languageId;
        DelphiCommander.pipeData = {
            command: 'gotoFileLocation',
            filePath: filePath,
            fileName: path.basename(filePath),
            relativePath: relativePath,
            workspaceFolder: workspaceFolder ? workspaceFolder.uri.fsPath : null,
            line: line,
            column: column,
            languageId: languageId,
            timestamp: new Date().toISOString()
        };
        DelphiCommander.logActiveEditorValues(filePath, fileName, relativePath, workspaceFolder, line, column, languageId);
        return { filePath, relativePath, workspaceFolder, line, column, fileName };
    }

    static logActiveEditorValues(filePath, fileName, relativePath, workspaceFolder, line, column, languageId) {
        console.log('=== Active Editor Information ===');
        console.log('Full file path:', filePath);
        console.log('File name:', fileName);
        console.log('Relative path:', relativePath);
        console.log('Workspace folder:', workspaceFolder ? workspaceFolder.uri.fsPath : 'Not in workspace');
        console.log('Current line:', line);
        console.log('Current column:', column);
        console.log('Language ID:', languageId);
    }
}

module.exports = {
    DelphiCommander
};
