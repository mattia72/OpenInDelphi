class DelphiCommander {
    static pipeData = null;
    static errorMsg = 'Error occurred: Please check if Delphi is running and verify your DripExtensions settings.\n'
                    + 'If the problem persists, please report it on the GitHub repository: https://github.com/mattia72/OpenInDelphi/issues';

    static sendCommandToDelphi(pipeData, pipeName = '\\\\.\\pipe\\vscode_delphi_bridge') {
        const net = require('net');
        const jsonData = JSON.stringify(pipeData, null, 2);
        const client = net.connect(pipeName, () => {
            client.write(jsonData);
            client.end();
        });
        client.on('error', (err) => {
            console.error('Pipe error:', err);
            // Benutzer informieren statt in eine temporäre Datei zu schreiben
            try {
                const vscode = require('vscode');
                vscode.window.showErrorMessage('Error: ' + err.message);
                vscode.window.showErrorMessage(DelphiCommander.errorMsg);
            } catch (e) {
                // Fallback if vscode is not available
                console.error('Could not show error notification:', e);
            }
        });
        client.on('end', () => {
            console.log('Successfully written to pipe:', pipeName);
        });
    }

    static activateDelphiWindow() {
        const os = require('os');
        if (os.platform() === 'win32') {
            try {
                const { exec } = require('child_process');
                const path = require('path');
                
                // Pfad zum PowerShell-Skript
                const scriptPath = path.join(__dirname, 'scripts', 'activate-delphi-window.ps1');
                
                // PowerShell-Skript ausführen
                exec(`powershell -NoProfile -ExecutionPolicy Bypass -File "${scriptPath}"`, (error, stdout, stderr) => {
                    if (error) {
                        console.error('Error activating Delphi window:', error);
                        console.error('stderr:', stderr);
                    } else {
                        console.log('PowerShell output:', stdout);
                        console.log('Delphi window activation completed');
                    }
                });
            } catch (error) {
                console.error('Failed to activate Delphi window:', error);
            }
        }
    }

    static openCurrentFileInDelphi() {
        const vscode = require('vscode');
        const activeEditor = vscode.window.activeTextEditor;
        if (activeEditor) {
            DelphiCommander.getActiveEditorData(activeEditor);
            try {
                DelphiCommander.sendCommandToDelphi(DelphiCommander.pipeData);
                DelphiCommander.activateDelphiWindow();
            } catch (error) {
                console.error('Error creating pipe data:', error);
            }
            const pd = DelphiCommander.pipeData;
            const locationInfo = `File: ${pd.fileName}\nPath: ${pd.filePath}\nRelative: ${pd.relativePath}\nPosition: Line ${pd.line}, Column ${pd.column}\nLanguage: ${pd.languageId}`;
            vscode.window.showInformationMessage(locationInfo);
        } else {
            vscode.window.showWarningMessage('No file is currently open in the editor.');
        }
    }

    static buildActiveProjectInDelphi() {
        const vscode = require('vscode');
        const pipeData = {
            command: 'buildActiveProject',
            timestamp: new Date().toISOString()
        };
        
        try {
            DelphiCommander.sendCommandToDelphi(pipeData);
            DelphiCommander.activateDelphiWindow();
            vscode.window.showInformationMessage('Build command sent to Delphi');
        } catch (error) {
            console.error('Error sending build command:', error);
        }
    }

    static compileActiveProjectInDelphi() {
        const vscode = require('vscode');
        const pipeData = {
            command: 'compileActiveProject', 
            timestamp: new Date().toISOString()
        };
        
        try {
            DelphiCommander.sendCommandToDelphi(pipeData);
            DelphiCommander.activateDelphiWindow();
            vscode.window.showInformationMessage('Compile command sent to Delphi');
        } catch (error) {
            console.error('Error sending compile command:', error);
        }
    }

    // createPipeData entfällt, Logik wandert nach getActiveEditorData

    static getActiveEditorData(activeEditor) {
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
            fileName: filePath.split('\\').pop() || filePath.split('/').pop() || filePath,
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
