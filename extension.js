const vscode = require('vscode');
const { DelphiCommander } = require('./delphiCommander');

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
	console.log('Congratulations, your extension "OpenInDelphi" is now active!');
	
	// Register the commands
	const openFileCommandDisposable = vscode.commands.registerCommand('openindelphi.openCurrentFileInDelphi', () => {
		DelphiCommander.openCurrentFileInDelphi();
	});

	const buildProjectCommandDisposable = vscode.commands.registerCommand('openindelphi.buildActiveProjectInDelphi', () => {
		DelphiCommander.buildActiveProjectInDelphi();
	});

	const compileProjectCommandDisposable = vscode.commands.registerCommand('openindelphi.compileActiveProjectInDelphi', () => {
		DelphiCommander.compileActiveProjectInDelphi();
	});
	
	// Create a command that checks if context menu should be visible
	const checkContextMenuDisposable = vscode.commands.registerCommand('openindelphi.checkContextMenu', () => {
		return shouldShowContextMenu();
	});
	
	context.subscriptions.push(openFileCommandDisposable, buildProjectCommandDisposable, compileProjectCommandDisposable, checkContextMenuDisposable);
	
	// Function to update the context menu visibility
	const updateContextMenuVisibility = () => {
		const shouldShow = shouldShowContextMenu();
		vscode.commands.executeCommand('setContext', 'openindelphi.shouldShowContextMenu', shouldShow);
		console.log('OpenInDelphi context menu visibility updated:', shouldShow);
	};
	
	// Listen for configuration changes to update context menu visibility
	const configChangeDisposable = vscode.workspace.onDidChangeConfiguration(event => {
		if (event.affectsConfiguration('openindelphi')) {
			console.log('OpenInDelphi configuration changed');
			updateContextMenuVisibility();
		}
	});
	
	// Listen for active editor changes to update context menu visibility
	const editorChangeDisposable = vscode.window.onDidChangeActiveTextEditor(() => {
		updateContextMenuVisibility();
	});
	
	// Listen for when documents are opened
	const documentOpenDisposable = vscode.workspace.onDidOpenTextDocument(() => {
		updateContextMenuVisibility();
	});
	
	// Listen for when text editor selection changes (when user clicks in editor)
	const selectionChangeDisposable = vscode.window.onDidChangeTextEditorSelection(() => {
		updateContextMenuVisibility();
	});
	
	// Listen for when visible text editors change
	const visibleEditorsChangeDisposable = vscode.window.onDidChangeVisibleTextEditors(() => {
		updateContextMenuVisibility();
	});
	
	context.subscriptions.push(configChangeDisposable, editorChangeDisposable, documentOpenDisposable, selectionChangeDisposable, visibleEditorsChangeDisposable);
}

/**
 * Check if context menu should be shown based on current file extension
 * @returns {boolean}
 */
function shouldShowContextMenu() {
	let shouldShow = false;
	let showContextMenu = false;
	let fileExtension;
	try {
		const config = vscode.workspace.getConfiguration('openindelphi');
		showContextMenu = config.get('showContextMenu', true);
		
		// First check: is context menu enabled at all?
		if (!showContextMenu) {
			return false;
		}
		
		const allowedExtensions = config.get('showContextMenuOnFileExtension', ['*']);
		
		// If '*' is in the list, show for all files
		if (allowedExtensions.includes('*')) {
			return true;
		}
		
		const activeEditor = vscode.window.activeTextEditor;
		if (!activeEditor) {
			return false;
		}
		
		const filePath = activeEditor.document.uri.fsPath;
		fileExtension = getFileExtension(filePath);
		
		// Check if current file extension is in allowed list
		shouldShow = allowedExtensions.some(ext => {
			// Handle files without extension
			if (fileExtension === '' && ext === '') {
				return true;
			}
			return ext.toLowerCase() === fileExtension.toLowerCase();
		});
		
		return shouldShow;
	} catch (error) {
		console.error('OpenInDelphi: Error in shouldShowContextMenu:', error);
		return true; // Default to showing menu on error
	} finally {
		console.log(`OpenInDelphi: Context menu enabled: '${showContextMenu}', File extension '${fileExtension}' showing: ${shouldShow}`);
	}
}

/**
 * Get file extension from file path
 * @param {string} filePath 
 * @returns {string}
 */
function getFileExtension(filePath) {
	if (!filePath || typeof filePath !== 'string') {
		return '';
	}
	
	const lastDotIndex = filePath.lastIndexOf('.');
	const lastSlashIndex = Math.max(filePath.lastIndexOf('/'), filePath.lastIndexOf('\\'));
	
	// Check if the dot is after the last slash/backslash (to avoid directory names with dots)
	if (lastDotIndex === -1 || lastDotIndex < lastSlashIndex) {
		return '';
	}
	
	return filePath.substring(lastDotIndex + 1);
}

// This method is called when your extension is deactivated
function deactivate() {
	// Extension cleanup is handled automatically by VS Code
}

module.exports = {
	activate,
	deactivate
}
