class DelphiCommander {
    static pipeData = null;
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
                vscode.window.showErrorMessage(
                    'Error sending to Delphi (pipe error): ' + err.message + '\nPlease check if Delphi is running and verify your DripExtensions settings.'
                );
            } catch (e) {
                // Fallback if vscode is not available
                console.error('Could not show error notification:', e);
            }
        });
        client.on('end', () => {
            console.log('Successfully written to pipe:', pipeName);
            // Delphi-Fenster aktivieren nach erfolgreichem Senden
            DelphiCommander.activateDelphiWindow();
        });
    }

    static activateDelphiWindow() {
        const os = require('os');
        if (os.platform() === 'win32') {
            try {
                const { exec } = require('child_process');
                // PowerShell-Befehl um Delphi-Fenster zu aktivieren
                const powershellCmd = `
                    Add-Type -TypeDefinition '
                        using System;
                        using System.Runtime.InteropServices;
                        public class Win32 {
                            [DllImport("user32.dll")]
                            public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
                            [DllImport("user32.dll")]
                            public static extern bool SetForegroundWindow(IntPtr hWnd);
                            [DllImport("user32.dll")]
                            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
                        }
                    ';
                    $delphiWindow = [Win32]::FindWindow($null, "*Delphi*");
                    if ($delphiWindow -ne [IntPtr]::Zero) {
                        [Win32]::ShowWindow($delphiWindow, 9);
                        [Win32]::SetForegroundWindow($delphiWindow);
                        Write-Host "Delphi window activated";
                    } else {
                        Get-Process | Where-Object {$_.ProcessName -like "*bds*" -or $_.ProcessName -like "*delphi*"} | ForEach-Object {
                            $mainWindow = $_.MainWindowHandle;
                            if ($mainWindow -ne [IntPtr]::Zero) {
                                [Win32]::ShowWindow($mainWindow, 9);
                                [Win32]::SetForegroundWindow($mainWindow);
                                Write-Host "Delphi process window activated";
                            }
                        }
                    }
                `.replace(/\n\s+/g, ' ');
                
                exec(`powershell -NoProfile -Command "${powershellCmd}"`, (error) => {
                    if (error) {
                        console.error('Error activating Delphi window:', error);
                    } else {
                        console.log('Delphi window activation attempt completed');
                    }
                });
            } catch (error) {
                console.error('Failed to activate Delphi window:', error);
            }
        }
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
