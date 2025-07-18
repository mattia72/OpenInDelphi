// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const os = require('os');

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {

	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Congratulations, your extension "openindelphi" is now active!');

	// The command has been defined in the package.json file
	// Now provide the implementation of the command with  registerCommand
	// The commandId parameter must match the command field in package.json
	const disposable = vscode.commands.registerCommand('openindelphi.openCurrentFileInDelphi', function () {
		// Get the currently active editor
		const activeEditor = vscode.window.activeTextEditor;
		
		if (activeEditor) {
			// Get the file path of the currently edited file
			const filePath = activeEditor.document.uri.fsPath;
			const fileName = activeEditor.document.fileName;
			const workspaceFolder = vscode.workspace.getWorkspaceFolder(activeEditor.document.uri);
			
			// Get cursor position information
			const position = activeEditor.selection.active;
			const line = position.line + 1; // VS Code uses 0-based line numbers
			const column = position.character + 1; // VS Code uses 0-based column numbers
			
			// Get relative path if in workspace
			const relativePath = workspaceFolder ? 
				vscode.workspace.asRelativePath(activeEditor.document.uri) : 
				filePath;
			
			console.log('=== Active Editor Information ===');
			console.log('Full file path:', filePath);
			console.log('File name:', fileName);
			console.log('Relative path:', relativePath);
			console.log('Workspace folder:', workspaceFolder ? workspaceFolder.uri.fsPath : 'Not in workspace');
			console.log('Current line:', line);
			console.log('Current column:', column);
			console.log('Language ID:', activeEditor.document.languageId);
			
			// Create data object to send through pipe
			const pipeData = {
				filePath: filePath,
				fileName: path.basename(filePath),
				relativePath: relativePath,
				workspaceFolder: workspaceFolder ? workspaceFolder.uri.fsPath : null,
				line: line,
				column: column,
				languageId: activeEditor.document.languageId,
				timestamp: new Date().toISOString()
			};
			
			// Write to named pipe
			const pipeName = '\\\\.\\pipe\\vscode_delphi_bridge';
			
			try {
				// Convert data to JSON string
				const jsonData = JSON.stringify(pipeData, null, 2);
				
				// Write to named pipe (Windows format)
				fs.writeFile(pipeName, jsonData, (err) => {
					if (err) {
						console.error('Error writing to pipe:', err);
						// Try alternative approach - write to temp file
						const tempFile = path.join(os.tmpdir(), 'vscode_delphi_bridge.json');
						fs.writeFileSync(tempFile, jsonData);
						console.log('Written to temp file instead:', tempFile);
						vscode.window.showInformationMessage(`Data written to temp file: ${tempFile}`);
					} else {
						console.log('Successfully written to pipe:', pipeName);
						vscode.window.showInformationMessage('Data sent to Delphi via named pipe');
					}
				});
				
			} catch (error) {
				console.error('Error creating pipe data:', error);
				vscode.window.showErrorMessage('Failed to send data to pipe');
			}
			
			// Display the file path and location information
			const locationInfo = `File: ${fileName}
Path: ${filePath}
Relative: ${relativePath}
Position: Line ${line}, Column ${column}
Language: ${activeEditor.document.languageId}`;
			
			vscode.window.showInformationMessage(locationInfo);
			
			// Here you can add the logic to open the file in Delphi
			// For example, you could use child_process to execute a command
			// that opens Delphi with the current file at the specific line
		} else {
			vscode.window.showWarningMessage('No file is currently open in the editor.');
		}
	});

	context.subscriptions.push(disposable);
}

// This method is called when your extension is deactivated
function deactivate() {}

module.exports = {
	activate,
	deactivate
}
